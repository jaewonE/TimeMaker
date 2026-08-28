import Combine
import Foundation
import TimeMakerCore

@MainActor
final class TimerStore: ObservableObject {
    @Published private(set) var phase: TimerPhase = .idle
    @Published private(set) var configuredSeconds: Int = 30 * 60
    @Published private(set) var remainingSeconds: Int = 30 * 60
    @Published var currentLabel: String = LabelNormalization.fallbackLabel {
        didSet {
            guard !isRestoringState else { return }
            defaults.set(currentLabel, forKey: Self.lastLabelKey)
            persistState()
        }
    }
    @Published private(set) var currentSessionElapsedSeconds: Int = 0

    private static let stateKey = "timer.persistedState"
    private static let lastLabelKey = "timer.lastLabel"

    private let history: HistoryStore
    private let settings: SettingsStore
    private let notificationService: NotificationService
    private let defaults: UserDefaults

    private var ticker: Timer?
    private var deadline: Date?
    private var sessionStartedAt: Date?
    private var lastResumedAt: Date?
    private var accumulatedActiveSeconds: TimeInterval = 0
    private var plannedDurationSeconds: Int = 30 * 60
    private var isRestoringState = false

    init(
        history: HistoryStore,
        settings: SettingsStore,
        notificationService: NotificationService,
        defaults: UserDefaults = .standard
    ) {
        self.history = history
        self.settings = settings
        self.notificationService = notificationService
        self.defaults = defaults

        restoreState()
        startTicker()

        DispatchQueue.main.async { [weak self] in
            self?.reconcileWithClock()
        }
    }

    var displayText: String {
        DurationFormatting.timer(phase == .idle ? configuredSeconds : remainingSeconds)
    }

    var displayedMinutes: Int {
        DurationFormatting.components(phase == .idle ? configuredSeconds : remainingSeconds).minutes
    }

    var displayedSeconds: Int {
        DurationFormatting.components(phase == .idle ? configuredSeconds : remainingSeconds).seconds
    }

    var canChangeDuration: Bool { phase == .idle }
    var canStart: Bool { phase != .idle || configuredSeconds > 0 }

    @discardableResult
    func toggle() -> TimerPhase {
        switch phase {
        case .idle:
            start()
        case .running:
            pause()
        case .paused:
            resume()
        }
        return phase
    }

    func setDuration(minutes: Int) {
        setDuration(seconds: min(max(minutes, 0), DurationFormatting.maximumMinutes) * 60)
    }

    func setDuration(seconds: Int) {
        guard canChangeDuration else { return }
        configuredSeconds = min(max(seconds, 0), DurationFormatting.maximumSeconds)
        remainingSeconds = configuredSeconds
        plannedDurationSeconds = configuredSeconds
        persistState()
    }

    func adjustMinutes(direction: ScrollDirection, step: Int) {
        guard canChangeDuration else { return }
        setDuration(seconds: TimerAdjustment.minutes(
            in: configuredSeconds,
            direction: direction,
            step: step
        ))
    }

    func adjustSeconds(direction: ScrollDirection, step: Int) {
        guard canChangeDuration else { return }
        setDuration(seconds: TimerAdjustment.seconds(
            in: configuredSeconds,
            direction: direction,
            step: step
        ))
    }

    func cancel(now: Date = Date()) {
        guard phase != .idle else {
            remainingSeconds = configuredSeconds
            persistState()
            return
        }

        if phase == .running {
            updateRunningState(now: now)
        }
        guard phase != .idle else { return }

        let elapsedSeconds = min(max(currentSessionElapsedSeconds, 0), plannedDurationSeconds)
        if settings.countCancelledTimerTime, elapsedSeconds > 0 {
            let label = normalizedLabel(currentLabel)
            let startedAt = sessionStartedAt ?? now.addingTimeInterval(-TimeInterval(elapsedSeconds))
            history.addSession(TimerSession(
                label: label,
                startedAt: startedAt,
                endedAt: now,
                durationSeconds: elapsedSeconds
            ))
        }

        resetActiveTimerState()
        persistState()
    }

    func restoreDefaultLabelIfEmpty() {
        guard currentLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        currentLabel = settings.defaultLabel
    }

    func suggestions(for query: String) -> [LabelUsage] {
        history.suggestions(matching: query)
    }

    func todayProgressSeconds(now: Date = Date(), calendar: Calendar = .current) -> Int {
        let completed = history.completedSecondsToday(now: now, calendar: calendar)
        guard phase != .idle, let sessionStartedAt else { return completed }
        let startOfToday = calendar.startOfDay(for: now)
        guard now >= startOfToday else { return completed }

        let maximumTodayContribution = Int(now.timeIntervalSince(max(sessionStartedAt, startOfToday)))
        return completed + min(currentSessionElapsedSeconds, max(maximumTodayContribution, 0))
    }

    private func start(now: Date = Date()) {
        guard configuredSeconds > 0 else { return }

        let label = normalizedLabel(currentLabel)
        if currentLabel != label { currentLabel = label }
        history.recordLabelUse(label, at: now)

        phase = .running
        remainingSeconds = configuredSeconds
        plannedDurationSeconds = configuredSeconds
        sessionStartedAt = now
        lastResumedAt = now
        accumulatedActiveSeconds = 0
        currentSessionElapsedSeconds = 0
        deadline = now.addingTimeInterval(TimeInterval(remainingSeconds))
        persistState()
    }

    private func pause(now: Date = Date()) {
        guard phase == .running else { return }
        updateRunningState(now: now)
        guard phase == .running else { return }

        if let lastResumedAt {
            accumulatedActiveSeconds += max(now.timeIntervalSince(lastResumedAt), 0)
        }
        self.lastResumedAt = nil
        deadline = nil
        currentSessionElapsedSeconds = min(Int(accumulatedActiveSeconds.rounded(.down)), plannedDurationSeconds)
        phase = .paused
        persistState()
    }

    private func resume(now: Date = Date()) {
        guard phase == .paused, remainingSeconds > 0 else { return }
        phase = .running
        lastResumedAt = now
        deadline = now.addingTimeInterval(TimeInterval(remainingSeconds))
        persistState()
    }

    private func startTicker() {
        ticker?.invalidate()
        let ticker = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.reconcileWithClock()
            }
        }
        RunLoop.main.add(ticker, forMode: .common)
        self.ticker = ticker
    }

    private func reconcileWithClock(now: Date = Date()) {
        guard phase == .running else { return }
        updateRunningState(now: now)
    }

    private func updateRunningState(now: Date) {
        guard let deadline else { return }

        let interval = deadline.timeIntervalSince(now)
        remainingSeconds = max(Int(ceil(interval)), 0)

        let currentSegment = lastResumedAt.map { max(now.timeIntervalSince($0), 0) } ?? 0
        currentSessionElapsedSeconds = min(
            Int((accumulatedActiveSeconds + currentSegment).rounded(.down)),
            plannedDurationSeconds
        )

        if interval <= 0 {
            complete(at: deadline)
        }
    }

    private func complete(at completionDate: Date) {
        let label = normalizedLabel(currentLabel)
        let start = sessionStartedAt ?? completionDate.addingTimeInterval(-TimeInterval(plannedDurationSeconds))
        let session = TimerSession(
            label: label,
            startedAt: start,
            endedAt: completionDate,
            durationSeconds: plannedDurationSeconds
        )
        history.addSession(session)
        notificationService.deliverCompletion(
            label: label,
            enabled: settings.notificationsEnabled
        )

        resetActiveTimerState()
        persistState()
    }

    private func restoreState() {
        isRestoringState = true
        defer { isRestoringState = false }

        if let lastLabel = defaults.string(forKey: Self.lastLabelKey),
           !lastLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            currentLabel = lastLabel
        }

        guard let data = defaults.data(forKey: Self.stateKey),
              let saved = try? JSONDecoder().decode(PersistedTimerState.self, from: data) else {
            return
        }

        configuredSeconds = min(max(saved.configuredSeconds, 0), DurationFormatting.maximumSeconds)
        remainingSeconds = min(max(saved.remainingSeconds, 0), DurationFormatting.maximumSeconds)
        currentLabel = normalizedLabel(saved.label)
        deadline = saved.deadline
        sessionStartedAt = saved.sessionStartedAt
        lastResumedAt = saved.lastResumedAt
        accumulatedActiveSeconds = max(saved.accumulatedActiveSeconds, 0)
        plannedDurationSeconds = min(
            max(saved.plannedDurationSeconds, 0),
            DurationFormatting.maximumSeconds
        )
        phase = saved.phase

        if phase == .idle {
            remainingSeconds = configuredSeconds
            deadline = nil
            sessionStartedAt = nil
            lastResumedAt = nil
        } else if phase == .paused {
            deadline = nil
            lastResumedAt = nil
            currentSessionElapsedSeconds = Int(accumulatedActiveSeconds.rounded(.down))
        }
    }

    private func persistState() {
        let state = PersistedTimerState(
            phase: phase,
            configuredSeconds: configuredSeconds,
            remainingSeconds: remainingSeconds,
            label: normalizedLabel(currentLabel),
            deadline: deadline,
            sessionStartedAt: sessionStartedAt,
            lastResumedAt: lastResumedAt,
            accumulatedActiveSeconds: accumulatedActiveSeconds,
            plannedDurationSeconds: plannedDurationSeconds
        )
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: Self.stateKey)
        }
    }

    private func resetActiveTimerState() {
        phase = .idle
        remainingSeconds = configuredSeconds
        deadline = nil
        sessionStartedAt = nil
        lastResumedAt = nil
        accumulatedActiveSeconds = 0
        currentSessionElapsedSeconds = 0
    }

    private func normalizedLabel(_ value: String) -> String {
        LabelNormalization.displayLabel(value, fallback: settings.defaultLabel)
    }
}

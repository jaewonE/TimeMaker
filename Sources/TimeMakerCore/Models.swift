import Foundation

public enum TimerPhase: String, Codable, Sendable {
    case idle
    case running
    case paused
}

public enum AppearancePreference: String, Codable, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    public var id: String { rawValue }
}

public struct TimerSession: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let label: String
    public let startedAt: Date
    public let endedAt: Date
    public let durationSeconds: Int

    public init(
        id: UUID = UUID(),
        label: String,
        startedAt: Date,
        endedAt: Date,
        durationSeconds: Int
    ) {
        self.id = id
        self.label = label
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = max(durationSeconds, 0)
    }
}

public struct LabelUsage: Codable, Hashable, Identifiable, Sendable {
    public var id: String { normalizedLabel }
    public let label: String
    public let normalizedLabel: String
    public var count: Int
    public var lastUsedAt: Date

    public init(label: String, count: Int = 1, lastUsedAt: Date = Date()) {
        let displayLabel = LabelNormalization.displayLabel(label)
        self.label = displayLabel
        self.normalizedLabel = LabelNormalization.lookupKey(displayLabel)
        self.count = max(count, 1)
        self.lastUsedAt = lastUsedAt
    }
}

public struct PersistedTimerState: Codable, Sendable {
    public var phase: TimerPhase
    public var configuredSeconds: Int
    public var remainingSeconds: Int
    public var label: String
    public var deadline: Date?
    public var sessionStartedAt: Date?
    public var lastResumedAt: Date?
    public var accumulatedActiveSeconds: TimeInterval
    public var plannedDurationSeconds: Int

    public init(
        phase: TimerPhase,
        configuredSeconds: Int,
        remainingSeconds: Int,
        label: String,
        deadline: Date?,
        sessionStartedAt: Date?,
        lastResumedAt: Date?,
        accumulatedActiveSeconds: TimeInterval,
        plannedDurationSeconds: Int
    ) {
        self.phase = phase
        self.configuredSeconds = configuredSeconds
        self.remainingSeconds = remainingSeconds
        self.label = label
        self.deadline = deadline
        self.sessionStartedAt = sessionStartedAt
        self.lastResumedAt = lastResumedAt
        self.accumulatedActiveSeconds = accumulatedActiveSeconds
        self.plannedDurationSeconds = plannedDurationSeconds
    }
}

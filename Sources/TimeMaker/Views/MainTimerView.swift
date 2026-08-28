import AppKit
import SwiftUI
import TimeMakerCore

struct MainTimerView: View {
    @ObservedObject var timer: TimerStore
    @ObservedObject var history: HistoryStore
    @ObservedObject var settings: SettingsStore
    @ObservedObject var presentation: MainTimerPresentationState

    let onClose: () -> Void
    let onShowAnalytics: () -> Void
    let onShowSettings: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var labelIsFocused: Bool
    @State private var isHovered = false
    @State private var isLabelHovered = false
    @State private var isKeyWindow = true
    @State private var selectedSuggestionIndex: Int?
    @State private var localFocusResetToken = 0

    private let presets = [5, 10, 15, 30, 60, 90]

    private var controlsAreVisible: Bool { isHovered || isKeyWindow }
    private var suggestions: [LabelUsage] {
        guard labelIsFocused else { return [] }
        return timer.suggestions(for: timer.currentLabel)
    }

    var body: some View {
        ZStack {
            panelBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                toolbar
                    .opacity(controlsAreVisible ? 1 : 0)
                    .animation(
                        .easeOut(duration: 0.22).delay(controlsAreVisible ? 0 : 0.35),
                        value: controlsAreVisible
                    )

                labelField
                    .zIndex(20)
                    .padding(.top, 6)

                timerDisplay
                    .padding(.top, 2)

                startPauseButton
                    .padding(.top, 2)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 10)

            WindowKeyStateReader(isKeyWindow: $isKeyWindow)
                .frame(width: 0, height: 0)

            WindowFocusResetter(resetToken: presentation.focusResetToken &+ localFocusResetToken)
                .frame(width: 0, height: 0)
        }
        .frame(width: 360, height: 208)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .topLeading) {
            TodayProgressDots(totalSeconds: timer.todayProgressSeconds())
                .padding(.leading, 14)
                .padding(.top, 124)
                .allowsHitTesting(false)
        }
        .onHover { isHovered = $0 }
        .onAppear(perform: endLabelEditing)
        .onChange(of: presentation.focusResetToken) { _, _ in
            endLabelEditing()
        }
        .onExitCommand(perform: dismissTimer)
    }

    private var panelBackground: some View {
        Group {
            if colorScheme == .dark {
                Color(red: 0.11, green: 0.12, blue: 0.12)
            } else {
                TimeMakerTheme.panelLight
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button(action: dismissTimer) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 17, height: 17)
                    .background(Color.secondary.opacity(0.72), in: Circle())
            }
            .buttonStyle(.plain)
            .help(Text("action.close"))
            .accessibilityLabel(Text("action.close"))

            Spacer()

            Button {
                timer.cancel()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 17, weight: .regular))
                    .frame(width: 25, height: 23)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HoverIconButtonStyle())
            .disabled(timer.phase == .idle)
            .help(Text("action.reset"))
            .accessibilityLabel(Text("action.reset"))

            Button(action: onShowAnalytics) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 17, weight: .regular))
                    .frame(width: 25, height: 23)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HoverIconButtonStyle())
            .help(Text("nav.analytics"))
            .accessibilityLabel(Text("nav.analytics"))

            timerMenu
        }
        .frame(height: 30)
    }

    private var timerMenu: some View {
        Menu {
            Menu {
                ForEach(presets, id: \.self) { minutes in
                    Button {
                        timer.setDuration(minutes: minutes)
                    } label: {
                        if timer.configuredSeconds == minutes * 60, timer.phase == .idle {
                            Label(
                                String(format: NSLocalizedString("menu.minutes", comment: ""), minutes),
                                systemImage: "checkmark"
                            )
                        } else {
                            Text(String(format: NSLocalizedString("menu.minutes", comment: ""), minutes))
                        }
                    }
                }
            } label: {
                Label("menu.timer", systemImage: "timer")
            }
            .disabled(!timer.canChangeDuration)

            Divider()

            Button(action: onShowAnalytics) {
                Label("nav.analytics", systemImage: "chart.bar.xaxis")
            }
            Button(action: onShowSettings) {
                Label("nav.settings", systemImage: "gearshape")
            }

            Divider()

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("action.quit", systemImage: "power")
            }
        } label: {
            Text("⋮")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .frame(width: 23, height: 23)
                .contentShape(Circle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .foregroundStyle(Color.primary.opacity(0.88))
        .help(Text("menu.open"))
        .accessibilityLabel(Text("menu.open"))
    }

    private var labelField: some View {
        TextField("label.placeholder", text: $timer.currentLabel)
            .textFieldStyle(.plain)
            .font(.system(size: 20, weight: .regular, design: .rounded))
            .multilineTextAlignment(.center)
            .focused($labelIsFocused)
            .frame(width: 220, height: 26)
            .padding(.horizontal, 6)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        labelIsFocused
                            ? Color.primary.opacity(0.075)
                            : isLabelHovered ? Color.primary.opacity(0.045) : .clear
                    )
            }
            .overlay(alignment: .top) {
                if !suggestions.isEmpty {
                    suggestionsList
                        .offset(y: 30)
                }
            }
            .onSubmit {
                endLabelEditing()
            }
            .onHover { isLabelHovered = $0 }
            .onChange(of: timer.currentLabel) { _, _ in
                selectedSuggestionIndex = nil
            }
            .onChange(of: labelIsFocused) { _, isFocused in
                if !isFocused {
                    selectedSuggestionIndex = nil
                }
            }
            .onKeyPress(.downArrow) {
                guard !suggestions.isEmpty else { return .ignored }
                moveSuggestionSelection(by: 1)
                return .handled
            }
            .onKeyPress(.upArrow) {
                guard !suggestions.isEmpty else { return .ignored }
                moveSuggestionSelection(by: -1)
                return .handled
            }
            .onKeyPress(.return) {
                if acceptSelectedSuggestion() {
                    return .handled
                }
                endLabelEditing()
                return .handled
            }
            .accessibilityLabel(Text("label.accessibility"))
    }

    private var suggestionsList: some View {
        VStack(spacing: 2) {
            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, usage in
                Button {
                    selectSuggestion(usage)
                } label: {
                    HStack(spacing: 9) {
                        Text(usage.label)
                            .lineLimit(1)
                        Spacer()
                        Text("\(usage.count)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 9)
                    .frame(height: 26)
                    .contentShape(Rectangle())
                    .background(
                        selectedSuggestionIndex == index
                            ? Color.primary.opacity(0.1)
                            : .clear,
                        in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .frame(width: 220)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 12, y: 5)
    }

    private var timerDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            scrollableNumber(
                String(format: "%02d", timer.displayedMinutes),
                accessibilityLabel: "timer.minutes",
                thresholdMultiplier: TimerScrollSensitivity.minutesThresholdMultiplier(
                    for: settings.scrollSensitivity
                )
            ) { direction in
                timer.adjustMinutes(direction: direction, step: settings.scrollStep)
            }

            Text(":")
                .font(timerFont)
                .foregroundStyle(.primary)
                .accessibilityHidden(true)

            scrollableNumber(
                String(format: "%02d", timer.displayedSeconds),
                accessibilityLabel: "timer.seconds",
                thresholdMultiplier: TimerScrollSensitivity.secondsThresholdMultiplier(
                    for: settings.scrollSensitivity
                )
            ) { direction in
                timer.adjustSeconds(direction: direction, step: settings.scrollStep)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.64)
        .frame(maxWidth: 324, minHeight: 70)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("timer.remaining"))
        .accessibilityValue(Text(timer.displayText))
    }

    private var timerFont: Font {
        .system(size: 66, weight: .regular, design: .rounded).monospacedDigit()
    }

    private func scrollableNumber(
        _ value: String,
        accessibilityLabel: LocalizedStringKey,
        thresholdMultiplier: Double,
        onScroll: @escaping (ScrollDirection) -> Void
    ) -> some View {
        Text(value)
            .font(timerFont)
            .foregroundStyle(.primary)
            .contentShape(Rectangle())
            .overlay {
                ScrollWheelMonitor(
                    enabled: timer.canChangeDuration,
                    thresholdMultiplier: thresholdMultiplier,
                    onScroll: onScroll
                )
            }
            .help(timer.canChangeDuration ? Text("timer.scrollHint") : Text("timer.runningHint"))
            .accessibilityLabel(Text(accessibilityLabel))
            .accessibilityValue(Text(value))
    }

    private var startPauseButton: some View {
        Button {
            let newPhase = timer.toggle()
            if newPhase == .running, settings.hideWindowOnStart {
                onClose()
            }
        } label: {
            Image(systemName: timer.phase == .running ? "pause.fill" : "play.fill")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(TimeMakerTheme.accentDark)
                .offset(x: timer.phase == .running ? 0 : 2)
                .frame(width: 41, height: 41)
                .background(TimeMakerTheme.accentSoft.opacity(0.82), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!timer.canStart)
        .help(Text(timer.phase == .running ? "action.pause" : "action.start"))
        .accessibilityLabel(Text(timer.phase == .running ? "action.pause" : "action.start"))
    }

    private func dismissTimer() {
        endLabelEditing()
        onClose()
    }

    private func endLabelEditing() {
        labelIsFocused = false
        selectedSuggestionIndex = nil
        localFocusResetToken &+= 1
    }

    private func moveSuggestionSelection(by offset: Int) {
        let count = suggestions.count
        guard count > 0 else { return }

        let currentIndex: Int
        if let selectedSuggestionIndex {
            currentIndex = selectedSuggestionIndex
        } else {
            currentIndex = offset > 0 ? -1 : 0
        }
        selectedSuggestionIndex = (currentIndex + offset + count) % count
    }

    private func acceptSelectedSuggestion() -> Bool {
        guard let selectedSuggestionIndex,
              suggestions.indices.contains(selectedSuggestionIndex) else {
            return false
        }

        selectSuggestion(suggestions[selectedSuggestionIndex])
        return true
    }

    private func selectSuggestion(_ usage: LabelUsage) {
        timer.currentLabel = usage.label
        endLabelEditing()
    }
}

private struct HoverIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.primary.opacity(0.88))
            .background(
                Color.primary.opacity(configuration.isPressed ? 0.12 : 0),
                in: Circle()
            )
    }
}

private struct WindowFocusResetter: NSViewRepresentable {
    let resetToken: Int

    func makeNSView(context: Context) -> FocusResetView {
        FocusResetView()
    }

    func updateNSView(_ nsView: FocusResetView, context: Context) {
        nsView.resetFocusIfNeeded(for: resetToken)
    }

    final class FocusResetView: NSView {
        private var lastResetToken: Int?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            resetFirstResponder()
        }

        func resetFocusIfNeeded(for token: Int) {
            guard lastResetToken != token else { return }
            lastResetToken = token
            resetFirstResponder()
        }

        private func resetFirstResponder() {
            DispatchQueue.main.async { [weak self] in
                self?.window?.makeFirstResponder(nil)
            }
        }
    }
}

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

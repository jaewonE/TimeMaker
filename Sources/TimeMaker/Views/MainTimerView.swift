import AppKit
import SwiftUI
import TimeMakerCore

struct MainTimerView: View {
    @ObservedObject var timer: TimerStore
    @ObservedObject var history: HistoryStore
    @ObservedObject var settings: SettingsStore

    let onClose: () -> Void
    let onShowAnalytics: () -> Void
    let onShowSettings: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var labelIsFocused: Bool
    @State private var isHovered = false
    @State private var isKeyWindow = true

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

                TodayProgressDots(totalSeconds: timer.todayProgressSeconds())
                    .padding(.top, 4)

                Spacer(minLength: 7)

                startPauseButton

                Spacer(minLength: 12)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)

            WindowKeyStateReader(isKeyWindow: $isKeyWindow)
                .frame(width: 0, height: 0)
        }
        .frame(width: 380, height: 272)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onHover { isHovered = $0 }
        .onExitCommand(perform: onClose)
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
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 21, height: 21)
                    .background(Color.secondary.opacity(0.72), in: Circle())
            }
            .buttonStyle(.plain)
            .help(Text("action.close"))
            .accessibilityLabel(Text("action.close"))

            Spacer()

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
                    .fill(labelIsFocused ? Color.primary.opacity(0.045) : .clear)
            }
            .overlay(alignment: .top) {
                if !suggestions.isEmpty {
                    suggestionsList
                        .offset(y: 30)
                }
            }
            .onSubmit {
                labelIsFocused = false
            }
            .accessibilityLabel(Text("label.accessibility"))
    }

    private var suggestionsList: some View {
        VStack(spacing: 2) {
            ForEach(suggestions) { usage in
                Button {
                    timer.currentLabel = usage.label
                    labelIsFocused = false
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
                accessibilityLabel: "timer.minutes"
            ) { direction in
                timer.adjustMinutes(direction: direction, step: settings.scrollStep)
            }

            Text(":")
                .font(timerFont)
                .foregroundStyle(.primary)
                .accessibilityHidden(true)

            scrollableNumber(
                String(format: "%02d", timer.displayedSeconds),
                accessibilityLabel: "timer.seconds"
            ) { direction in
                timer.adjustSeconds(direction: direction, step: settings.scrollStep)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.64)
        .frame(maxWidth: 344, minHeight: 70)
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
        onScroll: @escaping (ScrollDirection) -> Void
    ) -> some View {
        Text(value)
            .font(timerFont)
            .foregroundStyle(.primary)
            .contentShape(Rectangle())
            .overlay {
                ScrollWheelMonitor(enabled: timer.canChangeDuration, onScroll: onScroll)
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
                .font(.system(size: 21, weight: .regular))
                .foregroundStyle(TimeMakerTheme.accentDark)
                .offset(x: timer.phase == .running ? 0 : 2)
                .frame(width: 58, height: 58)
                .background(TimeMakerTheme.accentSoft.opacity(0.82), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!timer.canStart)
        .help(Text(timer.phase == .running ? "action.pause" : "action.start"))
        .accessibilityLabel(Text(timer.phase == .running ? "action.pause" : "action.start"))
    }
}

private struct HoverIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.secondary.opacity(0.78))
            .background(
                Color.primary.opacity(configuration.isPressed ? 0.12 : 0),
                in: Circle()
            )
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

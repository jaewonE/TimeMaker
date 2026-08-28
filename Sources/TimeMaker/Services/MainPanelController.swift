import AppKit
import SwiftUI

@MainActor
final class MainPanelController: NSWindowController {
    private let timer: TimerStore
    private let presentation = MainTimerPresentationState()
    private var hasPositionedWindow = false

    init(
        timer: TimerStore,
        history: HistoryStore,
        settings: SettingsStore,
        onShowAnalytics: @escaping () -> Void,
        onShowSettings: @escaping () -> Void
    ) {
        self.timer = timer

        let panel = MainPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 208),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.animationBehavior = .utilityWindow

        super.init(window: panel)

        let rootView = MainTimerView(
            timer: timer,
            history: history,
            settings: settings,
            presentation: presentation,
            onClose: { [weak self] in
                self?.closePanel()
            },
            onShowAnalytics: { [weak self] in
                self?.closePanel()
                onShowAnalytics()
            },
            onShowSettings: { [weak self] in
                self?.closePanel()
                onShowSettings()
            }
        )
        panel.contentViewController = NSHostingController(rootView: rootView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var isVisible: Bool { window?.isVisible == true }

    func toggle() {
        if isVisible {
            closePanel()
        } else {
            show()
        }
    }

    func show() {
        guard let panel = window else { return }

        if !hasPositionedWindow {
            panel.center()
            hasPositionedWindow = true
        }

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        presentation.resetLabelInput()
    }

    func closePanel() {
        timer.restoreDefaultLabelIfEmpty()
        presentation.resetLabelInput()
        window?.orderOut(nil)
    }
}

@MainActor
final class MainTimerPresentationState: ObservableObject {
    @Published private(set) var focusResetToken = 0

    func resetLabelInput() {
        focusResetToken &+= 1
    }
}

private final class MainPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

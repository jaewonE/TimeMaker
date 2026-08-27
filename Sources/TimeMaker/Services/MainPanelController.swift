import AppKit
import SwiftUI

@MainActor
final class MainPanelController: NSWindowController {
    private weak var statusButton: NSStatusBarButton?

    init(
        timer: TimerStore,
        history: HistoryStore,
        settings: SettingsStore,
        onShowAnalytics: @escaping () -> Void,
        onShowSettings: @escaping () -> Void
    ) {
        let panel = MainPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 272),
            styleMask: [.borderless, .nonactivatingPanel],
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
        panel.animationBehavior = .utilityWindow

        super.init(window: panel)

        let rootView = MainTimerView(
            timer: timer,
            history: history,
            settings: settings,
            onClose: { [weak panel] in panel?.orderOut(nil) },
            onShowAnalytics: { [weak panel] in
                panel?.orderOut(nil)
                onShowAnalytics()
            },
            onShowSettings: { [weak panel] in
                panel?.orderOut(nil)
                onShowSettings()
            }
        )
        panel.contentViewController = NSHostingController(rootView: rootView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var isVisible: Bool { window?.isVisible == true }

    func toggle(relativeTo button: NSStatusBarButton) {
        if isVisible {
            closePanel()
        } else {
            show(relativeTo: button)
        }
    }

    func show(relativeTo button: NSStatusBarButton) {
        guard let panel = window else { return }
        statusButton = button

        let buttonRectInWindow = button.convert(button.bounds, to: nil)
        let buttonRectOnScreen = button.window?.convertToScreen(buttonRectInWindow) ?? .zero
        let screen = button.window?.screen ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? .zero

        var origin = NSPoint(
            x: buttonRectOnScreen.midX - (panel.frame.width / 2),
            y: buttonRectOnScreen.minY - panel.frame.height - 8
        )
        origin.x = min(max(origin.x, visibleFrame.minX + 8), visibleFrame.maxX - panel.frame.width - 8)
        origin.y = max(origin.y, visibleFrame.minY + 8)
        panel.setFrameOrigin(origin)

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func closePanel() {
        window?.orderOut(nil)
    }
}

private final class MainPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

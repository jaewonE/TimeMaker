import AppKit
import SwiftUI

@MainActor
final class WorkspaceWindowController: NSWindowController, NSWindowDelegate {
    private let navigation: WorkspaceNavigation

    init(
        navigation: WorkspaceNavigation,
        history: HistoryStore,
        settings: SettingsStore
    ) {
        self.navigation = navigation

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "TimeMaker"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unified
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 820, height: 560)
        window.center()

        super.init(window: window)
        window.delegate = self
        window.contentViewController = NSHostingController(rootView: WorkspaceView(
            navigation: navigation,
            history: history,
            settings: settings
        ))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(_ section: WorkspaceSection) {
        navigation.selection = section
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}

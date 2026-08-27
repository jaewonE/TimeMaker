import AppKit
import SwiftUI

@main
struct TimeMakerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let notificationService = NotificationService()
    private lazy var history = HistoryStore()
    private lazy var settings = SettingsStore(notificationService: notificationService)
    private lazy var timer = TimerStore(
        history: history,
        settings: settings,
        notificationService: notificationService
    )
    private let navigation = WorkspaceNavigation()

    private lazy var workspace = WorkspaceWindowController(
        navigation: navigation,
        history: history,
        settings: settings
    )
    private lazy var mainPanel = MainPanelController(
        timer: timer,
        history: history,
        settings: settings,
        onShowAnalytics: { [weak self] in self?.workspace.show(.analytics) },
        onShowSettings: { [weak self] in self?.workspace.show(.settings) }
    )
    private lazy var menuBar = MenuBarController(
        timer: timer,
        mainPanel: mainPanel,
        workspace: workspace
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        let isUITestLaunch = CommandLine.arguments.contains("--ui-test")
        NSApp.setActivationPolicy(isUITestLaunch ? .regular : .accessory)
        _ = menuBar
        settings.prepareSystemIntegrations()

        if isUITestLaunch,
           let durationArgument = CommandLine.arguments.first(where: { $0.hasPrefix("--ui-test-seconds=") }),
           let seconds = Int(durationArgument.split(separator: "=").last ?? ""),
           seconds > 0 {
            timer.setDuration(seconds: seconds)
        }

        if isUITestLaunch || CommandLine.arguments.contains("--show-main") {
            menuBar.showMainPanel()
        } else if CommandLine.arguments.contains("--show-analytics") {
            menuBar.showWorkspace(.analytics)
        } else if CommandLine.arguments.contains("--show-settings") {
            menuBar.showWorkspace(.settings)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

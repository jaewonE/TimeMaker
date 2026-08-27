import AppKit
import Combine
import TimeMakerCore

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let timer: TimerStore
    private let mainPanel: MainPanelController
    private let workspace: WorkspaceWindowController
    private var cancellables: Set<AnyCancellable> = []
    private let presets = [5, 10, 15, 30, 60, 90]

    init(
        timer: TimerStore,
        mainPanel: MainPanelController,
        workspace: WorkspaceWindowController
    ) {
        self.timer = timer
        self.mainPanel = mainPanel
        self.workspace = workspace
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureStatusButton()
        observeTimer()
    }

    private func configureStatusButton() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.toolTip = "TimeMaker"
        button.setAccessibilityLabel(NSLocalizedString("status.accessibility", comment: ""))
        updateStatusTitle()
    }

    func showMainPanel() {
        guard let button = statusItem.button else { return }
        mainPanel.show(relativeTo: button)
    }

    private func observeTimer() {
        Publishers.CombineLatest3(timer.$phase, timer.$configuredSeconds, timer.$remainingSeconds)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.updateStatusTitle()
            }
            .store(in: &cancellables)
    }

    private func updateStatusTitle() {
        guard let button = statusItem.button else { return }
        let title = timer.displayText
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium),
            .baselineOffset: 0
        ]
        button.attributedTitle = NSAttributedString(string: title, attributes: attributes)
        button.setAccessibilityValue(title)
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            mainPanel.toggle(relativeTo: sender)
            return
        }

        if event.type == .rightMouseUp {
            mainPanel.closePanel()
            showContextMenu(from: sender)
        } else {
            mainPanel.toggle(relativeTo: sender)
        }
    }

    private func showContextMenu(from button: NSStatusBarButton) {
        let menu = makeContextMenu()
        menu.delegate = self
        statusItem.menu = menu
        button.performClick(nil)
        statusItem.menu = nil
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let timerItem = NSMenuItem(
            title: NSLocalizedString("menu.timer", comment: ""),
            action: nil,
            keyEquivalent: ""
        )
        let timerSubmenu = NSMenu(title: NSLocalizedString("menu.timer", comment: ""))
        for minutes in presets {
            let item = NSMenuItem(
                title: String(format: NSLocalizedString("menu.minutes", comment: ""), minutes),
                action: #selector(selectPreset(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = minutes
            item.isEnabled = timer.canChangeDuration
            item.state = timer.phase == .idle && timer.configuredSeconds == minutes * 60 ? .on : .off
            timerSubmenu.addItem(item)
        }
        timerItem.submenu = timerSubmenu
        menu.addItem(timerItem)

        menu.addItem(.separator())
        menu.addItem(menuItem(
            titleKey: "nav.analytics",
            action: #selector(showAnalytics),
            imageName: "chart.bar.xaxis"
        ))
        menu.addItem(menuItem(
            titleKey: "nav.settings",
            action: #selector(showSettings),
            imageName: "gearshape"
        ))
        menu.addItem(.separator())
        menu.addItem(menuItem(
            titleKey: "action.quit",
            action: #selector(quit),
            imageName: "power"
        ))
        return menu
    }

    private func menuItem(titleKey: String, action: Selector, imageName: String) -> NSMenuItem {
        let item = NSMenuItem(
            title: NSLocalizedString(titleKey, comment: ""),
            action: action,
            keyEquivalent: ""
        )
        item.target = self
        item.image = NSImage(systemSymbolName: imageName, accessibilityDescription: nil)
        item.isEnabled = true
        return item
    }

    @objc private func selectPreset(_ sender: NSMenuItem) {
        guard let minutes = sender.representedObject as? Int else { return }
        timer.setDuration(minutes: minutes)
    }

    @objc private func showAnalytics() {
        workspace.show(.analytics)
    }

    @objc private func showSettings() {
        workspace.show(.settings)
    }

    func showWorkspace(_ section: WorkspaceSection) {
        workspace.show(section)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

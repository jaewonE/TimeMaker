import AppKit
import Combine
import TimeMakerCore

@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let timer: TimerStore
    private let mainPanel: MainPanelController
    private let workspace: WorkspaceWindowController
    private var cancellables: Set<AnyCancellable> = []

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
        mainPanel.show()
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
            mainPanel.toggle()
            return
        }

        if event.type == .rightMouseUp {
            _ = timer.toggle()
        } else {
            mainPanel.toggle()
        }
    }

    func showWorkspace(_ section: WorkspaceSection) {
        workspace.show(section)
    }

}

import AppKit
import Foundation
import UserNotifications

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    private static let completionSound = NSSound(
        contentsOf: URL(fileURLWithPath: "/System/Library/Sounds/Glass.aiff"),
        byReference: true
    )

    var onNotificationClicked: (() -> Void)?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorizationIfNeeded(
        enabled: Bool,
        completion: (() -> Void)? = nil
    ) {
        guard enabled else {
            completion?()
            return
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, error in
            if let error {
                NSLog("TimeMaker notification authorization failed: %@", error.localizedDescription)
            }
            completion?()
        }
    }

    func getAuthorizationStatus(_ completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus)
        }
    }

    func deliverCompletion(label: String, enabled: Bool, soundEnabled: Bool) {
        guard enabled else { return }

        if soundEnabled {
            DispatchQueue.main.async {
                if Self.completionSound?.play() != true {
                    NSSound.beep()
                }
            }
        }

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.completed.title", comment: "")
        content.body = String(
            format: NSLocalizedString("notification.completed.body", comment: ""),
            label
        )
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: "timer-complete-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                NSLog("TimeMaker notification delivery failed: %@", error.localizedDescription)
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            DispatchQueue.main.async { [weak self] in
                self?.onNotificationClicked?()
            }
        }
        completionHandler()
    }
}

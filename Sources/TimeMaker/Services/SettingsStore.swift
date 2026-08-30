import AppKit
import Combine
import Foundation
import ServiceManagement
import TimeMakerCore
import UserNotifications

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var scrollStep: Int
    @Published private(set) var scrollSensitivity: ScrollSensitivity
    @Published private(set) var allowActiveTimerScrollAdjustment: Bool
    @Published private(set) var launchAtLogin: Bool
    @Published private(set) var hideWindowOnStart: Bool
    @Published private(set) var countCancelledTimerTime: Bool
    @Published private(set) var defaultLabel: String
    @Published private(set) var appearance: AppearancePreference
    @Published private(set) var notificationsEnabled: Bool
    @Published private(set) var notificationSoundEnabled: Bool
    @Published private(set) var loginItemStatusText: String = ""
    @Published private(set) var notificationStatusText: String = ""

    private enum Key {
        static let scrollStep = "settings.scrollStep"
        static let scrollSensitivity = "settings.scrollSensitivity"
        static let allowActiveTimerScrollAdjustment = "settings.allowActiveTimerScrollAdjustment"
        static let legacyScrollDistance = "settings.scrollDistance"
        static let launchAtLogin = "settings.launchAtLogin"
        static let hideWindowOnStart = "settings.hideWindowOnStart"
        static let countCancelledTimerTime = "settings.countCancelledTimerTime"
        static let defaultLabel = "settings.defaultLabel"
        static let appearance = "settings.appearance"
        static let notificationsEnabled = "settings.notificationsEnabled"
        static let notificationSoundEnabled = "settings.notificationSoundEnabled"
    }

    private let defaults: UserDefaults
    private let notificationService: NotificationService

    init(
        defaults: UserDefaults = .standard,
        notificationService: NotificationService
    ) {
        self.defaults = defaults
        self.notificationService = notificationService

        // Read persisted values before registering defaults so a v1.0.3 custom
        // distance can be migrated without mistaking the registered 1× default
        // for an explicitly selected value.
        let storedSensitivity = defaults.object(forKey: Key.scrollSensitivity) as? NSNumber
        let legacyScrollDistance = defaults.object(forKey: Key.legacyScrollDistance) as? NSNumber

        defaults.register(defaults: [
            Key.scrollStep: 5,
            Key.scrollSensitivity: ScrollSensitivity.one.rawValue,
            Key.allowActiveTimerScrollAdjustment:
                TimerScrollAdjustmentPolicy.defaultAllowsActiveAdjustment,
            Key.launchAtLogin: true,
            Key.hideWindowOnStart: true,
            Key.countCancelledTimerTime: false,
            Key.defaultLabel: LabelNormalization.fallbackLabel,
            Key.appearance: AppearancePreference.system.rawValue,
            Key.notificationsEnabled: true,
            Key.notificationSoundEnabled: false
        ])

        scrollStep = min(max(defaults.integer(forKey: Key.scrollStep), 1), 60)
        if let storedSensitivity {
            scrollSensitivity = ScrollSensitivity.closest(to: storedSensitivity.doubleValue)
        } else if let legacyScrollDistance {
            let migratedSensitivity = ScrollSensitivity.closest(to: legacyScrollDistance.doubleValue)
            scrollSensitivity = migratedSensitivity
            defaults.set(migratedSensitivity.rawValue, forKey: Key.scrollSensitivity)
        } else {
            scrollSensitivity = .one
        }
        allowActiveTimerScrollAdjustment = defaults.bool(
            forKey: Key.allowActiveTimerScrollAdjustment
        )
        launchAtLogin = defaults.bool(forKey: Key.launchAtLogin)
        hideWindowOnStart = defaults.bool(forKey: Key.hideWindowOnStart)
        countCancelledTimerTime = defaults.bool(forKey: Key.countCancelledTimerTime)
        defaultLabel = LabelNormalization.displayLabel(
            defaults.string(forKey: Key.defaultLabel) ?? LabelNormalization.fallbackLabel
        )
        appearance = AppearancePreference(
            rawValue: defaults.string(forKey: Key.appearance) ?? "system"
        ) ?? .system
        notificationsEnabled = defaults.bool(forKey: Key.notificationsEnabled)
        notificationSoundEnabled = defaults.bool(forKey: Key.notificationSoundEnabled)
    }

    func prepareSystemIntegrations() {
        applyAppearance()
        notificationService.requestAuthorizationIfNeeded(enabled: notificationsEnabled) { [weak self] in
            self?.refreshNotificationStatus()
        }
        synchronizeLoginItem()
    }

    func updateScrollStep(_ value: Int) {
        scrollStep = min(max(value, 1), 60)
        defaults.set(scrollStep, forKey: Key.scrollStep)
    }

    func updateScrollSensitivity(_ value: ScrollSensitivity) {
        scrollSensitivity = value
        defaults.set(value.rawValue, forKey: Key.scrollSensitivity)
    }

    func updateAllowActiveTimerScrollAdjustment(_ enabled: Bool) {
        allowActiveTimerScrollAdjustment = enabled
        defaults.set(enabled, forKey: Key.allowActiveTimerScrollAdjustment)
    }

    func updateLaunchAtLogin(_ enabled: Bool) {
        launchAtLogin = enabled
        defaults.set(enabled, forKey: Key.launchAtLogin)
        synchronizeLoginItem()
    }

    func updateHideWindowOnStart(_ enabled: Bool) {
        hideWindowOnStart = enabled
        defaults.set(enabled, forKey: Key.hideWindowOnStart)
    }

    func updateCountCancelledTimerTime(_ enabled: Bool) {
        countCancelledTimerTime = enabled
        defaults.set(enabled, forKey: Key.countCancelledTimerTime)
    }

    func updateDefaultLabel(_ value: String) {
        defaultLabel = LabelNormalization.displayLabel(value)
        defaults.set(defaultLabel, forKey: Key.defaultLabel)
    }

    func updateAppearance(_ value: AppearancePreference) {
        appearance = value
        defaults.set(value.rawValue, forKey: Key.appearance)
        applyAppearance()
    }

    func updateNotificationsEnabled(_ enabled: Bool) {
        notificationsEnabled = enabled
        defaults.set(enabled, forKey: Key.notificationsEnabled)
        notificationService.requestAuthorizationIfNeeded(enabled: enabled) { [weak self] in
            self?.refreshNotificationStatus()
        }
    }

    func updateNotificationSoundEnabled(_ enabled: Bool) {
        notificationSoundEnabled = enabled
        defaults.set(enabled, forKey: Key.notificationSoundEnabled)
    }

    private func applyAppearance() {
        switch appearance {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    private func synchronizeLoginItem() {
        guard Bundle.main.bundleURL.pathExtension == "app" else {
            loginItemStatusText = NSLocalizedString("settings.login.requiresApp", comment: "")
            return
        }

        let service = SMAppService.mainApp
        do {
            if launchAtLogin,
               service.status != .enabled,
               service.status != .requiresApproval {
                try service.register()
            } else if !launchAtLogin, service.status == .enabled || service.status == .requiresApproval {
                try service.unregister()
            }
            updateLoginItemStatus(service.status)
        } catch {
            loginItemStatusText = error.localizedDescription
        }
    }

    private func updateLoginItemStatus(_ status: SMAppService.Status) {
        switch status {
        case .enabled:
            loginItemStatusText = NSLocalizedString("settings.login.enabled", comment: "")
        case .requiresApproval:
            loginItemStatusText = NSLocalizedString("settings.login.requiresApproval", comment: "")
        case .notRegistered:
            loginItemStatusText = NSLocalizedString("settings.login.disabled", comment: "")
        case .notFound:
            loginItemStatusText = NSLocalizedString("settings.login.notFound", comment: "")
        @unknown default:
            loginItemStatusText = NSLocalizedString("settings.login.unknown", comment: "")
        }
    }

    private func refreshNotificationStatus() {
        notificationService.getAuthorizationStatus { [weak self] status in
            DispatchQueue.main.async {
                guard let self else { return }
                switch status {
                case .authorized, .provisional, .ephemeral:
                    self.notificationStatusText = NSLocalizedString(
                        "settings.notifications.authorized",
                        comment: ""
                    )
                case .denied:
                    self.notificationStatusText = NSLocalizedString(
                        "settings.notifications.denied",
                        comment: ""
                    )
                case .notDetermined:
                    self.notificationStatusText = NSLocalizedString(
                        "settings.notifications.notDetermined",
                        comment: ""
                    )
                @unknown default:
                    self.notificationStatusText = NSLocalizedString(
                        "settings.notifications.unknown",
                        comment: ""
                    )
                }
            }
        }
    }
}

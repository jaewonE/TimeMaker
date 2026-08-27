import ServiceManagement
import SwiftUI
import TimeMakerCore

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                SettingsGroup(title: "settings.timer.title") {
                    SettingRow(
                        title: "settings.scrollStep",
                        description: "settings.scrollStep.description"
                    ) {
                        Stepper(
                            value: Binding(
                                get: { settings.scrollStep },
                                set: settings.updateScrollStep
                            ),
                            in: 1...60
                        ) {
                            Text(String(
                                format: NSLocalizedString("settings.minutes.value", comment: ""),
                                settings.scrollStep
                            ))
                            .monospacedDigit()
                            .frame(minWidth: 46, alignment: .trailing)
                        }
                        .labelsHidden()
                    }

                    Divider()

                    SettingRow(
                        title: "settings.hideOnStart",
                        description: "settings.hideOnStart.description"
                    ) {
                        Toggle("", isOn: Binding(
                            get: { settings.hideWindowOnStart },
                            set: settings.updateHideWindowOnStart
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                    }
                }

                SettingsGroup(title: "settings.system.title") {
                    SettingRow(
                        title: "settings.launchAtLogin",
                        description: "settings.launchAtLogin.description"
                    ) {
                        Toggle("", isOn: Binding(
                            get: { settings.launchAtLogin },
                            set: settings.updateLaunchAtLogin
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                    }

                    if !settings.loginItemStatusText.isEmpty {
                        Text(settings.loginItemStatusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Divider()

                    SettingRow(
                        title: "settings.notifications",
                        description: "settings.notifications.description"
                    ) {
                        Toggle("", isOn: Binding(
                            get: { settings.notificationsEnabled },
                            set: settings.updateNotificationsEnabled
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                    }

                    if !settings.notificationStatusText.isEmpty {
                        Text(settings.notificationStatusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                SettingsGroup(title: "settings.appearance.title") {
                    SettingRow(
                        title: "settings.darkMode",
                        description: "settings.darkMode.description"
                    ) {
                        Picker("", selection: Binding(
                            get: { settings.appearance },
                            set: settings.updateAppearance
                        )) {
                            Text("settings.appearance.system").tag(AppearancePreference.system)
                            Text("settings.appearance.light").tag(AppearancePreference.light)
                            Text("settings.appearance.dark").tag(AppearancePreference.dark)
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(width: 225)
                    }
                }

                if let error = settingsError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(28)
        }
        .navigationTitle(Text("nav.settings"))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("settings.title")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text("settings.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var settingsError: String? { nil }
}

private struct SettingsGroup<Content: View>: View {
    let title: LocalizedStringKey
    let content: Content

    init(title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            VStack(spacing: 14) {
                content
            }
            .padding(18)
            .timeMakerCard()
        }
    }
}

private struct SettingRow<Accessory: View>: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let accessory: Accessory

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.description = description
        self.accessory = accessory()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 18)
            accessory
        }
    }
}

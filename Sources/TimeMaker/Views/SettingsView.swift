import ServiceManagement
import SwiftUI
import TimeMakerCore

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var history: HistoryStore

    @State private var pendingHistoryClearPeriod: HistoryClearPeriod?
    @State private var isShowingHistoryClearConfirmation = false
    @State private var historyClearResult: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                SettingsGroup(title: "settings.timer.title") {
                    SettingRow(
                        title: "settings.scrollStep",
                        description: "settings.scrollStep.description"
                    ) {
                        HStack(spacing: 8) {
                            Text(String(
                                format: NSLocalizedString("settings.scrollStep.value", comment: ""),
                                settings.scrollStep
                            ))
                            .monospacedDigit()
                            .frame(width: 34, alignment: .trailing)

                            Stepper("", value: Binding(
                                get: { settings.scrollStep },
                                set: settings.updateScrollStep
                            ), in: 1...60)
                            .labelsHidden()
                        }
                    }

                    Divider()

                    SettingRow(
                        title: "settings.scrollSensitivity",
                        description: "settings.scrollSensitivity.description"
                    ) {
                        ScrollSensitivitySlider(sensitivity: Binding(
                            get: { settings.scrollSensitivity },
                            set: settings.updateScrollSensitivity
                        ))
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

                    Divider()

                    SettingRow(
                        title: "settings.countCancelledTime",
                        description: "settings.countCancelledTime.description"
                    ) {
                        Toggle("", isOn: Binding(
                            get: { settings.countCancelledTimerTime },
                            set: settings.updateCountCancelledTimerTime
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                    }
                }

                SettingsGroup(title: "settings.labels.title") {
                    SettingRow(
                        title: "settings.defaultLabel",
                        description: "settings.defaultLabel.description"
                    ) {
                        DefaultLabelField(settings: settings)
                    }

                    Divider()

                    SettingRow(
                        title: "settings.clearHistory",
                        description: "settings.clearHistory.description"
                    ) {
                        Menu {
                            ForEach(HistoryClearPeriod.allCases) { period in
                                Button(historyClearPeriodTitle(period)) {
                                    pendingHistoryClearPeriod = period
                                    isShowingHistoryClearConfirmation = true
                                }
                            }
                        } label: {
                            Label("settings.clearHistory.choose", systemImage: "trash")
                        }
                        .menuStyle(.borderlessButton)
                    }

                    if let historyClearResult {
                        Text(historyClearResult)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
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

                    Divider()

                    SettingRow(
                        title: "settings.notificationsSound",
                        description: "settings.notificationsSound.description"
                    ) {
                        Toggle("", isOn: Binding(
                            get: { settings.notificationSoundEnabled },
                            set: settings.updateNotificationSoundEnabled
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .disabled(!settings.notificationsEnabled)
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
        .confirmationDialog(
            historyClearConfirmationTitle,
            isPresented: $isShowingHistoryClearConfirmation,
            titleVisibility: .visible
        ) {
            if pendingHistoryClearPeriod != nil {
                Button(historyClearActionTitle, role: .destructive) {
                    clearHistory()
                }
            }
            Button("action.cancel", role: .cancel) {
                pendingHistoryClearPeriod = nil
            }
        } message: {
            Text(historyClearConfirmationMessage)
        }
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

    private var historyClearConfirmationTitle: String {
        NSLocalizedString("settings.clearHistory.confirmation.title", comment: "")
    }

    private var historyClearConfirmationMessage: String {
        guard let period = pendingHistoryClearPeriod else { return "" }
        return String(
            format: NSLocalizedString("settings.clearHistory.confirmation.message", comment: ""),
            historyClearPeriodTitle(period)
        )
    }

    private var historyClearActionTitle: String {
        guard let period = pendingHistoryClearPeriod else { return "" }
        return String(
            format: NSLocalizedString("settings.clearHistory.action", comment: ""),
            historyClearPeriodTitle(period)
        )
    }

    private func historyClearPeriodTitle(_ period: HistoryClearPeriod) -> String {
        NSLocalizedString("settings.clearHistory.period.\(period.rawValue)", comment: "")
    }

    private func clearHistory() {
        guard let period = pendingHistoryClearPeriod else { return }
        let removedCount = history.clearTimerRecords(in: period)
        historyClearResult = String(
            format: NSLocalizedString("settings.clearHistory.result", comment: ""),
            removedCount
        )
        pendingHistoryClearPeriod = nil
    }
}

private struct DefaultLabelField: View {
    @ObservedObject var settings: SettingsStore
    @State private var draft = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("label.placeholder", text: $draft)
            .textFieldStyle(.roundedBorder)
            .frame(width: 190)
            .focused($isFocused)
            .onSubmit {
                commit()
                isFocused = false
            }
            .onChange(of: isFocused) { _, focused in
                if !focused {
                    commit()
                }
            }
            .onChange(of: settings.defaultLabel) { _, value in
                if !isFocused {
                    draft = value
                }
            }
            .onAppear {
                draft = settings.defaultLabel
            }
            .accessibilityLabel(Text("settings.defaultLabel"))
    }

    private func commit() {
        settings.updateDefaultLabel(draft)
        draft = settings.defaultLabel
    }
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

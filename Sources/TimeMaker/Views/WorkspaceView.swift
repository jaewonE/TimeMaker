import SwiftUI

struct WorkspaceView: View {
    @ObservedObject var navigation: WorkspaceNavigation
    @ObservedObject var history: HistoryStore
    @ObservedObject var settings: SettingsStore

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 196)

            Divider()

            Group {
                switch navigation.selection {
                case .analytics:
                    AnalyticsView(history: history)
                case .settings:
                    SettingsView(settings: settings)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 820, minHeight: 560)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("app.name")
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .padding(.horizontal, 13)
                .padding(.bottom, 14)

            sidebarButton(
                section: .analytics,
                title: "nav.analytics",
                systemImage: "chart.bar.xaxis"
            )
            sidebarButton(
                section: .settings,
                title: "nav.settings",
                systemImage: "gearshape"
            )

            Spacer()

            Text("sidebar.localData")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 13)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 9)
        .background(.ultraThinMaterial)
    }

    private func sidebarButton(
        section: WorkspaceSection,
        title: LocalizedStringKey,
        systemImage: String
    ) -> some View {
        Button {
            navigation.selection = section
        } label: {
            Label(title, systemImage: systemImage)
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 11)
                .frame(height: 36)
                .background(
                    navigation.selection == section
                        ? TimeMakerTheme.accent.opacity(0.18)
                        : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

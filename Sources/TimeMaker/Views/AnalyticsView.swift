import Charts
import SwiftUI
import TimeMakerCore

struct AnalyticsView: View {
    @ObservedObject var history: HistoryStore

    private var snapshot: AnalyticsSnapshot {
        AnalyticsBuilder.snapshot(sessions: history.sessions)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                summaryCards
                charts
                recentSessions
            }
            .padding(28)
        }
        .navigationTitle(Text("nav.analytics"))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("analytics.title")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text("analytics.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "analytics.today",
                value: DurationFormatting.compact(snapshot.todaySeconds),
                detail: String(
                    format: NSLocalizedString("analytics.sessions.value", comment: ""),
                    snapshot.todaySessionCount
                ),
                systemImage: "sun.max"
            )
            SummaryCard(
                title: "analytics.thisWeek",
                value: DurationFormatting.compact(snapshot.weekSeconds),
                detail: String(
                    format: NSLocalizedString("analytics.average.value", comment: ""),
                    DurationFormatting.compact(snapshot.dailyAverageSeconds)
                ),
                systemImage: "calendar"
            )
            SummaryCard(
                title: "analytics.streak",
                value: String(
                    format: NSLocalizedString("analytics.days.value", comment: ""),
                    snapshot.currentStreak
                ),
                detail: snapshot.mostUsedLabel ?? NSLocalizedString("analytics.noActivity", comment: ""),
                systemImage: "flame"
            )
        }
    }

    private var charts: some View {
        HStack(alignment: .top, spacing: 14) {
            weeklyChart
                .frame(maxWidth: .infinity)
            activityChart
                .frame(width: 245)
        }
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("analytics.lastSevenDays")
                .font(.headline)

            Chart(snapshot.daily) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Minutes", Double(day.totalSeconds) / 60)
                )
                .foregroundStyle(TimeMakerTheme.accent.gradient)
                .cornerRadius(4)
                .accessibilityLabel(day.date.formatted(date: .abbreviated, time: .omitted))
                .accessibilityValue("\(day.totalSeconds / 60) min")
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                    AxisGridLine().foregroundStyle(.clear)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let minutes = value.as(Double.self) {
                            Text("\(Int(minutes))m")
                        }
                    }
                }
            }
            .frame(height: 190)
        }
        .padding(18)
        .timeMakerCard()
    }

    private var activityChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("analytics.activities")
                .font(.headline)

            if snapshot.activities.isEmpty {
                ContentUnavailableView(
                    "analytics.empty.title",
                    systemImage: "chart.pie",
                    description: Text("analytics.empty.description")
                )
                .frame(height: 190)
            } else {
                ZStack {
                    Chart(Array(snapshot.activities.prefix(6))) { activity in
                        SectorMark(
                            angle: .value("Minutes", activity.totalSeconds),
                            innerRadius: .ratio(0.62),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Activity", activity.label))
                        .cornerRadius(3)
                    }
                    .chartLegend(position: .bottom, alignment: .leading, spacing: 7)

                    VStack(spacing: 2) {
                        Text(DurationFormatting.compact(snapshot.weekSeconds))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("analytics.focus")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .offset(y: -12)
                }
                .frame(height: 190)
            }
        }
        .padding(18)
        .timeMakerCard()
    }

    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("analytics.recentSessions")
                .font(.headline)

            if history.sessions.isEmpty {
                HStack {
                    Spacer()
                    ContentUnavailableView(
                        "analytics.empty.title",
                        systemImage: "timer",
                        description: Text("analytics.empty.description")
                    )
                    Spacer()
                }
                .padding(.vertical, 16)
            } else {
                ForEach(Array(history.sessions.prefix(8))) { session in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(TimeMakerTheme.accentSoft)
                            .frame(width: 9, height: 9)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.label)
                                .fontWeight(.medium)
                            Text(session.endedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(DurationFormatting.compact(session.durationSeconds))
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .monospacedDigit()
                    }
                    .padding(.vertical, 5)

                    if session.id != history.sessions.prefix(8).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(18)
        .timeMakerCard()
    }
}

private struct SummaryCard: View {
    let title: LocalizedStringKey
    let value: String
    let detail: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: systemImage)
                    .foregroundStyle(TimeMakerTheme.accentDark)
            }

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .timeMakerCard()
    }
}

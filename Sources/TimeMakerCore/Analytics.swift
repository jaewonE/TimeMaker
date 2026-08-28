import Foundation

public struct DailyFocus: Identifiable, Hashable, Sendable {
    public var id: Date { date }
    public let date: Date
    public let totalSeconds: Int
    public let sessionCount: Int

    public init(date: Date, totalSeconds: Int, sessionCount: Int) {
        self.date = date
        self.totalSeconds = totalSeconds
        self.sessionCount = sessionCount
    }
}

public struct ActivityFocus: Identifiable, Hashable, Sendable {
    public var id: String { label }
    public let label: String
    public let totalSeconds: Int
    public let sessionCount: Int

    public init(label: String, totalSeconds: Int, sessionCount: Int) {
        self.label = label
        self.totalSeconds = totalSeconds
        self.sessionCount = sessionCount
    }
}

public struct AnalyticsSnapshot: Sendable {
    public let todaySeconds: Int
    public let todaySessionCount: Int
    public let weekSeconds: Int
    public let dailyAverageSeconds: Int
    public let currentStreak: Int
    public let mostUsedLabel: String?
    public let daily: [DailyFocus]
    public let activities: [ActivityFocus]

    public init(
        todaySeconds: Int,
        todaySessionCount: Int,
        weekSeconds: Int,
        dailyAverageSeconds: Int,
        currentStreak: Int,
        mostUsedLabel: String?,
        daily: [DailyFocus],
        activities: [ActivityFocus]
    ) {
        self.todaySeconds = todaySeconds
        self.todaySessionCount = todaySessionCount
        self.weekSeconds = weekSeconds
        self.dailyAverageSeconds = dailyAverageSeconds
        self.currentStreak = currentStreak
        self.mostUsedLabel = mostUsedLabel
        self.daily = daily
        self.activities = activities
    }
}

public enum AnalyticsBuilder {
    public static func snapshot(
        sessions: [TimerSession],
        now: Date = Date(),
        calendar: Calendar = .current,
        dayCount: Int = 7
    ) -> AnalyticsSnapshot {
        let safeDayCount = max(dayCount, 1)
        let today = calendar.startOfDay(for: now)
        let startDate = calendar.date(byAdding: .day, value: -(safeDayCount - 1), to: today) ?? today
        let relevantSessions = sessions.filter { $0.endedAt >= startDate && $0.endedAt <= now }

        let daily = (0..<safeDayCount).compactMap { offset -> DailyFocus? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: startDate),
                  let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
                return nil
            }
            let matches = relevantSessions.filter { $0.endedAt >= day && $0.endedAt < nextDay }
            return DailyFocus(
                date: day,
                totalSeconds: matches.reduce(0) { $0 + $1.durationSeconds },
                sessionCount: matches.count
            )
        }

        let todayFocus = daily.last ?? DailyFocus(date: today, totalSeconds: 0, sessionCount: 0)
        let weekSeconds = daily.reduce(0) { $0 + $1.totalSeconds }
        let activeDayCount = max(daily.filter { $0.totalSeconds > 0 }.count, 1)

        let activityGroups = Dictionary(grouping: relevantSessions) { session in
            LabelNormalization.lookupKey(session.label)
        }
        let activities = activityGroups.values.map { group in
            let displayLabel = group
                .max(by: { $0.endedAt < $1.endedAt })
                .map { LabelNormalization.displayLabel($0.label) }
                ?? LabelNormalization.fallbackLabel
            return ActivityFocus(
                label: displayLabel,
                totalSeconds: group.reduce(0) { $0 + $1.durationSeconds },
                sessionCount: group.count
            )
        }
        .sorted { lhs, rhs in
            if lhs.totalSeconds != rhs.totalSeconds {
                return lhs.totalSeconds > rhs.totalSeconds
            }
            return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
        }

        let allActiveDays = Set(sessions.map { calendar.startOfDay(for: $0.endedAt) })
        let streak = calculateStreak(activeDays: allActiveDays, today: today, calendar: calendar)

        return AnalyticsSnapshot(
            todaySeconds: todayFocus.totalSeconds,
            todaySessionCount: todayFocus.sessionCount,
            weekSeconds: weekSeconds,
            dailyAverageSeconds: weekSeconds / activeDayCount,
            currentStreak: streak,
            mostUsedLabel: activities.first?.label,
            daily: daily,
            activities: activities
        )
    }

    private static func calculateStreak(
        activeDays: Set<Date>,
        today: Date,
        calendar: Calendar
    ) -> Int {
        guard !activeDays.isEmpty else { return 0 }

        var cursor = today
        if !activeDays.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  activeDays.contains(yesterday) else {
                return 0
            }
            cursor = yesterday
        }

        var streak = 0
        while activeDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }
        return streak
    }
}

import XCTest
@testable import TimeMakerCore

final class TimeMakerCoreTests: XCTestCase {
    func testTimerFormattingKeepsMinutesAboveOneHour() {
        XCTAssertEqual(DurationFormatting.timer(90 * 60), "90:00")
        XCTAssertEqual(DurationFormatting.timer((123 * 60) + 7), "123:07")
        XCTAssertEqual(DurationFormatting.timer(DurationFormatting.maximumSeconds + 100), "1440:00")
    }

    func testMinuteScrollingUsesConfiguredStepAndWraps() {
        XCTAssertEqual(
            TimerAdjustment.minutes(in: 30 * 60, direction: .increase, step: 5),
            35 * 60
        )
        XCTAssertEqual(
            TimerAdjustment.minutes(in: 2 * 60, direction: .decrease, step: 5),
            1_438 * 60
        )
        XCTAssertEqual(
            TimerAdjustment.minutes(
                in: DurationFormatting.maximumSeconds,
                direction: .increase,
                step: 1
            ),
            0
        )
    }

    func testSecondScrollingWrapsWithoutChangingMinutes() {
        XCTAssertEqual(
            TimerAdjustment.seconds(in: (30 * 60) + 58, direction: .increase, step: 5),
            (30 * 60) + 3
        )
        XCTAssertEqual(
            TimerAdjustment.seconds(in: (30 * 60) + 2, direction: .decrease, step: 5),
            (30 * 60) + 57
        )
    }

    func testSuggestionsMatchSubstringAndRankByFrequency() {
        let now = Date(timeIntervalSince1970: 10_000)
        let usages = [
            LabelUsage(label: "Deep Work", count: 3, lastUsedAt: now),
            LabelUsage(label: "Writing", count: 9, lastUsedAt: now),
            LabelUsage(label: "Weekly Review", count: 7, lastUsedAt: now.addingTimeInterval(-100))
        ]

        let results = LabelSuggestions.matching("w", usages: usages)

        XCTAssertEqual(results.map(\.label), ["Writing", "Weekly Review", "Deep Work"])
    }

    func testAnalyticsBuildsDailyTotalsActivitiesAndStreak() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let formatter = ISO8601DateFormatter()
        let now = try XCTUnwrap(formatter.date(from: "2026-08-27T12:00:00Z"))
        let yesterday = try XCTUnwrap(formatter.date(from: "2026-08-26T12:00:00Z"))
        let twoDaysAgo = try XCTUnwrap(formatter.date(from: "2026-08-25T12:00:00Z"))

        let sessions = [
            TimerSession(
                label: "Work",
                startedAt: now.addingTimeInterval(-1_800),
                endedAt: now,
                durationSeconds: 1_800
            ),
            TimerSession(
                label: "Writing",
                startedAt: yesterday.addingTimeInterval(-3_600),
                endedAt: yesterday,
                durationSeconds: 3_600
            ),
            TimerSession(
                label: "Work",
                startedAt: twoDaysAgo.addingTimeInterval(-1_800),
                endedAt: twoDaysAgo,
                durationSeconds: 1_800
            )
        ]

        let snapshot = AnalyticsBuilder.snapshot(
            sessions: sessions,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.todaySeconds, 1_800)
        XCTAssertEqual(snapshot.weekSeconds, 7_200)
        XCTAssertEqual(snapshot.currentStreak, 3)
        XCTAssertEqual(snapshot.activities.first?.label, "Work")
        XCTAssertEqual(snapshot.activities.first?.totalSeconds, 3_600)
    }
}

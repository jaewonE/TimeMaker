import XCTest
@testable import TimeMakerCore

final class TimeMakerCoreTests: XCTestCase {
    func testTimerFormattingKeepsMinutesAboveOneHour() {
        XCTAssertEqual(DurationFormatting.timer(90 * 60), "90:00")
        XCTAssertEqual(DurationFormatting.timer((123 * 60) + 7), "123:07")
        XCTAssertEqual(DurationFormatting.timer(DurationFormatting.maximumSeconds + 100), "1440:00")
    }

    func testMinuteScrollingUsesConfiguredStepAndStopsAtBounds() {
        XCTAssertEqual(
            TimerAdjustment.minutes(in: 30 * 60, direction: .increase, step: 5),
            35 * 60
        )
        XCTAssertEqual(
            TimerAdjustment.minutes(in: 2 * 60, direction: .decrease, step: 5),
            0
        )
        XCTAssertEqual(
            TimerAdjustment.minutes(in: 30, direction: .decrease, step: 5),
            30
        )
        XCTAssertEqual(
            TimerAdjustment.minutes(
                in: DurationFormatting.maximumSeconds,
                direction: .increase,
                step: 1
            ),
            DurationFormatting.maximumSeconds
        )
    }

    func testScrollDistanceUsesDifferentMinuteAndSecondThresholds() {
        XCTAssertEqual(TimerScrollDistance.minutesThresholdMultiplier(from: 1), 4)
        XCTAssertEqual(TimerScrollDistance.secondsThresholdMultiplier(from: 1), 2)
        XCTAssertEqual(TimerScrollDistance.minutesThresholdMultiplier(from: 3), 12)
        XCTAssertEqual(TimerScrollDistance.secondsThresholdMultiplier(from: 3), 6)
        XCTAssertEqual(
            TimerAdjustment.minutes(
                in: 30 * 60,
                direction: .increase,
                step: 1
            ),
            31 * 60
        )
        XCTAssertEqual(
            TimerAdjustment.seconds(
                in: 30 * 60,
                direction: .increase,
                step: 1
            ),
            (30 * 60) + 1
        )
    }

    func testProgressDotsUseAtMostEightVerticalRows() {
        XCTAssertEqual(ProgressDotLayout.rowCount(for: 24), 8)
        XCTAssertEqual(ProgressDotLayout.columnCount(for: 24), 3)
        XCTAssertEqual(ProgressDotLayout.rowCount(for: 9), 8)
        XCTAssertEqual(ProgressDotLayout.columnCount(for: 9), 2)
    }

    func testHistoryClearPeriodsUseOnlyTheRequestedRecentRange() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-08-28T12:00:00Z"))

        XCTAssertTrue(
            HistoryClearPeriod.oneDay.includes(
                now.addingTimeInterval(-86_400),
                relativeTo: now,
                calendar: calendar
            )
        )
        XCTAssertFalse(
            HistoryClearPeriod.oneDay.includes(
                now.addingTimeInterval(-86_401),
                relativeTo: now,
                calendar: calendar
            )
        )
        XCTAssertTrue(
            HistoryClearPeriod.threeMonths.includes(
                try XCTUnwrap(calendar.date(byAdding: .month, value: -2, to: now)),
                relativeTo: now,
                calendar: calendar
            )
        )
        XCTAssertFalse(
            HistoryClearPeriod.threeMonths.includes(
                try XCTUnwrap(calendar.date(byAdding: .month, value: -4, to: now)),
                relativeTo: now,
                calendar: calendar
            )
        )
        XCTAssertTrue(
            HistoryClearPeriod.all.includes(
                now.addingTimeInterval(86_400),
                relativeTo: now,
                calendar: calendar
            )
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

    func testLabelNormalizationTreatsSeparatorsAndEnglishCaseAsEquivalent() {
        XCTAssertEqual(LabelNormalization.lookupKey("Deep Work"), "deep work")
        XCTAssertEqual(LabelNormalization.lookupKey("deep-work"), "deep work")
        XCTAssertEqual(LabelNormalization.lookupKey("DEEP__WORK"), "deep work")

        let usages = [
            LabelUsage(label: "Deep Work", count: 3),
            LabelUsage(label: "Reading", count: 1)
        ]

        XCTAssertEqual(LabelSuggestions.matching("DEEP_work", usages: usages).map(\.label), ["Deep Work"])
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

    func testAnalyticsGroupsEquivalentLabelsTogether() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-08-27T12:00:00Z"))
        let sessions = [
            TimerSession(
                label: "Deep Work",
                startedAt: now.addingTimeInterval(-1_800),
                endedAt: now,
                durationSeconds: 1_800
            ),
            TimerSession(
                label: "deep_work",
                startedAt: now.addingTimeInterval(-900),
                endedAt: now,
                durationSeconds: 900
            )
        ]

        let snapshot = AnalyticsBuilder.snapshot(sessions: sessions, now: now, calendar: calendar)

        XCTAssertEqual(snapshot.activities.count, 1)
        XCTAssertEqual(snapshot.activities.first?.totalSeconds, 2_700)
        XCTAssertEqual(snapshot.activities.first?.sessionCount, 2)
    }
}

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

    func testDiscreteScrollSensitivityPreservesTheTimerIncrementSetting() {
        XCTAssertEqual(
            ScrollSensitivity.allCases.map(\.rawValue),
            [0.5, 1, 2, 3, 4, 5]
        )
        XCTAssertEqual(ScrollSensitivity.closest(to: 1.4), .one)
        XCTAssertEqual(TimerScrollSensitivity.minutesThresholdMultiplier(for: .one), 4)
        XCTAssertEqual(TimerScrollSensitivity.secondsThresholdMultiplier(for: .one), 2)
        XCTAssertEqual(TimerScrollSensitivity.minutesThresholdMultiplier(for: .three), 12)
        XCTAssertEqual(TimerScrollSensitivity.secondsThresholdMultiplier(for: .three), 6)
        XCTAssertEqual(
            TimerAdjustment.minutes(
                in: 30 * 60,
                direction: .increase,
                step: 5
            ),
            35 * 60
        )
        XCTAssertEqual(
            TimerAdjustment.seconds(
                in: 30 * 60,
                direction: .increase,
                step: 5
            ),
            (30 * 60) + 5
        )
    }

    func testActiveTimerScrollAdjustmentRequiresExplicitOptIn() {
        XCTAssertFalse(TimerScrollAdjustmentPolicy.defaultAllowsActiveAdjustment)
        XCTAssertTrue(
            TimerScrollAdjustmentPolicy.isEnabled(
                during: .idle,
                allowsActiveAdjustment: false
            )
        )
        XCTAssertFalse(
            TimerScrollAdjustmentPolicy.isEnabled(
                during: .running,
                allowsActiveAdjustment: false
            )
        )
        XCTAssertFalse(
            TimerScrollAdjustmentPolicy.isEnabled(
                during: .paused,
                allowsActiveAdjustment: false
            )
        )
        XCTAssertTrue(
            TimerScrollAdjustmentPolicy.isEnabled(
                during: .running,
                allowsActiveAdjustment: true
            )
        )
        XCTAssertTrue(
            TimerScrollAdjustmentPolicy.isEnabled(
                during: .paused,
                allowsActiveAdjustment: true
            )
        )
    }

    func testActiveTimerScrollAdjustmentUpdatesOnlyTheCurrentSessionPlan() {
        XCTAssertEqual(
            TimerAdjustment.activeSession(
                requestedRemainingSeconds: 1_800,
                previousRemainingSeconds: 1_500,
                plannedDurationSeconds: 1_800,
                elapsedSeconds: 300
            ),
            TimerAdjustment.ActiveSessionResult(
                remainingSeconds: 1_800,
                plannedDurationSeconds: 2_100
            )
        )
        XCTAssertEqual(
            TimerAdjustment.activeSession(
                requestedRemainingSeconds: 1_200,
                previousRemainingSeconds: 1_500,
                plannedDurationSeconds: 1_800,
                elapsedSeconds: 300
            ),
            TimerAdjustment.ActiveSessionResult(
                remainingSeconds: 1_200,
                plannedDurationSeconds: 1_500
            )
        )
        XCTAssertEqual(
            TimerAdjustment.activeSession(
                requestedRemainingSeconds: 0,
                previousRemainingSeconds: 1_500,
                plannedDurationSeconds: 1_800,
                elapsedSeconds: 300
            ),
            TimerAdjustment.ActiveSessionResult(
                remainingSeconds: 0,
                plannedDurationSeconds: 300
            )
        )
    }

    func testActiveTimerScrollAdjustmentKeepsTheSessionWithinTheMaximumDuration() {
        XCTAssertEqual(
            TimerAdjustment.activeSession(
                requestedRemainingSeconds: 120,
                previousRemainingSeconds: 30,
                plannedDurationSeconds: DurationFormatting.maximumSeconds - 30,
                elapsedSeconds: DurationFormatting.maximumSeconds - 60
            ),
            TimerAdjustment.ActiveSessionResult(
                remainingSeconds: 60,
                plannedDurationSeconds: DurationFormatting.maximumSeconds
            )
        )
    }

    func testClickExtensionDefaultsToOneMinuteAndIsEnabled() {
        XCTAssertTrue(TimerClickExtensionPolicy.defaultEnabled)
        XCTAssertEqual(TimerClickExtensionPolicy.defaultMinutes, 1)
        XCTAssertEqual(TimerClickExtensionPolicy.clampedMinutes(0), 1)
        XCTAssertEqual(TimerClickExtensionPolicy.clampedMinutes(61), 60)
    }

    func testClickExtensionAddsRemainingTimeWithoutChangingRecordedDuration() {
        var result = TimerAdjustment.ActiveSessionResult(
            remainingSeconds: 35 * 60,
            plannedDurationSeconds: 40 * 60
        )

        for _ in 0..<5 {
            result = TimerAdjustment.unrecordedActiveSessionExtension(
                remainingSeconds: result.remainingSeconds,
                plannedDurationSeconds: result.plannedDurationSeconds,
                incrementMinutes: 1
            )
        }

        XCTAssertEqual(result.remainingSeconds, 40 * 60)
        XCTAssertEqual(result.plannedDurationSeconds, 40 * 60)
    }

    func testScrollAdjustmentStillChangesRecordedDurationAfterClickExtension() {
        let clickResult = TimerAdjustment.unrecordedActiveSessionExtension(
            remainingSeconds: 35 * 60,
            plannedDurationSeconds: 40 * 60,
            incrementMinutes: 5
        )
        let scrolledRemainingSeconds = TimerAdjustment.minutes(
            in: clickResult.remainingSeconds,
            direction: .increase,
            step: 10
        )
        let scrollResult = TimerAdjustment.activeSession(
            requestedRemainingSeconds: scrolledRemainingSeconds,
            previousRemainingSeconds: clickResult.remainingSeconds,
            plannedDurationSeconds: clickResult.plannedDurationSeconds,
            elapsedSeconds: 5 * 60
        )

        XCTAssertEqual(scrollResult.remainingSeconds, 50 * 60)
        XCTAssertEqual(scrollResult.plannedDurationSeconds, 50 * 60)
    }

    func testClickExtensionStopsAtMaximumWithoutChangingRecordedDuration() {
        XCTAssertEqual(
            TimerAdjustment.unrecordedActiveSessionExtension(
                remainingSeconds: DurationFormatting.maximumSeconds - 30,
                plannedDurationSeconds: 40 * 60,
                incrementMinutes: 1
            ),
            TimerAdjustment.ActiveSessionResult(
                remainingSeconds: DurationFormatting.maximumSeconds,
                plannedDurationSeconds: 40 * 60
            )
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

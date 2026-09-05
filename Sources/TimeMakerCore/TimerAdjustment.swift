import Foundation

public enum ScrollDirection: Int, Sendable {
    case decrease = -1
    case increase = 1
}

public enum ScrollSensitivity: Double, CaseIterable, Identifiable, Codable, Sendable {
    case half = 0.5
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5

    public var id: Double { rawValue }

    public static func closest(to value: Double) -> ScrollSensitivity {
        allCases.min { lhs, rhs in
            abs(lhs.rawValue - value) < abs(rhs.rawValue - value)
        } ?? .one
    }
}

public enum TimerScrollSensitivity {
    public static let secondsBaseDistanceMultiplier = 2.0
    public static let minutesAdditionalSensitivityMultiplier = 2.0

    public static func secondsThresholdMultiplier(for sensitivity: ScrollSensitivity) -> Double {
        sensitivity.rawValue * secondsBaseDistanceMultiplier
    }

    public static func minutesThresholdMultiplier(for sensitivity: ScrollSensitivity) -> Double {
        secondsThresholdMultiplier(for: sensitivity) * minutesAdditionalSensitivityMultiplier
    }
}

public enum TimerScrollAdjustmentPolicy {
    public static let defaultAllowsActiveAdjustment = false

    public static func isEnabled(
        during phase: TimerPhase,
        allowsActiveAdjustment: Bool
    ) -> Bool {
        phase == .idle || allowsActiveAdjustment
    }
}

public enum TimerClickExtensionPolicy {
    public static let defaultEnabled = true
    public static let defaultMinutes = 1
    public static let minimumMinutes = 1
    public static let maximumMinutes = 60
    public static let minuteRange = minimumMinutes...maximumMinutes

    public static func clampedMinutes(_ value: Int) -> Int {
        min(max(value, minimumMinutes), maximumMinutes)
    }
}

public enum TimerAdjustment {
    public struct ActiveSessionResult: Equatable, Sendable {
        public let remainingSeconds: Int
        public let plannedDurationSeconds: Int
    }

    public static func activeSession(
        requestedRemainingSeconds: Int,
        previousRemainingSeconds: Int,
        plannedDurationSeconds: Int,
        elapsedSeconds: Int
    ) -> ActiveSessionResult {
        let safeElapsedSeconds = min(
            max(elapsedSeconds, 0),
            DurationFormatting.maximumSeconds
        )
        let maximumRemainingSeconds = DurationFormatting.maximumSeconds - safeElapsedSeconds
        let remainingSeconds = min(
            max(requestedRemainingSeconds, 0),
            maximumRemainingSeconds
        )
        let adjustment = remainingSeconds - max(previousRemainingSeconds, 0)
        let adjustedPlannedDuration = min(
            max(plannedDurationSeconds + adjustment, safeElapsedSeconds),
            DurationFormatting.maximumSeconds
        )

        return ActiveSessionResult(
            remainingSeconds: remainingSeconds,
            plannedDurationSeconds: adjustedPlannedDuration
        )
    }

    public static func unrecordedActiveSessionExtension(
        remainingSeconds: Int,
        plannedDurationSeconds: Int,
        incrementMinutes: Int
    ) -> ActiveSessionResult {
        let safeRemainingSeconds = min(
            max(remainingSeconds, 0),
            DurationFormatting.maximumSeconds
        )
        let safeIncrementMinutes = TimerClickExtensionPolicy.clampedMinutes(incrementMinutes)
        let additionalSeconds = safeIncrementMinutes * 60

        return ActiveSessionResult(
            remainingSeconds: min(
                safeRemainingSeconds + additionalSeconds,
                DurationFormatting.maximumSeconds
            ),
            plannedDurationSeconds: min(
                max(plannedDurationSeconds, 0),
                DurationFormatting.maximumSeconds
            )
        )
    }

    public static func minutes(
        in totalSeconds: Int,
        direction: ScrollDirection,
        step: Int
    ) -> Int {
        let safeStep = min(max(step, 1), DurationFormatting.maximumMinutes)
        let components = DurationFormatting.components(totalSeconds)
        let rawMinutes = components.minutes + (direction.rawValue * safeStep)
        let boundedMinutes = min(max(rawMinutes, 0), DurationFormatting.maximumMinutes)
        let seconds = boundedMinutes == DurationFormatting.maximumMinutes ? 0 : components.seconds
        return min((boundedMinutes * 60) + seconds, DurationFormatting.maximumSeconds)
    }

    public static func seconds(
        in totalSeconds: Int,
        direction: ScrollDirection,
        step: Int
    ) -> Int {
        let safeStep = min(max(step, 1), 60)
        let components = DurationFormatting.components(totalSeconds)

        guard components.minutes < DurationFormatting.maximumMinutes else {
            return DurationFormatting.maximumSeconds
        }

        let rawSeconds = components.seconds + (direction.rawValue * safeStep)
        let wrappedSeconds = ((rawSeconds % 60) + 60) % 60
        return (components.minutes * 60) + wrappedSeconds
    }
}

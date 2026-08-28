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

public enum TimerAdjustment {
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

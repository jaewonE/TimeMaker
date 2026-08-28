import Foundation

public enum ScrollDirection: Int, Sendable {
    case decrease = -1
    case increase = 1
}

public enum TimerScrollSensitivity {
    public static let minutesMultiplier = 4
    public static let secondsMultiplier = 2

    public static func minutesStep(from baseStep: Int) -> Int {
        normalizedBaseStep(baseStep) * minutesMultiplier
    }

    public static func secondsStep(from baseStep: Int) -> Int {
        normalizedBaseStep(baseStep) * secondsMultiplier
    }

    private static func normalizedBaseStep(_ value: Int) -> Int {
        min(max(value, 1), 60)
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
        let safeStep = min(max(step, 1), DurationFormatting.maximumSeconds)
        let components = DurationFormatting.components(totalSeconds)

        guard components.minutes < DurationFormatting.maximumMinutes else {
            return DurationFormatting.maximumSeconds
        }

        let rawSeconds = components.seconds + (direction.rawValue * safeStep)
        let wrappedSeconds = ((rawSeconds % 60) + 60) % 60
        return (components.minutes * 60) + wrappedSeconds
    }
}

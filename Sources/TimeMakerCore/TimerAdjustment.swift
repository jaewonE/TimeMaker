import Foundation

public enum ScrollDirection: Int, Sendable {
    case decrease = -1
    case increase = 1
}

public enum TimerAdjustment {
    public static func minutes(
        in totalSeconds: Int,
        direction: ScrollDirection,
        step: Int
    ) -> Int {
        let safeStep = min(max(step, 1), 60)
        let components = DurationFormatting.components(totalSeconds)
        let rangeSize = DurationFormatting.maximumMinutes + 1
        let rawMinutes = components.minutes + (direction.rawValue * safeStep)
        let wrappedMinutes = ((rawMinutes % rangeSize) + rangeSize) % rangeSize
        let seconds = wrappedMinutes == DurationFormatting.maximumMinutes ? 0 : components.seconds
        return min((wrappedMinutes * 60) + seconds, DurationFormatting.maximumSeconds)
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

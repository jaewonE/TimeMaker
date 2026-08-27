import Foundation

public enum DurationFormatting {
    public static let maximumMinutes = 1_440
    public static let maximumSeconds = maximumMinutes * 60

    public static func timer(_ seconds: Int) -> String {
        let safeSeconds = min(max(seconds, 0), maximumSeconds)
        let minutes = safeSeconds / 60
        let remainder = safeSeconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }

    public static func compact(_ seconds: Int) -> String {
        let safeSeconds = max(seconds, 0)
        let hours = safeSeconds / 3_600
        let minutes = (safeSeconds % 3_600) / 60

        if hours > 0, minutes > 0 {
            return "\(hours)h \(minutes)m"
        }
        if hours > 0 {
            return "\(hours)h"
        }
        return "\(minutes)m"
    }

    public static func components(_ seconds: Int) -> (minutes: Int, seconds: Int) {
        let safeSeconds = min(max(seconds, 0), maximumSeconds)
        return (safeSeconds / 60, safeSeconds % 60)
    }
}

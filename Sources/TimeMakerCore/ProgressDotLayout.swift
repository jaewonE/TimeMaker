import Foundation

public enum ProgressDotLayout {
    public static let maximumRows = 8

    public static func rowCount(for itemCount: Int) -> Int {
        min(max(itemCount, 1), maximumRows)
    }

    public static func columnCount(for itemCount: Int) -> Int {
        let safeCount = max(itemCount, 1)
        return (safeCount + maximumRows - 1) / maximumRows
    }
}

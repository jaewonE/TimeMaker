import Foundation

public enum HistoryClearPeriod: String, CaseIterable, Identifiable, Sendable {
    case oneDay
    case threeDays
    case oneWeek
    case oneMonth
    case threeMonths
    case sixMonths
    case oneYear
    case all

    public var id: String { rawValue }

    public func includes(
        _ date: Date,
        relativeTo now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        if self == .all {
            return true
        }

        guard date <= now, let cutoff = cutoff(relativeTo: now, calendar: calendar) else {
            return false
        }
        return date >= cutoff
    }

    public func cutoff(relativeTo now: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .oneDay:
            calendar.date(byAdding: .day, value: -1, to: now)
        case .threeDays:
            calendar.date(byAdding: .day, value: -3, to: now)
        case .oneWeek:
            calendar.date(byAdding: .day, value: -7, to: now)
        case .oneMonth:
            calendar.date(byAdding: .month, value: -1, to: now)
        case .threeMonths:
            calendar.date(byAdding: .month, value: -3, to: now)
        case .sixMonths:
            calendar.date(byAdding: .month, value: -6, to: now)
        case .oneYear:
            calendar.date(byAdding: .year, value: -1, to: now)
        case .all:
            nil
        }
    }
}

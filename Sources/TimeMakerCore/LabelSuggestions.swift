import Foundation

public enum LabelSuggestions {
    public static func matching(
        _ query: String,
        usages: [LabelUsage],
        limit: Int = 6
    ) -> [LabelUsage] {
        let normalizedQuery = LabelNormalization.lookupKey(query)

        return usages
            .filter { usage in
                let normalizedUsage = LabelNormalization.lookupKey(usage.label)
                return normalizedQuery.isEmpty || normalizedUsage.contains(normalizedQuery)
            }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count {
                    return lhs.count > rhs.count
                }
                if lhs.lastUsedAt != rhs.lastUsedAt {
                    return lhs.lastUsedAt > rhs.lastUsedAt
                }
                return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
            }
            .prefix(max(limit, 0))
            .map { $0 }
    }
}

import Foundation

public enum LabelSuggestions {
    public static func matching(
        _ query: String,
        usages: [LabelUsage],
        limit: Int = 6
    ) -> [LabelUsage] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let foldedQuery = trimmedQuery.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )

        return usages
            .filter { usage in
                foldedQuery.isEmpty || usage.normalizedLabel.contains(foldedQuery)
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

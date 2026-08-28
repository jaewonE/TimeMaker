import Foundation

public enum LabelNormalization {
    public static let fallbackLabel = "work"

    public static func displayLabel(_ value: String, fallback: String = fallbackLabel) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    public static func lookupKey(_ value: String) -> String {
        let folded = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
            .lowercased(with: Locale(identifier: "en_US_POSIX"))

        let separators = CharacterSet.whitespacesAndNewlines
            .union(CharacterSet(charactersIn: "-_"))
        return folded
            .components(separatedBy: separators)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

import Foundation

/// Generic key/value claim wrapper used across document models and sharing.
///
/// The display name is derived from the key when the caller doesn't supply one
/// (snake_case / camelCase → "Sentence case"), so callers get a sane fallback
/// without having to localize every claim key locally.
public struct Field<T: Codable & Hashable>: Codable, Hashable {
    public let key: String
    public let displayName: String
    public let value: T

    public init(key: String, displayName: String? = nil, value: T) {
        self.key = key
        self.displayName = displayName ?? Self.formatDisplayName(from: key)
        self.value = value
    }

    /// Converts a raw claim key into a human-readable label.
    /// Examples: "birth_date" → "Birth date", "emailAddress" → "Email address"
    public static func formatDisplayName(from key: String) -> String {
        var result = key.replacingOccurrences(of: "_", with: " ")
        result = result.replacingOccurrences(
            of: "([a-z])([A-Z])",
            with: "$1 $2",
            options: .regularExpression
        )
        result = result.lowercased()
        if let first = result.first {
            result = first.uppercased() + result.dropFirst()
        }
        return result.trimmingCharacters(in: .whitespaces)
    }
}

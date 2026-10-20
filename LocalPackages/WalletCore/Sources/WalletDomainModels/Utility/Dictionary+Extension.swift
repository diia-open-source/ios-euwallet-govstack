import Foundation

public extension Dictionary {
    /// Like `Dictionary(uniqueKeysWithValues:)` but keeps the first value on a duplicate key instead of trapping.
    /// Use when keys come from untrusted data — e.g. mdoc claim names, which can repeat across namespaces.
    init<S: Sequence>(keepingFirst pairs: S) where S.Element == (Key, Value) {
        self.init(pairs, uniquingKeysWith: { first, _ in first })
    }
}

import Foundation

public struct TransactionParty: Sendable, Hashable {
    public let name: String

    public init(name: String) {
        self.name = name
    }
}

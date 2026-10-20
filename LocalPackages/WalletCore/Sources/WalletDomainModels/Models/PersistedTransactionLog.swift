import Foundation

/// Opaque persistence shape for a transaction log entry.
///
/// `WalletCore` owns the encoding/decoding of upstream `TransactionLog` payloads — the
/// host app's persistence adapter sees only this `(id, data)` shape. This is what makes
/// `WalletCore` the single boundary across which eudi-* types flow: blobs in, domain
/// types out.
public struct PersistedTransactionLog: Sendable, Hashable {
    public let id: Int64
    public let data: Data

    public init(id: Int64, data: Data) {
        self.id = id
        self.data = data
    }
}

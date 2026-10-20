import Foundation
import WalletDomainModels

/// Persistence port for transaction log records.
///
/// The host app implements this with its database of choice (GRDB, SQLite, Core Data, etc.).
/// Operations work against opaque `PersistedTransactionLog` blobs — the adapter never sees
/// upstream eudi-* types, only `(id, data)` pairs.
///
/// `WalletCore` owns the codec: it serializes upstream `MdocDataModel18013.TransactionLog`
/// payloads into the `Data` field on write and decodes them on read inside
/// `DefaultTransactionLogStorage`. Callers that need a domain-facing API consume
/// `TransactionLogStorage`; only the storage internals talk to `TransactionLogStore`.
public protocol TransactionLogStore: Sendable {
    func create(_ record: PersistedTransactionLog) async throws
    func fetchAll() async throws -> [PersistedTransactionLog]
    func fetchOne(id: Int64) async throws -> PersistedTransactionLog?
    func delete(id: Int64) async throws
    func deleteAll() async throws
}

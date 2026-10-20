import Foundation
import WalletDomainModels

/// Domain-facing read/delete surface for transaction logs.
///
/// Wallet packages (Transactions, Menu, etc.) consume this protocol. The concrete
/// implementation lives inside `WalletCore` (`DefaultTransactionLogStorage`) and wraps a
/// `TransactionLogStore` — it decodes the persisted blob into upstream `TransactionLog`
/// internally, then converts to domain types before returning. Writes are not part of
/// this surface: they flow through `EudiWalletKit` → the internal
/// `WalletKitTransactionLoggerBridge` → `TransactionLogStore.create(_:)`.
public protocol TransactionLogStorage: Sendable {
    func fetchAll() async throws -> [TransactionLogEntry]

    /// Documents from a presentation log's payload, for transaction-detail rendering.
    /// Returns `[]` for non-presentation logs.
    func fetchPresentedDocuments(forLogId id: Int64) async throws -> [Credential]

    func delete(id: Int64) async throws
    func deleteAll() async throws
}

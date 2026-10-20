import Foundation
import WalletCore
import WalletDomainModels
import EudiWalletKit
import MdocDataModel18013

/// Default `TransactionLogStorage` implementation.
///
/// Wraps a `TransactionLogStore` (the app's persistence adapter) and owns the JSON codec for upstream `MdocDataModel18013.TransactionLog`.
/// Callers (Transactions list, transaction details, etc.) consume only domain types via this class; the upstream type never escapes the WalletCore boundary.
///
/// `public` so the host (`AppConfigurator.bootstrapWalletDependencies()`) can construct it explicitly and pass it into `WalletDependencies.configure(...)` — this keeps WalletDependencies from needing to know how to build SDK-coupled storage, which matters in Phase H when this file moves into WalletEngine and WalletCore loses the SDK dep.
public final class DefaultTransactionLogStorage: TransactionLogStorage {
    private let store: TransactionLogStore
    private let decoder: JSONDecoder

    public init(store: TransactionLogStore, decoder: JSONDecoder = JSONDecoder()) {
        self.store = store
        self.decoder = decoder
    }

    public func fetchAll() async throws -> [TransactionLogEntry] {
        try await store.fetchAll().compactMap { record in
            decode(record.data)?.toDomainEntry()
        }
    }

    public func fetchPresentedDocuments(forLogId id: Int64) async throws -> [Credential] {
        guard let record = try await store.fetchOne(id: id),
              let log = decode(record.data),
              log.type == .presentation else { return [] }
        return PresentationLogData(log, uiCulture: nil).documents.map { $0.toDomainCredential() }
    }

    public func delete(id: Int64) async throws {
        try await store.delete(id: id)
    }

    public func deleteAll() async throws {
        try await store.deleteAll()
    }

    private func decode(_ data: Data) -> TransactionLog? {
        try? decoder.decode(TransactionLog.self, from: data)
    }
}

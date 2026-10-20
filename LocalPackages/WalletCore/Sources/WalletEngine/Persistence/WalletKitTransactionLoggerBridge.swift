import Foundation
import WalletCore
import WalletDomainModels
import MdocDataModel18013

/// Internal adapter that lets `EudiWalletKit` call back into the host app's persistence
/// without exposing `MdocDataModel18013.TransactionLogger` (the upstream protocol) past
/// the WalletCore boundary.
///
/// The wallet-kit controller passes this bridge to `EudiWallet.init(transactionLogger:)`.
/// On each `log(transaction:)` callback the bridge JSON-encodes the upstream
/// `TransactionLog` and hands the resulting blob to the app's `TransactionLogStore`. The
/// app never has to import upstream eudi-* modules to satisfy the logger contract.
internal actor WalletKitTransactionLoggerBridge: TransactionLogger {
    private let store: TransactionLogStore
    private let encoder: JSONEncoder

    init(store: TransactionLogStore, encoder: JSONEncoder = JSONEncoder()) {
        self.store = store
        self.encoder = encoder
    }

    func log(transaction: TransactionLog) async throws {
        let data = try encoder.encode(transaction)
        let record = PersistedTransactionLog(id: transaction.timestamp, data: data)
        try await store.create(record)
    }
}

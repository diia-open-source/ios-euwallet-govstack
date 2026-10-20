import Foundation
import GRDB
import WalletCore
import WalletDomainModels

/// Owns the GRDB-backed persistence adapter for transaction logs.
/// The store is what the app hands to `WalletCore.WalletDependencies.configure(transactionLogStore:)`; everything else (domain reads, upstream encoding, the wallet-kit logger contract) lives in WalletCore / WalletEngine.
public final class TransactionLogController {
    public let transactionLogStore: TransactionLogStore

    /// Convenience pass-through to `WalletDependencies.transactionLogStorage`.
    /// Lets the host UI keep its existing call sites (`AppConfigurator.transactionLogController.transactionLogStorage`) unchanged while the underlying wiring lives in WalletCore.
    public var transactionLogStorage: TransactionLogStorage { WalletDependencies.transactionLogStorage }

    public init(config: TransactionLogConfig) {
        switch config.database {
        case .grdb:
            do {
                let fileManager = FileManager.default
                let appSupportURL = try fileManager.url(
                    for: .applicationSupportDirectory, in: .userDomainMask,
                    appropriateFor: nil, create: true)
                let directoryURL = appSupportURL.appendingPathComponent(config.databaseDirectoryName, isDirectory: true)
                // Use `completeUntilFirstUserAuthentication`, not `.completeUnlessOpen`/`.complete`: the transaction log must stay writable during background deferred-issuance, and a `completeUnlessOpen` file can't be opened during a cold `BGAppRefreshTask` launch while the device is locked (which would hit the `fatalError` below).
                // The log is still encrypted at rest and unreadable until the device's first unlock after boot.
                try fileManager.createDirectory(
                    at: directoryURL,
                    withIntermediateDirectories: true,
                    attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])

                let databaseURL = directoryURL.appendingPathComponent(config.databaseFileName)

                let dbQueue = try DatabaseQueue(path: databaseURL.path)
                self.transactionLogStore = try GRDBTransactionLogStore(dbQueue: dbQueue)
            } catch {
                fatalError("grdb setup failed")
            }
        }
    }
}

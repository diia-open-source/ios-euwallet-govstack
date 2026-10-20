import Foundation
import GRDB
import WalletDomainModels

/// GRDB row for one persisted transaction log. The `transactionLogData` blob is whatever
/// `WalletCore.WalletKitTransactionLoggerBridge` encoded — this layer never inspects it.
struct GRDBTransactionLog: Codable, FetchableRecord, PersistableRecord, MutablePersistableRecord, Equatable {
    static let databaseTableName = "transaction_logs"

    var id: Int64
    var transactionLogData: Data

    enum Columns {
        static let transactionLogData = Column(CodingKeys.transactionLogData)
    }
}

extension GRDBTransactionLog {
    init(_ record: PersistedTransactionLog) {
        self.id = record.id
        self.transactionLogData = record.data
    }

    var asPersisted: PersistedTransactionLog {
        PersistedTransactionLog(id: id, data: transactionLogData)
    }
}

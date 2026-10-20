import Foundation
import GRDB
import WalletCore
import WalletDomainModels

/// GRDB-backed persistence adapter for transaction log blobs. Conforms to the
/// `WalletCore.TransactionLogStore` port — pure CRUD over `(id, data)` records.
/// All eudi-* awareness lives inside `WalletCore`; this layer has no upstream imports.
final class GRDBTransactionLogStore: TransactionLogStore {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue
        try createTableIfNeeded()
    }

    private func createTableIfNeeded() throws {
        try dbQueue.write { db in
            try db.create(table: GRDBTransactionLog.databaseTableName, ifNotExists: true) { t in
                t.column("id", .integer).primaryKey()
                t.column("transactionLogData", .blob).notNull()
            }
        }
    }

    func create(_ record: PersistedTransactionLog) async throws {
        let row = GRDBTransactionLog(record)
        try await dbQueue.write { db in
            try row.insert(db)
        }
    }

    func fetchAll() async throws -> [PersistedTransactionLog] {
        try await dbQueue.read { db in
            try GRDBTransactionLog.fetchAll(db)
        }.map(\.asPersisted)
    }

    func fetchOne(id: Int64) async throws -> PersistedTransactionLog? {
        try await dbQueue.read { db in
            try GRDBTransactionLog.fetchOne(db, key: id)
        }?.asPersisted
    }

    func delete(id: Int64) async throws {
        try await dbQueue.write { db in
            _ = try GRDBTransactionLog.deleteOne(db, key: id)
        }
    }

    func deleteAll() async throws {
        try await dbQueue.write { db in
            _ = try GRDBTransactionLog.deleteAll(db)
        }
    }
}

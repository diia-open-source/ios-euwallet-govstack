import Foundation

public struct TransactionLogConfig {
    enum LogDataBase {
        case grdb
    }

    let database: LogDataBase = .grdb

    public init() {}

    var databaseFileName: String {
        switch self.database {
        case .grdb:
            return "db.sqlite"
        }
    }
    
    var databaseDirectoryName: String {
        switch self.database {
        case .grdb:
            return "Database"
        }
    }
}

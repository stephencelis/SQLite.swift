import Foundation

enum SQLiteFeature {
    case partialIntegrityCheck      // PRAGMA integrity_check(table)
    case sqliteSchemaTable          // sqlite_master => sqlite_schema

    func isSupported(by version: SQLiteVersion) -> Bool {
        switch self {
        case .partialIntegrityCheck, .sqliteSchemaTable:
            return version > SQLiteVersion(major: 3, minor: 33)
        }
    }
}

extension Connection {
    func supports(_ feature: SQLiteFeature) -> Bool {
        feature.isSupported(by: sqliteVersion)
    }
}

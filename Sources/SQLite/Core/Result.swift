#if StandaloneSQLite
import sqlite3
#elseif SQLCipher
import SQLCipher
#elseif SQLiteSwiftCSQLite
import SQLiteSwiftCSQLite
#else
import SQLite3 // SystemSQLite
#endif

public enum Result: Error {

    fileprivate static let successCodes: Set = [SQLITE_OK, SQLITE_ROW, SQLITE_DONE]

    /// Represents a SQLite specific [error code](https://sqlite.org/rescode.html)
    ///
    /// - message: English-language text that describes the error
    ///
    /// - code: SQLite [error code](https://sqlite.org/rescode.html#primary_result_code_list)
    ///
    /// - statement: the statement which produced the error
    case error(message: String, code: Int32)

    /// Represents a SQLite specific [extended error code] (https://sqlite.org/rescode.html#primary_result_codes_versus_extended_result_codes)
    ///
    /// - message: English-language text that describes the error
    ///
    /// - extendedCode: SQLite [extended error code](https://sqlite.org/rescode.html#extended_result_code_list)
    ///
    /// - statement: the statement which produced the error
    case extendedError(message: String, extendedCode: Int32)

    init?(errorCode: Int32, connection: Connection) {
        guard !Result.successCodes.contains(errorCode) else { return nil }

        let message = String(cString: sqlite3_errmsg(connection.handle))

        guard connection.usesExtendedErrorCodes else {
            self = .error(message: message, code: errorCode)
            return
        }

        let extendedErrorCode = sqlite3_extended_errcode(connection.handle)
        self = .extendedError(message: message, extendedCode: extendedErrorCode)
    }

}

extension Result: CustomStringConvertible {

    public var description: String {
        switch self {
        case let .error(message, errorCode):
            return "\(message) (code: \(errorCode))"
        case let .extendedError(message, extendedCode):
            return "\(message) (extended code: \(extendedCode))"
        }
    }
}

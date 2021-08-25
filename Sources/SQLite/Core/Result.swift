#if SQLITE_SWIFT_STANDALONE
import sqlite3
#elseif SQLITE_SWIFT_SQLCIPHER
import SQLCipher
#elseif os(Linux)
import CSQLite
#else
import SQLite3
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
    case error(message: String, code: Int32, statement: Statement?)

    init?(errorCode: Int32, connection: Connection, statement: Statement? = nil) {
        guard !Result.successCodes.contains(errorCode) else { return nil }

        let message = String(cString: sqlite3_errmsg(connection.handle))
        self = .error(message: message, code: errorCode, statement: statement)
    }

}

extension Result: CustomStringConvertible {

    public var description: String {
        switch self {
        case let .error(message, errorCode, statement):
            if let statement = statement {
                return "\(message) (\(statement)) (code: \(errorCode))"
            } else {
                return "\(message) (code: \(errorCode))"
            }
        }
    }
}

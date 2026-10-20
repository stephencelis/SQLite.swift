import XCTest
import Foundation
@testable import SQLite

#if StandaloneSQLite
import sqlite3
#elseif SQLCipher
import SQLCipher
#elseif SQLiteSwiftCSQLite
import SQLiteSwiftCSQLite
#else
import SQLite3 // SystemSQLite
#endif

class ResultTests: XCTestCase {
    var connection: Connection!

    override func setUpWithError() throws {
        connection = try Connection(.inMemory)
    }

    func test_init_with_ok_code_returns_nil() {
        XCTAssertNil(Result(errorCode: SQLITE_OK, connection: connection) as Result?)
    }

    func test_init_with_row_code_returns_nil() {
        XCTAssertNil(Result(errorCode: SQLITE_ROW, connection: connection) as Result?)
    }

    func test_init_with_done_code_returns_nil() {
        XCTAssertNil(Result(errorCode: SQLITE_DONE, connection: connection) as Result?)
    }

    func test_init_with_other_code_returns_error() {
        if case .some(.error(let message, let code)) =
            Result(errorCode: SQLITE_MISUSE, connection: connection) {
            XCTAssertEqual("not an error", message)
            XCTAssertEqual(SQLITE_MISUSE, code)
            XCTAssert(connection === connection)
        } else {
            XCTFail("no error")
        }
    }

    func test_description_contains_error_code() {
        XCTAssertEqual("not an error (code: 21)",
            Result(errorCode: SQLITE_MISUSE, connection: connection)?.description)
    }

    func test_init_extended_with_other_code_returns_error() {
        connection.usesExtendedErrorCodes = true
        if case .some(.extendedError(let message, let extendedCode)) =
            Result(errorCode: SQLITE_MISUSE, connection: connection) {
            XCTAssertEqual("not an error", message)
            XCTAssertEqual(extendedCode, 0)
            XCTAssert(connection === connection)
        } else {
            XCTFail("no error")
        }
    }
}

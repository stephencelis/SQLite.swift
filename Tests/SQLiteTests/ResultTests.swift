import XCTest
@testable import SQLite

#if SQLITE_SWIFT_STANDALONE
import sqlite3
#elseif SQLITE_SWIFT_SQLCIPHER
import SQLCipher
#elseif SWIFT_PACKAGE || COCOAPODS
    #if os(Linux)
    import CSQLiteLinux
    #else
    import CSQLite
    #endif
#endif

class ResultTests : XCTestCase {
    let connection = try! Connection(.inMemory)

    func test_init_with_ok_code_returns_nil() {
        XCTAssertNil(Result(errorCode: SQLITE_OK, connection: connection, statement: nil) as Result?)
    }

    func test_init_with_row_code_returns_nil() {
        XCTAssertNil(Result(errorCode: SQLITE_ROW, connection: connection, statement: nil) as Result?)
    }

    func test_init_with_done_code_returns_nil() {
        XCTAssertNil(Result(errorCode: SQLITE_DONE, connection: connection, statement: nil) as Result?)
    }

    func test_init_with_other_code_returns_error() {
        if case .some(.error(let message, let code, let statement)) =
        Result(errorCode: SQLITE_MISUSE, connection: connection, statement: nil)  {
            XCTAssertEqual("not an error", message)
            XCTAssertEqual(SQLITE_MISUSE, code)
            XCTAssertNil(statement)
            XCTAssert(self.connection === connection)
        } else {
            XCTFail()
        }
    }

    func test_description_contains_error_code() {
        XCTAssertEqual("not an error (code: 21)",
                Result(errorCode: SQLITE_MISUSE, connection: connection, statement: nil)?.description)
    }

    func test_description_contains_statement_and_error_code() {
        let statement = try! Statement(connection, "SELECT 1")
        XCTAssertEqual("not an error (SELECT 1) (code: 21)",
                Result(errorCode: SQLITE_MISUSE, connection: connection, statement: statement)?.description)
    }
}

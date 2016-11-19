import XCTest
import SQLite

class StatementTests : SQLiteTestCase {
    override func setUp() {
        super.setUp()
        CreateUsersTable()
    }

    func test_cursor_to_blob() {
        try! InsertUsers("alice")
        let statement = try! db.prepare("SELECT email FROM users")
        XCTAssert(try! statement.step())
        let blob = statement.row[0] as Blob
        XCTAssertEqual("alice@example.com", String(bytes: blob.bytes, encoding: .utf8)!)
    }
}

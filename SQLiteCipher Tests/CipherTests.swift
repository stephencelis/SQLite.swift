import XCTest
import SQLite

class CipherTests: XCTestCase {

    let db = Database()

    var users: Query { return db["users"] }

    override func setUp() {
        db.key("hello")
        CreateUsersTable(db)
        InsertUser(db, "alice")

        super.setUp()
    }

    func test_key() {
        XCTAssertEqual(1, users.count)
    }

    func test_rekey() {
        db.rekey("world")
        XCTAssertEqual(1, users.count)
    }

}
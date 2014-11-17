import XCTest
import SQLite

class StatementTests: XCTestCase {

    let db = Database()

    override func setUp() {
        super.setUp()

        CreateUsersTable(db)
    }

    func test_bind_withVariadicParameters_bindsParameters() {
        let stmt = db.prepare("SELECT ?, ?, ?, ?, ?")
        ExpectExecutions(db, ["SELECT 0, 1, 2.0, '3', x'34'": 1]) { _ in
            withBlob { blob in
                stmt.bind(false, 1, 2.0, "3", blob).run()
                return
            }
        }
    }

    func test_bind_withArrayOfParameters_bindsParameters() {
        let stmt = db.prepare("SELECT ?, ?, ?, ?, ?")
        ExpectExecutions(db, ["SELECT 0, 1, 2.0, '3', x'34'": 1]) { _ in
            withBlob { blob in
                stmt.bind([false, 1, 2.0, "3", blob]).run()
                return
            }
        }
    }

    func test_bind_withNamedParameters_bindsParameters() {
        let stmt = db.prepare("SELECT ?1, ?2, ?3, ?4, ?5")
        ExpectExecutions(db, ["SELECT 0, 1, 2.0, '3', x'34'": 1]) { _ in
            withBlob { blob in
                stmt.bind(["?1": false, "?2": 1, "?3": 2.0, "?4": "3", "?5": blob]).run()
                return
            }
        }
    }

    func test_bind_withBlob_bindsBlob() {
        let stmt = db.prepare("SELECT ?")
        ExpectExecutions(db, ["SELECT x'34'": 1]) { _ in
            withBlob { blob in
                stmt.bind(blob).run()
                return
            }
        }
    }

    func test_bind_withBool_bindsInt() {
        let stmt = db.prepare("SELECT ?")
        ExpectExecutions(db, ["SELECT 0": 1, "SELECT 1": 1]) { _ in
            stmt.bind(false).run()
            stmt.bind(true).run()
        }
    }

    func test_bind_withDouble_bindsDouble() {
        let stmt = db.prepare("SELECT ?")
        ExpectExecutions(db, ["SELECT 2.0": 1]) { _ in
            stmt.bind(2.0).run()
            return
        }
    }

    func test_bind_withInt_bindsInt() {
        let stmt = db.prepare("SELECT ?")
        ExpectExecutions(db, ["SELECT 3": 1]) { _ in
            stmt.bind(3).run()
            return
        }
    }

    func test_bind_withString() {
        let stmt = db.prepare("SELECT ?")
        ExpectExecutions(db, ["SELECT '4'": 1]) { _ in
            stmt.bind("4").run()
            return
        }
    }

    func test_run_withNoParameters() {
        let stmt = db.prepare(
            "INSERT INTO users (email, admin) VALUES ('alice@example.com', 1)"
        )
        stmt.run()
        XCTAssertEqual(1, db.totalChanges)
    }

    func test_run_withVariadicParameters() {
        let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)")
        stmt.run("alice@example.com", true)
        XCTAssertEqual(1, db.totalChanges)
    }

    func test_run_withArrayOfParameters() {
        let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)")
        stmt.run(["alice@example.com", true])
        XCTAssertEqual(1, db.totalChanges)
    }

    func test_run_withNamedParameters() {
        let stmt = db.prepare(
            "INSERT INTO users (email, admin) VALUES ($email, $admin)"
        )
        stmt.run(["$email": "alice@example.com", "$admin": true])
        XCTAssertEqual(1, db.totalChanges)
    }

    func test_scalar_withNoParameters() {
        let zero = db.prepare("SELECT 0")
        XCTAssertEqual(0, zero.scalar() as Int)
    }

    func test_scalar_withNoParameters_retainsBindings() {
        let count = db.prepare("SELECT count(*) FROM users WHERE age >= ?", 21)
        XCTAssertEqual(0, count.scalar() as Int)

        InsertUser(db, "alice", age: 21)
        XCTAssertEqual(1, count.scalar() as Int)
    }

    func test_scalar_withVariadicParameters() {
        InsertUser(db, "alice", age: 21)
        let count = db.prepare("SELECT count(*) FROM users WHERE age >= ?")
        XCTAssertEqual(1, count.scalar(21) as Int)
    }

    func test_scalar_withArrayOfParameters() {
        InsertUser(db, "alice", age: 21)
        let count = db.prepare("SELECT count(*) FROM users WHERE age >= ?")
        XCTAssertEqual(1, count.scalar([21]) as Int)
    }

    func test_scalar_withNamedParameters() {
        InsertUser(db, "alice", age: 21)
        let count = db.prepare("SELECT count(*) FROM users WHERE age >= $age")
        XCTAssertEqual(1, count.scalar(["$age": 21]) as Int)
    }

    func test_scalar_withParameters_updatesBindings() {
        InsertUser(db, "alice", age: 21)
        let count = db.prepare("SELECT count(*) FROM users WHERE age >= ?")
        XCTAssertEqual(1, count.scalar(21) as Int)
        XCTAssertEqual(0, count.scalar(22) as Int)
    }

    func test_scalar_boolReturnValue() {
        InsertUser(db, "alice", admin: true)
        XCTAssertEqual(true, db.scalar("SELECT admin FROM users") as Bool)
    }

    func test_scalar_doubleReturnValue() {
        XCTAssertEqual(2.0, db.scalar("SELECT 2.0") as Double)
    }

    func test_scalar_intReturnValue() {
        XCTAssertEqual(3, db.scalar("SELECT 3") as Int)
    }

    func test_scalar_stringReturnValue() {
        XCTAssertEqual("4", db.scalar("SELECT '4'") as String)
    }

    func test_generate_allowsIteration() {
        InsertUsers(db, "alice", "betsy", "cindy")
        var count = 0
        for row in db.prepare("SELECT id FROM users") {
            XCTAssertEqual(1, row.count)
            count++
        }
        XCTAssertEqual(3, count)
    }

    func test_row_returnsArrayOfValues() {
        InsertUser(db, "alice")
        let stmt = db.prepare("SELECT id, email FROM users")
        stmt.next()

        let row = stmt.row!

        XCTAssertEqual(1, row[0] as Int)
        XCTAssertEqual("alice@example.com", row[1] as String)
    }

}

func withBlob(block: Blob -> ()) {
    let length = 1
    let buflen = Int(length) + 1
    let buffer = UnsafeMutablePointer<()>.alloc(buflen)
    memcpy(buffer, "4", UInt(length))
    block(Blob(bytes: buffer, length: length))
    buffer.dealloc(buflen)
}

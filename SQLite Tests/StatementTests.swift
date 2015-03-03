import XCTest
import SQLite

class StatementTests: XCTestCase {

    let db = Database()

    override func setUp() {
        super.setUp()

        CreateUsersTable(db)
    }

    func test_bind_withVariadicParameters_bindsParameters() {
        let stmt = db.prepare("SELECT ?, ?, ?, ?")
        ExpectExecutions(db, ["SELECT 1, 2.0, '3', x'34'": 1]) { _ in
            withBlob { blob in
                stmt.bind(1, 2.0, "3", blob).run()
                return
            }
        }
    }

    func test_bind_withArrayOfParameters_bindsParameters() {
        let stmt = db.prepare("SELECT ?, ?, ?, ?")
        ExpectExecutions(db, ["SELECT 1, 2.0, '3', x'34'": 1]) { _ in
            withBlob { blob in
                stmt.bind([1, 2.0, "3", blob]).run()
                return
            }
        }
    }

    func test_bind_withNamedParameters_bindsParameters() {
        let stmt = db.prepare("SELECT ?1, ?2, ?3, ?4")
        ExpectExecutions(db, ["SELECT 1, 2.0, '3', x'34'": 1]) { _ in
            withBlob { blob in
                stmt.bind(["?1": 1, "?2": 2.0, "?3": "3", "?4": blob]).run()
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
        stmt.run("alice@example.com", 1)
        XCTAssertEqual(1, db.totalChanges)
    }

    func test_run_withArrayOfParameters() {
        let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)")
        stmt.run(["alice@example.com", 1])
        XCTAssertEqual(1, db.totalChanges)
    }

    func test_run_withNamedParameters() {
        let stmt = db.prepare(
            "INSERT INTO users (email, admin) VALUES ($email, $admin)"
        )
        stmt.run(["$email": "alice@example.com", "$admin": 1])
        XCTAssertEqual(1, db.totalChanges)
    }

    func test_scalar_withNoParameters() {
        let zero = db.prepare("SELECT 0")
        XCTAssertEqual(Int64(0), zero.scalar() as Int64)
    }

    func test_scalar_withNoParameters_retainsBindings() {
        let count = db.prepare("SELECT count(*) FROM users WHERE age >= ?", 21)
        XCTAssertEqual(Int64(0), count.scalar() as Int64)

        InsertUser(db, "alice", age: 21)
        XCTAssertEqual(Int64(1), count.scalar() as Int64)
    }

    func test_scalar_withVariadicParameters() {
        InsertUser(db, "alice", age: 21)
        let count = db.prepare("SELECT count(*) FROM users WHERE age >= ?")
        XCTAssertEqual(Int64(1), count.scalar(21) as Int64)
    }

    func test_scalar_withArrayOfParameters() {
        InsertUser(db, "alice", age: 21)
        let count = db.prepare("SELECT count(*) FROM users WHERE age >= ?")
        XCTAssertEqual(Int64(1), count.scalar([21]) as Int64)
    }

    func test_scalar_withNamedParameters() {
        InsertUser(db, "alice", age: 21)
        let count = db.prepare("SELECT count(*) FROM users WHERE age >= $age")
        XCTAssertEqual(Int64(1), count.scalar(["$age": 21]) as Int64)
    }

    func test_scalar_withParameters_updatesBindings() {
        InsertUser(db, "alice", age: 21)
        let count = db.prepare("SELECT count(*) FROM users WHERE age >= ?")
        XCTAssertEqual(Int64(1), count.scalar(21) as Int64)
        XCTAssertEqual(Int64(0), count.scalar(22) as Int64)
    }

    func test_scalar_doubleReturnValue() {
        XCTAssertEqual(2.0, db.scalar("SELECT 2.0") as Double)
    }

    func test_scalar_intReturnValue() {
        XCTAssertEqual(Int64(3), db.scalar("SELECT 3") as Int64)
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

    func test_generate_allowsReuse() {
        InsertUsers(db, "alice", "betsy", "cindy")
        var count = 0
        let stmt = db.prepare("SELECT id FROM users")
        for row in stmt { count++ }
        for row in stmt { count++ }
        XCTAssertEqual(6, count)
    }

    func test_row_returnsValues() {
        InsertUser(db, "alice")
        let stmt = db.prepare("SELECT id, email FROM users")
        stmt.step()

        XCTAssertEqual(Int64(1), stmt.row[0] as Int64)
        XCTAssertEqual("alice@example.com", stmt.row[1] as String)
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

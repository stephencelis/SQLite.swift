import XCTest
import SQLite

class DatabaseTests: XCTestCase {

    let db = Database()

    override func setUp() {
        super.setUp()

        CreateUsersTable(db)
    }

    func test_readonly_returnsFalseOnReadWriteConnections() {
        XCTAssert(!db.readonly)
    }

    func test_readonly_returnsTrueOnReadOnlyConnections() {
        let db = Database(readonly: true)
        XCTAssert(db.readonly)
    }

    func test_lastID_returnsNilOnNewConnections() {
        XCTAssert(db.lastID == nil)
    }

    func test_lastID_returnsLastIDAfterInserts() {
        InsertUser(db, "alice")
        XCTAssert(db.lastID! == 1)
    }

    func test_lastChanges_returnsZeroOnNewConnections() {
        XCTAssertEqual(0, db.lastChanges)
    }

    func test_lastChanges_returnsNumberOfChanges() {
        InsertUser(db, "alice")
        XCTAssertEqual(1, db.lastChanges)
        InsertUser(db, "betsy")
        XCTAssertEqual(1, db.lastChanges)
    }

    func test_totalChanges_returnsTotalNumberOfChanges() {
        XCTAssertEqual(0, db.totalChanges)
        InsertUser(db, "alice")
        XCTAssertEqual(1, db.totalChanges)
        InsertUser(db, "betsy")
        XCTAssertEqual(2, db.totalChanges)
    }

    func test_prepare_preparesAndReturnsStatements() {
        db.prepare("SELECT * FROM users WHERE admin = 0")
        db.prepare("SELECT * FROM users WHERE admin = ?", false)
        db.prepare("SELECT * FROM users WHERE admin = ?", [false])
        db.prepare("SELECT * FROM users WHERE admin = $admin", ["$admin": false])
        // no-op assert-nothing-asserted
    }

    func test_run_preparesRunsAndReturnsStatements() {
        ExpectExecutions(db, ["SELECT * FROM users WHERE admin = 0": 4]) { db in
            db.run("SELECT * FROM users WHERE admin = 0")
            db.run("SELECT * FROM users WHERE admin = ?", false)
            db.run("SELECT * FROM users WHERE admin = ?", [false])
            db.run("SELECT * FROM users WHERE admin = $admin", ["$admin": false])
        }
    }

    func test_scalar_preparesRunsAndReturnsScalarValues() {
        XCTAssertEqual(0, db.scalar("SELECT count(*) FROM users WHERE admin = 0") as Int)
        XCTAssertEqual(0, db.scalar("SELECT count(*) FROM users WHERE admin = ?", false) as Int)
        XCTAssertEqual(0, db.scalar("SELECT count(*) FROM users WHERE admin = ?", [false]) as Int)
        XCTAssertEqual(0, db.scalar("SELECT count(*) FROM users WHERE admin = $admin", ["$admin": false]) as Int)
    }

    func test_transaction_beginsAndCommitsStatements() {
        let fulfilled = [
            "BEGIN DEFERRED TRANSACTION": 1,
            "COMMIT TRANSACTION": 1,
            "ROLLBACK TRANSACTION": 0
        ]
        ExpectExecutions(db, fulfilled) { db in
            let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)")
            db.transaction(stmt.bind("alice@example.com", true))
        }
    }

    func test_transaction_executesBeginDeferred() {
        ExpectExecutions(db, ["BEGIN DEFERRED TRANSACTION": 1]) { db in
            let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)")
            db.transaction(.Deferred, stmt.bind("alice@example.com", true))
        }
    }

    func test_transaction_executesBeginImmediate() {
        ExpectExecutions(db, ["BEGIN IMMEDIATE TRANSACTION": 1]) { db in
            let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)")
            db.transaction(.Immediate, stmt.bind("alice@example.com", true))
        }
    }

    func test_transaction_executesBeginExclusive() {
        ExpectExecutions(db, ["BEGIN EXCLUSIVE TRANSACTION": 1]) { db in
            let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)")
            db.transaction(.Exclusive, stmt.bind("alice@example.com", true))
        }
    }

    func test_transaction_rollsBackOnFailure() {
        let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)")
        db.transaction(stmt.bind("alice@example.com", true))
        let fulfilled = [
            "COMMIT TRANSACTION": 0,
            "ROLLBACK TRANSACTION": 1,
            "INSERT INTO users (email, admin) VALUES ('alice@example.com', 1)": 1
        ]
        var txn: Statement!
        ExpectExecutions(db, fulfilled) { db in
            txn = db.transaction(
                stmt.bind("alice@example.com", true),
                stmt.bind("alice@example.com", true)
            )
            return
        }
        XCTAssertTrue(txn.failed)
        XCTAssert(txn.reason!.lowercaseString.rangeOfString("unique") != nil)
    }

    func test_savepoint_nestsAndNamesSavepointsAutomatically() {
        let fulfilled = [
            "SAVEPOINT '1'": 1,
            "SAVEPOINT '2'": 2,
            "RELEASE SAVEPOINT '2'": 2,
            "RELEASE SAVEPOINT '1'": 1,
        ]
        ExpectExecutions(db, fulfilled) { db in
            db.savepoint(
                db.savepoint(
                    InsertUser(db, "alice"),
                    InsertUser(db, "betsy"),
                    InsertUser(db, "cindy")
                ),
                db.savepoint(
                    InsertUser(db, "donna"),
                    InsertUser(db, "emery"),
                    InsertUser(db, "flint")
                )
            )
            return
        }
    }

    func test_savepoint_rollsBackOnFailure() {
        let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)")
        let fulfilled = [
            "SAVEPOINT '1'": 1,
            "SAVEPOINT '2'": 1,
            "RELEASE SAVEPOINT '2'": 0,
            "RELEASE SAVEPOINT '1'": 0,
            "ROLLBACK TO SAVEPOINT '1'": 1,
            "INSERT INTO users (email, admin) VALUES ('alice@example.com', 1)": 2
        ]
        ExpectExecutions(db, fulfilled) { db in
            db.savepoint(
                db.savepoint(
                    stmt.run("alice@example.com", true),
                    stmt.run("alice@example.com", true),
                    stmt.run("alice@example.com", true)
                ),
                db.savepoint(
                    stmt.run("alice@example.com", true),
                    stmt.run("alice@example.com", true),
                    stmt.run("alice@example.com", true)
                )
            )
            return
        }
    }

    func test_savepoint_quotesNames() {
        let fulfilled = [
            "SAVEPOINT 'That''s all, Folks!'": 1,
            "RELEASE SAVEPOINT 'That''s all, Folks!'": 1
        ]
        ExpectExecutions(db, fulfilled) { db in
            db.savepoint("That's all, Folks!", db.run("SELECT 1"))
            return
        }
    }

    func test_userVersion_getsAndSetsUserVersion() {
        XCTAssertEqual(0, db.userVersion)
        db.userVersion = 1
        XCTAssertEqual(1, db.userVersion)
    }

}

import XCTest
import SQLite

class ConnectionTests : SQLiteTestCase {

    override func setUp() {
        super.setUp()

        CreateUsersTable()
    }

    func test_init_withInMemory_returnsInMemoryConnection() {
        let db = try! Connection(.inMemory)
        XCTAssertEqual("", db.description)
    }

    func test_init_returnsInMemoryByDefault() {
        let db = try! Connection()
        XCTAssertEqual("", db.description)
    }

    func test_init_withTemporary_returnsTemporaryConnection() {
        let db = try! Connection(.temporary)
        XCTAssertEqual("", db.description)
    }

    func test_init_withURI_returnsURIConnection() {
        let db = try! Connection(.uri("\(NSTemporaryDirectory())/SQLite.swift Tests.sqlite3"))
        XCTAssertEqual("\(NSTemporaryDirectory())/SQLite.swift Tests.sqlite3", db.description)
    }

    func test_init_withString_returnsURIConnection() {
        let db = try! Connection("\(NSTemporaryDirectory())/SQLite.swift Tests.sqlite3")
        XCTAssertEqual("\(NSTemporaryDirectory())/SQLite.swift Tests.sqlite3", db.description)
    }

    func test_readonly_returnsFalseOnReadWriteConnections() {
        XCTAssertFalse(db.readonly)
    }

    func test_readonly_returnsTrueOnReadOnlyConnections() {
        let db = try! Connection(readonly: true)
        XCTAssertTrue(db.readonly)
    }

    func test_lastInsertRowid_returnsNilOnNewConnections() {
        XCTAssert(db.lastInsertRowid == nil)
    }

    func test_lastInsertRowid_returnsLastIdAfterInserts() {
        _ = try! InsertUser("alice")
        XCTAssertEqual(1, db.lastInsertRowid!)
    }

    func test_changes_returnsZeroOnNewConnections() {
        XCTAssertEqual(0, db.changes)
    }

    func test_changes_returnsNumberOfChanges() {
        _ = try! InsertUser("alice")
        XCTAssertEqual(1, db.changes)
        _ = try! InsertUser("betsy")
        XCTAssertEqual(1, db.changes)
    }

    func test_totalChanges_returnsTotalNumberOfChanges() {
        XCTAssertEqual(0, db.totalChanges)
        _ = try! InsertUser("alice")
        XCTAssertEqual(1, db.totalChanges)
        _ = try! InsertUser("betsy")
        XCTAssertEqual(2, db.totalChanges)
    }

    func test_prepare_preparesAndReturnsStatements() {
        _ = try! db.prepare("SELECT * FROM users WHERE admin = 0")
        _ = try! db.prepare("SELECT * FROM users WHERE admin = ?", 0)
        _ = try! db.prepare("SELECT * FROM users WHERE admin = ?", [0])
        _ = try! db.prepare("SELECT * FROM users WHERE admin = $admin", ["$admin": 0])
    }

    func test_run_preparesRunsAndReturnsStatements() {
        _ = try! db.run("SELECT * FROM users WHERE admin = 0")
        _ = try! db.run("SELECT * FROM users WHERE admin = ?", 0)
        _ = try! db.run("SELECT * FROM users WHERE admin = ?", [0])
        _ = try! db.run("SELECT * FROM users WHERE admin = $admin", ["$admin": 0])
        AssertSQL("SELECT * FROM users WHERE admin = 0", 4)
    }

    func test_scalar_preparesRunsAndReturnsScalarValues() {
        XCTAssertEqual(0, try! db.scalar("SELECT count(*) FROM users WHERE admin = 0") as? Int64)
        XCTAssertEqual(0, try! db.scalar("SELECT count(*) FROM users WHERE admin = ?", 0) as? Int64)
        XCTAssertEqual(0, try! db.scalar("SELECT count(*) FROM users WHERE admin = ?", [0]) as? Int64)
        XCTAssertEqual(0, try! db.scalar("SELECT count(*) FROM users WHERE admin = $admin", ["$admin": 0]) as? Int64)
        AssertSQL("SELECT count(*) FROM users WHERE admin = 0", 4)
    }

    func test_transaction_executesBeginDeferred() {
        try! db.transaction(.Deferred) {}

        AssertSQL("BEGIN DEFERRED TRANSACTION")
    }

    func test_transaction_executesBeginImmediate() {
        try! db.transaction(.Immediate) {}

        AssertSQL("BEGIN IMMEDIATE TRANSACTION")
    }

    func test_transaction_executesBeginExclusive() {
        try! db.transaction(.Exclusive) {}

        AssertSQL("BEGIN EXCLUSIVE TRANSACTION")
    }

    func test_transaction_beginsAndCommitsTransactions() {
        let stmt = try! db.prepare("INSERT INTO users (email) VALUES (?)", "alice@example.com")

        try! db.transaction {
            _ = try stmt.run()
        }

        AssertSQL("BEGIN DEFERRED TRANSACTION")
        AssertSQL("INSERT INTO users (email) VALUES ('alice@example.com')")
        AssertSQL("COMMIT TRANSACTION")
        AssertSQL("ROLLBACK TRANSACTION", 0)
    }

    func test_transaction_rollsBackTransactionsIfCommitsFail() {
        // This test case needs to emulate an environment where the individual statements succeed, but committing the
        // transactuin fails. Using deferred foreign keys is one option to achieve this.
        try! db.execute("PRAGMA foreign_keys = ON;")
        try! db.execute("PRAGMA defer_foreign_keys = ON;")
        let stmt = try! db.prepare("INSERT INTO users (email, manager_id) VALUES (?, ?)", "alice@example.com", 100)

        do {
            try db.transaction {
                try stmt.run()
            }
        } catch {
        }

        AssertSQL("BEGIN DEFERRED TRANSACTION")
        AssertSQL("INSERT INTO users (email, manager_id) VALUES ('alice@example.com', 100)")
        AssertSQL("COMMIT TRANSACTION")
        AssertSQL("ROLLBACK TRANSACTION")

        // Run another transaction to ensure that a subsequent transaction does not fail with an "cannot start a
        // transaction within a transaction" error.
        let stmt2 = try! db.prepare("INSERT INTO users (email) VALUES (?)", "alice@example.com")
        try! db.transaction {
            try stmt2.run()
        }
    }

    func test_transaction_beginsAndRollsTransactionsBack() {
        let stmt = try! db.prepare("INSERT INTO users (email) VALUES (?)", "alice@example.com")

        do {
            try db.transaction {
                _ = try stmt.run()
                _ = try stmt.run()
            }
        } catch {
        }

        AssertSQL("BEGIN DEFERRED TRANSACTION")
        AssertSQL("INSERT INTO users (email) VALUES ('alice@example.com')", 2)
        AssertSQL("ROLLBACK TRANSACTION")
        AssertSQL("COMMIT TRANSACTION", 0)
    }

    func test_savepoint_beginsAndCommitsSavepoints() {
        let db = self.db

        try! db.savepoint("1") {
            try db.savepoint("2") {
                _ = try db.run("INSERT INTO users (email) VALUES (?)", "alice@example.com")
            }
        }

        AssertSQL("SAVEPOINT '1'")
        AssertSQL("SAVEPOINT '2'")
        AssertSQL("INSERT INTO users (email) VALUES ('alice@example.com')")
        AssertSQL("RELEASE SAVEPOINT '2'")
        AssertSQL("RELEASE SAVEPOINT '1'")
        AssertSQL("ROLLBACK TO SAVEPOINT '2'", 0)
        AssertSQL("ROLLBACK TO SAVEPOINT '1'", 0)
    }

    func test_savepoint_beginsAndRollsSavepointsBack() {
        let db = self.db
        let stmt = try! db.prepare("INSERT INTO users (email) VALUES (?)", "alice@example.com")

        do {
            try db.savepoint("1") {
                try db.savepoint("2") {
                    _ = try stmt.run()
                    _ = try stmt.run()
                    _ = try stmt.run()
                }
                try db.savepoint("2") {
                    _ = try stmt.run()
                    _ = try stmt.run()
                    _ = try stmt.run()
                }
            }
        } catch {
        }

        AssertSQL("SAVEPOINT '1'")
        AssertSQL("SAVEPOINT '2'")
        AssertSQL("INSERT INTO users (email) VALUES ('alice@example.com')", 2)
        AssertSQL("ROLLBACK TO SAVEPOINT '2'")
        AssertSQL("ROLLBACK TO SAVEPOINT '1'")
        AssertSQL("RELEASE SAVEPOINT '2'", 0)
        AssertSQL("RELEASE SAVEPOINT '1'", 0)
    }

    func test_updateHook_setsUpdateHook_withInsert() {
        async { done in
            db.updateHook { operation, db, table, rowid in
                XCTAssertEqual(Operation.insert, operation)
                XCTAssertEqual("main", db)
                XCTAssertEqual("users", table)
                XCTAssertEqual(1, rowid)
                done()
            }
            _ = try! InsertUser("alice")
        }
    }

    func test_updateHook_setsUpdateHook_withUpdate() {
        _ = try! InsertUser("alice")
        async { done in
            db.updateHook { operation, db, table, rowid in
                XCTAssertEqual(Operation.update, operation)
                XCTAssertEqual("main", db)
                XCTAssertEqual("users", table)
                XCTAssertEqual(1, rowid)
                done()
            }
            _ = try! db.run("UPDATE users SET email = 'alice@example.com'")
        }
    }

    func test_updateHook_setsUpdateHook_withDelete() {
        _ = try! InsertUser("alice")
        async { done in
            db.updateHook { operation, db, table, rowid in
                XCTAssertEqual(Operation.delete, operation)
                XCTAssertEqual("main", db)
                XCTAssertEqual("users", table)
                XCTAssertEqual(1, rowid)
                done()
            }
            _ = try! db.run("DELETE FROM users WHERE id = 1")
        }
    }

    func test_commitHook_setsCommitHook() {
        async { done in
            db.commitHook {
                done()
            }
            try! db.transaction {
                _ = try self.InsertUser("alice")
            }
            XCTAssertEqual(1, try! db.scalar("SELECT count(*) FROM users") as? Int64)
        }
    }

    func test_rollbackHook_setsRollbackHook() {
        async { done in
            db.rollbackHook(done)
            do {
                try db.transaction {
                    _ = try self.InsertUser("alice")
                    _ = try self.InsertUser("alice") // throw
                }
            } catch {
            }
            XCTAssertEqual(0, try! db.scalar("SELECT count(*) FROM users") as? Int64)
        }
    }

    func test_commitHook_withRollback_rollsBack() {
        async { done in
            db.commitHook {
                throw NSError(domain: "com.stephencelis.SQLiteTests", code: 1, userInfo: nil)
            }
            db.rollbackHook(done)
            do {
                try db.transaction {
                    _ = try self.InsertUser("alice")
                }
            } catch {
            }
            XCTAssertEqual(0, try! db.scalar("SELECT count(*) FROM users") as? Int64)
        }
    }

    func test_createFunction_withArrayArguments() {
        db.createFunction("hello") { $0[0].map { "Hello, \($0)!" } }

        XCTAssertEqual("Hello, world!", try! db.scalar("SELECT hello('world')") as? String)
        XCTAssert(try! db.scalar("SELECT hello(NULL)") == nil)
    }

    func test_createFunction_createsQuotableFunction() {
        db.createFunction("hello world") { $0[0].map { "Hello, \($0)!" } }

        XCTAssertEqual("Hello, world!", try! db.scalar("SELECT \"hello world\"('world')") as? String)
        XCTAssert(try! db.scalar("SELECT \"hello world\"(NULL)") == nil)
    }

    func test_createCollation_createsCollation() {
        try! db.createCollation("NODIACRITIC") { lhs, rhs in
            return lhs.compare(rhs, options: .diacriticInsensitive)
        }
        XCTAssertEqual(1, try! db.scalar("SELECT ? = ? COLLATE NODIACRITIC", "cafe", "café") as? Int64)
    }

    func test_createCollation_createsQuotableCollation() {
        try! db.createCollation("NO DIACRITIC") { lhs, rhs in
            return lhs.compare(rhs, options: .diacriticInsensitive)
        }
        XCTAssertEqual(1, try! db.scalar("SELECT ? = ? COLLATE \"NO DIACRITIC\"", "cafe", "café") as? Int64)
    }

    func test_interrupt_interruptsLongRunningQuery() {
        try! InsertUsers("abcdefghijklmnopqrstuvwxyz".characters.map { String($0) })
        db.createFunction("sleep") { args in
            usleep(UInt32((args[0] as? Double ?? Double(args[0] as? Int64 ?? 1)) * 1_000_000))
            return nil
        }

        let stmt = try! db.prepare("SELECT *, sleep(?) FROM users", 0.1)
        _ = try! stmt.run()

        _ = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).asyncAfter(deadline: DispatchTime.now() + Double(Int64(10 * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC), execute: db.interrupt)
        AssertThrows(try stmt.run())
    }

}

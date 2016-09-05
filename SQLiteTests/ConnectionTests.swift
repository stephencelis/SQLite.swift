import XCTest
import SQLite

class ConnectionTests : SQLiteTestCase {

    override func setUp() {
        super.setUp()

        CreateUsersTable()
    }

    func test_init_withInMemory_returnsInMemoryConnection() {
        _ = try! Connection(.inMemory)
        XCTAssertEqual("", self.db.description)
    }

    func test_init_returnsInMemoryByDefault() {
        _ = try! Connection()
        XCTAssertEqual("", self.db.description)
    }

    func test_init_withTemporary_returnsTemporaryConnection() {
        let db = try! Connection(.temporary)
        XCTAssertEqual("", self.db.description)
    }

    func test_init_withURI_returnsURIConnection() {
        let db = try! Connection(.uri("\(NSTemporaryDirectory())/SQLite.swift Tests.sqlite3"))
        XCTAssertEqual("\(NSTemporaryDirectory())/SQLite.swift Tests.sqlite3", self.db.description)
    }

    func test_init_withString_returnsURIConnection() {
        let db = try! Connection("\(NSTemporaryDirectory())/SQLite.swift Tests.sqlite3")
        XCTAssertEqual("\(NSTemporaryDirectory())/SQLite.swift Tests.sqlite3", self.db.description)
    }

    func test_readonly_returnsFalseOnReadWriteConnections() {
        XCTAssertFalse(self.db.readonly)
    }

    func test_readonly_returnsTrueOnReadOnlyConnections() {
        let db = try! Connection(readonly: true)
        XCTAssertTrue(self.db.readonly)
    }

    func test_lastInsertRowid_returnsNilOnNewConnections() {
        XCTAssert(self.db.lastInsertRowid == nil)
    }

    func test_lastInsertRowid_returnsLastIdAfterInserts() {
        try! InsertUser("alice")
        XCTAssertEqual(1, self.db.lastInsertRowid!)
    }

    func test_changes_returnsZeroOnNewConnections() {
        XCTAssertEqual(0, self.db.changes)
    }

    func test_changes_returnsNumberOfChanges() {
        try! InsertUser("alice")
        XCTAssertEqual(1, self.db.changes)
        try! InsertUser("betsy")
        XCTAssertEqual(1, self.db.changes)
    }

    func test_totalChanges_returnsTotalNumberOfChanges() {
        XCTAssertEqual(0, self.db.totalChanges)
        try! InsertUser("alice")
        XCTAssertEqual(1, self.db.totalChanges)
        try! InsertUser("betsy")
        XCTAssertEqual(2, self.db.totalChanges)
    }

    func test_prepare_preparesAndReturnsStatements() {
        _ = try! self.db.prepare("SELECT * FROM users WHERE admin = 0")
        _ = try! self.db.prepare("SELECT * FROM users WHERE admin = ?", 0)
        _ = try! self.db.prepare("SELECT * FROM users WHERE admin = ?", [0])
        _ = try! self.db.prepare("SELECT * FROM users WHERE admin = $admin", ["$admin": 0])
    }

    func test_run_preparesRunsAndReturnsStatements() {
        try! self.db.run("SELECT * FROM users WHERE admin = 0")
        try! self.db.run("SELECT * FROM users WHERE admin = ?", 0)
        try! self.db.run("SELECT * FROM users WHERE admin = ?", [0])
        try! self.db.run("SELECT * FROM users WHERE admin = $admin", ["$admin": 0])
        AssertSQL("SELECT * FROM users WHERE admin = 0", 4)
    }

    func test_scalar_preparesRunsAndReturnsScalarValues() {
        XCTAssertEqual(0, self.db.scalar("SELECT count(*) FROM users WHERE admin = 0") as? Int64)
        XCTAssertEqual(0, self.db.scalar("SELECT count(*) FROM users WHERE admin = ?", 0) as? Int64)
        XCTAssertEqual(0, self.db.scalar("SELECT count(*) FROM users WHERE admin = ?", [0]) as? Int64)
        XCTAssertEqual(0, self.db.scalar("SELECT count(*) FROM users WHERE admin = $admin", ["$admin": 0]) as? Int64)
        AssertSQL("SELECT count(*) FROM users WHERE admin = 0", 4)
    }

    func test_transaction_executesBeginDeferred() {
        try! self.db.transaction(.Deferred) {}

        AssertSQL("BEGIN DEFERRED TRANSACTION")
    }

    func test_transaction_executesBeginImmediate() {
        try! self.db.transaction(.Immediate) {}

        AssertSQL("BEGIN IMMEDIATE TRANSACTION")
    }

    func test_transaction_executesBeginExclusive() {
        try! self.db.transaction(.Exclusive) {}

        AssertSQL("BEGIN EXCLUSIVE TRANSACTION")
    }

    func test_transaction_beginsAndCommitsTransactions() {
        let stmt = try! self.db.prepare("INSERT INTO users (email) VALUES (?)", "alice@example.com")

        try! self.db.transaction {
            try stmt.run()
        }

        AssertSQL("BEGIN DEFERRED TRANSACTION")
        AssertSQL("INSERT INTO users (email) VALUES ('alice@example.com')")
        AssertSQL("COMMIT TRANSACTION")
        AssertSQL("ROLLBACK TRANSACTION", 0)
    }

    func test_transaction_beginsAndRollsTransactionsBack() {
        let stmt = try! self.db.prepare("INSERT INTO users (email) VALUES (?)", "alice@example.com")

        do {
            try self.db.transaction {
                try stmt.run()
                try stmt.run()
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

        try! self.db.savepoint("1") {
            try self.db.savepoint("2") {
                try self.db.run("INSERT INTO users (email) VALUES (?)", "alice@example.com")
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
        let stmt = try! self.db.prepare("INSERT INTO users (email) VALUES (?)", "alice@example.com")

        do {
            try self.db.savepoint("1") {
                try self.db.savepoint("2") {
                    try stmt.run()
                    try stmt.run()
                    try stmt.run()
                }
                try self.db.savepoint("2") {
                    try stmt.run()
                    try stmt.run()
                    try stmt.run()
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
            self.db.updateHook { operation, db, table, rowid in
                XCTAssertEqual(Operation.insert, operation)
                XCTAssertEqual("main", db)
                XCTAssertEqual("users", table)
                XCTAssertEqual(1, rowid)
                // done()
            }
            try! self.InsertUser("alice")
        }
    }

    func test_updateHook_setsUpdateHook_withUpdate() {
        try! InsertUser("alice")
        async { done in
            self.db.updateHook { operation, db, table, rowid in
                XCTAssertEqual(Operation.update, operation)
                XCTAssertEqual("main", db)
                XCTAssertEqual("users", table)
                XCTAssertEqual(1, rowid)
                // // done()
            }
            try! self.db.run("UPDATE users SET email = 'alice@example.com'")
        }
    }

    func test_updateHook_setsUpdateHook_withDelete() {
        try! InsertUser("alice")
        async { done in
            self.db.updateHook { operation, db, table, rowid in
                XCTAssertEqual(Operation.delete, operation)
                XCTAssertEqual("main", db)
                XCTAssertEqual("users", table)
                XCTAssertEqual(1, rowid)
                // done()
            }
            try! self.db.run("DELETE FROM users WHERE id = 1")
        }
    }

    func test_commitHook_setsCommitHook() {
        async { done in
            self.db.commitHook {
                // done()
            }
            try! self.db.transaction {
                try self.InsertUser("alice")
            }
            XCTAssertEqual(1, self.db.scalar("SELECT count(*) FROM users") as? Int64)
        }
    }

    func test_rollbackHook_setsRollbackHook() {
        async { done in
            self.db.rollbackHook({ 
                // done()
            })
            do {
                try self.db.transaction {
                    try self.InsertUser("alice")
                    try self.InsertUser("alice") // throw
                }
            } catch {
            }
            XCTAssertEqual(0, self.db.scalar("SELECT count(*) FROM users") as? Int64)
        }
    }

    func test_commitHook_withRollback_rollsBack() {
        async { done in
            self.db.commitHook {
                throw NSError(domain: "com.stephencelis.SQLiteTests", code: 1, userInfo: nil)
            }
            self.db.rollbackHook({ 
                // done()
            })
            do {
                try self.db.transaction {
                    try self.InsertUser("alice")
                }
            } catch {
            }
            XCTAssertEqual(0, self.db.scalar("SELECT count(*) FROM users") as? Int64)
        }
    }

    func test_createFunction_withArrayArguments() {
        self.db.createFunction("hello") { $0[0].map { "Hello, \($0)!" } }

        XCTAssertEqual("Hello, world!", self.db.scalar("SELECT hello('world')") as? String)
        XCTAssert(self.db.scalar("SELECT hello(NULL)") == nil)
    }

    func test_createFunction_createsQuotableFunction() {
        self.db.createFunction("hello world") { $0[0].map { "Hello, \($0)!" } }

        XCTAssertEqual("Hello, world!", self.db.scalar("SELECT \"hello world\"('world')") as? String)
        XCTAssert(self.db.scalar("SELECT \"hello world\"(NULL)") == nil)
    }

    func test_createCollation_createsCollation() {
        self.db.createCollation("NODIACRITIC") { lhs, rhs in
            return lhs.compare(rhs, options: .diacriticInsensitive)
        }
        XCTAssertEqual(1, self.db.scalar("SELECT ? = ? COLLATE NODIACRITIC", "cafe", "café") as? Int64)
    }

    func test_createCollation_createsQuotableCollation() {
        self.db.createCollation("NO DIACRITIC") { lhs, rhs in
            return lhs.compare(rhs, options: .diacriticInsensitive)
        }
        XCTAssertEqual(1, self.db.scalar("SELECT ? = ? COLLATE \"NO DIACRITIC\"", "cafe", "café") as? Int64)
    }

    func test_interrupt_interruptsLongRunningQuery() {
        try! InsertUsers("abcdefghijklmnopqrstuvwxyz".characters.map { String($0) })
        self.db.createFunction("sleep") { args in
            usleep(UInt32((args[0] as? Double ?? Double(args[0] as? Int64 ?? 1)) * 1_000_000))
            return nil
        }

        let stmt = try! self.db.prepare("SELECT *, sleep(?) FROM users", 0.1)
        try! stmt.run()

        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
            
        queue.asyncAfter(deadline: DispatchTime.now() + Double(Int64(10 * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC), execute: self.db.interrupt)
        
        AssertThrows(try stmt.run())
    }

}

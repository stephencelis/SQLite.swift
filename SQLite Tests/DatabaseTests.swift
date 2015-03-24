import XCTest
import SQLite

class DatabaseTests: SQLiteTestCase {

    override func setUp() {
        super.setUp()

        createUsersTable()
    }

    func test_readonly_returnsFalseOnReadWriteConnections() {
        XCTAssert(!db.readonly)
    }

    func test_readonly_returnsTrueOnReadOnlyConnections() {
        let db = Database(readonly: true)
        XCTAssert(db.readonly)
    }

    func test_lastId_returnsNilOnNewConnections() {
        XCTAssert(db.lastId == nil)
    }

    func test_lastId_returnsLastIdAfterInserts() {
        insertUser("alice")
        XCTAssert(db.lastId! == 1)
    }

    func test_lastChanges_returnsZeroOnNewConnections() {
        XCTAssertEqual(0, db.lastChanges)
    }

    func test_lastChanges_returnsNumberOfChanges() {
        insertUser("alice")
        XCTAssertEqual(1, db.lastChanges)
        insertUser("betsy")
        XCTAssertEqual(1, db.lastChanges)
    }

    func test_totalChanges_returnsTotalNumberOfChanges() {
        XCTAssertEqual(0, db.totalChanges)
        insertUser("alice")
        XCTAssertEqual(1, db.totalChanges)
        insertUser("betsy")
        XCTAssertEqual(2, db.totalChanges)
    }

    func test_prepare_preparesAndReturnsStatements() {
        db.prepare("SELECT * FROM users WHERE admin = 0")
        db.prepare("SELECT * FROM users WHERE admin = ?", 0)
        db.prepare("SELECT * FROM users WHERE admin = ?", [0])
        db.prepare("SELECT * FROM users WHERE admin = $admin", ["$admin": 0])
        // no-op assert-nothing-asserted
    }

    func test_run_preparesRunsAndReturnsStatements() {
        db.run("SELECT * FROM users WHERE admin = 0")
        db.run("SELECT * FROM users WHERE admin = ?", 0)
        db.run("SELECT * FROM users WHERE admin = ?", [0])
        db.run("SELECT * FROM users WHERE admin = $admin", ["$admin": 0])
        AssertSQL("SELECT * FROM users WHERE admin = 0", 4)
    }

    func test_scalar_preparesRunsAndReturnsScalarValues() {
        XCTAssertEqual(0, db.scalar("SELECT count(*) FROM users WHERE admin = 0") as! Int64)
        XCTAssertEqual(0, db.scalar("SELECT count(*) FROM users WHERE admin = ?", 0) as! Int64)
        XCTAssertEqual(0, db.scalar("SELECT count(*) FROM users WHERE admin = ?", [0]) as! Int64)
        XCTAssertEqual(0, db.scalar("SELECT count(*) FROM users WHERE admin = $admin", ["$admin": 0]) as! Int64)
        AssertSQL("SELECT count(*) FROM users WHERE admin = 0", 4)
    }

    func test_transaction_executesBeginDeferred() {
        db.transaction(.Deferred) { _ in .Commit }

        AssertSQL("BEGIN DEFERRED TRANSACTION")
    }

    func test_transaction_executesBeginImmediate() {
        db.transaction(.Immediate) { _ in .Commit }

        AssertSQL("BEGIN IMMEDIATE TRANSACTION")
    }

    func test_transaction_executesBeginExclusive() {
        db.transaction(.Exclusive) { _ in .Commit }

        AssertSQL("BEGIN EXCLUSIVE TRANSACTION")
    }

    func test_commit_commitsTransaction() {
        db.transaction()

        db.commit()

        AssertSQL("COMMIT TRANSACTION")
    }

    func test_rollback_rollsTransactionBack() {
        db.transaction()

        db.rollback()

        AssertSQL("ROLLBACK TRANSACTION")
    }

    func test_transaction_beginsAndCommitsTransactions() {
        let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)", "alice@example.com", 1)

        db.transaction { _ in stmt.run().failed ? .Rollback : .Commit }

        AssertSQL("BEGIN DEFERRED TRANSACTION")
        AssertSQL("INSERT INTO users (email, admin) VALUES ('alice@example.com', 1)")
        AssertSQL("COMMIT TRANSACTION")
        AssertSQL("ROLLBACK TRANSACTION", 0)
    }

    func test_transaction_beginsAndRollsTransactionsBack() {
        let stmt = db.run("INSERT INTO users (email, admin) VALUES (?, ?)", "alice@example.com", 1)

        db.transaction { _ in stmt.run().failed ? .Rollback : .Commit }

        AssertSQL("BEGIN DEFERRED TRANSACTION")
        AssertSQL("INSERT INTO users (email, admin) VALUES ('alice@example.com', 1)", 2)
        AssertSQL("ROLLBACK TRANSACTION")
        AssertSQL("COMMIT TRANSACTION", 0)
    }

    func test_transaction_withOperators_allowsForFlowControl() {
        let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)")
        let txn = db.transaction() &&
            stmt.bind("alice@example.com", 1) &&
            stmt.bind("alice@example.com", 1) &&
            stmt.bind("alice@example.com", 1) &&
            db.commit()
        txn || db.rollback()

        XCTAssertTrue(txn.failed)
        XCTAssert(txn.reason!.lowercaseString.rangeOfString("unique") != nil)

        AssertSQL("INSERT INTO users (email, admin) VALUES ('alice@example.com', 1)", 2)
        AssertSQL("ROLLBACK TRANSACTION")
        AssertSQL("COMMIT TRANSACTION", 0)
    }

    func test_savepoint_quotesSavepointNames() {
        db.savepoint("That's all, Folks!")

        AssertSQL("SAVEPOINT 'That''s all, Folks!'")
    }

    func test_release_quotesSavepointNames() {
        let savepointName = "That's all, Folks!"
        db.savepoint(savepointName)

        db.release(savepointName)

        AssertSQL("RELEASE SAVEPOINT 'That''s all, Folks!'")
    }

    func test_release_defaultsToCurrentSavepointName() {
        db.savepoint("Hello, World!")

        db.release()

        AssertSQL("RELEASE SAVEPOINT 'Hello, World!'")
    }

    func test_release_maintainsTheSavepointNameStack() {
        db.savepoint("1")
        db.savepoint("2")
        db.savepoint("3")

        db.release("2")
        db.release()

        AssertSQL("RELEASE SAVEPOINT '2'")
        AssertSQL("RELEASE SAVEPOINT '1'")
        AssertSQL("RELEASE SAVEPOINT '3'", 0)
    }

    func test_rollback_quotesSavepointNames() {
        let savepointName = "That's all, Folks!"
        db.savepoint(savepointName)

        db.rollback(savepointName)

        AssertSQL("ROLLBACK TO SAVEPOINT 'That''s all, Folks!'")
    }

    func test_rollback_defaultsToCurrentSavepointName() {
        db.savepoint("Hello, World!")

        db.rollback()

        AssertSQL("ROLLBACK TO SAVEPOINT 'Hello, World!'")
    }

    func test_rollback_maintainsTheSavepointNameStack() {
        db.savepoint("1")
        db.savepoint("2")
        db.savepoint("3")

        db.rollback("2")
        db.rollback()

        AssertSQL("ROLLBACK TO SAVEPOINT '2'")
        AssertSQL("ROLLBACK TO SAVEPOINT '1'")
        AssertSQL("ROLLBACK TO SAVEPOINT '3'", 0)
    }

    func test_savepoint_beginsAndReleasesTransactions() {
        let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)", "alice@example.com", 1)

        db.savepoint("1") { _ in stmt.run().failed ? .Rollback : .Release }

        AssertSQL("SAVEPOINT '1'")
        AssertSQL("INSERT INTO users (email, admin) VALUES ('alice@example.com', 1)")
        AssertSQL("RELEASE SAVEPOINT '1'")
        AssertSQL("ROLLBACK TO SAVEPOINT '1'", 0)
    }

    func test_savepoint_beginsAndRollsTransactionsBack() {
        let stmt = db.run("INSERT INTO users (email, admin) VALUES (?, ?)", "alice@example.com", 1)

        db.savepoint("1") { _ in stmt.run().failed ? .Rollback : .Release }

        AssertSQL("SAVEPOINT '1'")
        AssertSQL("INSERT INTO users (email, admin) VALUES ('alice@example.com', 1)", 2)
        AssertSQL("ROLLBACK TO SAVEPOINT '1'", 1)
        AssertSQL("RELEASE SAVEPOINT '1'", 0)
    }

    func test_savepoint_withOperators_allowsForFlowControl() {
        let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)")

        var txn = db.savepoint("1")

        txn = txn && (
            db.savepoint("2") &&
                stmt.run("alice@example.com", 1) &&
                stmt.run("alice@example.com", 1) &&
                stmt.run("alice@example.com", 1) &&
                db.release()
        )
        txn || db.rollback()

        txn = txn && (
            db.savepoint("2") &&
                stmt.run("alice@example.com", 1) &&
                stmt.run("alice@example.com", 1) &&
                stmt.run("alice@example.com", 1) &&
                db.release()
        )
        txn || db.rollback()

        txn && db.release() || db.rollback()

        AssertSQL("SAVEPOINT '1'")
        AssertSQL("SAVEPOINT '2'")
        AssertSQL("RELEASE SAVEPOINT '2'", 0)
        AssertSQL("RELEASE SAVEPOINT '1'", 0)
        AssertSQL("ROLLBACK TO SAVEPOINT '1'")
        AssertSQL("INSERT INTO users (email, admin) VALUES ('alice@example.com', 1)", 2)
    }

    func test_interrupt_interruptsLongRunningQuery() {
        insertUsers(map("abcdefghijklmnopqrstuvwxyz") { String($0) })
        db.create(function: "sleep") { args in
            usleep(UInt32(Double(args[0] as? Double ?? Double(args[0] as? Int64 ?? 1)) * 1_000_000))
            return nil
        }

        let stmt = db.prepare("SELECT *, sleep(?) FROM users", 0.1)
        stmt.run()
        XCTAssert(!stmt.failed)

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(10 * NSEC_PER_MSEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), db.interrupt)
        stmt.run()
        XCTAssert(stmt.failed)
    }

    func test_userVersion_getsAndSetsUserVersion() {
        XCTAssertEqual(0, db.userVersion)
        db.userVersion = 1
        XCTAssertEqual(1, db.userVersion)
    }

    func test_foreignKeys_getsAndSetsForeignKeys() {
        XCTAssertEqual(false, db.foreignKeys)
        db.foreignKeys = true
        XCTAssertEqual(true, db.foreignKeys)
    }

    func test_createFunction_withArrayArguments() {
        db.create(function: "hello") { $0[0].map { "Hello, \($0)!" } }

        XCTAssertEqual("Hello, world!", db.scalar("SELECT hello('world')") as! String)
        XCTAssert(db.scalar("SELECT hello(NULL)") == nil)
    }

    func test_createFunction_createsQuotableFunction() {
        db.create(function: "hello world") { $0[0].map { "Hello, \($0)!" } }

        XCTAssertEqual("Hello, world!", db.scalar("SELECT \"hello world\"('world')") as! String)
        XCTAssert(db.scalar("SELECT \"hello world\"(NULL)") == nil)
    }

    func test_createCollation_createsCollation() {
        db.create(collation: "NODIACRITIC") { lhs, rhs in
            return lhs.compare(rhs, options: .DiacriticInsensitiveSearch)
        }
        XCTAssertEqual(1, db.scalar("SELECT ? = ? COLLATE NODIACRITIC", "cafe", "café") as! Int64)
    }

    func test_createCollation_createsQuotableCollation() {
        db.create(collation: "NO DIACRITIC") { lhs, rhs in
            return lhs.compare(rhs, options: .DiacriticInsensitiveSearch)
        }
        XCTAssertEqual(1, db.scalar("SELECT ? = ? COLLATE \"NO DIACRITIC\"", "cafe", "café") as! Int64)
    }

}

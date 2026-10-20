import XCTest
import Foundation
@testable import SQLite

@MainActor
class ConnectionHookTests: SQLiteTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        try createUsersTable()
    }

    func test_updateHook_setsUpdateHook_withInsert() throws {
        try wait { done in
            db.updateHook { operation, db, table, rowid in
                XCTAssertEqual(Connection.Operation.insert, operation)
                XCTAssertEqual("main", db)
                XCTAssertEqual("users", table)
                XCTAssertEqual(1, rowid)
                done()
            }
            try insertUser("alice")
        }
    }

    func test_updateHook_setsUpdateHook_withUpdate() throws {
        try insertUser("alice")
        try wait { done in
            db.updateHook { operation, db, table, rowid in
                XCTAssertEqual(Connection.Operation.update, operation)
                XCTAssertEqual("main", db)
                XCTAssertEqual("users", table)
                XCTAssertEqual(1, rowid)
                done()
            }
            try db.run("UPDATE users SET email = 'alice@example.com'")
        }
    }

    func test_updateHook_setsUpdateHook_withDelete() throws {
        try insertUser("alice")
        try wait { done in
            db.updateHook { operation, db, table, rowid in
                XCTAssertEqual(Connection.Operation.delete, operation)
                XCTAssertEqual("main", db)
                XCTAssertEqual("users", table)
                XCTAssertEqual(1, rowid)
                done()
            }
            try db.run("DELETE FROM users WHERE id = 1")
        }
    }

    func test_commitHook_setsCommitHook() throws {
        try wait { done in
            db.commitHook {
                done()
            }
            try db.transaction {
                try insertUser("alice")
            }
            XCTAssertEqual(1, try db.scalar("SELECT count(*) FROM users") as? Int64)
        }
    }

    func test_rollbackHook_setsRollbackHook() throws {
        try wait { done in
            db.rollbackHook(done)
            do {
                try db.transaction {
                    try insertUser("alice")
                    try insertUser("alice") // throw
                }
            } catch {
            }
            XCTAssertEqual(0, try db.scalar("SELECT count(*) FROM users") as? Int64)
        }
    }

    func test_commitHook_withRollback_rollsBack() throws {
        try wait { done in
            db.commitHook {
                throw NSError(domain: "com.stephencelis.SQLiteTests", code: 1, userInfo: nil)
            }
            db.rollbackHook(done)
            do {
                try db.transaction {
                    try insertUser("alice")
                }
            } catch {
            }
            XCTAssertEqual(0, try db.scalar("SELECT count(*) FROM users") as? Int64)
        }
    }

    private func wait(
        expect description: String = "async",
        timeout: Double = 5,
        block: (@escaping () -> Void) throws -> Void) throws {
        let expectation = self.expectation(description: description)
        try block({ expectation.fulfill() })
        waitForExpectations(timeout: timeout, handler: nil)
    }
}

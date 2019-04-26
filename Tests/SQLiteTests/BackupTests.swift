import XCTest
import Foundation
import Dispatch
@testable import SQLite

#if SQLITE_SWIFT_STANDALONE
import sqlite3
#elseif SQLITE_SWIFT_SQLCIPHER
import SQLCipher
#elseif os(Linux)
import CSQLite
#else
import SQLite3
#endif

class BackupTests : SQLiteTestCase {
    override func setUp() {
        super.setUp()
        
        CreateUsersTable()
    }
    
    func test_backup_copies_database() throws {
        let source = db!
        let target = try Connection()

        try InsertUsers("alice", "betsy")
        
        let backup = try Backup(targetConnection: target, sourceConnection: source)
        try backup.step()
        
        let users = try target.prepare("SELECT email FROM users ORDER BY email")
        XCTAssertEqual(users.map { $0[0] as? String }, ["alice@example.com", "betsy@example.com"])
    }
}


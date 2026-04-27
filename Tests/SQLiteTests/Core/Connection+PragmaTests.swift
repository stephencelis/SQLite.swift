import XCTest
import Foundation
@testable import SQLite

class ConnectionPragmaTests: SQLiteTestCase {
    func test_userVersion() {
        db.userVersion = 2
        XCTAssertEqual(2, db.userVersion!)
    }

    func test_sqlite_version() {
        XCTAssertTrue(db.sqliteVersion >= .init(major: 3, minor: 0))
    }

    func test_foreignKeys_defaults_to_false() {
        XCTAssertFalse(db.foreignKeys)
    }

    func test_foreignKeys_sets_value() {
        db.foreignKeys = true
        XCTAssertTrue(db.foreignKeys)
    }

    func test_defer_foreignKeys_defaults_to_false() {
        XCTAssertFalse(db.deferForeignKeys)
    }

    func test_defer_foreignKeys_sets_value() {
        db.deferForeignKeys = true
        XCTAssertTrue(db.deferForeignKeys)
    }

    // MARK: - journal_mode / synchronous / WAL

    func test_journalMode_defaults_to_memory_for_in_memory_database() {
        // In-memory databases cannot use WAL; SQLite reports `memory`.
        XCTAssertEqual(db.journalMode, .memory)
    }

    func test_journalMode_round_trip_on_file_database() throws {
        try withTemporaryDatabasePath(prefix: "sqlite-swift-wal") { path in
            let fileDB = try Connection(path)
            let applied = try fileDB.setJournalMode(.wal)
            XCTAssertEqual(applied, .wal)
            XCTAssertEqual(fileDB.journalMode, .wal)

            let reverted = try fileDB.setJournalMode(.delete)
            XCTAssertEqual(reverted, .delete)
        }
    }

    func test_setJournalMode_returns_actual_mode_for_in_memory() throws {
        // SQLite silently downgrades WAL to memory for `:memory:` databases.
        let applied = try db.setJournalMode(.wal)
        XCTAssertEqual(applied, .memory)
    }

    func test_synchronous_round_trip() {
        db.synchronous = .normal
        XCTAssertEqual(db.synchronous, .normal)
        db.synchronous = .full
        XCTAssertEqual(db.synchronous, .full)
    }

    func test_walAutoCheckpoint_round_trip() {
        db.walAutoCheckpoint = 500
        XCTAssertEqual(db.walAutoCheckpoint, 500)
    }

    func test_walCheckpoint_returns_zero_pages_when_not_in_wal_mode() throws {
        // Not in WAL mode → log/checkpointed are -1.
        let result = try db.walCheckpoint()
        XCTAssertFalse(result.busy)
        XCTAssertEqual(result.log, -1)
        XCTAssertEqual(result.checkpointed, -1)
    }

    func test_enableWAL_on_file_database_sets_wal_and_synchronous_normal() throws {
        try withTemporaryDatabasePath(prefix: "sqlite-swift-enablewal") { path in
            let fileDB = try Connection(path)
            let mode = try fileDB.enableWAL()
            XCTAssertEqual(mode, .wal)
            XCTAssertEqual(fileDB.journalMode, .wal)
            XCTAssertEqual(fileDB.synchronous, .normal)
        }
    }

    func test_enableWAL_is_idempotent() throws {
        try withTemporaryDatabasePath(prefix: "sqlite-swift-enablewal-idem") { path in
            let fileDB = try Connection(path)
            XCTAssertEqual(try fileDB.enableWAL(), .wal)
            XCTAssertEqual(try fileDB.enableWAL(), .wal)
        }
    }

    func test_enableWAL_does_not_touch_synchronous_when_wal_unsupported() throws {
        // In-memory database cannot use WAL; synchronous should be left untouched.
        db.synchronous = .full
        let mode = try db.enableWAL()
        XCTAssertNotEqual(mode, .wal)
        XCTAssertEqual(db.synchronous, .full)
    }

    // MARK: - init journalMode parameter

    func test_init_with_journalMode_wal_applies_on_file_database() throws {
        try withTemporaryDatabasePath(prefix: "sqlite-swift-init-wal") { path in
            let fileDB = try Connection(path, journalMode: .wal)
            XCTAssertEqual(fileDB.journalMode, .wal)
            XCTAssertEqual(fileDB.synchronous, .normal)
        }
    }

    func test_init_with_journalMode_wal_skipped_for_in_memory() throws {
        let memoryDB = try Connection(.inMemory, journalMode: .wal)
        XCTAssertEqual(memoryDB.journalMode, .memory)
    }

    func test_init_with_journalMode_wal_skipped_for_temporary() throws {
        let tempDB = try Connection(.temporary, journalMode: .wal)
        XCTAssertNotEqual(tempDB.journalMode, .wal)
    }

    func test_init_with_journalMode_wal_skipped_for_readonly() throws {
        try withTemporaryDatabasePath(prefix: "sqlite-swift-init-readonly") { path in
            // Create the database file first; readonly cannot create.
            _ = try Connection(path)
            let readonlyDB = try Connection(path, readonly: true, journalMode: .wal)
            XCTAssertNotEqual(readonlyDB.journalMode, .wal)
        }
    }

    func test_init_with_journalMode_wal_skipped_for_uri_readonly_mode() throws {
        try withTemporaryDatabasePath(prefix: "sqlite-swift-init-uri-ro") { path in
            // Create the database first so the read-only URI open succeeds.
            _ = try Connection(path)
            // `readonly: false` here, but the URI parameter forces read-only.
            // The init must consult the live `readonly` flag, not just its parameter.
            let uriRO = try Connection(.uri(path, parameters: [.mode(.readOnly)]),
                                       readonly: false,
                                       journalMode: .wal)
            XCTAssertTrue(uriRO.readonly)
            XCTAssertNotEqual(uriRO.journalMode, .wal)
        }
    }

    func test_init_with_journalMode_truncate_applies_on_file_database() throws {
        try withTemporaryDatabasePath(prefix: "sqlite-swift-init-truncate") { path in
            let fileDB = try Connection(path, journalMode: .truncate)
            XCTAssertEqual(fileDB.journalMode, .truncate)
        }
    }

    // MARK: - Helpers

    /// Creates a unique temporary database path, runs the block, then removes
    /// the main file plus SQLite's `-wal` / `-shm` sidecars (which use a `-`
    /// separator, not a `.` extension).
    private func withTemporaryDatabasePath(prefix: String,
                                           _ block: (String) throws -> Void) throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString).sqlite3")
            .path
        defer {
            for sidecar in ["", "-wal", "-shm", "-journal"] {
                try? FileManager.default.removeItem(atPath: path + sidecar)
            }
        }
        try block(path)
    }
}

import Foundation

public typealias UserVersion = Int32

public extension Connection {
    /// The user version of the database.
    /// See SQLite [PRAGMA user_version](https://sqlite.org/pragma.html#pragma_user_version)
    var userVersion: UserVersion? {
        get {
            (try? scalar("PRAGMA user_version") as? Int64)?.map(Int32.init)
        }
        set {
            _ = try? run("PRAGMA user_version = \(newValue ?? 0)")
        }
    }

    /// The version of SQLite.
    /// See SQLite [sqlite_version()](https://sqlite.org/lang_corefunc.html#sqlite_version)
    var sqliteVersion: SQLiteVersion {
        guard let version = (try? scalar("SELECT sqlite_version()")) as? String,
              let splits = .some(version.split(separator: ".", maxSplits: 3)), splits.count == 3,
              let major = Int(splits[0]), let minor = Int(splits[1]), let point = Int(splits[2]) else {
            return .zero
        }
        return .init(major: major, minor: minor, point: point)
    }

    // Changing the foreign_keys setting affects the execution of all statements prepared using the database
    // connection, including those prepared before the setting was changed.
    //
    // https://sqlite.org/pragma.html#pragma_foreign_keys
    var foreignKeys: Bool {
        get { getBoolPragma("foreign_keys") }
        set { setBoolPragma("foreign_keys", newValue) }
    }

    var deferForeignKeys: Bool {
        get { getBoolPragma("defer_foreign_keys") }
        set { setBoolPragma("defer_foreign_keys", newValue) }
    }

    /// The journal mode for the main database.
    /// See SQLite [PRAGMA journal_mode](https://sqlite.org/pragma.html#pragma_journal_mode)
    ///
    /// `WAL` is persistent across connections (stored in the database header), so
    /// setting this once is sufficient. Setting may silently no-op for some
    /// databases (e.g. `:memory:`, network file systems). Use `setJournalMode(_:)`
    /// to verify the new mode.
    var journalMode: JournalMode {
        get {
            guard let raw = (try? scalar("PRAGMA journal_mode")) as? String,
                  let mode = JournalMode(rawValue: raw.lowercased()) else { return .delete }
            return mode
        }
        set {
            _ = try? setJournalMode(newValue)
        }
    }

    /// Sets the journal mode and returns the mode actually in effect after the
    /// change. SQLite reports the resulting mode; callers should compare against
    /// `mode` to detect failures (e.g. WAL on a network file system).
    @discardableResult
    func setJournalMode(_ mode: JournalMode) throws -> JournalMode {
        guard let raw = try scalar("PRAGMA journal_mode = \(mode.rawValue.uppercased())") as? String,
              let result = JournalMode(rawValue: raw.lowercased()) else {
            return .delete
        }
        return result
    }

    /// Enables WAL journaling and pairs it with `synchronous = NORMAL`, which is
    /// the recommended configuration: durable, fast, and safe against database
    /// corruption (only the most recent committed transaction may be lost on
    /// power failure).
    ///
    /// Idempotent. Safe to call on every connection — WAL is persisted in the
    /// database header, so subsequent connections inherit it, but calling this
    /// again is a no-op.
    ///
    /// SQLite silently downgrades WAL on databases that cannot support it
    /// (`:memory:`, network file systems, read-only media). Inspect the return
    /// value to detect this case; `synchronous` is only changed when WAL was
    /// successfully applied.
    ///
    /// - Returns: The journal mode actually in effect after the call.
    /// - Throws: `Result.Error` if the pragma cannot be executed.
    @discardableResult
    func enableWAL() throws -> JournalMode {
        let mode = try setJournalMode(.wal)
        if mode == .wal {
            try setSynchronous(.normal)
        }
        return mode
    }

    /// Throwing equivalent of the `synchronous` setter; surfaces SQLite errors
    /// instead of silently swallowing them.
    func setSynchronous(_ mode: Synchronous) throws {
        try run("PRAGMA synchronous = \(mode.rawValue)")
    }

    /// The disk synchronization mode. `NORMAL` is the recommended pairing with
    /// WAL: durable, fast, and safe against corruption (only the most recent
    /// committed transaction may be lost on power failure).
    /// See SQLite [PRAGMA synchronous](https://sqlite.org/pragma.html#pragma_synchronous)
    var synchronous: Synchronous {
        get {
            guard let value = (try? scalar("PRAGMA synchronous")) as? Int64,
                  let mode = Synchronous(rawValue: Int(value)) else { return .full }
            return mode
        }
        set {
            _ = try? run("PRAGMA synchronous = \(newValue.rawValue)")
        }
    }

    /// The WAL auto-checkpoint threshold in pages. SQLite checkpoints
    /// automatically once the WAL reaches this many pages (default 1000).
    /// Set to 0 (or negative) to disable automatic checkpoints.
    /// See SQLite [PRAGMA wal_autocheckpoint](https://sqlite.org/pragma.html#pragma_wal_autocheckpoint)
    var walAutoCheckpoint: Int {
        get {
            guard let value = (try? scalar("PRAGMA wal_autocheckpoint")) as? Int64 else { return 1000 }
            return Int(value)
        }
        set {
            _ = try? run("PRAGMA wal_autocheckpoint = \(newValue)")
        }
    }

    /// Runs a WAL checkpoint and returns its result.
    ///
    /// - Parameters:
    ///   - mode: The checkpoint mode. Defaults to `.passive`.
    ///   - schema: The attached database schema to checkpoint, or `nil` for all
    ///     attached databases.
    /// - Returns: A tuple of:
    ///   - `busy`: `true` if the checkpoint could not complete because a reader
    ///     or writer prevented it.
    ///   - `log`: Number of frames in the WAL.
    ///   - `checkpointed`: Number of frames moved from the WAL to the database
    ///     file (or -1 if not in WAL mode).
    /// - Throws: `Result.Error` if the pragma cannot be executed.
    @discardableResult
    func walCheckpoint(mode: WALCheckpointMode = .passive, schema: String? = nil) throws
        -> (busy: Bool, log: Int, checkpointed: Int) {
        let scope = schema.map { "\($0.quote())." } ?? ""
        let stmt = try prepare("PRAGMA \(scope)wal_checkpoint(\(mode.rawValue))")
        _ = try stmt.step()
        let busy: Int64 = stmt.row[0]
        let log: Int64 = stmt.row[1]
        let checkpointed: Int64 = stmt.row[2]
        return (busy != 0, Int(log), Int(checkpointed))
    }

    private func getBoolPragma(_ key: String) -> Bool {
        guard let binding = try? scalar("PRAGMA \(key)"),
              let intBinding = binding as? Int64 else { return false }
        return intBinding == 1
    }

    private func setBoolPragma(_ key: String, _ newValue: Bool) {
        _ = try? run("PRAGMA \(key) = \(newValue ? "1" : "0")")
    }
}

public extension Connection {
    /// SQLite journal modes.
    /// See <https://sqlite.org/pragma.html#pragma_journal_mode>
    enum JournalMode: String, CaseIterable {
        case delete
        case truncate
        case persist
        case memory
        case wal
        case off
    }

    /// SQLite `synchronous` settings.
    /// See <https://sqlite.org/pragma.html#pragma_synchronous>
    enum Synchronous: Int, CaseIterable {
        case off    = 0
        case normal = 1
        case full   = 2
        case extra  = 3
    }

    /// WAL checkpoint modes.
    /// See <https://sqlite.org/pragma.html#pragma_wal_checkpoint>
    enum WALCheckpointMode: String {
        case passive  = "PASSIVE"
        case full     = "FULL"
        case restart  = "RESTART"
        case truncate = "TRUNCATE"
    }
}

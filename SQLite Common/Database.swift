//
// SQLite.Database
// Copyright (c) 2014 Stephen Celis.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation

/// A connection (handle) to a SQLite database.
public final class Database {

    internal let handle: COpaquePointer = nil

    /// Whether or not the database was opened in a read-only state.
    public var readonly: Bool { return sqlite3_db_readonly(handle, nil) == 1 }

    /// Instantiates a new connection to a database.
    ///
    /// :param: path     The path to the database. Creates a new database if it
    ///                  doesn’t already exist (unless in read-only mode). Pass
    ///                  ":memory:" (or nothing) to open a new, in-memory
    ///                  database. Pass "" (or nil) to open a temporary,
    ///                  file-backed database. Default: ":memory:".
    ///
    /// :param: readonly Whether or not to open the database in a read-only
    ///                  state. Default: false.
    ///
    /// :returns: A new database connection.
    public init(_ path: String? = ":memory:", readonly: Bool = false) {
        let flags = readonly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE
        try(sqlite3_open_v2(path ?? "", &handle, flags, nil))
    }

    deinit { try(sqlite3_close(handle)) } // sqlite3_close_v2 in Yosemite/iOS 8?

    // MARK: -

    /// The last row ID inserted into the database via this connection.
    public var lastID: Int? {
        let lastID = Int(sqlite3_last_insert_rowid(handle))
        return lastID == 0 ? nil : lastID
    }

    /// The last number of changes (inserts, updates, or deletes) made to the
    /// database via this connection.
    public var lastChanges: Int {
        return Int(sqlite3_changes(handle))
    }

    /// The total number of changes (inserts, updates, or deletes) made to the
    /// database via this connection.
    public var totalChanges: Int { return Int(sqlite3_total_changes(handle)) }

    // MARK: - Execute

    /// Executes a batch of SQL statements.
    ///
    /// :param: SQL A batch of zero or more semicolon-separated SQL statements.
    public func execute(SQL: String) {
        try(sqlite3_exec(handle, SQL, nil, nil, nil))
    }

    // MARK: - Prepare

    /// Prepares a single SQL statement (with optional parameter bindings).
    ///
    /// :param: statement A single SQL statement.
    ///
    /// :param: bindings  A list of parameters to bind to the statement.
    ///
    /// :returns: A prepared statement.
    public func prepare(statement: String, _ bindings: Binding?...) -> Statement {
        if !bindings.isEmpty { return prepare(statement, bindings) }
        return Statement(self, statement)
    }

    /// Prepares a single SQL statement and binds parameters to it.
    ///
    /// :param: statement A single SQL statement.
    ///
    /// :param: bindings  A list of parameters to bind to the statement.
    ///
    /// :returns: A prepared statement.
    public func prepare(statement: String, _ bindings: [Binding?]) -> Statement {
        return prepare(statement).bind(bindings)
    }

    /// Prepares a single SQL statement and binds parameters to it.
    ///
    /// :param: statement A single SQL statement.
    ///
    /// :param: bindings  A dictionary of named parameters to bind to the
    ///                   statement.
    ///
    /// :returns: A prepared statement.
    public func prepare(statement: String, _ bindings: [String: Binding?]) -> Statement {
        return prepare(statement).bind(bindings)
    }

    // MARK: - Run

    /// Runs a single SQL statement (with optional parameter bindings).
    ///
    /// :param: statement A single SQL statement.
    ///
    /// :param: bindings  A list of parameters to bind to the statement.
    ///
    /// :returns: The statement.
    public func run(statement: String, _ bindings: Binding?...) -> Statement {
        return run(statement, bindings)
    }

    /// Prepares, binds, and runs a single SQL statement.
    ///
    /// :param: statement A single SQL statement.
    ///
    /// :param: bindings  A list of parameters to bind to the statement.
    ///
    /// :returns: The statement.
    public func run(statement: String, _ bindings: [Binding?]) -> Statement {
        return prepare(statement).run(bindings)
    }

    /// Prepares, binds, and runs a single SQL statement.
    ///
    /// :param: statement A single SQL statement.
    ///
    /// :param: bindings  A dictionary of named parameters to bind to the
    ///                   statement.
    ///
    /// :returns: The statement.
    public func run(statement: String, _ bindings: [String: Binding?]) -> Statement {
        return prepare(statement).run(bindings)
    }

    // MARK: - Scalar

    /// Runs a single SQL statement (with optional parameter bindings),
    /// returning the first value of the first row.
    ///
    /// :param: statement A single SQL statement.
    ///
    /// :param: bindings  A list of parameters to bind to the statement.
    ///
    /// :returns: The first value of the first row returned.
    public func scalar(statement: String, _ bindings: Binding?...) -> Binding? {
        return scalar(statement, bindings)
    }

    /// Prepares, binds, and runs a single SQL statement, returning the first
    /// value of the first row.
    ///
    /// :param: statement A single SQL statement.
    ///
    /// :param: bindings  A list of parameters to bind to the statement.
    ///
    /// :returns: The first value of the first row returned.
    public func scalar(statement: String, _ bindings: [Binding?]) -> Binding? {
        return prepare(statement).scalar(bindings)
    }

    /// Prepares, binds, and runs a single SQL statement, returning the first
    /// value of the first row.
    ///
    /// :param: statement A single SQL statement.
    ///
    /// :param: bindings  A dictionary of named parameters to bind to the
    ///                   statement.
    ///
    /// :returns: The first value of the first row returned.
    public func scalar(statement: String, _ bindings: [String: Binding?]) -> Binding? {
        return prepare(statement).scalar(bindings)
    }

    // MARK: - Transactions

    /// The mode in which a transaction acquires a lock.
    public enum TransactionMode: String {

        /// Defers locking the database till the first read/write executes.
        case Deferred = "DEFERRED"

        /// Immediately acquires a reserved lock on the database.
        case Immediate = "IMMEDIATE"

        /// Immediately acquires an exclusive lock on all databases.
        case Exclusive = "EXCLUSIVE"

    }

    /// Runs a series of statements in a transaction. The first statement to
    /// fail will short-circuit the rest and roll back the changes. A successful
    /// transaction will automatically be committed.
    ///
    /// :param: statements Statements to run in the transaction.
    ///
    /// :returns: The last statement executed, successful or not.
    public func transaction(statements: (@autoclosure () -> Statement)...) -> Statement {
        return transaction(.Deferred, statements)
    }

    /// Runs a series of statements in a transaction. The first statement to
    /// fail will short-circuit the rest and roll back the changes. A successful
    /// transaction will automatically be committed.
    ///
    /// :param: mode       The mode in which the transaction will acquire a
    ///                    lock.
    ///
    /// :param: statements Statements to run in the transaction.
    ///
    /// :returns: The last statement executed, successful or not.
    public func transaction(mode: TransactionMode, _ statements: (@autoclosure () -> Statement)...) -> Statement {
        return transaction(mode, statements)
    }

    private func transaction(mode: TransactionMode, _ statements: [@autoclosure () -> Statement]) -> Statement {
        var transaction = run("BEGIN \(mode.rawValue) TRANSACTION")
        // FIXME: rdar://15217242 // for statement in statements { transaction = transaction && statement() }
        for idx in 0..<statements.count { transaction = transaction && statements[idx]() }
        transaction = transaction && run("COMMIT TRANSACTION")
        if transaction.failed { run("ROLLBACK TRANSACTION") }
        return transaction
    }

    // MARK: - Savepoints

    private var saveName = 0

    /// Runs a series of statements in a new savepoint. The first statement to
    /// fail will short-circuit the rest and roll back the changes. A successful
    /// savepoint will automatically be committed.
    ///
    /// :param: statements Statements to run in the savepoint.
    ///
    /// :returns: The last statement executed, successful or not.
    public func savepoint(statements: (@autoclosure () -> Statement)...) -> Statement {
        let transaction = savepoint("\(++saveName)", statements)
        --saveName
        return transaction
    }

    /// Runs a series of statements in a new savepoint. The first statement to
    /// fail will short-circuit the rest and roll back the changes. A successful
    /// savepoint will automatically be committed.
    ///
    /// :param: name       The name of the savepoint.
    ///
    /// :param: statements Statements to run in the savepoint.
    ///
    /// :returns: The last statement executed, successful or not.
    public func savepoint(name: String, _ statements: (@autoclosure () -> Statement)...) -> Statement {
        return savepoint(name, statements)
    }

    private func savepoint(name: String, _ statements: [@autoclosure () -> Statement]) -> Statement {
        let quotedName = quote(literal: name)
        var savepoint = run("SAVEPOINT \(quotedName)")
        // FIXME: rdar://15217242 // for statement in statements { savepoint = savepoint && statement() }
        for idx in 0..<statements.count { savepoint = savepoint && statements[idx]() }
        savepoint = savepoint && run("RELEASE SAVEPOINT \(quotedName)")
        if savepoint.failed { run("ROLLBACK TO SAVEPOINT \(quotedName)") }
        return savepoint
    }

    // MARK: - Configuration

    public var userVersion: Int {
        get { return scalar("PRAGMA user_version") as Int }
        set { run("PRAGMA user_version = \(transcode(newValue))") }
    }

    // MARK: - Handlers

    /// Sets a busy timeout to retry after encountering a busy signal (lock).
    ///
    /// :param: ms Milliseconds to wait before retrying.
    public func timeout(ms: Int) {
        sqlite3_busy_timeout(handle, Int32(ms))
    }

    /// Sets a busy handler to call after encountering a busy signal (lock).
    ///
    /// :param: callback This block is executed during a lock in which a busy
    ///                  error would otherwise be returned. It’s passed the
    ///                  number of times it’s been called for this lock. If it
    ///                  returns true, it will try again. If it returns false,
    ///                  no further attempts will be made.
    public func busy(callback: (Int -> Bool)?) {
        if let callback = callback {
            SQLiteBusyHandler(handle) { callback(Int($0)) ? 1 : 0 }
        } else {
            SQLiteBusyHandler(handle, nil)
        }
    }

    /// Sets a handler to call when a statement is executed with the compiled
    /// SQL.
    ///
    /// :param: callback This block is executed as a statement is executed with
    ///                  the compiled SQL as an argument. E.g., pass println to
    ///                  act as a logger.
    public func trace(callback: (String -> ())?) {
        if let callback = callback {
            SQLiteTrace(handle) { callback(String.fromCString($0)!) }
        } else {
            SQLiteTrace(handle, nil)
        }
    }

    // MARK: - Error Handling

    /// Returns the last error produced on this connection.
    public var lastError: String {
        return String.fromCString(sqlite3_errmsg(handle))!
    }

    internal func try(block: @autoclosure () -> Int32) {
        perform { if block() != SQLITE_OK { assertionFailure("\(self.lastError)") } }
    }

    // MARK: - Threading

    private let queue = dispatch_queue_create("SQLite.Database", DISPATCH_QUEUE_SERIAL)

    internal func perform(block: () -> ()) { dispatch_sync(queue, block) }

}

extension Database: DebugPrintable {

    public var debugDescription: String {
        return "Database(\(String.fromCString(sqlite3_db_filename(handle, nil))!))"
    }

}

internal func quote(#literal: String) -> String {
    return quote(literal, "'")
}

internal func quote(#identifier: String) -> String {
    return quote(identifier, "\"")
}

private func quote(string: String, mark: Character) -> String {
    let escaped = Array(string).reduce("") { string, character in
        string + (character == mark ? "\(mark)\(mark)" : "\(character)")
    }
    return "\(mark)\(escaped)\(mark)"
}

//
// SQLite.swift
// https://github.com/stephencelis/SQLite.swift
// Copyright © 2014-2015 Stephen Celis.
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

import Dispatch
#if SQLITE_SWIFT_STANDALONE
import sqlite3
#else
import CSQLite
#endif


private let vfsName = "unix-excl"


// Connection pool for accessing an SQLite database
// with multiple readers & a single writer. Utilizes
// WAL mode.
public final class ConnectionPool {

    private let location : DirectConnection.Location
    private var availableReadConnections = [DirectConnection]()
    private var unavailableReadConnections = [DirectConnection]()
    private let lockQueue : dispatch_queue_t
    private var writeConnection : DirectConnection!
    private let connectionSemaphore = dispatch_semaphore_create(5)
    
    public var foreignKeys : Bool {
        get {
            return internalSetup[.ForeignKeys] != nil
        }
        set {
            internalSetup[.ForeignKeys] = newValue ? { try $0.execute("PRAGMA foreign_keys = ON;") } : nil
        }
    }
    
    public typealias ConnectionProcessor = Connection throws -> Void
    public var setup = [ConnectionProcessor]()
    
    private enum InternalOption {
        case WriteAheadLogging
        case ForeignKeys
    }
    
    private var internalSetup = [InternalOption: ConnectionProcessor]()
    
    public init(_ location: DirectConnection.Location) throws {
        self.location = location
        self.lockQueue = dispatch_queue_create("SQLite.ConnectionPool.Lock", DISPATCH_QUEUE_SERIAL)
        self.internalSetup[.WriteAheadLogging] = { try $0.execute("PRAGMA journal_mode = WAL;") }
    }
    
    public var totalReadableConnectionCount : Int {
        return availableReadConnections.count + unavailableReadConnections.count
    }
    
    public var availableReadableConnectionCount : Int {
        return availableReadConnections.count
    }
    
    // Connection that automatically returns itself
    // to the pool when it goes out of scope
    private class BorrowedConnection : Connection, Equatable {
        
        let pool : ConnectionPool
        let connection : DirectConnection
        
        init(pool: ConnectionPool, connection: DirectConnection) {
            self.pool = pool
            self.connection = connection
        }
        
        deinit {
            dispatch_sync(pool.lockQueue) {
                if let index = self.pool.unavailableReadConnections.indexOf(self.connection) {
                    self.pool.unavailableReadConnections.removeAtIndex(index)
                }
                self.pool.availableReadConnections.append(self.connection)
                dispatch_semaphore_signal(self.pool.connectionSemaphore)
            }
        }

        var readonly : Bool { return connection.readonly }
        var lastInsertRowid : Int64? { return connection.lastInsertRowid }
        var changes : Int { return connection.changes }
        var totalChanges : Int { return connection.totalChanges }
        
        func execute(SQL: String) throws { return try connection.execute(SQL) }
        @warn_unused_result func prepare(statement: String, _ bindings: Binding?...) throws -> Statement { return try connection.prepare(statement, bindings) }
        @warn_unused_result func prepare(statement: String, _ bindings: [Binding?]) throws -> Statement { return try connection.prepare(statement, bindings) }
        @warn_unused_result func prepare(statement: String, _ bindings: [String: Binding?]) throws -> Statement { return try connection.prepare(statement, bindings) }
        
        func run(statement: String, _ bindings: Binding?...) throws -> Statement { return try connection.run(statement, bindings) }
        func run(statement: String, _ bindings: [Binding?]) throws -> Statement { return try connection.run(statement, bindings) }
        func run(statement: String, _ bindings: [String: Binding?]) throws -> Statement { return try connection.run(statement, bindings) }
        
        @warn_unused_result func scalar(statement: String, _ bindings: Binding?...) -> Binding? { return connection.scalar(statement, bindings) }
        @warn_unused_result func scalar(statement: String, _ bindings: [Binding?]) -> Binding? { return connection.scalar(statement, bindings) }
        @warn_unused_result func scalar(statement: String, _ bindings: [String: Binding?]) -> Binding? { return connection.scalar(statement, bindings) }
        
        func transaction(mode: TransactionMode, block: (Connection) throws -> Void) throws { return try connection.transaction(mode, block: block) }
        func savepoint(name: String, block: (Connection) throws -> Void) throws { return try connection.savepoint(name, block: block) }

        func sync<T>(block: () throws -> T) rethrows -> T { return try connection.sync(block) }
        func check(resultCode: Int32, statement: Statement? = nil) throws -> Int32 { return try connection.check(resultCode, statement: statement) }
        
    }
    
    
    // Acquires a read/write connection to the database
    
    var writeConnectionInit = dispatch_once_t()
    
    public var writable : DirectConnection {

        dispatch_once(&writeConnectionInit) {
        
            let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_WAL | SQLITE_OPEN_NOMUTEX
            self.writeConnection = try! DirectConnection(self.location, flags: flags, dispatcher: ReentrantDispatcher("SQLite.ConnectionPool.Write"), vfsName: vfsName)
            self.writeConnection.busyTimeout = 2
            
            for setupProcessor in self.internalSetup.values {
                try! setupProcessor(self.writeConnection)
            }
            
            for setupProcessor in self.setup {
                try! setupProcessor(self.writeConnection)
            }
            
        }
        
        return writeConnection
    }
    
    // Acquires a read only connection to the database
    public var readable : Connection {
        
        var borrowed : BorrowedConnection!
        
        dispatch_semaphore_wait(connectionSemaphore, DISPATCH_TIME_FOREVER)
        dispatch_sync(lockQueue) {
            
            // Ensure database is open
            self.writable
            
            let connection : DirectConnection
            
            if let availableConnection = self.availableReadConnections.popLast() {
                connection = availableConnection
            }
            else {
                
                let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_WAL | SQLITE_OPEN_NOMUTEX
                
                connection = try! DirectConnection(self.location, flags: flags, dispatcher: ImmediateDispatcher(), vfsName: vfsName)
                connection.busyTimeout = 2
                
                for (type, setupProcessor) in self.internalSetup {
                    if type == .WriteAheadLogging {
                        continue
                    }
                    try! setupProcessor(connection)
                }
                
                for setupProcessor in self.setup {
                    try! setupProcessor(connection)
                }
                
            }
            
            self.unavailableReadConnections.append(connection)
            
            borrowed = BorrowedConnection(pool: self, connection: connection)
        }
        
        return borrowed
    }
    
}

    
private func ==(lhs: ConnectionPool.BorrowedConnection, rhs: ConnectionPool.BorrowedConnection) -> Bool {
    return lhs.connection == rhs.connection
}

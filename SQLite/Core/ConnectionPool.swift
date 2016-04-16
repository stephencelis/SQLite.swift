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

import Foundation


private let vfsName = "unix-excl"


/// Connection pool delegate
public protocol ConnectionPoolDelegate {
    
    func poolShouldAddConnection(pool: ConnectionPool) -> Bool
    func pool(pool: ConnectionPool, didAddConnection: Connection)
    
}


// Connection pool for accessing an SQLite database
// with multiple readers & a single writer. Utilizes
// WAL mode.
public final class ConnectionPool {

    private let location : DBConnection.Location
    private var availableReadConnections = [DBConnection]()
    private var unavailableReadConnections = [DBConnection]()
    private let lockQueue : dispatch_queue_t
    private var writeConnection : DBConnection!
    
    public var delegate : ConnectionPoolDelegate?
    
    public init(_ location: DBConnection.Location) throws {
        self.location = location
        self.lockQueue = dispatch_queue_create("SQLite.ConnectionPool.Lock", DISPATCH_QUEUE_SERIAL)
        try writable.execute("PRAGMA journal_mode = WAL;")
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
        let connection : DBConnection
        
        init(pool: ConnectionPool, connection: DBConnection) {
            self.pool = pool
            self.connection = connection
        }
        
        deinit {
            dispatch_sync(pool.lockQueue) {
                if let index = self.pool.unavailableReadConnections.indexOf(self.connection) {
                    self.pool.unavailableReadConnections.removeAtIndex(index)
                }
                self.pool.availableReadConnections.append(self.connection)
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
    public var writable : DBConnection {
        
        var writeConnectionInit = dispatch_once_t()
        dispatch_once(&writeConnectionInit) {
        
            let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_WAL | SQLITE_OPEN_NOMUTEX
            self.writeConnection = try! DBConnection(self.location, flags: flags, dispatcher: ReentrantDispatcher("SQLite.ConnectionPool.Write"), vfsName: vfsName)
            self.writeConnection.busyTimeout = 2
            
            if let delegate = self.delegate {
                delegate.pool(self, didAddConnection: self.writeConnection)
            }
        }
        
        return writeConnection
    }
    
    // Acquires a read only connection to the database
    public var readable : Connection {
        
        var borrowed : BorrowedConnection!
        
        repeat {
            
            dispatch_sync(lockQueue) {
                
                let connection : DBConnection
                
                if let availableConnection = self.availableReadConnections.popLast() {
                    connection = availableConnection
                }
                else if self.delegate?.poolShouldAddConnection(self) ?? true {
        
                    let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_WAL | SQLITE_OPEN_NOMUTEX
                    
                    connection = try! DBConnection(self.location, flags: flags, dispatcher: ImmediateDispatcher(), vfsName: vfsName)
                    connection.busyTimeout = 2
                
                    self.delegate?.pool(self, didAddConnection: connection)
                    
                }
                else {
                    return
                }
                
                self.unavailableReadConnections.append(connection)
                
                borrowed = BorrowedConnection(pool: self, connection: connection)
            }
            
        } while borrowed == nil
        
        return borrowed
    }
    
}

    
private func ==(lhs: ConnectionPool.BorrowedConnection, rhs: ConnectionPool.BorrowedConnection) -> Bool {
    return lhs.connection == rhs.connection
}

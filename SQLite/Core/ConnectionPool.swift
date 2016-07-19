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

    private let location: Connection.Location
    private var availableReadConnections = [Connection]()
    private var unavailableReadConnections = [Connection]()
    private let lockQueue: dispatch_queue_t
    private var writeConnection: Connection!
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
    
    /// Initializes a new SQLite connection pool.
    ///
    /// - Parameters:
    ///
    ///   - location: The location of the database. Creates a new database if it
    ///     doesn’t already exist.
    ///
    ///     Default: `.InMemory`.
    ///
    /// - Throws: `Result.Error` iff a connection cannot be established.
    ///
    /// - Returns: A new connection pool.
    public init(_ location: Connection.Location = .InMemory) throws {
        self.location = location
        self.lockQueue = dispatch_queue_create("SQLite.ConnectionPool.Lock", DISPATCH_QUEUE_SERIAL)
        self.internalSetup[.WriteAheadLogging] = { try $0.execute("PRAGMA journal_mode = WAL;") }
    }
    
    /// Initializes a new connection to a database.
    ///
    /// - Parameters:
    ///
    ///   - filename: The location of the database. Creates a new database if
    ///     it doesn’t already exist (unless in read-only mode).
    ///
    /// - Throws: `Result.Error` iff a connection cannot be established.
    ///
    /// - Returns: A new database connection pool.
    public convenience init(_ filename: String) throws {
        try self.init(.URI(filename))
    }
    
    public var totalReadableConnectionCount : Int {
        return availableReadConnections.count + unavailableReadConnections.count
    }
    
    public var availableReadableConnectionCount : Int {
        return availableReadConnections.count
    }
    
    /// Calls `readBlock` with an available read connection from the connection pool,
    /// after which the connection is made available again.
    public func read(readBlock: (connection: Connection) -> Void) {
        let connection = readable
        readBlock(connection: connection)
        
        dispatch_sync(lockQueue) {
            if let index = self.unavailableReadConnections.indexOf(connection) {
                self.unavailableReadConnections.removeAtIndex(index)
            }
            self.availableReadConnections.append(connection)
            dispatch_semaphore_signal(self.connectionSemaphore)
        }
    }
    
    /// Calls `readWriteBlock` with a writeable connection
    public func readWrite(readWriteBlock: (connection: Connection) -> Void) {
        let connection = writable
        readWriteBlock(connection: connection)
    }
    
    // Acquires a read/write connection to the database
    var writeConnectionInit = dispatch_once_t()
    
    private var writable: Connection {

        dispatch_once(&writeConnectionInit) {
        
            let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_WAL | SQLITE_OPEN_NOMUTEX
            self.writeConnection = try! Connection(self.location, flags: flags, dispatcher: ReentrantDispatcher("SQLite.ConnectionPool.Write"), vfsName: vfsName)
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
    private var readable: Connection {
        
        var borrowed: Connection!
        
        dispatch_semaphore_wait(connectionSemaphore, DISPATCH_TIME_FOREVER)
        dispatch_sync(lockQueue) {
            
            // Ensure database is open
            self.writable
            
            let connection: Connection
            
            if let availableConnection = self.availableReadConnections.popLast() {
                connection = availableConnection
            }
            else {
                
                let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_WAL | SQLITE_OPEN_NOMUTEX
                
                connection = try! Connection(self.location, flags: flags, dispatcher: ImmediateDispatcher(), vfsName: vfsName)
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
            
            borrowed = connection
        }
        
        return borrowed
    }
    
}

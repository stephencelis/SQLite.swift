import XCTest
import SQLite

class ConnectionPoolTests : SQLiteTestCase {

    var pool : ConnectionPool!
    
    override func setUp() {
        let _ = try? NSFileManager.defaultManager().removeItemAtPath("\(NSTemporaryDirectory())/SQLite.swift Pool Tests.sqlite")
        pool = try! ConnectionPool("\(NSTemporaryDirectory())/SQLite.swift Pool Tests.sqlite")
    }
    
    func testConnectionSetupClosures() {
        
        pool.foreignKeys = true
        pool.setup.append { try $0.execute("CREATE TABLE IF NOT EXISTS test(value INT)") }
        pool.read { conn in
            XCTAssertTrue(conn.scalar("PRAGMA foreign_keys") as! Int64 == 1)
        }
        
        pool.readWrite { conn in
            try! conn.execute("INSERT INTO test(value) VALUES (1)")
            try! conn.execute("SELECT value FROM test")
        }
        
    }

    func testConcurrentAccess2() {
        
        let threadCount = 20
        pool.readWrite { conn in
            try! conn.execute("DROP TABLE IF EXISTS test; CREATE TABLE test(id INTEGER PRIMARY KEY, name TEXT);")
            try! conn.execute("DELETE FROM test")
            for threadNumber in 0..<threadCount {
                try! conn.execute("INSERT INTO test(id,name) VALUES(\(threadNumber), 'test\(threadNumber)')")
            }
        }
        
        
        var quit = false
        let queue = dispatch_queue_create("Readers", DISPATCH_QUEUE_CONCURRENT)
        for threadNumber in 0..<threadCount {
            var reads = 0
            
            let ex = expectationWithDescription("thread" + String(threadNumber))
            
            dispatch_async(queue) {
                
                print("started", threadNumber)
                
                while !quit {
                    self.pool.read { conn in
                        let _ = try! conn.prepare("SELECT name FROM test WHERE id = ?").scalar(threadNumber) as! String
                        reads += 1
                    }
                }
                
                XCTAssertTrue(reads > 0, "Thread \(threadNumber) did not read.")
                print("ended at", reads, "reads")
                
                ex.fulfill()
            }
            
        }
        
        for x in 10..<100 {
            
            let name = "test" + String(x)
            let idx = Int(rand()) % threadCount
            
            pool.readWrite { conn in
                do {
                    try conn.run("UPDATE test SET name=? WHERE id=?", name, idx)
                }
                catch let error {
                    XCTFail((error as? CustomStringConvertible)?.description ?? "Unknown")
                }
            }
            
            usleep(500)
        }
        
        quit = true
        waitForExpectationsWithTimeout(1000, handler: nil)
    }
    
    func testConcurrentAccess() throws {
        pool.readWrite { conn in
            try! conn.execute("DROP TABLE IF EXISTS test; CREATE TABLE test(value);")
            try! conn.run("INSERT INTO test(value) VALUES(?)", 0)
        }
        
        let q = dispatch_queue_create("Readers/Writers", DISPATCH_QUEUE_CONCURRENT);
        var finished = false
        
        for _ in 0..<20 {
            
            dispatch_async(q) {
                
                while !finished {
                    var val: Binding?
                    self.pool.read { conn in
                        val = conn.scalar("SELECT value FROM test")
                    }
                    assert(val != nil, "DB query returned nil result set")
                }
                
            }
            
        }
        
        for c in 0..<5000 {
            pool.readWrite { conn in
                try! conn.run("INSERT INTO test(value) VALUES(?)", c)
            }
            
            usleep(100);
            
        }
        
        finished = true
        
        // Wait for readers to finish
        dispatch_barrier_sync(q) {
        }
        
    }
    
    func testMultiplePools() {
        let pool2 = try! ConnectionPool("\(NSTemporaryDirectory())/SQLite.swift Pool Tests.sqlite")
        pool.readWrite { conn in
            try! conn.execute("DROP TABLE IF EXISTS test; CREATE TABLE test(value);")
            try! conn.run("INSERT INTO test(value) VALUES(?)", 0)
        }
        
        let q = dispatch_queue_create("Readers/Writers", DISPATCH_QUEUE_CONCURRENT);
        var finished = false
        
        for _ in 0..<20 {
            dispatch_async(q) {
                while !finished {
                    var val: Binding?
                    self.pool.read { conn in
                        val = conn.scalar("SELECT value FROM test")
                    }
                    assert(val != nil, "DB query returned nil result set")
                }
            }
        }
        
        for _ in 0..<20 {
            dispatch_async(q) {
                while !finished {
                    var val: Binding?
                    pool2.read { conn in
                        val = conn.scalar("SELECT value FROM test")
                    }
                    assert(val != nil, "DB query returned nil result set")
                }
            }
        }
        
        for c in 0..<5000 {
            pool.readWrite { conn in
                try! conn.run("INSERT INTO test(value) VALUES(?)", c)
            }
            
            pool2.readWrite { conn in
                try! conn.run("INSERT INTO test(value) VALUES(?)", c + 5000)
            }
            
            usleep(100);
        }
        
        finished = true
        
        // Wait for readers to finish
        dispatch_barrier_sync(q) {
        }
        
    }
    
    func testAutoRelease() {
        pool.read { conn in
            try! conn.execute("SELECT 1")
        }
        
        XCTAssertEqual(pool.totalReadableConnectionCount, pool.availableReadableConnectionCount)
    }
    
}

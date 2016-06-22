import XCTest
import SQLite

class ConnectionPoolTests : SQLiteTestCase {

    var pool : ConnectionPool!
    
    override func setUp() {
        let _ = try? NSFileManager.defaultManager().removeItemAtPath("\(NSTemporaryDirectory())/SQLite.swift Pool Tests.sqlite")
        pool = try! ConnectionPool(.URI("\(NSTemporaryDirectory())/SQLite.swift Pool Tests.sqlite"))
    }
    
    func testConnectionSetupClosures() {
        
        pool.foreignKeys = true
        pool.setup.append { try $0.execute("CREATE TABLE IF NOT EXISTS test(value INT)") }
        
        XCTAssertTrue(pool.readable.scalar("PRAGMA foreign_keys") as! Int64 == 1)
        try! pool.writable.execute("INSERT INTO test(value) VALUES (1)")
        try! pool.readable.execute("SELECT value FROM test")
    }

    func testConcurrentAccess2() {
        
        let threadCount = 20
        let conn = pool.writable
        try! conn.execute("DROP TABLE IF EXISTS test; CREATE TABLE test(id INTEGER PRIMARY KEY, name TEXT);")
        try! conn.execute("DELETE FROM test")
        for threadNumber in 0..<threadCount {
            try! conn.execute("INSERT INTO test(id,name) VALUES(\(threadNumber), 'test\(threadNumber)')")
        }
        
        var quit = false
        let queue = dispatch_queue_create("Readers", DISPATCH_QUEUE_CONCURRENT)
        for threadNumber in 0..<threadCount {
            var reads = 0

            let ex = expectationWithDescription("thread" + String(threadNumber))
            
            dispatch_async(queue) {
                
                print("started", threadNumber)

                let conn = self.pool.readable
                
                let stmt = try! conn.prepare("SELECT name FROM test WHERE id = ?")
                var curr = stmt.scalar(threadNumber) as! String
                while !quit {
                    
                    let now = stmt.scalar(threadNumber) as! String
                    if now != curr {
                        //print(now)
                        curr = now
                    }
                    reads += 1
                }
                
                print("ended at", reads, "reads")
                
                ex.fulfill()
            }
            
        }
        
        for x in 10..<1000 {
            
            let name = "test" + String(x)
            let idx = Int(rand()) % threadCount
            
            do {
                try conn.run("UPDATE test SET name=? WHERE id=?", name, idx)
            }
            catch let error {
                XCTFail((error as? CustomStringConvertible)?.description ?? "Unknown")
            }
            
            usleep(500)
        }
        
        quit = true
        waitForExpectationsWithTimeout(1000, handler: nil)
    }
    
    func testConcurrentAccess() throws {
        
        try! pool.writable.execute("DROP TABLE IF EXISTS test; CREATE TABLE test(value);")
        try! pool.writable.run("INSERT INTO test(value) VALUES(?)", 0)
        
        let q = dispatch_queue_create("Readers/Writers", DISPATCH_QUEUE_CONCURRENT);
        var finished = false
        
        for _ in 0..<20 {
            
            dispatch_async(q) {
                
                while !finished {
                    
                    let val = self.pool.readable.scalar("SELECT value FROM test")
                    assert(val != nil, "DB query returned nil result set")
                    
                }
                
            }
            
        }
        
        for c in 0..<5000 {
            
            try pool.writable.run("INSERT INTO test(value) VALUES(?)", c)
            
            usleep(100);
            
        }
        
        finished = true
        
        // Wait for readers to finish
        dispatch_barrier_sync(q) {
        }
        
    }
    
    func testAutoRelease() {
        
        do {
            try! pool.readable.execute("SELECT 1")
        }
        
        XCTAssertEqual(pool.totalReadableConnectionCount, pool.availableReadableConnectionCount)
    }
    
}

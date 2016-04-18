import XCTest
import SQLite

class ConnectionPoolTests : SQLiteTestCase {

    override func setUp() {
        super.setUp()
    }
    
    func testConnectionSetupClosures() {
        
        let _ = try? NSFileManager.defaultManager().removeItemAtPath("\(NSTemporaryDirectory())/SQLite.swift Pool Tests.sqlite")
        let pool = try! ConnectionPool(.URI("\(NSTemporaryDirectory())/SQLite.swift Pool Tests.sqlite"))
        
        pool.foreignKeys = true
        pool.setup.append { try $0.execute("CREATE TABLE IF NOT EXISTS test(value INT)") }
        
        XCTAssertTrue(try pool.readable.scalar("PRAGMA foreign_keys") as! Int64 == 1)
        try! pool.writable.execute("INSERT INTO test(value) VALUES (1)")
        try! pool.readable.execute("SELECT value FROM test")
    }

    func testConcurrentAccess2() {
        
        let _ = try? NSFileManager.defaultManager().removeItemAtPath("\(NSTemporaryDirectory())/SQLite.swift Pool Tests.sqlite")
        let pool = try! ConnectionPool(.URI("\(NSTemporaryDirectory())/SQLite.swift Pool Tests.sqlite"))
        
        let conn = pool.writable
        try! conn.execute("DROP TABLE IF EXISTS test; CREATE TABLE test(id INTEGER PRIMARY KEY, name TEXT);")
        try! conn.execute("DELETE FROM test")
        try! conn.execute("INSERT INTO test(id,name) VALUES(0, 'test0')")
        try! conn.execute("INSERT INTO test(id,name) VALUES(1, 'test1')")
        try! conn.execute("INSERT INTO test(id,name) VALUES(2, 'test2')")
        try! conn.execute("INSERT INTO test(id,name) VALUES(3, 'test3')")
        try! conn.execute("INSERT INTO test(id,name) VALUES(4, 'test4')")
        
        var quit = false
        let queue = dispatch_queue_create("Readers", DISPATCH_QUEUE_CONCURRENT)
        for x in 0..<5 {
            var reads = 0

            let ex = expectationWithDescription("thread" + String(x))
            
            dispatch_async(queue) {
                
                print("started", x)

                let conn = pool.readable
                
                let stmt = try! conn.prepare("SELECT name FROM test WHERE id = ?")
                var curr = stmt.scalar(x) as! String
                while !quit {
                    
                    let now = stmt.scalar(x) as! String
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
        
        for x in 10..<5000 {
            
            let name = "test" + String(x)
            let idx = Int(rand()) % 5
            
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
        
        let _ = try? NSFileManager.defaultManager().removeItemAtPath("\(NSTemporaryDirectory())/SQLite.swift Pool Tests.sqlite")
        let pool = try! ConnectionPool(.URI("\(NSTemporaryDirectory())/SQLite.swift Pool Tests.sqlite"))
        
        try! pool.writable.execute("DROP TABLE IF EXISTS test; CREATE TABLE test(value);")
        try! pool.writable.run("INSERT INTO test(value) VALUES(?)", 0)
        
        let q = dispatch_queue_create("Readers/Writers", DISPATCH_QUEUE_CONCURRENT);
        var finished = false
        
        for _ in 0..<5 {
            
            dispatch_async(q) {
                
                while !finished {
                    
                    let val = pool.readable.scalar("SELECT value FROM test")
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
        
        let _ = try? NSFileManager.defaultManager().removeItemAtPath("\(NSTemporaryDirectory())/SQLite.swift Pool Tests.sqlite")
        let pool = try! ConnectionPool(.URI("\(NSTemporaryDirectory())/SQLite.swift Pool Tests.sqlite"))
        
        do {
            try! pool.readable.execute("SELECT 1")
        }
        
        XCTAssertEqual(pool.totalReadableConnectionCount, pool.availableReadableConnectionCount)
    }
    
}

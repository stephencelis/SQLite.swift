import XCTest
import SQLite

class ConnectionPoolTests : SQLiteTestCase {

    override func setUp() {
        super.setUp()
    }

    func testConcurrentAccess() {
        
        let _ = try? NSFileManager.defaultManager().removeItemAtPath("\(NSTemporaryDirectory())/SQLiteswiftTests.sqlite")
        let pool = try! ConnectionPool(.URI("\(NSTemporaryDirectory())/SQLiteswiftTests.sqlite"))
        
        let conn = pool.writable
        try! conn.execute("CREATE TABLE IF NOT EXISTS test(id INTEGER PRIMARY KEY, name TEXT)")
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
                var curr = conn.scalar("SELECT name FROM test WHERE id = ?", x) as! String
                while !quit {
                    let now = conn.scalar("SELECT name FROM test WHERE id = ?", x) as! String
                    if now != curr {
                        print(now)
                        curr = now
                    }
                    reads += 1
                }
                print("ended at", reads, "reads")
                ex.fulfill()
            }
        }
        
        for x in 10..<500 {
            let name = "test" + String(x)
            let idx = Int(rand()) % 5
            try! conn.run("UPDATE test SET name=? WHERE id=?", name, idx)
            usleep(15000)
        }
        
        quit = true
        waitForExpectationsWithTimeout(1000, handler: nil)
    }
  
}

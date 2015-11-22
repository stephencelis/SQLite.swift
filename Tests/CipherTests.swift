import XCTest
import SQLiteCipher

class CipherTests: XCTestCase {

    let db = try! Connection()

    override func setUp() {
        try! db.key("hello")

        try! db.run("CREATE TABLE foo (bar TEXT)")
        try! db.run("INSERT INTO foo (bar) VALUES ('world')")

        super.setUp()
    }

    func test_key() {
        XCTAssertEqual(1, db.scalar("SELECT count(*) FROM foo") as? Int64)
    }

    func test_rekey() {
        try! db.rekey("goodbye")
        XCTAssertEqual(1, db.scalar("SELECT count(*) FROM foo") as? Int64)
    }

    func test_keyFailure() {
        let path = "\(NSTemporaryDirectory())/db.sqlite3"
        _ = try? NSFileManager.defaultManager().removeItemAtPath(path)

        let connA = try! Connection(path)
        defer { try! NSFileManager.defaultManager().removeItemAtPath(path) }

        try! connA.key("hello")

        let connB = try! Connection(path)

        var rc: Int32?
        do {
            try connB.key("world")
        } catch Result.Error(_, let code, _) {
            rc = code
        } catch {
            XCTFail()
        }
        XCTAssertEqual(SQLITE_NOTADB, rc)
    }
    
}

#if SQLITE_SWIFT_SQLCIPHER
import XCTest
import SQLite
import SQLCipher

class CipherTests: XCTestCase {

    let db1 = try! Connection()
    let db2 = try! Connection()

    override func setUp() {
        // db

        try! db1.key("hello")

        try! db1.run("CREATE TABLE foo (bar TEXT)")
        try! db1.run("INSERT INTO foo (bar) VALUES ('world')")

        // db2
        let key2 = keyData()
        try! db2.key(Blob(bytes: key2.bytes, length: key2.length))

        try! db2.run("CREATE TABLE foo (bar TEXT)")
        try! db2.run("INSERT INTO foo (bar) VALUES ('world')")

        super.setUp()
    }

    func test_key() {
        XCTAssertEqual(1, try! db1.scalar("SELECT count(*) FROM foo") as? Int64)
    }

    func test_rekey() {
        try! db1.rekey("goodbye")
        XCTAssertEqual(1, try! db1.scalar("SELECT count(*) FROM foo") as? Int64)
    }

    func test_data_key() {
        XCTAssertEqual(1, try! db2.scalar("SELECT count(*) FROM foo") as? Int64)
    }

    func test_data_rekey() {
        let newKey = keyData()
        try! db2.rekey(Blob(bytes: newKey.bytes, length: newKey.length))
        XCTAssertEqual(1, try! db2.scalar("SELECT count(*) FROM foo") as? Int64)
    }

    func test_keyFailure() {
        let path = "\(NSTemporaryDirectory())/db.sqlite3"
        _ = try? FileManager.default.removeItem(atPath: path)

        let connA = try! Connection(path)
        defer { try! FileManager.default.removeItem(atPath: path) }

        try! connA.key("hello")

        let connB = try! Connection(path)

        var rc: Int32?
        do {
            try connB.key("world")
        } catch Result.error(_, let code, _) {
            rc = code
        } catch {
            XCTFail()
        }
        XCTAssertEqual(SQLITE_NOTADB, rc)
    }

    private func keyData(length: Int = 64) -> NSMutableData {
        let keyData = NSMutableData(length: length)!
        let result  = SecRandomCopyBytes(kSecRandomDefault, length,
                                         keyData.mutableBytes.assumingMemoryBound(to: UInt8.self))
        XCTAssertEqual(0, result)
        return keyData
    }
}
#endif

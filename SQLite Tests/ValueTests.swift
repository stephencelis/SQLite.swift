import XCTest
import SQLite

class ValueTests: SQLiteTestCase {

    func test_blob_toHex() {
        let blob = Blob(
            data:[0,10,20,30,40,50,60,70,80,90,100,150,250,255] as [UInt8]
        )
        XCTAssertEqual(blob.toHex(), "000a141e28323c46505a6496faff")
    }
    
}

import XCTest
import SQLite

class FoundationTests: XCTestCase {
    func testDataFromBlob() {
        let data = Data([1, 2, 3])
        let blob = data.datatypeValue
        XCTAssertEqual([1, 2, 3], blob.bytes)
    }

    func testBlobToData() {
        let blob = Blob(bytes: [1, 2, 3])
        let data = Data.fromDatatypeValue(blob)
        XCTAssertEqual(Data([1, 2, 3]), data)
    }

    func testStringFromUUID() {
        let uuid = UUID(uuidString: "4ABE10C9-FF12-4CD4-90C1-4B429001BAD3")!
        let string = uuid.datatypeValue
        XCTAssertEqual("4ABE10C9-FF12-4CD4-90C1-4B429001BAD3", string)
    }

    func testUUIDFromString() {
        let string = "4ABE10C9-FF12-4CD4-90C1-4B429001BAD3"
        let uuid = UUID.fromDatatypeValue(string)
        XCTAssertEqual(UUID(uuidString: "4ABE10C9-FF12-4CD4-90C1-4B429001BAD3"), uuid)
    }

    func testCompareBlob() {
        let data1 = Data([1, 2, 3])
        let data2 = Data([1, 3, 3])
        let data3 = Data([4, 3])
        let blob1 = data1.datatypeValue
        let blob2 = data2.datatypeValue
        let blob3 = data3.datatypeValue
        XCTAssert(blob1 < blob2)
        XCTAssert(blob2 > blob1)
        XCTAssert(blob1 > blob3)
        XCTAssert(blob2 > blob3)
    }
}

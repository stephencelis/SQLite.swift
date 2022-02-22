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

    func testUUIDInsert() {
        struct Test: Codable {
            var uuid: UUID
            var string: String
        }
        let testUUID = UUID()
        let testValue = Test(uuid: testUUID, string: "value")
        let db = try! Connection(.temporary)
        try! db.run(table.create { t in
            t.column(uuid)
            t.column(string)
        }
        )

        let iQuery = try! table.insert(testValue)
        try! db.run(iQuery)

        let fQuery = table.filter(uuid == testUUID)
        if let result = try! db.pluck(fQuery) {
            let testValueReturned = Test(uuid: result[uuid], string: result[string])
            XCTAssertEqual(testUUID, testValueReturned.uuid)
        } else {
            XCTFail("Search for uuid failed")
        }
    }
}

import XCTest
import SQLite

class RTreeTests: XCTestCase {

    let id = Expression<Int64>("id")
    let minX = Expression<Double>("minX")
    let maxX = Expression<Double>("maxX")
    let minY = Expression<Double>("minY")
    let maxY = Expression<Double>("maxY")

    let db = Database()
    var index: Query { return db["index"] }

    func test_createVtable_usingRtree_createsVirtualTable() {
        ExpectExecution(db, "CREATE VIRTUAL TABLE \"index\" USING rtree(\"id\", \"minX\", \"maxX\", \"minY\", \"maxY\")", db.create(vtable: index, using: rtree(id, minX, maxX, minY, maxY)))
    }

}

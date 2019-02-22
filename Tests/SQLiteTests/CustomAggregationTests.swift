import XCTest
import Foundation
import Dispatch
@testable import SQLite

#if SQLITE_SWIFT_STANDALONE
import sqlite3
#elseif SQLITE_SWIFT_SQLCIPHER
import SQLCipher
#elseif os(Linux)
import CSQLite
#else
import SQLite3
#endif

class CustomAggregationTests : SQLiteTestCase {
    override func setUp() {
        super.setUp()
        CreateUsersTable()
        try! InsertUser("Alice", age: 30, admin: true)
        try! InsertUser("Bob", age: 25, admin: true)
        try! InsertUser("Eve", age: 28, admin: false)
    }
    
    func testCustomSum() {
        let step = { (bindings: [Binding?], state: UnsafeMutablePointer<Int64>) in
            if let v = bindings[0] as? Int64 {
                state.pointee += v
            }
        }

        let final = { (state: UnsafeMutablePointer<Int64>) -> Binding? in
            let v = state.pointee
            let p = UnsafeMutableBufferPointer(start: state, count: 1)
            p.deallocate()
            return v
        }
        let _ = db.createAggregation("mySUM", step: step, final: final) {
            let v = UnsafeMutableBufferPointer<Int64>.allocate(capacity: 1)
            v[0] = 0
            return v.baseAddress!
        }
        let result = try! db.prepare("SELECT mySUM(age) AS s FROM users")
        let i = result.columnNames.index(of: "s")!
        for row in result {
            let value = row[i] as? Int64
            XCTAssertEqual(83, value)
        }
    }
    
    func testCustomSumGrouping() {
        let step = { (bindings: [Binding?], state: UnsafeMutablePointer<Int64>) in
            if let v = bindings[0] as? Int64 {
                state.pointee += v
            }
        }
        let final = { (state: UnsafeMutablePointer<Int64>) -> Binding? in
            let v = state.pointee
            let p = UnsafeMutableBufferPointer(start: state, count: 1)
            p.deallocate()
            return v
        }
        let _ = db.createAggregation("mySUM", step: step, final: final) {
            let v = UnsafeMutableBufferPointer<Int64>.allocate(capacity: 1)
            v[0] = 0
            return v.baseAddress!
        }
        let result = try! db.prepare("SELECT mySUM(age) AS s FROM users GROUP BY admin ORDER BY s")
        let i = result.columnNames.index(of: "s")!
        let values = result.compactMap { $0[i] as? Int64 }
        XCTAssertTrue(values.elementsEqual([28, 55]))
    }
}

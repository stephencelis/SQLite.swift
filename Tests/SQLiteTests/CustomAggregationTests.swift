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
    
    func testUnsafeCustomSum() {
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
        let _ = db.createAggregation("mySUM1", step: step, final: final) {
            let v = UnsafeMutableBufferPointer<Int64>.allocate(capacity: 1)
            v[0] = 0
            return v.baseAddress!
        }
        let result = try! db.prepare("SELECT mySUM1(age) AS s FROM users")
        let i = result.columnNames.index(of: "s")!
        for row in result {
            let value = row[i] as? Int64
            XCTAssertEqual(83, value)
        }
    }
    
    func testUnsafeCustomSumGrouping() {
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
        let _ = db.createAggregation("mySUM2", step: step, final: final) {
            let v = UnsafeMutableBufferPointer<Int64>.allocate(capacity: 1)
            v[0] = 0
            return v.baseAddress!
        }
        let result = try! db.prepare("SELECT mySUM2(age) AS s FROM users GROUP BY admin ORDER BY s")
        let i = result.columnNames.index(of: "s")!
        let values = result.compactMap { $0[i] as? Int64 }
        XCTAssertTrue(values.elementsEqual([28, 55]))
    }
    
    func testCustomSum() {
        let reduce : (Int64, [Binding?]) -> Int64 = { (last, bindings) in
            let v = (bindings[0] as? Int64) ?? 0
            return last + v
        }
        let _ = db.createAggregation("myReduceSUM1", initialValue: Int64(2000), reduce: reduce, result: { $0 })
        let result = try! db.prepare("SELECT myReduceSUM1(age) AS s FROM users")
        let i = result.columnNames.index(of: "s")!
        for row in result {
            let value = row[i] as? Int64
            XCTAssertEqual(2083, value)
        }
    }

    func testCustomSumGrouping() {
        let reduce : (Int64, [Binding?]) -> Int64 = { (last, bindings) in
            let v = (bindings[0] as? Int64) ?? 0
            return last + v
        }
        let _ = db.createAggregation("myReduceSUM2", initialValue: Int64(3000), reduce: reduce, result: { $0 })
        let result = try! db.prepare("SELECT myReduceSUM2(age) AS s FROM users GROUP BY admin ORDER BY s")
        let i = result.columnNames.index(of: "s")!
        let values = result.compactMap { $0[i] as? Int64 }
        XCTAssertTrue(values.elementsEqual([3028, 3055]))
    }
    
    func testCustomObjectSum() {
        {
            let initial = TestObject(value: 1000)
            let reduce : (TestObject, [Binding?]) -> TestObject = { (last, bindings) in
                let v = (bindings[0] as? Int64) ?? 0
                return TestObject(value: last.value + v)
            }
            let _ = db.createAggregation("myReduceSUMX", initialValue: initial, reduce: reduce, result: { $0.value })
            // end this scope to ensure that the initial value is retained
            // by the createAggregation call.
        }()
        let result = try! db.prepare("SELECT myReduceSUMX(age) AS s FROM users")
        let i = result.columnNames.index(of: "s")!
        for row in result {
            let value = row[i] as? Int64
            XCTAssertEqual(1083, value)
        }
    }
}

/// This class is used to test that aggregation state variables
/// can be reference types and are properly memory managed when
/// crossing the Swift<->C boundary multiple times.
class TestObject {
    var value: Int64
    init(value: Int64) {
        self.value = value
    }
    deinit {
    }
}

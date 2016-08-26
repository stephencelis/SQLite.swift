//
//  DoubleTests.swift
//  SQLite
//
//  Created by Konshin on 26.08.16.
//
//

import XCTest
import SQLite

class DoubleTests: XCTestCase {
    func testDouble() {
        let doubleColumn = "Value"
        let doubleExpression = Expression<Double>(doubleColumn)
        
        let db = try! Connection()
        let tableName = "test"
        let table = Table(tableName)
        
        try! db.run("create table \(tableName) (\(doubleColumn) NUMERIC) ")
        try! db.run("insert into \(tableName) (\(doubleColumn)) values (2000)")
        
        for row in try! db.prepare(table) {
            XCTAssertNotNil(row[doubleExpression])
        }
    }
}

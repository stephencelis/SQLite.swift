import XCTest
import SQLite

class StatementTests : XCTestCase {

    /**
     https://github.com/stephencelis/SQLite.swift/issues/331
     */
    func test_issueWithNumericType() {
        let db2 = try! Connection()
        db2.trace { print($0) }

        let table = "numeric_table"
        let column = "numeric_value"
        try! db2.run("create table \(table) (\(column) NUMERIC) ")
        try! db2.run("insert into \(table) (\(column)) values (2000.1)")

        let tbl2 = Table(table)
        let x2 = Expression<Double>(column)

        for row in try! db2.prepare(tbl2) {
            XCTAssertNotNil(row[x2])
        }

        try! db2.run("delete from \(table)")
        try! db2.run("insert into \(table) (\(column)) values (2000)")

        for row in try! db2.prepare(tbl2) {
            let x = row[x2]
            _ = x
        }
    }
}

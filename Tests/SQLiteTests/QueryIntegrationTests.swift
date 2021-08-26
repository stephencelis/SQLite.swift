import XCTest
#if SQLITE_SWIFT_STANDALONE
import sqlite3
#elseif SQLITE_SWIFT_SQLCIPHER
import SQLCipher
#elseif os(Linux)
import CSQLite
#else
import SQLite3
#endif
@testable import SQLite

class QueryIntegrationTests: SQLiteTestCase {

    let id = Expression<Int64>("id")
    let email = Expression<String>("email")
    let age = Expression<Int>("age")

    override func setUpWithError() throws {
        try super.setUpWithError()
        try createUsersTable()
    }

    // MARK: -

    func test_select() {
        let managerId = Expression<Int64>("manager_id")
        let managers = users.alias("managers")

        let alice = try! db.run(users.insert(email <- "alice@example.com"))
        _ = try! db.run(users.insert(email <- "betsy@example.com", managerId <- alice))

        for user in try! db.prepare(users.join(managers, on: managers[id] == users[managerId])) {
            _ = user[users[managerId]]
        }
    }

    func test_prepareRowIterator() {
        let names = ["a", "b", "c"]
        try! insertUsers(names)

        let emailColumn = Expression<String>("email")
        let emails = try! db.prepareRowIterator(users).map { $0[emailColumn] }

        XCTAssertEqual(names.map({ "\($0)@example.com" }), emails.sorted())
    }

    func test_ambiguousMap() {
        let names = ["a", "b", "c"]
        try! insertUsers(names)

        let emails = try! db.prepare("select email from users", []).map { $0[0] as! String  }

        XCTAssertEqual(names.map({ "\($0)@example.com" }), emails.sorted())
    }

    func test_select_optional() {
        let managerId = Expression<Int64?>("manager_id")
        let managers = users.alias("managers")

        let alice = try! db.run(users.insert(email <- "alice@example.com"))
        _ = try! db.run(users.insert(email <- "betsy@example.com", managerId <- alice))

        for user in try! db.prepare(users.join(managers, on: managers[id] == users[managerId])) {
            _ = user[users[managerId]]
        }
    }

    func test_select_codable() throws {
        let table = Table("codable")
        try db.run(table.create { builder in
            builder.column(Expression<Int>("int"))
            builder.column(Expression<String>("string"))
            builder.column(Expression<Bool>("bool"))
            builder.column(Expression<Double>("float"))
            builder.column(Expression<Double>("double"))
            builder.column(Expression<Date>("date"))
            builder.column(Expression<String?>("optional"))
            builder.column(Expression<Data>("sub"))
        })

        let value1 = TestCodable(int: 1, string: "2", bool: true, float: 3, double: 4,
                                 date: Date(timeIntervalSince1970: 0), optional: nil, sub: nil)
        let value = TestCodable(int: 5, string: "6", bool: true, float: 7, double: 8,
                                date: Date(timeIntervalSince1970: 5000), optional: "optional", sub: value1)

        try db.run(table.insert(value))

        let rows = try db.prepare(table)
        let values: [TestCodable] = try rows.map({ try $0.decode() })
        XCTAssertEqual(values.count, 1)
        XCTAssertEqual(values[0].int, 5)
        XCTAssertEqual(values[0].string, "6")
        XCTAssertEqual(values[0].bool, true)
        XCTAssertEqual(values[0].float, 7)
        XCTAssertEqual(values[0].double, 8)
        XCTAssertEqual(values[0].date, Date(timeIntervalSince1970: 5000))
        XCTAssertEqual(values[0].optional, "optional")
        XCTAssertEqual(values[0].sub?.int, 1)
        XCTAssertEqual(values[0].sub?.string, "2")
        XCTAssertEqual(values[0].sub?.bool, true)
        XCTAssertEqual(values[0].sub?.float, 3)
        XCTAssertEqual(values[0].sub?.double, 4)
        XCTAssertEqual(values[0].sub?.date, Date(timeIntervalSince1970: 0))
        XCTAssertNil(values[0].sub?.optional)
        XCTAssertNil(values[0].sub?.sub)
    }

    func test_scalar() {
        XCTAssertEqual(0, try! db.scalar(users.count))
        XCTAssertEqual(false, try! db.scalar(users.exists))

        try! insertUsers("alice")
        XCTAssertEqual(1, try! db.scalar(users.select(id.average)))
    }

    func test_pluck() {
        let rowid = try! db.run(users.insert(email <- "alice@example.com"))
        XCTAssertEqual(rowid, try! db.pluck(users)![id])
    }

    func test_insert() {
        let id = try! db.run(users.insert(email <- "alice@example.com"))
        XCTAssertEqual(1, id)
    }

    func test_insert_many() {
        let id = try! db.run(users.insertMany([[email <- "alice@example.com"], [email <- "geoff@example.com"]]))
        XCTAssertEqual(2, id)
    }

    func test_upsert() throws {
        try XCTSkipUnless(db.satisfiesMinimumVersion(minor: 24))
        let fetchAge = { () throws -> Int? in
            try self.db.pluck(self.users.filter(self.email == "alice@example.com")).flatMap { $0[self.age] }
        }

        let id = try db.run(users.upsert(email <- "alice@example.com", age <- 30, onConflictOf: email))
        XCTAssertEqual(1, id)
        XCTAssertEqual(30, try fetchAge())

        let nextId = try db.run(users.upsert(email <- "alice@example.com", age <- 42, onConflictOf: email))
        XCTAssertEqual(1, nextId)
        XCTAssertEqual(42, try fetchAge())
    }

    func test_update() {
        let changes = try! db.run(users.update(email <- "alice@example.com"))
        XCTAssertEqual(0, changes)
    }

    func test_delete() {
        let changes = try! db.run(users.delete())
        XCTAssertEqual(0, changes)
    }

    func test_union() throws {
        let expectedIDs = [
            try db.run(users.insert(email <- "alice@example.com")),
            try db.run(users.insert(email <- "sally@example.com"))
        ]

        let query1 = users.filter(email == "alice@example.com")
        let query2 = users.filter(email == "sally@example.com")

        let actualIDs = try db.prepare(query1.union(query2)).map { $0[id] }
        XCTAssertEqual(expectedIDs, actualIDs)

        let query3 = users.select(users[*], Expression<Int>(literal: "1 AS weight")).filter(email == "sally@example.com")
        let query4 = users.select(users[*], Expression<Int>(literal: "2 AS weight")).filter(email == "alice@example.com")

        print(query3.union(query4).order(Expression<Int>(literal: "weight")).asSQL())

        let orderedIDs = try db.prepare(query3.union(query4).order(Expression<Int>(literal: "weight"), email)).map { $0[id] }
        XCTAssertEqual(Array(expectedIDs.reversed()), orderedIDs)
    }

    func test_no_such_column() throws {
        let doesNotExist = Expression<String>("doesNotExist")
        try! insertUser("alice")
        let row = try! db.pluck(users.filter(email == "alice@example.com"))!

        XCTAssertThrowsError(try row.get(doesNotExist)) { error in
            if case QueryError.noSuchColumn(let name, _) = error {
                XCTAssertEqual("\"doesNotExist\"", name)
            } else {
                XCTFail("unexpected error: \(error)")
            }
        }
    }

    func test_catchConstraintError() {
        try! db.run(users.insert(email <- "alice@example.com"))
        do {
            try db.run(users.insert(email <- "alice@example.com"))
            XCTFail("expected error")
        } catch let Result.error(_, code, _) where code == SQLITE_CONSTRAINT {
            // expected
        } catch let error {
            XCTFail("unexpected error: \(error)")
        }
    }

    // https://github.com/stephencelis/SQLite.swift/issues/285
    func test_order_by_random() throws {
        try insertUsers(["a", "b", "c'"])
        let result = Array(try db.prepare(users.select(email).order(Expression<Int>.random()).limit(1)))
        XCTAssertEqual(1, result.count)
    }
}

extension Connection {
    func satisfiesMinimumVersion(minor: Int, patch: Int = 0) -> Bool {
        guard let version = try? scalar("SELECT sqlite_version()") as? String else { return false }
        let components = version.split(separator: ".", maxSplits: 3).compactMap { Int($0) }
        guard components.count == 3 else { return false }

        return components[1] >= minor && components[2] >= patch
    }
}

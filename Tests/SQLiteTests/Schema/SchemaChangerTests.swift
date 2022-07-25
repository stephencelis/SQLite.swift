import XCTest
@testable import SQLite

class SchemaChangerTests: SQLiteTestCase {
    var schemaChanger: SchemaChanger!

    override func setUpWithError() throws {
        try super.setUpWithError()
        try createUsersTable()

        try insertUsers("bob")

        schemaChanger = SchemaChanger(connection: db)
    }

    func test_empty_migration_does_not_change_column_definitions() throws {
        let previous = try db.columnInfo(table: "users")
        try schemaChanger.alter(table: "users") { _ in
        }
        let current = try db.columnInfo(table: "users")

        XCTAssertEqual(previous, current)
    }

    func test_empty_migration_does_not_change_index_definitions() throws {
        let previous = try db.indexInfo(table: "users")
        try schemaChanger.alter(table: "users") { _ in
        }
        let current = try db.indexInfo(table: "users")

        XCTAssertEqual(previous, current)
    }

    func test_empty_migration_does_not_change_foreign_key_definitions() throws {
        let previous = try db.foreignKeyInfo(table: "users")
        try schemaChanger.alter(table: "users") { _ in
        }
        let current = try db.foreignKeyInfo(table: "users")

        XCTAssertEqual(previous, current)
    }

    func test_empty_migration_does_not_change_the_row_count() throws {
        let previous = try db.scalar(users.count)
        try schemaChanger.alter(table: "users") { _ in
        }
        let current = try db.scalar(users.count)

        XCTAssertEqual(previous, current)
    }

    func test_remove_column() throws {
        try schemaChanger.alter(table: "users") { table in
            table.remove("age")
        }
        let columns = try db.columnInfo(table: "users").map(\.name)
        XCTAssertFalse(columns.contains("age"))
    }

    func test_remove_column_legacy() throws {
        schemaChanger = .init(connection: db, version: (3, 24, 0)) // DROP COLUMN introduced in 3.35.0

        try schemaChanger.alter(table: "users") { table in
            table.remove("age")
        }
        let columns = try db.columnInfo(table: "users").map(\.name)
        XCTAssertFalse(columns.contains("age"))
    }

    func test_rename_column() throws {
        try schemaChanger.alter(table: "users") { table in
            table.rename("age", to: "age2")
        }

        let columns = try db.columnInfo(table: "users").map(\.name)
        XCTAssertFalse(columns.contains("age"))
        XCTAssertTrue(columns.contains("age2"))
    }

    func test_rename_column_legacy() throws {
        schemaChanger = .init(connection: db, version: (3, 24, 0)) // RENAME COLUMN introduced in 3.25.0

        try schemaChanger.alter(table: "users") { table in
            table.rename("age", to: "age2")
        }

        let columns = try db.columnInfo(table: "users").map(\.name)
        XCTAssertFalse(columns.contains("age"))
        XCTAssertTrue(columns.contains("age2"))
    }

    func test_add_column() throws {
        let newColumn = ColumnDefinition(name: "new_column", primaryKey: nil, type: .TEXT, null: true, defaultValue: .NULL, references: nil)

        try schemaChanger.alter(table: "users") { table in
            table.add(newColumn)
        }

        let columns = try db.columnInfo(table: "users")
        XCTAssertTrue(columns.contains(newColumn))
    }

    func test_drop_table() throws {
        try schemaChanger.drop(table: "users")
        XCTAssertThrowsError(try db.scalar(users.count)) { error in
            if case Result.error(let message, _, _) =  error {
                XCTAssertEqual(message, "no such table: users")
            } else {
                XCTFail("unexpected error \(error)")
            }
        }
    }
}

import XCTest
@testable import SQLite

class ConnectionSchemaTests: SQLiteTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        try createUsersTable()
    }

    func test_column_info() throws {
        let columns = try db.columnInfo(table: "users")
        XCTAssertEqual(columns, [
            ColumnDefinition(name: "id",
                             primaryKey: .init(autoIncrement: false, onConflict: nil),
                             type: .INTEGER,
                             null: true,
                             defaultValue: .NULL,
                             references: nil),
            ColumnDefinition(name: "email",
                             primaryKey: nil,
                             type: .TEXT,
                             null: false,
                             defaultValue: .NULL,
                             references: nil),
            ColumnDefinition(name: "age",
                             primaryKey: nil,
                             type: .INTEGER,
                             null: true,
                             defaultValue: .NULL,
                             references: nil),
            ColumnDefinition(name: "salary",
                             primaryKey: nil,
                             type: .REAL,
                             null: true,
                             defaultValue: .NULL,
                             references: nil),
            ColumnDefinition(name: "admin",
                             primaryKey: nil,
                             type: .TEXT,
                             null: false,
                             defaultValue: .numericLiteral("0"),
                             references: nil),
            ColumnDefinition(name: "manager_id",
                             primaryKey: nil, type: .INTEGER,
                             null: true,
                             defaultValue: .NULL,
                             references: .init(table: "users", column: "manager_id", primaryKey: "id", onUpdate: nil, onDelete: nil)),
            ColumnDefinition(name: "created_at",
                             primaryKey: nil,
                             type: .TEXT,
                             null: true,
                             defaultValue: .NULL,
                             references: nil)
        ])
    }

    func test_column_info_parses_conflict_modifier() throws {
        try db.run("CREATE TABLE t (\"id\" INTEGER PRIMARY KEY ON CONFLICT IGNORE AUTOINCREMENT)")

        XCTAssertEqual(
            try db.columnInfo(table: "t"), [
            ColumnDefinition(
                name: "id",
                primaryKey: .init(autoIncrement: true, onConflict: .IGNORE),
                type: .INTEGER,
                null: true,
                defaultValue: .NULL,
                references: nil)
            ]
        )
    }

    func test_column_info_detects_missing_autoincrement() throws {
        try db.run("CREATE TABLE t (\"id\" INTEGER PRIMARY KEY)")

        XCTAssertEqual(
            try db.columnInfo(table: "t"), [
            ColumnDefinition(
                    name: "id",
                    primaryKey: .init(autoIncrement: false),
                    type: .INTEGER,
                    null: true,
                    defaultValue: .NULL,
                    references: nil)
            ]
        )
    }

    func test_index_info_no_index() throws {
        let indexes = try db.indexInfo(table: "users")
        XCTAssertTrue(indexes.isEmpty)
    }

    func test_index_info_with_index() throws {
        try db.run("CREATE UNIQUE INDEX index_users ON users (age DESC) WHERE age IS NOT NULL")
        let indexes = try db.indexInfo(table: "users")

        XCTAssertEqual(indexes, [
            IndexDefinition(
                table: "users",
                name: "index_users",
                unique: true,
                columns: ["age"],
                where: "age IS NOT NULL",
                orders: ["age": .DESC]
            )
        ])
    }

    func test_foreign_key_info_empty() throws {
        try db.run("CREATE TABLE t (\"id\" INTEGER PRIMARY KEY)")

        let foreignKeys = try db.foreignKeyInfo(table: "t")
        XCTAssertTrue(foreignKeys.isEmpty)
    }

    func test_foreign_key_info() throws {
        let linkTable = Table("test_links")

        let idColumn = SQLite.Expression<Int64>("id")
        let testIdColumn = SQLite.Expression<Int64>("test_id")

        try db.run(linkTable.create(block: { definition in
            definition.column(idColumn, primaryKey: .autoincrement)
            definition.column(testIdColumn, unique: false, check: nil, references: users, Expression<Int64>("id"))
        }))

        let foreignKeys = try db.foreignKeyInfo(table: "test_links")
        XCTAssertEqual(foreignKeys, [
            .init(table: "users", column: "test_id", primaryKey: "id", onUpdate: nil, onDelete: nil)
        ])
    }
}

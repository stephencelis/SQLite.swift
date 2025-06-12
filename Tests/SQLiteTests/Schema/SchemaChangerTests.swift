import XCTest
@testable import SQLite

class SchemaChangerTests: SQLiteTestCase {
    var schemaChanger: SchemaChanger!
    var schema: SchemaReader!

    override func setUpWithError() throws {
        try super.setUpWithError()
        try createUsersTable()

        try insertUsers("bob")

        schema = SchemaReader(connection: db)
        schemaChanger = SchemaChanger(connection: db)
    }

    func test_empty_migration_does_not_change_column_definitions() throws {
        let previous = try schema.columnDefinitions(table: "users")
        try schemaChanger.alter(table: "users") { _ in
        }
        let current = try schema.columnDefinitions(table: "users")

        XCTAssertEqual(previous, current)
    }

    func test_empty_migration_does_not_change_index_definitions() throws {
        let previous = try schema.indexDefinitions(table: "users")
        try schemaChanger.alter(table: "users") { _ in
        }
        let current = try schema.indexDefinitions(table: "users")

        XCTAssertEqual(previous, current)
    }

    func test_empty_migration_does_not_change_foreign_key_definitions() throws {
        let previous = try schema.foreignKeys(table: "users")
        try schemaChanger.alter(table: "users") { _ in
        }
        let current = try schema.foreignKeys(table: "users")

        XCTAssertEqual(previous, current)
    }

    func test_empty_migration_does_not_change_the_row_count() throws {
        let previous = try db.scalar(users.count)
        try schemaChanger.alter(table: "users") { _ in
        }
        let current = try db.scalar(users.count)

        XCTAssertEqual(previous, current)
    }

    func test_drop_column() throws {
        try schemaChanger.alter(table: "users") { table in
            table.drop(column: "age")
        }
        let columns = try schema.columnDefinitions(table: "users").map(\.name)
        XCTAssertFalse(columns.contains("age"))
    }

    func test_drop_column_legacy() throws {
        schemaChanger = .init(connection: db, version: .init(major: 3, minor: 24)) // DROP COLUMN introduced in 3.35.0

        try schemaChanger.alter(table: "users") { table in
            table.drop(column: "age")
        }
        let columns = try schema.columnDefinitions(table: "users").map(\.name)
        XCTAssertFalse(columns.contains("age"))
    }

    func test_rename_column() throws {
        try schemaChanger.alter(table: "users") { table in
            table.rename(column: "age", to: "age2")
        }

        let columns = try schema.columnDefinitions(table: "users").map(\.name)
        XCTAssertFalse(columns.contains("age"))
        XCTAssertTrue(columns.contains("age2"))
    }

    func test_rename_column_legacy() throws {
        schemaChanger = .init(connection: db, version: .init(major: 3, minor: 24)) // RENAME COLUMN introduced in 3.25.0

        try schemaChanger.alter(table: "users") { table in
            table.rename(column: "age", to: "age2")
        }

        let columns = try schema.columnDefinitions(table: "users").map(\.name)
        XCTAssertFalse(columns.contains("age"))
        XCTAssertTrue(columns.contains("age2"))
    }

    func test_add_column() throws {
        let column = SQLite.Expression<String>("new_column")
        let newColumn = ColumnDefinition(name: "new_column",
                                         type: .TEXT,
                                         nullable: true,
                                         defaultValue: .stringLiteral("foo"))

        try schemaChanger.alter(table: "users") { table in
            table.add(column: newColumn)
        }

        let columns = try schema.columnDefinitions(table: "users")
        XCTAssertTrue(columns.contains(newColumn))

        XCTAssertEqual(try db.pluck(users.select(column))?[column], "foo")
    }

    func test_add_column_primary_key_fails() throws {
        let newColumn = ColumnDefinition(name: "new_column",
                                         primaryKey: .init(autoIncrement: false, onConflict: nil),
                                         type: .TEXT)

        XCTAssertThrowsError(try schemaChanger.alter(table: "users") { table in
            table.add(column: newColumn)
        }) { error in
            if case SchemaChanger.Error.invalidColumnDefinition(_) = error {
                XCTAssertEqual("Invalid column definition: can not add primary key column", error.localizedDescription)
            } else {
                XCTFail("invalid error: \(error)")
            }
        }
    }

    func test_add_index() throws {
        try schemaChanger.alter(table: "users") { table in
            table.add(index: .init(table: table.name, name: "age_index", unique: false, columns: ["age"], indexSQL: nil))
        }

        let indexes = try schema.indexDefinitions(table: "users").filter { !$0.isInternal }
        XCTAssertEqual([
            IndexDefinition(table: "users",
                            name: "age_index",
                            unique: false,
                            columns: ["age"],
                            where: nil,
                            orders: nil,
                            origin: .createIndex)
        ], indexes)
    }

    func test_add_index_if_not_exists() throws {
        let index = IndexDefinition(table: "users", name: "age_index", unique: false, columns: ["age"], indexSQL: nil)
        try schemaChanger.alter(table: "users") { table in
            table.add(index: index)
        }

        try schemaChanger.alter(table: "users") { table in
            table.add(index: index, ifNotExists: true)
        }

        XCTAssertThrowsError(
            try schemaChanger.alter(table: "users") { table in
                table.add(index: index, ifNotExists: false)
            }
        )
    }

    func test_drop_index() throws {
        try db.execute("""
            CREATE INDEX age_index ON users(age)
        """)

        try schemaChanger.alter(table: "users") { table in
            table.drop(index: "age_index")
        }
        let indexes = try schema.indexDefinitions(table: "users").filter { !$0.isInternal }
        XCTAssertEqual(0, indexes.count)
    }

    func test_drop_index_if_exists() throws {
        try db.execute("""
            CREATE INDEX age_index ON users(age)
        """)

        try schemaChanger.alter(table: "users") { table in
            table.drop(index: "age_index")
        }

        try schemaChanger.alter(table: "users") { table in
            table.drop(index: "age_index", ifExists: true)
        }

        XCTAssertThrowsError(
            try schemaChanger.alter(table: "users") { table in
                table.drop(index: "age_index", ifExists: false)
            }
        ) { error in
            if case Result.error(let message, _, _) =  error {
                XCTAssertEqual(message, "no such index: age_index")
            } else {
                XCTFail("unexpected error \(error)")
            }
        }
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

    func test_drop_table_if_exists_true() throws {
        try schemaChanger.drop(table: "xxx", ifExists: true)
    }

    func test_drop_table_if_exists_false() throws {
        XCTAssertThrowsError(try schemaChanger.drop(table: "xxx", ifExists: false)) { error in
            if case Result.error(let message, _, _) =  error {
                XCTAssertEqual(message, "no such table: xxx")
            } else {
                XCTFail("unexpected error \(error)")
            }
        }
    }

    func test_rename_table() throws {
        try schemaChanger.rename(table: "users", to: "users_new")
        let users_new = Table("users_new")
        XCTAssertEqual((try db.scalar(users_new.count)) as Int, 1)
    }

    func test_create_table() throws {
        try schemaChanger.create(table: "foo") { table in
            table.add(column: .init(name: "id", primaryKey: .init(autoIncrement: true), type: .INTEGER))
            table.add(column: .init(name: "name", type: .TEXT, nullable: false, unique: true))
            table.add(column: .init(name: "age", type: .INTEGER))

            table.add(index: .init(table: table.name,
                                   name: "nameIndex",
                                   unique: true,
                                   columns: ["name"],
                                   where: nil,
                                   orders: nil))
        }

        // make sure new table can be queried
        let foo = Table("foo")
        XCTAssertEqual((try db.scalar(foo.count)) as Int, 0)

        let columns = try schema.columnDefinitions(table: "foo")
        XCTAssertEqual(columns, [
            ColumnDefinition(name: "id",
                             primaryKey: .init(autoIncrement: true, onConflict: nil),
                             type: .INTEGER,
                             nullable: true,
                             unique: false,
                             defaultValue: .NULL,
                             references: nil),
            ColumnDefinition(name: "name",
                             primaryKey: nil,
                             type: .TEXT,
                             nullable: false,
                             unique: true,
                             defaultValue: .NULL,
                             references: nil),
            ColumnDefinition(name: "age",
                             primaryKey: nil,
                             type: .INTEGER,
                             nullable: true,
                             unique: false,
                             defaultValue: .NULL,
                             references: nil)
        ])

        let indexes = try schema.indexDefinitions(table: "foo").filter { !$0.isInternal }
        XCTAssertEqual(indexes, [
            IndexDefinition(table: "foo", name: "nameIndex", unique: true, columns: ["name"], where: nil, orders: nil, origin: .createIndex)
        ])
    }

    func test_create_table_add_column_expression() throws {
        try schemaChanger.create(table: "foo") { table in
            table.add(expression: SQLite.Expression<String>("name"))
            table.add(expression: SQLite.Expression<Int>("age"))
            table.add(expression: SQLite.Expression<Double?>("salary"))
        }

        let columns = try schema.columnDefinitions(table: "foo")
        XCTAssertEqual(columns, [
            ColumnDefinition(name: "name",
                             primaryKey: nil,
                             type: .TEXT,
                             nullable: false,
                             defaultValue: .NULL,
                             references: nil),
            ColumnDefinition(name: "age",
                             primaryKey: nil,
                             type: .INTEGER,
                             nullable: false,
                             defaultValue: .NULL,
                             references: nil),
            ColumnDefinition(name: "salary",
                             primaryKey: nil,
                             type: .REAL,
                             nullable: true,
                             defaultValue: .NULL,
                             references: nil)
            ])
    }

    func test_create_table_if_not_exists() throws {
        try schemaChanger.create(table: "foo") { table in
            table.add(column: .init(name: "id", primaryKey: .init(autoIncrement: true), type: .INTEGER))
        }

        try schemaChanger.create(table: "foo", ifNotExists: true) { table in
            table.add(column: .init(name: "id", primaryKey: .init(autoIncrement: true), type: .INTEGER))
        }

        XCTAssertThrowsError(
            try schemaChanger.create(table: "foo", ifNotExists: false) { table in
                table.add(column: .init(name: "id", primaryKey: .init(autoIncrement: true), type: .INTEGER))
            }
        ) { error in
            if case Result.error(_, let code, _) = error {
                XCTAssertEqual(code, 1)
            } else {
                XCTFail("unexpected error: \(error)")
            }
        }
    }

    func test_create_table_if_not_exists_with_index() throws {
        try schemaChanger.create(table: "foo") { table in
            table.add(column: .init(name: "id", primaryKey: .init(autoIncrement: true), type: .INTEGER))
            table.add(column: .init(name: "name", type: .TEXT))
            table.add(index: .init(table: "foo", name: "name_index", unique: true, columns: ["name"], indexSQL: nil))
        }

        // ifNotExists needs to apply to index creation as well
        try schemaChanger.create(table: "foo", ifNotExists: true) { table in
            table.add(column: .init(name: "id", primaryKey: .init(autoIncrement: true), type: .INTEGER))
            table.add(index: .init(table: "foo", name: "name_index", unique: true, columns: ["name"], indexSQL: nil))
        }
    }

    func test_create_table_with_foreign_key_reference() throws {
        try schemaChanger.create(table: "foo") { table in
            table.add(column: .init(name: "id", primaryKey: .init(autoIncrement: true), type: .INTEGER))
        }

        try schemaChanger.create(table: "bars") { table in
            table.add(column: .init(name: "id", primaryKey: .init(autoIncrement: true), type: .INTEGER))
            table.add(column: .init(name: "foo_id",
                                    type: .INTEGER,
                                    nullable: false,
                                    references: .init(toTable: "foo", toColumn: "id")))
        }

        let barColumns = try schema.columnDefinitions(table: "bars")

        XCTAssertEqual([
            ColumnDefinition(name: "id",
                             primaryKey: .init(autoIncrement: true, onConflict: nil),
                             type: .INTEGER,
                             nullable: true,
                             unique: false,
                             defaultValue: .NULL,
                             references: nil),

            ColumnDefinition(name: "foo_id",
                             primaryKey: nil,
                             type: .INTEGER,
                             nullable: false,
                             unique: false,
                             defaultValue: .NULL,
                             references: .init(fromColumn: "foo_id", toTable: "foo", toColumn: "id", onUpdate: nil, onDelete: nil))
        ], barColumns)
    }

    func test_run_arbitrary_sql() throws {
        try schemaChanger.run("DROP TABLE users")
        XCTAssertEqual(0, try schema.objectDefinitions(name: "users", type: .table).count)
    }
}

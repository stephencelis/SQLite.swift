import XCTest
import SQLite

private let id = Expression<Int>("id")
private let email = Expression<String>("email")
private let age = Expression<Int?>("age")
private let salary = Expression<Double>("salary")
private let admin = Expression<Bool>("admin")
private let manager_id = Expression<Int?>("manager_id")

class SchemaTests: XCTestCase {

    let db = Database()
    var users: Query { return db["users"] }

    override func setUp() {
        super.setUp()
        db.run("PRAGMA foreign_keys = ON")
        db.trace(println)
    }

    func test_createTable_createsTable() {
        ExpectExecution(db, "CREATE TABLE \"users\" (\"age\" INTEGER)",
            db.create(table: users) { t in t.column(age) }
        )
    }

    func test_createTable_temporary_createsTemporaryTable() {
        ExpectExecution(db, "CREATE TEMPORARY TABLE \"users\" (\"age\" INTEGER)",
            db.create(table: users, temporary: true) { t in t.column(age) }
        )
    }

    func test_createTable_ifNotExists_createsTableIfNotExists() {
        ExpectExecution(db, "CREATE TABLE IF NOT EXISTS \"users\" (\"age\" INTEGER)",
            db.create(table: users, ifNotExists: true) { t in t.column(age) }
        )
    }

    func test_createTable_column_buildsColumnDefinition() {
        ExpectExecution(db, "CREATE TABLE \"users\" (\"email\" TEXT NOT NULL)",
            db.create(table: users) { t in
                t.column(email)
            }
        )
    }

    func test_createTable_column_withPrimaryKey_buildsPrimaryKeyClause() {
        ExpectExecution(db, "CREATE TABLE \"users\" (\"id\" INTEGER PRIMARY KEY NOT NULL)",
            db.create(table: users) { t in
                t.column(id, primaryKey: true)
            }
        )
    }

    func test_createTable_column_withPrimaryKey_buildsPrimaryKeyAutoincrementClause() {
        ExpectExecution(db, "CREATE TABLE \"users\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL)",
            db.create(table: users) { t in
                t.column(id, primaryKey: .Autoincrement)
            }
        )
    }

    func test_createTable_column_withNullFalse_buildsNotNullClause() {
        ExpectExecution(db, "CREATE TABLE \"users\" (\"email\" TEXT NOT NULL)",
            db.create(table: users) { t in
                t.column(email)
            }
        )
    }

    func test_createTable_column_withUnique_buildsUniqueClause() {
        ExpectExecution(db, "CREATE TABLE \"users\" (\"email\" TEXT NOT NULL UNIQUE)",
            db.create(table: users) { t in
                t.column(email, unique: true)
            }
        )
    }

    func test_createTable_column_withCheck_buildsCheckClause() {
        ExpectExecution(db, "CREATE TABLE \"users\" (\"admin\" BOOLEAN NOT NULL CHECK (\"admin\" IN (0, 1)))",
            db.create(table: users) { t in
                t.column(admin, check: contains([false, true], admin))
            }
        )
    }

    func test_createTable_column_withDefaultValue_buildsDefaultClause() {
        ExpectExecution(db, "CREATE TABLE \"users\" (\"salary\" REAL NOT NULL DEFAULT 0.0)",
            db.create(table: users) { t in
                t.column(salary, defaultValue: 0)
            }
        )
    }

    func test_createTable_stringColumn_collation_buildsCollateClause() {
        ExpectExecution(db, "CREATE TABLE \"users\" (\"email\" TEXT NOT NULL COLLATE NOCASE)",
            db.create(table: users) { t in
                t.column(email, collate: .NoCase)
            }
        )
    }

    func test_createTable_intColumn_referencingNamespacedColumn_buildsReferencesClause() {
        let users = self.users
        ExpectExecution(db, "CREATE TABLE \"users\" (" +
            "\"id\" INTEGER PRIMARY KEY NOT NULL, " +
            "\"manager_id\" INTEGER REFERENCES \"users\"(\"id\")" +
        ")",
            db.create(table: users) { t in
                t.column(id, primaryKey: true)
                t.column(manager_id, references: users[id])
            }
        )
    }

    func test_createTable_intColumn_referencingQuery_buildsReferencesClause() {
        let users = self.users
        ExpectExecution(db, "CREATE TABLE \"users\" (" +
            "\"id\" INTEGER PRIMARY KEY NOT NULL, " +
            "\"manager_id\" INTEGER REFERENCES \"users\"" +
        ")",
            db.create(table: users) { t in
                t.column(id, primaryKey: true)
                t.column(manager_id, references: users)
            }
        )
    }

    func test_createTable_primaryKey_buildsPrimaryKeyTableConstraint() {
        let users = self.users
        ExpectExecution(db, "CREATE TABLE \"users\" (\"email\" TEXT NOT NULL, PRIMARY KEY(\"email\"))",
            db.create(table: users) { t in
                t.column(email)
                t.primaryKey(email)
            }
        )
    }

    func test_createTable_primaryKey_buildsCompositePrimaryKeyTableConstraint() {
        let users = self.users
        ExpectExecution(db, "CREATE TABLE \"users\" (" +
            "\"id\" INTEGER NOT NULL, \"email\" TEXT NOT NULL, PRIMARY KEY(\"id\", \"email\")" +
        ")",
            db.create(table: users) { t in
                t.column(id)
                t.column(email)
                t.primaryKey(id, email)
            }
        )
    }

    func test_createTable_unique_buildsUniqueTableConstraint() {
        let users = self.users
        ExpectExecution(db, "CREATE TABLE \"users\" (\"email\" TEXT NOT NULL, UNIQUE(\"email\"))",
            db.create(table: users) { t in
                t.column(email)
                t.unique(email)
            }
        )
    }

    func test_createTable_unique_buildsCompositeUniqueTableConstraint() {
        let users = self.users
        ExpectExecution(db, "CREATE TABLE \"users\" (" +
            "\"id\" INTEGER NOT NULL, \"email\" TEXT NOT NULL, UNIQUE(\"id\", \"email\")" +
        ")",
            db.create(table: users) { t in
                t.column(id)
                t.column(email)
                t.unique(id, email)
            }
        )
    }

    func test_createTable_check_buildsCheckTableConstraint() {
        let users = self.users
        ExpectExecution(db, "CREATE TABLE \"users\" (\"admin\" BOOLEAN NOT NULL, CHECK (\"admin\" IN (0, 1)))",
            db.create(table: users) { t in
                t.column(admin)
                t.check(contains([false, true], admin))
            }
        )
    }

    func test_createTable_foreignKey_referencingNamespacedColumn_buildsForeignKeyTableConstraint() {
        let users = self.users
        ExpectExecution(db,
            "CREATE TABLE \"users\" (" +
                "\"id\" INTEGER PRIMARY KEY NOT NULL, " +
                "\"manager_id\" INTEGER, " +
                "FOREIGN KEY(\"manager_id\") REFERENCES \"users\"(\"id\")" +
            ")",
            db.create(table: users) { t in
                t.column(id, primaryKey: true)
                t.column(manager_id)
                t.foreignKey(manager_id, references: users[id])
            }
        )
    }

    func test_createTable_foreignKey_referencingTable_buildsForeignKeyTableConstraint() {
        let users = self.users
        ExpectExecution(db,
            "CREATE TABLE \"users\" (" +
                "\"id\" INTEGER PRIMARY KEY NOT NULL, " +
                "\"manager_id\" INTEGER, " +
                "FOREIGN KEY(\"manager_id\") REFERENCES \"users\"" +
            ")",
            db.create(table: users) { t in
                t.column(id, primaryKey: true)
                t.column(manager_id)
                t.foreignKey(manager_id, references: users)
            }
        )
    }

    func test_createTable_foreignKey_withUpdateDependency_buildsUpdateDependency() {
        let users = self.users
        ExpectExecution(db,
            "CREATE TABLE \"users\" (" +
                "\"id\" INTEGER PRIMARY KEY NOT NULL, " +
                "\"manager_id\" INTEGER, " +
                "FOREIGN KEY(\"manager_id\") REFERENCES \"users\" ON UPDATE CASCADE" +
            ")",
            db.create(table: users) { t in
                t.column(id, primaryKey: true)
                t.column(manager_id)
                t.foreignKey(manager_id, references: users, update: .Cascade)
            }
        )
    }

    func test_create_foreignKey_withDeleteDependency_buildsDeleteDependency() {
        let users = self.users
        ExpectExecution(db,
            "CREATE TABLE \"users\" (" +
                "\"id\" INTEGER PRIMARY KEY NOT NULL, " +
                "\"manager_id\" INTEGER, " +
                "FOREIGN KEY(\"manager_id\") REFERENCES \"users\" ON DELETE CASCADE" +
            ")",
            db.create(table: users) { t in
                t.column(id, primaryKey: true)
                t.column(manager_id)
                t.foreignKey(manager_id, references: users, delete: .Cascade)
            }
        )
    }

    func test_createTable_withQuery_createsTableWithQuery() {
        CreateUsersTable(db)
        ExpectExecution(db,
            "CREATE TABLE \"emails\" AS SELECT \"email\" FROM \"users\"",
            db.create(table: db["emails"], from: users.select(email))
        )
        ExpectExecution(db,
            "CREATE TEMPORARY TABLE IF NOT EXISTS \"emails\" AS SELECT \"email\" FROM \"users\"",
            db.create(table: db["emails"], temporary: true, ifNotExists: true, from: users.select(email))
        )
    }

    func test_alterTable_renamesTable() {
        CreateUsersTable(db)
        ExpectExecution(db, "ALTER TABLE \"users\" RENAME TO \"people\"", db.rename(table: users, to: "people") )
    }

    func test_alterTable_addsNotNullColumn() {
        CreateUsersTable(db)
        let column = Expression<Double>("bonus")

        ExpectExecution(db, "ALTER TABLE \"users\" ADD COLUMN \"bonus\" REAL NOT NULL DEFAULT 0.0",
            db.alter(table: users, add: column, defaultValue: 0)
        )
    }

    func test_alterTable_addsRegularColumn() {
        CreateUsersTable(db)
        let column = Expression<Double?>("bonus")

        ExpectExecution(db, "ALTER TABLE \"users\" ADD COLUMN \"bonus\" REAL",
            db.alter(table: users, add: column)
        )
    }

    func test_alterTable_withDefaultValue_addsRegularColumn() {
        CreateUsersTable(db)
        let column = Expression<Double?>("bonus")

        ExpectExecution(db, "ALTER TABLE \"users\" ADD COLUMN \"bonus\" REAL DEFAULT 0.0",
            db.alter(table: users, add: column, defaultValue: 0)
        )
    }

    func test_alterTable_withForeignKey_addsRegularColumn() {
        CreateUsersTable(db)
        let column = Expression<Int?>("parent_id")

        ExpectExecution(db, "ALTER TABLE \"users\" ADD COLUMN \"parent_id\" INTEGER REFERENCES \"users\"(\"id\")",
            db.alter(table: users, add: column, references: users[id])
        )
    }

    func test_dropTable_dropsTable() {
        CreateUsersTable(db)
        ExpectExecution(db, "DROP TABLE \"users\"", db.drop(table: users) )
        ExpectExecution(db, "DROP TABLE IF EXISTS \"users\"", db.drop(table: users, ifExists: true) )
    }

    func test_index_executesIndexStatement() {
        CreateUsersTable(db)
        ExpectExecution(db,
            "CREATE INDEX \"index_users_on_email\" ON \"users\" (\"email\")",
            db.create(index: users, on: email)
        )
    }

    func test_index_withUniqueness_executesUniqueIndexStatement() {
        CreateUsersTable(db)
        ExpectExecution(db,
            "CREATE UNIQUE INDEX \"index_users_on_email\" ON \"users\" (\"email\")",
            db.create(index: users, unique: true, on: email)
        )
    }

    func test_index_ifNotExists_executesIndexStatement() {
        CreateUsersTable(db)
        ExpectExecution(db,
            "CREATE INDEX IF NOT EXISTS \"index_users_on_email\" ON \"users\" (\"email\")",
            db.create(index: users, ifNotExists: true, on: email)
        )
    }

    func test_index_withMultipleColumns_executesCompoundIndexStatement() {
        CreateUsersTable(db)
        ExpectExecution(db,
            "CREATE INDEX \"index_users_on_age_DESC_email\" ON \"users\" (\"age\" DESC, \"email\")",
            db.create(index: users, on: age.desc, email)
        )
    }

//    func test_index_withFilter_executesPartialIndexStatementWithWhereClause() {
//        if SQLITE_VERSION >= "3.8" {
//            CreateUsersTable(db)
//            ExpectExecution(db,
//                "CREATE INDEX index_users_on_age ON \"users\" (age) WHERE admin",
//                db.create(index: users.filter(admin), on: age)
//            )
//        }
//    }

    func test_dropIndex_dropsIndex() {
        CreateUsersTable(db)
        db.create(index: users, on: email)

        ExpectExecution(db, "DROP INDEX \"index_users_on_email\"", db.drop(index: users, on: email))
        ExpectExecution(db, "DROP INDEX IF EXISTS \"index_users_on_email\"", db.drop(index: users, ifExists: true, on: email))
    }

    func test_createView_withQuery_createsViewWithQuery() {
        CreateUsersTable(db)
        ExpectExecution(db,
            "CREATE VIEW \"emails\" AS SELECT \"email\" FROM \"users\"",
            db.create(view: db["emails"], from: users.select(email))
        )
        ExpectExecution(db,
            "CREATE TEMPORARY VIEW IF NOT EXISTS \"emails\" AS SELECT \"email\" FROM \"users\"",
            db.create(view: db["emails"], temporary: true, ifNotExists: true, from: users.select(email))
        )
    }

    func test_dropView_dropsView() {
        CreateUsersTable(db)
        db.create(view: db["emails"], from: users.select(email))

        ExpectExecution(db, "DROP VIEW \"emails\"", db.drop(view: db["emails"]))
        ExpectExecution(db, "DROP VIEW IF EXISTS \"emails\"", db.drop(view: db["emails"], ifExists: true))
    }

    func test_quotedIdentifiers() {
        let table = db["table"]
        let column = Expression<Int>("My lil' primary key, \"Kiwi\"")

        ExpectExecution(db, "CREATE TABLE \"table\" (\"My lil' primary key, \"\"Kiwi\"\"\" INTEGER NOT NULL)",
            db.create(table: db["table"]) { $0.column(column) }
        )
    }

}

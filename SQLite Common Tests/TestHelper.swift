import SQLite
import XCTest

func Trace(SQL: String) {
    println(SQL)
}

func CreateUsersTable(db: Database) {
    db.execute(
        "CREATE TABLE \"users\" (" +
            "id INTEGER PRIMARY KEY, " +
            "email TEXT NOT NULL UNIQUE, " +
            "age INTEGER, " +
            "salary REAL, " +
            "admin BOOLEAN NOT NULL DEFAULT 0 CHECK (admin IN (0, 1)), " +
            "manager_id INTEGER, " +
            "FOREIGN KEY(manager_id) REFERENCES users(id)" +
        ")"
    )
    db.trace(Trace)
}

func InsertUser(db: Database, name: String, age: Int? = nil, admin: Bool? = false) -> Statement {
    return db.run(
        "INSERT INTO \"users\" (email, age, admin) values (?, ?, ?)",
        ["\(name)@example.com", age, admin]
    )
}

func InsertUsers(db: Database, names: String...) {
    for name in names { InsertUser(db, name) }
}


func ExpectExecutions(db: Database, statements: [String: Int], block: Database -> ()) {
    var fulfilled = [String: Int]()
    for (SQL, _) in statements { fulfilled[SQL] = 0 }
    db.trace { SQL in
        Trace(SQL)
        if let count = fulfilled[SQL] { fulfilled[SQL] = count + 1 }
    }

    block(db)

    XCTAssertEqual(statements, fulfilled)
}

func ExpectExecution(db: Database, SQL: String, statement: @autoclosure () -> Statement) {
    ExpectExecutions(db, [SQL: 1]) { _ in
        statement()
        return
    }
}

func ExpectExecution(db: Database, SQL: String, query: Query) {
    ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
}

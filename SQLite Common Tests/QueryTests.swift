import XCTest
import SQLite

class QueryTests: XCTestCase {

    let db = Database()
    var users: Query { return db["users"] }

    override func setUp() {
        super.setUp()

        CreateUsersTable(db)
    }

    func test_select_withString_compilesSelectClause() {
        let query = users.select("email")

        let SQL = "SELECT email FROM users"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_select_withVariadicStrings_compilesSelectClause() {
        let query = users.select("email", "count(*)")

        let SQL = "SELECT email, count(*) FROM users"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_join_compilesJoinClause() {
        let query = users.join("users AS managers", on: "users.manager_id = managers.id")

        let SQL = "SELECT * FROM users INNER JOIN users AS managers ON users.manager_id = managers.id"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_join_withExplicityType_compilesJoinClauseWithType() {
        let query = users.join(.LeftOuter, "users AS managers", on: "users.manager_id = managers.id")

        let SQL = "SELECT * FROM users LEFT OUTER JOIN users AS managers ON users.manager_id = managers.id"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_join_whenChained_compilesAggregateJoinClause() {
        let query = users
            .join("users AS managers", on: "users.manager_id = managers.id")
            .join("users AS managed", on: "managed.manager_id = users.id")

        let SQL = "SELECT * FROM users " +
            "INNER JOIN users AS managers ON users.manager_id = managers.id " +
            "INNER JOIN users AS managed ON managed.manager_id = users.id"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_filter_withoutBindings_compilesWhereClause() {
        let query = users.filter("admin = 1")

        let SQL = "SELECT * FROM users WHERE admin = 1"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_filter_withExplicitBindings_compilesWhereClause() {
        let query = users.filter("admin = ?", true)

        let SQL = "SELECT * FROM users WHERE admin = 1"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_filter_withImplicitBindingsDictionary_compilesWhereClause() {
        let query = users.filter(["email": "alice@example.com", "age": 30])

        let SQL = "SELECT * FROM users " +
            "WHERE email = 'alice@example.com' " +
            "AND age = 30"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_filter_withArrayBindings_compilesWhereClause() {
        let query = users.filter(["id": [1, 2]])

        let SQL = "SELECT * FROM users WHERE id IN (1, 2)"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_filter_withRangeBindings_compilesWhereClause() {
        let query = users.filter(["age": 20..<30])

        let SQL = "SELECT * FROM users WHERE age BETWEEN 20 AND 30"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_filter_whenChained_compilesAggregateWhereClause() {
        let query = users
            .filter("email = ?", "alice@example.com")
            .filter("age >= ?", 21)

        let SQL = "SELECT * FROM users " +
            "WHERE email = 'alice@example.com' " +
            "AND age >= 21"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_group_withSingleColumnName_compilesGroupClause() {
        let query = users.group("age")

        let SQL = "SELECT * FROM users GROUP BY age"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_group_withVariadicColumnNames_compilesGroupClause() {
        let query = users.group("age", "admin")

        let SQL = "SELECT * FROM users GROUP BY age, admin"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_group_withColumnNameAndHavingBindings_compilesGroupClause() {
        let query = users.group("age", having: "age >= ?", 30)

        let SQL = "SELECT * FROM users GROUP BY age HAVING age >= 30"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_group_withColumnNamesAndHavingBindings_compilesGroupClause() {
        let query = users.group(["age", "admin"], having: "age >= ?", 30)

        let SQL = "SELECT * FROM users GROUP BY age, admin HAVING age >= 30"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_order_withSingleColumnName_compilesOrderClause() {
        let query = users.order("age")

        let SQL = "SELECT * FROM users ORDER BY age ASC"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_order_withVariadicColumnNames_compilesOrderClause() {
        let query = users.order("age", "email")

        let SQL = "SELECT * FROM users ORDER BY age ASC, email ASC"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_order_withColumnAndSortDirection_compilesOrderClause() {
        let query = users.order("age", .Desc)

        let SQL = "SELECT * FROM users ORDER BY age DESC"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_order_withColumnSortDirectionTuple_compilesOrderClause() {
        let query = users.order(("age", .Desc))

        let SQL = "SELECT * FROM users ORDER BY age DESC"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_order_withVariadicColumnSortDirectionTuples_compilesOrderClause() {
        let query = users.order(("age", .Desc), ("email", .Asc))

        let SQL = "SELECT * FROM users ORDER BY age DESC, email ASC"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_order_whenChained_compilesAggregateOrderClause() {
        let query = users.order("age").order("email")

        let SQL = "SELECT * FROM users ORDER BY age ASC, email ASC"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_reverse_reversesOrder() {
        let query = users.order(("age", .Desc), ("email", .Asc))

        let SQL = "SELECT * FROM users ORDER BY age ASC, email DESC"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in reverse(query) {} }
    }

    func test_reverse_withoutOrder_reversesOrderByRowID() {
        let SQL = "SELECT * FROM users ORDER BY users.ROWID DESC"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in reverse(self.users) {} }
    }

    func test_limit_compilesLimitClause() {
        let query = users.limit(5)

        let SQL = "SELECT * FROM users LIMIT 5"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_limit_withOffset_compilesOffsetClause() {
        let query = users.limit(5, offset: 5)

        let SQL = "SELECT * FROM users LIMIT 5 OFFSET 5"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_limit_whenChained_overridesLimit() {
        let query = users.limit(5).limit(10)

        var SQL = "SELECT * FROM users LIMIT 10"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }

        SQL = "SELECT * FROM users"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query.limit(nil) {} }
    }

    func test_limit_whenChained_withOffset_overridesOffset() {
        let query = users.limit(5, offset: 5).limit(10, offset: 10)

        var SQL = "SELECT * FROM users LIMIT 10 OFFSET 10"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }

        SQL = "SELECT * FROM users"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query.limit(nil) {} }
    }

    func test_SQL_compilesProperly() {
        let query = users
            .select("email", "count(email) AS count")
            .filter("age >= ?", 21)
            .group("age", having: "count > ?", 1)
            .order("email", .Desc)
            .limit(1, offset: 2)

        let SQL = "SELECT email, count(email) AS count FROM users " +
            "WHERE age >= 21 " +
            "GROUP BY age HAVING count > 1 " +
            "ORDER BY email DESC " +
            "LIMIT 1 " +
            "OFFSET 2"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_first_withAnEmptyQuery_returnsNil() {
        XCTAssert(users.first == nil)
    }

    func test_first_returnsTheFirstRow() {
        InsertUsers(db, "alice", "betsy")
        ExpectExecutions(db, ["SELECT * FROM users LIMIT 1": 1]) { _ in
            XCTAssertEqual(1, self.users.first!["id"] as Int)
        }
    }

    func test_last_withAnEmptyQuery_returnsNil() {
        XCTAssert(users.last == nil)
    }

    func test_last_returnsTheLastRow() {
        InsertUsers(db, "alice", "betsy")
        ExpectExecutions(db, ["SELECT * FROM users ORDER BY users.ROWID DESC LIMIT 1": 1]) { _ in
            XCTAssertEqual(2, self.users.last!["id"] as Int)
        }
    }

    func test_last_withAnOrderedQuery_reversesOrder() {
        ExpectExecutions(db, ["SELECT * FROM users ORDER BY age DESC LIMIT 1": 1]) { _ in
            self.users.order("age").last
            return
        }
    }

    func test_isEmpty_returnsWhetherOrNotTheQueryIsEmpty() {
        ExpectExecutions(db, ["SELECT * FROM users LIMIT 1": 2]) { _ in
            XCTAssertTrue(self.users.isEmpty)
            InsertUser(self.db, "alice")
            XCTAssertFalse(self.users.isEmpty)
        }
    }

    func test_insert_insertsRows() {
        let SQL = "INSERT INTO users (email, age) VALUES ('alice@example.com', 30)"
        ExpectExecutions(db, [SQL: 1]) { _ in
            XCTAssertEqual(1, self.users.insert(["email": "alice@example.com", "age": 30]).ID!)
        }

        XCTAssert(users.insert(["email": "alice@example.com", "age": 30]).ID == nil)
    }

    func test_update_updatesRows() {
        InsertUsers(db, "alice", "betsy")
        InsertUser(db, "dolly", admin: true)

        XCTAssertEqual(2, users.filter(["admin": false]).update(["age": 30, "admin": true]).changes)
        XCTAssertEqual(0, users.filter(["admin": false]).update(["age": 30, "admin": true]).changes)
    }

    func test_delete_deletesRows() {
        InsertUser(db, "alice", age: 20)
        XCTAssertEqual(0, users.filter(["email": "betsy@example.com"]).delete().changes)

        InsertUser(db, "betsy", age: 30)
        XCTAssertEqual(2, users.delete().changes)
        XCTAssertEqual(0, users.delete().changes)
    }

    func test_count_returnsCount() {
        XCTAssertEqual(0, users.count)

        InsertUser(db, "alice")
        XCTAssertEqual(1, users.count)
        XCTAssertEqual(0, users.filter("age IS NOT NULL").count)
    }

    func test_count_withColumn_returnsCount() {
        InsertUser(db, "alice", age: 20)
        InsertUser(db, "betsy", age: 20)
        InsertUser(db, "cindy")

        XCTAssertEqual(2, users.count("age"))
        XCTAssertEqual(1, users.count("DISTINCT age"))
    }

    func test_max_returnsMaximum() {
        XCTAssert(users.max("age") == nil)

        InsertUser(db, "alice", age: 20)
        InsertUser(db, "betsy", age: 30)
        XCTAssertEqual(30, users.max("age") as Int)
    }

    func test_min_returnsMinimum() {
        XCTAssert(users.min("age") == nil)

        InsertUser(db, "alice", age: 20)
        InsertUser(db, "betsy", age: 30)
        XCTAssertEqual(20, users.min("age") as Int)
    }

    func test_average_returnsAverage() {
        XCTAssert(users.average("age") == nil)

        InsertUser(db, "alice", age: 20)
        InsertUser(db, "betsy", age: 30)
        XCTAssertEqual(25.0, users.average("age")!)
    }

    func test_sum_returnsSum() {
        XCTAssert(users.sum("age") == nil)

        InsertUser(db, "alice", age: 20)
        InsertUser(db, "betsy", age: 30)
        XCTAssertEqual(50, users.sum("age") as Int)
    }

    func test_total_returnsTotal() {
        XCTAssertEqual(0.0, users.total("age"))

        InsertUser(db, "alice", age: 20)
        InsertUser(db, "betsy", age: 30)
        XCTAssertEqual(50.0, users.total("age"))
    }

}

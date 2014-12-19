import XCTest
import SQLite

class QueryTests: XCTestCase {

    let db = Database()
    var users: Query { return db["users"] }

    let id = Expression<Int>("id")
    let email = Expression<String>("email")
    let age = Expression<Int?>("age")
    let salary = Expression<Double>("salary")
    let admin = Expression<Bool>("admin")
    let manager_id = Expression<Int>("manager_id")

    override func setUp() {
        super.setUp()

        CreateUsersTable(db)
    }

    func test_select_withExpression_compilesSelectClause() {
        let query = users.select(email)

        let SQL = "SELECT \"email\" FROM \"users\""
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_select_withVariadicExpressions_compilesSelectClause() {
        let query = users.select(email, count(*))

        let SQL = "SELECT \"email\", count(*) FROM \"users\""
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_select_withStar_resetsSelectClause() {
        let query = users.select(email)

        let SQL = "SELECT * FROM \"users\""
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query.select(all: *) {} }
    }

    func test_selectDistinct_withExpression_compilesSelectClause() {
        let query = users.select(distinct: age)

        let SQL = "SELECT DISTINCT \"age\" FROM \"users\""
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_selectDistinct_withStar_compilesSelectClause() {
        let query = users.select(distinct: *)

        let SQL = "SELECT DISTINCT * FROM \"users\""
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_join_compilesJoinClause() {
        let managers = db["users"].alias("managers")

        let query = users.join(managers, on: managers[id] == users[manager_id])

        let SQL = "SELECT * FROM \"users\" " +
            "INNER JOIN \"users\" AS \"managers\" ON (\"managers\".\"id\" = \"users\".\"manager_id\")"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_join_withExplicitType_compilesJoinClauseWithType() {
        let managers = db["users"].alias("managers")

        let query = users.join(.LeftOuter, managers, on: managers[id] == users[manager_id])

        let SQL = "SELECT * FROM \"users\" " +
            "LEFT OUTER JOIN \"users\" AS \"managers\" ON (\"managers\".\"id\" = \"users\".\"manager_id\")"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_join_withTableCondition_compilesJoinClauseWithTableCondition() {
        var managers = db["users"].alias("managers")
        managers = managers.filter(managers[admin])

        let query = users.join(managers, on: managers[id] == users[manager_id])

        let SQL = "SELECT * FROM \"users\" " +
            "INNER JOIN \"users\" AS \"managers\" " +
            "ON ((\"managers\".\"id\" = \"users\".\"manager_id\") " +
            "AND \"managers\".\"admin\")"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_join_whenChained_compilesAggregateJoinClause() {
        let managers = users.alias("managers")
        let managed = users.alias("managed")

        let middleManagers = users
            .join(managers, on: managers[id] == users[manager_id])
            .join(managed, on: managed[manager_id] == users[id])

        let SQL = "SELECT * FROM \"users\" " +
            "INNER JOIN \"users\" AS \"managers\" ON (\"managers\".\"id\" = \"users\".\"manager_id\") " +
            "INNER JOIN \"users\" AS \"managed\" ON (\"managed\".\"manager_id\" = \"users\".\"id\")"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in middleManagers {} }
    }

    func test_join_withNamespacedStar_expandsColumnNames() {
        let managers = db["users"].alias("managers")

        let aliceID = users.insert(email <- "alice@example.com")!
        users.insert(email <- "betty@example.com", manager_id <- aliceID)!

        let query = users
            .select(users[*], managers[*])
            .join(managers, on: managers[id] == users[manager_id])

        let SQL = "SELECT \"users\".*, \"managers\".* FROM \"users\" " +
            "INNER JOIN \"users\" AS \"managers\" " +
            "ON (\"managers\".\"id\" = \"users\".\"manager_id\")"
        ExpectExecutions(db, [SQL: 1]) { _ in for row in query { println(row) } }
    }

    func test_namespacedColumnRowValueAccess() {
        let aliceID = users.insert(email <- "alice@example.com")!
        let bettyID = users.insert(email <- "betty@example.com", manager_id <- aliceID)!

        let alice = users.first!
        XCTAssertEqual(aliceID, alice[id])

        let managers = db["users"].alias("managers")
        let query = users.join(managers, on: managers[id] == users[manager_id])

        let betty = query.first!
        XCTAssertEqual(alice[email], betty[managers[email]])
    }

    func test_filter_compilesWhereClause() {
        let query = users.filter(admin == true)

        let SQL = "SELECT * FROM \"users\" WHERE (\"admin\" = 1)"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_filter_whenChained_compilesAggregateWhereClause() {
        let query = users
            .filter(email == "alice@example.com")
            .filter(age >= 21)

        let SQL = "SELECT * FROM \"users\" " +
            "WHERE ((\"email\" = 'alice@example.com') " +
            "AND (\"age\" >= 21))"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_group_withSingleExpressionName_compilesGroupClause() {
        let query = users.group(age)

        let SQL = "SELECT * FROM \"users\" GROUP BY \"age\""
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_group_withVariadicExpressionNames_compilesGroupClause() {
        let query = users.group(age, admin)

        let SQL = "SELECT * FROM \"users\" GROUP BY \"age\", \"admin\""
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_group_withExpressionNameAndHavingBindings_compilesGroupClause() {
        let query = users.group(age, having: age >= 30)

        let SQL = "SELECT * FROM \"users\" GROUP BY \"age\" HAVING (\"age\" >= 30)"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_group_withExpressionNamesAndHavingBindings_compilesGroupClause() {
        let query = users.group([age, admin], having: age >= 30)

        let SQL = "SELECT * FROM \"users\" GROUP BY \"age\", \"admin\" HAVING (\"age\" >= 30)"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_order_withSingleExpressionName_compilesOrderClause() {
        let query = users.order(age)

        let SQL = "SELECT * FROM \"users\" ORDER BY \"age\""
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_order_withVariadicExpressionNames_compilesOrderClause() {
        let query = users.order(age, email)

        let SQL = "SELECT * FROM \"users\" ORDER BY \"age\", \"email\""
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_order_withExpressionAndSortDirection_compilesOrderClause() {
        let query = users.order(age.desc, email.asc)

        let SQL = "SELECT * FROM \"users\" ORDER BY \"age\" DESC, \"email\" ASC"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_limit_compilesLimitClause() {
        let query = users.limit(5)

        let SQL = "SELECT * FROM \"users\" LIMIT 5"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_limit_withOffset_compilesOffsetClause() {
        let query = users.limit(5, offset: 5)

        let SQL = "SELECT * FROM \"users\" LIMIT 5 OFFSET 5"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_limit_whenChained_overridesLimit() {
        let query = users.limit(5).limit(10)

        var SQL = "SELECT * FROM \"users\" LIMIT 10"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }

        SQL = "SELECT * FROM \"users\""
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query.limit(nil) {} }
    }

    func test_limit_whenChained_withOffset_overridesOffset() {
        let query = users.limit(5, offset: 5).limit(10, offset: 10)

        var SQL = "SELECT * FROM \"users\" LIMIT 10 OFFSET 10"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }

        SQL = "SELECT * FROM \"users\""
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query.limit(nil) {} }
    }

    func test_alias_compilesAliasInSelectClause() {
        let managers = users.alias("managers")
        var SQL = "SELECT * FROM \"users\" AS \"managers\""
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in managers {} }
    }

    func test_subscript_withExpression_returnsNamespacedExpression() {
        ExpectExecution(db, "SELECT \"users\".\"admin\" FROM \"users\"", users.select(users[admin]))
        ExpectExecution(db, "SELECT \"users\".\"salary\" FROM \"users\"", users.select(users[salary]))
        ExpectExecution(db, "SELECT \"users\".\"age\" FROM \"users\"", users.select(users[age]))
        ExpectExecution(db, "SELECT \"users\".\"email\" FROM \"users\"", users.select(users[email]))
        ExpectExecution(db, "SELECT \"users\".* FROM \"users\"", users.select(users[*]))
    }

    func test_subscript_withAliasAndExpression_returnsAliasedExpression() {
        let managers = users.alias("managers")
        ExpectExecution(db, "SELECT \"managers\".\"admin\" FROM \"users\" AS \"managers\"", managers.select(managers[admin]))
        ExpectExecution(db, "SELECT \"managers\".\"salary\" FROM \"users\" AS \"managers\"", managers.select(managers[salary]))
        ExpectExecution(db, "SELECT \"managers\".\"age\" FROM \"users\" AS \"managers\"", managers.select(managers[age]))
        ExpectExecution(db, "SELECT \"managers\".\"email\" FROM \"users\" AS \"managers\"", managers.select(managers[email]))
        ExpectExecution(db, "SELECT \"managers\".* FROM \"users\" AS \"managers\"", managers.select(managers[*]))
    }

    func test_SQL_compilesProperly() {
        var managers = users.alias("managers")
        // TODO: automatically namespace in the future?
        managers = managers.filter(managers[admin] == true)

        let query = users
            .select(users[email], count(users[email]))
            .join(.LeftOuter, managers, on: managers[id] == users[manager_id])
            .filter(21..<32 ~= users[age])
            .group(users[age], having: count(users[email]) > 1)
            .order(users[email].desc)
            .limit(1, offset: 2)

        let SQL = "SELECT \"users\".\"email\", count(\"users\".\"email\") FROM \"users\" " +
            "LEFT OUTER JOIN \"users\" AS \"managers\" " +
            "ON ((\"managers\".\"id\" = \"users\".\"manager_id\") AND (\"managers\".\"admin\" = 1)) " +
            "WHERE \"users\".\"age\" BETWEEN 21 AND 32 " +
            "GROUP BY \"users\".\"age\" HAVING (count(\"users\".\"email\") > 1) " +
            "ORDER BY \"users\".\"email\" DESC " +
            "LIMIT 1 " +
            "OFFSET 2"
        ExpectExecutions(db, [SQL: 1]) { _ in for _ in query {} }
    }

    func test_first_withAnEmptyQuery_returnsNil() {
        XCTAssert(users.first == nil)
    }

    func test_first_returnsTheFirstRow() {
        InsertUsers(db, "alice", "betsy")
        ExpectExecutions(db, ["SELECT * FROM \"users\" LIMIT 1": 1]) { _ in
            XCTAssertEqual(1, self.users.first![self.id])
        }
    }

    func test_isEmpty_returnsWhetherOrNotTheQueryIsEmpty() {
        ExpectExecutions(db, ["SELECT * FROM \"users\" LIMIT 1": 2]) { _ in
            XCTAssertTrue(self.users.isEmpty)
            InsertUser(self.db, "alice")
            XCTAssertFalse(self.users.isEmpty)
        }
    }

    func test_insert_insertsRows() {
        let SQL = "INSERT INTO \"users\" (\"email\", \"age\") VALUES ('alice@example.com', 30)"

        ExpectExecutions(db, [SQL: 1]) { _ in
            XCTAssertEqual(1, self.users.insert(self.email <- "alice@example.com", self.age <- 30).ID!)
        }

        XCTAssert(self.users.insert(self.email <- "alice@example.com", self.age <- 30).ID == nil)
    }

    func test_insert_withQuery_insertsRows() {
        db.execute("CREATE TABLE \"emails\" (\"email\" TEXT)")
        let emails = db["emails"]
        let admins = users.select(email).filter(admin == true)

        ExpectExecution(db, "INSERT INTO \"emails\" SELECT \"email\" FROM \"users\" WHERE (\"admin\" = 1)", emails.insert(admins))
    }

    func test_insert_insertsDefaultRow() {
        db.execute("CREATE TABLE \"timestamps\" (\"id\" INTEGER PRIMARY KEY, \"timestamp\" TEXT DEFAULT CURRENT_DATETIME)")
        let table = db["timestamps"]

        ExpectExecutions(db, ["INSERT INTO \"timestamps\" DEFAULT VALUES": 1]) { _ in
            XCTAssertEqual(1, table.insert().ID!)
        }
    }

    func test_replace_replaceRows() {
        let SQL = "INSERT OR REPLACE INTO \"users\" (\"email\", \"age\") VALUES ('alice@example.com', 30)"

        ExpectExecutions(db, [SQL: 1]) { _ in
            XCTAssertEqual(1, self.users.replace(self.email <- "alice@example.com", self.age <- 30).ID!)
        }

        XCTAssertEqual(1, self.users.replace(self.id <- 1, self.email <- "bob@example.com", self.age <- 30).ID!)
    }
    
    func test_update_updatesRows() {
        InsertUsers(db, "alice", "betsy")
        InsertUser(db, "dolly", admin: true)

        XCTAssertEqual(2, users.filter(!admin).update(age <- 30, admin <- true).changes!)
        XCTAssertEqual(0, users.filter(!admin).update(age <- 30, admin <- true).changes!)
    }

    func test_delete_deletesRows() {
        InsertUser(db, "alice", age: 20)
        XCTAssertEqual(0, users.filter(email == "betsy@example.com").delete().changes!)

        InsertUser(db, "betsy", age: 30)
        XCTAssertEqual(2, users.delete().changes!)
        XCTAssertEqual(0, users.delete().changes!)
    }

    func test_count_returnsCount() {
        XCTAssertEqual(0, users.count)

        InsertUser(db, "alice")
        XCTAssertEqual(1, users.count)
        XCTAssertEqual(0, users.filter(age != nil).count)
    }

    func test_count_withExpression_returnsCount() {
        InsertUser(db, "alice", age: 20)
        InsertUser(db, "betsy", age: 20)
        InsertUser(db, "cindy")

        XCTAssertEqual(2, users.count(age))
        XCTAssertEqual(1, users.count(distinct: age))
    }

    func test_max_withInt_returnsMaximumInt() {
        XCTAssert(users.max(age) == nil)

        InsertUser(db, "alice", age: 20)
        InsertUser(db, "betsy", age: 30)
        XCTAssertEqual(30, users.max(age)!)
    }

    func test_min_withInt_returnsMinimumInt() {
        XCTAssert(users.min(age) == nil)

        InsertUser(db, "alice", age: 20)
        InsertUser(db, "betsy", age: 30)
        XCTAssertEqual(20, users.min(age)!)
    }

    func test_averageWithInt_returnsDouble() {
        XCTAssert(users.average(age) == nil)

        InsertUser(db, "alice", age: 20)
        InsertUser(db, "betsy", age: 50)
        InsertUser(db, "cindy", age: 50)
        XCTAssertEqual(40.0, users.average(age)!)
        XCTAssertEqual(35.0, users.average(distinct: age)!)
    }

    func test_sum_returnsSum() {
        XCTAssert(users.sum(age) == nil)

        InsertUser(db, "alice", age: 20)
        InsertUser(db, "betsy", age: 30)
        InsertUser(db, "cindy", age: 30)
        XCTAssertEqual(80, users.sum(age)!)
        XCTAssertEqual(50, users.sum(distinct: age)!)
    }

    func test_total_returnsTotal() {
        XCTAssertEqual(0.0, users.total(age))

        InsertUser(db, "alice", age: 20)
        InsertUser(db, "betsy", age: 30)
        InsertUser(db, "cindy", age: 30)
        XCTAssertEqual(80.0, users.total(age))
        XCTAssertEqual(50.0, users.total(distinct: age))
    }

    func test_row_withBoundColumn_returnsValue() {
        InsertUser(db, "alice", age: 20)
        XCTAssertEqual(21, users.select(age + 1).first![age + 1]!)
    }

    func test_valueExtension_serializesAndDeserializes() {
        let id = Expression<Int>("id")
        let timestamp = Expression<NSDate?>("timestamp")
        let touches = db["touches"]
        db.create(table: touches) { t in
            t.column(id, primaryKey: true)
            t.column(timestamp)
        }

        let date = NSDate(timeIntervalSince1970: 0)
        touches.insert(timestamp <- date)!
        XCTAssertEqual(touches.first!.get(timestamp)!, date)

        XCTAssertNil(touches.filter(id == touches.insert()!).first!.get(timestamp))

        XCTAssert(touches.filter(timestamp < NSDate()).first != nil)
    }

}

private let formatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    formatter.timeZone = NSTimeZone(abbreviation: "UTC")
    return formatter
}()

extension NSDate: Value {

    public typealias Datatype = String

    public class var declaredDatatype: String { return Datatype.declaredDatatype }

    public class func fromDatatypeValue(datatypeValue: Datatype) -> NSDate {
        return formatter.dateFromString(datatypeValue)!
    }

    public var datatypeValue: Datatype {
        return formatter.stringFromDate(self)
    }

}

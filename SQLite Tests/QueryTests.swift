import XCTest
import SQLite

class QueryTests: SQLiteTestCase {

    override func setUp() {
        createUsersTable()

        super.setUp()
    }

    func test_select_withExpression_compilesSelectClause() {
        AssertSQL("SELECT \"email\" FROM \"users\"", users.select(email))
    }

    func test_select_withVariadicExpressions_compilesSelectClause() {
        AssertSQL("SELECT \"email\", count(*) FROM \"users\"", users.select(email, count(*)))
    }

    func test_select_withStar_resetsSelectClause() {
        let query = users.select(email)

        AssertSQL("SELECT * FROM \"users\"", query.select(*))
    }

    func test_selectDistinct_withExpression_compilesSelectClause() {
        AssertSQL("SELECT DISTINCT \"age\" FROM \"users\"", users.select(distinct: age))
    }

    func test_selectDistinct_withStar_compilesSelectClause() {
        AssertSQL("SELECT DISTINCT * FROM \"users\"", users.select(distinct: *))
    }

    func test_join_compilesJoinClause() {
        let managers = db["users"].alias("managers")

        let SQL = "SELECT * FROM \"users\" " +
            "INNER JOIN \"users\" AS \"managers\" ON (\"managers\".\"id\" = \"users\".\"manager_id\")"
        AssertSQL(SQL, users.join(managers, on: managers[id] == users[manager_id]))
    }

    func test_join_withExplicitType_compilesJoinClauseWithType() {
        let managers = db["users"].alias("managers")

        let SQL = "SELECT * FROM \"users\" " +
            "LEFT OUTER JOIN \"users\" AS \"managers\" ON (\"managers\".\"id\" = \"users\".\"manager_id\")"
        AssertSQL(SQL, users.join(.LeftOuter, managers, on: managers[id] == users[manager_id]))
    }

    func test_join_withTableCondition_compilesJoinClauseWithTableCondition() {
        var managers = db["users"].alias("managers")
        managers = managers.filter(managers[admin])

        let SQL = "SELECT * FROM \"users\" " +
            "INNER JOIN \"users\" AS \"managers\" " +
            "ON ((\"managers\".\"id\" = \"users\".\"manager_id\") " +
            "AND \"managers\".\"admin\")"
        AssertSQL(SQL, users.join(managers, on: managers[id] == users[manager_id]))
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
        AssertSQL(SQL, middleManagers)
    }

    func test_join_withNamespacedStar_expandsColumnNames() {
        let managers = db["users"].alias("managers")

        let aliceId = users.insert(email <- "alice@example.com")!
        users.insert(email <- "betty@example.com", manager_id <- aliceId)!

        let query = users
            .select(users[*], managers[*])
            .join(managers, on: managers[id] == users[manager_id])

        let SQL = "SELECT \"users\".*, \"managers\".* FROM \"users\" " +
            "INNER JOIN \"users\" AS \"managers\" " +
            "ON (\"managers\".\"id\" = \"users\".\"manager_id\")"
        AssertSQL(SQL, query)
    }

    func test_namespacedColumnRowValueAccess() {
        let aliceId = users.insert(email <- "alice@example.com")!
        let bettyId = users.insert(email <- "betty@example.com", manager_id <- aliceId)!

        let alice = users.first!
        XCTAssertEqual(aliceId, alice[id])

        let managers = db["users"].alias("managers")
        let query = users.join(managers, on: managers[id] == users[manager_id])

        let betty = query.first!
        XCTAssertEqual(alice[email], betty[managers[email]])
    }

    func test_filter_compilesWhereClause() {
        AssertSQL("SELECT * FROM \"users\" WHERE (\"admin\" = 1)", users.filter(admin == true))
    }

    func test_filter_whenChained_compilesAggregateWhereClause() {
        let query = users
            .filter(email == "alice@example.com")
            .filter(age >= 21)

        let SQL = "SELECT * FROM \"users\" " +
            "WHERE ((\"email\" = 'alice@example.com') " +
            "AND (\"age\" >= 21))"
        AssertSQL(SQL, query)
    }

    func test_group_withSingleExpressionName_compilesGroupClause() {
        AssertSQL("SELECT * FROM \"users\" GROUP BY \"age\"",
            users.group(age))
    }

    func test_group_withVariadicExpressionNames_compilesGroupClause() {
        AssertSQL("SELECT * FROM \"users\" GROUP BY \"age\", \"admin\"", users.group(age, admin))
    }

    func test_group_withExpressionNameAndHavingBindings_compilesGroupClause() {
        AssertSQL("SELECT * FROM \"users\" GROUP BY \"age\" HAVING (\"age\" >= 30)", users.group(age, having: age >= 30))
    }

    func test_group_withExpressionNamesAndHavingBindings_compilesGroupClause() {
        AssertSQL("SELECT * FROM \"users\" GROUP BY \"age\", \"admin\" HAVING (\"age\" >= 30)",
            users.group([age, admin], having: age >= 30))
    }

    func test_order_withSingleExpressionName_compilesOrderClause() {
        AssertSQL("SELECT * FROM \"users\" ORDER BY \"age\"", users.order(age))
    }

    func test_order_withVariadicExpressionNames_compilesOrderClause() {
        AssertSQL("SELECT * FROM \"users\" ORDER BY \"age\", \"email\"", users.order(age, email))
    }

    func test_order_withExpressionAndSortDirection_compilesOrderClause() {
        AssertSQL("SELECT * FROM \"users\" ORDER BY \"age\" DESC, \"email\" ASC", users.order(age.desc, email.asc))
    }

    func test_limit_compilesLimitClause() {
        AssertSQL("SELECT * FROM \"users\" LIMIT 5", users.limit(5))
    }

    func test_limit_withOffset_compilesOffsetClause() {
        AssertSQL("SELECT * FROM \"users\" LIMIT 5 OFFSET 5", users.limit(5, offset: 5))
    }

    func test_limit_whenChained_overridesLimit() {
        let query = users.limit(5)

        AssertSQL("SELECT * FROM \"users\" LIMIT 10", query.limit(10))
        AssertSQL("SELECT * FROM \"users\"", query.limit(nil))
    }

    func test_limit_whenChained_withOffset_overridesOffset() {
        let query = users.limit(5, offset: 5)

        AssertSQL("SELECT * FROM \"users\" LIMIT 10 OFFSET 10", query.limit(10, offset: 10))
        AssertSQL("SELECT * FROM \"users\"", query.limit(nil))
    }

    func test_alias_compilesAliasInSelectClause() {
        AssertSQL("SELECT * FROM \"users\" AS \"managers\"", users.alias("managers"))
    }

    func test_subscript_withExpression_returnsNamespacedExpression() {
        AssertSQL("SELECT \"users\".\"admin\" FROM \"users\"", users.select(users[admin]))
        AssertSQL("SELECT \"users\".\"salary\" FROM \"users\"", users.select(users[salary]))
        AssertSQL("SELECT \"users\".\"age\" FROM \"users\"", users.select(users[age]))
        AssertSQL("SELECT \"users\".\"email\" FROM \"users\"", users.select(users[email]))
        AssertSQL("SELECT \"users\".* FROM \"users\"", users.select(users[*]))
    }

    func test_subscript_withAliasAndExpression_returnsAliasedExpression() {
        let managers = users.alias("managers")
        AssertSQL("SELECT \"managers\".\"admin\" FROM \"users\" AS \"managers\"", managers.select(managers[admin]))
        AssertSQL("SELECT \"managers\".\"salary\" FROM \"users\" AS \"managers\"", managers.select(managers[salary]))
        AssertSQL("SELECT \"managers\".\"age\" FROM \"users\" AS \"managers\"", managers.select(managers[age]))
        AssertSQL("SELECT \"managers\".\"email\" FROM \"users\" AS \"managers\"", managers.select(managers[email]))
        AssertSQL("SELECT \"managers\".* FROM \"users\" AS \"managers\"", managers.select(managers[*]))
    }

    func test_SQL_compilesProperly() {
        var managers = users.alias("managers")
        // TODO: automatically namespace in the future?
        managers = managers.filter(managers[admin] == true)

        let query = users
            .select(users[email], count(users[age]))
            .join(.LeftOuter, managers, on: managers[id] == users[manager_id])
            .filter(21..<32 ~= users[age])
            .group(users[age], having: count(users[age]) > 1)
            .order(users[email].desc)
            .limit(1, offset: 2)

        let SQL = "SELECT \"users\".\"email\", count(\"users\".\"age\") FROM \"users\" " +
            "LEFT OUTER JOIN \"users\" AS \"managers\" " +
            "ON ((\"managers\".\"id\" = \"users\".\"manager_id\") AND (\"managers\".\"admin\" = 1)) " +
            "WHERE \"users\".\"age\" BETWEEN 21 AND 32 " +
            "GROUP BY \"users\".\"age\" HAVING (count(\"users\".\"age\") > 1) " +
            "ORDER BY \"users\".\"email\" DESC " +
            "LIMIT 1 " +
            "OFFSET 2"
        AssertSQL(SQL, query)
    }

    func test_first_withAnEmptyQuery_returnsNil() {
        XCTAssert(users.first == nil)
    }

    func test_first_returnsTheFirstRow() {
        insertUsers("alice", "betsy")

        XCTAssertEqual(1, users.first![id])
        AssertSQL("SELECT * FROM \"users\" LIMIT 1")
    }

    func test_isEmpty_returnsWhetherOrNotTheQueryIsEmpty() {
        XCTAssertTrue(users.isEmpty)

        insertUser("alice")

        XCTAssertFalse(users.isEmpty)

        AssertSQL("SELECT * FROM \"users\" LIMIT 1", 2)
    }

    func test_insert_insertsRows() {
        XCTAssertEqual(1, users.insert(email <- "alice@example.com", age <- 30).id!)

        AssertSQL("INSERT INTO \"users\" (\"email\", \"age\") VALUES ('alice@example.com', 30)")

        XCTAssertNil(users.insert(email <- "alice@example.com", age <- 30).id)
    }

    func test_insert_withQuery_insertsRows() {
        db.execute("CREATE TABLE \"emails\" (\"email\" TEXT)")
        let emails = db["emails"]
        let admins = users.select(email).filter(admin == true)

        emails.insert(admins)!
        AssertSQL("INSERT INTO \"emails\" SELECT \"email\" FROM \"users\" WHERE (\"admin\" = 1)")
    }

    func test_insert_insertsDefaultRow() {
        db.execute("CREATE TABLE \"timestamps\" (\"id\" INTEGER PRIMARY KEY, \"timestamp\" TEXT DEFAULT CURRENT_DATETIME)")
        let table = db["timestamps"]

        XCTAssertEqual(1, table.insert().id!)
        AssertSQL("INSERT INTO \"timestamps\" DEFAULT VALUES")
    }

    func test_replace_replaceRows() {
        XCTAssertEqual(1, users.replace(email <- "alice@example.com", age <- 30).id!)
        AssertSQL("INSERT OR REPLACE INTO \"users\" (\"email\", \"age\") VALUES ('alice@example.com', 30)")

        XCTAssertEqual(1, users.replace(id <- 1, email <- "betty@example.com", age <- 30).id!)
        AssertSQL("INSERT OR REPLACE INTO \"users\" (\"id\", \"email\", \"age\") VALUES (1, 'betty@example.com', 30)")
    }

    func test_update_updatesRows() {
        insertUsers("alice", "betsy")
        insertUser("dolly", admin: true)

        XCTAssertEqual(2, users.filter(!admin).update(age <- 30, admin <- true).changes!)
        XCTAssertEqual(0, users.filter(!admin).update(age <- 30, admin <- true).changes!)
    }

    func test_delete_deletesRows() {
        insertUser("alice", age: 20)
        XCTAssertEqual(0, users.filter(email == "betsy@example.com").delete().changes!)

        insertUser("betsy", age: 30)
        XCTAssertEqual(2, users.delete().changes!)
        XCTAssertEqual(0, users.delete().changes!)
    }

    func test_count_returnsCount() {
        XCTAssertEqual(0, users.count)

        insertUser("alice")
        XCTAssertEqual(1, users.count)
        XCTAssertEqual(0, users.filter(age != nil).count)
    }

    func test_count_withExpression_returnsCount() {
        insertUser("alice", age: 20)
        insertUser("betsy", age: 20)
        insertUser("cindy")

        XCTAssertEqual(2, users.count(age))
        XCTAssertEqual(1, users.count(distinct: age))
    }

    func test_max_withInt_returnsMaximumInt() {
        XCTAssert(users.max(age) == nil)

        insertUser("alice", age: 20)
        insertUser("betsy", age: 30)
        XCTAssertEqual(30, users.max(age)!)
    }

    func test_min_withInt_returnsMinimumInt() {
        XCTAssert(users.min(age) == nil)

        insertUser("alice", age: 20)
        insertUser("betsy", age: 30)
        XCTAssertEqual(20, users.min(age)!)
    }

    func test_averageWithInt_returnsDouble() {
        XCTAssert(users.average(age) == nil)

        insertUser("alice", age: 20)
        insertUser("betsy", age: 50)
        insertUser("cindy", age: 50)
        XCTAssertEqual(40.0, users.average(age)!)
        XCTAssertEqual(35.0, users.average(distinct: age)!)
    }

    func test_sum_returnsSum() {
        XCTAssert(users.sum(age) == nil)

        insertUser("alice", age: 20)
        insertUser("betsy", age: 30)
        insertUser("cindy", age: 30)
        XCTAssertEqual(80, users.sum(age)!)
        XCTAssertEqual(50, users.sum(distinct: age)!)
    }

    func test_total_returnsTotal() {
        XCTAssertEqual(0.0, users.total(age))

        insertUser("alice", age: 20)
        insertUser("betsy", age: 30)
        insertUser("cindy", age: 30)
        XCTAssertEqual(80.0, users.total(age))
        XCTAssertEqual(50.0, users.total(distinct: age))
    }

    func test_row_withBoundColumn_returnsValue() {
        insertUser("alice", age: 20)
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
    formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
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

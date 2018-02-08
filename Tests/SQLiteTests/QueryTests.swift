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

class QueryTests : XCTestCase {

    let users = Table("users")
    let id = Expression<Int64>("id")
    let email = Expression<String>("email")
    let age = Expression<Int?>("age")
    let admin = Expression<Bool>("admin")
    let optionalAdmin = Expression<Bool?>("admin")

    let posts = Table("posts")
    let userId = Expression<Int64>("user_id")
    let categoryId = Expression<Int64>("category_id")
    let published = Expression<Bool>("published")

    let categories = Table("categories")
    let tag = Expression<String>("tag")

    func test_select_withExpression_compilesSelectClause() {
        AssertSQL("SELECT \"email\" FROM \"users\"", users.select(email))
    }

    func test_select_withStarExpression_compilesSelectClause() {
        AssertSQL("SELECT * FROM \"users\"", users.select(*))
    }

    func test_select_withNamespacedStarExpression_compilesSelectClause() {
        AssertSQL("SELECT \"users\".* FROM \"users\"", users.select(users[*]))
    }

    func test_select_withVariadicExpressions_compilesSelectClause() {
        AssertSQL("SELECT \"email\", count(*) FROM \"users\"", users.select(email, count(*)))
    }

    func test_select_withExpressions_compilesSelectClause() {
        AssertSQL("SELECT \"email\", count(*) FROM \"users\"", users.select([email, count(*)]))
    }

    func test_selectDistinct_withExpression_compilesSelectClause() {
        AssertSQL("SELECT DISTINCT \"age\" FROM \"users\"", users.select(distinct: age))
    }

    func test_selectDistinct_withExpressions_compilesSelectClause() {
        AssertSQL("SELECT DISTINCT \"age\", \"admin\" FROM \"users\"", users.select(distinct: [age, admin]))
    }

    func test_selectDistinct_withStar_compilesSelectClause() {
        AssertSQL("SELECT DISTINCT * FROM \"users\"", users.select(distinct: *))
    }

    func test_join_compilesJoinClause() {
        AssertSQL(
            "SELECT * FROM \"users\" INNER JOIN \"posts\" ON (\"posts\".\"user_id\" = \"users\".\"id\")",
            users.join(posts, on: posts[userId] == users[id])
        )
    }

    func test_join_withExplicitType_compilesJoinClauseWithType() {
        AssertSQL(
            "SELECT * FROM \"users\" LEFT OUTER JOIN \"posts\" ON (\"posts\".\"user_id\" = \"users\".\"id\")",
            users.join(.leftOuter, posts, on: posts[userId] == users[id])
        )

        AssertSQL(
            "SELECT * FROM \"users\" CROSS JOIN \"posts\" ON (\"posts\".\"user_id\" = \"users\".\"id\")",
            users.join(.cross, posts, on: posts[userId] == users[id])
        )
    }

    func test_join_withTableCondition_compilesJoinClauseWithTableCondition() {
        AssertSQL(
            "SELECT * FROM \"users\" INNER JOIN \"posts\" ON ((\"posts\".\"user_id\" = \"users\".\"id\") AND \"published\")",
            users.join(posts.filter(published), on: posts[userId] == users[id])
        )
    }

    func test_join_whenChained_compilesAggregateJoinClause() {
        AssertSQL(
            "SELECT * FROM \"users\" " +
            "INNER JOIN \"posts\" ON (\"posts\".\"user_id\" = \"users\".\"id\") " +
            "INNER JOIN \"categories\" ON (\"categories\".\"id\" = \"posts\".\"category_id\")",
            users.join(posts, on: posts[userId] == users[id]).join(categories, on: categories[id] == posts[categoryId])
        )
    }

    func test_filter_compilesWhereClause() {
        AssertSQL("SELECT * FROM \"users\" WHERE (\"admin\" = 1)", users.filter(admin == true))
    }

    func test_filter_compilesWhereClause_false() {
        AssertSQL("SELECT * FROM \"users\" WHERE (\"admin\" = 0)", users.filter(admin == false))
    }

    func test_filter_compilesWhereClause_optional() {
        AssertSQL("SELECT * FROM \"users\" WHERE (\"admin\" = 1)", users.filter(optionalAdmin == true))
    }

    func test_filter_compilesWhereClause_optional_false() {
        AssertSQL("SELECT * FROM \"users\" WHERE (\"admin\" = 0)", users.filter(optionalAdmin == false))
    }

    func test_where_compilesWhereClause() {
        AssertSQL("SELECT * FROM \"users\" WHERE (\"admin\" = 1)", users.where(admin == true))
    }

    func test_where_compilesWhereClause_false() {
        AssertSQL("SELECT * FROM \"users\" WHERE (\"admin\" = 0)", users.where(admin == false))
    }

    func test_where_compilesWhereClause_optional() {
        AssertSQL("SELECT * FROM \"users\" WHERE (\"admin\" = 1)", users.where(optionalAdmin == true))
    }

    func test_where_compilesWhereClause_optional_false() {
        AssertSQL("SELECT * FROM \"users\" WHERE (\"admin\" = 0)", users.where(optionalAdmin == false))
    }

    func test_filter_whenChained_compilesAggregateWhereClause() {
        AssertSQL(
            "SELECT * FROM \"users\" WHERE ((\"age\" >= 35) AND \"admin\")",
            users.filter(age >= 35).filter(admin)
        )
    }

    func test_group_withSingleExpressionName_compilesGroupClause() {
        AssertSQL("SELECT * FROM \"users\" GROUP BY \"age\"",
            users.group(age))
    }

    func test_group_withVariadicExpressionNames_compilesGroupClause() {
        AssertSQL("SELECT * FROM \"users\" GROUP BY \"age\", \"admin\"", users.group(age, admin))
    }

    func test_group_withExpressionNameAndHavingBindings_compilesGroupClause() {
        AssertSQL("SELECT * FROM \"users\" GROUP BY \"age\" HAVING \"admin\"", users.group(age, having: admin))
        AssertSQL("SELECT * FROM \"users\" GROUP BY \"age\" HAVING (\"age\" >= 30)", users.group(age, having: age >= 30))
    }

    func test_group_withExpressionNamesAndHavingBindings_compilesGroupClause() {
        AssertSQL(
            "SELECT * FROM \"users\" GROUP BY \"age\", \"admin\" HAVING \"admin\"",
            users.group([age, admin], having: admin)
        )
        AssertSQL(
            "SELECT * FROM \"users\" GROUP BY \"age\", \"admin\" HAVING (\"age\" >= 30)",
            users.group([age, admin], having: age >= 30)
        )
    }

    func test_order_withSingleExpressionName_compilesOrderClause() {
        AssertSQL("SELECT * FROM \"users\" ORDER BY \"age\"", users.order(age))
    }

    func test_order_withVariadicExpressionNames_compilesOrderClause() {
        AssertSQL("SELECT * FROM \"users\" ORDER BY \"age\", \"email\"", users.order(age, email))
    }

    func test_order_withArrayExpressionNames_compilesOrderClause() {
        AssertSQL("SELECT * FROM \"users\" ORDER BY \"age\", \"email\"", users.order([age, email]))
    }

    func test_order_withExpressionAndSortDirection_compilesOrderClause() {
//        AssertSQL("SELECT * FROM \"users\" ORDER BY \"age\" DESC, \"email\" ASC", users.order(age.desc, email.asc))
    }

    func test_order_whenChained_resetsOrderClause() {
        AssertSQL("SELECT * FROM \"users\" ORDER BY \"age\"", users.order(email).order(age))
    }

    func test_reverse_withoutOrder_ordersByRowIdDescending() {
//        AssertSQL("SELECT * FROM \"users\" ORDER BY \"ROWID\" DESC", users.reverse())
    }

    func test_reverse_withOrder_reversesOrder() {
//        AssertSQL("SELECT * FROM \"users\" ORDER BY \"age\" DESC, \"email\" ASC", users.order(age, email.desc).reverse())
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

        AssertSQL("SELECT * FROM \"users\" LIMIT 10 OFFSET 20", query.limit(10, offset: 20))
        AssertSQL("SELECT * FROM \"users\"", query.limit(nil))
    }

    func test_alias_aliasesTable() {
        let managerId = Expression<Int64>("manager_id")

        let managers = users.alias("managers")

        AssertSQL(
            "SELECT * FROM \"users\" " +
            "INNER JOIN \"users\" AS \"managers\" ON (\"managers\".\"id\" = \"users\".\"manager_id\")",
            users.join(managers, on: managers[id] == users[managerId])
        )
    }

    func test_insert_compilesInsertExpression() {
        AssertSQL(
            "INSERT INTO \"users\" (\"email\", \"age\") VALUES ('alice@example.com', 30)",
            users.insert(email <- "alice@example.com", age <- 30)
        )
    }

    func test_insert_withOnConflict_compilesInsertOrOnConflictExpression() {
        AssertSQL(
            "INSERT OR REPLACE INTO \"users\" (\"email\", \"age\") VALUES ('alice@example.com', 30)",
            users.insert(or: .replace, email <- "alice@example.com", age <- 30)
        )
    }

    func test_insert_compilesInsertExpressionWithDefaultValues() {
        AssertSQL("INSERT INTO \"users\" DEFAULT VALUES", users.insert())
    }

    func test_insert_withQuery_compilesInsertExpressionWithSelectStatement() {
        let emails = Table("emails")

        AssertSQL(
            "INSERT INTO \"emails\" SELECT \"email\" FROM \"users\" WHERE \"admin\"",
            emails.insert(users.select(email).filter(admin))
        )
    }

    func test_insert_encodable() throws {
        let emails = Table("emails")
        let value = TestCodable(int: 1, string: "2", bool: true, float: 3, double: 4, optional: nil, sub: nil)
        let insert = try emails.insert(value)
        AssertSQL(
            "INSERT INTO \"emails\" (\"int\", \"string\", \"bool\", \"float\", \"double\") VALUES (1, '2', 1, 3.0, 4.0)",
            insert
        )
    }

    func test_insert_encodable_with_nested_encodable() throws {
        let emails = Table("emails")
        let value1 = TestCodable(int: 1, string: "2", bool: true, float: 3, double: 4, optional: nil, sub: nil)
        let value = TestCodable(int: 1, string: "2", bool: true, float: 3, double: 4, optional: "optional", sub: value1)
        let insert = try emails.insert(value)
        let encodedJSON = try JSONEncoder().encode(value1)
        let encodedJSONString = String(data: encodedJSON, encoding: .utf8)!
        AssertSQL(
            "INSERT INTO \"emails\" (\"int\", \"string\", \"bool\", \"float\", \"double\", \"optional\", \"sub\") VALUES (1, '2', 1, 3.0, 4.0, 'optional', '\(encodedJSONString)')",
            insert
        )
    }

    func test_update_compilesUpdateExpression() {
        AssertSQL(
            "UPDATE \"users\" SET \"age\" = 30, \"admin\" = 1 WHERE (\"id\" = 1)",
            users.filter(id == 1).update(age <- 30, admin <- true)
        )
    }

    func test_update_compilesUpdateLimitOrderExpression() {
        AssertSQL(
            "UPDATE \"users\" SET \"age\" = 30 ORDER BY \"id\" LIMIT 1",
            users.order(id).limit(1).update(age <- 30)
        )
    }

    func test_update_encodable() throws {
        let emails = Table("emails")
        let value = TestCodable(int: 1, string: "2", bool: true, float: 3, double: 4, optional: nil, sub: nil)
        let update = try emails.update(value)
        AssertSQL(
            "UPDATE \"emails\" SET \"int\" = 1, \"string\" = '2', \"bool\" = 1, \"float\" = 3.0, \"double\" = 4.0",
            update
        )
    }

    func test_update_encodable_with_nested_encodable() throws {
        let emails = Table("emails")
        let value1 = TestCodable(int: 1, string: "2", bool: true, float: 3, double: 4, optional: nil, sub: nil)
        let value = TestCodable(int: 1, string: "2", bool: true, float: 3, double: 4, optional: nil, sub: value1)
        let update = try emails.update(value)
        let encodedJSON = try JSONEncoder().encode(value1)
        let encodedJSONString = String(data: encodedJSON, encoding: .utf8)!
        AssertSQL(
            "UPDATE \"emails\" SET \"int\" = 1, \"string\" = '2', \"bool\" = 1, \"float\" = 3.0, \"double\" = 4.0, \"sub\" = '\(encodedJSONString)'",
            update
        )
    }

    func test_delete_compilesDeleteExpression() {
        AssertSQL(
            "DELETE FROM \"users\" WHERE (\"id\" = 1)",
            users.filter(id == 1).delete()
        )
    }

    func test_delete_compilesDeleteLimitOrderExpression() {
        AssertSQL(
            "DELETE FROM \"users\" ORDER BY \"id\" LIMIT 1",
            users.order(id).limit(1).delete()
        )
    }

    func test_delete_compilesExistsExpression() {
        AssertSQL(
            "SELECT EXISTS (SELECT * FROM \"users\")",
            users.exists
        )
    }

    func test_count_returnsCountExpression() {
        AssertSQL("SELECT count(*) FROM \"users\"", users.count)
    }

    func test_scalar_returnsScalarExpression() {
        AssertSQL("SELECT \"int\" FROM \"table\"", table.select(int) as ScalarQuery<Int>)
        AssertSQL("SELECT \"intOptional\" FROM \"table\"", table.select(intOptional) as ScalarQuery<Int?>)
        AssertSQL("SELECT DISTINCT \"int\" FROM \"table\"", table.select(distinct: int) as ScalarQuery<Int>)
        AssertSQL("SELECT DISTINCT \"intOptional\" FROM \"table\"", table.select(distinct: intOptional) as ScalarQuery<Int?>)
    }

    func test_subscript_withExpression_returnsNamespacedExpression() {
        let query = Table("query")

        AssertSQL("\"query\".\"blob\"", query[data])
        AssertSQL("\"query\".\"blobOptional\"", query[dataOptional])

        AssertSQL("\"query\".\"bool\"", query[bool])
        AssertSQL("\"query\".\"boolOptional\"", query[boolOptional])

        AssertSQL("\"query\".\"date\"", query[date])
        AssertSQL("\"query\".\"dateOptional\"", query[dateOptional])

        AssertSQL("\"query\".\"double\"", query[double])
        AssertSQL("\"query\".\"doubleOptional\"", query[doubleOptional])

        AssertSQL("\"query\".\"int\"", query[int])
        AssertSQL("\"query\".\"intOptional\"", query[intOptional])

        AssertSQL("\"query\".\"int64\"", query[int64])
        AssertSQL("\"query\".\"int64Optional\"", query[int64Optional])

        AssertSQL("\"query\".\"string\"", query[string])
        AssertSQL("\"query\".\"stringOptional\"", query[stringOptional])

        AssertSQL("\"query\".*", query[*])
    }

    func test_tableNamespacedByDatabase() {
        let table = Table("table", database: "attached")

        AssertSQL("SELECT * FROM \"attached\".\"table\"", table)
    }

}

class QueryIntegrationTests : SQLiteTestCase {

    let id = Expression<Int64>("id")
    let email = Expression<String>("email")

    override func setUp() {
        super.setUp()

        CreateUsersTable()
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
        try! InsertUsers(names)

        let emailColumn = Expression<String>("email")
        let emails = try! db.prepareRowIterator(users).map { $0[emailColumn] }

        XCTAssertEqual(names.map({ "\($0)@example.com" }), emails.sorted())
    }

    func test_ambiguousMap() {
        let names = ["a", "b", "c"]
        try! InsertUsers(names)

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
            builder.column(Expression<String?>("optional"))
            builder.column(Expression<Data>("sub"))
        })

        let value1 = TestCodable(int: 1, string: "2", bool: true, float: 3, double: 4, optional: nil, sub: nil)
        let value = TestCodable(int: 5, string: "6", bool: true, float: 7, double: 8, optional: "optional", sub: value1)

        try db.run(table.insert(value))

        let rows = try db.prepare(table)
        let values: [TestCodable] = try rows.map({ try $0.decode() })
        XCTAssertEqual(values.count, 1)
        XCTAssertEqual(values[0].int, 5)
        XCTAssertEqual(values[0].string, "6")
        XCTAssertEqual(values[0].bool, true)
        XCTAssertEqual(values[0].float, 7)
        XCTAssertEqual(values[0].double, 8)
        XCTAssertEqual(values[0].optional, "optional")
        XCTAssertEqual(values[0].sub?.int, 1)
        XCTAssertEqual(values[0].sub?.string, "2")
        XCTAssertEqual(values[0].sub?.bool, true)
        XCTAssertEqual(values[0].sub?.float, 3)
        XCTAssertEqual(values[0].sub?.double, 4)
        XCTAssertNil(values[0].sub?.optional)
        XCTAssertNil(values[0].sub?.sub)
    }

    func test_scalar() {
        XCTAssertEqual(0, try! db.scalar(users.count))
        XCTAssertEqual(false, try! db.scalar(users.exists))

        try! InsertUsers("alice")
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
        try! InsertUser("alice")
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
}

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

class QueryTests: XCTestCase {

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
        assertSQL("SELECT \"email\" FROM \"users\"", users.select(email))
    }

    func test_select_withStarExpression_compilesSelectClause() {
        assertSQL("SELECT * FROM \"users\"", users.select(*))
    }

    func test_select_withNamespacedStarExpression_compilesSelectClause() {
        assertSQL("SELECT \"users\".* FROM \"users\"", users.select(users[*]))
    }

    func test_select_withVariadicExpressions_compilesSelectClause() {
        assertSQL("SELECT \"email\", count(*) FROM \"users\"", users.select(email, count(*)))
    }

    func test_select_withExpressions_compilesSelectClause() {
        assertSQL("SELECT \"email\", count(*) FROM \"users\"", users.select([email, count(*)]))
    }

    func test_selectDistinct_withExpression_compilesSelectClause() {
        assertSQL("SELECT DISTINCT \"age\" FROM \"users\"", users.select(distinct: age))
    }

    func test_selectDistinct_withExpressions_compilesSelectClause() {
        assertSQL("SELECT DISTINCT \"age\", \"admin\" FROM \"users\"", users.select(distinct: [age, admin]))
    }

    func test_selectDistinct_withStar_compilesSelectClause() {
        assertSQL("SELECT DISTINCT * FROM \"users\"", users.select(distinct: *))
    }

    func test_join_compilesJoinClause() {
        assertSQL(
            "SELECT * FROM \"users\" INNER JOIN \"posts\" ON (\"posts\".\"user_id\" = \"users\".\"id\")",
            users.join(posts, on: posts[userId] == users[id])
        )
    }

    func test_join_withExplicitType_compilesJoinClauseWithType() {
        assertSQL(
            "SELECT * FROM \"users\" LEFT OUTER JOIN \"posts\" ON (\"posts\".\"user_id\" = \"users\".\"id\")",
            users.join(.leftOuter, posts, on: posts[userId] == users[id])
        )

        assertSQL(
            "SELECT * FROM \"users\" CROSS JOIN \"posts\" ON (\"posts\".\"user_id\" = \"users\".\"id\")",
            users.join(.cross, posts, on: posts[userId] == users[id])
        )
    }

    func test_join_withTableCondition_compilesJoinClauseWithTableCondition() {
        assertSQL(
            "SELECT * FROM \"users\" INNER JOIN \"posts\" ON ((\"posts\".\"user_id\" = \"users\".\"id\") AND \"published\")",
            users.join(posts.filter(published), on: posts[userId] == users[id])
        )
    }

    func test_join_whenChained_compilesAggregateJoinClause() {
        assertSQL(
            "SELECT * FROM \"users\" " +
            "INNER JOIN \"posts\" ON (\"posts\".\"user_id\" = \"users\".\"id\") " +
            "INNER JOIN \"categories\" ON (\"categories\".\"id\" = \"posts\".\"category_id\")",
            users.join(posts, on: posts[userId] == users[id]).join(categories, on: categories[id] == posts[categoryId])
        )
    }

    func test_filter_compilesWhereClause() {
        assertSQL("SELECT * FROM \"users\" WHERE (\"admin\" = 1)", users.filter(admin == true))
    }

    func test_filter_compilesWhereClause_false() {
        assertSQL("SELECT * FROM \"users\" WHERE (\"admin\" = 0)", users.filter(admin == false))
    }

    func test_filter_compilesWhereClause_optional() {
        assertSQL("SELECT * FROM \"users\" WHERE (\"admin\" = 1)", users.filter(optionalAdmin == true))
    }

    func test_filter_compilesWhereClause_optional_false() {
        assertSQL("SELECT * FROM \"users\" WHERE (\"admin\" = 0)", users.filter(optionalAdmin == false))
    }

    func test_where_compilesWhereClause() {
        assertSQL("SELECT * FROM \"users\" WHERE (\"admin\" = 1)", users.where(admin == true))
    }

    func test_where_compilesWhereClause_false() {
        assertSQL("SELECT * FROM \"users\" WHERE (\"admin\" = 0)", users.where(admin == false))
    }

    func test_where_compilesWhereClause_optional() {
        assertSQL("SELECT * FROM \"users\" WHERE (\"admin\" = 1)", users.where(optionalAdmin == true))
    }

    func test_where_compilesWhereClause_optional_false() {
        assertSQL("SELECT * FROM \"users\" WHERE (\"admin\" = 0)", users.where(optionalAdmin == false))
    }

    func test_filter_whenChained_compilesAggregateWhereClause() {
        assertSQL(
            "SELECT * FROM \"users\" WHERE ((\"age\" >= 35) AND \"admin\")",
            users.filter(age >= 35).filter(admin)
        )
    }

    func test_group_withSingleExpressionName_compilesGroupClause() {
        assertSQL("SELECT * FROM \"users\" GROUP BY \"age\"",
            users.group(age))
    }

    func test_group_withVariadicExpressionNames_compilesGroupClause() {
        assertSQL("SELECT * FROM \"users\" GROUP BY \"age\", \"admin\"", users.group(age, admin))
    }

    func test_group_withExpressionNameAndHavingBindings_compilesGroupClause() {
        assertSQL("SELECT * FROM \"users\" GROUP BY \"age\" HAVING \"admin\"", users.group(age, having: admin))
        assertSQL("SELECT * FROM \"users\" GROUP BY \"age\" HAVING (\"age\" >= 30)", users.group(age, having: age >= 30))
    }

    func test_group_withExpressionNamesAndHavingBindings_compilesGroupClause() {
        assertSQL(
            "SELECT * FROM \"users\" GROUP BY \"age\", \"admin\" HAVING \"admin\"",
            users.group([age, admin], having: admin)
        )
        assertSQL(
            "SELECT * FROM \"users\" GROUP BY \"age\", \"admin\" HAVING (\"age\" >= 30)",
            users.group([age, admin], having: age >= 30)
        )
    }

    func test_order_withSingleExpressionName_compilesOrderClause() {
        assertSQL("SELECT * FROM \"users\" ORDER BY \"age\"", users.order(age))
    }

    func test_order_withVariadicExpressionNames_compilesOrderClause() {
        assertSQL("SELECT * FROM \"users\" ORDER BY \"age\", \"email\"", users.order(age, email))
    }

    func test_order_withArrayExpressionNames_compilesOrderClause() {
        assertSQL("SELECT * FROM \"users\" ORDER BY \"age\", \"email\"", users.order([age, email]))
    }

    func test_order_withExpressionAndSortDirection_compilesOrderClause() {
//        AssertSQL("SELECT * FROM \"users\" ORDER BY \"age\" DESC, \"email\" ASC", users.order(age.desc, email.asc))
    }

    func test_order_whenChained_resetsOrderClause() {
        assertSQL("SELECT * FROM \"users\" ORDER BY \"age\"", users.order(email).order(age))
    }

    func test_reverse_withoutOrder_ordersByRowIdDescending() {
//        AssertSQL("SELECT * FROM \"users\" ORDER BY \"ROWID\" DESC", users.reverse())
    }

    func test_reverse_withOrder_reversesOrder() {
//        AssertSQL("SELECT * FROM \"users\" ORDER BY \"age\" DESC, \"email\" ASC", users.order(age, email.desc).reverse())
    }

    func test_limit_compilesLimitClause() {
        assertSQL("SELECT * FROM \"users\" LIMIT 5", users.limit(5))
    }

    func test_limit_withOffset_compilesOffsetClause() {
        assertSQL("SELECT * FROM \"users\" LIMIT 5 OFFSET 5", users.limit(5, offset: 5))
    }

    func test_limit_whenChained_overridesLimit() {
        let query = users.limit(5)

        assertSQL("SELECT * FROM \"users\" LIMIT 10", query.limit(10))
        assertSQL("SELECT * FROM \"users\"", query.limit(nil))
    }

    func test_limit_whenChained_withOffset_overridesOffset() {
        let query = users.limit(5, offset: 5)

        assertSQL("SELECT * FROM \"users\" LIMIT 10 OFFSET 20", query.limit(10, offset: 20))
        assertSQL("SELECT * FROM \"users\"", query.limit(nil))
    }

    func test_alias_aliasesTable() {
        let managerId = Expression<Int64>("manager_id")

        let managers = users.alias("managers")

        assertSQL(
            "SELECT * FROM \"users\" " +
            "INNER JOIN \"users\" AS \"managers\" ON (\"managers\".\"id\" = \"users\".\"manager_id\")",
            users.join(managers, on: managers[id] == users[managerId])
        )
    }

    func test_insert_compilesInsertExpression() {
        assertSQL(
            "INSERT INTO \"users\" (\"email\", \"age\") VALUES ('alice@example.com', 30)",
            users.insert(email <- "alice@example.com", age <- 30)
        )
    }

    func test_insert_withOnConflict_compilesInsertOrOnConflictExpression() {
        assertSQL(
            "INSERT OR REPLACE INTO \"users\" (\"email\", \"age\") VALUES ('alice@example.com', 30)",
            users.insert(or: .replace, email <- "alice@example.com", age <- 30)
        )
    }

    func test_insert_compilesInsertExpressionWithDefaultValues() {
        assertSQL("INSERT INTO \"users\" DEFAULT VALUES", users.insert())
    }

    func test_insert_withQuery_compilesInsertExpressionWithSelectStatement() {
        let emails = Table("emails")

        assertSQL(
            "INSERT INTO \"emails\" SELECT \"email\" FROM \"users\" WHERE \"admin\"",
            emails.insert(users.select(email).filter(admin))
        )
    }

    func test_insert_many_compilesInsertManyExpression() {
        assertSQL(
            """
            INSERT INTO \"users\" (\"email\", \"age\") VALUES ('alice@example.com', 30), ('geoff@example.com', 32),
             ('alex@example.com', 83)
            """.replacingOccurrences(of: "\n", with: ""),
            users.insertMany([[email <- "alice@example.com", age <- 30],
                              [email <- "geoff@example.com", age <- 32], [email <- "alex@example.com", age <- 83]])
        )
    }
    func test_insert_many_compilesInsertManyNoneExpression() {
        assertSQL(
            "INSERT INTO \"users\" DEFAULT VALUES",
            users.insertMany([])
        )
    }

    func test_insert_many_withOnConflict_compilesInsertManyOrOnConflictExpression() {
        assertSQL(
            """
            INSERT OR REPLACE INTO \"users\" (\"email\", \"age\") VALUES ('alice@example.com', 30),
             ('geoff@example.com', 32), ('alex@example.com', 83)
            """.replacingOccurrences(of: "\n", with: ""),
            users.insertMany(or: .replace, [[email <- "alice@example.com", age <- 30],
                                            [email <- "geoff@example.com", age <- 32],
                                            [email <- "alex@example.com", age <- 83]])
        )
    }

    func test_insert_encodable() throws {
        let emails = Table("emails")
        let value = TestCodable(int: 1, string: "2", bool: true, float: 3, double: 4,
                                date: Date(timeIntervalSince1970: 0), optional: nil, sub: nil)
        let insert = try emails.insert(value)
        assertSQL(
            """
            INSERT INTO \"emails\" (\"int\", \"string\", \"bool\", \"float\", \"double\", \"date\")
             VALUES (1, '2', 1, 3.0, 4.0, '1970-01-01T00:00:00.000')
            """.replacingOccurrences(of: "\n", with: ""),
            insert
        )
    }

    func test_insert_encodable_with_nested_encodable() throws {
        let emails = Table("emails")
        let value1 = TestCodable(int: 1, string: "2", bool: true, float: 3, double: 4,
                                 date: Date(timeIntervalSince1970: 0), optional: nil, sub: nil)
        let value = TestCodable(int: 1, string: "2", bool: true, float: 3, double: 4,
                                date: Date(timeIntervalSince1970: 0), optional: "optional", sub: value1)
        let insert = try emails.insert(value)
        let encodedJSON = try JSONEncoder().encode(value1)
        let encodedJSONString = String(data: encodedJSON, encoding: .utf8)!
        assertSQL(
            """
            INSERT INTO \"emails\" (\"int\", \"string\", \"bool\", \"float\", \"double\", \"date\", \"optional\",
             \"sub\") VALUES (1, '2', 1, 3.0, 4.0, '1970-01-01T00:00:00.000', 'optional', '\(encodedJSONString)')
            """.replacingOccurrences(of: "\n", with: ""),
            insert
        )
    }

    func test_upsert_withOnConflict_compilesInsertOrOnConflictExpression() {
        assertSQL(
            """
            INSERT INTO \"users\" (\"email\", \"age\") VALUES ('alice@example.com', 30) ON CONFLICT (\"email\")
             DO UPDATE SET \"age\" = \"excluded\".\"age\"
            """.replacingOccurrences(of: "\n", with: ""),
            users.upsert(email <- "alice@example.com", age <- 30, onConflictOf: email)
        )
    }

    func test_upsert_encodable() throws {
        let emails = Table("emails")
        let string = Expression<String>("string")
        let value = TestCodable(int: 1, string: "2", bool: true, float: 3, double: 4,
                                date: Date(timeIntervalSince1970: 0), optional: nil, sub: nil)
        let insert = try emails.upsert(value, onConflictOf: string)
        assertSQL(
            """
            INSERT INTO \"emails\" (\"int\", \"string\", \"bool\", \"float\", \"double\", \"date\")
             VALUES (1, '2', 1, 3.0, 4.0, '1970-01-01T00:00:00.000') ON CONFLICT (\"string\")
             DO UPDATE SET \"int\" = \"excluded\".\"int\", \"bool\" = \"excluded\".\"bool\",
             \"float\" = \"excluded\".\"float\", \"double\" = \"excluded\".\"double\", \"date\" = \"excluded\".\"date\"
            """.replacingOccurrences(of: "\n", with: ""),
            insert
        )
    }

    func test_insert_many_encodable() throws {
        let emails = Table("emails")
        let value1 = TestCodable(int: 1, string: "2", bool: true, float: 3, double: 4,
                                 date: Date(timeIntervalSince1970: 0), optional: nil, sub: nil)
        let value2 = TestCodable(int: 2, string: "3", bool: true, float: 3, double: 5,
                                 date: Date(timeIntervalSince1970: 0), optional: nil, sub: nil)
        let value3 = TestCodable(int: 3, string: "4", bool: true, float: 3, double: 6,
                                 date: Date(timeIntervalSince1970: 0), optional: nil, sub: nil)
        let insert = try emails.insertMany([value1, value2, value3])
        assertSQL(
            """
            INSERT INTO \"emails\" (\"int\", \"string\", \"bool\", \"float\", \"double\", \"date\")
             VALUES (1, '2', 1, 3.0, 4.0, '1970-01-01T00:00:00.000'), (2, '3', 1, 3.0, 5.0, '1970-01-01T00:00:00.000'),
             (3, '4', 1, 3.0, 6.0, '1970-01-01T00:00:00.000')
            """.replacingOccurrences(of: "\n", with: ""),
            insert
        )
    }

    func test_update_compilesUpdateExpression() {
        assertSQL(
            "UPDATE \"users\" SET \"age\" = 30, \"admin\" = 1 WHERE (\"id\" = 1)",
            users.filter(id == 1).update(age <- 30, admin <- true)
        )
    }

    func test_update_compilesUpdateLimitOrderExpression() {
        assertSQL(
            "UPDATE \"users\" SET \"age\" = 30 ORDER BY \"id\" LIMIT 1",
            users.order(id).limit(1).update(age <- 30)
        )
    }

    func test_update_encodable() throws {
        let emails = Table("emails")
        let value = TestCodable(int: 1, string: "2", bool: true, float: 3, double: 4,
                                date: Date(timeIntervalSince1970: 0), optional: nil, sub: nil)
        let update = try emails.update(value)
        assertSQL(
            """
            UPDATE \"emails\" SET \"int\" = 1, \"string\" = '2', \"bool\" = 1, \"float\" = 3.0, \"double\" = 4.0,
             \"date\" = '1970-01-01T00:00:00.000'
            """.replacingOccurrences(of: "\n", with: ""),
            update
        )
    }

    func test_update_encodable_with_nested_encodable() throws {
        let emails = Table("emails")
        let value1 = TestCodable(int: 1, string: "2", bool: true, float: 3, double: 4,
                                 date: Date(timeIntervalSince1970: 0), optional: nil, sub: nil)
        let value = TestCodable(int: 1, string: "2", bool: true, float: 3, double: 4,
                                date: Date(timeIntervalSince1970: 0), optional: nil, sub: value1)
        let update = try emails.update(value)
        let encodedJSON = try JSONEncoder().encode(value1)
        let encodedJSONString = String(data: encodedJSON, encoding: .utf8)!
        assertSQL(
            """
            UPDATE \"emails\" SET \"int\" = 1, \"string\" = '2', \"bool\" = 1, \"float\" = 3.0, \"double\" = 4.0,
             \"date\" = '1970-01-01T00:00:00.000', \"sub\" = '\(encodedJSONString)'
            """.replacingOccurrences(of: "\n", with: ""),
            update
        )
    }

    func test_delete_compilesDeleteExpression() {
        assertSQL(
            "DELETE FROM \"users\" WHERE (\"id\" = 1)",
            users.filter(id == 1).delete()
        )
    }

    func test_delete_compilesDeleteLimitOrderExpression() {
        assertSQL(
            "DELETE FROM \"users\" ORDER BY \"id\" LIMIT 1",
            users.order(id).limit(1).delete()
        )
    }

    func test_delete_compilesExistsExpression() {
        assertSQL(
            "SELECT EXISTS (SELECT * FROM \"users\")",
            users.exists
        )
    }

    func test_count_returnsCountExpression() {
        assertSQL("SELECT count(*) FROM \"users\"", users.count)
    }

    func test_scalar_returnsScalarExpression() {
        assertSQL("SELECT \"int\" FROM \"table\"", table.select(int) as ScalarQuery<Int>)
        assertSQL("SELECT \"intOptional\" FROM \"table\"", table.select(intOptional) as ScalarQuery<Int?>)
        assertSQL("SELECT DISTINCT \"int\" FROM \"table\"", table.select(distinct: int) as ScalarQuery<Int>)
        assertSQL("SELECT DISTINCT \"intOptional\" FROM \"table\"", table.select(distinct: intOptional) as ScalarQuery<Int?>)
    }

    func test_subscript_withExpression_returnsNamespacedExpression() {
        let query = Table("query")

        assertSQL("\"query\".\"blob\"", query[data])
        assertSQL("\"query\".\"blobOptional\"", query[dataOptional])

        assertSQL("\"query\".\"bool\"", query[bool])
        assertSQL("\"query\".\"boolOptional\"", query[boolOptional])

        assertSQL("\"query\".\"date\"", query[date])
        assertSQL("\"query\".\"dateOptional\"", query[dateOptional])

        assertSQL("\"query\".\"double\"", query[double])
        assertSQL("\"query\".\"doubleOptional\"", query[doubleOptional])

        assertSQL("\"query\".\"int\"", query[int])
        assertSQL("\"query\".\"intOptional\"", query[intOptional])

        assertSQL("\"query\".\"int64\"", query[int64])
        assertSQL("\"query\".\"int64Optional\"", query[int64Optional])

        assertSQL("\"query\".\"string\"", query[string])
        assertSQL("\"query\".\"stringOptional\"", query[stringOptional])

        assertSQL("\"query\".*", query[*])
    }

    func test_tableNamespacedByDatabase() {
        let table = Table("table", database: "attached")

        assertSQL("SELECT * FROM \"attached\".\"table\"", table)
    }

}

class QueryIntegrationTests: SQLiteTestCase {

    let id = Expression<Int64>("id")
    let email = Expression<String>("email")
    let age = Expression<Int>("age")

    override func setUp() {
        super.setUp()

        createUsersTable()
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
        guard db.satisfiesMinimumVersion(minor: 24) else { return }
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
}

private extension Connection {
    func satisfiesMinimumVersion(minor: Int, patch: Int = 0) -> Bool {
        guard let version = try? scalar("SELECT sqlite_version()") as? String else { return false }
        let components = version.split(separator: ".", maxSplits: 3).compactMap { Int($0) }
        guard components.count == 3 else { return false }

        return components[1] >= minor && components[2] >= patch
    }
}

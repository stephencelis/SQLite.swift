import XCTest
@testable import SQLite

class SelectTests: SQLiteTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        try createUsersTable()
        try createUsersDataTable()
    }

    func createUsersDataTable() throws {
        try db.execute("""
            CREATE TABLE users_name (
                id INTEGER,
                user_id INTEGER REFERENCES users(id),
                name TEXT,
                step_count BLOB,
                stair_count INTEGER
            )
            """
        )
    }

    func test_select_columns_from_multiple_tables() throws {
        let usersData = Table("users_name")
        let users = Table("users")

        let name = Expression<String>("name")
        let id = Expression<Int64>("id")
        let userID = Expression<Int64>("user_id")
        let stepCount = Expression<UInt64>("step_count")
        let stairCount = Expression<UInt32>("stair_count")
        let email = Expression<String>("email")
        // use UInt64.max - 1 to test Endianness - it should store/load as big endian
        let reallyBigNumber = UInt64.max - 1
        let prettyBigNumber = UInt32.max - 1

        try! insertUser("Joey")
        try! db.run(usersData.insert(
            id <- 1,
            userID <- 1,
            name <- "Joey",
            stepCount <- reallyBigNumber,
            stairCount <- prettyBigNumber
        ))

        try! db.prepare(users.select(name, email, stepCount, stairCount).join(usersData, on: userID == users[id])).forEach {
            XCTAssertEqual($0[name], "Joey")
            XCTAssertEqual($0[email], "Joey@example.com")
            XCTAssertEqual($0[stepCount], reallyBigNumber)
            XCTAssertEqual($0[stairCount], prettyBigNumber)
        }

        // ensure we can bind UInt64 and UInt32
        _ = try db.run("SELECT * FROM \"users_name\" WHERE step_count = ? AND stair_count = ?",
                       reallyBigNumber, prettyBigNumber)
    }
}

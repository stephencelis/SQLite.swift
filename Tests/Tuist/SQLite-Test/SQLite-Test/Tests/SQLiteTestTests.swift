import Testing
import SQLite

struct SQLiteTestTests {

    @Test func test_connection() async throws {
        let connection = try SQLite.Connection(.inMemory)
        let version = connection.sqliteVersion

        #expect(version.major == 3)

    }
}

import XCTest
@testable import SQLite

// Note: these tests are only run when the FTS5 trait has been enabled.
class FTS5IntegrationTests: SQLiteTestCase {
    let email = SQLite.Expression<String>("email")
    let index = VirtualTable("index")

    private func createIndex() throws {
        try createOrSkip { db in
            try db.run(index.create(.FTS5(
                FTS5Config()
                    .column(email)
                    .tokenizer(.Unicode61()))
            ))
        }

        for user in try db.prepare(users) {
            try db.run(index.insert(email <- user[email]))
        }
    }

    private func createTrigramIndex() throws {
        try createOrSkip { db in
            try db.run(index.create(.FTS5(
                FTS5Config()
                  .column(email)
                  .tokenizer(.Trigram(caseSensitive: false)))
            ))
        }

        for user in try db.prepare(users) {
            try db.run(index.insert(email <- user[email]))
        }
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        try createUsersTable()
        try insertUsers("John", "Paul", "George", "Ringo")
    }

    func testMatch() throws {
        try createIndex()
        let matches = Array(try db.prepare(index.match("Paul")))
        XCTAssertEqual(matches.map { $0[email ]}, ["Paul@example.com"])
    }

    func testMatchPartial() throws {
        try insertUsers("Paula")
        try createIndex()
        let matches = Array(try db.prepare(index.match("Pa*")))
        XCTAssertEqual(matches.map { $0[email ]}, ["Paul@example.com", "Paula@example.com"])
    }

    func testTrigramIndex() throws {
        try createTrigramIndex()
        let matches = Array(try db.prepare(index.match("Paul")))
        XCTAssertEqual(1, matches.count)
    }

    func testWeightedBM25ChangesResultOrder() throws {
        let articles = VirtualTable("articles")
        let title = SQLite.Expression<String>("title")
        let body = SQLite.Expression<String>("body")
        try createOrSkip { db in
            try db.run(articles.create(.FTS5(FTS5Config().columns([title, body]))))
        }

        try db.run(articles.insert(title <- "swift swift", body <- "other"))
        try db.run(articles.insert(title <- "other", body <- "swift swift"))

        let titleFirst = try db.prepare(articles.match("swift").order(articles.bm25(10.0, 1.0)))
        XCTAssertEqual(titleFirst.map { $0[title] }, ["swift swift", "other"])

        let bodyFirst = try db.prepare(articles.match("swift").order(articles.bm25(1.0, 10.0)))
        XCTAssertEqual(bodyFirst.map { $0[title] }, ["other", "swift swift"])
    }

    private func createOrSkip(_ createIndex: (Connection) throws -> Void) throws {
        #if FTS5
        try createIndex(db)
        #else
        throw XCTSkip("FTS5 is not enabled")
        #endif
    }
}

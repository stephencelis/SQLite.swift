import XCTest
@testable import SQLite

class FTSIntegrationTests: SQLiteTestCase {
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

    private func createOrSkip(_ createIndex: (Connection) throws -> Void) throws {
        #if FTS5
        try createIndex(db)
        #else
        throw XCTSkip("FTS5 is not enabled")
        #endif
    }
}

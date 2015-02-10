import XCTest
import SQLite

let subject = Expression<String>("subject")
let body = Expression<String>("body")

class FTSTests: SQLiteTestCase {

    var emails: Query { return db["emails"] }

    func test_createVtable_usingFts4_createsVirtualTable() {
        db.create(vtable: emails, using: fts4(subject, body))

        AssertSQL("CREATE VIRTUAL TABLE \"emails\" USING fts4(\"subject\", \"body\")")
    }

    func test_createVtable_usingFts4_withPorterTokenizer_createsVirtualTableWithTokenizer() {
        db.create(vtable: emails, using: fts4([subject, body], tokenize: .Porter))

        AssertSQL("CREATE VIRTUAL TABLE \"emails\" USING fts4(\"subject\", \"body\", tokenize=porter)")
    }

    func test_match_withColumnExpression_buildsMatchExpressionWithColumnIdentifier() {
        db.create(vtable: emails, using: fts4(subject, body))

        AssertSQL("SELECT * FROM \"emails\" WHERE (\"subject\" MATCH 'hello')", emails.filter(match("hello", subject)))
    }

    func test_match_withQuery_buildsMatchExpressionWithTableIdentifier() {
        db.create(vtable: emails, using: fts4(subject, body))

        AssertSQL("SELECT * FROM \"emails\" WHERE (\"emails\" MATCH 'hello')", emails.filter(match("hello", emails)))
    }

}

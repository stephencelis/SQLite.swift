import XCTest
import SQLite

class ExpressedTests : XCTestCase {
	@Expressed("id") var propertyID:String = "1"
	func testExpressed() {
		let expression: Expression<String> = $propertyID
	}
}

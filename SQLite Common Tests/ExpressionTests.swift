import XCTest
import SQLite

class ExpressionTests: XCTestCase {

    let db = Database()
    var users: Query { return db["users"] }

    override func setUp() {
        super.setUp()

        CreateUsersTable(db)
    }

    func test_stringExpressionPlusStringExpression_buildsConcatenatingStringExpression() {
        let string = Expression<String>(value: "Hello")
        ExpectExecutions(db, ["SELECT 'Hello' || 'Hello' FROM users": 3]) { _ in
            for _ in self.users.select(string + string) {}
            for _ in self.users.select(string + "Hello") {}
            for _ in self.users.select("Hello" + string) {}
        }
    }

    func test_integerExpression_plusIntegerExpression_buildsAdditiveIntegerExpression() {
        let int = Expression<Int>(value: 2)
        ExpectExecutions(db, ["SELECT 2 + 2 FROM users": 3]) { _ in
            for _ in self.users.select(int + int) {}
            for _ in self.users.select(int + 2) {}
            for _ in self.users.select(2 + int) {}
        }
    }

    func test_doubleExpression_plusDoubleExpression_buildsAdditiveDoubleExpression() {
        let double = Expression<Double>(value: 2.0)
        ExpectExecutions(db, ["SELECT 2.0 + 2.0 FROM users": 3]) { _ in
            for _ in self.users.select(double + double) {}
            for _ in self.users.select(double + 2.0) {}
            for _ in self.users.select(2.0 + double) {}
        }
    }

    func test_integerExpression_minusIntegerExpression_buildsSubtractiveIntegerExpression() {
        let int = Expression<Int>(value: 2)
        ExpectExecutions(db, ["SELECT 2 - 2 FROM users": 3]) { _ in
            for _ in self.users.select(int - int) {}
            for _ in self.users.select(int - 2) {}
            for _ in self.users.select(2 - int) {}
        }
    }

    func test_doubleExpression_minusDoubleExpression_buildsSubtractiveDoubleExpression() {
        let double = Expression<Double>(value: 2.0)
        ExpectExecutions(db, ["SELECT 2.0 - 2.0 FROM users": 3]) { _ in
            for _ in self.users.select(double - double) {}
            for _ in self.users.select(double - 2.0) {}
            for _ in self.users.select(2.0 - double) {}
        }
    }

    func test_integerExpression_timesIntegerExpression_buildsMultiplicativeIntegerExpression() {
        let int = Expression<Int>(value: 2)
        ExpectExecutions(db, ["SELECT 2 * 2 FROM users": 3]) { _ in
            for _ in self.users.select(int * int) {}
            for _ in self.users.select(int * 2) {}
            for _ in self.users.select(2 * int) {}
        }
    }

    func test_doubleExpression_timesDoubleExpression_buildsMultiplicativeDoubleExpression() {
        let double = Expression<Double>(value: 2.0)
        ExpectExecutions(db, ["SELECT 2.0 * 2.0 FROM users": 3]) { _ in
            for _ in self.users.select(double * double) {}
            for _ in self.users.select(double * 2.0) {}
            for _ in self.users.select(2.0 * double) {}
        }
    }

    func test_integerExpression_dividedByIntegerExpression_buildsDivisiveIntegerExpression() {
        let int = Expression<Int>(value: 2)
        ExpectExecutions(db, ["SELECT 2 / 2 FROM users": 3]) { _ in
            for _ in self.users.select(int / int) {}
            for _ in self.users.select(int / 2) {}
            for _ in self.users.select(2 / int) {}
        }
    }

    func test_doubleExpression_dividedByDoubleExpression_buildsDivisiveDoubleExpression() {
        let double = Expression<Double>(value: 2.0)
        ExpectExecutions(db, ["SELECT 2.0 / 2.0 FROM users": 3]) { _ in
            for _ in self.users.select(double / double) {}
            for _ in self.users.select(double / 2.0) {}
            for _ in self.users.select(2.0 / double) {}
        }
    }

    func test_integerExpression_moduloIntegerExpression_buildsModuloIntegerExpression() {
        let int = Expression<Int>(value: 2)
        ExpectExecutions(db, ["SELECT 2 % 2 FROM users": 3]) { _ in
            for _ in self.users.select(int % int) {}
            for _ in self.users.select(int % 2) {}
            for _ in self.users.select(2 % int) {}
        }
    }

    func test_integerExpression_bitShiftLeftIntegerExpression_buildsLeftShiftedIntegerExpression() {
        let int = Expression<Int>(value: 2)
        ExpectExecutions(db, ["SELECT 2 << 2 FROM users": 3]) { _ in
            for _ in self.users.select(int << int) {}
            for _ in self.users.select(int << 2) {}
            for _ in self.users.select(2 << int) {}
        }
    }

    func test_integerExpression_bitShiftRightIntegerExpression_buildsRightShiftedIntegerExpression() {
        let int = Expression<Int>(value: 2)
        ExpectExecutions(db, ["SELECT 2 >> 2 FROM users": 3]) { _ in
            for _ in self.users.select(int >> int) {}
            for _ in self.users.select(int >> 2) {}
            for _ in self.users.select(2 >> int) {}
        }
    }

    func test_integerExpression_bitwiseAndIntegerExpression_buildsAndedIntegerExpression() {
        let int = Expression<Int>(value: 2)
        ExpectExecutions(db, ["SELECT 2 & 2 FROM users": 3]) { _ in
            for _ in self.users.select(int & int) {}
            for _ in self.users.select(int & 2) {}
            for _ in self.users.select(2 & int) {}
        }
    }

    func test_integerExpression_bitwiseOrIntegerExpression_buildsOredIntegerExpression() {
        let int = Expression<Int>(value: 2)
        ExpectExecutions(db, ["SELECT 2 | 2 FROM users": 3]) { _ in
            for _ in self.users.select(int | int) {}
            for _ in self.users.select(int | 2) {}
            for _ in self.users.select(2 | int) {}
        }
    }

    func test_bitwiseNot_integerExpression_buildsComplementIntegerExpression() {
        let int = Expression<Int>(value: 2)
        let query = users.select(~int)
        ExpectExecutions(db, ["SELECT ~(2) FROM users": 1]) { _ in for _ in query {} }
    }

    func test_equalityOperator_withEquatableExpressions_buildsBooleanExpression() {
        let bool = Expression<Bool>(value: true)
        ExpectExecutions(db, ["SELECT 1 = 1 FROM users": 3]) { _ in
            for _ in self.users.select(bool == bool) {}
            for _ in self.users.select(bool == true) {}
            for _ in self.users.select(true == bool) {}
        }
    }

    func test_inequalityOperator_withEquatableExpressions_buildsBooleanExpression() {
        let bool = Expression<Bool>(value: true)
        ExpectExecutions(db, ["SELECT 1 != 1 FROM users": 3]) { _ in
            for _ in self.users.select(bool != bool) {}
            for _ in self.users.select(bool != true) {}
            for _ in self.users.select(true != bool) {}
        }
    }

    func test_greaterThanOperator_withComparableExpressions_buildsBooleanExpression() {
        let int = Expression<Int>(value: 2)
        ExpectExecutions(db, ["SELECT 2 > 2 FROM users": 3]) { _ in
            for _ in self.users.select(int > int) {}
            for _ in self.users.select(int > 2) {}
            for _ in self.users.select(2 > int) {}
        }
    }

    func test_greaterThanOrEqualToOperator_withComparableExpressions_buildsBooleanExpression() {
        let int = Expression<Int>(value: 2)
        ExpectExecutions(db, ["SELECT 2 >= 2 FROM users": 3]) { _ in
            for _ in self.users.select(int >= int) {}
            for _ in self.users.select(int >= 2) {}
            for _ in self.users.select(2 >= int) {}
        }
    }

    func test_lessThanOperator_withComparableExpressions_buildsBooleanExpression() {
        let int = Expression<Int>(value: 2)
        ExpectExecutions(db, ["SELECT 2 < 2 FROM users": 3]) { _ in
            for _ in self.users.select(int < int) {}
            for _ in self.users.select(int < 2) {}
            for _ in self.users.select(2 < int) {}
        }
    }

    func test_lessThanOrEqualToOperator_withComparableExpressions_buildsBooleanExpression() {
        let int = Expression<Int>(value: 2)
        ExpectExecutions(db, ["SELECT 2 <= 2 FROM users": 3]) { _ in
            for _ in self.users.select(int <= int) {}
            for _ in self.users.select(int <= 2) {}
            for _ in self.users.select(2 <= int) {}
        }
    }

    func test_unaryMinusOperator_withIntegerExpression_buildsNegativeIntegerExpression() {
        let int = Expression<Int>(value: 2)
        let query = users.select(-int)
        ExpectExecution(db, query, "-(2)")
    }

    func test_unaryMinusOperator_withDoubleExpression_buildsNegativeDoubleExpression() {
        let double = Expression<Double>(value: 2.0)
        let query = users.select(-double)
        ExpectExecution(db, query, "-(2.0)")
    }

    func test_betweenOperator_withComparableExpression_buildsBetweenBooleanExpression() {
        let int = Expression<Int>(value: 2)
        let query = users.select(0...5 ~= int)
        ExpectExecution(db, query, "2 BETWEEN 0 AND 5")
    }

    func test_likeOperator_withStringExpression_buildsLikeExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(like("%ello", string))
        ExpectExecution(db, query, "'Hello' LIKE '%ello'")
    }

    func test_globOperator_withStringExpression_buildsGlobExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(glob("*ello", string))
        ExpectExecution(db, query, "'Hello' GLOB '*ello'")
    }

    func test_matchOperator_withStringExpression_buildsMatchExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(match("ello", string))
        ExpectExecution(db, query, "'Hello' MATCH 'ello'")
    }

    func test_doubleAndOperator_withBooleanExpressions_buildsCompoundExpression() {
        let bool = Expression<Bool>(value: true)
        let query = users.select(bool && bool)
        ExpectExecution(db, query, "(1) AND (1)")
    }

    func test_doubleOrOperator_withBooleanExpressions_buildsCompoundExpression() {
        let bool = Expression<Bool>(value: true)
        let query = users.select(bool || bool)
        ExpectExecution(db, query, "(1) OR (1)")
    }

    func test_unaryNotOperator_withBooleanExpressions_buildsNotExpression() {
        let bool = Expression<Bool>(value: true)
        let query = users.select(!bool)
        ExpectExecution(db, query, "NOT (1)")
    }

    func test_absFunction_withNumberExpressions_buildsAbsExpression() {
        let int = Expression<Int>(value: -2)
        let query = users.select(abs(int))
        ExpectExecution(db, query, "abs(-2)")
    }

    func test_coalesceFunction_withValueExpressions_buildsCoalesceExpression() {
        let int1 = Expression<Int>(value: nil)
        let int2 = Expression<Int>(value: nil)
        let int3 = Expression<Int>(value: 3)
        let query = users.select(coalesce(int1, int2, int3))
        ExpectExecution(db, query, "coalesce(NULL, NULL, 3)")
    }

    func test_ifNullFunction_withValueExpressionAndValue_buildsIfNullExpression() {
        let int = Expression<Int>(value: nil)
        ExpectExecution(db, users.select(ifnull(int, 1)), "ifnull(NULL, 1)")
        ExpectExecution(db, users.select(int ?? 1), "ifnull(NULL, 1)")
    }

    func test_lengthFunction_withValueExpression_buildsLengthIntExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(length(string))
        ExpectExecution(db, query, "length('Hello')")
    }

    func test_lowerFunction_withStringExpression_buildsLowerStringExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(lower(string))
        ExpectExecution(db, query, "lower('Hello')")
    }

    func test_ltrimFunction_withStringExpression_buildsTrimmedStringExpression() {
        let string = Expression<String>(value: " Hello")
        let query = users.select(ltrim(string))
        ExpectExecution(db, query, "ltrim(' Hello')")
    }

    func test_ltrimFunction_withStringExpressionAndReplacementCharacters_buildsTrimmedStringExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(ltrim(string, "H"))
        ExpectExecution(db, query, "ltrim('Hello', 'H')")
    }

    func test_randomFunction_buildsRandomIntExpression() {
        let query = users.select(random)
        ExpectExecution(db, query, "random()")
    }

    func test_replaceFunction_withStringExpressionAndFindReplaceStrings_buildsReplacedStringExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(replace(string, "He", "E"))
        ExpectExecution(db, query, "replace('Hello', 'He', 'E')")
    }

    func test_roundFunction_withDoubleExpression_buildsRoundedDoubleExpression() {
        let double = Expression<Double>(value: 3.14159)
        let query = users.select(round(double))
        ExpectExecution(db, query, "round(3.14159)")
    }

    func test_roundFunction_withDoubleExpressionAndPrecision_buildsRoundedDoubleExpression() {
        let double = Expression<Double>(value: 3.14159)
        let query = users.select(round(double, 2))
        ExpectExecution(db, query, "round(3.14159, 2)")
    }

    func test_rtrimFunction_withStringExpression_buildsTrimmedStringExpression() {
        let string = Expression<String>(value: "Hello ")
        let query = users.select(rtrim(string))
        ExpectExecution(db, query, "rtrim('Hello ')")
    }

    func test_rtrimFunction_withStringExpressionAndReplacementCharacters_buildsTrimmedStringExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(rtrim(string, "lo"))
        ExpectExecution(db, query, "rtrim('Hello', 'lo')")
    }

    func test_substrFunction_withStringExpressionAndStartIndex_buildsSubstringExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(substr(string, 1))
        ExpectExecution(db, query, "substr('Hello', 1)")
    }

    func test_substrFunction_withStringExpressionPositionAndLength_buildsSubstringExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(substr(string, 1, 2))
        ExpectExecution(db, query, "substr('Hello', 1, 2)")
    }

    func test_substrFunction_withStringExpressionAndRange_buildsSubstringExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(substr(string, 1..<3))
        ExpectExecution(db, query, "substr('Hello', 1, 2)")
    }

    func test_trimFunction_withStringExpression_buildsTrimmedStringExpression() {
        let string = Expression<String>(value: " Hello ")
        let query = users.select(trim(string))
        ExpectExecution(db, query, "trim(' Hello ')")
    }

    func test_trimFunction_withStringExpressionAndReplacementCharacters_buildsTrimmedStringExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(trim(string, "lo"))
        ExpectExecution(db, query, "trim('Hello', 'lo')")
    }

    func test_upperFunction_withStringExpression_buildsLowerStringExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(upper(string))
        ExpectExecution(db, query, "upper('Hello')")
    }

    let id = Expression<Int>("id")
    let email = Expression<String>("email")
    let salary = Expression<Double>("salary")
    let admin = Expression<Bool>("admin")

    func test_countFunction_withExpression_buildsCountExpression() {
        ExpectExecution(db, users.select(count(id)), "count(id)")
        ExpectExecution(db, users.select(count(email)), "count(email)")
        ExpectExecution(db, users.select(count(salary)), "count(salary)")
        ExpectExecution(db, users.select(count(admin)), "count(admin)")
    }

    func test_countFunction_withStar_buildsCountExpression() {
        ExpectExecution(db, users.select(count(*)), "count(*)")
    }

    func test_maxFunction_withExpression_buildsMaxExpression() {
        ExpectExecution(db, users.select(max(id)), "max(id)")
        ExpectExecution(db, users.select(max(email)), "max(email)")
        ExpectExecution(db, users.select(max(salary)), "max(salary)")
        ExpectExecution(db, users.select(max(admin)), "max(admin)")
    }

    func test_minFunction_withExpression_buildsMinExpression() {
        ExpectExecution(db, users.select(min(id)), "min(id)")
        ExpectExecution(db, users.select(min(email)), "min(email)")
        ExpectExecution(db, users.select(min(salary)), "min(salary)")
        ExpectExecution(db, users.select(min(admin)), "min(admin)")
    }

    func test_averageFunction_withExpression_buildsAverageExpression() {
        ExpectExecution(db, users.select(average(id)), "avg(id)")
        ExpectExecution(db, users.select(average(salary)), "avg(salary)")
    }

    func test_sumFunction_withExpression_buildsSumExpression() {
        ExpectExecution(db, users.select(sum(id)), "sum(id)")
        ExpectExecution(db, users.select(sum(salary)), "sum(salary)")
    }

    func test_totalFunction_withExpression_buildsTotalExpression() {
        ExpectExecution(db, users.select(total(id)), "total(id)")
        ExpectExecution(db, users.select(total(salary)), "total(salary)")
    }

    func test_containsFunction_withValueExpressionAndValueArray_buildsInExpression() {
        ExpectExecution(db, users.select(contains([1, 2, 3], id)), "id IN (1, 2, 3)")
    }

}

func ExpectExecution(db: Database, query: Query, SQL: String) {
    ExpectExecutions(db, ["SELECT \(SQL) FROM users": 1]) { _ in for _ in query {} }
}

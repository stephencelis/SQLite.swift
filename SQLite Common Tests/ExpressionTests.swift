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
        ExpectExecutionMatches(db, "~(2)", users.select(~int))
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
        ExpectExecutionMatches(db, "-(2)", query)
    }

    func test_unaryMinusOperator_withDoubleExpression_buildsNegativeDoubleExpression() {
        let double = Expression<Double>(value: 2.0)
        let query = users.select(-double)
        ExpectExecutionMatches(db, "-(2.0)", query)
    }

    func test_betweenOperator_withComparableExpression_buildsBetweenBooleanExpression() {
        let int = Expression<Int>(value: 2)
        let query = users.select(0...5 ~= int)
        ExpectExecutionMatches(db, "2 BETWEEN 0 AND 5", query)
    }

    func test_likeOperator_withStringExpression_buildsLikeExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(like("%ello", string))
        ExpectExecutionMatches(db, "'Hello' LIKE '%ello'", query)
    }

    func test_globOperator_withStringExpression_buildsGlobExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(glob("*ello", string))
        ExpectExecutionMatches(db, "'Hello' GLOB '*ello'", query)
    }

    func test_matchOperator_withStringExpression_buildsMatchExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(match("ello", string))
        ExpectExecutionMatches(db, "'Hello' MATCH 'ello'", query)
    }

    func test_doubleAndOperator_withBooleanExpressions_buildsCompoundExpression() {
        let bool = Expression<Bool>(value: true)
        let query = users.select(bool && bool)
        ExpectExecutionMatches(db, "(1) AND (1)", query)
    }

    func test_doubleOrOperator_withBooleanExpressions_buildsCompoundExpression() {
        let bool = Expression<Bool>(value: true)
        let query = users.select(bool || bool)
        ExpectExecutionMatches(db, "(1) OR (1)", query)
    }

    func test_unaryNotOperator_withBooleanExpressions_buildsNotExpression() {
        let bool = Expression<Bool>(value: true)
        let query = users.select(!bool)
        ExpectExecutionMatches(db, "NOT (1)", query)
    }

    func test_absFunction_withNumberExpressions_buildsAbsExpression() {
        let int = Expression<Int>(value: -2)
        let query = users.select(abs(int))
        ExpectExecutionMatches(db, "abs(-2)", query)
    }

    func test_coalesceFunction_withValueExpressions_buildsCoalesceExpression() {
        let int1 = Expression<Int>(value: nil)
        let int2 = Expression<Int>(value: nil)
        let int3 = Expression<Int>(value: 3)
        let query = users.select(coalesce(int1, int2, int3))
        ExpectExecutionMatches(db, "coalesce(NULL, NULL, 3)", query)
    }

    func test_ifNullFunction_withValueExpressionAndValue_buildsIfNullExpression() {
        let int = Expression<Int>(value: nil)
        ExpectExecutionMatches(db, "ifnull(NULL, 1)", users.select(ifnull(int, 1)))
        ExpectExecutionMatches(db, "ifnull(NULL, 1)", users.select(int ?? 1))
    }

    func test_lengthFunction_withValueExpression_buildsLengthIntExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(length(string))
        ExpectExecutionMatches(db, "length('Hello')", query)
    }

    func test_lowerFunction_withStringExpression_buildsLowerStringExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(lower(string))
        ExpectExecutionMatches(db, "lower('Hello')", query)
    }

    func test_ltrimFunction_withStringExpression_buildsTrimmedStringExpression() {
        let string = Expression<String>(value: " Hello")
        let query = users.select(ltrim(string))
        ExpectExecutionMatches(db, "ltrim(' Hello')", query)
    }

    func test_ltrimFunction_withStringExpressionAndReplacementCharacters_buildsTrimmedStringExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(ltrim(string, "H"))
        ExpectExecutionMatches(db, "ltrim('Hello', 'H')", query)
    }

    func test_randomFunction_buildsRandomIntExpression() {
        let query = users.select(random)
        ExpectExecutionMatches(db, "random()", query)
    }

    func test_replaceFunction_withStringExpressionAndFindReplaceStrings_buildsReplacedStringExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(replace(string, "He", "E"))
        ExpectExecutionMatches(db, "replace('Hello', 'He', 'E')", query)
    }

    func test_roundFunction_withDoubleExpression_buildsRoundedDoubleExpression() {
        let double = Expression<Double>(value: 3.14159)
        let query = users.select(round(double))
        ExpectExecutionMatches(db, "round(3.14159)", query)
    }

    func test_roundFunction_withDoubleExpressionAndPrecision_buildsRoundedDoubleExpression() {
        let double = Expression<Double>(value: 3.14159)
        let query = users.select(round(double, 2))
        ExpectExecutionMatches(db, "round(3.14159, 2)", query)
    }

    func test_rtrimFunction_withStringExpression_buildsTrimmedStringExpression() {
        let string = Expression<String>(value: "Hello ")
        let query = users.select(rtrim(string))
        ExpectExecutionMatches(db, "rtrim('Hello ')", query)
    }

    func test_rtrimFunction_withStringExpressionAndReplacementCharacters_buildsTrimmedStringExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(rtrim(string, "lo"))
        ExpectExecutionMatches(db, "rtrim('Hello', 'lo')", query)
    }

    func test_substrFunction_withStringExpressionAndStartIndex_buildsSubstringExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(substr(string, 1))
        ExpectExecutionMatches(db, "substr('Hello', 1)", query)
    }

    func test_substrFunction_withStringExpressionPositionAndLength_buildsSubstringExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(substr(string, 1, 2))
        ExpectExecutionMatches(db, "substr('Hello', 1, 2)", query)
    }

    func test_substrFunction_withStringExpressionAndRange_buildsSubstringExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(substr(string, 1..<3))
        ExpectExecutionMatches(db, "substr('Hello', 1, 2)", query)
    }

    func test_trimFunction_withStringExpression_buildsTrimmedStringExpression() {
        let string = Expression<String>(value: " Hello ")
        let query = users.select(trim(string))
        ExpectExecutionMatches(db, "trim(' Hello ')", query)
    }

    func test_trimFunction_withStringExpressionAndReplacementCharacters_buildsTrimmedStringExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(trim(string, "lo"))
        ExpectExecutionMatches(db, "trim('Hello', 'lo')", query)
    }

    func test_upperFunction_withStringExpression_buildsLowerStringExpression() {
        let string = Expression<String>(value: "Hello")
        let query = users.select(upper(string))
        ExpectExecutionMatches(db, "upper('Hello')", query)
    }

    let id = Expression<Int>("id")
    let age = Expression<Int>("age")
    let email = Expression<String>("email")
    let salary = Expression<Double>("salary")
    let admin = Expression<Bool>("admin")

    func test_countFunction_withExpression_buildsCountExpression() {
        ExpectExecutionMatches(db, "count(id)", users.select(count(id)))
        ExpectExecutionMatches(db, "count(email)", users.select(count(email)))
        ExpectExecutionMatches(db, "count(salary)", users.select(count(salary)))
        ExpectExecutionMatches(db, "count(admin)", users.select(count(admin)))
    }

    func test_countFunction_withStar_buildsCountExpression() {
        ExpectExecutionMatches(db, "count(*)", users.select(count(*)))
    }

    func test_maxFunction_withExpression_buildsMaxExpression() {
        ExpectExecutionMatches(db, "max(id)", users.select(max(id)))
        ExpectExecutionMatches(db, "max(email)", users.select(max(email)))
        ExpectExecutionMatches(db, "max(salary)", users.select(max(salary)))
        ExpectExecutionMatches(db, "max(admin)", users.select(max(admin)))
    }

    func test_minFunction_withExpression_buildsMinExpression() {
        ExpectExecutionMatches(db, "min(id)", users.select(min(id)))
        ExpectExecutionMatches(db, "min(email)", users.select(min(email)))
        ExpectExecutionMatches(db, "min(salary)", users.select(min(salary)))
        ExpectExecutionMatches(db, "min(admin)", users.select(min(admin)))
    }

    func test_averageFunction_withExpression_buildsAverageExpression() {
        ExpectExecutionMatches(db, "avg(id)", users.select(average(id)))
        ExpectExecutionMatches(db, "avg(salary)", users.select(average(salary)))
    }

    func test_sumFunction_withExpression_buildsSumExpression() {
        ExpectExecutionMatches(db, "sum(id)", users.select(sum(id)))
        ExpectExecutionMatches(db, "sum(salary)", users.select(sum(salary)))
    }

    func test_totalFunction_withExpression_buildsTotalExpression() {
        ExpectExecutionMatches(db, "total(id)", users.select(total(id)))
        ExpectExecutionMatches(db, "total(salary)", users.select(total(salary)))
    }

    func test_containsFunction_withValueExpressionAndValueArray_buildsInExpression() {
        ExpectExecutionMatches(db, "id IN (1, 2, 3)", users.select(contains([1, 2, 3], id)))
    }

    func test_plusEquals_withStringExpression_buildsSetter() {
        let SQL = "UPDATE users SET email = email || email"
        ExpectExecution(db, SQL, users.update(email += email))
    }

    func test_plusEquals_withStringValue_buildsSetter() {
        let SQL = "UPDATE users SET email = email || '.com'"
        ExpectExecution(db, SQL, users.update(email += ".com"))
    }

    func test_plusEquals_withNumberExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age + age", users.update(age += age))
        ExpectExecution(db, "UPDATE users SET salary = salary + salary", users.update(salary += salary))
    }

    func test_plusEquals_withNumberValue_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age + 1", users.update(age += 1))
        ExpectExecution(db, "UPDATE users SET salary = salary + 100.0", users.update(salary += 100))
    }

    func test_minusEquals_withNumberExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age - age", users.update(age -= age))
        ExpectExecution(db, "UPDATE users SET salary = salary - salary", users.update(salary -= salary))
    }

    func test_minusEquals_withNumberValue_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age - 1", users.update(age -= 1))
        ExpectExecution(db, "UPDATE users SET salary = salary - 100.0", users.update(salary -= 100))
    }

    func test_timesEquals_withNumberExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age * age", users.update(age *= age))
        ExpectExecution(db, "UPDATE users SET salary = salary * salary", users.update(salary *= salary))
    }

    func test_timesEquals_withNumberValue_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age * 1", users.update(age *= 1))
        ExpectExecution(db, "UPDATE users SET salary = salary * 100.0", users.update(salary *= 100))
    }

    func test_divideEquals_withNumberExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age / age", users.update(age /= age))
        ExpectExecution(db, "UPDATE users SET salary = salary / salary", users.update(salary /= salary))
    }

    func test_divideEquals_withNumberValue_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age / 1", users.update(age /= 1))
        ExpectExecution(db, "UPDATE users SET salary = salary / 100.0", users.update(salary /= 100))
    }

    func test_moduloEquals_withIntegerExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age % age", users.update(age %= age))
    }

    func test_moduloEquals_withIntegerValue_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age % 10", users.update(age %= 10))
    }

    func test_rightShiftEquals_withIntegerExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age >> age", users.update(age >>= age))
    }

    func test_rightShiftEquals_withIntegerValue_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age >> 1", users.update(age >>= 1))
    }

    func test_leftShiftEquals_withIntegerExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age << age", users.update(age <<= age))
    }

    func test_leftShiftEquals_withIntegerValue_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age << 1", users.update(age <<= 1))
    }

    func test_bitwiseAndEquals_withIntegerExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age & age", users.update(age &= age))
    }

    func test_bitwiseAndEquals_withIntegerValue_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age & 1", users.update(age &= 1))
    }

    func test_bitwiseOrEquals_withIntegerExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age | age", users.update(age |= age))
    }

    func test_bitwiseOrEquals_withIntegerValue_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age | 1", users.update(age |= 1))
    }

    func test_postfixPlus_withIntegerValue_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age + 1", users.update(age++))
    }

    func test_postfixMinus_withIntegerValue_buildsSetter() {
        ExpectExecution(db, "UPDATE users SET age = age - 1", users.update(age--))
    }

}

func ExpectExecutionMatches(db: Database, SQL: String, query: Query) {
    ExpectExecution(db, "SELECT \(SQL) FROM users", query)
}

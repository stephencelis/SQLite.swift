import XCTest
import SQLite

class ExpressionTests: XCTestCase {

    let db = Database()
    var users: Query { return db["users"] }

    func ExpectExecutionMatches(SQL: String, _ expression: Expressible) {
        ExpectExecution(db, "SELECT \(SQL) FROM \"users\"", users.select(expression))
    }

    let stringA = Expression<String>(value: "A")
    let stringB = Expression<String?>(value: "B")

    let int1 = Expression<Int>(value: 1)
    let int2 = Expression<Int?>(value: 2)

    let double1 = Expression<Double>(value: 1.5)
    let double2 = Expression<Double?>(value: 2.5)

    let bool0 = Expression<Bool>(value: false)
    let bool1 = Expression<Bool?>(value: true)

    override func setUp() {
        super.setUp()

        CreateUsersTable(db)
    }

    func test_stringExpressionPlusStringExpression_buildsConcatenatingStringExpression() {
        ExpectExecutionMatches("('A' || 'A')", stringA + stringA)
        ExpectExecutionMatches("('A' || 'B')", stringA + stringB)
        ExpectExecutionMatches("('B' || 'A')", stringB + stringA)
        ExpectExecutionMatches("('B' || 'B')", stringB + stringB)
        ExpectExecutionMatches("('A' || 'B')", stringA + "B")
        ExpectExecutionMatches("('B' || 'A')", stringB + "A")
        ExpectExecutionMatches("('B' || 'A')", "B" + stringA)
        ExpectExecutionMatches("('A' || 'B')", "A" + stringB)
    }

    func test_integerExpression_plusIntegerExpression_buildsAdditiveIntegerExpression() {
        ExpectExecutionMatches("(1 + 1)", int1 + int1)
        ExpectExecutionMatches("(1 + 2)", int1 + int2)
        ExpectExecutionMatches("(2 + 1)", int2 + int1)
        ExpectExecutionMatches("(2 + 2)", int2 + int2)
        ExpectExecutionMatches("(1 + 2)", int1 + 2)
        ExpectExecutionMatches("(2 + 1)", int2 + 1)
        ExpectExecutionMatches("(2 + 1)", 2 + int1)
        ExpectExecutionMatches("(1 + 2)", 1 + int2)
    }

    func test_doubleExpression_plusDoubleExpression_buildsAdditiveDoubleExpression() {
        ExpectExecutionMatches("(1.5 + 1.5)", double1 + double1)
        ExpectExecutionMatches("(1.5 + 2.5)", double1 + double2)
        ExpectExecutionMatches("(2.5 + 1.5)", double2 + double1)
        ExpectExecutionMatches("(2.5 + 2.5)", double2 + double2)
        ExpectExecutionMatches("(1.5 + 2.5)", double1 + 2.5)
        ExpectExecutionMatches("(2.5 + 1.5)", double2 + 1.5)
        ExpectExecutionMatches("(2.5 + 1.5)", 2.5 + double1)
        ExpectExecutionMatches("(1.5 + 2.5)", 1.5 + double2)
    }

    func test_integerExpression_minusIntegerExpression_buildsSubtractiveIntegerExpression() {
        ExpectExecutionMatches("(1 - 1)", int1 - int1)
        ExpectExecutionMatches("(1 - 2)", int1 - int2)
        ExpectExecutionMatches("(2 - 1)", int2 - int1)
        ExpectExecutionMatches("(2 - 2)", int2 - int2)
        ExpectExecutionMatches("(1 - 2)", int1 - 2)
        ExpectExecutionMatches("(2 - 1)", int2 - 1)
        ExpectExecutionMatches("(2 - 1)", 2 - int1)
        ExpectExecutionMatches("(1 - 2)", 1 - int2)
    }

    func test_doubleExpression_minusDoubleExpression_buildsSubtractiveDoubleExpression() {
        ExpectExecutionMatches("(1.5 - 1.5)", double1 - double1)
        ExpectExecutionMatches("(1.5 - 2.5)", double1 - double2)
        ExpectExecutionMatches("(2.5 - 1.5)", double2 - double1)
        ExpectExecutionMatches("(2.5 - 2.5)", double2 - double2)
        ExpectExecutionMatches("(1.5 - 2.5)", double1 - 2.5)
        ExpectExecutionMatches("(2.5 - 1.5)", double2 - 1.5)
        ExpectExecutionMatches("(2.5 - 1.5)", 2.5 - double1)
        ExpectExecutionMatches("(1.5 - 2.5)", 1.5 - double2)
    }

    func test_integerExpression_timesIntegerExpression_buildsMultiplicativeIntegerExpression() {
        ExpectExecutionMatches("(1 * 1)", int1 * int1)
        ExpectExecutionMatches("(1 * 2)", int1 * int2)
        ExpectExecutionMatches("(2 * 1)", int2 * int1)
        ExpectExecutionMatches("(2 * 2)", int2 * int2)
        ExpectExecutionMatches("(1 * 2)", int1 * 2)
        ExpectExecutionMatches("(2 * 1)", int2 * 1)
        ExpectExecutionMatches("(2 * 1)", 2 * int1)
        ExpectExecutionMatches("(1 * 2)", 1 * int2)
    }

    func test_doubleExpression_timesDoubleExpression_buildsMultiplicativeDoubleExpression() {
        ExpectExecutionMatches("(1.5 * 1.5)", double1 * double1)
        ExpectExecutionMatches("(1.5 * 2.5)", double1 * double2)
        ExpectExecutionMatches("(2.5 * 1.5)", double2 * double1)
        ExpectExecutionMatches("(2.5 * 2.5)", double2 * double2)
        ExpectExecutionMatches("(1.5 * 2.5)", double1 * 2.5)
        ExpectExecutionMatches("(2.5 * 1.5)", double2 * 1.5)
        ExpectExecutionMatches("(2.5 * 1.5)", 2.5 * double1)
        ExpectExecutionMatches("(1.5 * 2.5)", 1.5 * double2)
    }

    func test_integerExpression_dividedByIntegerExpression_buildsDivisiveIntegerExpression() {
        ExpectExecutionMatches("(1 / 1)", int1 / int1)
        ExpectExecutionMatches("(1 / 2)", int1 / int2)
        ExpectExecutionMatches("(2 / 1)", int2 / int1)
        ExpectExecutionMatches("(2 / 2)", int2 / int2)
        ExpectExecutionMatches("(1 / 2)", int1 / 2)
        ExpectExecutionMatches("(2 / 1)", int2 / 1)
        ExpectExecutionMatches("(2 / 1)", 2 / int1)
        ExpectExecutionMatches("(1 / 2)", 1 / int2)
    }

    func test_doubleExpression_dividedByDoubleExpression_buildsDivisiveDoubleExpression() {
        ExpectExecutionMatches("(1.5 / 1.5)", double1 / double1)
        ExpectExecutionMatches("(1.5 / 2.5)", double1 / double2)
        ExpectExecutionMatches("(2.5 / 1.5)", double2 / double1)
        ExpectExecutionMatches("(2.5 / 2.5)", double2 / double2)
        ExpectExecutionMatches("(1.5 / 2.5)", double1 / 2.5)
        ExpectExecutionMatches("(2.5 / 1.5)", double2 / 1.5)
        ExpectExecutionMatches("(2.5 / 1.5)", 2.5 / double1)
        ExpectExecutionMatches("(1.5 / 2.5)", 1.5 / double2)
    }

    func test_integerExpression_moduloIntegerExpression_buildsModuloIntegerExpression() {
        ExpectExecutionMatches("(1 % 1)", int1 % int1)
        ExpectExecutionMatches("(1 % 2)", int1 % int2)
        ExpectExecutionMatches("(2 % 1)", int2 % int1)
        ExpectExecutionMatches("(2 % 2)", int2 % int2)
        ExpectExecutionMatches("(1 % 2)", int1 % 2)
        ExpectExecutionMatches("(2 % 1)", int2 % 1)
        ExpectExecutionMatches("(2 % 1)", 2 % int1)
        ExpectExecutionMatches("(1 % 2)", 1 % int2)
    }

    func test_integerExpression_bitShiftLeftIntegerExpression_buildsLeftShiftedIntegerExpression() {
        ExpectExecutionMatches("(1 << 1)", int1 << int1)
        ExpectExecutionMatches("(1 << 2)", int1 << int2)
        ExpectExecutionMatches("(2 << 1)", int2 << int1)
        ExpectExecutionMatches("(2 << 2)", int2 << int2)
        ExpectExecutionMatches("(1 << 2)", int1 << 2)
        ExpectExecutionMatches("(2 << 1)", int2 << 1)
        ExpectExecutionMatches("(2 << 1)", 2 << int1)
        ExpectExecutionMatches("(1 << 2)", 1 << int2)
    }

    func test_integerExpression_bitShiftRightIntegerExpression_buildsRightShiftedIntegerExpression() {
        ExpectExecutionMatches("(1 >> 1)", int1 >> int1)
        ExpectExecutionMatches("(1 >> 2)", int1 >> int2)
        ExpectExecutionMatches("(2 >> 1)", int2 >> int1)
        ExpectExecutionMatches("(2 >> 2)", int2 >> int2)
        ExpectExecutionMatches("(1 >> 2)", int1 >> 2)
        ExpectExecutionMatches("(2 >> 1)", int2 >> 1)
        ExpectExecutionMatches("(2 >> 1)", 2 >> int1)
        ExpectExecutionMatches("(1 >> 2)", 1 >> int2)
    }

    func test_integerExpression_bitwiseAndIntegerExpression_buildsAndedIntegerExpression() {
        ExpectExecutionMatches("(1 & 1)", int1 & int1)
        ExpectExecutionMatches("(1 & 2)", int1 & int2)
        ExpectExecutionMatches("(2 & 1)", int2 & int1)
        ExpectExecutionMatches("(2 & 2)", int2 & int2)
        ExpectExecutionMatches("(1 & 2)", int1 & 2)
        ExpectExecutionMatches("(2 & 1)", int2 & 1)
        ExpectExecutionMatches("(2 & 1)", 2 & int1)
        ExpectExecutionMatches("(1 & 2)", 1 & int2)
    }

    func test_integerExpression_bitwiseOrIntegerExpression_buildsOredIntegerExpression() {
        ExpectExecutionMatches("(1 | 1)", int1 | int1)
        ExpectExecutionMatches("(1 | 2)", int1 | int2)
        ExpectExecutionMatches("(2 | 1)", int2 | int1)
        ExpectExecutionMatches("(2 | 2)", int2 | int2)
        ExpectExecutionMatches("(1 | 2)", int1 | 2)
        ExpectExecutionMatches("(2 | 1)", int2 | 1)
        ExpectExecutionMatches("(2 | 1)", 2 | int1)
        ExpectExecutionMatches("(1 | 2)", 1 | int2)
    }

    func test_integerExpression_bitwiseExclusiveOrIntegerExpression_buildsOredIntegerExpression() {
        ExpectExecutionMatches("(~((1 & 1)) & (1 | 1))", int1 ^ int1)
        ExpectExecutionMatches("(~((1 & 2)) & (1 | 2))", int1 ^ int2)
        ExpectExecutionMatches("(~((2 & 1)) & (2 | 1))", int2 ^ int1)
        ExpectExecutionMatches("(~((2 & 2)) & (2 | 2))", int2 ^ int2)
        ExpectExecutionMatches("(~((1 & 2)) & (1 | 2))", int1 ^ 2)
        ExpectExecutionMatches("(~((2 & 1)) & (2 | 1))", int2 ^ 1)
        ExpectExecutionMatches("(~((2 & 1)) & (2 | 1))", 2 ^ int1)
        ExpectExecutionMatches("(~((1 & 2)) & (1 | 2))", 1 ^ int2)
    }

    func test_bitwiseNot_integerExpression_buildsComplementIntegerExpression() {
        ExpectExecutionMatches("~(1)", ~int1)
        ExpectExecutionMatches("~(2)", ~int2)
    }

    func test_equalityOperator_withEquatableExpressions_buildsBooleanExpression() {
        ExpectExecutionMatches("(0 = 0)", bool0 == bool0)
        ExpectExecutionMatches("(0 = 1)", bool0 == bool1)
        ExpectExecutionMatches("(1 = 0)", bool1 == bool0)
        ExpectExecutionMatches("(1 = 1)", bool1 == bool1)
        ExpectExecutionMatches("(0 = 1)", bool0 == true)
        ExpectExecutionMatches("(1 = 0)", bool1 == false)
        ExpectExecutionMatches("(1 = 0)", true == bool0)
        ExpectExecutionMatches("(0 = 1)", false == bool1)
    }

    func test_inequalityOperator_withEquatableExpressions_buildsBooleanExpression() {
        ExpectExecutionMatches("(0 != 0)", bool0 != bool0)
        ExpectExecutionMatches("(0 != 1)", bool0 != bool1)
        ExpectExecutionMatches("(1 != 0)", bool1 != bool0)
        ExpectExecutionMatches("(1 != 1)", bool1 != bool1)
        ExpectExecutionMatches("(0 != 1)", bool0 != true)
        ExpectExecutionMatches("(1 != 0)", bool1 != false)
        ExpectExecutionMatches("(1 != 0)", true != bool0)
        ExpectExecutionMatches("(0 != 1)", false != bool1)
    }

    func test_greaterThanOperator_withComparableExpressions_buildsBooleanExpression() {
        ExpectExecutionMatches("(1 > 1)", int1 > int1)
        ExpectExecutionMatches("(1 > 2)", int1 > int2)
        ExpectExecutionMatches("(2 > 1)", int2 > int1)
        ExpectExecutionMatches("(2 > 2)", int2 > int2)
        ExpectExecutionMatches("(1 > 2)", int1 > 2)
        ExpectExecutionMatches("(2 > 1)", int2 > 1)
        ExpectExecutionMatches("(2 > 1)", 2 > int1)
        ExpectExecutionMatches("(1 > 2)", 1 > int2)
    }

    func test_greaterThanOrEqualToOperator_withComparableExpressions_buildsBooleanExpression() {
        ExpectExecutionMatches("(1 >= 1)", int1 >= int1)
        ExpectExecutionMatches("(1 >= 2)", int1 >= int2)
        ExpectExecutionMatches("(2 >= 1)", int2 >= int1)
        ExpectExecutionMatches("(2 >= 2)", int2 >= int2)
        ExpectExecutionMatches("(1 >= 2)", int1 >= 2)
        ExpectExecutionMatches("(2 >= 1)", int2 >= 1)
        ExpectExecutionMatches("(2 >= 1)", 2 >= int1)
        ExpectExecutionMatches("(1 >= 2)", 1 >= int2)
    }

    func test_lessThanOperator_withComparableExpressions_buildsBooleanExpression() {
        ExpectExecutionMatches("(1 < 1)", int1 < int1)
        ExpectExecutionMatches("(1 < 2)", int1 < int2)
        ExpectExecutionMatches("(2 < 1)", int2 < int1)
        ExpectExecutionMatches("(2 < 2)", int2 < int2)
        ExpectExecutionMatches("(1 < 2)", int1 < 2)
        ExpectExecutionMatches("(2 < 1)", int2 < 1)
        ExpectExecutionMatches("(2 < 1)", 2 < int1)
        ExpectExecutionMatches("(1 < 2)", 1 < int2)
    }

    func test_lessThanOrEqualToOperator_withComparableExpressions_buildsBooleanExpression() {
        ExpectExecutionMatches("(1 <= 1)", int1 <= int1)
        ExpectExecutionMatches("(1 <= 2)", int1 <= int2)
        ExpectExecutionMatches("(2 <= 1)", int2 <= int1)
        ExpectExecutionMatches("(2 <= 2)", int2 <= int2)
        ExpectExecutionMatches("(1 <= 2)", int1 <= 2)
        ExpectExecutionMatches("(2 <= 1)", int2 <= 1)
        ExpectExecutionMatches("(2 <= 1)", 2 <= int1)
        ExpectExecutionMatches("(1 <= 2)", 1 <= int2)
    }

    func test_unaryMinusOperator_withIntegerExpression_buildsNegativeIntegerExpression() {
        ExpectExecutionMatches("-(1)", -int1)
        ExpectExecutionMatches("-(2)", -int2)
    }

    func test_unaryMinusOperator_withDoubleExpression_buildsNegativeDoubleExpression() {
        ExpectExecutionMatches("-(1.5)", -double1)
        ExpectExecutionMatches("-(2.5)", -double2)
    }

    func test_betweenOperator_withComparableExpression_buildsBetweenBooleanExpression() {
        ExpectExecutionMatches("1 BETWEEN 0 AND 5", 0...5 ~= int1)
        ExpectExecutionMatches("2 BETWEEN 0 AND 5", 0...5 ~= int2)
    }

    func test_likeOperator_withStringExpression_buildsLikeExpression() {
        ExpectExecutionMatches("('A' LIKE 'B%')", like("B%", stringA))
        ExpectExecutionMatches("('B' LIKE 'A%')", like("A%", stringB))
    }

    func test_globOperator_withStringExpression_buildsGlobExpression() {
        ExpectExecutionMatches("('A' GLOB 'B*')", glob("B*", stringA))
        ExpectExecutionMatches("('B' GLOB 'A*')", glob("A*", stringB))
    }

    func test_matchOperator_withStringExpression_buildsMatchExpression() {
        ExpectExecutionMatches("('A' MATCH 'B')", match("B", stringA))
        ExpectExecutionMatches("('B' MATCH 'A')", match("A", stringB))
    }

    func test_collateOperator_withStringExpression_buildsCollationExpression() {
        ExpectExecutionMatches("('A' COLLATE BINARY)", collate(.Binary, stringA))
        ExpectExecutionMatches("('B' COLLATE NOCASE)", collate(.NoCase, stringB))
        ExpectExecutionMatches("('A' COLLATE RTRIM)", collate(.RTrim, stringA))
    }

    func test_doubleAndOperator_withBooleanExpressions_buildsCompoundExpression() {
        ExpectExecutionMatches("(0 AND 0)", bool0 && bool0)
        ExpectExecutionMatches("(0 AND 1)", bool0 && bool1)
        ExpectExecutionMatches("(1 AND 0)", bool1 && bool0)
        ExpectExecutionMatches("(1 AND 1)", bool1 && bool1)
        ExpectExecutionMatches("(0 AND 1)", bool0 && true)
        ExpectExecutionMatches("(1 AND 0)", bool1 && false)
        ExpectExecutionMatches("(1 AND 0)", true && bool0)
        ExpectExecutionMatches("(0 AND 1)", false && bool1)
    }

    func test_doubleOrOperator_withBooleanExpressions_buildsCompoundExpression() {
        ExpectExecutionMatches("(0 OR 0)", bool0 || bool0)
        ExpectExecutionMatches("(0 OR 1)", bool0 || bool1)
        ExpectExecutionMatches("(1 OR 0)", bool1 || bool0)
        ExpectExecutionMatches("(1 OR 1)", bool1 || bool1)
        ExpectExecutionMatches("(0 OR 1)", bool0 || true)
        ExpectExecutionMatches("(1 OR 0)", bool1 || false)
        ExpectExecutionMatches("(1 OR 0)", true || bool0)
        ExpectExecutionMatches("(0 OR 1)", false || bool1)
    }

    func test_unaryNotOperator_withBooleanExpressions_buildsNotExpression() {
        ExpectExecutionMatches("NOT (0)", !bool0)
        ExpectExecutionMatches("NOT (1)", !bool1)
    }

    func test_absFunction_withNumberExpressions_buildsAbsExpression() {
        let int1 = Expression<Int>(value: -1)
        let int2 = Expression<Int?>(value: -2)

        ExpectExecutionMatches("abs(-1)", abs(int1))
        ExpectExecutionMatches("abs(-2)", abs(int2))
    }

    func test_coalesceFunction_withValueExpressions_buildsCoalesceExpression() {
        let int1 = Expression<Int?>(value: nil as Int?)
        let int2 = Expression<Int?>(value: nil as Int?)
        let int3 = Expression<Int?>(value: 3)

        ExpectExecutionMatches("coalesce(NULL, NULL, 3)", coalesce(int1, int2, int3))
    }

    func test_ifNullFunction_withValueExpressionAndValue_buildsIfNullExpression() {
        let int1 = Expression<Int?>(value: nil as Int?)
        let int2 = Expression<Int?>(value: 2)
        let int3 = Expression<Int>(value: 3)

        ExpectExecutionMatches("ifnull(NULL, 1)", ifnull(int1, 1))
        ExpectExecutionMatches("ifnull(NULL, 1)", int1 ?? 1)
        ExpectExecutionMatches("ifnull(NULL, 2)", ifnull(int1, int2))
        ExpectExecutionMatches("ifnull(NULL, 2)", int1 ?? int2)
        ExpectExecutionMatches("ifnull(NULL, 3)", ifnull(int1, int3))
        ExpectExecutionMatches("ifnull(NULL, 3)", int1 ?? int3)
    }

    func test_lengthFunction_withValueExpression_buildsLengthIntExpression() {
        ExpectExecutionMatches("length('A')", length(stringA))
        ExpectExecutionMatches("length('B')", length(stringB))
    }

    func test_lowerFunction_withStringExpression_buildsLowerStringExpression() {
        ExpectExecutionMatches("lower('A')", lower(stringA))
        ExpectExecutionMatches("lower('B')", lower(stringB))
    }

    func test_ltrimFunction_withStringExpression_buildsTrimmedStringExpression() {
        ExpectExecutionMatches("ltrim('A')", ltrim(stringA))
        ExpectExecutionMatches("ltrim('B')", ltrim(stringB))
    }

    func test_ltrimFunction_withStringExpressionAndReplacementCharacters_buildsTrimmedStringExpression() {
        ExpectExecutionMatches("ltrim('A', 'A?')", ltrim(stringA, "A?"))
        ExpectExecutionMatches("ltrim('B', 'B?')", ltrim(stringB, "B?"))
    }

    func test_randomFunction_buildsRandomIntExpression() {
        ExpectExecutionMatches("random()", random)
    }

    func test_replaceFunction_withStringExpressionAndFindReplaceStrings_buildsReplacedStringExpression() {
        ExpectExecutionMatches("replace('A', 'A', 'B')", replace(stringA, "A", "B"))
        ExpectExecutionMatches("replace('B', 'B', 'A')", replace(stringB, "B", "A"))
    }

    func test_roundFunction_withDoubleExpression_buildsRoundedDoubleExpression() {
        ExpectExecutionMatches("round(1.5)", round(double1))
        ExpectExecutionMatches("round(2.5)", round(double2))
    }

    func test_roundFunction_withDoubleExpressionAndPrecision_buildsRoundedDoubleExpression() {
        ExpectExecutionMatches("round(1.5, 1)", round(double1, 1))
        ExpectExecutionMatches("round(2.5, 1)", round(double2, 1))
    }

    func test_rtrimFunction_withStringExpression_buildsTrimmedStringExpression() {
        ExpectExecutionMatches("rtrim('A')", rtrim(stringA))
        ExpectExecutionMatches("rtrim('B')", rtrim(stringB))
    }

    func test_rtrimFunction_withStringExpressionAndReplacementCharacters_buildsTrimmedStringExpression() {
        ExpectExecutionMatches("rtrim('A', 'A?')", rtrim(stringA, "A?"))
        ExpectExecutionMatches("rtrim('B', 'B?')", rtrim(stringB, "B?"))
    }

    func test_substrFunction_withStringExpressionAndStartIndex_buildsSubstringExpression() {
        ExpectExecutionMatches("substr('A', 1)", substr(stringA, 1))
        ExpectExecutionMatches("substr('B', 1)", substr(stringB, 1))
    }

    func test_substrFunction_withStringExpressionPositionAndLength_buildsSubstringExpression() {
        ExpectExecutionMatches("substr('A', 1, 2)", substr(stringA, 1, 2))
        ExpectExecutionMatches("substr('B', 1, 2)", substr(stringB, 1, 2))
    }

    func test_substrFunction_withStringExpressionAndRange_buildsSubstringExpression() {
        ExpectExecutionMatches("substr('A', 1, 2)", substr(stringA, 1..<3))
        ExpectExecutionMatches("substr('B', 1, 2)", substr(stringB, 1..<3))
    }

    func test_trimFunction_withStringExpression_buildsTrimmedStringExpression() {
        ExpectExecutionMatches("trim('A')", trim(stringA))
        ExpectExecutionMatches("trim('B')", trim(stringB))
    }

    func test_trimFunction_withStringExpressionAndReplacementCharacters_buildsTrimmedStringExpression() {
        ExpectExecutionMatches("trim('A', 'A?')", trim(stringA, "A?"))
        ExpectExecutionMatches("trim('B', 'B?')", trim(stringB, "B?"))
    }

    func test_upperFunction_withStringExpression_buildsLowerStringExpression() {
        ExpectExecutionMatches("upper('A')", upper(stringA))
        ExpectExecutionMatches("upper('B')", upper(stringB))
    }

    let id = Expression<Int>("id")
    let age = Expression<Int?>("age")
    let email = Expression<String>("email")
    let email2 = Expression<String?>("email")
    let salary = Expression<Double>("salary")
    let salary2 = Expression<Double?>("salary")
    let admin = Expression<Bool>("admin")
    let admin2 = Expression<Bool?>("admin")

    func test_countFunction_withExpression_buildsCountExpression() {
        ExpectExecutionMatches("count(\"id\")", count(id))
        ExpectExecutionMatches("count(\"age\")", count(age))
        ExpectExecutionMatches("count(\"email\")", count(email))
        ExpectExecutionMatches("count(\"email\")", count(email2))
        ExpectExecutionMatches("count(\"salary\")", count(salary))
        ExpectExecutionMatches("count(\"salary\")", count(salary2))
        ExpectExecutionMatches("count(\"admin\")", count(admin))
        ExpectExecutionMatches("count(\"admin\")", count(admin2))
        ExpectExecutionMatches("count(DISTINCT \"id\")", count(distinct: id))
        ExpectExecutionMatches("count(DISTINCT \"age\")", count(distinct: age))
        ExpectExecutionMatches("count(DISTINCT \"email\")", count(distinct: email))
        ExpectExecutionMatches("count(DISTINCT \"email\")", count(distinct: email2))
        ExpectExecutionMatches("count(DISTINCT \"salary\")", count(distinct: salary))
        ExpectExecutionMatches("count(DISTINCT \"salary\")", count(distinct: salary2))
        ExpectExecutionMatches("count(DISTINCT \"admin\")", count(distinct: admin))
        ExpectExecutionMatches("count(DISTINCT \"admin\")", count(distinct: admin2))
    }

    func test_countFunction_withStar_buildsCountExpression() {
        ExpectExecutionMatches("count(*)", count(*))
    }

    func test_maxFunction_withExpression_buildsMaxExpression() {
        ExpectExecutionMatches("max(\"id\")", max(id))
        ExpectExecutionMatches("max(\"age\")", max(age))
        ExpectExecutionMatches("max(\"email\")", max(email))
        ExpectExecutionMatches("max(\"email\")", max(email2))
        ExpectExecutionMatches("max(\"salary\")", max(salary))
        ExpectExecutionMatches("max(\"salary\")", max(salary2))
    }

    func test_minFunction_withExpression_buildsMinExpression() {
        ExpectExecutionMatches("min(\"id\")", min(id))
        ExpectExecutionMatches("min(\"age\")", min(age))
        ExpectExecutionMatches("min(\"email\")", min(email))
        ExpectExecutionMatches("min(\"email\")", min(email2))
        ExpectExecutionMatches("min(\"salary\")", min(salary))
        ExpectExecutionMatches("min(\"salary\")", min(salary2))
    }

    func test_averageFunction_withExpression_buildsAverageExpression() {
        ExpectExecutionMatches("avg(\"id\")", average(id))
        ExpectExecutionMatches("avg(\"age\")", average(age))
        ExpectExecutionMatches("avg(\"salary\")", average(salary))
        ExpectExecutionMatches("avg(\"salary\")", average(salary2))
        ExpectExecutionMatches("avg(DISTINCT \"id\")", average(distinct: id))
        ExpectExecutionMatches("avg(DISTINCT \"age\")", average(distinct: age))
        ExpectExecutionMatches("avg(DISTINCT \"salary\")", average(distinct: salary))
        ExpectExecutionMatches("avg(DISTINCT \"salary\")", average(distinct: salary2))
    }

    func test_sumFunction_withExpression_buildsSumExpression() {
        ExpectExecutionMatches("sum(\"id\")", sum(id))
        ExpectExecutionMatches("sum(\"age\")", sum(age))
        ExpectExecutionMatches("sum(\"salary\")", sum(salary))
        ExpectExecutionMatches("sum(\"salary\")", sum(salary2))
        ExpectExecutionMatches("sum(DISTINCT \"id\")", sum(distinct: id))
        ExpectExecutionMatches("sum(DISTINCT \"age\")", sum(distinct: age))
        ExpectExecutionMatches("sum(DISTINCT \"salary\")", sum(distinct: salary))
        ExpectExecutionMatches("sum(DISTINCT \"salary\")", sum(distinct: salary2))
    }

    func test_totalFunction_withExpression_buildsTotalExpression() {
        ExpectExecutionMatches("total(\"id\")", total(id))
        ExpectExecutionMatches("total(\"age\")", total(age))
        ExpectExecutionMatches("total(\"salary\")", total(salary))
        ExpectExecutionMatches("total(\"salary\")", total(salary2))
        ExpectExecutionMatches("total(DISTINCT \"id\")", total(distinct: id))
        ExpectExecutionMatches("total(DISTINCT \"age\")", total(distinct: age))
        ExpectExecutionMatches("total(DISTINCT \"salary\")", total(distinct: salary))
        ExpectExecutionMatches("total(DISTINCT \"salary\")", total(distinct: salary2))
    }

    func test_containsFunction_withValueExpressionAndValueArray_buildsInExpression() {
        ExpectExecutionMatches("(\"id\" IN (1, 2, 3))", contains([1, 2, 3], id))
        ExpectExecutionMatches("(\"age\" IN (20, 30, 40))", contains([20, 30, 40], age))
    }

    func test_plusEquals_withStringExpression_buildsSetter() {
        let SQL = "UPDATE \"users\" SET \"email\" = (\"email\" || \"email\")"
        ExpectExecution(db, SQL, users.update(email += email))
        ExpectExecution(db, SQL, users.update(email += email2))
        ExpectExecution(db, SQL, users.update(email2 += email))
        ExpectExecution(db, SQL, users.update(email2 += email2))
    }

    func test_plusEquals_withStringValue_buildsSetter() {
        let SQL = "UPDATE \"users\" SET \"email\" = (\"email\" || '.com')"
        ExpectExecution(db, SQL, users.update(email += ".com"))
        ExpectExecution(db, SQL, users.update(email2 += ".com"))
    }

    func test_plusEquals_withNumberExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" + \"age\")", users.update(age += age))
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" + \"id\")", users.update(age += id))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" + \"age\")", users.update(id += age))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" + \"id\")", users.update(id += id))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" + \"salary\")", users.update(salary += salary))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" + \"salary\")", users.update(salary += salary2))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" + \"salary\")", users.update(salary2 += salary))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" + \"salary\")", users.update(salary2 += salary2))
    }

    func test_plusEquals_withNumberValue_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" + 1)", users.update(id += 1))
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" + 1)", users.update(age += 1))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" + 100.0)", users.update(salary += 100))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" + 100.0)", users.update(salary2 += 100))
    }

    func test_minusEquals_withNumberExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" - \"age\")", users.update(age -= age))
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" - \"id\")", users.update(age -= id))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" - \"age\")", users.update(id -= age))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" - \"id\")", users.update(id -= id))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" - \"salary\")", users.update(salary -= salary))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" - \"salary\")", users.update(salary -= salary2))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" - \"salary\")", users.update(salary2 -= salary))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" - \"salary\")", users.update(salary2 -= salary2))
    }

    func test_minusEquals_withNumberValue_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" - 1)", users.update(id -= 1))
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" - 1)", users.update(age -= 1))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" - 100.0)", users.update(salary -= 100))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" - 100.0)", users.update(salary2 -= 100))
    }

    func test_timesEquals_withNumberExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" * \"age\")", users.update(age *= age))
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" * \"id\")", users.update(age *= id))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" * \"age\")", users.update(id *= age))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" * \"id\")", users.update(id *= id))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" * \"salary\")", users.update(salary *= salary))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" * \"salary\")", users.update(salary *= salary2))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" * \"salary\")", users.update(salary2 *= salary))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" * \"salary\")", users.update(salary2 *= salary2))
    }

    func test_timesEquals_withNumberValue_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" * 1)", users.update(id *= 1))
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" * 1)", users.update(age *= 1))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" * 100.0)", users.update(salary *= 100))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" * 100.0)", users.update(salary2 *= 100))
    }

    func test_divideEquals_withNumberExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" / \"age\")", users.update(age /= age))
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" / \"id\")", users.update(age /= id))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" / \"age\")", users.update(id /= age))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" / \"id\")", users.update(id /= id))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" / \"salary\")", users.update(salary /= salary))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" / \"salary\")", users.update(salary /= salary2))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" / \"salary\")", users.update(salary2 /= salary))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" / \"salary\")", users.update(salary2 /= salary2))
    }

    func test_divideEquals_withNumberValue_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" / 1)", users.update(id /= 1))
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" / 1)", users.update(age /= 1))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" / 100.0)", users.update(salary /= 100))
        ExpectExecution(db, "UPDATE \"users\" SET \"salary\" = (\"salary\" / 100.0)", users.update(salary2 /= 100))
    }

    func test_moduloEquals_withIntegerExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" % \"age\")", users.update(age %= age))
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" % \"id\")", users.update(age %= id))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" % \"age\")", users.update(id %= age))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" % \"id\")", users.update(id %= id))
    }

    func test_moduloEquals_withIntegerValue_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" % 10)", users.update(age %= 10))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" % 10)", users.update(id %= 10))
    }

    func test_rightShiftEquals_withIntegerExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" >> \"age\")", users.update(age >>= age))
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" >> \"id\")", users.update(age >>= id))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" >> \"age\")", users.update(id >>= age))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" >> \"id\")", users.update(id >>= id))
    }

    func test_rightShiftEquals_withIntegerValue_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" >> 1)", users.update(age >>= 1))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" >> 1)", users.update(id >>= 1))
    }

    func test_leftShiftEquals_withIntegerExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" << \"age\")", users.update(age <<= age))
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" << \"id\")", users.update(age <<= id))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" << \"age\")", users.update(id <<= age))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" << \"id\")", users.update(id <<= id))
    }

    func test_leftShiftEquals_withIntegerValue_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" << 1)", users.update(age <<= 1))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" << 1)", users.update(id <<= 1))
    }

    func test_bitwiseAndEquals_withIntegerExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" & \"age\")", users.update(age &= age))
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" & \"id\")", users.update(age &= id))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" & \"age\")", users.update(id &= age))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" & \"id\")", users.update(id &= id))
    }

    func test_bitwiseAndEquals_withIntegerValue_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" & 1)", users.update(age &= 1))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" & 1)", users.update(id &= 1))
    }

    func test_bitwiseOrEquals_withIntegerExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" | \"age\")", users.update(age |= age))
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" | \"id\")", users.update(age |= id))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" | \"age\")", users.update(id |= age))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" | \"id\")", users.update(id |= id))
    }

    func test_bitwiseOrEquals_withIntegerValue_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" | 1)", users.update(age |= 1))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" | 1)", users.update(id |= 1))
    }

    func test_bitwiseExclusiveOrEquals_withIntegerExpression_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (~((\"age\" & \"age\")) & (\"age\" | \"age\"))", users.update(age ^= age))
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (~((\"age\" & \"id\")) & (\"age\" | \"id\"))", users.update(age ^= id))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (~((\"id\" & \"age\")) & (\"id\" | \"age\"))", users.update(id ^= age))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (~((\"id\" & \"id\")) & (\"id\" | \"id\"))", users.update(id ^= id))
    }

    func test_bitwiseExclusiveOrEquals_withIntegerValue_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (~((\"age\" & 1)) & (\"age\" | 1))", users.update(age ^= 1))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (~((\"id\" & 1)) & (\"id\" | 1))", users.update(id ^= 1))
    }

    func test_postfixPlus_withIntegerValue_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" + 1)", users.update(age++))
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" + 1)", users.update(age++))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" + 1)", users.update(id++))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" + 1)", users.update(id++))
    }

    func test_postfixMinus_withIntegerValue_buildsSetter() {
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" - 1)", users.update(age--))
        ExpectExecution(db, "UPDATE \"users\" SET \"age\" = (\"age\" - 1)", users.update(age--))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" - 1)", users.update(id--))
        ExpectExecution(db, "UPDATE \"users\" SET \"id\" = (\"id\" - 1)", users.update(id--))
    }

    func test_precedencePreserved() {
        let n = Expression<Int>(value: 1)
        ExpectExecutionMatches("(((1 = 1) AND (1 = 1)) OR (1 = 1))", (n == n && n == n) || n == n)
        ExpectExecutionMatches("((1 = 1) AND ((1 = 1) OR (1 = 1)))", n == n && (n == n || n == n))
    }

}

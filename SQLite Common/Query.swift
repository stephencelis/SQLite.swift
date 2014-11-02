//
// SQLite.Query
// Copyright (c) 2014 Stephen Celis.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

/// A dictionary mapping column names to values.
public typealias Values = [String: Value?]

/// A query object. Used to build SQL statements with a collection of chainable
/// helper functions.
public struct Query {

    internal var database: Database

    internal init(_ database: Database, _ tableName: String) {
        self.database = database
        self.tableName = tableName
    }

    // MARK: - Keywords

    /// Determines the join operator for a query’s JOIN clause.
    public enum JoinType: String {

        /// A CROSS JOIN.
        case Cross = "CROSS"

        /// An INNER JOIN.
        case Inner = "INNER"

        /// A LEFT OUTER JOIN.
        case LeftOuter = "LEFT OUTER"

    }

    private var columns: Expressible = Expression<()>("*")
    internal var tableName: String
    private var alias: String?
    private var joins = [Expressible]()
    private var filter: Expression<Bool>?
    private var group: Expressible?
    private var order = [Expressible]()
    private var limit: (to: Int, offset: Int?)? = nil

    public func alias(alias: String?) -> Query {
        var query = self
        query.alias = alias
        return query
    }

    /// Sets the SELECT clause on the query.
    ///
    /// :param: all A list of expressions to select.
    ///
    /// :returns: A query with the given SELECT clause applied.
    public func select(all: Expressible...) -> Query {
        var query = self
        query.columns = SQLite.join(", ", all)
        return query
    }

    /// Sets the SELECT DISTINCT clause on the query.
    ///
    /// :param: columns A list of expressions to select.
    ///
    /// :returns: A query with the given SELECT DISTINCT clause applied.
    public func select(distinct columns: Expressible...) -> Query {
        var query = self
        query.columns = SQLite.join(" ", [Expression<()>("DISTINCT"), SQLite.join(", ", columns)])
        return query
    }

    // rdar://18778670 causes select(distinct: *) to make select(*) ambiguous
    /// Sets the SELECT clause on the query.
    ///
    /// :param: star A literal *.
    ///
    /// :returns: A query with SELECT * applied.
    public func select(all star: Star) -> Query {
        return select(star(nil, nil))
    }

    /// Sets the SELECT clause on the query.
    ///
    /// :param: star A literal *.
    ///
    /// :returns: A query with SELECT * applied.
    public func select(distinct star: Star) -> Query {
        return select(distinct: star(nil, nil))
    }

    /// Adds an INNER JOIN clause to the query.
    ///
    /// :param: table A query representing the other table.
    ///
    /// :param: on    A boolean expression describing the join condition.
    ///
    /// :returns: A query with the given INNER JOIN clause applied.
    public func join(table: Query, on: Expression<Bool>) -> Query {
        return join(.Inner, table, on: on)
    }

    /// Adds a JOIN clause to the query.
    ///
    /// :param: type  The JOIN operator.
    ///
    /// :param: table A query representing the other table.
    ///
    /// :param: on    A boolean expression describing the join condition.
    ///
    /// :returns: A query with the given JOIN clause applied.
    public func join(type: JoinType, _ table: Query, on: Expression<Bool>) -> Query {
        var query = self
        let condition = table.filter.map { on && $0 } ?? on
        let expression = Expression<()>("\(type.rawValue) JOIN \(table) ON \(condition.SQL)", condition.bindings)
        query.joins.append(expression)
        return query
    }

    /// Adds a condition the the query’s WHERE clause.
    ///
    /// :param: condition A boolean expression to filter on.
    ///
    /// :returns: A query with the given WHERE clause applied.
    public func filter(condition: Expression<Bool>) -> Query {
        var query = self
        query.filter = filter.map { $0 && condition } ?? condition
        return query
    }

    /// Sets a GROUP BY clause on the query.
    ///
    /// :param: by A list of columns to group by.
    ///
    /// :returns: A query with the given GROUP BY clause applied.
    public func group(by: Expressible...) -> Query {
        return group(by)
    }

    /// Sets a GROUP BY clause (with optional HAVING) on the query.
    ///
    /// :param: by       A column to group by.
    ///
    /// :param: having   A condition determining which groups are returned.
    ///
    /// :returns: A query with the given GROUP BY clause applied.
    public func group(by: Expressible, having: Expression<Bool>) -> Query {
        return group([by], having: having)
    }

    /// Sets a GROUP BY-HAVING clause on the query.
    ///
    /// :param: by       A list of columns to group by.
    ///
    /// :param: having   A condition determining which groups are returned.
    ///
    /// :returns: A query with the given GROUP BY clause applied.
    public func group(by: [Expressible], having: Expression<Bool>? = nil) -> Query {
        var query = self
        var group = SQLite.join(" ", [Expression<()>("GROUP BY"), SQLite.join(", ", by)])
        if let having = having { group = SQLite.join(" ", [group, Expression<()>("HAVING"), having]) }
        query.group = group
        return query
    }

    /// Sets an ORDER BY clause on the query.
    ///
    /// :param: by An ordered list of columns and directions to sort by.
    ///
    /// :returns: A query with the given ORDER BY clause applied.
    public func order(by: Expressible...) -> Query {
        var query = self
        query.order = by
        return query
    }

    /// Sets the LIMIT clause (and resets any OFFSET clause) on the query.
    ///
    /// :param: to The maximum number of rows to return.
    ///
    /// :returns: A query with the given LIMIT clause applied.
    public func limit(to: Int?) -> Query {
        return limit(to: to, offset: nil)
    }

    /// Sets LIMIT and OFFSET clauses on the query.
    ///
    /// :param: to     The maximum number of rows to return.
    ///
    /// :param: offset The number of rows to skip.
    ///
    /// :returns: A query with the given LIMIT and OFFSET clauses applied.
    public func limit(to: Int, offset: Int) -> Query {
        return limit(to: to, offset: offset)
    }

    // prevents limit(nil, offset: 5)
    private func limit(#to: Int?, offset: Int? = nil) -> Query {
        var query = self
        if let to = to {
            query.limit = (to, offset)
        } else {
            query.limit = nil
        }
        return query
    }

    // MARK: - Namespacing

    /// Prefixes a column expression with the query’s table name or alias.
    ///
    /// :param: column A column expression.
    ///
    /// :returns: A column expression namespaced with the query’s table name or
    ///           alias.
    public func namespace<T>(column: Expression<T>) -> Expression<T> {
        return Expression("\(alias ?? tableName).\(column.SQL)", column.bindings)
    }

    // FIXME: rdar://18673897 subscript<T>(expression: Expression<T>) -> Expression<T>

    /// Prefixes a column expression with the query’s table name or alias.
    ///
    /// :param: column A column expression.
    ///
    /// :returns: A column expression namespaced with the query’s table name or
    ///           alias.
    public subscript(column: Expression<Bool>) -> Expression<Bool> {
        return namespace(column)
    }

    /// Prefixes a column expression with the query’s table name or alias.
    ///
    /// :param: column A column expression.
    ///
    /// :returns: A column expression namespaced with the query’s table name or
    ///           alias.
    public subscript(column: Expression<Double>) -> Expression<Double> {
        return namespace(column)
    }

    /// Prefixes a column expression with the query’s table name or alias.
    ///
    /// :param: column A column expression.
    ///
    /// :returns: A column expression namespaced with the query’s table name or
    ///           alias.
    public subscript(column: Expression<Int>) -> Expression<Int> {
        return namespace(column)
    }

    /// Prefixes a column expression with the query’s table name or alias.
    ///
    /// :param: column A column expression.
    ///
    /// :returns: A column expression namespaced with the query’s table name or
    ///           alias.
    public subscript(column: Expression<String>) -> Expression<String> {
        return namespace(column)
    }

    /// Prefixes a star with the query’s table name or alias.
    ///
    /// :param: star A literal *.
    ///
    /// :returns: A * expression namespaced with the query’s table name or
    ///           alias.
    public subscript(star: Star) -> Expression<()> {
        return namespace(star(nil, nil))
    }

    // MARK: - Compiling Statements

    private var selectStatement: Statement {
        var expressions = [selectClause]
        joinClause.map(expressions.append)
        whereClause.map(expressions.append)
        group.map(expressions.append)
        orderClause.map(expressions.append)
        limitClause.map(expressions.append)
        let expression = SQLite.join(" ", expressions)
        return database.prepare(expression.SQL, expression.bindings)
    }

    /// ON CONFLICT resolutions.
    public enum OnConflict: String {

        case Replace = "REPLACE"

        case Rollback = "ROLLBACK"

        case Abort = "ABORT"

        case Fail = "FAIL"

        case Ignore = "IGNORE"

    }

    private func insertStatement(values: [Setter], or: OnConflict? = nil) -> Statement {
        var insertClause = "INSERT"
        if let or = or { insertClause = "\(insertClause) OR \(or.rawValue)" }
        var expressions: [Expressible] = [Expression<()>("\(insertClause) INTO \(tableName)")]
        println(expressions)
        let (c, v) = (SQLite.join(", ", values.map { $0.0 }), SQLite.join(", ", values.map { $0.1 }))
        expressions.append(Expression<()>("(\(c.SQL)) VALUES (\(v.SQL))", c.bindings + v.bindings))
        whereClause.map(expressions.append)
        let expression = SQLite.join(" ", expressions)
        return database.prepare(expression.SQL, expression.bindings)
    }

    private func updateStatement(values: [Setter]) -> Statement {
        var expressions: [Expressible] = [Expression<()>("UPDATE \(tableName) SET")]
        expressions.append(SQLite.join(", ", values.map { SQLite.join(" = ", [$0, $1]) }))
        whereClause.map(expressions.append)
        let expression = SQLite.join(" ", expressions)
        return database.prepare(expression.SQL, expression.bindings)
    }

    private var deleteStatement: Statement {
        var expressions: [Expressible] = [Expression<()>("DELETE FROM \(tableName)")]
        whereClause.map(expressions.append)
        let expression = SQLite.join(" ", expressions)
        return database.prepare(expression.SQL, expression.bindings)
    }

    // MARK: -

    private var selectClause: Expressible {
        return SQLite.join(" ", [Expression<()>("SELECT"), columns, Expression<()>("FROM \(self)")])
    }

    private var joinClause: Expressible? {
        if joins.count == 0 { return nil }
        return SQLite.join(" ", joins)
    }

    internal var whereClause: Expressible? {
        if let filter = filter {
            return Expression<()>("WHERE \(filter.SQL)", filter.bindings)
        }
        return nil
    }

    private var orderClause: Expressible? {
        if order.count == 0 { return nil }
        let clause = SQLite.join(", ", order)
        return Expression<()>("ORDER BY \(clause.SQL)", clause.bindings)
    }

    private var limitClause: Expressible? {
        if let limit = limit {
            var clause = Expression<()>("LIMIT \(limit.to)")
            if let offset = limit.offset {
                clause = SQLite.join(" ", [clause, Expression<()>("OFFSET \(offset)")])
            }
            return clause
        }
        return nil
    }

    // MARK: - Array

    /// The first result (or nil if the query has no results).
    public var first: Row? { return limit(1).generate().next() }

    /// Returns true if the query has no results.
    public var isEmpty: Bool { return first == nil }

    // MARK: - Modifying

    /// Runs an INSERT statement against the query.
    ///
    /// :param: values A list of values to set.
    ///
    /// :returns: The statement.
    public func insert(values: Setter...) -> Statement { return insert(values).statement }

    /// Runs an INSERT statement against the query.
    ///
    /// :param: values A list of values to set.
    ///
    /// :returns: The row ID.
    public func insert(values: Setter...) -> Int? { return insert(values).ID }

    /// Runs an INSERT statement against the query.
    ///
    /// :param: values A list of values to set.
    ///
    /// :returns: The row ID and statement.
    public func insert(values: Setter...) -> (ID: Int?, statement: Statement) {
        return insert(values)
    }

    private func insert(values: [Setter]) -> (ID: Int?, statement: Statement) {
        let statement = insertStatement(values).run()
        return (statement.failed ? nil : database.lastID, statement)
    }

    /// Runs an UPDATE statement against the query.
    ///
    /// :param: values A list of values to set.
    ///
    /// :returns: The statement.
    public func update(values: Setter...) -> Statement { return update(values).statement }

    /// Runs an UPDATE statement against the query.
    ///
    /// :param: values A list of values to set.
    ///
    /// :returns: The number of updated rows.
    public func update(values: Setter...) -> Int { return update(values).changes }

    /// Runs an UPDATE statement against the query.
    ///
    /// :param: values A list of values to set.
    ///
    /// :returns: The number of updated rows and statement.
    public func update(values: Setter...) -> (changes: Int, statement: Statement) {
        return update(values)
    }

    private func update(values: [Setter]) -> (changes: Int, statement: Statement) {
        let statement = updateStatement(values).run()
        return (statement.failed ? 0 : database.lastChanges ?? 0, statement)
    }

    /// Runs a REPLACE statement against the query.
    ///
    /// :param: values A list of values to set.
    ///
    /// :returns: The statement.
    public func replace(values: Setter...) -> Statement { return replace(values).statement }

    /// Runs a REPLACE statement against the query.
    ///
    /// :param: values A list of values to set.
    ///
    /// :returns: The row ID.
    public func replace(values: Setter...) -> Int? { return replace(values).ID }

    /// Runs a REPLACE statement against the query.
    ///
    /// :param: values A list of values to set.
    ///
    /// :returns: The row ID and statement.
    public func replace(values: Setter...) -> (ID: Int?, statement: Statement) {
        return replace(values)
    }

    private func replace(values: [Setter]) -> (ID: Int?, statement: Statement) {
        let statement = insertStatement(values, or: .Replace).run()
        return (statement.failed ? nil : database.lastID, statement)
    }

    /// Runs a DELETE statement against the query.
    ///
    /// :returns: The statement.
    public func delete() -> Statement { return delete().statement }

    /// Runs a DELETE statement against the query.
    ///
    /// :returns: The number of deleted rows.
    public func delete() -> Int { return delete().changes }

    /// Runs a DELETE statement against the query.
    ///
    /// :returns: The number of deleted rows and statement.
    public func delete() -> (changes: Int, statement: Statement) {
        let statement = deleteStatement.run()
        return (statement.failed ? 0 : database.lastChanges ?? 0, statement)
    }

    // MARK: - Aggregate Functions

    /// Runs count(*) against the query and returns it.
    public var count: Int { return count(Expression<()>("*")) }

    /// Runs count() against the query.
    ///
    /// :param: column The column used for the calculation.
    ///
    /// :returns: The number of rows matching the given column.
    public func count<T>(column: Expression<T>) -> Int {
        return calculate(SQLite.count(column))!
    }

    /// Runs max() against the query.
    ///
    /// :param: column The column used for the calculation.
    ///
    /// :returns: The largest value of the given column.
    public func max<T: Value>(column: Expression<T>) -> T? {
        return calculate(SQLite.max(column))
    }

    /// Runs min() against the query.
    ///
    /// :param: column The column used for the calculation.
    ///
    /// :returns: The smallest value of the given column.
    public func min<T: Value>(column: Expression<T>) -> T? {
        return calculate(SQLite.min(column))
    }

    /// Runs avg() against the query.
    ///
    /// :param: column The column used for the calculation.
    ///
    /// :returns: The average value of the given column.
    public func average<T: Number>(column: Expression<T>) -> Double? {
        return calculate(SQLite.average(column))
    }

    /// Runs sum() against the query.
    ///
    /// :param: column The column used for the calculation.
    ///
    /// :returns: The sum of the given column’s values.
    public func sum<T: Number>(column: Expression<T>) -> T? {
        return calculate(SQLite.sum(column))
    }

    /// Runs total() against the query.
    ///
    /// :param: column The column used for the calculation.
    ///
    /// :returns: The total of the given column’s values.
    public func total<T: Number>(column: Expression<T>) -> Double {
        return calculate(SQLite.total(column))!
    }

    private func calculate<T, U>(expression: Expression<T>) -> U? {
        return select(expression).selectStatement.scalar() as? U
    }

}

/// A row object. Returned by iterating over a Query. Provides typed subscript
/// access to a row’s values.
public struct Row {

    private var values: Values

    private init(_ values: Values) {
        self.values = values
    }

    /// Returns a row’s value for the given column.
    ///
    /// :param: column An expression representing a column selected in a Query.
    ///
    /// returns The value for the given column.
    public func get<T: Value>(column: Expression<T>) -> T? {
        return values[column.SQL] as? T
    }

    // FIXME: rdar://18673897 subscript<T>(expression: Expression<T>) -> Expression<T>

    /// Returns a row’s value for the given column.
    ///
    /// :param: column An expression representing a column selected in a Query.
    ///
    /// returns The value for the given column.
    public subscript(column: Expression<Bool>) -> Bool? {
        return get(column)
    }

    /// Returns a row’s value for the given column.
    ///
    /// :param: column An expression representing a column selected in a Query.
    ///
    /// returns The value for the given column.
    public subscript(column: Expression<Double>) -> Double? {
        return get(column)
    }

    /// Returns a row’s value for the given column.
    ///
    /// :param: column An expression representing a column selected in a Query.
    ///
    /// returns The value for the given column.
    public subscript(column: Expression<Int>) -> Int? {
        return get(column)
    }

    /// Returns a row’s value for the given column.
    ///
    /// :param: column An expression representing a column selected in a Query.
    ///
    /// returns The value for the given column.
    public subscript(column: Expression<String>) -> String? {
        return get(column)
    }

}

// MARK: - SequenceType
extension Query: SequenceType {

    public typealias Generator = QueryGenerator

    public func generate() -> Generator { return Generator(selectStatement) }

}

// MARK: - GeneratorType
public struct QueryGenerator: GeneratorType {

    private var statement: Statement

    private init(_ statement: Statement) { self.statement = statement }

    public func next() -> Row? {
        statement.next()
        return statement.values.map { Row($0) }
    }

}

// MARK: - Printable
extension Query: Printable {

    public var description: String {
        if let alias = alias { return "\(tableName) AS \(alias)" }
        return tableName
    }

}

extension Database {

    public subscript(tableName: String) -> Query {
        return Query(self, tableName)
    }

}

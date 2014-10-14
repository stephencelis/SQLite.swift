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
public typealias Values = [String: Datatype?]

/// A query object. Used to build SQL statements with a collection of chainable
/// helper functions.
public struct Query {

    private var database: Database

    internal init(_ database: Database, _ tableName: String) {
        self.database = database
        self.tableName = tableName
        self.columnNames = ["*"]
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

    /// Determines the direction in which rows are returned for a query’s ORDER
    /// BY clause.
    public enum SortDirection: String {

        /// Ascending order (smaller to larger values).
        case Asc = "ASC"

        /// Descending order (larger to smaller values).
        case Desc = "DESC"

    }

    private var columnNames: [String]
    private var tableName: String
    private var joins = [JoinType, String, String]()
    private var conditions: String?
    private var bindings = [Datatype?]()
    private var groupByHaving: ([String], String?, [Datatype?])?
    private var order = [String, SortDirection]()
    private var limit: Int?
    private var offset: Int?

    // MARK: -

    /// Sets a SELECT clause on the query.
    ///
    /// :param: columnNames A list of columns to retrieve.
    ///
    /// :returns: A query with the given SELECT clause applied.
    public func select(columnNames: String...) -> Query {
        var query = self
        query.columnNames = columnNames
        return query
    }

    /// Adds an INNER JOIN clause to the query.
    ///
    /// :param: tableName  The table being joined.
    ///
    /// :param: constraint The condition in which the table is joined.
    ///
    /// :returns: A query with the given INNER JOIN clause applied.
    public func join(tableName: String, on constraint: String) -> Query {
        return join(.Inner, tableName, on: constraint)
    }

    /// Adds a JOIN clause to the query.
    ///
    /// :param: type      The JOIN operator used.
    ///
    /// :param: tableName The table being joined.
    ///
    /// :param: constraint The condition in which the table is joined.
    ///
    /// :returns: A query with the given JOIN clause applied.
    public func join(type: JoinType, _ tableName: String, on constraint: String) -> Query {
        var query = self
        query.joins.append(type, tableName, constraint)
        return query
    }

    /// Adds a condition to the query’s WHERE clause.
    ///
    /// :param: condition A dictionary of conditions where the keys map to
    ///                   column names and the columns must equal the given
    ///                   values.
    ///
    /// :returns: A query with the given condition applied.
    public func filter(condition: [String: Datatype?]) -> Query {
        var query = self
        for (column, value) in condition {
            if let value = value {
                query = query.filter("\(column) = ?", value)
            } else {
                query = query.filter("\(column) IS NULL")
            }
        }
        return query
    }

    /// Adds a condition to the query’s WHERE clause.
    ///
    /// :param: condition A dictionary of conditions where the keys map to
    ///                   column names and the columns must be in the lists of
    ///                   given values.
    ///
    /// :returns: A query with the given condition applied.
    public func filter(condition: [String: [Datatype?]]) -> Query {
        var query = self
        for (column, values) in condition {
            let templates = Swift.join(", ", [String](count: values.count, repeatedValue: "?"))
            query = query.filter("\(column) IN (\(templates))", values)
        }
        return query
    }

    /// Adds a condition to the query’s WHERE clause.
    ///
    /// :param: condition A dictionary of conditions where the keys map to
    ///                   column names and the columns must be in the ranges of
    ///                   given values.
    ///
    /// :returns: A query with the given condition applied.
    public func filter<T: Datatype>(condition: [String: Range<T>]) -> Query {
        var query = self
        for (column, value) in condition {
            query = query.filter("\(column) BETWEEN ? AND ?", value.startIndex, value.endIndex)
        }
        return query
    }

    /// Adds a condition to the query’s WHERE clause.
    ///
    /// :param: condition A string condition with optional "?"-parameterized
    ///                   bindings.
    ///
    /// :param: bindings  A list of parameters to bind to the WHERE clause.
    ///
    /// :returns: A query with the given condition applied.
    public func filter(condition: String, _ bindings: Datatype?...) -> Query {
        return filter(condition, bindings)
    }

    /// Adds a condition to the query’s WHERE clause.
    ///
    /// :param: condition A string condition with optional "?"-parameterized
    ///                   bindings.
    ///
    /// :param: bindings  A list of parameters to bind to the WHERE clause.
    ///
    /// :returns: A query with the given condition applied.
    public func filter(condition: String, _ bindings: [Datatype?]) -> Query {
        var query = self
        if let conditions = query.conditions {
            query.conditions = "\(conditions) AND \(condition)"
        } else {
            query.conditions = condition
        }
        query.bindings += bindings
        return query
    }

    /// Sets a GROUP BY clause on the query.
    ///
    /// :param: by A list of columns to group by.
    ///
    /// :returns: A query with the given GROUP BY clause applied.
    public func group(by: String...) -> Query {
        return group(by, bindings)
    }

    /// Sets a GROUP BY-HAVING clause on the query.
    ///
    /// :param: by       A column to group by.
    ///
    /// :param: having   A condition determining which groups are returned.
    ///
    /// :param: bindings A list of parameters to bind to the HAVING clause.
    ///
    /// :returns: A query with the given GROUP BY clause applied.
    public func group(by: String, having: String, _ bindings: Datatype?...) -> Query {
        return group([by], having: having, bindings)
    }

    /// Sets a GROUP BY-HAVING clause on the query.
    ///
    /// :param: by       A list of columns to group by.
    ///
    /// :param: having   A condition determining which groups are returned.
    ///
    /// :param: bindings A list of parameters to bind to the HAVING clause.
    ///
    /// :returns: A query with the given GROUP BY clause applied.
    public func group(by: [String], having: String, _ bindings: Datatype?...) -> Query {
        return group(by, having: having, bindings)
    }

    private func group(by: [String], having: String? = nil, _ bindings: [Datatype?]) -> Query {
        var query = self
        query.groupByHaving = (by, having, bindings)
        return query
    }

    /// Adds sorting instructions to the query’s ORDER BY clause.
    ///
    /// :param: by A list of columns to order by with an ascending sort.
    ///
    /// :returns: A query with the given sorting instructions applied.
    public func order(by: String...) -> Query {
        return order(by)
    }

    private func order(by: [String]) -> Query {
        return order(by.map { ($0, .Asc) })
    }

    /// Adds sorting instructions to the query’s ORDER BY clause.
    ///
    /// :param: by        A column to order by.
    ///
    /// :param: direction The direction in which the column is ordered.
    ///
    /// :returns: A query with the given sorting instructions applied.
    public func order(by: String, _ direction: SortDirection) -> Query {
        return order([(by, direction)])
    }

    /// Adds sorting instructions to the query’s ORDER BY clause.
    ///
    /// :param: by An ordered list of columns and directions to sort them by.
    ///
    /// :returns: A query with the given sorting instructions applied.
    public func order(by: (String, SortDirection)...) -> Query {
        return order(by)
    }

    private func order(by: [(String, SortDirection)]) -> Query {
        var query = self
        query.order += by
        return query
    }

    /// Sets the LIMIT clause (and resets any OFFSET clause) on the query.
    ///
    /// :param: to The maximum number of rows to return.
    ///
    /// :returns A query with the given LIMIT clause applied.
    public func limit(to: Int?) -> Query {
        return limit(to: to, offset: nil)
    }

    /// Sets LIMIT and OFFSET clauses on the query.
    ///
    /// :param: to     The maximum number of rows to return.
    ///
    /// :param: offset The number of rows to skip.
    ///
    /// :returns A query with the given LIMIT and OFFSET clauses applied.
    public func limit(to: Int, offset: Int) -> Query {
        return limit(to: to, offset: offset)
    }

    // prevent limit(nil, offset: 5)
    private func limit(#to: Int?, offset: Int? = nil) -> Query {
        var query = self
        (query.limit, query.offset) = (to, offset)
        return query
    }

    // MARK: - Compiling Statements

    private var selectStatement: Statement {
        let columnNames = Swift.join(", ", self.columnNames)

        var parts = ["SELECT \(columnNames) FROM \(tableName)"]
        joinClause.map(parts.append)
        whereClause.map(parts.append)
        groupClause.map(parts.append)
        orderClause.map(parts.append)
        limitClause.map(parts.append)

        var bindings = self.bindings
        if let (_, _, values) = groupByHaving { bindings += values }

        return database.prepare(Swift.join(" ", parts), bindings)
    }

    private func insertStatement(values: Values) -> Statement {
        var (parts, bindings) = (["INSERT INTO \(tableName)"], self.bindings)
        let valuesClause = Swift.join(", ", map(values) { columnName, value in
            bindings.append(value)
            return columnName
        })
        let templates = Swift.join(", ", [String](count: values.count, repeatedValue: "?"))
        parts.append("(\(valuesClause)) VALUES (\(templates))")
        return database.prepare(Swift.join(" ", parts), bindings)
    }

    private func updateStatement(values: Values) -> Statement {
        var (parts, bindings) = (["UPDATE \(tableName)"], [Datatype?]())
        let valuesClause = Swift.join(", ", map(values) { columnName, value in
            bindings.append(value)
            return "\(columnName) = ?"
        })
        parts.append("SET \(valuesClause)")
        whereClause.map(parts.append)
        return database.prepare(Swift.join(" ", parts), bindings + self.bindings)
    }

    private var deleteStatement: Statement {
        var parts = ["DELETE FROM \(tableName)"]
        whereClause.map(parts.append)
        return database.prepare(Swift.join(" ", parts), bindings)
    }

    // MARK: -

    private var joinClause: String? {
        if joins.count == 0 { return nil }
        let clause = joins.map { "\($0.rawValue) JOIN \($1) ON \($2)" }
        return Swift.join(" ", clause)
    }

    private var whereClause: String? {
        if let conditions = conditions { return "WHERE \(conditions)" }
        return nil
    }

    private var groupClause: String? {
        if let (groupBy, having, _) = groupByHaving {
            let groups = Swift.join(", ", groupBy)
            var clause = ["GROUP BY \(groups)"]
            having.map { clause.append("HAVING \($0)") }
            return Swift.join(" ", clause)
        }
        return nil
    }

    private var orderClause: String? {
        if order.count == 0 { return nil }
        let mapped = order.map { "\($0.0) \($0.1.rawValue)" }
        let joined = Swift.join(", ", mapped)
        return "ORDER BY \(joined)"
    }

    private var limitClause: String? {
        if let to = limit {
            var clause = ["LIMIT \(to)"]
            offset.map { clause.append("OFFSET \($0)") }
            return Swift.join(" ", clause)
        }
        return nil
    }

    // MARK: - Array

    /// The first result (or nil if the query has no results).
    public var first: Values? { return limit(1).generate().next() }

    /// The last result (or nil if the query has no results).
    public var last: Values? { return reverse(self).first }

    /// Returns true if the query has no results.
    public var isEmpty: Bool { return first == nil }

    // MARK: - Modifying

    /// Runs an INSERT statement with the given row of values.
    ///
    /// :param: values A dictionary of column names to values.
    ///
    /// :returns: The statement.
    public func insert(values: Values) -> Statement { return insert(values).statement }

    /// Runs an INSERT statement with the given row of values.
    ///
    /// :param: values A dictionary of column names to values.
    ///
    /// :returns: The row ID.
    public func insert(values: Values) -> Int? { return insert(values).ID }

    /// Runs an INSERT statement with the given row of values.
    ///
    /// :param: values A dictionary of column names to values.
    ///
    /// :returns: The row ID and statement.
    public func insert(values: Values) -> (ID: Int?, statement: Statement) {
        let statement = insertStatement(values).run()
        return (statement.failed ? nil : database.lastID, statement)
    }

    /// Runs an UPDATE statement against the query with the given values.
    ///
    /// :param: values A dictionary of column names to values.
    ///
    /// :returns: The statement.
    public func update(values: Values) -> Statement { return update(values).statement }

    /// Runs an UPDATE statement against the query with the given values.
    ///
    /// :param: values A dictionary of column names to values.
    ///
    /// :returns: The number of updated rows.
    public func update(values: Values) -> Int { return update(values).changes }

    /// Runs an UPDATE statement against the query with the given values.
    ///
    /// :param: values A dictionary of column names to values.
    ///
    /// :returns: The number of updated rows and statement.
    public func update(values: Values) -> (changes: Int, statement: Statement) {
        let statement = updateStatement(values).run()
        return (statement.failed ? 0 : database.lastChanges ?? 0, statement)
    }

    /// Runs an DELETE statement against the query.
    ///
    /// :returns: The statement.
    public func delete() -> Statement { return delete().statement }

    /// Runs an DELETE statement against the query.
    ///
    /// :returns: The number of deleted rows.
    public func delete() -> Int { return delete().changes }

    /// Runs an DELETE statement against the query.
    ///
    /// :returns: The number of deleted rows and statement.
    public func delete() -> (changes: Int, statement: Statement) {
        let statement = deleteStatement.run()
        return (statement.failed ? 0 : database.lastChanges ?? 0, statement)
    }

    // MARK: - Aggregate Functions

    /// Runs count(*) against the query and returns it.
    public var count: Int { return count("*") }

    /// Runs count() against the query.
    ///
    /// :param: columnName The column used for the calculation.
    ///
    /// :returns: The number of rows matching the given column.
    public func count(columnName: String) -> Int {
        return calculate("count", columnName) as Int
    }

    /// Runs max() against the query.
    ///
    /// :param: columnName The column used for the calculation.
    ///
    /// :returns: The largest value of the given column.
    public func max(columnName: String) -> Datatype? {
        return calculate("max", columnName)
    }

    /// Runs min() against the query.
    ///
    /// :param: columnName The column used for the calculation.
    ///
    /// :returns: The smallest value of the given column.
    public func min(columnName: String) -> Datatype? {
        return calculate("min", columnName)
    }

    /// Runs avg() against the query.
    ///
    /// :param: columnName The column used for the calculation.
    /// :returns: The average value of the given column.
    public func average(columnName: String) -> Double? {
        return calculate("avg", columnName) as? Double
    }

    /// Runs sum() against the query.
    ///
    /// :param: columnName The column used for the calculation.
    ///
    /// :returns: The sum of the given column’s values.
    public func sum(columnName: String) -> Datatype? {
        return calculate("sum", columnName)
    }

    /// Runs total() against the query.
    ///
    /// :param: columnName The column used for the calculation.
    ///
    /// :returns: The total of the given column’s values.
    public func total(columnName: String) -> Double {
        return calculate("total", columnName) as Double
    }

    private func calculate(function: String, _ columnName: String) -> Datatype? {
        return select("\(function)(\(columnName))").selectStatement.scalar()
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

    public func next() -> Values? {
        statement.next()
        return statement.values
    }

}

/// Reverses the order of a given query.
///
/// :param: query A query object to reverse.
///
/// :returns: A reversed query.
public func reverse(query: Query) -> Query {
    if query.order.count == 0 { return query.order("\(query.tableName).ROWID", .Desc) }

    var reversed = query
    reversed.order = query.order.map { ($0, $1 == .Asc ? .Desc : .Asc) }
    return reversed
}

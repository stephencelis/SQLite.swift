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

    private var database: Database

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

    /// Determines the direction in which rows are returned for a query’s ORDER
    /// BY clause.
    public enum SortDirection: String {

        /// Ascending order (smaller to larger values).
        case Asc = "ASC"

        /// Descending order (larger to smaller values).
        case Desc = "DESC"

    }

    private var columns: [Expressible] = [Expression<()>("*")]
    internal var tableName: String
    private var joins = [Expressible]()
    private var filter: Expression<Bool>?
    private var group: Expressible?
    private var order = [Expressible]()
    private var limit: (to: Int, offset: Int?)? = nil

    public func select(columns: Expressible...) -> Query {
        var query = self
        query.columns = columns
        return query
    }

    public func select(star: Star) -> Query {
        var query = self
        query.columns = [star(nil, nil)]
        return query
    }

    public func join(table: Query, on: Expression<Bool>) -> Query {
        return join(.Inner, table, on: on)
    }

    public func join(type: JoinType, _ table: Query, on: Expression<Bool>) -> Query {
        var query = self
        let condition = table.filter.map { on && $0 } ?? on
        let expression = Expression<()>("\(type.rawValue) JOIN \(table.tableName) ON \(condition.SQL)", condition.bindings)
        query.joins.append(expression)
        return query
    }

    public func filter(condition: Expression<Bool>) -> Query {
        var query = self
        query.filter = filter.map { $0 && condition } ?? condition
        return query
    }

    public func group(by: Expressible...) -> Query {
        return group(by)
    }

    public func group(by: Expressible, having: Expression<Bool>) -> Query {
        return group([by], having: having)
    }

    public func group(by: [Expressible], having: Expression<Bool>? = nil) -> Query {
        var query = self
        var group = SQLite.join(" ", [Expression<()>("GROUP BY"), SQLite.join(", ", by)])
        if let having = having { group = SQLite.join(" ", [group, Expression<()>("HAVING"), having]) }
        query.group = group
        return query
    }

    public func order(by: Expressible...) -> Query {
        var query = self
        query.order = by
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
        if let to = to {
            query.limit = (to, offset)
        } else {
            query.limit = nil
        }
        return query
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

    private func insertStatement(values: [(Expressible, Expressible)]) -> Statement {
        var expressions: [Expressible] = [Expression<()>("INSERT INTO \(tableName)")]
        let (c, v) = (SQLite.join(", ", values.map { $0.0 }), SQLite.join(", ", values.map { $0.1 }))
        expressions.append(Expression<()>("(\(c.SQL)) VALUES (\(v.SQL))", c.bindings + v.bindings))
        whereClause.map(expressions.append)
        let expression = SQLite.join(" ", expressions)
        return database.prepare(expression.SQL, expression.bindings)
    }

    private func updateStatement(values: [(Expressible, Expressible)]) -> Statement {
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
        let select = SQLite.join(", ", columns)
        return SQLite.join(" ", [Expression<()>("SELECT"), select, Expression<()>("FROM \(tableName)")])
    }

    private var joinClause: Expressible? {
        if joins.count == 0 { return nil }
        return SQLite.join(" ", joins)
    }

    private var whereClause: Expressible? {
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
    public var first: Values? { return limit(1).generate().next() }

    /// Returns true if the query has no results.
    public var isEmpty: Bool { return first == nil }

    // MARK: - Modifying

    public final class ValuesBuilder {

        private let query: Query

        private var values = [(Expressible, Expressible)]()

        private init(_ query: Query, _ builder: ValuesBuilder -> ()) {
            self.query = query
            builder(self)
        }

        public func set<T: Value>(column: Expression<T>, _ value: T?) {
            values.append((column, Expression<()>(value: value)))
        }

    }

    /// Runs an INSERT statement against the query.
    ///
    /// :param: builder A block with a ValuesBuilder, used for aggregating
    ///                 values for the INSERT.
    ///
    /// :returns: The statement.
    public func insert(builder: ValuesBuilder -> ()) -> Statement { return insert(builder).statement }

    /// Runs an INSERT statement against the query.
    ///
    /// :param: builder A block with a ValuesBuilder, used for aggregating
    ///                 values for the INSERT.
    ///
    /// :returns: The row ID.
    public func insert(builder: ValuesBuilder -> ()) -> Int? { return insert(builder).ID }

    /// Runs an INSERT statement against the query.
    ///
    /// :param: builder A block with a ValuesBuilder, used for aggregating
    ///                 values for the INSERT.
    ///
    /// :returns: The row ID and statement.
    public func insert(builder: ValuesBuilder -> ()) -> (ID: Int?, statement: Statement) {
        let statement = insertStatement(ValuesBuilder(self, builder).values).run()
        return (statement.failed ? nil : database.lastID, statement)
    }

    /// Runs an UPDATE statement against the query.
    ///
    /// :param: builder A block with a ValuesBuilder, used for aggregating
    ///                 values for the UPDATE.
    ///
    /// :returns: The statement.
    public func update(builder: ValuesBuilder -> ()) -> Statement { return update(builder).statement }

    /// Runs an UPDATE statement against the query.
    ///
    /// :param: builder A block with a ValuesBuilder, used for aggregating
    ///                 values for the UPDATE.
    ///
    /// :returns: The number of updated rows.
    public func update(builder: ValuesBuilder -> ()) -> Int { return update(builder).changes }

    /// Runs an UPDATE statement against the query.
    ///
    /// :param: builder A block with a ValuesBuilder, used for aggregating
    ///                 values for the UPDATE.
    ///
    /// :returns: The number of updated rows and statement.
    public func update(builder: ValuesBuilder -> ()) -> (changes: Int, statement: Statement) {
        let statement = updateStatement(ValuesBuilder(self, builder).values).run()
        return (statement.failed ? 0 : database.lastChanges ?? 0, statement)
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

extension Database {

    public subscript(tableName: String) -> Query {
        return Query(self, tableName)
    }

}

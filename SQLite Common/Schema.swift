//
// SQLite.Schema
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

public extension Database {

    public func create(
        #table: Query,
        temporary: Bool = false,
        ifNotExists: Bool = false,
        _ block: SchemaBuilder -> ()
    ) -> Statement {
        var builder = SchemaBuilder(table)
        block(builder)
        let create = createSQL("TABLE", temporary, false, ifNotExists, table.tableName)
        let columns = SQLite.join(", ", builder.columns).compile()
        return run("\(create) (\(columns))")
    }

    public func create(#table: Query, temporary: Bool = false, ifNotExists: Bool = false, from: Query) -> Statement {
        let create = createSQL("TABLE", temporary, false, ifNotExists, table.tableName)
        let expression = from.selectExpression
        return run("\(create) AS \(expression.SQL)", expression.bindings)
    }

    public func rename(#table: Query, to tableName: String) -> Statement {
        return run("ALTER TABLE \(table.tableName) RENAME TO \(tableName)")
    }

    public func alter<T: Value>(
        #table: Query,
        add column: Expression<T>,
        check: Expression<Bool>? = nil,
        defaultValue: T
    ) -> Statement {
        return alter(table, define(column, false, false, false, check, Expression(value: defaultValue), nil))
    }

    public func alter<T: Value>(
        #table: Query,
        add column: Expression<T?>,
        check: Expression<Bool>? = nil,
        defaultValue: T? = nil
    ) -> Statement {
        let value = defaultValue.map { Expression<T>(value: $0) }
        return alter(table, define(Expression<T>(column), false, true, false, check, value, nil))
    }

    public func alter<T: Value>(
        #table: Query,
        add column: Expression<T?>,
        check: Expression<Bool>? = nil,
        references: Expression<T>
    ) -> Statement {
        let expressions = [Expression<()>("REFERENCES"), namespace(references)]
        return alter(table, define(Expression<T>(column), false, true, false, check, nil, expressions))
    }

    private func alter(table: Query, _ definition: Expressible) -> Statement {
        return run("ALTER TABLE \(table.tableName) ADD COLUMN \(definition.expression.compile())")
    }

    public func drop(#table: Query, ifExists: Bool = false) -> Statement {
        return run(dropSQL("TABLE", ifExists, table.tableName))
    }

    public func create(
        index table: Query,
        unique: Bool = false,
        ifNotExists: Bool = false,
        on columns: Expressible...
    ) -> Statement {
        let create = createSQL("INDEX", false, unique, ifNotExists, indexName(table, on: columns))
        let joined = SQLite.join(", ", columns)
        return run("\(create) ON \(table.tableName) (\(joined.compile()))")
    }

    public func drop(index table: Query, ifExists: Bool = false, on columns: Expressible...) -> Statement {
        return run(dropSQL("INDEX", ifExists, indexName(table, on: columns)))
    }

    private func indexName(table: Query, on columns: [Expressible]) -> String {
        let string = join(" ", ["index", table.tableName, "on"] + columns.map { $0.expression.SQL })
        return Array(string).reduce("") { underscored, character in
            if "A"..."Z" ~= character || "a"..."z" ~= character { return underscored + String(character) }
            return underscored + "_"
        }
    }

    public func create(#view: Query, temporary: Bool = false, ifNotExists: Bool = false, from: Query) -> Statement {
        let create = createSQL("VIEW", temporary, false, ifNotExists, view.tableName)
        let expression = from.selectExpression
        return run("\(create) AS \(expression.SQL)", expression.bindings)
    }

    public func drop(#view: Query, ifExists: Bool = false) -> Statement {
        return run(dropSQL("VIEW", ifExists, view.tableName))
    }

}

public final class SchemaBuilder {

    let table: Query
    var columns = [Expressible]()

    private init(_ table: Query) {
        self.table = table
    }

    public func column<T: Value>(
        name: Expression<T>,
        primaryKey: Bool = false,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: Expression<T>? = nil
    ) {
        column(name, primaryKey, false, unique, check, value)
    }

    public func column<T: Value>(
        name: Expression<T>,
        primaryKey: Bool = false,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: T
    ) {
        column(name, primaryKey, false, unique, check, Expression(value: value))
    }

    public func column<T: Value>(
        name: Expression<T?>,
        primaryKey: Bool = false,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: Expression<T>? = nil
    ) {
        column(Expression<T>(name), primaryKey, true, unique, check, value)
    }

    public func column<T: Value>(
        name: Expression<T?>,
        primaryKey: Bool = false,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: T?
    ) {
        column(Expression<T>(name), primaryKey, true, unique, check, value.map { Expression(value: $0) })
    }

    public func column(
        name: Expression<String>,
        primaryKey: Bool = false,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: Expression<String>? = nil,
        collate: Collation
    ) {
        let expressions: [Expressible] = [Expression<()>("COLLATE \(collate.rawValue)")]
        column(name, primaryKey, false, unique, check, value, expressions)
    }

    public func column(
        name: Expression<String>,
        primaryKey: Bool = false,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: String,
        collate: Collation
    ) {
        let expressions: [Expressible] = [Expression<()>("COLLATE \(collate.rawValue)")]
        column(name, primaryKey, false, unique, check, Expression(value: value), expressions)
    }

    public func column(
        name: Expression<String?>,
        primaryKey: Bool = false,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: Expression<String>? = nil,
        collate: Collation
    ) {
        let expressions: [Expressible] = [Expression<()>("COLLATE \(collate.rawValue)")]
        column(Expression<String>(name), primaryKey, true, unique, check, value, expressions)
    }

    public func column(
        name: Expression<String?>,
        primaryKey: Bool = false,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: String?,
        collate: Collation
    ) {
        let expressions: [Expressible] = [Expression<()>("COLLATE \(collate.rawValue)")]
        column(Expression<String>(name), primaryKey, true, unique, check, Expression(value: value), expressions)
    }

    public func column(
        name: Expression<Int>,
        primaryKey: Bool = false,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: Expression<Int>? = nil,
        references: Expression<Int>
    ) {
        assertForeignKeysEnabled()
        let expressions: [Expressible] = [Expression<()>("REFERENCES"), namespace(references)]
        column(name, primaryKey, false, unique, check, value, expressions)
    }

    public func column(
        name: Expression<Int>,
        primaryKey: Bool = false,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: Int,
        references: Expression<Int>
    ) {
        assertForeignKeysEnabled()
        let expressions: [Expressible] = [Expression<()>("REFERENCES"), namespace(references)]
        column(name, primaryKey, false, unique, check, Expression(value: value), expressions)
    }

    public func column(
        name: Expression<Int?>,
        primaryKey: Bool = false,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: Expression<Int>? = nil,
        references: Expression<Int>
    ) {
        assertForeignKeysEnabled()
        let expressions: [Expressible] = [Expression<()>("REFERENCES"), namespace(references)]
        column(Expression<Int>(name), primaryKey, true, unique, check, value, expressions)
    }

    public func column(
        name: Expression<Int?>,
        primaryKey: Bool = false,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: Int?,
        references: Expression<Int>
    ) {
        assertForeignKeysEnabled()
        let expressions: [Expressible] = [Expression<()>("REFERENCES"), namespace(references)]
        column(Expression<Int>(name), primaryKey, true, unique, check, Expression(value: value), expressions)
    }

    public func column(
        name: Expression<Int>,
        primaryKey: Bool = false,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue: Expression<Int>? = nil,
        references: Query
    ) {
        return column(
            name,
            primaryKey: primaryKey,
            unique: unique,
            check: check,
            defaultValue: defaultValue,
            references: Expression(references.tableName)
        )
    }

    public func column(
        name: Expression<Int>,
        primaryKey: Bool = false,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue: Int,
        references: Query
    ) {
        return column(
            name,
            primaryKey: primaryKey,
            unique: unique,
            check: check,
            defaultValue: defaultValue,
            references: Expression(references.tableName)
        )
    }

    public func column(
        name: Expression<Int?>,
        primaryKey: Bool = false,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue: Expression<Int>? = nil,
        references: Query
    ) {
        return column(
            name,
            primaryKey: primaryKey,
            unique: unique,
            check: check,
            defaultValue: defaultValue,
            references: Expression(references.tableName)
        )
    }

    public func column(
        name: Expression<Int?>,
        primaryKey: Bool = false,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue: Int?,
        references: Query
    ) {
        return column(
            name,
            primaryKey: primaryKey,
            unique: unique,
            check: check,
            defaultValue: defaultValue,
            references: Expression(references.tableName)
        )
    }

    private func column<T: Value>(
        name: Expression<T>,
        _ primaryKey: Bool,
        _ null: Bool,
        _ unique: Bool,
        _ check: Expression<Bool>?,
        _ defaultValue: Expression<T>?,
        _ expressions: [Expressible]? = nil
    ) {
        columns.append(define(name, primaryKey, null, unique, check, defaultValue, expressions))
    }

    public func primaryKey(column: Expressible...) {
        let primaryKey = SQLite.join(", ", column)
        columns.append(Expression<()>("PRIMARY KEY(\(primaryKey.SQL))", primaryKey.bindings))
    }

    public func unique(column: Expressible...) {
        let unique = SQLite.join(", ", column)
        columns.append(Expression<()>("UNIQUE(\(unique.SQL))", unique.bindings))
    }

    public func check(condition: Expression<Bool>) {
        columns.append(Expression<()>("CHECK \(condition.SQL)", condition.bindings))
    }

    public enum Dependency: String {

        case NoAction = "NO ACTION"

        case Restrict = "RESTRICT"

        case SetNull = "SET NULL"

        case SetDefault = "SET DEFAULT"

        case Cascade = "CASCADE"

    }

    public func foreignKey<T: Value>(
        column: Expression<T>,
        references: Expression<T>,
        update: Dependency? = nil,
        delete: Dependency? = nil
    ) {
        assertForeignKeysEnabled()
        var parts: [Expressible] = [Expression<()>("FOREIGN KEY(\(column.SQL)) REFERENCES", column.bindings)]
        parts.append(namespace(references))
        if let update = update { parts.append(Expression<()>("ON UPDATE \(update.rawValue)")) }
        if let delete = delete { parts.append(Expression<()>("ON DELETE \(delete.rawValue)")) }
        columns.append(SQLite.join(" ", parts))
    }
    public func foreignKey<T: Value>(
        column: Expression<T?>,
        references: Expression<T>,
        update: Dependency? = nil,
        delete: Dependency? = nil
    ) {
        assertForeignKeysEnabled()
        var parts: [Expressible] = [Expression<()>("FOREIGN KEY(\(column.SQL)) REFERENCES", column.bindings)]
        parts.append(namespace(references))
        if let update = update { parts.append(Expression<()>("ON UPDATE \(update.rawValue)")) }
        if let delete = delete { parts.append(Expression<()>("ON DELETE \(delete.rawValue)")) }
        columns.append(SQLite.join(" ", parts))
    }

    public func foreignKey<T: Value>(
        column: Expression<T>,
        references: Query,
        update: Dependency? = nil,
        delete: Dependency? = nil
    ) {
        foreignKey(column, references: Expression(references.tableName), update: update, delete: delete)
    }
    public func foreignKey<T: Value>(
        column: Expression<T?>,
        references: Query,
        update: Dependency? = nil,
        delete: Dependency? = nil
    ) {
        foreignKey(column, references: Expression(references.tableName), update: update, delete: delete)
    }

    private func assertForeignKeysEnabled() {
        assert(table.database.scalar("PRAGMA foreign_keys") as Int == 1, "foreign key constraints are disabled")
    }

}

private func namespace(column: Expressible) -> Expressible {
    let expression = column.expression
    if !contains(expression.SQL, ".") { return expression }
    let reference = Array(expression.SQL).reduce("") { SQL, character in
        let string = String(character)
        return SQL + (string == "." ? "(" : string)
    }
    return Expression<()>("\(reference))", expression.bindings)
}

private func define<T: Value>(
    column: Expression<T>,
    primaryKey: Bool,
    null: Bool,
    unique: Bool,
    check: Expression<Bool>?,
    defaultValue: Expression<T>?,
    expressions: [Expressible]?
) -> Expressible {
    var parts: [Expressible] = [Expression<()>(column), Expression<()>(T.datatype)]
    if primaryKey { parts.append(Expression<()>("PRIMARY KEY")) }
    if !null { parts.append(Expression<()>("NOT NULL")) }
    if unique { parts.append(Expression<()>("UNIQUE")) }
    if let check = check { parts.append(Expression<()>("CHECK \(check.SQL)", check.bindings)) }
    if let value = defaultValue { parts.append(Expression<()>("DEFAULT \(value.SQL)", value.bindings)) }
    if let expressions = expressions { parts += expressions }
    return SQLite.join(" ", parts)
}

private func createSQL(
    type: String,
    temporary: Bool,
    unique: Bool,
    ifNotExists: Bool,
    name: String
) -> String {
    var parts: [String] = ["CREATE"]
    if temporary { parts.append("TEMPORARY") }
    if unique { parts.append("UNIQUE") }
    parts.append(type)
    if ifNotExists { parts.append("IF NOT EXISTS") }
    parts.append(name)
    return Swift.join(" ", parts)
}

private func dropSQL(type: String, ifExists: Bool, name: String) -> String {
    var parts: [String] = ["DROP \(type)"]
    if ifExists { parts.append("IF EXISTS") }
    parts.append(name)
    return Swift.join(" ", parts)
}

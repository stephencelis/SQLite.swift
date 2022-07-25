import Foundation

/*
    https://www.sqlite.org/lang_altertable.html

   The only schema altering commands directly supported by SQLite are the "rename table" and "add column"
   commands shown above.

    (SQLite 3.25.0: RENAME COLUMN)
    (SQLite 3.35.0: DROP COLUMN)

   However, applications can make other arbitrary changes to the format of a table using a
   simple sequence of operations. The steps to make arbitrary changes to the schema design of some table X are as follows:

        1. If foreign key constraints are enabled, disable them using PRAGMA foreign_keys=OFF.
        2. Start a transaction.
        3. Remember the format of all indexes and triggers associated with table X
           (SELECT sql FROM sqlite_master WHERE tbl_name='X' AND type='index')
        4. Use CREATE TABLE to construct a new table "new_X" that is in the desired revised format of table X.
        5. Transfer content from X into new_X using a statement like: INSERT INTO new_X SELECT ... FROM X.
        6. Drop the old table X: DROP TABLE X.
        7. Change the name of new_X to X using: ALTER TABLE new_X RENAME TO X.
        8. Use CREATE INDEX and CREATE TRIGGER to reconstruct indexes and triggers associated with table X.
        9. If any views refer to table X in a way that is affected by the schema change, then drop those views using DROP VIEW
       10. If foreign key constraints were originally enabled then run PRAGMA foreign_key_check
       11. Commit the transaction started in step 2.
       12. If foreign keys constraints were originally enabled, reenable them now.
*/
public class SchemaChanger: CustomStringConvertible {
    enum SchemaChangeError: LocalizedError {
        case foreignKeyError([ForeignKeyError])

        var errorDescription: String? {
            switch self {
            case .foreignKeyError(let errors):
                return "Foreign key errors: \(errors)"
            }
        }
    }

    public enum Operation {
        case none
        case add(ColumnDefinition)
        case remove(String)
        case renameColumn(String, String)
        case renameTable(String)

        /// Returns non-nil if the operation can be executed with a simple SQL statement
        func toSQL(_ table: String, version: SQLiteVersion) -> String? {
            switch self {
            case .add(let definition):
                return "ALTER TABLE \(table.quote()) ADD COLUMN \(definition.toSQL())"
            case .renameColumn(let from, let to) where version >= (3, 25, 0):
                return "ALTER TABLE \(table.quote()) RENAME COLUMN \(from.quote()) TO \(to.quote())"
            case .remove(let column) where version >= (3, 35, 0):
                return "ALTER TABLE \(table.quote()) DROP COLUMN \(column.quote())"
            default: return nil
            }
        }
    }

    public class AlterTableDefinition {
        fileprivate var operations: [Operation] = []

        let name: String

        init(name: String) {
            self.name = name
        }

        public func add(_ column: ColumnDefinition) {
            operations.append(.add(column))
        }

        public func remove(_ column: String) {
            operations.append(.remove(column))
        }

        public func rename(_ column: String, to: String) {
            operations.append(.renameColumn(column, to))
        }
    }

    private let connection: Connection
    private let version: SQLiteVersion
    static let tempPrefix = "tmp_"
    typealias Block = () throws -> Void
    public typealias AlterTableDefinitionBlock = (AlterTableDefinition) -> Void

    struct Options: OptionSet {
        let rawValue: Int
        static let `default`: Options = []
        static let temp = Options(rawValue: 1)
    }

    public convenience init(connection: Connection) {
        self.init(connection: connection,
                  version: connection.sqliteVersion)
    }

    init(connection: Connection, version: SQLiteVersion) {
        self.connection = connection
        self.version = version
    }

    public func alter(table: String, block: AlterTableDefinitionBlock) throws {
        let alterTableDefinition = AlterTableDefinition(name: table)
        block(alterTableDefinition)

        for operation in alterTableDefinition.operations {
            try run(table: table, operation: operation)
        }
    }

    public func drop(table: String) throws {
        try dropTable(table)
    }

    private func run(table: String, operation: Operation) throws {
        if let sql = operation.toSQL(table, version: version) {
            try connection.run(sql)
        } else {
            try doTheTableDance(table: table, operation: operation)
        }
    }

    private func doTheTableDance(table: String, operation: Operation) throws {
        try connection.transaction {
            try disableRefIntegrity {
                let tempTable = "\(SchemaChanger.tempPrefix)\(table)"
                try moveTable(from: table, to: tempTable, options: [.temp], operation: operation)
                try moveTable(from: tempTable, to: table)
                let foreignKeyErrors = try connection.foreignKeyCheck()
                if foreignKeyErrors.count > 0 {
                    throw SchemaChangeError.foreignKeyError(foreignKeyErrors)
                }
            }
        }
    }

    private func disableRefIntegrity(block: Block) throws {
        let oldForeignKeys = connection.foreignKeys
        let oldDeferForeignKeys = connection.deferForeignKeys

        connection.deferForeignKeys = true
        connection.foreignKeys = false

        defer {
            connection.deferForeignKeys = oldDeferForeignKeys
            connection.foreignKeys = oldForeignKeys
        }

        try block()
    }

    private func moveTable(from: String, to: String, options: Options = .default, operation: Operation = .none) throws {
        try copyTable(from: from, to: to, options: options, operation: operation)
        try dropTable(from)
    }

    private func copyTable(from: String, to: String, options: Options = .default, operation: Operation) throws {
        let fromDefinition = TableDefinition(
            name: from,
            columns: try connection.columnInfo(table: from),
            indexes: try connection.indexInfo(table: from)
        )
        let toDefinition   = fromDefinition.apply(.renameTable(to)).apply(operation)

        try createTable(definition: toDefinition, options: options)
        try createTableIndexes(definition: toDefinition)
        if case .remove = operation {
            try copyTableContents(from: fromDefinition.apply(operation), to: toDefinition)
        } else {
            try copyTableContents(from: fromDefinition, to: toDefinition)
        }
    }

    private func createTable(definition: TableDefinition, options: Options) throws {
        try connection.run(definition.toSQL(temporary: options.contains(.temp)))
    }

    private func createTableIndexes(definition: TableDefinition) throws {
        for index in definition.indexes {
            try index.validate()
            try connection.run(index.toSQL())
        }
    }

    private func dropTable(_ table: String) throws {
        try connection.run("DROP TABLE IF EXISTS \(table.quote())")
    }

    private func copyTableContents(from: TableDefinition, to: TableDefinition) throws {
        try connection.run(from.copySQL(to: to))
    }

    public var description: String {
        "SQLiteSchemaChanger: \(connection.description)"
    }
}

extension IndexDefinition {
    func renameTable(to: String) -> IndexDefinition {
        func indexName() -> String {
            if to.starts(with: SchemaChanger.tempPrefix) {
                return "\(SchemaChanger.tempPrefix)\(name)"
            } else if table.starts(with: SchemaChanger.tempPrefix) {
                return name.replacingOccurrences(of: SchemaChanger.tempPrefix, with: "")
            } else {
                return name
            }
        }
        return IndexDefinition(table: to, name: indexName(), unique: unique, columns: columns, where: `where`, orders: orders)
    }

    func renameColumn(from: String, to: String) -> IndexDefinition {
        IndexDefinition(table: table, name: name, unique: unique, columns: columns.map {
            $0 == from ? to : $0
        }, where: `where`, orders: orders)
    }
}

extension TableDefinition {
    func apply(_ operation: SchemaChanger.Operation) -> TableDefinition {
        switch operation {
        case .none: return self
        case .add: fatalError("Use 'ALTER TABLE ADD COLUMN (...)'")
        case .remove(let column):
            return TableDefinition(name: name,
                columns: columns.filter { $0.name != column },
                indexes: indexes.filter { !$0.columns.contains(column) }
            )
        case .renameColumn(let from, let to):
            return TableDefinition(
                name: name,
                columns: columns.map { $0.rename(from: from, to: to) },
                indexes: indexes.map { $0.renameColumn(from: from, to: to) }
        )
        case .renameTable(let to):
            return TableDefinition(name: to, columns: columns, indexes: indexes.map { $0.renameTable(to: to) })
        }
    }
}

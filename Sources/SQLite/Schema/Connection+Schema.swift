import Foundation

extension Connection {
    // https://sqlite.org/pragma.html#pragma_table_info
    //
    // This pragma returns one row for each column in the named table. Columns in the result set include the
    // column name, data type, whether or not the column can be NULL, and the default value for the column. The
    // "pk" column in the result set is zero for columns that are not part of the primary key, and is the
    // index of the column in the primary key for columns that are part of the primary key.
    func columnInfo(table: String) throws  -> [ColumnDefinition] {
        func parsePrimaryKey(column: String) throws -> ColumnDefinition.PrimaryKey? {
            try createTableSQL(name: table).flatMap { .init(sql: $0) }
        }

        let foreignKeys: [String: [ColumnDefinition.ForeignKey]] =
            Dictionary(grouping: try foreignKeyInfo(table: table), by: { $0.column })

        return try run("PRAGMA table_info(\(table.quote()))").compactMap { row -> ColumnDefinition? in
            guard let name = row[1] as? String,
                  let type = row[2] as? String,
                  let notNull = row[3] as? Int64,
                  let defaultValue = row[4] as? String?,
                  let primaryKey = row[5] as? Int64 else { return nil }
            return ColumnDefinition(name: name,
                                    primaryKey: primaryKey == 1 ? try parsePrimaryKey(column: name) : nil,
                                    type: ColumnDefinition.Affinity.from(type),
                                    null: notNull == 0,
                                    defaultValue: .from(defaultValue),
                                    references: foreignKeys[name]?.first)
        }
    }

    func indexInfo(table: String) throws -> [IndexDefinition] {
        func indexSQL(name: String) throws  -> String? {
            try run("""
                    SELECT sql FROM sqlite_master WHERE name=? AND type='index'
                      UNION ALL
                    SELECT sql FROM sqlite_temp_master WHERE name=? AND type='index'
                    """, name, name)
                    .compactMap { row in row[0] as? String }
                    .first
        }

        func columns(name: String) throws -> [String] {
            try run("PRAGMA index_info(\(name.quote()))").compactMap { row in
                row[2] as? String
            }
        }

        return try run("PRAGMA index_list(\(table.quote()))").compactMap { row -> IndexDefinition? in
            guard let name = row[1] as? String,
                  let unique = row[2] as? Int64,
                    // Indexes SQLite creates implicitly for internal use start with "sqlite_".
                    // See https://www.sqlite.org/fileformat2.html#intschema
                  !name.starts(with: "sqlite_") else {
                return nil
            }
            return .init(table: table,
                         name: name,
                         unique: unique == 1,
                         columns: try columns(name: name),
                         indexSQL: try indexSQL(name: name))
        }
    }

    func foreignKeyInfo(table: String) throws -> [ColumnDefinition.ForeignKey] {
        try run("PRAGMA foreign_key_list(\(table.quote()))").compactMap { row in
            if let table = row[2] as? String,      // table
               let column = row[3] as? String,     // from
               let primaryKey = row[4] as? String, // to
               let onUpdate = row[5] as? String,
               let onDelete = row[6] as? String {
                return .init(table: table, column: column, primaryKey: primaryKey,
                             onUpdate: onUpdate == TableBuilder.Dependency.noAction.rawValue ? nil : onUpdate,
                             onDelete: onDelete == TableBuilder.Dependency.noAction.rawValue ? nil : onDelete
                )
            } else {
                return nil
            }
        }
    }

    // https://sqlite.org/pragma.html#pragma_foreign_key_check

    // There are four columns in each result row.
    // The first column is the name of the table that
    // contains the REFERENCES clause.
    // The second column is the rowid of the row that contains the
    // invalid REFERENCES clause, or NULL if the child table is a WITHOUT ROWID table.
    // The third column is the name of the table that is referred to.
    // The fourth column is the index of the specific foreign key constraint that failed.
    func foreignKeyCheck() throws -> [ForeignKeyError] {
        try run("PRAGMA foreign_key_check").compactMap { row -> ForeignKeyError? in
            guard let table = row[0] as? String,
                  let rowId = row[1] as? Int64,
                  let target = row[2] as? String else { return nil }

            return ForeignKeyError(from: table, rowId: rowId, to: target)
        }
    }

    private func createTableSQL(name: String) throws  -> String? {
        try run("""
                SELECT sql FROM sqlite_master WHERE name=? AND type='table'
                  UNION ALL
                SELECT sql FROM sqlite_temp_master WHERE name=? AND type='table'
        """, name, name)
            .compactMap { row in row[0] as? String }
            .first
    }
}

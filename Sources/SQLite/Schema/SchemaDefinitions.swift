import Foundation

struct TableDefinition: Equatable {
    let name: String
    let columns: [ColumnDefinition]
    let indexes: [IndexDefinition]

    var quotedColumnList: String {
        columns.map { $0.name.quote() }.joined(separator: ", ")
    }
}

// https://sqlite.org/syntax/column-def.html
// column-name -> type-name -> column-constraint*
public struct ColumnDefinition: Equatable {

    // The type affinity of a column is the recommended type for data stored in that column.
    // The important idea here is that the type is recommended, not required. Any column can still
    // store any type of data. It is just that some columns, given the choice, will prefer to use one
    // storage class over another. The preferred storage class for a column is called its "affinity".
    public enum Affinity: String, CustomStringConvertible, CaseIterable {
        case INTEGER
        case NUMERIC
        case REAL
        case TEXT
        case BLOB

        public var description: String {
            rawValue
        }

        static func from(_ string: String) -> Affinity {
            Affinity.allCases.first { $0.rawValue.lowercased() == string.lowercased() } ?? TEXT
        }
    }

    public enum OnConflict: String, CaseIterable {
        case ROLLBACK
        case ABORT
        case FAIL
        case IGNORE
        case REPLACE

        static func from(_ string: String) -> OnConflict? {
            OnConflict.allCases.first { $0.rawValue == string }
        }
    }

    public struct PrimaryKey: Equatable {
        let autoIncrement: Bool
        let onConflict: OnConflict?

        // swiftlint:disable:next force_try
        static let pattern = try! NSRegularExpression(pattern: "PRIMARY KEY\\s*(?:ASC|DESC)?\\s*(?:ON CONFLICT (\\w+)?)?\\s*(AUTOINCREMENT)?")

        init(autoIncrement: Bool = true, onConflict: OnConflict? = nil) {
            self.autoIncrement = autoIncrement
            self.onConflict = onConflict
        }

        init?(sql: String) {
            if let match = PrimaryKey.pattern.firstMatch(in: sql, range: NSRange(location: 0, length: sql.count)) {
                let conflict = match.range(at: 1)
                var onConflict: ColumnDefinition.OnConflict?
                if conflict.location != NSNotFound {
                    onConflict = .from((sql as NSString).substring(with: conflict))
                }
                let autoIncrement = match.range(at: 2).location != NSNotFound
                self.init(autoIncrement: autoIncrement, onConflict: onConflict)
            } else {
                return nil
            }
        }
    }

    public struct ForeignKey: Equatable {
        let table: String
        let column: String
        let primaryKey: String
        let onUpdate: String?
        let onDelete: String?
    }

    public let name: String
    public let primaryKey: PrimaryKey?
    public let type: Affinity
    public let null: Bool
    public let defaultValue: LiteralValue
    public let references: ForeignKey?

    public init(name: String, primaryKey: PrimaryKey?, type: Affinity, null: Bool, defaultValue: LiteralValue,
                references: ForeignKey?) {
        self.name = name
        self.primaryKey = primaryKey
        self.type = type
        self.null = null
        self.defaultValue = defaultValue
        self.references = references
    }

    func rename(from: String, to: String) -> ColumnDefinition {
        guard from == name else { return self }
        return ColumnDefinition(name: to, primaryKey: primaryKey, type: type, null: null, defaultValue: defaultValue, references: references)
    }
}

public enum LiteralValue: Equatable, CustomStringConvertible {
    // swiftlint:disable force_try
    private static let singleQuote = try! NSRegularExpression(pattern: "^'(.*)'$")
    private static let doubleQuote = try! NSRegularExpression(pattern: "^\"(.*)\"$")
    private static let blob        = try! NSRegularExpression(pattern: "^[xX]\'(.*)\'$")
    // swiftlint:enable force_try

    case numericLiteral(String)
    case stringLiteral(String)
    // BLOB literals are string literals containing hexadecimal data and preceded by a single "x" or "X"
    // character. Example: X'53514C697465'
    case blobLiteral(String)

    // If there is no explicit DEFAULT clause attached to a column definition, then the default value of the
    // column is NULL
    // swiftlint:disable identifier_name
    case NULL

    // Beginning with SQLite 3.23.0 (2018-04-02), SQLite recognizes the identifiers "TRUE" and
    // "FALSE" as boolean literals, if and only if those identifiers are not already used for some other
    // meaning.
    //
    // The boolean identifiers TRUE and FALSE are usually just aliases for the integer values 1 and 0, respectively.
    case TRUE
    case FALSE
    case CURRENT_TIME
    case CURRENT_DATE
    case CURRENT_TIMESTAMP
    // swiftlint:enable identifier_name

    static func from(_ string: String?) -> LiteralValue {
        func parse(_ value: String) -> LiteralValue {
            if let match = singleQuote.firstMatch(in: value, range: NSRange(location: 0, length: value.count)) {
                return stringLiteral((value as NSString).substring(with: match.range(at: 1)).replacingOccurrences(of: "''", with: "'"))
            } else if let match = doubleQuote.firstMatch(in: value, range: NSRange(location: 0, length: value.count)) {
                return stringLiteral((value as NSString).substring(with: match.range(at: 1)).replacingOccurrences(of: "\"\"", with: "\""))
            } else if let match = blob.firstMatch(in: value, range: NSRange(location: 0, length: value.count)) {
                return blobLiteral((value as NSString).substring(with: match.range(at: 1)))
            } else {
                return numericLiteral(value)
            }
        }
        guard let string = string else { return NULL }

        switch string {
        case "NULL": return NULL
        case "TRUE": return TRUE
        case "FALSE": return FALSE
        case "CURRENT_TIME": return CURRENT_TIME
        case "CURRENT_TIMESTAMP": return CURRENT_TIMESTAMP
        case "CURRENT_DATE": return CURRENT_DATE
        default: return parse(string)
        }
    }

    public var description: String {
        switch self {
        case .NULL: return "NULL"
        case .TRUE: return "TRUE"
        case .FALSE: return "FALSE"
        case .CURRENT_TIMESTAMP: return "CURRENT_TIMESTAMP"
        case .CURRENT_TIME: return "CURRENT_TIME"
        case .CURRENT_DATE: return "CURRENT_DATE"
        case .stringLiteral(let value): return value.quote("'")
        case .blobLiteral(let value): return "X\(value.quote("'"))"
        case .numericLiteral(let value): return value
        }
    }

    func map<U>(block: (LiteralValue) -> U) -> U? {
        if self == .NULL {
            return nil
        } else {
            return block(self)
        }
    }
}

// https://sqlite.org/lang_createindex.html
// schema-name.index-name ON table-name ( indexed-column+ ) WHERE expr
public struct IndexDefinition: Equatable {
    // SQLite supports index names up to 64 characters.
    static let maxIndexLength = 64

    // swiftlint:disable force_try
    static let whereRe = try! NSRegularExpression(pattern: "\\sWHERE\\s+(.+)$")
    static let orderRe = try! NSRegularExpression(pattern: "\"?(\\w+)\"? DESC")
    // swiftlint:enable force_try

    public enum Order: String { case ASC, DESC }

    public init(table: String, name: String, unique: Bool = false, columns: [String], `where`: String? = nil, orders: [String: Order]? = nil) {
        self.table = table
        self.name = name
        self.unique = unique
        self.columns = columns
        self.where = `where`
        self.orders = orders
    }

    init (table: String, name: String, unique: Bool, columns: [String], indexSQL: String?) {
        func wherePart(sql: String) -> String? {
            IndexDefinition.whereRe.firstMatch(in: sql, options: [], range: NSRange(location: 0, length: sql.count)).map {
                (sql as NSString).substring(with: $0.range(at: 1))
            }
        }

        func orders(sql: String) -> [String: IndexDefinition.Order] {
            IndexDefinition.orderRe.matches(in: sql, range: NSRange(location: 0, length: sql.count))
                    .reduce([String: IndexDefinition.Order]()) { (memo, result) in
                        var memo2 = memo
                        let column = (sql as NSString).substring(with: result.range(at: 1))
                        memo2[column] = .DESC
                        return memo2
            }
        }
        self.init(table: table,
                  name: name,
                  unique: unique,
                  columns: columns,
                  where: indexSQL.flatMap(wherePart),
                  orders: indexSQL.flatMap(orders))
    }

    let table: String
    let name: String
    let unique: Bool
    let columns: [String]
    let `where`: String?
    let orders: [String: Order]?

    enum IndexError: LocalizedError {
        case tooLong(String, String)

        var errorDescription: String? {
            switch self {
            case .tooLong(let name, let table):
                return "Index name '\(name)' on table '\(table)' is too long; the limit is " +
                     "\(IndexDefinition.maxIndexLength) characters"
            }
        }
    }

    func validate() throws {
        if name.count > IndexDefinition.maxIndexLength {
            throw IndexError.tooLong(name, table)
        }
    }
}

struct ForeignKeyError: CustomStringConvertible {
    let from: String
    let rowId: Int64
    let to: String

    var description: String {
        "\(from) [\(rowId)] => \(to)"
    }
}

extension TableDefinition {
    func toSQL(temporary: Bool = false) -> String {
        assert(columns.count > 0, "no columns to create")

        return ([
            "CREATE",
            temporary ? "TEMPORARY" : nil,
            "TABLE",
            name,
            "(",
            columns.map { $0.toSQL() }.joined(separator: ",\n"),
            ")"
        ] as [String?]).compactMap { $0 }
         .joined(separator: " ")
    }

    func copySQL(to: TableDefinition) -> String {
        assert(columns.count > 0, "no columns to copy")
        assert(columns.count == to.columns.count, "column counts don't match")
        return "INSERT INTO \(to.name.quote()) (\(to.quotedColumnList)) SELECT \(quotedColumnList) FROM \(name.quote())"
    }
}

extension ColumnDefinition {
    func toSQL() -> String {
        [
            name.quote(),
            type.rawValue,
            defaultValue.map { "DEFAULT \($0)" },
            primaryKey.map { $0.toSQL() },
            null ? nil : "NOT NULL",
            references.map { $0.toSQL() }
        ].compactMap { $0 }
         .joined(separator: " ")
    }
}

extension IndexDefinition {
    public func toSQL(ifNotExists: Bool = false) -> String {
        let commaSeparatedColumns = columns.map { (column: String) -> String in
            column.quote() + (orders?[column].map { " \($0.rawValue)" } ?? "")
        }.joined(separator: ", ")

        return ([
            "CREATE",
            unique ? "UNIQUE" : nil,
            "INDEX",
            ifNotExists ? "IF NOT EXISTS" : nil,
            name.quote(),
            "ON",
            table.quote(),
            "(\(commaSeparatedColumns))",
            `where`.map { "WHERE \($0)" }
        ] as [String?]).compactMap { $0 }
         .joined(separator: " ")
    }
}

extension ColumnDefinition.ForeignKey {
    func toSQL() -> String {
        ([
            "REFERENCES",
            table.quote(),
            "(\(primaryKey.quote()))",
            onUpdate.map { "ON UPDATE \($0)" },
            onDelete.map { "ON DELETE \($0)" }
        ] as [String?]).compactMap { $0 }
         .joined(separator: " ")
    }
}

extension ColumnDefinition.PrimaryKey {
    func toSQL() -> String {
        [
            "PRIMARY KEY",
            autoIncrement ? "AUTOINCREMENT" : nil,
            onConflict.map { "ON CONFLICT \($0.rawValue)" }
        ].compactMap { $0 }.joined(separator: " ")
    }
}

//
// SQLite.swift
// https://github.com/stephencelis/SQLite.swift
// Copyright © 2014-2015 Stephen Celis.
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

extension Module {

    @warn_unused_result public static func FTS4(column: Expressible, _ more: Expressible...) -> Module {
        return FTS4([column] + more)
    }

    @warn_unused_result public static func FTS4(columns: [Expressible] = [], tokenize tokenizer: Tokenizer? = nil) -> Module {
        return FTS4(FTS4Config().columns(columns).tokenizer(tokenizer))
    }

    @warn_unused_result public static func FTS4(config: FTS4Config) -> Module {
        return Module(name: "fts4", arguments: config.arguments())
    }
}

extension VirtualTable {

    /// Builds an expression appended with a `MATCH` query against the given
    /// pattern.
    ///
    ///     let emails = VirtualTable("emails")
    ///
    ///     emails.filter(emails.match("Hello"))
    ///     // SELECT * FROM "emails" WHERE "emails" MATCH 'Hello'
    ///
    /// - Parameter pattern: A pattern to match.
    ///
    /// - Returns: An expression appended with a `MATCH` query against the given
    ///   pattern.
    @warn_unused_result public func match(pattern: String) -> Expression<Bool> {
        return "MATCH".infix(tableName(), pattern)
    }

    @warn_unused_result public func match(pattern: Expression<String>) -> Expression<Bool> {
        return "MATCH".infix(tableName(), pattern)
    }

    @warn_unused_result public func match(pattern: Expression<String?>) -> Expression<Bool?> {
        return "MATCH".infix(tableName(), pattern)
    }

    /// Builds a copy of the query with a `WHERE … MATCH` clause.
    ///
    ///     let emails = VirtualTable("emails")
    ///
    ///     emails.match("Hello")
    ///     // SELECT * FROM "emails" WHERE "emails" MATCH 'Hello'
    ///
    /// - Parameter pattern: A pattern to match.
    ///
    /// - Returns: A query with the given `WHERE … MATCH` clause applied.
    @warn_unused_result public func match(pattern: String) -> QueryType {
        return filter(match(pattern))
    }

    @warn_unused_result public func match(pattern: Expression<String>) -> QueryType {
        return filter(match(pattern))
    }

    @warn_unused_result public func match(pattern: Expression<String?>) -> QueryType {
        return filter(match(pattern))
    }

}

public struct Tokenizer {

    public static let Simple = Tokenizer("simple")

    public static let Porter = Tokenizer("porter")

    @warn_unused_result public static func Unicode61(removeDiacritics removeDiacritics: Bool? = nil, tokenchars: Set<Character> = [], separators: Set<Character> = []) -> Tokenizer {
        var arguments = [String]()

        if let removeDiacritics = removeDiacritics {
            arguments.append("removeDiacritics=\(removeDiacritics ? 1 : 0)".quote())
        }

        if !tokenchars.isEmpty {
            let joined = tokenchars.map { String($0) }.joinWithSeparator("")
            arguments.append("tokenchars=\(joined)".quote())
        }

        if !separators.isEmpty {
            let joined = separators.map { String($0) }.joinWithSeparator("")
            arguments.append("separators=\(joined)".quote())
        }

        return Tokenizer("unicode61", arguments)
    }

    @warn_unused_result public static func Custom(name: String) -> Tokenizer {
        return Tokenizer(Tokenizer.moduleName.quote(), [name.quote()])
    }

    public let name: String

    public let arguments: [String]

    private init(_ name: String, _ arguments: [String] = []) {
        self.name = name
        self.arguments = arguments
    }

    private static let moduleName = "SQLite.swift"

}

extension Tokenizer : CustomStringConvertible {

    public var description: String {
        return ([name] + arguments).joinWithSeparator(" ")
    }

}

extension Connection {

    public func registerTokenizer(submoduleName: String, next: String -> (String, Range<String.Index>)?) throws {
        try check(_SQLiteRegisterTokenizer(handle, Tokenizer.moduleName, submoduleName) { input, offset, length in
            let string = String.fromCString(input)!

            guard let (token, range) = next(string) else { return nil }

            let view = string.utf8
            offset.memory += string.substringToIndex(range.startIndex).utf8.count
            length.memory = Int32(range.startIndex.samePositionIn(view).distanceTo(range.endIndex.samePositionIn(view)))
            return token
        })
    }

}

/// Configuration options shared between the [FTS4](https://www.sqlite.org/fts3.html) and
/// [FTS5](https://www.sqlite.org/fts5.html) extensions.
public class FTSConfig {
    public enum ColumnOption {
        /// [The notindexed= option](https://www.sqlite.org/fts3.html#section_6_5)
        case unindexed
    }

    typealias ColumnDefinition = (Expressible, options: [ColumnOption])
    var columnDefinitions = [ColumnDefinition]()
    var tokenizer: Tokenizer?
    var prefixes = [Int]()
    var externalContentSchema: SchemaType?
    var isContentless: Bool = false

    /// Adds a column definition
    public func column(column: Expressible, _ options: [ColumnOption] = []) -> Self {
        self.columnDefinitions.append((column, options))
        return self
    }

    public func columns(columns: [Expressible]) -> Self {
        for column in columns {
            self.column(column)
        }
        return self
    }

    /// [Tokenizers](https://www.sqlite.org/fts3.html#tokenizer)
    public func tokenizer(tokenizer: Tokenizer?) -> Self {
        self.tokenizer = tokenizer
        return self
    }

    /// [The prefix= option](https://www.sqlite.org/fts3.html#section_6_6)
    public func prefix(prefix: [Int]) -> Self {
        self.prefixes += prefix
        return self
    }

    /// [The content= option](https://www.sqlite.org/fts3.html#section_6_2)
    public func externalContent(schema: SchemaType) -> Self {
        self.externalContentSchema = schema
        return self
    }

    /// [Contentless FTS4 Tables](https://www.sqlite.org/fts3.html#section_6_2_1)
    public func contentless() -> Self {
        self.isContentless = true
        return self
    }

    func formatColumnDefinitions() -> [Expressible] {
        return columnDefinitions.map { $0.0 }
    }

    func arguments() -> [Expressible] {
        return options().arguments
    }

    func options() -> Options {
        var options = Options()
        options.append(formatColumnDefinitions())
        if let tokenizer = tokenizer {
            options.append("tokenize", value: Expression<Void>(literal: tokenizer.description))
        }
        options.appendCommaSeparated("prefix", values:prefixes.sort().map { String($0) })
        if isContentless {
            options.append("content", value: "")
        } else if let externalContentSchema = externalContentSchema {
            options.append("content", value: externalContentSchema.tableName())
        }
        return options
    }

    struct Options {
        var arguments = [Expressible]()

        mutating func append(columns: [Expressible]) -> Options {
            arguments.appendContentsOf(columns)
            return self
        }

        mutating func appendCommaSeparated(key: String, values: [String]) -> Options {
            if values.isEmpty {
                return self
            } else {
                return append(key, value: values.joinWithSeparator(","))
            }
        }

        mutating func append(key: String, value: CustomStringConvertible?) -> Options {
            return append(key, value: value?.description)
        }

        mutating func append(key: String, value: String?) -> Options {
            return append(key, value: value.map { Expression<String>($0) })
        }

        mutating func append(key: String, value: Expressible?) -> Options {
            if let value = value {
                arguments.append("=".join([Expression<Void>(literal: key), value]))
            }
            return self
        }
    }
}

/// Configuration for the [FTS4](https://www.sqlite.org/fts3.html) extension.
public class FTS4Config : FTSConfig {
    /// [The matchinfo= option](https://www.sqlite.org/fts3.html#section_6_4)
    public enum MatchInfo : CustomStringConvertible {
        case FTS3
        public var description: String {
            return "fts3"
        }
    }

    /// [FTS4 options](https://www.sqlite.org/fts3.html#fts4_options)
    public enum Order : CustomStringConvertible {
        /// Data structures are optimized for returning results in ascending order by docid (default)
        case Asc
        /// FTS4 stores its data in such a way as to optimize returning results in descending order by docid.
        case Desc

        public var description: String {
            switch self {
            case Asc: return "asc"
            case Desc: return "desc"
            }
        }
    }

    var compressFunction: String?
    var uncompressFunction: String?
    var languageId: String?
    var matchInfo: MatchInfo?
    var order: Order?

    override public init() {
    }

    /// [The compress= and uncompress= options](https://www.sqlite.org/fts3.html#section_6_1)
    public func compress(functionName: String) -> Self {
        self.compressFunction = functionName
        return self
    }

    /// [The compress= and uncompress= options](https://www.sqlite.org/fts3.html#section_6_1)
    public func uncompress(functionName: String) -> Self {
        self.uncompressFunction = functionName
        return self
    }

    /// [The languageid= option](https://www.sqlite.org/fts3.html#section_6_3)
    public func languageId(columnName: String) -> Self {
        self.languageId = columnName
        return self
    }

    /// [The matchinfo= option](https://www.sqlite.org/fts3.html#section_6_4)
    public func matchInfo(matchInfo: MatchInfo) -> Self {
        self.matchInfo = matchInfo
        return self
    }

    /// [FTS4 options](https://www.sqlite.org/fts3.html#fts4_options)
    public func order(order: Order) -> Self {
        self.order = order
        return self
    }

    override func options() -> Options {
        var options = super.options()
        for (column, _) in (columnDefinitions.filter { $0.options.contains(.unindexed) }) {
            options.append("notindexed", value: column)
        }
        options.append("languageid", value: languageId)
        options.append("compress", value: compressFunction)
        options.append("uncompress", value: uncompressFunction)
        options.append("matchinfo", value: matchInfo)
        options.append("order", value: order)
        return options
    }
}

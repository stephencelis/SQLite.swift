//
// SQLite.Statement
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

private let SQLITE_STATIC = sqlite3_destructor_type(COpaquePointer(bitPattern: 0))
private let SQLITE_TRANSIENT = sqlite3_destructor_type(COpaquePointer(bitPattern: -1))

/// A single SQL statement.
public final class Statement {

    private let handle: COpaquePointer

    private var database: COpaquePointer { return sqlite3_db_handle(handle) }

    internal init(_ handle: COpaquePointer) { self.handle = handle }

    deinit { sqlite3_finalize(handle) }

    private lazy var columnNames: [String] = { [unowned self] in
        let count = sqlite3_column_count(self.handle)
        return (0..<count).map { String.fromCString(sqlite3_column_name(self.handle, $0))! }
    }()

    // MARK: - Binding

    /// Binds a list of parameters to a statement.
    ///
    /// :param: values A list of parameters to bind to the statement.
    ///
    /// :returns: The statement object (useful for chaining).
    public func bind(values: Datatype?...) -> Statement {
        return bind(values)
    }

    /// Binds a list of parameters to a statement.
    ///
    /// :param: values A list of parameters to bind to the statement.
    ///
    /// :returns: The statement object (useful for chaining).
    public func bind(values: [Datatype?]) -> Statement {
        if values.isEmpty { return self }
        reset()
        assert(values.count == Int(sqlite3_bind_parameter_count(handle)), "\(Int(sqlite3_bind_parameter_count(handle))) values expected, \(values.count) passed")
        for idx in 1...values.count { bind(values[idx - 1], atIndex: idx) }
        return self
    }

    /// Binds a dictionary of named parameters to a statement.
    ///
    /// :param: values A dictionary of named parameters to bind to the
    ///                statement.
    ///
    /// :returns: The statement object (useful for chaining).
    public func bind(values: [String: Datatype?]) -> Statement {
        reset()
        for (name, value) in values {
            let idx = sqlite3_bind_parameter_index(handle, name)
            assert(idx > 0, "parameter not found: \(name)")
            bind(value, atIndex: Int(idx))
        }
        return self
    }

    internal func bind(#bool: Bool, atIndex idx: Int) {
        bind(int: bool ? 1 : 0, atIndex: idx)
    }

    internal func bind(#double: Double, atIndex idx: Int) {
        try(sqlite3_bind_double(handle, Int32(idx), double))
    }

    internal func bind(#int: Int, atIndex idx: Int) {
        try(sqlite3_bind_int64(handle, Int32(idx), Int64(int)))
    }

    internal func bind(#text: String, atIndex idx: Int) {
        try(sqlite3_bind_text(handle, Int32(idx), text, -1, SQLITE_TRANSIENT))
    }

    private func bind(value: Datatype?, atIndex idx: Int) {
        if let datatype = value {
            datatype.bindTo(self, atIndex: idx)
        } else {
            try(sqlite3_bind_null(handle, Int32(idx)))
        }
    }

    // MARK: - Run

    /// :param: bindings A list of parameters to bind to the statement.
    ///
    /// :returns: The statement object (useful for chaining).
    public func run(bindings: Datatype?...) -> Statement {
        if !bindings.isEmpty { return run(bindings) }
        reset(clearBindings: false)
        for _ in self {}
        return self
    }

    /// :param: bindings A list of parameters to bind to the statement.
    ///
    /// :returns: The statement object (useful for chaining).
    public func run(bindings: [Datatype?]) -> Statement {
        return bind(bindings).run()
    }

    /// :param: bindings A dictionary of named parameters to bind to the
    ///                  statement.
    ///
    /// :returns: The statement object (useful for chaining).
    public func run(bindings: [String: Datatype?]) -> Statement {
        return bind(bindings).run()
    }

    // MARK: - Scalar

    /// :param: bindings A list of parameters to bind to the statement.
    ///
    /// :returns: The first value of the first row returned.
    public func scalar(bindings: Datatype?...) -> Datatype? {
        if !bindings.isEmpty { return scalar(bindings) }
        reset(clearBindings: false)
        let value: Datatype? = next()?[0]
        for _ in self {}
        return value
    }

    /// :param: bindings A list of parameters to bind to the statement.
    ///
    /// :returns: The first value of the first row returned.
    public func scalar(bindings: [Datatype?]) -> Datatype? {
        return bind(bindings).scalar()
    }

    /// :param: bindings A dictionary of named parameters to bind to the
    ///                  statement.
    ///
    /// :returns: The first value of the first row returned.
    public func scalar(bindings: [String: Datatype?]) -> Datatype? {
        return bind(bindings).scalar()
    }

    // MARK: -

    private func reset(clearBindings: Bool = true) {
        (status, reason) = (SQLITE_OK, nil)
        sqlite3_reset(handle)
        if (clearBindings) { sqlite3_clear_bindings(handle) }
    }

    // MARK: - Error Handling

    /// :returns: Whether or not a statement has produced an error.
    public var failed: Bool {
        return !(status == SQLITE_OK || status == SQLITE_ROW || status == SQLITE_DONE)
    }

    /// :returns: The reason for an error.
    public var reason: String?

    private var status: Int32 = SQLITE_OK

    private func try(block: @autoclosure () -> Int32) {
        if failed { return }
        status = block()
        if failed { reason = String.fromCString(sqlite3_errmsg(database)) }
    }

}

extension Statement: SequenceType {

    public typealias Generator = Statement

    public func generate() -> Generator { return self }

}

extension Statement: GeneratorType {

    /// A single row.
    public typealias Element = [Datatype?]

    /// :returns: The next row from the result set (or nil).
    public func next() -> Element? {
        if status == SQLITE_DONE { return nil }
        try(sqlite3_step(handle))
        return row
    }

    /// :returns: The current row of an open statement.
    public var row: Element? {
        if status != SQLITE_ROW { return nil }
        var row = Element()
        for idx in 0..<columnNames.count {
            switch sqlite3_column_type(handle, Int32(idx)) {
            case SQLITE_FLOAT:
                row.append(Double(sqlite3_column_double(handle, Int32(idx))))
            case SQLITE_INTEGER:
                let int = Int(sqlite3_column_int64(handle, Int32(idx)))
                var bool = false
                if let type = String.fromCString(sqlite3_column_decltype(handle, Int32(idx))) {
                    bool = type.hasPrefix("BOOL")
                }
                row.append(bool ? int != 0 : int)
            case SQLITE_NULL:
                row.append(nil)
            case SQLITE_TEXT:
                row.append(String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(handle, Int32(idx))))!)
            case let type:
                assertionFailure("unsupported column type: \(type)")
            }
        }
        return row
    }

    /// :returns: A dictionary of column name to row value.
    public var values: [String: Datatype?]? {
        if let row = row {
            var values = [String: Datatype?]()
            for idx in 0..<row.count { values[columnNames[idx]] = row[idx] }
            return values
        }
        return nil
    }

}

extension Statement: DebugPrintable {

    public var debugDescription: String {
        return "Statement(\"\(String.fromCString(sqlite3_sql(handle))!)\")"
    }

}

public func &&(lhs: Statement, rhs: @autoclosure () -> Statement) -> Statement {
    if lhs.status == SQLITE_OK { lhs.run() }
    return lhs.failed ? lhs : rhs()
}

public func ||(lhs: Statement, rhs: @autoclosure () -> Statement) -> Statement {
    if lhs.status == SQLITE_OK { lhs.run() }
    return lhs.failed ? rhs() : lhs
}

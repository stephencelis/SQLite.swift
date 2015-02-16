//
// SQLite.swift
// https://github.com/stephencelis/SQLite.swift
// Copyright (c) 2014-2015 Stephen Celis.
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

    /// Creates or redefines a custom SQL function.
    ///
    /// :param: function The name of the function to create or redefine.
    ///
    /// :param: block    A block of code to run when the function is called.
    ///                  The block is called with an array of raw SQL values
    ///                  mapped to the function's parameters and should return a
    ///                  raw SQL value (or nil).
    public func create(#function: String, _ block: [Binding?] -> Binding?) {
        try(SQLiteCreateFunction(handle, function) { context, argc, argv in
            let arguments: [Binding?] = map(0..<argc) { idx in
                let value = argv[Int(idx)]
                switch sqlite3_value_type(value) {
                case SQLITE_BLOB:
                    let bytes = sqlite3_value_blob(value)
                    let length = sqlite3_value_bytes(value)
                    return Blob(bytes: bytes, length: Int(length))
                case SQLITE_FLOAT:
                    return Double(sqlite3_value_double(value))
                case SQLITE_INTEGER:
                    return Int(sqlite3_value_int64(value))
                case SQLITE_NULL:
                    return nil
                case SQLITE_TEXT:
                    return String.fromCString(UnsafePointer(sqlite3_value_text(value)))!
                case let type:
                    assertionFailure("unsupported value type: \(type)")
                }
            }
            let result = block(arguments)
            if let result = result as? Blob {
                sqlite3_result_blob(context, result.bytes, Int32(result.length), nil)
            } else if let result = result as? Double {
                sqlite3_result_double(context, result)
            } else if let result = result as? Int {
                sqlite3_result_int64(context, Int64(result))
            } else if let result = result as? String {
                sqlite3_result_text(context, result, Int32(countElements(result)), SQLITE_TRANSIENT)
            } else if result == nil {
                sqlite3_result_null(context)
            } else {
                assertionFailure("unsupported result type: \(result)")
            }
        })
    }

    // MARK: - Type-Safe Function Creation Shims

    // MARK: 0 Arguments

    /// Creates or redefines a custom SQL function.
    ///
    /// :param: function The name of the function to create or redefine.
    ///
    /// :param: block    A block of code to run when the function is called.
    ///                  The assigned types must be explicit.
    ///
    /// :returns: A closure returning a SQL expression to call the function.
    public func create<Z: Value>(#function: String, _ block: () -> Z) -> (() -> Expression<Z>) {
        return { self.create(function) { _ in return block() }([]) }
    }

    public func create<Z: Value>(#function: String, _ block: () -> Z?) -> (() -> Expression<Z?>) {
        return { self.create(function) { _ in return block() }([]) }
    }

    // MARK: 1 Argument

    public func create<Z: Value, A: Value>(#function: String, _ block: A -> Z) -> (Expression<A> -> Expression<Z>) {
        return { self.create(function) { block(asValue($0[0])) }([$0]) }
    }

    public func create<Z: Value, A: Value>(#function: String, _ block: A? -> Z) -> (Expression<A?> -> Expression<Z>) {
        return { self.create(function) { block($0[0].map(asValue)) }([$0]) }
    }

    public func create<Z: Value, A: Value>(#function: String, _ block: A -> Z?) -> (Expression<A> -> Expression<Z?>) {
        return { self.create(function) { block(asValue($0[0])) }([$0]) }
    }

    public func create<Z: Value, A: Value>(#function: String, _ block: A? -> Z?) -> (Expression<A?> -> Expression<Z?>) {
        return { self.create(function) { block($0[0].map(asValue)) }([$0]) }
    }

    // MARK: 2 Arguments

    public func create<Z: Value, A: protocol<Value, Expressible>, B: Value>(#function: String, _ block: (A, B) -> Z) -> ((A, Expression<B>) -> Expression<Z>) {
        return { self.create(function) { block(asValue($0[0]), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: protocol<Value, Expressible>, B: Value>(#function: String, _ block: (A?, B) -> Z) -> ((A?, Expression<B>) -> Expression<Z>) {
        return { self.create(function) { block($0[0].map(asValue), asValue($0[1])) }([Expression<A?>(value: $0), $1]) }
    }

    public func create<Z: Value, A: protocol<Value, Expressible>, B: Value>(#function: String, _ block: (A, B?) -> Z) -> ((A, Expression<B?>) -> Expression<Z>) {
        return { self.create(function) { block(asValue($0[0]), $0[1].map(asValue)) }([$0, $1]) }
    }

    public func create<Z: Value, A: protocol<Value, Expressible>, B: Value>(#function: String, _ block: (A?, B?) -> Z) -> ((A?, Expression<B?>) -> Expression<Z>) {
        return { self.create(function) { block($0[0].map(asValue), $0[1].map(asValue)) }([Expression<A?>(value: $0), $1]) }
    }

    public func create<Z: Value, A: protocol<Value, Expressible>, B: Value>(#function: String, _ block: (A, B) -> Z?) -> ((A, Expression<B>) -> Expression<Z?>) {
        return { self.create(function) { block(asValue($0[0]), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: protocol<Value, Expressible>, B: Value>(#function: String, _ block: (A?, B) -> Z?) -> ((A?, Expression<B>) -> Expression<Z?>) {
        return { self.create(function) { block($0[0].map(asValue), asValue($0[1])) }([Expression<A?>(value: $0), $1]) }
    }

    public func create<Z: Value, A: protocol<Value, Expressible>, B: Value>(#function: String, _ block: (A, B?) -> Z?) -> ((A, Expression<B?>) -> Expression<Z?>) {
        return { self.create(function) { block(asValue($0[0]), $0[1].map(asValue)) }([$0, $1]) }
    }

    public func create<Z: Value, A: protocol<Value, Expressible>, B: Value>(#function: String, _ block: (A?, B?) -> Z?) -> ((A?, Expression<B?>) -> Expression<Z?>) {
        return { self.create(function) { block($0[0].map(asValue), $0[1].map(asValue)) }([Expression<A?>(value: $0), $1]) }
    }

    public func create<Z: Value, A: Value, B: Value>(#function: String, _ block: (A, B) -> Z) -> ((Expression<A>, Expression<B>) -> Expression<Z>) {
        return { self.create(function) { block(asValue($0[0]), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: Value>(#function: String, _ block: (A?, B) -> Z) -> ((Expression<A?>, Expression<B>) -> Expression<Z>) {
        return { self.create(function) { block($0[0].map(asValue), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: Value>(#function: String, _ block: (A, B?) -> Z) -> ((Expression<A>, Expression<B?>) -> Expression<Z>) {
        return { self.create(function) { block(asValue($0[0]), $0[1].map(asValue)) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: Value>(#function: String, _ block: (A?, B?) -> Z) -> ((Expression<A?>, Expression<B?>) -> Expression<Z>) {
        return { self.create(function) { block($0[0].map(asValue), $0[1].map(asValue)) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: Value>(#function: String, _ block: (A, B) -> Z?) -> ((Expression<A>, Expression<B>) -> Expression<Z?>) {
        return { self.create(function) { block(asValue($0[0]), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: Value>(#function: String, _ block: (A?, B) -> Z?) -> ((Expression<A?>, Expression<B>) -> Expression<Z?>) {
        return { self.create(function) { block($0[0].map(asValue), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: Value>(#function: String, _ block: (A, B?) -> Z?) -> ((Expression<A>, Expression<B?>) -> Expression<Z?>) {
        return { self.create(function) { block(asValue($0[0]), $0[1].map(asValue)) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: Value>(#function: String, _ block: (A?, B?) -> Z?) -> ((Expression<A?>, Expression<B?>) -> Expression<Z?>) {
        return { self.create(function) { block($0[0].map(asValue), $0[1].map(asValue)) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: protocol<Value, Expressible>>(#function: String, _ block: (A, B) -> Z) -> ((Expression<A>, B) -> Expression<Z>) {
        return { self.create(function) { block(asValue($0[0]), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: protocol<Value, Expressible>>(#function: String, _ block: (A?, B) -> Z) -> ((Expression<A?>, B) -> Expression<Z>) {
        return { self.create(function) { block($0[0].map(asValue), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: protocol<Value, Expressible>>(#function: String, _ block: (A, B?) -> Z) -> ((Expression<A>, B?) -> Expression<Z>) {
        return { self.create(function) { block(asValue($0[0]), $0[1].map(asValue)) }([$0, Expression<B?>(value: $1)]) }
    }

    public func create<Z: Value, A: Value, B: protocol<Value, Expressible>>(#function: String, _ block: (A?, B?) -> Z) -> ((Expression<A?>, B?) -> Expression<Z>) {
        return { self.create(function) { block($0[0].map(asValue), $0[1].map(asValue)) }([$0, Expression<B?>(value: $1)]) }
    }

    public func create<Z: Value, A: Value, B: protocol<Value, Expressible>>(#function: String, _ block: (A, B) -> Z?) -> ((Expression<A>, B) -> Expression<Z?>) {
        return { self.create(function) { block(asValue($0[0]), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: protocol<Value, Expressible>>(#function: String, _ block: (A?, B) -> Z?) -> ((Expression<A?>, B) -> Expression<Z?>) {
        return { self.create(function) { block($0[0].map(asValue), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: protocol<Value, Expressible>>(#function: String, _ block: (A, B?) -> Z?) -> ((Expression<A>, B?) -> Expression<Z?>) {
        return { self.create(function) { block(asValue($0[0]), $0[1].map(asValue)) }([$0, Expression<B?>(value: $1)]) }
    }

    public func create<Z: Value, A: Value, B: protocol<Value, Expressible>>(#function: String, _ block: (A?, B?) -> Z?) -> ((Expression<A?>, B?) -> Expression<Z?>) {
        return { self.create(function) { block($0[0].map(asValue), $0[1].map(asValue)) }([$0, Expression<B?>(value: $1)]) }
    }

    // MARK: -

    private func create<Z: Value>(function: String, _ block: [Binding?] -> Z) -> ([Expressible] -> Expression<Z>) {
        return { Expression<Z>(self.create(function) { (arguments: [Binding?]) -> Z? in block(arguments) }($0)) }
    }

    private func create<Z: Value>(function: String, _ block: [Binding?] -> Z?) -> ([Expressible] -> Expression<Z?>) {
        create(function: function) { block($0)?.datatypeValue }
        return { arguments in wrap(function, Expression<Z>.join(", ", arguments)) }
    }

}

private func asValue<A: Value>(value: Binding?) -> A {
    return A.fromDatatypeValue(value as A.Datatype) as A
}

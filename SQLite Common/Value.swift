//
// SQLite.Value
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

public protocol Value {

    class var datatype: String { get }

    func bindTo(statement: Statement, atIndex idx: Int)

}

public protocol Number: Value {}

extension Bool: Value {

    public static var datatype: String { return "BOOLEAN" }

    public func bindTo(statement: Statement, atIndex idx: Int) {
        statement.bind(bool: self, atIndex: idx)
    }

}

extension Double: Number {

    public static var datatype: String { return "REAL" }

    public func bindTo(statement: Statement, atIndex idx: Int) {
        statement.bind(double: self, atIndex: idx)
    }

}

extension Int: Number {

    public static var datatype: String { return "INTEGER" }

    public func bindTo(statement: Statement, atIndex idx: Int) {
        statement.bind(int: self, atIndex: idx)
    }

}

extension String: Value {

    public static var datatype: String { return "TEXT" }

    public func bindTo(statement: Statement, atIndex idx: Int) {
        statement.bind(text: self, atIndex: idx)
    }

}

//
// SQLite.Expression
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

public struct Expression<T> {

    public let SQL: String
    public let bindings: [Binding?]

    public init(_ SQL: String = "", _ bindings: [Binding?] = []) {
        (self.SQL, self.bindings) = (SQL, bindings)
    }

    public init<V>(_ expression: Expression<V>) {
        self.init(expression.SQL, expression.bindings)
    }

    public init(value: Binding?) {
        self.init("?", [value])
    }

    public var asc: Expression<()> {
        return join(" ", [self, Expression("ASC")])
    }

    public var desc: Expression<()> {
        return join(" ", [self, Expression("DESC")])
    }

    // naïve compiler for statements that can't be bound, e.g., CREATE TABLE
    internal func compile() -> String {
        var idx = 0
        return Array(SQL).reduce("") { SQL, character in
            let string = String(character)
            return SQL + (string == "?" ? transcode(self.bindings[idx++]) : string)
        }
    }

}

public protocol Expressible {

    var expression: Expression<()> { get }

}

extension Bool: Expressible {

    public var expression: Expression<()> {
        return Expression(value: self)
    }

}

extension Double: Expressible {

    public var expression: Expression<()> {
        return Expression(value: self)
    }

}

extension Int: Expressible {

    public var expression: Expression<()> {
        return Expression(value: self)
    }

}

extension String: Expressible {

    public var expression: Expression<()> {
        return Expression(value: self)
    }

}

extension Expression: Expressible {

    public var expression: Expression<()> {
        return Expression<()>(self)
    }

}

// MARK: - Expressions

public func +(lhs: Expression<String>, rhs: Expression<String>) -> Expression<String> { return infix("||", lhs, rhs) }
public func +(lhs: Expression<String>, rhs: Expression<String?>) -> Expression<String?> { return infix("||", lhs, rhs) }
public func +(lhs: Expression<String?>, rhs: Expression<String>) -> Expression<String?> { return infix("||", lhs, rhs) }
public func +(lhs: Expression<String?>, rhs: Expression<String?>) -> Expression<String?> { return infix("||", lhs, rhs) }
public func +(lhs: Expression<String>, rhs: String) -> Expression<String> { return lhs + Expression(value: rhs) }
public func +(lhs: Expression<String?>, rhs: String) -> Expression<String?> { return lhs + Expression(value: rhs) }
public func +(lhs: String, rhs: Expression<String>) -> Expression<String> { return Expression(value: lhs) + rhs }
public func +(lhs: String, rhs: Expression<String?>) -> Expression<String?> { return Expression(value: lhs) + rhs }

public func +<V: Number>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> { return infix(__FUNCTION__, lhs, rhs) }
public func +<V: Number>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func +<V: Number>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func +<V: Number>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func +<V: Number>(lhs: Expression<V>, rhs: V) -> Expression<V> { return lhs + Expression(value: rhs) }
public func +<V: Number>(lhs: Expression<V?>, rhs: V) -> Expression<V?> { return lhs + Expression(value: rhs) }
public func +<V: Number>(lhs: V, rhs: Expression<V>) -> Expression<V> { return Expression(value: lhs) + rhs }
public func +<V: Number>(lhs: V, rhs: Expression<V?>) -> Expression<V?> { return Expression(value: lhs) + rhs }

public func -<V: Number>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> { return infix(__FUNCTION__, lhs, rhs) }
public func -<V: Number>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func -<V: Number>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func -<V: Number>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func -<V: Number>(lhs: Expression<V>, rhs: V) -> Expression<V> { return lhs - Expression(value: rhs) }
public func -<V: Number>(lhs: Expression<V?>, rhs: V) -> Expression<V?> { return lhs - Expression(value: rhs) }
public func -<V: Number>(lhs: V, rhs: Expression<V>) -> Expression<V> { return Expression(value: lhs) - rhs }
public func -<V: Number>(lhs: V, rhs: Expression<V?>) -> Expression<V?> { return Expression(value: lhs) - rhs }

public func *<V: Number>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> { return infix(__FUNCTION__, lhs, rhs) }
public func *<V: Number>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func *<V: Number>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func *<V: Number>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func *<V: Number>(lhs: Expression<V>, rhs: V) -> Expression<V> { return lhs * Expression(value: rhs) }
public func *<V: Number>(lhs: Expression<V?>, rhs: V) -> Expression<V?> { return lhs * Expression(value: rhs) }
public func *<V: Number>(lhs: V, rhs: Expression<V>) -> Expression<V> { return Expression(value: lhs) * rhs }
public func *<V: Number>(lhs: V, rhs: Expression<V?>) -> Expression<V?> { return Expression(value: lhs) * rhs }

public func /<V: Number>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> { return infix(__FUNCTION__, lhs, rhs) }
public func /<V: Number>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func /<V: Number>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func /<V: Number>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func /<V: Number>(lhs: Expression<V>, rhs: V) -> Expression<V> { return lhs / Expression(value: rhs) }
public func /<V: Number>(lhs: Expression<V?>, rhs: V) -> Expression<V?> { return lhs / Expression(value: rhs) }
public func /<V: Number>(lhs: V, rhs: Expression<V>) -> Expression<V> { return Expression(value: lhs) / rhs }
public func /<V: Number>(lhs: V, rhs: Expression<V?>) -> Expression<V?> { return Expression(value: lhs) / rhs }

public func %(lhs: Expression<Int>, rhs: Expression<Int>) -> Expression<Int> { return infix(__FUNCTION__, lhs, rhs) }
public func %(lhs: Expression<Int>, rhs: Expression<Int?>) -> Expression<Int?> { return infix(__FUNCTION__, lhs, rhs) }
public func %(lhs: Expression<Int?>, rhs: Expression<Int>) -> Expression<Int?> { return infix(__FUNCTION__, lhs, rhs) }
public func %(lhs: Expression<Int?>, rhs: Expression<Int?>) -> Expression<Int?> { return infix(__FUNCTION__, lhs, rhs) }
public func %(lhs: Expression<Int>, rhs: Int) -> Expression<Int> { return lhs % Expression(value: rhs) }
public func %(lhs: Expression<Int?>, rhs: Int) -> Expression<Int?> { return lhs % Expression(value: rhs) }
public func %(lhs: Int, rhs: Expression<Int>) -> Expression<Int> { return Expression(value: lhs) % rhs }
public func %(lhs: Int, rhs: Expression<Int?>) -> Expression<Int?> { return Expression(value: lhs) % rhs }

public func <<(lhs: Expression<Int>, rhs: Expression<Int>) -> Expression<Int> { return infix(__FUNCTION__, lhs, rhs) }
public func <<(lhs: Expression<Int>, rhs: Expression<Int?>) -> Expression<Int?> { return infix(__FUNCTION__, lhs, rhs) }
public func <<(lhs: Expression<Int?>, rhs: Expression<Int>) -> Expression<Int?> { return infix(__FUNCTION__, lhs, rhs) }
public func <<(lhs: Expression<Int?>, rhs: Expression<Int?>) -> Expression<Int?> { return infix(__FUNCTION__, lhs, rhs) }
public func <<(lhs: Expression<Int>, rhs: Int) -> Expression<Int> { return lhs << Expression(value: rhs) }
public func <<(lhs: Expression<Int?>, rhs: Int) -> Expression<Int?> { return lhs << Expression(value: rhs) }
public func <<(lhs: Int, rhs: Expression<Int>) -> Expression<Int> { return Expression(value: lhs) << rhs }
public func <<(lhs: Int, rhs: Expression<Int?>) -> Expression<Int?> { return Expression(value: lhs) << rhs }

public func >>(lhs: Expression<Int>, rhs: Expression<Int>) -> Expression<Int> { return infix(__FUNCTION__, lhs, rhs) }
public func >>(lhs: Expression<Int>, rhs: Expression<Int?>) -> Expression<Int?> { return infix(__FUNCTION__, lhs, rhs) }
public func >>(lhs: Expression<Int?>, rhs: Expression<Int>) -> Expression<Int?> { return infix(__FUNCTION__, lhs, rhs) }
public func >>(lhs: Expression<Int?>, rhs: Expression<Int?>) -> Expression<Int?> { return infix(__FUNCTION__, lhs, rhs) }
public func >>(lhs: Expression<Int>, rhs: Int) -> Expression<Int> { return lhs >> Expression(value: rhs) }
public func >>(lhs: Expression<Int?>, rhs: Int) -> Expression<Int?> { return lhs >> Expression(value: rhs) }
public func >>(lhs: Int, rhs: Expression<Int>) -> Expression<Int> { return Expression(value: lhs) >> rhs }
public func >>(lhs: Int, rhs: Expression<Int?>) -> Expression<Int?> { return Expression(value: lhs) >> rhs }

public func &(lhs: Expression<Int>, rhs: Expression<Int>) -> Expression<Int> { return infix(__FUNCTION__, lhs, rhs) }
public func &(lhs: Expression<Int>, rhs: Expression<Int?>) -> Expression<Int?> { return infix(__FUNCTION__, lhs, rhs) }
public func &(lhs: Expression<Int?>, rhs: Expression<Int>) -> Expression<Int?> { return infix(__FUNCTION__, lhs, rhs) }
public func &(lhs: Expression<Int?>, rhs: Expression<Int?>) -> Expression<Int?> { return infix(__FUNCTION__, lhs, rhs) }
public func &(lhs: Expression<Int>, rhs: Int) -> Expression<Int> { return lhs & Expression(value: rhs) }
public func &(lhs: Expression<Int?>, rhs: Int) -> Expression<Int?> { return lhs & Expression(value: rhs) }
public func &(lhs: Int, rhs: Expression<Int>) -> Expression<Int> { return Expression(value: lhs) & rhs }
public func &(lhs: Int, rhs: Expression<Int?>) -> Expression<Int?> { return Expression(value: lhs) & rhs }

public func |(lhs: Expression<Int>, rhs: Expression<Int>) -> Expression<Int> { return infix(__FUNCTION__, lhs, rhs) }
public func |(lhs: Expression<Int>, rhs: Expression<Int?>) -> Expression<Int?> { return infix(__FUNCTION__, lhs, rhs) }
public func |(lhs: Expression<Int?>, rhs: Expression<Int>) -> Expression<Int?> { return infix(__FUNCTION__, lhs, rhs) }
public func |(lhs: Expression<Int?>, rhs: Expression<Int?>) -> Expression<Int?> { return infix(__FUNCTION__, lhs, rhs) }
public func |(lhs: Expression<Int>, rhs: Int) -> Expression<Int> { return lhs | Expression(value: rhs) }
public func |(lhs: Expression<Int?>, rhs: Int) -> Expression<Int?> { return lhs | Expression(value: rhs) }
public func |(lhs: Int, rhs: Expression<Int>) -> Expression<Int> { return Expression(value: lhs) | rhs }
public func |(lhs: Int, rhs: Expression<Int?>) -> Expression<Int?> { return Expression(value: lhs) | rhs }

public func ^(lhs: Expression<Int>, rhs: Expression<Int>) -> Expression<Int> { return (~(lhs & rhs)) & (lhs | rhs) }
public func ^(lhs: Expression<Int>, rhs: Expression<Int?>) -> Expression<Int?> { return (~(lhs & rhs)) & (lhs | rhs) }
public func ^(lhs: Expression<Int?>, rhs: Expression<Int>) -> Expression<Int?> { return (~(lhs & rhs)) & (lhs | rhs) }
public func ^(lhs: Expression<Int?>, rhs: Expression<Int?>) -> Expression<Int?> { return (~(lhs & rhs)) & (lhs | rhs) }
public func ^(lhs: Expression<Int>, rhs: Int) -> Expression<Int> { return lhs ^ Expression(value: rhs) }
public func ^(lhs: Expression<Int?>, rhs: Int) -> Expression<Int?> { return lhs ^ Expression(value: rhs) }
public func ^(lhs: Int, rhs: Expression<Int>) -> Expression<Int> { return Expression(value: lhs) ^ rhs }
public func ^(lhs: Int, rhs: Expression<Int?>) -> Expression<Int?> { return Expression(value: lhs) ^ rhs }

public prefix func ~(rhs: Expression<Int>) -> Expression<Int> { return wrap(__FUNCTION__, rhs) }
public prefix func ~(rhs: Expression<Int?>) -> Expression<Int?> { return wrap(__FUNCTION__, rhs) }

public enum Collation: String {

    case Binary = "BINARY"

    case NoCase = "NOCASE"

    case RTrim = "RTRIM"

}

public func collate(collation: Collation, expression: Expression<String>) -> Expression<String> {
    return infix("COLLATE", expression, Expression<String>(collation.rawValue))
}
public func collate(collation: Collation, expression: Expression<String?>) -> Expression<String?> {
    return infix("COLLATE", expression, Expression<String>(collation.rawValue))
}

// MARK: - Predicates

public func ==<V: Value where V.Datatype: Binding>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> {
    return infix("=", lhs, rhs)
}
public func ==<V: Value where V.Datatype: Binding>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix("=", lhs, rhs)
}
public func ==<V: Value where V.Datatype: Binding>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> {
    return infix("=", lhs, rhs)
}
public func ==<V: Value where V.Datatype: Binding>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix("=", lhs, rhs)
}
public func ==<V: Value where V.Datatype: Binding>(lhs: Expression<V>, rhs: V) -> Expression<Bool> {
    return lhs == Expression(value: rhs.datatypeValue)
}
public func ==<V: Value where V.Datatype: Binding>(lhs: Expression<V?>, rhs: V?) -> Expression<Bool?> {
    if let rhs = rhs { return lhs == Expression(value: rhs.datatypeValue) }
    return Expression("\(lhs.SQL) IS ?", lhs.bindings + [nil])
}
public func ==<V: Value where V.Datatype: Binding>(lhs: V, rhs: Expression<V>) -> Expression<Bool> {
    return Expression(value: lhs.datatypeValue) == rhs
}
public func ==<V: Value where V.Datatype: Binding>(lhs: V?, rhs: Expression<V?>) -> Expression<Bool?> {
    if let lhs = lhs { return Expression(value: lhs.datatypeValue) == rhs }
    return Expression("? IS \(rhs.SQL)", [nil] + rhs.bindings)
}

public func !=<V: Value where V.Datatype: Binding>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func !=<V: Value where V.Datatype: Binding>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func !=<V: Value where V.Datatype: Binding>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func !=<V: Value where V.Datatype: Binding>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func !=<V: Value where V.Datatype: Binding>(lhs: Expression<V>, rhs: V) -> Expression<Bool> {
    return lhs != Expression(value: rhs.datatypeValue)
}
public func !=<V: Value where V.Datatype: Binding>(lhs: Expression<V?>, rhs: V?) -> Expression<Bool?> {
    if let rhs = rhs { return lhs != Expression(value: rhs.datatypeValue) }
    return Expression("\(lhs.SQL) IS NOT ?", lhs.bindings + [nil])
}
public func !=<V: Value where V.Datatype: Binding>(lhs: V, rhs: Expression<V>) -> Expression<Bool> {
    return Expression(value: lhs.datatypeValue) != rhs
}
public func !=<V: Value where V.Datatype: Binding>(lhs: V?, rhs: Expression<V?>) -> Expression<Bool?> {
    if let lhs = lhs { return Expression(value: lhs.datatypeValue) != rhs }
    return Expression("? IS NOT \(rhs.SQL)", [nil] + rhs.bindings)
}

public func ><V: Value where V.Datatype: Binding>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func ><V: Value where V.Datatype: Binding>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func ><V: Value where V.Datatype: Binding>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func ><V: Value where V.Datatype: Binding>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func ><V: Value where V.Datatype: Binding>(lhs: Expression<V>, rhs: V) -> Expression<Bool> {
    return lhs > Expression(value: rhs.datatypeValue)
}
public func ><V: Value where V.Datatype: Binding>(lhs: Expression<V?>, rhs: V) -> Expression<Bool?> {
    return lhs > Expression(value: rhs.datatypeValue)
}
public func ><V: Value where V.Datatype: Binding>(lhs: V, rhs: Expression<V>) -> Expression<Bool> {
    return Expression(value: lhs.datatypeValue) > rhs
}
public func ><V: Value where V.Datatype: Binding>(lhs: V, rhs: Expression<V?>) -> Expression<Bool?> {
    return Expression(value: lhs.datatypeValue) > rhs
}

public func >=<V: Value where V.Datatype: Binding>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func >=<V: Value where V.Datatype: Binding>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func >=<V: Value where V.Datatype: Binding>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func >=<V: Value where V.Datatype: Binding>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func >=<V: Value where V.Datatype: Binding>(lhs: Expression<V>, rhs: V) -> Expression<Bool> {
    return lhs >= Expression(value: rhs.datatypeValue)
}
public func >=<V: Value where V.Datatype: Binding>(lhs: Expression<V?>, rhs: V) -> Expression<Bool?> {
    return lhs >= Expression(value: rhs.datatypeValue)
}
public func >=<V: Value where V.Datatype: Binding>(lhs: V, rhs: Expression<V>) -> Expression<Bool> {
    return Expression(value: lhs.datatypeValue) >= rhs
}
public func >=<V: Value where V.Datatype: Binding>(lhs: V, rhs: Expression<V?>) -> Expression<Bool?> {
    return Expression(value: lhs.datatypeValue) >= rhs
}

public func <<V: Value where V.Datatype: Binding>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func <<V: Value where V.Datatype: Binding>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func <<V: Value where V.Datatype: Binding>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func <<V: Value where V.Datatype: Binding>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func <<V: Value where V.Datatype: Binding>(lhs: Expression<V>, rhs: V) -> Expression<Bool> {
    return lhs < Expression(value: rhs.datatypeValue)
}
public func <<V: Value where V.Datatype: Binding>(lhs: Expression<V?>, rhs: V) -> Expression<Bool?> {
    return lhs < Expression(value: rhs.datatypeValue)
}
public func <<V: Value where V.Datatype: Binding>(lhs: V, rhs: Expression<V>) -> Expression<Bool> {
    return Expression(value: lhs.datatypeValue) < rhs
}
public func <<V: Value where V.Datatype: Binding>(lhs: V, rhs: Expression<V?>) -> Expression<Bool?> {
    return Expression(value: lhs.datatypeValue) < rhs
}

public func <=<V: Value where V.Datatype: Binding>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func <=<V: Value where V.Datatype: Binding>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func <=<V: Value where V.Datatype: Binding>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func <=<V: Value where V.Datatype: Binding>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func <=<V: Value where V.Datatype: Binding>(lhs: Expression<V>, rhs: V) -> Expression<Bool> {
    return lhs <= Expression(value: rhs.datatypeValue)
}
public func <=<V: Value where V.Datatype: Binding>(lhs: Expression<V?>, rhs: V) -> Expression<Bool?> {
    return lhs <= Expression(value: rhs.datatypeValue)
}
public func <=<V: Value where V.Datatype: Binding>(lhs: V, rhs: Expression<V>) -> Expression<Bool> {
    return Expression(value: lhs.datatypeValue) <= rhs
}
public func <=<V: Value where V.Datatype: Binding>(lhs: V, rhs: Expression<V?>) -> Expression<Bool?> {
    return Expression(value: lhs.datatypeValue) <= rhs
}

public prefix func -<V: Number>(rhs: Expression<V>) -> Expression<V> { return wrap(__FUNCTION__, rhs) }
public prefix func -<V: Number>(rhs: Expression<V?>) -> Expression<V?> { return wrap(__FUNCTION__, rhs) }

public func ~=<I: IntervalType, V: Value where V: Binding, V == I.Bound>(lhs: I, rhs: Expression<V>) -> Expression<Bool> {
    return Expression("\(rhs.SQL) BETWEEN ? AND ?", rhs.bindings + [lhs.start, lhs.end])
}
public func ~=<I: IntervalType, V: Value where V: Binding, V == I.Bound>(lhs: I, rhs: Expression<V?>) -> Expression<Bool?> {
    return Expression<Bool?>(lhs ~= Expression<V>(rhs))
}

// MARK: Operators

public func like(string: String, expression: Expression<String>) -> Expression<Bool> {
    return infix("LIKE", expression, Expression<String>(value: string))
}
public func like(string: String, expression: Expression<String?>) -> Expression<Bool?> {
    return infix("LIKE", expression, Expression<String>(value: string))
}

public func glob(string: String, expression: Expression<String>) -> Expression<Bool> {
    return infix("GLOB", expression, Expression<String>(value: string))
}
public func glob(string: String, expression: Expression<String?>) -> Expression<Bool?> {
    return infix("GLOB", expression, Expression<String>(value: string))
}

public func match(string: String, expression: Expression<String>) -> Expression<Bool> {
    return infix("MATCH", expression, Expression<String>(value: string))
}
public func match(string: String, expression: Expression<String?>) -> Expression<Bool?> {
    return infix("MATCH", expression, Expression<String>(value: string))
}

// MARK: Compound

public func &&(lhs: Expression<Bool>, rhs: Expression<Bool>) -> Expression<Bool> { return infix("AND", lhs, rhs) }
public func &&(lhs: Expression<Bool>, rhs: Expression<Bool?>) -> Expression<Bool?> { return infix("AND", lhs, rhs) }
public func &&(lhs: Expression<Bool?>, rhs: Expression<Bool>) -> Expression<Bool?> { return infix("AND", lhs, rhs) }
public func &&(lhs: Expression<Bool?>, rhs: Expression<Bool?>) -> Expression<Bool?> { return infix("AND", lhs, rhs) }
public func &&(lhs: Expression<Bool>, rhs: Bool) -> Expression<Bool> { return lhs && Expression(value: rhs) }
public func &&(lhs: Expression<Bool?>, rhs: Bool) -> Expression<Bool?> { return lhs && Expression(value: rhs) }
public func &&(lhs: Bool, rhs: Expression<Bool>) -> Expression<Bool> { return Expression(value: lhs) && rhs }
public func &&(lhs: Bool, rhs: Expression<Bool?>) -> Expression<Bool?> { return Expression(value: lhs) && rhs }

public func ||(lhs: Expression<Bool>, rhs: Expression<Bool>) -> Expression<Bool> { return infix("OR", lhs, rhs) }
public func ||(lhs: Expression<Bool>, rhs: Expression<Bool?>) -> Expression<Bool?> { return infix("OR", lhs, rhs) }
public func ||(lhs: Expression<Bool?>, rhs: Expression<Bool>) -> Expression<Bool?> { return infix("OR", lhs, rhs) }
public func ||(lhs: Expression<Bool?>, rhs: Expression<Bool?>) -> Expression<Bool?> { return infix("OR", lhs, rhs) }
public func ||(lhs: Expression<Bool>, rhs: Bool) -> Expression<Bool> { return lhs || Expression(value: rhs) }
public func ||(lhs: Expression<Bool?>, rhs: Bool) -> Expression<Bool?> { return lhs || Expression(value: rhs) }
public func ||(lhs: Bool, rhs: Expression<Bool>) -> Expression<Bool> { return Expression(value: lhs) || rhs }
public func ||(lhs: Bool, rhs: Expression<Bool?>) -> Expression<Bool?> { return Expression(value: lhs) || rhs }

public prefix func !(rhs: Expression<Bool>) -> Expression<Bool> { return wrap("NOT ", rhs) }
public prefix func !(rhs: Expression<Bool?>) -> Expression<Bool?> { return wrap("NOT ", rhs) }

// MARK: - Core Functions

public func abs<V: Number>(expression: Expression<V>) -> Expression<V> { return wrap(__FUNCTION__, expression) }
public func abs<V: Number>(expression: Expression<V?>) -> Expression<V?> { return wrap(__FUNCTION__, expression) }

// FIXME: support Expression<V?>..., Expression<V> when Swift supports inner variadic signatures
public func coalesce<V>(expressions: Expression<V?>...) -> Expression<V?> {
    return wrap(__FUNCTION__, join(", ", expressions.map { $0 }))
}

public func ifnull<V: Expressible>(expression: Expression<V?>, defaultValue: V) -> Expression<V> {
    return wrap(__FUNCTION__, join(", ", [expression, defaultValue]))
}
public func ??<V: Expressible>(expression: Expression<V?>, defaultValue: V) -> Expression<V> {
    return ifnull(expression, defaultValue)
}

public func length<V>(expression: Expression<V>) -> Expression<Int> { return wrap(__FUNCTION__, expression) }
public func length<V>(expression: Expression<V?>) -> Expression<Int?> { return wrap(__FUNCTION__, expression) }

public func lower(expression: Expression<String>) -> Expression<String> { return wrap(__FUNCTION__, expression) }
public func lower(expression: Expression<String?>) -> Expression<String?> { return wrap(__FUNCTION__, expression) }

public func ltrim(expression: Expression<String>) -> Expression<String> { return wrap(__FUNCTION__, expression) }
public func ltrim(expression: Expression<String?>) -> Expression<String?> { return wrap(__FUNCTION__, expression) }

public func ltrim(expression: Expression<String>, characters: String) -> Expression<String> {
    return wrap(__FUNCTION__, join(", ", [expression, characters]))
}
public func ltrim(expression: Expression<String?>, characters: String) -> Expression<String?> {
    return wrap(__FUNCTION__, join(", ", [expression, characters]))
}

public var random: Expression<Int> { return wrap(__FUNCTION__, Expression<()>()) }

public func replace(expression: Expression<String>, match: String, subtitute: String) -> Expression<String> {
    return wrap(__FUNCTION__, join(", ", [expression, match, subtitute]))
}
public func replace(expression: Expression<String?>, match: String, subtitute: String) -> Expression<String?> {
    return wrap(__FUNCTION__, join(", ", [expression, match, subtitute]))
}

public func round(expression: Expression<Double>) -> Expression<Double> { return wrap(__FUNCTION__, expression) }
public func round(expression: Expression<Double?>) -> Expression<Double?> { return wrap(__FUNCTION__, expression) }
public func round(expression: Expression<Double>, precision: Int) -> Expression<Double> {
    return wrap(__FUNCTION__, join(", ", [expression, precision]))
}
public func round(expression: Expression<Double?>, precision: Int) -> Expression<Double?> {
    return wrap(__FUNCTION__, join(", ", [expression, precision]))
}

public func rtrim(expression: Expression<String>) -> Expression<String> { return wrap(__FUNCTION__, expression) }
public func rtrim(expression: Expression<String?>) -> Expression<String?> { return wrap(__FUNCTION__, expression) }
public func rtrim(expression: Expression<String>, characters: String) -> Expression<String> {
    return wrap(__FUNCTION__, join(", ", [expression, characters]))
}
public func rtrim(expression: Expression<String?>, characters: String) -> Expression<String?> {
    return wrap(__FUNCTION__, join(", ", [expression, characters]))
}

public func substr(expression: Expression<String>, startIndex: Int) -> Expression<String> {
    return wrap(__FUNCTION__, join(", ", [expression, startIndex]))
}
public func substr(expression: Expression<String?>, startIndex: Int) -> Expression<String?> {
    return wrap(__FUNCTION__, join(", ", [expression, startIndex]))
}

public func substr(expression: Expression<String>, position: Int, length: Int) -> Expression<String> {
    return wrap(__FUNCTION__, join(", ", [expression, position, length]))
}
public func substr(expression: Expression<String?>, position: Int, length: Int) -> Expression<String?> {
    return wrap(__FUNCTION__, join(", ", [expression, position, length]))
}

public func substr(expression: Expression<String>, subRange: Range<Int>) -> Expression<String> {
    return substr(expression, subRange.startIndex, subRange.endIndex - subRange.startIndex)
}
public func substr(expression: Expression<String?>, subRange: Range<Int>) -> Expression<String?> {
    return substr(expression, subRange.startIndex, subRange.endIndex - subRange.startIndex)
}

public func trim(expression: Expression<String>) -> Expression<String> { return wrap(__FUNCTION__, expression) }
public func trim(expression: Expression<String?>) -> Expression<String?> { return wrap(__FUNCTION__, expression) }
public func trim(expression: Expression<String>, characters: String) -> Expression<String> {
    return wrap(__FUNCTION__, join(", ", [expression, characters]))
}
public func trim(expression: Expression<String?>, characters: String) -> Expression<String?> {
    return wrap(__FUNCTION__, join(", ", [expression, characters]))
}

public func upper(expression: Expression<String>) -> Expression<String> { return wrap(__FUNCTION__, expression) }
public func upper(expression: Expression<String?>) -> Expression<String?> { return wrap(__FUNCTION__, expression) }

// MARK: - Aggregate Functions

public func count<V>(expression: Expression<V>) -> Expression<Int> { return wrap(__FUNCTION__, expression) }
public func count<V>(expression: Expression<V?>) -> Expression<Int?> { return wrap(__FUNCTION__, expression) }

public func count(star: Star) -> Expression<Int> { return count(star(nil, nil)) }

public func max<V: Value where V.Datatype: Binding>(expression: Expression<V>) -> Expression<V> {
    return wrap(__FUNCTION__, expression)
}
public func max<V: Value where V.Datatype: Binding>(expression: Expression<V?>) -> Expression<V?> {
    return wrap(__FUNCTION__, expression)
}

public func min<V: Value where V.Datatype: Binding>(expression: Expression<V>) -> Expression<V> {
    return wrap(__FUNCTION__, expression)
}
public func min<V: Value where V.Datatype: Binding>(expression: Expression<V?>) -> Expression<V?> {
    return wrap(__FUNCTION__, expression)
}

public func average<V: Number>(expression: Expression<V>) -> Expression<Double> { return wrap("avg", expression) }
public func average<V: Number>(expression: Expression<V?>) -> Expression<Double?> { return wrap("avg", expression) }

public func sum<V: Number>(expression: Expression<V>) -> Expression<V> { return wrap(__FUNCTION__, expression) }
public func sum<V: Number>(expression: Expression<V?>) -> Expression<V?> { return wrap(__FUNCTION__, expression) }

public func total<V: Number>(expression: Expression<V>) -> Expression<Double> { return wrap(__FUNCTION__, expression) }
public func total<V: Number>(expression: Expression<V?>) -> Expression<Double?> { return wrap(__FUNCTION__, expression) }

// MARK: - Helper

public typealias Star = (Expression<Binding>?, Expression<Binding>?) -> Expression<()>

public func *(Expression<Binding>?, Expression<Binding>?) -> Expression<()> {
    return Expression<()>("*")
}

public func contains<V: Value where V.Datatype: Binding>(values: [V.Datatype], column: Expression<V>) -> Expression<Bool> {
    let templates = join(", ", [String](count: values.count, repeatedValue: "?"))
    return infix("IN", column, Expression<V>("(\(templates))", values.map { $0 }))
}
public func contains<V: Value where V.Datatype: Binding>(values: [V.Datatype?], column: Expression<V?>) -> Expression<Bool> {
    let templates = join(", ", [String](count: values.count, repeatedValue: "?"))
    return infix("IN", column, Expression<V>("(\(templates))", values.map { $0 }))
}

// MARK: - Modifying

/// A pair of expressions used to set values in INSERT and UPDATE statements.
public typealias Setter = (Expressible, Expressible)

/// Returns a setter to be used with INSERT and UPDATE statements.
///
/// :param: column The column being set.
///
/// :param: value  The value the column is being set to.
///
/// :returns: A setter that can be used in a Query's insert and update
///           functions.
public func set<V: Value where V.Datatype: Binding>(column: Expression<V>, value: V) -> Setter {
    return (column, Expression<()>(value: value.datatypeValue))
}
public func set<V: Value where V.Datatype: Binding>(column: Expression<V?>, value: V?) -> Setter {
    return (column, Expression<()>(value: value?.datatypeValue))
}
public func set<V: Value>(column: Expression<V>, value: Expression<V>) -> Setter { return (column, value) }
public func set<V: Value>(column: Expression<V>, value: Expression<V?>) -> Setter { return (column, value) }
public func set<V: Value>(column: Expression<V?>, value: Expression<V>) -> Setter { return (column, value) }
public func set<V: Value>(column: Expression<V?>, value: Expression<V?>) -> Setter { return (column, value) }

infix operator <- { associativity left precedence 140 }
public func <-<V: Value>(column: Expression<V>, value: Expression<V>) -> Setter { return set(column, value) }
public func <-<V: Value>(column: Expression<V>, value: Expression<V?>) -> Setter { return set(column, value) }
public func <-<V: Value>(column: Expression<V?>, value: Expression<V>) -> Setter { return set(column, value) }
public func <-<V: Value>(column: Expression<V?>, value: Expression<V?>) -> Setter { return set(column, value) }
public func <-<V: Value where V.Datatype: Binding>(column: Expression<V>, value: V) -> Setter { return set(column, value) }
public func <-<V: Value where V.Datatype: Binding>(column: Expression<V?>, value: V?) -> Setter { return set(column, value) }

public func +=(column: Expression<String>, value: Expression<String>) -> Setter { return set(column, column + value) }
public func +=(column: Expression<String>, value: Expression<String?>) -> Setter { return set(column, column + value) }
public func +=(column: Expression<String?>, value: Expression<String>) -> Setter { return set(column, column + value) }
public func +=(column: Expression<String?>, value: Expression<String?>) -> Setter { return set(column, column + value) }
public func +=(column: Expression<String>, value: String) -> Setter { return set(column, column + value) }
public func +=(column: Expression<String?>, value: String) -> Setter { return set(column, column + value) }

public func +=<V: protocol<Number, Value>>(column: Expression<V>, value: Expression<V>) -> Setter {
    return set(column, column + value)
}
public func +=<V: protocol<Number, Value>>(column: Expression<V>, value: Expression<V?>) -> Setter {
    return set(column, column + value)
}
public func +=<V: protocol<Number, Value>>(column: Expression<V?>, value: Expression<V>) -> Setter {
    return set(column, column + value)
}
public func +=<V: protocol<Number, Value>>(column: Expression<V?>, value: Expression<V?>) -> Setter {
    return set(column, column + value)
}
public func +=<V: protocol<Number, Value>>(column: Expression<V>, value: V) -> Setter { return set(column, column + value) }
public func +=<V: protocol<Number, Value>>(column: Expression<V?>, value: V) -> Setter { return set(column, column + value) }

public func -=<V: protocol<Number, Value>>(column: Expression<V>, value: Expression<V>) -> Setter {
    return set(column, column - value)
}
public func -=<V: protocol<Number, Value>>(column: Expression<V>, value: Expression<V?>) -> Setter {
    return set(column, column - value)
}
public func -=<V: protocol<Number, Value>>(column: Expression<V?>, value: Expression<V>) -> Setter {
    return set(column, column - value)
}
public func -=<V: protocol<Number, Value>>(column: Expression<V?>, value: Expression<V?>) -> Setter {
    return set(column, column - value)
}
public func -=<V: protocol<Number, Value>>(column: Expression<V>, value: V) -> Setter { return set(column, column - value) }
public func -=<V: protocol<Number, Value>>(column: Expression<V?>, value: V) -> Setter { return set(column, column - value) }

public func *=<V: protocol<Number, Value>>(column: Expression<V>, value: Expression<V>) -> Setter {
    return set(column, column * value)
}
public func *=<V: protocol<Number, Value>>(column: Expression<V>, value: Expression<V?>) -> Setter {
    return set(column, column * value)
}
public func *=<V: protocol<Number, Value>>(column: Expression<V?>, value: Expression<V>) -> Setter {
    return set(column, column * value)
}
public func *=<V: protocol<Number, Value>>(column: Expression<V?>, value: Expression<V?>) -> Setter {
    return set(column, column * value)
}
public func *=<V: protocol<Number, Value>>(column: Expression<V>, value: V) -> Setter { return set(column, column * value) }
public func *=<V: protocol<Number, Value>>(column: Expression<V?>, value: V) -> Setter { return set(column, column * value) }

public func /=<V: protocol<Number, Value>>(column: Expression<V>, value: Expression<V>) -> Setter {
    return set(column, column / value)
}
public func /=<V: protocol<Number, Value>>(column: Expression<V>, value: Expression<V?>) -> Setter {
    return set(column, column / value)
}
public func /=<V: protocol<Number, Value>>(column: Expression<V?>, value: Expression<V>) -> Setter {
    return set(column, column / value)
}
public func /=<V: protocol<Number, Value>>(column: Expression<V?>, value: Expression<V?>) -> Setter {
    return set(column, column / value)
}
public func /=<V: protocol<Number, Value>>(column: Expression<V>, value: V) -> Setter {
    return set(column, column / value)
}
public func /=<V: protocol<Number, Value>>(column: Expression<V?>, value: V) -> Setter {
    return set(column, column / value)
}

public func %=(column: Expression<Int>, value: Expression<Int>) -> Setter { return set(column, column % value) }
public func %=(column: Expression<Int>, value: Expression<Int?>) -> Setter { return set(column, column % value) }
public func %=(column: Expression<Int?>, value: Expression<Int>) -> Setter { return set(column, column % value) }
public func %=(column: Expression<Int?>, value: Expression<Int?>) -> Setter { return set(column, column % value) }
public func %=(column: Expression<Int>, value: Int) -> Setter { return set(column, column % value) }
public func %=(column: Expression<Int?>, value: Int) -> Setter { return set(column, column % value) }

public func <<=(column: Expression<Int>, value: Expression<Int>) -> Setter { return set(column, column << value) }
public func <<=(column: Expression<Int>, value: Expression<Int?>) -> Setter { return set(column, column << value) }
public func <<=(column: Expression<Int?>, value: Expression<Int>) -> Setter { return set(column, column << value) }
public func <<=(column: Expression<Int?>, value: Expression<Int?>) -> Setter { return set(column, column << value) }
public func <<=(column: Expression<Int>, value: Int) -> Setter { return set(column, column << value) }
public func <<=(column: Expression<Int?>, value: Int) -> Setter { return set(column, column << value) }

public func >>=(column: Expression<Int>, value: Expression<Int>) -> Setter { return set(column, column >> value) }
public func >>=(column: Expression<Int>, value: Expression<Int?>) -> Setter { return set(column, column >> value) }
public func >>=(column: Expression<Int?>, value: Expression<Int>) -> Setter { return set(column, column >> value) }
public func >>=(column: Expression<Int?>, value: Expression<Int?>) -> Setter { return set(column, column >> value) }
public func >>=(column: Expression<Int>, value: Int) -> Setter { return set(column, column >> value) }
public func >>=(column: Expression<Int?>, value: Int) -> Setter { return set(column, column >> value) }

public func &=(column: Expression<Int>, value: Expression<Int>) -> Setter { return set(column, column & value) }
public func &=(column: Expression<Int>, value: Expression<Int?>) -> Setter { return set(column, column & value) }
public func &=(column: Expression<Int?>, value: Expression<Int>) -> Setter { return set(column, column & value) }
public func &=(column: Expression<Int?>, value: Expression<Int?>) -> Setter { return set(column, column & value) }
public func &=(column: Expression<Int>, value: Int) -> Setter { return set(column, column & value) }
public func &=(column: Expression<Int?>, value: Int) -> Setter { return set(column, column & value) }

public func |=(column: Expression<Int>, value: Expression<Int>) -> Setter { return set(column, column | value) }
public func |=(column: Expression<Int>, value: Expression<Int?>) -> Setter { return set(column, column | value) }
public func |=(column: Expression<Int?>, value: Expression<Int>) -> Setter { return set(column, column | value) }
public func |=(column: Expression<Int?>, value: Expression<Int?>) -> Setter { return set(column, column | value) }
public func |=(column: Expression<Int>, value: Int) -> Setter { return set(column, column | value) }
public func |=(column: Expression<Int?>, value: Int) -> Setter { return set(column, column | value) }

public func ^=(column: Expression<Int>, value: Expression<Int>) -> Setter { return set(column, column ^ value) }
public func ^=(column: Expression<Int>, value: Expression<Int?>) -> Setter { return set(column, column ^ value) }
public func ^=(column: Expression<Int?>, value: Expression<Int>) -> Setter { return set(column, column ^ value) }
public func ^=(column: Expression<Int?>, value: Expression<Int?>) -> Setter { return set(column, column ^ value) }
public func ^=(column: Expression<Int>, value: Int) -> Setter { return set(column, column ^ value) }
public func ^=(column: Expression<Int?>, value: Int) -> Setter { return set(column, column ^ value) }

public postfix func ++(column: Expression<Int>) -> Setter {
    // rdar://18825175 segfaults during archive: // column += 1
    return (column, Expression<Int>("(\(column.SQL) + 1)", column.bindings))
}
public postfix func ++(column: Expression<Int?>) -> Setter {
    // rdar://18825175 segfaults during archive: // column += 1
    return (column, Expression<Int>("(\(column.SQL) + 1)", column.bindings))
}
public postfix func --(column: Expression<Int>) -> Setter {
    // rdar://18825175 segfaults during archive: // column -= 1
    return (column, Expression<Int>("(\(column.SQL) - 1)", column.bindings))
}
public postfix func --(column: Expression<Int?>) -> Setter {
    // rdar://18825175 segfaults during archive: // column -= 1
    return (column, Expression<Int>("(\(column.SQL) - 1)", column.bindings))
}

// MARK: - Internal

internal func join(separator: String, expressions: [Expressible]) -> Expression<()> {
    var (SQL, bindings) = ([String](), [Binding?]())
    for expressible in expressions {
        let expression = expressible.expression
        SQL.append(expression.SQL)
        bindings.extend(expression.bindings)
    }
    return Expression(Swift.join(separator, SQL), bindings)
}

internal func transcode(literal: Binding?) -> String {
    if let literal = literal {
        if let literal = literal as? String { return quote(literal: literal) }
        if let literal = literal as? Bool { return literal ? "1" : "0" }
        return "\(literal)"
    }
    return "NULL"
}

internal func wrap<T, U>(function: String, expression: Expression<T>) -> Expression<U> {
    return Expression("\(function)\(surround(expression.SQL))", expression.bindings)
}

private func infix<T, U, V>(function: String, lhs: Expression<T>, rhs: Expression<U>) -> Expression<V> {
    return Expression(surround("\(lhs.SQL) \(function) \(rhs.SQL)"), lhs.bindings + rhs.bindings)
}

private func surround(expression: String) -> String { return "(\(expression))" }

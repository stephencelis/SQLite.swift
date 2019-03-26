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

// TODO: use `@warn_unused_result` by the time operator functions support it

private enum Operators: String {
    case plus = "+"
    case minus = "-"
    case or = "OR"
    case and = "AND"
    case not = "NOT "
    case mul = "*"
    case div = "/"
    case mod = "%"
    case bitwiseLeft = "<<"
    case bitwiseRight = ">>"
    case bitwiseAnd = "&"
    case bitwiseOr = "|"
    case bitwiseXor = "~"
    case eq = "="
    case neq = "!="
    case gt = ">"
    case lt = "<"
    case gte = ">="
    case lte = "<="
    case concatenate = "||"
    
    func infix<T>(_ lhs: Expressible, _ rhs: Expressible, wrap: Bool = true) -> Expression<T> {
        return self.rawValue.infix(lhs, rhs, wrap: wrap)
    }
    
    func wrap<T>(_ expression: Expressible) -> Expression<T> {
        return self.rawValue.wrap(expression)
    }
}

public func +(lhs: Expression<String>, rhs: Expression<String>) -> Expression<String> {
    return Operators.concatenate.infix(lhs, rhs)
}

public func +(lhs: Expression<String>, rhs: Expression<String?>) -> Expression<String?> {
    return Operators.concatenate.infix(lhs, rhs)
}
public func +(lhs: Expression<String?>, rhs: Expression<String>) -> Expression<String?> {
    return Operators.concatenate.infix(lhs, rhs)
}
public func +(lhs: Expression<String?>, rhs: Expression<String?>) -> Expression<String?> {
    return Operators.concatenate.infix(lhs, rhs)
}
public func +(lhs: Expression<String>, rhs: String) -> Expression<String> {
    return Operators.concatenate.infix(lhs, rhs)
}
public func +(lhs: Expression<String?>, rhs: String) -> Expression<String?> {
    return Operators.concatenate.infix(lhs, rhs)
}
public func +(lhs: String, rhs: Expression<String>) -> Expression<String> {
    return Operators.concatenate.infix(lhs, rhs)
}
public func +(lhs: String, rhs: Expression<String?>) -> Expression<String?> {
    return Operators.concatenate.infix(lhs, rhs)
}

// MARK: -

public func +<V : Value>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> where V.Datatype : Number {
    return Operators.plus.infix(lhs, rhs)
}
public func +<V : Value>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype : Number {
    return Operators.plus.infix(lhs, rhs)
}
public func +<V : Value>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> where V.Datatype : Number {
    return Operators.plus.infix(lhs, rhs)
}
public func +<V : Value>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype : Number {
    return Operators.plus.infix(lhs, rhs)
}
public func +<V : Value>(lhs: Expression<V>, rhs: V) -> Expression<V> where V.Datatype : Number {
    return Operators.plus.infix(lhs, rhs)
}
public func +<V : Value>(lhs: Expression<V?>, rhs: V) -> Expression<V?> where V.Datatype : Number {
    return Operators.plus.infix(lhs, rhs)
}
public func +<V : Value>(lhs: V, rhs: Expression<V>) -> Expression<V> where V.Datatype : Number {
    return Operators.plus.infix(lhs, rhs)
}
public func +<V: Value>(lhs: V, rhs: Expression<V?>) -> Expression<V?> where V.Datatype : Number {
    return Operators.plus.infix(lhs, rhs)
}

public func -<V : Value>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> where V.Datatype : Number {
    return Operators.minus.infix(lhs, rhs)
}
public func -<V : Value>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype : Number {
    return Operators.minus.infix(lhs, rhs)
}
public func -<V : Value>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> where V.Datatype : Number {
    return Operators.minus.infix(lhs, rhs)
}
public func -<V : Value>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype : Number {
    return Operators.minus.infix(lhs, rhs)
}
public func -<V : Value>(lhs: Expression<V>, rhs: V) -> Expression<V> where V.Datatype : Number {
    return Operators.minus.infix(lhs, rhs)
}
public func -<V : Value>(lhs: Expression<V?>, rhs: V) -> Expression<V?> where V.Datatype : Number {
    return Operators.minus.infix(lhs, rhs)
}
public func -<V : Value>(lhs: V, rhs: Expression<V>) -> Expression<V> where V.Datatype : Number {
    return Operators.minus.infix(lhs, rhs)
}
public func -<V: Value>(lhs: V, rhs: Expression<V?>) -> Expression<V?> where V.Datatype : Number {
    return Operators.minus.infix(lhs, rhs)
}

public func *<V : Value>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> where V.Datatype : Number {
    return Operators.mul.infix(lhs, rhs)
}
public func *<V : Value>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype : Number {
    return Operators.mul.infix(lhs, rhs)
}
public func *<V : Value>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> where V.Datatype : Number {
    return Operators.mul.infix(lhs, rhs)
}
public func *<V : Value>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype : Number {
    return Operators.mul.infix(lhs, rhs)
}
public func *<V : Value>(lhs: Expression<V>, rhs: V) -> Expression<V> where V.Datatype : Number {
    return Operators.mul.infix(lhs, rhs)
}
public func *<V : Value>(lhs: Expression<V?>, rhs: V) -> Expression<V?> where V.Datatype : Number {
    return Operators.mul.infix(lhs, rhs)
}
public func *<V : Value>(lhs: V, rhs: Expression<V>) -> Expression<V> where V.Datatype : Number {
    return Operators.mul.infix(lhs, rhs)
}
public func *<V: Value>(lhs: V, rhs: Expression<V?>) -> Expression<V?> where V.Datatype : Number {
    return Operators.mul.infix(lhs, rhs)
}

public func /<V : Value>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> where V.Datatype : Number {
    return Operators.div.infix(lhs, rhs)
}
public func /<V : Value>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype : Number {
    return Operators.div.infix(lhs, rhs)
}
public func /<V : Value>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> where V.Datatype : Number {
    return Operators.div.infix(lhs, rhs)
}
public func /<V : Value>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype : Number {
    return Operators.div.infix(lhs, rhs)
}
public func /<V : Value>(lhs: Expression<V>, rhs: V) -> Expression<V> where V.Datatype : Number {
    return Operators.div.infix(lhs, rhs)
}
public func /<V : Value>(lhs: Expression<V?>, rhs: V) -> Expression<V?> where V.Datatype : Number {
    return Operators.div.infix(lhs, rhs)
}
public func /<V : Value>(lhs: V, rhs: Expression<V>) -> Expression<V> where V.Datatype : Number {
    return Operators.div.infix(lhs, rhs)
}
public func /<V: Value>(lhs: V, rhs: Expression<V?>) -> Expression<V?> where V.Datatype : Number {
    return Operators.div.infix(lhs, rhs)
}

public prefix func -<V : Value>(rhs: Expression<V>) -> Expression<V> where V.Datatype : Number {
    return Operators.minus.wrap(rhs)
}
public prefix func -<V : Value>(rhs: Expression<V?>) -> Expression<V?> where V.Datatype : Number {
    return Operators.minus.wrap(rhs)
}

// MARK: -

public func %<V : Value>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> where V.Datatype == Int64 {
    return Operators.mod.infix(lhs, rhs)
}
public func %<V : Value>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.mod.infix(lhs, rhs)
}
public func %<V : Value>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.mod.infix(lhs, rhs)
}
public func %<V : Value>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.mod.infix(lhs, rhs)
}
public func %<V : Value>(lhs: Expression<V>, rhs: V) -> Expression<V> where V.Datatype == Int64 {
    return Operators.mod.infix(lhs, rhs)
}
public func %<V : Value>(lhs: Expression<V?>, rhs: V) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.mod.infix(lhs, rhs)
}
public func %<V : Value>(lhs: V, rhs: Expression<V>) -> Expression<V> where V.Datatype == Int64 {
    return Operators.mod.infix(lhs, rhs)
}
public func %<V : Value>(lhs: V, rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.mod.infix(lhs, rhs)
}

public func <<<V : Value>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> where V.Datatype == Int64 {
    return Operators.bitwiseLeft.infix(lhs, rhs)
}
public func <<<V : Value>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseLeft.infix(lhs, rhs)
}
public func <<<V : Value>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseLeft.infix(lhs, rhs)
}
public func <<<V : Value>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseLeft.infix(lhs, rhs)
}
public func <<<V : Value>(lhs: Expression<V>, rhs: V) -> Expression<V> where V.Datatype == Int64 {
    return Operators.bitwiseLeft.infix(lhs, rhs)
}
public func <<<V : Value>(lhs: Expression<V?>, rhs: V) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseLeft.infix(lhs, rhs)
}
public func <<<V : Value>(lhs: V, rhs: Expression<V>) -> Expression<V> where V.Datatype == Int64 {
    return Operators.bitwiseLeft.infix(lhs, rhs)
}
public func <<<V : Value>(lhs: V, rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseLeft.infix(lhs, rhs)
}

public func >><V : Value>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> where V.Datatype == Int64 {
    return Operators.bitwiseRight.infix(lhs, rhs)
}
public func >><V : Value>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseRight.infix(lhs, rhs)
}
public func >><V : Value>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseRight.infix(lhs, rhs)
}
public func >><V : Value>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseRight.infix(lhs, rhs)
}
public func >><V : Value>(lhs: Expression<V>, rhs: V) -> Expression<V> where V.Datatype == Int64 {
    return Operators.bitwiseRight.infix(lhs, rhs)
}
public func >><V : Value>(lhs: Expression<V?>, rhs: V) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseRight.infix(lhs, rhs)
}
public func >><V : Value>(lhs: V, rhs: Expression<V>) -> Expression<V> where V.Datatype == Int64 {
    return Operators.bitwiseRight.infix(lhs, rhs)
}
public func >><V : Value>(lhs: V, rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseRight.infix(lhs, rhs)
}

public func &<V : Value>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> where V.Datatype == Int64 {
    return Operators.bitwiseAnd.infix(lhs, rhs)
}
public func &<V : Value>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseAnd.infix(lhs, rhs)
}
public func &<V : Value>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseAnd.infix(lhs, rhs)
}
public func &<V : Value>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseAnd.infix(lhs, rhs)
}
public func &<V : Value>(lhs: Expression<V>, rhs: V) -> Expression<V> where V.Datatype == Int64 {
    return Operators.bitwiseAnd.infix(lhs, rhs)
}
public func &<V : Value>(lhs: Expression<V?>, rhs: V) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseAnd.infix(lhs, rhs)
}
public func &<V : Value>(lhs: V, rhs: Expression<V>) -> Expression<V> where V.Datatype == Int64 {
    return Operators.bitwiseAnd.infix(lhs, rhs)
}
public func &<V : Value>(lhs: V, rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseAnd.infix(lhs, rhs)
}

public func |<V : Value>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> where V.Datatype == Int64 {
    return Operators.bitwiseOr.infix(lhs, rhs)
}
public func |<V : Value>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseOr.infix(lhs, rhs)
}
public func |<V : Value>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseOr.infix(lhs, rhs)
}
public func |<V : Value>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseOr.infix(lhs, rhs)
}
public func |<V : Value>(lhs: Expression<V>, rhs: V) -> Expression<V> where V.Datatype == Int64 {
    return Operators.bitwiseOr.infix(lhs, rhs)
}
public func |<V : Value>(lhs: Expression<V?>, rhs: V) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseOr.infix(lhs, rhs)
}
public func |<V : Value>(lhs: V, rhs: Expression<V>) -> Expression<V> where V.Datatype == Int64 {
    return Operators.bitwiseOr.infix(lhs, rhs)
}
public func |<V : Value>(lhs: V, rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseOr.infix(lhs, rhs)
}

public func ^<V : Value>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> where V.Datatype == Int64 {
    return (~(lhs & rhs)) & (lhs | rhs)
}
public func ^<V : Value>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return (~(lhs & rhs)) & (lhs | rhs)
}
public func ^<V : Value>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> where V.Datatype == Int64 {
    return (~(lhs & rhs)) & (lhs | rhs)
}
public func ^<V : Value>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return (~(lhs & rhs)) & (lhs | rhs)
}
public func ^<V : Value>(lhs: Expression<V>, rhs: V) -> Expression<V> where V.Datatype == Int64 {
    return (~(lhs & rhs)) & (lhs | rhs)
}
public func ^<V : Value>(lhs: Expression<V?>, rhs: V) -> Expression<V?> where V.Datatype == Int64 {
    return (~(lhs & rhs)) & (lhs | rhs)
}
public func ^<V : Value>(lhs: V, rhs: Expression<V>) -> Expression<V> where V.Datatype == Int64 {
    return (~(lhs & rhs)) & (lhs | rhs)
}
public func ^<V : Value>(lhs: V, rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return (~(lhs & rhs)) & (lhs | rhs)
}

public prefix func ~<V : Value>(rhs: Expression<V>) -> Expression<V> where V.Datatype == Int64 {
    return Operators.bitwiseXor.wrap(rhs)
}
public prefix func ~<V : Value>(rhs: Expression<V?>) -> Expression<V?> where V.Datatype == Int64 {
    return Operators.bitwiseXor.wrap(rhs)
}

// MARK: -

public func ==<V : Value>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> where V.Datatype : Equatable {
    return Operators.eq.infix(lhs, rhs)
}
public func ==<V : Value>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Equatable {
    return Operators.eq.infix(lhs, rhs)
}
public func ==<V : Value>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> where V.Datatype : Equatable {
    return Operators.eq.infix(lhs, rhs)
}
public func ==<V : Value>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Equatable {
    return Operators.eq.infix(lhs, rhs)
}
public func ==<V : Value>(lhs: Expression<V>, rhs: V) -> Expression<Bool> where V.Datatype : Equatable {
    return Operators.eq.infix(lhs, rhs)
}
public func ==<V : Value>(lhs: Expression<V?>, rhs: V?) -> Expression<Bool?> where V.Datatype : Equatable {
    guard let rhs = rhs else { return "IS".infix(lhs, Expression<V?>(value: nil)) }
    return Operators.eq.infix(lhs, rhs)
}
public func ==<V : Value>(lhs: V, rhs: Expression<V>) -> Expression<Bool> where V.Datatype : Equatable {
    return Operators.eq.infix(lhs, rhs)
}
public func ==<V : Value>(lhs: V?, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Equatable {
    guard let lhs = lhs else { return "IS".infix(Expression<V?>(value: nil), rhs) }
    return Operators.eq.infix(lhs, rhs)
}

public func !=<V : Value>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> where V.Datatype : Equatable {
    return Operators.neq.infix(lhs, rhs)
}
public func !=<V : Value>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Equatable {
    return Operators.neq.infix(lhs, rhs)
}
public func !=<V : Value>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> where V.Datatype : Equatable {
    return Operators.neq.infix(lhs, rhs)
}
public func !=<V : Value>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Equatable {
    return Operators.neq.infix(lhs, rhs)
}
public func !=<V : Value>(lhs: Expression<V>, rhs: V) -> Expression<Bool> where V.Datatype : Equatable {
    return Operators.neq.infix(lhs, rhs)
}
public func !=<V : Value>(lhs: Expression<V?>, rhs: V?) -> Expression<Bool?> where V.Datatype : Equatable {
    guard let rhs = rhs else { return "IS NOT".infix(lhs, Expression<V?>(value: nil)) }
    return Operators.neq.infix(lhs, rhs)
}
public func !=<V : Value>(lhs: V, rhs: Expression<V>) -> Expression<Bool> where V.Datatype : Equatable {
    return Operators.neq.infix(lhs, rhs)
}
public func !=<V : Value>(lhs: V?, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Equatable {
    guard let lhs = lhs else { return "IS NOT".infix(Expression<V?>(value: nil), rhs) }
    return Operators.neq.infix(lhs, rhs)
}

public func ><V : Value>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> where V.Datatype : Comparable {
    return Operators.gt.infix(lhs, rhs)
}
public func ><V : Value>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.gt.infix(lhs, rhs)
}
public func ><V : Value>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.gt.infix(lhs, rhs)
}
public func ><V : Value>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.gt.infix(lhs, rhs)
}
public func ><V : Value>(lhs: Expression<V>, rhs: V) -> Expression<Bool> where V.Datatype : Comparable {
    return Operators.gt.infix(lhs, rhs)
}
public func ><V : Value>(lhs: Expression<V?>, rhs: V) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.gt.infix(lhs, rhs)
}
public func ><V : Value>(lhs: V, rhs: Expression<V>) -> Expression<Bool> where V.Datatype : Comparable {
    return Operators.gt.infix(lhs, rhs)
}
public func ><V : Value>(lhs: V, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.gt.infix(lhs, rhs)
}

public func >=<V : Value>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> where V.Datatype : Comparable {
    return Operators.gte.infix(lhs, rhs)
}
public func >=<V : Value>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.gte.infix(lhs, rhs)
}
public func >=<V : Value>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.gte.infix(lhs, rhs)
}
public func >=<V : Value>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.gte.infix(lhs, rhs)
}
public func >=<V : Value>(lhs: Expression<V>, rhs: V) -> Expression<Bool> where V.Datatype : Comparable {
    return Operators.gte.infix(lhs, rhs)
}
public func >=<V : Value>(lhs: Expression<V?>, rhs: V) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.gte.infix(lhs, rhs)
}
public func >=<V : Value>(lhs: V, rhs: Expression<V>) -> Expression<Bool> where V.Datatype : Comparable {
    return Operators.gte.infix(lhs, rhs)
}
public func >=<V : Value>(lhs: V, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.gte.infix(lhs, rhs)
}

public func <<V : Value>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> where V.Datatype : Comparable {
    return Operators.lt.infix(lhs, rhs)
}
public func <<V : Value>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.lt.infix(lhs, rhs)
}
public func <<V : Value>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.lt.infix(lhs, rhs)
}
public func <<V : Value>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.lt.infix(lhs, rhs)
}
public func <<V : Value>(lhs: Expression<V>, rhs: V) -> Expression<Bool> where V.Datatype : Comparable {
    return Operators.lt.infix(lhs, rhs)
}
public func <<V : Value>(lhs: Expression<V?>, rhs: V) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.lt.infix(lhs, rhs)
}
public func <<V : Value>(lhs: V, rhs: Expression<V>) -> Expression<Bool> where V.Datatype : Comparable {
    return Operators.lt.infix(lhs, rhs)
}
public func <<V : Value>(lhs: V, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.lt.infix(lhs, rhs)
}

public func <=<V : Value>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> where V.Datatype : Comparable {
    return Operators.lte.infix(lhs, rhs)
}
public func <=<V : Value>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.lte.infix(lhs, rhs)
}
public func <=<V : Value>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.lte.infix(lhs, rhs)
}
public func <=<V : Value>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.lte.infix(lhs, rhs)
}
public func <=<V : Value>(lhs: Expression<V>, rhs: V) -> Expression<Bool> where V.Datatype : Comparable {
    return Operators.lte.infix(lhs, rhs)
}
public func <=<V : Value>(lhs: Expression<V?>, rhs: V) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.lte.infix(lhs, rhs)
}
public func <=<V : Value>(lhs: V, rhs: Expression<V>) -> Expression<Bool> where V.Datatype : Comparable {
    return Operators.lte.infix(lhs, rhs)
}
public func <=<V : Value>(lhs: V, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Comparable {
    return Operators.lte.infix(lhs, rhs)
}

public func ~=<V : Value>(lhs: ClosedRange<V>, rhs: Expression<V>) -> Expression<Bool> where V.Datatype : Comparable & Value {
    return Expression("\(rhs.template) BETWEEN ? AND ?", rhs.bindings + [lhs.lowerBound.datatypeValue, lhs.upperBound.datatypeValue])
}

public func ~=<V : Value>(lhs: ClosedRange<V>, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Comparable & Value {
    return Expression("\(rhs.template) BETWEEN ? AND ?", rhs.bindings + [lhs.lowerBound.datatypeValue, lhs.upperBound.datatypeValue])
}

public func ~=<V : Value>(lhs: Range<V>, rhs: Expression<V>) -> Expression<Bool> where V.Datatype : Comparable & Value {
    return Expression("\(rhs.template) >= ? AND \(rhs.template) < ?", rhs.bindings + [lhs.lowerBound.datatypeValue] + rhs.bindings + [lhs.upperBound.datatypeValue])
}

public func ~=<V : Value>(lhs: Range<V>, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Comparable & Value {
    return Expression("\(rhs.template) >= ? AND \(rhs.template) < ?", rhs.bindings + [lhs.lowerBound.datatypeValue] + rhs.bindings + [lhs.upperBound.datatypeValue])
}

public func ~=<V : Value>(lhs: PartialRangeThrough<V>, rhs: Expression<V>) -> Expression<Bool> where V.Datatype : Comparable & Value {
    return Expression("\(rhs.template) <= ?", rhs.bindings + [lhs.upperBound.datatypeValue])
}

public func ~=<V : Value>(lhs: PartialRangeThrough<V>, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Comparable & Value {
    return Expression("\(rhs.template) <= ?", rhs.bindings + [lhs.upperBound.datatypeValue])
}

public func ~=<V : Value>(lhs: PartialRangeUpTo<V>, rhs: Expression<V>) -> Expression<Bool> where V.Datatype : Comparable & Value {
    return Expression("\(rhs.template) < ?", rhs.bindings + [lhs.upperBound.datatypeValue])
}

public func ~=<V : Value>(lhs: PartialRangeUpTo<V>, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Comparable & Value {
    return Expression("\(rhs.template) < ?", rhs.bindings + [lhs.upperBound.datatypeValue])
}

public func ~=<V : Value>(lhs: PartialRangeFrom<V>, rhs: Expression<V>) -> Expression<Bool> where V.Datatype : Comparable & Value {
    return Expression("\(rhs.template) >= ?", rhs.bindings + [lhs.lowerBound.datatypeValue])
}

public func ~=<V : Value>(lhs: PartialRangeFrom<V>, rhs: Expression<V?>) -> Expression<Bool?> where V.Datatype : Comparable & Value {
    return Expression("\(rhs.template) >= ?", rhs.bindings + [lhs.lowerBound.datatypeValue])
}

// MARK: -

public func &&(lhs: Expression<Bool>, rhs: Expression<Bool>) -> Expression<Bool> {
    return Operators.and.infix(lhs, rhs)
}
public func &&(lhs: Expression<Bool>, rhs: Expression<Bool?>) -> Expression<Bool?> {
    return Operators.and.infix(lhs, rhs)
}
public func &&(lhs: Expression<Bool?>, rhs: Expression<Bool>) -> Expression<Bool?> {
    return Operators.and.infix(lhs, rhs)
}
public func &&(lhs: Expression<Bool?>, rhs: Expression<Bool?>) -> Expression<Bool?> {
    return Operators.and.infix(lhs, rhs)
}
public func &&(lhs: Expression<Bool>, rhs: Bool) -> Expression<Bool> {
    return Operators.and.infix(lhs, rhs)
}
public func &&(lhs: Expression<Bool?>, rhs: Bool) -> Expression<Bool?> {
    return Operators.and.infix(lhs, rhs)
}
public func &&(lhs: Bool, rhs: Expression<Bool>) -> Expression<Bool> {
    return Operators.and.infix(lhs, rhs)
}
public func &&(lhs: Bool, rhs: Expression<Bool?>) -> Expression<Bool?> {
    return Operators.and.infix(lhs, rhs)
}

public func ||(lhs: Expression<Bool>, rhs: Expression<Bool>) -> Expression<Bool> {
    return Operators.or.infix(lhs, rhs)
}
public func ||(lhs: Expression<Bool>, rhs: Expression<Bool?>) -> Expression<Bool?> {
    return Operators.or.infix(lhs, rhs)
}
public func ||(lhs: Expression<Bool?>, rhs: Expression<Bool>) -> Expression<Bool?> {
    return Operators.or.infix(lhs, rhs)
}
public func ||(lhs: Expression<Bool?>, rhs: Expression<Bool?>) -> Expression<Bool?> {
    return Operators.or.infix(lhs, rhs)
}
public func ||(lhs: Expression<Bool>, rhs: Bool) -> Expression<Bool> {
    return Operators.or.infix(lhs, rhs)
}
public func ||(lhs: Expression<Bool?>, rhs: Bool) -> Expression<Bool?> {
    return Operators.or.infix(lhs, rhs)
}
public func ||(lhs: Bool, rhs: Expression<Bool>) -> Expression<Bool> {
    return Operators.or.infix(lhs, rhs)
}
public func ||(lhs: Bool, rhs: Expression<Bool?>) -> Expression<Bool?> {
    return Operators.or.infix(lhs, rhs)
}

public prefix func !(rhs: Expression<Bool>) -> Expression<Bool> {
    return Operators.not.wrap(rhs)
}
public prefix func !(rhs: Expression<Bool?>) -> Expression<Bool?> {
    return Operators.not.wrap(rhs)
}

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

/// - Warning: `Binding` is a protocol that SQLite.swift uses internally to
///   directly map SQLite types to Swift types.
///
///   Do not conform custom types to the Binding protocol. See the `Value`
///   protocol, instead.
public protocol Binding {}

public protocol Number: Binding {}

public protocol Value: Expressible { // extensions cannot have inheritance clauses

    associatedtype ValueType = Self

    associatedtype Datatype: Binding

    static var declaredDatatype: String { get }

    static func fromDatatypeValue(_ datatypeValue: Datatype) -> ValueType

    var datatypeValue: Datatype { get }

}

extension Double: Number, Value {

    public static let declaredDatatype = "REAL"

    public static func fromDatatypeValue(_ datatypeValue: Double) -> Double {
        datatypeValue
    }

    public var datatypeValue: Double {
        self
    }

}

extension Int64: Number, Value {

    public static let declaredDatatype = "INTEGER"

    public static func fromDatatypeValue(_ datatypeValue: Int64) -> Int64 {
        datatypeValue
    }

    public var datatypeValue: Int64 {
        self
    }

}

extension UInt64: Number, Value {

    public static let declaredDatatype = Blob.declaredDatatype

    public static func fromDatatypeValue(_ datatypeValue: Blob) -> UInt64 {
        guard datatypeValue.bytes.count >= MemoryLayout<UInt64>.size else { return 0 }
        let bigEndianUInt64 = datatypeValue.bytes.withUnsafeBytes({ $0.load(as: UInt64.self )})
        return UInt64(bigEndian: bigEndianUInt64)
    }

    public var datatypeValue: Blob {
        var bytes: [UInt8] = []
        withUnsafeBytes(of: self) { pointer in
            // little endian by default on iOS/macOS, so reverse to get bigEndian
            bytes.append(contentsOf: pointer.reversed())
        }
        return Blob(bytes: bytes)
    }

}

extension String: Binding, Value {

    public static let declaredDatatype = "TEXT"

    public static func fromDatatypeValue(_ datatypeValue: String) -> String {
        datatypeValue
    }

    public var datatypeValue: String {
        self
    }

}

extension Blob: Binding, Value {

    public static let declaredDatatype = "BLOB"

    public static func fromDatatypeValue(_ datatypeValue: Blob) -> Blob {
        datatypeValue
    }

    public var datatypeValue: Blob {
        self
    }

}

// MARK: -

extension Bool: Binding, Value {

    public static var declaredDatatype = Int64.declaredDatatype

    public static func fromDatatypeValue(_ datatypeValue: Int64) -> Bool {
        datatypeValue != 0
    }

    public var datatypeValue: Int64 {
        self ? 1 : 0
    }

}

extension Int: Number, Value {

    public static var declaredDatatype = Int64.declaredDatatype

    public static func fromDatatypeValue(_ datatypeValue: Int64) -> Int {
        Int(datatypeValue)
    }

    public var datatypeValue: Int64 {
        Int64(self)
    }

}

extension UInt32: Number, Value {

    public static var declaredDatatype = Int64.declaredDatatype

    public static func fromDatatypeValue(_ datatypeValue: Int64) -> UInt32 {
        UInt32(datatypeValue)
    }

    public var datatypeValue: Int64 {
        Int64(self)
    }

}

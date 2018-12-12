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

import Foundation

extension QueryType {
    /// Creates an `INSERT` statement by encoding the given object
    /// This method converts any custom nested types to JSON data and does not handle any sort
    /// of object relationships. If you want to support relationships between objects you will
    /// have to provide your own Encodable implementations that encode the correct ids.
    ///
    /// - Parameters:
    ///
    ///   - encodable: An encodable object to insert
    ///
    ///   - userInfo: User info to be passed to encoder
    ///
    ///   - otherSetters: Any other setters to include in the insert
    ///
    /// - Returns: An `INSERT` statement fort the encodable object
    public func insert(_ encodable: Encodable, userInfo: [CodingUserInfoKey:Any] = [:], otherSetters: [Setter] = []) throws -> Insert {
        let encoder = SQLiteEncoder(userInfo: userInfo)
        try encodable.encode(to: encoder)
        return self.insert(encoder.setters + otherSetters)
    }

    /// Creates an `UPDATE` statement by encoding the given object
    /// This method converts any custom nested types to JSON data and does not handle any sort
    /// of object relationships. If you want to support relationships between objects you will
    /// have to provide your own Encodable implementations that encode the correct ids.
    ///
    /// - Parameters:
    ///
    ///   - encodable: An encodable object to insert
    ///
    ///   - userInfo: User info to be passed to encoder
    ///
    ///   - otherSetters: Any other setters to include in the insert
    ///
    /// - Returns: An `UPDATE` statement fort the encodable object
    public func update(_ encodable: Encodable, userInfo: [CodingUserInfoKey:Any] = [:], otherSetters: [Setter] = []) throws -> Update {
        let encoder = SQLiteEncoder(userInfo: userInfo)
        try encodable.encode(to: encoder)
        return self.update(encoder.setters + otherSetters)
    }
}

extension Row {
    /// Decode an object from this row
    /// This method expects any custom nested types to be in the form of JSON data and does not handle
    /// any sort of object relationships. If you want to support relationships between objects you will
    /// have to provide your own Decodable implementations that decodes the correct columns.
    ///
    /// - Parameter: userInfo
    ///
    /// - Returns: a decoded object from this row
    public func decode<V: Decodable>(userInfo: [CodingUserInfoKey: Any] = [:]) throws -> V {
        return try V(from: self.decoder(userInfo: userInfo))
    }

    public func decoder(userInfo: [CodingUserInfoKey: Any] = [:]) -> Decoder {
        return SQLiteDecoder(row: self, userInfo: userInfo)
    }
}

/// Generates a list of settings for an Encodable object
fileprivate class SQLiteEncoder: Encoder {
    class SQLiteKeyedEncodingContainer<MyKey: CodingKey>: KeyedEncodingContainerProtocol {
        typealias Key = MyKey

        let encoder: SQLiteEncoder
        let codingPath: [CodingKey] = []

        init(encoder: SQLiteEncoder) {
            self.encoder = encoder
        }

        func superEncoder() -> Swift.Encoder {
            fatalError("SQLiteEncoding does not support super encoders")
        }

        func superEncoder(forKey key: Key) -> Swift.Encoder {
            fatalError("SQLiteEncoding does not support super encoders")
        }

        func encodeNil(forKey key: SQLiteEncoder.SQLiteKeyedEncodingContainer<Key>.Key) throws {
            self.encoder.setters.append(Expression<String?>(key.stringValue) <- nil)
        }

        func encode(_ value: Int, forKey key: SQLiteEncoder.SQLiteKeyedEncodingContainer<Key>.Key) throws {
            self.encoder.setters.append(Expression(key.stringValue) <- value)
        }

        func encode(_ value: Bool, forKey key: Key) throws {
            self.encoder.setters.append(Expression(key.stringValue) <- value)
        }

        func encode(_ value: Float, forKey key: Key) throws {
            self.encoder.setters.append(Expression(key.stringValue) <- Double(value))
        }

        func encode(_ value: Double, forKey key: Key) throws {
            self.encoder.setters.append(Expression(key.stringValue) <- value)
        }

        func encode(_ value: String, forKey key: Key) throws {
            self.encoder.setters.append(Expression(key.stringValue) <- value)
        }

        func encode<T>(_ value: T, forKey key: Key) throws where T : Swift.Encodable {
            if let data = value as? Data {
                self.encoder.setters.append(Expression(key.stringValue) <- data)
            }
            else {
                let encoded = try JSONEncoder().encode(value)
                let string = String(data: encoded, encoding: .utf8)
                self.encoder.setters.append(Expression(key.stringValue) <- string)
            }
        }

        func encode(_ value: Int8, forKey key: Key) throws {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: self.codingPath, debugDescription: "encoding an Int8 is not supported"))
        }

        func encode(_ value: Int16, forKey key: Key) throws {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: self.codingPath, debugDescription: "encoding an Int16 is not supported"))
        }

        func encode(_ value: Int32, forKey key: Key) throws {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: self.codingPath, debugDescription: "encoding an Int32 is not supported"))
        }

        func encode(_ value: Int64, forKey key: Key) throws {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: self.codingPath, debugDescription: "encoding an Int64 is not supported"))
        }

        func encode(_ value: UInt, forKey key: Key) throws {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: self.codingPath, debugDescription: "encoding an UInt is not supported"))
        }

        func encode(_ value: UInt8, forKey key: Key) throws {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: self.codingPath, debugDescription: "encoding an UInt8 is not supported"))
        }

        func encode(_ value: UInt16, forKey key: Key) throws {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: self.codingPath, debugDescription: "encoding an UInt16 is not supported"))
        }

        func encode(_ value: UInt32, forKey key: Key) throws {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: self.codingPath, debugDescription: "encoding an UInt32 is not supported"))
        }

        func encode(_ value: UInt64, forKey key: Key) throws {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: self.codingPath, debugDescription: "encoding an UInt64 is not supported"))
        }

        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError("encoding a nested container is not supported")
        }

        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            fatalError("encoding nested values is not supported")
        }
    }

    fileprivate var setters: [Setter] = []
    let codingPath: [CodingKey] = []
    let userInfo: [CodingUserInfoKey: Any]

    init(userInfo: [CodingUserInfoKey: Any]) {
        self.userInfo = userInfo
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError("not supported")
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("not supported")
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(SQLiteKeyedEncodingContainer(encoder: self))
    }
}

fileprivate class SQLiteDecoder : Decoder {
    class SQLiteKeyedDecodingContainer<MyKey: CodingKey> : KeyedDecodingContainerProtocol {
        typealias Key = MyKey

        let codingPath: [CodingKey] = []
        let row: Row

        init(row: Row) {
            self.row = row
        }

        var allKeys: [Key] {
            return self.row.columnNames.keys.compactMap({Key(stringValue: $0)})
        }

        func contains(_ key: Key) -> Bool {
            return self.row.hasValue(for: key.stringValue)
        }

        func decodeNil(forKey key: Key) throws -> Bool {
            return !self.contains(key)
        }

        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
            return try self.row.get(Expression(key.stringValue))
        }

        func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
            return try self.row.get(Expression(key.stringValue))
        }

        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "decoding an Int8 is not supported"))
        }

        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "decoding an Int16 is not supported"))
        }

        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "decoding an Int32 is not supported"))
        }

        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "decoding an UInt64 is not supported"))
        }

        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "decoding an UInt is not supported"))

        }

        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "decoding an UInt8 is not supported"))
        }

        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "decoding an UInt16 is not supported"))
        }

        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "decoding an UInt32 is not supported"))
        }

        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "decoding an UInt64 is not supported"))
        }

        func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
            return Float(try self.row.get(Expression<Double>(key.stringValue)))
        }

        func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
            return try self.row.get(Expression(key.stringValue))
        }

        func decode(_ type: String.Type, forKey key: Key) throws -> String {
            return try self.row.get(Expression(key.stringValue))
        }

        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Swift.Decodable {
            if type == Data.self {
                let data = try self.row.get(Expression<Data>(key.stringValue))
                return data as! T
            }
            guard let JSONString = try self.row.get(Expression<String?>(key.stringValue)) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "an unsupported type was found"))
            }
            guard let data = JSONString.data(using: .utf8) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "invalid utf8 data found"))
            }
            return try JSONDecoder().decode(type, from: data)
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "decoding nested containers is not supported"))
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "decoding unkeyed containers is not supported"))
        }

        func superDecoder() throws -> Swift.Decoder {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "decoding super encoders containers is not supported"))
        }

        func superDecoder(forKey key: Key) throws -> Swift.Decoder {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "decoding super decoders is not supported"))
        }
    }

    let row: Row
    let codingPath: [CodingKey] = []
    let userInfo: [CodingUserInfoKey: Any]

    init(row: Row, userInfo: [CodingUserInfoKey: Any]) {
        self.row = row
        self.userInfo = userInfo
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(SQLiteKeyedDecodingContainer(row: self.row))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "decoding an unkeyed container is not supported"))
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "decoding a single value container is not supported"))
    }
}


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

extension Data: SafeValue {

    public static var declaredDatatype: String {
        Blob.declaredDatatype
    }

    public static func fromDatatypeValue(_ dataValue: Blob) -> Data {
        Data(dataValue.bytes)
    }

    public var datatypeValue: Blob {
        withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Blob in
            Blob(bytes: pointer.baseAddress!, length: count)
        }
    }

}

extension Date: SafeValue {

    public static var declaredDatatype: String {
        return Double.declaredDatatype
    }

    /// - Parameter doubleValue: Time interval since 1970 (Unix Epoch).
    public static func fromDatatypeValue(_ doubleValue: Double) -> Date {
        return Date(timeIntervalSince1970: doubleValue)
    }

    /// Time interval since 1970 (Unix Epoch).
    public var datatypeValue: Double {
        return timeIntervalSince1970
    }

}

/// A global date formatter used to serialize and deserialize `NSDate` objects.
/// If multiple date formats are used in an application’s database(s), use a
/// custom `Value` type per additional format.
public var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()

extension UUID: SafeValue {

    public static var declaredDatatype: String {
        String.declaredDatatype
    }

    public static func fromDatatypeValue(_ stringValue: String) -> UUID {
        UUID(uuidString: stringValue)!
    }

    public var datatypeValue: String {
        uuidString
    }

}

extension URL: RiskyValue {

	public enum URLRiskyValueError: Error {
		case urlFromStringFailed(String)
	}

	public typealias Datatype = String

	public var datatypeValue: String {
		return absoluteString
	}

	public static var declaredDatatype: String {
		String.declaredDatatype
	}

	public static func fromDatatypeValue(_ datatypeValue: String) throws -> URL {
		guard let url = URL(string: datatypeValue) else { throw URLRiskyValueError.urlFromStringFailed(datatypeValue) }
		return url
	}
}

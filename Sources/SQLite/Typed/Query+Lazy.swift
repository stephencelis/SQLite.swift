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

extension Array where Element == LazySequence<AnyIterator<Row>> {
	@available(swift, deprecated: 1, message: "Please use return value of prepare as Array directly")
	public init(_ values: Element) {
		preconditionFailure("Please use return value of prepare as Array directly")
	}
}

extension Connection {
	@_disfavoredOverload
	public func prepare(_ query: QueryType) throws -> [Row] {
		let expression = query.expression
		let statement = try prepare(expression.template, expression.bindings)

		let columnNames = try columnNamesForQuery(query)

		return Array(AnyIterator {
			statement.next().map { cursor in
				Row(columnNames, (0..<columnNames.count).map({
					try? cursor.getValue($0) as Binding?
				}))
			}
		})
	}

	public func prepare(_ query: QueryType) throws -> LazySequence<AnyIterator<Row>> {
		let expression = query.expression
		let statement = try prepare(expression.template, expression.bindings)

		let columnNames = try columnNamesForQuery(query)

		return AnyIterator { statement.next().map { Row(columnNames, $0) } }.lazy
	}
}

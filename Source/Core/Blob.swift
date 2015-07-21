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

public struct Blob {

    public var bytes: UnsafePointer<Void> {
        return UnsafePointer(implementation.bytes)
    }

    public var length: Int {
        return implementation.length
    }

    public init(bytes: UnsafePointer<Void>, length: Int) {
        self.implementation = Implementation(bytes: bytes, length: length)
    }

    // MARK: -

    private var implementation: Implementation

    private final class Implementation {

        let bytes: UnsafeMutablePointer<UInt8>
        let length: Int

        init(bytes: UnsafePointer<Void>, length: Int) {
            self.bytes = UnsafeMutablePointer.alloc(length + 1)
            self.length = length

            memcpy(self.bytes, bytes, length)
            self.bytes[length] = 0
        }

        deinit {
            bytes.dealloc(length + 1)
        }

    }

}

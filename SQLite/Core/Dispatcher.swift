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


/// Block dispatch method
public protocol Dispatcher {
    
    /// Dispatches the provided block
    func dispatch(block: dispatch_block_t)
    
}


/// Dispatches block immediately on current thread
public final class ImmediateDispatcher : Dispatcher {
    
    public func dispatch(block: dispatch_block_t) {
        block()
    }
    
}


/// Synchronously dispatches block on a serial
/// queue. Specifically allows reentrant calls
public final class ReentrantDispatcher : Dispatcher {
    
    static let queueKey = unsafeBitCast(ReentrantDispatcher.self, UnsafePointer<Void>.self)
    
    let queue : dispatch_queue_t
    
    let queueContext : UnsafeMutablePointer<Void>
    
    public init(_ name: String) {
        queue = dispatch_queue_create(name, DISPATCH_QUEUE_SERIAL)
        queueContext = unsafeBitCast(queue, UnsafeMutablePointer<Void>.self)
        dispatch_queue_set_specific(queue, ReentrantDispatcher.queueKey, queueContext, nil)
    }
    
    public func dispatch(block: dispatch_block_t) {
        if dispatch_get_specific(ReentrantDispatcher.queueKey) == self.queueContext {
            block()
        } else {
            dispatch_sync(self.queue, block) // FIXME: rdar://problem/21389236
        }
    }
    
}

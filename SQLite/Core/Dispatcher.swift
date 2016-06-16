//
//  Dispatcher.swift
//  SQLite
//
//  Created by Kevin Wooten on 11/28/15.
//  Copyright © 2015 stephencelis. All rights reserved.
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
  
  let queueContext : UnsafeMutablePointer<Void>!
  
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

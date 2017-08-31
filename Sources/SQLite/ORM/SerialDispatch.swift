//
//  SerialDispatch.swift
//  GLRender
//
//  Created by dongpeng Lin on 09/08/2017.
//  Copyright © 2017 dongpeng Lin. All rights reserved.
//

import Foundation


public protocol SerialDispatch {
    var serialDispatchQueue:DispatchQueue { get }
    var dispatchQueueKey:DispatchSpecificKey<Int> { get }
}

public extension SerialDispatch {
    public func runOperationAsynchronously(_ operation:@escaping () -> ()) {
        self.serialDispatchQueue.async {
            operation()
        }
    }
    
    public func runOperationSynchronously(_ operation:@escaping () -> ()) {
        // TODO: Verify this works as intended
        if (DispatchQueue.getSpecific(key:self.dispatchQueueKey) == 81) {
            operation()
        } else {
            self.serialDispatchQueue.sync {
                operation()
            }
        }
    }
    
    public func runOperationSynchronously(_ operation:@escaping () throws -> ()) throws {
        var caughtError:Error? = nil
        runOperationSynchronously {
            do {
                try operation()
            } catch {
                caughtError = error
            }
        }
        if (caughtError != nil) {throw caughtError!}
    }
    
    public func runOperationSynchronously<T>(_ operation:@escaping () throws -> T) throws -> T {
        var returnedValue: T!
        try runOperationSynchronously {
            returnedValue = try operation()
        }
        return returnedValue
    }
    
    public func runOperationSynchronously<T>(_ operation:@escaping () -> T) -> T {
        var returnedValue: T!
        runOperationSynchronously {
            returnedValue = operation()
        }
        return returnedValue
    }
}

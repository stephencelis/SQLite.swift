//
//  Errors.swift
//  SQLite
//
//  Created by Kevin Wooten on 4/17/16.
//
//

import Foundation


public enum FunctionError : ErrorType, CustomStringConvertible {
    case UnsupportedArgumentType(type: Int32)
    case UnsupportedResultType(value: Binding)
    
    public var description : String {
        switch self {
        case UnsupportedArgumentType(let type):
            return "Unsupported argument type: \(type)"
        case UnsupportedResultType(let value):
            return "Unsupported result type for value: \(value)"
        }
    }
}

public enum BindingError : ErrorType, CustomStringConvertible {
    case UnsupportedType(value: Binding)
    case ParameterNotFound(name: String)
    case IncorrectParameterCount(expected: Int, provided: Int)

    public var description : String {
        switch self {
        case UnsupportedType(let value):
            return "Unsupported type for value: \(value)"
        case ParameterNotFound(let name):
            return "Parameter not found: \(name)"
        case let IncorrectParameterCount(expected, provided):
            return "Incorrect parameter count, \(provided) provided with \(expected) expected"
        }
    }
}

public enum QueryError : ErrorType, CustomStringConvertible {
    case NoSuchTable(name: String)
    case NoSuchColumn(name: String)
    case AmbiguousColumn(name: String)
    
    public var description : String {
        switch self {
        case NoSuchTable(let name):
            return "No such table: \(name)"
        case NoSuchColumn(let name):
            return "No such column: \(name)"
        case AmbiguousColumn(let name):
            return "Ambiguous column: \(name)"
        }
    }
}

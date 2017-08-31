//
//  MAObjectSchema.swift
//  FaceU
//
//  Created by dongpeng Lin on 25/04/2017.
//  Copyright © 2017 dongpeng Lin. All rights reserved.
//

import Foundation
import SQLite

final class MAObjectSchema : NSObject {
    
    public var properties : [MAProperty]
    public var className : String
    private let primaryKeyIndex : Int
    public let objClass : MAObject.Type
    
    init(className:String, properties:[MAProperty], primaryKeyIndex:NSInteger, cl:MAObject.Type) {
        self.properties = properties
        self.className = className
        self.primaryKeyIndex = primaryKeyIndex
        self.objClass = cl
    }
    
    func primaryKeyProperty() -> MAProperty {
        return properties[primaryKeyIndex]
    }
    
    func modelColumns() -> [String] {
        var columns = [String]()
        for property in properties {
            columns.append(property.name)
        }
        return columns
    }
    
}

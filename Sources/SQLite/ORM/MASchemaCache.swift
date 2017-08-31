//
//  MASchemaCache.swift
//  FaceU
//
//  Created by dongpeng Lin on 28/04/2017.
//  Copyright © 2017 dongpeng Lin. All rights reserved.
//

import Foundation
import SQLite


public final class MASchemaCache : NSObject {
    
    static var schemaCache:[String : MAObjectSchema] = [:]
    static var tableCache:[String : Table] = [:]
    
    static var tableModelDictionary:[String:String] = [:] //tableName:MAObjectModel
    
    static func objectSchema(_ model:MAObject) -> MAObjectSchema {
        let name = NSStringFromClass(type(of: model))
        if let obj = schemaCache[name] {
            return obj
        }
        let schema = model.generalSchema()
        schemaCache[name] = schema
        return schema
    }
    
    static func objectSchema<T:MAObject>(_ m:T.Type) -> MAObjectSchema {
        let name = NSStringFromClass(m)
        if let obj = schemaCache[name] {
            return obj
        }
        let model = m.init()
        let schema = model.generalSchema()
        schemaCache[name] = schema
        return schema
    }
    
    static func schemaTableForObject(model:MAObject, tableName:String, operation:MAOperation) -> (Table, MAObjectSchema) {
        let schema = objectSchema(model)
        var table = tableCache[tableName]
        if table == nil {
            table = operation.createTable(table: tableName, model: model)
            updateTableModelCache(tableName: tableName, modelName: schema.className)
            tableCache[tableName] = table
        }
        return (table!, schema)
    }
    
    static func schemaTableForObject<T:MAObject>(_ m:T.Type, tableName:String, operation:MAOperation) -> (Table, MAObjectSchema) {
        let schema = objectSchema(m)
        var table = tableCache[tableName]
        if table == nil {
            let model = m.init()
            table = operation.createTable(table: tableName, model: model)
            updateTableModelCache(tableName: tableName, modelName: schema.className)
            tableCache[tableName] = table
        }
        return (table!, schema)
    }
    
    public static func cleanAll() {
        tableCache = [:]
        loadTableCache()
    }
    
    static func updateTableModelCache(tableName:String, modelName:String) {
        if tableModelDictionary[tableName] == nil {
            tableModelDictionary[tableName] = modelName
            DispatchQueue.global().async {
                let url = tableUrl()
                if NSKeyedArchiver.archiveRootObject(tableModelDictionary, toFile: url) {
                    print(tableModelDictionary)
                }
            }
        }
    }
    
    static func loadTableCache() {
        let url = tableUrl()
            if let dic = NSKeyedUnarchiver.unarchiveObject(withFile: url) as? [String:String] {
                print(dic)
                tableModelDictionary = dic
            }
    }
    
    private static func tableUrl() -> String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let authId = "000"
        return "\(path)/\(authId).tableCache"
    }

}

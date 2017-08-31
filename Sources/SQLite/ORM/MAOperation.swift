//
//  MAOperation.swift
//  FaceU
//
//  Created by dongpeng Lin on 25/04/2017.
//  Copyright © 2017 dongpeng Lin. All rights reserved.
//

import Foundation
import SQLite


public class MAOperation : NSObject, SerialDispatch {
    
    public weak var db : Connection!
    public let serialDispatchQueue: DispatchQueue = DispatchQueue(label: "com.db.contextQueue", qos: .default, attributes: .concurrent)
    
    public let dispatchQueueKey = DispatchSpecificKey<Int>()
    
    public func save(model:MAObject, inTableName:String) {
        runOperationAsynchronously {
            let (table, schema) = MASchemaCache.schemaTableForObject(model: model, tableName: inTableName, operation:self)
            self.save(model: model, table: table, schema: schema)
        }
        
    }
    
    private func save(model:MAObject, table:Table, schema:MAObjectSchema) {
        var ary:[Setter] = []
        for pt in schema.properties {
            ary.append(pt.generalSetter(model: model))
        }
        do {
            try self.db.run(table.insert(or: .replace, ary))
        } catch {
            MAOperation.sqliteError("MAlite error, save: \(error)")
        }
    }
    
    public func saveAll(models:[MAObject], inTableName:String) {
        
        runOperationAsynchronously {
            NSLog("aaa begin save models in \(inTableName)")
            guard models.count > 0, inTableName.characters.count > 0 else {
                return
            }
            let model = models.first!
            let (table, schema) = MASchemaCache.schemaTableForObject(model: model, tableName: inTableName, operation:self)
            do {
                try self.db.transaction {
                    for model in models {
                        self.save(model: model, table: table, schema: schema)
//                        var ary:[Setter] = []
//                        for pt in schema.properties {
//                            ary.append(pt.generalSetter(model: model))
//                        }
//                        try self.db.run(table.insert(or: .replace, ary))
                    }
                }
            } catch {
                print(error)
            }
            NSLog("aaa end save models in \(inTableName)")
        }
        
    }
    
    public func delete(model:MAObject, inTableName:String) {
        runOperationAsynchronously {
            let (table, schema) = MASchemaCache.schemaTableForObject(model: model, tableName: inTableName, operation:self)
            do {
                let pt = schema.primaryKeyProperty()
                let filterTable = table.filter(pt.filter(model: model))
                try self.db.run(filterTable.delete())
            } catch {
                MAOperation.sqliteError("MAlite error, delete: \(error)")
            }
        }
    }
    
    
    public func queryAll(_ m:MAObject, inTableName:String) -> [MAObject] {
        var items:[MAObject] = []
        runOperationAsynchronously {
            let (table, schema) =  MASchemaCache.schemaTableForObject(model: m, tableName: inTableName, operation:self)
            do {
                let datas = try self.db.prepare(table)
                for data in datas {
                    let item = schema.objClass.init()
                    for pt in schema.properties {
                        pt.convertcolumnToModel(model: item, row: data)
                    }
                    items.append(item)
                }
            } catch {
                MAOperation.sqliteError("MAlite error, queryall: \(error)")
            }
        }
        return items
    }
    
    public func queryAll<T:MAObject>(_ m:T.Type, inTableName:String) -> [T] {
        var items:[T] = []
        runOperationSynchronously {
            let (table, schema) =  MASchemaCache.schemaTableForObject(m, tableName: inTableName, operation:self)
            do {
                let datas = try self.db.prepare(table)
                for data in datas {
                    let item = schema.objClass.init()
//                    data.convertToModel(model: item)
                    for pt in schema.properties {
                        pt.convertcolumnToModel(model: item, row: data)
                    }
                    items.append(item as! T)
                }
            } catch {
                MAOperation.sqliteError("MAlite error, queryAll: \(error)")
            }
        }
        return items
    }
    
    public func query<T:MAObject>(_ m:T.Type, inTableName:String, primaryKey:Any) -> T? {
        let model = m.init()
        var exist = false
        runOperationSynchronously {
            let (table, schema) = MASchemaCache.schemaTableForObject(m, tableName: inTableName, operation: self)
            let pt = schema.primaryKeyProperty()
            let filterTable = table.filter(pt.filter(key: primaryKey))
            do {
                let datas = try self.db.prepare(filterTable)
                for data in datas {
                    for pp in schema.properties {
                        pp.convertcolumnToModel(model: model, row: data)
                    }
                    exist = true
                    break

                }
            } catch {
                MAOperation.sqliteError("get item error:\(error)")
            }
        }
        
        return exist ? model : nil
    }
    
    
    func createTable(table:String, model:MAObject) -> Table {
        let tb = Table(table)
        runOperationSynchronously {
            let schema = MASchemaCache.objectSchema(model)
            do {
                try self.db.run(tb.create(ifNotExists: true, block: { (t) in
                    for pt in schema.properties {
                        pt.buildColumn(builder: t)
                    }
                }))
            } catch {
                MAOperation.sqliteError("MAlite error, createTable: \(error)")
            }
        }
        return tb
    }
    
    func crateTable<T:MAObject>(_ m:T.Type, tableName:String) {
        let model = m.init()
        _ = createTable(table: tableName, model: model)
    }
    
    public func flushTable(_ tableName:String) {
        runOperationAsynchronously {
            if let table = MASchemaCache.tableCache[tableName] {
                do {
                    try self.db.run(table.delete())
                } catch {
                    MAOperation.sqliteError("MAlite error,flushTable: \(error)")
                }
            }
        }
    }
    
    public class func sqliteError(_ message:String) {
        #if DEBUG
            fatalError(message)
        #else
            print(message)
        #endif
    }
    
    
}


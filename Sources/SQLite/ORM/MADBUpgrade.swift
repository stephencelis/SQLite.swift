//
//  MADBUpgrade.swift
//  FaceU
//
//  Created by dongpeng Lin on 12/07/2017.
//  Copyright © 2017 dongpeng Lin. All rights reserved.
//

import Foundation
import SQLite

extension  Connection {
    public var userVersion : Int32 {
        get { return Int32(try! scalar("PRAGMA user_version") as! Int64) }
        set { try! run("PRAGMA user_version = \(newValue)") }
    }
    
    public func columns(tableName:String) -> [String] {
        let MAl = "PRAGMA table_info(\(tableName))"
        do {
            let state = try prepare(MAl)
            var existColumns:[String] = []
            for row in state {
                existColumns.append(row[1]! as! String)
            }
            return existColumns
            
            //                        let table = try Array(_db.prepare(MAl))
            //                        var existColumns:[String] = []
            //                        for line in table {
            //                            existColumns.append(line[1]! as! String)
            //                        }

        } catch {
            print(error)
        }
        return []
    }
    
    public func dbUpdate() {
        let version = self.userVersion
        if let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            let intVersion = Int32(bundleVersion.replacingOccurrences(of: ".", with: ""))!
            if intVersion != version {
                for (tableName, model) in MASchemaCache.tableModelDictionary {
                    let swiftModel = "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String).\(model)"
                    if let cl = NSClassFromString(swiftModel) as? MAObject.Type {
                        let schema = MASchemaCache.objectSchema(cl)
                        let table = Table(tableName)
                        do {
                            let columns = self.columns(tableName: schema.className)
                            var left = [MAProperty]()
                            for property in schema.properties {
                                if !columns.contains(property.name) {
                                    left.append(property)
                                }
                            }
                            if left.count > 0 {
                                for property in left {
                                    try self.run(property.addColumn(table: table))
                                }
                            }
                        } catch {
                            print(error)
                        }
                    }
                }
                self.userVersion = intVersion
            }
        }
    }

}

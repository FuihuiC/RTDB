//
//  RTTableInfo.swift
//  RTDatabase
//
//  Created by ENUUI on 2018/6/3.
//

import Foundation
class RTFTableInfo {
    var tableName: String
    var columns: [RTFType]
    
    lazy var create: String? = {
        return creatSql(self.tableName, self.columns)
    }()
    
    lazy var insert: String? = {
        return insertSql(self.tableName, self.columns)
    }()
    
    lazy var update: String? = {
        return updateSql(self.tableName, self.columns)
    }()
    
    lazy var delete: String? = {
        return deleteSql(self.tableName)
    }()
    
    init(_ tableName: String, _ columns: [RTFType]) {
        self.tableName = tableName
        self.columns = columns
    }
}

fileprivate func creatSql(_ tableName: String, _ columns: [RTFType]) -> String? {
    
    guard columns.count > 0 else { return nil }
    
    var sql = "CREATE TABLE if not exists '" + tableName + "' ('_id' integer primary key autoincrement not null"
    
    for type in columns {
        sql += ", " + type.bindStr
    }
    sql += ")"
    return sql
}

fileprivate func insertSql(_ tableName: String, _ columns: [RTFType]) -> String? {
    guard columns.count > 0 else { return nil }
    
    var cols = " ("
    var vals = " VALUES ("
    var i = 0
    
    for type in columns {
        let end = (i == (columns.count - 1)) ? ")" : ", "
        
        cols += type.name + end
        vals += ":" + type.name + end
        
        i += 1
    }
    
    let sql = "INSERT INTO " + tableName + cols + vals
    return sql
}

fileprivate func updateSql(_ tableName: String, _ columns: [RTFType]) -> String? {
    guard columns.count > 0 else { return nil }
    
    var sql = "UPDATE " + tableName + " SET "
    var i = 0
    for type in columns {
        let end = (i == (columns.count - 1)) ? " = ?" : " = ?, "
        sql += type.name + end
        
        i += 1
    }
    
    sql += " WHERE _id = "
    return sql
}

fileprivate func deleteSql(_ tableName: String) -> String? {
    return "DELETE FROM " + tableName + " WHERE _id ="
}

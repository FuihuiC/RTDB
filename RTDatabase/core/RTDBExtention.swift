//
//  RTDBExtention.swift
//  RTDatabase
//
//  Created by ENUUI on 2018/6/3.
//

import Foundation

fileprivate var dictCacheTableInfo = [String: RTFTableInfo]()
fileprivate var semaphore = DispatchSemaphore(value: 1)

fileprivate enum RTFBaseOperation {
    case Insert
    case Update
    case Delete
}

//extension RTFDBDefault: RTDB {
extension RTDB {
    /// Create a table by class following RTFAble
    public func createTable(_ cls: AnyClass) throws {
        let (info, err) = infoFor(cls)
        
        if err != nil {
            throw err!
        }
        
        if let creatSql = info!.create {
            try self.exec(query: creatSql)
        } else {
            throw RTError(103, "Found out an empty create sql!")
        }
    }
    
    /// insert a row
    public func insertTable<T: RTFAble>(_ obj: T) throws {
        try baseOperate(RTFBaseOperation.Insert, obj)
    }
    
    /// update a row
    public func updateTable<T: RTFAble>(_ obj: T) throws {
        try baseOperate(RTFBaseOperation.Update, obj)
    }
    
    /// delete a row
    public func deleteTable<T: RTFAble>(_ obj: T) throws {
        try baseOperate(RTFBaseOperation.Delete, obj)
    }
}

extension RTDB {
    
    fileprivate func baseOperate<T: RTFAble>(_ op: RTFBaseOperation, _ obj: T) throws {
        let (info, err) = infoFor(T.self)
        if err != nil {
            throw err!
        }
        var query: String?
        switch op {
        case .Insert:
            query = info?.insert
        case .Update:
            query = info?.update
        case .Delete:
            query = info?.delete
        }
        
        if query == nil {
            throw RTError(103, "Found out an empty base operate sql!")
        }
        
        if op == .Update || op == .Delete {
            query! += "\(obj._id)"
        }
        
        var values: [Any]?
        if op == .Insert || op == .Update {
            values = columnValues(obj)
        }
        
        try self.exec(query: query!, arrArgs: values)
    }
    
    fileprivate func columnValues<T: RTFAble>(_ obj: T) -> [Any] {
        let columns = T.columns
        var values = [Any]()
        for type in columns {
            if let v = obj.columnValue(forKey: type.name) {
                values.append(v)
            } else {
                values.append(NSNull())
            }
        }
        return values
    }
    
    fileprivate func infoFor(_ cls: AnyClass) -> (RTFTableInfo?, RTError?) {
        
        guard let clsAble = cls as? RTFAble.Type else {
            return (nil, RTError(103, "The class \(cls) does not follow protocol 'RTFAble'"))
        }
        semaphore.wait()
        var info = dictCacheTableInfo[clsAble.tableName]
        
        if info == nil  {
            let tableName = clsAble.tableName
            let columns = clsAble.columns
            
            if tableName.count == 0 {
                return (nil, RTError(103, "Class \(cls)'s tableName is emtpy!"))
            }
            if columns.count == 0 {
                return (nil, RTError(103, "Class \(cls)'s columns is emtpy!"))
            }
            
            info = RTFTableInfo(clsAble.tableName, clsAble.columns)
            dictCacheTableInfo[clsAble.tableName] = info
        }
        
        semaphore.signal()
        return (info, nil);
    }
}



//
//  RTDBExtention.swift
//  RTDatabase
//
//  Created by ENUUI on 2018/6/3.
//

import Foundation

fileprivate var dictCacheTableInfo = [String: RTFTableInfo]()
fileprivate var semaphore = DispatchSemaphore(value: 1)


//extension RTFDBDefault: RTDB {
extension RTDB {
    /// Create a table by class following RTFAble
    public func createTable(_ cls: AnyClass) throws {
        let (info, err) = infoFor(cls)
        
        if err != nil {
            throw err!
        }
        
        if let creatSql = info!.creat {
            do {
                try self.exec(query: creatSql)
            } catch let err {
                throw err
            }
        } else {
            throw RTError(103, "Found out an empty create sql!")
        }
    }
    
    /// insert a row
    public func insertTable<T: RTFAble>(_ obj: T) throws {
        let (info, err) = infoFor(T.self)
        if err != nil {
            throw err!
        }
        
        if let insert = info!.insert {
            do {
                try self.exec(query: insert, arrArgs: [1])
            } catch let err {
                throw err
            }
        } else {
            throw RTError(103, "Found out an empty insert sql!")
        }
    }
    
    fileprivate func columnValues<T: RTFAble>(_ obj: T) {
        let columns = T.columns
        var values = [Any]()
        for type in columns {
            
        }
    }
    
    /// update a row
    public func updateTable<T: RTFAble>(_ obj: T) throws {
        let (info, err) = infoFor(T.self)
        if err != nil {
            throw err!
        }
        
        if let update = info!.update {
            do {
                try self.exec(query: update + "\(obj._id)")
            } catch let err {
                throw err
            }
        } else {
            throw RTError(103, "Found out an empty update sql!")
        }
    }
    
    /// delete a row
    public func deleteTable<T: RTFAble>(_ obj: T) throws {
        let (info, err) = infoFor(T.self)
        if err != nil {
            throw err!
        }
        
        if let delete = info!.delete {
            do {
                try self.exec(query: delete + "\(obj._id)")
            } catch let err {
                throw err
            }
        } else {
            throw RTError(103, "Found out an empty delete sql!")
        }
    }
}

extension RTDB {
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



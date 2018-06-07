//
//  RTFAble.swift
//  RTDatabase
//
//  Created by ENUUI on 2018/6/3.
//

import Foundation


public enum RTFType {
    case _Int(String)
    case _Int8(String)
    case _Int16(String)
    case _Int32(String)
    case _Int64(String)
    
    case _Float(String)
    case _Double(String)
    
    case _Number(String)
    case _String(String)
    case _Data(String)
    case _Date(String)
}

extension RTFType {
    var name: String {
        switch self {
        case ._Int(let n):
            return n
        case ._Int8(let n):
            return n
        case ._Int16(let n):
            return n
        case ._Int32(let n):
            return n
        case ._Int64(let n):
            return n
            
        case ._Float(let n):
            return n
        case ._Double(let n):
            return n
        case ._Number(let n):
            return n
            
        case ._String(let n):
            return n
        case ._Data(let n):
            return n
        case ._Date(let n):
            return n
        }
    }
    
    var bindType: String {
        switch self {
        case ._Int, ._Int8, ._Int16, ._Int32, ._Int64:
            return "INTEGER"
        case ._Float, ._Double, ._Number, ._Date:
            return "REAL"
        case ._Data:
            return "BLOB"
        case ._String:
            return "TEXT"
        }
    }
    
    var bindStr: String {
        return "'" + name + "' '" + bindType + "'"
    }
}


public protocol RTFAble: AnyObject {
    
    var _id: Int64 { set get }
    
    static var tableName: String { set get }
    static var columns: [RTFType] { set get }
}

extension RTFAble {
    public func columnValue(forKey key: String) -> Any? {
        let objM = Mirror(reflecting: self)
        var value: Any?

        for item in objM.children {
            if let label = item.label {
                if label == key {
                    value = item.value
                    break
                }
            }
        }
        return value
    }
}

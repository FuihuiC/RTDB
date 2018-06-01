//
//  RTFDB.swift
//  RTDatabase
//
//  Created by hc-jim on 2018/6/1.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

import Foundation

open class RTFDB {
    public let db = RTDB()
    public var defaultQueue = DispatchQueue.main
    
    public init() {}
    
    public func onDefault() -> RTFDBExtra {
        return RTFDBExtra(db, defaultQueue)
    }
    
    public func onMain() -> RTFDBExtra {
        return RTFDBExtra(db, defaultQueue)
    }
    
    public func onQueue(_ q: DispatchQueue) -> RTFDBExtra {
        return RTFDBExtra(db, defaultQueue)
    }
    
    public func onClose() {
        db.close()
    }
}

typealias rt_sw_closure_t = ()->Void

public class RTFDBExtra {
    fileprivate var defaultQueue: DispatchQueue!
    fileprivate var db: RTDB!
    fileprivate var workQ: DispatchQueue?
    fileprivate var backMain = false
    fileprivate var error: Error?
    fileprivate var next: RTNext?
    
    init(_ db: RTDB, _ defaultQueue: DispatchQueue) {
        self.db = db
        self.defaultQueue = defaultQueue
    }
    
    public func onMain() -> RTFDBExtra {
        backMain = true
        workQ = nil
        return self;
    }
    
    public func onQueue(_ q: DispatchQueue) -> RTFDBExtra {
        self.backMain = false
        workQ = q
        return self
    }
    
    public func onDefault() -> RTFDBExtra {
        return onQueue(defaultQueue)
    }
    
    public func onError(_ closure: @escaping (Error?)->Void) {
        if self.error != nil {
            closure(self.error)
        }
    }
    
    // ------------------------------
    
    public func onOpen(_ path: String) -> RTFDBExtra {
        return self.onOpenFlags(path, RT_SQLITE_OPEN_CREATE | RT_SQLITE_OPEN_READWRITE | RT_SQLITE_OPEN_FULLMUTEX | RT_SQLITE_OPEN_SHAREDCACHE)
    }
    
    public func onOpenFlags(_ path: String, _ flags: Int32) -> RTFDBExtra {
        return onWorkQueue {
            self.openDB(path, flags)
        }
    }
    
    // -------------
    public func execDict(_ sql: String, _ params: [String: AnyObject]?) -> RTFDBExtra {
        return self.onWorkQueue {
            self.exec(sql, params, nil);
        }
    }
    
    public func execArr(_ sql: String, _ arrArgs: [AnyObject]?) -> RTFDBExtra {
        return self.onWorkQueue {
            self.exec(sql, nil, arrArgs)
        }
    }
    
    public func execArgs(_ args: AnyObject ...) -> RTFDBExtra {
        return self.onWorkQueue {
            let sql = args.first as! String
            let arrArgs = args.dropFirst()
            self.exec(sql, nil, Array(arrArgs))
        }
    }
}

extension RTFDBExtra {
    fileprivate func openDB(_ path: String, _ flags: Int32) {
        do {
            try self.db.open(path: path, flags: flags)
        } catch let err {
            self.error = err
        }
    }
    
    fileprivate func exec(_ sql: String, _ param: [String: AnyObject]?, _ arrArgs: [AnyObject]?) {
        var next: RTNext? = nil
        do {
            if param != nil {
                next = try self.db.exec(sql: sql, params: param)
            } else if arrArgs != nil {
                next = try self.db.exec(sql: sql, arrArgs: arrArgs)
            } else {
                next = try self.db.exec(sql: sql)
            }
        } catch let err {
            self.error = err
        }
        self.next = next
    }
}

extension RTFDBExtra {
    fileprivate func onWorkQueue(_ closure: @escaping rt_sw_closure_t) -> RTFDBExtra {
        let semaphore = DispatchSemaphore(value: 1)
        runClosure {
            closure()
            semaphore.signal()
        }
        semaphore.wait()
        return self;
    }
    
    fileprivate func runClosure(_ closure: @escaping rt_sw_closure_t) {
        if self.backMain {
            if !Thread.isMainThread {
                DispatchQueue.main.async(execute: closure)
            } else {
                closure();
            }
        } else if self.workQ != nil {
            workQ!.async(execute: closure)
        } else {
            closure();
        }
    }
}

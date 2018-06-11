//
//  RTFDB.swift
//  RTDatabase
//
//  Created by ENUUI on 2018/6/1.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

import Foundation

typealias rt_sw_closure_t = ()->Void

open class RTFDB {
    fileprivate var db = RTDB()
    
    public var defaultQueue: DispatchQueue?
    
    public init() {}
    
    public convenience init(defaultQueue: DispatchQueue?) {
        self.init()
        self.defaultQueue = defaultQueue
    }
    
    public var onMain: RTFDBExtra {
        return RTFDBExtra(db, defaultQueue).onMain
    }

    public var onDefault: RTFDBExtra {
        return RTFDBExtra(db, defaultQueue)
    }
    
    public func onQueue(_ q: DispatchQueue) -> RTFDBExtra {
        return RTFDBExtra(db, defaultQueue).onQueue(q)
    }
    
    public func onClose() {
        db.close()
    }
}

public class RTFDBExtra {
    fileprivate var defaultQueue: DispatchQueue?
    fileprivate var db: RTDB!
    fileprivate var workQ: DispatchQueue?
    fileprivate var backMain = false
    fileprivate var error: Error?
    fileprivate var next: RTNext?
    
    init(_ db: RTDB, _ defaultQueue: DispatchQueue?) {
        self.db = db
        if let dq = defaultQueue {
            self.defaultQueue = dq
        }
    }
    
    /// Change the queue to Main
    public var onMain: RTFDBExtra {
        self.backMain = true
        self.workQ = nil
        return self
    }
    
    /// Reset RTFDBExtra
    public var onDefault: RTFDBExtra {
        self.error = nil
        return onQueue(defaultQueue)
    }

    /// Change the queue to a custom queue
    public func onQueue(_ q: DispatchQueue?) -> RTFDBExtra {
        self.backMain = false
        self.workQ = q
        return self
    }
    
    // Out error
    public func onError(_ closure: @escaping (Error)->Void) {
        
        if let err = self.error {
            closure(err)
        }
    }
    
    // ------------------------------
    /// Open database.
    public func onOpen(_ path: String) -> RTFDBExtra {
        return self.onOpenFlags(path, RT_SQLITE_OPEN_CREATE | RT_SQLITE_OPEN_READWRITE | RT_SQLITE_OPEN_FULLMUTEX | RT_SQLITE_OPEN_SHAREDCACHE)
    }
    
    /// Open database.
    public func onOpenFlags(_ path: String, _ flags: Int32) -> RTFDBExtra {
        return onWorkQueue {
            self.openDB(path, flags)
        }
    }
    
    // -------------
    
    /// Execute sql.
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
    
    public func onNext(_ closure: @escaping (RTNext?)->Void) -> RTFDBExtra {
        return self.onWorkQueue {
            closure(self.next)
        }
    }
    
    public func onEnum(_ closure: @escaping ([AnyHashable: Any]?, Int32, UnsafeMutablePointer<ObjCBool>?)->Void) -> RTFDBExtra {
        return self.onWorkQueue {
            guard let n = self.next else { return }
            
            n.enumAllSteps { (dict, i, pStop, err) in
                self.error = err
                closure(dict, i, pStop)
            }
        }
    }
    
    public func onDone() -> RTFDBExtra {
        guard let n = self.next else { return self }
        
        return self.onWorkQueue {
            while (n.step()) {}
            self.error = n.finalError()
        }
    }
}

extension RTFDBExtra {
    /// create
    public func onCreate(_ cls: AnyClass) -> RTFDBExtra {
        return self.onWorkQueue {
            do {
                try self.db.createTable(cls)
            } catch let err {
                self.error = err
            }
        }
    }
    
    /// insert
    public func onInsert<T: RTFAble>(_ obj: T) -> RTFDBExtra {
        return self.onWorkQueue {
            do {
                try self.db.insertTable(obj)
            } catch let err {
                self.error = err
            }
        }
    }
    
    /// update
    public func onUpdate<T: RTFAble>(_ obj: T) -> RTFDBExtra {
        return self.onWorkQueue {
            do {
                try self.db.updateTable(obj)
            } catch let err {
                self.error = err
            }
        }
    }
    
    /// delete
    public func onDelete<T: RTFAble>(_ obj: T) -> RTFDBExtra {
        return self.onWorkQueue {
            do {
                try self.db.deleteTable(obj)
            } catch let err {
                self.error = err
            }
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
        if self.error != nil {
            return self
        }
        
        let semaphore = DispatchSemaphore(value: 1)
        self.runClosure {
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

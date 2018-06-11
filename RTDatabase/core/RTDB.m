//
//  RTDB.m
//  RTSQLite
//
//  Created by ENUUI on 2018/5/3.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTDB.h"

@implementation RTDB
- (void *)sqlite3_db {
    return self->_db;
}
- (BOOL)close {
    BOOL suc = rt_sqlite3_close(_db);
    if (suc) {
        _db = nil;
    }
    return suc;
}

#pragma mark -
- (BOOL)openWithPath:(NSString *)path withError:(NSError *__autoreleasing *)error {
    NSAssert(path, @"DB path should not be empty!");
    
    int flags = RT_SQLITE_OPEN_CREATE | RT_SQLITE_OPEN_READWRITE | RT_SQLITE_OPEN_FULLMUTEX | RT_SQLITE_OPEN_SHAREDCACHE;
    return rt_sqlite3_open(&_db, path, flags, error);
}

- (BOOL)openWithPath:(NSString *)path withFlags:(int)flags withError:(NSError *__autoreleasing *)error {
    return rt_sqlite3_open(&_db, path, flags, error);
}

#pragma mark - PUBLIC

- (BOOL)execWithQuery:(NSString *)sql {
    return [self execQuery:sql withErr:NULL withParams:nil withArrArgs:nil withArgs:nil];
}

- (BOOL)execWithQuery:(NSString *)sql withError:(NSError *__autoreleasing *)err {
    return [self execQuery:sql withErr:err withParams:nil withArrArgs:nil withArgs:nil];
}

- (BOOL)execQuery:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION {
    va_list args;
    va_start(args, sql);
    BOOL result = [self execQuery:sql withErr:NULL withParams:nil withArrArgs:nil withArgs:args];
    va_end(args);
    return result;
}

- (BOOL)exceWithError:(NSError *__autoreleasing *)err withQuery:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION {
    va_list args;
    va_start(args, sql);
    BOOL result = [self execQuery:sql withErr:err withParams:nil withArrArgs:nil withArgs:args];
    va_end(args);
    return result;
}

- (BOOL)exceQuery:(NSString *)sql withArrArgs:(NSArray *)arrArgs {
    return [self execQuery:sql withErr:NULL withParams:nil withArrArgs:arrArgs withArgs:nil];
}

- (BOOL)exceQuery:(NSString *)sql withArrArgs:(NSArray *)arrArgs withError:(NSError *__autoreleasing *)err {
    return [self execQuery:sql withErr:err withParams:nil withArrArgs:arrArgs withArgs:nil];
}

- (BOOL)exceQuery:(NSString *)sql withParams:(NSDictionary *)params {
    return [self execQuery:sql withErr:NULL withParams:params withArrArgs:nil withArgs:nil];
}

- (BOOL)exceQuery:(NSString *)sql withParams:(NSDictionary *)params withError:(NSError *__autoreleasing *)err {
    return [self execQuery:sql withErr:err withParams:params withArrArgs:nil withArgs:nil];
}

// ----------------
- (RTNext *)execWithSql:(NSString *)sql {
    return [self execSql:sql withParams:nil withArrArgs:nil withArgs:nil withError:NULL];
}

- (RTNext *)execWithSql:(NSString *)sql withError:(NSError *__autoreleasing *)err {
    return [self execSql:sql withParams:nil withArrArgs:nil withArgs:nil withError:err];
}

- (RTNext *)execSql:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION {
    va_list args;
    va_start(args, sql);
    RTNext *next = [self execSql:sql withParams:nil withArrArgs:nil withArgs:args withError:NULL];
    va_end(args);
    
    return next;
}

- (RTNext *)execWithError:(NSError *__autoreleasing *)err withSql:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION {
    
    va_list args;
    va_start(args, sql);
    RTNext *next = [self execSql:sql withParams:nil withArrArgs:nil withArgs:args withError:err];
    va_end(args);
    
    return next;
}

- (RTNext *)execSql:(NSString *)sql withArrArgs:(NSArray *)arrArgs {
    return [self execSql:sql withParams:nil withArrArgs:arrArgs withArgs:nil  withError:NULL];
}

- (RTNext *)execSql:(NSString *)sql withArrArgs:(NSArray *)arrArgs withError:(NSError *__autoreleasing *)err {
    return [self execSql:sql withParams:nil withArrArgs:arrArgs withArgs:nil  withError:err];
}

- (RTNext *)execSql:(NSString *)sql withParams:(NSDictionary *)params {
    return [self execSql:sql withParams:params withArrArgs:nil withArgs:nil withError:NULL];
}

- (RTNext *)execSql:(NSString *)sql withParams:(NSDictionary *)params withError:(NSError *__autoreleasing *)err {
    
    return [self execSql:sql withParams:params withArrArgs:nil withArgs:nil  withError:err];
}


#pragma mark -
- (BOOL)execQuery:(NSString *)sql
          withErr:(NSError *__autoreleasing *)err
       withParams:(NSDictionary *)params
      withArrArgs:(NSArray *)arrArgs
         withArgs:(va_list)args {
    
    RTNext *next = [self execSql:sql withParams:params withArrArgs:arrArgs withArgs:args withError:err];

    
    if (!next) {
        return NO;
    }
    [next stepWithError:err];
    
    if (err != NULL && *err != nil) {
        return NO;
    } else return YES;
}

- (RTNext *)execSql:(NSString *)sql
         withParams:(NSDictionary *)params
        withArrArgs:(NSArray *)arrArgs
           withArgs:(va_list)args
          withError:(NSError *__autoreleasing *)err {
    
    DELog(@"RTDB: -sql: %@", sql);
    
    if (!sql || sql.length == 0) {
        rt_error([NSString stringWithFormat:@"RTDB: empty sql!"], 101, err);
        return nil;
    }
    
    void *stmt;
    if (!rt_sqlite3_prepare_v2(_db, [sql UTF8String], &stmt, err)) {
        return nil;
    };
    int bindcount = rt_sqlite3_bind_parameter_count(stmt);
    
    NSMutableArray *mArrArgs;
    if (arrArgs && arrArgs.count > 0) { // NSArray
        mArrArgs = [NSMutableArray arrayWithArray:arrArgs];
    } else if (args) {  // va_list
        mArrArgs = [NSMutableArray arrayWithCapacity:bindcount];
        id v;
        for (int i = 0; i < bindcount; i++) {
            v = va_arg(args, id);
            if (v) {
                [mArrArgs addObject:v];
            }
        }
    } else if (params && params.count > 0) { // NSDictionary
        sql = [self formatSqlForDictArgu:sql];
    }
    
    
    // bind data to sqilte
    
    int boundCount = 0;
    if (mArrArgs && mArrArgs.count > 0) {
        for (int i = 0; i < mArrArgs.count; i++) {
            id value = mArrArgs[i];
            rt_objc_t t = rt_object_class_type(value);
            
            int re = rt_sqlite3_bind(stmt, i + 1, value, t);
            if (rt_sqlite3_status_code(re) != RT_SQLITE_OK) {
                rt_sqlite3_err(re, err);
                break;
            }
            boundCount++;
        }
    } else if (params && params.count > 0) {
        
        NSArray *arrKeys = params.allKeys;
        int i = 0;
        for (NSString *dickey in arrKeys) {
            NSString *key = [@":" stringByAppendingString:dickey];
            int idx = rt_sqlite3_bind_param_index(stmt, [key UTF8String]);
            id value = params[dickey];
            if (idx == 0) {
                rt_error([NSString stringWithFormat:@"RTDB can not find a param for key: %@. -sql: %@", dickey, sql], 102, err);
                break;
            }
            rt_objc_t t = rt_object_class_type(value);
            rt_sqlite3_bind(stmt, idx, value, t);
            
            i++;
            boundCount++;
        }
    }
    
    if (boundCount != bindcount) {
        if (err != NULL && !(*err)) { // if no errmsg, build.
            rt_error(@"RTDB recieved sql paramters count is not equal to args for bind!", 102, err);
        }
        
        rt_sqlite3_finalize(&stmt);
        return nil;
    }
    
    RTNext *next = [[RTNext alloc] initWithStmt:stmt withSql:sql];
    
    return next;
}

// format sql for bind. change (?, ?...) to (:name1, :name2, ...)
- (NSString *)formatSqlForDictArgu:(NSString *)sql {
    BOOL sqlT = [sql containsString:@":"];
    NSString *sql_format = sql;
    if (!sqlT) {
        NSRange r1 = [sql rangeOfString:@"("];
        NSRange r2 = [sql rangeOfString:@")"];
        if (r1.length == 0 || r2.length == 0) { return sql; }
        
        NSString *strColumns = [sql substringWithRange:NSMakeRange(r1.location + 1, r2.location - r1.location - 1)];
        
        NSArray *arrColumns = [strColumns componentsSeparatedByString:@","];
        
        for (int i = 0; i < arrColumns.count; i++) {
            NSString *column = arrColumns[i];
            column = [column stringByReplacingOccurrencesOfString:@" " withString:@""];
            
            NSRange rangeAim = [sql_format rangeOfString:@"?"];
            if (rangeAim.length > 0) {
                sql_format = [sql_format stringByReplacingCharactersInRange:rangeAim withString:[@":" stringByAppendingString:column]];
            }
        }
        DELog(@"sql_format = %@", sql_format);
    }
    return sql_format;
}

// --------------------------------------
- (BOOL)begin {
    return [self execQuery:@"BEGIN", nil];
}

- (BOOL)commit {
    return [self execQuery:@"COMMIT", nil];
}

- (BOOL)rollback {
    return [self execQuery:@"ROLLBACK", nil];
}
@end

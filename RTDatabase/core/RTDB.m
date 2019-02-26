//
//  RTDB.m
//  RTDatebase
//
//  Created by hc-jim on 2019/2/25.
//  Copyright © 2019 ENUUI. All rights reserved.
//

#import "RTDB.h"
#import <sqlite3.h>
#import <objc/runtime.h>


#ifndef RT_DELog
#   ifdef DEBUG
#    define RT_DELog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#   else
#       define RT_DELog(...)
#   endif
#endif

const int baseCode = 10000;

void rt_error(NSString *errMsg, int code, NSError **err) {
    if (errMsg == nil) errMsg = @"Unknown err!";
    
    if (err == NULL) return;
    
    *err = [NSError errorWithDomain:NSCocoaErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: errMsg}];
}

// sqlite3 error handle
void rt_sqlite3_err(int result, NSError **err) {
    NSString *errMsg;
    if (@available(iOS 8.2, *)) {
        errMsg = [NSString stringWithUTF8String:sqlite3_errstr(result)];

    } else {
        errMsg = [NSString stringWithFormat:@"sqlite3 error code: %d", result];
    }
    int code = baseCode + result;
    
    rt_error(errMsg, code, err);
}
// -----------------------

static int rt_str_compare(const char *src1, const char *src2) {
    return (strcmp(src1, src2) == 0);
}

static rt_objc_t rt_object_class_type(id obj) {
    if (!obj || [obj isKindOfClass:[NSNull class]]) {
        return '0';
    }
    
    rt_objc_t t = '0';
    const char *clsName = class_getName([obj class]);
    
    if (rt_str_compare(clsName, "NSTaggedPointerString")
        || rt_str_compare(clsName, "__NSCFConstantString")
        ) {
        t = rttext;
    } else if (rt_str_compare(clsName, "NSConcreteMutableData")
               || rt_str_compare(clsName, "_NSInlineData")
               ) {
        t = rtblob;
    } else if (rt_str_compare(clsName, "__NSDate")) {
        t = rtdate;
    } else if (rt_str_compare(clsName, "__NSCFBoolean")) {
        t = rtbool;
    } else if (rt_str_compare(clsName, "__NSCFNumber")) {
        if (rt_str_compare([obj objCType], @encode(char))) {
            t = rtchar;
        } else if (rt_str_compare([obj objCType], @encode(unsigned char))) {
            t = rtuchar;
        } else if (rt_str_compare([obj objCType], @encode(short))) {
            t = rtshort;
        } else if (rt_str_compare([obj objCType], @encode(unsigned short))) {
            t = rtushort;
        } else if (rt_str_compare([obj objCType], @encode(int))) {
            t = rtint;
        } else if (rt_str_compare([obj objCType], @encode(unsigned int))) {
            t = rtuint;
        } else if (rt_str_compare([obj objCType], @encode(long))) {
            t = rtlong;
        } else if (rt_str_compare([obj objCType], @encode(unsigned long))) {
            t = rtulong;
        } else if (rt_str_compare([obj objCType], @encode(long long))) {
            t = rtlong;
        } else if (rt_str_compare([obj objCType], @encode(unsigned long long))) {
            t = rtulong;
        } else if (rt_str_compare([obj objCType], @encode(float))) {
            t = rtfloat;
        } else if (rt_str_compare([obj objCType], @encode(double))) {
            t = rtdouble;
        }
    }
    return t;
}

// sqlite3_bind
static int rt_sqlite3_bind(void *pstmt, int idx, id value, rt_objc_t objT) {
    int result = -1;
    sqlite3_stmt *stmt = (sqlite3_stmt *)pstmt;
    if (!value || (NSNull *)value == [NSNull null]) {
        result = sqlite3_bind_null(stmt, idx);
    } else {
        switch (objT) {
            case rttext:
                result = sqlite3_bind_text(stmt, idx, [value description].UTF8String, -1, SQLITE_STATIC);
                break;
            case rtblob: {
                const void *bytes = [value bytes];
                result = sqlite3_bind_blob(stmt, idx, bytes, (int)[value length], SQLITE_STATIC);
            }
                break;
            case rtnumber: {
                result = sqlite3_bind_double(stmt, idx, [value doubleValue]);
            }
                break;
            case rtfloat:
                result = sqlite3_bind_double(stmt, idx, [value floatValue]);
                break;
            case rtdouble:
                result = sqlite3_bind_double(stmt, idx, [value doubleValue]);
                break;
            case rtdate: {
                double dvalue = [value timeIntervalSince1970];
                result = sqlite3_bind_double(stmt, idx, dvalue);
            }
                break;
            case rtchar:
                result = sqlite3_bind_int(stmt, idx, [value charValue]);
                break;
            case rtuchar:
                result = sqlite3_bind_int(stmt, idx, [value unsignedCharValue]);
                break;
            case rtshort:
                result = sqlite3_bind_int(stmt, idx, [value shortValue]);
                break;
            case rtushort:
                result = sqlite3_bind_int(stmt, idx, [value unsignedShortValue]);
                break;
            case rtint:
                result = sqlite3_bind_int(stmt, idx, [value intValue]);
                break;
            case rtuint:
                result = sqlite3_bind_int64(stmt, idx, (long long)[value unsignedIntValue]);
                break;
            case rtlong:
                result = sqlite3_bind_int64(stmt, idx, [value longLongValue]);
                break;
            case rtulong:
                result = sqlite3_bind_int64(stmt, idx, (long long)[value unsignedLongLongValue]);
                break;
            case rtbool:
                result = sqlite3_bind_int(stmt, idx, ([value boolValue] ? 1 : 0));
                break;
            default:
                result = sqlite3_bind_text(stmt, idx, [[value description] UTF8String], -1, SQLITE_STATIC);
                break;
        }
    }
    return result;
}

// -------
static void rt_sqlite3_finalize(void *stmt) {
    if (stmt == NULL) return;
    
    sqlite3_finalize(stmt);
    stmt = 0x00;
}

@interface RTDB () {
    sqlite3 *_db;
}
@end


@implementation RTDB
#pragma mark - open/close db
- (BOOL)openWithPath:(NSString *)path withError:(NSError *__autoreleasing *)error {
    // open. create if not exit.
    // readwrite
    // sync
    int flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_SHAREDCACHE;
    
    return [self openWithPath:path withFlags:flags withError:error];
}

- (BOOL)openWithPath:(NSString *)path withFlags:(int)flags withError:(NSError *__autoreleasing *)error {
    int re = sqlite3_open_v2(path.UTF8String, &_db, flags, NULL);
    
    if (re != SQLITE_OK) {
        rt_sqlite3_err(re, error);
        return NO;
    }
    return YES;
}

- (BOOL)close {
    if (_db == NULL) {
        return YES;
    }
    
    int result;
    bool retry;
    bool closedStmt = false;
    
    do {
        retry = false;
        result = sqlite3_close(_db);
        if (result == SQLITE_BUSY || result == SQLITE_LOCKED) {
            if (!closedStmt) {
                sqlite3_stmt *stmt;
                while ((stmt = sqlite3_next_stmt(_db, nil)) != 0) {
                    sqlite3_finalize(stmt);
                    closedStmt = true;
                }
            }
        }
    } while (retry);
    
    _db = nil;
    
    return closedStmt;
}

#pragma mark -
/**
 * Execute the SQL statement and return if it is successful
 * If you select the (withError:) method and pass in (NSError **) err, the error message is transmitted when the execution fails.
 * Select the appropriate method according to the different parameters outside the SQL statement.
 */
- (BOOL)execWithQuery:(NSString *)sql {
    return [self execWithQuery:sql withError:nil];
}

- (BOOL)execWithQuery:(NSString *)sql withError:(NSError *__autoreleasing *)err {
    return [self execQuery:sql withDicValues:nil withArrValues:nil withListValues:NULL withError:err];
}

- (BOOL)execQuery:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION {
    va_list ap;
    va_start(ap, sql);
    
    BOOL re = [self execQuery:sql withDicValues:nil withArrValues:nil withListValues:ap withError:nil];
    
    va_end(ap);
    return re;
}

- (BOOL)execWithError:(NSError *__autoreleasing *)err withQuery:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION {
    va_list ap;
    va_start(ap, sql);
    
    BOOL re = [self execQuery:sql withDicValues:nil withArrValues:nil withListValues:ap withError:err];
    
    va_end(ap);
    return re;
}

- (BOOL)exceQuery:(NSString *)sql withArrValues:(NSArray *)arrValues {
    return [self execQuery:sql withArrValues:arrValues withError:nil];
}

- (BOOL)execQuery:(NSString *)sql withArrValues:(NSArray *)arrValues withError:(NSError *__autoreleasing *)err {
    
    return [self execQuery:sql withDicValues:nil withArrValues:arrValues withListValues:NULL withError:err];
}

- (BOOL)execQuery:(NSString *)sql withDicValues:(NSDictionary *)dicValues {
    return [self execQuery:sql withDicValues:dicValues withError:nil];
}

- (BOOL)execQuery:(NSString *)sql withDicValues:(NSDictionary *)dicValues withError:(NSError *__autoreleasing *)err {
    return [self execQuery:sql withDicValues:dicValues withArrValues:nil withListValues:NULL withError:err];
}

#pragma mark -
/**
 * Execute the SQL statement and return an object of RTNext. For details, please see RTNext class.
 * If you select the (withError:) method and pass in (NSError **) err, the error message is transmitted when the execution fails.
 * Select the appropriate method according to the different parameters outside the SQL statement.
 */
- (RTNext *)execSQL:(NSString *)sql {
    return [self execSQL:sql withError:nil];
}

- (RTNext *)execSQL:(NSString *)sql withError:(NSError *__autoreleasing *)err {
    return [self execSQL:sql withDicValues:nil withArrValues:nil withListValues:NULL withError:err];
}

//
- (RTNext *)execSQL:(NSString *)sql
       withDicValues:(NSDictionary *)dicValues {
    return [self execSQL:sql withDicValues:dicValues withError:nil];
}

- (RTNext *)execSQL:(NSString *)sql
       withDicValues:(NSDictionary *)dicValues
           withError:(NSError *__autoreleasing *)error {
    return [self execSQL:sql withDicValues:dicValues withArrValues:nil withListValues:NULL withError:error];
}

//
- (RTNext *)execSQL:(NSString *)sql
       withArrValues:(NSArray *)arrValues {
    return [self execSQL:sql withArrValues:arrValues withError:nil];
}

- (RTNext *)execSQL:(NSString *)sql
       withArrValues:(NSArray *)arrValues
           withError:(NSError *__autoreleasing *)error {
    return [self execSQL:sql withDicValues:nil withArrValues:arrValues withListValues:NULL withError:error];
}

//
- (RTNext *)execSQLWithArgs:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION {
    va_list ap;
    va_start(ap, sql);

    RTNext *steps = [self execSQL:sql withDicValues:nil withArrValues:nil withListValues:ap withError:nil];
    va_end(ap);
    
    return steps;
}

- (RTNext *)execSQLWithError:(NSError *__autoreleasing *)error
      withArgs:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION {
    va_list ap;
    va_start(ap, sql);
    
    RTNext *steps = [self execSQL:sql withDicValues:nil withArrValues:nil withListValues:ap withError:error];
    va_end(ap);
    
    return steps;
}
#pragma mark -
- (BOOL)execQuery:(NSString *)sql
    withDicValues:(NSDictionary *)dicValues
    withArrValues:(NSArray *)arrValues
   withListValues:(va_list)listValues
        withError:(NSError *__autoreleasing *)error {
    
    [[self execSQL:sql withDicValues:dicValues withArrValues:arrValues withListValues:listValues withError:error] stepWithError:error];
    return error == NULL;
}

- (RTNext *)execSQL:(NSString *)sql
       withDicValues:(NSDictionary *)dicValues
       withArrValues:(NSArray *)arrValues
      withListValues:(va_list)listValues
           withError:(NSError *__autoreleasing *)error {
    
    sqlite3_stmt *stmt = [self prepareStmt:sql withError:error];
    
    if (dicValues || arrValues || listValues != NULL) {
        if (![self bindStmt:stmt withDicValues:dicValues withArrValues:arrValues withListValues:listValues withError:error]) {
            return nil;
        }
    }
    
    return [RTNext stepsWithStmt:stmt withSQL:sql];
}

#pragma mark -
// prepare
- (void *)prepareStmt:(NSString *)sql
            withError:(NSError *__autoreleasing *)err {
    RT_DELog(@"RTDB: -sql: %@", sql);
    
    if (!sql || sql.length == 0) {
        rt_error([NSString stringWithFormat:@"RTDB: empty sql!"], 101, err);
    }
    
    sqlite3_stmt *stmt;
    int re = sqlite3_prepare_v2(_db, sql.UTF8String, -1, &stmt, 0);
    
    if (re != SQLITE_OK) {
        rt_sqlite3_err(re, err);
        return NULL;
    }
    return stmt;
}

// bind
- (BOOL)bindStmt:(sqlite3_stmt *)stmt
   withDicValues:(NSDictionary *)dicValues
   withArrValues:(NSArray *)arrValues
  withListValues:(va_list)listValues
       withError:(NSError *__autoreleasing *)err {
    
    int bindCount = sqlite3_bind_parameter_count(stmt);
    
    NSMutableArray *mValues;
    if (arrValues && arrValues.count > 0) {
        
        mValues = arrValues.mutableCopy;
    } else if (listValues != NULL) {
        
        mValues = [NSMutableArray arrayWithCapacity:bindCount];
        for (id v = va_arg(listValues, id); v != nil; v = va_arg(listValues, id)) {
            [mValues addObject:v];
        }
    }
    
    BOOL result = YES;
    int boundCount = 0;
    if (mValues && mValues.count > 0) {
        for (int i = 0; i < mValues.count; i++) {
            id value = mValues[i];
            rt_objc_t t = rt_object_class_type(value);
            
            int re = rt_sqlite3_bind(stmt, i+1, value, t);
            if (re != SQLITE_OK) {
                rt_sqlite3_err(re, err);
                result = NO;
                break;
            }
            boundCount++;
        }
    } else if (dicValues && dicValues.count > 0) {
        
        for (NSString *key in dicValues) {
            id value = dicValues[key];
            
            int idx = sqlite3_bind_parameter_index(stmt, [NSString stringWithFormat:@":%@", key].UTF8String);
            
            if (idx > 0) {
                rt_sqlite3_bind(stmt, idx, value, rt_object_class_type(value));
                boundCount++;
            } else {
                rt_error([NSString stringWithFormat:@"RTDB can not find a param for key: %@.", key], 102, err);
                result = NO;
                break;
            }
        }
    }
    
    if (result && (boundCount != bindCount)) {
        if (err != NULL && !(*err)) { // if no errmsg, build.
            rt_error(@"RTDB recieved sql paramters count is not equal to args for bind!", 102, err);
        }
        result = NO;
    }
    
    if (!result) {
        rt_sqlite3_finalize(stmt);
    }
    
    return result;
}

@end

//
//  RTStep.m
//  RTSQLite
//
//  Created by ENUUI on 2018/5/3.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTStep.h"
#import <sqlite3.h>

#pragma mark -
#pragma mark FUNCTION

const int baseCode = 10000;

void rt_error(NSString *errMsg, int code, NSError **err) {
    if (err == NULL) return;
    
    if (errMsg == nil) errMsg = @"Unknown err!";
    
    DELog(@"RTDB: %@", errMsg);
    *err = [NSError errorWithDomain:NSCocoaErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: errMsg}];
}

// sqlite3 error handle
void rt_sqlite3_err(int result, NSError **err) {
    
    NSString *errMsg = [NSString stringWithUTF8String:sqlite3_errstr(result)];
    int code = baseCode + result;
    
    rt_error(errMsg, code, err);
}

// open db
bool rt_sqlite3_open(void **db, NSString *path, int flags, NSError **err) {
    sqlite3 **sqDB = (sqlite3 **)db;
    int result = sqlite3_open_v2(path.UTF8String, sqDB, flags, nil);
    if (result != SQLITE_OK) {
        rt_sqlite3_err(result, err);
        return false;
    } else return true;
}

bool rt_sqlite3_close(void *db) {
    if (db == NULL) {
        return true;
    }
    
    int result;
    bool retry;
    bool closedStmt = false;
    
    do {
        retry = false;
        result = sqlite3_close(db);
        if (result == SQLITE_BUSY || result == SQLITE_LOCKED) {
            if (!closedStmt) {
                sqlite3_stmt *stmt;
                while ((stmt = sqlite3_next_stmt(db, nil)) != 0) {
                    rt_printf("closing sqlite3_stmt *");
                    sqlite3_finalize(stmt);
                    closedStmt = true;
                }
            }
        }
    } while (retry);
    
    return YES;
}

// sqlite3_exec
int rt_sqlite3_exec(void *db, rt_char_t *sql, NSError **err) {
    char *errmsg;
    int reCode = sqlite3_exec((sqlite3 *)db, sql, NULL, NULL, &errmsg);
    int result = rt_sqlite3_status_code(reCode);
    
    if (result == RT_SQLITE_ERROR) {
        NSString *msg = (errmsg == NULL) ? @"Unknown error" : [NSString stringWithUTF8String:errmsg];
        rt_error(msg, baseCode + reCode, err);
        if (errmsg != NULL) {
            free(errmsg);
        }
    }
    return result;
}

// sqlite3_prepare_v2
bool rt_sqlite3_prepare_v2(void *db, rt_char_t *sql, void **ppStmt, NSError **err) {

    int result = sqlite3_prepare_v2((sqlite3 *)db, sql, -1, (sqlite3_stmt **)ppStmt, 0);
    if (result != SQLITE_OK) {
        rt_sqlite3_err(result, err);
        return false;
    } else return true;
}

// sqlite3状态码转换
int rt_sqlite3_status_code(int sqlite3_code) {
    
    switch (sqlite3_code) {
        case SQLITE_OK:
            return RT_SQLITE_OK;
        case SQLITE_DONE:
            return RT_SQLITE_DONE;
        case SQLITE_ROW:
            return RT_SQLITE_ROW;
        default:
            return RT_SQLITE_ERROR;
            break;
    }
}

// Evaluate An SQL Statement
int rt_sqlite3_step(void *stmt, NSError **err) {
    int result = sqlite3_step((sqlite3_stmt *)stmt);
    
    if (result != SQLITE_OK && result != SQLITE_DONE && result != SQLITE_ROW) {
        rt_sqlite3_err(result, err);
    }
    
    return rt_sqlite3_status_code(result);
}

/** 获取的primary id */
NSInteger rt_get_primary_id(void *db, rt_char_t *sql, NSError **err) {
    long long _id = -1;
    void *idStmt;
    if (!rt_sqlite3_prepare_v2((sqlite3 *)db, sql, &idStmt, err)) {
        return _id;
    } else if (!rt_sqlite3_step(idStmt, err)) {
        rt_sqlite3_finalize(&idStmt);
        return _id;
    } else {
        _id = sqlite3_column_int64(idStmt, 0);
    }
    
    rt_sqlite3_finalize(&idStmt);
    
    return _id;
}

// sqlite3_bind
int rt_sqlite3_bind(void *pstmt, int idx, id value, rt_objc_t objT) {
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

// sqlite3_column
id rt_sqlite3_column(void *stmt, int idx, rt_objc_t objT) {
    id result = nil;
    switch (objT) {
        case rttext: {
            const unsigned char *ctext = sqlite3_column_text(stmt, idx);
            if (ctext != NULL) {
                result = [NSString stringWithUTF8String:(const char *)ctext];
            }
        }
            break;
        case rtblob: {
            const void *bytes = sqlite3_column_blob(stmt, idx);
            if (bytes != NULL) {
                int size = sqlite3_column_bytes(stmt, idx);
                result = [NSData dataWithBytes:bytes length:size];
            }
        }
            break;
        case rtnumber:
        case rtfloat:
        case rtdouble:
            result = @(sqlite3_column_double(stmt, idx));
            break;
        case rtdate: {
            double timeInterval = sqlite3_column_double(stmt, idx);
            result = [NSDate dateWithTimeIntervalSince1970:timeInterval];
        }
            break;
        case rtchar:
        case rtuchar:
        case rtshort:
        case rtushort:
        case rtint:
        case rtbool:
            result = @(sqlite3_column_int(stmt, idx));
            break;
        case rtuint:
        case rtlong:
        case rtulong:
            result = @(sqlite3_column_int64(stmt, idx));
            break;
        default: {
            result = rt_sqlite3_value(stmt, idx);
        }
            break;
    }
    return result;
}

// sqlite3_value
id rt_sqlite3_value(void *stmt, int idx) {
    sqlite3_value *sqv = sqlite3_column_value(stmt, idx);
    rt_objc_t t = rt_type_from_sqlite(sqlite3_value_type(sqv));
    
    id result;
    
    switch (t) {
        case rtlong: {
            result = @(sqlite3_value_int64(sqv));
        }
            break;
        case rtdouble: {
            result = @(sqlite3_value_double(sqv));
        }
            break;
        case rtblob: {
            const void *bytes = sqlite3_value_blob(sqv);
            if (bytes != NULL) {
                result = [NSData dataWithBytes:bytes length:sizeof(bytes)];
            }
        }
            break;
        case rttext: {
            const unsigned char *ctext = sqlite3_value_text(sqv);
            if (ctext != NULL) {
                result = [NSString stringWithUTF8String:(const char *)ctext];
            }
        }
            break;
        default:
            break;
    }
    return result;
}

//
rt_char_t *rt_sqlite3_table_name(void *stmt) {
    return sqlite3_column_table_name(stmt, 0);
}

// Destroy A Prepared Statement Object
void rt_sqlite3_finalize(void **stmt) {
    if (stmt == NULL) return;
    if (*stmt == NULL) return;
    sqlite3_finalize(*stmt);
    *stmt = 0x00;
}

#pragma mark -
//////////////////////////
//////////////////////////
//////////////////////////
void rt_column_enum(void *stmt, rt_pro_info *proInfo, rt_column_enum_block_t block) {
    
    rt_enum_info(proInfo, ^(rt_pro_info *pro) {
        rt_objc_t t;
        if (pro->t) {
            t = pro->t;
        } else {
            t = rt_column_type(stmt, pro->idx);
        }
        rt_sqlite3_column(stmt, pro->idx, t);
    });
}

Class rt_column_class(void *stmt) {
    rt_char_t *clsName = sqlite3_column_table_name(stmt, 0);
    if (clsName == NULL) {
        return Nil;
    }
    
    NSString *className = [NSString stringWithUTF8String:clsName];
    if (!className) {
        return Nil;
    }
    
    Class cls = NSClassFromString(className);
    return cls;
}

// 将sqlite3的数据类型转为RT type
rt_objc_t rt_type_from_sqlite(int sqType) {
    switch (sqType) {
        case SQLITE_INTEGER:
            return rtlong;
        case SQLITE_FLOAT:
            return rtdouble;
        case SQLITE_BLOB:
            return rtblob;
        case SQLITE_TEXT:
            return rttext;
        default: // SQLITE_NULL
            return '0';
    }
}

// 获取类型
rt_objc_t rt_column_type(void *stmt, int idx) {
    int type = sqlite3_column_type(stmt, idx);
    return rt_type_from_sqlite(type);
}

rt_pro_info *rt_column_pro_info(void *stmt, int *outCount) {
    int count = rt_sqlite3_column_count(stmt);

    if (count == 0) {
        return NULL;
    }
    
    if (outCount != NULL) {
        *outCount = count;
    }
    
    rt_pro_info *info = NULL;
    for (int i = 0; i < count; i++) {
        rt_char_t *name = rt_sqlite3_column_name(stmt, i);
        if (name != NULL) {
            rt_pro_info *next = rt_make_info(i, '0', name);
            rt_info_append(&info, next);
        }
    }
    return info;
}

int rt_sqlite3_column_count(void *stmt) {
    return sqlite3_column_count(stmt);
}

rt_char_t *rt_sqlite3_column_name(void *stmt, int N) {
    return sqlite3_column_name(stmt, N);
}

// -------------------------------------------------------------

rt_pro_info *rt_sqlite3_bind_info(void *stmt, int *outCount) {
    int count = rt_sqlite3_bind_parameter_count(stmt);
    if (count == 0) {
        return NULL;
    }
    
    if (outCount != NULL) {
        *outCount = count;
    }
    rt_pro_info *info = NULL;
    for (int i = 0; i < count; i++) {
        rt_char_t *name = rt_sqlite3_bind_parameter_name(stmt, i);
        if (name != NULL) {
            rt_pro_info *next = rt_make_info(i, '0', name);
            rt_info_append(&info, next);
        }
    }
    
    return info;
}

rt_char_t *rt_sqlite3_bind_parameter_name(void *stmt, int idx) {
    return sqlite3_bind_parameter_name(stmt, idx);
}

int rt_sqlite3_bind_param_index(void *stmt, rt_char_t *name) {
    return sqlite3_bind_parameter_index(stmt, name);
}

int rt_sqlite3_bind_parameter_count(void *stmt) {
    return sqlite3_bind_parameter_count(stmt);
}

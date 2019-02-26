//
//  RTNext.m
//  RTDatebase
//
//  Created by hc-jim on 2019/2/25.
//  Copyright © 2019 ENUUI. All rights reserved.
//

#import "RTNext.h"
#import <sqlite3.h>
#import "RTDB.h"

// sqlite3_value
id rt_sqlite3_value(void *stmt, int idx) {
    sqlite3_value *sqv = sqlite3_column_value(stmt, idx);
    int type = sqlite3_value_type(sqv);
    id result;
    
    switch (type) {
        case SQLITE_INTEGER: {
            result = @(sqlite3_value_int64(sqv));
        }
            break;
        case SQLITE_FLOAT: {
            result = @(sqlite3_value_double(sqv));
        }
            break;
        case SQLITE_BLOB: {
            const void *bytes = sqlite3_value_blob(sqv);
            if (bytes != NULL) {
                result = [NSData dataWithBytes:bytes length:sizeof(bytes)];
            }
        }
            break;
        case SQLITE_TEXT: {
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


@interface RTNext () {
    sqlite3_stmt *_stmt;
}
@property (nonatomic, strong) NSError *error;
@end


@implementation RTNext

+ (instancetype)stepsWithStmt:(void *)stmt withSQL:(NSString *)sql {
    return [[self alloc] initWithStmt:(sqlite3_stmt *)stmt withSQL:sql];
}

- (instancetype)initWithStmt:(sqlite3_stmt *)stmt withSQL:(NSString *)sql {
    if (self = [super init]) {
        _stmt = stmt;
        _sql = sql;
    }
    return self;
}

- (nullable NSError *)finalError {
    return _error;
}

- (void)dealloc {
    [self close];
}

- (void)close {
    if (_stmt != NULL) {
        sqlite3_finalize(_stmt);
        _stmt = 0x00;
    }
}

#pragma mark - step
- (BOOL)step {
    return [self stepWithError:nil];
}

- (BOOL)stepWithError:(NSError *__autoreleasing *)error {
    
    BOOL canStep = YES;
    int re = sqlite3_step(_stmt);
    switch (re) {
        case SQLITE_ROW:
            break;
        case SQLITE_DONE:
        case SQLITE_OK: {
            canStep = NO;
        }
            break;
        default: {
            rt_sqlite3_err(re, error);
            if (error) {
                self.error = *error;
            }
            canStep = NO;
        }
            break;
    }
    
    if (!canStep) {
        sqlite3_finalize(_stmt);
        _stmt = 0x00;
    }
    
    return canStep;
}

#pragma mark - enum
- (void)enumRows:(void(^)(NSDictionary *rowDict, int step, BOOL *stop, NSError *error))callback {
    
    [self enumTask:callback columns:nil];
}

- (void)enumColumns:(void(^)(NSString *colName, id colValue, int row, int colIndex, BOOL *stop, NSError *error))callback {
    [self enumTask:nil columns:callback];
}

- (void)enumTask:(void(^)(int step, BOOL enableRow, BOOL *stop, NSError *error))callback {
    
    if (!callback) {
        return;
    }
    
    NSError *err;
    int colCount = sqlite3_column_count(_stmt);
    if (colCount == 0) {
        rt_error([NSString stringWithFormat:@"RTDB did not find column. -sql: %@", _sql], 108, &err);
        self.error = err;
        callback(0, NO, NULL, err);
        return;
    }
    
    int step = 0;
    BOOL stop;
    while (1) {
        int re = sqlite3_step(_stmt);
        
        if (re == SQLITE_DONE || re == SQLITE_OK) {
            break;
        } else if (re != SQLITE_ROW) {
            rt_sqlite3_err(re, &err);
            self.error = err;
            callback(step, NO, NULL, err);
            break;
        }
        
        callback(step, YES, &stop, nil);
        
        if (stop) {
            break;
        }
        
        step++;
    }
}

- (void)enumTask:(void(^)(NSDictionary *rowDict, int step, BOOL *stop, NSError *error))rowCallback columns:(void(^)(NSString *colName, id colValue, int step, int colIndex, BOOL *stop, NSError *error))colCallback {

    if (!rowCallback && !colCallback) {
        return;
    }
    
    NSError *err;
    int colCount = sqlite3_column_count(_stmt);
    if (colCount == 0) {
        rt_error([NSString stringWithFormat:@"RTDB did not find column. -sql: %@", _sql], 108, &err);
        self.error = err;
        if (rowCallback) {
            rowCallback(nil, 0, NULL, err);
        }
        if (colCallback) {
            colCallback(nil, nil, 0, 0, NULL, err);
        }
        return;
    }

    int row = 0;
    BOOL stop = NO;
    while (1) {
        int re = sqlite3_step(_stmt);

        if (re == SQLITE_DONE || re == SQLITE_OK) {
            break;
        } else if (re != SQLITE_ROW) {
            rt_sqlite3_err(re, &err);
            self.error = err;
            if (rowCallback) {
                rowCallback(nil, 0, NULL, err);
            }
            if (colCallback) {
                colCallback(nil, nil, 0, 0, NULL, err);
            }
        }

        NSMutableDictionary *mTempDict;
        if (rowCallback) {
            mTempDict = [NSMutableDictionary dictionaryWithCapacity:colCount];
        }
        
        for (int col = 0; col < colCount; col++) {
            const char *cname = sqlite3_column_name(_stmt, col);
            id value = rt_sqlite3_value(_stmt, col);
            
            NSString *name = nil;
            if (cname != NULL) {
                name = [NSString stringWithUTF8String:cname];
            }
            
            if (name == nil) {
                rt_error([NSString stringWithFormat:@"RTDB found empty name for value: %@. -sql: %@", value, _sql], 108, &err);
                if (colCallback) {
                    colCallback(nil, value, row, col, NULL, err);
                }
                break;
            } else {
                if (colCallback) {
                    colCallback(name, value, row, col, &stop, err);
                }
                mTempDict[name] = value;
            }
        }
        
        if (rowCallback) {
            if (mTempDict.count > 0) {
                rowCallback(mTempDict.copy, row, &stop, nil);
            } else {
                rt_error([NSString stringWithFormat:@"RTDB found out empty row at %d. -sql: %@", row, _sql], 108, &err);
                rowCallback(nil, row, NULL, err);
                break;
            }
        }
        if (stop) {
            break;
        }
        row++;
    }
}

#pragma mark - value
/** Get value by column index */
- (id)valueForColumn:(int)column {
    return rt_sqlite3_value(_stmt, column);
}

- (NSString *)textForColumn:(int)column {
    return rt_sqlite3_column(_stmt, column, rttext);
}

- (NSData *)dataForColumn:(int)column {
    return rt_sqlite3_column(_stmt, column, rtblob);
}

- (NSNumber *)numberForColumn:(int)column {
    return rt_sqlite3_column(_stmt, column, rtnumber);
}

- (NSDate *)dateForColumn:(int)column {
    return rt_sqlite3_column(_stmt, column, rtdate);
}

- (double)doubleForColumn:(int)column {
    return [rt_sqlite3_column(_stmt, column, rtdouble) doubleValue];
}

- (float)floatForColumn:(int)column {
    return [rt_sqlite3_column(_stmt, column, rtfloat) floatValue];
}

- (char)charForColumn:(int)column {
    return [rt_sqlite3_column(_stmt, column, rtchar) charValue];
}

- (unsigned char)ucharForColumn:(int)column {
    return [rt_sqlite3_column(_stmt, column, rtuchar) unsignedCharValue];
}

- (short)shortForColumn:(int)column {
    return [rt_sqlite3_column(_stmt, column, rtshort) shortValue];
}

- (unsigned short)ushortForColumn:(int)column {
    return [rt_sqlite3_column(_stmt, column, rtushort) unsignedShortValue];
}

- (int)intForColumn:(int)column {
    return [rt_sqlite3_column(_stmt, column, rtint) intValue];
}

- (unsigned int)uintForColumn:(int)column {
    return [rt_sqlite3_column(_stmt, column, rtuint) unsignedIntValue];
}

- (long)longForColumn:(int)column {
    return [rt_sqlite3_column(_stmt, column, rtlong) longValue];
}

- (unsigned long)ulongForColumn:(int)column {
    return [rt_sqlite3_column(_stmt, column, rtulong) unsignedLongValue];
}

- (long long)llongForColumn:(int)column {
    return [rt_sqlite3_column(_stmt, column, rtlong) longLongValue];
}

- (unsigned long long)ullongForColumn:(int)column {
    return [rt_sqlite3_column(_stmt, column, rtulong) unsignedLongLongValue];
}

- (BOOL)boolForColumn:(int)column {
    return [rt_sqlite3_column(_stmt, column, rtbool) boolValue];
}

#pragma mark -
- (NSString *)tableName {
    return [NSString stringWithUTF8String:sqlite3_column_table_name(_stmt, 0)];
}
@end

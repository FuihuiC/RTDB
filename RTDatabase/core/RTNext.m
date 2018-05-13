//
//  RTNext.m
//  RTSQLite
//
//  Created by ENUUI on 2018/5/7.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTNext.h"
#import "RTStep.h"

@interface RTNext () {
    void *_stmt;
    rt_pro_info *_infos;
}
@property (nonatomic, copy) NSString *sql;
@property (nonatomic, assign) int countOfColumn;
@end

@implementation RTNext
- (instancetype)initWithStmt:(void *)stmt withSql:(NSString *)sql {
    if (self = [super init]) {
        self->_stmt = stmt;
        self.sql = sql;
        int count = 0;
        _infos = rt_column_pro_info(self->_stmt, &count);
        _countOfColumn = count;
    }
    return self;
}

- (void)dealloc {
    [self finalizeStep];
}

- (BOOL)step {
    return [self stepWithError:nil];
}

- (BOOL)stepWithError:(NSError *__autoreleasing *)error {
    BOOL result = (rt_sqlite3_step(_stmt, error) == RT_SQLITE_ROW);
    
    if (!result) {
        [self finalizeStep];
    }
    
    return result;
}

- (void)finalizeStep {
    rt_sqlite3_finalize(&_stmt);
}

#pragma mark -

- (void)enumAllSteps:(RT_STEP_CALLBACK_BLOCK)stepCallback {
    [self enumSteps:stepCallback withColumns:nil];
}

- (void)enumAllColumns:(RT_COLUMN_CALLBACK_BLOCK)columnCallback {
    [self enumSteps:nil withColumns:columnCallback];
}

- (void)enumSteps:(RT_STEP_CALLBACK_BLOCK)stepCallback withColumns:(RT_COLUMN_CALLBACK_BLOCK)columnCallback {
    
    // prepare callback
    RT_STEP_CALLBACK_BLOCK stepback = ^(NSDictionary *dic, int step, BOOL *stop, NSError *err) {
        if (stepCallback) {
            stepCallback(dic, step, stop, err);
        }
    };
    
    RT_COLUMN_CALLBACK_BLOCK columnback = ^(id value, NSString *name, int step, int column, BOOL *stop, NSError *err) {
        if (columnCallback) {
            columnCallback(value, name, step, column, stop, err);
        }
    };
    
    /*
     * start step work!
     */
    NSError *err;
    int count = rt_sqlite3_column_count(_stmt);
    if (count == 0) {
        rt_db_err([NSString stringWithFormat:@"RTDB did not find column. -sql: %@", _sql], &err);
        stepback(nil, 0, NULL, err);
        columnback(nil, nil, 0, 0, NULL, err);
        return;
    }
    
    int step = 0;
    BOOL stop = NO;
    
    while (1) {
        int result = rt_sqlite3_step(_stmt, &err);
        
        if (result == RT_SQLITE_ERROR) { // error!
            columnback(nil, nil, step, 0, NULL, err);
            stepback(nil, step, NULL, err);
            break;
        }
        
        if (result != RT_SQLITE_ROW) { // Step Done!
            break;
        }
        
        NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithCapacity:count];
        for (int column = 0; column < count; column++) {
            rt_char_t *cname = rt_sqlite3_column_name(_stmt, column);
            
            id value = rt_sqlite3_value(_stmt, column);
            
            NSString *name = nil;
            if (cname != NULL) {
                name = [NSString stringWithUTF8String:cname];
            }
            
            if (name == nil) {
                rt_db_err([NSString stringWithFormat:@"RTDB found empty name for value: %@. -sql: %@", value, _sql], &err);
                columnback(nil, nil, step, column, &stop, err);
            } else {
                columnback(name, value, step, column, &stop, nil);
                
                mDic[name] = value;
            }
        }
        if (mDic.count > 0) {
            stepback(mDic.copy, step, &stop, nil);
        } else {
            rt_db_err([NSString stringWithFormat:@"RTDB found out empty row at %d. -sql: %@", step, _sql], &err);
            stepback(nil, step, &stop, err);
        }
        step++;
        if (stop) {
            break;
        }
    }
}

/** info of column */
- (int)columnCountOfRow {
    return _countOfColumn;
}

- (int)columnForName:(NSString *)name {
    int column = rt_info_by_name(_infos, [name UTF8String])->idx;
    return column;
}

- (NSString *)nameForColumn:(int)column {
    rt_char_t *cname = rt_info_at_idx(_infos, column)->name;
    if (cname == NULL) {
        return nil;
    }
    return [NSString stringWithUTF8String:cname];
}

#pragma mark column value
/** Get value by column name */
- (id)valueForName:(NSString *)name {
    int column = [self columnForName:name];
    return rt_sqlite3_value(_stmt, column);
}

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

@end

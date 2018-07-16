//
//  RTDBDefault.m
//  RTSQLite
//
//  Created by ENUUI on 2018/5/8.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTDBDefault.h"

typedef void(^RT_DB_STEP_BLOCK)(void *stmt, Class cls, rt_pro_info *proInfo, BOOL cached, BOOL *stop);


typedef enum : NSUInteger {
    op_insert,
    op_update,
    op_delete,
} RTDBOperateMode;

@interface RTDBDefault () {
    dispatch_semaphore_t _semaphore;
}
@property (nonatomic, strong) NSMutableDictionary<NSString *, RTInfo *> *mDicTablesCache;
@end

@implementation RTDBDefault

- (instancetype)init {
    if (self = [super init]) {
        _semaphore = dispatch_semaphore_create(1);
        _mDicTablesCache = [NSMutableDictionary<NSString *, RTInfo *> dictionary];
    }
    return self;
}

// Get a RTInfo object which cahced the model class info.
- (RTInfo *)infoForClass:(Class)cls withError:(NSError *__autoreleasing*)error {
    NSString *clsName = [NSString stringWithUTF8String:rt_class_name(cls)];
    if (!clsName || clsName.length == 0) return nil;
    
    dispatch_semaphore_wait(_semaphore, dispatch_time(DISPATCH_TIME_NOW, DISPATCH_TIME_FOREVER));
    
    RTInfo *info = _mDicTablesCache[clsName];
    if (!info) {
        NSError *err;
        info = [[RTInfo alloc] initWithClass:cls withError:&err];
        if (!err) {
            _mDicTablesCache[clsName] = info;
        } else {
            info = nil;
            if (error != NULL) {
                *error = err;
            }
        }
    }
    
    dispatch_semaphore_signal(_semaphore);
    return info;
}
#pragma mark - 

- (BOOL)creatTable:(Class)cls withError:(NSError * __autoreleasing *)err {
    
    RTInfo *info = [self infoForClass:cls withError:err];

    if (!info) {
        if (err != NULL && *err == nil) {
            rt_error(@"RTDB get class info failure!", 103, err);
        }
        return NO;
    }
    
    return rt_sqlite3_exec([self sqlite3_db], [info creatSql], err);
}

// insert
- (BOOL)insertObj:(id)obj withError:(NSError * __autoreleasing *)err {
    return [self baseOperate:op_insert withObj:obj withError:err];
}

// update
- (BOOL)updateObj:(id)obj withParams:(NSDictionary <NSString *, id>*)params withError:(NSError *__autoreleasing *)err {
    
    if (!params && params.count == 0) {
        return [self updateObj:obj withError:err];
    }
    
    if (obj == nil) {
        rt_error(@"RTDB recieve an empty obj!", 104, err);
        return NO;
    }
    
    NSMutableString *mSql = [NSMutableString stringWithString:[NSString stringWithFormat:@"UPDATE %s SET", rt_class_name([obj class])]];
    
    NSArray <NSString *>*allKeys = params.allKeys;
    NSString *key = nil;
    
    for (int i = 0; i < allKeys.count; i++) {
        key = allKeys[i];
        [mSql appendFormat:@" %@ = ?, ", key];
    }
    
    if ([mSql hasSuffix:@", "]) {
        [mSql deleteCharactersInRange:NSMakeRange(mSql.length - 2, 2)];
    }
    
    NSInteger idx = [[obj valueForKey:@"_id"] integerValue];
    [mSql appendFormat:@" where _id = %ld", (long)idx];
    
    return [self exceQuery:mSql.copy withParams:params];
}

- (BOOL)updateObj:(id)obj withError:(NSError * __autoreleasing *)err {
    return [self baseOperate:op_update withObj:obj withError:err];
}

// delete
- (BOOL)deleteObj:(id)obj withError:(NSError * __autoreleasing *)err {
    return [self baseOperate:op_delete withObj:obj withError:err];
}

- (BOOL)baseOperate:(RTDBOperateMode)op withObj:(id)obj withError:(NSError * __autoreleasing *)err {
    if (obj == nil) {
        rt_error(@"RTDB recieve an empty obj!", 104, err);
        return NO;
    }
    
    RTInfo *info = [self infoForClass:[obj class] withError:err];

    if (!info) {
        if (err != NULL && *err == nil) {
            rt_error(@"RTDB get class info failure!", 103, err);
        }
        return NO;
    }
    
    if (!info->_has_id) {
        rt_error(@"RTDB can not find primety property '_id'!", 105, err);
        return NO;
    }
    
    // get max _id before insert
    NSInteger _id = -1;
    if (op == op_insert) {
        _id = rt_get_primary_id([self sqlite3_db], [info maxidSql], err);
        if (_id != -1) {
            _id++;
        } else {
            rt_error(@"RTDB can not find primary key '_id' max value!", 105, err);
            return NO;
        }
    }
    
    // prepare sql
    rt_char_t *sql = NULL;
    if (op == op_insert) {
        sql = [info insertSql];
    } else {
        NSInteger idx = [[obj valueForKey:@"_id"] integerValue];
        if (op == op_update) {
            sql = [info updateSqlWithID:idx];
        } else if (op == op_delete) {
            sql = [info deleteSqlWithID:idx];
        }
    }
    
    if (sql == NULL) {
        rt_error(@"RTDB can not find which column to operate!", 106, err);
        return NO;
    }
    
    void *stmt;
    if (!rt_sqlite3_prepare_v2([self sqlite3_db], sql, &stmt, err)) {
        return NO;
    }
    
    if (op == op_update || op == op_delete) {
        free((char *)sql);
    }
    
    // bind obj value to sqlite3
    if (op != op_delete) {
        rt_pro_info *proInfo = info->_prosInfo;
        
        for (rt_pro_info *pro = proInfo; pro != NULL; pro = pro->next) {
            rt_sqlite3_bind(stmt, pro->idx, [obj valueForKey:[NSString stringWithUTF8String:pro->name]], pro->t);
        }
    }
    
    BOOL res = rt_sqlite3_step(stmt, err);
    rt_sqlite3_finalize(&stmt);
    if (!res) {
        return NO;
    }
    
    if (op == op_insert) {
        // Assignment the maximum primary key value to the table to _id
        [obj setValue:@(_id) forKey:@"_id"];
    } else if (op == op_delete) {
        [obj setValue:@(0) forKey:@"_id"];
    }
    return YES;
}

- (NSArray <NSDictionary *>*)fetchSql:(NSString *)sql withError:(NSError * __autoreleasing *)err {
    
    NSMutableArray <NSDictionary *>*mArr = [NSMutableArray<NSDictionary *> array];
    
    BOOL re = [self querySql:sql withError:err withCallback:^(void *stmt, Class cls, rt_pro_info *proInfo, BOOL cached, BOOL *stop) {
        NSMutableDictionary *mDic = [NSMutableDictionary dictionary];
        
        
        for (rt_pro_info *pro = proInfo; pro != NULL; pro = pro->next) {
            rt_objc_t t;
            if (rt_str_compare(pro->name, "_id")) {
                t = rtlong;
            } else if (cached) {
                t = pro->t;
            } else {
                t = rt_column_type(stmt, pro->idx);
            }
            id value = rt_sqlite3_column(stmt, pro->idx, t);
            NSString *name = [NSString stringWithUTF8String:pro->name];
            mDic[name] = value;
        }
        
        if (mDic.count > 0) {
            [mArr addObject:mDic.copy];
        }
    }];
    
    if (re && mArr.count > 0) {
        return mArr.copy;
    } else return nil;
}

- (NSArray *)fetchObjSql:(NSString *)sql withError:(NSError * __autoreleasing *)err {
    NSMutableArray *mArr = [NSMutableArray array];
    
    BOOL re = [self querySql:sql withError:err withCallback:^(void *stmt, Class cls, rt_pro_info *proInfo, BOOL cached, BOOL *stop) {
        
        if (cls == Nil) {
            rt_error([NSString stringWithFormat:@"RTDB did not find a class from sql: %@", sql], 103, err);
            *stop = YES;
            return;
        }
        
        id obj = [[cls alloc] init];
        for (rt_pro_info *pro = proInfo; pro != NULL; pro = pro->next) {
            rt_objc_t t;
            if (rt_str_compare(pro->name, "_id")) {
                t = rtlong;
            } else if (cached) {
                t = pro->t;
            } else {
                t = rt_column_type(stmt, pro->idx);
            }
            id value = rt_sqlite3_column(stmt, pro->idx, t);
            NSString *name = [NSString stringWithUTF8String:pro->name];
            
            if (!name) {
                return;
            }
            
            SEL slct = [self setterFromName:name];
            if (slct == nil) {
                return;
            }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
            if ([obj respondsToSelector:slct]) {
#pragma clang diagnostic pop
                [obj setValue:value forKey:name];
            }
        }
        if (obj) {
            [mArr addObject:obj];
        }
    }];
    
    if (re && mArr.count > 0) {
        return mArr.copy;
    } else return nil;
}

- (BOOL)querySql:(NSString *)sql withError:(NSError * __autoreleasing *)err withCallback:(RT_DB_STEP_BLOCK)callback {
    if (!sql && sql.length == 0) {
        rt_error(@"RTDB: sql should not be empty", 101, err);
        return NO;
    }
    
    __block void *stmt;
    if (!rt_sqlite3_prepare_v2([self sqlite3_db], [sql UTF8String], &stmt, err)) {
        return NO;
    }
    
    Class cls = rt_column_class(stmt);
    if (cls == Nil) {
        rt_error([NSString stringWithFormat:@"RTDB did not find class. - sql: %@", sql], 103, err);
        rt_sqlite3_finalize(&stmt);
        return NO;
    }
    
    int count;
    rt_pro_info *proInfo = rt_column_pro_info(stmt, &count);
    if (proInfo == NULL) {
        rt_error([NSString stringWithFormat:@"RTDB did not find pros info. - sql: %@", sql], 107, err);
        rt_sqlite3_finalize(&stmt);
        return NO;
    }
    
    RTInfo *sqInfo = [self infoForClass:cls withError:nil];

    BOOL cached = (rt_pro_t_assign(sqInfo->_prosInfo, &proInfo, NULL) == 1);
    
    int result = -1;
    while (1) {
        result = rt_sqlite3_step(stmt, err);
        if (result != RT_SQLITE_ROW) break;
        
        if (callback) {
            BOOL stop;
            callback(stmt, cls, proInfo, cached, &stop);
            if (stop) {
                break;
            }
        }
    }
    // free
    rt_sqlite3_finalize(&stmt);
    rt_free_info(proInfo);
    return (result != RT_SQLITE_ERROR);
}

// ----------------------------------------------
// ----------------------------------------------
// ----------------------------------------------
- (SEL)setterFromName:(NSString *)name {
    if (!name || name.length == 0) {
        return nil;
    }
    NSString *result;
    
    NSUInteger len = name.length;
    if (len == 1) {
        result = [NSString stringWithFormat:@"set%@:", name.uppercaseString];
    } else {
        char first = [[name substringToIndex:1] UTF8String][0];
        
        NSString *sufix = [name substringFromIndex:1];
        if (first >= 'a' && first <= 'z') {
            first -= 32;
        }
        
        result = [NSString stringWithFormat:@"set%c%@:", first, sufix];
    }
    return NSSelectorFromString(result);
}

@end

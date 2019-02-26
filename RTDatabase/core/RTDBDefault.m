//
//  RTOBDB.m
//  RTDatebase
//
//  Created by hc-jim on 2019/2/25.
//  Copyright © 2019 ENUUI. All rights reserved.
//

#import "RTDBDefault.h"
#import <objc/runtime.h>

static NSString *const kRT_PRIMARY_PROPERTY = @"_id";

static NSString *const kRT_SQL_FECTH_MAX_ID = @"SELECT MAX(_id) FROM %@";
static NSString *const kRT_SQL_INSERT_OBJ = @"INSERT INTO %@ (%@) VALUES (:%@)";
static NSString *const kRT_SQL_CREATE_TABLE = @"CREATE TABLE if not exists'%@' ('_id' 'INTEGER' primary key autoincrement NOT NULL";
static NSString *const kRT_SQL_UPDATE_OBJ = @"UPDATE %@ SET %@ WHERE _id = %@";
static NSString *const kRT_SQL_DELETE_OBJ = @"DELETE FROM %@ WHERE _id = %@";
static NSString *const kRT_SQL_SELECT_TABLE = @"SELECT * FROM %@ ";

// ---------------------------------------------------
// Whether two strings are equal
static int rt_str_compare(const char *src1, const char *src2) {
    return (strcmp(src1, src2) == 0);
}

// 获取property类型
static rt_objc_t rt_object_type(const char *attr) {
    
    if (strlen(attr) > 2) {
        char idx_1 = attr[1];
        if (idx_1 == '@') {
            if (strlen(attr) > 7    && // NSString
                attr[5]     == 'S'  &&
                attr[6]     == 't'  &&
                attr[7]     == 'r') {
                return rttext;
            } else if (strlen(attr) > 8    && // NSData
                       attr[6]     == 'a'  &&
                       attr[7]     == 't'  &&
                       attr[8]     == 'a') {
                return rtblob;
            } else if (strlen(attr) > 8    && // NSDate
                       attr[6]     == 'a'  &&
                       attr[7]     == 't'  &&
                       attr[8]     == 'e') {
                return rtdate;
            } else if (strlen(attr) > 8    && // NSNumber
                       attr[5]     == 'N'  &&
                       attr[6]     == 'u'  &&
                       attr[7]     == 'm') {
                return rtdouble;
            }
        } else if (idx_1 == 'c' || // char
                   idx_1 == 'C' || // unsigned char, Boolean
                   idx_1 == 's' || // short
                   idx_1 == 'S' || // unsigned short
                   idx_1 == 'i' || // int
                   idx_1 == 'I' || // unsigned int
                   idx_1 == 'q' || // long, long long
                   idx_1 == 'Q' || // unsigned long, unsigned long long, size_t
                   idx_1 == 'B' || // BOOL, bool
                   idx_1 == 'd' || // CGFloat, double
                   idx_1 == 'f') { // float
            return idx_1;
        }
    }
    return 0;
}

// 根据property类型 获取 bind 类型
static const char *rt_sqlite3_bind_type(rt_objc_t t) {
    switch (t) {
        case rttext:
            return "TEXT";
        case rtblob:
            return "BLOB";
        case rtfloat:
        case rtdouble:
        case rtdate:
        case rtnumber:
            return "REAL";
        case rtchar:
        case rtuchar:
        case rtshort:
        case rtushort:
        case rtint:
        case rtuint:
        case rtlong:
        case rtulong:
        case rtbool:
            return "INTEGER";
        default:
            return "";
            break;
    }
}

@interface RTClassInfo : NSObject
@end

@implementation RTClassInfo

+ (NSString *)className:(Class)cls {
    return [NSString stringWithUTF8String:class_getName(cls)];
}

+ (unsigned int)enumClassProperties:(Class)cls callback:(void(^)(const char *proName, const char *bindType))callback {
    
    unsigned int outCount;
    objc_property_t *proList = class_copyPropertyList(cls, &outCount);
    
    if (outCount == 0) {
        if (proList != NULL) {
            free(proList);
        }
        return 0;
    }
    
    for (objc_property_t pro = *proList; pro != NULL; pro = *(++proList)) {
        const char *cn = property_getName(pro);
        
        if (strlen(cn) == 0) continue;
        
        rt_objc_t t = rt_object_type(property_getAttributes(pro));
        if (t == 0) continue;
        
        if (rt_str_compare(cn, "_id")) continue;
        
        callback(cn, rt_sqlite3_bind_type(t));
    }
    
    return outCount;
}

+ (NSArray *)classAllPros:(Class)cls {
    NSMutableArray *mArrPros = [NSMutableArray array];
    [self enumClassProperties:cls callback:^(const char *proName, const char *bindType) {
        if (proName != NULL) {
            [mArrPros addObject:[NSString stringWithFormat:@"%s", proName]];
        }
    }];
    return mArrPros.copy;
}

+ (NSString *)createTableSQLFromClass:(Class)cls {
    
    NSString *clsName = [NSString stringWithUTF8String:class_getName(cls)];
    
    if (!clsName || [clsName isEqualToString:@"NSObject"]) {
        return nil;
    }
    
    NSMutableString *mCreateSQL = [NSMutableString stringWithFormat:kRT_SQL_CREATE_TABLE, clsName];

    int outCount = [self enumClassProperties:cls callback:^(const char *proName, const char *bindType) {
        [mCreateSQL appendFormat:@", '%s' '%s'", proName, bindType];
    }];
    
    if (outCount > 0) {
        [mCreateSQL appendString:@")"];
        return mCreateSQL.copy;
    }
    
    return nil;
}

+ (NSDictionary *)allKeyValuesFrom:(NSObject<RTDBDefaultProtocol>*)obj {
    NSMutableDictionary *mDic = [NSMutableDictionary dictionary];
    
    [self enumClassProperties:[obj class] callback:^(const char *proName, const char *bindType) {
        NSString *propertyName = [NSString stringWithUTF8String:proName];
        mDic[propertyName] = [obj valueForKey:propertyName];
    }];
    
    if (mDic.count == 0) return nil;
    
    return mDic.copy;
}

+ (NSString *)maxidSQLFrom:(Class)cls {
    return [NSString stringWithFormat:kRT_SQL_FECTH_MAX_ID, [self className:cls]];
}

+ (NSString *)insertSQLFromObj:(NSObject<RTDBDefaultProtocol>*)obj {
    NSMutableArray *mPros = [NSMutableArray array];
    
    [self enumClassProperties:[obj class] callback:^(const char *proName, const char *bindType) {
        [mPros addObject:[NSString stringWithUTF8String:proName]];
    }];
    
    if (mPros.count == 0) {
        return nil;
    }
    
    NSString *keys = [mPros componentsJoinedByString:@", "];
    NSString *values = [mPros componentsJoinedByString:@", :"];
    NSString *tableName = [self className:[obj class]];
    
    return [NSString stringWithFormat:kRT_SQL_INSERT_OBJ, tableName, keys, values];
}

/////
+ (NSString *)updateSQLFromObj:(NSObject<RTDBDefaultProtocol>*)obj {
    NSMutableString *mUpdateStr = [NSMutableString string];
    
    [self enumClassProperties:[obj class] callback:^(const char *proName, const char *bindType) {
        [mUpdateStr appendFormat:@"%@ = ?, ", [NSString stringWithUTF8String:proName]];
    }];
    
    if (mUpdateStr.length > 2) {
        [mUpdateStr deleteCharactersInRange:NSMakeRange(mUpdateStr.length - 2, 2)];
        id _id = [obj valueForKey:kRT_PRIMARY_PROPERTY];
        return [NSString stringWithFormat:kRT_SQL_UPDATE_OBJ, [self className:[obj class]], mUpdateStr, _id];
    } else return nil;
}

+ (NSString *)updateSQLFromOBJ:(id)obj withArray:(NSArray <NSString *>*)proArray {
    if (proArray.count == 1) {
        return [NSString stringWithFormat:@"%@ = ?", proArray[0]];
    } else {
        NSString *keys = [[proArray componentsJoinedByString:@" = ?, "] stringByAppendingString:@" = ?"];
        return [NSString stringWithFormat:kRT_SQL_UPDATE_OBJ, [self className:[obj class]], keys, [obj valueForKey:kRT_PRIMARY_PROPERTY]];
    }
}

+ (NSArray *)updateValuesFromOBJ:(id)obj withArray:(NSArray <NSString *>*)proArray {
    NSMutableArray *mArrValues = [NSMutableArray arrayWithCapacity:proArray.count];
    
    for (int i = 0; i < proArray.count; i++) {
        id value = [obj valueForKey:proArray[i]];
        if (!value) {
            value = [NSNull null];
        }
        [mArrValues addObject:value];
    }
    
    return mArrValues.copy;
}

+ (NSArray *)updateValuesFromProDict:(NSDictionary *)proDict withArray:(NSArray <NSString *>*)proArray {
    NSMutableArray *mArrValues = [NSMutableArray arrayWithCapacity:proArray.count];
    
    for (int i = 0; i < proArray.count; i++) {
        id value = proDict[proArray[i]];
        if (!value) {
            value = [NSNull null];
        }
        [mArrValues addObject:value];
    }
    
    return mArrValues.copy;
}
//////
+ (NSString *)deleteSQLFromObj:(NSObject<RTDBDefaultProtocol>*)obj {
    return [NSString stringWithFormat:kRT_SQL_DELETE_OBJ, [self className:[obj class]], [obj valueForKey:kRT_PRIMARY_PROPERTY]];
}

+ (NSString *)fetchSQLFromClass:(Class)cls withCondition:(NSString *)condition {
    return [NSString stringWithFormat:kRT_SQL_SELECT_TABLE, condition];
}
@end

///////////
///////////
@interface RTDBDefault ()

@end

@implementation RTDBDefault

- (void)setDbHandler:(RTDB *)dbHandler {
    _dbHandler = dbHandler;
}

- (BOOL)createTable:(Class)cls {
    return [self createTable:cls withError:nil];
}

- (BOOL)createTable:(Class)cls withError:(NSError *__autoreleasing *)error {
    NSString *sql = [RTClassInfo createTableSQLFromClass:cls];
    
    if (!sql) {
        rt_error(@"RTDB can not find any property.", 114, error);
        return NO;
    }
    
    return [_dbHandler execWithQuery:sql withError:error];
}

// insert one row
- (BOOL)insertObj:(NSObject<RTDBDefaultProtocol>*)obj {
    return [self insertObj:obj withError:nil];
}

- (BOOL)insertObj:(NSObject<RTDBDefaultProtocol>*)obj withError:(NSError * __autoreleasing *)error {
    
    NSInteger _id = -1;
    
    NSString *maxidSQL = [RTClassInfo maxidSQLFrom:[obj class]];
    RTNext *steps = [_dbHandler execSQL:maxidSQL];
    if (![steps stepWithError:error]) {
        return NO;
    };
    _id = [steps longForColumn:0];
    
    if (_id < 0) {
        rt_error(@"RTDB can not find primary key '_id' max value!", 105, error);
        return NO;
    }
    
    NSString *sql = [RTClassInfo insertSQLFromObj:obj];
    NSDictionary *keyValues = [RTClassInfo allKeyValuesFrom:obj];
    
    if (![_dbHandler execQuery:sql withDicValues:keyValues withError:error]) {
        return NO;
    }
    
    [obj setValue:@(++_id) forKey:kRT_PRIMARY_PROPERTY];
    return YES;
}

// remove one row from table;
- (BOOL)deleteObj:(NSObject<RTDBDefaultProtocol>*)obj {
    return [self deleteObj:obj withError:nil];
}
- (BOOL)deleteObj:(NSObject<RTDBDefaultProtocol>*)obj withError:(NSError * __autoreleasing *)error {
    
    NSString *sql = [RTClassInfo deleteSQLFromObj:obj];
    
    if ([_dbHandler execWithQuery:sql withError:error]) {
        [obj setValue:@(0) forKey:kRT_PRIMARY_PROPERTY];
        return YES;
    } else return NO;
}

// update a row's all values;
- (BOOL)updateObj:(NSObject<RTDBDefaultProtocol>*)obj {
    return [self updateObj:obj withError:nil];
}

- (BOOL)updateObj:(NSObject<RTDBDefaultProtocol>*)obj withError:(NSError * __autoreleasing *)error {
    NSArray *pros = [RTClassInfo classAllPros:[obj class]];
    return [self updateObj:obj withPropertyArray:pros];
}

- (BOOL)updateObj:(NSObject<RTDBDefaultProtocol>*)obj withPropertyArray:(NSArray<NSString *>*)proArray {
    return [self updateObj:obj withPropertyArray:proArray withError:NULL];
}

- (BOOL)updateObj:(NSObject<RTDBDefaultProtocol>*)obj withPropertyArray:(NSArray<NSString *>*)proArray withError:(NSError *_Nullable __autoreleasing *)error {
    
    NSString *sql = [RTClassInfo updateSQLFromOBJ:obj withArray:proArray];
    NSArray *valuesArray = [RTClassInfo updateValuesFromOBJ:obj withArray:proArray];
    
    return [_dbHandler execQuery:sql withArrValues:valuesArray withError:error];
}

- (BOOL)updateObj:(NSObject<RTDBDefaultProtocol>*)obj withPropertyDict:(NSDictionary<NSString *, id>*)proDict {
    return [self updateObj:obj withPropertyDict:proDict withError:NULL];
}

- (BOOL)updateObj:(NSObject<RTDBDefaultProtocol>*)obj withPropertyDict:(NSDictionary<NSString *, id>*)proDict withError:(NSError *_Nullable __autoreleasing *)error {
    
    NSArray *allKeys = proDict.allKeys;
    
    NSString *sql = [RTClassInfo updateSQLFromOBJ:obj withArray:allKeys];
    NSArray *valuesArray = [RTClassInfo updateValuesFromProDict:proDict withArray:allKeys];
    return [_dbHandler execSQL:sql withArrValues:valuesArray withError:error];
}

////////
- (NSArray *)fetch:(Class)cls withCondition:(NSString *)condtion {
    return [self fetch:cls withCondition:condtion withError:NULL];
}

- (NSArray *)fetch:(Class)cls withCondition:(NSString *)condtion withError:(NSError * __autoreleasing *)error {
    
    NSString *sql = [RTClassInfo fetchSQLFromClass:cls withCondition:condtion];
    
    RTNext *step = [_dbHandler execSQL:sql withError:error];
    
    NSMutableArray *mObjs = [NSMutableArray array];
    __block int steping = -1;
    __block id obj = nil;
    
    [step enumColumns:^(NSString * _Nullable colName, id  _Nullable colValue, int step, int colIndex, BOOL * _Nullable stop, NSError * _Nullable err) {
        if (step > steping) {
            obj = [[cls alloc] init];
            if (obj) {
                [mObjs addObject:obj];
            }
            steping = step;
        }
        if (!error && colName) {
            [obj setValue:colValue forKey:colName];
        } else {
            *error = err;
        }
    }];
    
    if (mObjs.count > 0) {
        return mObjs.copy;
    } else return nil;
}

- (NSArray *)fetchSQL:(NSString *)sql {
    return [self fetchSQL:sql withError:NULL];
}

- (NSArray *)fetchSQL:(NSString *)sql withError:(NSError * __autoreleasing *)error {
    
    RTNext *steps = [_dbHandler execSQL:sql withError:error];
    
    NSString *tableName = [steps tableName];
    if (!tableName) {
        rt_error(@"RTDB can not find a table from sql.", 111, error);
        return nil;
    }
    
    Class cls = NSClassFromString(tableName);
    if (!cls) {
        rt_error([NSString stringWithFormat:@"RTDB can not find a class named '%@'", tableName], 111, error);
        return nil;
    }
    
    return [self enumSteps:steps forClass:cls withError:error];
}

#pragma mark - private
- (NSArray *)fetchClass:(Class)cls SQL:(NSString *)sql withError:(NSError * __autoreleasing *)error {
    
    RTNext *steps = [_dbHandler execSQL:sql withError:error];

    return [self enumSteps:steps forClass:cls withError:error];
}

- (NSArray *)enumSteps:(RTNext *)steps forClass:(Class)cls withError:(NSError * __autoreleasing *)error {
    
    NSMutableArray *mObjs = [NSMutableArray array];
    __block int rowing = -1;
    __block id obj = nil;
    [steps enumColumns:^(NSString * _Nullable colName, id  _Nullable colValue, int row, int colIndex, BOOL * _Nullable stop, NSError * _Nullable err) {
        
        if (err) {
            *error = err;
            *stop = YES;
            return;
        }
        
        if (row > rowing) {
            obj = [[cls alloc] init];
            if (obj) {
                [mObjs addObject:obj];
            }
            rowing = row;
        }
        
        if (!error && colName) {
            [obj setValue:colValue forKey:colName];
        } else {
            *error = err;
        }
    }];
    
    if (mObjs.count == 0) {
        rt_error(@"RTDB can not find any row.", 112, error);
        return nil;
    }
    return mObjs.copy;
}

@end

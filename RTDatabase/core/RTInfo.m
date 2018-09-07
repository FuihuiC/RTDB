//
//  RTInfo.m
//  RTSQLite
//
//  Created by ENUUI on 2018/5/3.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTInfo.h"
#import <objc/runtime.h>

@interface NSMutableString (Extra)
- (void)rt_appendCString:(rt_char_t *)aString;
@end

@implementation NSMutableString (Extra)
- (void)rt_appendCString:(rt_char_t *)aString {
    [self appendFormat:@"%s", aString];
}
@end

#pragma mark - private interface
/** property type */
static rt_objc_t rt_object_type(rt_char_t *attr);

/** property type to bind type */
static rt_char_t *rt_sqlite3_bind_type(rt_char_t c);


static int rt_prepare_info(Class cls, rt_pro_info_p *proInfos, NSError **err);
static int rt_class_info_v(Class cls, int count, rt_pro_info_p *infos, BOOL *has_id);


#pragma mark - FUNCTION

// 获取class的名字
rt_char_t *rt_class_name(Class cls) {
    return object_getClassName(cls);
}

// ---------------------------------------------------
rt_objc_t rt_object_class_type(id obj) {
    if (!obj || [obj isKindOfClass:[NSNull class]]) {
        return '0';
    }
    
    rt_objc_t t = '0';
    rt_char_t *clsName = class_getName([obj class]);
    
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
// 获取property类型
static rt_objc_t rt_object_type(rt_char_t *attr) {
    
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
static rt_char_t *rt_sqlite3_bind_type(rt_char_t t) {
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

static int rt_class_info_v(Class cls, int count, rt_pro_info_p *infos, BOOL *has_id) {
    
    const char *clsName = class_getName(cls);
    
    if (cls == Nil || !clsName || strcmp(clsName, "NSObject") == 0) {
        return count;
    }
    
    unsigned int outCount;
    objc_property_t *proList = class_copyPropertyList(cls, &outCount);
    if (outCount == 0) {
        free(proList);
        return count;
    }
    
    int columnIdx = count;
    for (int i = 0; i < outCount; i++) {
        objc_property_t pro = proList[i];
        
        rt_char_t *cn = property_getName(pro);
        
        if (strlen(cn) == 0) continue;
        
        rt_objc_t t = rt_object_type(property_getAttributes(pro));
        if (t == 0) continue; // unkown type
        
        if (strcmp(cn, "_id") == 0) {
            if (has_id != NULL) {
                *has_id = YES;
            }
            continue;
        }
        
        // pro info
        rt_pro_info *next = rt_make_info(columnIdx + 1, t, cn);
        // sql
        rt_info_append(infos, next);
        
        columnIdx++;
    }
    
    return rt_class_info_v(class_getSuperclass(cls), columnIdx, infos, has_id);
}


static int rt_prepare_info(Class cls, rt_pro_info_p *proInfos, NSError **err) {
    
    rt_pro_info *infos = NULL;
    BOOL hasID = NO;
    int count = rt_class_info_v(cls, 0, &infos, &hasID);
    
    if (count == 0) {
        rt_error(@"RTDB can not find properties from class!", 103, err);
        if (infos != NULL) {
            rt_free_info(infos);
        }
        return 0;
    }
    
    if (!hasID) {
        rt_error(@"RTDB can not find _id!", 105, err);
        if (infos != NULL) {
            rt_free_info(infos);
        }
        return 0;
    }
    if (proInfos) {
        *proInfos = infos;
    }
    return count;
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
#pragma mark - @implementation RTInfo
//////////////////////////////////////////////////////

@interface RTInfo () {
    rt_char_t   *_clsName;  // class name
    rt_char_t   *_insert;   // insert sql
    rt_char_t   *_update;   // update sql
    rt_char_t   *_delete;   // delete sql
    rt_char_t   *_maxid;    // max _id sql
}
@property (nonatomic, assign) int count;
@end

@implementation RTInfo

- (instancetype)initWithClass:(Class)cls withError:(NSError *__autoreleasing*)error {
    if (self = [super init]) {
        
        _cls = cls;
        NSError *err;
        _count = rt_prepare_info(cls, &_prosInfo, &err);
        if (!err) {
            _has_id = YES;
        } else {
            if (error != NULL) {
                *error = err;
            }
        }
    }
    return self;
}

- (rt_char_t *)className {
    if (_clsName == NULL) {
        _clsName = class_getName(_cls);
    }
    return _clsName;
}

- (rt_char_t *)maxidSql {
    if (_maxid == NULL) {
        _maxid = [[NSString stringWithFormat:@"SELECT MAX(_id) FROM %s", [self className]] UTF8String];
    }
    return _maxid;
}

- (rt_char_t *)createSql {
    
    NSMutableString *mCreateSql = [NSMutableString stringWithString:@"CREATE TABLE if not exists '"];
    
    [mCreateSql rt_appendCString:[self className]];
    [mCreateSql appendString:@"' ('_id' integer primary key autoincrement not null"];
    
    for (rt_pro_info *pro = _prosInfo; pro != NULL; pro = pro->next) {
        rt_char_t *bindT = rt_sqlite3_bind_type(pro->t);
        [mCreateSql appendFormat:@", '%s' '%s'", pro->name, bindT];
    }
    [mCreateSql appendString:@")"];

    return [mCreateSql UTF8String];
}

- (rt_char_t *)insertSql {
    if (_insert == NULL) {
        
        NSMutableString *mInsertSql = [NSMutableString stringWithString:@"INSERT INTO "];
        
        NSMutableString *mNames = [NSMutableString string];
        NSMutableString *mValues = [NSMutableString string];
        
        for (rt_pro_info *pro = _prosInfo; pro != NULL; pro = pro->next) {
            
            [mNames appendFormat:@"%s, ", pro->name];
            [mValues appendFormat:@":%s, ", pro->name];
        }
        
        if ([mNames hasSuffix:@","]) {
            [mNames deleteCharactersInRange:NSMakeRange(mNames.length - 1, 1)];
            [mNames appendString:@")"];
        }
        
        if ([mValues hasSuffix:@","]) {
            [mValues deleteCharactersInRange:NSMakeRange(mValues.length - 1, 1)];
            [mValues appendString:@")"];
        }
        
        [mInsertSql appendFormat:@"%@  VALUES (%@", mNames, mValues];

        _insert = [mInsertSql UTF8String];
    }
    return _insert;
}

- (rt_char_t *)updateSql {
    if (_update == nil) {

        NSMutableString *mUpdateSql = [NSMutableString stringWithString:@"UPDATE "];
        [mUpdateSql appendFormat:@"%s SET ", [self className]];
        
        for (rt_pro_info *pro = _prosInfo; pro != NULL; pro = pro->next) {
            [mUpdateSql appendFormat:@"%s = ?,", pro->name];
        }
        if ([mUpdateSql hasSuffix:@","]) {
            [mUpdateSql deleteCharactersInRange:NSMakeRange(mUpdateSql.length - 1, 1)];
        }
        
        [mUpdateSql appendString:@" WHERE _id = "];
        _update = [mUpdateSql UTF8String];
    }
    return _update;
}

- (rt_char_t *)deleteSql {
    if (_delete == nil) {
       _delete = [[NSString stringWithFormat:@"DELETE FROM %s WHERE _id = ", [self className]] UTF8String];
    }
    return _delete;
}

- (rt_char_t *)updateSqlWithID:(NSInteger)_id {
    if ([self updateSql] == NULL)  return NULL;
    
    return [[NSString stringWithFormat:@"%s %ld", _update, _id] UTF8String];
}

- (rt_char_t *)deleteSqlWithID:(NSInteger)_id {
    if ([self deleteSql] == NULL) return NULL;
    return [[NSString stringWithFormat:@"%s %ld", _delete, _id] UTF8String];
}

- (void)dealloc {
    if (_prosInfo != NULL) {
        rt_free_info(_prosInfo);
    }
}

@end


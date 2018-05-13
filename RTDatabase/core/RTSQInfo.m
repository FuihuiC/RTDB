 //
//  RTSQInfo.m
//  RTSQLite
//
//  Created by ENUUI on 2018/5/3.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTSQInfo.h"
#import <objc/runtime.h>


#pragma mark - private interface
/**
 获取property类型

 @param attr runtime 获取的 property attribute
 @return 类型 (rt_char_t)
 */
static rt_objc_t rt_object_type(rt_char_t *attr);

/**
 根据property类型 获取 bind 类型

 @param c property类型
 @return bind 类型
 */
static rt_char_t *rt_sqlite3_bind_type(rt_char_t c);

/**
 获取需要建表的类的信息

 @param cls 需要建表的类
 @param className 类名
 @param proInfos 属性信息
 @param creat  创建表的语句
 @param insert 插入sql语句
 @param update 改cloumn的语句
 */
static void rt_class_info(Class cls, BOOL *has_id, char **className, rt_pro_info_p *proInfos, char * *creat, char * *insert, char * *update, char * *delete);

#pragma mark - FUNCTION

void rt_free_str(char **str) {
    if (str == NULL) {
        return;
    }
    if (*str == NULL) {
        return;
    }
    free(*str);
    *str = 0x00;
}

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



static void rt_class_info(Class cls, BOOL *has_id, char **className, rt_pro_info_p *proInfos, char **creat, char **insert, char **update, char **delete) {
    
    rt_char_t *clsName = class_getName(cls);
   
    unsigned int outCount;
    objc_property_t *proList = class_copyPropertyList(cls, &outCount);
    
    if (outCount > 0) {
        
        char *props   = NULL;
        props = rt_strcat(props, " (");
        char *values  = NULL;
        values = rt_strcat(values, "VALUES (");
        char *updates = NULL;
        char *creats  = NULL;
        
        rt_pro_info *infos = NULL;
        for (int i = 0; i < outCount; i++) {
            objc_property_t pro = proList[i];
            
            rt_char_t *cn = property_getName(pro);
            
            if (strlen(cn) == 0) continue;

            rt_objc_t t = rt_object_type(property_getAttributes(pro));
            if (t == 0) continue; // unkown type
            
            // sql bind type
            rt_char_t *bindT = rt_sqlite3_bind_type(t);
            
            if ((strcmp(cn, "_id") == 0) && (strcmp(bindT, "INTEGER") == 0)) {
                *has_id = YES;
                continue;
            }
            
            // pro info
            rt_pro_info *next = rt_make_info(i, t, cn);
            // sql
            rt_info_append(&infos, next);
            
            bool end = (i == (outCount - 1));
            
            // creat
            rt_char_t *creat_end = end ? "')" : "', ";
            rt_str_append(&creats, 6,
                          "'",
                          cn,
                          "' ",
                          "'",
                          bindT,
                          creat_end);
            
            // insert
            // pros
            rt_char_t *p = end ? ") " : ", ";
            rt_str_append(&props, 2, cn, p);
            // values
            rt_char_t *v = end ? "?)" : "?, ";
            values = rt_strcat(values, (char *)v);
            
            // update
            rt_char_t *update_end = end ? "=?" : "=?, ";
            rt_str_append(&updates, 2, cn, update_end);
        }

        char *creatSql = NULL; // CREATE
        rt_str_append(&creatSql, 4,
                      "CREATE TABLE if not exists '",
                      clsName,
                      "' ('_id' integer primary key autoincrement not null, ",
                      creats);
        free(creats);
        
        char *insertSql = NULL; // INSERT
        rt_str_append(&insertSql, 4, "INSERT INTO ", clsName, props, values);
        free(props);
        free(values);
        
        char *updateSql = NULL; // UPDATE
        rt_str_append(&updateSql, 5, "UPDATE ", clsName, " SET ", updates, " WHERE _id = ");
        free(updates);
        
        char *dstr = NULL; // DELETE
        rt_str_append(&dstr, 3, "DELETE FROM ", clsName, " WHERE _id = ");
        
        *className = (char *)clsName;
        *proInfos = infos;
        *creat = creatSql;
        *insert = insertSql;
        *update = updateSql;
        *delete = dstr;
    }
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
#pragma mark - @implementation RTSQInfo
//////////////////////////////////////////////////////
@implementation RTSQInfo

- (instancetype)initWithClass:(Class)cls {
    if (self = [super init]) {
        _has_id = NO;
        rt_class_info(cls, &_has_id, &_clsName, &_prosInfo, &_creat, &_insert, &_update, &_delete);
        
        char *maxid = NULL;
        rt_str_append(&maxid, 2, "SELECT MAX(_id) FROM ", _clsName);
        _maxid = maxid;
    }
    return self;
}

- (rt_char_t *)updateSqlWithID:(NSInteger)_id {
    if (_creat == NULL)  return NULL;
    
    char *updateSql = (char *)calloc((strlen(_update) + rt_integer_digit(_id)), char_len);
    sprintf(updateSql, "%s%ld", _update, (long)_id);
    return (rt_char_t *)updateSql;
}

- (rt_char_t *)deleteSqlWithID:(NSInteger)_id {
    if (_delete == NULL) return NULL;
    
    char *deleteSql = (char *)calloc((strlen(_delete) + rt_integer_digit(_id)), char_len);
    sprintf(deleteSql, "%s%ld", _delete, (long)_id);
    return (rt_char_t *)deleteSql;
}

- (void)dealloc {
    if (_prosInfo != NULL) {
        rt_free_info(&_prosInfo);
    }
}
@end

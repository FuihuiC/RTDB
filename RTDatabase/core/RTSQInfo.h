//
//  RTSQInfo.h
//  RTSQLite
//
//  Created by ENUUI on 2018/5/3.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTPreset.h"

RT_EXTERN void rt_free_str(char **str);

RT_EXTERN rt_objc_t rt_object_class_type(id obj);

RT_EXTERN rt_char_t *rt_class_name(Class cls);

#pragma mark - @interface RTSQInfo
/** Caching information about the model class. */
@interface RTSQInfo : NSObject {
    @public
    BOOL        _has_id;    // if the model class has property named _id and _id is the type of integer, _has_id = YES.
    char        *_clsName;  // class name
    char        *_creat;    // creat sql
    char        *_insert;   // insert sql
    char        *_update;   // update sql
    char        *_delete;   // delete sql
    char        *_maxid;    // max _id sql
    rt_pro_info *_prosInfo; // property infomation for RTDB
}

- (instancetype)initWithClass:(Class)cls;

/**
 Method make the update sql complete.

 @param _id column primary _id
 @return update sql, need call function free().
 */
- (rt_char_t *)updateSqlWithID:(NSInteger)_id;

/**
 Method make the delete sql complete.

 @param _id column primary _id
 @return delete sql, need call function free().
 */
- (rt_char_t *)deleteSqlWithID:(NSInteger)_id;
@end

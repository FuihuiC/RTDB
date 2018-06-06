//
//  RTInfo.h
//  RTSQLite
//
//  Created by ENUUI on 2018/5/3.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTPreset.h"

RT_EXTERN rt_char_t *rt_class_name(Class cls);

#pragma mark - @interface RTInfo

/** Caching information about the model class. */
NS_SWIFT_UNAVAILABLE("")
@interface RTInfo : NSObject {
    @public
    BOOL        _has_id;    // if the model class has property named _id and _id is the type of integer, _has_id = YES.
    rt_pro_info *_prosInfo; // property infomation for RTDB
}

@property (nonatomic, strong) Class cls;


- (instancetype)initWithClass:(Class)cls withError:(NSError *__autoreleasing*)error;



- (rt_char_t *)className;
- (rt_char_t *)creatSql;
- (rt_char_t *)insertSql;
- (rt_char_t *)maxidSql;
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

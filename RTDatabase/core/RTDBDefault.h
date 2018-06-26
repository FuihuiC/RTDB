//
//  RTDBDefault.h
//  RTSQLite
//
//  Created by ENUUI on 2018/5/8.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTDB.h"
#import "RTInfo.h"

NS_SWIFT_UNAVAILABLE("")
@interface RTDBDefault : RTDB
/**
 Building a table based on the model class

 @param cls modle class for building a table. A property _id typed of integer is required
 @param err OUT: error msg
 @return Whether to perform success or not
 */
- (BOOL)creatTable:(Class)cls withError:(NSError * __autoreleasing *)err;


/**
 insert

 @param obj the object of the class which has been build a table. If the object has not a property _id typed of integer, it will be error.
 @param err OUT: error msg
 @return Whether to perform success or not
 */
- (BOOL)insertObj:(id)obj withError:(NSError * __autoreleasing *)err;


/**
 update

 @param obj The object of the class which has been build a table. If the object has not a property _id typed of integer, it will be error.
 @param params columns To update;
 @param err OUT: error msg
 @return Whether to perform success or not
 */
- (BOOL)updateObj:(id)obj withParams:(NSDictionary <NSString *, id>*)params withError:(NSError *__autoreleasing *)err;

/**
 update

 @param obj The object of the class which has been build a table. If the object has not a property _id typed of integer, it will be error.
 @param err OUT: error msg
 @return Whether to perform success or not
 */
- (BOOL)updateObj:(id)obj withError:(NSError * __autoreleasing *)err;


/**
 delete

 @param obj the object of the class which has been build a table. If the object has not a property _id typed of integer, it will be error.
 @param err OUT: error msg
 @return Whether to perform success or not
 */
- (BOOL)deleteObj:(id)obj withError:(NSError * __autoreleasing *)err;

/**
 select
 
 @return Dictionary array. Each dictionary corresponds to a row of data.
 */
- (NSArray<NSDictionary *> *)fetchSql:(NSString *)sql withError:(NSError * __autoreleasing *)err;

/**
 select

 @return Object array. Object's type depend on the table name in the paramter sql.
 */
- (NSArray *)fetchObjSql:(NSString *)sql withError:(NSError * __autoreleasing *)err;
@end

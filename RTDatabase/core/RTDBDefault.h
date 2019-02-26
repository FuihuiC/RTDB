//
//  RTOBDB.h
//  RTDatebase
//
//  Created by hc-jim on 2019/2/25.
//  Copyright © 2019 ENUUI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTDB.h"

NS_ASSUME_NONNULL_BEGIN

@protocol RTDBDefaultProtocol
@property (nonatomic, assign) NSInteger _id;
@end


@interface RTDBDefault : NSObject
// 装载 RTDB
@property (nonatomic, strong) RTDB *dbHandler;

/**
 Building a table based on the model class
 
 cls: modle class for building a table. A property _id typed of integer is required
 error OUT: error msg
 return: Whether to perform success or not
 */
- (BOOL)createTable:(Class)cls;
- (BOOL)createTable:(Class)cls withError:(NSError *_Nullable __autoreleasing *)error;

/**
 insert
 
 obj: the object of the class which has been build a table. If the object has not a property _id typed of integer, it will be error.
 error OUT: error msg
 return: Whether to perform success or not
 */
- (BOOL)insertObj:(NSObject<RTDBDefaultProtocol>*)obj;
- (BOOL)insertObj:(NSObject<RTDBDefaultProtocol>*)obj withError:(NSError *_Nullable __autoreleasing *)error;

// remove one row from table;
- (BOOL)deleteObj:(NSObject<RTDBDefaultProtocol>*)obj;
- (BOOL)deleteObj:(NSObject<RTDBDefaultProtocol>*)obj withError:(NSError *_Nullable __autoreleasing *)error;

/**
 update
 
 @param obj The object of the class which has been build a table. If the object has not a property _id typed of integer, it will be error.
 */
- (BOOL)updateObj:(NSObject<RTDBDefaultProtocol>*)obj;
- (BOOL)updateObj:(NSObject<RTDBDefaultProtocol>*)obj withError:(NSError *_Nullable __autoreleasing *)error;
- (BOOL)updateObj:(NSObject<RTDBDefaultProtocol>*)obj withPropertyArray:(NSArray<NSString *>*)proArray;
- (BOOL)updateObj:(NSObject<RTDBDefaultProtocol>*)obj withPropertyArray:(NSArray<NSString *>*)proArray withError:(NSError *_Nullable __autoreleasing *)error;
- (BOOL)updateObj:(NSObject<RTDBDefaultProtocol>*)obj withPropertyDict:(NSDictionary<NSString *, id>*)proDict;
- (BOOL)updateObj:(NSObject<RTDBDefaultProtocol>*)obj withPropertyDict:(NSDictionary<NSString *, id>*)proDict withError:(NSError *_Nullable __autoreleasing *)error;

////////
- (NSArray *)fetch:(Class)cls withCondition:(NSString *)condtion;
- (NSArray *)fetch:(Class)cls withCondition:(NSString *)condtion withError:(NSError *_Nullable __autoreleasing *)error;

- (NSArray *)fetchSQL:(NSString *)sql withError:(NSError *_Nullable __autoreleasing *)error;
@end
NS_ASSUME_NONNULL_END

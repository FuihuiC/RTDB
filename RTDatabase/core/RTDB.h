//
//  RTDB.h
//  RTSQLite
//
//  Created by ENUUI on 2018/5/3.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTNext.h"
#import "RTDBFunc.h"
#import "RTInfo.h"

/**
 * This class is used to manage SQLite.
 * This class encapsulates the basic operations of SQLite.
 */
@interface RTDB : NSObject  {
    @public
    void *_db;
}

#pragma mark -
/**
 * Create or open sqlite. based on the specified path.
 * @required: The path needs to end with the SQLite file.
 */
- (BOOL)openWithPath:(NSString *)path withError:(NSError *__autoreleasing *)error NS_SWIFT_NAME(open(path:));
- (BOOL)openWithPath:(NSString *)path withFlags:(int)flags withError:(NSError *__autoreleasing *)error NS_SWIFT_NAME(open(path:flags:));

/**
 * Close the SQLite that has been opened
 */
- (BOOL)close;

/**
 * Execute the SQL statement and return if it is successful
 * If you select the (withError:) method and pass in (NSError **) err, the error message is transmitted when the execution fails.
 * Select the appropriate method according to the different parameters outside the SQL statement.
 */
- (BOOL)execWithQuery:(NSString *)sql;
- (BOOL)execWithQuery:(NSString *)sql withError:(NSError *__autoreleasing *)err NS_SWIFT_NAME(exec(query:));

- (BOOL)execQuery:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION NS_SWIFT_UNAVAILABLE("");
- (BOOL)exceWithError:(NSError *__autoreleasing *)err withQuery:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION NS_SWIFT_UNAVAILABLE("");

- (BOOL)exceQuery:(NSString *)sql withArrArgs:(NSArray *)arrArgs;
- (BOOL)exceQuery:(NSString *)sql withArrArgs:(NSArray *)arrArgs withError:(NSError *__autoreleasing *)err NS_SWIFT_NAME(exec(query:arrArgs:));

- (BOOL)exceQuery:(NSString *)sql withParams:(NSDictionary *)params;
- (BOOL)exceQuery:(NSString *)sql withParams:(NSDictionary *)params withError:(NSError *__autoreleasing *)err NS_SWIFT_NAME(exec(query:params:));

/**
 * Execute the SQL statement and return an object of RTNext. For details, please see RTNext class.
 * If you select the (withError:) method and pass in (NSError **) err, the error message is transmitted when the execution fails.
 * Select the appropriate method according to the different parameters outside the SQL statement.
 */
- (RTNext *)execWithSql:(NSString *)sql;
- (RTNext *)execWithSql:(NSString *)sql withError:(NSError *__autoreleasing *)err NS_SWIFT_NAME(exec(sql:));

- (RTNext *)execSql:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION NS_SWIFT_UNAVAILABLE("");
- (RTNext *)execWithError:(NSError *__autoreleasing *)err withSql:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION NS_SWIFT_UNAVAILABLE("");

- (RTNext *)execSql:(NSString *)sql withArrArgs:(NSArray *)arrArgs;
- (RTNext *)execSql:(NSString *)sql withArrArgs:(NSArray *)arrArgs withError:(NSError *__autoreleasing *)err NS_SWIFT_NAME(exec(sql:arrArgs:));

- (RTNext *)execSql:(NSString *)sql withParams:(NSDictionary *)params;
- (RTNext *)execSql:(NSString *)sql withParams:(NSDictionary *)params withError:(NSError *__autoreleasing *)err NS_SWIFT_NAME(exec(sql:params:));


- (RTNext *)execSql:(NSString *)sql
         withParams:(NSDictionary *)params
        withArrArgs:(NSArray *)arrArgs
           withArgs:(va_list)args
          withError:(NSError *__autoreleasing *)err NS_SWIFT_UNAVAILABLE("");


- (BOOL)begin;
- (BOOL)commit;
- (BOOL)rollback;
@end

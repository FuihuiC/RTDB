//
//  RTSDBExtra.h
//  RTDatabase
//
//  Created by ENUUI on 2018/5/23.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTDBDefault.h"

typedef void(^rt_error_b_t)(NSError *error);
typedef void(^rt_next_block_t)(RTNext *next);
typedef void(^rt_step_block_t)(NSDictionary *result, int idx, BOOL *stop);

typedef void(^rt_select_block_t)(NSArray *result);

NS_SWIFT_UNAVAILABLE("")
@interface RTSDBExtra : NSObject

#pragma mark Usual
- (RTSDBExtra *)onMain;
@property (nonatomic, readonly) void(^onError)(rt_error_b_t);

- (void)onEnd;
- (RTSDBExtra *)reset;
/**
 * When invoked after onFetch, onResult will callback
 * the array of objects corresponding to the query table.
 * Otherwise, onResult will call back the dictionary
 * array of query results
 */
@property (nonatomic, readonly) RTSDBExtra *(^onResult)(rt_select_block_t);

#pragma mark Normal
/** open database if path exist */
@property (nonatomic, readonly) RTSDBExtra *(^onOpen)(NSString *);

@property (nonatomic, readonly) RTSDBExtra *(^onOpenFlags)(NSString *, int);

/**
 * Execute a sql statement.
 * Three methods of parameter typed of NSDictionary NSArray and ...
 * After these three methods, please call onEnum or onStep.
 */
@property (nonatomic, readonly) RTSDBExtra *(^execDict)(NSString *, NSDictionary *);

@property (nonatomic, readonly) RTSDBExtra *(^execArr)(NSString *, NSArray *);

@property (nonatomic, readonly) RTSDBExtra *(^execArgs)(NSString *, ...);

/**
 * Called after execDict execArr and execArgs.
 * rt_step_block_t will callback all data typed of NSDictionary by loop.
 * This method is suggested to be used to select data from table
 */
@property (nonatomic, readonly) RTSDBExtra *(^onEnum)(rt_step_block_t);
/**
 * Called after execDict execArr and execArgs.
 * rt_next_block_t will callback RTNext object. Detial see RTNext.
 * This method is suggested to be used to one step operate.
 */
@property (nonatomic, readonly) RTSDBExtra *(^onStep)(rt_next_block_t);
/**
 * Called after execDict execArr and execArgs.
 * onDone() will run out all sqlite3_step() == SQLITE_ROW, and callback nothing.
 * see error call onError().
 */
- (RTSDBExtra *)onDone;

#pragma mark Default
/** detial see RTDBDefault */
@property (nonatomic, readonly) RTSDBExtra *(^onCreate)(Class);

@property (nonatomic, readonly) RTSDBExtra *(^onInsert)(id obj);

@property (nonatomic, readonly) RTSDBExtra *(^onUpdate)(id obj);

@property (nonatomic, readonly) RTSDBExtra *(^onUpdateWithParams)(id obj, NSDictionary *);

@property (nonatomic, readonly) RTSDBExtra *(^onDelete)(id obj);

/**
 * OnFetch will look up the table based on the incoming SQL
 * and associate each row's data to the object of the class
 * and store it in the array.
 * Call onResult will callback the array.
 */
@property (nonatomic, readonly) RTSDBExtra *(^onFetch)(NSString *);

@property (nonatomic, readonly) RTSDBExtra *(^onFetchObjs)(NSString *, rt_select_block_t);

#pragma mark Transaction
- (RTSDBExtra *)onBegin;
- (RTSDBExtra *)onCommit;
- (RTSDBExtra *)onRollback;
@end

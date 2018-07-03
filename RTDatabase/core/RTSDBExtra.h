//
//  RTSDBExtra.h
//  RTDatabase
//
//  Created by ENUUI on 2018/5/23.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTDBDefault.h"

typedef void(^rt_error_b_t)(NSError *error);

typedef void(^rt_block_t)(void);
typedef void(^rt_next_block_t)(RTNext *);
typedef void(^rt_step_block_t)(NSDictionary *, int, BOOL *);

typedef void(^rt_select_block_t)(NSArray *);

NS_SWIFT_UNAVAILABLE("")
@interface RTSDBExtra : NSObject

#pragma mark Usual

// back to defaultQueue
- (RTSDBExtra *)onDefault;

- (RTSDBExtra *(^)(dispatch_queue_t))onQueue;
@property (nonatomic, readonly) RTSDBExtra *(^onQueue)(dispatch_queue_t);

- (RTSDBExtra *)onMain;


- (RTSDBExtra *(^)(rt_block_t))onWorkQueue;
@property (nonatomic, readonly) RTSDBExtra *(^onWorkQueue)(rt_block_t);

- (void(^)(rt_error_b_t))onError;
@property (nonatomic, readonly) void(^onError)(rt_error_b_t);

- (void)onEnd;

#pragma mark Normal
/** open database if path exist */
- (RTSDBExtra *(^)(NSString *))onOpen;
@property (nonatomic, readonly) RTSDBExtra *(^onOpen)(NSString *);

- (RTSDBExtra *(^)(NSString *, int))onOpenFlags;
@property (nonatomic, readonly) RTSDBExtra *(^onOpenFlags)(NSString *, int);

/**
 * Execute a sql statement.
 * Three methods of parameter typed of NSDictionary NSArray and ...
 * After these three methods, please call onEnum or onStep.
 */
- (RTSDBExtra *(^)(NSString *, NSDictionary *))execDict;
@property (nonatomic, readonly) RTSDBExtra *(^execDict)(NSString *, NSDictionary *);

- (RTSDBExtra *(^)(NSString *, NSArray *))execArr;
@property (nonatomic, readonly) RTSDBExtra *(^execArr)(NSString *, NSArray *);

- (RTSDBExtra *(^)(NSString *, ...))execArgs;
@property (nonatomic, readonly) RTSDBExtra *(^execArgs)(NSString *, ...);

/**
 * Called after execDict execArr and execArgs.
 * rt_step_block_t will callback all data typed of NSDictionary by loop.
 * This method is suggested to be used to select data from table
 */
- (RTSDBExtra *(^)(rt_step_block_t))onEnum;
@property (nonatomic, readonly) RTSDBExtra *(^onEnum)(rt_step_block_t);
/**
 * Called after execDict execArr and execArgs.
 * rt_next_block_t will callback RTNext object. Detial see RTNext.
 * This method is suggested to be used to one step operate.
 */
- (RTSDBExtra *(^)(rt_next_block_t))onStep;
@property (nonatomic, readonly) RTSDBExtra *(^onStep)(rt_next_block_t);
/**
 * Called after execDict execArr and execArgs.
 * onDone() will run out all sqlite3_step() == SQLITE_ROW, and callback nothing.
 * see error call onError().
 */
- (RTSDBExtra *)onDone;

#pragma mark Default
/** detial see RTDBDefault */
- (RTSDBExtra *(^)(Class))onCreate;
@property (nonatomic, readonly) RTSDBExtra *(^onCreate)(Class);

- (RTSDBExtra *(^)(id obj))onInsert;
@property (nonatomic, readonly) RTSDBExtra *(^onInsert)(id obj);

- (RTSDBExtra *(^)(id obj))onUpdate;
@property (nonatomic, readonly) RTSDBExtra *(^onUpdate)(id obj);

- (RTSDBExtra *(^)(id obj, NSDictionary *params))onUpdateWithParams;
@property (nonatomic, readonly) RTSDBExtra *(^onUpdateWithParams)(id obj, NSDictionary *);

- (RTSDBExtra *(^)(id obj))onDelete;
@property (nonatomic, readonly) RTSDBExtra *(^onDelete)(id obj);


- (RTSDBExtra *(^)(NSString *, rt_select_block_t))onFetchDics;
@property (nonatomic, readonly) RTSDBExtra *(^onFetchDics)(NSString *, rt_select_block_t);

- (RTSDBExtra *(^)(NSString *, rt_select_block_t))onFetchObjs;
@property (nonatomic, readonly) RTSDBExtra *(^onFetchObjs)(NSString *, rt_select_block_t);

#pragma mark Transaction
- (RTSDBExtra *)onBegin;
- (RTSDBExtra *)onCommit;
- (RTSDBExtra *)onRollback;
@end

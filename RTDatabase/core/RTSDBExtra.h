//
//  RTSDBExtra.h
//  RTDatabase
//
//  Created by hc-jim on 2018/5/23.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTDBDefault.h"

typedef void(^rt_error_b_t)(NSError *error);

typedef void(^rt_block_t)(void);
typedef void(^rt_next_block_t)(RTNext *);
typedef void(^rt_step_block_t)(NSDictionary *dic, int step, BOOL *stop);

typedef void(^rt_select_block_t)(NSArray *);


@interface RTSDBExtra : NSObject

#pragma mark Usual
- (void)threadLock:(rt_block_t)block;
// back to defaultQueue
- (RTSDBExtra *)onDefault;
- (RTSDBExtra *(^)(dispatch_queue_t))onQueue;
- (RTSDBExtra *)onMain;
- (RTSDBExtra *(^)(rt_block_t))onWorkQueue;
- (void(^)(rt_error_b_t))onError;

#pragma mark Normal
/** open database if path exist */
- (RTSDBExtra *(^)(NSString *))onOpen;
- (RTSDBExtra *(^)(NSString *, int))onOpenFlags;

/**
 * Execute a sql statement.
 * Three methods of parameter typed of NSDictionary NSArray and ...
 * After these three methods, please call onEnum or onStep.
 */
- (RTSDBExtra *(^)(NSString *, NSDictionary *))execDict;
- (RTSDBExtra *(^)(NSString *, NSArray *))execArr;
- (RTSDBExtra *(^)(NSString *, ...))execArgs;

/**
 * Called after execDict execArr and execArgs.
 * rt_step_block_t will callback all data typed of NSDictionary by loop.
 * This method is suggested to be used to select data from table
 */
- (RTSDBExtra *(^)(rt_step_block_t))onEnum;

/**
 * Called after execDict execArr and execArgs.
 * rt_next_block_t will callback RTNext object. Detial see RTNext.
 * This method is suggested to be used to one step operate.
 */
- (RTSDBExtra *(^)(rt_next_block_t))onStep;

/**
 * Called after execDict execArr and execArgs.
 * onDone() will run out all sqlite3_step() == SQLITE_ROW, and callback nothing.
 * see error call onError().
 */
- (RTSDBExtra *(^)(void))onDone;
#pragma mark Default
/** detial see RTDBDefault */
- (RTSDBExtra *(^)(Class))onCreat;
- (RTSDBExtra *(^)(id obj))onInsert;
- (RTSDBExtra *(^)(id obj))onUpdate;
- (RTSDBExtra *(^)(id obj))onDelete;
- (RTSDBExtra *(^)(NSString *, rt_select_block_t))onFetchDics;
- (RTSDBExtra *(^)(NSString *, rt_select_block_t))onFetchObjs;
@end

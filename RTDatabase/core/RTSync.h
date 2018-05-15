//
//  RTSync.h
//  RTSQLite
//
//  Created by ENUUI on 2018/5/10.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTNext.h"
@class RTSyncRun;
typedef void(^rt_error_b_t)(NSError *error);

typedef void(^rt_block_t)(void);
typedef void(^rt_next_block_t)(RTNext *);
typedef void(^rt_step_block_t)(NSDictionary *dic, int step, BOOL *stop);

typedef void(^rt_select_block_t)(NSArray *);


@interface RTSync : NSObject

/**
 * Operate about sqlite is suggested to be locked.
 */
- (void)threadLock:(rt_block_t)block;

/**
 * After call onQueue() or onMain(), all operate on the queue until
 * calling onQueue() again or call onMain()
 */
- (RTSyncRun *(^)(dispatch_queue_t))onQueue;
- (RTSyncRun *)onMain;

/**
 * If not a RTSyncRun object. call onDefault().
 * After this method, call methods only belong to RTSyncRun.
 */
- (RTSyncRun *)onDefault;

/** open database if path exist */
- (RTSyncRun *(^)(NSString *))onOpen;
- (RTSyncRun *(^)(NSString *, int))onOpenFlags;
/** close database */
- (void)onClose;

/**
 * Execute a sql statement.
 * Three methods of parameter typed of NSDictionary NSArray and ...
 * After these three methods, please call onEnum or onStep.
 */
- (RTSyncRun *(^)(NSString *, NSDictionary *))execDict;
- (RTSyncRun *(^)(NSString *, NSArray *))execArr;
- (RTSyncRun *(^)(NSString *, ...))execArgs;
@end


@interface RTSyncRun : NSObject
#pragma mark Usual
- (void)threadLock:(rt_block_t)block;
- (RTSyncRun *(^)(dispatch_queue_t))onQueue;
- (RTSyncRun *)onMain;
- (RTSyncRun *(^)(rt_block_t))onWorkQueue;
- (void(^)(rt_error_b_t))onError;

#pragma mark Normal

/** open database if path exist */
- (RTSyncRun *(^)(NSString *))onOpen;
- (RTSyncRun *(^)(NSString *, int))onOpenFlags;

/**
 * Execute a sql statement.
 * Three methods of parameter typed of NSDictionary NSArray and ...
 * After these three methods, please call onEnum or onStep.
 */
- (RTSyncRun *(^)(NSString *, NSDictionary *))execDict;
- (RTSyncRun *(^)(NSString *, NSArray *))execArr;
- (RTSyncRun *(^)(NSString *, ...))execArgs;

/**
 * Called after execDict execArr and execArgs.
 * rt_step_block_t will callback all data typed of NSDictionary by loop.
 * This method is suggested to be used to select data from table
 */
- (RTSyncRun *(^)(rt_step_block_t))onEnum;

/**
 * Called after execDict execArr and execArgs.
 * rt_next_block_t will callback RTNext object. Detial see RTNext.
 * This method is suggested to be used to one step operate.
 */
- (RTSyncRun *(^)(rt_next_block_t))onStep;

/**
 * Called after execDict execArr and execArgs.
 * onDone() will run out all sqlite3_step() == SQLITE_ROW, and callback nothing.
 * see error call onError().
 */
- (RTSyncRun *(^)(void))onDone;
#pragma mark Default
/** detial see RTDBDefault */
- (RTSyncRun *(^)(Class))onCreat;
- (RTSyncRun *(^)(id obj))onInsert;
- (RTSyncRun *(^)(id obj))onUpdate;
- (RTSyncRun *(^)(id obj))onDelete;
- (RTSyncRun *(^)(NSString *, rt_select_block_t))onFetchDics;
- (RTSyncRun *(^)(NSString *, rt_select_block_t))onFetchObjs;
@end





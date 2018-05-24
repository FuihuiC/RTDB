//
//  RTSDB.h
//  RTSQLite
//
//  Created by ENUUI on 2018/5/10.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTSDBExtra.h"

@interface RTSDB : NSObject

/**
 * If the defaultQueue is set, all operations will be executed on this queue
 * until a new queue is set up.
 * Set a new queue can call setDefaultQueue:, onQueue and onMain.
 * But onQueue and onMain did not change the defaultQueue.
 *
 * Call onDefault, back to defaultQueue.
 *
 * Default is NULL, and all operations will be executed on current queue.
 */
@property (nonatomic, strong) dispatch_queue_t defaultQueue;

/**
 * Operate about sqlite is suggested to be locked.
 */
- (void)threadLock:(rt_block_t)block;

/**
 * After call onQueue() or onMain(), all operate on the queue until
 * calling onQueue() again or call onMain()
 *
 * If did not set a defaultQueue, calling onDefault will not change the queue.
 */
- (RTSDBExtra *)onDefault;
- (RTSDBExtra *(^)(dispatch_queue_t))onQueue;
- (RTSDBExtra *)onMain;


///** open database if path exist */
//- (RTSDBExtra *(^)(NSString *))onOpen;
//- (RTSDBExtra *(^)(NSString *, int))onOpenFlags;
//
///**
// * Execute a sql statement.
// * Three methods of parameter typed of NSDictionary NSArray and ...
// * After these three methods, please call onEnum or onStep.
// */
//- (RTSDBExtra *(^)(NSString *, NSDictionary *))execDict;
//- (RTSDBExtra *(^)(NSString *, NSArray *))execArr;
//- (RTSDBExtra *(^)(NSString *, ...))execArgs;

/** Transaction */
//- (void)onBegin;
//- (void)onCommit;
//- (void)onRollback;


/** close database */
- (void)onClose;
@end

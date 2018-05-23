//
//  RTSDB.h
//  RTSQLite
//
//  Created by ENUUI on 2018/5/10.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTSDBExtra.h"

//@class RTSDBExtra;

@interface RTSDB : NSObject

/**
 * Operate about sqlite is suggested to be locked.
 */
- (void)threadLock:(rt_block_t)block;

/**
 * After call onQueue() or onMain(), all operate on the queue until
 * calling onQueue() again or call onMain()
 */
- (RTSDBExtra *(^)(dispatch_queue_t))onQueue;
- (RTSDBExtra *)onMain;

/**
 * If not a RTSDBExtra object. call onDefault().
 * After this method, call methods only belong to RTSDBExtra.
 */
- (RTSDBExtra *)onDefault;

/** open database if path exist */
- (RTSDBExtra *(^)(NSString *))onOpen;
- (RTSDBExtra *(^)(NSString *, int))onOpenFlags;
/** close database */
- (void)onClose;

/**
 * Execute a sql statement.
 * Three methods of parameter typed of NSDictionary NSArray and ...
 * After these three methods, please call onEnum or onStep.
 */
- (RTSDBExtra *(^)(NSString *, NSDictionary *))execDict;
- (RTSDBExtra *(^)(NSString *, NSArray *))execArr;
- (RTSDBExtra *(^)(NSString *, ...))execArgs;
@end


//@interface RTSDBExtra : NSObject
//
//@end





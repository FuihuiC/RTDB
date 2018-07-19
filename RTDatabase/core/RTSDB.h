//
//  RTSDB.h
//  RTSQLite
//
//  Created by ENUUI on 2018/5/10.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTSDBExtra.h"


typedef void(^RTQueueBlock)(RTSDBExtra *dber);
NS_SWIFT_UNAVAILABLE("")
@interface RTSDB : NSObject

/** RTDB manager */
@property (nonatomic, strong) RTDBDefault *db;

/**
 * If the defaultQueue is set, all operations will be executed on this queue
 * until a new queue is set up.
 */
@property (nonatomic, strong) dispatch_queue_t defaultQueue;

/**
 * This method will not change a queue.
 */
- (RTSDBExtra *)onCurrent;

/**
 * Change to the given queue, and callback a RTSDBExtra instance.
 */
@property (nonatomic, readonly) void(^on)(dispatch_queue_t, RTQueueBlock);
/**
 * Change to the default queue, and callback a RTSDBExtra instance.
 * If RTSDB dose not have a defaultQueue, it will change back to MainQueue.
 */
@property (nonatomic, readonly) void(^onDefault)(RTQueueBlock);

/** close database */
- (void)onClose;
@end

//
//  RTSDB.m
//  RTSQLite
//
//  Created by ENUUI on 2018/5/10.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTSDB.h"
#define RT_EXTRA [[RTSDBExtra alloc] initWithDBManager:self.db withDefaultQueue:self.defaultQueue]
///----------------------------------------------------------
///----------------------------------------------------------
///----------------------------------------------------------
#pragma mark - RTSDBExtra
@interface RTSDBExtra ()
- (instancetype)initWithDBManager:(RTDBDefault *)dbManager withDefaultQueue:(dispatch_queue_t)q;
@end

///----------------------------------------------------------
///----------------------------------------------------------
///----------------------------------------------------------
#pragma mark - RTSync

@implementation RTSDB

- (instancetype)init {
    if (self = [super init]) {
        _db = [[RTDBDefault alloc] init];
    }
    return self;
}

- (RTSDBExtra *)onMain {
    return RT_EXTRA.onMain;
}

- (void (^)(dispatch_queue_t, void (^)(RTSDBExtra *)))on {
    return ^(dispatch_queue_t q, void (^block)(RTSDBExtra *)) {
        if (!block) return;
        dispatch_async(q, ^{
           block(RT_EXTRA.onQueue(q));
        });
    };
}

- (RTSDBExtra *)onCurrent {
    return RT_EXTRA;
}
// ---
- (void (^)(RTQueueBlock))onDefault {
    return ^(RTQueueBlock block) {
        dispatch_queue_t q = self.defaultQueue;
        if (q == NULL) {
            q = dispatch_get_main_queue();
        }
        self.on(q, ^(RTSDBExtra *dber) {
            block(dber);
        });
    };
}

// -------------
- (void)onClose {
    [self.db close];
}
@end

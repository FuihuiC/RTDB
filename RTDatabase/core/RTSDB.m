//
//  RTSDB.m
//  RTSQLite
//
//  Created by ENUUI on 2018/5/10.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTSDB.h"
#import "RTDBDefault.h"

#define RT_EXTRA [[RTSDBExtra alloc] initWithDBManager:self.dbManager withSem:self->_semaphore withDefaultQueue:self.defaultQueue]
///----------------------------------------------------------
///----------------------------------------------------------
///----------------------------------------------------------
#pragma mark - RTSDBExtra
@interface RTSDBExtra ()
- (RTSDBExtra *(^)(NSString *, va_list *))queryArgs;

- (instancetype)initWithDBManager:(RTDBDefault *)dbManager withSem:(dispatch_semaphore_t)semaphore withDefaultQueue:(dispatch_queue_t)q;

@end

///----------------------------------------------------------
///----------------------------------------------------------
///----------------------------------------------------------
#pragma mark - RTSync
@interface RTSDB () {
    dispatch_semaphore_t _semaphore;
}

@property (nonatomic, strong) RTDBDefault *dbManager;

- (void(^)(rt_block_t))lock;
@end

@implementation RTSDB

- (instancetype)init {
    if (self = [super init]) {
        _semaphore = dispatch_semaphore_create(1);
        _dbManager = [[RTDBDefault alloc] init];
    }
    return self;
}

- (RTSDBExtra *)onMain {
    return RT_EXTRA.onMain;
}

- (RTSDBExtra *(^)(dispatch_queue_t))onQueue {
    return ^RTSDBExtra *(dispatch_queue_t q) {
        if (q == NULL) return self.onMain;
        
        return RT_EXTRA.onQueue(q);
    };
}
// ---
- (void)threadLock:(rt_block_t)block {
    self.lock(block);
}

- (void(^)(rt_block_t))lock {
    return ^(rt_block_t block) {
        if (!block) return;
        
        if (self->_semaphore == NULL) {
            block();
        } else {
            dispatch_semaphore_wait(self->_semaphore, dispatch_time(DISPATCH_TIME_NOW, DISPATCH_TIME_FOREVER));
            block();
            dispatch_semaphore_signal(self->_semaphore);
        }
    };
}

// ---
- (RTSDBExtra *)onDefault {
    if (_defaultQueue == NULL) {
        return RT_EXTRA;
    } else {
        return RT_EXTRA.onQueue(_defaultQueue);
    }
}

- (RTSDBExtra *(^)(NSString *))onOpen {
    return ^(NSString *path) {
        return RT_EXTRA.onOpen(path);
    };
}

- (RTSDBExtra *(^)(NSString *, int))onOpenFlags {
    return ^(NSString *path, int flags) {
        return RT_EXTRA.onOpenFlags(path, flags);
    };
}

// -------------
- (void)onClose {
    [self threadLock:^{
        [self.dbManager close];
    }];
}
@end

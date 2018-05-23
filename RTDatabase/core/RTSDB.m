//
//  RTSDB.m
//  RTSQLite
//
//  Created by ENUUI on 2018/5/10.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTSDB.h"
#import "RTDBDefault.h"



#define RT_EXTRA [[RTSDBExtra alloc] initWithDBManager:self.dbManager withSem:self->_semaphore]
///----------------------------------------------------------
///----------------------------------------------------------
///----------------------------------------------------------
#pragma mark - RTSDBExtra
@interface RTSDBExtra ()
- (RTSDBExtra *(^)(NSString *, va_list *))queryArgs;

- (instancetype)initWithDBManager:(RTDBDefault *)dbManager withSem:(dispatch_semaphore_t)semaphore;

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
    return RT_EXTRA;
}

// Trying to use assertions to control incoming dispatch_queue_t is not empty. But think it's too violent and give up.
- (RTSDBExtra *(^)(dispatch_queue_t))onQueue {
    return ^RTSDBExtra *(dispatch_queue_t q) {
        if (q == NULL) return RT_EXTRA;
        
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
            dispatch_semaphore_wait(self->_semaphore, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
            block();
            dispatch_semaphore_signal(self->_semaphore);
        }
    };
}

// ---
- (RTSDBExtra *)onDefault {
    return RT_EXTRA;
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

- (void)onClose {
    [self threadLock:^{
        [self.dbManager close];
    }];
}

// ---
- (RTSDBExtra *(^)(NSString *, NSDictionary *))execDict {
    return ^RTSDBExtra *(NSString *sql, NSDictionary *params) {
        return RT_EXTRA.execDict(sql, params);
    };
}

- (RTSDBExtra *(^)(NSString *, NSArray *))execArr {
    return ^RTSDBExtra *(NSString *sql, NSArray *arrArgs) {
        return RT_EXTRA.execArr(sql, arrArgs);
    };
}

- (RTSDBExtra *(^)(NSString *, ...))execArgs {
    return ^RTSDBExtra *(NSString *sql, ...) {
        va_list args;
        va_start(args, sql);
        return RT_EXTRA.queryArgs(sql, &args);
    };
}

@end

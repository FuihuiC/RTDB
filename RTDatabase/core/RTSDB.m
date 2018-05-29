//
//  RTSDB.m
//  RTSQLite
//
//  Created by ENUUI on 2018/5/10.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTSDB.h"
#import "RTDBDefault.h"

#define RT_EXTRA [[RTSDBExtra alloc] initWithDBManager:self.dbManager withDefaultQueue:self.defaultQueue]
///----------------------------------------------------------
///----------------------------------------------------------
///----------------------------------------------------------
#pragma mark - RTSDBExtra
@interface RTSDBExtra ()
- (RTSDBExtra *(^)(NSString *, va_list *))queryArgs;

- (instancetype)initWithDBManager:(RTDBDefault *)dbManager  withDefaultQueue:(dispatch_queue_t)q;

@end

///----------------------------------------------------------
///----------------------------------------------------------
///----------------------------------------------------------
#pragma mark - RTSync
@interface RTSDB ()
@property (nonatomic, strong) RTDBDefault *dbManager;

@end

@implementation RTSDB

- (instancetype)init {
    if (self = [super init]) {
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
    [self.dbManager close];
}
@end

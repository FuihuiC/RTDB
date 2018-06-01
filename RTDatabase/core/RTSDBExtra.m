//
//  RTSDBExtra.m
//  RTDatabase
//
//  Created by ENUUI on 2018/5/23.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTSDBExtra.h"

@interface RTSDBExtra () {
    va_list *_args;
    dispatch_queue_t _work_q;
    dispatch_queue_t _defaultQueue;
}
@property (nonatomic, weak) RTDBDefault *dbManager;

@property (nonatomic, copy) NSString *sql;
@property (nonatomic, strong) NSArray *arrArgs;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, strong) NSString *workQueueLabel;
@property (nonatomic, assign) BOOL backMain; // Whether go back main;

@property (nonatomic, strong) RTNext *next;

// ---------------
@property (nonatomic, strong) NSError *err;
@property (nonatomic, assign) BOOL needSync;

@property (nonatomic, assign) BOOL rollback; // Transaction rollback.
@end

@implementation RTSDBExtra

- (instancetype)initWithDBManager:(RTDBDefault *)dbManager withDefaultQueue:(dispatch_queue_t)q {
    if (self = [super init]) {
        self.dbManager = dbManager;
        self->_defaultQueue = q;
        self->_work_q = q;
    }
    return self;
}

- (void)dealloc {
    if (_args != NULL) {
        va_end(*_args);
    }
}

#pragma mark method
// run in the queue last set.
- (RTSDBExtra *(^)(rt_block_t))onWorkQueue {
    return ^RTSDBExtra *(rt_block_t block) {
        
        if (!block) return self;
        
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        [self runOnWorkQueue:^{
            block();
            dispatch_semaphore_signal(sem);
        }];
        dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, DISPATCH_TIME_FOREVER));
        return self;
    };
}

- (void)runOnWorkQueue:(rt_block_t)block {
    if (!block) return;
    
    if (self.backMain) {
        if (![NSThread isMainThread]) {
            dispatch_async(dispatch_get_main_queue(), block);
        } else {
            block();
        }
    } else if (self->_work_q != NULL) {
        dispatch_async(self->_work_q, block);
    } else {
        block();
    }
}

// back to defaultQueue
- (RTSDBExtra *)onDefault {
    
    if (self.err) {
        self.err = nil;
    }
    if (_sql) {
        _sql = nil;
    }
    if (_params) {
        _params = nil;
    }
    if (_args != NULL) {
        va_end(*_args);
    }
    
    if (self->_defaultQueue == NULL) {
        return self;
    } else {
        return self.onQueue(self->_defaultQueue);
    }
}

// change queue.
- (RTSDBExtra *)onMain {
    self.backMain = YES;
    self->_work_q = NULL;
    return self;
}

- (RTSDBExtra *(^)(dispatch_queue_t))onQueue {
    return ^RTSDBExtra *(dispatch_queue_t q) {
        if (q == NULL) return self.onMain;
        self.backMain = NO;
        self->_work_q = q;
        return self;
    };
}

#pragma mark -
// if error, callback.
- (void(^)(rt_error_b_t))onError {
    return ^(rt_error_b_t b) {
        if (!b) return;
        if (!self.err) return;
        b(self.err);
    };
}

//------
- (RTSDBExtra *(^)(void))onDone {
    return ^(void) {
        if (!self.next) {
            return self;
        } else {
            return self.onWorkQueue(^() {
                NSError *err;
                while ([self.next stepWithError:&err]) {}
                self.err = err;
            });
        }
    };
}

- (RTSDBExtra *(^)(rt_next_block_t))onStep {
    return ^(rt_next_block_t b) {
        if (!b) {
            NSError *error;
            rt_error(@"RTSync onStep(): arg block can not be NULL", 109, &error);
            self.err = error;
            return self;
        } else {
            if (!self.next) {
                return self;
            } else return self.onWorkQueue(^(){
                b(self.next);
            });
        }
    };
}

// Map steps, and call back result.
- (RTSDBExtra *(^)(rt_step_block_t))onEnum {
    return ^(rt_step_block_t b) {
        if (!b) {
            NSError *error;
            rt_error(@"RTSync onEnum(): arg block can not be NULL", 109, &error);
            self.err = error;
            return self;
        } else {
            return self.onWorkQueue(^(){
                if (self.next) self.lockOnEnum(b);
            });
        }
    };
}

- (void (^)(rt_step_block_t))lockOnEnum {
    return ^(rt_step_block_t b) {
        __block NSError *error;
        [self.next enumAllSteps:^(NSDictionary *dic, int step, BOOL *stop, NSError *err) {
            error = err;
            if (!err) b(dic, step, stop);
        }];
        
        self.err = error;
    };
}
#pragma mark -

- (RTSDBExtra *(^)(NSString *))onOpen {
    return ^(NSString *path) {
        return self.onOpenFlags(path, RT_SQLITE_OPEN_CREATE | RT_SQLITE_OPEN_READWRITE | RT_SQLITE_OPEN_FULLMUTEX | RT_SQLITE_OPEN_SHAREDCACHE);
    };
}

- (RTSDBExtra *(^)(NSString *, int))onOpenFlags {
    
    return ^(NSString *path, int flags) {
        return self.onWorkQueue(^() {
            [self openDB:path withFlags:flags];
        });
    };
}

- (void)openDB:(NSString *)path withFlags:(int)flags {
    
    NSError *err;
    [self.dbManager openWithPath:path withFlags:flags withError:&err];
    self.err = err;
}

#pragma mark -
- (RTSDBExtra *(^)(NSString *, NSDictionary *))execDict {
    
    return ^(NSString *sql, NSDictionary *params) {
        return self.onWorkQueue(^(void){
            [self execSql:sql withParams:params withArrArgs:nil withArgs:nil];
        });
    };
}

- (RTSDBExtra *(^)(NSString *, NSArray *))execArr {
    return ^(NSString *sql, NSArray *arrArgs) {
        return self.onWorkQueue(^(void){
            [self execSql:sql withParams:nil withArrArgs:arrArgs withArgs:nil];
        });
    };
}

- (RTSDBExtra *(^)(NSString *, ...))execArgs {
    return ^(NSString *sql, ...) {
        __block va_list args;
        va_start(args, sql);
        return self.queryArgs(sql, &args);
    };
}

- (RTSDBExtra *(^)(NSString *, va_list *))queryArgs {
    return ^(NSString *sql, va_list *args) {
        return self.onWorkQueue(^(void) {
            [self execSql:sql withParams:nil withArrArgs:nil withArgs:args];
        });
    };
}

- (void)execSql:(NSString *)sql withParams:(NSDictionary *)params withArrArgs:(NSArray *)arrArgs withArgs:(va_list *)args {
    
    _sql = sql;
    _arrArgs = arrArgs;
    _params = params;
    if (args != NULL) {
        _args = args;
    }
    
    NSError *err = NULL;
    
    RTNext *next = [self.dbManager execSql:sql withErr:&err withParams:params withArrArgs:arrArgs withArgs:(self->_args != NULL) ? *(self->_args) : NULL];
    
    self.next = next;
    if (self->_args != NULL) {
        va_end(*(self->_args));
        self->_args = 0x00;
    }
    
    _err = err;
}

#pragma mark -
- (RTSDBExtra *(^)(Class))onCreat {
    return ^(Class cls) {
        return self.onWorkQueue(^() {
            [self tableCreat:cls];
        });
    };
}

- (void)tableCreat:(Class)cls {
    
    NSError *err;
    [self.dbManager creatTable:cls withError:&err];
    self.err = err;
}

// insert
- (RTSDBExtra *(^)(id obj))onInsert {
    return ^(id obj) {
        return self.onWorkQueue(^() {
            [self insertObj:obj];
        });
    };
}

- (void)insertObj:(id)obj {
    
    NSError *err;
    [self.dbManager insertObj:obj withError:&err];
    self.err = err;
}

// update
- (RTSDBExtra *(^)(id obj))onUpdate {
    return ^(id obj) {
        return self.onWorkQueue(^() {
            [self updateObj:obj];
        });
    };
}

- (void)updateObj:(id)obj {
    
    NSError *err;
    [self.dbManager updateObj:obj withError:&err];
    self.err = err;
}

// delete
- (RTSDBExtra *(^)(id obj))onDelete {
    return ^(id obj) {
        return self.onWorkQueue(^() {
            [self deleteObj:obj];
        });
    };
}

- (void)deleteObj:(id)obj {
    
    NSError *err;
    [self.dbManager deleteObj:obj withError:&err];
    self.err = err;
}

// select
- (RTSDBExtra *(^)(NSString *, rt_select_block_t))onFetchDics {
    return ^(NSString *sql, rt_select_block_t b) {
        if (!b) {
            NSError *error;
            rt_error(@"RTSync onFetchDics(): arg block can not be NULL", 109, &error);
            self.err = error;
            return self;
        } else return self.onWorkQueue(^() {
            b([self selectDics:sql]);
        });
    };
}

- (NSArray <NSDictionary *>*)selectDics:(NSString *)sql {
    
    NSError *err;
    NSArray <NSDictionary *>* results = [self.dbManager fetchSql:sql withError:&err];
    self.err = err;
    
    return results;
}

// select
- (RTSDBExtra *(^)(NSString *, rt_select_block_t))onFetchObjs {
    return ^(NSString *sql, rt_select_block_t b) {
        if (!b) {
            NSError *error;
            rt_error(@"RTSync onFetchObjs(): arg block can not be NULL.", 109, &error);
            self.err = error;
            return self;
        } else return self.onWorkQueue(^() {
            b([self selectObjs:sql]);
        });
    };
}

- (NSArray *)selectObjs:(NSString *)sql {
    
    NSArray <NSDictionary *>* results;
    NSError *err;
    results = [self.dbManager fetchObjSql:sql withError:&err];
    self.err = err;
    return results;
}

#pragma mark -

- (RTSDBExtra *(^)(rt_block_t))transaction {
    return ^(rt_block_t block) {
        
        NSAssert(block != NULL, @"RTDB: - The block while transacting can not be NULL.");
        
        return self.onWorkQueue(^(){
            [self.dbManager begin];
            @try {
                block();
            } @catch (NSException *exception) {
                [self.dbManager rollback];
                NSError *err;
                rt_error(@"Transaction failed!", 110, &err);
                self.err = err;
            }
            [self.dbManager commit];
        });
    };
}

- (RTSDBExtra *(^)(rt_block_t))onTrans {
    return ^(rt_block_t block) {
        return self.onWorkQueue(^{
            @try {
                block();
            } @catch (NSException *exception) {
                NSError *err;
                rt_error(@"Transaction failed!", 110, &err);
                self.err = err;
                self.rollback = YES;
            }
        });
    };
}

- (RTSDBExtra *(^)(void))onBegin {
    return ^{
        return self.onWorkQueue(^{
            self.rollback = NO;
            [self.dbManager begin];
        });
    };
}

- (RTSDBExtra *(^)(void))onCommit {
    return ^{
        if (self.rollback) {
            return self;
        }
        return self.onWorkQueue(^{
            [self.dbManager commit];
        });
    };
}

- (RTSDBExtra *(^)(void))onRollback {
    return ^{
        if (!self.rollback) {
            return self;
        }
        return self.onWorkQueue(^{
            [self.dbManager rollback];
        });
    };
}
@end

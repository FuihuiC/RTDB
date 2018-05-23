//
//  RTSDBExtra.m
//  RTDatabase
//
//  Created by hc-jim on 2018/5/23.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTSDBExtra.h"

@interface RTSDBExtra () {
    va_list *_args;
    dispatch_queue_t _work_q;
    dispatch_semaphore_t _semaphore;
}
@property (nonatomic, strong) RTDBDefault *dbManager;

@property (nonatomic, copy) NSString *sql;
@property (nonatomic, strong) NSArray *arrArgs;
@property (nonatomic, strong) NSDictionary *params;

@property (nonatomic, strong) RTNext *next;
@property (nonatomic, assign) BOOL result;
@property (nonatomic, strong) NSError *err;
@property (nonatomic, assign) BOOL async;
@end

@implementation RTSDBExtra

- (instancetype)initWithDBManager:(RTDBDefault *)dbManager withSem:(dispatch_semaphore_t)semaphore {
    if (self = [super init]) {
        self.dbManager = dbManager;
        self->_semaphore = semaphore;
    }
    return self;
}

- (void)dealloc {
    if (_args != NULL) {
        va_end(*_args);
    }
}

#pragma mark method
- (void)threadLock:(rt_block_t)block {
    if (!block) return;
    
    self.onWorkQueue(^(){
        [self lock:block];
    });
}

// goto synchronize
- (void)lock:(rt_block_t)block {
    if (!block) return;
    
    if (self->_semaphore == NULL) {
        block();
    } else {
        dispatch_semaphore_wait(self->_semaphore, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
        block();
        dispatch_semaphore_signal(self->_semaphore);
    }
}

// run in last set queue.
- (RTSDBExtra *(^)(rt_block_t))onWorkQueue {
    return ^RTSDBExtra *(rt_block_t block) {
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        [self runOnWorkQueue:^{
            block();
            dispatch_semaphore_signal(sem);
        }];
        dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
        return self;
    };
}

- (void)runOnWorkQueue:(rt_block_t)block {
    if (!block) return;
    
    if (_async) {
        if (self->_work_q != NULL) {
            dispatch_async(_work_q, block);
        } else {
            block();
        }
    } else {
        if (![NSThread isMainThread]) {
            dispatch_sync(dispatch_get_main_queue(), block);
        } else {
            block();
        }
    }
}

// change queue.
- (RTSDBExtra *)onMain {
    self.async = NO;
    self->_work_q = dispatch_get_main_queue();
    return self;
}

- (RTSDBExtra *(^)(dispatch_queue_t))onQueue {
    return ^RTSDBExtra *(dispatch_queue_t q) {
        // Trying to use assertions to control incoming dispatch_queue_t is not empty. But think it's too violent and give up.
        if (q == NULL) return self;
        
        self.async = YES;
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
                [self lock:^{
                    NSError *err;
                    while ([self.next stepWithError:&err]) {}
                    self.err = err;
                }];
            });
        }
    };
}

- (RTSDBExtra *(^)(rt_next_block_t))onStep {
    return ^(rt_next_block_t b) {
        if (!b) {
            NSError *error;
            rt_db_err(@"RTSync onStep(): arg block can not be NULL", &error);
            self.err = error;
            return self;
        } else {
            if (!self.next) {
                return self;
            } else return self.onWorkQueue(^(){
                [self lock:^{
                    b(self.next);
                }];
            });
        }
    };
}

// Map steps, and call back result.

- (RTSDBExtra *(^)(rt_step_block_t))onEnum {
    return ^(rt_step_block_t b) {
        if (!b) {
            NSError *error;
            rt_db_err(@"RTSync onEnum(): arg block can not be NULL", &error);
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
        [self lock:^{
            [self.next enumAllSteps:^(NSDictionary *dic, int step, BOOL *stop, NSError *err) {
                error = err;
                if (!err) b(dic, step, stop);
            }];
        }];
        self.err = error;
    };
}
#pragma mark -

- (RTSDBExtra *(^)(NSString *))onOpen {
    return ^(NSString *path) {
        return self.onWorkQueue(^() {
            [self openDB:path withFlags:(RT_SQLITE_OPEN_CREATE | RT_SQLITE_OPEN_READWRITE | RT_SQLITE_OPEN_NOMUTEX | RT_SQLITE_OPEN_SHAREDCACHE)];
        });
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
    [self lock:^{
        NSError *err;
        [self.dbManager openWithPath:path withFlags:flags withError:&err];
        self.err = err;
    }];
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
    __block NSError *err = NULL;
    [self lock:^{
        RTNext *next = [self.dbManager execSql:sql withErr:&err withParams:params withArrArgs:arrArgs withArgs:(self->_args != NULL) ? *(self->_args) : NULL];
        self.next = next;
        if (self->_args != NULL) {
            va_end(*(self->_args));
            self->_args = 0x00;
        }
    }];
    
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
    [self lock:^{
        NSError *err;
        [self.dbManager creatTable:cls withError:&err];
        self.err = err;
    }];
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
    [self lock:^{
        NSError *err;
        [self.dbManager insertObj:obj withError:&err];
        self.err = err;
    }];
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
    [self lock:^{
        NSError *err;
        [self.dbManager updateObj:obj withError:&err];
        self.err = err;
    }];
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
    [self lock:^{
        NSError *err;
        [self.dbManager deleteObj:obj withError:&err];
        self.err = err;
    }];
}

// select
- (RTSDBExtra *(^)(NSString *, rt_select_block_t))onFetchDics {
    return ^(NSString *sql,rt_select_block_t b) {
        if (!b) {
            NSError *error;
            rt_db_err(@"RTSync onEnum(): arg block can not be NULL", &error);
            self.err = error;
            return self;
        } else return self.onWorkQueue(^() {
            b([self selectDics:sql]);
        });
    };
}

- (NSArray <NSDictionary *>*)selectDics:(NSString *)sql {
    __block NSArray <NSDictionary *>* results;
    [self lock:^{
        NSError *err;
        results = [self.dbManager fetchSql:sql withError:&err];
        self.err = err;
    }];
    return results;
}

// select
- (RTSDBExtra *(^)(NSString *, rt_select_block_t))onFetchObjs {
    return ^(NSString *sql,rt_select_block_t b) {
        if (!b) {
            NSError *error;
            rt_db_err(@"RTSync onEnum(): arg block can not be NULL", &error);
            self.err = error;
            return self;
        } else return self.onWorkQueue(^() {
            b([self selectObjs:sql]);
        });
    };
}

- (NSArray *)selectObjs:(NSString *)sql {
    __block NSArray <NSDictionary *>* results;
    [self lock:^{
        NSError *err;
        results = [self.dbManager fetchObjSql:sql withError:&err];
        self.err = err;
    }];
    return results;
}
@end

//
//  RTSync.m
//  RTSQLite
//
//  Created by ENUUI on 2018/5/10.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTSync.h"
#import "RTDBDefault.h"

#define RT_SYNC_TIMEOUT dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC)
#define RT_DEFAULT_FLAGS (RT_SQLITE_OPEN_CREATE | RT_SQLITE_OPEN_READWRITE | RT_SQLITE_OPEN_NOMUTEX | RT_SQLITE_OPEN_SHAREDCACHE)
///----------------------------------------------------------
///----------------------------------------------------------
///----------------------------------------------------------
#pragma mark - RTSyncRun
@interface RTSyncRun () {
    va_list *_args;
    dispatch_queue_t _work_q;
}
@property (nonatomic, copy) NSString *sql;
@property (nonatomic, strong) NSArray *arrArgs;
@property (nonatomic, strong) NSDictionary *params;

@property (nonatomic, strong) RTNext *next;
@property (nonatomic, assign) BOOL result;
@property (nonatomic, strong) NSError *err;
@property (nonatomic, assign) BOOL async;

- (instancetype)initWithPath:(NSString *)path withFlags:(int)flags;
- (instancetype)initWithQueue:(dispatch_queue_t )q;
- (instancetype)initWithSql:(NSString *)sql withArrArgs:(NSArray *)arrArgs withParams:(NSDictionary *)params withArgs:(va_list *)args;
@end

///----------------------------------------------------------
///----------------------------------------------------------
///----------------------------------------------------------
#pragma mark - RTSync
@interface RTSync () {
@public
    dispatch_semaphore_t _semaphore;
}
- (void(^)(rt_block_t))lock;
@end

@implementation RTSync

- (instancetype)init {
    if (self = [super init]) {
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (RTSyncRun *)onMain {
    return [[RTSyncRun alloc] init];
}

// Trying to use assertions to control incoming dispatch_queue_t is not empty. But think it's too violent and give up.
- (RTSyncRun *(^)(dispatch_queue_t))onQueue {
    return ^RTSyncRun *(dispatch_queue_t q) {
        if (q == NULL) return [[RTSyncRun alloc] init];
        return [[RTSyncRun alloc] initWithQueue:q];
    };
}
// ---
- (void)threadLock:(rt_block_t)block {
    self.lock(block);
}

- (void(^)(rt_block_t))lock {
    return ^(rt_block_t block) {
        if (self->_semaphore == NULL) {
            block();
        } else {
            dispatch_semaphore_wait(self->_semaphore, RT_SYNC_TIMEOUT);
            block();
            dispatch_semaphore_signal(self->_semaphore);
        }
    };
}

// ---
- (RTSyncRun *)onDefault {
    return [[RTSyncRun alloc] init];
}


- (RTSyncRun *(^)(NSString *))onOpen {
    return ^(NSString *path) {
        return [[RTSyncRun alloc] initWithPath:path withFlags:RT_DEFAULT_FLAGS];
    };
}

- (RTSyncRun *(^)(NSString *, int))onOpenFlags {
    return ^(NSString *path, int flags) {
        return [[RTSyncRun alloc] initWithPath:path withFlags:flags];
    };
}

- (void)onClose {
    [self threadLock:^{
        [[RTDB sharedInstance] close];
    }];
}

// ---
- (RTSyncRun *(^)(NSString *, NSDictionary *))execDict {
    return ^RTSyncRun *(NSString *sql, NSDictionary *params) {
        return [[RTSyncRun alloc] initWithSql:sql withArrArgs:nil withParams:params withArgs:NULL];
    };
}

- (RTSyncRun *(^)(NSString *, NSArray *))execArr {
    return ^RTSyncRun *(NSString *sql, NSArray *arrArgs) {
        return [[RTSyncRun alloc] initWithSql:sql withArrArgs:arrArgs withParams:nil withArgs:NULL];
    };
}

- (RTSyncRun *(^)(NSString *, ...))execArgs {
    return ^RTSyncRun *(NSString *sql, ...) {
        va_list args;
        va_start(args, sql);
        return [[RTSyncRun alloc] initWithSql:sql withArrArgs:nil withParams:nil withArgs:&args];
    };
}

@end

///----------------------------------------------------------
///----------------------------------------------------------
///----------------------------------------------------------
#pragma mark - RTSyncRun
@implementation RTSyncRun

- (instancetype)initWithQueue:(dispatch_queue_t )q {
    if (self = [super init]) {
        if (q != NULL) {
            _work_q = q;
            _async = YES;
        }
    }
    return self;
}

- (instancetype)initWithPath:(NSString *)path withFlags:(int)flags {
    if (self = [super init]) {
        [self openDB:path withFlags:flags];
    }
    return self;
}

- (instancetype)initWithSql:(NSString *)sql withArrArgs:(NSArray *)arrArgs withParams:(NSDictionary *)params withArgs:(va_list *)args {
    if (self = [super init]) {
        [self execSql:sql withParams:params withArrArgs:arrArgs withArgs:args];
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
    [RTDB sharedInstance].onSync.lock(block);
}

// run in last set queue.
- (RTSyncRun *(^)(rt_block_t))onWorkQueue {
    return ^RTSyncRun *(rt_block_t block) {
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        [self runOnWorkQueue:^{
            block();
            dispatch_semaphore_signal(sem);
        }];
        dispatch_semaphore_wait(sem, RT_SYNC_TIMEOUT);
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
- (RTSyncRun *)onMain {
    self.async = NO;
    self->_work_q = dispatch_get_main_queue();
    return self;
}

- (RTSyncRun *(^)(dispatch_queue_t))onQueue {
    return ^RTSyncRun *(dispatch_queue_t q) {
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
- (RTSyncRun *(^)(void))onDone {
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

- (RTSyncRun *(^)(rt_next_block_t))onStep {
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

- (RTSyncRun *(^)(rt_step_block_t))onEnum {
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

- (RTSyncRun *(^)(NSString *))onOpen {
    return ^(NSString *path) {
        return self.onWorkQueue(^() {
            [self openDB:path withFlags:RT_DEFAULT_FLAGS];
        });
    };
}

- (RTSyncRun *(^)(NSString *, int))onOpenFlags {
    return ^(NSString *path, int flags) {
        return self.onWorkQueue(^() {
            [self openDB:path withFlags:flags];
        });
    };
}

- (void)openDB:(NSString *)path withFlags:(int)flags {
    [self lock:^{
        NSError *err;
        [[RTDB sharedInstance] openWithPath:path withFlags:flags withError:&err];
        self.err = err;
    }];
}

#pragma mark -
- (RTSyncRun *(^)(NSString *, NSDictionary *))execDict {
    
    return ^(NSString *sql, NSDictionary *params) {
        return self.onWorkQueue(^(void){
            [self execSql:sql withParams:params withArrArgs:nil withArgs:nil];
        });
    };
}

- (RTSyncRun *(^)(NSString *, NSArray *))execArr {
    return ^(NSString *sql, NSArray *arrArgs) {
        return self.onWorkQueue(^(void){
            [self execSql:sql withParams:nil withArrArgs:arrArgs withArgs:nil];
        });
    };
}

- (RTSyncRun *(^)(NSString *, ...))execArgs {
    return ^(NSString *sql, ...) {
        __block va_list args;
        va_start(args, sql);
        self->_args = &args;
        return self.onWorkQueue(^(void) {
            [self execSql:sql withParams:nil withArrArgs:nil withArgs:nil];
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
        RTNext *next = [[RTDB sharedInstance] execSql:sql withErr:&err withParams:params withArrArgs:arrArgs withArgs:(self->_args != NULL) ? *(self->_args) : NULL];
        self.next = next;
        if (self->_args != NULL) {
            va_end(*(self->_args));
            self->_args = 0x00;
        }
    }];
    
    _err = err;
}

#pragma mark -
- (RTSyncRun *(^)(Class))onCreat {
    return ^(Class cls) {
        return self.onWorkQueue(^() {
            [self tableCreat:cls];
        });
    };
}
- (void)tableCreat:(Class)cls {
    [self lock:^{
        NSError *err;
        [[RTDBDefault sharedInstance] creatTable:cls withError:&err];
        self.err = err;
    }];
}

// insert
- (RTSyncRun *(^)(id obj))onInsert {
    return ^(id obj) {
        return self.onWorkQueue(^() {
            [self insertObj:obj];
        });
    };
}

- (void)insertObj:(id)obj {
    [self lock:^{
        NSError *err;
        [[RTDBDefault sharedInstance] insertObj:obj withError:&err];
        self.err = err;
    }];
}

// update
- (RTSyncRun *(^)(id obj))onUpdate {
    return ^(id obj) {
        return self.onWorkQueue(^() {
            [self updateObj:obj];
        });
    };
}

- (void)updateObj:(id)obj {
    [self lock:^{
        NSError *err;
        [[RTDBDefault sharedInstance] updateObj:obj withError:&err];
        self.err = err;
    }];
}

// delete
- (RTSyncRun *(^)(id obj))onDelete {
    return ^(id obj) {
        return self.onWorkQueue(^() {
            [self deleteObj:obj];
        });
    };
}

- (void)deleteObj:(id)obj {
    [self lock:^{
        NSError *err;
        [[RTDBDefault sharedInstance] deleteObj:obj withError:&err];
        self.err = err;
    }];
}

// select
- (RTSyncRun *(^)(NSString *, rt_select_block_t))onFetchDics {
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
        results = [[RTDBDefault sharedInstance] fetchSql:sql withError:&err];
        self.err = err;
    }];
    return results;
}

// select
- (RTSyncRun *(^)(NSString *, rt_select_block_t))onFetchObjs {
    return ^(NSString *sql,rt_select_block_t b) {
        if (!b) {
            NSError *error;
            rt_db_err(@"RTSync onEnum(): arg block can not be NULL", &error);
            self.err = error;
            return self;
        } else return self.onWorkQueue(^() {
            
        });
    };
}

- (NSArray <NSDictionary *>*)selectObjs:(NSString *)sql {
    __block NSArray <NSDictionary *>* results;
    [self lock:^{
        NSError *err;
        results = [[RTDBDefault sharedInstance] fetchObjSql:sql withError:&err];
        self.err = err;
    }];
    return results;
}
@end

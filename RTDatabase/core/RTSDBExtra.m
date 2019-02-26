//
//  RTSDBExtra.m
//  RTDatabase
//
//  Created by ENUUI on 2018/5/23.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTSDBExtra.h"

typedef void(^rt_block_t)(void);

@interface RTSDBExtra () {
    va_list *_args;
//    dispatch_queue_t _defaultQueue;
}

@property (nonatomic, assign) BOOL isObjcMode;

@property (nonatomic, weak) RTDBDefault *dbManager;

@property (nonatomic, copy) NSString *sql;
@property (nonatomic, strong) NSArray *arrArgs;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, assign) BOOL backMain; // Whether go back main;

@property (nonatomic, strong) RTNext *next;
// ---------------
@property (nonatomic, strong) NSError *err;
@property (nonatomic, assign) BOOL rollback; // Transaction rollback.
@property (nonatomic, strong) NSArray *arrResult; // last time select result array.

- (RTSDBExtra *(^)(rt_block_t))onRun;
@end

@implementation RTSDBExtra

- (instancetype)initWithDBManager:(RTDBDefault *)dbManager{
    if (self = [super init]) {
        self.dbManager = dbManager;
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
- (RTSDBExtra *(^)(rt_block_t))onRun {
  
    return ^RTSDBExtra *(rt_block_t block) {
        if (self.err) return self;
        return [self run:block];
    };
}

- (RTSDBExtra *)run:(rt_block_t)block {
    if (!block) return self;
    
    if ([NSThread isMainThread] || !self.backMain) {
        block();
        return self;
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_main_queue(), ^{
        block();
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return self;
}
// change queue.
- (RTSDBExtra *)onMain {
    self.backMain = YES;
    return self;
}


#pragma mark -
// if error, callback.
- (void(^)(rt_error_b_t))onError {
    return ^(rt_error_b_t b) {
        if (!b) return;
        if (!self.err) return;
        [self run:^{
            b(self.err);
        }];
    };
}

- (void)onEnd {
    self.next = nil;
    self.err = nil;
    self.dbManager = nil;
}

- (RTSDBExtra *)reset {
    self.rollback = NO;
    self.backMain = NO;
    self.isObjcMode = NO;
    
    self.arrResult = nil;
    self.arrArgs = nil;
    self.params = nil;
    if (_args != NULL) {
        va_end(*_args);
        _args = 0x0;
    }
    
    self.next = nil;
    
    self.err = nil;
    return self;
}
//------
- (RTSDBExtra *)onDone {
    
    if (!self.next) {
        return self;
    } else {
        return self.onRun(^() {
            NSError *err;
            while ([self.next stepWithError:&err]) {}
            self.err = err;
        });
    }
}

- (RTSDBExtra *(^)(rt_next_block_t))onStep {
    return ^(rt_next_block_t b) {
        if (!b) {
            return [self extraError:@"RTSDBExtra onStep(): arg block can not be NULL" withCode:109];
        } else {
            if (!self.next) {
                return self;
            } else return self.onRun(^(){
                b(self.next);
            });
        }
    };
}

// Map steps, and call back result.
- (RTSDBExtra *(^)(rt_step_block_t))onEnum {
    return ^(rt_step_block_t b) {
        if (!b) {
            return [self extraError:@"RTSync onEnum(): arg block can not be NULL" withCode:109];
        } else {
            return self.onRun(^(){
                if (self.next) self.lockOnEnum(b);
            });
        }
    };
}

- (void (^)(rt_step_block_t))lockOnEnum {
    return ^(rt_step_block_t b) {
        __block NSError *error;
        [self.next enumRows:^(NSDictionary * _Nullable rowDict, int row, BOOL * _Nullable stop, NSError * _Nullable error) {
            if (!error) b(rowDict, row, stop);
        }];
        
        self.err = error;
    };
}
#pragma mark -

//- (RTSDBExtra *(^)(NSString *))onOpen {
//    return ^(NSString *path) {
//        return self.onOpenFlags(path, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | RT_SQLITE_OPEN_FULLMUTEX | RT_SQLITE_OPEN_SHAREDCACHE);
//    };
//}

- (RTSDBExtra *(^)(NSString *, int))onOpenFlags {
    
    return ^(NSString *path, int flags) {
        return self.onRun(^() {
            [self openDB:path withFlags:flags];
        });
    };
}

- (void)openDB:(NSString *)path withFlags:(int)flags {
    
    NSError *err;
    [self.dbManager.dbHandler openWithPath:path withFlags:flags withError:&err];
    self.err = err;
}

#pragma mark -
- (RTSDBExtra *(^)(NSString *, NSDictionary *))execDict {
    
    return ^(NSString *sql, NSDictionary *params) {
        return self.onRun(^(void){
            [self execSql:sql withParams:params withArrArgs:nil withArgs:nil];
        });
    };
}

- (RTSDBExtra *(^)(NSString *, NSArray *))execArr {
    return ^(NSString *sql, NSArray *arrArgs) {
        return self.onRun(^(void){
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
        return self.onRun(^(void) {
            [self execSql:sql withParams:nil withArrArgs:nil withArgs:args];
        });
    };
}

- (void)execSql:(NSString *)sql withParams:(NSDictionary *)params withArrArgs:(NSArray *)arrArgs withArgs:(va_list *)args {
    _isObjcMode = NO;
    _sql = sql;
    _arrArgs = arrArgs;
    _params = params;
    if (args != NULL) {
        _args = args;
    }
    
    NSError *err = NULL;
    RTNext *next = [self.dbManager.dbHandler execSQL:sql withDicValues:params withArrValues:arrArgs withListValues:(self->_args != NULL) ? *(self->_args) : NULL withError:&err];
    
    self.next = next;
    if (self->_args != NULL) {
        va_end(*(self->_args));
        self->_args = 0x00;
    }
    
    _err = err;
}

#pragma mark -
- (RTSDBExtra *(^)(Class))onCreate {
    return ^(Class cls) {
        return self.onRun(^() {
            [self tableCreat:cls];
        });
    };
}

- (void)tableCreat:(Class)cls {
    
    NSError *err;
    [self.dbManager createTable:cls withError:&err];
    self.err = err;
}

// insert
- (RTSDBExtra *(^)(id obj))onInsert {
    return ^(id obj) {
        return self.onRun(^() {
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
        return self.onRun(^() {
            [self updateObj:obj];
        });
    };
}

- (RTSDBExtra *(^)(id, NSDictionary *))onUpdateWithParams {
    return ^(id obj, NSDictionary *params) {
        return self.onRun(^() {
            [self updateObj:obj withParams:params];
        });
    };
}

- (void)updateObj:(id)obj {
    
    NSError *err;
    [self.dbManager updateObj:obj withError:&err];
    self.err = err;
}

- (void)updateObj:(id)obj withParams:(NSDictionary<NSString *,id> *)params {
    
    NSError *err;
    [self.dbManager updateObj:obj withPropertyDict:params withError:&err];
    self.err = err;
}
// delete
- (RTSDBExtra *(^)(id obj))onDelete {
    return ^(id obj) {
        return self.onRun(^() {
            [self deleteObj:obj];
        });
    };
}

- (void)deleteObj:(id)obj {
    
    NSError *err;
    [self.dbManager deleteObj:obj withError:&err];
    self.err = err;
}

- (NSArray <NSDictionary *>*)selectDics:(NSString *)sql {
    
    NSError *err;
    NSArray <NSDictionary *>* results = [self.dbManager fetchSQL:sql withError:&err];

    self.err = err;
    
    return results;
}

- (RTSDBExtra *(^)(NSString *))onFetch {
    return ^(NSString *sql) {
        if (!sql || sql.length == 0) {
            return [self extraError:@"sql recieved by onFetch is empty!" withCode:109];
        } else return self.onRun(^(){
            self.arrResult = [self selectObjs:sql];
        });
    };
}

- (RTSDBExtra *(^)(rt_select_block_t))onResult {
    return ^(rt_select_block_t block) {
        if (!block) {
            return self;
        }

        return self.onRun(^() {
            if (self.isObjcMode) {
                block(self.arrResult);
            } else {
                
                if (!self.next) return;
                
                NSMutableArray *mArrResult = [NSMutableArray array];
                [self.next enumRows:^(NSDictionary * _Nullable rowDict, int row, BOOL * _Nullable stop, NSError * _Nullable error) {
                    if (rowDict) {
                        [mArrResult addObject:rowDict];
                    }
                }];
               
                if (mArrResult.count > 0) {
                    self.arrResult = mArrResult.copy;
                }
                block(self.arrResult);
            }
        });
    };
}

- (RTSDBExtra *)extraError:(NSString *)msg withCode:(int)code {
    NSError *error;
    rt_error(msg, code, &error);
    self.err = error;
    return self;
}

// select
- (RTSDBExtra *(^)(NSString *, rt_select_block_t))onFetchObjs {
    return ^(NSString *sql, rt_select_block_t b) {
        if (!b) {
            return [self extraError:@"RTSDBExtra onFetchObjs(): arg block can not be NULL." withCode:109];
        } else return self.onRun(^() {
            NSArray *result = [self selectObjs:sql];
            if (result) {
                b(result);
            }
        });
    };
}

- (NSArray *)selectObjs:(NSString *)sql {
    
    NSArray <NSDictionary *>* results;
    NSError *err;
    _isObjcMode = YES;
    results = [self.dbManager fetchSQL:sql withError:&err];
    
    self.err = err;
    return results;
}

#pragma mark -

- (RTSDBExtra *(^)(rt_block_t))transaction {
    return ^(rt_block_t block) {
        
        NSAssert(block != NULL, @"RTDB: - The block while transacting can not be NULL.");
        
        return self.onRun(^(){
            [self.dbManager.dbHandler execWithQuery:@"BEGIN"];
            @try {
                block();
            } @catch (NSException *exception) {
                [self.dbManager.dbHandler execWithQuery:@"ROLLBACK"];
                [self extraError:@"Transaction failed!" withCode:110];
            }
            [self.dbManager.dbHandler execWithQuery:@"COMMIT"];
        });
    };
}

- (RTSDBExtra *(^)(rt_block_t))onTrans {
    return ^(rt_block_t block) {
        return self.onRun(^{
            @try {
                block();
            } @catch (NSException *exception) {
                [self extraError:@"Transaction failed!" withCode:110];
                self.rollback = YES;
            }
        });
    };
}

- (RTSDBExtra *)onBegin {
    return self.onRun(^{
        self.rollback = NO;
        [self.dbManager.dbHandler execWithQuery:@"BEGIN"];
    });
}

- (RTSDBExtra *)onCommit {
    if (self.rollback) {
        return self;
    }
    return self.onRun(^{
        [self.dbManager.dbHandler execWithQuery:@"COMMIT"];
    });
}

- (RTSDBExtra *)onRollback {
    if (!self.rollback) {
        return self;
    }
    return self.onRun(^{
        [self.dbManager.dbHandler execWithQuery:@"ROLLBACK"];
    });
}
@end

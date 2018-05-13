<p align="center" >
<img src="RTDB-logo.png" title="RTDB logo" float=left>
</p>

## Installing

#### Installation with CocoaPods
```
pod 'RTDatabase'
```
#### Installation by cloning the repository


## How To Use
* RTDB
```
// Open DB
NSError *err;
[[RTDB sharedInstance] openWithPath:@"~/RTDB.sqlite3" withError:&err];

// creat table
[[RTDB sharedInstance] 
execQuery:@"CREATE TABLE if not exists 'DB' \
('name' 'TEXT', 'data' 'BLOB', 'n' 'REAL', 'date' 'REAL', \
'f' 'REAL', 'd' 'REAL', 'c' 'INTEGER', 'uc' 'INTEGER')", nil];

// insert
/**
 * sql like
 * @"INSERT INTO DB (name, data, n, date, f, d, c, uc) \
 * VALUES (:name, :data, :n, :date, :f, :d, :c, :uc)"
 * is supported better.
 */  
 
[[RTDB sharedInstance] execQuery:
@"INSERT INTO DB (name, data, n, date, f, d, c, uc) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
@"_name",
[@"test" dataUsingEncoding:NSUTF8StringEncoding],
[NSDate date],
[NSNumber numberWithDouble:123.213124324],
@(1.2),
@(1.2123124),
@(-'c'),
@('c'),
nil];

// select
RTNext *next = [[RTDB sharedInstance] execSql:@"SELECT * FROM DB", nil];

[next enumAllSteps:^(NSDictionary *dic, int step, BOOL *stop, NSError *err) {
if (!err) {
NSLog(@"%@", dic);
} else {
// err handle.
}
}];

BOOL step = [next step]; // When sqlite3_step() == SQLITE_ROW, return YES.
```
* RTDBDefault
```
// creat table for model class. 

NSError *err;
[[RTDBDefault sharedInstance] creatTable:[DB class] withError:&err];

/**
* @interface DB : NSObject
* // _id is needed for primary key
* @property (nonatomic, assign) NSInteger _id;
* @end
*/
DB *obj = [[DB alloc] init];
// insert
[[RTDBDefault sharedInstance] insertObj:obj withError:&err];
// update
[[RTDBDefault sharedInstance] updateObj:obj withError:&err];
// delete
[[RTDBDefault sharedInstance] deleteObj:obj withError:&err];

NSArray <DB *>*arr = [[RTDBDefault sharedInstance] 
                     fetchObjSql:@"SELECT * FROM DB order by _id" withError:&err];

NSArray <NSDictionary *>*arr = [[RTDBDefault sharedInstance] 
                     fetchSql:@"SELECT * FROM DB order by _id" withError:&err];
```

* [RTDB sharedInstance].onSync or [RTDBDefault sharedInstance].onSync

While using .onSync, [RTDB sharedInstance] or [RTDBDefault sharedInstance] 
it doesn't matter to select which one.
```
// open database
[RTDB sharedInstance]
.onSync
.onOpen(@"~/RTDB.sqlite3")
.onError(^(NSError *err) {
NSLog(@"%@", err);
});

// creat table
[RTDB sharedInstance]
.onSync
.execArgs(@"CREATE TABLE if not exists 'DB' \
('name' 'TEXT', 'data' 'BLOB', 'n' 'REAL', 'date' 'REAL', 'f' \
'REAL', 'd' 'REAL', 'c' 'INTEGER', 'uc' 'INTEGER')", nil)
.onDone()
.onError(^(NSError *err) {
NSLog(@"%@", err);
});

// insert
[RTDB sharedInstance]
.onSync
.execArgs(
@"INSERT INTO DB (name, data, n, date, f, d, c, uc) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
@"name",
[@"name" dataUsingEncoding:NSUTF8StringEncoding],
@(1),
[NSDate date],
@(1.412),
@(0.31231),
@(-'e'),
@('e'),
nil)
.onDone()
.onError(^(NSError *err) {
NSLog(@"%@", err);
});
// select
[RTDB sharedInstance]
.onSync
.onQueue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
.execArgs(@"SELECT * FROM DB", nil)
// .onQueue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
.onEnum(^(NSDictionary *dic, int step, BOOL *stop){
NSLog(@"%@", dic);
NSLog(@"%d", step);
NSLog(@"%@", [NSThread currentThread]);
})
.onError(^(NSError *err) {
NSLog(@"%@", err);
});


/**
* @interface DB : NSObject
*
* @property (nonatomic, assign) NSInteger _id; // _id is needed for primary key
* @end
*/
DB *obj = [[DB alloc] init];
// insert 
[RTDB sharedInstance]
.onSync
.onDefault
.onInsert(obj)
.onError(^(NSError *err) {
NSLog(@"%@", err);
});  

// update
[RTDB sharedInstance]
.onSync
.onQueue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
.onUpdate(obj)
.onError(^(NSError *err) {
NSLog(@"%@", err);
});

// delete
[RTDB sharedInstance]
.onSync
.onDefault
.onDelete(obj)
.onError(^(NSError *err) {
NSLog(@"%@", err);
});

// select    
[RTDBDefault sharedInstance]
.onSync
.onDefault
.onFetchDics(@"SELECT * FROM DB order by _id", ^(NSArray <NSDictionary *>* result) {
for (NSDictionary *dic in result) {
NSLog(@"%@", dic);
}
})
.onError(^(NSError *err) {
NSLog(@"%@", err);
});
[RTDBDefault sharedInstance]
.onSync
.onDefault
.onFetchObjs(@"", ^(NSArray <DB *>*result) {
for (DB *obj in result) {
NSLog(@"%@", obj);
}
})
.onError(^(NSError *err) {
NSLog(@"%@", err);
});

[RTDB sharedInstance]
.onSync
.execArgs(@"SELECT * FROM DB")
.onStep(^(RTNext *next) {
int count = [next columnCountOfRow];
while ([next step]) {
for (int i = 0; i < count; i++) {
NSString *name = [next nameForColumn:i];
id value = [next valueForColumn:i];
NSLog(@"name: %@, value = %@", name, value);
}
}
})
.onError(^(NSError *err) {
NSLog(@"%@", err)
});
```
## Thread safe
- While using RTDB or RTDBDefault without .onSync, thread is not safe.  
- Methods of RTSync or RTSyncRun operate db are thread safe.  
- RTSync use dispatch_semaphore_t to control concurrency.  
See more
* [dispatch_semaphore_create](https://developer.apple.com/documentation/dispatch/1452955-dispatch_semaphore_create?language=objc)
* [dispatch_semaphore_wait](https://developer.apple.com/documentation/dispatch/1452919-dispatch_semaphore_signal?language=objc)
* [dispatch_semaphore_signal](https://developer.apple.com/documentation/dispatch/1452919-dispatch_semaphore_signal?language=occ)

## Author

- [ENUUI](https://github.com/FuihuiC)

## Licenses

All source code is licensed under the [MIT License](https://raw.github.com/rs/SDWebImage/master/LICENSE).

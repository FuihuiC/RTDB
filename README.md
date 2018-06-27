<p align="center" >
<img src="RTDB-logo.png" title="RTDB logo" float=left>
</p>



## SQLite
RTDB is build on top of SQLite.  
See more:  
[SQLite Home](http://sqlite.org/index.html)  
[SQLite Documentation](http://www.sqlite.org/docs.html)

## Installing

#### Installation with CocoaPods
```
platform :ios, '8.2'

pod 'RTDatabase'
```
#### Installation by cloning the repository

## How To Use
* RTDB


#### RTDB requires ARC.

Open sqlite3 using the flags by default:
###### SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_SHAREDCACHE   
or you can customize the flags.

- OPEN 

Before using RTDB, it must be opened.
```
// init a RTDB instance.
RTDB *db = [[RTDB alloc] init];  

// Open DB
NSError *err;
BOOL result = [db openWithPath:@"~/RTDB.sqlite3" withError:&err];
if (!result) {
NSLog(@"%@". err);
}
```  
- EXECUTE 

If sql string do not have a `SELECT`, you may call methods begin with `execQuery` which return a value type of BOOL.  
These methods are actually wrapper around `sqlite3_prepare_v2()`, `sqlite3_step()`, and `sqlite3_finalize()`.
```
// creat table
[db execQuery:@"CREATE TABLE if not exists 'DB' \
('name' 'TEXT', 'data' 'BLOB', 'n' 'REAL', 'date' 'REAL', \
'f' 'REAL', 'd' 'REAL', 'c' 'INTEGER', 'uc' 'INTEGER')", nil];

// insert
/**
* sql like
* @"INSERT INTO DB (name, data, n, date, f, d, c, uc) \
* VALUES (:name, :data, :n, :date, :f, :d, :c, :uc)"
* is supported better.
*/  

[db execQuery:
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
```
Methods begin with `execSql` return an object of RTNext. If sql string has a 'SELECT', call these motheds.  
The object type of RTNext can call `step` to see if there is any next step. Or use `enumAllSteps` `enumAllColumns` to enumerate every step's values.  

```

// select
RTNext *next = [db execSql:@"SELECT * FROM DB", nil];

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

RTDBDefault inherits RTDB, so all RTDB's methods are enabled while using RTDBDefault.  
RTDBDefault can create a table by class automaticly, and convert per row selected from table to an object Type of the class, which has the same name of the table. It is important to note that the class need have a property named "_id" and type of integer.  `_id` is set as primary key;
```
// init a RTDBDefault instance.
RTDBDefault *defaultDB = [[RTDBDefault alloc] init];
```  

```
// creat table for model class. 
NSError *err;
[defaultDB creatTable:[DB class] withError:&err];

/**
* @interface DB : NSObject
* // _id is needed for primary key
* @property (nonatomic, assign) NSInteger _id;
* @end
*/
DB *obj = [[DB alloc] init];
// insert
[defaultDB insertObj:obj withError:&err];
// update
[defaultDB updateObj:obj withError:&err];
// delete
[defaultDB deleteObj:obj withError:&err];

NSArray <DB *>*arr = [defaultDB 
fetchObjSql:@"SELECT * FROM DB order by _id" withError:&err];

NSArray <NSDictionary *>*arr = [defaultDB 
fetchSql:@"SELECT * FROM DB order by _id" withError:&err];
```

* RTSDB & RTSDBExtra  

RTSDB & RTSDBExtra provide a chainable way of using RTDB & RTDBDefault.  
When calling RTSDB instance's method, it will return a new RTSDBExtra instance. RTSDBExtra's instance methods are chainable.  

```
// init a RTSDB instance.
RTSDB *db = [[RTSDB alloc] init];

// open database
db.onDefault
.onOpen(@"~/RTDB.sqlite3")
.onError(^(NSError *err) {
    NSLog(@"%@", err);
});

// creat table
db.onDefault
.execArgs(@"CREATE TABLE if not exists 'DB' \
('name' 'TEXT', 'data' 'BLOB', 'n' 'REAL', 'date' 'REAL', 'f' \
'REAL', 'd' 'REAL', 'c' 'INTEGER', 'uc' 'INTEGER')", nil)
.onDone()
.onError(^(NSError *err) {
    NSLog(@"%@", err);
});

// insert
db.onDefault
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
db.onDefault
.execArgs(@"SELECT * FROM DB", nil) 0))
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
db.onDefault
.onInsert(obj)
.onError(^(NSError *err) {
    NSLog(@"%@", err);
});  

// update
db.onDefault
.onUpdate(obj)
.onError(^(NSError *err) {
    NSLog(@"%@", err);
});

// delete
db.onDefault
.onDelete(obj)
.onError(^(NSError *err) {
    NSLog(@"%@", err);
});

// select    
db.onDefault
.onFetchDics(@"SELECT * FROM DB order by _id", ^(NSArray <NSDictionary *>* result) {
for (NSDictionary *dic in result) {
    NSLog(@"%@", dic);
}
})
.onError(^(NSError *err) {
    NSLog(@"%@", err);
});

//
db.onDefault
.onFetchObjs(@"", ^(NSArray <DB *>*result) {
    for (DB *obj in result) {
       NSLog(@"%@", obj);
    }
})
.onError(^(NSError *err) {
    NSLog(@"%@", err);
});

db.onDefault
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

* Asynchronous  

RTSDB & RTSDBExtra provide an asynchronous scheme.  
If set the RTSDB instance's `defaultQueue` typed of `dispatch_queue_t`, and then all operation will be called on this queue.  
And you can call `onQueue()` or `onMain` change the queue next. The `onQueue()` and `onMain` will not change the defaultQueue.
Calling `onDefault` will change back defaultQueue.


## Author

- [ENUUI](https://github.com/FuihuiC)

## Licenses

All source code is licensed under the [MIT License](https://raw.github.com/rs/SDWebImage/master/LICENSE).

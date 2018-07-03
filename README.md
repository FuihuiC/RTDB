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
When calling RTSDB instance's method, it will return a new RTSDBExtra instance. RTSDBExtra's instance methods are chainable. You can use point syntax to call each method. 

```
// init a RTSDB instance.
RTSDB *db = [[RTSDB alloc] init];

db.onDefault
.onOpen(@"~/RTDB.sqlite3")
.onError(^(NSError *err) {
    NSLog(@"%@", err);
});
```
In RTSDBExtra, an asynchronous execution scheme is provided.After the `onMain` is invoked, the operation will be executed on the main queue.After the `onQueue` is invoked, the operation will be executed on the specified queue.  
If the default queue is set, the operation after the `onDefault` is invoked will be executed on the default queue. Otherwise, it is executed on the main queue.The queues can be switched on many times during the call process.
> `onQueue` will not change the default queue.
```
// select
db.onDefault
.execArgs(@"SELECT * FROM DB", nil) 0))
.onQueue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
.onEnum(^(NSDictionary *dic, int step, BOOL *stop){
    // Called in a subqueue
    NSLog(@"%@", dic);
    NSLog(@"%d", step);
    NSLog(@"%@", [NSThread currentThread]);
})
.onError(^(NSError *err) {
    NSLog(@"%@", err);
});
```
* Prepare SQL

RTDB provides a quick solution for building SQL strings.Concretely implemented in classes beginning with PP.  
All classes starting with PP comply with the protocol PPSQLProtocol.The protocol has two methods(build, add) and a property(mStrResult) which are @repuired, and several optional methods.  
The required property named mStrResult is the container of sql string. 

PPSQL provides several entry methods for creating SQL for SQLite common operations.   
1. If you need to add column to the SQL string, call the `subs`  method after calling the corresponding entry method.  
The method `subs` will callback an object followed the protocol PPSQLProtocol. Look at the `PPSubSQL.h` file in detail.
```
e.g.
/**
* To create tables, 
* you need to tell SQLite all columns and every column's database type.
*/
PPSQL *pp = [[PPSQL alloc] init];
NSString *sql = pp.CREATE(@"Person").subs(^(id<PPSQLProtocol> sub) {
sub.INTEGER(@"_id").primaryKey.autoincrement.notNull
    .TEXT(@"name")
    .INTEGER(@"age")
    .REAL(@"height")
    .BLOB(@"info");
}).build;

NSLog(@"%@", sql);

Print Result:
-> CREATE TABLE if not exists 'Person'
('_id' 'INTEGER' primary key autoincrement NOT NULL,
'name' 'TEXT', 'age' 'INTEGER', 'height' 'REAL', 'info' 'BLOB')
```  
2. If you want to add qualifying conditions in the SQL string, call the method (`terms`).  
The method terms will callback an object typed of `PPTerm`.`PPTerm` contains many SQLite SQL clauses. Please select them according to requirements.
```
e.g.
sql = pp.UPDATE(@"Person").subs(^(id<PPSQLProtocol> sub) {
sub.column(@"age");
}).terms(^(PPTerm *term) {
term.where.equal(@"_id", @(1));
}).build;

NSLog(@"%@", sql);

Print Result:

-> UPDATE Person SET age = ? WHERE _id = 1
```
3. Custom SQL string, please try calling method `add`.
#### Pay Attention:
>The indefinite parameters need to end with nil.


## Author

- [ENUUI](https://github.com/FuihuiC)
## 中文参考
- [RTDatabase(1) 存储篇](https://www.jianshu.com/p/37e7d4abd4dd)
- [RTDatabase(2) SQL篇](https://www.jianshu.com/p/1739567ea7e4)
## Licenses

All source code is licensed under the [MIT License](https://raw.github.com/rs/SDWebImage/master/LICENSE).

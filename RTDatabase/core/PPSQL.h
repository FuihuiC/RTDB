//
//  PPSQL.h
//  RTDatabase
//
//  Created by ENUUI on 2018/7/2.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPTerm.h"
#import "PPSubSQL.h"

typedef void(^PPSQLSubBlock)(id<PPSQLProtocol>);
typedef void(^PPSQLTermBlock)(PPTerm *);

// --------------PPSQL---------------
NS_SWIFT_UNAVAILABLE("")
@interface PPSQL : NSObject 
@property (nonatomic, strong, readonly) NSMutableString *mStrResult;


/**
 * Append a custom string.
 */
- (PPSQL *(^)(NSString *))add;
@property (nonatomic, readonly) PPSQL *(^add)(NSString *);

- (NSString *)build;
/**
 * CREATE default sql is "CREATE TABLE if not exists 'table name'"
 * The subs followed by CREATE will call back an obj typed of id<PPSQLProtocol>.
 * Actually, the obj is typed of PPSQLCreate.
 *
 * PPSQL *pp = [[PPSQL alloc] init];
 *
 * NSString *sql = pp.CREATE(@"Person").subs(^(id<PPSQLProtocol> sub) {
 *
 *    sub.INTEGER(@"_id").primaryKey.autoincrement.notNull
 *       .TEXT(@"name")
 *       .INTEGER(@"age")
 *       .REAL(@"height")
 *       .BLOB(@"info");
 * }).build;
 *
 * NSLog(@"%@", sql);
 *
 * Print Result:
 * -> CREATE TABLE if not exists 'Person'
 *   ('_id' 'INTEGER' primary key autoincrement NOT NULL,
 *   'name' 'TEXT', 'age' 'INTEGER', 'height' 'REAL', 'info' 'BLOB')
 */
- (PPSQL *(^)(NSString *))CREATE;
@property (nonatomic, readonly) PPSQL *(^CREATE)(NSString *);

/**
 * sql = pp.UPDATE(@"Person").subs(^(id<PPSQLProtocol> sub) {
 *     sub.column(@"age");
 * }).terms(^(PPTerm *term) {
 *     term.where.equal(@"_id", @(1));
 * }).build;
 *
 * NSLog(@"%@", sql);
 * Print Result:
 * -> UPDATE Person SET age = ? WHERE _id = 1
 */

/**
 * INSERT INTO %@
 */
- (PPSQL *(^)(NSString *))INSERT;
@property (nonatomic, readonly) PPSQL *(^INSERT)(NSString *);

/**
 * UPDATE %@ SET 
 */
- (PPSQL *(^)(NSString *))UPDATE;
@property (nonatomic, readonly) PPSQL *(^UPDATE)(NSString *);

/**
 * DELETE FROM %@
 */
- (PPSQL *(^)(NSString *))DELETE;
@property (nonatomic, readonly) PPSQL *(^DELETE)(NSString *);

/**
 * SELECT
 */
- (PPSQL *)SELECT;
- (PPSQL *)distinct;


/**
 * subs callback an obj type of id<PPSQLProtocol>,
 *  which can be an instance of PPSQLCreate, PPSQLInsert or PPSQLUpdate.
 */
- (PPSQL *(^)(PPSQLSubBlock))subs;
@property (nonatomic, readonly) PPSQL*(^subs)(PPSQLSubBlock);

/**
 * terms callback an obj type of PPTerm.
 */
- (PPSQL *(^)(PPSQLTermBlock))terms;
@property (nonatomic, readonly) PPSQL *(^terms)(PPSQLTermBlock);
@end






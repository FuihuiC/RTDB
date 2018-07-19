//
//  PPSQL.h
//  RTDatabase
//
//  Created by ENUUI on 2018/7/2.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPTerm.h"
#import "PPColumns.h"


typedef void(^PPSQLTermBlock)(PPTerm *);
typedef void(^PPSQLColumnBlock)(PPColumns *);
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
 * NSString *sql = pp.CREATE(@"Person").columns(^(PPColumns *columns) {
 *
 *    columns.INTEGER(@"_id").primaryKey.autoincrement.notNull
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
 * sql = pp.INSERT(@"Person").columns(^(PPColumns *columns) {
 *     columns
 *      .column(@{@"nameDict": @"TEXT", @"ageDict": @"INTEGER", @"genderDict": @"TEXT"})
 *      .column(@[@"nameArr", @"ageArr", @"genderArr"])
 *      .column(@"name").column(@"age").column(@"gender");
 * }).build;
 *
 * NSLog(@"%@", sql);
 * Print Result:
 * -> INSERT INTO Person(ageDict, nameDict, genderDict, nameArr, ageArr, genderArr, name, age, gender) VALUES (:ageDict, :nameDict, :genderDict, :nameArr, :ageArr, :genderArr, :name, :age, :gender)
 */
- (PPSQL *(^)(NSString *))INSERT;
@property (nonatomic, readonly) PPSQL *(^INSERT)(NSString *);

/**
 * UPDATE %@ SET
 * sql = pp.UPDATE(@"Person").columns(^(PPColumns *columns) {
 *     columns
 *      .column(@{@"nameDict": @"TEXT", @"ageDict": @"INTEGER", @"genderDict": @"TEXT"})
 *      .column(@[@"nameArr", @"ageArr", @"genderArr"])
 *      .column(@"name").column(@"age").column(@"gender");
 * })
 * .terms(^(PPTerm *term){
 *     term.where.moreOrEquel(@"age", @(12));
 * })
 * .build;
 *
 * NSLog(@"%@", sql);
 * Print Result:
 * -> UPDATE Person SET ageDict = ?, nameDict = ?, genderDict = ?, nameArr = ?, ageArr = ?, genderArr = ?, name = ?, age = ?, gender = ? WHERE age >= 12
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

- (PPSQL *(^)(PPSQLColumnBlock))columns;
@property (nonatomic, readonly) PPSQL *(^columns)(PPSQLColumnBlock);

/**
 * terms callback an obj type of PPTerm.
 */
- (PPSQL *(^)(PPSQLTermBlock))terms;
@property (nonatomic, readonly) PPSQL *(^terms)(PPSQLTermBlock);
@end






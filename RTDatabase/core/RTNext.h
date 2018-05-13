//
//  RTNext.h
//  RTSQLite
//
//  Created by ENUUI on 2018/5/7.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RTSync;

/**
 Method (enumAllSteps:) callback block type

 @param dic  store data
 @param step index of step
 @param stop if *stop = YES, the loop will stop.
 @param err  When there is a error, stop this loop. The reason will be stored in error
 */
typedef void(^RT_STEP_CALLBACK_BLOCK)(NSDictionary *dic, int step, BOOL *stop, NSError *err);

/**
 Method (enumAllColumns:) callback block type

 @param value  column value
 @param name   column name
 @param step   index of step
 @param column index of column
 @param stop   if *stop = YES, the loop will stop.
 @param err    When there is a error, stop this loop. The reason will be stored in error
 */
typedef void(^RT_COLUMN_CALLBACK_BLOCK)(id value, NSString *name, int step, int column, BOOL *stop, NSError *err);


@interface RTNext : NSObject
- (instancetype)initWithStmt:(void *)stmt withSql:(NSString *)sql;

/**
 * Loop executes sqlite3_step ().
 * If the result is SQLITE_OK, it will look for the corresponding row.
 * If there is data, it will be stored in NSDictionary and callback by block.
 */
- (void)enumAllSteps:(RT_STEP_CALLBACK_BLOCK)stepCallback;

/** Loop executes sqlite3_step () and find current row all column value out. */
- (void)enumAllColumns:(RT_COLUMN_CALLBACK_BLOCK)columnCallback;

/** See if there is any next step */
- (BOOL)step;
- (BOOL)stepWithError:(NSError *__autoreleasing *)error;

/** Get column count of per row in this table */
- (int)columnCountOfRow;
/** Get column index by name */
- (int)columnForName:(NSString *)name;
/** Get name by column index */
- (NSString *)nameForColumn:(int)column;
/** Get value by column name */
- (id)valueForName:(NSString *)name;
#pragma mark value for column
/** Get value by column index */
- (id)valueForColumn:(int)column;

- (NSString *)textForColumn:(int)column;
- (NSData *)dataForColumn:(int)column;
- (NSNumber *)numberForColumn:(int)column;
- (NSDate *)dateForColumn:(int)column;
- (double)doubleForColumn:(int)column;
- (float)floatForColumn:(int)column;
- (char)charForColumn:(int)column;
- (unsigned char)ucharForColumn:(int)column;
- (short)shortForColumn:(int)column;
- (unsigned short)ushortForColumn:(int)column;
- (int)intForColumn:(int)column;
- (unsigned int)uintForColumn:(int)column;
- (long)longForColumn:(int)column;
- (unsigned long)ulongForColumn:(int)column;
- (long long)llongForColumn:(int)column;
- (unsigned long long)ullongForColumn:(int)column;
- (BOOL)boolForColumn:(int)column;
@end

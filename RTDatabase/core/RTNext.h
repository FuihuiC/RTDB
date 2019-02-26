//
//  RTNext.h
//  RTDatebase
//
//  Created by hc-jim on 2019/2/25.
//  Copyright © 2019 ENUUI. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RTDB;
NS_ASSUME_NONNULL_BEGIN

@interface RTNext : NSObject

@property (nonatomic, readonly) NSString *sql;

+ (instancetype)stepsWithStmt:(void *)stmt withSQL:(NSString *)sql;
- (nullable NSError *)finalError;

- (BOOL)step;
- (BOOL)stepWithError:(NSError *_Nullable __autoreleasing *)error;

#pragma mark -
- (void)enumRows:(void(^)(NSDictionary * _Nullable rowDict, int row, BOOL * _Nullable stop, NSError *_Nullable error))callback;
- (void)enumColumns:(void(^)(NSString * _Nullable colName, id _Nullable colValue, int row, int colIndex, BOOL * _Nullable stop, NSError * _Nullable error))callback;

#pragma mark value for column
/** Get value by column index */
- (nullable id)valueForColumn:(int)column;

- (nullable NSString *)textForColumn:(int)column;
- (nullable NSData *)dataForColumn:(int)column;
- (nullable NSNumber *)numberForColumn:(int)column;
- (nullable NSDate *)dateForColumn:(int)column;

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

#pragma mark -
- (NSString *)tableName;
@end

NS_ASSUME_NONNULL_END

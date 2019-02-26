//
//  RTDB.h
//  RTDatebase
//
//  Created by hc-jim on 2019/2/25.
//  Copyright © 2019 ENUUI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTNext.h"

#ifndef RT_EXTERN
#define RT_EXTERN extern
#endif

NS_ASSUME_NONNULL_BEGIN

// sqlite3 error handle
RT_EXTERN void rt_error(NSString *errMsg, int code, NSError **err);
RT_EXTERN void rt_sqlite3_err(int result, NSError **err);

typedef enum : char {
    rttext   = 'T', // string
    rtblob   = 'D', // data
    rtnumber = 'N', // number
    
    // float
    rtfloat  = 'f', // float
    rtdouble = 'd', // double
    rtdate   = '#', // NSDate: converted to double
    
    // integer
    rtchar   = 'c', // char
    rtuchar  = 'C', // unsigned char
    rtshort  = 's', // short
    rtushort = 'S', // unsigned short
    rtint    = 'i', // int
    rtuint   = 'I', // unsigned int
    rtlong   = 'q', // long
    rtulong  = 'Q', // unsigned long
    rtbool   = 'B'  // BOOL
} rt_objc_t;


@interface RTDB : NSObject
/**
 * Create or open sqlite. based on the specified path.
 * @required: The path needs to end with the SQLite file.
 */
- (BOOL)openWithPath:(NSString *)path withError:(NSError *_Nullable __autoreleasing *)error;
- (BOOL)openWithPath:(NSString *)path withFlags:(int)flags withError:(NSError *_Nullable __autoreleasing *)error;

/**
 * Close the SQLite that has been opened
 */
- (BOOL)close;

#pragma mark -
/**
 * Execute the SQL statement and return if it is successful
 * If you select the (withError:) method and pass in (NSError **) err, the error message is transmitted when the execution fails.
 * Select the appropriate method according to the different parameters outside the SQL statement.
 */
- (BOOL)execWithQuery:(NSString *)sql;

- (BOOL)execWithQuery:(NSString *)sql withError:(NSError *_Nullable __autoreleasing *)err;

- (BOOL)execQuery:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION;
- (BOOL)execWithError:(NSError *_Nullable __autoreleasing *)err withQuery:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION;

- (BOOL)exceQuery:(NSString *)sql withArrValues:(NSArray *)arrValues;
- (BOOL)execQuery:(NSString *)sql withArrValues:(NSArray *)arrValues withError:(NSError *_Nullable __autoreleasing *)err;

- (BOOL)execQuery:(NSString *)sql withDicValues:(NSDictionary *)dicValues;
- (BOOL)execQuery:(NSString *)sql withDicValues:(NSDictionary *)dicValues withError:(NSError *_Nullable __autoreleasing *)err;

#pragma mark -
/**
 * Execute the SQL statement and return an object of RTNext. For details, please see RTNext class.
 * If you select the (withError:) method and pass in (NSError **) err, the error message is transmitted when the execution fails.
 * Select the appropriate method according to the different parameters outside the SQL statement.
 */
- (RTNext *)execSQL:(NSString *)sql;
- (RTNext *)execSQL:(NSString *)sql withError:(NSError *_Nullable __autoreleasing *)err;

- (RTNext *)execSQL:(NSString *)sql
       withDicValues:(NSDictionary *)dicValues;
- (RTNext *)execSQL:(NSString *)sql
       withDicValues:(NSDictionary *)dicValues
           withError:(NSError *_Nullable __autoreleasing *)error;

- (RTNext *)execSQL:(NSString *)sql
       withArrValues:(NSArray *)arrValues;
- (RTNext *)execSQL:(NSString *)sql
       withArrValues:(NSArray *)arrValues
           withError:(NSError *_Nullable __autoreleasing *)error;

- (RTNext *)execSQLWithArgs:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION;
- (RTNext *)execSQLWithError:(NSError *_Nullable __autoreleasing *)error
                     withArgs:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION;





- (RTNext *)execSQL:(NSString *)sql
      withDicValues:(NSDictionary *)dicValues
      withArrValues:(NSArray *)arrValues
     withListValues:(va_list)listValues
          withError:(NSError *__autoreleasing *)error;
@end

NS_ASSUME_NONNULL_END

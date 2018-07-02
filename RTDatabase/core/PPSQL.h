//
//  PPSQL.h
//  RTDatabase
//
//  Created by hc-jim on 2018/7/2.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RTSubSQLProtocol;
@class PPWhere, PPConditon;

typedef void(^PPSQLSubBlock)(id<RTSubSQLProtocol>);
typedef void(^PPSQLWhereBlock)(PPWhere *);
typedef void(^PPSQLConditionBlock)(PPConditon *);
// -----------------------------
@protocol RTSubSQLProtocol <NSObject>

@required
@property (nonatomic, strong, readonly) NSMutableString *mStrResult;

- (NSString *)build;
- (id<RTSubSQLProtocol>(^)(NSString *))add;

@optional
- (id<RTSubSQLProtocol> (^)(NSString *))TEXT;
- (id<RTSubSQLProtocol> (^)(NSString *))INTEGER;
- (id<RTSubSQLProtocol> (^)(NSString *))BLOB;
- (id<RTSubSQLProtocol> (^)(NSString *))REAL;
- (id<RTSubSQLProtocol>)notNull;
- (id<RTSubSQLProtocol>)primaryKey;
- (id<RTSubSQLProtocol>)autoincrement;

// insert update only
- (id<RTSubSQLProtocol> (^)(NSString *))column;

@end

// --------------PPSQL---------------
@interface PPSQL : NSObject <RTSubSQLProtocol>
@property (nonatomic, strong, readonly) NSMutableString *mStrResult;

- (PPSQL *(^)(NSString *))CREATE;
- (PPSQL *(^)(NSString *))INSERT;
- (PPSQL *(^)(NSString *))UPDATE;
- (PPSQL *(^)(NSString *))DELETE;

- (PPSQL *(^)(NSString *))SELECT;

- (PPSQL *(^)(PPSQLSubBlock))subs;

- (PPSQL *(^)(PPSQLWhereBlock))where;

- (PPSQL *(^)(PPSQLConditionBlock))terms;
@end

// --------------PPConditon---------------
@interface PPConditon : NSObject <RTSubSQLProtocol>
@property (nonatomic, strong, readonly) NSMutableString *mStrResult;

- (PPConditon *(^)(NSUInteger))limit;
- (PPConditon *(^)(NSString *))orderBy;
/**
 * Orders must be end with nil;
 */
- (PPConditon *(^)(NSString *, ...))ordersBy;
- (PPConditon *)desc; // Descending order
- (PPConditon *)asc;  // Ascending order
@end

// --------------PPWhere---------------
@interface PPWhere : NSObject <RTSubSQLProtocol>
@property (nonatomic, strong, readonly) NSMutableString *mStrResult;

- (PPWhere *(^)(NSString *, ...))condition;

- (PPWhere *(^)(NSString *, id))equal; // =
- (PPWhere *(^)(NSString *, id))more;  // >
- (PPWhere *(^)(NSString *, id))less;  // <
- (PPWhere *(^)(NSString *, id))moreOrEquel; // >=
- (PPWhere *(^)(NSString *, id))lessOrEquel; // <=

- (PPWhere *)AND;
- (PPWhere *)OR;
@end

// --------------PPSQLCreate---------------
@interface PPSQLCreate : NSObject <RTSubSQLProtocol>
@property (nonatomic, strong, readonly) NSMutableString *mStrResult;

- (PPSQLCreate *(^)(NSString *))TEXT;
- (PPSQLCreate *(^)(NSString *))INTEGER;
- (PPSQLCreate *(^)(NSString *))BLOB;
- (PPSQLCreate *(^)(NSString *))REAL;
- (PPSQLCreate *)notNull;

- (PPSQLCreate *)primaryKey;
- (PPSQLCreate *)autoincrement;
@end

// --------------PPSQLInsert---------------
@interface PPSQLInsert : NSObject <RTSubSQLProtocol>

@property (nonatomic, strong, readonly) NSMutableString *mStrResult;

- (PPSQLInsert *(^)(NSString *))column;
@end

@interface PPSQLUpdate : NSObject <RTSubSQLProtocol>
@property (nonatomic, strong, readonly) NSMutableString *mStrResult;

- (PPSQLUpdate *(^)(NSString *))column;
@end



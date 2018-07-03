//
//  PPTerm.h
//  RTDatabase
//
//  Created by hc-jim on 2018/7/3.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPSQLProtocol.h"


/**
 * PPSQL *pp = [[PPSQL alloc] init];
 * sql = pp.DELETE(@"Person").terms(^(PPTerm *term) {
 *     term.where.moreOrEquel(@"_id", @(3));
 * }).build;
 *
 * NSLog(@"%@", sql);
 * Print result:
 * -> DELETE FROM Person WHERE _id >= 3
 */

// --------------PPTerm---------------
@interface PPTerm : NSObject <PPSQLProtocol>
@property (nonatomic, strong, readonly) NSMutableString *mStrResult;
- (PPTerm *(^)(NSString *))add;
// Glob
@end

@interface PPTerm (Match)

- (PPTerm *)like;
- (PPTerm *)glob;
@end

@interface PPTerm (Where)

- (PPTerm *)where;
@end

@interface PPTerm (GroupBy)
// Group By
- (PPTerm *(^)(NSString *))groupBy;
@property (nonatomic, copy, readonly) PPTerm *(^groupBy)(NSString *);

/**
 * The indefinite parameters must end with nil
 */
- (PPTerm *(^)(NSString *, ...))groupBys;
@property (nonatomic, copy, readonly) PPTerm *(^groupBys)(NSString *, ...);
// Having
- (PPTerm *)having;
@end

@interface PPTerm (Limit)
// limit
- (PPTerm *(^)(NSUInteger))limit;
@property (nonatomic, copy, readonly) PPTerm *(^limit)(NSUInteger);

@end

@interface PPTerm (OrderBy)
// orderBy
- (PPTerm *(^)(NSString *))orderBy;
@property (nonatomic, copy, readonly) PPTerm *(^orderBy)(NSString *);

/**
 * The indefinite parameters must end with nil
 */
- (PPTerm *(^)(NSString *, ...))ordersBy;
@property (nonatomic, copy, readonly) PPTerm *(^ordersBy)(NSString *, ...);

- (PPTerm *)desc; // Descending order
- (PPTerm *)asc;  // Ascending order

@end

// --------------PPTerm---------------
@interface PPTerm (Condition)
@property (nonatomic, strong, readonly) NSMutableString *mStrResult;

/**
 * The indefinite parameters must end with nil
 */
- (PPTerm *(^)(NSString *, ...))condition;
@property (nonatomic, copy, readonly) PPTerm *(^condition)(NSString *, ...);

- (PPTerm *(^)(NSString *, id))equal; // =
@property (nonatomic, copy, readonly) PPTerm *(^equal)(NSString *, id);

- (PPTerm *(^)(NSString *, id))more;  // >
@property (nonatomic, copy, readonly) PPTerm *(^more)(NSString *, id);

- (PPTerm *(^)(NSString *, id))less;  // <
@property (nonatomic, copy, readonly) PPTerm *(^less)(NSString *, id);

- (PPTerm *(^)(NSString *, id))moreOrEquel; // >=
@property (nonatomic, copy, readonly) PPTerm *(^moreOrEquel)(NSString *, id);

- (PPTerm *(^)(NSString *, id))lessOrEquel; // <=
@property (nonatomic, copy, readonly) PPTerm *(^lessOrEquel)(NSString *, id);

- (PPTerm *)AND;
- (PPTerm *)OR;
@end

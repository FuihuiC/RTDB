//
//  PPSQLProtocol.h
//  RTDatabase
//
//  Created by ENUUI on 2018/7/3.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#ifndef PPSQLProtocol_h
#define PPSQLProtocol_h


#endif /* PPSQLProtocol_h */
// -----------------------------


#define INIT_WITH_MSTRING - (instancetype)init { \
if (self = [super init]) { \
_mStrResult = [NSMutableString string]; \
} \
return self; \
}

@protocol PPSQLProtocol

@required
@property (nonatomic, strong, readonly) NSMutableString *mStrResult;

- (NSString *)build;
- (id<PPSQLProtocol>(^)(NSString *))add;

@optional
// creat sql only
- (id<PPSQLProtocol> (^)(NSString *))TEXT;
- (id<PPSQLProtocol> (^)(NSString *))INTEGER;
- (id<PPSQLProtocol> (^)(NSString *))BLOB;
- (id<PPSQLProtocol> (^)(NSString *))REAL;
- (id<PPSQLProtocol>)notNull;
- (id<PPSQLProtocol>)primaryKey;
- (id<PPSQLProtocol>)autoincrement;

// select only
- (id<PPSQLProtocol> (^)(NSString *))from;
- (id<PPSQLProtocol>)asterisk;

// select update insert
- (id<PPSQLProtocol> (^)(NSString *))column;

@end

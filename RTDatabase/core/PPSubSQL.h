//
//  PPSubSQL.h
//  RTDatabase
//
//  Created by ENUUI on 2018/7/3.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPSQLProtocol.h"

// --------------PPSQLCreate---------------
@interface PPSQLCreate : NSObject <PPSQLProtocol>
@property (nonatomic, strong, readonly) NSMutableString *mStrResult;

- (PPSQLCreate *(^)(NSString *))TEXT;
@property (nonatomic, readonly) PPSQLCreate *(^TEXT)(NSString *);

- (PPSQLCreate *(^)(NSString *))INTEGER;
@property (nonatomic, readonly) PPSQLCreate *(^INTEGER)(NSString *);

- (PPSQLCreate *(^)(NSString *))BLOB;
@property (nonatomic, readonly) PPSQLCreate *(^BLOB)(NSString *);

- (PPSQLCreate *(^)(NSString *))REAL;
@property (nonatomic, readonly) PPSQLCreate *(^REAL)(NSString *);

- (PPSQLCreate *)notNull;

- (PPSQLCreate *)primaryKey;
- (PPSQLCreate *)autoincrement;
@end

// --------------PPSQLInsert---------------
@interface PPSQLInsert : NSObject <PPSQLProtocol>

@property (nonatomic, strong, readonly) NSMutableString *mStrResult;

- (PPSQLInsert *(^)(NSString *))column;
@property (nonatomic, readonly) PPSQLInsert *(^column)(NSString *);
@end

@interface PPSQLUpdate : NSObject <PPSQLProtocol>
@property (nonatomic, strong, readonly) NSMutableString *mStrResult;

- (PPSQLUpdate *(^)(NSString *))column;
@property (nonatomic, readonly) PPSQLUpdate *(^column)(NSString *);
@end

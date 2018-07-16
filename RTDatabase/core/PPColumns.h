//
//  PPColumns.h
//  RTDatabase
//
//  Created by ENUUI on 2018/7/16.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPColumns : NSObject
- (instancetype)initWithType:(NSUInteger)type;
- (NSString *)build;

- (PPColumns *(^)(id))column;
@property (nonatomic, readonly) PPColumns *(^column)(NSString *);
@end


@interface PPColumns (Create)

- (PPColumns *(^)(NSString *))TEXT;
@property (nonatomic, readonly) PPColumns *(^TEXT)(NSString *);

- (PPColumns *(^)(NSString *))INTEGER;
@property (nonatomic, readonly) PPColumns *(^INTEGER)(NSString *);

- (PPColumns *(^)(NSString *))BLOB;
@property (nonatomic, readonly) PPColumns *(^BLOB)(NSString *);

- (PPColumns *(^)(NSString *))REAL;
@property (nonatomic, readonly) PPColumns *(^REAL)(NSString *);

- (PPColumns *)notNull;

- (PPColumns *)primaryKey;
- (PPColumns *)autoincrement;

@end

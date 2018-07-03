//
//  PPSQL.m
//  RTDatabase
//
//  Created by ENUUI on 2018/7/2.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "PPSQL.h"


typedef enum : NSUInteger {
    PPSQLOperateCreate = 1,
    PPSQLOperateSelect,
    PPSQLOperateInsert,
    PPSQLOperateUpdate,
    PPSQLOperateDelete,
} PPSQLOperateType;

@interface PPSQL ()
@property (nonatomic, assign) PPSQLOperateType opType;
@end

@implementation PPSQL

INIT_WITH_MSTRING

- (PPSQL *(^)(NSString *))add {
    return ^(NSString *args) {
        [self.mStrResult appendString:args];
        return self;
    };
}

- (NSString *)build {
    return self.mStrResult.copy;
}

- (PPSQL *(^)(NSString *))CREATE {
    [self reset];
    self.opType = PPSQLOperateCreate;
    return ^(NSString *tableName) {
        NSAssert(tableName && tableName.length > 0, @"Table name can not be empty");
        
        [self.mStrResult appendFormat:@"CREATE TABLE if not exists '%@'", tableName];
        return self;
    };
}

- (PPSQL *(^)(NSString *))INSERT {
    [self reset];
    self.opType = PPSQLOperateInsert;
    return ^(NSString *tableName) {
        NSAssert(tableName && tableName.length > 0, @"Table name can not be empty");
        
        [self.mStrResult appendFormat:@"INSERT INTO %@", tableName];
        return self;
    };
}

- (PPSQL *(^)(NSString *))UPDATE {
    [self reset];
    self.opType = PPSQLOperateUpdate;
    return ^(NSString *tableName) {
        NSAssert(tableName && tableName.length > 0, @"Table name can not be empty");
        
        [self.mStrResult appendFormat:@"UPDATE %@ SET ", tableName];
        return self;
    };
}

- (PPSQL *(^)(NSString *))DELETE {
    [self reset];
    self.opType = PPSQLOperateDelete;
    return ^(NSString *tableName) {
        NSAssert(tableName && tableName.length > 0, @"Table name can not be empty");
        
        [self.mStrResult appendFormat:@"DELETE FROM %@", tableName];
        return self;
    };
}

- (PPSQL *(^)(NSString *))SELECT {
    [self reset];
    self.opType = PPSQLOperateDelete;
    return ^(NSString *tableName) {
        NSAssert(tableName && tableName.length > 0, @"Table name can not be empty");
        [self.mStrResult appendFormat:@"SELECT * FROM %@", tableName];
        return self;
    };
}

- (PPSQL *)distinct {
    [self.mStrResult appendString:@" DISTINCT"];
    return self;
}

// ---------------------------------------
- (PPSQL *(^)(PPSQLSubBlock))subs {
    id<PPSQLProtocol> subOP = [self sub];
    return ^(PPSQLSubBlock block) {
        NSAssert(block != nil, @"Sub block can not be empty!");
        block(subOP);
        [self.mStrResult appendString:[subOP build]];
        return self;
    };
}

- (id<PPSQLProtocol>)sub {
    id<PPSQLProtocol> subOP = nil;
    switch (self.opType) {
        case PPSQLOperateCreate: {
            subOP = [[PPSQLCreate alloc] init];
        }
            break;
        case PPSQLOperateSelect: {}
            break;
        case PPSQLOperateInsert: {
            subOP = [[PPSQLInsert alloc] init];
        }
            break;
        case PPSQLOperateUpdate: {
            subOP = [[PPSQLUpdate alloc] init];
        }
            break;
        case PPSQLOperateDelete: {}
            break;
        default:
            break;
    }
    
    return subOP;
}

- (PPSQL *(^)(PPSQLTermBlock))terms {
    return ^(PPSQLTermBlock block) {
        NSAssert(block != nil, @"Block can not be empty!");
        PPTerm *condition = [[PPTerm alloc] init];
        block(condition);
        return self.add(condition.build);
    };
}

- (PPSQL *)reset {
    if (self.mStrResult.length > 0) {
        [self.mStrResult deleteCharactersInRange:NSMakeRange(0, self.mStrResult.length)];
    }
    return self;
}
@end



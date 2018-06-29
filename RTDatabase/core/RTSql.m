//
//  RTSql.m
//  RTDatabase
//
//  Created by ENUUI on 2018/6/29.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTSql.h"

@interface RTSql ()
@property (nonatomic, strong) NSMutableString *mSql;
@end

@implementation RTSql

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}
- (NSMutableString *)mSql {
    if (_mSql == nil) {
        _mSql = [NSMutableString string];
    }
    return _mSql;
}

#pragma mark -
- (RTSql *(^)(NSString *))append {
    return ^(NSString *args) {
        [self.mSql appendFormat:@" %@", args];
        return self;
    };
}
// CREATE
- (RTSql *(^)(NSString *))CREATE {
    return ^(NSString *args) {
        [self.mSql appendFormat:@"CREATE TABLE if not exists '%@'", args];
        return self;
    };
}

- (RTSql *(^)(NSString *))columnINTEGER  {
    return ^(NSString *args) {
        [self.mSql appendFormat:@" '%@' 'INTEGER'", args];
        return self;
    };
}

- (RTSql *(^)(NSString *))columnTEXT {
    return ^(NSString *args) {
        [self.mSql appendFormat:@" '%@' 'TEXT'", args];
        return self;
    };
}

- (RTSql *(^)(NSString *))columnBLOB {
    return ^(NSString *args) {
        [self.mSql appendFormat:@" '%@' 'BLOB'", args];
        return self;
    };
}

- (RTSql *(^)(NSString *))columnREAL {
    return ^(NSString *args) {
        [self.mSql appendFormat:@" '%@' 'REAL'", args];
        return self;
    };
}

// SELECT
- (RTSql *(^)(NSString *))SELECT {
    return ^(NSString *args) {
        [self.mSql appendFormat:@"SELECT %@", args];
        return self;
    };
}

// UPDATE
- (RTSql *(^)(NSString *))UPDATE {
    return ^(NSString *args) {
        [self.mSql appendFormat:@"UPDATE %@", args];
        return self;
    };
}

// INSERT
- (RTSql *(^)(NSString *, ...))INSERT {
    return ^(NSString *tableName, ...) {
        va_list ap;
        va_start(ap, tableName);
        
        [self.mSql appendFormat:@"INSERT INTO %@", tableName];
        NSMutableArray *mArr = [NSMutableArray array];
        
        for (NSString *column = va_arg(ap, NSString *); column != nil; column = va_arg(ap, NSString *)) {
            [mArr addObject:column];
        }
        va_end(ap);
        
        NSString *columns = [mArr componentsJoinedByString:@", "];
        NSString *placeholders = [mArr componentsJoinedByString:@", :"];
        if (placeholders || placeholders.length > 0) {
            placeholders = [NSString stringWithFormat:@":%@", placeholders];
        }
        
        return self.leftBracket.append(columns).rightBracket.append(@" VALUES").leftBracket.append(placeholders).rightBracket;
    };
}

// DELETE
- (RTSql *(^)(NSString *))DELETE {
    return ^(NSString *args) {
        [self.mSql appendFormat:@"DELETE %@", args];
        return self;
    };
}

- (RTSql *(^)(NSString *))or_ {
    return ^(NSString *args) {
        [self.mSql appendFormat:@" or %@", args];
        return self;
    };
}

- (RTSql *(^)(NSString *))and_ {
    return ^(NSString *args) {
        [self.mSql appendFormat:@" and %@", args];
        return self;
    };
}

- (RTSql *(^)(NSString *))like {
    return ^(NSString *args) {
        [self.mSql appendFormat:@" LIKE %@", args];
        return self;
    };
}

- (RTSql *(^)(NSString *))glob {
    return ^(NSString *args) {
        [self.mSql appendFormat:@" GLOB %@", args];
        return self;
    };
}

- (RTSql *(^)(NSString *))where {
    return ^(NSString *args) {
        [self.mSql appendFormat:@" WHERE %@", args];
        return self;
    };
}

- (RTSql *(^)(NSString *))orderBy {
    return ^(NSString *args) {
        [self.mSql appendFormat:@" order by %@", args];
        return self;
    };
}

- (RTSql *)desc {
    [self.mSql appendString:@" DESC"];
    return self;
}

- (RTSql *)asc {
    [self.mSql appendString:@" ASC"];
    return self;
}

- (RTSql *(^)(NSString *))groupBy {
    return ^(NSString *args) {
        [self.mSql appendFormat:@" GROUP BY %@", args];
        return self;
    };
}

- (RTSql *(^)(NSString *))having {
    return ^(NSString *args) {
        [self.mSql appendFormat:@" HAVING %@", args];
        return self;
    };
}

- (RTSql *(^)(NSString *))distinct {
    return ^(NSString *args) {
        [self.mSql appendFormat:@" DISTINCT %@", args];
        return self;
    };
}

- (RTSql *(^)(NSInteger))limit {
    return ^(NSInteger count) {
        [self.mSql appendFormat:@" limit %ld", count];
        return self;
    };
}

- (RTSql *(^)(NSString *))from {
    return ^(NSString *args) {
        [self.mSql appendFormat:@" FROM %@", args];
        return self;
    };
}
// types
- (RTSql *)integer {
    [self.mSql appendString:@" INTEGER"];
    return self;
}
- (RTSql *)text {
    [self.mSql appendString:@" TEXT"];
    return self;
}
- (RTSql *)blob {
    [self.mSql appendString:@" BLOB"];
    return self;
}
- (RTSql *)real {
    [self.mSql appendString:@" REAL"];
    return self;
}

//brackets
- (RTSql *)leftBracket {
    [self.mSql appendString:@" ("];
    return self;
}

- (RTSql *)rightBracket {
    [self.mSql appendString:@")"];
    return self;
}

// comma
- (RTSql *)comma {
    [self.mSql appendString:@","];
    return self;
}

// asterisk
- (RTSql *)asterisk {
    [self.mSql appendString:@" *"];
    return self;
}

- (RTSql *(^)(NSString *))quotes {
    return ^(NSString *args) {
        [self.mSql appendFormat:@" '%@'", args];
        return self;
    };
}

- (NSString *)end {
    
    NSString *result = _mSql.copy;
    DELog(@"%@", result);
    [self reset];
    return result;
}

- (RTSql *)reset {
    if (self.mSql.length > 0) {
        [self.mSql deleteCharactersInRange:NSMakeRange(0, self.mSql.length)];
    }
    return self;
}
@end

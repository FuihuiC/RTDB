//
//  RTSql.m
//  RTDatabase
//
//  Created by ENUUI on 2018/6/29.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "RTSql.h"


typedef enum : NSUInteger {
    RTSQL_CREATE = 1,
    RTSQL_INSERT,
    RTSQL_UPDATE,
    RTSQL_DELETE
} RTSQLType;

@interface RTSubSql ()
@property (nonatomic, assign) RTSQLType opType;
- (NSString *)build;
@end

// --------------------------------------------------
// --------------------------------------------------
// --------------------------------------------------
@interface RTSql ()
@property (nonatomic, strong) NSMutableString *mSql;
@property (nonatomic, strong) RTSubSql *subSql;
@property (nonatomic, assign) RTSQLType opType;
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

- (RTSubSql *)subSql {
    if (_subSql == nil) {
        _subSql = [[RTSubSql alloc] init];
    }
    return _subSql;;
}

- (RTSql *(^)(void(^)(RTSubSql *)))columns {
    return ^(void(^block)(RTSubSql *)) {
        NSAssert(block != nil, @"Columns can not recieve a empty block!");
        self.subSql.opType = self.opType;
        block(self.subSql);
        [self.mSql appendString:[self.subSql build]];
        return self;
    };
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
    self.opType = RTSQL_CREATE;
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

// --------------------------------------------------


@interface RTSubCreate ()


@end

@implementation RTSubCreate
- (RTSubCreate *(^)(NSString *))TEXT {
    return ^(NSString *column) {
        
        return self;
    };
}

- (RTSubCreate *(^)(NSString *))INTEGER {
    return ^(NSString *column) {
        
        return self;
    };
}

- (RTSubCreate *(^)(NSString *))BLOB {
    return ^(NSString *column) {
        
        return self;
    };
}

- (RTSubCreate *(^)(NSString *))REAL {
    return ^(NSString *column) {
        
        return self;
    };
}

- (RTSubCreate *)notNull  {
    return self;
}

- (RTSubCreate *)primaryKey  {
    return self;
}

- (RTSubCreate *)autoincrement  {
    return self;
}

@end
// --------------------------------------------------
// --------------------------------------------------

typedef enum : NSUInteger {
    RTSubColumnTEXT   = 1,
    RTSubColumnINTEGER,
    RTSubColumnBLOB,
    RTSubColumnREAl
} RTSubColumnType;

@interface RTSubSql ()
@property (nonatomic, strong) NSMutableString *mStrResult;
@end

@implementation RTSubSql

- (instancetype)init {
    if (self = [super init]) {
        _mStrResult = [NSMutableString string];
    }
    return self;
}

- (NSString *)build {
    if (self.opType == RTSQL_CREATE) {
        return [NSString stringWithFormat:@"(%@)", _mStrResult];
    }
    return _mStrResult.copy;
}

- (void)column:(NSString *)column withType:(RTSubColumnType)type {
    switch (self.opType) {
        case RTSQL_CREATE:
            [self createColumn:column withType:type];
            break;
        default:
            break;
    }
}

- (void)createColumn:(NSString *)column withType:(RTSubColumnType)type {
    NSString *format = @", '%@' '%@'";
    if (_mStrResult.length == 0) {
        format = @"'%@' '%@'";
    }
    
    switch (type) {
        case RTSubColumnTEXT: {
            [_mStrResult appendFormat:format, column, @"TEXT"];
        }
            break;
        case RTSubColumnINTEGER: {
            [_mStrResult appendFormat:format, column, @"INTEGER"];
        }
            break;
        case RTSubColumnBLOB: {
            [_mStrResult appendFormat:format, column, @"BLOB"];
        }
            break;
        case RTSubColumnREAl: {
            [_mStrResult appendFormat:format, column, @"REAL"];
        }
            break;
        default:
            break;
    }
}

- (RTSubSql *(^)(NSString *))TEXT {
    return ^(NSString *column) {
        [self column:column withType:RTSubColumnTEXT];
        return self;
    };
}

- (RTSubSql *(^)(NSString *))INTEGER {
    return ^(NSString *column) {
        [self column:column withType:RTSubColumnINTEGER];
        return self;
    };
}

- (RTSubSql *(^)(NSString *))BLOB {
    return ^(NSString *column) {
        [self column:column withType:RTSubColumnBLOB];
        return self;
    };
}

- (RTSubSql *(^)(NSString *))REAL {
    return ^(NSString *column) {
        [self column:column withType:RTSubColumnREAl];
        return self;
    };
}

- (RTSubSql *)notNull {
    [self.mStrResult appendFormat:@" NOT NULL"];
    return self;
}

- (RTSubSql *(^)(NSString *))add {
    return ^(NSString *args) {
        [self.mStrResult appendString:args];
        return self;
    };
}
@end

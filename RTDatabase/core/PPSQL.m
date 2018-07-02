//
//  PPSQL.m
//  RTDatabase
//
//  Created by hc-jim on 2018/7/2.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "PPSQL.h"

#define INIT_WITH_MSTRING - (instancetype)init { \
if (self = [super init]) { \
_mStrResult = [NSMutableString string]; \
} \
return self; \
}

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

- (id<RTSubSQLProtocol> (^)(NSString *))add {
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

// ---------------------------------------
- (PPSQL *(^)(PPSQLSubBlock))subs {
    id<RTSubSQLProtocol> subOP = [self sub];
    return ^(PPSQLSubBlock block) {
        NSAssert(block != nil, @"Sub block can not be empty!");
        block(subOP);
        [self.mStrResult appendString:[subOP build]];
        return self;
    };
}

- (id<RTSubSQLProtocol>)sub {
    id<RTSubSQLProtocol> subOP = nil;
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

- (PPSQL *(^)(PPSQLWhereBlock))where {
    
    return ^(PPSQLWhereBlock block) {
        [self.mStrResult appendString:@" WHERE"];
        PPWhere *con = [[PPWhere alloc] init];
        block(con);
        
        return self.add(con.build);
    };
}

- (PPSQL *(^)(PPSQLConditionBlock))terms {
    return ^(PPSQLConditionBlock block) {
        NSAssert(block != nil, @"Block can not be empty!");
        PPConditon *condition = [[PPConditon alloc] init];
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

// ---------------------------------------------------
// ---------------------------------------------------
#pragma mark - PPConditon
// ---------------------------------------------------
@implementation PPConditon
INIT_WITH_MSTRING

- (id<RTSubSQLProtocol> (^)(NSString *))add {
    return ^(NSString *args) {
        [self.mStrResult appendString:args];
        return self;
    };
}

- (NSString *)build {
    return self.mStrResult.copy;
}

- (PPConditon *(^)(NSUInteger))limit {
    return ^(NSUInteger no) {
        [self.mStrResult appendFormat:@" limit %lu", (unsigned long)no];
        return self;
    };
}

- (PPConditon *(^)(NSString *))orderBy {
    return ^(NSString *col) {
        [self.mStrResult appendFormat:@" ORDER BY %@", col];
        return self;
    };
}

- (PPConditon *(^)(NSString *, ...))ordersBy {
    return ^(NSString *col, ...) {
        va_list ap;
        va_start(ap, col);
        NSMutableString *mStrTemp = [NSMutableString stringWithString:col];
        for (NSString *aCol = va_arg(ap, NSString *); aCol != nil; aCol = va_arg(ap, NSString *)) {
            [mStrTemp appendFormat:@", %@", aCol];
        }
        va_end(ap);
        [self.mStrResult appendFormat:@" ORDER BY %@", mStrTemp];
        return self;
    };
}

- (PPConditon *)desc { // Descending order
    return self.add(@" DESC");
}
- (PPConditon *)asc { // Ascending order
    return self.add(@" ASC");
}

@end

// ---------------------------------------------------
// ---------------------------------------------------
#pragma mark - PPWhere
// ---------------------------------------------------
@implementation PPWhere
INIT_WITH_MSTRING

- (id<RTSubSQLProtocol> (^)(NSString *))add {
    return ^(NSString *args) {
        [self.mStrResult appendString:args];
        return self;
    };
}

- (NSString *)build {
    return self.mStrResult.copy;
}

- (PPWhere *(^)(NSString *, ...))condition {
    return ^(NSString *format, ...) {
        va_list ap;
        va_start(ap, format);
        NSString *result = [[NSString alloc] initWithFormat:format arguments:ap];
        va_end(ap);
        
        [self.mStrResult appendFormat: @" %@", result];
        return self;
    };
}

- (PPWhere *(^)(NSString *, id))equal { // =
    return ^(NSString *key, id value) {
        [self.mStrResult appendFormat:@" %@ = %@", key, value];
        return self;
    };
}

- (PPWhere *(^)(NSString *, id))more { // >
    return ^(NSString *key, id value) {
        [self.mStrResult appendFormat:@" %@ > %@", key, value];
        return self;
    };
}

- (PPWhere *(^)(NSString *, id))less { // <
    return ^(NSString *key, id value) {
        [self.mStrResult appendFormat:@" %@ < %@", key, value];
        return self;
    };
}

- (PPWhere *(^)(NSString *, id))moreOrEquel { // >=
    return ^(NSString *key, id value) {
        [self.mStrResult appendFormat:@" %@ >= %@", key, value];
        return self;
    };
}

- (PPWhere *(^)(NSString *, id))lessOrEquel { // <=
    return ^(NSString *key, id value) {
        [self.mStrResult appendFormat:@" %@ <= %@", key, value];
        return self;
    };
}

- (PPWhere *)AND {
    return self.add(@" AND");
}

- (PPWhere *)OR {
    return self.add(@" OR");
}
@end

// ---------------------------------------------------
// ---------------------------------------------------
#pragma mark - PPSQLCreate
// ---------------------------------------------------
@interface PPSQLCreate ()
@property (nonatomic, strong) NSMutableString *mStrColumns;
@end
@implementation PPSQLCreate

- (instancetype)init {
    if (self = [super init]) {
        _mStrResult = [NSMutableString stringWithString:@"(%@)"];
        _mStrColumns = [NSMutableString string];
    }
    return self;
}

- (id<RTSubSQLProtocol> (^)(NSString *))add {
    return ^(NSString *args) {
        [self.mStrResult appendString:args];
        return self;
    };
}

- (NSString *)build {
    return [NSString stringWithFormat:self.mStrResult, _mStrColumns];
}

- (PPSQLCreate *(^)(NSString *))TEXT {
    return ^(NSString *column) {
        [self addColumn:column withSQType:@"TEXT"];
        return self;
    };
}

- (PPSQLCreate *(^)(NSString *))INTEGER {
    return ^(NSString *column) {
        [self addColumn:column withSQType:@"INTEGER"];
        return self;
    };
}

- (PPSQLCreate *(^)(NSString *))BLOB {
    return ^(NSString *column) {
        [self addColumn:column withSQType:@"BLOB"];
        return self;
    };
}

- (PPSQLCreate *(^)(NSString *))REAL {
    return ^(NSString *column) {
        [self addColumn:column withSQType:@"REAL"];
        return self;
    };
}

- (void)addColumn:(NSString *)column withSQType:(NSString *)t {
    NSAssert(column && column.length > 0, @"Create column can not be empty!");
    
    NSString *format = @", '%@' '%@'";
    if (_mStrColumns.length == 0) {
        format = @"'%@' '%@'";
    }
    [self.mStrColumns appendFormat:format, column, t];
}

- (PPSQLCreate *)notNull {
    [self.mStrColumns appendString:@" NOT NULL"];
    return self;
}

- (PPSQLCreate *)primaryKey {
    [self.mStrColumns appendString:@" primary key"];
    return self;
}

- (PPSQLCreate *)autoincrement {
    [self.mStrColumns appendString:@" autoincrement"];
    return self;
}

@end

// ---------------------------------------------------
// ---------------------------------------------------
#pragma mark - PPSQLInsert
// ---------------------------------------------------

@interface PPSQLInsert ()

@property (nonatomic, strong) NSMutableString *mStrColumns;
@property (nonatomic, strong) NSMutableString *mStrValues;
@end

@implementation PPSQLInsert

- (instancetype)init {
    if (self = [super init]) {
        _mStrResult = [NSMutableString stringWithString:@"(%@) VALUES (%@)"];
        _mStrColumns = [NSMutableString string];
        _mStrValues = [NSMutableString string];
    }
    return self;
}

- (id<RTSubSQLProtocol> (^)(NSString *))add {
    return ^(NSString *args) {
        [self.mStrResult appendString:args];
        return self;
    };
}

- (NSString *)build {
    return [NSString stringWithFormat:self.mStrResult, self.mStrColumns, self.mStrValues];
}

- (PPSQLInsert *(^)(NSString *))column {
    return ^(NSString *col) {
        
        NSAssert(col && col.length > 0, @"Column can not be empty!");
        
        NSString *formatCol = @", %@";
        NSString *formatVal = @", :%@";
        
        if (self.mStrColumns.length == 0) {
            formatCol = @"%@";
        }
        if (self.mStrValues.length == 0) {
            formatVal = @":%@";
        }
        
        [self.mStrColumns appendFormat:formatCol, col];
        [self.mStrValues appendFormat:formatVal, col];
        return self;
    };
}

@end

// ---------------------------------------------------
// ---------------------------------------------------
#pragma mark - PPSQLUpdate
// ---------------------------------------------------
@interface PPSQLUpdate ()

@end

@implementation PPSQLUpdate
INIT_WITH_MSTRING

- (id<RTSubSQLProtocol> (^)(NSString *))add {
    return ^(NSString *args) {
        [self.mStrResult appendString:args];
        return self;
    };
}

- (NSString *)build {
    return self.mStrResult.copy;
}

- (PPSQLUpdate *(^)(NSString *))column {
    return ^(NSString *col) {
        NSAssert(col && col.length > 0, @"Column can not be empty!");
        
        NSString *format = @", %@ = ?";
        if (self.mStrResult.length == 0) {
            format = @"%@ = ?";
        }
        [self.mStrResult appendFormat:format, col];
        return self;
    };
}
@end


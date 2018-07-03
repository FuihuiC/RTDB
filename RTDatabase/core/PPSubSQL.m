//
//  PPSubSQL.m
//  RTDatabase
//
//  Created by hc-jim on 2018/7/3.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "PPSubSQL.h"


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

- (id<PPSQLProtocol> (^)(NSString *))add {
    return ^(NSString *args) {
        [self.mStrResult appendFormat:@" %@", args];
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

- (id<PPSQLProtocol> (^)(NSString *))add {
    return ^(NSString *args) {
        [self.mStrResult appendFormat:@" %@", args];
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

- (id<PPSQLProtocol> (^)(NSString *))add {
    return ^(NSString *args) {
        [self.mStrResult appendFormat:@" %@", args];
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


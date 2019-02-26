//
//  PPColumns.m
//  RTDatabase
//
//  Created by ENUUI on 2018/7/16.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "PPColumns.h"

@interface PPColumns ()

@property (nonatomic, assign) NSUInteger type;
@property (nonatomic, strong) NSMutableArray <NSString *>*mArrColumns;
@property (nonatomic, strong) NSMutableDictionary *mDicColumns;

@property (nonatomic, strong) NSMutableString *mStrResult;
@end
@implementation PPColumns

- (instancetype)initWithType:(NSUInteger)type {
    if (self = [super init]) {
        self.type = type;
    }
    return self;
}

- (NSMutableArray<NSString *> *)mArrColumns {
    if (_mArrColumns == nil) {
        _mArrColumns = [NSMutableArray<NSString *> array];
    }
    return _mArrColumns;
}

- (NSMutableDictionary *)mDicColumns {
    if (_mDicColumns == nil) {
        _mDicColumns = [NSMutableDictionary dictionary];
    }
    return _mDicColumns;
}


// ---------------------------------------------------------
- (PPColumns *(^)(id))column {
    return ^(id col) {
        if (col == nil) {
            return self;
        }
        
        [self appendColumn:col];
        return self;
    };
}


- (void)appendColumn:(id)col {
    if ([col isKindOfClass:[NSString class]]) {
        [self.mArrColumns addObject:col];
    } else if ([col isKindOfClass:[NSArray class]]) {
        [self.mArrColumns addObjectsFromArray:col];
    } else if ([col isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)col;
        if (self.type == 1) {
            [self.mDicColumns addEntriesFromDictionary:dict];
        } else {
            [self.mArrColumns addObjectsFromArray:dict.allKeys];
        }
    }
}

#pragma mark build
// ---------------------------------------------------------
- (NSString *)build {
    NSString *result;
    switch (self.type) {
        case 1: { // Create
            result = [self buildCreateColumns];
        }
            break;
        case 2: { // Select
            result = [self buildSelectColumns];
        }
            break;
        case 3: { // Insert
            result = [self buildInsertColumns];
        }
            break;
        case 4: { // Update
            result = [self buildUpdateColumns];
        }
            break;
        default:
            break;
    }
    return result;
}

- (NSString *)buildSelectColumns {
    if (!_mArrColumns || _mArrColumns.count == 0) {
        return @"";
    }
    return [_mArrColumns componentsJoinedByString:@", "];
}

- (NSString *)buildUpdateColumns {
    if (!_mArrColumns || _mArrColumns.count == 0) {
        return @"";
    }
    return [NSString stringWithFormat:@"%@ = ?", [_mArrColumns componentsJoinedByString:@" = ?, "]];
}

- (NSString *)buildInsertColumns {
    if (!_mArrColumns || _mArrColumns.count == 0) {
        return @"";
    }
    NSString *cols = [_mArrColumns componentsJoinedByString:@", "];
    NSString *vals = [_mArrColumns componentsJoinedByString:@", :"];
    return [NSString stringWithFormat:@"(%@) VALUES (:%@)", cols, vals];
}

- (NSString *)buildCreateColumns {
    NSMutableArray *mArr = [NSMutableArray arrayWithCapacity:(_mDicColumns.count + _mArrColumns.count)];
    
    if (_mDicColumns && _mDicColumns.count > 0) {
        NSArray *arrKeys = _mDicColumns.allKeys;
        for (int i = 0; i < arrKeys.count; i++) {
            NSString *key = arrKeys[i];
            NSString *value = _mDicColumns[key];
            [mArr addObject:[NSString stringWithFormat:@"'%@' '%@'", key, value]];
        }
    }
    
    if (_mArrColumns && _mArrColumns.count > 0) {
        [mArr addObjectsFromArray:_mArrColumns];
    }

    if (mArr.count > 0) {
        NSString *result = [mArr componentsJoinedByString:@", "];
        return [NSString stringWithFormat:@"(%@)", result];
    } else return @"";
}

// ---------------------------------------
- (PPColumns *(^)(NSString *))TEXT {
    return ^(NSString *col) {
        if (!col) return self;
        [self.mArrColumns addObject:[NSString stringWithFormat:@"'%@' 'TEXT'", col]];
        return self;
    };
}

- (PPColumns *(^)(NSString *))INTEGER {
    return ^(NSString *col) {
        if (!col) return self;
        [self.mArrColumns addObject:[NSString stringWithFormat:@"'%@' 'INTEGER'", col]];
        return self;
    };
}

- (PPColumns *(^)(NSString *))BLOB {
    return ^(NSString *col) {
        if (!col) return self;
        [self.mArrColumns addObject:[NSString stringWithFormat:@"'%@' 'BLOB'", col]];
        return self;
    };
}

- (PPColumns *(^)(NSString *))REAL {
    return ^(NSString *col) {
        if (!col) return self;
        [self.mArrColumns addObject:[NSString stringWithFormat:@"'%@' 'REAL'", col]];
        return self;
    };
}

- (PPColumns *)notNull {
    [self appendAtLastWithQuery:@"NOT NULL"];
    return self;
}

- (PPColumns *)primaryKey {
    [self appendAtLastWithQuery:@"primary key"];
    return self;
}

- (PPColumns *)autoincrement {
    [self appendAtLastWithQuery:@"autoincrement"];
    return self;
}

- (void)appendAtLastWithQuery:(NSString *)query {
    if (_mArrColumns.count > 0) {
        NSString *column = _mArrColumns.lastObject;
        NSString *result = [column stringByAppendingFormat:@" %@", query];
        [_mArrColumns replaceObjectAtIndex:(_mArrColumns.count - 1) withObject:result];
    }
}
@end

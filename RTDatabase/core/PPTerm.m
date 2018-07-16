//
//  PPTerm.m
//  RTDatabase
//
//  Created by ENUUI on 2018/7/3.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import "PPTerm.h"

// ---------------------------------------------------
// ---------------------------------------------------
#pragma mark - PPTerm
// ---------------------------------------------------
@implementation PPTerm
INIT_WITH_MSTRING

- (PPTerm *(^)(NSString *))add {
    return ^(NSString *args) {
        [self.mStrResult appendFormat:@" %@", args];
        return self;
    };
}

- (NSString *)build {
    return self.mStrResult.copy;
}

// match
- (PPTerm *)like {
    [self.mStrResult appendString:@" LIKE"];
    return self;
}

- (PPTerm *)GLOB {
    [self.mStrResult appendString:@" GLOB"];
    return self;
}

// where
- (PPTerm *)where {
    [self.mStrResult appendString:@" WHERE"];
    return self;
}

// limit
- (PPTerm *(^)(NSUInteger))limit {
    return ^(NSUInteger no) {
        [self.mStrResult appendFormat:@" limit %lu", (unsigned long)no];
        return self;
    };
}

// order by
- (PPTerm *(^)(NSString *))orderBy {
    return ^(NSString *col) {
        NSString *format = @", %@";
        if (![self.mStrResult containsString:@"ORDER BY"]) {
            format = @" ORDER BY %@";
        }
        [self.mStrResult appendFormat:format, col];
        return self;
    };
}

- (PPTerm *(^)(NSString *, ...))ordersBy {
    return ^(NSString *col, ...) {
        va_list ap;
        va_start(ap, col);
        [self appendColumns:ap withFirst:col withOrder:@"ORDER BY"];
        va_end(ap);
        
        return self;
    };
}

- (PPTerm *)desc { // Descending order
    return self.add(@" DESC");
}
- (PPTerm *)asc { // Ascending order
    return self.add(@" ASC");
}

// GROUP BY
- (PPTerm *(^)(NSString *))groupBy {
    return ^(NSString *column) {
        NSString *format = @", %@";
        if (![self.mStrResult containsString:@"GROUP BY"]) {
            format = @" GROUP BY %@";
        }
        [self.mStrResult appendFormat:format, column];
        return self;
    };
}

- (PPTerm *(^)(NSString *, ...))groupBys {
    return ^(NSString *col, ...) {
        va_list ap;
        va_start(ap, col);
        [self appendColumns:ap withFirst:col withOrder:@"GROUP BY"];
        va_end(ap);
        return self;
    };
}

// having
- (PPTerm *)having {
    [self.mStrResult appendString:@" HAVING"];
    return self;
}


- (PPTerm *(^)(NSString *, ...))condition {
    return ^(NSString *format, ...) {
        va_list ap;
        va_start(ap, format);
        NSString *result = [[NSString alloc] initWithFormat:format arguments:ap];
        va_end(ap);
        
        [self.mStrResult appendFormat: @" %@", result];
        return self;
    };
}

- (PPTerm *(^)(NSString *, id))equal { // =
    return ^(NSString *key, id value) {
        [self.mStrResult appendFormat:@" %@ = %@", key, value];
        return self;
    };
}

- (PPTerm *(^)(NSString *, id))more { // >
    return ^(NSString *key, id value) {
        [self.mStrResult appendFormat:@" %@ > %@", key, value];
        return self;
    };
}

- (PPTerm *(^)(NSString *, id))less { // <
    return ^(NSString *key, id value) {
        [self.mStrResult appendFormat:@" %@ < %@", key, value];
        return self;
    };
}

- (PPTerm *(^)(NSString *, id))moreOrEquel { // >=
    return ^(NSString *key, id value) {
        [self.mStrResult appendFormat:@" %@ >= %@", key, value];
        return self;
    };
}

- (PPTerm *(^)(NSString *, id))lessOrEquel { // <=
    return ^(NSString *key, id value) {
        [self.mStrResult appendFormat:@" %@ <= %@", key, value];
        return self;
    };
}

- (PPTerm *)AND {
    return self.add(@"AND");
}

- (PPTerm *)OR {
    return self.add(@"OR");
}

// ---------------------
- (void)appendColumns:(va_list)ap withFirst:(NSString *)col withOrder:(NSString *)order {
    NSString *columns = [self appendColumns:ap];
    
    NSString *format = @" %@%@";
    if (![self.mStrResult containsString:order]) {
        format = @" %@ %@%@";
    }
    
    [self.mStrResult appendFormat:format, order, col, columns];
}

- (NSString *)appendColumns:(va_list)ap {
    NSMutableString *mStrTemp = [NSMutableString string];
    for (NSString *aCol = va_arg(ap, NSString *); aCol != nil; aCol = va_arg(ap, NSString *)) {
        [mStrTemp appendFormat:@", %@", aCol];
    }
    return mStrTemp.copy;
}
@end

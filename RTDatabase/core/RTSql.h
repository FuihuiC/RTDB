//
//  RTSql.h
//  RTDatabase
//
//  Created by ENUUI on 2018/6/29.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RTPreset.h"

@class RTSql;
typedef RTSql *(^RTSQLBuildBlock)(NSString *);

@interface RTSql : NSObject

- (RTSql *(^)(NSString *))append;

// CREATE
- (RTSql *(^)(NSString *))CREATE;
- (RTSql *(^)(NSString *))columnINTEGER;
- (RTSql *(^)(NSString *))columnTEXT;
- (RTSql *(^)(NSString *))columnBLOB;
- (RTSql *(^)(NSString *))columnREAL;

- (RTSql *(^)(NSString *))SELECT;
- (RTSql *(^)(NSString *))UPDATE;
- (RTSql *(^)(NSString *, ...))INSERT;
- (RTSql *(^)(NSString *))DELETE;

- (RTSql *(^)(NSString *))or_;
- (RTSql *(^)(NSString *))and_;
- (RTSql *(^)(NSString *))like;
- (RTSql *(^)(NSString *))glob;
- (RTSql *(^)(NSString *))where;
- (RTSql *(^)(NSString *))orderBy;
- (RTSql *)desc; // 降序
- (RTSql *)asc;  // 升序

- (RTSql *(^)(NSInteger))limit;
- (RTSql *(^)(NSString *))groupBy;
- (RTSql *(^)(NSString *))having;
- (RTSql *(^)(NSString *))distinct;

- (RTSql *(^)(NSString *))from;

// ------ type --------
- (RTSql *)integer;
- (RTSql *)text;
- (RTSql *)blob;
- (RTSql *)real;

// ------ interpunction --------
//brackets
- (RTSql *)leftBracket;
- (RTSql *)rightBracket;

// comma
- (RTSql *)comma;
// asterisk
- (RTSql *)asterisk;
- (RTSql *(^)(NSString *))quotes;

- (NSString *)end;
- (RTSql *)reset;
@end

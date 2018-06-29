//
//  RTDatabase.h
//  RTDatabase
//
//  Created by ENUUI on 2018/5/13.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for RTDatabase.
FOUNDATION_EXPORT double RTDatabaseVersionNumber;

//! Project version string for RTDatabase.
FOUNDATION_EXPORT const unsigned char RTDatabaseVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <RTDatabase/PublicHeader.h>

#if OS_OBJECT_USE_OBJC
#import <RTDatabase/RTSDB.h>
#else
#import <RTDatabase/RTDB.h>
#endif

#import <RTDatabase/RTSql.h>

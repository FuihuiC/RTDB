//
//  RTPreset.h
//  RTSQLite
//
//  Created by ENUUI on 2018/5/3.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#ifndef RTPreset_h
#define RTPreset_h

#ifndef RT_EXTERN
#define RT_EXTERN extern
#endif



#ifndef DELog
#   ifdef DEBUG
#    define DELog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#   else
#       define DELog(...)
#   endif
#endif

#ifndef rt_printf
#   ifdef DEBUG
#       define rt_printf(...) printf(__VA_ARGS__);
#   else
#       define rt_printf(...)
#   endif
#endif

#endif /* RTPreset_h */

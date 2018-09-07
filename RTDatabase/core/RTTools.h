//
//  RTTools.h
//  RTDatabase
//
//  Created by hc-jim on 2018/7/16.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#ifndef RTTools_h
#define RTTools_h

#import "RTPreset.h"

#define RT_SQLITE_ERROR 0
#define RT_SQLITE_OK 1
#define RT_SQLITE_DONE 2
#define RT_SQLITE_ROW 3


/** flags for rt_sqlite3_open third arg. */
/** Set up database connection running in multi thread mode (without specifying single thread mode) */
#define RT_SQLITE_OPEN_NOMUTEX          0x00008000
/** Set the database connection to run in serial mode */
#define RT_SQLITE_OPEN_FULLMUTEX        0x00010000

#define RT_SQLITE_OPEN_SHAREDCACHE      0x00020000
#define RT_SQLITE_OPEN_PRIVATECACHE     0x00040000

#define RT_SQLITE_OPEN_READONLY         0x00000001
#define RT_SQLITE_OPEN_READWRITE        0x00000002
#define RT_SQLITE_OPEN_CREATE           0x00000004
/**
 * If URI filename interpretation is enabled,
 * and the filename argument begins with "file:"
 * then the filename is interpreted as a URI.
 */
#define RT_SQLITE_OPEN_URI              0x00000040
#define RT_SQLITE_OPEN_MEMORY           0x00000080

#define RT_SQLITE_OPEN_FILEPROTECTION_COMPLETE                             0x00100000
#define RT_SQLITE_OPEN_FILEPROTECTION_COMPLETEUNLESSOPEN                   0x00200000
#define RT_SQLITE_OPEN_FILEPROTECTION_COMPLETEUNTILFIRSTUSERAUTHENTICATION 0x00300000
#define RT_SQLITE_OPEN_FILEPROTECTION_NONE                                 0x00400000
#define RT_SQLITE_OPEN_FILEPROTECTION_MASK                                 0x00700000


#endif /* RTTools_h */



@class NSString, NSError;


typedef void(^rt_operator_b)(void);

typedef const char rt_char_t;

typedef enum : char {
    rttext   = 'T', // string
    rtblob   = 'D', // data
    rtnumber = 'N', // number
    
    // float
    rtfloat  = 'f', // float
    rtdouble = 'd', // double
    rtdate   = '#', // NSDate: converted to double
    
    // integer
    rtchar   = 'c', // char
    rtuchar  = 'C', // unsigned char
    rtshort  = 's', // short
    rtushort = 'S', // unsigned short
    rtint    = 'i', // int
    rtuint   = 'I', // unsigned int
    rtlong   = 'q', // long
    rtulong  = 'Q', // unsigned long
    rtbool   = 'B'  // BOOL
} rt_objc_t;

static size_t char_len = sizeof(char);

#pragma mark - FUNCTION
/**
 * error
 * 101: empty sql string.
 * 102: parameter error
 * 103: class info error
 * 104: object empty
 * 105: primety key _id error
 * 106: operate error
 * 107: info from sql error
 * 108: column error
 * 109: block empty
 * 110: transaction error
 *
 * >=10000: error by sqlite3
 */
RT_EXTERN void rt_error(
                        NSString *errMsg, /* message */
                        int code,         /* err code */
                        NSError **err     /* OUT: NSError */
);


RT_EXTERN rt_objc_t rt_object_class_type(id obj);

/** Get the number of digits of integer */
RT_EXTERN int rt_integer_digit(long long n);
/** Whether two strings are equal */
RT_EXTERN int rt_str_compare(rt_char_t *src1, rt_char_t *src2);
/** mutable a const char * */
RT_EXTERN char *rt_str_mutable(const char *src);

typedef struct RT_PRO_INFO rt_pro_info;
typedef struct RT_PRO_INFO * rt_pro_info_p;
typedef void(^rt_rpoInfo_block_t)(rt_pro_info *pro);

/** struct for saving property info */
struct RT_PRO_INFO {
    int idx;           // index
    rt_objc_t t;       // type
    rt_char_t *name;   // property name
    rt_pro_info *next; // next info pointer
};

/** build a property info struct */
RT_EXTERN rt_pro_info *rt_make_info(int idx, rt_objc_t t, rt_char_t *name);

/** insert a new property info struct at last */
RT_EXTERN void rt_info_append(
                              rt_pro_info_p *infos, /* Singly Linked List saved property infoes */
                              rt_pro_info *next     /* new property info struct */
);

/** get the property info at an index */
RT_EXTERN rt_pro_info *rt_info_at_idx(
                                      rt_pro_info *infos,
                                      int idx
                                      );

/** Get the info by name. */
RT_EXTERN rt_pro_info *rt_info_by_name(
                                       rt_pro_info *infos,
                                       rt_char_t *name
                                       );

/** Sequence traverses the linked list. If block exists, callback every node. */
RT_EXTERN void rt_enum_info(
                            rt_pro_info *proInfo,
                            rt_rpoInfo_block_t block
                            );

/** Assign the type in infos1 to infos2 according to proName */
RT_EXTERN int rt_pro_t_assign(rt_pro_info *infos1, rt_pro_info_p *infos2, char **errMsg);

/** free Singly Linked List */
RT_EXTERN void rt_free_info(rt_pro_info *infos);

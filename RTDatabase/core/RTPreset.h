//
//  RTPreset.h
//  RTSQLite
//
//  Created by ENUUI on 2018/5/3.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#ifndef RTPreset_h
#define RTPreset_h

#define RT_SQLITE_ERROR 0
#define RT_SQLITE_OK 1
#define RT_SQLITE_DONE 2
#define RT_SQLITE_ROW 3


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
/** Get the number of digits of integer */
RT_EXTERN int rt_integer_digit(long long n);
/** Whether two strings are equal */
RT_EXTERN int rt_str_compare(rt_char_t *src1, rt_char_t *src2);
/** mutable a const char * */
RT_EXTERN char *rt_str_mutable(const char *src);

/**
 * The two strings are stitching together and the result of the splicing is returned.
 * After the end of the use, free is needed.
 */
RT_EXTERN char *rt_strcat(char *str1, char *str2) ;

/** Stitching strings together */
RT_EXTERN void rt_str_append(
  char **dest, /* Stitching result pointer */
  int count,   /* Number of strings to be spliced*/
  ...          /* Indeterminate parameter. char * */
);


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
RT_EXTERN void rt_free_info(rt_pro_info_p *infos);

#endif /* RTPreset_h */

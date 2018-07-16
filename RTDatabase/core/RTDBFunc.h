//
//  RTDBFunc.h
//  RTSQLite
//
//  Created by ENUUI on 2018/5/3.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTTools.h"

typedef void(^rt_column_enum_block_t)(const char *cname, id value);


/** sqlite3 result code to RT status code */
RT_EXTERN int rt_sqlite3_status_code(int sqlite3_code);
/** sqlite3 type to RT type */
RT_EXTERN rt_objc_t rt_type_from_sqlite(int sqType);


/** get sqlite3's error msg */
RT_EXTERN void rt_sqlite3_err(
  int result,    /* sqlite3 result */
  NSError **err  /* OUT: NSError */
);

/**
 * Opening A New Database Connection
 * flags: SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_NOMUTEX | SQLITE_OPEN_SHAREDCACHE
 */
RT_EXTERN bool rt_sqlite3_open(
  void **db,      /* OUT: SQLite db handle */
  NSString *path, /* Database filename */
  int flags,       
  NSError **err   /* OUT: NSError */
);

/** close db */
RT_EXTERN bool rt_sqlite3_close(void *db);

/** One-Step Query Execution Interface */
RT_EXTERN int rt_sqlite3_exec(
  void *db,       /* Database handle */
  rt_char_t *sql, /* SQL statement, utf8 */
  NSError **err   /* OUT: Error msg */
);

/**
 * Compiling An SQL Statement
 * Return succeed or not.
 */
RT_EXTERN bool rt_sqlite3_prepare_v2(
  void *db,       /* Database handle */
  rt_char_t *sql, /* SQL statement, utf8 */
  void **ppStmt,  /* OUT: Statement handle */
  NSError **err   /* OUT: Error msg */
);

/**
 * Evaluate An SQL Statement
 * RETURN:
 * RT_SQLITE_ERROR 0: see err msg
 * RT_SQLITE_OK 1: success
 * RT_SQLITE_DONE 2: sqlite3_step() has finished executing 
 * RT_SQLITE_ROW 3: qlite3_step() has another row ready
 */
RT_EXTERN int rt_sqlite3_step(
  void *stmt,   /* a pointer to the [sqlite3_stmt] object returned from [sqlite3_prepare_v2()] or its variants */
  NSError **err /* OUT: Error msg */
);

/** primary id */
RT_EXTERN NSInteger rt_get_primary_id(void *db, rt_char_t *sql, NSError **err);

/**
 * Binding Values To Prepared Statements
 * return [SQLITE_OK] on success or an [error code] if anything goes wrong
 */
RT_EXTERN int rt_sqlite3_bind(
  void *stmt,    /* a pointer to the [sqlite3_stmt] object returned from [sqlite3_prepare_v2()] or its variants */
  int idx,       /* the index of the SQL parameter to be set */
  id value,      /* the value to bind to the parameter */
  rt_objc_t objT /* objT the type of the value */
);

/**
 * Result Values From A Query
 * return the value of the column
 */
RT_EXTERN id rt_sqlite3_column(
  void *stmt,    /* a pointer to the [sqlite3_stmt] object returned from [sqlite3_prepare_v2()] or its variants */
  int idx,       /* the index of the SQL parameter to be set */
  rt_objc_t objT /* objT the type of the value */
);

/**
 * Result Values From A Query
 * return the value of the column
 */
RT_EXTERN id rt_sqlite3_value(
  void *stmt, /* a pointer to the [sqlite3_stmt] object returned from [sqlite3_prepare_v2()] or its variants */
  int idx     /* the index of the SQL parameter to be set */
);

RT_EXTERN rt_char_t *rt_sqlite3_table_name(void *stmt);
/* Destroy A Prepared Statement Object */
RT_EXTERN void rt_sqlite3_finalize(void **stmt);


#pragma mark -
//////////////////////////
//////////////////////////
//////////////////////////
#pragma mark column
RT_EXTERN void rt_column_enum(void *stmt, rt_pro_info *proInfo, rt_column_enum_block_t block);
RT_EXTERN Class rt_column_class(void *stmt);
RT_EXTERN rt_objc_t rt_column_type(void *stmt, int idx);

/** get columns name and idx. */
RT_EXTERN rt_pro_info *rt_column_pro_info(
  void *stmt, /* a pointer to the [sqlite3_stmt] object returned from [sqlite3_prepare_v2()] or its variants */
  int *count  /* OUT: column count */
);

RT_EXTERN rt_char_t *rt_sqlite3_column_name(void *stmt, int N);
RT_EXTERN int rt_sqlite3_column_count(void *stmt);

#pragma mark bind
RT_EXTERN rt_pro_info *rt_sqlite3_bind_info(void *stmt, int *outCount);
RT_EXTERN rt_char_t *rt_sqlite3_bind_parameter_name(void *stmt, int idx);
RT_EXTERN int rt_sqlite3_bind_param_index(void *stmt, rt_char_t *name);
RT_EXTERN int rt_sqlite3_bind_parameter_count(void *stmt);

//
//  RTTools.m
//  RTSQLite
//
//  Created by ENUUI on 2018/5/5.
//  Copyright © 2018年 ENUUI. All rights reserved.
//

#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#import "RTPreset.h"


// Get the number of digits of integer
int rt_integer_digit(long long n) {
    long long i = n;
    int m = 0;
    while (i) {
        m++;
        i /= 10;
    }
    return m;
}

// Whether two strings are equal
int rt_str_compare(rt_char_t *src1, rt_char_t *src2) {
    return (strcmp(src1, src2) == 0);
}

// mutable a const char
char *rt_str_mutable(const char *src) {
    if (src == NULL) {
        return NULL;
    }
    unsigned long src_len = strlen(src);
    char *result = malloc((src_len + 1) * sizeof(char));
    memmove(result, src, src_len);
    memmove(result + src_len, "\0", sizeof(char));
    return result;
}

// The two strings are stitching together and the result of the splicing is returned.
char *rt_strcat(char *str1, char *str2) {
    
    unsigned long len_1 = 0;
    unsigned long len_2 = 0;
    if (str1 != NULL) {
        len_1 = strlen(str1);
    }
    if (str2 != NULL) {
        len_2 = strlen(str2);
    }
    
    char *result = NULL;
    if (len_1 + len_2 == 0) {
        return NULL;
    }
    
    result = (char *)malloc((len_1 + len_2 + 1) * sizeof(char));
    
    if (len_1 > 0) {
        memmove(result, str1, len_1);
        memmove(result + len_1, "\0", sizeof(char));
    }
    
    if (len_2 > 0) {
        memmove(result + len_1, str2, len_2);
        memmove(result + len_1 + len_2, "\0", sizeof(char));
    }
    return result;
}

void rt_str_append_v(char **dest, ...) {
    if (dest == NULL) return;
    
    size_t char_len = sizeof(char);
    size_t len = 0;
    
    va_list ap;
    va_start(ap, dest);
    
    if (*dest != NULL) {
        len += strlen(*dest);
    }
    
    size_t src_len = 0;
    
    for (char *src = va_arg(ap, char *); src != NULL; src = va_arg(ap, char *)) {
        src_len = strlen(src);
        *dest = realloc(*dest, (len + src_len) * char_len);
        memmove(*dest + len, src, src_len);
        len += src_len;
    }
    va_end(ap);
    
    *dest = realloc(*dest, (len + 1) * char_len);
    memmove(*dest + len, "\0", char_len);
}

/////////////////////////////
/////////////////////////////
/////////////////////////////
//---------------------------------------------------------------
rt_pro_info *rt_make_info(int idx, rt_objc_t t, rt_char_t *name) {
    rt_pro_info *info = (rt_pro_info *)malloc(sizeof(rt_pro_info));
    info->idx  = idx;
    info->t    = t;
    info->name = name;
    info->next = NULL;
    return info;
}

void rt_info_append(rt_pro_info_p *infos, rt_pro_info *next) {
    if (*infos == NULL) {
        if (next != NULL) {
            *infos = next;
        }
    } else {
        rt_pro_info *temp = *infos;;
        while (1) {
            if (temp->next == NULL) {
                temp->next = next;
                break;
            } else {
                temp = temp->next;
            }
        }
    }
}

rt_pro_info *rt_info_at_idx(rt_pro_info *infos, int idx) {
    if (infos->idx == idx) {
        return infos;
    } else {
        if (infos->next != NULL) {
            return rt_info_at_idx(infos->next, idx);
        } else return NULL;
    }
}

rt_pro_info *rt_info_by_name(rt_pro_info *infos, rt_char_t *name) {
    if (rt_str_compare(infos->name, name)) {
        return infos;
    } else {
        if (infos->next != NULL) {
            return rt_info_by_name(infos->next, name);
        } else return NULL;
    }
}

void rt_enum_info(rt_pro_info *proInfo, rt_rpoInfo_block_t block) {
    if (!block) return;
    
    if (proInfo == NULL) {
        block(NULL);
    } else {
        rt_pro_info *temp = proInfo;
        while (temp) {
            block(temp);
            temp = temp->next;
        }
    }
}

int rt_pro_t_assign(rt_pro_info *infos1, rt_pro_info_p *infos2, char **errMsg) {
    
    if (infos1 == NULL && errMsg != NULL) {
        *errMsg = "RTDB recieve a empty infos1";
        return 0;
    }
    
    if (*infos2 == NULL && errMsg != NULL) {
        *errMsg = "RTDB recieve a empty infos2";
        return 0;
    }
    
    rt_enum_info(*infos2, ^(rt_pro_info *pro) {
        rt_pro_info *i = rt_info_by_name(infos1, pro->name);
        if (i != NULL) {
            pro->t = i->t;
        }
    });
    return 1;
}

void rt_free_info(rt_pro_info *infos) {
    if (infos == NULL) return;
    
    rt_free_info(infos->next);
    
    free(infos);
    infos = 0x00;
}

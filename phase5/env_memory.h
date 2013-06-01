/* This library is for the functions of the enviroment's
   memory  (stack and constant arrays) */

#include "memory_manager.h"

#define AVM_STACK_ENV_SIZE 4

/* The main registers of the AVM */
extern avm_memcell ax, bx, cx;
extern avm_memcell retval;

/* The stack pointers */
extern unsigned int top, topsp;

/* The functions that retrieve values
   from the constants arrays */
double consts_getdouble(unsigned int);
int consts_getint(unsigned int);
char * libfuncs_getused(unsigned int);
char * consts_getstr(unsigned int);
userfunc_s * userfuncs_getfunc(unsigned int);
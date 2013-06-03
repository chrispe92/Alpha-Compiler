#ifndef ENV_MEM_LIB
#include "../env_memory.h"
#endif

#ifndef DISPATCHER
#include "../dispatcher.h"
#endif

typedef unsigned char (*tobool_func_t)(avm_memcell *);
extern tobool_func_t to_bool_funcs[];

typedef unsigned char (*cmp_func)(double,double);
extern cmp_func cmp_functions[];

unsigned char is_greater(double, double);
unsigned char is_greatereq(double,double);
unsigned char is_less(double,double);
unsigned char is_less_eq(double,double);

unsigned char double_tobool(avm_memcell *);
unsigned char int_tobool(avm_memcell *);
unsigned char string_tobool(avm_memcell *);
unsigned char bool_tobool(avm_memcell *);
unsigned char table_tobool(avm_memcell *);
unsigned char userfunc_tobool(avm_memcell *);
unsigned char libfunc_tobool(avm_memcell *);
unsigned char nil_tobool(avm_memcell *);
unsigned char undef_tobool(avm_memcell *);

unsigned char avm_tobool(avm_memcell *m);

void execute_jeq (instr_s * instr);
void execute_jump(instr_s *);
char is_num_type(avm_memcell_t type);
void execute_cmp(instr_s * instr);
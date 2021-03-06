#include "tc_generator.h"

/* The expandable arrays for the constants of the code */

// For the number constants 
double * double_consts = NULL;
unsigned int current_double_index = 0;
unsigned int total_double_consts = 0;

// For the integer number constants
int * integer_consts = NULL;
unsigned int current_int_index = 0;
unsigned int total_integer_consts = 0;

// For the strings
char ** str_consts = NULL;
unsigned int current_str_index = 0;
unsigned int total_str_consts = 0;

// For the library functions
char ** named_lib_funcs = NULL;
unsigned int current_lib_func_index = 0;
unsigned int total_named_lib_funcs = 0;

// For the user functions
userfunc_s * user_funcs = NULL;
unsigned int current_user_func_index = 0;
unsigned int total_user_funcs = 0;

/* The list for the incomplete jumps */
incomplete_jump * i_jumps = NULL;
unsigned int i_jumps_total = 0;

/* The array that will include 
   the final target instructions. */
instr_s * instructions = NULL;
unsigned int current_instr_index = 0;
unsigned int total_instructions = 0;

/* The stack used to save functions
   during the target code generation. */
func_stack * funcs = NULL;
 
/* The current quad we are processing
   for the target code generation  */
unsigned int current_quad;

/* Counts the function scope for
   shadowing functions */
unsigned int current_func_scope = 0;

generator_func_t generators[] = {
	generate_ASSIGN,
	generate_ADD,
	generate_SUB,
	generate_MUL,
	generate_DIV,
	generate_MOD,
	generate_UMINUS,
	generate_AND,
	generate_OR,
	generate_NOT,
	generate_IF_EQ,
	generate_IF_NOTEQ,
	generate_IF_LESSEQ,
	generate_IF_GREATEREQ,
	generate_IF_LESS,
	generate_IF_GREATER,
	generate_CALL,
	generate_PARAM,
	generate_RETURN,
	generate_GETRETVAL,
	generate_FUNCSTART,
	generate_FUNCEND,
	generate_JUMP,
	generate_NEWTABLE,
	generate_TABLEGETELEM,
	generate_TABLESETELEM,
	generate_NOP
};
 
unsigned int add_const_to_array(void * constant,const_t type){
	unsigned int value_index;
	value_index = value_exists_in_arr(constant,type);
	if(value_index!=-1)
		return(value_index);

	switch(type){
		case double_c:{
			if(current_double_index == total_double_consts)
				expand_const_array(type);
			double * current_double = double_consts + current_double_index++;
			*current_double = *((double *)(constant));
			return(current_double_index-1);
		}
		case int_c:{
			if(current_int_index == total_integer_consts)
				expand_const_array(type);
			int * current_int = integer_consts + current_int_index++;
			*current_int = *((int *)(constant));
			return(current_int_index-1);
		}
		case str_c:{
			if(current_str_index == total_str_consts)
			expand_const_array(type);
			char *  current_str = malloc(strlen((char*)constant)+1);
			strcpy(current_str,(char*)constant);
			str_consts[current_str_index++] = current_str;
			return(current_str_index-1);
		}
		case user_func_c:{
			if(current_user_func_index == total_user_funcs)
				expand_const_array(type);
			userfunc_s * current_user_func = user_funcs + current_user_func_index++;
			current_user_func->address = ((userfunc_s *)constant)->address;
			current_user_func->local_size = ((userfunc_s *)constant)->local_size;
			current_user_func->name = malloc(strlen(((userfunc_s *)constant)->name)+1);
			current_user_func->scope = current_func_scope;
			strcpy(current_user_func->name,((userfunc_s *)constant)->name);
			return(current_user_func_index-1);
		}
		case lib_func_c:{
			if(current_lib_func_index == total_named_lib_funcs)
				expand_const_array(type);
			char * current_lib_func = malloc(strlen((char *)constant)+1);
			strcpy(current_lib_func,(char *)constant);
			named_lib_funcs[current_lib_func_index++] = current_lib_func;
			return(current_lib_func_index-1);
		}
		default: assert(0);
	}
}

unsigned int value_exists_in_arr(void * value, const_t type){
	int i;
	switch(type){
		case double_c:{
			for(i=0;i<current_double_index;i++){
				if(double_consts[i]==*((double *)value))return i;
			}
			break;
		}
		case int_c:{
			for(i=0;i<current_int_index;i++){
				if(integer_consts[i]==*((int *)value))return i;
			}
			break;
		}
		case str_c:{
			for(i=0;i<current_str_index;i++){
				if(strcmp(str_consts[i],(char *)value)==0)return i;
			}
			break;
		}
		case user_func_c:{
			for(i=current_user_func_index-1;i>=0;i--){
				if(strcmp((user_funcs[i]).name,(char *)value)==0 && user_funcs[i].scope<=current_func_scope)
					return i;
			}
			break;
		}
		case lib_func_c:{
			for(i=0;i<current_lib_func_index;i++){
				if(strcmp(named_lib_funcs[i],(char *)value)==0)return i;
			}
			break;
		}
		default: assert(0);
	}
	return -1;
}

void expand_const_array(const_t array_type){
	switch(array_type){
		case double_c:{
			double * new_double_arr = (double *)malloc(DOUBLE_ARR_NEW_SIZE);
			memcheck(new_double_arr,"new_double_array");
			memcpy(new_double_arr,double_consts,DOUBLE_ARR_SIZE);
			double_consts = new_double_arr;
			total_double_consts += EXPAND_SIZE;
			break;
		}
		case int_c:{
			int * new_int_arr = (int *)malloc(INTGER_ARR_NEW_SIZE);
			memcheck(new_int_arr,"new integer array");
			memcpy(new_int_arr,integer_consts,INTEGER_ARR_SIZE);
			integer_consts = new_int_arr;
			total_integer_consts += EXPAND_SIZE;
			break;
		}
		case str_c:{
			char ** new_str_arr = (char **)malloc(STRING_ARR_NEW_SIZE);
			memcheck(new_str_arr,"new string array");
			memcpy(new_str_arr,str_consts,STRING_ARR_SIZE);
			str_consts = new_str_arr;
			total_str_consts += EXPAND_SIZE;
			break;
		}
		case user_func_c:{
			userfunc_s * new_user_func_arr = (userfunc_s *)malloc(USER_FUNC_ARR_NEW_SIZE);
			memcheck(new_user_func_arr,"new user func array");
			memcpy(new_user_func_arr,user_funcs,USER_FUNC_ARR_SIZE);
			user_funcs = new_user_func_arr;
			total_user_funcs += EXPAND_SIZE;
			break;
		}
		case lib_func_c:{
			char ** new_lib_func_arr = (char **)malloc(LIB_FUNC_ARR_NEW_SIZE);
			memcheck(new_lib_func_arr,"new lib func array");
			memcpy(new_lib_func_arr,named_lib_funcs,LIB_FUNC_ARR_SIZE);
			named_lib_funcs = new_lib_func_arr;
			total_named_lib_funcs += EXPAND_SIZE;
			break;
		}
		default: assert(0);
	}
}

vmarg_s * create_vmarg(void){
	vmarg_s * new_vmarg = malloc(sizeof(vmarg_s));
	memcheck(new_vmarg,"new vmarg");
	new_vmarg->name = NULL;
	return(new_vmarg);
}
 
instr_s * create_instr(void){
	instr_s * new_instr = malloc(sizeof(instr_s));
	memcheck(new_instr,"new instr");
	new_instr->arg1 = NULL;
	new_instr->arg2 = NULL;
	new_instr->result = NULL;
	return(new_instr);
}

vmarg_s * make_operand(expr * e, vmarg_s * arg){
	switch(e->type){
		case var_e:
		case assign_expr_e:
		case table_item_e:
		case arithm_expr_e:
		case bool_expr_e:
		case new_table_e: {
			assert(e->sym);
			arg->value = e->sym->offset;
			arg->name = malloc(strlen(e->sym->name)+1);
			memcheck(arg->name,"make_operand arg name");
			strcpy(arg->name,e->sym->name);
			switch(e->sym->space){
				case PROGRAM_VAR: arg->type = global_a;	break;
				case FUNC_LOCAL:  arg->type = local_a;	break;
				case FORMAL_ARG:  arg->type = formal_a;	break;
				default:assert(0);
			}
			break;
		}
		case const_bool_e:{
			arg->value = e->bool_value;
			arg->type = bool_a;
			break;
		}
		case const_str_e:{
			arg->value = add_const_to_array(e->str_value,str_c);
			arg->type = string_a;
			break;
		}
		case const_int_e:{
			arg->value = add_const_to_array(&(e->int_value),int_c);
			arg->type = integer_a;
			break;
		}
		case const_num_e:{
			arg->value = add_const_to_array(&(e->num_value),double_c);
			arg->type = double_a;
			break;
		}
		case nil_e:{
			arg->type = nil_a;
			break;
		}
		case program_func_e:{
			arg->type = userfunc_a;
			arg->value = add_const_to_array(e->sym->name,user_func_c);
			break;
		}
		case library_func_e:{
			arg->type = libfunc_a;
			arg->value = add_const_to_array(e->sym->name,lib_func_c);
			break;
		}
		default: assert(0);
	}
	return arg;
}

void make_double_operand(vmarg_s * arg,double * value){
	arg->value = add_const_to_array(value,double_c);
	arg->type = double_a;
}

void make_integer_operand(vmarg_s * arg,int value){
	int c = value;
	arg->value = add_const_to_array(&c,int_c);
	arg->type = integer_a;
}

void make_boolean_operand(vmarg_s * arg,unsigned int value){
	arg->value = value;
	arg->type = bool_a;
}

void make_retval_operand(vmarg_s * arg){
	arg->type = retval_a;
}

void add_incomplete_jump(unsigned int instr_id, unsigned int iaddress){
	incomplete_jump * new_jump = malloc(sizeof(incomplete_jump));
	memcheck(new_jump,"new incomplete jump");
	new_jump->instr_id = instr_id;
	new_jump->iaddress = iaddress;
	new_jump->next = i_jumps;
	i_jumps = new_jump;
}

void expand_instr_array(){
	instr_s * new_instr_arr = (instr_s *)malloc(INSTR_ARR_NEW_SIZE);
	memcheck(new_instr_arr,"new instruction array");
	memcpy(new_instr_arr,instructions,INSTR_ARR_SIZE);
	instructions = new_instr_arr;
	total_instructions += EXPAND_SIZE;
}

void patch_incomplete_jumps(){
	incomplete_jump * temp = i_jumps;
	while(temp){
		if(temp->iaddress == curr_quad)
			instructions[temp->instr_id].result->value = next_instr_label();
		else
			instructions[temp->instr_id].result->value = quads[temp->iaddress].taddress;
		temp = temp->next;
	}
}

unsigned int next_instr_label(){
	return(current_instr_index);
}

void emit_instruction(instr_s * instr){
	instr_s * new_instr = create_instr();

	if(current_instr_index == total_instructions)
		expand_instr_array();

	new_instr = instructions + current_instr_index++;
	new_instr->opcode = instr->opcode;
	new_instr->arg1 = instr->arg1;
	new_instr->arg2 = instr->arg2;
	new_instr->result = instr->result;
	new_instr->line = instr->line;	
}

void generate(vmopcode_e op, quad * q){
	instr_s * instr = create_instr();
	instr->opcode = op;

	if(q->arg1!=NULL){
		instr->arg1  = create_vmarg();
		instr->arg1 = make_operand(q->arg1,instr->arg1);
	}
	if(q->arg2!=NULL){
		instr->arg2  = create_vmarg();
		instr->arg2 = make_operand(q->arg2,instr->arg2);
	}
	if(q->result!=NULL){
		instr->result = create_vmarg();
		instr->result = make_operand(q->result,instr->result);
	}
 
	instr->line = q->line;
	q->taddress = next_instr_label();
	emit_instruction(instr);
}

void generate_ADD(quad * q){
	generate(add_v,q);
}

void generate_SUB(quad * q){
	generate(sub_v,q);
}

void generate_MUL(quad * q){
	generate(mul_v,q);
}

void generate_DIV(quad * q){
	generate(div_v,q);
}

void generate_MOD(quad * q){
	generate(mod_v,q);
}

void generate_UMINUS(quad * q){
	instr_s * instr = create_instr();
	instr->arg1 = create_vmarg();
	instr->arg2 = create_vmarg();
	instr->result = create_vmarg();
	instr->opcode = mul_v;
	instr->line = q->line;

	q->taddress = next_instr_label();
	
	make_operand(q->arg1,instr->arg1);
	make_integer_operand(instr->arg2,-1);
	make_operand(q->result,instr->result);
	emit_instruction(instr);
}

void generate_NEWTABLE(quad * q){
	generate(newtable_v,q);
}

void generate_TABLEGETELEM(quad * q){
	generate(tablegetelem_v,q);
}

void generate_TABLESETELEM(quad * q){
	generate(tablesetelem_v,q);
}

void generate_ASSIGN(quad * q){
	generate(assign_v,q);
}

void generate_NOP(quad * q){
	instr_s * instr = create_instr();
	instr->opcode = nop_v;
	emit_instruction(instr);
}

void generate_relational(vmopcode_e op, quad * q){
	instr_s * instr = create_instr();
	instr->opcode = op;
	instr->line = q->line;
	instr->result = create_vmarg();
	instr->result->type = label_a;

	if(q->arg1){
		instr->arg1 = create_vmarg();
		instr->arg1 = make_operand(q->arg1,instr->arg1);
	}
	if(q->arg2){
		instr->arg2 = create_vmarg();
		instr->arg2 = make_operand(q->arg2,instr->arg2);
	}

	if(q->result->int_value < current_quad)
		instr->result->value = quads[q->result->int_value].taddress;
	else
		add_incomplete_jump(next_instr_label(),q->result->int_value);
	
 	q->taddress = next_instr_label();
	emit_instruction(instr);
}

void generate_JUMP(quad * q){
	generate_relational(jump_v,q);
}

void generate_IF_EQ(quad * q){
	generate_relational(jeq_v,q);
}

void generate_IF_NOTEQ(quad * q){
	generate_relational(jne_v,q);
}

void generate_IF_GREATER(quad * q){
	generate_relational(jgt_v,q);
}

void generate_IF_GREATEREQ(quad * q){
	generate_relational(jge_v,q);
}

void generate_IF_LESS(quad * q){
	generate_relational(jlt_v,q);
}

void generate_IF_LESSEQ(quad * q){
	generate_relational(jle_v,q);
}

void generate_NOT(quad * q){
	q->taddress = next_instr_label();
	instr_s * instr;

	instr = create_instr();
	instr->opcode = jeq_v;
	instr->line = q->line;
	instr->arg1 = create_vmarg();
	instr->arg2 = create_vmarg();
	instr->result = create_vmarg();
	make_operand(q->arg1,instr->arg1);
	make_boolean_operand(instr->arg2,0);
	instr->result->type = label_a;
	instr->result->value = next_instr_label() + 3;
	emit_instruction(instr);

	instr = create_instr();
	instr->opcode = assign_v;
	instr->line = q->line;
	instr->arg1 = create_vmarg();
	instr->result = create_vmarg();
	make_boolean_operand(instr->arg1,0);
	make_operand(q->result,instr->result);
	emit_instruction(instr);

	instr = create_instr();
	instr->opcode = jump_v;
	instr->line = q->line;
	instr->result = create_vmarg();
	instr->result->type = label_a;
	instr->result->value = next_instr_label() + 2;
	emit_instruction(instr);

	instr = create_instr();
	instr->opcode = assign_v;
	instr->line = q->line;
	instr->arg1 = create_vmarg();
	instr->result = create_vmarg();
	make_boolean_operand(instr->arg1,1);
	make_operand(q->result,instr->result);
	emit_instruction(instr);
}
	 
void generate_OR(quad * q){
	q->taddress = next_instr_label();
	instr_s * instr;

	instr = create_instr();  
	instr->opcode = jeq_v;
	instr->line = q->line;
	instr->arg1 = create_vmarg();
	instr->arg2 = create_vmarg();
	instr->result = create_vmarg();
	make_operand(q->arg1,instr->arg1);
	make_boolean_operand(instr->arg2,1);
	instr->result->type = label_a;
	instr->result->value = next_instr_label() + 4;
	emit_instruction(instr);

	instr = create_instr();  
	instr->opcode = jeq_v;
	instr->line = q->line;
	instr->arg1 = create_vmarg();
	instr->arg2 = create_vmarg();
	instr->result = create_vmarg();
	make_operand(q->arg2,instr->arg1);
	make_boolean_operand(instr->arg2,1);
	instr->result->type = label_a;
	instr->result->value = next_instr_label() + 3;
	emit_instruction(instr);

	instr = create_instr();  
	instr->opcode = assign_v;
	instr->line = q->line;
	instr->arg1 = create_vmarg();
	instr->result = create_vmarg();
	make_boolean_operand(instr->arg1,0);
	make_operand(q->result,instr->result);
	emit_instruction(instr);

	instr = create_instr();  
	instr->opcode = jump_v;
	instr->line = q->line;
	instr->result = create_vmarg();
	instr->result->type = label_a;
	instr->result->value = next_instr_label() + 2;
	emit_instruction(instr);

	instr = create_instr();  
	instr->opcode = assign_v;
	instr->line = q->line;
	instr->arg1 = create_vmarg();
	instr->result = create_vmarg();
	make_boolean_operand(instr->arg1,1);
	make_operand(q->result,instr->result);
	emit_instruction(instr);
}
 
void generate_AND(quad * q){
	instr_s * instr; 
	q->taddress = next_instr_label();

	instr = create_instr();
	instr->opcode = jeq_v;
	instr->line = q->line;
	instr->arg1 = create_vmarg();
	instr->arg2 = create_vmarg();
	instr->result = create_vmarg();
	make_operand(q->arg1,instr->arg1);
	make_boolean_operand(instr->arg2,0);
	instr->result->type = label_a;
	instr->result->value = next_instr_label() + 4;
	emit_instruction(instr);

	instr = create_instr();
	instr->opcode = jeq_v;
	instr->line = q->line;
	instr->arg1 = create_vmarg();
	instr->arg2 = create_vmarg();
	instr->result = create_vmarg();
	make_operand(q->arg2,instr->arg1);
	make_boolean_operand(instr->arg2,0);
	instr->result->type = label_a;
	instr->result->value = next_instr_label() + 3;
	emit_instruction(instr);

	instr = create_instr();
	instr->opcode = assign_v;
	instr->line = q->line;
	instr->arg1 = create_vmarg();
	instr->result = create_vmarg();
	make_boolean_operand(instr->arg1,1);
	make_operand(q->result,instr->result);
	emit_instruction(instr);

	instr = create_instr();
	instr->opcode = jump_v;
	instr->line = q->line;
	instr->result = create_vmarg();
	instr->result->type = label_a;
	instr->result->value = next_instr_label() + 2;
	emit_instruction(instr);

	instr = create_instr();
	instr->opcode = assign_v;
	instr->line = q->line;
	instr->arg1 = create_vmarg();
	instr->result = create_vmarg();
	make_boolean_operand(instr->arg1,0);
	make_operand(q->result,instr->result);
	emit_instruction(instr);
}

void generate_PARAM(quad * q){
	q->taddress = next_instr_label();
	instr_s * instr = create_instr();
	instr->line = q->line;
	instr->opcode = pusharg_v;
	instr->result = create_vmarg();
	make_operand(q->result,instr->result);
	emit_instruction(instr);
}

void generate_CALL(quad * q){
	q->taddress = next_instr_label();
	instr_s * instr = create_instr();
	instr->opcode = call_v;
	instr->line = q->line;
	instr->result = create_vmarg();
	make_operand(q->result,instr->result);

	if(q->result->sym->type==LIBFUNC){
		instr->result->value = value_exists_in_arr(q->result->sym->name,lib_func_c);
		instr->result->type = libfunc_a;
		if(instr->result->value==-1){
			printf("\n\tError at line %d : Library function %s does not exist.\n",q->line,q->result->sym->name);
			exit(0);
		}
	}
	else{ 
		if(q->result->sym->type!=USERFUNC){
			instr->result->value = q->result->sym->offset;
			switch(q->result->sym->space){
				case PROGRAM_VAR: instr->result->type = global_a; break;
				case FUNC_LOCAL:  instr->result->type = local_a; break;
				case FORMAL_ARG:  instr->result->type = formal_a; break;
			}
		}
		else{
			instr->result->value = value_exists_in_arr(q->result->sym->name,user_func_c);
			instr->result->type = userfunc_a;
		}
		if(instr->result->value==-1){
			printf("\n\tError at line %d : User function %s does not exist.\n",q->line,q->result->sym->name);
			exit(0);
		}
	}
	emit_instruction(instr);
}
	 
void generate_GETRETVAL(quad * q){
	q->taddress = next_instr_label();
	instr_s * instr = create_instr();
	instr->opcode = assign_v;
	instr->result = create_vmarg();
	instr->arg1 = create_vmarg();
	make_operand(q->result,instr->result);
	make_retval_operand(instr->arg1);

	// Make sure this is valid.
	instr->arg1->value = 0;
	
	emit_instruction(instr);
}

void generate_FUNCSTART(quad * q){
	 
	st_entry * symbol = q->result->sym;
	symbol->taddress = next_instr_label();
	q->taddress = next_instr_label();
	
	userfunc_s * func = malloc(sizeof(userfunc_s));
	func->address = symbol->taddress;
	
	// Careful with the size
	func->local_size = count_func_locals(st, symbol->name);
	func->scope = current_func_scope;
	//printf("The size of %s is %d\n",symbol->name,func->local_size);

 	func->name  = malloc(strlen(symbol->name)+1);
 	strcpy(func->name,symbol->name);
	add_const_to_array(func,user_func_c);

	push_func(&funcs,symbol,q->line);

	instr_s * instr = create_instr();
	instr->result = create_vmarg();
	instr->opcode = funcenter_v;
	make_operand(q->result,instr->result);
	emit_instruction(instr);
	current_func_scope++;
}
 
void generate_RETURN(quad * q){
	q->taddress = next_instr_label();
	instr_s * instr = create_instr();
	instr->opcode = assign_v;
	instr->line = q->line;
	instr->result = create_vmarg();
	instr->arg1 = create_vmarg();
 
	if(q->result){
		make_retval_operand(instr->result);
		make_operand(q->result,instr->arg1);
		emit_instruction(instr);
	}

	(top_func(funcs))->ret_list = list_insert((top_func(funcs))->ret_list,next_instr_label());

	instr = create_instr();
	instr->opcode = jump_v;
	instr->line = q->line;
	instr->result = create_vmarg();
	make_retval_operand(instr->result);
	emit_instruction(instr);
}

void generate_FUNCEND(quad * q){
	current_func_scope--;
	list_node * return_list = (top_func(funcs))->ret_list;
	while(return_list){
		instructions[return_list->value].result = create_vmarg();
		(instructions[return_list->value].result)->value = next_instr_label();
		return_list = return_list->next;
	}
	pop_func(&funcs);
	q->taddress = next_instr_label();
	instr_s * instr = create_instr();
	instr->opcode = funcexit_v;
	instr->result = create_vmarg();
	make_operand(q->result,instr->result);
	emit_instruction(instr);
}

void reset_operand(vmarg_s * arg){
	free(arg);
	arg = NULL;
}

void destory_instr(instr_s * instr){
	free(instr->arg1);
	free(instr->arg2);
	free(instr->result);
	free(instr);
}

void generate_instructions(void){
	for(current_quad=0;current_quad<curr_quad;current_quad++){
		(*generators[quads[current_quad].op])(quads+current_quad);
	}
	patch_incomplete_jumps();
}

print_expr(expr * e){
	switch(e->type)
	{
		case var_e: {printf("var_e\n");break;}
		case table_item_e:{printf("table_item_e\n");break;}
		case program_func_e:{printf("programfunc\n");break;}
		case library_func_e:{printf("libraryfunc\n");break;}
		case arithm_expr_e:{printf("arithm_expr_e\n");break;}
		case bool_expr_e:{printf("bool_expr_e\n");break;}
		case assign_expr_e:{printf("assign_expr_e\n");break;}
		case new_table_e:{printf("new_table_e\n");break;}
		case const_int_e:{printf("const_int_e\n");break;}
		case const_num_e:{printf("const_num_e\n");break;}
		case const_bool_e:{printf("const_bool_e\n");break;}
		case const_str_e:{printf("const_str_e\n");break;}
		case nil_e:{printf("nil_e\n");break;}
		default: assert(0);
	}
}

void print_string(){
	int i;
	for(i=0;i<current_str_index;i++){
		printf("String : %s\n",str_consts[i]);
	}
}

void push_func(func_stack ** top,st_entry * sym, unsigned int line){
	func_stack * newNode = malloc(sizeof(func_stack));
	if(memerror(newNode,"new func stack node"))exit(0);
	newNode->sym = create_symbol(sym->name,sym->active,sym->scope,sym->line,sym->type,sym->offset,sym->space);
	newNode->ret_list = NULL;
	newNode->line = line;
	newNode->next = *top;
	*top = newNode;
}

func_stack * top_func(func_stack * top){
	if(top!=NULL)return top;
	return NULL;
}

void pop_func(func_stack ** top){
	func_stack * temp;
	temp = *top;
	if(*top!=NULL){
		*top = (*top)->next;
		free(temp);
	}
}

void print_instructions()
{
	int i;
	FILE * quads_output; 
 
	quads_output = fopen("target_code.txt","w"); 
	if(quads_output==NULL)
		quads_output = stderr;  

	fprintf(quads_output,"<user functions>: \n");
	for(i=0;i<current_user_func_index;i++){
		fprintf(quads_output,"%d : %s\n",i,user_funcs[i].name);
	}
	fprintf(quads_output,"<end of funcs>\n");	

	fprintf(quads_output,"<lib functions>: \n");
	for(i=0;i<current_lib_func_index;i++){
		fprintf(quads_output,"%d : %s\n",i,named_lib_funcs[i]);
	}
	fprintf(quads_output,"<end of lib funcs>\n");	

	fprintf(quads_output,"<strings> : \n");
	for(i=0;i<current_str_index;i++){
		fprintf(quads_output,"%d : %s\n",i,str_consts[i]);
	}
	fprintf(quads_output,"<end of strings>\n");

	fprintf(quads_output,"<integers> : \n");
	for(i=0;i<current_int_index;i++){
		fprintf(quads_output,"%d : %d\n",i,integer_consts[i]);
	}
	fprintf(quads_output,"<end of integers>\n");
	fprintf(quads_output,"<doubles> : \n");
	for(i=0;i<current_double_index;i++){
		fprintf(quads_output,"%d : %lf\n",i,double_consts[i]);
	}
	fprintf(quads_output,"<end of doubles>\n");

	fprintf(quads_output,"number of strings %d\n",current_str_index);
	for(i=0;i<next_instr_label();i++){
			fprintf(quads_output,"%d:\t%s",i,vm_opcode_to_str(instructions[i].opcode));
			if(instructions[i].arg1){
				fprintf(quads_output," %d (%s",instructions[i].arg1->value,value_type_to_str(instructions[i].arg1->type));
				if(instructions[i].arg1->name!=NULL){
					fprintf(quads_output,":%s)",instructions[i].arg1->name);
				}
				else fprintf(quads_output,")");
			}
			if(instructions[i].arg2){
				fprintf(quads_output," %d (%s",instructions[i].arg2->value,value_type_to_str(instructions[i].arg2->type));
				if(instructions[i].arg2->name!=NULL){
					fprintf(quads_output,":%s)",instructions[i].arg2->name);
				}
				else fprintf(quads_output,")");
			}
			if(instructions[i].result){
				fprintf(quads_output," %d (%s",instructions[i].result->value,value_type_to_str(instructions[i].result->type));
				if(instructions[i].result->name!=NULL){
					fprintf(quads_output,":%s)",instructions[i].result->name);
				}
				else fprintf(quads_output,")");
			}
			fprintf(quads_output,"\n");
	}
	fclose(quads_output);
}
 
char * vm_opcode_to_str(vmopcode_e op){
	char * ops[] = {"ASSIGN","ADD","SUB","MUL","DIV","MOD","UMINUS","AND","OR","NOT",
					"JEQ","JNE","JLE","JGE","JLT","JGT",
					"CALLFUNC","PUSHARG","RET","GETRETVAL","ENTERFUNC","EXITFUNC",
					"JUMP","NEWTABLE","TABLEGETELEM","TABLESETITEM","NOP" };
	return(ops[op-assign_v]);
}

char * value_type_to_str(vmarg_t type){
	char * value_types[] = {"label_a","global_a","formal_a","local_a",
							"integer_a" ,"double_a" ,"string_a" ,"bool_a",
							"nil_a" , "userfunc_a" ,"libfunc_a" ,"retval_a"};
	return(value_types[type]);
} 

void write_binary_file(){
 
	FILE * binary_output;

    if ((binary_output = fopen(DEFAULT_BINARY_NAME, "wb+")) == NULL) {
            fprintf(stderr, "Output error : Cannot open file %s\n", DEFAULT_BINARY_NAME);
            exit(0);
    }

    write_magic_number(binary_output);
    write_arrays(binary_output);
    write_code(binary_output);
 
 	fclose(binary_output);
}

void write_magic_number(FILE * output){
	unsigned int magic_number = MAGIC_NUMBER;
	fwrite(&magic_number,sizeof(unsigned int),1,output);
}

void write_arrays(FILE * output){
	int i;
	unsigned int size;
	char null_terminator = '\0';
	int integer_value;
	double double_value;

	// Writing the string array
	fwrite(&current_str_index,sizeof(unsigned int),1,output);
	for(i=0;i<current_str_index;i++){
		if(str_consts[i][0]=='"'){
			size = strlen(str_consts[i]) - 2;
			fwrite(&size,sizeof(unsigned int),1,output);
			fwrite(str_consts[i]+1,sizeof(char)*size,1,output);
		}
		else{
			size = strlen(str_consts[i]);
			fwrite(&size,sizeof(unsigned int),1,output);
			fwrite(str_consts[i],sizeof(char)*size,1,output);
		}
		fwrite(&null_terminator,1,1,output);
	}

	// Writing the integer array
	fwrite(&current_int_index,sizeof(unsigned int),1,output);
	for(i=0;i<current_int_index;i++){
		fwrite(&integer_consts[i],sizeof(int),1,output);
	}

	// Writing the double array
	fwrite(&current_double_index,sizeof(unsigned int),1,output);
	for(i=0;i<current_double_index;i++){
		fwrite(&double_consts[i],sizeof(double),1,output);
	}

	// Writing the user functions
	fwrite(&current_user_func_index,sizeof(unsigned int),1,output);
	for(i=0;i<current_user_func_index;i++){
		fwrite(&(user_funcs[i].address),sizeof(unsigned int),1,output);
		fwrite(&(user_funcs[i].local_size),sizeof(unsigned int),1,output);
		size = strlen(user_funcs[i].name);
		fwrite(&size,sizeof(unsigned int),1,output);
		fwrite(user_funcs[i].name,sizeof(char)*size,1,output);
		fwrite(&null_terminator,1,1,output);
	}
 
 	// Writing the library functions
 	fwrite(&current_lib_func_index,sizeof(unsigned int),1,output);
	for(i=0;i<current_lib_func_index;i++){
		size = strlen(named_lib_funcs[i]);
		fwrite(&size,sizeof(unsigned int),1,output);
		fwrite(named_lib_funcs[i],sizeof(char)*size,1,output);
		fwrite(&null_terminator,1,1,output);
	}

}

void write_code(FILE * output){
	int i;
	unsigned int len = 0;
	char null_terminator = '\0';

	fwrite(&current_instr_index,sizeof(unsigned int),1,output);
	for(i=0;i<current_instr_index;i++){

		fwrite(&(instructions[i].opcode),1,1,output);
		fwrite(&(instructions[i].line),sizeof(unsigned int),1,output);

		// Writing the arg1
		if(instructions[i].arg1){
			fwrite(&(instructions[i].arg1->type),1,1,output);
			fwrite(&(instructions[i].arg1->value),sizeof(unsigned int),1,output);
			if(instructions[i].arg1->name==NULL){
				len = 0;
				fwrite(&len,sizeof(unsigned int),1,output);
			}
			else{
				len = strlen(instructions[i].arg1->name);
				fwrite(&len,sizeof(unsigned int),1,output);
				fwrite((instructions[i].arg1->name),len,1,output);
			}
			fwrite(&null_terminator,1,1,output);
		}

		// Writing the arg2
		if(instructions[i].arg2){
			fwrite(&(instructions[i].arg2->type),1,1,output);
			fwrite(&(instructions[i].arg2->value),sizeof(unsigned int),1,output);
			if(instructions[i].arg2->name==NULL){
				len = 0;
				fwrite(&len,sizeof(unsigned int),1,output);
			}
			else{
				len = strlen(instructions[i].arg2->name);
				fwrite(&len,sizeof(unsigned int),1,output);
				fwrite((instructions[i].arg2->name),len,1,output);
			}
			fwrite(&null_terminator,1,1,output);
		}	

		// Writing the result
		if(instructions[i].result){
			fwrite(&(instructions[i].result->type),1,1,output);
			fwrite(&(instructions[i].result->value),sizeof(unsigned int),1,output);
			if(instructions[i].result->name==NULL){
				len = 0;
				fwrite(&len,sizeof(unsigned int),1,output);
			}
			else{
				len = strlen(instructions[i].result->name);
				fwrite(&len,sizeof(unsigned int),1,output);
				fwrite((instructions[i].result->name),len,1,output);
			}
			fwrite(&null_terminator,1,1,output);
		}
	}
}
 
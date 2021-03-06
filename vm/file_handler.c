#include "file_handler.h"

// For the number constants 
double * double_consts = NULL;
unsigned int total_double_consts = 0;

// For the integer number constants
int * integer_consts = NULL;
unsigned int total_integer_consts = 0;

// For the strings
char ** str_consts = NULL;
unsigned int total_str_consts = 0;

// For the library functions
char ** named_lib_funcs = NULL;
unsigned int total_named_lib_funcs = 0;

// For the user functions
userfunc_s * user_funcs = NULL;
unsigned int total_user_funcs = 0;

/* The array that includes
   the final target instructions. */
instr_s * instructions = NULL;
unsigned int total_instructions = 0;

void read_binary_file(char * filename){
	FILE * src;
	unsigned int i;

    if ((src = fopen(filename, "rb")) == NULL) {
        fprintf(stderr, "\nError : Cannot read binary file %s\n", filename);
        exit(0);
    }

 	read_magic_number(src);
 	read_arrays(src);
 	read_instructions(src);
 	fclose(src);
}

void read_arrays(FILE * src){
	read_strings(src);
	read_integers(src);
	read_doubles(src);
	read_user_functions(src);
	read_lib_functions(src);
}

void read_strings(FILE * src){
	unsigned int i;
	unsigned int length;
	fread(&total_str_consts,sizeof(unsigned int),1,src);
	if(total_str_consts>0){
		str_consts = (char **)malloc(total_str_consts*sizeof(char *));
		if(total_str_consts!=0)
			memerror(str_consts,"new str_consts array");
		for(i=0;i<total_str_consts;i++){
			fread(&length,sizeof(unsigned int),1,src);
			str_consts[i] = malloc(length+1);
			memerror(str_consts[i],"new string to array");
			fread(str_consts[i],length+1,1,src);
		}
	}
}

void read_integers(FILE * src){
	unsigned int i;
	fread(&total_integer_consts,sizeof(unsigned int),1,src);
	if(total_integer_consts>0){
		integer_consts = (int *)malloc(total_integer_consts*sizeof(int));
		if(total_integer_consts!=0)
			memerror(integer_consts,"new integer_consts array");
		for(i=0;i<total_integer_consts;i++){
			fread(&integer_consts[i],sizeof(int),1,src);
		}
	}
}

void read_doubles(FILE * src){
	unsigned int i;
	fread(&total_double_consts,sizeof(unsigned int),1,src);
	if(total_double_consts>0){
		double_consts = (double *)malloc(total_double_consts*sizeof(double));
		if(total_double_consts!=0)
			memerror(double_consts,"new double_consts array");
		for(i=0;i<total_double_consts;i++){
			fread(&double_consts[i],sizeof(double),1,src);
		}
	}	
}

void read_user_functions(FILE * src){
	unsigned int i;
	unsigned int length;
	fread(&total_user_funcs,sizeof(unsigned int),1,src);
	if(total_user_funcs>0){
		user_funcs = (userfunc_s *)malloc(total_user_funcs*sizeof(userfunc_s));
		if(total_user_funcs!=0)
			memerror(user_funcs,"new user_funcs array");
		for(i=0;i<total_user_funcs;i++){
			fread(&(user_funcs[i].address),sizeof(unsigned int),1,src);
			fread(&(user_funcs[i].local_size),sizeof(unsigned int),1,src);
			fread(&length,sizeof(unsigned int),1,src);
			user_funcs[i].name = malloc(length+1);
			memerror(user_funcs[i].name,"new user_funcs name");
			fread((user_funcs[i].name),length+1,1,src);
		}
	}	
}

void read_lib_functions(FILE * src){
	unsigned int i;
	unsigned int length;
	fread(&total_named_lib_funcs,sizeof(unsigned int),1,src);
	if(total_named_lib_funcs>0){
		named_lib_funcs = (char **)malloc(total_named_lib_funcs*sizeof(char *));
		if(total_named_lib_funcs!=0)
			memerror(named_lib_funcs,"new named_lib_funcs array");
		for(i=0;i<total_named_lib_funcs;i++){
			fread(&length,sizeof(unsigned int),1,src);
			named_lib_funcs[i] = malloc(length+1);
			memerror(named_lib_funcs[i],"new library func name");
			fread(named_lib_funcs[i],length+1,1,src);
		}
	}
}

void read_magic_number(FILE * src){
	unsigned int magic_number;
	fread(&magic_number,sizeof(unsigned int),1,src);
	if(magic_number!=MAGIC_NUMBER)
		error_message("loading file failed (invalid file type).");
}

void read_instructions(FILE * src){
	unsigned int i;
	unsigned int total_args;
	unsigned int length;
	char temp;

	fread(&total_instructions,sizeof(unsigned int),1,src);
	if(total_instructions>0){
		instructions = (instr_s *)malloc(sizeof(instr_s)*total_instructions);
		memerror(instructions,"new instructions array");
		for(i=0;i<total_instructions;i++){
			fread(&instructions[i].opcode,1,1,src);
			fread(&instructions[i].line,sizeof(unsigned int),1,src);
			total_args = get_instr_arg_num(instructions[i].opcode);
			switch(total_args){
				case 3:{
					instructions[i].arg1 = create_vmarg();
					fread(&instructions[i].arg1->type,1,1,src);
					fread(&instructions[i].arg1->value,sizeof(unsigned int),1,src);
					fread(&length,sizeof(unsigned int),1,src);
					if(length!=0){
						instructions[i].arg1->name = malloc(length+1);
						fread((instructions[i].arg1->name),length+1,1,src);
					}
					else
						fread(&temp,1,1,src);
					instructions[i].arg2 = create_vmarg();
					fread(&instructions[i].arg2->type,1,1,src);
					fread(&instructions[i].arg2->value,sizeof(unsigned int),1,src);
					fread(&length,sizeof(unsigned int),1,src);
					if(length!=0){
						instructions[i].arg2->name = malloc(length+1);
						fread((instructions[i].arg2->name),length+1,1,src);
					}
					else
						fread(&temp,1,1,src);
					instructions[i].result = create_vmarg();
					fread(&instructions[i].result->type,1,1,src);
					fread(&instructions[i].result->value,sizeof(unsigned int),1,src);
					fread(&length,sizeof(unsigned int),1,src);
					if(length!=0){
						instructions[i].result->name = malloc(length+1);
						fread((instructions[i].result->name),length+1,1,src);
					}
					else
						fread(&temp,1,1,src);
					break;
				}
				case 2:{
					instructions[i].arg1 = create_vmarg();
					fread(&instructions[i].arg1->type,1,1,src);
					fread(&instructions[i].arg1->value,sizeof(unsigned int),1,src);
					fread(&length,sizeof(unsigned int),1,src);
					if(length!=0){
						instructions[i].arg1->name = malloc(length+1);
						fread((instructions[i].arg1->name),length+1,1,src);
					}
					else
						fread(&temp,1,1,src);
					instructions[i].arg2 = NULL;
					instructions[i].result = create_vmarg();
					fread(&instructions[i].result->type,1,1,src);
					fread(&instructions[i].result->value,sizeof(unsigned int),1,src);
					fread(&length,sizeof(unsigned int),1,src);
					if(length!=0){
						instructions[i].result->name = malloc(length+1);
						fread((instructions[i].result->name),length+1,1,src);
					}
					else
						fread(&temp,1,1,src);
					break;
				}
				case 1:{
					instructions[i].arg1 = NULL;
					instructions[i].arg2 = NULL;
					instructions[i].result = create_vmarg();
					fread(&instructions[i].result->type,1,1,src);
					fread(&instructions[i].result->value,sizeof(unsigned int),1,src);
					fread(&length,sizeof(unsigned int),1,src);
					if(length!=0){
						instructions[i].result->name = malloc(length+1);
						fread((instructions[i].result->name),length+1,1,src);
					}
					else
						fread(&temp,1,1,src);
					break;
				}
				case 0:{
					instructions[i].arg1 = NULL;
					instructions[i].arg2 = NULL;
					instructions[i].result = NULL;	
					break;
				}
				default: assert(0);
			}
		}
	}
}

void error_message(char * msg){
	fprintf(stderr, "\nError : %s\n", msg);
	exit(0);
}

void memerror(void * ptr, const char * name){
	if(ptr==NULL){
		fprintf(stderr,"Error : Memory allocation for the <%s> failed.\n",name);
		exit(0);
	}
}

unsigned int get_instr_arg_num(vmopcode_e op){
	if(op==add_v||op==sub_v||op==mul_v||op==div_v||op==mod_v||op==jeq_v||op==jne_v||op==jle_v
	||op==jge_v||op==jlt_v||op==jgt_v||op==tablesetelem_v||op==tablegetelem_v)
		return 3;
	else if(op==assign_v)
		return 2;
	else if(op==call_v||op==pusharg_v||op==funcenter_v||op==funcexit_v||op==jump_v||op==newtable_v)
		return 1;
	else if(op==nop_v)
		return 0;
	else 
		assert(0);
}

vmarg_s * create_vmarg(void){
	vmarg_s * new_vmarg = malloc(sizeof(vmarg_s));
	new_vmarg->name = NULL;
	memerror(new_vmarg,"new vmarg");
	return(new_vmarg);
}
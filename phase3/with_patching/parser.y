%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
 
 	#include "ic_generator.h"
	#define YYPARSE_PARAM st
	
	int yyerror (const char * yaccProvideMessage);
	
	// Importing variables from yylex.
	extern int yylex(void);
	extern int yylineno;
	extern char * yytext;
	extern FILE * yyin;

	// A temporary symbol pointing to the last function
	st_entry * func_entry = NULL;

	// Some parameters for the elist
	method_call_param m_param;
 
 	// A temporary expression used to make some things easier.
 	expr * temp_expr = NULL;

 	// A stack for pushing a useful variable when entering a function
 	expr * expr_stack = NULL;

 	// An expression list used for the format (function(){})()
 	expr * func_expr_list = NULL;

 	// The lists in which we save the labels for patching.
 	list_node * break_list = NULL;
 	list_node * con_list = NULL;

 	stack_node * break_stack = NULL;
 	stack_node * con_stack = NULL;

 	unsigned int new_s = 0;
 	unsigned int curr_level = 0;



%}
%error-verbose
%start program
%defines 
%output="parser.c"

%union{
	int intval;
	double fltval;
	char * strval;
	struct st_entry * symbol;
	struct expr_s * expression;
}

%token <intval> INTEGER;
%token <fltval> REAL;
%token <strval> STRING;
%token <strval> IDENTIFIER;

%token <strval>	IF ELSE WHILE FOR FUNCTION RETURN BREAK CONTINUE AND NOT OR LOCAL TRUE FALSE NIL
%token <strval> EQUAL PLUS MINUS MULTI SLASH PERCENT DEQUAL NEQUAL DPLUS DMINUS GREATER LESS EQ_GREATER EQ_LESS
%token <strval> BRACE_L BRACE_R BRACKET_L BRACKET_R PAREN_L PAREN_R SEMICOLON COMMA COLON DCOLON DOT DDOT

%type <strval> stmt  assignexpr const primary member call callsuffix normcall methodcall term index_temp   else_prefix forprefix M  
%type <strval> elist objectdef funcdef indexedelem indexed idlist block ifstmt block_in whilestmt forstmt func_temp   whilestart Z
%type <expression> expr lvalue con_elist
 
 
%left EQUAL
%left OR
%left AND
%nonassoc DEQUAL NEQUAL
%nonassoc GREATER EQ_GREATER LESS EQ_LESS
%left PLUS MINUS
%left MULTI SLASH PERCENT
%right NOT UMINUS DPLUS DMINUS
%left DOT DDOT
%left BRACKET_R BRACKET_L
%left PAREN_R PAREN_L
%nonassoc IF_TERM
%nonassoc ELSE
%% 

program:
		program M stmt {}
		| {printf("\nCompiling...\n\n");}
		;

stmt:
		expr SEMICOLON { fun_rec=0; reset_tmp_var_counter(); }
		| BREAK SEMICOLON {
			if(scope_loop<=0)
				yyerror("Cannot use break; outside of a loop.");
			else{
				break_list = stack_top(break_stack);
				break_list = list_insert(break_list,curr_quad);
				break_stack->head = break_list;
				emit(jump,NULL,NULL,NULL,-1,yylineno);
			}
		}
		| CONTINUE SEMICOLON {
			if(scope_loop<=0)
				yyerror("Cannot use continue; outside of a loop.");
			else{
							
				con_list = stack_top(con_stack);
				con_list = list_insert(con_list,curr_quad);
				con_stack->head = con_list;
				emit(jump,NULL,NULL,NULL,-1,yylineno);
			}
		}
		| forstmt {}
		| whilestmt {}
		| block {}
		| ifstmt {}
		| funcdef {}
		| returnstmt {}
		| SEMICOLON {}
		;

expr:
		assignexpr {$<expression>$ = $<expression>1;}
		|	expr PLUS expr 	{
				$<expression>$ = emit_arithm((symbol_table **)st,add,$<expression>1,$<expression>3,$<expression>$,curr_quad,yylineno);
				temp_expr = $<expression>$;
		}
		|	expr MINUS expr	{
				$<expression>$ = emit_arithm((symbol_table **)st,sub,$<expression>1,$<expression>3,$<expression>$,curr_quad,yylineno);
				temp_expr = $<expression>$;
		}
		|	expr MULTI expr {
				$<expression>$ = emit_arithm((symbol_table **)st,mul,$<expression>1,$<expression>3,$<expression>$,curr_quad,yylineno);
				temp_expr = $<expression>$;
		}
		|	expr SLASH expr {
				$<expression>$ = emit_arithm((symbol_table **)st,op_div,$<expression>1,$<expression>3,$<expression>$,curr_quad,yylineno);
				temp_expr = $<expression>$;
			}
		|	expr PERCENT expr {
				$<expression>$ = emit_arithm((symbol_table **)st,mod,$<expression>1,$<expression>3,$<expression>$,curr_quad,yylineno);
				temp_expr = $<expression>$;
			}
		|	expr GREATER expr {
				emmited_quads_temp = list_insert(emmited_quads_temp,curr_quad);
				curr_emmited_quads_temp = list_insert(curr_emmited_quads_temp,curr_quad);
				emit(if_greater,$<expression>1,$<expression>3,NULL,curr_quad,yylineno);
				quads[curr_quad-1].if_level = 0;
				quads[curr_quad-1].next_if_type = none;
				emit(jump,NULL,NULL,new_expr_const_int(0),-1,yylineno);
				new_s++;
		}
		|	expr EQ_GREATER expr {
				emmited_quads_temp = list_insert(emmited_quads_temp,curr_quad);
				curr_emmited_quads_temp = list_insert(curr_emmited_quads_temp,curr_quad);
				emit(if_greq,$<expression>1,$<expression>3,NULL,curr_quad,yylineno);
				quads[curr_quad-1].if_level = 0;
				quads[curr_quad-1].next_if_type = none;
				emit(jump,NULL,NULL,new_expr_const_int(0),-1,yylineno);
				new_s++;
		}
		|	expr LESS expr {
				emmited_quads_temp = list_insert(emmited_quads_temp,curr_quad);
				curr_emmited_quads_temp = list_insert(curr_emmited_quads_temp,curr_quad);
				emit(if_less,$<expression>1,$<expression>3,NULL,curr_quad,yylineno);
				quads[curr_quad-1].if_level = 0;
				quads[curr_quad-1].next_if_type = none;
				emit(jump,NULL,NULL,new_expr_const_int(0),-1,yylineno);
				new_s++;
		}
		|   expr EQ_LESS expr {
				emmited_quads_temp = list_insert(emmited_quads_temp,curr_quad);
				curr_emmited_quads_temp = list_insert(curr_emmited_quads_temp,curr_quad);
				emit(if_leq,$<expression>1,$<expression>3,NULL,curr_quad,yylineno);
				quads[curr_quad-1].if_level = 0;
				quads[curr_quad-1].next_if_type = none;
				emit(jump,NULL,NULL,new_expr_const_int(0),-1,yylineno);
				new_s++;
		}
		|	expr DEQUAL expr {
				emmited_quads_temp = list_insert(emmited_quads_temp,curr_quad);
				curr_emmited_quads_temp = list_insert(curr_emmited_quads_temp,curr_quad);
				emit(if_eq,$<expression>1,$<expression>3,NULL,curr_quad,yylineno);
				quads[curr_quad-1].if_level = 0;
				quads[curr_quad-1].next_if_type = none;
				emit(jump,NULL,NULL,new_expr_const_int(0),-1,yylineno);
				new_s++;
				temp_expr = $<expression>$;

		}
		|	expr NEQUAL expr {
				emmited_quads_temp = list_insert(emmited_quads_temp,curr_quad);
				curr_emmited_quads_temp = list_insert(curr_emmited_quads_temp,curr_quad);
				emit(if_neq,$<expression>1,$<expression>3,NULL,curr_quad,yylineno);
				quads[curr_quad-1].if_level = 0;
				quads[curr_quad-1].next_if_type = none;
				emit(jump,NULL,NULL,new_expr_const_int(0),-1,yylineno);
				new_s++;
		}
		|	expr AND M expr {
				if(new_s==2){
					setIfType(and_case,curr_quad-2);
					setIfType(and_case,curr_quad-4);
				}
				else{
					if(quads[$<intval>3].next_if_type==none)quads[$<intval>3].next_if_type = and_case;
				}
				new_s = 0;
				$<expression>$ = new_expr(bool_expr_e);
				$<expression>$->sym = new_temp_var(st,yylineno);
				temp_expr = $<expression>$;
		}
		|	expr OR M expr {
				printf("OR ");
				if(new_s==2){
					setIfType(or_case,curr_quad-2);
					setIfType(or_case,curr_quad-4);
				}
				else{
					if(quads[$<intval>3].next_if_type==none)quads[$<intval>3].next_if_type = or_case;
				}
				printf("Exp: %d\n",new_s);
				new_s = 0;
				$<expression>$ = new_expr(bool_expr_e);
				$<expression>$->sym = new_temp_var(st,yylineno);
				temp_expr = $<expression>$;
		}
		| 	term {$<expression>$ = $<expression>1;}
		;

Z:
	{
		curr_level++;
	}


term:
		PAREN_L Z expr   PAREN_R	{
				$<expression>$ = $<expression>3; temp_expr=$<expression>$;
				while(curr_emmited_quads_temp){
					quads[curr_emmited_quads_temp->value].if_level = curr_level;
					curr_emmited_quads_temp = curr_emmited_quads_temp->next;
				}
				curr_emmited_quads_temp = NULL;
				curr_level--;
		}
		| MINUS expr %prec UMINUS {
			check_uminus($<expression>2,yylineno);
			if(is_num_expr($<expression>2)){
				$<expression>$ = emit_arithm((symbol_table **)st,mul,$<expression>2,new_expr_const_int(-1),$<expression>$,curr_quad,yylineno);
			}
			else{
				$<expression>$ = new_expr(arithm_expr_e);
				$<expression>$->sym =  new_temp_var(st,yylineno);
				emit(uminus,$<expression>2,NULL,$<expression>$,curr_quad,yylineno);
			}
			temp_expr = $<expression>$;
		}
		| NOT expr {
			emit(if_eq,$<expression>2,new_expr_const_bool(0),NULL,curr_quad,yylineno);
			emit(jump,NULL,NULL,new_expr_const_int(0),-1,yylineno);
			$<expression>$ = new_expr(bool_expr_e);
			$<expression>$->sym = new_temp_var(st,yylineno);
			temp_expr = $<expression>$;
		}
		| lvalue DPLUS {
			if(fun_rec)printf("Error at line %d : %s is a function, cannot assign to a function.\n",yylineno,$$);
			else{
				$<expression>$ = new_expr(var_e);
				$<expression>$->sym = new_temp_var(st,yylineno);
				if($<expression>1->type==table_item_e){
					expr * value = emit_iftableitem($<expression>1,st,yylineno);
					emit(assign,value,NULL,$<expression>$,curr_quad,yylineno);
					emit(add,value,new_expr_const_int(1),value,curr_quad,yylineno);
					emit(table_set_elem,$<expression>1,$<expression>1->index,value,curr_quad,yylineno);
				}
				else{
					emit(assign,$<expression>1,NULL,$<expression>$,curr_quad,yylineno);
					emit(add,$<expression>1,new_expr_const_int(1),$<expression>1,curr_quad,yylineno);
				}
				temp_expr = $<expression>$;
			}
		}
		| DPLUS lvalue {
			if(fun_rec)printf("Error at line %d : %s is a function, cannot assign to a function.\n",yylineno,$$);
			else {
				if($<expression>2->type == table_item_e){
					$<expression>$ = emit_iftableitem($<expression>2,st,yylineno);
					emit(add,$<expression>$,new_expr_const_int(1),$<expression>$,curr_quad,yylineno);
					emit(table_set_elem,$<expression>2,$<expression>2->index,$<expression>$,curr_quad,yylineno);
				}
				else{
					emit(add,$<expression>2,new_expr_const_int(1),$<expression>2,curr_quad,yylineno);
					$<expression>$ = new_expr(arithm_expr_e);
					$<expression>$->sym = new_temp_var(st,yylineno);
					emit(assign,$<expression>2,NULL,$<expression>$,curr_quad,yylineno);
				}
				temp_expr = $<expression>$;
			}
		}
		| lvalue DMINUS {
			if(fun_rec)printf("Error at line %d : %s is a function, cannot assign to a function.\n",yylineno,$$);
			else{
				$<expression>$ = new_expr(var_e);
				$<expression>$->sym = new_temp_var(st,yylineno);
				if($<expression>1->type==table_item_e){
					expr * value = emit_iftableitem($<expression>1,st,yylineno);
					emit(assign,value,NULL,$<expression>$,curr_quad,yylineno);
					emit(sub,value,new_expr_const_int(1),value,curr_quad,yylineno);
					emit(table_set_elem,$<expression>1,$<expression>1->index,value,curr_quad,yylineno);
				}
				else{
					emit(assign,$<expression>1,NULL,$<expression>$,curr_quad,yylineno);
					emit(sub,$<expression>1,new_expr_const_int(1),$<expression>1,curr_quad,yylineno);
				}
			}
			temp_expr = $<expression>$;
		}
		| DMINUS lvalue {
			if(fun_rec)printf("Error at line %d : %s is a function, cannot assign to a function.\n",yylineno,$$);
			else {
				if($<expression>2->type == table_item_e){
					$<expression>$ = emit_iftableitem($<expression>2,st,yylineno);
					emit(sub,$<expression>$,new_expr_const_int(1),$<expression>$,curr_quad,yylineno);
					emit(table_set_elem,$<expression>2,$<expression>2->index,$<expression>$,curr_quad,yylineno);
				}
				else{
					emit(sub,$<expression>2,new_expr_const_int(1),$<expression>2,curr_quad,yylineno);
					$<expression>$ = new_expr(arithm_expr_e);
					$<expression>$->sym = new_temp_var(st,yylineno);
					emit(assign,$<expression>2,NULL,$<expression>$,curr_quad,yylineno);
				}
				temp_expr = $<expression>$;
			}
		}
		| primary {$<expression>$ = $<expression>1; }
		;

primary:
		lvalue	{
			$<expression>$ = emit_iftableitem($1,st,yylineno);
			temp_expr = $<expression>$;
		}
		| const { $<expression>$ = $<expression>1;}
		| call  { $<expression>$ = $<expression>1; temp_expr = $<expression>$;}
		| objectdef {

			$<expression>$ = new_expr(new_table_e);
			$<expression>$ = $<expression>1;
			temp_expr = $<expression>$;
		}
		| PAREN_L funcdef PAREN_R {
			$<expression>$ = new_expr(program_func_e);
			($<expression>$)->sym = (st_entry *)$<expression>2;
		}
		;

const:
		REAL {$<expression>$=new_expr_const_num(yylval.fltval);temp_expr = $<expression>$;}
		| INTEGER {$<expression>$=new_expr_const_int(yylval.intval);temp_expr = $<expression>$;}
		| STRING {$<expression>$ = new_expr_const_str(yylval.strval);temp_expr = $<expression>$;}
		| NIL {$<expression>$ = new_expr(nil_e);temp_expr = $<expression>$;}
		| TRUE {$<expression>$ = new_expr_const_bool(1);temp_expr = $<expression>$;}
		| FALSE {$<expression>$ = new_expr_const_bool(0);temp_expr = $<expression>$;}
		;

assignexpr:
		lvalue EQUAL{expr_started=1;} 
		expr { 
			expr_started=0; 
			if(fun_rec)
				printf("Error at line %d: '%s' is a declared function, cannot assign to a function.\n",yylineno,$2);
			fun_rec=0;

			// Careful with the labels
			if(($1)->type==table_item_e){
				emit(table_set_elem,$<expression>1,$<expression>1->index,temp_expr,curr_quad,yylineno);
				$<expression>$ = emit_iftableitem($<expression>1,st,yylineno);
				$<expression>$->type=assign_expr_e;
			}
			else{
				emit(assign,temp_expr,NULL,$<expression>1,curr_quad,yylineno);
				$<expression>$ = new_expr(assign_expr_e);


				if($<expression>1->sym->type!=TEMP_VAR){
					($<expression>$)->sym = new_temp_var(st,yylineno);
					emit(assign,$<expression>1,NULL,$<expression>$,curr_quad,yylineno);
				}
				else $<expression>$->sym = $<expression>1->sym;
				
			}
		}
		;

lvalue:
		IDENTIFIER {

			// Adding the id to the symbol table.
			// Every required checking is included in the following function.
			add_variable((symbol_table **)st, $1,yylineno);
			$<expression>$ = lvalue_expr((*((symbol_table **)st))->last_symbol);

		}
		| LOCAL IDENTIFIER {

			// Adding the local id to the symbol table.
			// Every required checking is included in the following function.
			add_local_variable((symbol_table **)st, $2,yylineno);
			$<expression>$ = lvalue_expr((*((symbol_table **)st))->last_symbol);
		}
		| DCOLON IDENTIFIER {

			// We check that the global variable exists
			// The whole proccess is handled by the following funciton.
			check_global_variable((symbol_table **)st, $2,yylineno);
			$<expression>$ = lvalue_expr((*((symbol_table **)st))->last_symbol);
		}
		| member {}
		;

member:
		lvalue DOT IDENTIFIER {
			$<expression>$ = new_member_item_expr($1,$3,st,yylineno);
		}
		| lvalue BRACKET_L expr BRACKET_R {
			$1 = emit_iftableitem($1,st,yylineno);
			$<expression>$ = new_expr(table_item_e);
			($<expression>$)->sym = ($1)->sym;
			($<expression>$)->index = $3;
		}
		| call DOT IDENTIFIER {}
		| call BRACKET_L expr BRACKET_R {}
		;

call:
		call PAREN_L elist PAREN_R {
			$<expression>$ = make_call($<expression>1,m_param.elist,(symbol_table **)st,yylineno);
			m_param.elist = NULL;
		}
		| lvalue callsuffix {
			if(m_param.method){
				expr * self = $1;
				$1 = emit_iftableitem(new_member_item_expr(self,m_param.name,st,yylineno),st,yylineno);
				self->next = m_param.elist;
				m_param.elist = self;
			}
			$<expression>$ = make_call($1,m_param.elist,(symbol_table **)st,yylineno);
			m_param.elist = NULL;
		}
		| PAREN_L funcdef PAREN_R PAREN_L elist PAREN_R {
			expr * func = new_expr(program_func_e);
			func->sym =  	(*(symbol_table **)st)->last_symbol;
			$<expression>$ = make_call(func,func_expr_list,(symbol_table **)st,yylineno);
		}
		;

callsuffix:
		normcall {
			$$ = $1;
		}
		| methodcall {
			$$ = $1;
		}
		;

normcall:
		PAREN_L elist PAREN_R {
			m_param.method = 0;
		}
		;

methodcall:
		DDOT IDENTIFIER PAREN_L elist PAREN_R {
			m_param.elist = $<expression>4;
			m_param.method = 1;
			m_param.name = malloc(strlen($2)+1);
			strcpy(m_param.name,$2);
		}
		;

objectdef:
		BRACKET_L elist BRACKET_R {
			int i=0;
			expr * table = new_expr(new_table_e);
			table->sym = new_temp_var(st,yylineno);
			emit(table_create,NULL,NULL,table,curr_quad,yylineno);

			expr * temp = m_param.elist;
			while(temp){
				emit(table_set_elem,table,new_expr_const_int(i),temp,0,yylineno);
				temp = temp->next;
				i++;
			}
			$<expression>$ = table;
		}
		| BRACKET_L indexed BRACKET_R {
			expr * table = new_expr(new_table_e);
			expr * temp = index_expr;

			table->sym = new_temp_var(st,yylineno);
			emit(table_create,NULL,NULL,table,curr_quad,yylineno);

			while(temp){
				emit(table_set_elem,table,temp,temp->index,0,yylineno);
				temp = temp->next;
			}
			$<expression>$ = table;
			index_expr = NULL;
		 	
		}
		;

indexed:
		indexedelem {$<expression>$=$<expression>1;}
		|indexed COMMA indexedelem {
			$<expression>$ = $<expression>1;
			$<expression>$->next = $<expression>3;
			index_expr = $<expression>$;
		}
		;

indexedelem:
		BRACE_L index_temp BRACE_R {
			$<expression>$ = $<expression>2;
		}
		;

index_temp:
		expr COLON expr {
			$<expression>$ = $<expression>1;
			$<expression>$->index = $<expression>3;
		}
		;

elist:	expr con_elist{
			$<expression>$ = $<expression>1;
			$<expression>$->next = $<expression>2;
			m_param.elist = $<expression>$;
		} 
		| {$<expression>$ = NULL; m_param.elist = NULL;}
		;

con_elist: COMMA expr con_elist	{
			$<expression>$ = $<expression>2;
			$<expression>$->next = $<expression>3;
			m_param.elist = $<expression>$;
		} 
		|	{$<expression>$ = NULL; m_param.elist = NULL;}
		;
 
func_temp:
		IDENTIFIER{

			// Adding the function(with name) to the symbol table.
			// Every required checking is included in the following method.
			add_function((symbol_table **)st,$1,yylineno,1);
			func_entry = (*((symbol_table **)st))->last_symbol;

			// We add funcstart quad
			st_entry * se = st_lookup_scope(*((symbol_table **)st),$1,scope_main);
			temp_expr = lvalue_expr(se);
			temp_expr->next = expr_stack;
			expr_stack = temp_expr;
			temp_expr = NULL;

			emit(func_start,NULL,NULL, lvalue_expr(se), curr_quad,yylineno);
			 
		} 
		PAREN_L {
			scope_main++;
			in_func=1;
			func_started=1;
			func_scope++;
		 	enter_scope_space();
		} 
		idlist PAREN_R{enter_scope_space();}  block { 
			func_scope--;
			in_func=0;
			
			// We add funcend quad
			st_entry * se = st_lookup_scope(*((symbol_table **)st),top(func_names),scope_main);
			emit(func_end,NULL,NULL, lvalue_expr(se), curr_quad,yylineno);
			pop(&func_names);
			temp_expr = expr_stack;
			expr_stack = expr_stack->next;

		}
		| PAREN_L{
		 
 			// Adding the function(without name) to the symbol table.
			// Every required checking is included in the following method.
			add_function((symbol_table **)st,NULL,yylineno,0);
			temp_expr = NULL;
			
			// We add funcstart quad
			st_entry * se = (*(symbol_table **)(st))->last_symbol;

			temp_expr = lvalue_expr(se);
			temp_expr->next = expr_stack;
			expr_stack = temp_expr;
			temp_expr = NULL;

			emit(func_start,NULL,NULL, lvalue_expr(se), curr_quad,yylineno);
 		 	enter_scope_space();
 		 

		} idlist PAREN_R{enter_scope_space();} block {   
			func_var=0;
			func_scope--;
			in_func=0;
			st_entry * se = st_lookup_scope(*((symbol_table **)st),top(func_names),scope_main);
			emit(func_end,NULL,NULL, lvalue_expr(se), curr_quad,yylineno);
			pop(&func_names);
			temp_expr = expr_stack;
			expr_stack = expr_stack->next;

		}
		; 

funcdef:
		FUNCTION{
			// Starting function
			func_var=1;

			// We push the loop scope and the offset to a stack
			push_value(&loop_stack,scope_loop);
			push_value(&scope_offset_stack,get_current_scope_offset());

			// We set the new scope offset and loop scope to zero
			reset_curr_scope_offset();
			scope_loop=0;


		} 
		func_temp {
			// Function definition ended

			// We set the scope loop to the previous value
			scope_loop = top_value(loop_stack);
			 
			pop(&loop_stack);
			 
			// We decrease the scope space by two. 
			exit_scope_space();
			exit_scope_space();

			// We set the scope offset to the previous scope
			set_curr_scope_offset(top_value(scope_offset_stack));
			pop(&scope_offset_stack);
		}
		;

idlist:
		IDENTIFIER {
 
 			// Adding the argument of a function to the symbol table.
			// Every required checking is included in the following method.
 			add_function_argument((symbol_table **)st,$1,yylineno,0);
 			increase_curr_scope_offset();

 			// Adding to expression list
 			expr * e = new_expr_const_str($1);
 			e->next = func_expr_list;
 			func_expr_list = e; 
		}
		| idlist COMMA IDENTIFIER {

			// Adding the argument of a function to the symbol table.
			// Every required checking is included in the following method.
			add_function_argument((symbol_table **)st,$3,yylineno,1);
			increase_curr_scope_offset();

			// Adding to expression list
 			expr * e = new_expr_const_str($3);
 			e->next = func_expr_list;
 			func_expr_list = e; 
		}
		| {}
		;

block:
		BRACE_L {

			if(!func_started)
				scope_main++;
			else
				func_started = 0;

		} block_in BRACE_R {

			// We disable the local variables of the current scope
			scope_set_active((symbol_table **)st,scope_main,0);
			scope_main--;

		}
		;
 
block_in:	
		block_in stmt {}
		| {}
		;

ifstmt:
		IF PAREN_L M expr M PAREN_R M stmt M %prec IF_TERM { 
			backpatch_jumps($<intval>3,$<intval>5-1,$<intval>9);
			backpatch_if($<intval>3,$<intval>5-1,$<intval>7,0);
			special_if_backpatch($<intval>3,$<intval>5-1,quads[$<intval>5-2].type);
			emmited_quads_temp = NULL;
		 	patch_label($<intval>5-1,$<intval>9);
		}
		| IF PAREN_L M expr M PAREN_R M stmt M else_prefix M stmt { 
			backpatch_jumps($<intval>3,$<intval>5-1,$<intval>9);
			backpatch_if($<intval>3,$<intval>5-1,$<intval>7,0);
			emmited_quads_temp = NULL;
			patch_label($<intval>5-2,$<intval>5);
			patch_label($<intval>5-1,$<intval>9);
		}
		;

else_prefix:
		ELSE {
 
		}
		;

 

whilestmt:
		whilestart PAREN_L M expr M PAREN_R
		M stmt M {
			scope_loop--;
			emit(jump,NULL,NULL,new_expr_const_int($<intval>3),-1,yylineno);
			 	 
			backpatch_jumps($<intval>3,$<intval>5-1,$<intval>9+1);
			backpatch_if($<intval>3,$<intval>5-1,$<intval>7,0);
			patch_label($<intval>5-1,$<intval>9+1);

			break_list = stack_top(break_stack);
			con_list = stack_top(con_stack);

			while(break_list){
				patch_label(break_list->value,curr_quad);
				break_list = break_list->next;
			}

			while(con_list){
				patch_label(con_list->value,$<intval>1);
				con_list = con_list->next;
			}
			
			break_stack = pop_node(break_stack);
			con_stack = pop_node(con_stack);
			emmited_quads_temp = NULL;
		} 
		;

whilestart:
		WHILE{
			scope_loop++;
			$<intval>$ = curr_quad;
 			break_stack = push_node(break_stack,NULL);
			con_stack = push_node(con_stack,NULL);
		}

 

M: {
	$<intval>$ = curr_quad;
}

forprefix:
		FOR PAREN_L elist SEMICOLON {
			scope_loop++;
			break_stack = push_node(break_stack,NULL);
			con_stack = push_node(con_stack,NULL);
		}
		;

forstmt:
		forprefix M expr M SEMICOLON M elist M PAREN_R M {
			emit(jump,NULL,NULL,new_expr_const_int($<intval>2),-1,yylineno);
		} 
		stmt M {

			emit(jump,NULL,NULL,new_expr_const_int($<intval>8-2),-1,yylineno);
			printf("for (<elist>;<expr>;<elist>) <stmt>\n ");
			scope_loop--;
 	

			backpatch_jumps($<intval>2,$<intval>6-1,$<intval>13+1);
			backpatch_if($<intval>2,$<intval>6-1,$<intval>10,3);
			patch_label($<intval>4-2,$<intval>10+1);
			patch_label($<intval>4-1,$<intval>13+1);
			break_list = stack_top(break_stack);
			con_list = stack_top(con_stack);

			while(break_list){
				patch_label(break_list->value,curr_quad);
				break_list = break_list->next;
			}

			while(con_list){
				patch_label(con_list->value,$<intval>2+1);
				con_list = con_list->next;
			}

			break_stack = pop_node(break_stack);
			con_stack = pop_node(con_stack);
 			emmited_quads_temp = NULL;

		}
		;

returnstmt:
		RETURN SEMICOLON {
			if(func_scope==0)yyerror("Cannot use return; when not in a function.");
			else emit(ret,NULL,NULL,NULL,curr_quad,yylineno);
			
		
		}
		| RETURN expr SEMICOLON {
			if(func_scope==0)yyerror("Cannot use return; when not in a function.");
			else emit(ret,NULL,NULL,$<expression>2,curr_quad,yylineno);
			
		}
		;

%%

int yyerror (const char * yaccProvideMessage){
	fprintf(stderr,"Syntax error at line %d: %s\n",yylineno,yaccProvideMessage);
}
 

int main(int argc,char ** argv)
{
 	symbol_table * st = NULL;
 	st = create_symbol_table();
 	m_param.elist = NULL;

    	if (argc > 1) {
        	if ((yyin = fopen(argv[1], "r")) == NULL) {
            		fprintf(stderr, "Cannot read file %s\n", argv[1]);
            		return 1;
        	}
    	}
    	else
        	yyin = stdin;

	yyparse(&st);

	write_quads();

	printf("\nComplation has finished.\n");
	//print_st(st);
 
	return 0;	
}
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

 	expr * expr_stack = NULL;

 	unsigned int assign_func = 0;

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

%type <strval> stmt  assignexpr const primary member call callsuffix normcall methodcall   term   index_temp
%type <strval> elist objectdef funcdef indexedelem indexed idlist block ifstmt block_in whilestmt forstmt func_temp
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
		program stmt 
		| {printf("\n <--[Parsing Started]-->\n\n");}
		;

stmt:
		expr SEMICOLON { fun_rec=0; reset_tmp_var_counter(); }
		| BREAK SEMICOLON {
			if(scope_loop>0)
				printf("break;\n");
			else
				yyerror("Cannot use break; outside of a loop.");
		}
		| CONTINUE SEMICOLON {
			if(scope_loop>0)printf("continue;\n");
			else yyerror("Cannot use continue; outside of a loop.");
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
		|	expr PLUS expr 	{printf("<expr> + <expr>\n",$1,$3);}
		|	expr MINUS expr	{printf("<expr> - <expr>\n",$1,$3);}
		|	expr MULTI expr {printf("<expr> * <expr>\n",$1,$3);}
		|	expr SLASH expr {
					printf("<expr> / <expr>\n",$1,$3);
					if($3==0)yyerror("Cannot divide by zero.");
			}
		|	expr PERCENT expr {

					printf("<expr> %% <expr>\n",$1,$3);
					if($3==0)yyerror("Cannot divide by zero.");
			}
		|	expr GREATER expr {printf("<expr> > <expr>\n",$1,$3);}
		|	expr EQ_GREATER expr {printf("<expr> >= <expr>\n",$1,$3);}
		|	expr LESS expr {printf("<expr> < <expr>\n",$1,$3);}
		|   	expr EQ_LESS expr {printf("<expr> <= <expr>d\n",$1,$3);}
		|	expr DEQUAL expr {printf("<expr> == <expr>\n",$1,$3); }
		|	expr NEQUAL expr {printf("<expr> != <expr>\n",$1,$3);}
		|	expr AND expr {printf("<expr> and <expr>\n",$1,$3);}
		|	expr OR expr {printf("<expr> or <expr>\n",$1,$3);}
		| 	term {$<expression>$ = $<expression>1;}
		;

term:
		PAREN_L expr PAREN_R	{printf("(expr)\n");}
		| MINUS expr %prec UMINUS {printf("-<expr>\n");}
		| NOT expr {printf("!<expr>\n");}
		| lvalue DPLUS {
			if(fun_rec)printf("Error at line %d : %s is a function, cannot assign to a function.\n",yylineno,$$);
			else printf("lvalue++\n");}
		| DPLUS lvalue {
			if(fun_rec)printf("Error at line %d : %s is a function, cannot assign to a function.\n",yylineno,$$);
			else printf("++lvalue\n");}
		| lvalue DMINUS {
			if(fun_rec)printf("Error at line %d : %s is a function, cannot assign to a function.\n",yylineno,$$);
			else printf("lvalue--\n");
		}
		| DMINUS lvalue {
			if(fun_rec)printf("Error at line %d : %s is a function, cannot assign to a function.\n",yylineno,$$);
			else printf("--lvalue\n");}
		| primary {$<expression>$ = $<expression>1;}
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
		| NIL {$<expression>$ = new_expr(null_e);temp_expr = $<expression>$;}
		| TRUE {$<expression>$ = new_expr_const_bool(1);temp_expr = $<expression>$;}
		| FALSE {$<expression>$ = new_expr_const_bool(0);temp_expr = $<expression>$;}
		;

assignexpr:
		lvalue EQUAL{expr_started=1;printf("Expr started\n");} 
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
				//if(assign_func)
				//	emit(assign,$<expression>1,NULL,$<expression>1,curr_quad,yylineno);
				//else
				emit(assign,temp_expr,NULL,$<expression>1,curr_quad,yylineno);

				//assign_func = 0;
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
			printf("lvalue.id\n");
			$<expression>$ = new_member_item_expr($1,$3,st,yylineno);
			printf("lvalue.id %s\n",$<expression>$->index->str_value);
			 
		}
		| lvalue BRACKET_L expr BRACKET_R {
			printf("lvalue[expr]\n");
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
			printf("funccall(<elist>)\n");
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
			func->sym = (st_entry *)$<symbol>2;
			$<expression>$ = make_call(func,m_param.elist,(symbol_table **)st,yylineno);
			m_param.elist = NULL;
		}
		;

callsuffix:
		normcall {
			printf("funcall %s()\n",$$);
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
			printf("..id(elist)\n");
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
		|
		{
			$<expression>$ = NULL;		
		}
		;

con_elist: COMMA expr con_elist	{
			$<expression>$ = $<expression>2;
			$<expression>$->next = $<expression>3;
		} 
		|	{$<expression>$ = NULL;}
		;
 
func_temp:
		IDENTIFIER{

			// TO DO :
			// Make an expression stack and etc

			// Adding the function(with name) to the symbol table.
			// Every required checking is included in the following method.
			add_function((symbol_table **)st,$1,yylineno,1);
			func_entry = (*((symbol_table **)st))->last_symbol;

			// We add funcstart quad
			st_entry * se = st_lookup_scope(*((symbol_table **)st),$1,scope_main);
			temp_expr = lvalue_expr(se);


			printf("Expr : %s\n",expr_to_str(temp_expr));
			emit(func_start,NULL,NULL, lvalue_expr(se), curr_quad,yylineno);
			assign_func = 1;
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
			printf("Func <id> (<parameters>) \n");

		}
		| PAREN_L{
		 
 			// Adding the function(without name) to the symbol table.
			// Every required checking is included in the following method.
			add_function((symbol_table **)st,NULL,yylineno,0);

			// We add funcstart quad
			st_entry * se = (*(symbol_table **)(st))->last_symbol;
			emit(func_start,NULL,NULL, lvalue_expr(se), curr_quad,yylineno);

 		 	enter_scope_space();
 		 	assign_func = 1;

		} idlist PAREN_R{enter_scope_space();} block {   
			func_var=0;
			func_scope--;
			in_func=0;
			st_entry * se = st_lookup_scope(*((symbol_table **)st),top(func_names),scope_main);
			emit(func_end,NULL,NULL, lvalue_expr(se), curr_quad,yylineno);
			pop(&func_names);

			printf("Func (<parameters>) \n");
		}
		; 

funcdef:
		FUNCTION{
			// Starting function
			func_var=1;printf("FUNCTION\n");

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
		}
		| idlist COMMA IDENTIFIER {

			// Adding the argument of a function to the symbol table.
			// Every required checking is included in the following method.
			add_function_argument((symbol_table **)st,$3,yylineno,1);
			increase_curr_scope_offset();
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
		IF PAREN_L expr PAREN_R stmt %prec IF_TERM { printf("if (<expr>) <stmt>\n"); }
		| IF PAREN_L expr PAREN_R stmt ELSE stmt { printf("if (<expr>) <stmt> else <stmt>\n"); }
		;

whilestmt:
		WHILE {scope_loop++;} PAREN_L expr PAREN_R stmt {scope_loop--;} {
			printf("while (<expr>) <stmt>\n");
		}
		;

forstmt:
		FOR {scope_loop++;} PAREN_L elist SEMICOLON expr SEMICOLON elist PAREN_R stmt {
			printf("for (<elist>;<expr>;<elist>) <stmt>\n ");
			scope_loop--;
		}
		;

returnstmt:
		RETURN SEMICOLON {
			if(func_scope==0)yyerror("Cannot use return; when not in a function.");
			else printf("return ;\n");
		}
		| RETURN expr SEMICOLON {
			if(func_scope==0)yyerror("Cannot use return; when not in a function.");
			else printf("return <expr>;\n");
		}
		;

%%

int yyerror (const char * yaccProvideMessage){
	fprintf(stderr,"Error at line %d: %s\n",yylineno,yaccProvideMessage);
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

	printf("\n <--[Parsing Completed]-->\n");
	printf("Press [Enter] to continue with the symbol table.\n");
	getchar();
	print_st(st);
 
	return 0;	
}
parser: lex.yy.c parser.c lex_lib.o st.o par_lib.o ic_gen.o tc_gen.o
	gcc -o parser lex.yy.c lex_lib.o st.o parser.c par_lib.o ic_gen.o tc_gen.o 
	rm *.o
	rm -f lex.yy.c
	rm -f parser.c
	rm -f parser.h
parser.c:
	bison --yacc parser.y
tc_gen.o:
	gcc -o tc_gen.o -c tc_generator.c
ic_gen.o:	
	gcc -o ic_gen.o -c ic_generator.c
par_lib.o:
	gcc -o par_lib.o -c parser_lib.c
lex.yy.c:
	flex lex_analyzer.l
lex_lib.o: lex_lib.c lex_lib.h
	gcc -o lex_lib.o -c lex_lib.c
st.o: symbol_table.c symbol_table.h
	gcc -o st.o -c symbol_table.c
clean:
	rm -f *.o
	rm -f out.amc
	rm -f quads.txt
	rm -f target_code.txt
	rm -f lex.yy.c
	rm -f parser.c
	rm -f parser.h
	rm -f parser

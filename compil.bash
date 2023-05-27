yacc pgyaccet4.yacc
yacc -d pgyaccet4.yacc
lex pglex4.lex
gcc -Wall -c lex.yy.c
gcc -Wall y.tab.c lex.yy.o -lfl -o analyseur

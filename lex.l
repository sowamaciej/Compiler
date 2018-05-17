%{
#include <stdlib.h>
#include <string.h>
#include "def.tab.hh"
#define INFILE_ERROR 1
#define OUTFILE_ERROR 2
extern int yylineno;
int yyerror(const char *msg,...);
%}
%%
\=\=					{ return EQ;}
\!\=					{ return NE;}
\<						{ return LT;}
\>						{ return GT;}
\>\=					{return GE;}
\<\=					{return LE;}
\&\&					{ return AND;}
\|\|					{ return OR;}
\+						{ return '+';}
\*						{ return '*';}
\(						{ return '(';}
\)						{ return ')';}
\/						{ return '/';}
\-						{ return '-';}
\^						{ return '^';}
\[						{ return '[';}
\]						{ return ']';}
\{						{ return '{';}
\}						{ return '}';}
\;						{ return ';';}
\=						{ return '=';}
if						{ return IF;}
else					{ return ELSE;}
int						{ return INT;}
float					{ return FLOAT;}
for 					{ return FOR;}
printi				{return PRINTI;}
printf				{return PRINTF;}
prints				{return PRINTS;}
readi					{return INPUTI;}
readf					{return INPUTF;}
[1-9][0-9]*[.][0-9]+|0[.][0-9]+		{ yylval.fval = atof(yytext);
			return LZ;}
\"[^\"]*\" {yylval.text = strdup(yytext);
			return STRING;}
0|[1-9][0-9]*		{ yylval.ival = atoi(yytext);
			return LC;}

[A-Za-z_][A-Za-z0-9_]*	{ yylval.text = strdup(yytext);
			return ID;}
\ |\t			{;}
\n			{yylineno++ ;}
.			{yyerror("B��d leksykalny\n");}
%%
int yyerror(const char *msg,...)
{
	printf("%d: %s", yylineno, msg);
	exit(1);
}

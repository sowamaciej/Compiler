CC=gcc
LEX=flex
YACC=bison
LD=gcc
CPP=g++

all:	leks

leks:	def.tab.o lex.yy.o
	$(CPP) -std=c++11 lex.yy.o def.tab.o -o leks -ll

lex.yy.o:	lex.yy.c
	$(CC) -c lex.yy.c

lex.yy.c: lex.l
	$(LEX) lex.l

def.tab.o:	def.tab.cc
	$(CPP) -std=c++11 -c def.tab.cc

def.tab.cc:	def.yy
	$(YACC)  def.yy

clean:
	rm *.o leks

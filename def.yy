%{
#include <stdio.h>
#include <stack>
#include <string.h>
#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <map>
#define INFILE_ERROR 1
#define OUTFILE_ERROR 2

extern FILE *yyin;
extern FILE *yyout;
extern "C" int yylex();
extern "C" int yyerror(const char *msg,...);
extern int yylineno;
static int ifLabel=0;
static int strCounter=0;
static int licznik=0;
using namespace std;
int  ARRI =10;
int ARRF= 11;
    static int helper=0;
//ofstream
ofstream trojki;
ofstream rpn;
ofstream assembler;

//struktury
struct element {
    string name;
    int type;
};
struct symbol_info{
  int type; //int/float/string -> LD/LC/STRING
  int size; //size
  string id; //id zmiennej (nazwa)
  string value; //wartość
};

//kolekcje
stack<struct element> stos;
stack<string> etykiety;
vector<string> assemblerCode;
map<string,struct symbol_info>symbole;

//deklaracje
void makeThrees(char name);
void makeAssembler(element el1, element el2, string temporaryName, char sign);
void makeAssignementAssembler(element el1, element el2);
void makeComparisionAssembler(string condition);
string GetFloat(element el, int regNum);
void printFloat(string name);
void printInteger(string name);
void printString(string name);
void inputFloat(string name);
void inputInteger(string name);
void callSyscall();
string GetInteger(element el, int regNum);
//template
template<typename T>
string toString(T value)
{
    stringstream sstream;
    sstream<<value;
    return sstream.str();
}

template <typename T>
void pushElement(T name,int type){
    struct element el;
    el.name=toString(name);
    el.type=type;
    stos.push(el);
};

%}
%union
{char *text;
int	ival;float fval;};

//tokeny
%type <text> wyr
%token <text> ID
%token <text> STRING
%token <ival> LC
%token <fval> LZ
%token PRINTF PRINTS PRINTI //wyswietlanie
%token INPUTI INPUTF //pobieranie
%token INT FLOAT //deklaracja
%token EQ NE LT GT GE LE//porownanie
%token AND OR //warunki
%token FOR //petla
%token IF ELSE //jezeli
%token ENTER //nie wiem po co xD
%left '+' '-'
%left '*' '/'
%start wielelinii
%%
wielelinii
  :wielelinii linia
  |linia
;
linia
	:przypisanie ';'		{;}
	|deklaracja ';'		{;}
  |wyswietlanie ';' {;}
  |pobieranie ';' {;}
  |if_stmt ';'{;}
  |wyr ';'{;}
  |for_stmt ';' {;}
;
for_stmt
  :for_stmt_begin '{' wielelinii '}' {string etykieta1=etykiety.top();
                                      etykiety.pop();
                                      string etykieta2=etykiety.top();
                                      etykiety.pop();
                                      assemblerCode.push_back("b "+etykieta2);
                                      assemblerCode.push_back(etykieta1+":");

                                    }
;
for_stmt_begin
  : for_stmt_init for_stmt_inc warunek ')'
;
for_stmt_init
  :FOR '(' przypisanie ';' {string newEtykieta="ETYKIETA"+toString(ifLabel);
                            ifLabel++;
                          string newEtykieta2="ETYKIETA"+toString(ifLabel);
                            ifLabel++;
                            etykiety.push(newEtykieta2);
                            etykiety.push(newEtykieta);
                            assemblerCode.push_back("b "+newEtykieta);
                            assemblerCode.push_back(newEtykieta2+":");
                          }
;
for_stmt_inc
  :przypisanie ';' {string etykieta=etykiety.top();
                      etykiety.pop();
                      assemblerCode.push_back(etykieta+":");
                      }
;
if_stmt
  :if_stmt_begin '{' wielelinii '}' {string etykieta=etykiety.top();
                                      assemblerCode.push_back(etykieta+":");
                                      etykiety.pop();ifLabel++;}
  |if_stmt_begin '{' wielelinii '}' else_stmt '{' wielelinii '}'{string etykieta=etykiety.top();
                                                                  assemblerCode.push_back(etykieta+":");
                                                                  etykiety.pop();ifLabel++;}
;
if_stmt_begin
  : IF '(' warunek ')' {;}
;
else_stmt
  :ELSE  {  string etykieta=etykiety.top();
            string newEtykieta="ETYKIETA"+toString(ifLabel);
            assemblerCode.push_back("b "+newEtykieta);
            assemblerCode.push_back(etykieta+":");
            etykiety.pop();
            etykieta = "ETYKIETA"+toString(ifLabel);
            etykiety.push(etykieta);}
;
warunek
  : wyr EQ wyr {makeComparisionAssembler("bne");}
  | wyr NE wyr {makeComparisionAssembler("beq");}
  | wyr LT wyr {makeComparisionAssembler("bge");}
  | wyr GT wyr {makeComparisionAssembler("ble");}
  | wyr LE wyr {makeComparisionAssembler("bgt");}
  | wyr GE wyr {makeComparisionAssembler("blt");}
;
wyswietlanie
  :PRINTI  '='  ID  {printInteger($3);} //printi=x;
  |PRINTI '=' ID tab_wyr  {
                          string temporaryName="printTempInt";
                          auto it=symbole.find(temporaryName);
                          symbol_info sInfo;
                          sInfo.id=temporaryName;
                          sInfo.type=LC;
                          sInfo.size=1;
                          sInfo.value="0";
                          symbole.insert(std::pair<string,symbol_info>(temporaryName,sInfo));
                          element var1=stos.top();
                          stos.pop();
                          string _asm1=GetInteger(var1,0);
                          assemblerCode.push_back("la $t4, "+toString($3));
                          if(var1.type==ID)
                            assemblerCode.push_back("lw $t5, "+toString(var1.name));
                          else
                              assemblerCode.push_back("li $t5, "+toString(var1.name));
                          assemblerCode.push_back("mul $t5,$t5,4");
                          assemblerCode.push_back("add $t4, $t4, $t5");
                          assemblerCode.push_back("lw $t0, ($t4)");
                          assemblerCode.push_back("sw $t0, " +temporaryName);
                          printInteger(temporaryName);
  }
  |PRINTF  '=' ID  {printFloat($3);} //printf=x;
  |PRINTF '=' ID tab_wyr {string temporaryName="printTempFloat";
                        auto it=symbole.find(temporaryName);
                        symbol_info sInfo;
                        sInfo.id=temporaryName;
                        sInfo.type=LZ;
                        sInfo.size=1;
                        sInfo.value="0";
                        symbole.insert(std::pair<string,symbol_info>(temporaryName,sInfo));
                        element var1=stos.top();
                        stos.pop();
                        string _asm1=GetInteger(var1,0);
                        assemblerCode.push_back("la $t4, "+toString($3));
                        if(var1.type==ID)
                          assemblerCode.push_back("lw $t5, "+toString(var1.name));
                        else
                            assemblerCode.push_back("li $t5, "+toString(var1.name));
                        assemblerCode.push_back("mul $t5,$t5,4");
                        assemblerCode.push_back("add $t4, $t4, $t5");
                        assemblerCode.push_back("l.s $f0, ($t4)");
                        assemblerCode.push_back("s.s $f0, " +temporaryName);
                        printFloat(temporaryName);
  }
  |PRINTS '=' STRING { //prints="asd";
                        auto it = symbole.find($3);
                        symbol_info sInfo;
                        sInfo.type=STRING;
                        sInfo.size=1;
                        sInfo.id="_string"+toString(strCounter);
                        sInfo.value=$3;
                        if(it!=symbole.end()){
                          printString(it->second.id);
                        }else{
                        symbole.insert(std::pair<string,symbol_info>($3,sInfo));
                        printString(sInfo.id);
                        strCounter++;
                      }
   }
;
pobieranie
  : ID '=' INPUTI {inputInteger($1);} //readi
  | ID '=' INPUTF {inputFloat($1);} //readf
;
deklaracja
	:INT ID					{

                auto it=symbole.find($2);
                if(it!=symbole.end()) {cout << "ERROR already declared int\n";exit(-1);}
                symbol_info sInfo;
                sInfo.type=LC;
                sInfo.size=1;
                sInfo.id=$2;
                sInfo.value="0";
                symbole.insert(std::pair<string,symbol_info>($2,sInfo));
							    }
	|FLOAT ID				{

                auto it=symbole.find($2);
                if(it!=symbole.end()) {cout << "ERROR already declared float\n";exit(-1);}
                symbol_info sInfo;
                sInfo.type=LZ;
                sInfo.size=1;
                sInfo.id=$2;
                sInfo.value="0.0";
                symbole.insert(std::pair<string,symbol_info>($2,sInfo));
							    }
  |INT ID '[' LC ']' {
                            symbol_info sInfo;
                            sInfo.type=ARRI;
                            sInfo.size=$4;
                            sInfo.id=$2;
                            sInfo.value="0:"+toString($4);
                            symbole.insert(std::pair<string,symbol_info>($2,sInfo));
                          ;}
  |FLOAT ID '[' LC ']' {
                              symbol_info sInfo;
                              sInfo.type=ARRF;
                              sInfo.size=$4;
                              sInfo.id=$2;
                              sInfo.value="0:"+toString($4);
                              symbole.insert(std::pair<string,symbol_info>($2,sInfo));
                              ;}
;

przypisanie
  :ID '=' wyr			{pushElement($1,ID);
                    makeThrees('=');}


  |ID '[' wyr ']' '=' wyr {
                  auto it=symbole.find($1);
                  if(it->second.type==ARRI){
                    assemblerCode.push_back("la $t4, "+toString($1));
                    element variable1=stos.top();
                    stos.pop();
                    string _asm1=GetInteger(variable1,0);
                    assemblerCode.push_back(_asm1);

                    element variable2=stos.top();
                                      stos.pop();
                    string _asm2=GetInteger(variable2,5);
                    assemblerCode.push_back(_asm2);
                    assemblerCode.push_back("mul $t5, $t5, 4");
                    assemblerCode.push_back("add $t4, $t4, $t5");
                    assemblerCode.push_back("sw $t0, ($t4)");

                  }else
                  {
                    assemblerCode.push_back("la $t4, "+toString($1));
                    element variable1=stos.top();
                    stos.pop();
                    string _asm1=GetFloat(variable1,0);
                    assemblerCode.push_back(_asm1);

                    element variable2=stos.top();
                                      stos.pop();
                    string _asm2=GetInteger(variable2,5);
                    assemblerCode.push_back(_asm2);
                    assemblerCode.push_back("mul $t5, $t5, 4");
                    assemblerCode.push_back("add $t4, $t4, $t5");
                    assemblerCode.push_back("s.s $f0, ($t4)");
                  }
                    ;}
;

wyr
	:wyr '+' skladnik	{makeThrees('+');printf("+");}
	|wyr '-' skladnik	{makeThrees('-');printf("-");}
	|skladnik		{;}
	;
skladnik
	:skladnik '*' czynnik	{makeThrees('*');printf("*");}
	|skladnik '/' czynnik	{makeThrees('/');printf("/");}
	|czynnik		{;}
	;
czynnik
	:ID			{pushElement($1,ID);}
	|LC			{pushElement($1,LC);}
	|LZ     {pushElement($1,LZ);}
  |ID tab_wyr {
                  auto it=symbole.find($1);
                  if(it->second.type==ARRI){
                  element var1=stos.top();
                  stos.pop();
                  assemblerCode.push_back("la $t4,"+toString($1));
                  if(var1.type==ID)
                    assemblerCode.push_back("lw $t5, "+toString(var1.name));
                  else
                      assemblerCode.push_back("li $t5, "+toString(var1.name));
                  assemblerCode.push_back("mul $t5, $t5, 4");
                  assemblerCode.push_back("add $t4, $t4, $t5");
                  assemblerCode.push_back("lw $t0, ($t4)");
                  helper++;
                  string temporaryName="_tmp"+toString(helper);
                  symbol_info sInfo;
                  sInfo.id=temporaryName;
                  sInfo.type=LC;
                  sInfo.size=1;
                  sInfo.value="0";
                  symbole.insert(std::pair<string,symbol_info>(temporaryName,sInfo));
                  pushElement(temporaryName,ID);
                  assemblerCode.push_back("sw $t0, "+temporaryName);
                }else {
                  element var1=stos.top();
                  stos.pop();
                  assemblerCode.push_back("la $t4,"+toString($1));
                  if(var1.type==ID)
                    assemblerCode.push_back("lw $t5, "+toString(var1.name));
                  else
                      assemblerCode.push_back("li $t5, "+toString(var1.name));
                  assemblerCode.push_back("mul $t5, $t5, 4");
                  assemblerCode.push_back("add $t4, $t4, $t5");
                  assemblerCode.push_back("l.s $f0, ($t4)");
                  licznik++;
                  string temporaryName="_tmp_float"+toString(licznik);
                  symbol_info sInfo;
                  sInfo.id=temporaryName;
                  sInfo.type=LZ;
                  sInfo.size=1;
                  sInfo.value="0";
                  symbole.insert(std::pair<string,symbol_info>(temporaryName,sInfo));
                  pushElement(temporaryName,ID);
                  assemblerCode.push_back("s.s $f0, "+temporaryName);
                }
                ;}
  |STRING {;}
	|'(' wyr ')'		{;}
	;
tab_wyr
  :'[' wyr ']' {

  }
;
%%
void callSyscall(){
  string _asm1;
  _asm1="syscall";
  assemblerCode.push_back(_asm1);
}
void makeComparisionAssembler(string condition){
  struct element variable2=stos.top();
  stos.pop();
  struct element variable1=stos.top();
  stos.pop();
  if(variable1.type==LZ || variable2.type==LZ) {cout << "ERROR incorrect condition types\n";exit(-1);}
  string _asm1, _asm2, etykieta;
  _asm1=GetInteger(variable1,0);
  _asm2=GetInteger(variable2,1);
  etykieta = "ETYKIETA"+toString(ifLabel);
  etykiety.push(etykieta);
  assemblerCode.push_back(_asm1);
  assemblerCode.push_back(_asm2);
  assemblerCode.push_back(condition+" $t0,$t1, "+etykieta); //do funkcji
  ifLabel++;
}
void inputInteger(string name){
  string _asm1, _asm2;
  _asm1="li $v0, 5";
  _asm2="sw $v0, " + name;
  assemblerCode.push_back(_asm1);
  callSyscall();
  assemblerCode.push_back(_asm2);
}
void inputFloat(string name){
  string _asm1, _asm2;
  _asm1="li $v0, 6";
  _asm2="s.s $f0, " + name;
  assemblerCode.push_back(_asm1);
  callSyscall();
  assemblerCode.push_back(_asm2);
}
void printInteger(string name){
  string _asm1, _asm2;
  _asm1="li $v0, 1";
  _asm2="lw $a0, " + name;
  assemblerCode.push_back(_asm1);
  assemblerCode.push_back(_asm2);
  callSyscall();
}
void printFloat(string name){
  string _asm1, _asm2;
  _asm1="li $v0, 2";
  _asm2="lwc1 $f12, " + name;
  assemblerCode.push_back(_asm1);
  assemblerCode.push_back(_asm2);
  callSyscall();
}
void printString(string name){
  string _asm1, _asm2;
  _asm1="li $v0, 4"; // to warto do funkcj wjebac
  _asm2="la $a0, " + name;
  assemblerCode.push_back(_asm1);
  assemblerCode.push_back(_asm2);
  callSyscall();
}
string convert (int id){
  if(id == LC || id == ARRI)
    return ".word";
  else if(id == LZ || id==ARRF)
    return ".float";
  else if (id==STRING)
    return ".asciiz";

  return ".unknown";
}

int GetType(element el)
{
  if(el.type == LC || el.type == LZ)
    return el.type;
  else if(el.type==ID)
  {
    auto it = symbole.find(el.name);
    if(it !=symbole.end())
      return it->second.type;
  }
  else
    throw "Nie znaleziono symbolu!";

  throw "Nieznany typ!";
}
void makeThrees(char sign ){
    struct element variable2=stos.top();
    stos.pop();
    struct element variable1=stos.top();
    stos.pop();


    if(sign=='='){
      trojki<<variable2.name <<" = " << variable1.name<<endl;
      //przypisanie assembler
      makeAssignementAssembler(variable1,variable2);
    }else{
      helper++;
      int type1=GetType(variable1);
      int type2=GetType(variable2);
      string temporaryName="_tmp"+toString(helper);
      trojki<<temporaryName + "=" + variable1.name + sign + variable2.name<<endl;
      pushElement(temporaryName,ID);

      symbol_info sInfo;
      sInfo.id=temporaryName;

      if(type1==LZ || type2 == LZ)
        sInfo.type=LZ;
      else
        sInfo.type=LC;

      sInfo.size=1;
      sInfo.value="0";
      symbole.insert(std::pair<string,symbol_info>(temporaryName,sInfo));
      makeAssembler(variable1,variable2,temporaryName,sign);
  }
};

string GetOperatorCode(char sign,int type1,int type2)
{
    string s;
    if(sign=='+')
      s="add";
    else if(sign=='-')
      s="sub";
    else if(sign=='*')
      s="mul";
    else if(sign=='/')
      s="div";

    if(type1 == LC && type2 == LC)
      s=s + " $t0, $t0,$t1";
    else
      s=s + ".s $f0,$f0,$f1";

    return s;
}

string GetStoreCode(int type1,int type2, string result)
{
    string s;
    if(type1==LC && type2==LC)
      s="sw $t0," + result;
    else
      s="s.s $f0," + result;

    return s;
}

string GetFloat(element el, int regNum)
{
    if(el.type==ID)
      return "l.s $f" + toString(regNum) + "," + el.name;
    symbol_info sInfo;
    sInfo.id="_tmp_float" + toString(licznik);
    licznik++;
    sInfo.type=LZ;
    sInfo.size=1;
    sInfo.value=el.name;
    symbole.insert(std::pair<string,symbol_info>(sInfo.id,sInfo));

    return "l.s $f" + toString(regNum) + "," + sInfo.id;

}

string GetInteger(element el, int regNum)
{
    if(el.type==ID)
      return "lw $t"  + toString(regNum) + "," + el.name;
    else if (el.type==LC)
      return "li $t" + toString(regNum) + "," + el.name;
}
void makeAssignementAssembler(element el1, element el2)
{
  string _asm1,_asm2,_asm3;
  int flaga=0;
  int type1=GetType(el1);
  int type2=GetType(el2);

  if(type1==LZ && type2== LZ ){
      _asm1=GetFloat(el1,0);
      assemblerCode.push_back(_asm1);
  }
  else if(type1==LC && type2==LC ){
      _asm1=GetInteger(el1,0);
      assemblerCode.push_back(_asm1);
  }
  else if(type2==LC && type1==LZ){
    cout << "Blad przypisania";
    exit(-1);
  }

  if(type2==LZ && type1==LC){
    _asm1=GetInteger(el1,0);
    _asm2="mtc1 $t0, $f0";
    _asm3="cvt.s.w $f1, $f0";
    assemblerCode.push_back(_asm1);
    flaga=1;
  }

  if(flaga==1){
    assemblerCode.push_back(_asm2);
    assemblerCode.push_back(_asm3);
  }
  _asm2=GetStoreCode(type1,type2,el2.name);
  assemblerCode.push_back(_asm2);
}

void makeAssembler(element el1, element el2, string temporaryName, char sign)
{
    string _asm1,_asm2,_asm3,_asm4,_asm5,_asm_tmp1,_asm_tmp2;
    int type1;
    int type2;
    int flag=0;

    type1=GetType(el1);
    type2=GetType(el2);

    if(type1==LZ && type2== LZ){
        _asm1=GetFloat(el1,0);
        _asm2=GetFloat(el2,1);
    }
    else if(type1==LC && type2==LC){
        _asm1=GetInteger(el1,0);
        _asm2=GetInteger(el2,1);
    }
    else {
      int rejestr;
      flag=1;

      if(type1==LZ){
        rejestr=1;
        _asm1=GetFloat(el1,0);
        _asm2=GetInteger(el2,rejestr);
      }
      else if(type2== LZ)
      {
        rejestr=0;
        _asm1=GetInteger(el1,rejestr);
        _asm2=GetFloat(el2,rejestr);
      }

      _asm_tmp1="mtc1 $t" + toString(rejestr) + ", $f" + toString(rejestr);
      _asm_tmp2="cvt.s.w $f" + toString(rejestr) + ", $f" + toString(rejestr);
    }

    assemblerCode.push_back(_asm1);

    if(flag==1 && type2 ==LZ){
      assemblerCode.push_back(_asm_tmp1);
      assemblerCode.push_back(_asm_tmp2);
    }
    assemblerCode.push_back(_asm2);
    if(flag==1 && type1==LZ){
      assemblerCode.push_back(_asm_tmp1);
      assemblerCode.push_back(_asm_tmp2);
    }

    _asm3=GetOperatorCode(sign,type1,type2);
    _asm4=GetStoreCode(type1,type2,temporaryName);

    assemblerCode.push_back(_asm3);
    assemblerCode.push_back(_asm4);

}
int main(int argc, char *argv[])
{
  trojki.open("trojki.txt");
  yyparse();
	yyout=fopen("a.asm","w");

  fprintf(yyout,"%s",".data\n");

  for(auto sym:symbole)
  {
    fprintf(yyout,"\t%s\t:",sym.second.id.c_str());
    fprintf(yyout,"\t%s",convert(sym.second.type).c_str());
    fprintf(yyout,"\t%s\n",sym.second.value.c_str());
  }
  fprintf(yyout,"%s",".text\n\n");
  for(auto kod:assemblerCode){
    fprintf(yyout,"%s\n",kod.c_str());
  }
	fclose(yyout);
	return 0;
}

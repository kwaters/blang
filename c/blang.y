/* B parser */

%{
    #include <stdint.h>
    #include "ast.h"

    extern void yyerror(char *);
    extern int yylex(void);
%}

%union {
    int assign_op;
    intptr_t number;
    char *name;
    bstring str;
}

%token ASSIGN 258
%token CHAR 259
%token DEC 260
%token EQ 261
%token GTE 262
%token INC 263
%token LTE 264
%token NAME 265
%token NEQ 266
%token NUMBER 267
%token SHIFTL 268
%token SHIFTR 269
%token STRING 270
%token AUTO 271
%token CASE 272
%token ELSE 273
%token EXTRN 274
%token GOTO 275
%token IF 276
%token RETURN 277
%token SWITCH 278
%token WHILE 279

%precedence IF_PREC
%precedence ELSE

%right ASSIGN
%right '?' ':'
%left '|'
%left '&'
%left EQ NEQ
%left '<' LTE '>' GTE
%left SHIFTL SHIFTR
%left '+' '-'
%left '*' '/' '%'
%right DEC INC UNARY_PREC
%left '(' '['

%%

program: /* empty */
    | program defintion
    ;

defintion: NAME ilist ';'
    | NAME '[' ']' opt_ilist ';'
    | NAME '[' constant ']' opt_ilist ';'
    | NAME '(' arg_list ')' statement
    ;

opt_ilist: /* empty */
    | ilist
    ;

ilist: ival
     | ilist ',' ival
     ;

ival: constant
    | NAME
    ;

constant: NUMBER
    | CHAR
    | STRING
    ;

arg_list: /* empty */
    | arg_list_nonempty
    ;

arg_list_nonempty: NAME
    | arg_list_nonempty ',' NAME
    ;

statement: AUTO auto_list ';' statement
    | EXTRN extrn_list ';' statement
    | NAME ':' statement
    | CASE constant ':' statement
    | '{' block '}'
    | IF '(' value ')' statement %prec IF_PREC
    | IF '(' value ')' statement ELSE statement
    | WHILE '(' value ')' statement
    | SWITCH '(' value ')' statement
    | GOTO value ';'
    | RETURN ';'
    | RETURN '(' value ')' ';'
    | value ';'
    | ';'
    ;

auto_list: auto_val
    | auto_list ',' auto_val
    ;

auto_val: NAME
    | NAME constant
    ;

extrn_list: NAME
    | extrn_list ',' NAME
    ;

block: /* empty */
    | block statement
    ;

value: '(' value ')'
    | NAME
    | '*' value %prec UNARY_PREC
    | value '[' value ']'
    | constant
    | value ASSIGN value
    | incdec value %prec UNARY_PREC
    | value incdec
    | '-' value %prec UNARY_PREC
    | '!' value %prec UNARY_PREC
    | '&' value
    | value '|' value
    | value '&' value
    | value EQ value
    | value NEQ value
    | value '<' value
    | value LTE value
    | value '>' value
    | value GTE value
    | value SHIFTL value
    | value SHIFTR value
    | value '-' value
    | value '+' value
    | value '%' value
    | value '*' value
    | value '/' value
    | value '?' value ':' value
    | value '(' opt_value_list ')'
    ;

incdec: INC
    | DEC
    ;

opt_value_list: /* empty */
    | value_list
    ;

value_list: value
    | value_list ',' value
    ;

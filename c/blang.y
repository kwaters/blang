/* B parser */

%code requires{
    #include "ast.h"
}

%{
    #include <stdint.h>
    #include <string.h>
    #include "vector.h"

    extern void yyerror(char *);
    extern int yylex(void);
%}

%union {
    I num;
    I name;
    struct Vector *vector;
    Ast *ast;
    I binop;
    struct Bstring str;
}

%type<num> incdec nconstant;
%type<vector> block opt_value_list value_list ilist opt_ilist auto_list
    extrn_list arg_list arg_list_nonempty;
%type<ast> statement value constant ival defintion;

%token<num> ASSIGN 258
%token<num> CHAR 259
%token DEC 260
%token EQ 261
%token GTE 262
%token INC 263
%token LTE 264
%token<name> NAME 265
%token NEQ 266
%token<num> NUMBER 267
%token SHIFTL 268
%token SHIFTR 269
%token<str> STRING 270
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

defintion: NAME opt_ilist ';' {
        $$ = ast_get(A_XDEF);
        $$->xdef.name = $1;
        $$->xdef.size = -1;
        $$->xdef.initializer = $2;
    }
    | NAME '[' ']' opt_ilist ';' {
        $$ = ast_get(A_XDEF);
        $$->xdef.name = $1;
        /* "If the vector size is missing, zero is assumed." -- 7.2 */
        $$->xdef.size = 0;
        $$->xdef.initializer = $4;
    }
    | NAME '[' nconstant ']' opt_ilist ';' {
        $$ = ast_get(A_XDEF);
        $$->xdef.name = $1;
        $$->xdef.size = $3;
        $$->xdef.initializer = $5;
    }
    | NAME '(' arg_list ')' statement {
        $$ = ast_get(A_FDEF);
        $$->fdef.statement = $5;
        $$->fdef.name = $1;
        $$->fdef.arguments = $3;
    }
    ;

opt_ilist: /* empty */ {
        $$ = vector_get_reserve(0);
    }
    | ilist
    ;

ilist: ival {
        $$ = vector_get();
        vector_push(&($$), (I)($1));
     }
     | ilist ',' ival {
        $$ = $1;
        vector_push(&($$), (I)($3));
     }
     ;

ival: constant
    | NAME {
        $$ = ast_get(A_NAME);
        $$->name.name = (I)($1);
    }
    ;

nconstant: NUMBER
    | CHAR
    ;

constant: nconstant {
        $$ = ast_get(A_NUM);
        $$->num.num = $1;
    }
    | STRING {
        $$ = ast_get(A_STR);
        $$->str.s = malloc($1.len);
        memcpy($$->str.s, $1.s, $1.len);
        $$->str.len = $1.len;
    }
    ;

arg_list: /* empty */ {
        $$ = vector_get_reserve(0);
    }
    | arg_list_nonempty
    ;

arg_list_nonempty: NAME {
        $$ = vector_get();
        vector_push(&($$), $1);
    }
    | arg_list_nonempty ',' NAME {
        $$ = $1;
        vector_push(&($$), $3);
    }
    ;

statement: AUTO auto_list ';' statement {
        $$ = ast_get(A_VAR);
        $$->var.statement = $4;
        $$->var.isAuto = 1;
        $$->var.variables = $2;
    }
    | EXTRN extrn_list ';' statement {
        $$ = ast_get(A_VAR);
        $$->var.statement = $4;
        $$->var.isAuto = 0;
        $$->var.variables = $2;
    }
    | NAME ':' statement {
        $$ = ast_get(A_LABEL);
        $$->label.statement = $3;
        $$->label.name = $1;
    }
    | CASE nconstant ':' statement {
        $$ = ast_get(A_CLABEL);
        $$->clabel.statement = $4;
        $$->clabel.num = $2;
    }
    | '{' block '}' {
        $$ = ast_get(A_SEQ);
        $$->seq.statements = $2;
    }
    | IF '(' value ')' statement %prec IF_PREC {
        $$ = ast_get(A_IFE);
        $$->ife.cond = $3;
        $$->ife.then = $5;
        $$->ife.else_ = ast_get(A_VOID);
    }
    | IF '(' value ')' statement ELSE statement {
        $$ = ast_get(A_IFE);
        $$->ife.cond = $3;
        $$->ife.then = $5;
        $$->ife.else_ = $7;
    }
    | WHILE '(' value ')' statement {
        $$ = ast_get(A_WHILE);
        $$->while_.cond = $3;
        $$->while_.statement = $5;
    }
    | SWITCH '(' value ')' statement {
        $$ = ast_get(A_SWITCH);
        $$->switch_.value = $3;
        $$->switch_.statement = $5;
    }
    | GOTO value ';' {
        $$ = ast_get(A_GOTO);
        $$->goto_.expr = $2;
    }
    | RETURN ';' {
        $$ = ast_get(A_VRTRN);
    }
    | RETURN '(' value ')' ';' {
        $$ = ast_get(A_RTRN);
        $$->rtrn.expr = $3;
    }
    | value ';' {
        $$ = ast_get(A_EXPR);
        $$->expr.expr = $1;
    }
    | ';' {
        $$ = ast_get(A_VOID);
    }
    ;

auto_list: NAME {
        $$ = vector_get();
        vector_push(&($$), $1);
        vector_push(&($$), -1);
    }
    | NAME nconstant {
        $$ = vector_get();
        vector_push(&($$), $1);
        vector_push(&($$), $2);
    }
    | auto_list ',' NAME {
        $$ = $1;
        vector_push(&($$), $3);
        vector_push(&($$), -1);
    }
    | auto_list ',' NAME nconstant {
        $$ = $1;
        vector_push(&($$), $3);
        vector_push(&($$), $4);
    }
    ;

extrn_list: NAME {
        $$ = vector_get();
        vector_push(&($$), $1);
    }
    | extrn_list ',' NAME {
        $$ = $1;
        vector_push(&($$), $3);
    }
    ;

block: /* empty */ {
        $$ = vector_get();
    }
    | block statement {
        $$ = $1;
        vector_push(&($$), (I)($2));
    }
    ;

value: '(' value ')' {
        $$ = $2;
    }
    | NAME {
        $$ = ast_get(A_NAME);
        $$->name.name = (I)($1);
    }
    | '*' value %prec UNARY_PREC {
        $$ = ast_get(A_IND);
        $$->ind.expr = $2;
    }
    | value '[' value ']' {
        $$ = ast_get(A_INDEX);
        $$->index.vector = $1;
        $$->index.index = $3;
    }
    | constant
    | value ASSIGN value {
        $$ = ast_get(A_ASSIGN);
        $$->assign.lhs = $1;
        $$->assign.rhs = $3;
        $$->assign.op = $2;
    }
    | incdec value %prec UNARY_PREC {
        $$ = ast_get(A_PRE);
        $$->pre.expr = $2;
        $$->pre.num = $1;
    }
    | value incdec {
        $$ = ast_get(A_POST);
        $$->post.expr = $1;
        $$->post.num = $2;
    }
    | '-' value %prec UNARY_PREC {
        $$ = ast_get(A_UNARY);
        $$->unary.expr = $2;
        $$->unary.op = U_NEG;
    }
    | '!' value %prec UNARY_PREC {
        $$ = ast_get(A_UNARY);
        $$->unary.expr = $2;
        $$->unary.op = U_NOT;
    }
    | '&' value {
        $$ = ast_get(A_ADDR);
        $$->addr.expr = $2;
    }
    | value '|' value     { $$ = ast_binop($1, $3, O_OR);     }
    | value '&' value     { $$ = ast_binop($1, $3, O_AND);    }
    | value EQ value      { $$ = ast_binop($1, $3, O_EQ);     }
    | value NEQ value     { $$ = ast_binop($1, $3, O_NEQ);    }
    | value '<' value     { $$ = ast_binop($1, $3, O_LT);     }
    | value LTE value     { $$ = ast_binop($1, $3, O_LTE);    }
    | value '>' value     { $$ = ast_binop($1, $3, O_GT);     }
    | value GTE value     { $$ = ast_binop($1, $3, O_GTE);    }
    | value SHIFTL value  { $$ = ast_binop($1, $3, O_SHIFTL); }
    | value SHIFTR value  { $$ = ast_binop($1, $3, O_SHIFTR); }
    | value '-' value     { $$ = ast_binop($1, $3, O_MINUS);  }
    | value '+' value     { $$ = ast_binop($1, $3, O_PLUS);   }
    | value '%' value     { $$ = ast_binop($1, $3, O_REM);    }
    | value '*' value     { $$ = ast_binop($1, $3, O_MUL);    }
    | value '/' value     { $$ = ast_binop($1, $3, O_DIV);    }
    | value '?' value ':' value {
        $$ = ast_get(A_COND);
        $$->cond.cond = $1;
        $$->cond.yes = $3;
        $$->cond.no = $5;
    }
    | value '(' opt_value_list ')' {
        $$ = ast_get(A_CALL);
        $$->call.function = $1;
        $$->call.arguments = $3;
    }
    ;

incdec: INC  { $$ =  1; }
    | DEC    { $$ = -1; }
    ;

opt_value_list: /* empty */  { $$ = vector_get(); }
    | value_list
    ;

value_list: value {
        $$ = vector_get();
        vector_push(&($$), (I)($1));
    }
    | value_list ',' value {
        $$ = $1;
        vector_push(&($$), (I)($3));
    }
    ;

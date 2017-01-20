/* B parser */

%{
    #include <stdint.h>
    #include "ast.h"
    #include "vector.h"

    extern void yyerror(char *);
    extern int yylex(void);
%}

%union {
    I num;
    char *name;
    bstring str;
    struct Vector *vector;
    union Ast *ast;
}

%type<num> incdec;
%type<vector> block opt_value_list value_list ilist opt_ilist;
%type<ast> statement value constant ival;

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
    | NAME '(' arg_list ')' statement {
        ast_show($5);
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

constant: NUMBER {
        $$ = ast_get(A_NUM);
        $$->num.num = $1;
    }
    | CHAR {
        $$ = ast_get(A_NUM);
        $$->num.num = $1;
    }
    | STRING {
        $$ = ast_get(A_STR);
    }
    ;

arg_list: /* empty */
    | arg_list_nonempty
    ;

arg_list_nonempty: NAME
    | arg_list_nonempty ',' NAME
    ;

statement: AUTO auto_list ';' statement {
        /* TODO */
        /* $$ = ast_get(A_VAR); */
        $$ = $4;
    }
    | EXTRN extrn_list ';' statement {
        /* TODO */
        /* $$ = ast_get(A_VAR); */
        $$ = $4;
    }
    | NAME ':' statement {
        /* TODO */
        /* $$ = ast_get(A_LABEL); */
        $$ = $3;
    }
    | CASE constant ':' statement {
        /* TODO */
        /* $$ = ast_get(A_LABEL); */
        $$ = $4;
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

auto_list: auto_val
    | auto_list ',' auto_val
    ;

auto_val: NAME
    | NAME constant
    ;

extrn_list: NAME
    | extrn_list ',' NAME
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

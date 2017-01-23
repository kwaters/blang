#pragma once

#include <stddef.h>

#include "base.h"

typedef struct bstring_ {
    char *s;
    size_t len;
} bstring;

enum {
    /* AST node kinds. */
    A_PROG = 1,
    A_XDEF,
    A_FDEF,
    /* Statements */
    A_VAR,
    A_LABEL,
    A_CLABEL,
    A_SEQ,
    A_IFE,
    A_WHILE,
    A_SWITCH,
    A_GOTO,
    A_VRTRN,
    A_RTRN,
    A_EXPR,
    A_VOID,
    /* lvalues */
    A_NAME,
    A_IND,
    A_INDEX,
    /* rvalues */
    A_NUM,
    A_STR,
    A_ASSIGN,
    A_PRE,
    A_POST,
    A_UNARY,
    A_ADDR,
    A_BIN,
    A_COND,
    A_CALL
};

enum {
    O_OR = 1,
    O_AND,
    O_EQ,
    O_NEQ,
    O_LT,
    O_LTE,
    O_GT,
    O_GTE,
    O_SHIFTL,
    O_SHIFTR,
    O_MINUS,
    O_PLUS,
    O_REM,
    O_MUL,
    O_DIV
};

enum {
    U_NEG = 1,
    U_NOT
};

typedef I AstKind;
typedef I Name;

#if 0
A_PROG
A_XDEF
A_FDEF
A_VAR
A_LABEL
A_CLABEL
A_SEQ
A_IFE
A_WHILE
A_SWITCH
A_GOTO
A_VRTRN
A_RTRN
A_EXPR
A_VOID
A_NAME
A_IND
A_INDEX
A_NUM
A_STR
A_ASSIGN
A_PRE
A_POST
A_UNARY
A_ADDR
A_BIN
A_COND
A_CALL
#endif

typedef union Ast_ Ast;

struct AstProg {
    AstKind kind;
    struct Vector *definitions;
};
struct AstXdef {
    AstKind kind;
    Name name;
    I size;  /* -1 -> scalar */
    struct Vector *initializer;
};
struct AstFdef {
    AstKind kind;
    Ast *statement;
    Name name;
    struct Vector *arguments;
};
struct AstVar {
    AstKind kind;
    Ast *statement;
    I isAuto;
    struct Vector *variables;
};
struct AstLabel {
    AstKind kind;
    Ast *statement;
    Name name;
};
struct AstCLabel {
    AstKind kind;
    Ast *statement;
    I num;
};
struct AstSeq {
    AstKind kind;
    struct Vector *statements;
};
struct AstIfe {
    AstKind kind;
    Ast *cond;
    Ast *then;
    Ast *else_;
};
struct AstWhile {
    AstKind kind;
    Ast *cond;
    Ast *statement;
};
struct AstSwitch {
    AstKind kind;
    Ast *value;
    Ast *statement;
    struct Vector *table;
};
struct AstGoto {
    AstKind kind;
    Ast *expr;
};
struct AstVrtrn {
    AstKind kind;
};
struct AstRtrn {
    AstKind kind;
    Ast *expr;
};
struct AstExpr {
    AstKind kind;
    Ast *expr;
};
struct AstVoid {
    AstKind kind;
};
struct AstName {
    AstKind kind;
    Name name;
};
struct AstInd {
    AstKind kind;
    Ast *expr;
};
struct AstIndex {
    AstKind kind;
    Ast *vector;
    Ast *index;
};
struct AstNum {
    AstKind kind;
    I num;
};
struct AstStr {
    AstKind kind;
    char *s;
    I len;
};
struct AstAssign {
    AstKind kind;
    Ast *lhs;
    Ast *rhs;
    I op;
};
struct AstPre {
    AstKind kind;
    Ast *expr;
    I num;
};
struct AstPost {
    AstKind kind;
    Ast *expr;
    I num;
};
struct AstUnary {
    AstKind kind;
    Ast *expr;
    I op;
};
struct AstAddr {
    AstKind kind;
    Ast *expr;
};
struct AstBin {
    AstKind kind;
    Ast *lhs;
    Ast *rhs;
    I op;
};
struct AstCond {
    AstKind kind;
    Ast *cond;
    Ast *yes;
    Ast *no;
};
struct AstCall {
    AstKind kind;
    Ast *function;
    struct Vector *arguments;
};

union Ast_ {
    AstKind kind;
    struct AstProg prog;
    struct AstXdef xdef;
    struct AstFdef fdef;
    struct AstVar var;
    struct AstLabel label;
    struct AstCLabel clabel;
    struct AstSeq seq;
    struct AstIfe ife;
    struct AstWhile while_;
    struct AstSwitch switch_;
    struct AstGoto goto_;
    struct AstVrtrn vrtrn;
    struct AstRtrn rtrn;
    struct AstExpr expr;
    struct AstVoid void_;
    struct AstName name;
    struct AstInd ind;
    struct AstIndex index;
    struct AstNum num;
    struct AstStr str;
    struct AstAssign assign;
    struct AstPre pre;
    struct AstPost post;
    struct AstUnary unary;
    struct AstAddr addr;
    struct AstBin bin;
    struct AstCond cond;
    struct AstCall call;
};

typedef void (*AstWalkFunc)(Ast **node, void *data);
void ast_walk(Ast **node, AstWalkFunc pre, AstWalkFunc post, void *data);
void ast_show(Ast *root);
Ast *ast_get(AstKind kind);
void ast_release(Ast *node);
void ast_release_recursive(Ast *ast);
Ast *ast_binop(Ast *lhs, Ast *rhs, I op);

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

union Ast;

struct AstProg {
    AstKind kind;
    struct Vector *definitions;
};
struct AstXdef {
    AstKind kind;
    /* TODO */
};
struct AstFdef {
    AstKind kind;
    union Ast *statement;
    Name name;
    struct Vector *arguments;
};
struct AstVar {
    /* TODO */
    AstKind kind;
};
struct AstLabel {
    /* TODO */
    AstKind kind;
};
struct AstSeq {
    AstKind kind;
    struct Vector *statements;
};
struct AstIfe {
    AstKind kind;
    union Ast *cond;
    union Ast *then;
    union Ast *else_;
};
struct AstWhile {
    AstKind kind;
    union Ast *cond;
    union Ast *statement;
};
struct AstSwitch {
    AstKind kind;
    union Ast *value;
    union Ast *statement;
    struct Vector *table;
};
struct AstGoto {
    AstKind kind;
    union Ast *expr;
};
struct AstVrtrn {
    AstKind kind;
};
struct AstRtrn {
    AstKind kind;
    union Ast *expr;
};
struct AstExpr {
    AstKind kind;
    union Ast *expr;
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
    union Ast *expr;
};
struct AstIndex {
    AstKind kind;
    union Ast *vector;
    union Ast *index;
};
struct AstNum {
    AstKind kind;
    I num;
};
struct AstStr {
    AstKind kind;
};
struct AstAssign {
    AstKind kind;
    union Ast *lhs;
    union Ast *rhs;
    I op;
};
struct AstPre {
    AstKind kind;
    union Ast *expr;
    I num;
};
struct AstPost {
    AstKind kind;
    union Ast *expr;
    I num;
};
struct AstUnary {
    AstKind kind;
    union Ast *expr;
    I op;
};
struct AstAddr {
    AstKind kind;
    union Ast *expr;
};
struct AstBin {
    AstKind kind;
    union Ast *lhs;
    union Ast *rhs;
    I op;
};
struct AstCond {
    AstKind kind;
    union Ast *cond;
    union Ast *lhs;
    union Ast *rhs;
};
struct AstCall {
    AstKind kind;
    union Ast *function;
    struct Vector *arguments;
};

union Ast {
    AstKind kind;
    struct AstProg prog;
    struct AstXdef xdef;
    struct AstFdef fdef;
    struct AstVar var;
    struct AstLabel label;
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

typedef void (*AstWalkFunc)(union Ast **node, void *data);
void ast_walk(union Ast **node, AstWalkFunc pre, AstWalkFunc post, void *data);
void ast_show(union Ast *root);


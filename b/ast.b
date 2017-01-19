/* vim: set ft=blang : */

/* AST node kinds. */
A_PROG     1;  /* program node */
A_XDEF     2;  /* external variable declaration */
A_FDEF     3;  /* function declaration */

/* Statements */
A_VAR      4;  /* "auto" or "extrn" variable declaration */
A_LABEL    5;  /* Statement or "case" label */
A_SEQ      6;  /* Sequence of statements */
A_IFE      7;  /* "if else" statement */
A_WHILE    8;  /* "while" statement */
A_SWITCH   9;  /* "switch" statement */
A_GOTO    10;  /* "goto" statement */
A_VRTRN   11;  /* Void return statement */
A_RTRN    12;  /* "return" statement */
A_EXPR    13;  /* Expression statement */
A_VOID    14;  /* Void statement */

/* lvalues */
A_NAME    15;  /* Name */
A_IND     16;  /* Rvalue operator (aka indirection operator) */
A_INDEX   17;  /* Vector index */

/* rvalues */
A_NUM     18;  /* Numeric or character constant */
A_STR     19;  /* String constant */
A_ASSIGN  20;  /* Assignment operator */
A_PRE     21;  /* Pre-inc/dec operator */
A_POST    22;  /* Post-inc/dec operator */
A_UNARY   23;  /* Mathematical unary operator */
A_ADDR    24;  /* Lvalue operator (aka address operator) */
A_BIN     25;  /* Binary operator */
A_COND    26;  /* Conditional expression (?:) */
A_CALL    27;  /* Function call */


/* Since case labels must be a constant, it can be confusion to switch on the
 * AST node type.  This is a pre-formatted switch statement, which can by
 * copied.  Because comments cannot be nested this is a real function. */
stDummy(node) {
    switch (node[0]) {
    case  1:  /* A_PROG */
    case  2:  /* A_XDEF */
    case  3:  /* A_FDEF */
    case  4:  /* A_VAR */
    case  5:  /* A_LABEL */
    case  6:  /* A_SEQ */
    case  7:  /* A_IFE */
    case  8:  /* A_WHILE */
    case  9:  /* A_SWITCH */
    case 10:  /* A_GOTO */
    case 11:  /* A_VRTRN */
    case 12:  /* A_RTRN */
    case 13:  /* A_EXPR */
    case 14:  /* A_VOID */
    case 15:  /* A_NAME */
    case 16:  /* A_IND */
    case 17:  /* A_INDEX */
    case 18:  /* A_NUM */
    case 19:  /* A_STR */
    case 20:  /* A_ASSIGN */
    case 21:  /* A_PRE */
    case 22:  /* A_POST */
    case 23:  /* A_UNARY */
    case 24:  /* A_ADDR */
    case 25:  /* A_BIN */
    case 26:  /* A_COND */
    case 27:  /* A_CALL */
        ;
    }
}

stGet(kind) {
}

stRlse(node) {
}

stWalk(n, pre, post, data) {
    auto n;

    if (pre)
        pre(n, data);

    switch ((*n)[0]) {
    case  1:  /* A_PROG */
    case  2:  /* A_XDEF */
    case  3:  /* A_FDEF */
    case  4:  /* A_VAR */
    case  5:  /* A_LABEL */
    case  6:  /* A_SEQ */
    case  7:  /* A_IFE */
    case  8:  /* A_WHILE */
    case  9:  /* A_SWITCH */
    case 10:  /* A_GOTO */
    case 11:  /* A_VRTRN */
    case 12:  /* A_RTRN */
    case 13:  /* A_EXPR */
    case 14:  /* A_VOID */
    case 15:  /* A_NAME */
    case 16:  /* A_IND */
    case 17:  /* A_INDEX */
    case 18:  /* A_NUM */
    case 19:  /* A_STR */
    case 20:  /* A_ASSIGN */
    case 21:  /* A_PRE */
    case 22:  /* A_POST */
    case 23:  /* A_UNARY */
    case 24:  /* A_ADDR */
    case 25:  /* A_BIN */
    case 26:  /* A_COND */
    case 27:  /* A_CALL */
        ;
    }
break:

    if (post)
        post(n, data);
}

stShPre(node, data) {
}
stShPost(node, data) {
}

/* Debug printout of a syntax tree. */
stShow(node) {
}

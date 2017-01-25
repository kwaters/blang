/* vim: set ft=blang : */

/* AST node kinds. */
A_PROG     1;  /* program node */
A_XDEF     2;  /* external variable declaration */
A_FDEF     3;  /* function declaration */

/* Statements */
A_VAR      4;  /* "auto" or "extrn" variable declaration */
A_LABEL    5;  /* Statement label */
A_CLABEL   6;  /* "case" label */
A_SEQ      7;  /* Sequence of statements */
A_IFE      8;  /* "if else" statement */
A_WHILE    9;  /* "while" statement */
A_SWITCH  10;  /* "switch" statement */
A_GOTO    11;  /* "goto" statement */
A_VRTRN   12;  /* Void return statement */
A_RTRN    13;  /* "return" statement */
A_EXPR    14;  /* Expression statement */
A_VOID    15;  /* Void statement */

/* lvalues */
A_NAME    16;  /* Name */
A_IND     17;  /* Rvalue operator (aka indirection operator) */
A_INDEX   18;  /* Vector index */

/* rvalues */
A_NUM     19;  /* Numeric or character constant */
A_STR     20;  /* String constant */
A_ASSIGN  21;  /* Assignment operator */
A_PRE     22;  /* Pre-inc/dec operator */
A_POST    23;  /* Post-inc/dec operator */
A_UNARY   24;  /* Mathematical unary operator */
A_ADDR    25;  /* Lvalue operator (aka address operator) */
A_BIN     26;  /* Binary operator */
A_COND    27;  /* Conditional expression (?:) */
A_CALL    28;  /* Function call */

/* synthetic */
A_LOAD    29;  /* lvalue to rvalue Load */

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
    case  6:  /* A_CLABEL */
    case  7:  /* A_SEQ */
    case  8:  /* A_IFE */
    case  9:  /* A_WHILE */
    case  10:  /* A_SWITCH */
    case 11:  /* A_GOTO */
    case 12:  /* A_VRTRN */
    case 13:  /* A_RTRN */
    case 14:  /* A_EXPR */
    case 15:  /* A_VOID */
    case 16:  /* A_NAME */
    case 17:  /* A_IND */
    case 18:  /* A_INDEX */
    case 19:  /* A_NUM */
    case 20:  /* A_STR */
    case 21:  /* A_ASSIGN */
    case 22:  /* A_PRE */
    case 23:  /* A_POST */
    case 24:  /* A_UNARY */
    case 25:  /* A_ADDR */
    case 26:  /* A_BIN */
    case 27:  /* A_COND */
    case 28:  /* A_CALL */
        ;
    }
}

stGet(kind) {
}

stRlse(node) {
}

stWalk(n, pre, post, data) {
    if (pre)
        pre(n, data);

    switch ((*n)[0]) {
    case  1:  /* A_PROG */
    case  2:  /* A_XDEF */
    case  3:  /* A_FDEF */
    case  4:  /* A_VAR */
    case  5:  /* A_LABEL */
    case  6:  /* A_CLABEL */
    case  7:  /* A_SEQ */
    case  8:  /* A_IFE */
    case  9:  /* A_WHILE */
    case  10:  /* A_SWITCH */
    case 11:  /* A_GOTO */
    case 12:  /* A_VRTRN */
    case 13:  /* A_RTRN */
    case 14:  /* A_EXPR */
    case 15:  /* A_VOID */
    case 16:  /* A_NAME */
    case 17:  /* A_IND */
    case 18:  /* A_INDEX */
    case 19:  /* A_NUM */
    case 20:  /* A_STR */
    case 21:  /* A_ASSIGN */
    case 22:  /* A_PRE */
    case 23:  /* A_POST */
    case 24:  /* A_UNARY */
    case 25:  /* A_ADDR */
    case 26:  /* A_BIN */
    case 27:  /* A_COND */
    case 28:  /* A_CALL */
    case 29:  /* A_LOAD */
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

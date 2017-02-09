/* vim: set ft=blang : */

/* AST node kinds. */
A_PROG     1;  /* defs -- program node */
A_XDEF     2;  /* name, sz, ilist -- external variable declaration */
A_FDEF     3;  /* name, args, stmt -- function declaration */

/* Statements */
A_VAR      4;  /* vars, stmt, isAuto -- "auto" or "extrn" declaration */
A_LABEL    5;  /* stmt, name -- Statement label */
A_CLABEL   6;  /* "stmt, nconst -- case" label */
A_SEQ      7;  /* stmts -- Sequence of statements */
A_IFE      8;  /* cond, yes, no -- "if else" statement */
A_WHILE    9;  /* cond, stmt -- "while" statement */
A_SWITCH  10;  /* cond, stmt -- "switch" statement */
A_GOTO    11;  /* expr -- "goto" statement */
A_VRTRN   12;  /* -- Void return statement */
A_RTRN    13;  /* expr -- "return" statement */
A_EXPR    14;  /* expr -- Expression statement */
A_VOID    15;  /* -- Void statement */

/* lvalues */
A_NAME    16;  /* name -- Name */
A_IND     17;  /* expr -- Rvalue operator (aka indirection operator) */
A_INDEX   18;  /* vec, index -- Vector index */

/* rvalues */
A_NUM     19;  /* number -- Numeric or character constant */
A_STR     20;  /* base, len -- String constant */
A_ASSIGN  21;  /* lhs, rhs, op -- Assignment operator */
A_PRE     22;  /* expr, val -- Pre-inc/dec operator */
A_POST    23;  /* expr, val -- Post-inc/dec operator */
A_UNARY   24;  /* expr, op -- Mathematical unary operator */
A_ADDR    25;  /* expr -- Lvalue operator (aka address operator) */
A_BIN     26;  /* lhs, rhs, op -- Binary operator */
A_COND    27;  /* cond, yes, no -- Conditional expression (?:) */
A_CALL    28;  /* expr, args -- Function call */

/* synthetic */
A_LOAD    29;  /* expr -- lvalue to rvalue Load */

/* Unary operator kinds. */
U_NEG      1;
U_NOT      2;

/* Binary operator kinds. */
O_OR      1;
O_AND     2;
O_EQ      3;
O_NEQ     4;
O_LT      5;
O_LTE     6;
O_GT      7;
O_GTE     8;
O_SHIFTL  9;
O_SHIFTR 10;
O_MINUS  11;
O_PLUS   12;
O_REM    13;
O_MUL    14;
O_DIV    15;


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
    case 10:  /* A_SWITCH */
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
}

stGet(kind, lineNo) {
    extrn getvec;
    extrn stSz;
    auto n;

    n = getvec(stSz(kind) - 1);
    n[0] = kind;
    n[1] = lineNo;
    return (n);
}

/* ast release single node. */
stRlse(node) {
    extrn rlsevec;
    extrn vcRlse;
    extrn stSz;

    auto kind;
    kind = node[0];

    /* Release emdedded vectors. */
    switch (kind) {
    case  1:  /* A_PROG */
    case  4:  /* A_VAR */
    case  7:  /* A_SEQ */
        vcRlse(node[2]);
        goto break;

    case  3:  /* A_FDEF */
    case 28:  /* A_CALL */
        vcRlse(node[3]);
        goto break;

    case  2:  /* A_XDEF */
        vcRlse(node[4]);
        goto break;

    case 20:  /* A_STR */
        rlsevec(node[2] - 1, node[2][-1]);
        goto break;
    }
break:
    rlsevec(node, stSz(kind));
}

/* ast release node recursive. */
stRlseR(node) {
    extrn stRlseRH;
    stRlseRH(&node);
}

/* ast release node recursive helper. */
stRlseRH(node) {
    extrn stApply, stRlse;
    stApply(*node, stRlseRH);
    stRlse(*node);
}

/* Vector size of an AST node of kind |kind|. */
stSz(kind) {
    extrn ice;

    switch (kind) {
    case 12:  /* A_VRTRN */
    case 15:  /* A_VOID */
        return (2);

    case  1:  /* A_PROG */
    case  7:  /* A_SEQ */
    case 11:  /* A_GOTO */
    case 13:  /* A_RTRN */
    case 14:  /* A_EXPR */
    case 16:  /* A_NAME */
    case 17:  /* A_IND */
    case 19:  /* A_NUM */
    case 25:  /* A_ADDR */
    case 29:  /* A_LOAD */
        return (3);

    case  5:  /* A_LABEL */
    case  6:  /* A_CLABEL */
    case  9:  /* A_WHILE */
    case 10:  /* A_SWITCH */
    case 18:  /* A_INDEX */
    case 20:  /* A_STR */
    case 22:  /* A_PRE */
    case 23:  /* A_POST */
    case 24:  /* A_UNARY */
    case 28:  /* A_CALL */
        return (4);

    case  2:  /* A_XDEF */
    case  3:  /* A_FDEF */
    case  4:  /* A_VAR */
    case  8:  /* A_IFE */
    case 21:  /* A_ASSIGN */
    case 26:  /* A_BIN */
    case 27:  /* A_COND */
        return (5);
    }
    ice("Unknown AST kind");
}

/* For every child of node |n|, call f(&child).
 *
 * Note: stApply takes a pointer to an AST node, but f takes a pointer to a
 * pointer to an AST node.  Changing *child in f, will change the child of the
 * AST node.
 */
stApply(n, f) {
    extrn ice;
    extrn vcApply;

    switch (n[0]) {
    case  1:  /* A_PROG */
    case  7:  /* A_SEQ */
        vcApply(n[2], f);
        return;

    case  2:  /* A_XDEF */
        /* TODO: Irregular */
        vcApply(n[4], f);
        return;

    case  3:  /* A_FDEF */
        /* TODO: Irregular */
        f(&n[4]);
        return;

    case  4:  /* A_VAR */
        /* TODO: Irregular */
        f(&n[3]);
        return;

    case  5:  /* A_LABEL */
    case  6:  /* A_CLABEL */
    case 11:  /* A_GOTO */
    case 13:  /* A_RTRN */
    case 14:  /* A_EXPR */
    case 17:  /* A_IND */
    case 22:  /* A_PRE */
    case 23:  /* A_POST */
    case 24:  /* A_UNARY */
    case 25:  /* A_ADDR */
    case 29:  /* A_LOAD */
        f(&n[2]);
        return;

    case  8:  /* A_IFE */
    case 27:  /* A_COND */
        f(&n[2]);
        f(&n[3]);
        f(&n[4]);
        return;

    case  9:  /* A_WHILE */
    case 10:  /* A_SWITCH */
    case 18:  /* A_INDEX */
    case 21:  /* A_ASSIGN */
    case 26:  /* A_BIN */
        f(&n[2]);
        f(&n[3]);
        return;

    case 12:  /* A_VRTRN */
    case 15:  /* A_VOID */
    case 16:  /* A_NAME */
    case 19:  /* A_NUM */
    case 20:  /* A_STR */
        return;

    case 28:  /* A_CALL */
        f(&n[2]);
        vcApply(n[3], f);
        return;
    }
    ice("Unknown AST kind");
}

/* Debug printout of a syntax tree. */
stShow(node) {
    extrn stSNode;
    stSNode(&node);
}

/* Indentation level for stSNode(). */
stIndent 0;

/* Work function for stShow(). */
stSNode(n) {
    extrn printf;
    extrn stIndent;
    extrn stApply;
    auto i;

    i = 0;
    while (i++ < stIndent)
        printf("  ");

    printf("NODE: %d (%d)*n", *n, (*n)[0]);

    stIndent++;
    stApply(*n, stSNode);
    stIndent--;
}

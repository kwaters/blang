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

/* Should '}' be printed for the stNode(). */

/* Indent the current line |stIndent| spaces. */
stSNI() {
    extrn printf;
    extrn stIndent;
    auto i;
    i = 0;
    while (i++ < stIndent)
        printf("  ");
}

/* Print a name. */
stSName(name) {
    extrn putchar;
    auto c;
    while (name) {
        putchar(name & 0377);
        name =>> 8;
    }
}

/* Print a string. */
stSStr(s, len)
{
    extrn putchar, printf, char;
    auto i, c;

    i = 0;
    while (i < len) {
        c = char(s, i++);
        switch (c) {
        case '*0': printf("**0"); goto loop;
        case '*e': printf("**e"); goto loop;
        case '*t': printf("**t"); goto loop;
        case '*n': printf("**n"); goto loop;
        case '**': printf("****"); goto loop;
        case '*"': printf("***""); goto loop;
        }
        if (c >= ' ' & c <= '~')
            putchar(c);
        else
            printf("**?");
loop:;
    }
}

/* Print a binary op */
stSBOp(op)
{
    extrn printf, ice;

    /* TODO(kwaters): Is this better done with a table? */
    switch (op) {
    case  1: printf("OR");     return;
    case  2: printf("AND");    return;
    case  3: printf("EQ");     return;
    case  4: printf("NEQ");    return;
    case  5: printf("LT");     return;
    case  6: printf("LTE");    return;
    case  7: printf("GT");     return;
    case  8: printf("GTE");    return;
    case  9: printf("SHIFTL"); return;
    case 10: printf("SHIFTR"); return;
    case 11: printf("MINUS");  return;
    case 12: printf("PLUS");   return;
    case 13: printf("REM");    return;
    case 14: printf("MUL");    return;
    case 15: printf("DIV");    return;
    }
    ice("Unknown binary operation");
}

/* Print a unary op */
stSUOp(op)
{
    extrn printf, ice;

    /* TODO(kwaters): Is this better done with a table? */
    switch(op) {
    case  1: printf("NEG"); return;
    case  2: printf("NOT"); return;
    }
    ice("Unknown unary operation");
}

/* Work function for stShow(). */
stSNode(node) {
    extrn stIndent;
    extrn printf, putchar, printn, ice;
    extrn stApply, stSNI, stSName, stSStr, stSBOp, stSUOp;
    extrn vcSize;
    extrn exit;

    auto n, i, sz;

    stSNI();

    /* TODO(kwaters): Is this better done with a table? */
    n = *node;
    switch (n[0]) {
    case  1:  /* A_PROG */
        printf("PROG {*n");
        goto close;

    case  2:  /* A_XDEF */
        printf("XDEF ");
        stSName(n[2]);
        printf(" %d {*n", n[3]);
        goto close;

    case  3:  /* A_FDEF */
        printf("FDEF ");
        stSName(n[2]);
        sz = vcSize(n[3]);
        if (sz == 0) {
            printf("() {*n");
            goto close;
        }
        i = 0;
        while (i < sz) {
            printf(i == 0 ? "(" : ", ");
            stSName(n[3][i++]);
        }
        printf(") {*n");
        goto close;

    case  4:  /* A_VAR */
        if (n[4]) {
            /* is auto */
            printf("VAR AUTO ");
            i = 0;
            sz = vcSize(n[2]);
            while (i < sz) {
                printf(i == 0 ? "[" : ", ");
                stSName(n[2][i]);
                if (n[2][i + 1] >= 0) {
                    putchar(" ");
                    printn(n[2][i + 1], 10);
                }
                i =+ 2;
            }
        } else {
            printf("VAR EXTRN ");
            i = 0;
            sz = vcSize(n[2]);
            while (i < sz) {
                printf(i == 0 ? "[" : ", ");
                stSName(n[2][i++]);
            }
        }
        printf("] {*n");
        goto close;

    case  5:  /* A_LABEL */
        printf("LABEL ");
        stSName(n[3]);
        printf(" {*n");
        goto close;

    case  6:  /* A_CLABEL */
        printf("CLABEL %d {*n", n[3]);
        goto close;

    case  7:  /* A_SEQ */
        printf("SEQ {*n");
        goto close;

    case  8:  /* A_IFE */
        printf("IFE {*n");
        goto close;

    case  9:  /* A_WHILE */
        printf("WHILE {*n");
        goto close;

    case 10:  /* A_SWITCH */
        printf("SWITCH {*n");
        goto close;

    case 11:  /* A_GOTO */
        printf("GOTO {*n");
        goto close;

    case 12:  /* A_VRTRN */
        printf("VRTRN*n");
        return;

    case 13:  /* A_RTRN */
        printf("RTRN {*n");
        goto close;

    case 14:  /* A_EXPR */
        printf("EXPR {*n");
        goto close;

    case 15:  /* A_VOID */
        printf("VOID*n");
        return;

    case 16:  /* A_NAME */
        printf("NAME ");
        stSName(n[2]);
        printf("*n");
        return;

    case 17:  /* A_IND */
        printf("IND {*n");
        goto close;

    case 18:  /* A_INDEX */
        printf("INDEX {*n");
        goto close;

    case 19:  /* A_NUM */
        printf("NUM %d*n", n[2]);
        return;

    case 20:  /* A_STR */
        printf("STR *"");
        stSStr(n[2], n[3]);
        printf("*"*n");
        return;

    case 21:  /* A_ASSIGN */
        if (n[4]) {
            printf("ASSIGN ");
            stSBOp(n[4]);
            printf(" {*n");
        } else {
            printf("ASSIGN {*n");
        }
        goto close;

    case 22:  /* A_PRE */
        printf("PRE %d {*n", n[3]);
        goto close;

    case 23:  /* A_POST */
        printf("POST %d {*n", n[3]);
        goto close;

    case 24:  /* A_UNARY */
        printf("UNARY ");
        stSUOp(n[3]);
        printf(" {*n");
        goto close;

    case 25:  /* A_ADDR */
        printf("ADDR {*n");
        goto close;

    case 26:  /* A_BIN */
        printf("BIN ");
        stSBOp(n[4]);
        printf(" {*n");
        goto close;

    case 27:  /* A_COND */
        printf("COND {*n");
        goto close;

    case 28:  /* A_CALL */
        printf("CALL {*n");
        goto close;

    case 29:  /* A_LOAD */
        printf("LOAD {*n");
        goto close;
    }
    ice("Unknown AST node kind");

close:
    stIndent++;
    stApply(n, stSNode);
    stIndent--;

    stSNI();
    printf("}*n");
}

/* vim: set ft=blang : */


/* Current token. */
yTok[4];  /* lTokenSz */

/* Next token. */
yNext[4];  /* lTokenSz */

yError(s, lineNo) {
    extrn exit, printf;

    printf("error: %s (%d)*n", s, lineNo);
    exit();
}

/* Consume one token. */
yShift() {
    extrn memcpy;
    extrn ice;
    extrn lTokenSz, lMain;
    extrn yTok, yNext;

    memcpy(yTok, yNext, lTokenSz);

    if (lMain(yNext))
        ice("Lexer did not produce a token");
}

/* Consume a token.  Signal an error if the consumed token was not of type
 * |kind|.
 */
yExpect(kind) {
    extrn error;
    extrn yTok, yShift, yError;

    if (yTok[0] == kind) {
        yShift();
        return;
    }

    if (kind == ']')
        yError("[]", yTok[3]);
    if (kind == ')')
        yError("()", yTok[3]);
    if (kind == '}')
        yError("$)", yTok[3]);
    yError("xx", yTok[3]);
}

yMain() {
    extrn T_NAME;
    extrn A_PROG;
    extrn vcGet, vcPush;
    extrn yShift, yDef, yExpect, yTok;
    extrn stGet;

    auto program, n;

    /* Prime the two token lookahead. */
    yShift();
    yShift();

    program = vcGet();
    while (yTok[0] == T_NAME) {
        vcPush(&program, yDef());
    }
    yExpect('*e');

    n = stGet(A_PROG, 1);
    n[2] = program;
    return (n);
}

yDef() {
    extrn T_NUMBER, T_NAME;
    extrn A_XDEF;
    extrn ice;
    extrn yTok, yShift, yExpect, yFdef, yIval, yError, yNConst;
    extrn stGet;
    extrn vcGet, vcPush;

    auto name, lineNo, ival, ivals, sz, n;

    if (yTok[0] != T_NAME)
        ice("Definitions start with a T_NAME");

    name = yTok[1];
    lineNo = yTok[3];
    yShift();

    if (yTok[0] == '(')
        return (yFdef(name, lineNo));

    /* Array size. */
    if (yTok[0] == '[') {
        yShift();
        /* TODO: string constants. */
        if (!yNConst(&sz))
            sz = 0;
        yExpect(']');
    } else {
        sz = -1;
    }

    /* Initializer list. */
    ivals = vcGet();
    if (ival = yIval()) {
        vcPush(&ivals, ival);
        while (yTok[0] == ',') {
            yShift();
            if (!(ival = yIval()))
                yError("xx", yTok[3]);  /* Expected ival. */
            vcPush(&ivals, ival);
        }
    }
    yExpect(';');

    n = stGet(A_XDEF, lineNo);
    n[2] = name;
    n[3] = sz;
    n[4] = ivals;
    return (n);
}

yIval() {
    extrn yConst, yName;
    auto ival;

    if (ival = yConst())
        return (ival);
    return (yName());
}

/* Numeric constant.  success = yNConst(&num); */
yNConst(num)
{
    extrn T_NUMBER, T_CHAR;
    extrn yTok;
    extrn yShift;

    if (yTok[0] == T_NUMBER | yTok[0] == T_CHAR) {
        *num = yTok[1];
        yShift();
        return (1);
    }
    return (0);
}

yConst() {
    extrn A_STR, A_NUM;
    extrn T_STRING;
    extrn stGet;
    extrn yTok, yNConst, yShift;

    auto n, num;

    if (yTok[0] == T_STRING) {
        n = stGet(A_STR, yTok[3]);
        n[2] = yTok[1];
        n[3] = yTok[2];
        yShift();
        return (n);
    }
    if (yNConst(&num)) {
        n = stGet(A_NUM, yTok[3]);
        n[2] = num;
        return (n);
    }
    return (0);
}

yName() {
    extrn T_NAME;
    extrn A_NAME;
    extrn stGet;
    extrn yTok;

    auto n;

    if (yTok[0] != T_NAME)
        return (0);

    /* TODO: extrn hack goes here. */
    n = stGet(A_NAME, yTok[3]);
    n[2] = yTok[1];
    return (n);
}

yFdef(name, lineNo) {
    extrn A_FDEF;
    extrn yTok;
    extrn ice;
    extrn stGet;
    extrn yStmt, yNList, yExpect, yShift;

    auto n;

    if (yTok[0] != '(')
        ice("FDefs start with a '('");
    yShift();

    n = stGet(A_FDEF, lineNo);
    n[2] = name;
    n[3] = yNList();
    yExpect(')');
    n[4] = yStmt();
    return (n);
}

/* Statement
 *
 * Never returns 0.
 */
yStmt() {
    extrn yTok, yNext;
    extrn A_LABEL, A_IFE, A_VOID, A_WHILE, A_SWITCH, A_GOTO, A_VRTRN, A_RTRN,
          A_EXPR, A_CLABEL, A_SEQ, A_VAR;
    extrn T_ELSE, T_NAME, T_NUMBER;
    extrn stGet;
    extrn vcGet, vcPush;
    extrn yExpr, yCBody, yShift, yExpect, yError, yNList, yAList, yNConst;
    extrn ice;

    auto n;

    switch (yTok[0]) {
    case 271:  /* T_AUTO */
        n = stGet(A_VAR, yTok[3]);
        yShift();
        n[2] = yAList();
        yExpect(';');
        n[3] = yStmt();
        n[4] = 1;
        return (n);

    case 274:  /* T_EXTRN */
        n = stGet(A_VAR, yTok[3]);
        yShift();
        /* Ensure at least one name. */
        if (yTok[0] != T_NAME)
            yError("sx", yTok[3]);  /* Expected NAME. */
        n[2] = yNList();
        yExpect(';');
        n[3] = yStmt();
        n[4] = 0;
        return (n);

    case 265:  /* T_NAME */
        /* lookahead for ':' */
        if (yNext[0] != ':')
            goto lExpr;

        n = stGet(A_LABEL, yTok[3]);
        n[3] = yTok[1];
        yShift();
        yShift();
        n[2] = yStmt();
        return (n);

    case 272:  /* T_CASE */
        n = stGet(A_CLABEL, yTok[3]);
        yShift();
        /* TODO: string constants. */
        if (!yNConst(&n[3]))
            yError("xx", yTok[3]);
        yExpect(':');
        n[2] = yStmt();
        return (n);

    case '{':
        n = stGet(A_SEQ, yTok[3]);
        yShift();
        n[2] = vcGet();
        while (yTok[0] != '}') {
            vcPush(&n[2], yStmt());
        }
        yShift();
        return (n);

    case 276:  /* T_IF */
        n = yCBody(A_IFE);
        /* Else is greedy.  Dangling else is solved by binding to the most
         * recent if. */
        if (yTok[0] == T_ELSE) {
            yShift();
            n[4] = yStmt();
        } else {
            n[4] = stGet(A_VOID, n[1]);
        }
        return (n);

    case 279:  /* T_WHILE */
        return (yCBody(A_WHILE));

    case 278:  /* T_SWITCH */
        return (yCBody(A_SWITCH));

    case 275:  /* T_GOTO */
        yShift();
        n = stGet(A_GOTO, yTok[3]);
        n[2] = yExpr();
        yExpect(';');
        return (n);

    case 277:  /* T_RETURN */
        yShift();
        if (yTok[0] == ';')
            return (stGet(A_VRTRN, yTok[3]));

        n = stGet(A_RTRN, yTok[3]);
        n[2] = yExpr();
        yExpect(';');
        return (n);

    case ';':
        n = stGet(A_VOID, yTok[3]);
        yShift();
        return (n);
    }

lExpr:
    n = stGet(A_EXPR, yTok[3]);
    n[2] = yExpr();
    yExpect(';');
    return (n);
}

/* Conditional body (while, switch, if) */
yCBody(kind) {
    extrn yTok;
    extrn stGet;
    extrn yShift, yExpect, yExpr, yStmt;

    auto n;

    n = stGet(kind, yTok[3]);
    yShift();

    yExpect('(');
    n[2] = yExpr();
    yExpect(')');
    n[3] = yStmt();
    return (n);
}

/* Name list */
yNList() {
    extrn T_NAME;
    extrn yTok;
    extrn yError, yShift;
    extrn vcGet, vcPush;

    auto args;

    args = vcGet();
    if (yTok[0] != T_NAME)
        return (args);

    goto list;
    while (yTok[0] == ',') {
        yShift();
        if (yTok[0] != T_NAME)
            yError("xx", yTok[3]);  /* Expected name. */
list:
        vcPush(&args, yTok[1]);
        yShift();
    }

    return (args);
}

/* Auto list */
yAList() {
    extrn yTok;
    extrn T_NUMBER, T_NAME;
    extrn vcGet, vcPush;
    extrn yShift, yExpect;

    auto autos;

    autos = vcGet();

    goto list;
    while (yTok[0] == ',') {
        yShift();
list:
        /* Push before consuming.  If we don't have a T_NAME token, we'll have
         * pushed garbage, but the compiler will error out anyway. */
        vcPush(&autos, yTok[1]);
        yExpect(T_NAME);

        if (yTok[0] == T_NUMBER) {
            /* TODO: String constants. */
            vcPush(&autos, yTok[1]);
            yShift();
        } else {
            vcPush(&autos, -1);
        }
    }
    return (autos);
}

/* Expression list */
yEList() {
    extrn yTok;
    extrn vcGet, vcPush;
    extrn yExpr, yShift;
    auto exprs;

    exprs = vcGet();
    /* This is sort of hacky, since yExpr() raises an error, we instead check
     * for the end of the list. */
    if (yTok[0] == ')')
        return (exprs);

    while (1) {
        vcPush(&exprs, yExpr());
        if (yTok[0] != ',')
            return (exprs);
        yShift();
    }
}

/* Precedence table.
 *
 * Higher precendence numbers bind tighter.
 *
 * T_ASSIGN precendence = 1
 * ? :      precendence = 2
 *
 * TOKEN, precedence level, operator code
 */
yPTable[]
    '|',  3,  1,
    '&',  4,  2,
    261,  5,  3,  /* == */
    266,  5,  4,  /* != */
    '<',  6,  5,
    264,  6,  6,  /* <= */
    '>',  6,  7,
    262,  6,  8,  /* >= */
    268,  7,  9,  /* << */
    269,  7, 10,  /* >> */
    '-',  8, 11,
    '+',  8, 12,
    '%',  9, 13,
    '**', 9, 14,
    '/',  9, 15,
    0;

/* Returns the row in the precdence table for a binary operator.  Returns 0 if
 * the current token is not a binary operator. */
yPrec(kind) {
    extrn yPTable;
    auto p;

    p = yPTable;
    while (*p) {
        if (kind == *p)
            return (p);
        p =+ 3;
    }
    return (0);
}

/* Parse an expression.
 *
 * Never returns 0. */
yExpr() {
    extrn yBOp;
    return (yBOp(1));
}

/* Precedence climbing parser. */
yBOp(minPrec) {
    extrn T_ASSIGN;
    extrn A_BIN, A_ASSIGN, A_COND;
    extrn yTok;
    extrn stGet;
    extrn yPrec, yTerm, yShift, yExpect, yExpr;

    auto n, op, lhs, mid, rhs;

    lhs = yTerm();

    while (1) {
        if (yTok[0] == T_ASSIGN) {
            if (1 < minPrec)
                return (lhs);

            /* Lookup =<<op>> */
            op = yPrec(yTok[1]);
            if (op)
                op = op[2];

            yShift();
            rhs = yBOp(1);

            n = stGet(A_ASSIGN);
            n[2] = lhs;
            n[3] = rhs;
            n[4] = op;
            lhs = n;
        } else if (yTok[0] == '?') {
            if (2 < minPrec)
                return (lhs);

            yShift();
            mid = yExpr();
            yExpect(':');
            rhs = yBOp(2);

            n = stGet(A_COND);
            n[2] = lhs;
            n[3] = mid;
            n[4] = rhs;
            lhs = n;
        } else {
            op = yPrec(yTok[0]);
            if (!op)
                return (lhs);
            if (op[1] < minPrec)
                return (lhs);

            yShift();
            rhs = yBOp(op[1] + 1);

            n = stGet(A_BIN);
            n[2] = lhs;
            n[3] = rhs;
            n[4] = op[2];
            lhs = n;
        }
    }
}

/* Parse primary expressions and unary operators.
 *
 * Never returns 0. */
yTerm() {
    extrn A_IND, A_PRE, A_UNARY, A_STR, A_NAME, A_NUM, A_POST, A_CALL, A_INDEX, A_ADDR;
    extrn U_NEG, U_NOT;
    extrn T_INC;
    extrn yTok;
    extrn yShift, yExpr, yExpect, yError, yEList;
    extrn stGet;

    auto n, sufn;

    /* Prefix and primary expression */
    switch (yTok[0]) {
    case '(':
        yShift();
        n = yExpr();
        yExpect(')');
        goto suffix;

    /* prefixes */
    case '**':
        n = stGet(A_IND, yTok[3]);
        yShift();
        n[2] = yTerm();
        return (n);

    case 263:  /* T_INC */
    case 260:  /* T_DEC */
        n = stGet(A_PRE, yTok[3]);
        n[3] = yTok[0] == T_INC ? 1 : -1;
        yShift();
        n[2] = yTerm();
        return(n);

    case '-':
    case '!':
        n = stGet(A_UNARY, yTok[3]);
        n[3] = yTok[0] == '-' ? U_NEG : U_NOT;
        yShift();
        n[2] = yTerm();
        return (n);

    case '&':
        n = stGet(A_ADDR, yTok[3]);
        yShift();
        n[2] = yTerm();
        return (n);

    case 270:  /* T_STRING */
        n = stGet(A_STR, yTok[3]);
        n[2] = yTok[1];
        n[3] = yTok[2];
        yShift();
        goto suffix;

    case 265:  /* T_NAME */
        n = stGet(A_NAME, yTok[3]);
        n[2] = yTok[1];
        yShift();
        goto suffix;

    case 259:  /* CHAR */
    case 267:  /* T_NUMBER */
        n = stGet(A_NUM, yTok[3]);
        n[2] = yTok[1];
        yShift();
        goto suffix;
    }

    yError("ex", yTok[3]);  /* Expected expression. */
    return (0);

suffix:
    switch (yTok[0]) {
    case 263:  /* T_INC */
    case 260:  /* T_DEC */
        sufn = stGet(A_POST, yTok[3]);
        sufn[2] = n;
        sufn[3] = yTok[0] == T_INC ? 1 : -1;
        yShift();
        n = sufn;
        goto suffix;

    case '(':
        sufn = stGet(A_CALL, yTok[3]);
        sufn[2] = n;
        yShift();
        sufn[3] = yEList();
        yExpect(')');
        n = sufn;
        goto suffix;

    case '[':
        sufn = stGet(A_INDEX, yTok[3]);
        sufn[2] = n;
        yShift();
        sufn[3] = yExpr();
        yExpect(']');
        n = sufn;
        goto suffix;
    }

    return (n);
}

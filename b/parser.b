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
 * |kind|. */
yExpect(kind) {
    extrn error;
    extrn yTok, yShift, yError;

    if (yTok[0] != kind)
        yError("xx", yTok[3]);
    yShift();
}

yMain() {
    extrn vcGet, vcPush;
    extrn T_NAME;
    extrn yShift, yDef, yExpect, yTok;

    auto program;

    /* Prime the two token lookahead. */
    yShift();
    yShift();

    program = vcGet();
    while (yTok[0] == T_NAME) {
        vcPush(&program, yDef());
    }
    yExpect('*d');
}

yDef() {
    extrn ice;
    extrn T_NUMBER, T_NAME;
    extrn yTok, yShift, yExpect, yFdef, yIval, yError;
    extrn vcGet, vcPush;

    auto name, lineNo, ival, ivals, sz;

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
        if (yTok[0] == T_NUMBER) {
            sz = yTok[1];
            yShift();
        } else {
            sz = 0;
        }
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

    return (0);
}

yIval() {
    extrn yConst, yName;
    auto ival;

    if (ival = yConst())
        return (ival);
    return (yName());
}

yConst() {
    extrn A_STR, A_NUM;
    extrn T_NUMBER, T_STRING;
    extrn stGet;
    extrn yTok;

    auto n;

    if (yTok[0] == T_STRING) {
        n = stGet(A_STR, yTok[3]);
        n[2] = yTok[1];
        n[3] = yTok[2];
        return (n);
    }
    if (yTok[0] == T_NUMBER) {
        n = stGet(A_NUM, yTok[3]);
        n[2] = yTok[1];
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
          A_EXPR, A_EXTRN, A_CLABEL, A_SEQ, A_AUTO;
    extrn T_ELSE, T_NAME, T_NUMBER;
    extrn stGet;
    extrn vcGet, vcPush;
    extrn yExpr, yCBody, yShift, yExpect, yError, yNList, yAList;
    extrn ice;

    auto n;

    switch (yTok[0]) {
    case 271:  /* T_AUTO */
        n = stGet(A_AUTO, yTok[3]);
        yShift();
        n[2] = yAList();
        yExpect(';');
        n[3] = yStmt();
        return (n);

    case 274:  /* T_EXTRN */
        n = stGet(A_EXTRN, yTok[3]);
        yShift();
        /* Ensure at least one name. */
        if (yTok[0] != T_NAME)
            yError("xx", yTok[3]);  /* Expected NAME. */
        n[2] = yNList();
        yExpect(';');
        n[3] = yStmt();
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
        n[3] = yTok[1];
        yExpect(T_NUMBER);
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
        if (!(n[2] = yExpr()))
            yError("xx", yTok[3]);  /* Expected expression. */
        yExpect(';');
        return (n);

    case 277:  /* T_RETURN */
        yShift();
        if (yTok[0] == ';')
            return (stGet(A_VRTRN, yTok[3]));

        n = stGet(A_RTRN, yTok[3]);
        if (!(n[2] = yExpr()))
            yError("xx", yTok[3]);  /* Expected expression. */
        yExpect(';');
        return (n);

    case ';':
        n = stGet(A_VOID, yTok[3]);
        yShift();
        return (n);
    }

lExpr:
    n = stGet(A_EXPR, yTok[3]);
    if (!(n[2] = yExpr()))
        yError("Expected expression.", yTok[3]);
    return (n);
}

/* Conditional body (while, switch, if) */
yCBody(kind) {
    extrn yTok;
    extrn stGet;
    extrn yShift, yExpect, yExpr, yError, yStmt;

    auto n;

    n = stGet(kind, yTok[3]);
    yShift();

    yExpect('(');
    if (!(n[2] = yExpr()))
        yError("xx", yTok[3]); /* expected expression */
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

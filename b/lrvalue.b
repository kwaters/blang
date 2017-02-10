/* vim: set ft=blang : */

/* Left-Right value resolution pass.
 *
 * After lrvalue_pass is complete all A_IND, A_ADDR, and A_INDEX nodes will be
 * eliminated and A_LOAD nodes will have been inserted.
 */
lrPass(root) {
    extrn stApply;
    extrn lrPassI;
    stApply(root, lrPassI);
}

/* lrPassI(&node) -- implementation */
lrPassI(pnode) {
    extrn A_BIN, O_PLUS;
    extrn stGet, stRlse, stApply;
    extrn vcApply;
    extrn lrCheckL, lrForceR;

    auto n, temp;
    n = *pnode;

    switch (n[0]) {
    case  8:  /* A_IFE */
    case  9:  /* A_WHILE */
    case 10:  /* A_SWITCH */
    case 11:  /* A_GOTO */
    case 13:  /* A_RTRN */
    case 14:  /* A_EXPR */
        lrForceR(&n[2]);
        goto break;

    case 17:  /* A_IND */
        lrForceR(&n[2]);
        *pnode = n[2];
        stRlse(n);
        /* Visit the hoisted node. */
        lrPassI(pnode);
        return;

    case 18:  /* A_INDEX */
        lrForceR(&n[2]);
        lrForceR(&n[3]);

        /* Replace with addition. */
        temp = stGet(A_BIN, n[1]);
        temp[2] = n[2];
        temp[3] = n[3];
        temp[4] = O_PLUS;
        *pnode = temp;
        stRlse(n);
        n = temp;
        goto break;

    case 26:  /* A_BIN */
        lrForceR(&n[2]);
        lrForceR(&n[3]);
        goto break;

    case 21:  /* A_ASSIGN */
        lrCheckL(&n[2]);
        lrForceR(&n[3]);
        goto break;

    case 22:  /* A_PRE */
    case 23:  /* A_POST */
        lrCheckL(&n[2]);
        goto break;

    case 24:  /* A_UNARY */
        lrForceR(&n[2]);
        goto break;

    case 25:  /* A_ADDR */
        lrCheckL(&n[2]);
        *pnode = n[2];
        stRlse(n);
        /* Visit the hoisted node. */
        lrPassI(pnode);
        return;

    case 27:  /* A_COND */
        lrForceR(&n[2]);
        lrForceR(&n[3]);
        lrForceR(&n[4]);
        goto break;

    case 28:  /* A_CALL */
        lrForceR(&n[2]);
        vcApply(n[3], lrForceR);
        goto break;
    }
break:
    stApply(n, lrPassI);
}

/* lrForceR(&node) */
lrForceR(pnode) {
    extrn A_LOAD;
    extrn ice;
    extrn stGet;
    auto n;
    n = *pnode;

    switch (n[0]) {
    case 16:  /* A_NAME */
    case 17:  /* A_IND */
    case 18:  /* A_INDEX */
        goto load;

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
        /* Already an rvalue */
        return;
    }
    ice("Unexpected node in lrForceR");

    /* Insert load. */
load:
    *pnode = stGet(A_LOAD);
    (*pnode)[2] = n;
}

/* lrCheckL(&node) */
lrCheckL(pnode) {
    extrn ice;
    extrn error;
    auto n;

    n = *pnode;
    switch (n[0]) {
    case 16:  /* A_NAME */
    case 17:  /* A_IND */
    case 18:  /* A_INDEX */
        return;

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
        error("lv", 0, n[1]);
    }

    ice("Unexpected node in lrForceR");
}

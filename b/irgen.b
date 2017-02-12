/* vim: set ft=blang : */

igFunc() {
}

igNode(pnode) {
    n = *pnode;

    switch (n[0]) {
    case  4:  /* A_VAR */
    case  5:  /* A_LABEL */
        nte = ntAdd(n[3], n[1], NT_INT);
        nte[2] = bbSplit();
        igNode(n[2]);
        return (0);

    case  6:  /* A_CLABEL */
        block = bbSplit();
        if (igCaseT) {
            vcPush(&igCaseT, n[3]);
            vcPush(&igCaseT, block);
        }
        igNode(n[2]);
        return(0);

    case  7:  /* A_SEQ */
        stApply(n, igNode);
        return;

    case  8:  /* A_IFE */
        v = igNode(n[2]);

        yes = bbGet();
        no = bbGet();
        exit = bbGet();

        irI(I_IF, v, yes, no);

        bbCur = yes;
        igNode(n[3]);
        irI(I_J, exit);

        bbCur = no;
        igNode(n[4]);
        irI(I_J, exit);

        bbCur = exit;
        return (0);

    case  9:  /* A_WHILE */
        body = bbGet();
        exit = bbGet();

        head = bbSplit();
        v = igNode(n[2]);
        irI(I_IF, v, body, exit);

        bbCur = body;
        igNode(n[3]);
        irI(I_J, head);

        bbCur = exit;
        return (0);

    case 10:  /* A_SWITCH */
        v = igNode(n[2]);
        block = bbCur;

        lCaseT = igCaseT;
        igCaseT = vcGet();
        bbCur = body = bbGet();
        igNode(n[3]);
        igCaseT = lCaseT;

        exit = bbGet();
        bbCur = block;
        irI(I_SWTCH, v, exit, igCaseT);
        return (0);

    case 11:  /* A_GOTO */
        /* TODO: ordering */
        if (n[2][0] == A_LOAD) {
            if (n[2][2][0] == A_NAME) {
                nte = ntFetch(n[2][2][2]);
                flags = nte[1];
                if ((flags & NT_K_M) == NT_INT & (flags & NT_NO_S) != 0) {
                    irI(I_J, name[2]);
                    return (0);
                }
            }
        }
        /* TODO succ/pred */
        irI(I_CJ, igNode(n[2]));
        return (0);

    case 12:  /* A_VRTRN */
        irI(I_RET, irUndef());
        return (0);

    case 13:  /* A_RTRN */
        irI(I_RET, igNode(n[2]));
        return (0);

    case 14:  /* A_EXPR */
        igNode(n[2]);
        return (0);

    case 15:  /* A_VOID */
        return (0);

    case 16:  /* A_NAME */
        nte = ntFetch(n[2]);
        kind = nte[1] & NT_K_M;
        if (kind == NT_ARG)
            return (irI(I_ARG, nte[2]));
        if (kind == NT_AUTO)
            return (irI(I_AUTO, nte[0]));
        /* TODO: block must be loaded into NT_INT */
        if (kind == NT_INT)
            return (irI(I_AUTO, nte[0]));
        if (kind == NT_EXT)
            return (irI(I_EXTRN, nte[0]));
        ice("Bad variable kind");

    case 19:  /* A_NUM */
        return (irI(I_NUM, n[2]));

    case 20:  /* A_STR */
        return (irI(I_STR, n[2], n[3]));

    case 21:  /* A_ASSIGN */
        addr = igNode(n[2]);
        v = igNode(n[3]);
        if (n[4])
            v = irI(I_BIN, irI(I_LOAD, addr), v);
        irI(I_STORE, addr, v);
        return (v);

    case 22:  /* A_PRE */
        addr = igNode(n[2]);
        v = irI(I_BIN, O_PLUS, irI(I_LOAD, addr), n[3]);
        irI(I_STORE, addr, v);
        return (v);

    case 23:  /* A_POST */
        addr = igNode(n[2]);
        v = irI(I_LOAD, addr);
        irI(I_STORE, addr, irI(I_BIN, O_PLUS, v, n[3]));
        return (v);

    case 24:  /* A_UNARY */
        return (irI(I_UNARY, n[3], igNode(n[2])));

    case 26:  /* A_BIN */
        return (irI(I_BIN, n[4], igNode(n[2]), igNode(n[3])));

    case 27:  /* A_COND */
        v = igNode(n[2]);

        irI(I_IF, v, yes, no);
        yes = bbGet();
        no = bbGet();
        exit = bbGet();

        bbCur = yes;
        yesV = igNode(n[3]);
        irI(I_J, exit);

        bbCur = no;
        noV = igNode(n[4]);
        irI(I_J, exit);

        bbCur = exit;
        return (irI(I_PHI, yesV, yes, noV, no, 0));

    case 28:  /* A_CALL */
        v = igNode(n[2]);

        sz = vcSize(n[3]);
        args = vcGetR(sz);
        vcSSize(&args, sz);
        i = 0;
        while (i < sz)
            args[i] = igNode(n[3][i]);

        return (irI(I_CALL, v, args));

    case 29:  /* A_LOAD */
        return (irI(I_LOAD, igNode(n[2])));

    }
    ice("Unexpected node");
};

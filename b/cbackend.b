/* vim: set ft=blang : */

cbEmitF(func)
{
    extrn printf;
    extrn obFmt;
    extrn bbList;
    extrn vcSize;
    extrn cbI;
    auto i, sz;
    auto bb, p;

    obFmt("I [2:cname](I **args)*n{*n", func);

    sz = vcSize(bbList);
    i = 0;
    while (i < sz) {
        printf("BB%d:*n", bbList[i][0]);
        bb = bbList[i++];
        p = bb[3];
        while (p != bb) {
            cbI(p);
            p = p[3];
        }
    }

    obFmt("}*n*n");
}

cbI(inst) {
    extrn I_UNDEF;
    extrn obFmt;
    extrn ice;

    switch (inst[0]) {
    case  1:  /* I_UNDEF */
    case  2:  /* I_PHI */
        return;

    case  3:  /* I_NUM */
        obFmt("    t[1] = [6];*n", inst);
        return;

    case  4:  /* I_STR */
        return;

    case  5:  /* I_ARG */
        obFmt("    t[1] = PTOI(&args[:lb]t[6][:rb]);*n", inst);
        return;

    case  6:  /* I_AUTO */
        ice("Unexpected I_AUTO.");
        return;

    case  7:  /* I_EXTRN */
        obFmt("    t[1] = PTOI(&[6:cname]);*n", inst);
        return;

    case  8:  /* I_BLOCK */
        obFmt("    t[1] = (I)&&BB[6.0];*n", inst);
        return;

    case  9:  /* I_BIN */
        obFmt("    t[1] = t[7.1] [6:cbop] t[8.1];*n", inst);
        return;

    case 10:  /* I_UNARY */
        obFmt("    t[1] = [6:cuop]t[7.1];*n", inst);
        return;

    case 11:  /* I_CALL */
        obFmt("    p = carg;*n[7:rep:    **p++ = t[0.1];*n]    t[1] = (**(FN)t[6.1])(carg);*n", inst);
        return;

    case 12:  /* I_LOAD */
        obFmt("    t[1] = **ITOP(t[6.1]);*n", inst);
        return;

    case 13:  /* I_STORE */
        obFmt("    **ITOP(t[6.1]) = t[7.1];*n", inst);
        return;

    case 14:  /* I_J */
        obFmt("    goto BB[6.0];*n", inst);
        return;

    case 15:  /* I_CJ */
        obFmt("    goto **(void **)t[6.1];*n", inst);
        return;

    case 16:  /* I_RET */
        if (inst[6][0] == I_UNDEF)
            obFmt("    return 0; /** undef **/*n", inst);
        else
            obFmt("    return t[6.1];*n", inst);
        return;

    case 17:  /* I_IF */
        obFmt("    if (t[6.1]) goto BB[7.0]; else goto BB[8.0];*n", inst);
        return;

    case 18:  /* I_SWTCH */
        obFmt("    switch (t[6.1]) {*n    default: goto BB[7.0];*n[8:rep:    case [0]: goto BB[1.0];*n]    }*n", inst);
        return;

    case 19:  /* I_ALLOC */
        if (inst[7])
            obFmt("    t[1] = PTOI(&[7:cname]);*n", inst);
        else
            obFmt("    t[1] = alloca([6]);*n", inst);
        return;
    }
    ice("Unhandled instruction.");
}

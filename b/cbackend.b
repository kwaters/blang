/* vim: set ft=blang : */


cbEmitP(program) {
    extrn A_FDEF, A_XDEF;
    extrn obFmt;
    extrn vcSize;
    extrn igFunc;
    extrn cbEmitF, cbEmitX;
    auto i, sz, inst;

    obFmt("#include *"base.h*"*n");

    i = 0;
    sz = vcSize(program[2]);
    while (i < sz) {
        inst = program[2][i];
        if (inst[0] == A_FDEF) {
            igFunc(inst);
            cbEmitF(inst);
        } else if (inst[0] == A_XDEF) {
            cbEmitX(inst);
        }
        i++;
    }

}

cbEmitX(decl) {
    extrn vcSize;
    extrn ice;
    extrn obFmt;
    auto sz, asz;
    if (decl[3] == -1) {
        /* scalar */
        sz = vcSize(decl[4]);
        if (sz == 0)
            obFmt("I [2:cname];*n", decl);
        else if (sz == 1)
            obFmt("I [2:cname] = [4.0.2];*n", decl);
        else
            ice("Unimplemented *"vector*" scalar.");
    } else {
        /* array */
        asz = decl[3];
        if (sz = vcSize(decl[4]))
            asz = sz;
        obFmt("I [2:cname:I]", decl);
        obFmt("[:lb][][:rb] = {", &asz);
        obFmt("[4:list:[0.2]] };*n", decl);
        obFmt("I [2:cname];*n", decl);
        obFmt("void __attribute__((constructor)) [2:cname:S](void)*n{*n", decl);
        obFmt("    [2:cname] = PTOI([2:cname:I]);*n;}*n", decl);
    }
}

cbEmitF(func) {
    extrn printf;
    extrn obFmt;
    extrn bbList;
    extrn vcSize;
    extrn cbI, cbFVD, cbPass1, cbPass2;
    auto i, sz;
    auto bb, p;

    obFmt("I [2:cname:I](I **args)*n{*n", func);

    cbFVD();
    cbPass1();
    cbPass2();

    obFmt("}*n");
    obFmt("I [2:cname] = (I)&[2:cname:I];*n*n", func);
}

it [4];

/* Function variable declarition */
cbFVD() {
    extrn NT_K_M;
    extrn ntIter, ntNext;
    extrn obFmt;
    extrn it;
    extrn printf;
    auto nte;
    auto kind;

    ntIter(it);
    while (nte = ntNext(it)) {
        kind = nte[2] & NT_K_M;
        switch (kind) {
        case 0:  /* NT_ARG */
            goto break;
        case 1:  /* NT_AUTO */
        case 2:  /* NT_INT */
            obFmt("    I [0:cname];*n", nte);
            goto break;
        case 3:  /* NT_EXT */
            obFmt("    extern I [0:cname];*n", nte);
            goto break;
        }
break:
        ;
    }
}

cbMaxA;

cbPass1() {
    extrn vcSize;
    extrn bbList;
    extrn obFmt;
    extrn cbV;
    extrn cbMaxA;
    auto i, p, sz, bb;

    cbMaxA = 1;

    sz = vcSize(bbList);
    i = 0;
    while (i < sz) {
        bb = bbList[i++];
        p = bb[3];
        while (p != bb) {
            cbV(p);
            p = p[3];
        }
    }

    obFmt("    I carg[:lb][][:rb];*n    I **p;*n", &cbMaxA);
}

cbV(inst) {
    extrn obFmt, char;
    extrn ice;
    extrn cbMaxA;
    extrn vcSize;

    auto s, len, x, i, sz, comma;

    switch (inst[0]) {
    case  2:  /* I_PHI */
        obFmt("    I phi[1];*n", inst);
        goto decl;

    case  4:  /* I_STR */
        s = inst[6];
        len = inst[7];
        sz = len / 8;
        comma = 0;
        x = 0;
        i = 0;

        obFmt("    static const I str[1][:lb][:rb] = { ", inst);
        while (i < sz) {
            if (comma)
                obFmt(", ");
            else
                comma = 1;
            obFmt("[]", &s[i++]);
        }

        len =- 8 * sz + 1;
        while (len >= 0)
            x = x << 8 | char(&s[i], len--);

        /* Strings are *e terminated so x cannot be zero unless the string is a
         * multiple of 8 characters long. */
        if (x) {
            if (comma)
                obFmt(", ");
            obFmt("[]", &x);
        }
        obFmt(" };*n");
        goto decl;

    case 11:  /* I_CALL */
        sz = vcSize(inst[7]);
        if (sz > cbMaxA)
            cbMaxA = sz;
        goto decl;

    case  1:  /* I_UNDEF */
    case  3:  /* I_NUM */
    case  5:  /* I_ARG */
    case  7:  /* I_EXTRN */
    case  8:  /* I_BLOCK */
    case  9:  /* I_BIN */
    case 10:  /* I_UNARY */
    case 12:  /* I_LOAD */
    case 19:  /* I_ALLOC */
        goto decl;

    case 13:  /* I_STORE */
    case 14:  /* I_J */
    case 15:  /* I_CJ */
    case 16:  /* I_RET */
    case 17:  /* I_IF */
    case 18:  /* I_SWTCH */
        return;
        ;
    }
    ice("Unhandled instruction.");

decl:
    obFmt("    I t[1];*n", inst);
}

cbPass2() {
    extrn vcSize;
    extrn bbList;
    extrn obFmt;
    extrn cbI;
    auto i, p, sz, bb;

    sz = vcSize(bbList);
    i = 0;
    while (i < sz) {
        obFmt("BB[0]:*n", bbList[i]);
        bb = bbList[i++];
        p = bb[3];
        while (p != bb) {
            cbI(p);
            p = p[3];
        }

        /* TODO(kwaters): PHI copies. */
    }
}

cbI(inst) {
    extrn I_UNDEF;
    extrn obFmt;
    extrn ice;
    extrn cbPhiCp;

    switch (inst[0]) {

    case  1:  /* I_UNDEF */
        return;

    case  2:  /* I_PHI */
        obFmt("    t[1] = phi[1];*n", inst);
        return;

    case  3:  /* I_NUM */
        obFmt("    t[1] = [6];*n", inst);
        return;

    case  4:  /* I_STR */
        obFmt("    t[1] = PTOI(str[1]);*n", inst);
        return;

    case  5:  /* I_ARG */
        obFmt("    t[1] = PTOI(&args[:lb][6][:rb]);*n", inst);
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
        cbPhiCp(inst[2]);
        obFmt("    goto BB[6.0];*n", inst);
        return;

    case 15:  /* I_CJ */
        cbPhiCp(inst[2]);
        obFmt("    goto **(void **)t[6.1];*n", inst);
        return;

    case 16:  /* I_RET */
        cbPhiCp(inst[2]);
        if (inst[6][0] == I_UNDEF)
            obFmt("    return 0; /** undef **/*n", inst);
        else
            obFmt("    return t[6.1];*n", inst);
        return;

    case 17:  /* I_IF */
        cbPhiCp(inst[2]);
        obFmt("    if (t[6.1]) goto BB[7.0]; else goto BB[8.0];*n", inst);
        return;

    case 18:  /* I_SWTCH */
        cbPhiCp(inst[2]);
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

cbPhiCp(block)
{
    extrn bbSucc, next;
    extrn I_PHI;
    extrn vcSize;
    extrn it;
    extrn obFmt;
    auto i, sz, succ, phi, vec;

    bbSucc(it, block);
    while (succ = next(it)) {
        phi = succ[3];
        while (phi != succ & phi[0] == I_PHI) {
            vec = phi[6];
            i = 0;
            sz = vcSize(vec);
            while (i < sz) {
                if (vec[i + 1] == block) {
                    obFmt("    phi[1] = ", phi);
                    obFmt("t[1];*n", vec[i]);
                }
                i =+ 2;
            }
            phi = phi[3];
        }
    }
}

/* vim: set ft=blang : */

/* SSA based intermediate representation. */

/* Instruction/Value types. */

/* Special */
I_UNDEF  1;  /* -- undefined value */
I_PHI    2;  /* (value, predecessor) ... -- PHI node */

/* Constants */
I_NUM    3;  /* num -- number */
I_STR    4;  /* str, len -- string */
I_ARG    5;  /* argNo -- address of an arguments */
I_AUTO   6;  /* name -- address of a local */
I_EXTRN  7;  /* name -- address of an extrn */
I_BLOCK  8;  /* block -- address of a block for CJ */

/* Expressions */
I_BIN    9;  /* op, lhs, rhs -- binary operation */
I_UNARY 10;  /* op, expr -- unary operation */
I_CALL  11;  /* f, arg ... -- function call */

/* Memory */
I_LOAD  12;  /* addr */
I_STORE 13;  /* addr, value */
I_ALLOC 19;  /* sz, name */

/* Terminators.  All blocks end with exactly one terminator */
I_J     14;  /* block */
I_CJ    15;  /* value -- computed jump */
I_RET   16;  /* value */
I_IF    17;  /* value, blockNZ, blockZ -- jump if non-zero/zero */
I_SWTCH 18;  /* value, default, (const, block) ... */

/* Notes:
 * -  Void returns return UNDEF.
 *
 * Todo:
 * -  Does CJ need to list possible targets?
 */

irDummy(kind) {
    extrn ice;
    switch (kind) {
    case  1:  /* I_UNDEF */
    case  2:  /* I_PHI */
    case  3:  /* I_NUM */
    case  4:  /* I_STR */
    case  5:  /* I_ARG */
    case  6:  /* I_AUTO */
    case  7:  /* I_EXTRN */
    case  8:  /* I_BLOCK */
    case  9:  /* I_BIN */
    case 10:  /* I_UNARY */
    case 11:  /* I_CALL */
    case 12:  /* I_LOAD */
    case 13:  /* I_STORE */
    case 14:  /* I_J */
    case 15:  /* I_CJ */
    case 16:  /* I_RET */
    case 17:  /* I_IF */
    case 18:  /* I_SWTCH */
    case 19:  /* I_ALLOC */
        ;
    }
    ice("Unhandled instruction.");
}

/* Instruction layout
 *
 *  [0] Instruction kind
 *  [1] Name
 *  [2] Pointer to parent block
 *  [3] Double-LL next instruction
 *  [4]           previous instruction
 *  [5] pointer to vector of uses
 *
 *  [6+] arguments
 *
 *  For variable length instructions [5] is a pointer to a vector.
 */

irTCnt 0;

/* Create a new instruction */
irI(kind, a0, a1, a2, a3, a4, a5) {
    extrn bbCur, bbFirst, bbLast, bbEmpty;
    extrn irIns;
    auto last, insp;
    extrn obFmt, irShow;

    return (irIns(bbCur[4], kind, a0, a1, a2, a3, a4, a5));
}

/* Insert an instruction.
 *
 * ip is the instruction you want to insert after.  ip == bb, inserts at
 * begining of the basic block.
 */
irIns(ip, kind, a0, a1, a2) {
    extrn irTCnt;
    extrn getvec, ice;
    extrn vcPush, vcGet, vcSize;
    extrn irSz, irAUse;
    auto inst, i, sz, onext, oprev, vec, parent;
    extrn obFmt;

    inst = getvec(irSz(kind) - 1);
    inst[0] = kind;
    inst[2] = ip[2];
    inst[1] = ++irTCnt;
    inst[5] = vcGet();

    /* Insert into linked-list. */
    onext = ip[3];
    inst[3] = onext;
    inst[4] = ip;
    onext[4] = inst;
    ip[3] = inst;

    switch (kind) {
    case  1:  /* I_UNDEF */
        /* nop */
        goto break;

    case  2:  /* I_PHI */
        vec = vcGet();
        i = &a0;
        while (*i) {
            /* TODO: PHI should add uses */
            vcPush(&vec, *i++);
            vcPush(&vec, *i++);
        }
        inst[6] = vec;
        goto break;

    case  3:  /* I_NUM */
    case  5:  /* I_ARG */
    case  6:  /* I_AUTO */
    case  7:  /* I_EXTRN */
    case  8:  /* I_BLOCK */
    case 14:  /* I_J */
        inst[6] = a0;
        goto break;

    case  4:  /* I_STR */
    case 19:  /* I_ALLOC */
        inst[6] = a0;
        inst[7] = a1;
        goto break;

    case  9:  /* I_BIN */
        inst[6] = a0;
        inst[7] = irAUse(a1, inst);
        inst[8] = irAUse(a2, inst);
        goto break;

    case 10:  /* I_UNARY */
        inst[6] = a0;
        inst[7] = irAUse(a1, inst);
        goto break;

    case 11:  /* I_CALL */
        inst[6] = irAUse(a0, inst);
        inst[7] = a1;
        sz = vcSize(a1);
        i = 0;
        while (i < sz)
            irAUse(a1[i++], inst);
        goto break;

    case 12:  /* I_LOAD */
    case 15:  /* I_CJ */
    case 16:  /* I_RET */
        inst[6] = irAUse(a0, inst);
        goto break;

    case 13:  /* I_STORE */
        inst[6] = irAUse(a0, inst);
        inst[7] = irAUse(a1, inst);
        goto break;

    case 17:  /* I_IF */
        inst[6] = irAUse(a0, inst);
        inst[7] = a1;
        inst[8] = a2;
        goto break;

    case 18:  /* I_SWTCH */
        inst[6] = irAUse(a0, inst);
        inst[7] = a1;
        inst[8] = a2;
        goto break;

        inst[6] = a0;
        inst[7] = a1;
        goto break;
    }
    ice("Unhandled instruction.");
break:
    return (inst);
}

/* Size of an instruction */
irSz(kind) {
    extrn ice;
    switch (kind) {
    case  1:  /* I_UNDEF */
        return (6);

    case  2:  /* I_PHI */
    case  3:  /* I_NUM */
    case  5:  /* I_ARG */
    case  6:  /* I_AUTO */
    case  7:  /* I_EXTRN */
    case  8:  /* I_BLOCK */
    case 12:  /* I_LOAD */
    case 14:  /* I_J */
    case 15:  /* I_CJ */
    case 16:  /* I_RET */
        return (7);

    case  4:  /* I_STR */
    case 10:  /* I_UNARY */
    case 11:  /* I_CALL */
    case 13:  /* I_STORE */
    case 19:  /* I_ALLOC */
        return (8);

    case  9:  /* I_BIN */
    case 17:  /* I_IF */
    case 18:  /* I_SWTCH */
        return (9);
    }
    ice("Unhandled instruction.");
}

/* Add a use to a use-def chain. */
irAUse(def, use) {
    extrn vcPush;
    vcPush(&def[5], use);
    return (def);
}

irDel(inst) {
    extrn irRlse;
    auto next, prev;

    /* Unlink instruction. */
    next = inst[3];
    prev = inst[4];
    prev[3] = next;
    next[4] = prev;

    irRlse(inst);
}

irRlse(inst) {
    extrn rlsevec;
    extrn vcRlse;
    extrn irSz;
    vcRlse(inst[5]);
    rlsevec(inst, irSz(inst[0]) - 1);
}

irRepS 0;
irRepD 0;
irRep(dst, src)
{
    extrn irRepS, irRepI, irRepD, irDel;
    extrn vcApply;

    irRepS = src;
    irRepD = dst;
    vcApply(dst[5], irRepI);

    irDel(dst);
}

irRepI(instp)
{
    extrn irRepS, irRepD, irAUse;
    extrn vcSize;
    extrn ice;

    auto inst, src, dst;
    auto i, sz, vec;
    src = irRepS;
    dst = irRepD;
    inst = *instp;

    switch (inst[0]) {
    case  2:  /* I_PHI */
        ice("unimplemented");

    case  9:  /* I_BIN */
        if (inst[8] == dst)
            inst[8] = irAUse(src);
        /* falltrhough */
    case 10:  /* I_UNARY */
        if (inst[7] == dst)
            inst[7] = irAUse(src);
        return;

    case 11:  /* I_CALL */
        if (inst[6] == dst)
            inst[6] = irAUse(src);
        vec = inst[7];
        i = 0;
        sz = vcSize(vec);
        while (i < sz) {
            if (vec[i] == dst)
                vec[i] = irAUse(src);
            i++;
        }
        return;

    case 13:  /* I_STORE */
        if (inst[7] == dst)
            inst[7] = irAUse(src);
        /* fallthrough */
    case 12:  /* I_LOAD */
    case 15:  /* I_CJ */
    case 16:  /* I_RET */
    case 17:  /* I_IF */
    case 18:  /* I_SWTCH */
        if (inst[6] == dst)
            inst[6] = irAUse(src);
        return;
    }
    ice("Unexpected instruction in irRep");
}


irShow(inst) {
    extrn ice, printf;
    extrn obFmt;
    extrn vcSize;
    auto i, sz, vec;

    switch (inst[0]) {
    case  1:  /* I_UNDEF */
        printf("t%d = UNDEF;*n", inst[1]);
        return;

    case  2:  /* I_PHI */
        obFmt("t[1] = PHI([6:list:t[0.1] [:lb]BB[1.0][:rb]]);*n", inst);
        return;

    case  3:  /* I_NUM */
        printf("t%d = %d;*n", inst[1], inst[6]);
        return;

    case  4:  /* I_STR */
        obFmt("t[1] = *"[6:str:7]*";*n", inst);
        return;

    case  5:  /* I_ARG */
        printf("t%d = ARG(%d);*n", inst[1], inst[6]);
        return;

    case  6:  /* I_AUTO */
        obFmt("t[1] = &[6:name];*n", inst);
        return;

    case  7:  /* I_EXTRN */
        obFmt("t[1] = &[6:name]; /** extrn **/*n", inst);
        return;

    case  8:  /* I_BLOCK */
        obFmt("t[1] = &&BB[6.0];*n", inst);
        return;

    case  9:  /* I_BIN */
        obFmt("t[1] = t[7.1] [6:bop] t[8.1];*n", inst);
        return;

    case 10:  /* I_UNARY */
        obFmt("t[1] = [6:uop] t[7.1];*n", inst);
        return;

    case 11:  /* I_CALL */
        obFmt("t[1] = t[6.1]([7:list:t[0.1]]);*n", inst);
        return;

    case 12:  /* I_LOAD */
        printf("t%d = LOAD t%d;*n", inst[1], inst[6][1]);
        return;

    case 13:  /* I_STORE */
        printf("STORE t%d, t%d;*n", inst[6][1], inst[7][1]);
        return;

    case 14:  /* I_J */
        printf("J BB%d;*n", inst[6][0]);
        return;

    case 15:  /* I_CJ */
        printf("CJ t%d;*n", inst[6][1]);
        return;

    case 16:  /* I_RET */
        printf("RET t%d;*n", inst[6][1]);
        return;

    case 17:  /* I_IF */
        printf("IF t%d BB%d, BB%d;*n", inst[6][1], inst[7][0], inst[8][0]);
        return;

    case 18:  /* I_SWTCH */
        obFmt("SWTCH t[6.1] default: BB[7.0], [8:list:[0]: BB[1.0]];*n",
              inst);
        return;

    case 19:  /* I_ALLOC */
        obFmt("t[1] = ALLOC([6]);[7:gz:  /** [7:name] **/]*n", inst);
        return;
    }
    ice("Unhandled instruction.");
}

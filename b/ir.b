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
I_EXTRN  7;  /* name -- address of an extrn */
I_BLOCK  8;  /* block -- address of a block for CJ */

/* Expressions */
I_BIN    9;  /* op, lhs, rhs -- binary operation */
I_UNARY 10;  /* op, expr -- unary operation */
I_CALL  11;  /* f, arg ... -- function call */

/* Memory */
I_LOAD  12;  /* addr */
I_STORE 13;  /* addr, value */
I_ALLOC 19;  /* sz, name -- Allocate space on the stack */

/* Terminators.  All blocks end with exactly one terminator */
I_J     14;  /* block */
I_CJ    15;  /* value -- computed jump */
I_RET   16;  /* value */
I_IF    17;  /* value, blockNZ, blockZ -- jump if non-zero/zero */
I_SWTCH 18;  /* value, default, (const, block) ... */

/* Notes:
 * -  Void returns are return UNDEF.
 */

irDummy(kind) {
    extrn ice;
    switch (kind) {
    case  1:  /* I_UNDEF */
    case  2:  /* I_PHI */
    case  3:  /* I_NUM */
    case  4:  /* I_STR */
    case  5:  /* I_ARG */
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

/* Count of the number of temporaries/Names. */
irTCnt 0;

/* Create a new instruction in the current basic block */
irI(kind, a0, a1, a2) {
    extrn bbCur;
    extrn irIns;

    return (irIns(bbCur[4], kind, a0, a1, a2));
}

/* Insert an instruction.
 *
 * ip is the instruction you want to insert after.  ip == bb, inserts at
 * begining of the basic block.
 */
irIns(ip, kind, a0, a1, a2) {
    extrn irTCnt;
    extrn getvec;
    extrn ice;
    extrn vcGet, vcPush, vcSize;
    extrn irAUse, irSz;

    auto inst, oldNext;
    auto i, sz;

    inst = getvec(irSz(kind) - 1);
    inst[0] = kind;
    inst[1] = ++irTCnt;
    inst[2] = ip[2];
    inst[5] = vcGet();

    /* Insert into linked-list. */
    oldNext = ip[3];
    inst[3] = oldNext;
    inst[4] = ip;
    oldNext[4] = inst;
    ip[3] = inst;

    switch (kind) {
    case  1:  /* I_UNDEF */
        return (inst);

    case  2:  /* I_PHI */
        /* Add uses. */
        sz = vcSize(a0);
        i = 0;
        while (i < sz) {
            irAUse(a0[i], inst);
            i =+ 2;
        }
        if (i != sz)
            ice("I_PHI expected pairs of arguments");

        inst[6] = a0;
        return (inst);

    case  3:  /* I_NUM */
    case  5:  /* I_ARG */
    case  7:  /* I_EXTRN */
    case  8:  /* I_BLOCK */
    case 14:  /* I_J */
        inst[6] = a0;
        return (inst);

    case  4:  /* I_STR */
    case 19:  /* I_ALLOC */
        inst[6] = a0;
        inst[7] = a1;
        return (inst);

    case  9:  /* I_BIN */
        inst[6] = a0;
        inst[7] = irAUse(a1, inst);
        inst[8] = irAUse(a2, inst);
        return (inst);

    case 10:  /* I_UNARY */
        inst[6] = a0;
        inst[7] = irAUse(a1, inst);
        return (inst);

    case 11:  /* I_CALL */
        inst[6] = irAUse(a0, inst);
        inst[7] = a1;
        sz = vcSize(a1);
        i = 0;
        while (i < sz)
            irAUse(a1[i++], inst);
        return (inst);

    case 12:  /* I_LOAD */
    case 15:  /* I_CJ */
    case 16:  /* I_RET */
        inst[6] = irAUse(a0, inst);
        return (inst);

    case 13:  /* I_STORE */
        inst[6] = irAUse(a0, inst);
        inst[7] = irAUse(a1, inst);
        return (inst);

    case 17:  /* I_IF */
        inst[6] = irAUse(a0, inst);
        inst[7] = a1;
        inst[8] = a2;
        return (inst);

    case 18:  /* I_SWTCH */
        inst[6] = irAUse(a0, inst);
        inst[7] = a1;
        inst[8] = a2;
        return (inst);
    }
    ice("Unhandled instruction in irIns.");
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

/* Release an instruction. */
irRlse(inst) {
    extrn rlsevec;
    extrn vcRlse;
    extrn irSz;
    auto next, prev;

    /* Unlink instruction. */
    next = inst[3];
    prev = inst[4];
    prev[3] = next;
    next[4] = prev;

    /* Release internal vectors */
    vcRlse(inst[5]);
    switch (inst[0]) {
    case  2:  /* I_PHI */
        vcRlse(inst[6]);
        goto break;
    case 11:  /* I_CALL */
        vcRlse(inst[7]);
        goto break;
    }

break:
    rlsevec(inst, irSz(inst[0]) - 1);
}

/* Replace |dst| instruction with |src| instruction, releasing |dst|.
 *
 * This updates referencing instructions and use chains.
 */
irRep(dst, src)
{
    extrn irRepS, irRepD, irRepI;
    extrn irRlse;
    extrn vcApply;

    irRepS = src;
    irRepD = dst;
    vcApply(dst[5], irRepI);

    irRlse(dst);
}

/* irRep() internals. */
irRepS 0;
irRepD 0;
irRepI(instp)
{
    extrn irRepS, irRepD;

    extrn irAUse;
    extrn vcSize;
    extrn ice;
    extrn obFmt;

    auto inst, src, dst;
    auto i, sz, vec;

    src = irRepS;
    dst = irRepD;
    inst = *instp;

    switch (inst[0]) {
    case  2:  /* I_PHI */
        vec = inst[6];
        i = 0;
        sz = vcSize(vec);
        while (i < sz) {
            if (vec[i] == dst)
                vec[i] = irAUse(src, inst);
            i =+ 2;
        }
        return;

    case  9:  /* I_BIN */
        if (inst[7] == dst)
            inst[7] = irAUse(src, inst);
        if (inst[8] == dst)
            inst[8] = irAUse(src, inst);
        return;

    case 10:  /* I_UNARY */
        if (inst[7] == dst)
            inst[7] = irAUse(src, inst);
        return;

    case 11:  /* I_CALL */
        if (inst[6] == dst)
            inst[6] = irAUse(src, inst);
        vec = inst[7];
        i = 0;
        sz = vcSize(vec);
        while (i < sz) {
            if (vec[i] == dst)
                vec[i] = irAUse(src, inst);
            i++;
        }
        return;

    case 12:  /* I_LOAD */
    case 15:  /* I_CJ */
    case 16:  /* I_RET */
    case 17:  /* I_IF */
    case 18:  /* I_SWTCH */
        if (inst[6] == dst)
            inst[6] = irAUse(src, inst);
        return;

    case 13:  /* I_STORE */
        if (inst[6] == dst)
            inst[6] = irAUse(src, inst);
        if (inst[7] == dst)
            inst[7] = irAUse(src, inst);
        return;

    }
    ice("Unexpected instruction in irRep");
}

/* Pretty print an instruction. */
irShow(inst) {
    extrn ice;
    extrn obFmt;

    switch (inst[0]) {
    case  1:  /* I_UNDEF */
        obFmt("t[1] = undef*n", inst);
        return;

    case  2:  /* I_PHI */
        obFmt("t[1] = phi([6:list:t[0.1] [:lb]BB[1.0][:rb]])*n", inst);
        return;

    case  3:  /* I_NUM */
        obFmt("t[1] = [6]*n", inst);
        return;

    case  4:  /* I_STR */
        obFmt("t[1] = *"[6:str:7]*"*n", inst);
        return;

    case  5:  /* I_ARG */
        obFmt("t[1] = arg([6])*n", inst);
        return;

    case  7:  /* I_EXTRN */
        obFmt("t[1] = &[6:name]; /** extrn **/*n", inst);
        return;

    case  8:  /* I_BLOCK */
        obFmt("t[1] = BB[6.0]*n", inst);
        return;

    case  9:  /* I_BIN */
        obFmt("t[1] = t[7.1] [6:bop] t[8.1]*n", inst);
        return;

    case 10:  /* I_UNARY */
        obFmt("t[1] = [6:uop] t[7.1]*n", inst);
        return;

    case 11:  /* I_CALL */
        obFmt("t[1] = t[6.1]([7:list:t[0.1]])*n", inst);
        return;

    case 12:  /* I_LOAD */
        obFmt("t[1] = load t[6.1]*n", inst);
        return;

    case 13:  /* I_STORE */
        obFmt("store t[6.1], t[7.1]*n", inst);
        return;

    case 14:  /* I_J */
        obFmt("j BB[6.0]*n", inst);
        return;

    case 15:  /* I_CJ */
        obFmt("cj t[6.1]*n", inst);
        return;

    case 16:  /* I_RET */
        obFmt("ret t[6.1]*n", inst);
        return;

    case 17:  /* I_IF */
        obFmt("if t[6.1] BB[7.0] BB[8.0]*n", inst);
        return;

    case 18:  /* I_SWTCH */
        obFmt("switch t[6.1] default: BB[7.0], [8:list:[0]: BB[1.0]]*n",
              inst);
        return;

    case 19:  /* I_ALLOC */
        obFmt("t[1] = alloca [6][7:gz: [7:name]]*n", inst);
        return;
    }
    ice("Unhandled instruction.");
}

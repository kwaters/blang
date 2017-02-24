/* vim: set ft=blang : */

/* Computed jump elimination.
 *
 * Replaces CJ with J when escape analysis shows that an Internal variable is
 * not writtern.  Leaves dead instructions.
 */

cjElim() {
    extrn NT_K_M, NT_INT;
    extrn I_LOAD;
    extrn it;
    extrn ntIter, ntNext;
    extrn vcSize;
    extrn cjLCJ, cjSB, cjElimCJ;
    extrn obFmt;
    auto nte, kind;
    auto block;
    auto uses, i, sz;
    auto storeCnt;

    ntIter(it);
    while (nte = ntNext(it)) {
        if ((nte[2] & NT_K_M) != NT_INT)
            goto continue;

        block = nte[3];

        /* Check all uses to see if the label escapes. */
        uses = nte[4][5];
        storeCnt = 0;
        i = 0;
        sz = vcSize(uses);
        while (i < sz) {
            if (cjSB(uses[i], block))
                storeCnt++;
            else if (!cjLCJ(uses[i]))
                goto continue;
            i++;
        }

        /* Rewrite CJ's */
        i = 0;
        sz = vcSize(uses);
        while (i < sz) {
            if (uses[i][0] == I_LOAD)
                cjElimCJ(uses[i][5][0], block);
            i++;
        }
        /* TODO(kwaters): Delete dead store. */

continue:;
    }
}

/* Is this use a CJ (LOAD value)? */
cjLCJ(inst) {
    extrn I_LOAD, I_CJ;
    extrn vcSize;
    auto uses;
    extrn obFmt;

    if (inst[0] != I_LOAD)
        return (0);

    uses = inst[5];
    if (vcSize(uses) != 1)
        return (0);

    inst = uses[0];
    if (inst[0] != I_CJ)
        return (0);

    return (1);
}

/* Is this a store of |block|? */
cjSB(inst, block) {
    extrn I_STORE, I_BLOCK;
    extrn obFmt;

    if (inst[0] != I_STORE)
        return (0);

    inst = inst[7];
    if (inst[0] != I_BLOCK)
        return (0);

    return (inst[6] == block);
}

cjElimCJ(inst, block) {
    extrn I_J, I_CJ;
    extrn ice;
    extrn vcSize;

    if (inst[0] != I_CJ)
        ice("Expected CJ instruction.");
    if (vcSize(inst[5]) != 0)
        ice("Unexpected use of CJ instruction.");

    /* I_CJ and I_J are the same size and are both terminators.  We can modify
     * them in place. */
    inst[0] = I_J;
    inst[6] = block;
}

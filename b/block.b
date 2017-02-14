/* vim: set ft=blang : */

/* Basic block / Control Flow Graph
 *
 * Memory layout
 *   [0] Name
 *   [1] firstI
 *   [2] lastI
 */

/* Current basic block. */
bbCur 0;

/* List of basic blocks. */
bbList 0;

/* Offsets */
bbFirst 1;
bbLast 2;

/* Forget all basic blocks. */
bbReset() {
    extrn bbList;
    extrn vcGet, vcSSize;
    /* TODO: release */
    if (!bbList)
        bbList = vcGet();
    vcSSize(&bbList, 0);
}

/* Allocate a new basic block. */
bbGet() {
    extrn vcGet, vcSize, vcPush;
    extrn bbList;
    extrn getvec;
    auto block;

    block = getvec(2);
    vcPush(&bbList, block);

    /* Note names start at 1. */
    block[0] = vcSize(bbList);
    block[1] = 0;
    block[2] = 0;

    return (block);
}

/* Release a basic block. */
bbRlse(block) {
    extrn rlsevec;
    rlsevec(block, 2);
}

/* Create a new block, linking in after the current block. */
bbSplit() {
    extrn I_J;
    extrn irI;
    extrn bbCur;
    extrn bbGet, bbEmpty;
    auto block;

    /* If there are no instructions in the current block, we don't need to
     * split it. */
    if (bbEmpty(bbCur))
        return (bbCur);

    block = bbGet();
    irI(I_J, block);
    bbCur = block;
    return (block);
}

/* Is the specified block terminated. */
bbTermQ(block) {
    extrn I_J, I_SWTCH;
    extrn printf;
    auto inst, kind;

    inst = block[2];
    printf("BB%d: next=%d prev=%d*n", block[0], block[1], block[2]);
    if (!inst)
        return;
    kind = inst[0];
    printf("kind=%d*n", kind);
    return (I_J <= kind & kind <= I_SWTCH);
}

bbEmpty(block) {
    extrn ice;

    if (!block[1] != !block[2])
        ice("Inconsistency in instruction linked-list.");
    return (!block[1]);
}

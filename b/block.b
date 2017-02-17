/* vim: set ft=blang : */

/* Basic block / Control Flow Graph
 *
 * Memory layout
 *   [0] Name
 *   [2] pointer to self
 *   [3] firstI
 *   [4] lastI
 */

/* Current basic block. */
bbCur 0;

/* List of basic blocks. */
bbList 0;

/* Offsets */
bbFirst 3;
bbLast 4;

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

    block = getvec(4);
    vcPush(&bbList, block);

    /* Note names start at 1. */
    block[0] = vcSize(bbList);
    block[1] = 0;
    block[2] = block;
    block[3] = block;
    block[4] = block;

    return (block);
}

/* Release a basic block. */
bbRlse(block) {
    extrn rlsevec;
    rlsevec(block, 4);
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
    return (block[1] == block);
}

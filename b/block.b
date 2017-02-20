/* vim: set ft=blang : */

/* Basic block / Control Flow Graph
 *
 * Memory layout
 *   [0] Name
 *   [2] pointer to self
 *   [3] firstI
 *   [4] lastI
 *
 * Basic blocks contain a doubly linked circular list of instructions, with the
 * BB serving as a sentinal.
 */

/* Offsets */
bbFirst 3;
bbLast 4;

/* Vector of all basic blocks. */
bbList 0;

/* Current basic block. */
bbCur 0;

/* Release all basic blocks. */
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

/* Return true if a basic block contains no instructions. */
bbEmpty(block) {
    return (block[1] == block);
}

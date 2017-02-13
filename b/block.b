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

/* Allocate a new basic block. */
bbGet() {
    extrn vcGet, vcSize, vcPush;
    extrn bbList;
    extrn getvec;
    auto block;

    if (!bbList)
        bbList = vcGet();

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
    extrn bbGet;
    auto block;

    block = bbGet();
    irI(I_J, block);
    bbCur = block;
}

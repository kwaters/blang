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

/* Returns an iterator which iterates over the successors of a block. */
bbSucc(it, block) {
    extrn ice;
    extrn itSeq;
    extrn bbSCJNxt, bbSwtchN;
    extrn ntIter;
    auto term;

    term = block[4];
    switch (term[0]) {
    case 14:  /* I_J */
        it[0] = itSeq;
        it[1] = &term[6];
        it[2] = 1;
        return;

    case 15:  /* I_CJ */
        ntIter(it);
        it[0] = bbSCJNxt;
        return;

    case 16:  /* I_RET */
        it[0] = itSeq;
        it[2] = 0;
        return;

    case 17:  /* I_IF */
        it[0] = itSeq;
        it[1] = &term[7];
        it[2] = 2;
        return;

    case 18:  /* I_SWTCH */
        it[0] = bbSwtchN;
        it[1] = term;
        it[2] = -1;
        return;
    }
    ice("Block missing terminator.");
}

/* Advance an iterator.  Returns (0) on exhaustion. */
next(it) {
    return (it[0](it));
}

/* Next for sequeces of vector values. */
itSeq(it) {
    if (it[2] <= 0)
        return (0);
    it[2]--;
    return (*it[1]++);
}

/* Basic block successor CJ next. */
bbSCJNxt(it) {
    extrn NT_K_M, NT_INT;
    extrn ntNext;
    auto nte;

    /* Computed jump can jump to any label in the function. */
    while (nte = ntNext(it)) {
        if ((nte[2] & NT_K_M) == NT_INT)
            return (nte[3]);
    }
    return (0);
}

/* Basic block successor switch next. */
bbSwtchN(it) {
    extrn vcSize;
    auto term, vec, ret;

    /* Default first */
    if (it[2] <= -1) {
        term = it[1];
        vec = term[8];
        it[1] = &vec[1];
        it[2] = vcSize(vec) / 2;
        return (term[7]);
    }

    /* Exhaustion */
    if (it[2] <= 0)
        return (0);

    ret = *it[1];
    it[1] =+ 2;
    it[2]--;
    return (ret);
}

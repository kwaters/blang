/* vim: set ft=blang : */

/* Nametable
 *
 * Nametable Entry layout
 * [0] Name
 * [1] lineNo of first use
 * [2] flags
 * [3] ARG: #
 *     INTERNAL: block
 * [4] "instruction" in the entry block
 */

/* The nametable */
ntTable 0;

ntTESz 5;  /* Table entry size. */

/* Flags */
/* Variable kinds */
NT_ARG  0;
NT_AUTO 1;
NT_INT  2;
NT_EXT  3;
NT_K_M  3;  /* Kind mask */

NT_DEF  4;  /* Defined bit */
NT_NO_S 8;  /* Never stored to bit */

/* Empty the nametable.
 *
 * The nametable is one level, and cleared between functions. */
ntReset() {
    extrn ntTable, ntTESz;
    extrn vcGetR, vcSSize;

    if (!ntTable)
        ntTable = vcGetR(16 * ntTESz);

    vcSSize(&ntTable, 0);
}

/* Lookup a name.
 *
 * Never returns 0.
 */
ntFetch(name, lineNo) {
    extrn ntTESz, ntTable, NT_INT;
    extrn vcSize, vcSSize;
    extrn ntFetchI;
    auto p, sz;
    extrn printf, stSName;

    if (p = ntFetchI(name))
        return (p);

    /* Name not found in the table, add it as an undefined internal. */
    sz = vcSize(ntTable);
    vcSSize(&ntTable, sz + ntTESz);
    p = ntTable + sz;
    p[0] = name;
    p[1] = lineNo;
    p[2] = NT_INT;
    p[3] = 0;
    p[4] = 0;
    return (p);
}

/* Internal name lookup, returns 0 if not found. */
ntFetchI(name) {
    extrn ntTable, ntTESz;
    extrn vcSize;
    auto p, end;

    p = ntTable;
    end = p + vcSize(ntTable);
    while (p < end) {
        if (*p == name)
            return (p);
        p =+ ntTESz;
    }
    return (0);
}

ntCheck() {
    extrn printf;
    extrn stSName, ntTESz, ntTable;
    extrn vcSize;
    auto i, sz;

    i = 0;
    sz = vcSize(ntTable);
    while (i < sz) {
        stSName(i[0]);
        printf("*n");
        i =+ ntTESz;
    }
}

/* Check that all variables are defined. */
ntCDef() {
    extrn ntTable, ntTESz, NT_DEF;
    extrn vcSize;
    extrn error;
    auto i, sz, nte;

    i = 0;
    sz = vcSize(ntTable);
    while (i < sz) {
        nte = ntTable + i;
        if (!(nte[2] & NT_DEF))
            error("un", nte[0], nte[1]);
        i =+ ntTESz;
    }
}

/* Add a new name.
 *
 * Returns a pointer to the new entry.
 */
ntAdd(name, lineNo, kind) {
    extrn ntFetchI;
    extrn ntTESz, ntTable, NT_DEF, NT_INT, NT_K_M;
    extrn error;
    extrn vcSize, vcSSize;
    auto p, sz;
    extrn printf, stSName;

    if (p = ntFetchI(name)) {
        if ((p[2] & NT_DEF) | (p[2] & NT_K_M) != NT_INT)
            error("rd", name, lineNo);
        p[2] =| NT_DEF;
        return (p);
    }

    sz = vcSize(ntTable);
    vcSSize(&ntTable, sz + ntTESz);
    p = ntTable + sz;
    p[0] = name;
    p[1] = lineNo;
    p[2] = kind | NT_DEF;
    p[3] = 0;
    p[4] = 0;
    return (p);
}

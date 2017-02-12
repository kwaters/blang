/* vim: set ft=blang : */

/* Nametable
 *
 * Nametable Entry layout
 * [0] Name
 * [1] flags
 * [2] ARG: #
 *     INTERNAL: block
 */ 

/* The nametable */
ntTable 0;

ntTESz 3;  /* Table entry size. */

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
ntFetch(name) {
    extrn ntTESz, ntTable, NT_INT;
    extrn vcSize, vcSSize;
    extrn ntFetchI;
    auto p, sz;

    if (p = ntFetchI(name))
        return (p);

    /* Name not found in the table, add it as an undefined internal. */
    sz = vcSize(ntTable);
    vcSSize(&ntTable, sz + ntTESz);
    p = ntTable + sz;
    p[0] = name;
    p[1] = NT_INT;
    p[2] = 0;
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
        if (*p = name)
            return (p);
        p =+ ntTESz;
    }
    return (0);
}

/* Add a new name.
 *
 * Returns a pointer to the new entry.
 */
ntAdd(name, lineNo, kind) {
    extrn ntFetchI;
    extrn ntTESz, ntTable, NT_DEF;
    extrn error;
    extrn vcSize, vcSSize;
    auto p, sz;

    if (ntFetchI(name))
        error("rd", name, lineNo);

    sz = vcSize(ntTable);
    vcSSize(&ntTable, sz + ntTESz);
    p = ntTable + sz;
    p[0] = name;
    p[1] = kind | NT_DEF;
    p[2] = 0;
    return (p);
}

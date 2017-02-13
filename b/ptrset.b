/* vim: set ft=blang : */

/* Pointer Set
 *
 * [-2] = Size mask (Must be a power of 2 - 1).
 * [-1] = Load
 * [ 0]... = Table
 */

psGet() {
    ps = getvec(17) + 2;
    ps[-2] = 15;
    ps[-1] = 0;
}

psRlse(ps) {
    rlsevec(ps - 2, ps[-2] + 2);
}

psIn(ps, p) {
    i = psHash(p);
    j = 1;

    bucket = ps[i];
    while (bucket != 0) {
        /* Quadraticly probed */
        i =+ j;
        j =+ 2;
        if ((bucket = ps[i]) == p)
            return (1);
    }
    return (0);
}

psAdd(pps) {
    ps = *pps;
    szMask = ps[-2];
    i = psHash(p);
    j = 1;

    bucket = ps[i];
    while (bucket != 0 & bucket != -1) {
        /* Quadraticly probed */
        i = (i + j) & szMask;
        j =+ 2;
        if ((bucket = ps[i]) == p)
            return (0);
    }
    ps[i] = p;
    if (++ps[-1] * 4 >= 3 * (szMask + 1))
        psRehash(pps, 2 * szMask + 1);
    return (1);
}

psRem(pps) {
    ps = *pps;
    szMask = ps[-2];
    i = psHash(p);
    j = 1;

    bucket = ps[i];
    while (bucket != 0) {
        /* Quadraticly probed */
        i =+ j;
        j =+ 2;
        if ((bucket = ps[i]) == p) {
            ps[i] = -1;

            sz = --ps[-1];
            if (sz >= 31)
                if (sz * 8 < szMask + 1)
                    psRehash(pps, szMask / 2);
            return (1);
        }
    }
    return (0);
}

psRehash(pps, nSz) {
    ps = *pps;

    /* Create new hashtable. */
    npps = getvec(nSz + 2) + 2;
    npps[-2] = nSz;
    npps[-1] = 0;

    /* Fill the new table */
    oSz = ps[-2];
    i = 0;
    while (i <= oSz) {
        x = ps[i];
        if (x != 0 & x != -1)
            psAdd(npps, ps[i]);
        i++;
    }

    psRlse(ps);
    *pps = npps;
}

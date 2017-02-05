/* vim: set ft=blang : */

/* Input buffer for lexer. */

/* Main buffer.
 *
 * 4KiB with 2 words of padding, this allows for a trailing '*e',
 * and for un-getting.
 */
ibBuf[514];

/* Offset in characters from the start of the input buffer. */
ibOfs;
ibLimit;

/* File handle for the input buffer. */
/* TODO: initializer with negative number is broken. */
ibF;

ibOpen(s) {
    extrn read, open, close;
    extrn printf, lchar, exit;
    extrn ibOfs, ibLimit, ibBuf, ibF;

    auto nread;

    if (ibF >= 0)
        close(ibF);

    ibF = open(s, 0);
    if (ibF < 0) {
        printf("Unable to open *"%s*": %d*n", s, ibF);
        exit();
    }

    nread = read(ibF, ibBuf + 1, 4096);
    if (nread < 0) {
        printf("Read failed: %d*n", nread);
        exit();
    }

    ibOfs = 8;
    ibLimit = ibOfs + nread;
    lchar(ibBuf, ibLimit, '*e');
}

ibGet() {
    extrn char, lchar, read;
    extrn printf, exit;
    extrn ibOfs, ibLimit, ibF, ibBuf;

    auto c, nread;

    if ((c = char(ibBuf, ibOfs++)) != '*e')
        return (c);
    if (ibOfs < ibLimit)
        return (c);

    /* If the buffer has no characters in it, continue outputing '*e'. */
    if (ibLimit == 8) {
        ibOfs = 8;
        return ('*e');
    }

    /* Load next segment. */
    nread = read(ibF, ibBuf + 1, 4096);
    if (nread < 0) {
        printf("Read failed: %d*n", nread);
        exit();
    }

    ibOfs = 8;
    ibLimit = ibOfs + nread;
    lchar(ibBuf, ibLimit, '*e');

    return (ibGet());
}

ibUnget(c) {
    extrn lchar, char;
    extrn ice;
    extrn ibOfs, ibBuf;

    ibOfs--;
    if (ibOfs >= 8) {
        if (char(ibBuf, ibOfs) != c)
            ice("Bad unget.");
    } else if (ibOfs < 0) {
        ice("Too many ungets.");
    } else {
        lchar(ibBuf, ibOfs, c);
    }
}

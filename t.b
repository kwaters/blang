
.start() {
    main();
    exit(0);
}

exit(retarg) {
    auto retval;

    /* NB: Cannot write to retarg, if this function was not called with an
     * argument. */
    if (nargs() == 0)
        retval = 0;
    else
        retval = retarg;

    .syscall('exit', retval);
}

char(s, pos) {
    auto word, ofs;

    word = pos / 4;
    ofs = pos % 4;
    return ((s[word] >> (8 * ofs)) & 0377);
}

putchar(c) {
    .syscall('putc', c);
}

puts(s) {
    auto c, i;
    i = 0;
    while ((c = char(s, i++)) != '*e')
        putchar(c);
}

nargs(x) {
    auto bp, oldsp;
    /* bp of the calling function. */
    bp = (&x)[-2];

    /* sp of the calling functions calling function. */
    oldsp = bp[1];

    return (oldsp - bp - 2);
}

main() {
    puts("Hello, World!*n");
    exit();
}

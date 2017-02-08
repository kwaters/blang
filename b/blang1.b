/* vim: set ft=blang : */

ice(s) {
    extrn printf, exit;

    printf("ICE: %s*n", s);
    exit();
}

/* TODO: local arrays are unsupported. */
tok[4];

ident 0;
f(n) {
    extrn printf;
    extrn ident;
    extrn stApply;
    auto i;

    i = 0;
    while (i++ < ident)
        printf("  ");

    printf("NODE: %d (%d)*n", *n, (*n)[0]);

    ident++;
    stApply(*n, f);
    ident--;

}

main() {
    extrn printf, putchar, argv, exit;
    extrn ibOpen, ibGet;
    extrn lMain, lPrint;
    extrn tok;
    extrn yMain;

    extrn f, stApply, stRlseR;

    auto c;
    auto program;

    if (argv[0] != 2) {
        printf("Usage: blang1 INPUT*n");
        exit();
    }

    ibOpen(argv[2]);

    /*
    while ((c = ibGet()) != '*e')
        putchar(c);
    */
    /*
    while (!lMain(tok)) {
        lPrint(tok);
        if (tok[0] == '*e')
            return;
    }
    */
    program = yMain();
    stApply(program, f);
    stRlseR(program);
}

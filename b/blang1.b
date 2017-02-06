/* vim: set ft=blang : */

ice(s) {
    extrn printf, exit;

    printf("ICE: %s*n", s);
    exit();
}

/* TODO: local arrays are unsupported. */
tok[3];

main() {
    extrn printf, putchar, argv, exit;
    extrn ibOpen, ibGet;
    extrn lMain, lPrint;
    extrn tok;

    auto c;

    if (argv[0] != 2) {
        printf("Usage: blang1 INPUT*n");
        exit();
    }

    ibOpen(argv[2]);

    /*
    while ((c = ibGet()) != '*e')
        putchar(c);
    */
    while (!lMain(tok)) {
        lPrint(tok);
        if (tok[0] == '*e')
            return;
    }
}

/* vim: set ft=blang : */

ice(s) {
    extrn printf, exit;

    printf("ICE: %s*n", s);
    exit();
}

/* -dump-tokens -- Output the list of tokens from the lexer. */
optDTok 0;

/* -dump-ast -- Output the AST after parsing. */
optDAst 0;

/* input -- Input file. */
optInp 0;

/* parse arguments */
mPArgs() {
    extrn argv;
    extrn optDTok, optDAst, optInp;
    extrn strcmp, printf, exit;

    auto argc, arg, i;

    argc = argv[0];
    i = 1;
    while (i++ < argc) {
        arg = argv[i];
        if (strcmp(arg, "-dump-tokens") == 0) {
            optDTok = 1;
        } else if (strcmp(arg, "-dump-ast") == 0)
            optDAst = 1;
        else if (!optInp)
            optInp = arg;
        else
            goto error;
    }
    if (optInp)
        return;

error:
    printf("Usage: blang1 INPUT*n");
    exit();
}

/* TODO: local arrays are unsupported. */
tok[4];

main() {
    extrn printf, putchar, argv, exit;
    extrn ibOpen, ibGet;
    extrn lMain, lPrint;
    extrn tok;
    extrn yMain;
    extrn mPArgs, optInp, optDTok, optDAst;

    extrn f, stShow, stRlseR;

    auto c;
    auto program;

    mPArgs();
    ibOpen(optInp);

    if (optDTok) {
        while (!lMain(tok)) {
            lPrint(tok);
            if (tok[0] == '*e')
                return;
        }
        exit();
    }

    program = yMain();

    if (optDAst) {
        stShow(program);
        exit();
    }

    stRlseR(program);
}

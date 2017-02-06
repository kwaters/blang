/* vim: set ft=blang : */

ice(s) {
    extrn printf, exit;

    printf("ICE: %s*n", s);
    exit();
}

main() {
    extrn printf, putchar, argv, exit;
    extrn ibOpen, ibGet;

    auto c;

    if (argv[0] != 2) {
        printf("Usage: blang1 INPUT*n");
        exit();
    }

    ibOpen(argv[2]);
    while ((c = ibGet()) != '*e')
        putchar(c);
}

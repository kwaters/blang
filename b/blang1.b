/* vim: set ft=blang : */

ice(s) {
    extrn printf, exit;

    printf("ICE: %s*n", s);
    exit();
}

main() {
    extrn ibOpen, ibGet;
    extrn putchar;

    auto c;

    ibOpen("b/lexer.b");
    while ((c = ibGet()) != '*e')
        putchar(c);
}

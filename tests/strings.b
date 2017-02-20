/* vim: set ft=blang : */

main() {
    extrn g;
    g("");
    g("1");
    g("1x");
    g("1xx");
    g("1xxx");
    g("1xxxx");
    g("1xxxxx");
    g("1xxxxxx");
    g("1xxxxxxx");
    g("1xxxxxxx2");
    g("1xxxxxxx2x");
    g("1xxxxxxx2xx");
    g("1xxxxxxx2xxx");
    g("1xxxxxxx2xxxx");
    g("1xxxxxxx2xxxxx");
    g("1xxxxxxx2xxxxxx");
    g("1xxxxxxx2xxxxxxx");
    g("1xxxxxxx2xxxxxxx3");
    g("1xxxxxxx2xxxxxxx3x");
    g("1xxxxxxx2xxxxxxx3xx");
    g("1xxxxxxx2xxxxxxx3xxx");
    g("1xxxxxxx2xxxxxxx3xxxx");
    g("1xxxxxxx2xxxxxxx3xxxxx");
    g("1xxxxxxx2xxxxxxx3xxxxxx");
}

g(s) {
    extrn printf;
    printf("%s*n", s);
}

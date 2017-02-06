/* vim: set ft=blang : */

main() {
    extrn printf, argv;
    auto i, sz;

    sz = argv[0];
    i = 0;
    while (i < sz) {
        printf("%d: %s*n", i, argv[i + 1]);
        i++;
    }
}

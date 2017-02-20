/* vim: set ft=blang : */

randS1 1;
randS2 2;

rand() {
    extrn randS1, randS2;
    auto x;

    /* Knuth (39) -- 31 bit output, relies only on operators available in B. */
    x = (271828183 * randS1 + 314159269 * randS2) % 2147483647;
    randS2 = randS1;
    randS1 = x;
    return (x);
}

main() {
    extrn rand, printf;
    auto i;
    i = 0;
    while (i++ < 50000)
        printf("%d*n", rand());
}

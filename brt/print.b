/* vim: set ft=blang : */

printn(n, b) {
    extrn putchar;
    auto a;

    if (a = n / b)
        printn(a, b);
    putchar(n % b + '0');
}

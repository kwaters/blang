/* vim: set ft=blang : */

main() {
    extrn printn, putchar, printf;

    printn(42, 10);
    putchar('*n');
    printn(42, 8);
    putchar('*n');
    printn(42, 2);
    putchar('*n');

    printf("Hello, World! %o %d *n", 42, 42);
}

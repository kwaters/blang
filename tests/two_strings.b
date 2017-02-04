/* vim: set ft=blang : */

main()
{
    extrn f, printf;

    f();
    printf("String %d!*n", 2);
}

f()
{
    extrn printf;

    printf("String one!*n");
}


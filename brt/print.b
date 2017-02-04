/* vim: set ft=blang : */

printn(n, b) {
    extrn putchar;
    auto a;

    if (a = n / b)
        printn(a, b);
    putchar(n % b + '0');
}

printf(fmt, x0)
{
    extrn printn, char, putchar;
    auto adx, x, c, i, j;

    i = 0;
    adx = &x0;

loop:
    while ((c = char(fmt, i++)) != '%') {
        if (c == '*e')
            return;
        putchar(c);
    }
    x = *adx++;
    switch (c = char(fmt, i++)) {
    case 'd':
        /* decimal */
    case 'o':
        /* octal */
        if (x < 0) {
            x = -x;
            putchar('-');
        }
        printn(x, c == 'd' ? 10 : 8);
        goto loop;

    case 'c':
        /* character */
        putchar(x);
        goto loop;

    case 's':
        /* string */
        j = 0;
        while ((c = char(x, j++)) != '*e')
            putchar(c);
        goto loop;
    }

    /* "The characters in the string fmt which do not appear in one of these
     * two-character sequences are copied without change to the output unit."
     * --GCOS reference */
    putchar('%');
    i--;
    adx--;
    goto loop;
}

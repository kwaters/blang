/* vim: set ft=blang : */

strcmp(s1, s2) {
    extrn char;
    auto i, c1, c2;

    i = 0;
    while (1) {
        c1 = char(s1, i);
        c2 = char(s2, i++);
        if (c1 == c2) {
            if (c1 == '*e')
                return (0);
        } else {
            if (c1 < c2)
                return (-1);
            else
                return (1);
        }
    }
}

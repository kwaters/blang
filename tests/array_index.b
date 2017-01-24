/* vim: set ft=blang : */

/* test1 & test2 should produce the same code. */
test1(v, i) {
    return (v[i]);
}
test2(v, i) {
    return (*(v + i));
}

/* test3 & test4 should produce the same code. */
test3(v, i) {
    return (&v[i]);
}
test4(v, i) {
    return (v + i);
}

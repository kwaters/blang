/* vim: set ft=blang : */

elim() {
    goto label;
label:
    ;
}

noElim(x) {
    extrn g;
    auto i;

    if (x)
        i = label1;
    else
        i = label2;

    goto i;

label1:
    g();
    goto label2;
    g();
label2:
    ;
}

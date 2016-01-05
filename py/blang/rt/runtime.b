/* vim: set ft=blang : */

exit(status) {
    if (nargs() == 0)
        status = 0;

    .flush();
    .exit.(status);
}

read(fileno, buffer, count) {
    auto nread;
    .read.(nread, fileno, buffer, count);
    return (nread);
}

write(fileno, buffer, count) {
    auto nwrite;
    .write.(nwrite, fileno, buffer, count);
    return (nwrite);
}

open(string, mode) {
}

creat(string, mode) {
}

putchar(c) {
    extrn .outbuf, .outpos;

    lchar(.outbuf, .outpos, c);
    if (.outpos >= 512 | c == '*n')
        .flush();
}

.flush() {
    extrn .outpos;

    if (.outpos <= 0)
        return;
    write(0, .outbuf, .outpos);
}

.outbuf[128];
.outpos 0;

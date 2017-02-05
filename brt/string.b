/* vim: set ft=blang : */

memcpy(dst, src, sz) {
    auto end;

    end = src + sz;
    while (src < end)
        *dst++ = *src++;
}

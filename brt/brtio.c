#include <stdio.h>
#include <stdlib.h>

#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>

typedef intptr_t I;

#define ITOP(i) ((I*)((i) << 3))


/* file = open(string, mode); */
I BI_open(I *args)
{
    I string = args[0];
    I mode = args[1];

    char path[PATH_MAX];
    char *src;
    char *dst;
    I i;
    I fd;

    /* Copy the string replacing EOF with NUL. */
    src = (char *)ITOP(string);
    dst = path;
    for (i = 0; i < PATH_MAX; i++) {
        if (src[i] == '\004') {
            dst[i] = '\0';
            break;
        } else {
            dst[i] = src[i];
        }
    }
    dst[PATH_MAX - 1] = '\0';

    fd = open(path, mode ? O_RDWR : O_RDONLY);
    return fd;
}
I B_open = (I)BI_open;

/* error = close(file); */
I BI_close(I *args)
{
    return close((int)args[0]);
}
I B_close = (I)BI_close;

/* nread = read(file, buffer, count); */
I BI_read(I *args)
{
    I file = args[0];
    I buffer = args[1];
    I count = args[2];

    return read((int)file, ITOP(buffer), (size_t)count);
}
I B_read = (I)BI_read;

/* putchar(char); */
I BI_putchar(I *args)
{
    putchar((int)args[0]);
    return 0;
}
I B_putchar = (I)BI_putchar;

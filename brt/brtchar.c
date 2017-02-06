#include <stdint.h>
#include <stdlib.h>

#define ITOP(i) ((I*)((i) << 3))
#define PTOI(p) ((I)(p) >> 3)

typedef intptr_t I;

I BI_char(I *args)
{
    char *string = (char *)ITOP(args[0]);
    I i = args[1];
    return string[i];
}
I B_char = (I)BI_char;

I BI_lchar(I *args)
{
    char *string = (char *)ITOP(args[0]);
    I i = args[1];
    I c = args[2];
    string[i] = c;

    return 0;
}
I B_lchar = (I)BI_lchar;

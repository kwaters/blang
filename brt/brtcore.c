#include <stdint.h>
#include <stdlib.h>

#define ITOP(i) ((I*)((i) << 3))
#define PTOI(p) ((I)(p) >> 3)

typedef intptr_t I;

I BI_getvec(I *args)
{
    I size = args[0];
    return PTOI(malloc(sizeof(I) * (size + 1)));
}
I B_getvec = (I)BI_getvec;

I BI_rlsevec(I *args)
{
    I vec = args[0];
    I size = args[1];
    free(ITOP(vec));
    return 0;
}
I B_rlsevec = (I)BI_rlsevec;

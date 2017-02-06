#include <alloca.h>
#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define PTOI(p) ((I)(p) >> 3)

typedef intptr_t I;

extern I B_main;

I B_argv;

static void build_argv(int argc, char *argv[])
{
    I *args;
    I *p;
    int i;
    size_t *lens;
    size_t sz;

    lens = alloca(argc * sizeof(I));
    sz = 1;
    for (i = 0; i < argc; i++) {
        lens[i] = strlen(argv[i]);
        /* 1 for the slot in argv, and 1 for round-up and '*e'
         * termination. */
        sz += 2 + lens[i] / sizeof(I);
    }

    args = malloc(sz * sizeof(I));
    args[0] = argc;

    /* Copy in arguments. */
    p = args + argc + 1;
    for (i = 0; i < argc; i++) {
        args[1 + i] = PTOI(p);
        memcpy(p, argv[i], lens[i]);
        ((char *)p)[lens[i]] = '\004';
        p += 1 + lens[i] / sizeof(I);
    }

    assert(args + sz == p);

    /* Unfortunately, valgrind thinks this block is "lost". */
    B_argv = PTOI(args);
}

int main(int argc, char *argv[])
{
    build_argv(argc, argv);

    ((I (*)(I *))B_main)(0);
}

I BI_exit(I *args)
{
    exit(EXIT_SUCCESS);
}
I B_exit = (I)BI_exit;

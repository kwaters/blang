#include <stdint.h>
#include <stdlib.h>

typedef intptr_t I;
extern I B_main;

int main(int argc, char **argv)
{
    ((I (*)(I *))B_main)(0);
}

I BI_exit(I *args)
{
    exit(EXIT_SUCCESS);
}
I B_exit = (I)BI_exit;

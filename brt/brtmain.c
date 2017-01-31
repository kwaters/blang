#include <stdint.h>

typedef intptr_t I;
extern I B_main;

int main(int argc, char **argv)
{
    ((I (*)(I *))B_main)(0);
}

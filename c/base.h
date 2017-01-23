#pragma once

#include <stdint.h>

typedef intptr_t I;
struct Bstring {
    char *s;
    I len;
};

void ice(char *);

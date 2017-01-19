#pragma once

#include "base.h"

struct Vector {
    I capacity;
    I size;
    I data[1];
};

#define V_IDX(vector, idx) \
    ((vector)->data[idx])

struct Vector *vector_get();
struct Vector *vector_get_reserve(I capacity);
void vector_release(struct Vector *vector);
I vector_size(struct Vector *vector);
void vector_set_size(struct Vector **vector, I size);
I vector_capacity(struct Vector *vector);
void vector_push(struct Vector **vector, I x);
I vector_pop(struct Vector *vector);

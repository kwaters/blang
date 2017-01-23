#include "vector.h"

#include <stdlib.h>

struct Vector *vector_get() {
    return vector_get_reserve(6);
}

struct Vector *vector_get_reserve(I capacity)
{
    struct Vector *vector = malloc(sizeof(struct Vector) +
                                   sizeof(I) * (capacity - 1));
    vector->size = 0;
    vector->capacity = capacity;
    return vector;
}

void vector_release(struct Vector *vector)
{
    free(vector);
}

I vector_size(struct Vector *vector)
{
    return vector->size;
}

static void vector_grow(struct Vector **vector, I capacity)
{
    struct Vector *v = *vector;

    if (v->capacity >= capacity)
        return;

    v = realloc(v, sizeof(struct Vector) + sizeof(I) * (capacity - 1));
    v->capacity = capacity;
    *vector = v;
}

void vector_set_size(struct Vector **vector, I size)
{
    vector_grow(vector, size);
    (*vector)->size = size;
}

I vector_capacity(struct Vector *vector)
{
    return vector->capacity;
}

void vector_push(struct Vector **vector, I x)
{
    struct Vector *v = *vector;
    if (v->size >= v->capacity)
        vector_grow(&v, 2 * v->capacity + 2);
    v->data[v->size++] = x;
    *vector = v;
}

I vector_pop(struct Vector *vector)
{
    return vector->data[--vector->size];
}

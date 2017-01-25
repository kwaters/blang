/* vim: set ft=blang : */

/* Dynamically resizable vectors.
 *
 * Dynamically resizable vectors may be indexed as if they were regular
 * vectors.
 *
 * For example,
 *
 *     v = vcGet();
 *     vcSSize(&v, 2);
 *     v[0] = 1;
 *     v[1] = 2;
 *     foo(v);
 *     vcRlse(v);
 *
 * would create a new vector [1, 2], pass it to foo, and the return it to the
 * core hole.
 */

/* Returns an empty dynamically resizable vector from the core hole. */
vcGet() {
    extrn vcGetR;
    return (vcGetR(6));
}

/* Returns an empty dynamically resizable vector with an initial capacity of
 * |cap|. */
vcGetR(cap) {
    extrn getvec;
    auto v;

    v = getvec(cap + 1) + 2;
    v[-1] = 0;
    v[-2] = cap;
    return (v);
}

/* Release a dynamically resizable vector. */
vcRlse(vec) {
    extrn rlsevec;
    rlsevec(vec - 2, vec[-2] + 1);
}

/* Return the size of a vector */
vcSize(vec) {
    return (vec[-1]);
}

/* Set the size of a resizeable vector.  |v| is the address of the vector. */
vcSSize(v, size)
{
    extrn vcGrow;
    vcGrow(v, size);
    (*v)[-1] = size;
}

/* Return the capacity of a vector */
vcCap(vec) {
    return (vec[-2]);
}

/* Set the capacity of a resizeable vector.  |v| is the address of the
 * vector. */
vcGrow(v, cap) {
    extrn vcGetR, vcRlse;
    auto oldCap, oldV, newV, sz, i;

    oldV = *v;

    /* Never shrink a vector. */
    if (cap <= oldV[-2]) {
        return;
    }

    *v = newV = vcGetR(cap);

    /* Copy over the old vector */
    sz = oldV[-1];
    i = 0;
    while (i < sz)
        newV[i++] = oldV[i];
    newV[-1] = sz;

    newV[-2] = cap;
    vcRlse(oldV);
}

/* Add an element to the end of a vector.  |v| is the address of the vector. */
vcPush(v, x) {
    extrn vcGrow;
    auto vec;
    vec = *v;

    if (vec[-1] >= vec[-2]) {
        /* The vector is full, double the storage for the vector. */
        vcGrow(&vec, 2 * vec[-2] + 2);
    }
    vec[vec[-1]++] = x;

    /* Store the vector back in the caller. */
    *v = vec;
}

/* Returns and removes the last element of a vector. */
vcPop(vec) {
    return (vec[--vec[-1]]);
}

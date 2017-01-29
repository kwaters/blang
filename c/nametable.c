#include "nametable.h"

#include <stdlib.h>

#include "vector.h"

#define NT_ENTRY_SIZE 3

struct NameTableIter {
    I i;
};

static struct Vector *nt_table = 0;
static I nt_arg_count = 0;
static I nt_slot_count = 0;

/* Create or retrieve a name table entry */
static struct NameTableEntry *nt_fetch(Name name);

void nt_reset()
{
    if (!nt_table)
        nt_table = vector_get();

    vector_set_size(&nt_table, 0);
    nt_arg_count = 0;
    nt_slot_count = 0;
}

struct NameTableEntry *nt_fetch(Name name)
{
    I i;
    I size = vector_size(nt_table) / NT_ENTRY_SIZE;
    struct NameTableEntry *table = (struct NameTableEntry *)&V_IDX(nt_table, 0);

    for (i = 0; i < size; i++) {
        if (table[i].name == name) {
            return &table[i];
        }
    }

    vector_set_size(&nt_table, (size + 1) * NT_ENTRY_SIZE);
    table = (struct NameTableEntry *)&V_IDX(nt_table, 0);
    table[size].name = name;
    table[size].flags = 0;
    table[size].slot = 0;
    return &table[size];
}

void nt_add_arg(Name name)
{
    struct NameTableEntry *e = nt_fetch(name);
    if (e->flags != NT_NEW) {
        /* TODO: supposed to report name here. */
        err("rd", "Argument redeclaration");
    }

    e->flags = NT_ARG | NT_DEF_FLAG;
    e->slot = nt_arg_count++;
}

void nt_add_extrn(Name name)
{
    struct NameTableEntry *e = nt_fetch(name);
    if (e->flags != NT_NEW) {
        /* TODO: supposed to report name here. */
        err("rd", "Extrn redeclaration");
    }

    e->flags = NT_EXTRN | NT_DEF_FLAG;
}

void nt_add_auto(Name name)
{
    struct NameTableEntry *e = nt_fetch(name);
    if (e->flags != NT_NEW) {
        /* TODO: supposed to report name here. */
        err("rd", "Auto redeclaration");
    }

    e->flags = NT_AUTO | NT_DEF_FLAG;
    e->slot = nt_slot_count++;
}

void nt_add_internal(Name name)
{
    struct NameTableEntry *e = nt_fetch(name);
    if (e->flags == NT_NEW) {
        e->flags = NT_INTERNAL | NT_DEF_FLAG;
        e->slot = nt_slot_count++;
    } else if (e->flags == NT_INTERNAL) {
        e->flags |= NT_DEF_FLAG;
    } else {
        /* TODO: supposed to report name here. */
        err("rd", "Internal redeclaration");
    }
}

struct NameTableEntry *nt_lookup(Name name)
{
    struct NameTableEntry *e = nt_fetch(name);
    if (e->flags == NT_NEW) {
        e->flags = NT_INTERNAL;
        e->slot = nt_slot_count++;
    }
    return e;
}

void nt_check_defined()
{
    I i;
    I size = vector_size(nt_table) / NT_ENTRY_SIZE;
    struct NameTableEntry *table = (struct NameTableEntry *)&V_IDX(nt_table, 0);

    for (i = 0; i < size; i++) {
        if (!(table[i].flags & NT_DEF_FLAG)) {
            /* TODO: supposed to report name here. */
            err("un", "Undefined variable");
        }
    }
}

struct NameTableIter *nt_iter_get(void)
{
    struct NameTableIter *it = malloc(sizeof(struct NameTableIter));
    it->i = 0;
    return it;
}

void nt_iter_release(struct NameTableIter *it)
{
    free(it);
}

struct NameTableEntry *nt_next(struct NameTableIter *it)
{
    struct NameTableEntry *name;
    I size;

    size = vector_size(nt_table);
    if (it->i >= size)
        return NULL;

    name = (struct NameTableEntry *)&V_IDX(nt_table, it->i);
    it->i += NT_ENTRY_SIZE;
    return name;
}

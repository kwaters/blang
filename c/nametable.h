#pragma once

#include "base.h"
#include "ast.h"

struct NameTableEntry
{
    Name name;
    I flags;
    I slot;     /* argument or auto slot */
};

struct NameTableIter;

enum {
    NT_NEW = 0,
    NT_ARG = 1,
    NT_AUTO = 2,
    NT_INTERNAL = 3,
    NT_EXTRN = 4,

    NT_KIND_MASK = 7,

    NT_DEF_FLAG = 1 << 4
};

/* Remove all nametable entries */
void nt_reset();

/* Add and define entry in the nametable. */
void nt_add_arg(Name name);
void nt_add_extrn(Name name);
void nt_add_auto(Name name);
void nt_add_internal(Name name);

/* Lookup a name, if it's not in the table it's an undefined internal. */
struct NameTableEntry *nt_lookup(Name name);

/* Check that all names are defined. */
void nt_check_defined();

/* Iterate through all names in the nametable. */
struct NameTableIter *nt_iter_get(void);
void nt_iter_release(struct NameTableIter *it);
struct NameTableEntry *nt_next(struct NameTableIter *it);

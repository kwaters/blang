#include "tac.h"

#include <stdio.h>

#include "nametable.h"
#include "vector.h"

static void tac_func_name_pre(Ast **node, void *data);

void tac_function(Ast *f)
{
    I i;
    I sz;

    if (f->kind != A_FDEF)
        ice("FDEF ast node expected.");

    nt_reset();

    /* In 9.1 "Users' Reference to B," printn() makes a recursive call
     * without being explicitly imported as an extrn, so it must be
     * implicitly in the nametable.
     */
    nt_add_extrn(f->fdef.name);

    sz = vector_size(f->fdef.arguments);
    for (i = 0; i < sz; i++)
        nt_add_arg(V_IDX(f->fdef.arguments, i));

    ast_walk(&f, tac_func_name_pre, NULL, NULL);

    nt_check_defined();
    printf("%s(): name check OK.\n", ast_show_name(f->fdef.name));
}

void tac_func_name_pre(Ast **node, void *data)
{
    I i;
    I sz;
    Ast *n = *node;

    switch (n->kind) {
    case A_VAR:
        sz = vector_size(n->var.variables);
        if (n->var.isAuto)
            for (i = 0; i < sz; i += 2)
                nt_add_auto(V_IDX(n->var.variables, i));
        else
            for (i = 0; i < sz; i++)
                nt_add_extrn(V_IDX(n->var.variables, i));
        break;

    case A_LABEL:
        nt_add_internal(n->label.name);
        break;

    case A_NAME:
        nt_lookup(n->name.name);
        break;

    default:
        ;
    }
}

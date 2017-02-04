#include "tac.h"

#include "backend.h"
#include "block.h"
#include "nametable.h"
#include "vector.h"

static void tac_func_name_pre(Ast **node, void *data);
static I tac_value(Ast *n);

static I value_get_temp(void);
I tac_temp_count;
static struct Vector *case_table;

void tac_function(Ast *f)
{
    I i;
    I sz;

    if (f->kind != A_FDEF)
        ice("FDEF ast node expected.");

    case_table = NULL;

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

    tac_temp_count = 1;
    block_reset();
    tac_value(f->fdef.statement);
    tac_add(0, I_RET, 0, 0, 0);
}

I value_get_temp()
{
    return tac_temp_count++;
}

void tac_add(I dst, I instruction, I a1, I a2, I a3)
{
    struct Vector *vec = block_current->instructions;
    vector_push(&vec, dst);
    vector_push(&vec, instruction);
    vector_push(&vec, a1);
    vector_push(&vec, a2);
    vector_push(&vec, a3);
    block_current->instructions = vec;
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

I tac_value(Ast *n)
{
    I i;
    I size;
    I v;
    I temp;
    I lhs;
    I rhs;
    Block *b;
    Block *yes;
    Block *no;
    struct NameTableEntry *name;
    struct Vector *old_case_table;

    switch (n->kind) {
    case A_VOID:
        /* nop */
        return 0;

    case A_VAR:
        tac_value(n->var.statement);
        return 0;

    case A_LABEL:
        name = nt_lookup(n->label.name);
        name->slot = (I)block_split();
        tac_value(n->label.statement);
        return 0;

    case A_CLABEL:
        if (!case_table)
            err(">c", "case label outside switch.");

        vector_push(&case_table, n->clabel.num);
        vector_push(&case_table, (I)block_split());
        tac_value(n->clabel.statement);
        return 0;

    case A_SEQ:
        size = vector_size(n->seq.statements);
        for (i = 0; i < size; i++)
            tac_value((Ast *)V_IDX(n->seq.statements, i));
        return 0;

    case A_IFE:
        v = tac_value(n->ife.cond);
        b = block_current;

        block_current = yes = block_get();
        tac_value(n->ife.then);

        block_current = no = block_get();
        tac_value(n->ife.else_);

        block_current = b;
        tac_add(0, I_IF, (I)v, (I)yes, (I)no);

        b = block_get();
        block_current = yes;
        tac_add(0, I_J, (I)b, 0, 0);
        block_current = no;
        tac_add(0, I_J, (I)b, 0, 0);
        block_current = b;
        return 0;

    case A_WHILE:
        b = block_split();
        v = tac_value(n->while_.cond);

        block_current = yes = block_get();
        tac_value(n->while_.statement);
        tac_add(0, I_J, (I)b, 0, 0);

        no = block_get();
        block_current = b;
        tac_add(0, I_IF, (I)v, (I)yes, (I)no);
        block_current = no;
        return 0;

    case A_SWITCH:
        v = tac_value(n->switch_.value);

        b = block_current;

        block_current = block_get();
        old_case_table = case_table;
        case_table = n->switch_.table;
        tac_value(n->switch_.statement);
        n->switch_.table = case_table;
        case_table = old_case_table;

        no = block_split();
        block_current = b;
        tac_add(0, I_SWTCH, v, (I)n->switch_.table, (I)no);
        block_current = no;
        return 0;

    case A_GOTO:
        tac_add(0, I_CJ, tac_value(n->goto_.expr), 0, 0);
        block_current = block_get();
        return 0;

    case A_VRTRN:
        tac_add(0, I_RET, 0, 0, 0);
        return 0;

    case A_RTRN:
        tac_add(0, I_RET, tac_value(n->rtrn.expr), 0, 0);
        return 0;

    case A_EXPR:
        tac_value(n->expr.expr);
        return 0;

    case A_NAME:
        v = value_get_temp();
        name = nt_lookup(n->name.name);
        i = name->flags & NT_KIND_MASK;
        if (i == NT_ARG) {
            tac_add(v, I_ARG, (I)name, 0, 0);
        } else if (i == NT_AUTO || i == NT_INTERNAL) {
            tac_add(v, I_AUTO, (I)name, 0, 0);
        } else if (i == NT_EXTRN) {
            tac_add(v, I_EXTRN, (I)name, 0, 0);
        } else {
            ice("Unexpected symbol type.");
        }
        return v;

    case A_NUM:
        v = value_get_temp();
        tac_add(v, I_NUM, n->num.num, 0, 0);
        return v;

    case A_STR:
        v = value_get_temp();
        tac_add(v, I_STR, (I)n->str.s, n->str.len, 0);
        return v;

    case A_ASSIGN:
        lhs = tac_value(n->assign.lhs);
        rhs = tac_value(n->assign.rhs);
        if (n->assign.op) {
            v = value_get_temp();
            tac_add(v, I_LOAD, lhs, 0, 0);
            tac_add(v, I_BIN, n->assign.op, v, rhs);
            tac_add(0, I_STORE, lhs, v, 0);
            return v;
        } else {
            tac_add(0, I_STORE, lhs, rhs, 0);
            return rhs;
        }

    case A_PRE:
    case A_POST:
        lhs = tac_value(n->pre.expr);
        v = value_get_temp();
        tac_add(v, I_LOAD, lhs, 0, 0);
        rhs = value_get_temp();
        tac_add(rhs, I_NUM, n->pre.num, 0, 0);
        temp = value_get_temp();
        tac_add(temp, I_BIN, O_PLUS, v, rhs);
        tac_add(0, I_STORE, lhs, temp, 0);
        return n->kind ? temp : v;

    case A_UNARY:
        lhs = tac_value(n->unary.expr);
        v = value_get_temp();
        tac_add(v, I_UNARY, n->unary.op, lhs, 0);
        return v;

    case A_BIN:
        lhs = tac_value(n->bin.lhs);
        rhs = tac_value(n->bin.rhs);
        v = value_get_temp();
        tac_add(v, I_BIN, n->bin.op, lhs, rhs);
        return v;

    case A_COND:
        v = tac_value(n->cond.cond);
        temp = value_get_temp();

        b = block_current;
        block_current = yes = block_get();
        tac_add(temp, I_COPY, tac_value(n->cond.yes), 0, 0);
        block_current = no = block_get();
        tac_add(temp, I_COPY, tac_value(n->cond.no), 0, 0);

        block_current = b;
        tac_add(0, I_IF, (I)v, (I)yes, (I)no);
        b = block_get();
        block_current = yes;
        tac_add(0, I_J, (I)b, 0, 0);
        block_current = no;
        tac_add(0, I_J, (I)b, 0, 0);
        block_current = b;
        return temp;

    case A_CALL:
        size = vector_size(n->call.arguments);
        if (size) {
            v = value_get_temp();
            tac_add(v, I_ASPACE, size, 0, 0);
            for (i = 0; i < size; i++)
                tac_add(0, I_PARG, i, v,
                        tac_value((Ast *)V_IDX(n->call.arguments, i)));
            temp = value_get_temp();
            lhs = tac_value(n->call.function);
            tac_add(temp, I_CALL, lhs, v, size);
        } else {
            temp = value_get_temp();
            lhs = tac_value(n->call.function);
            tac_add(temp, I_CALL, lhs, 0, size);
        }
        return temp;

    case A_LOAD:
        temp = tac_value(n->load.expr);
        v = value_get_temp();
        tac_add(v, I_LOAD, temp, 0, 0);
        return v;

    default:
        ice("Unexpected node.");
    }

    ice("Unreachable");
    return 0;
}

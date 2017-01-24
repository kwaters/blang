#include "lrvalue.h"
#include "vector.h"

static void force_rvalue(Ast **node);
static void check_lvalue(Ast **node);

void lrvalue_pass_pre(Ast **node, void *data)
{
    Ast *n = *node;
    Ast *temp;
    I i;
    I sz;

    switch (n->kind) {
    /* statements containing an expression. */
    case A_IFE:
        force_rvalue(&n->ife.cond);
        break;
    case A_WHILE:
        force_rvalue(&n->while_.cond);
        break;
    case A_SWITCH:
        force_rvalue(&n->switch_.value);
        break;
    case A_GOTO:
        force_rvalue(&n->goto_.expr);
        break;
    case A_RTRN:
        force_rvalue(&n->rtrn.expr);
        break;
    case A_EXPR:
        force_rvalue(&n->expr.expr);
        break;

    /* lvalues */
    case A_NAME:
        break;
    case A_IND:
        force_rvalue(&n->ind.expr);
        /* This node is only used for lvalue/rvalue determination and can be
         * removed at this time. */
        *node = n->ind.expr;
        ast_release(n);
        /* Visit the hoisted node. */
        lrvalue_pass_pre(node, data);
        break;
    case A_INDEX:
        force_rvalue(&n->index.vector);
        force_rvalue(&n->index.index);
        /* Replace with addition.  Our parent has already been re-factored so
         * it already knows this node is an lvalue.  We do not need to visit
         * this new node only its children. */
        temp = ast_get(A_BIN);
        temp->bin.lhs = n->index.vector;
        temp->bin.rhs = n->index.index;
        temp->bin.op = O_PLUS;
        *node = temp;
        ast_release(n);
        break;

    /* rvalues */
    case A_NUM:
    case A_STR:
        break;
    case A_ASSIGN:
        check_lvalue(&n->assign.lhs);
        force_rvalue(&n->assign.rhs);
        break;
    case A_PRE:
        check_lvalue(&n->pre.expr);
        break;
    case A_POST:
        check_lvalue(&n->post.expr);
        break;
    case A_UNARY:
        force_rvalue(&n->unary.expr);
        break;
    case A_ADDR:
        check_lvalue(&n->addr.expr);
        /* This node is only used for lvalue/rvalue determination and can be
         * removed at this time. */
        *node = n->addr.expr;
        ast_release(n);
        /* Visit the hoisted node. */
        lrvalue_pass_pre(node, data);
        break;
    case A_BIN:
        force_rvalue(&n->bin.lhs);
        force_rvalue(&n->bin.rhs);
        break;
    case A_COND:
        force_rvalue(&n->cond.cond);
        force_rvalue(&n->cond.yes);
        force_rvalue(&n->cond.no);
        break;
    case A_CALL:
        force_rvalue(&n->call.function);
        sz = vector_size(n->call.arguments);
        for (i = 0; i < sz; i++)
            force_rvalue((Ast **)&V_IDX(n->call.arguments, i));
        break;

    default:
        ;
    }
}

void lrvalue_pass(Ast **node)
{
    ast_walk(node, lrvalue_pass_pre, NULL, NULL);
}

static void force_rvalue(Ast **node)
{
    Ast *n = *node;

    switch (n->kind) {
    case A_NAME:
    case A_IND:
    case A_INDEX:
        break;

    case A_NUM:
    case A_STR:
    case A_ASSIGN:
    case A_PRE:
    case A_POST:
    case A_UNARY:
    case A_ADDR:
    case A_BIN:
    case A_COND:
    case A_CALL:
    case A_LOAD:
        /* Already an rvalue */
        return;

    default:
        ice("Unexpected node in check lvalue");
    }

    /* We have an lvalue, insert a LOAD. */
    *node = ast_get(A_LOAD);
    (*node)->load.expr = n;
}

static void check_lvalue(Ast **node)
{
    Ast *n = *node;

    switch (n->kind) {
    case A_NAME:
    case A_IND:
    case A_INDEX:
        break;

    case A_NUM:
    case A_STR:
    case A_ASSIGN:
    case A_PRE:
    case A_POST:
    case A_UNARY:
    case A_ADDR:
    case A_BIN:
    case A_COND:
    case A_CALL:
    case A_LOAD:
        err("lv", "Rvalue where lvalue expected.");
        return;

    default:
        ice("Unexpected node in check_lvalue()");
    }
}

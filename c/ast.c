#include "ast.h"

#include <stdlib.h>
#include <string.h>

#include "vector.h"

static AstWalkFunc ast_pre_func;
static AstWalkFunc ast_post_func;
static void *ast_data;

static void ast_walk_vector(struct Vector *vector);

static void ast_walk_impl(union Ast **node)
{
    union Ast *n = *node;

    if (ast_pre_func)
        ast_pre_func(node, ast_data);

    switch (n->kind) {
    case A_PROG:
        ast_walk_vector(n->prog.definitions);
        break;
    case A_XDEF:
        /* TODO */
        break;
    case A_FDEF:
        ast_walk_impl(&n->fdef.statement);
        break;
    case A_VAR:
        /* TODO */
        break;
    case A_LABEL:
        /* TODO */
        break;
    case A_SEQ:
        ast_walk_vector(n->seq.statements);
        break;
    case A_IFE:
        ast_walk_impl(&n->ife.cond);
        ast_walk_impl(&n->ife.then);
        ast_walk_impl(&n->ife.else_);
        break;
    case A_WHILE:
        ast_walk_impl(&n->while_.cond);
        ast_walk_impl(&n->while_.statement);
        break;
    case A_SWITCH:
        ast_walk_impl(&n->switch_.value);
        ast_walk_impl(&n->switch_.statement);
        break;
    case A_GOTO:
        ast_walk_impl(&n->goto_.expr);
        break;
    case A_VRTRN:
        break;
    case A_RTRN:
        ast_walk_impl(&n->rtrn.expr);
        break;
    case A_EXPR:
        ast_walk_impl(&n->expr.expr);
        break;
    case A_VOID:
        break;
    case A_NAME:
        break;
    case A_IND:
        ast_walk_impl(&n->ind.expr);
        break;
    case A_INDEX:
        ast_walk_impl(&n->index.vector);
        ast_walk_impl(&n->index.index);
        break;
    case A_NUM:
        break;
    case A_STR:
        break;
    case A_ASSIGN:
        ast_walk_impl(&n->assign.lhs);
        ast_walk_impl(&n->assign.rhs);
        break;
    case A_PRE:
        ast_walk_impl(&n->pre.expr);
        break;
    case A_POST:
        ast_walk_impl(&n->post.expr);
        break;
    case A_UNARY:
        ast_walk_impl(&n->post.expr);
        break;
    case A_ADDR:
        ast_walk_impl(&n->addr.expr);
        break;
    case A_BIN:
        ast_walk_impl(&n->bin.lhs);
        ast_walk_impl(&n->bin.rhs);
        break;
    case A_COND:
        ast_walk_impl(&n->cond.cond);
        ast_walk_impl(&n->cond.lhs);
        ast_walk_impl(&n->cond.rhs);
        break;
    case A_CALL:
        ast_walk_impl(&n->call.function);
        ast_walk_vector(n->call.arguments);
        break;
    default:
        ice("Unexpected AST node");
    }

    if (ast_post_func)
        ast_post_func(node, ast_data);
}

static void ast_walk_vector(struct Vector *vector)
{
    I i;
    I size;

    size = vector_size(vector);
    for (i = 0; i < size; i++)
        ast_walk_impl((union Ast **)&V_IDX(vector, i));
}


void ast_walk(union Ast **node, AstWalkFunc pre_func, AstWalkFunc post_func, void *data)
{
    ast_pre_func = pre_func;
    ast_post_func = post_func;
    ast_data = data;
    ast_walk_impl(node);
}

union Ast *ast_get(AstKind kind)
{
    union Ast *ast = malloc(sizeof(union Ast));
    memset(ast, 0, sizeof(union Ast));

    ast->kind = kind;

    switch (ast->kind) {
    case A_PROG:
        ast->prog.definitions = vector_get();
        break;
    case A_XDEF:
        /* TODO */
        break;
    case A_FDEF:
        ast->fdef.arguments = vector_get();
        break;
    case A_VAR:
        /* TODO */
        break;
    case A_LABEL:
        /* TODO */
        break;
    case A_SEQ:
        ast->seq.statements = vector_get();
        break;
    case A_CALL:
        ast->call.arguments = vector_get();
        break;
    default:
        ;
    }

    return ast;
}

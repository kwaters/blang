#include "ast.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "vector.h"

static AstWalkFunc ast_pre_func;
static AstWalkFunc ast_post_func;
static void *ast_data;

static void ast_walk_vector(struct Vector *vector);

static void ast_walk_impl(Ast **node)
{
    Ast *n = *node;

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
        ast_walk_impl(&n->cond.yes);
        ast_walk_impl(&n->cond.no);
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
        ast_walk_impl((Ast **)&V_IDX(vector, i));
}


void ast_walk(Ast **node, AstWalkFunc pre_func, AstWalkFunc post_func, void *data)
{
    ast_pre_func = pre_func;
    ast_post_func = post_func;
    ast_data = data;
    ast_walk_impl(node);
}

Ast *ast_get(AstKind kind)
{
    Ast *ast = malloc(sizeof(Ast));
    memset(ast, 0, sizeof(Ast));

    ast->kind = kind;

    /* In the B version allocate the vector here. */

    return ast;
}

void ast_release(Ast *ast)
{
    switch (ast->kind) {
    case A_PROG:
        vector_release(ast->prog.definitions);
        break;
    case A_XDEF:
        /* TODO */
        break;
    case A_FDEF:
        vector_release(ast->fdef.arguments);
        break;
    case A_VAR:
        /* TODO */
        break;
    case A_LABEL:
        /* TODO */
        break;
    case A_SEQ:
        vector_release(ast->seq.statements);
        break;
    case A_CALL:
        vector_release(ast->call.arguments);
        break;
    default:
        ;
    }

    free(ast);
}

static void ast_release_recursive_post(Ast **ast, void *data)
{
    ast_release(*ast);
}

void ast_release_recursive(Ast *ast)
{
    ast_walk(&ast, NULL, ast_release_recursive_post, NULL);
}

Ast *ast_binop(Ast *lhs, Ast *rhs, I op)
{
    Ast *ast = ast_get(A_BIN);
    ast->bin.lhs = lhs;
    ast->bin.rhs = rhs;
    ast->bin.op = op;
    return ast;
}

static void ast_show_pre(Ast **node, void *v) {
    char *name[] = {
        [A_PROG] = "PROG",
        [A_XDEF] = "XDEF",
        [A_FDEF] = "FDEF",
        [A_VAR] = "VAR",
        [A_LABEL] = "LABEL",
        [A_SEQ] = "SEQ",
        [A_IFE] = "IFE",
        [A_WHILE] = "WHILE",
        [A_SWITCH] = "SWITCH",
        [A_GOTO] = "GOTO",
        [A_VRTRN] = "VRTRN",
        [A_RTRN] = "RTRN",
        [A_EXPR] = "EXPR",
        [A_VOID] = "VOID",
        [A_NAME] = "NAME",
        [A_IND] = "IND",
        [A_INDEX] = "INDEX",
        [A_NUM] = "NUM",
        [A_STR] = "STR",
        [A_ASSIGN] = "ASSIGN",
        [A_PRE] = "PRE",
        [A_POST] = "POST",
        [A_UNARY] = "UNARY",
        [A_ADDR] = "ADDR",
        [A_BIN] = "BIN",
        [A_COND] = "COND",
        [A_CALL] = "CALL"
    };
    printf("{%s ", name[(*node)->kind]);
}
static void ast_show_post(Ast **node, void *v) {
    printf("}");
}
void ast_show(Ast *root)
{
    ast_walk(&root, ast_show_pre, ast_show_post, NULL);
    printf("\n");
}

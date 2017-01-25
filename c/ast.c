#include "ast.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "vector.h"

static AstWalkFunc ast_pre_func;
static AstWalkFunc ast_post_func;
static void *ast_data;

static void ast_walk_vector(struct Vector *vector);
static void ast_show_string(char *s, I len);
char *ast_show_bin(I op);
char *ast_show_unary(I op);

static void ast_walk_impl(Ast **node)
{
    Ast *n;

    if (ast_pre_func)
        ast_pre_func(node, ast_data);

    /* NOTE: ast_pre_func may have altered *node */
    n = *node;

    switch (n->kind) {
    case A_PROG:
        ast_walk_vector(n->prog.definitions);
        break;
    case A_XDEF:
        ast_walk_vector(n->xdef.initializer);
        break;
    case A_FDEF:
        ast_walk_impl(&n->fdef.statement);
        break;
    case A_VAR:
        ast_walk_impl(&n->var.statement);
        break;
    case A_LABEL:
        ast_walk_impl(&n->label.statement);
        break;
    case A_CLABEL:
        ast_walk_impl(&n->clabel.statement);
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
    case A_LOAD:
        ast_walk_impl(&n->load.expr);
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
        vector_release(ast->xdef.initializer);
        break;
    case A_FDEF:
        vector_release(ast->fdef.arguments);
        break;
    case A_VAR:
        vector_release(ast->var.variables);
        break;
    case A_SEQ:
        vector_release(ast->seq.statements);
        break;
    case A_SWITCH:
        vector_release(ast->switch_.table);
        break;
    case A_STR:
        free(ast->str.s);
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

static int ast_show_indent_level = 0;
static int ast_show_close_node = 0;

static void ast_show_pre(Ast **node, void *v) {
    Ast *n;
    int i;
    int end;

    for (i = 0; i < ast_show_indent_level; ++i)
        printf("  ");

    ast_show_close_node = 1;
    n = *node;
    switch (n->kind) {
    case A_PROG:
        printf("PROG {\n");
        break;
    case A_XDEF:
        printf("XDEF %s %ld {\n", ast_show_name(n->xdef.name), n->xdef.size);
        break;
    case A_FDEF:
        printf("FDEF %s(", ast_show_name(n->fdef.name));
        for (i = 0, end = vector_size(n->fdef.arguments); i < end; i++) {
            if (i != 0)
                printf(", ");
            printf("%s", ast_show_name(V_IDX(n->fdef.arguments, i)));
        }
        printf(") {\n");
        break;
    case A_VAR:
        if (n->var.isAuto) {
            printf("VAR AUTO [");
            end = vector_size(n->var.variables);
            if (end % 2 != 0)
                ice("Unexpected VAR size.");
            for (i = 0; i < end; i += 2) {
                if (i != 0)
                    printf(", ");
                printf("%s %ld",
                       ast_show_name(V_IDX(n->fdef.arguments, i)),
                       V_IDX(n->fdef.arguments, i + 1));
            }
        } else {
            printf("VAR EXTRN [");
            end = vector_size(n->var.variables);
            for (i = 0; i < end; i++) {
                if (i != 0)
                    printf(", ");
                printf("%s", ast_show_name(V_IDX(n->fdef.arguments, i)));
            }
        }
        printf("] {\n");
        break;
    case A_LABEL:
        printf("LABEL %s {\n", ast_show_name(n->label.name));
        break;
    case A_CLABEL:
        printf("CLABEL %ld {\n", n->clabel.num);
        break;
    case A_SEQ:
        printf("SEQ {\n");
        break;
    case A_IFE:
        printf("IFE {\n");
        break;
    case A_WHILE:
        printf("WHILE {\n");
        break;
    case A_SWITCH:
        printf("SWITCH {\n");
        /* Don't need to print table. */
        break;
    case A_GOTO:
        printf("GOTO {\n");
        break;
    case A_VRTRN:
        printf("VRTRN\n");
        ast_show_close_node = 0;
        break;
    case A_RTRN:
        printf("RTRN {\n");
        break;
    case A_EXPR:
        printf("EXPR {\n");
        break;
    case A_VOID:
        printf("VOID\n");
        ast_show_close_node = 0;
        break;
    case A_NAME:
        printf("NAME %s\n", ast_show_name(n->name.name));
        ast_show_close_node = 0;
        break;
    case A_IND:
        printf("IND {\n");
        break;
    case A_INDEX:
        printf("INDEX {\n");
        break;
    case A_NUM:
        printf("NUM %ld\n", n->num.num);
        ast_show_close_node = 0;
        break;
    case A_STR:
        printf("STR \"");
        ast_show_string(n->str.s, n->str.len);
        printf("\"\n");
        ast_show_close_node = 0;
        break;
    case A_ASSIGN:
        if (n->assign.op) {
            printf("ASSIGN %s {\n", ast_show_bin(n->assign.op));
        } else {
            printf("ASSIGN {\n");
        }
        break;
    case A_PRE:
        printf("PRE %ld {\n", n->pre.num);
        break;
    case A_POST:
        printf("POST %ld {\n", n->post.num);
        break;
    case A_UNARY:
        printf("UNARY %s {\n", ast_show_unary(n->unary.op));
        break;
    case A_ADDR:
        printf("ADDR {\n");
        break;
    case A_BIN:
        printf("BIN %s {\n", ast_show_bin(n->bin.op));
        break;
    case A_COND:
        printf("COND {\n");
        break;
    case A_CALL:
        printf("CALL {\n");
        break;
    case A_LOAD:
        printf("LOAD {\n");
        break;
    default:
        ice("Unhandled kind in ast_show_pre.");
    }

    if (ast_show_close_node)
        ast_show_indent_level++;
}

static void ast_show_post(Ast **node, void *v) {
    int i;

    if (!ast_show_close_node) {
        ast_show_close_node = 1;
        return;
    }

    ast_show_indent_level--;
    for (i = 0; i < ast_show_indent_level; ++i)
        printf("  ");
    printf("}\n");
}

void ast_show(Ast *root)
{
    ast_walk(&root, ast_show_pre, ast_show_post, NULL);
    printf("\n");
}

char *ast_show_name(I name)
{
    static char s[9] = "";
    int i;

    for (i = 0; i < 8; i++) {
        s[i] = name & 0xff;
        name >>= 8;
    }
    return s;
}

void ast_show_string(char *s, I len)
{
    I i;
    for (i = 0; i < len; ++i) {
        char c = s[i];
        if (c == '\0') {
            printf("*0");
        } else if (c == '\x04') {
            printf("*e");
        } else if (c == '\t') {
            printf("*t");
        } else if (c == '\n') {
            printf("*n");
        } else if (c == '*') {
            printf("**");
        } else if (c == '"') {
            printf("*\"");
        } else if (c >= ' ' && c <= '~') {
            printf("%c", c);
        } else {
            printf("?");
        }
    }
}

char *ast_show_bin(I op)
{
    switch(op) {
    case O_OR: return "OR";
    case O_AND: return "AND";
    case O_EQ: return "EQ";
    case O_NEQ: return "NEQ";
    case O_LT: return "LT";
    case O_LTE: return "LTE";
    case O_GT: return "GT";
    case O_GTE: return "GTE";
    case O_SHIFTL: return "SHIFTL";
    case O_SHIFTR: return "SHIFTR";
    case O_MINUS: return "MINUS";
    case O_PLUS: return "PLUS";
    case O_REM: return "REM";
    case O_MUL: return "MUL";
    case O_DIV: return "DIV";
    }
    return "";
}

char *ast_show_unary(I op)
{
    switch(op) {
    case U_NEG: return "NEG";
    case U_NOT: return "NOT";
    }
    return "";
}

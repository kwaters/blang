#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "ast.h"
#include "backend.h"
#include "blang.tab.h"
#include "lrvalue.h"
#include "tac.h"
#include "vector.h"

extern FILE *yyin;
extern Ast *yy_program;

void ice(char *s)
{
    fprintf(stderr, "ICE: %s\n", s);
    abort();
}

void err(char *code, char *s)
{
    extern int yylineno;
    fprintf(stderr, "%s (%d): %s\n", code, yylineno, s);
    exit(1);
}

void yyerror(char *s)
{
    err("xx", s);
}

int main(int argc, char *argv[])
{
    I i;
    I sz;
    I dumpAst = 0;
    I dumpLr = 0;
    char *input = NULL;

    for (i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-dump-ast") == 0) {
            dumpAst = 1;
        } else if (strcmp(argv[i], "-dump-lr-ast") == 0) {
            dumpLr = 1;
        } else if (!input) {
            input = argv[i];
        } else {
            fprintf(stderr, "usage: bc1 SOURCE\n");
            return 1;
        }
    }
    if (!input) {
        fprintf(stderr, "usage: bc1 SOURCE\n");
        return 1;
    }

    FILE *f = fopen(input, "r");
    if (!f) {
        fprintf(stderr, "ERROR: cannot read \"%s\"\n", argv[1]);
        return 1;
    }

    yyin = f;
    if (yyparse())
        return 1;

    if (dumpAst) {
        ast_show(yy_program);
        return 0;
    }

    lrvalue_pass(&yy_program);

    if (dumpLr) {
        ast_show(yy_program);
        return 0;
    }

    backend_header();

    sz = vector_size(yy_program->prog.definitions);
    for (i = 0; i < sz; i++) {
        Ast *n = (Ast *)V_IDX(yy_program->prog.definitions, i);
        if (n->kind == A_FDEF) {
            tac_function(n);
            backend_show(n);
        } else {
            backend_xdef(n);
        }
    }

    ast_release_recursive(yy_program);

    return 0;
}

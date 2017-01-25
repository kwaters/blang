#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "ast.h"
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
    fprintf(stderr, "%s: %s\n", code, s);
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

    if (argc != 2) {
        fprintf(stderr, "usage: bc1 SOURCE\n");
        return 1;
    }

    FILE *f = fopen(argv[1], "r");
    if (!f) {
        fprintf(stderr, "ERROR: cannot read \"%s\"\n", argv[1]);
        return 1;
    }

    yyin = f;
    if (yyparse())
        return 1;

    lrvalue_pass(&yy_program);

    ast_show(yy_program);

    sz = vector_size(yy_program->prog.definitions);
    for (i = 0; i < sz; i++) {
        Ast *n = (Ast *)V_IDX(yy_program->prog.definitions, i);
        if (n->kind == A_FDEF)
            tac_function(n);
    }

    ast_release_recursive(yy_program);

    return 0;
}

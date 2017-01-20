#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "ast.h"
#include "blang.tab.h"

extern FILE *yyin;

void ice(char *s)
{
    fprintf(stderr, "ICE: %s\n", s);
    abort();
}

void yyerror(char *s)
{
    fprintf(stderr, "ERROR: syntax: %s\n", s);
    exit(1);
}

int main(int argc, char *argv[])
{
    int ret;

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
    ret = yyparse();
    printf("yyparse() = %d\n", ret);
    return 0;
}

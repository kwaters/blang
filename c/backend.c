#include "backend.h"

#include <stdio.h>

#include "base.h"
#include "block.h"
#include "nametable.h"
#include "tac.h"

static void backend_show_block(Block *block);
static I backend_count_arg_slots(Ast *f);

static char *optable[] = { "",
    "|",
    "&",
    "==",
    "!=",
    "<",
    "<=",
    ">",
    ">=",
    "<<",
    ">>",
    "-",
    "+",
    "%",
    "*",
    "/"
};
static char *uoptable[] = { "", "-", "~" };

void backend_header(void)
{
    printf("#include <stdint.h>\n");
    printf("#include <stddef.h>\n");
    printf("#define ITOP(i) ((I*)((i) << 3))\n");
    printf("#define PTOI(p) ((I)(p) >> 3)\n");
    printf("#define ASPACE(x) ({ I *ta = argp; argp += (x); (I)ta; })\n");
    printf("#define PARG(a, b, c) ((I *)a)[b] = c\n");
    printf("#define ARGCOUNT(count) I oargs[count]; I *argp = oargs;\n");
    printf("#define POPARG(count) do { argp -= count; } while(0)\n");
    printf("typedef intptr_t I;\n");
    printf("typedef I (*FN)(I[]);\n");
}

static char *backend_mangle(Name name, I impl)
{
    static char s[32] = "B";
    char *p = s + 1;
    int i;
    int c;

    if (impl)
        *p++ = 'I';

    for (i = 0; i < 8; i++) {
        c = (name >> (8 * i)) & 0xff;
        if (c == '.')
            *p++ = 'a' + i;
    }
    *p++ = '_';
    for (i = 0; i < 8; i++) {
        c = (name >> (8 * i)) & 0xff;
        if (c == '.')
            *p++ = '_';
        else
            *p++ = c;
    }
    *p++ = '\0';

    return s;
}

void backend_show(Ast *function)
{
    struct NameTableIter *it;
    struct NameTableEntry *name;
    I i;
    I size;
    I kind;

    if (function->kind != A_FDEF)
        ice("Expected FDEF node.");

    printf("I %s(I *args) {\n", backend_mangle(function->fdef.name, 1));

    it = nt_iter_get();
    while ((name = nt_next(it))) {
        kind = name->flags & NT_KIND_MASK;
        switch (kind) {
        case NT_ARG:
            break;
        case NT_AUTO:
            /* TODO: Arrays. */
            printf("    I %s;\n", backend_mangle(name->name, 0));
            break;
        case NT_EXTRN:
            printf("    extern I %s;\n", backend_mangle(name->name, 0));
            break;
        case NT_INTERNAL:
            printf("    I %s = (I)&&BB%02ld;\n", backend_mangle(name->name, 0),
                   ((Block *)name->slot)->name);
            break;
        }
    }
    nt_iter_release(it);

    printf("    ARGCOUNT(%ld)\n", backend_count_arg_slots(function));

    size = tac_temp_count;
    if (size > 1) {
        for (i = 1; i < size; i++) {
            switch (i % 10) {
            case 1:
                printf("    I t%ld", i);
                break;
            case 0:
                printf(", t%ld;\n", i);
                break;
            default:
                printf(", t%ld", i);
                break;
            }
        }
        if (i % 10 != 1)
            printf(";\n");
    }

    size = vector_size(block_list);
    for (i = 0; i < size; i++)
        backend_show_block((Block *)V_IDX(block_list, i));

    printf("}\n");
    printf("I %s = ", backend_mangle(function->fdef.name, 0));
    printf("(I)%s;\n\n", backend_mangle(function->fdef.name, 1));
}


I backend_count_arg_slots(Ast *f)
{
    I i;
    I j;
    I size;
    I *inst;
    I inst_size;

    I count;
    I max_count;
    Block *b;

    count = max_count = 0;

    size = vector_size(block_list);
    for (i = 0; i < size; i++) {
        b = (Block *)V_IDX(block_list, i);
        inst_size = vector_size(b->instructions);
        for (j = 0; j < inst_size; j += 5) {
            inst = &V_IDX(b->instructions, j);
            switch (inst[1]) {
            case I_ASPACE:
                count += inst[2];
                if (count > max_count)
                    max_count = count;
                break;

            case I_CALL:
                count -= inst[4];
                break;

            default:
                ;
            }
        }

        if (count != 0)
            ice("Unusued function arguments.");
    }
    return max_count;
}


static void backend_escape(I fst, I snd, I *inst)
{
    I arg;

    if (!(fst >= '0' && fst <= '4'))
        ice("Bad template");

    arg = inst[fst - '0'];

    switch (snd) {
    case 'd':
        printf("%ld", arg);
        break;
    case 't':
        printf("t%ld", arg);
        break;
    case 'B':
        printf("BB%02ld", ((Block *)arg)->name);
        break;
    case 'N':
        printf("%s", backend_mangle(((struct NameTableEntry *)arg)->name, 0));
        break;
    case 'O':
        printf("%s", optable[arg]);
        break;
    case 'S':
        printf("%ld", ((struct NameTableEntry *)arg)->slot);
        break;
    case 'U':
        printf("%s", uoptable[arg]);
        break;
    default:
        ice("Bad template");
    }
}

static void backend_print(I *inst, char *template)
{
    if (!template)
        ice("No template");

    printf("    ");
    if (inst[0])
        printf("t%ld = ", inst[0]);

    for (char *p = template; *p; p++) {
        if (*p == '$') {
            backend_escape(p[1], p[2], inst);
            p += 2;
        } else {
            putchar(*p);
        }
    }
    putchar('\n');
}

void backend_show_block(Block *block)
{
    char *patterns[] = {
        [I_NUM] = "$2d;",
        [I_ARG] = "PTOI(&args[$2S]);",
        [I_AUTO] = "PTOI(&$2N);",
        [I_EXTRN] = "PTOI(&$2N);",
        [I_BIN] = "$3t $2O $4t;",
        [I_UNARY] = "$2U$3t;",
        [I_COPY] = "$2t;",
        [I_LOAD] = "*ITOP($2t);",
        [I_STORE] = "*ITOP($2t) = $3t;",
        [I_ASPACE] = "ASPACE($2d);",
        [I_PARG] = "PARG($3t, $2d, $4t);",
        [I_J] = "goto $2B;",
        [I_CJ] = "goto *(void *)$2t;",
        [I_IF] = "if ($2t) goto $3B; else goto $4B;"
    };

    I tinst[3] = {0};
    I *inst;
    I i;
    I size;

    printf("BB%02ld:\n", block->name);

    size = vector_size(block->instructions);
    for (i = 0; i < size; i += 5) {
        inst = &V_IDX(block->instructions, i);

        switch (inst[1]) {
        case I_SWTCH:
            backend_print(inst, "switch ($2t) {");
            size = vector_size((struct Vector *)inst[3]);
            for (i = 0; i < size; i += 2) {
                tinst[1] = V_IDX((struct Vector *)inst[3], i);
                tinst[2] = V_IDX((struct Vector *)inst[3], i + 1);
                backend_print(tinst, "case $1d: goto $2B;");
            }
            backend_print(inst, "default: goto $4B;");
            backend_print(inst, "}");
            break;

        case I_STR:
            backend_print(inst, "/* STR */ 0;");
            break;

        case I_CALL:
            if (inst[3] == 0)
                backend_print(inst, "((FN)$2t)(NULL);  POPARG($4d);");
            else
                backend_print(inst, "((FN)$2t)((I *)$3t);  POPARG($4d);");
            break;

        case I_RET:
            if (inst[2] > 0)
                backend_print(inst, "return $2t;");
            else
                backend_print(inst, "return 0;");
            break;

        default:
            backend_print(inst, patterns[inst[1]]);

        }
    }
}

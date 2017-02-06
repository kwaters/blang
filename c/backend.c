#include "backend.h"

#include <stdio.h>

#include "base.h"
#include "block.h"
#include "call_count.h"
#include "nametable.h"
#include "tac.h"

static void backend_initializer(Ast *n);
static char *backend_mangle(Name name, I impl);
static void backend_show_block(Block *block);
static struct Vector *string_table;

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
static char *uoptable[] = { "", "-", "!" };

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

static void backend_show_string(I *inst)
{
    I i;
    I size = vector_size(string_table);
    for (i = 0; i < size; i += 2) {
        if ((I *)V_IDX(string_table, i) == inst) {
            printf("str%ld", V_IDX(string_table, i + 1));
            return;
        }
    }
    ice("Missing string.\n");
}

void backend_xdef(Ast *xdef)
{
    I i;
    I size;
    I array_size;

    if (xdef->kind != A_XDEF)
        ice("Expected XDEF node.");

    size = vector_size(xdef->xdef.initializer);
    if (xdef->xdef.size == -1) {
        /* scalar */
        if (size == 0) {
            printf("I %s;\n", backend_mangle(xdef->xdef.name, 0));
        } else if (size == 1) {
            printf("I %s = ", backend_mangle(xdef->xdef.name, 0));
            backend_initializer((Ast *)V_IDX(xdef->xdef.initializer, 0));
            printf(";\n");
        } else {
            ice("Unimplemented \"vector\" scalar.");
        }
    } else {
        /* array */
        array_size = size > xdef->xdef.size ? size : xdef->xdef.size;
        printf("I %s[%ld]", backend_mangle(xdef->xdef.name, 1), array_size);
        if (size > 0) {
            printf(" = { ");
            backend_initializer((Ast *)V_IDX(xdef->xdef.initializer, 0));
            for (i = 1; i < size; i++) {
                printf(", ");
                backend_initializer((Ast *)V_IDX(xdef->xdef.initializer, i));
            }
            printf(" }");
        }
        printf(";\n");

        printf("I %s;\n", backend_mangle(xdef->xdef.name, 0));
        printf("void __attribute__((constructor)) %s(void)\n",
               backend_mangle(xdef->xdef.name, 2));
        printf("{\n");
        printf("    %s = ", backend_mangle(xdef->xdef.name, 0));
        printf("PTOI(%s);\n", backend_mangle(xdef->xdef.name, 1));
        printf("}\n");
    }
}

void backend_initializer(Ast *n)
{
    switch (n->kind) {
    case A_NAME:
        ice("Initialization of external variables with addresses of other"
            "externals is not possible due to a loader deficiency.\n");
        break;
    case A_NUM:
        printf("%ld", n->num.num);
        break;
    case A_STR:
        ice("Initialization of external varible with string.");
        /* We need to initialize with the divided pointer. */
        break;
    default:
        ice("Unexpeted node kind.");
    }
}

static char *backend_mangle(Name name, I impl)
{
    static char s[32] = "B";
    char *p = s + 1;
    int i;
    int c;

    if (impl >= 2)
        *p++ = 'S';
    else if (impl >= 1)
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

static void backend_emit_string(I *inst)
{
    I x;
    I i;
    I string_num = vector_size(string_table) / 2;
    I len = inst[3];
    char *comma = "";
    char *s = (char *)inst[2];

    vector_push(&string_table, (I)inst);
    vector_push(&string_table, string_num);

    printf("    static I str%ld[] = { ", string_num);
    x = 0;
    for (i = 0; i < len; i++) {
        x |= (I)s[i] << (i % 8 * 8);
        if (i % 8 == 7) {
            printf("%s%ldl", comma, x);
            comma = ", ";
            x = 0;
        }
    }
    if (x % 8 != 7) {
        printf("%s%ldl", comma, x);
    }
    printf(" };\n");
}

static void backend_walk_strings(void)
{
    I i;
    I j;
    I size;
    I block_size;
    I *inst;
    Block *b;

    if (!string_table)
        string_table = vector_get();
    if (vector_size(string_table) != 0)
        ice("Unexpected strings in table.");

    block_size = vector_size(block_list);
    for (i = 0; i < block_size; i++) {
        b = (Block *)V_IDX(block_list, i);
        size = vector_size(b->instructions);
        for (j = 0; j < size; j+= 5) {
            inst = &V_IDX(b->instructions, j);
            if (inst[1] == I_STR)
                backend_emit_string(inst);
        }
    }
};

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

    backend_walk_strings();

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

    printf("    ARGCOUNT(%ld)\n", call_count(function));

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

    /* reset string table */
    vector_set_size(&string_table, 0);
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
    case 's':
        backend_show_string(inst);
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
        [I_STR] = "PTOI($2s);",
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

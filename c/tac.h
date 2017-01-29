#pragma once

#include "ast.h"

enum {
    /* Constants */
    I_NUM = 1, /* constant */
    I_STR, /* string, len */
    I_ARG, /* arg# */
    I_AUTO, /* name */
    I_EXTRN, /* name */
    I_BLOCK, /* block */

    /* Expressions */
    I_BIN, /* op, lhs, rhs */
    I_UNARY, /* op, value */
    I_COPY, /* value */

    /* Memory */
    I_LOAD, /* address */
    I_STORE, /* address, value */

    I_ASPACE, /* num */
    I_PARG, /* num, argbase, value */
    I_CALL, /* func, argbase */

    /* Terminators */
    I_J,  /* block */
    I_CJ, /* value -- computed jump */
    I_RET, /* value */
    I_IF, /* value, block, block */
    I_SWTCH /* value, table, block */
};

void tac_add(I dst, I instruction, I a1, I a2, I a3);
void tac_function(Ast *f);

extern I tac_temp_count;

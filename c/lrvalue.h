#pragma once

#include "ast.h"

/* lrvalue_pass()
 *
 * After lrvalue_pass is complete all A_IND, A_ADDR, and A_INDEX nodes will
 * be eliminated an A_LOAD nodes will have been inserted.
 */
extern void lrvalue_pass(Ast **program);

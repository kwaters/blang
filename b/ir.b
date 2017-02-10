/* vim: set ft=blang : */

/* SSA based intermediate representation. */

/* Instruction/Value types. */

/* Special */
I_UNDEF  1;  /* -- undefined value */
I_PHI    2;  /* (value, predecessor) ... -- PHI node */

/* Constants */
I_NUM    3;  /* num -- number */
I_STR    4;  /* str, len -- string */
I_ARG    5;  /* argNo -- address of an arguments */
I_AUTO   6;  /* name -- address of a local */
I_EXTRN  7;  /* name -- address of an extrn */
I_BLOCK  8;  /* block -- address of a block for CJ */

/* Expressions */
I_BIN    9;  /* op, lhs, rhs -- binary operation */
I_UNARY 10;  /* op, expr -- unary operation */
I_CALL  11;  /* f, arg ... -- function call */

/* Memory */
I_LOAD  12;  /* addr */
I_STORE 13;  /* addr, value */

/* Terminators.  All blocks end with exactly one terminator */
I_J     14;  /* block */
I_CJ    15;  /* value -- computed jump */
I_RET   16;  /* value */
I_IF    17;  /* value, blockNZ, blockZ -- jump if non-zero/zero */
I_SWTCH 18;  /* value, default, (const, block) ... */

/* Notes:
 * -  Void returns return UNDEF.
 *
 * Todo:
 * -  Does CJ need to list possible targets?
 */

/* Instruction layout
 *
 *  [0] Instruction kind
 *  [1] Pointer to parent block
 *  [2] Double-LL next instruction
 *  [3]           previous instruction
 *  [4] pointer to vector of uses
 *
 *  [5+] arguments
 *
 *  For variable length instructions [5] is a pointer to a vector.
 */

/* Replace an instruction with another */
iReplace(dst, src);

/* Create a new instruction */
iGet(kind, arg);

#pragma once

#include "vector.h"

typedef struct Block_ {
    I name;
    struct Vector *instructions;
} Block;

/* Create a new block. */
Block *block_get(void);

/* Release all blocks, and set the current block to a new empty block. */
void block_reset(void);

/* Split the current block.
 *
 * End the current block with an unconditional-branch to a new block, the new
 * block is returned.
 */
Block *block_split(void);

/* The current block. */
extern Block *block_current;
extern struct Vector *block_list;

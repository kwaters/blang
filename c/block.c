#include "block.h"

#include <stddef.h>
#include <stdlib.h>

#include "base.h"
#include "tac.h"

Block *block_current = NULL;
struct Vector *block_list = NULL;

static void block_release(Block *block);

Block *block_get(void)
{
    Block *block = malloc(sizeof(Block));
    vector_push(&block_list, (I)block);

    block->name = vector_size(block_list);
    block->instructions = vector_get();

    return block;
}

void block_release(Block *block)
{
    vector_release(block->instructions);
    free(block);
}

void block_reset(void)
{
    I i, size;

    if (block_list) {
        /* Clear the block list. */
        size = vector_size(block_list);
        for (i = 0; i < size; i++)
            block_release((Block *)V_IDX(block_list, i));
        vector_set_size(&block_list, 0);
    } else {
        block_list = vector_get();
    }

    /* Create a new empty block. */
    block_current = block_get();
}

Block *block_split(void)
{
    Block *block = block_get();
    tac_add(0, I_J, (I)block, 0, 0);
    block_current = block;
    return block;
}

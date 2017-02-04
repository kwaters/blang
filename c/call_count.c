#include "call_count.h"

#include "vector.h"

static I max_count;
static I current_count;
static void call_count_pre(Ast **n, void *d);
static void call_count_post(Ast **n, void *d);

I call_count(Ast *n)
{
    max_count = current_count = 0;
    ast_walk(&n, call_count_pre, call_count_post, NULL);
    if (current_count != 0)
        ice("Current call count should be 0.");
    return max_count;
}

void call_count_pre(Ast **n, void *data)
{
    if ((*n)->kind == A_CALL) {
        current_count += vector_size((*n)->call.arguments);
        if (current_count > max_count)
            max_count = current_count;
    }
}

void call_count_post(Ast **n, void *data)
{
    if ((*n)->kind == A_CALL)
        current_count -= vector_size((*n)->call.arguments);
}

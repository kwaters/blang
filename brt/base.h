#include <stdint.h>

typedef intptr_t I;
typedef I (*FN)(I *);
#define ITOP(i) ((I*)((i) << 3))
#define PTOI(p) (((I)(p)) >> 3)

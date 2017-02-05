AR := ar
BISON := bison
CC := clang
FLEX := flex
LD := clang

CFLAGS := -Wall -Wextra -Wno-unused-parameter -O0 -ggdb -std=c89 -I c -I $(SRC)/c

%.o: %.c
	$(CC) -MMD -o $@ -c $(CFLAGS) $<

%.c: %.b bc1
	./bc1 $< >$@ || \
	(rm -f $@; exit 1)

%.tab.c: %.y
	$(BISON) -o $@ -d -v $<

%.yy.c: %.l
	$(FLEX) -o $@ $<

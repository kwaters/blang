AR := ar
BISON := bison
CC := clang
FLEX := flex
LD := clang

CFLAGS := -Wall -Wextra -Wno-unused-parameter -O0 -ggdb -std=c89 -I c -I $(OUTPUT)/c

$(OUTPUT)/%.o: %.c
	$(CC) -MMD -o $@ -c $(CFLAGS) $<
$(OUTPUT)/%.o: $(OUTPUT)/%.c
	$(CC) -MMD -o $@ -c $(CFLAGS) $<

$(OUTPUT)/%.c: %.b $(OUTPUT)/bc1
	$(OUTPUT)/bc1 $< >$@

$(OUTPUT)/%.tab.c: %.y
	$(BISON) -o $@ -d -v $<

$(OUTPUT)/%.yy.c: %.l
	$(FLEX) -o $@ $<

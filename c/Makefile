CC := clang
LD := clang
FLEX := flex
BISON := bison

CFLAGS := -Wall -Wextra -Wno-unused-parameter -Os -ggdb -std=c89
LDFLAGS :=

PROGRAM := bc1
SOURCES := \
    ast.c \
    bc1.c \
    blang.tab.c \
    blang.yy.c \
    vector.c \
    lrvalue.c

OBJECTS := $(SOURCES:.c=.o)

.PHONY: all clean

all: $(PROGRAM)

clean:
	rm -f $(OBJECTS) blang.tab.c blang.tab.h blang.yy.c bc1 blang.output

$(PROGRAM): $(OBJECTS)
	clang -o $@ $(CFLAGS) $^

%.o: %.c
	$(CC) -o $@ -c $(CFLAGS) $<

%.tab.c: %.y
	$(BISON) -o $@ -d -v $<

%.yy.c: %.l
	$(FLEX) -o $@ $<

bc1.o: blang.tab.c


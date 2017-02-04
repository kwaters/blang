D := $(call get-D)

c-programs += bc1
bc1 :=
bc1 += $(D)ast.o
bc1 += $(D)backend.o
bc1 += $(D)bc1.o
bc1 += $(D)blang.tab.o
bc1 += $(D)blang.yy.o
bc1 += $(D)block.o
bc1 += $(D)call_count.o
bc1 += $(D)lrvalue.o
bc1 += $(D)nametable.o
bc1 += $(D)tac.o
bc1 += $(D)vector.o

# Yacc dependencies
$(D)blang.yy.c: $(D)blang.tab.c
$(D)bc1.o: $(D)blang.tab.c

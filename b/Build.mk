D := $(call get-D)

b-programs := blang1
blang1 :=
blang1 += $(D)blang1.o
blang1 += $(D)ibuffer.o
blang1 += $(D)lexer.o
blang1 += $(D)vector.o

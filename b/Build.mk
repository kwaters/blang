D := $(call get-D)

b-programs := blang1
blang1 :=
blang1 += $(D)ast.o
blang1 += $(D)blang1.o
blang1 += $(D)block.o
blang1 += $(D)ibuffer.o
blang1 += $(D)ir.o
blang1 += $(D)irgen.o
blang1 += $(D)lexer.o
blang1 += $(D)lrvalue.o
blang1 += $(D)nametabl.o
blang1 += $(D)obuffer.o
blang1 += $(D)parser.o
blang1 += $(D)string.o
blang1 += $(D)vector.o

D := $(call get-D)

b-programs += hello
hello :=
hello := $(D)hello.o

b-programs += num
num :=
num := $(D)num.o

b-programs += two_strings
two_strings += $(D)two_strings.o

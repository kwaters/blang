D := $(call get-D)

static-libs += brt
brt :=
brt += $(D)brtcore.o
brt += $(D)brtio.o
brt += $(D)brtmain.o
brt += $(D)print.o

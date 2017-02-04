.PHONY: all

.SECONDARY:

get-D = $(subst $(SRC)/,,$(dir $(lastword $(MAKEFILE_LIST))))

include $(SRC)/mk/rules.mk
include $(SRC)/Build.mk
include $(foreach dir,$(dirs),$(SRC)/$(dir)/Build.mk)

-include $(foreach target,$(c-programs),$(foreach src,$($(target)),$(src:.o=.d)))

VPATH += $(SRC)

define def-c-program =
all: $(1)
$(1): $($(1))
	$$(CC) -o $$@ $$(LDFLAGS) $$(CFLAGS) $$^
endef
$(foreach program,$(c-programs), \
    $(eval $(call def-c-program,$(program))))

define def-b-program =
all: $(1)
$(1): $($(1)) libbrt.a
	$$(CC) -o $$@ $$(LDFLAGS) $$(CFLAGS) $$^
endef
$(foreach program,$(b-programs), \
    $(eval $(call def-b-program,$(program))))

define def-static-lib
all: lib$(1).a
lib$(1).a: $($(1))
	rm -f $$@; \
	$$(AR) rcs $$@ $$^
endef
$(foreach lib,$(static-libs), \
    $(eval $(call def-static-lib,$(lib))))

$(foreach dir,$(dirs), \
    $(shell [[ -d $(dir) ]] || mkdir -p $(dir)))

.PHONY: all

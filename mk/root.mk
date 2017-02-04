.PHONY: all

OUTPUT := build

get-D = $(OUTPUT)/$(dir $(lastword $(MAKEFILE_LIST)))

include mk/rules.mk
include Build.mk
include $(foreach dir,$(dirs),$(dir)/Build.mk)

-include $(foreach target,$(c-programs),$(foreach src,$($(target)),$(src:.o=.d)))

vpath % $(OUTPUT)

define def-c-program =
all: $(OUTPUT)/$(1)
$(OUTPUT)/$(1): $($(1))
	$$(CC) -o $$@ $$(LDFLAGS) $$(CFLAGS) $$^
endef
$(foreach program,$(c-programs), \
    $(eval $(call def-c-program,$(program))))

define def-b-program =
all: $(OUTPUT)/$(1)
$(OUTPUT)/$(1): $($(1)) $$(OUTPUT)/libbrt.a
	$$(CC) -o $$@ $$(LDFLAGS) $$(CFLAGS) $$^
endef
$(foreach program,$(b-programs), \
    $(eval $(call def-b-program,$(program))))

define def-static-lib
all: $(OUTPUT)/lib$(1).a
$$(OUTPUT)/lib$(1).a: $($(1))
	rm -f $$@; \
	$$(AR) rcs $$@ $$^
endef
$(foreach lib,$(static-libs), \
    $(eval $(call def-static-lib,$(lib))))

$(foreach dir,$(dirs), \
    $(shell [[ -d $(OUTPUT)/$(dir) ]] || mkdir -p $(OUTPUT)/$(dir)))

.PHONY: all

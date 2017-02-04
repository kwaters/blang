MAKEFLAGS += -rR

export OUTPUT := build
export SRC := ..

.PHONY: main-make clean

main-make:
	@[[ -d $(OUTPUT) ]] || mkdir -p $(OUTPUT)
	@$(MAKE) -f $(SRC)/mk/root.mk -C $(OUTPUT) $(if $(MAKECMDGOALS),$(MAKECMDGOALS),all)

all: main-make
	@:

clean:
	rm -r $(OUTPUT)

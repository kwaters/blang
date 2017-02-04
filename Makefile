MAKEFLAGS += -rR --no-print-directory

.PHONY: main-make

%: main-make
	@:

main-make:
	@$(MAKE) -f mk/root.mk $(if $(MAKECMDGOALS),$(MAKECMDGOALS),all)

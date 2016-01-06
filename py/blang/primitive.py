#!/usr/bin/env python


import functools
import inspect
import sys


__all__ = ['register_prims']


def primitive(f):
    """Convience decorator for retrieving arguments from the vm data stack."""
    args, varargs, keywords, _ = inspect.getargspec(f)
    assert varargs is None
    assert keywords is None
    nargs = len(args) - 1
    assert nargs >= 0

    @functools.wraps(f)
    def inner(vm, p):
        args = vm.core[p:p + nargs]
        return f(vm, *args)

    return inner


@primitive
def exit(vm, retcode):
    vm.stop(retcode)


@primitive
def putchar(vm, c):
    if 0 <= c < 255:
        sys.stdout.write(chr(c))


def register_prims(vm):
    vm.add_prim('exit', exit)
    vm.add_prim('putc', putchar)

#!/usr/bin/env python

import collections


class Redeclaration(Exception):
    """Name redeclaration."""
    pass


Symbol = collections.namedtuple('Symbol', ['name', 'kind', 'addr'])


class SymbolTable(object):
    def __init__(self):
        self.symbols = {}
        self.auto_count = 0
        self.arg_count = 0

    def extrn(self, name):
        """Declare an extrn symbol."""
        if name in self.symbols:
            raise Redeclaration(name)
        self.symbols[name] = Symbol(name, 'extrn', None)

    def auto(self, name):
        """Decalre an auto variable."""
        if name in self.symbols:
            raise Redeclaration(name)
        self.auto_count += 1
        self.symbols[name] = Symbol(name, 'auto', -self.auto_count)

    def arg(self, name):
        """Declare an argument."""
        if name in self.symbols:
            raise Redeclaration(name)
        self.symbols[name] = Symbol(name, 'auto', self.arg_count + 2)
        self.arg_count += 1

    def label(self, name, addr):
        """Declare a label."""
        if name in self.symbols:
            # It is legal to use a label before declaring it.
            sym = self.symbols[name]
            if sym.addr is not None or sym.kind != 'label':
                raise Redeclaration(name)
        self.symbols[name] = Symbol(name, 'label', addr)

    def fetch(self, name, implicit_extrn=False):
        """Lookup a symbol.

        If implicit_extrn is True and this is the first fetch of this variable,
        declare it as an extrn.  Otherwise, it must be a label.
        """
        if name not in self.symbols:
            if implicit_extrn:
                self.extrn(name)
            else:
                self.label(name, None)
        return self.symbols[name]

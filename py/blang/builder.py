#!/usr/bin/env python

import numpy as np

from . import vm


__all__ = ['IBuilder']


_binop_symbols = {
    'mul': '*',
    'div': '/',
    'mod': '%',
    'add': '+',
    'sub': '-',
    'shl': '<<',
    'shr': '>>',
    'lt': '<',
    'lte': '<=',
    'gt': '>',
    'gte': '>=',
    'eq': '==',
    'neq': '!=',
    'and': '&',
    'xor': '^',
    'or': '|',
}


class IBuilderBase(object):
    """Auto-generated functions for IBuilder."""
    pass


class IBuilder(IBuilderBase):
    """Instruction builder.

    Includes functions for each instruction in both regular and immediate
    forms.

    Example:
        b = blang.builder.IBuilder()
        b.const_i(6)
        b.const_i(9)
        b.binop('*')
        b.const_i(42)
        b.binop('==')
    """
    def __init__(self):
        self._core = np.zeros(32, dtype=np.int32)
        self.ip = 0
        self._relocations = []
        self._extrns = {}

    _binop_subop = {
        _binop_symbols[binop.name]: subopcode
        for subopcode, binop in vm.binops.iteritems()
    }

    def __len__(self):
        return self.ip

    def __getitem__(self, addr):
        return self._core[addr]

    def __setitem__(self, addr, value):
        self._core[addr] = value

    def dw(self, x=0):
        """Emit a word.

        Returns the address of the word.
        """
        if self.ip >= len(self._core):
            self._core = np.hstack((self._core,
                                   np.zeros(len(self._core), dtype=np.int32)))
        r = self.ip
        self._core[self.ip] = x
        self.ip += 1
        return r

    def data(self, length):
        """Reserve space for a vector.

        Returns the address of the vector.
        """
        assert False, "Broken"
        r = self.ip
        self.ip += length
        return r

    def core(self):
        """Return a trimed core image."""
        return self._core[:self.ip]

    def define_extrn(self, name):
        """Define an extern at the current ip."""
        self._extrns[name] = self.ip

    def relocation(self, name, addr):
        """Add the value of "name" to core[addr] as link time."""
        self._relocations.append((name, addr))

    def link(self):
        for name, addr in self._relocations:
            self[addr] += self._extrns[name]

    # Override with symbolic sub-op names.
    def binop(self, op):
        return IBuilderBase.binop(self, self._binop_subop[op])
    def binop_i(self, op, imm=0):
        return IBuilderBase.binop_i(self, self._binop_subop[op], imm)


def _mk_inst(instruction):
    """Generate a member function for an instruction."""
    opcode = instruction.opcode
    def _inst(self):
        self.dw(opcode)
    return _inst


def _mk_inst_i(instruction):
    """Generate a member function for a .i instruction."""
    opcode = instruction.opcode | vm.VM.I_MASK
    def _inst_i(self, imm=0):
        self.dw(opcode)
        return self.dw(imm)
    return _inst_i


def _mk_inst_subop(instruction):
    """Generate a member function for an instruction with a sub-opcde."""
    opcode = instruction.opcode
    def _inst_subop(self, subop):
        self.dw(opcode | (subop << vm.VM.SUBOP_SHIFT))
    return _inst_subop


def _mk_inst_subop_i(instruction):
    """Generate a member function for a .i instruction with a sub-opcde."""
    opcode = instruction.opcode | vm.VM.I_MASK
    def _inst_subop_i(self, subop, imm=0):
        self.dw(opcode | (subop << vm.VM.SUBOP_SHIFT))
        return self.dw(imm)
    return _inst_subop_i


def _add_instructions(cls):
    """Add member functions for each instruction."""
    for instruction in vm.VM.instructions:
        if instruction.has_subop:
            setattr(cls, instruction.mnemonic, _mk_inst_subop(instruction))
            setattr(cls, instruction.mnemonic + '_i',
                    _mk_inst_subop_i(instruction))
        else:
            setattr(cls, instruction.mnemonic, _mk_inst(instruction))
            setattr(cls, instruction.mnemonic + '_i', _mk_inst_i(instruction))


_add_instructions(IBuilderBase)

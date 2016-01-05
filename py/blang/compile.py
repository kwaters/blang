#!/usr/bin/env python

import array
import collections

from . import vm
from . import ast
from .vm import VM

class Builder(object):
    """Helper for assembling functions."""
    def __init__(self):
        self.core = []

    def append(self, x):
        """Emit x."""
        self.core.append(x)

    def ref(self):
        """Return a reference to the last emitted word."""
        return len(self.core)

    def dw(self, x=0):
        """Add a data word."""
        r = self.ref()
        self.append(x)
        return r

    def patch(self, where, ref, rel=False):
        if rel:
            # TODO: Terrible hack, doesn't work for goto
            ref = ref - where - 1
        self.core[where] = ref

    @staticmethod
    def _mk_opcode_subop(instruction):
        opcode = instruction.opcode
        def _opcode_subop(self, subop):
            self.append(opcode | (subop << VM.SUBOP_SHIFT))
        return _opcode_subop

    @staticmethod
    def _mk_opcode_subop_i(instruction):
        opcode = instruction.opcode | VM.I_MASK
        def _opcode_subop_i(self, subop, imm=0):
            self.append(opcode | (subop << VM.SUBOP_SHIFT))
            r = self.ref()
            self.append(imm)
            return r
        return _opcode_subop_i

    @staticmethod
    def _mk_opcode(instruction):
        opcode = instruction.opcode
        def _opcode(self):
            self.append(opcode)
        return _opcode

    @staticmethod
    def _mk_opcode_i(instruction):
        opcode = instruction.opcode | VM.I_MASK
        def _opcode_i(self, imm=0):
            self.append(opcode)
            r = self.ref()
            self.append(imm)
            return r
        return _opcode_i

    @classmethod
    def _add_instructions(cls):
        """Add member functions for each instruction."""
        for instruction in VM.instructions:
            if instruction.has_subop:
                setattr(cls, instruction.mnemonic,
                        cls._mk_opcode_subop(instruction))
                setattr(cls, instruction.mnemonic + '_i',
                        cls._mk_opcode_subop_i(instruction))
            else:
                setattr(cls, instruction.mnemonic, cls._mk_opcode(instruction))
                setattr(cls, instruction.mnemonic + '_i',
                        cls._mk_opcode_i(instruction))


Builder._add_instructions()

Symbol = collections.namedtuple('Symbol', ['name', 'kind', 'addr'])

class SymbolTable(object):
    def __init__(self):
        self.clear()

    def clear(self):
        self.symbols = {}
        self.auto_count = 0

    def add_extrn(self, name):
        assert name not in self.symbols, "TODO: ???"
        self.symbols[name] = Symbol(name, 'extrn', 0)

    def add_args(self, args):
        for addr, arg in enumerate(args, start=2):
            self.symbols[arg] = Symbol(arg, 'local', addr)

    def add_auto(self, name):
        # TODO: Error
        assert name not in self.symbols
        self.auto_count += 1
        sym = Symbol(name, 'local', -self.auto_count)
        self.symbols[name] = sym
        return sym.addr

    def add_label(self, name, ref):
        if name in self.symbols:
            # TODO: Error
            assert self.symbols[name].kind == 'label'
            assert self.symbols[name].addr == 0
        self.symbols[name] = Symbol(name, 'label', ref)

    def fetch(self, name, implicit_extrn=False):
        if name not in self.symbols:
            s = Symbol(name, 'extrn' if implicit_extrn else 'label', 0)
            self.symbols[name] = s
            return s
        return self.symbols[name]


class Compiler(object):
    _binop_names = {
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

    def __init__(self):
        self.b = Builder()
        self.symtab = SymbolTable()
        self.linker = Linker()
        self.cstring = CString()

        self._binop_table = {}
        for subopcode, binop in vm.binops.iteritems():
            self._binop_table[self._binop_names[binop.name]] = subopcode

    def visit(self, b, node):
        m = getattr(self, 'visit_' + node.__class__.__name__)
        m(b, node)

    def visit_BinOp(self, b, binop):
        self.visit(b, binop.lhs)
        self.visit(b, binop.rhs)
        b.binop(self._binop_table[binop.op])

    def visit_Assign(self, b, assign):
        self.visit(b, assign.lhs)
        if assign.op == '':
            self.visit(b, assign.rhs)
        else:
            b.dup()
            b.load()
            self.visit(b, assign.rhs)
            b.binop(self._binop_table[assign.op])
        b.dup_x1()
        b.store()

    def visit_Load(self, b, load):
        self.visit(b, load.child)
        b.load()

    def visit_Inc(self, b, inc):
        amt = 1 if inc.op == '++' else -1
        self.visit(b, inc.child)
        b.dup()
        b.load()
        if inc.post:
            b.dup_x1()
            b.binop_i(self._binop_table['+'], amt)
        else:
            b.binop_i(self._binop_table['+'], amt)
            b.dup_x1()
        b.store()

    def visit_Call(self, b, call):
        self.visit(b, call.method)
        for arg in call.args:
            self.visit(b, arg)
        b.call(len(call.args))

    def visit_Name(self, b, name):
        # TODO: error on missing varaible ?!
        sym = self.symtab.fetch(name.name, name.implicit_extrn)
        if sym.kind == 'local':
            b.local_i(sym.addr)
        elif sym.kind == 'extrn':
            self.linker.add_fixup(name.name, b.const_i())
        elif sym.kind == 'label':
            self.patch_labels.append((name.name, b.const_i()))
        else:
            assert False

    def visit_UnaryOp(self, b, unaryop):
        if unaryop.op == '-':
            b.const_i(0)
            self.visit(b, unaryop.child)
            b.binop(self._binop_table['-'])
        elif unaryop.op == '!':
            self.visit(b, unaryop.child)
            b.const_i(0)
            b.binop(self._binop_table['=='])
        elif unaryop.op == '~':
            self.visit(b, unaryop.child)
            b.const_i(-1)
            b.binop(self._binop_table['^'])
        else:
            assert False

    def visit_TernaryOp(self, b, op):
        self.visit(b, op.cond)
        r_false_branch = b.jez_i()
        self.visit(b, op.iftrue)
        r_exit_branch = b.jmp_i()
        r_false = b.ref()
        self.visit(b, op.iffalse)
        r_exit = b.ref()

        b.patch(r_false_branch, r_false, rel=True)
        b.patch(r_exit_branch, r_exit, rel=True)

    def visit_Variable(self, b, var):
        assert var.auto
        offset = self.symtab.add_auto(var.name)
        if var.size >= 0:
            # Allocate the array on the stack, and write it's address into the
            # variable.
            b.local_i(offset)
            # TODO: Size of array
            b.alloca_i(var.size)
            b.store()

    def visit_Number(self, b, num):
        b.const_i(num.num)

    def visit_String(self, b, string):
        r = b.const_i()
        self.cstring.add(string.value, r)

    def visit_Definition(self, b, definition):
        assert False, "TODO: Not Implemented."

    def visit_Function(self, b, func):
        self.symtab.clear()
        # TODO: Document.  Unclear if the function name is automatically
        # in-scope.
        self.symtab.add_extrn(func.name)
        self.symtab.add_args(func.args)

        self.case_labels = []
        self.patch_labels = []
        self.declarations_done = False

        r_func_lvalue = b.dw()
        self.linker.define(func.name, r_func_lvalue)
        b.patch(r_func_lvalue, b.ref())

        r_alloca = b.alloca_i()
        b.pop()

        self.visit(b, func.body)
        b.ret_i(0)

        # Patch-up local alloc
        b.patch(r_alloca, self.symtab.auto_count)

        # Patch-up GOTOs
        for label in self.patch_labels:
            sym = self.symtab.fetch(label[0])
            b.patch(label[1], sym.addr, rel=True)

        print self.symtab.symbols

    def visit_Stmt(self, b, stmt):
        for case in stmt.cases:
            self.case_labels.append((case, b.ref()))
        for label in stmt.labels:
            self.symtab.add_label(label, b.ref())
        # TODO: This auto stuff is all wrong.
        self.declarations_done = True

    def visit_IfStmt(self, b, if_):
        self.visit_Stmt(b, if_)
        self.visit(b, if_.cond)
        r_false_branch = b.jez_i()
        self.visit(b, if_.iftrue)
        if if_.iffalse is not None:
            r_exit_branch = b.jmp_i()
            r_false = b.ref()
            self.visit(b, if_.iffalse)
            r_exit = b.ref()
            b.patch(r_exit_branch, r_exit, rel=True)
        else:
            r_false = b.ref()
        b.patch(r_false_branch, r_false, rel=True)

    def visit_ReturnStmt(self, b, return_):
        self.visit_Stmt(b, return_)
        if return_.value is None:
            b.ret_i(0)
        else:
            self.visit(b, return_.value)
            b.ret()

    def visit_CompoundStmt(self, b, compound):
        # TODO: "foo: { bar; }" is totally legal but shouldn't count as a
        # declaration.
        # self.visit_Stmt(b, compound)
        for stmt in compound.statements:
            self.visit(b, stmt)

    def visit_NullStmt(self, b, null):
        self.visit_Stmt(b, null)

    def visit_ExprStmt(self, b, expr):
        self.visit_Stmt(b, expr)
        self.visit(b, expr.expr)
        b.pop()

    def visit_WhileStmt(self, b, while_):
        self.visit_Stmt(b, while_)
        r_top = b.ref()
        self.visit(b, while_.cond)
        r_exit_branch = b.jez_i()
        self.visit(b, while_.body)
        r_top_branch = b.jmp_i()
        r_exit = b.ref()

        b.patch(r_exit_branch, r_exit, rel=True)
        b.patch(r_top_branch, r_top, rel=True)

    def visit_VariableStmt(self, b, var):
        # TODO: What should happen? better error reporting
        assert not var.labels and not var.cases, (
            "Jumping back to variable declarations is absurd.")

        # TODO: better error reporting
        assert not self.declarations_done, "Decl after non-decl."

        if var.extrn:
            for variable in var.variables:
                self.symtab.add_extrn(variable)
        else:
            for variable in var.variables:
                self.visit(b, variable)

    def visit_GotoStmt(self, b, goto):
        self.visit_Stmt(b, goto)

        # TODO: This is really nasty, goto can be called with almost anything,
        # and our rvalue/lvalue stuff gets confused.
        if isinstance(goto.target, ast.Load):
            self.visit(b, goto.target.child)
        else:
            self.visit(b, goto.target)
        b.binop_i(self._binop_table['-'], 3)
        b.jmp()

    def visit_SwitchStmt(self, b, switch):
        self.visit_Stmt(b, switch)

        # We put the tests below the body, so we can emit in one pass with only
        # simple fixups.
        r_switch_branch = b.jmp_i()

        self.case_labels = []
        self.visit(b, switch.body)
        r_exit_branch = b.jmp_i()

        # Unroll into an if-else chain
        r_switch = b.ref()
        self.visit(b, switch.expr)
        for case in self.case_labels:
            b.dup()
            b.const_i(case[0])
            b.binop(self._binop_table['=='])
            b.jez_i(3)
            b.pop()
            r = b.jmp_i()
            b.patch(r, case[1], rel=True)

        b.pop()
        r_exit = b.ref()

        b.patch(r_switch_branch, r_switch, rel=True)
        b.patch(r_exit_branch, r_exit, rel=True)


class Linker(object):
    def __init__(self):
        self._locs = {}
        self._fixups = []
        pass

    def define(self, name, addr):
        assert name not in self._locs
        self._locs[name] = addr

    def add_fixup(self, name, place):
        self._fixups.append((name, place))

    def link(self, b):
        for name, place in self._fixups:
            if name not in self._locs:
                print 'WARN: Undefined {!r}.'.format(name)
            b.patch(place, self._locs[name])


class CString(object):
    def __init__(self):
        self._strings = []

    def add(self, s, ref):
        self._strings.append((s, ref))

    def build(self, b):
        for s, ref in self._strings:
            s += '\x04\0\0\0'
            a = array.array('i')
            a.fromstring(s[:len(s) // 4 * 4])
            r = b.ref()
            for v in a:
                b.dw(v)
            b.patch(ref, r)

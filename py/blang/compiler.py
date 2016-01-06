#!/usr/bin/env python

import collections

from . import ast
from . import builder
from . import util


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
        addr = -self.auto_count
        self.symbols[name] = Symbol(name, 'auto', addr)
        return addr

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


Label = collections.namedtuple('Label', ['name', 'addr'])
CaseLabel = collections.namedtuple('CaseLabel', ['value', 'addr'])
String = collections.namedtuple('String', ['s', 'addr'])


class UndefLabel(Exception):
    pass


class Compiler(ast.AstVisitor):
    def __init__(self):
        self.builder = builder.IBuilder()

    # Top-level
    def visit_Definition(self, definition, b):
        assert False, "Not Implemented."

    def visit_Function(self, function, b):
        self.symtab = SymbolTable()
        self.case_labels = []
        self.label_uses = []
        self.strings = []

        b.define_extrn(function.name)

        # The symbol for the function is in scope in the function, event
        # without implicit extrns.  See the definition of printn() in section
        # 9.1.
        self.symtab.extrn(function.name)

        for arg in function.args:
            self.symtab.arg(arg)

        # The "rvalue" for a function is the address of the first instruction.
        # In Section 3, "(b ? f : g[i])(1, x > 1)" is given as an example.
        # Implying that function names are actually function pointers.
        b.dw(b.ip + 1)

        # Reserve space on the stack for the locals.  The number of locals,
        # isn't known until after the function has been compiled.
        auto_alloca = b.alloca_i()
        b.pop()

        # Function body
        self.visit(function.body, b)

        # Add explicit "return;" at the end of the function.
        b.ret_i(0)

        # Strings
        for string in self.strings:
            addr = b.ip
            for c in util.pack_string(string.s):
                b.dw(c)
            # TODO: If the builder is relocated this needs to be as well
            b[string.addr] = addr

        # Patches
        b[auto_alloca] = self.symtab.auto_count
        for label in self.label_uses:
            sym = self.symtab.fetch(label.name)
            # TODO: If the builder is relocated this needs to be as well
            if sym.addr is None:
                raise UndefLabel(label.name)
            b[label.addr] = sym.addr

    # Statements
    def handle_labels(self, stmt, b):
        for case in stmt.cases:
            self.case_labels.append(CaseLabel(case, self.ip))
        for label in stmt.labels:
            self.symtab.label(label, self.ip)

    def visit_IfStmt(self, if_, b):
        self.handle_labels(if_, b)
        self.visit(if_.cond, b)
        false_branch = b.jez_i()
        self.visit(if_.iftrue, b)

        if if_.iffalse is not None:
            exit_branch = b.jmp_i()
            false_target = b.ip
            self.visit(if_.iffalse, b)
            b[exit_branch] = sym.ip - exit_branch - 1
        else:
            false_target = b.ip

        b[false_branch] = false_target - false_branch - 1

    def visit_ReturnStmt(self, return_, b):
        self.handle_labels(return_, b)
        if return_.value is not None:
            self.visit(return_.value, b)
            b.ret()
        else:
            # A function call is an rvalue.  The return value for functions not
            # returning a value is not to be used.
            b.ret_i(0)

    def visit_CompoundStmt(self, compound, b):
        self.handle_labels(compound, b)
        for stmt in compound.statements:
            self.visit(stmt, b)

    def visit_NullStmt(self, null, b):
        self.handle_labels(null, b)

    def visit_ExprStmt(self, expr, b):
        self.handle_labels(expr, b)
        self.visit(expr.expr, b)
        b.pop()

    def visit_WhileStmt(self, while_, b):
        self.handle_labels(while_, b)
        top_target = b.ip
        self.visit(while_.cond, b)
        exit_branch = b.jez_i()
        self.visit(while_.body, b)
        top_branch = b.jmp_i()
        exit_target = b.ip

        b[exit_branch] = exit_target - exit_branch - 1
        b[top_branch] = top_target - top_branch - 1

    def visit_VariableStmt(self, variable, b):
        # Jumping across a variable statement appears to be legal.  In this
        # implementation jumping across a normal declaration has no effect, but
        # jumping across a vector declaration causes it to be reallocated.
        #
        # I believe this behavior is a bug.
        #
        # TODO: Fix jumping across vector.
        self.handle_labels(variable, b)
        for v in variable.variables:
            self.visit(v, b)

    def visit_Variable(self, variable, b):
        if variable.auto:
            addr = self.symtab.auto(variable.name)
            if variable.size >= 0:
                # Allocate the array on the stack, and write it's address into
                # the variable.
                b.local_i(addr)
                b.alloca_i(variable.size)
                b.store()
        else:
            self.symtab.extrn(variable.name)

    def visit_GotoStmt(self, goto, b):
        self.handle_labels(goto, b)
        self.visit(goto.target, b)

        # TODO: jmp is relative, but labels are easier to deal with if they're
        # absolute.  We do the math inline.
        # TODO: If the builder is relocated this needs to be as well
        b.binop_i('-', b.ip - 3)
        b.jmp()

    def visit_SwitchStmt(self, switch, b):
        self.handle_labels(switch, b)

        # We put the tests after the body, so we can emit in one pass with only
        # simple fixups.
        switch_branch = b.jmp_i()

        # Body
        self.case_labels = []
        self.visit(switch.body, b)
        exit_branch = b.jmp_i()

        # Unroll into an if-else chain
        switch_target = b.ip
        self.visit(b, switch.expr)

        for case in self.case_labels:
            b.dup()
            b.binop_i('==', case.value)
            b.jez_i(3)
            b.pop()
            b.jmp_i(case.addr - b.ip - 2)
        b.pop()
        exit_target = b.ip

        b[switch_branch] = switch_target - switch_branch - 1
        b[exit_branch] = exit_target - exit_branch - 1

    # Expressions
    def visit_BinOp(self, binop, b):
        self.visit(binop.lhs, b)
        self.visit(binop.rhs, b)
        b.binop(binop.op)

    def visit_Assign(self, assign, b):
        self.visit(assign.lhs, b)
        if assign.op:
            b.dup()
            b.load()
            self.visit(assign.rhs, b)
            b.binop(assign.op)
        else:
            self.visit(assign.rhs, b)
        b.dup_x1()
        b.store()

    def visit_Load(self, load, b):
        self.visit(load.child, b)
        if isinstance(load.child, ast.Name):
            # Labels don't have actual lvalues, but because the grammar is
            # context free we don't know that if a "name" is a label until now
            # and so we emitted a load when it was converted to an rvalue.  We
            # will omit that load here.
            #
            # Trying to take the address of a label, or assigning to one will
            # cause havok.
            if self.symtab.fetch(load.child.name).kind == 'label':
                return
        b.load()

    def visit_Inc(self, inc, b):
        self.visit(inc.child, b)
        amt = 1 if inc.op == '++' else -1
        b.dup()
        b.load()
        if inc.post:
            b.dup_x1()
            b.binop_i('+', amt)
        else:
            b.binop_i('+', amt)
            b.dup_x1()
        b.store()

    def visit_Call(self, call, b):
        self.visit(call.method, b)
        for arg in call.args:
            self.visit(arg, b)
        b.call(len(call.args))

    def visit_Name(self, name, b):
        sym = self.symtab.fetch(name.name, name.implicit_extrn)
        if sym.kind == 'auto':
            b.local_i(sym.addr)
        elif sym.kind == 'extrn':
            b.relocation(name.name, b.const_i())
        elif sym.kind == 'label':
            self.label_uses.append(Label(name.name, b.const_i()))
        else:
            assert False

    def visit_UnaryOp(self, unaryop, b):
        if unaryop.op == '-':
            b.const_i(0)
            self.visit(unaryop.child, b)
            b.binop('-')
        elif unaryop.op == '!':
            self.visit(unaryop.child, b)
            b.binop_i('==', 0)
        elif unaryop.op == '~':
            self.visit(unaryop.child, b)
            b.binop_i('^', -1)
        else:
            assert False

    def visit_TernaryOp(self, ternaryop, b):
        self.visit(op.cond, b)
        false_branch = b.jez_i()
        self.visit(op.iftrue, b)
        exit_branch = b.jmp_i()
        false_target = b.ip
        self.visit(op.iffalse, b)
        exit_target = b.ip

        b[false_branch] = false_target - false_branch - 1
        b[exit_branch] = exit_target - exit_branch - 1

    def visit_Number(self, number, b):
        b.const_i(number.num)

    def visit_String(self, string, b):
        # Strings are '*e' terminated.
        self.strings.append(String(string.value + '\x04', b.const_i()))

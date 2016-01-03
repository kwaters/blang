#!/usr/bin/env python

import collections
import sys


class Node(object):
    """Generic AST node."""
    __slots__ = []

    def show(self, indent=0, out=sys.stdout):
        """Dump a debug representation of this AST node.

        Uses _name and _show_fields of the node if they're available.
        """
        if hasattr(self, '_name'):
            name = self._name
        else:
            name = self.__class__.__name__ + '()'

        out.write(indent * '  ')
        print >>out, name.format(self)

        # Iterate children.  For children that are lists, iterate those lists
        # as well.
        for field in getattr(self, '_show_fields', []):
            v = getattr(self, field)
            if isinstance(v, collections.Iterable):
                for x in v:
                    x.show(indent + 1, out)
            elif v is not None:
                v.show(indent + 1, out)


class BinOp(Node):
    __slots__ = ['op', 'lhs', 'rhs']

    _name = 'BinOp({0.op!r})'
    _show_fields = ['lhs', 'rhs']

    def __init__(self, op, lhs, rhs):
        super(BinOp, self).__init__()
        self.op = op
        self.lhs = lhs
        self.rhs = rhs


class Assign(Node):
    __slots__ = ['op', 'lhs', 'rhs']

    _name = 'Assign({0.op!r})'
    _show_fields = ['lhs', 'rhs']

    def __init__(self, op, lhs, rhs):
        super(Assign, self).__init__()
        self.op = op
        self.lhs = lhs
        self.rhs = rhs


class Load(Node):
    __slots__ = ['child']

    _show_fields = ['child']

    def __init__(self, child):
        super(Load, self).__init__()
        self.child = child


class Inc(Node):
    __slots__ = ['op', 'post', 'child']

    _name = 'Inc({0.op!r}, {0.post!r})'
    _show_fields = ['child']

    def __init__(self, op, post, child):
        super(Inc, self).__init__()
        self.op = op
        self.post = post
        self.child = child


class Call(Node):
    __slots__ = ['method', 'args']

    _show_fields = ['method', 'args']

    def __init__(self, method, args):
        super(Call, self).__init__()
        self.method = method
        self.args = args


class Name(Node):
    __slots__ = ['name', 'implicit_extrn']

    _name = 'Name({0.name!r}, {0.implicit_extrn!r})'

    def __init__(self, name, implicit_extrn):
        super(Name, self).__init__()
        self.name = name
        self.implicit_extrn = implicit_extrn


class UnaryOp(Node):
    __slots__ = ['op', 'child']

    _name = 'UnaryOp({0.op!r})'
    _show_fields = ['child']

    def __init__(self, op, child):
        super(UnaryOp, self).__init__()
        self.op = op
        self.child = child


class TernaryOp(Node):
    __slots__ = ['cond', 'iftrue', 'iffalse']

    _show_fields = ['cond', 'iftrue', 'iffalse']

    def __init__(self, cond, iftrue, iffalse):
        super(TernaryOp, self).__init__()
        self.cond = cond
        self.iftrue = iftrue
        self.iffalse = iffalse


class Variable(Node):
    __slots__ = ['name', 'auto', 'size']

    _name = 'Variable({0.name!r}, {0.auto!r}, {0.size!r})'

    def __init__(self, name, auto, size=-1):
        super(Variable, self).__init__()
        self.name = name
        self.auto = auto
        self.size = size


class Number(Node):
    __slots__ = ['num']

    _name = 'Number(0x{0.num:x})'

    def __init__(self, num):
        super(Number, self).__init__()
        self.num = num


class String(Node):
    __slots__ = ['value']

    _name = 'String({0.value!r})'

    def __init__(self, value):
        super(String, self).__init__()
        self.value = value


class Definition(Node):
    __slots__ = ['name', 'init', 'size']

    _name = 'Definition({0.name!r}, {0.size!r})'
    _show_fields = ['init']

    def __init__(self, name, init, size=-1):
        super(Definition, self).__init__()
        self.name = name
        self.init = init
        self.size = size


class Function(Node):
    __slots__ = ['name', 'args', 'body']

    _name = 'Function({0.name!r}, {0.args!r})'
    _show_fields = ['body']

    def __init__(self, name, args, body):
        super(Function, self).__init__()
        self.name = name
        self.args = args
        self.body = body


class Stmt(Node):
    __slots__ = ['labels', 'cases']

    def __init__(self):
        super(Stmt, self).__init__()
        self.labels = []
        self.cases = []

    def attach_label(self, label):
        self.labels.append(label)

    def attach_case(self, case):
        self.cases.append(case)


class IfStmt(Stmt):
    __slots__ = ['cond', 'iftrue', 'iffalse']

    _show_fields = ['cond', 'iftrue', 'iffalse']

    def __init__(self, cond, iftrue, iffalse=None):
        super(IfStmt, self).__init__()
        self.cond = cond
        self.iftrue = iftrue
        self.iffalse = iffalse


class ReturnStmt(Stmt):
    __slots__ = ['value']

    _show_fields = ['value']

    def __init__(self, value=None):
        super(ReturnStmt, self).__init__()
        self.value = value


class CompoundStmt(Stmt):
    __slots__ = ['statements']

    _show_fields = ['statements']

    def __init__(self, statements):
        super(CompoundStmt, self).__init__()
        self.statements = statements


class NullStmt(Stmt):
    __slots__ = []

    def __init__(self, ):
        super(NullStmt, self).__init__()


class ExprStmt(Stmt):
    __slots__ = ['expr']

    _show_fields = ['expr']

    def __init__(self, expr):
        super(ExprStmt, self).__init__()
        self.expr = expr


class WhileStmt(Stmt):
    __slots__ = ['cond', 'body']

    _show_fields = ['cond', 'body']

    def __init__(self, cond, body):
        super(WhileStmt, self).__init__()
        self.cond = cond
        self.body = body


class VariableStmt(Stmt):
    __slots__ = ['extrn', 'variables']

    _name = 'VariableStmt({0.extrn!r})'
    _show_fields = ['variables']

    def __init__(self, extrn, variables):
        super(VariableStmt, self).__init__()
        self.extrn = extrn
        self.variables = variables


class GotoStmt(Stmt):
    __slots__ = ['target']

    _show_fields = ['target']

    def __init__(self, target):
        super(GotoStmt, self).__init__()
        self.target = target


class SwitchStmt(Stmt):
    __slots__ = ['expr', 'body']

    _show_fields = ['expr', 'body']

    def __init__(self, expr, body):
        super(SwitchStmt, self).__init__()
        self.expr = expr
        self.body = body

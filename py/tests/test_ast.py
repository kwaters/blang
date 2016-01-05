import unittest

from blang import ast


class TestVisitor1(ast.AstVisitor):
    pass


class TestVisitor2(ast.AstVisitor):
    def visit_Stmt(self, node, x):
        return 'stmt', x


class TestVisitor3(TestVisitor2):
    def visit_GotoStmt(self, node, x):
        return 'gotoStmt', x


class TestAstVisitor(unittest.TestCase):
    def test_unhandled(self):
        goto = ast.GotoStmt(ast.NullStmt())
        v = TestVisitor1()
        with self.assertRaises(AssertionError):
            v.visit(goto, 1)

    def test_incorrect_type(self):
        v = TestVisitor1()
        with self.assertRaises(AssertionError):
            v.visit(0, 1)

    def test_upcast(self):
        goto = ast.GotoStmt(None)
        v = TestVisitor2()
        self.assertEquals(v.visit(goto, 1), ('stmt', 1))

    def test_normal(self):
        goto = ast.GotoStmt(ast.NullStmt())
        v = TestVisitor3()
        self.assertEquals(v.visit(goto, 1), ('gotoStmt', 1))

        if_ = ast.IfStmt(ast.Number(0), ast.NullStmt())
        self.assertEquals(v.visit(if_, 2), ('stmt', 2))

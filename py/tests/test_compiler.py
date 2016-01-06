import unittest

from blang.compiler import SymbolTable, Symbol, Redeclaration

class TestSymbolTable(unittest.TestCase):

    def test_implicit_label(self):
        st = SymbolTable()
        st.fetch('x')
        self.assertEquals(st.fetch('x').kind, 'label')
        self.assertEquals(st.auto_count, 0)

    def test_implicit_extrn(self):
        st = SymbolTable()
        st.fetch('x', True)
        self.assertEquals(st.fetch('x').kind, 'extrn')
        self.assertEquals(st.auto_count, 0)

    def test_label(self):
        st = SymbolTable()
        st.fetch('x')
        st.label('x', 7)

        sym = st.fetch('x')
        self.assertEquals(sym.kind, 'label')
        self.assertEquals(sym.addr, 7)
        self.assertEquals(st.auto_count, 0)

    def test_auto(self):
        st = SymbolTable()
        st.auto('x')
        st.auto('y')

        self.assertEquals(st.fetch('x'), Symbol('x', 'auto', -1))
        self.assertEquals(st.fetch('y'), Symbol('y', 'auto', -2))
        self.assertEquals(st.auto_count, 2)

    def test_arg(self):
        st = SymbolTable()
        st.arg('a')
        st.arg('b')

        self.assertEquals(st.fetch('a'), Symbol('a', 'auto', 2))
        self.assertEquals(st.fetch('b'), Symbol('b', 'auto', 3))
        self.assertEquals(st.auto_count, 0)

    def test_redeclaration(self):
        st = SymbolTable()
        st.auto('x')

        with self.assertRaises(Redeclaration):
            st.auto('x')
        with self.assertRaises(Redeclaration):
            st.arg('x')
        with self.assertRaises(Redeclaration):
            st.label('x', 7)
        with self.assertRaises(Redeclaration):
            st.extrn('x')

    def test_label_redeclaration(self):
        st = SymbolTable()
        st.auto('x')
        st.extrn('y')
        st.arg('z')

        # Cannot use a variable as a label and then declare it as a different
        # type.
        with self.assertRaises(Redeclaration):
            st.label('x', 7)
        with self.assertRaises(Redeclaration):
            st.label('y', 8)
        with self.assertRaises(Redeclaration):
            st.label('z', 9)

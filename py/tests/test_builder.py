import unittest

from blang import vm
from blang.builder import IBuilder


class TestIBuilder(unittest.TestCase):

    def test_len(self):
        b = IBuilder()

        # Test len across growth
        for i in xrange(128):
            self.assertEquals(len(b), i)
            b.dw()

    def test_data(self):
        b = IBuilder()
        b.dw()

        for i in xrange(1, 128, 12):
            self.assertEquals(b.data(12), i)

    def test_inst(self):
        b = IBuilder()
        b.jmp()

        self.assertEquals(len(b), 1)
        self.assertEquals(b[0], vm.jmp.opcode)

    def test_inst_i(self):
        b = IBuilder()
        ret = b.jmp_i(42)

        self.assertEquals(len(b), 2)
        self.assertEquals(ret, 1)
        self.assertEquals(b[0], vm.jmp.opcode | vm.VM.I_MASK)
        self.assertEquals(b[1], 42)

    def test_binop(self):
        self.assertEquals(vm.binops[0x3].name, 'add')

        b = IBuilder()
        b.binop('+')

        self.assertEquals(len(b), 1)
        self.assertEquals(b[0], vm.binop.opcode | (3 << vm.VM.SUBOP_SHIFT))

    def test_binop_i(self):
        self.assertEquals(vm.binops[0x3].name, 'add')

        b = IBuilder()
        b.binop_i('+', 7)

        self.assertEquals(len(b), 2)
        self.assertEquals(b[0], vm.binop.opcode | vm.VM.I_MASK |
                                (3 << vm.VM.SUBOP_SHIFT))
        self.assertEquals(b[1], 7)

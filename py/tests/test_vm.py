import unittest

import numpy as np

from blang import vm
from blang import builder

class TestInstructions(unittest.TestCase):
    def setUp(self):
        self.vm = vm.VM()
        self.b = builder.IBuilder()
        self.b.data(32)

    def push(self, *args):
        for arg in args:
            self.vm.stack.append(np.int32(arg))

    def step(self, stack):
        """Execute an instruction and check the stack."""
        self.vm.load(self.b.core(), 32, 16)
        # Allocate 3 locals to help test "call"
        self.vm.sp -= 3
        self.vm.step()
        self.assertEquals(self.vm.stack, stack)

    def test_pop(self):
        self.push(1, 2, 3, 4)
        self.b.pop()
        self.step([1, 2, 3])

    def test_pop2(self):
        self.push(1, 2, 3, 4)
        self.b.pop2()
        self.step([1, 2])

    def test_dup(self):
        self.push(1, 2, 3, 4)
        self.b.dup()
        self.step([1, 2, 3, 4, 4])

    def test_dup2(self):
        self.push(1, 2, 3, 4)
        self.b.dup2()
        self.step([1, 2, 3, 4, 3, 4])

    def test_dup_x1(self):
        self.push(1, 2, 3, 4)
        self.b.dup_x1()
        self.step([1, 2, 4, 3, 4])

    def test_dup2_x1(self):
        self.push(1, 2, 3, 4)
        self.b.dup2_x1()
        self.step([1, 3, 4, 2, 3, 4])

    def test_dup_x2(self):
        self.push(1, 2, 3, 4)
        self.b.dup_x2()
        self.step([1, 4, 2, 3, 4])

    def test_dup2_x2(self):
        self.push(1, 2, 3, 4)
        self.b.dup2_x2()
        self.step([3, 4, 1, 2, 3, 4])

    def test_swap(self):
        self.push(1, 2, 3, 4)
        self.b.swap()
        self.step([1, 2, 4, 3])

    def test_const(self):
        self.push(1, 2, 3, 4)
        self.b.const()
        self.step([1, 2, 3, 4])

    def test_jmp(self):
        self.push(7)
        self.b.jmp()
        self.step([])
        self.assertEqual(self.vm.pc, 40)

    def test_jmp_back(self):
        self.push(-1)
        self.b.jmp()
        self.step([])
        self.assertEqual(self.vm.pc, 32)

    def test_call_0(self):
        self.push(40)
        self.b.call(0)
        self.step([33])
        self.assertEqual(self.vm.sp, 11)
        self.assertEqual(self.vm.bp, 11)
        self.assertEqual(self.vm.core[self.vm.bp], 16)
        self.assertEqual(self.vm.core[self.vm.bp + 1], 13)

    def test_call_2(self):
        self.push(40, 7, 11)
        self.b.call(2)
        self.step([33])
        self.assertEqual(self.vm.sp, 9)
        self.assertEqual(self.vm.bp, 9)
        self.assertEqual(self.vm.core[self.vm.bp], 16)
        self.assertEqual(self.vm.core[self.vm.bp + 1], 13)
        self.assertEqual(self.vm.core[self.vm.bp + 2], 7)
        self.assertEqual(self.vm.core[self.vm.bp + 3], 11)

    def test_ret(self):
        self.b[16] = 117
        self.b[17] = 127
        self.push(31, 12)
        self.b.ret()
        self.step([12])
        self.assertEqual(self.vm.bp, 117)
        self.assertEqual(self.vm.sp, 127)

    def test_call_ret(self):
        b = self.b
        vm = self.vm

        target = b.const_i()
        b.const_i(7)
        b.const_i(11)
        b.call(2)
        after = b.ip

        # Add buffer space before the function body.
        b.data(16)

        # Function body
        body = b.ip
        b.const_i(4)
        b.ret()

        # Patch
        b[target] = body

        vm.load(self.b.core(), 32, 16)
        vm.sp -= 3

        oldsp, oldbp = vm.sp, vm.bp

        # Call Function
        vm.step()
        vm.step()
        vm.step()
        vm.step()
        self.assertEqual(vm.pc, body)
        self.assertNotEqual(vm.sp, oldsp)
        self.assertNotEqual(vm.bp, oldbp)

        # Return
        vm.step()
        vm.step()
        self.assertEqual(vm.pc, after)
        self.assertEqual(vm.sp, oldsp)
        self.assertEqual(vm.bp, oldbp)
        self.assertEqual(vm.stack, [4])

    def test_jez_zero(self):
        self.push(0, 7)
        self.b.jez()
        self.step([])
        self.assertEqual(self.vm.pc, 40)

    def test_jez_one(self):
        self.push(1, 7)
        self.b.jez()
        self.step([])
        self.assertEqual(self.vm.pc, 33)

    def test_jnz_zero(self):
        self.push(0, 7)
        self.b.jnz()
        self.step([])
        self.assertEqual(self.vm.pc, 33)

    def test_jnz_one(self):
        self.push(1, 7)
        self.b.jnz()
        self.step([])
        self.assertEqual(self.vm.pc, 40)

    def test_alloca(self):
        self.push(5)
        self.b.alloca()
        self.step([8])
        self.assertEqual(self.vm.sp, 8)

    def test_local(self):
        self.push(5)
        self.b.local()
        self.step([16 + 5])

    def test_load(self):
        self.push([7])
        self.b[7] = 19
        self.b.load()
        self.step([19])

    def test_store(self):
        self.push(7, 19)
        self.b.store()
        self.step([])
        self.assertEqual(self.vm.core[7], 19)

    def test_binop(self):
        self.push(6, 9)
        self.b.binop('*')
        self.step([54])

    def test_prim_bad(self):
        self.push(0, 0)
        self.b.prim()
        with self.assertRaises(vm.VMError):
            self.step([])

    def test_prim(self):
        ret = [0]
        def check(vm, arg):
            ret[0] = arg

        self.vm.add_prim('chk', check)
        self.push(0x6b6863, 17)
        self.b.prim()
        self.step([])

        self.assertEqual(ret[0], 17)

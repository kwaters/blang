#!/usr/bin/env python

import collections
import operator


class VM(object):
    """Virtual machine for the B language

    The virtual machine is stack based with 3 registers and a word (32-bit)
    addressable memory.

    There is an operand stack, which instructions directly manipulate.  It is
    not memory mapped, so it is not available to the executing B program.
    There is a data stack in memory which is used to pass parameters to B
    functions and for local storage.

    PC - Program counter, points to the instruction immediately following the
         currently executing instruction.
    SP - Stack Pointer, points to the top of the data stack and grows downward.
    BP - Base Pointer, points to the current functions locals and arguments.
         Despite B frames having predictable size, we use BP to simplify code
         generation and allow nargs() to be implemented in B instead of as an
         instruction.

    Details of the calling convention are given in the "call" instruction.

    Instruction Format

    All instructions are one word.
                   24              16               8               0
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |0|          reserved           |  sub-opcode   |i|   opcode    |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

    Reserved bits should be set to zero.  The sign bit is always zero, this
    simplifies instruction decode.

    All instructions have an immediate (".i") form and a regular form.  In the
    immediate form the instruction is followed by a word which is pushed onto
    the stack before the instruction is executed.
    """
    pass


# Placeholder decorator for defining opcodes
def instruction(opcode, imm=False, subop=False):
    """Define an instruction.

    The name of the function becomes the mnemonic for the instruction.

    If "imm" is True, this is the definition for the immediate form.  And the
    top of stack will be passed into the instruction.  You only need to define
    one of the immediate or regular forms, the other will be generated
    automatically.

    If "subop" is True, this is the definition for an instruction that has a
    sub-opcode.  The sub-opcode will be passed into the instruction.
    """
    def inner(x):
        return x
    return inner


# Operand stack manipulation
# Mirrors the JVM opcode names
@instruction(0x10)
def pop(vm):
    """..., a -> ..."""
    vm.stack.pop()

@instruction(0x11)
def pop2(vm):
    """..., a, b -> ..."""
    vm.stack.pop()
    vm.stack.pop()

@instruction(0x12)
def dup(vm):
    """..., a -> ..., a, a"""
    vm.stack.append(vm.stack[-1])

@instruction(0x13)
def dup2(vm):
    """..., a, b -> ..., a, b, a, b"""
    vm.stack.append(vm.stack[-2])
    vm.stack.append(vm.stack[-2])

@instruction(0x14)
def dup_x1(vm):
    """..., a, b -> ..., b, a, b"""
    vm.stack.insert(-2, vm.stack[-1])

@instruction(0x15)
def dup2_x1(vm):
    """..., a, b, c -> ..., b, c, a, b, c"""
    vm.stack.insert(-3, vm.stack[-2])
    vm.stack.insert(-3, vm.stack[-1])

@instruction(0x16)
def dup_x2(vm):
    """..., a, b, c -> ..., c, a, b, c"""
    vm.stack.insert(-3, vm.stack[-1])

@instruction(0x17)
def dup2_x2(vm):
    """..., a, b, c, d -> ..., c, d, a, b, c, d"""
    vm.stack.insert(-4, vm.stack[-2])
    vm.stack.insert(-4, vm.stack[-1])

@instruction(0x18)
def swap(vm):
    """..., a, b -> ..., b, a"""
    vm.stack[-2:] = vm.stack[:-3:-1]

@instruction(0x19)
def const(vm):
    """... -> ..."""
    pass

# Flow Control
@instruction(0x20, imm=True)
def jmp(vm, addr):
    """..., addr -> ... | pc := pc + addr"""
    vm.pc += vm.stack.pop()

@instruction(0x21, subop=True)
def call(vm, nargs):
    """ ..., func, a0, a1, ..., an -> ..., retaddr

    1. oldsp := sp
    2. The arguments are pushed onto the data stack in reverse order.
    3. "oldsp" is pushed onto the stack
    4. "bp" is pushed onto the stack
    5. bp := sp

    Example Frame Layout
       +--------------------+ High Address
       | used               |
       +--------------------+
       | used               |
       +--------------------+
       | used               | <- oldsp
       +--------------------+
       | a2                 |
       +--------------------+
       | a1                 |
       +--------------------+
       | a0                 |
       +--------------------+
       | oldsp              |
       +--------------------+
       | oldbp              | <- bp, sp
       +--------------------+
       | locals             |
       +--------------------+
       | locals             |
       +--------------------+
       | locals             |
       +--------------------+ Low Address
    """
    oldsp = vm.sp
    for _ in xrange(nargs):
        vm.dpush(vm.stack.pop())
    vm.dpush(oldsp)
    vm.dpush(vm.bp)
    vm.bp = vm.sp

    # Jump and store return address
    vm.pc, vm.stack[-1] = vm.stack[-1], vm.pc

@instruction(0x22)
def ret(vm):
    """..., retaddr, retval -> ...

    1. pc := retaddr
    2. sp := bp[1]
    3. bp := bp[0]
    """
    vm.pc = vm.stack.pop(-2)
    vm.sp = vm.core[vm.bp + 1]
    vm.bp = vm.core[vm.bp]

@instruction(0x23, imm=True)
def jez(vm, addr):
    """..., x, addr -> ... | if x == 0, pc := pc + addr"""
    if vm.stack.pop() == 0:
        vm.pc += addr

@instruction(0x24, imm=True)
def jnz(vm, addr):
    """..., x, addr -> ... | if x != 0, pc := pc + addr"""
    if vm.stack.pop() != 0:
        vm.pc += addr

# Data stack manipulation
@instruction(0x30, imm=True)
def alloca(vm, size):
    """..., size -> ..., sp | sp := sp - size"""
    vm.sp -= size
    vm.stack.append(vm.sp)

@instruction(0x31, imm=True)
def local(vm, addr):
    """..., addr -> ..., bp + addr"""
    vm.stack.push(vm.bp + addr)

# Operators
@instruction(0x40)
def load(vm):
    """..., a -> ..., *a"""
    vm.stack[-1] = vm.core[vm.stack[-1]]

@instruction(0x41)
def store(vm):
    """..., a, b -> ... | *a := b"""
    value = vm.stack.pop()
    addr = vm.stack.pop
    vm.core[addr] = value

BinOp = collections.namedtuple('BinOp', ['name', 'func'])
binops = {
    0x0: BinOp('mul', operator.mul),
    0x1: BinOp('div', operator.div),
    0x2: BinOp('mod', operator.mod),
    0x3: BinOp('add', operator.add),
    0x4: BinOp('sub', operator.sub),
    0x5: BinOp('shl', operator.lshift),
    0x6: BinOp('shr', operator.rshift),
    0x7: BinOp('lt', operator.lt),
    0x8: BinOp('lte', operator.le),
    0x9: BinOp('gt', operator.gt),
    0xa: BinOp('gte', operator.ge),
    0xb: BinOp('eq', operator.eq),
    0xc: BinOp('neq', operator.ne),
    0xd: BinOp('and', operator.and_),
    0xe: BinOp('xor', operator.xor),
    0xf: BinOp('or', operator.or_),
}

@instruction(0x42, subop=True)
def binop(vm, subop):
    """..., a, b -> ..., a <op> b"""
    rhs = vm.stack.pop()
    lhs = vm.stack[-1]
    vm.stack[-1] = binop_ops[subop].func(lhs, rhs)

@instruction(0x42, subop=True)
def prim(vm):
    """Execute a primitive python function.

    Used to implement the B runtime.
    """
    assert False, "Not Implemented"

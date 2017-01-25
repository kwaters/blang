#!/usr/bin/env python

import blang
import blang.compiler
import blang.primitive
import blang.obj


s = """
.start() {
    main();
    exit(0);
}

exit(retval) {
    if (nargs() == 0)
        retval = 0;
    .syscall('exit', retval);
}

char(s, pos) {
    auto word, ofs;

    word = pos / 4;
    ofs = pos % 4;
    return ((s[word] >> (8 * ofs)) & 0377);
}

putchar(c) {
    .syscall('putc', c);
}

puts(s) {
    auto c, i;
    i = 0;
    while ((c = char(s, i++)) != '*e')
        putchar(c);
}

nargs(x) {
    auto bp, oldsp;
    /* bp of the calling function. */
    bp = (&x)[-2];

    /* sp of the calling functions calling function. */
    oldsp = bp[1];

    return (oldsp - bp - 2);
}

main() {
    puts("Hello, World!*n");
}
"""

vm = blang.vm.VM()
blang.primitive.register_prims(vm)

@blang.primitive.primitive
def abc(vm, p):
    vm.core[p] = 42

vm.add_prim('abc', abc)


c = blang.compiler.Compiler()
b = c.builder

while b.ip < 0x100:
    b.dw()

# Syscall
b.define_extrn('.syscall')
b.dw(b.ip + 1)
b.local_i(2)
b.load()
b.local_i(3)
b.prim()
b.ret_i(0)

for part in blang.parser.parser.parse(s):
    c.visit(part, b)

b.link()

o = blang.obj.BObject()
o.core = b.core().copy()

for relocation in b._relocations:
    o.relocations.append(blang.obj.Relocation(*relocation))
for n, a in b._extrns.iteritems():
    o.definitions.append(blang.obj.Definition(n, a))

o.pc, o.sp = b[b._extrns['.start']], 0xff

with open('out.bo', 'w') as f:
    w = blang.obj.Writer(f)
    w.dump(o)

print b.core()
vm.load(b.core(), b[b._extrns['.start']], 0xff)
print vm.disassemble_range(0, len(b))

print vm.run()

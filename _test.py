#!/usr/bin/env python

import blang
import blang.compiler
import blang.primitive


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
    auto v;

    puts("Hello, World!*n");
    .syscall('abc', 1, &main, 3);
    .syscall('abc', &v);
    exit(v);
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


print b.core()
vm.load(b.core(), b[b._extrns['.start']], 0xff)
print vm.disassemble_range(0, len(b))

print vm.run()

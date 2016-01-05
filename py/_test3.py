#!/usr/bin/env python

import blang
import blang.compile
import blang.runtime

s = """
main( ) {
  auto c;
  while (1) {
    while ( (c=getchar()) != ' ')
      if (putchar(c) == '*n') exit();
    putchar( '*n' );
    while ( (c=getchar()) == ' '); /* skip blanks */
    if (putchar(c)=='*n') exit(); /* done when newline */
    }
}
"""

s = """
f(x) {
    switch (x) {
        case 4:
            g();
            goto end;

        case ' ':
            h();
            goto end;
    }
    end:;
}
"""

s = """
main() {
    printf("Hello, World!*n%d 0%o*n%s*n", 42, 42, "OK");
}
"""

s = """
myprintn(number, base) {
    auto digits[32], ptr;
    ptr = digits;

    if (number < 0) {
        putchar('-');
        number = -number;
    }

    goto skip;
    while (number) {
skip:
        *ptr++ = '0' + number % base;
        number =/ base;
    }

    while (ptr > digits) {
        putchar(*--ptr);
    }
}

main() {
    auto base;
    base = 1;
    while (++base <= 10) {
        printf("%d: ");
        myprintn(42, base);
        printf("*n");
    }
}
"""

dangle = """
dangle(x, y) {
    if (x)
        if (y)
            return (0);
        else
            return (1);

    return (2);
}

main() {
    if (dangle(0, 0) != 2) {
        putstr("FAIL*n");
    } else if (dangle(0, 1) != 2) {
        putstr("FAIL*n");
    } else if (dangle(1, 0) != 1) {
        putstr("FAIL*n");
    } else if (dangle(1, 1) != 0) {
        putstr("FAIL*n");
    } else {
        putstr("OK*n");
    }
}
"""

vm = blang.vm.VM()
c = blang.compile.Compiler()
blang.runtime.setup_runtime(vm, c)

output = blang.parser.parser.parse(s)
for part in output:
    part.show()
    c.visit(c.b, part)

c.cstring.build(c.b)
c.linker.link(c.b)

print c.b.core
vm.core[:len(c.b.core)] = c.b.core

print vm.disassemble_range(0, len(c.b.core))

vm.sp = vm.bp = (len(c.b.core) + 0x200) & ~0xff
vm.run()

assert vm.core[:len(c.b.core)] == c.b.core

#!/usr/bin/env python

import sys

from . import parser
from . import vm

_runtime = '''
char(s, pos) {
    auto word, ofs;

    word = pos / 4;
    ofs = pos % 4;
    return ((s[word] >> (8 * ofs)) & 0377);
}

putstr(s) {
    auto i, c;

    i = 0;
    while ((c = char(s, i++)) != '*e')
        putchar(c);
}

printn(n, b) {
    auto a;
    if (a = n / b)
        printn(a, b);
    putchar(n % b + '0');
}

printf(fmt, x1,x2,x3,x4,x5,x6,x7,x8,x9) {
	extrn printn, char, putchar;
	auto adx, x, c, i, j;

	i= 0;	/* fmt index */
	adx = &x1;	/* argument pointer */
loop :
	while((c=char(fmt,i++) ) != '%') {
		if(c == '*e')
			return;
		putchar(c);
	}

	x = *adx++;
	switch (c = char(fmt,i++)) {
	case 'd': /* decimal */
	case 'o': /* octal */
		if(x < 0) {
			x = -x ;
			putchar('-');
		}
		printn(x, c=='o'?8:10);
		goto loop;

	case 'c' : /* char */
		putchar(x);
		goto loop;

	case 's': /* string */
		while((c=char(x, j++)) != '*e')
			putchar(c);
		goto loop;
	}
	putchar('%') ;
	i--;
	adx--;
	goto loop;
}
'''


def exit(vm):
    vm.stop()


def putchar(vm):
    c = vm.core[vm.bp + 2]
    if c == 0:
        sys.stdout.write('\0')
        return

    while c > 0:
        c, char = divmod(c, 256)
        sys.stdout.write(chr(char))


def _add_builtin(vm_, compiler, name, func):
    b = compiler.b
    linker = compiler.linker

    r_func_lvalue = b.dw()
    compiler.linker.define(name, r_func_lvalue)
    b.patch(r_func_lvalue, b.ref())

    b.prim(vm.add_prim(name, func))
    b.ret_i(0)


def setup_runtime(vm, compiler):
    b = compiler.b
    # Bootstrap
    compiler.linker.add_fixup('main', b.load_i())
    b.call(0)
    compiler.linker.add_fixup('exit', b.load_i())
    b.call(0)

    _add_builtin(vm, compiler, 'exit', exit)
    _add_builtin(vm, compiler, 'putchar', putchar)

    for part in parser.parser.parse(_runtime):
        compiler.visit(compiler.b, part)

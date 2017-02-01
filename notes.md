TODO
----
Makefile to support B compilation.
File handling in lexer.b.
Token dumping in C implementation for testing against B lexer.

Auto arrays.

Defer to post C phase:
    - "extern" hack
    - Line number tracking
    - Initialization of external variables with addresses of other externals

Performance Optimization
-----------------------
- Use 61-bit integers with the bottom 3 bits always zeroed.  Sort of like
  tagged arithmatic with only one tag type.
    - Advantages
        - bit representation = pointer representation
    - Disadvantages
        - `>>`, `*`, `/`, `%` are all more expensive.
- Pass arguments in registers if arguments are only used as rvalues.  We want
  to preserve the behavior of arguments as arrays as shown in the `printf()`
  implementation.

Bugs
----
- Backspace should be a legal identifier character.
- String literals should be legal constants.  Proposed behavior:
    - ICE when used as the size of an array.
    - Never match in case labels.
- The BNF has "(" name ")" as not being an lvalue.  So, `&(a)` is a syntax
  error.

Proposed Options
----------------
    -fshort-circuit
    -fextrn-call
    -dump-tokens

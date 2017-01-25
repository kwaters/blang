TODO
----
three-address-code
C backend
    - initializers (for globals with names)

defer "extrn" hack to post C phase.

Bugs
----
- Backspace should be a legal identifier character.
- String literals should be legal constants.  Proposed behavior:
    - ICE when used as the size of an array.
    - Never match in case labels.

Proposed Options
----------------
    -fshort-circuit
    -fextrn-call

#!/usr/bin/env python

import collections
import re

from ply import lex

from . import util


__all__ = ['tokens', 'Name', 'lexer']


Name = collections.namedtuple('Name', ['name', 'implicit_extrn'])


_keywords = set([
    'auto',
    'case',
    'else',
    'extrn',
    'goto',
    'if',
    'return',
    'switch',
    'while',
])

tokens = tuple(keyword.upper() for keyword in _keywords) + (
    'ASSIGN',
    'CHARACTER',
    'DEC',
    'EQ',
    'GTE',
    'INC',
    'LTE',
    'NAME',
    'NEQ',
    'NUMBER',
    'SHIFTL',
    'SHIFTR',
    'STRING',
)


_unescape_re = re.compile(r'\*(.)')
_escape_sequences = {
    '0': '\0',
    'e': '\x04',
    '(': '{',
    ')': '}',
    't': '\t',
    '*': '*',
    "'": "'",
    '"': '"',
    'n': '\n',
}
def unescape(s):
    "Remove B escape sequences."
    parts = _unescape_re.split(s)
    for i, part in enumerate(parts):
        if i % 2 == 0:
            continue
        # We define undefined escape sequences to be the escaped character.
        # The specification isn't clear if this is an error or not.  In the
        # spirit of making bugs subtle and exciting, we choose not to make it
        # an error.
        parts[i] = _escape_sequences.get(part, part)
    return ''.join(parts)


literals = '{}[]()*-&~!+<>&|?:,/%;'

t_ignore = ' \t'

t_INC = r'\+\+'
t_DEC = r'--'
t_SHIFTL = r'<<'
t_SHIFTR = r'>>'
t_LTE = r'<='
t_GTE = r'>='
t_NEQ = r'!='

def t_NAME(t):
    r'[a-z._A-Z][a-z._A-Z0-9]*'
    if t.value in _keywords:
        t.type = t.value.upper()
    else:
        # We use the lexer hack from the H6070 version for implicitly defined
        # extrns.  This makes the language quite a bit more ergonomic.
        #
        # This isn't a very efficient way to look ahead.
        peek = t.lexer.clone().token()
        implicit_extrn = peek is not None and peek.type == '('
        t.value = Name(t.value, implicit_extrn)
    return t

def t_NUMBER(t):
    r'[0-9]+'
    # In the PDP-11 version,
    #
    # "An octal constant is the same as a decimal constant except that it
    # begins with a zero. It is then interpreted in base 8. Note that 09 (base
    # 8) is legal and equal to 011."
    #
    # In the H6070 version,
    #
    # "The syntax of B says that any number that begins with 0 is an octal
    # number (and hence can't have any 8's or 9's in it)."
    #
    # We use the PDP-11 version, because it's more fun.
    s = t.value
    if s[0] == '0':
        x = 0
        for c in s[1:]:
            x = x * 8 + (ord(c) - ord('0'))
    else:
        x = int(s, 10)

    # "The value of the constant should not exceed the maximum value that can
    # be stored in a word."
    #
    # We will silently truncate.  In C99 mode clang-3.7 issues an error,
    # gcc-4.9.3 issues a warning.
    t.value = util.wrap(x)
    return t

def t_CHARACTER(t):
    r"'(?:[^'*]|\*.)*'"
    # "A character constant is represented by ' followed by one or more
    # characters (possibly escaped) followed by another '. It has an rvalue
    # equal to the value of the characters packed and right adjusted, with zero
    # fill."
    #
    # Since the H0670 is big-endian, I believe this means the character constant
    #   'eh' = 'e' << 8 | 'e' and 'abc' = 'a' << 16 | 'b' << 8 | 'c'
    #
    # But i686 is little-endian, and we want tricks like arrays of characters
    # to be reasonable strings, so we simply pack the character constant as
    # little-endian.
    s = unescape(t.value[1:-1])
    x, shift = 0, 0
    for c in s[:4]:
        x = (x << shift) | ord(c)
        shift += 8

    t.value = x
    return t

def t_STRING(t):
    r'"(?:[^"*]|\*.)*"'
    t.value = unescape(t.value[1:-1])
    return t

def t_COMMENT(t):
    r'/\*(?:\n|.)*?\*/'
    t.lexer.lineno += t.value.count('\n')

def t_NL(t):
    r'\n'
    t.lexer.lineno += 1

def t_ASSIGN(t):
    r'=(?:[=|&-+%*/]|==|!=|<[<=]?|>[>=]?)?'
    if t.value == '==':
        t.type = 'EQ'
    else:
        t.value = t.value[1:]
    return t

def t_error(t):
    #  TODO: errors
    assert False

lexer = lex.lex()

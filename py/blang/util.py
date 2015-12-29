#!/usr/bin/env python

def wrap(x):
    """Return x as a 32-bit int."""
    if -0x80000000 <= x <= 0x7fffffff:
        return x
    return (x + 0x80000000) % 0x100000000 - 0x80000000

#!/usr/bin/env python

import numpy as np
import struct

def wrap(x):
    """Return x as a 32-bit int."""
    if -0x80000000 <= x <= 0x7fffffff:
        return x
    return (x + 0x80000000) % 0x100000000 - 0x80000000


def pack_string(s):
    """Return s as an array of int32."""
    out = []
    for i in xrange(0, len(s) + 3, 4):
        out.append(struct.unpack('<i', struct.pack('<4s', s[i:i + 4]))[0])
    return out

#!/usr/bin/env python

import collections
import struct
import zlib
import cStringIO as StringIO

import numpy as np


Relocation = collections.namedtuple('Relocation', ['name', 'addr'])
Definition = collections.namedtuple('Definition', ['name', 'addr'])


class BObject(object):
    def __init__(self):
        self.core = np.array([], dtype=np.int32)
        self.relocations = []
        self.definitions = []
        self.pc = None
        self.sp = None


class Writer(object):
    _tag = struct.Struct('<4sI')
    _def = struct.Struct('<8sI')

    def __init__(self, file, compress=True):
        self.file = file
        if compress:
            self.file.write(struct.pack('<4s', 'BObz'))
            self.compress = zlib.compressobj(9)
        else:
            self.file.write(struct.pack('<4s', 'BObj'))
            self.compress = None

    def write(self, s):
        if self.compress is not None:
            self.file.write(self.compress.compress(s))
        else:
            self.file.write(s)

    def flush(self):
        if self.compress is not None:
            self.file.write(self.compress.flush())
        self.file.flush()

    def dump(self, obj):
        if obj.pc is not None:
            self.save_exec(obj.pc, obj.sp)
        if obj.definitions:
            self.save_defs(obj.definitions)
        if obj.relocations:
            self.save_rloc(obj.relocations)
        self.save_core(obj.core)
        self.save('end', '')
        self.flush()

    def save_exec(self, pc, sp):
        self.save('exec', struct.pack('<II', pc, sp))

    def save_defs(self, definitions):
        def_ = struct.Struct('<8sI')
        defs = [def_.pack(*definition) for definition in definitions]
        defs.sort()
        self.save('defs', ''.join(defs))

    def save_rloc(self, relocations):
        rlocs = {}
        for relocation in relocations:
            rlocs.setdefault(relocation.name, []).append(relocation.addr)

        names = []
        ofs = []
        addrs = []

        for name in sorted(rlocs.iterkeys()):
            names.append(name)
            ofs.append(len(addrs))
            r = rlocs[name]
            r.sort()
            addrs.extend(r)
            addrs.append(0xffffffff)

        name_struct = struct.Struct('<8s')
        num_struct = struct.Struct('<I')

        out = [num_struct.pack(len(names))]
        for name in names:
            out.append(name_struct.pack(name))
        for offset in ofs:
            out.append(num_struct.pack(4 * offset + 4 + 12 * len(names)))
        for addr in addrs:
            out.append(num_struct.pack(addr))

        self.save('rloc', ''.join(out))

    def save_defs(self, definitions):
        defs_struct = struct.Struct('<8sI')
        defs = sorted(definitions)
        self.save('defs', ''.join(defs_struct.pack(*def_) for def_ in defs))

    def save_core(self, core):
        bytes = core.tobytes()
        self.write(self._tag.pack('core', len(bytes)))
        self.write(bytes)

    def save(self, tag, data):
        self.write(self._tag.pack(tag, len(data)))
        self.write(data)


class ReadError(Exception):
    pass


class Reader(object):
    _tag = struct.Struct('<4sI')

    def load(self, file):
        magic = file.read(4)
        magic = struct.unpack('<4s', magic)[0]
        if magic == 'BObj':
            read = file.read
        elif magic == 'BObz':
            read = StringIO.StringIO(zlib.decompress(file.read())).read
        else:
            raise ReadError('Bad Magic')

        obj = BObject()

        while True:
            tag, size = self._tag.unpack(read(self._tag.size))
            data = read(size)
            if tag == 'core':
                self.read_core(obj, data)
            elif tag == 'defs':
                self.read_defs(obj, data)
            elif tag == 'rloc':
                self.read_rloc(obj, data)
            elif tag == 'exec':
                self.read_exec(obj, data)
            elif tag == 'end\x00':
                break

        return obj

    def read_core(self, obj, data):
        obj.core = np.frombuffer(data, dtype=np.int32).copy()

    def read_defs(self, obj, data):
        defs_struct = struct.Struct('<8sI')
        for i in xrange(0, len(data), 12):
            name, addr = defs_struct.unpack_from(data, i)
            name = name.rstrip('\x00')
            obj.definitions.append(Definition(name, addr))

    def read_rloc(self, obj, data):
        num_struct = struct.Struct('<I')
        name_struct = struct.Struct('<8s')

        count = num_struct.unpack_from(data)[0]
        for i in xrange(count):
            name = name_struct.unpack_from(data, 4 + i * name_struct.size)[0]
            name = name.rstrip('\x00')
            ofs = num_struct.unpack_from(data, 4 + count * name_struct.size +
                                               i * num_struct.size)[0]

            while True:
                print name, ofs, len(data)
                addr = num_struct.unpack_from(data, ofs)[0]
                print addr, ofs
                ofs += 4
                if addr == 0xffffffff:
                    break
                obj.relocations.append(Relocation(name, addr))


    def read_exec(self, obj, data):
        obj.pc, obj.sp = struct.unpack('<II', data)

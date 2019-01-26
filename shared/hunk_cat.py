# hunk_cat.py
# 
# Concatenate a sequence of Amiga hunk-based load files.
# 
# Written & released by Keir Fraser <keir.xen@gmail.com>
# 
# This is free and unencumbered software released into the public domain.
# See the file COPYING for more details, or visit <http://unlicense.org>.

import struct, sys, getopt

HUNK_HEADER       = 0x3f3
HUNK_UNIT         = 0x3e7
HUNK_NAME         = 0x3e8

HUNK_CODE         = 0x3e9
HUNK_DATA         = 0x3ea
HUNK_BSS          = 0x3eb

HUNK_RELOC32      = 0x3ec
HUNK_RELOC32SHORT = 0x3fc
HUNK_RELOC16      = 0x3ed
HUNK_RELOC8       = 0x3ee
HUNK_DREL32       = 0x3f7
HUNK_DREL16       = 0x3f8
HUNK_DREL8        = 0x3f9
HUNK_ABSRELOC16   = 0x3fd
HUNK_SYMBOL       = 0x3f0
HUNK_DEBUG        = 0x3f1
HUNK_END          = 0x3f2
HUNK_EXT          = 0x3ef
HUNK_OVERLAY      = 0x3f5
HUNK_BREAK        = 0x3f6
HUNK_LIB          = 0x3fa
HUNK_INDEX        = 0x3fb

def usage(argv):
    print("%s -o output_file input-files..." % argv[0])
    sys.exit(1)

def main(argv):
    try:
        opts, args = getopt.getopt(argv[1:], "o:")
    except getopt.GetoptError as err:
        print(str(err))
        usage(argv)
    in_f = []
    for a in args:
        in_f.append(open(a, "rb"))
    out_f = None
    for o, a in opts:
        if o == "-o":
            out_f = open(a, "wb")
    if len(in_f) == 0 or out_f is None:
        usage(argv)
    # Read hunk-size tables.
    hunk_sz = []
    hunk_nr = []
    for f in in_f:
        (id, x, nr, first, last) = struct.unpack(">IIIII", f.read(5*4))
        assert id == HUNK_HEADER
        assert x == 0
        assert first == 0
        assert last == nr-1
        hunk_nr.append(nr)
        for i in range(nr):
            (sz,) = struct.unpack(">I", f.read(4))
            hunk_sz.append(sz)
    # Output concatenated hunk-size table.
    out_f.write(struct.pack(">IIIII", HUNK_HEADER, 0, len(hunk_sz), 0,
                            len(hunk_sz)-1))
    for sz in hunk_sz:
        out_f.write(struct.pack(">I", sz))
    # Output hunks of each input file in turn.
    hunkbase = 0
    for f, f_idx in zip(in_f, range(len(in_f))):
        for h_idx in range(hunk_nr[f_idx]):
            while True:
                (id,) = struct.unpack(">I", f.read(4))
                out_f.write(struct.pack(">I", id))
                id &= 0x3fffffff
                if id == HUNK_CODE or id == HUNK_DATA or id == HUNK_BSS:
                    (nr,) = struct.unpack(">I", f.read(4))
                    out_f.write(struct.pack(">I", nr))
                    nr &= 0x3fffffff
                    if id != HUNK_BSS:
                        out_f.write(f.read(nr*4))
                elif id == HUNK_RELOC32:
                    while True:
                        (nr,) = struct.unpack(">I", f.read(4))
                        out_f.write(struct.pack(">I", nr))
                        if nr == 0:
                            break
                        (h,) = struct.unpack(">I", f.read(4))
                        h += hunkbase
                        out_f.write(struct.pack(">I", h))
                        out_f.write(f.read(nr*4))
                elif id == HUNK_END:
                    break
                else:
                    print("Unexpected hunk 0x%x" % (id))
                    assert False
        hunkbase += hunk_nr[f_idx]
    
if __name__ == "__main__":
    main(sys.argv)

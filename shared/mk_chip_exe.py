# mk_chip_exe.py
#
# Modify all executable hunks to require Chip memory.
#
# Written & released by Keir Fraser <keir.xen@gmail.com>
#
# This is free and unencumbered software released into the public domain.
# See the file COPYING for more details, or visit <http://unlicense.org>.

import struct, sys

def main(argv):
    if len(argv) != 2:
        print("%s <file>" % argv[0])
        return
    dat = bytearray(open(argv[1], "rb").read())
    (id, x, nr) = struct.unpack('>3I', dat[:3*4])
    assert id == 0x3f3 and x == 0
    sizes = list(struct.unpack('>%dI' % nr, dat[5*4:(5+nr)*4]))
    new_sizes = []
    for s in sizes:
        s &= 0x3fffffff
        s |= 0x40000000
        new_sizes.append(s)
    dat[5*4:(5+nr)*4] = struct.pack('>%dI' % nr, *new_sizes)
    open(argv[1], "wb").write(dat)
    
if __name__ == "__main__":
    main(sys.argv)

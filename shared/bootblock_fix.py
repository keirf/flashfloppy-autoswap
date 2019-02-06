# bootblock_fix.py <adf>
#
# Fix the checkdum in the specified ADF image file.
# 
# Written & released by Keir Fraser <keir.xen@gmail.com>
# 
# This is free and unencumbered software released into the public domain.
# See the file COPYING for more details, or visit <http://unlicense.org>.

import struct, sys

# Amiga bootblock checksum
def checksum(bb, sum=0):
    while len(bb):
        x, bb = struct.unpack(">L",bb[:4]), bb[4:]
        sum += x[0]
        if sum >= (1<<32):
            sum -= (1<<32)-1
    return sum

def main(argv):
    f = open(argv[1], "r+b")
    bb = bytearray(f.read(1024))
    (dos,csum,root) = struct.unpack('>3I', bb[:3*4])
    assert dos>>8 == 0x444f53
    bb[4:8] = bytearray(4)
    bb[4:8] = struct.pack('>I', checksum(bb)^0xffffffff)
    f.seek(0)
    f.write(bb)

if __name__ == "__main__":
    main(sys.argv)

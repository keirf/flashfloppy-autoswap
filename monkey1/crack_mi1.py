# crack_mi1.py
#
# Patches the Secret of Monkey Island resource file disk01.lec to skip the
# manual protection.
#
# Thanks to JOTD/WHDLoad where I discovered this method.
#
# Written & released by Keir Fraser <keir.xen@gmail.com>
#
# This is free and unencumbered software released into the public domain.
# See the file COPYING for more details, or visit <http://unlicense.org>.

import struct, sys, random

needle = bytearray([0x84, 0x68, 0x69, 0x69, 0x3a, 0x2a, 0x73, 0x61,
                    0x29, 0x6a, 0x69, 0x73, 0x60, 0x29, 0x62, 0x69])

def main(argv):
    if len(argv) != 2:
        print("%s <file>" % argv[0])
        return
    dat = bytearray(open(argv[1], "rb").read())
    offset = dat.find(needle)
    for i in range(256):
        dat[offset+i] = 0xff
    dat[offset+0x29] = 0xfe
    dat[offset+0xff] = 0xc9
    open(argv[1], "wb").write(dat)
    
if __name__ == "__main__":
    main(sys.argv)

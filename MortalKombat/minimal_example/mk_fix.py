# mk_fix.py <adf> <main_patch>
#
# Insert our code into the Mortal Kombat boot disk image.
# 
# Written & released by Keir Fraser <keir.xen@gmail.com>
# 
# This is free and unencumbered software released into the public domain.
# See the file COPYING for more details, or visit <http://unlicense.org>.

import struct, sys

def bsr(code, off, target): # BSR.w xxx
    code[off:off+4] = struct.pack('>Hh', 0x6100, target-off-2)

def inject(code, off, payload):
    code[off:off+len(payload)] = payload

def main(argv):
    f = open(argv[1], "r+b")

    # Modify main game routines for AutoSwap on DF0.
    f.seek(0x3200)
    main = bytearray(f.read(0x8000))
    bsr(main,0x40,0x74fe+4) # execute patch initialiser
    with open(argv[2], "rb") as p:
        inject(main,0x74fe,p.read())
    f.seek(0x3200)
    f.write(main)

if __name__ == "__main__":
    main(sys.argv)

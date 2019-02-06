# mk_fix.py <adf> <bb_patch> <main_patch>
#
# Insert our code into the Mortal Kombat boot disk image.
# 
# Written & released by Keir Fraser <keir.xen@gmail.com>
# 
# This is free and unencumbered software released into the public domain.
# See the file COPYING for more details, or visit <http://unlicense.org>.

import struct, sys

def bra(code, off, target):
    disp = target - off - 2
    if -128 <= disp <= 127:
        code[off:off+2] = struct.pack('Bb', 0x60, target-off-2)
    else:
        code[off:off+4] = struct.pack('>Hh', 0x6000, target-off-2)

def bsr(code, off, target):
    disp = target - off - 2
    if -128 <= disp <= 127:
        code[off:off+2] = struct.pack('Bb', 0x61, target-off-2)
    else:
        code[off:off+4] = struct.pack('>Hh', 0x6100, target-off-2)

def nop(code, off):
    code[off:off+2] = bytearray([0x4e, 0x71])

def inject(code, off, payload):
    code[off:off+len(payload)] = payload

def main(argv):
    f = open(argv[1], "r+b")

    # Modify bootblock to detect boot drive, disable caches, and patch
    # the first loader.
    bb = bytearray(f.read(1024))
    bra(bb,0xc,0x40)   # skip the cracktro
    bsr(bb,0x92,0xa8)  # execute <bb_patch>
    nop(bb,0x94)
    with open(argv[2], "rb") as p:
        inject(bb,0xa8,p.read())
    inject(bb,0x300,bytes('FlashFloppy AutoSwap Patch %s by Keir' % (argv[4]),
                          'utf8'))
    inject(bb,0x340,b'Original crack by NOMAD/Fairlight')
    f.seek(0)
    f.write(bb)

    # Modify main game routines for AutoSwap on boot drive.
    f.seek(0x3200)
    main = bytearray(f.read(0x8000))
    bsr(main,0x32,0x74fe+4) # execute patch initialiser
    with open(argv[3], "rb") as p:
        inject(main,0x74fe,p.read())
    f.seek(0x3200)
    f.write(main)

if __name__ == "__main__":
    main(sys.argv)

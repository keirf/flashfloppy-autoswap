# bootblock_fix.py [--ntsc-patch] <adf>
#
# Fix the checkdum in the specified ADF image file.
# 
# Written & released by Keir Fraser <keir.xen@gmail.com>
# 
# This is free and unencumbered software released into the public domain.
# See the file COPYING for more details, or visit <http://unlicense.org>.

import struct, sys

# Check whether LMB or fire button is pressed
# 1039 00bf e001  move.b  ciaapra,d0
# 4600            not.b   d0
# 0200 00c0       andi.b  #0xc0,d0
# 6768            beq.b   skip
# If either is pressed, switch to NTSC mode.
# 2649            movea.l a1,a3
# 2c78 0004       movea.l 4,a6
# 43fa 004e       lea.l   gfxname(pc),a1
# 4eae fe68       jsr     OldOpenLibrary(a6)
# 2240            movea.l d0,a1
# 3029 00ce       move.w  gb_DisplayFlags(a1),d0
# 0200 00fb       andi.b  #fb,d0
# 0000 0001       ori.b   #1,d0
# 3340 00ce       move.w  d0,gb_DisplayFlags(a1)
# 337c 00c8 00d8  move.w  #200,gb_NormalDisplayRows(a1)
# 0029 0002 000e  ori.b   #LIBF_CHANGED,lib_Flags(a1)
# 2449            movea.l a1,a2
# 4eae fe56       jsr     SumLibrary(a6)
# 224a            movea.l a2,a1
# 4eae fe62       jsr     CloseLibrary(a6)
# 1d7c 003c 0212  move.b  #60,VBlankFrequency(a6)
# 002e 0002 000e  ori.b   #LIBF_CHANGED,lib_Flags(a6)
# 224e            movea.l a6,a1
# 4eae fe56       jsr     SumLibrary(a6) 
# 33fc 0000 00df  move.w  #0,beamcon0
# f1dc 
# 224b            movea.l a3,a1
# 6012            bra.b   skip
# gfxname:       .asciz 'graphics.library'
# skip:
ntsc_patch_code = bytes([
    0x10,0x39,0x00,0xbf,0xe0,0x01,
    0x46,0x00,
    0x02,0x00,0x00,0xc0,
    0x67,0x68,

    0x26,0x49,
    0x2c,0x78,0x00,0x04,
    0x43,0xfa,0x00,0x4e,
    0x4e,0xae,0xfe,0x68,
    0x22,0x40,
    0x30,0x29,0x00,0xce,
    0x02,0x00,0x00,0xfb,
    0x00,0x00,0x00,0x01,
    0x33,0x40,0x00,0xce,
    0x33,0x7c,0x00,0xc8,0x00,0xd8,
    0x00,0x29,0x00,0x02,0x00,0x0e,
    0x24,0x49,
    0x4e,0xae,0xfe,0x56,
    0x22,0x4a,
    0x4e,0xae,0xfe,0x62,
    0x1d,0x7c,0x00,0x3c,0x02,0x12,
    0x00,0x2e,0x00,0x02,0x00,0x0e,
    0x22,0x4e,
    0x4e,0xae,0xfe,0x56,
    0x33,0xfc,0x00,0x00,0x00,0xdf,0xf1,0xdc,
    0x22,0x4b,
    0x60,0x12,

    # .asciz 'graphics.library'
    0x67,0x72,0x61,0x70,0x68,0x69,0x63,0x73,
    0x2e,0x6c,0x69,0x62,0x72,0x61,0x72,0x79,0x00,
    # .even
    0x00,
])

# Amiga bootblock checksum
def checksum(bb, sum=0):
    while len(bb):
        x, bb = struct.unpack(">L",bb[:4]), bb[4:]
        sum += x[0]
        if sum >= (1<<32):
            sum -= (1<<32)-1
    return sum

def main(argv):
    filename = argv[1]
    ntsc_patch = filename == '--ntsc-patch'
    if ntsc_patch:
        filename = argv[2]
    f = open(filename, "r+b")
    bb = bytearray(f.read(1024))
    dos, = struct.unpack('>I', bb[:4])
    assert dos>>8 == 0x444f53
    if ntsc_patch:
        patch_len = len(ntsc_patch_code)
        assert all(x==0 for x in bb[-patch_len:])
        bb[12+patch_len:] = bb[12:-patch_len]
        bb[12:12+patch_len] = ntsc_patch_code
    bb[4:8] = bytearray(4)
    bb[4:8] = struct.pack('>I', checksum(bb)^0xffffffff)
    f.seek(0)
    f.write(bb)

if __name__ == "__main__":
    main(sys.argv)

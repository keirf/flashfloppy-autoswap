# crack_atlantis.py
#
# Patches the Fate of Atlantis resource file atlantis.001 to accept any
# response to the manual protection.
#
# Thanks to http://sed.free.fr who provided the method and original C
# source code! Also to JOTD/WHDLoad where I discovered this method.
#
# Written & released by Keir Fraser <keir.xen@gmail.com>
#
# This is free and unencumbered software released into the public domain.
# See the file COPYING for more details, or visit <http://unlicense.org>.

import struct, sys, random


# We look for:
# c8 f4 00 d3 00 19 00 c8 f5 00 d4 00 12 00 c8 f6 00 d5 00 0b 00
# which corresponds to:
#     [0040] (C8)     if (Var[244] == Var[211]) {
#     [0047] (C8)       if (Var[245] == Var[212]) {
#     [004E] (C8)         if (Var[246] == Var[213]) {
# and replace 211 by 244, 212 by 245 and 213 by 246 so that the test
# passes whatever the user sets as response to the question.
# NB. The resource file is XOR-0x69, hence the search string also is XORed.
needle = bytearray([0xa1,0x9d,0x69,0xba,0x69,0x70,0x69,0xa1,0x9c,0x69,
                    0xbd,0x69,0x7b,0x69,0xa1,0x9f,0x69,0xbc,0x69,0x62,0x69])

def main(argv):
    if len(argv) != 2:
        print("%s <file>" % argv[0])
        return
    dat = bytearray(open(argv[1], "rb").read())
    offset = dat.find(needle)
    dat[offset+3] = dat[offset+1]
    dat[offset+3+7] = dat[offset+1+7]
    dat[offset+3+7+7] = dat[offset+1+7+7]
    open(argv[1], "wb").write(dat)
    
if __name__ == "__main__":
    main(sys.argv)

PREFIX = m68k-amigaos-
CC = $(PREFIX)gcc
AS = $(PREFIX)as
PYTHON = python3

CFLAGS += -MMD -MF .$(@F).d
DEPS = .*.d

CFLAGS += -nostdlib -fno-builtin -I..
CFLAGS += -Os -m68000 -Wall -Werror -std=gnu99 -msoft-float
#CFLAGS += -msmall-code
#CFLAGS += -DDEBUG
LDFLAGS += $(CFLAGS) -s
AFLAGS += $(CFLAGS) -D__ASSEMBLY__ -Wa,--register-prefix-optional
AFLAGS += -Wa,-l -Wa,--bitwise-or -Wa,--base-size-default-16
AFLAGS += -Wa,--disp-size-default-16 -Wa,--pcrel

TARGET = SteelSky-FFAS
VER = v1.5
NAME_PREFIX = SteelSky - 

all: bass_00.adf
	rm -rf $(TARGET)*
	mkdir -p $(TARGET)
	xdftool "$(TARGET)/$(NAME_PREFIX)Save.adf" format "disk_save"
	xdftool "$(TARGET)/$(NAME_PREFIX)Save.adf" write advisor
	cp $< "$(TARGET)/$(NAME_PREFIX)01.adf"
	cp Orig/bass_01.adf "$(TARGET)/$(NAME_PREFIX)02.adf"
	cp Orig/bass_02.adf "$(TARGET)/$(NAME_PREFIX)03.adf"
	cp Orig/bass_03.adf "$(TARGET)/$(NAME_PREFIX)04.adf"
	cp Orig/bass_04.adf "$(TARGET)/$(NAME_PREFIX)05.adf"
	cp Orig/bass_05.adf "$(TARGET)/$(NAME_PREFIX)06.adf"
	cp Orig/bass_06.adf "$(TARGET)/$(NAME_PREFIX)07.adf"
	cp Orig/bass_07.adf "$(TARGET)/$(NAME_PREFIX)08.adf"
	cp Orig/bass_08.adf "$(TARGET)/$(NAME_PREFIX)09.adf"
	cp Orig/bass_09.adf "$(TARGET)/$(NAME_PREFIX)10.adf"
	cp Orig/bass_10.adf "$(TARGET)/$(NAME_PREFIX)11.adf"
	cp Orig/bass_11.adf "$(TARGET)/$(NAME_PREFIX)12.adf"
	cp Orig/bass_12.adf "$(TARGET)/$(NAME_PREFIX)13.adf"
	cp Orig/bass_13.adf "$(TARGET)/$(NAME_PREFIX)14.adf"
	cp Orig/bass_14.adf "$(TARGET)/$(NAME_PREFIX)15.adf"
	cp 00-README.txt $(TARGET)/.
	zip -r $(TARGET)-$(VER).zip $(TARGET)

bass_00.adf: Orig/bass_00.adf ../atlantis/Orig/atlantis_01.adf bass_autoswap bass_fixes
	rm -rf disk_15* atlantis1*
	xdftool Orig/bass_00.adf unpack .
	xdftool ../atlantis/Orig/atlantis_01.adf unpack .
	dd if=../shared/addchip.bootblock.bin.68k of=disk_15.bootcode bs=1 skip=12 count=1012
	mkdir disk_15/c
	cp atlantis1/c/echo disk_15/c/.
	cp bass_autoswap disk_15/c/.
	sed -e 's/df0/echo "Beneath a Steel Sky: FlashFloppy AutoSwap $(VER)"\nc:bass_autoswap\ndf0/' -i disk_15/s/startup-sequence
	$(PYTHON) ../shared/hunk_cat.py -o SteelSky bass_fixes disk_15/SteelSky
	$(PYTHON) ../pack/pack_exe.py SteelSky SteelSky.pack
	rm -rf SteelSky
	mv SteelSky.pack disk_15/SteelSky
	rm -rf $@
	xdftool $@ pack disk_15
	rm -rf disk_15* atlantis1*
	$(PYTHON) ../shared/bootblock_fix.py --ntsc-patch $@

bass_autoswap: bass_autoswap_1 bass_autoswap_2
	$(PYTHON) ../shared/hunk_cat.py -o $@ $^
	$(PYTHON) ../shared/mk_chip_exe.py $@

bass_autoswap_1: bass_autoswap_entry.o
	$(CC) -o $@ $^ $(LDFLAGS)

bass_autoswap_2: bass_autoswap.o libnix.o crc.o
	$(CC) -o $@ $^ $(LDFLAGS)

bass_fixes: bass_fixes.o
	$(CC) -o $@ $^ $(LDFLAGS)
	$(PYTHON) ../shared/mk_chip_exe.py $@

libnix.c: ../shared/libnix.c
	ln -sf $< $@

crc.c: ../shared/crc.c
	ln -sf $< $@

bass_autoswap_entry.S: ../shared/amigados_autoswap_entry.S
	ln -sf $< $@

%.o: %.S
	$(CC) -o $@ -c $< $(AFLAGS)

%.o: %.c
	$(CC) -o $@ -c $< $(CFLAGS)

clean:
	rm -rf *.o *.adf bass_autoswap $(DEPS) $(TARGET)* bass_autoswap_* crc.c libnix.c disk_15* atlantis1*

DRIVE ?= /dev/sdb1
write: all
	sudo mount $(DRIVE) /mnt
	sudo rm -rf /mnt/$(TARGET)
	sudo cp -r $(TARGET) /mnt/.
	echo -n "$(TARGET)/$(NAME_PREFIX)01.adf" >IMAGE_A.CFG
	sudo cp IMAGE_A.CFG /mnt/.
	rm -f IMAGE_A.CFG
	sudo umount /mnt
	sudo fatsort $(DRIVE)

.PHONY: all clean write

-include $(DEPS)

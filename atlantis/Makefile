PREFIX = m68k-amigaos-
CC = $(PREFIX)gcc
AS = $(PREFIX)as
PYTHON = python

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

TARGET = FateOfAtlantis-FFAS
VER = v1.1
NAME_PREFIX = Atlantis - 

all: atlantis_01.adf
	rm -rf $(TARGET)*
	mkdir -p $(TARGET)
	xdftool "$(TARGET)/$(NAME_PREFIX)Save.adf" format "atlantis0"
	cp $< "$(TARGET)/$(NAME_PREFIX)01.adf"
	cp AtlantisOrig/atlantis_02.adf "$(TARGET)/$(NAME_PREFIX)02.adf"
	cp AtlantisOrig/atlantis_03.adf "$(TARGET)/$(NAME_PREFIX)03.adf"
	cp AtlantisOrig/atlantis_04.adf "$(TARGET)/$(NAME_PREFIX)04.adf"
	cp AtlantisOrig/atlantis_05.adf "$(TARGET)/$(NAME_PREFIX)05.adf"
	cp AtlantisOrig/atlantis_06.adf "$(TARGET)/$(NAME_PREFIX)06.adf"
	cp AtlantisOrig/atlantis_07.adf "$(TARGET)/$(NAME_PREFIX)07.adf"
	cp AtlantisOrig/atlantis_08.adf "$(TARGET)/$(NAME_PREFIX)08.adf"
	cp AtlantisOrig/atlantis_09.adf "$(TARGET)/$(NAME_PREFIX)09.adf"
	cp AtlantisOrig/atlantis_10.adf "$(TARGET)/$(NAME_PREFIX)10.adf"
	cp AtlantisOrig/atlantis_11.adf "$(TARGET)/$(NAME_PREFIX)11.adf"
	cp 00-README.txt $(TARGET)/.
	zip -r $(TARGET)-$(VER).zip $(TARGET)

atlantis_01.adf: AtlantisOrig/atlantis_01.adf atlantis_autoswap_setpatch atlantis_autoswap
	xdftool AtlantisOrig/atlantis_01.adf unpack .
	rm -f atlantis1/*nstall* atlantis1/.info atlantis1/c/iconx
	rm -f atlantis1/c/*.info atlantis1/*.info atlantis1/c/ask
	cp atlantis_autoswap_setpatch atlantis1/c/.
	cp atlantis_autoswap atlantis1/c/.
	sed -e 's/stack/echo "Atlantis FlashFloppy AutoSwap $(VER)"\nc:atlantis_autoswap_setpatch\nstack/' -i atlantis1/s/startup-sequence
	$(PYTHON) ./crack_atlantis.py atlantis1/atlantis.001
	rm -rf $@
	xdftool $@ pack atlantis1
	rm -rf atlantis1*

atlantis_autoswap_setpatch: atlantis_autoswap_setpatch.o
	$(CC) -o $@ $^ $(LDFLAGS)

atlantis_autoswap: atlantis_autoswap_entry.o atlantis_autoswap.o libnix.o crc.o
	$(CC) -o $@ $^ $(LDFLAGS)

libnix.c: ../shared/libnix.c
	ln -sf $< $@

crc.c: ../shared/crc.c
	ln -sf $< $@

%.o: %.S
	$(CC) -o $@ -c $< $(AFLAGS)

%.o: %.c
	$(CC) -o $@ -c $< $(CFLAGS)

clean:
	rm -rf *.o *.adf atlantis_autoswap_setpatch atlantis_autoswap startup-sequence atlantis1* $(DEPS) $(TARGET)*

write: all
	sudo mount /dev/sdd1 /mnt
	sudo rm -rf /mnt/$(TARGET)
	sudo cp -r $(TARGET) /mnt/.
	echo -n "$(TARGET)/$(NAME_PREFIX)01.adf" >IMAGE_A.CFG
	sudo cp IMAGE_A.CFG /mnt/.
	rm -f IMAGE_A.CFG
	sudo umount /mnt
	sudo fatsort /dev/sdd1

.PHONY: all clean write

-include $(DEPS)

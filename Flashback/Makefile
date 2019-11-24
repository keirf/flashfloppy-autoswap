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

TARGET = FlashBackADF
VER = v1.0
NAME_PREFIX = flashback

all: Flashback_Disk1.adf
	rm -rf $(TARGET)*
	mkdir -p $(TARGET)
	cp $< "$(TARGET)/$(NAME_PREFIX)01.adf"
	cp Orig/Flashback_Disk2.adf "$(TARGET)/$(NAME_PREFIX)02.adf"
	cp Orig/Flashback_Disk3.adf "$(TARGET)/$(NAME_PREFIX)03.adf"
	cp Orig/Flashback_Disk4.adf "$(TARGET)/$(NAME_PREFIX)04.adf"
	zip -r $(TARGET)-$(VER).zip $(TARGET)

Flashback_Disk1.adf: Orig/Flashback_Disk1.adf flash_autoswap
	rm -rf flashback\ disk\ 1*
	xdftool Orig/Flashback_Disk1.adf unpack .
	cp flash_autoswap flashback\ disk\ 1/.

	sed -i '1s/^/flash_autoswap\n/' flashback\ disk\ 1/s/startup-sequence
	rm -rf $@
	rm flashback\ disk\ 1/InstallScript
	rm flashback\ disk\ 1/InstallFlashback
	rm flashback\ disk\ 1/InstallFlashback.info
	xdftool $@ pack flashback\ disk\ 1
	rm -rf flashback\ disk\ 1*

flash_autoswap: flash_autoswap_1 flash_autoswap_2
	$(PYTHON) ../shared/hunk_cat.py -o $@ $^

flash_autoswap_1: flash_autoswap_entry.o
	$(CC) -o $@ $^ $(LDFLAGS)

flash_autoswap_2: flash_autoswap.o libnix.o crc.o
	$(CC) -o $@ $^ $(LDFLAGS)

libnix.c: ../shared/libnix.c
	ln -sf $< $@

crc.c: ../shared/crc.c
	ln -sf $< $@

flash_autoswap_entry.S: ../shared/amigados_autoswap_entry.S
	ln -sf $< $@

%.o: %.S
	$(CC) -o $@ -c $< $(AFLAGS)

%.o: %.c
	$(CC) -o $@ -c $< $(CFLAGS)

clean:
	rm -rf *.o *.adf flashback* flash_autoswap startup-sequence Flashback_Disk1* $(DEPS) $(TARGET)* flash_autoswap_* crc.c libnix.c

write: all
	sudo mount /dev/sdb1 /mnt
	sudo rm -rf /mnt/$(TARGET)
	sudo cp -r $(TARGET) /mnt/.
	echo -n "$(TARGET)/$(NAME_PREFIX)01.adf" >IMAGE_A.CFG
	sudo cp IMAGE_A.CFG /mnt/.
	rm -f IMAGE_A.CFG
	sudo umount /mnt
	sudo fatsort /dev/sdb1

.PHONY: all clean write

-include $(DEPS)

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

TARGET = MortalKombat-FFAS
VER = v1.2
NAME_PREFIX = MortalKombat - 

all: mk_0.adf
	rm -rf $(TARGET)*
	mkdir -p $(TARGET)
	cp $< "$(TARGET)/$(NAME_PREFIX)0.adf"
	cp FL_Crack/mk_01.adf "$(TARGET)/$(NAME_PREFIX)1.adf"
	cp FL_Crack/mk_02.adf "$(TARGET)/$(NAME_PREFIX)2.adf"
	cp 00-README.txt $(TARGET)/.
	zip -r $(TARGET)-$(VER).zip $(TARGET)

mk_0.adf: FL_Crack/mk_03.adf mk_fix.py bootblock_patch main_patch
	cp -f $< $@
	$(PYTHON) mk_fix.py $@ bootblock_patch main_patch "$(VER)"
	$(PYTHON) ../shared/bootblock_fix.py $@

main_patch: main_patch.o
	$(PYTHON) ../shared/hunk_strip.py $< $@

bootblock_patch: bootblock_patch.o
	$(PYTHON) ../shared/hunk_strip.py $< $@

%.o: %.S
	$(CC) -o $@ -c $< $(AFLAGS)

%.o: %.c
	$(CC) -o $@ -c $< $(CFLAGS)

clean:
	rm -rf *.o *.adf bootblock_patch main_patch $(DEPS) $(TARGET)*

DRIVE ?= /dev/sdb1
write: all
	sudo mount $(DRIVE) /mnt
	sudo rm -rf /mnt/$(TARGET)
	sudo cp -r $(TARGET) /mnt/.
	echo -n "$(TARGET)/$(NAME_PREFIX)0.adf" >IMAGE_A.CFG
	sudo cp IMAGE_A.CFG /mnt/.
	rm -f IMAGE_A.CFG
	sudo umount /mnt
	sudo fatsort $(DRIVE)

.PHONY: all clean write

-include $(DEPS)

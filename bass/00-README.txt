Beneath a Steel Sky: FlashFloppy AutoSwap v1.3
==============================================
-- Keir Fraser, 1st February 2019

Introduction
------------

This version of the game is patched to swap disks automatically when
used with a Gotek programmed with FlashFloppy >= v1.0.

Getting Started
---------------

The simplest method is to copy the whole distribution folder as-is to
your USB drive.

If you directly select images using LCD/OLED screen you can now
navigate to disk 1 and all further disk changes will be automatic.

If you use the Autoboot file selector you must assign all disks,
including the save-game disk, to slots -- the exact slot numbers do
not matter. You can now start the game by navigating to the slot for
disk 1.

Normal game requests for a disk change are mostly suppressed. Any
which do appear ("Insert xx" box in the middle of the screen) can be
ignored, simply left click to continue and the change will happen
automatically.

1MB Amigas
-----------

Steel Sky requires at least 1MB to run, however this is very tight and
there are limitations imposed for A500/2000 with only 512k chip
memory: Specifically, the game will run from the internal drive only
(DF0), and requires Kickstart 1.2 or 1.3.

External Drives
---------------

The default setup disables external drives to reclaim chip memory. If
you wish to boot from an external drive (Kickstart 2 or later!) and
have at least 1MB chip memory (A500+/A600/A1200/etc), you will need to
install an ordinary bootblock on Disk 1. This can be done from
AmigaDOS CLI or Shell: eg. "INSTALL DF0:" with Disk 1 mounted in DF0.

Renaming Disk Images
--------------------

If you do not like the default names for the disk images they may be
changed, with some restrictions. All the images must have the same
name pattern (eg. "SteelSky (%).adf") where % is the 2-digit
disk number or "Save" for the save-game disk:
"SteelSky (01).adf", "SteelSky (Save).adf", and so on.

Load / Save
-----------

A blank save disk is included in this distribution, and will be
mounted automatically when you select "Load" or "Save" within the
Load/Save requester. The message at the top of the requester to
manually insert the save disk should be ignored.

If you wish to use your own save-game disk, you must replace the
provided one, using the same image name, and the AmigaDOS disk label
*must* be "disk_save". You can use the RELABEL command in the Amiga
Shell/CLI to set the disk label.

Feedback / Bug Reports
----------------------

Send to the Facebook group (https://www.facebook.com/flashfloppy) or
raise an issue on Github (https://github.com/keirf/FlashFloppy).

Special Thanks
--------------

Thanks to:
 - ross/EAB for the special bootblock to reclaim chip memory
   on 512+512k systems!
 - JOTD/WHDLoad for his fixes and crack which I brazenly stole
   for this release!

Mortal Kombat: FlashFloppy AutoSwap v1.2
========================================
-- Keir Fraser, 22nd June 2020

Introduction
------------

This version of the game is patched to swap disks automatically when
used with a Gotek programmed with FlashFloppy >= v1.0.

Other features:
 * Boot from external Gotek (requires Kickstart v2 or later)
 * Approx 2x faster load times
 * Bug fixes

Getting Started
---------------

The simplest method is to copy the whole distribution folder as-is to
your USB drive.

If you directly select images using LCD/OLED screen you can now
navigate to disk 0 and all further disk changes will be automatic.

If you use the Autoboot file selector you must assign all disks,
including the save-game disk, to slots -- the exact slot numbers do
not matter. You can now start the game by navigating to the slot for
disk 0.

Normal game requests for a disk change are suppressed: Do NOT
manually eject or swap disk images during play!

Renaming Disk Images
--------------------

If you do not like the default names for the disk images they may be
changed, with some restrictions. All the images must have the same
name pattern (eg. "MortalKombat (%).adf") where % is the 2-digit
disk number: "MortalKombat (0).adf", "MortalKombat (1).adf", and
so on.

Feedback / Bug Reports
----------------------

Send to the Facebook group (https://www.facebook.com/flashfloppy) or
raise an issue on Github (https://github.com/keirf/FlashFloppy).

Special Thanks
--------------

Thanks to NOMAD/Fairlight for the original crack.

Flashback: FlashFloppy AutoSwap 
=================================================================

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

Orginal files need to be i Orig folder. This build removed install files on Disk 1
due to lack of required space.


lash_autoswap.c configuration
amigados.autoswap.c was modified to skip on duplicate files. There are the same files
on different disks, I assume it was made to decrease amount of disk swaps. Those
files are very unliekly to trigger disk swap routine, therefore on those patch need
to skip those files and just attempt to read them from current location.



# AutoSwap Game Patches for FlashFloppy

This project is cross-compiled on an x86 Ubuntu Linux system. However
other similar Linux-base systems (or a Linux virtual environment on
another OS) can likely be made to work quite easily.

## Original Disk Images

Each patched title requires the original disk images. The exact naming is
described for each title below:

### Monkey Island 2

The Kixx release (manual protection removed) is recommended, as the
AutoSwap patch does not include a crack. This can be found on the EAB
FTP server or Google Drive, and simply be unzipped as-is into the
**monkey2/** folder in this Git repository.

### Indiana Jones and the Fate of Atlantis

The original release is okay to use, as the AutoSwap patch includes a
crack for the manual protection. The original images can be found in
the SPS IPF library (number 851) but will require converting to ADF
format using HxC software or
[disk-analyse](https://www.github.com/keirf/Disk-Utilities).  The ADF
images should be copied to the folder **atlantis/Orig/** in
this Git repository. The ADF files should be named
atlantis_01.adf, atlantis_02.adf, and so on.

## Building

You must build and install bebbo's GCC v6 port for Amiga.  GCC has
prerequisites that are listed in the
[README](https://github.com/bebbo/amiga-gcc/blob/master/README.md),
along with instructions on how to install them in various
environments.  The build can be done to a private path in your home
directory, for example:
```
 # cd $HOME
 # mkdir -p install
 # git clone https://github.com/bebbo/amiga-gcc
 # cd amiga-gcc ; make update
 # make all -j8 PREFIX=$HOME/install
```

The compiler must be on your PATH when building other prerequisites
and the game patches themselves:
```
 # export PATH=$HOME/install/bin:$PATH
```

A further requirement is my Amiga file packer. This can be built
in a local folder and does not require full installation:
```
 # git clone https://github.com/keirf/Amiga-Stuff.git
 # cd Amiga-Stuff/inflate && make
```

You will also require Python v3.

## Building All Targets

Install prerequisites as above. Then:
```
 # git clone https://github.com/keirf/FF_AutoSwap.git
 # cd FF_AutoSwap
 # ln -s path/to/Amiga-Stuff/inflate pack
 # make
```

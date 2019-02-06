
# AutoSwap Game Patches for FlashFloppy
## Build Instructions

This project is cross-compiled on an x86 Ubuntu Linux system. However
other similar Linux-base systems (or a Linux virtual environment on
another OS) can likely be made to work quite easily.

## Prerequisites

### GCC v6 Cross Compiler

Build and install bebbo's GCC v6 port for Amiga.  GCC has
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

### Python v3 and packages

Install Python v3 and the `crcmod` package. These can be
installed on Ubuntu as follows:
```
 # sudo apt install python3 python3-pip
 # pip3 install --user crcmod
```

### File packer

Build and install my Amiga file packer. This can be built in a local
folder and does not require full installation:
```
 # git clone https://github.com/keirf/Amiga-Stuff.git
 # cd Amiga-Stuff/inflate && make
```

### xdftool: ADF image manipulation

This requires Python, and the package itself can be installed via
Python PIP. On Ubuntu for example:
```
 # sudo apt install python python-pip
 # pip install --user amitools
```

### disk-analyse: Disk image transcoding

If you are going to convert IPF images to ADF (see **Installing
original disk images**, below) using my disk analyser, this must first
be installed. Follow the instructions
[here](https://www.github.com/keirf/Disk-Utilities/blob/master/README.md),
paying particular attention to the section **IPF & CT Raw support**.

IPF images can then be converted to ADF by:
```
 # disk-analyse in.ipf out.adf
```

## Creating the build tree

Install prerequisites as above. Then:
```
 # git clone https://github.com/keirf/FF_AutoSwap.git
 # cd FF_AutoSwap
 # ln -s path/to/Amiga-Stuff/inflate pack
```

## Installing original disk images

Each patched title requires the original disk images. The appropriate
images can usually be found in the SPS IPF library (reference numbers
indicated below) but will require converting to ADF format using HxC
software or [disk-analyse](https://www.github.com/keirf/Disk-Utilities). 
The required exact location and naming of ADF files is described for
each title below:

### Beneath a Steel Sky

**SPS IPF 207**. The ADF images should be copied to the folder
**bass/Orig/** in this Git repository. The ADF files should be named
bass_00.adf, bass_01.adf, and so on.

### Indiana Jones and the Fate of Atlantis

**SPS IPF 851**. The ADF images should be copied to the folder
**atlantis/Orig/** in this Git repository. The ADF files should be
named atlantis_01.adf, atlantis_02.adf, and so on.

### Secret of Monkey Island (Monkey Island 1)

**SPS IPF 1625**. The ADF images should be copied to the
folder **monkey1/Orig/** in this Git repository. The ADF files should
be named mi_01.adf, mi_02.adf, and so on.

### Monkey Island 2

The Kixx release (manual protection removed) is recommended, as the
AutoSwap patch does not include a crack. This can be found on the EAB
FTP server or Google Drive, and simply be unzipped as-is into the
**monkey2/** folder in this Git repository:
**monkey2/MonkeyIsland2Kixx/MonkeyIsland2Disk1.adf** and so on.

## Building everything

With everything set up, building the set of patched game titles for
distribution is as simple as:
```
 # cd FF_AutoSwap
 # make dist
```

## Building one title

If you wish to build only one title then run make from the title's subfolder. For example:
```
 # cd monkey1 && make
```

#### Important Note

* *Beneath a Steel Sky* and *Secret of Monkey Island* depend on Disk 1
of *Indiana Jones and the Fate of Atlantis*. This must be installed
at **atlantis/Orig/atlantis_01.adf** to successfully build these
titles.

## Credits

Thanks are due to:

* **JOTD / WHDLoad** For his fixes and cracks, which I frequently borrowed
in outline or literally lifted into my own patches.

* **ross / EAB** For his *addchip* bootblock which reclaims valuable chip
memory for larger titles on 512kB chip systems.

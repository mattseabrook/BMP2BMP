# BMP2BMP

This software repository contains a utility that will extract the sprites from **Star Trek: 25th Anniversary** or **Star Trek: Judgment Rites**, both early 90's Point-and-Click Adventure games from Interplay Productions

## 2005

This folder contain's Denis Oezmen's original Borland Delphi 7 project, intact. If you have access to an Abandonware setup, this compiles and works out-of-the-box. The only addition is a README.md file I created to place all of Denis' original notes and commentary related to this utility from the XenTaX forum, Google, etc.

## 2021

Here is my updated version of the utility that compiles with **fpc**. A slight change was made to the code to enable the Alpha Channel of each Bitmap, in hopes that this is the first step towards community made mods, or fan-made games. 

### Getting Started

1. Download & clone this repository: `git clone x`
2. Build a new `trekext2` and `bmp2bmp` executables by running: `make all`
3. Binary is located in `build/`, and the objects and other files generated from source are located in `src/`
4. Verify `trekext2` and `bmp2bmp` exist in `build/`

#### Usage
 
1. Copy `PALETTE.PAL` and any matching set(s) of `*.DIR` and `*.001` files you want from either game directory, to wherever you want to run this operation (Don't run it in the game directory.)
2. First, use `trekext2` to extract the individual bitmaps from Interplay's LZSS compressed archive file: `trekext2 x.DIR y.001`.
3. Next, run `bmp2bmp *.bmp` to convert each `*.bmp` file to a standard "Windows" bitmap file format.

```bash
#!/bin/bash

# Build new execs of TREKEXT2 and BMP2BMP, then change dir to the build directory
make all && cd build

# Use TREKEXT2 to LZSS decompress the Interplay archives into individual *.bmp files
#   where (x) is the *.DIR file, and (y) is the corresponding *.001 file
./trekext2 x.DIR y.001

# Use BMP2BMP to convert the *.bmp files from above, into standard Windows format
./bmp2bmp *.bmp
```
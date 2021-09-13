Copyright (C) 2001-2006 Deniz Oezmen (http://oezmen.eu/)

All trademarks and copyrights mentioned implicitly or explicitly in this file or
the software described below are property of their respective owners.

# BMP2BMP

Converts BMP images into the standard Windows bitmap format.

```
Usage:  BMP2BMP <BMPFiles>

        BMPFiles        Specifies the BMP files to be converted. Wildcards are
                        allowed.
```

## Star Trek 25th BMP specifications

**Format Type**: Bitmap image
**Endian Order**: Little Endian

```
uint16 {2}   - X Coordinate Offset
uint16 {2}   - Y Coordinate Offset
uint16 {2}   - Image Width
uint16 {2}   - Image Height

byte {X}     - Image Data
```

## Notes and Comments

- In most cases the coordinate offset values tell the game where the bitmap has to be placed on screen (compared to the top left corner). Sometimes, the high bits of this values are set, resulting in abnormally high offsets. The reason for this is not yet known, it might be related to the need of relative offsets in the course of playing animation (ANM) files.
- An external palette (PAL) is needed to view or convert these images.
- The image data is ordered from the top left to the bottom right, line-wise.

# TREKEXT2

Extracts files from DIR/001 archives.

```
Usage:  TREKEXT2 <DIRFile> <001File>

        DIRFile         Specifies the DIR file to be processed.
        001File         Specifies the 001 archive file.
```
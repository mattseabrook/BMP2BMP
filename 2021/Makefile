all: trekext2 bmp2bmp

trekext2:
	mkdir -p build
	fpc -MDELPHI -o"build/trekext2" trekext2/trekext2.pas
	mkdir -p src
	mv build/*.o src && mv build/*.ppu src
bmp2bmp:
	mkdir -p build
	fpc -MDELPHI -o"build/bmp2bmp" bmp2bmp.dpr 
	mkdir -p src
	mv build/*.o src
	mv build/*.ppu src && mv build/*.rsj src
clean:
	rm -rf src && rm -rf build

.PHONY: all trekext2 bmp2bmp clean
{ File   : BMP2BMP.dpr
  Author : Deniz Oezmen
  Created: 2005-05-17, based on TREKBMPV.PAS created ~2001
  Changed: 2005-10-08

  Star Trek: 25th Anniversary/Judgment Rites BMP converter.
}
program BMP2BMP;

{$APPTYPE CONSOLE}

uses
  SysUtils, StrUtils, SaveBMP2;

type
  TBMPHeader = packed record
                 Unknown1: array[0..1] of Char;
                 Unknown2,
                 Width,
                 Height  : Word
               end;

  TBuffer    = array of Byte;

var
  BMPFile  : file;
  BMPHeader: TBMPHeader;
  Palette3 : TPalette3;

function Prefix(FileName: string): string;
var
  i: Longint;
begin
  FileName := ExpandFileName(FileName);

  i := Length(FileName) + 1;
  repeat
    Dec(i)
  until (i = 0) or (PosEx('.', FileName, i) > 0);

  if (i = 0) or (PosEx('\', FileName, i + 1) > 0) then
    Result := FileName
  else
    Result := Copy(FileName, 1, i - 1)
end;

function OpenBMPFile(var BMPFile: file; BMPName: string): Boolean;
begin
  FileMode := fmShareDenyWrite;
  AssignFile(BMPFile, BMPName);

  {$I-}
  Reset(BMPFile, 1);
  {$I+}
  OpenBMPFile := (IOResult = 0)
end;

function ReadHeader(var BMPHeader: TBMPHeader): Boolean;
var
  BytesRead: Longword;
begin
  BlockRead(BMPFile, BMPHeader, SizeOf(TBMPHeader), BytesRead);

  // make sure (among other factors) we don't read a "genuine" BMP
  Result := (BytesRead = SizeOf(TBMPHeader)) and
    (BMPHeader.Unknown1 <> 'BM') and (BMPHeader.Width * BMPHeader.Height +
      SizeOf(TBMPHeader) = FileSize(BMPFile))
end;

procedure ConvertPalette3(var Palette3: TPalette3);
var
  i, j: Byte;
begin
  for i := 0 to 255 do
    with Palette3[i] do
    begin
      (* expand values and swap R/B *)
      j := R;
      R := B shl 2;
      G := G shl 2;
      B := j shl 2
    end
end;

function ReadPalette(PALName: string): Boolean;
var
  PALFile  : file;
  BytesRead: Longword;
begin
  Writeln('Reading palette');

  AssignFile(PALFile, PALName);
  {$I-}
  Reset(PALFile, 1);
  {$I+}
  if IOResult <> 0 then
  begin
    Writeln('Could not open palette.');
    ReadPalette := False;
    Exit
  end;

  BlockRead(PALFile, Palette3, SizeOf(TPalette3), BytesRead);

  if BytesRead < SizeOf(TPalette3) then
  begin
    Writeln('Palette file invalid.');
    ReadPalette := False;
    Exit
  end;

  ConvertPalette3(Palette3);

  Close(PALFile);

  ReadPalette := True
end;

procedure ConvertBMP(BMPName: string);
var
  Buffer   : TBuffer;
  BufSize,
  BytesRead: Longword;
begin
  Writeln('Converting ', BMPName);

  BufSize := BMPHeader.Width * BMPHeader.Height;
  SetLength(Buffer, BufSize);

  BlockRead(BMPFile, Buffer[0], BufSize, BytesRead);
  BMPName := Prefix(BMPName) + '#.bmp';

  Dump8BitBMP(BMPName, BMPHeader.Width, BMPHeader.Height, Palette3, Buffer);

  Finalize(Buffer);
end;

procedure ParseFiles(FilePara: string);
var
  DirPos,
  i        : Byte;
  FileName,
  Dir,
  BMPName  : string;
  SearchRec: TSearchRec;
  PFilePara: PChar;
begin
  GetMem(PFilePara, Length(FilePara) + 1);
  StrPCopy(PFilePara, FilePara);

  // get the directory information from FilePara
  DirPos := 0;
  for i := 1 to Length(FilePara) do
    if FilePara[i] in [':', '\'] then
      DirPos := i;

  Dir := Copy(FilePara, 1, DirPos);

  // search for all files matching FilePara
  if FindFirst(PFilePara, faAnyFile - faDirectory - faVolumeID,
    SearchRec) = 0 then
  begin
    repeat
      FileName := SearchRec.Name;
      BMPName := Dir + FileName;

      // if this file is accessible, analyze it
      if OpenBMPFile(BMPFile, BMPName) then
        if ReadHeader(BMPHeader) then
        begin
          ConvertBMP(FileName);
          Close(BMPFile)
        end
        else
          Writeln(BMPName, ' is not a valid ("Trek") BMP file.')
      else
        Writeln(BMPName, ' not accessible')
    until FindNext(SearchRec) <> 0
  end
  else
    Writeln(FilePara, ' not found');
  FreeMem(PFilePara, Length(FilePara) + 1)
end;

begin
  if ParamCount = 2 then
  begin
    if ReadPalette(ParamStr(2)) then
      ParseFiles(ParamStr(1))
  end
  else
    Writeln('Incorrect number of parameters.')
end.

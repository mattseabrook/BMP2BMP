{ File   : TREKBMP3.PAS
  Author : Deniz Oezmen
  Created: 2001-09-12
  Changed: 2005-08-26

  Star Trek: 25th Anniversary/Judgment Rites DIR/001 extractor.
}
program TrekCDExtractor;
{$M $8000,$0,$0} (* give me stack! *)

uses
  TypeChg2;

type
  TFileEntry = record
                 FileName: array[1..8] of Char;
                 FileSuff: array[1..3] of Char;
                 FileOffs: array[1..3] of Byte
               end;

  TFileEntries = array[1..2048] of TFileEntry;

var
  DirFile    : file of TFileEntry;
  DataFile   : file;
  FileEntries: TFileEntries;
  FileEntry  : TFileEntry;
  i, j       : Integer;
  NrFiles    : Integer;
  CurDest    : file;
  LastOffs,
  LastSize   : Longint;
  FilesToDo  : Byte;

  Stat_BytesRead,
  Stat_BytesWritten,
  Stat_FilesExtracted: Longint;

function CheckCommandLine: Boolean;
begin
  CheckCommandLine := (ParamCount > 1)
end;

function OpenFiles: Boolean;
begin
  {$I-}
  Assign(DirFile, ParamStr(1));
  Reset(DirFile);
  {$I+}
  if IOResult = 0 then
  begin
    {$I-}
    Assign(DataFile, ParamStr(2));
    Reset(DataFile, 1);
    {$I+}
    OpenFiles := (IOResult = 0)
  end
  else
    OpenFiles := False
end;

function GetFileOffset(FE: TFileEntry): Longint;
begin
  GetFileOffset := Longint(FE.FileOffs[1]) +
                   Longint(FE.FileOffs[2]) * 256 +
                   Longint(FE.FileOffs[3]) * 256 * 256
end;

procedure CreateFile(var FE: TFileEntry);
var
  FName: string;
  c    : Char;
  i    : Integer;
begin
  FName := '';

  c := #255;
  i := 1;
  while (c <> #000) and (i < 9) do
  begin
    c := FE.FileName[i];
    if c <> #000 then FName := FName + c;
    Inc(i)
  end;

  if FilesToDo <> 0 then
  begin
    Inc(FName[Length(FName)]);
    Inc(FE.FileName[Length(FName)])
  end;

  FName := FName + '.';

  c := #255;
  i := 1;
  while (c <> #000) and (i < 4) do
  begin
    c := FE.FileSuff[i];
    if c <> #000 then FName := FName + c;
    Inc(i)
  end;

  Write(FName);

  Assign(CurDest, FName);
  Rewrite(CurDest, 1)
end;

procedure ExtractFile(FEntry: TFileEntry);
const
  N         = 4096;
  THRESHOLD = 2;
var
  HisBuf      : array[0..N - 1] of Byte;
  ClearBuf,
  MultFiles   : Boolean;
  BufReadPtr,
  BufWrtPtr,
  i, j        : Integer;
  b,
  Length,
  Tag         : Byte;
  CompSize,
  UnCompSize,
  BytesRead,
  BytesWritten,
  Offset,
  FOffs       : Longint;
begin
  for i := 1 to sizeof(HisBuf) do
    HisBuf[i] := 0;
  BufWrtPtr := 0;
  BytesRead := 0;
  BytesWritten := 0;
  CompSize := 0;
  UnCompSize := 0;
  if FilesToDo = 0 then
  begin
    FOffs := GetFileOffset(FEntry);
    MultFiles := FOffs < 130 * 256 * 256;
    if not MultFiles then
    begin
      FilesToDo := FOffs shr 16 - 129;
      FOffs := LastOffs + LastSize + 4
    end
  end
  else
  begin
    Dec(FilesToDo);
    FOffs := LastOffs + LastSize + 4;
    MultFiles := False
  end;
  Seek(DataFile, FOffs);
  if not MultFiles then
  begin
    BlockRead(DataFile, b, 1);
    if FOffs MOD 2 <> 0 then
      Inc(FOffs)
    else
      Seek(DataFile, FilePos(DataFile) - 1)
  end;
  LastOffs := FOffs;
  BlockRead(DataFile, UnCompSize, 2);
  BlockRead(DataFile, CompSize, 2);
  LastSize := CompSize;
  Write(' @ ', FOffs, ' from ', CompSize, ' to ', UnCompSize, ' ... ');
  while BytesRead < CompSize do
  begin
    Tag := 0;
    BlockRead(DataFile, Tag, 1);
    Inc(BytesRead);
    for i := 1 to 8 do
    begin
      if BytesRead < CompSize then
      begin
        if ((Tag and 1) = 0) and (BytesRead < CompSize - 1) then
        begin
          Offset := 0;
          Length := 0;
          BlockRead(DataFile, Length, 1);
          BlockRead(DataFile, Offset, 1);
          Inc(BytesRead, 2);
          Offset := (Offset shl 4) or (Length shr 4);
          Length := Length and $0F + THRESHOLD;
          if Offset <> 0 then
          begin
            BufReadPtr := BufWrtPtr - Offset;
            for j := 0 to Length do
            begin
              b := HisBuf[Longint(N - 1) and Longint(BufReadPtr + j)];
              HisBuf[BufWrtPtr] := b;
              BlockWrite(CurDest, b, 1);
              Inc(BytesWritten);
              Inc(BufWrtPtr);
              BufWrtPtr := Longint(BufWrtPtr) and Longint(N - 1)
            end
          end
        end
        else if BytesRead < CompSize then
        begin
          BlockRead(DataFile, b, 1);
          Inc(BytesRead);
          BlockWrite(CurDest, b, 1);
          HisBuf[BufWrtPtr] := b;
          Inc(BytesWritten);
          Inc(BufWrtPtr);
          BufWrtPtr := Longint(BufWrtPtr) and Longint(N - 1)
        end;
        Tag := Tag shr 1
      end
    end
  end;

  if (BytesRead <> CompSize) or
     (BytesWritten <> UnCompSize)
  then
    WriteLn('Warning: file might not have been extracted correctly!');

  Inc(Stat_BytesWritten, BytesWritten);
  Inc(Stat_BytesRead, BytesRead)
end;

procedure ExtractFiles;
begin
  Stat_BytesRead := 0;
  Stat_BytesWritten := 0;
  Stat_FilesExtracted := 0;
  i := 1;
  Seek(DirFile, 0);
  while not Eof(DirFile) do
  begin
    Read(DirFile, FileEntry);
    FileEntries[i] := FileEntry;
    Inc(i)
  end;
  NrFiles := i - 1;
  FilesToDo := 0;
  for i := 1 to NrFiles do
  begin
    Write('Extracting ');
    CreateFile(FileEntries[i]);
    ExtractFile(FileEntries[i]);
    Inc(Stat_FilesExtracted);
    WriteLn('finished');
    Close(CurDest);
    for j := 1 to FilesToDo do
    begin
      Write('Extracting ');
      CreateFile(FileEntries[i]);
      ExtractFile(FileEntries[i]);
      Inc(Stat_FilesExtracted);
      WriteLn('finished');
      Close(CurDest)
    end
  end
end;

begin
  WriteLn('Star Trek: 25th Anniversary/Judgment Rites source file extractor');
  WriteLn('(C)opyright Deniz Oezmen <deniz.oezmen@t-online.de>, 2000-2001');
  WriteLn('early alpha, use at your own risk ...');
  WriteLn('Thanks to Benjamin Haisch for the decompression specifications (deLZSS)');
  WriteLn;
  if CheckCommandLine then
  begin
    WriteLn('þ Command line OK');
    if OpenFiles then
    begin
      WriteLn('þ Source files opened successfully');
      WriteLn('þ Extracting all files now ...');
      ExtractFiles;
      WriteLn('');
      WriteLn('Statistics:');
      WriteLn('Input file size: ', FileSize(DataFile));
      WriteLn('Directory file size: ', FileSize(DirFile) * 14);
      WriteLn('Explicit file entries: ', NrFiles);
      WriteLn('Compressed data read: ', Stat_BytesRead);
      WriteLn('file data extracted: ', Stat_BytesWritten);
      WriteLn('Files extracted: ', Stat_FilesExtracted);
      WriteLn('');
      WriteLn('þ Clearing up and closing files ...');
      Close(DirFile);
      Close(DataFile);
    end
    else
      WriteLn('þ Couldn''t open source files ... please check command line')
  end
  else
  begin
    WriteLn('þ Parameter missing ...');
    WriteLn('  Usage: TREKEXTR data.dir data.001')
  end
end.
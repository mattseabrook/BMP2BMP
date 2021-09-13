{ File   : TYPECHG2.PAS
  Author : Deniz Oezmen
  Created: 2005-02-01
  Changed: 2005-08-25

  Library containing various type conversion functions.
}
unit TypeChg2;
{$N+ E-}

interface

const
  Version = $0201;
  Build   = $0005;
  Author  = 'Deniz Oezmen, 2005';

  HexChars : array[0..15] of Char = ('0', '1', '2', '3', '4', '5', '6', '7',
                                     '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
  HexCharsS: array[0..15] of Char = ('0', '1', '2', '3', '4', '5', '6', '7',
                                     '8', '9', 'a', 'b', 'c', 'd', 'e', 'f');
  BoolStr  : array[0..1] of String = ('TRUE', 'FALSE');
  DecChar = '.';

function BinToInt     (s: string)            : Longint;
function BooleanToStr (b: Boolean)           : string;
function DoubleToStr  (d: Double)            : string;
function HexToInt     (s: string)            : Longint;
function IntToBin     (i: LongInt; Len: Byte): string;
function IntToHex     (i: Longint; Len: Byte): string;
function IntToHexSmall(i: Longint; Len: Byte): string;
function IntToStr     (i: Longint)           : string;
function StrToBoolean (s: string)            : Boolean;
function StrToDouble  (s: string)            : double;
function StrToInt     (s: string)            : Longint;

function DecSystem(i: Longint): string;

function UCase(s: string): string;
function DCase(s: string): string;
function StrLeadingChar(s: string; c: Char; Len: Byte): string;
function StrTrailingChar(s: string; c: Char; Len: Byte): string;

implementation

function IntToStr(i: Longint): string;
var
  s: string;
begin
  Str(i, s);
  IntToStr := s
end;

function DoubleToStr(d: Double): string;
var
  s: string;
begin
  Str(d, s);
  DoubleToStr := s
end;

function StrToInt(s: string): Longint;
var
  i   : Longint;
  Code: Integer;
BEGIN
  Val(s, i, Code);
  if Code <> 0 then
    StrToInt := 0
  else
    StrToInt := i
end;

function StrToDouble(s: string): Double;
var
  d   : Double;
  Code: Integer;
begin
  Val(s, d, Code);
  if Code <> 0 then
    StrToDouble := 0
  else
    StrToDouble := d
end;

function IntToHex(i: Longint; Len: Byte): string;
var
  s: string;
begin
  if i = 0 then
    s := '0'
  else
    s := '';

  while i <> 0 do
  begin
    s := HexChars[i and $f] + s;
    i := i shr 4
  end;

  while Length(s) < Len do
    s := '0' + s;

  IntToHex := s
end;

function IntToHexSmall(i: Longint; Len: Byte): string;
var
  s: string;
begin
  if i = 0 then
    s := '0'
  else
    s := '';

  while i <> 0 do
  begin
    s := HexCharsS[i and $f] + s;
    i := i shr 4
  end;

  while Length(s) < Len do
    s := '0' + s;

  IntToHexSmall := s
end;

function IntToBin(i: Longint; Len: Byte): string;
var
  s: string;
begin
  if i = 0 then
    s := '0'
  else
    s := '';

  while i <> 0 do
  begin
    s := HexChars[i and 1] + s;
    i := i shr 1
  end;

  while Length(s) < Len do
    s := '0' + s;

  IntToBin := s
end;

function StrToBoolean(s: string): Boolean;
begin
  StrToBoolean := not (s[1] = '0')
end;

function HexToInt(s: string): Longint;
var
  i: Longint;
  j: Byte;
begin
  i := 0;

  for j := 1 to Length(s) do
  begin
    i := i shl 4;
    case s[j] of
      '0'..'9': Inc(i, Ord(s[j]) - 48);
      'a'..'f': Inc(i, Ord(s[j]) - 87);
      'A'..'F': Inc(i, Ord(s[j]) - 55);
    else
      begin
        i := 0;
        Break
      end
    end
  end;

  HexToInt := i
end;

function BooleanToStr(b: Boolean): string;
begin
  BooleanToStr := BoolStr[Byte(b)]
end;

function DecSystem(i: Longint): string;
var
  j     : Byte;
  s1, s2: string;
begin
  s1 := IntToStr(i);
  s2 := '';

  for j := 1 to Length(s1) do
  begin
    s2 := s2 + s1[j];
    if ((Length(s1) - j) mod 3 = 0) and (j <> Length(s1)) then
      s2 := s2 + DecChar
  end;

  DecSystem := s2
end;

function UCase(s: string): string;
var
  i: Byte;
begin
  for i := 1 to Length(s) do
    s[i] := UpCase(s[i]);
  UCase := s
end;

function DCase(s: string): string;
var
  i: Byte;
begin
  for i := 1 to Length(s) do
    case s[i] of
      'A'..'Z': s[i] := Chr(Ord(s[i]) + 32);
      'é'     : s[i] := 'Ñ';
      'ô'     : s[i] := 'î';
      'ö'     : s[i] := 'Å'
    end;

  DCase := s
end;

function BinToInt(s: string): Longint;
var
  i: Longint;
  j: Byte;
begin
  i := 0;

  for j := 1 to Length(s) do
  begin
    i := i shl 1;
    case s[j] of
      '0'..'1': Inc(i, Ord(s[j]) - 48);
    else
      begin
        i := 0;
        Break
      end
    end
  end;

  BinToInt := i
end;

function StrLeadingChar(s: string; c: Char; Len: Byte): string;
begin
  while Length(s) < Len do
    s := c + s;

  StrLeadingChar := s
end;

function StrTrailingChar(s: string; c: Char; Len: Byte): string;
begin
  while Length(s) < Len do
    s := s + c;

  StrTrailingChar := s
end;

begin
end.
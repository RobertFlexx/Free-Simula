unit utf8;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}
{$pointermath on}

interface

function UTF8Decode(P: PAnsiChar; Available: SizeUInt; out CodePoint: UInt32;
  out Width: SizeUInt): Boolean;
function UTF8Encode(CodePoint: UInt32; var Bytes: array of AnsiChar): SizeInt;
function UTF8Validate(P: PAnsiChar; LengthValue: SizeUInt; out ErrorOffset: SizeUInt): Boolean;
function UTF8CodePointCount(P: PAnsiChar; LengthValue: SizeUInt): SizeUInt;
function UnicodeIsIdentifierStart(CodePoint: UInt32): Boolean;
function UnicodeIsIdentifierContinue(CodePoint: UInt32): Boolean;
function UnicodeIsWhitespace(CodePoint: UInt32): Boolean;
function UnicodeSimpleLower(CodePoint: UInt32): UInt32;
function UnicodeSimpleUpper(CodePoint: UInt32): UInt32;
function UnicodeSimpleFold(CodePoint: UInt32): UInt32;

implementation

uses
  unicode;

function RangeContains(CodePoint: UInt32; const Ranges: array of TUnicodeRange): Boolean;
var
  LowIndex, HighIndex, MidIndex: SizeInt;
begin
  LowIndex := 0;
  HighIndex := High(Ranges);
  while LowIndex <= HighIndex do
  begin
    MidIndex := LowIndex + ((HighIndex - LowIndex) shr 1);
    if CodePoint < Ranges[MidIndex].FirstCodePoint then
      HighIndex := MidIndex - 1
    else if CodePoint > Ranges[MidIndex].LastCodePoint then
      LowIndex := MidIndex + 1
    else
      Exit(True);
  end;
  Result := False;
end;

function MapCodePoint(CodePoint: UInt32; const Mappings: array of TUnicodeMapping): UInt32;
var
  LowIndex, HighIndex, MidIndex: SizeInt;
begin
  LowIndex := 0;
  HighIndex := High(Mappings);
  while LowIndex <= HighIndex do
  begin
    MidIndex := LowIndex + ((HighIndex - LowIndex) shr 1);
    if CodePoint < Mappings[MidIndex].SourceCodePoint then
      HighIndex := MidIndex - 1
    else if CodePoint > Mappings[MidIndex].SourceCodePoint then
      LowIndex := MidIndex + 1
    else
      Exit(Mappings[MidIndex].TargetCodePoint);
  end;
  Result := CodePoint;
end;

function UTF8Decode(P: PAnsiChar; Available: SizeUInt; out CodePoint: UInt32;
  out Width: SizeUInt): Boolean;
var
  B0, B1, B2, B3: Byte;
begin
  CodePoint := 0;
  Width := 0;
  if (P = nil) or (Available = 0) then Exit(False);
  B0 := Byte(P[0]);
  if B0 < $80 then
  begin
    CodePoint := B0;
    Width := 1;
    Exit(True);
  end;
  if (B0 and $E0) = $C0 then
  begin
    if Available < 2 then Exit(False);
    B1 := Byte(P[1]);
    if (B1 and $C0) <> $80 then Exit(False);
    CodePoint := UInt32(B0 and $1F) shl 6 or UInt32(B1 and $3F);
    if CodePoint < $80 then Exit(False);
    Width := 2;
    Exit(True);
  end;
  if (B0 and $F0) = $E0 then
  begin
    if Available < 3 then Exit(False);
    B1 := Byte(P[1]);
    B2 := Byte(P[2]);
    if ((B1 and $C0) <> $80) or ((B2 and $C0) <> $80) then Exit(False);
    CodePoint := UInt32(B0 and $0F) shl 12 or UInt32(B1 and $3F) shl 6 or UInt32(B2 and $3F);
    if CodePoint < $800 then Exit(False);
    if (CodePoint >= $D800) and (CodePoint <= $DFFF) then Exit(False);
    Width := 3;
    Exit(True);
  end;
  if (B0 and $F8) = $F0 then
  begin
    if Available < 4 then Exit(False);
    B1 := Byte(P[1]);
    B2 := Byte(P[2]);
    B3 := Byte(P[3]);
    if ((B1 and $C0) <> $80) or ((B2 and $C0) <> $80) or ((B3 and $C0) <> $80) then Exit(False);
    CodePoint := UInt32(B0 and $07) shl 18 or UInt32(B1 and $3F) shl 12 or UInt32(B2 and $3F) shl 6 or UInt32(B3 and $3F);
    if (CodePoint < $10000) or (CodePoint > $10FFFF) then Exit(False);
    Width := 4;
    Exit(True);
  end;
  Result := False;
end;

function UTF8Encode(CodePoint: UInt32; var Bytes: array of AnsiChar): SizeInt;
begin
  Result := 0;
  if CodePoint <= $7F then
  begin
    if Length(Bytes) < 1 then Exit;
    Bytes[0] := AnsiChar(CodePoint);
    Exit(1);
  end;
  if CodePoint <= $7FF then
  begin
    if Length(Bytes) < 2 then Exit;
    Bytes[0] := AnsiChar($C0 or (CodePoint shr 6));
    Bytes[1] := AnsiChar($80 or (CodePoint and $3F));
    Exit(2);
  end;
  if (CodePoint >= $D800) and (CodePoint <= $DFFF) then Exit;
  if CodePoint <= $FFFF then
  begin
    if Length(Bytes) < 3 then Exit;
    Bytes[0] := AnsiChar($E0 or (CodePoint shr 12));
    Bytes[1] := AnsiChar($80 or ((CodePoint shr 6) and $3F));
    Bytes[2] := AnsiChar($80 or (CodePoint and $3F));
    Exit(3);
  end;
  if CodePoint <= $10FFFF then
  begin
    if Length(Bytes) < 4 then Exit;
    Bytes[0] := AnsiChar($F0 or (CodePoint shr 18));
    Bytes[1] := AnsiChar($80 or ((CodePoint shr 12) and $3F));
    Bytes[2] := AnsiChar($80 or ((CodePoint shr 6) and $3F));
    Bytes[3] := AnsiChar($80 or (CodePoint and $3F));
    Exit(4);
  end;
end;

function UTF8Validate(P: PAnsiChar; LengthValue: SizeUInt; out ErrorOffset: SizeUInt): Boolean;
var
  Offset, Width: SizeUInt;
  CodePoint: UInt32;
begin
  Offset := 0;
  while Offset < LengthValue do
  begin
    if not UTF8Decode(P + Offset, LengthValue - Offset, CodePoint, Width) then
    begin
      ErrorOffset := Offset;
      Exit(False);
    end;
    Inc(Offset, Width);
  end;
  ErrorOffset := LengthValue;
  Result := True;
end;

function UTF8CodePointCount(P: PAnsiChar; LengthValue: SizeUInt): SizeUInt;
var
  Offset, Width: SizeUInt;
  CodePoint: UInt32;
begin
  Result := 0;
  Offset := 0;
  while Offset < LengthValue do
  begin
    if not UTF8Decode(P + Offset, LengthValue - Offset, CodePoint, Width) then Exit(High(SizeUInt));
    Inc(Offset, Width);
    Inc(Result);
  end;
end;

function UnicodeIsIdentifierStart(CodePoint: UInt32): Boolean;
begin
  Result := RangeContains(CodePoint, UNICODE_IDENTIFIER_START_RANGES);
end;

function UnicodeIsIdentifierContinue(CodePoint: UInt32): Boolean;
begin
  Result := RangeContains(CodePoint, UNICODE_IDENTIFIER_CONTINUE_RANGES);
end;

function UnicodeIsWhitespace(CodePoint: UInt32): Boolean;
begin
  Result := RangeContains(CodePoint, UNICODE_WHITESPACE_RANGES);
end;

function UnicodeSimpleLower(CodePoint: UInt32): UInt32;
begin
  Result := MapCodePoint(CodePoint, UNICODE_SIMPLE_LOWER_MAP);
end;

function UnicodeSimpleUpper(CodePoint: UInt32): UInt32;
begin
  Result := MapCodePoint(CodePoint, UNICODE_SIMPLE_UPPER_MAP);
end;

function UnicodeSimpleFold(CodePoint: UInt32): UInt32;
begin
  Result := MapCodePoint(CodePoint, UNICODE_SIMPLE_FOLD_MAP);
end;

end.

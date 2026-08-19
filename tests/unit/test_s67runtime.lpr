program test_s67runtime;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

uses
  SysUtils, core, s67runtime;

procedure Fail(Code: Integer; const MessageText: RawByteString);
begin
  Writeln(StdErr, 'simula67 runtime test failed: ', MessageText);
  Halt(Code);
end;

function Bytes(const T: TTextDescriptor): RawByteString;
begin
  if (T.Length <= 0) or (T.StartPos = nil) then Exit('');
  SetString(Result, T.StartPos, T.Length);
end;

var
  Arena: TS67Arena;
  Whole, Slice, NumberText, RealText, Source: TTextDescriptor;
  Ch: AnsiChar;
  IntValue: Int64;
  RealValue: Double;
begin
  S67ArenaInit(Arena);
  try
    Whole := S67Blanks(Arena, 8);
    if (Whole.Length <> 8) or (Whole.CurrentPos <> 1) then
      Fail(1, 'blanks descriptor is malformed');

    S67TextInit(Source, PAnsiChar('abcde'), 5);
    if not S67TextAssign(Whole, Source) then Fail(2, 'text assignment failed');
    if Bytes(Whole) <> 'abcde   ' then Fail(3, 'text assignment did not blank-fill');

    if not S67TextSub(Whole, 2, 3, Slice) then Fail(4, 'sub rejected valid slice');
    if PtrUInt(Slice.StartPos) <> PtrUInt(Whole.StartPos) + 1 then Fail(5, 'sub allocated/copied instead of slicing');
    if not S67TextPutChar(Slice, 'X') then Fail(6, 'putchar failed');
    if Bytes(Whole) <> 'aXcde   ' then Fail(7, 'sub mutation did not alias main frame');

    S67TextSetPos(Whole, 0);
    if Whole.CurrentPos <> Whole.Length + 1 then Fail(8, 'setpos did not clamp');
    if S67TextMore(Whole) then Fail(9, 'more true after clamped setpos');
    if S67TextGetChar(Whole, Ch) then Fail(10, 'getchar read past frame');

    S67TextInit(Source, PAnsiChar('  -12345 '), 9);
    NumberText := S67Copy(Arena, Source);
    if not S67TextTryGetInt(NumberText, IntValue) then Fail(11, 'getint parse failed');
    if IntValue <> -12345 then Fail(12, 'getint value mismatch');

    S67TextInit(Source, PAnsiChar(' 12.5 '), 6);
    RealText := S67Copy(Arena, Source);
    if not S67TextTryGetReal(RealText, RealValue) then Fail(13, 'getreal parse failed');
    if Abs(RealValue - 12.5) > 1.0e-12 then Fail(14, 'getreal value mismatch');

    Whole := S67TextStrip(Whole);
    if Bytes(Whole) <> 'aXcde' then Fail(15, 'strip did not trim trailing spaces');
  finally
    S67ArenaClear(Arena);
  end;
end.

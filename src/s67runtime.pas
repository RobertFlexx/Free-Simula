unit s67runtime;

{$mode objfpc}{$H+}{$J-}
{$pointermath on}
{$R+}{$Q+}

interface

uses
  SysUtils, Math, core, registers, x64;

const
  S67_TEXT_START_OFFSET = 0;
  S67_TEXT_POS_OFFSET = 8;
  S67_TEXT_LENGTH_OFFSET = 12;
  S67_TEXT_DESCRIPTOR_SIZE = 16;
  S67_DEFAULT_IMAGE_LENGTH = 132;

type
  TTextDescriptor = packed record
    StartPos: PAnsiChar;
    CurrentPos: Int32;
    Length: Int32;
  end;
  PTextDescriptor = ^TTextDescriptor;

  PS67ArenaBlock = ^TS67ArenaBlock;
  TS67ArenaBlock = record
    Next: PS67ArenaBlock;
    Capacity: SizeUInt;
    Used: SizeUInt;
  end;

  TS67Arena = record
    First: PS67ArenaBlock;
    Current: PS67ArenaBlock;
    BlockSize: SizeUInt;
  end;

  TS67NativeDataOffsets = packed record
    ArenaCursor: Int32;
    ArenaEnd: Int32;
    SysInObject: Int32;
    SysOutObject: Int32;
    SysInDescriptor: Int32;
    SysOutDescriptor: Int32;
    InputBuffer: Int32;
    OutputBuffer: Int32;
    InputEOF: Int32;
    CurrentLowTen: Int32;
    CurrentDecimalMark: Int32;
  end;

  TS67NativeLabels = packed record
    Init: Int32;
    SysIn: Int32;
    SysOut: Int32;
    InImage: Int32;
    InChar: Int32;
    InInt: Int32;
    InReal: Int32;
    LastItem: Int32;
    EndFile: Int32;
    OutImage: Int32;
    OutChar: Int32;
    OutText: Int32;
    InText: Int32;
    InFrac: Int32;
    OutInt: Int32;
    OutFix: Int32;
    OutReal: Int32;
    OutFrac: Int32;
    Field: Int32;
    ArenaAlloc: Int32;
    TextConstant: Int32;
    TextStart: Int32;
    TextLength: Int32;
    TextMain: Int32;
    TextPos: Int32;
    TextSetPos: Int32;
    TextMore: Int32;
    TextGetChar: Int32;
    TextPutChar: Int32;
    TextSub: Int32;
    TextStrip: Int32;
    TextGetInt: Int32;
    TextGetReal: Int32;
    TextGetFrac: Int32;
    TextPutInt: Int32;
    TextPutFix: Int32;
    TextPutReal: Int32;
    TextPutFrac: Int32;
    TextWrite: Int32;
    TextBlanks: Int32;
    TextCopy: Int32;
    TextAssign: Int32;
    TextConcat: Int32;
    TextEqual: Int32;
    TextLeftAdjust: Int32;
    LowTen: Int32;
    DecimalMark: Int32;
    Upcase: Int32;
    Lowcase: Int32;
    MathSqrt: Int32;
    MathSin: Int32;
    MathCos: Int32;
    MathTan: Int32;
    MathArctan: Int32;
    MathLn: Int32;
    MathLog10: Int32;
    MathExp: Int32
  end;

  TS67NativeLinks = packed record
    Allocate: Int32;
    WriteRaw: Int32;
    PanicText: Int32;
  end;

procedure S67ArenaInit(out Arena: TS67Arena; BlockSize: SizeUInt = 65536);
procedure S67ArenaClear(var Arena: TS67Arena);
function S67ArenaAlloc(var Arena: TS67Arena; Bytes: SizeUInt;
  Alignment: SizeUInt = 8): Pointer;

procedure S67TextInit(out Text: TTextDescriptor; Buffer: PAnsiChar;
  CharacterCount: Int32);
function S67TextLength(const Text: TTextDescriptor): Int32; inline;
function S67TextPos(const Text: TTextDescriptor): Int32; inline;
procedure S67TextSetPos(var Text: TTextDescriptor; Position: Int32);
function S67TextMore(const Text: TTextDescriptor): Boolean; inline;
function S67TextGetChar(var Text: TTextDescriptor; out Ch: AnsiChar): Boolean;
function S67TextPutChar(var Text: TTextDescriptor; Ch: AnsiChar): Boolean;
function S67TextSub(const Text: TTextDescriptor; Start, Count: Int32;
  out Slice: TTextDescriptor): Boolean;
function S67TextStrip(const Text: TTextDescriptor): TTextDescriptor;
function S67TextTryGetInt(var Text: TTextDescriptor; out Value: Int64): Boolean;
function S67TextTryGetReal(var Text: TTextDescriptor; out Value: Double): Boolean;
function S67TextTryGetFrac(var Text: TTextDescriptor; out Value: Int64): Boolean;
function S67TextGetInt(var Text: TTextDescriptor): Int64;
function S67TextGetReal(var Text: TTextDescriptor): Double;
function S67TextGetFrac(var Text: TTextDescriptor): Int64;
function S67TextAssign(var Target: TTextDescriptor;
  const Source: TTextDescriptor): Boolean;
function S67Blanks(var Arena: TS67Arena; Count: Int32): TTextDescriptor;
function S67Copy(var Arena: TS67Arena;
  const Source: TTextDescriptor): TTextDescriptor;
procedure S67AppendWritableData(var Data: TByteBuffer;
  out Offsets: TS67NativeDataOffsets);
procedure S67AllocateNativeLabels(var Assembler: TX64Assembler;
  out Labels: TS67NativeLabels);
procedure S67EmitNative(var Assembler: TX64Assembler;
  const Labels: TS67NativeLabels; const Data: TS67NativeDataOffsets;
  const Links: TS67NativeLinks);

implementation

function AlignPointer(Value, Alignment: SizeUInt): SizeUInt; inline;
begin
  if Alignment <= 1 then Exit(Value);
  Result := (Value + Alignment - 1) and not (Alignment - 1);
end;

procedure S67ArenaInit(out Arena: TS67Arena; BlockSize: SizeUInt);
begin
  Arena := Default(TS67Arena);
  if BlockSize < 1024 then BlockSize := 1024;
  Arena.BlockSize := BlockSize;
end;

procedure S67ArenaClear(var Arena: TS67Arena);
var
  Block, NextBlock: PS67ArenaBlock;
begin
  Block := Arena.First;
  while Block <> nil do
  begin
    NextBlock := Block^.Next;
    FreeMem(Block);
    Block := NextBlock;
  end;
  Arena := Default(TS67Arena);
end;

function NewArenaBlock(var Arena: TS67Arena; Need: SizeUInt): PS67ArenaBlock;
var
  Capacity, Total: SizeUInt;
begin
  Capacity := Arena.BlockSize;
  if Capacity < Need then Capacity := AlignPointer(Need, 4096);
  Total := SizeOf(TS67ArenaBlock) + Capacity;
  GetMem(Result, Total);
  FillChar(Result^, Total, 0);
  Result^.Capacity := Capacity;
  if Arena.First = nil then Arena.First := Result;
  if Arena.Current <> nil then Arena.Current^.Next := Result;
  Arena.Current := Result;
end;

function S67ArenaAlloc(var Arena: TS67Arena; Bytes: SizeUInt;
  Alignment: SizeUInt): Pointer;
var
  Block: PS67ArenaBlock;
  Offset, HeaderSize: SizeUInt;
  Base: PByte;
begin
  if Bytes = 0 then Exit(nil);
  if (Alignment = 0) or ((Alignment and (Alignment - 1)) <> 0) then
    raise EArgumentException.Create('arena alignment must be a power of two');
  HeaderSize := SizeOf(TS67ArenaBlock);
  Block := Arena.Current;
  if Block <> nil then
  begin
    Offset := AlignPointer(Block^.Used, Alignment);
    if Offset + Bytes > Block^.Capacity then Block := nil;
  end;
  if Block = nil then
  begin
    Block := NewArenaBlock(Arena, Bytes + Alignment);
    Offset := 0;
  end;
  Offset := AlignPointer(Offset, Alignment);
  Base := PByte(Block);
  Result := Base + HeaderSize + Offset;
  Block^.Used := Offset + Bytes;
end;

procedure S67TextInit(out Text: TTextDescriptor; Buffer: PAnsiChar;
  CharacterCount: Int32);
begin
  if CharacterCount < 0 then
    raise ERangeError.Create('negative text length');
  Text.StartPos := Buffer;
  Text.CurrentPos := 1;
  Text.Length := CharacterCount;
end;

function S67TextLength(const Text: TTextDescriptor): Int32; inline;
begin
  Result := Text.Length;
end;

function S67TextPos(const Text: TTextDescriptor): Int32; inline;
begin
  Result := Text.CurrentPos;
end;

procedure S67TextSetPos(var Text: TTextDescriptor; Position: Int32);
begin
  if (Position < 1) or (Position > Text.Length + 1) then
    Text.CurrentPos := Text.Length + 1
  else
    Text.CurrentPos := Position;
end;

function S67TextMore(const Text: TTextDescriptor): Boolean; inline;
begin
  Result := (Text.CurrentPos >= 1) and (Text.CurrentPos <= Text.Length);
end;

function S67TextGetChar(var Text: TTextDescriptor; out Ch: AnsiChar): Boolean;
begin
  Result := S67TextMore(Text) and (Text.StartPos <> nil);
  if not Result then
  begin
    Ch := #0;
    Exit;
  end;
  Ch := Text.StartPos[Text.CurrentPos - 1];
  Inc(Text.CurrentPos);
end;

function S67TextPutChar(var Text: TTextDescriptor; Ch: AnsiChar): Boolean;
begin
  Result := S67TextMore(Text) and (Text.StartPos <> nil);
  if not Result then Exit;
  Text.StartPos[Text.CurrentPos - 1] := Ch;
  Inc(Text.CurrentPos);
end;

function S67TextSub(const Text: TTextDescriptor; Start, Count: Int32;
  out Slice: TTextDescriptor): Boolean;
begin
  Slice := Default(TTextDescriptor);
  Result := (Start >= 1) and (Count >= 0) and
    (Int64(Start) + Int64(Count) <= Int64(Text.Length) + 1);
  if not Result then Exit;
  Slice.StartPos := Text.StartPos;
  if (Slice.StartPos <> nil) and (Count <> 0) then
    Inc(Slice.StartPos, Start - 1);
  Slice.CurrentPos := 1;
  Slice.Length := Count;
end;

function S67TextStrip(const Text: TTextDescriptor): TTextDescriptor;
var
  N: Int32;
begin
  Result := Text;
  Result.CurrentPos := 1;
  N := Text.Length;
  while (N > 0) and (Text.StartPos <> nil) and
        (Text.StartPos[N - 1] = ' ') do
    Dec(N);
  Result.Length := N;
end;

function IsASCIISpace(Ch: AnsiChar): Boolean; inline;
begin
  Result := Ch in [' ', #9, #10, #13];
end;

procedure SkipSpaces(const Text: TTextDescriptor; var Index: Int32);
begin
  while (Index <= Text.Length) and (Text.StartPos <> nil) and
        IsASCIISpace(Text.StartPos[Index - 1]) do
    Inc(Index);
end;

function S67TextTryGetInt(var Text: TTextDescriptor; out Value: Int64): Boolean;
var
  Index, First, Digit: Int32;
  Negative: Boolean;
  Magnitude, Limit, Next: QWord;
  Ch: AnsiChar;
begin
  Result := False;
  Value := 0;
  if Text.StartPos = nil then Exit;
  Index := Text.CurrentPos;
  if Index < 1 then Index := 1;
  SkipSpaces(Text, Index);
  Negative := False;
  if Index <= Text.Length then
  begin
    Ch := Text.StartPos[Index - 1];
    if (Ch = '+') or (Ch = '-') then
    begin
      Negative := Ch = '-';
      Inc(Index);
    end;
  end;
  First := Index;
  Magnitude := 0;
  if Negative then Limit := QWord(High(Int64)) + 1
  else Limit := QWord(High(Int64));
  while Index <= Text.Length do
  begin
    Ch := Text.StartPos[Index - 1];
    if not (Ch in ['0'..'9']) then Break;
    Digit := Ord(Ch) - Ord('0');
    if Magnitude > (Limit - QWord(Digit)) div 10 then Exit;
    Next := Magnitude * 10 + QWord(Digit);
    Magnitude := Next;
    Inc(Index);
  end;
  if Index = First then Exit;
  if Negative then
  begin
    if Magnitude = QWord(High(Int64)) + 1 then
      Value := Low(Int64)
    else
      Value := -Int64(Magnitude);
  end
  else
    Value := Int64(Magnitude);
  Text.CurrentPos := Index;
  Result := True;
end;

function Pow10Integer(Exponent: Int32): Double;
var
  N: Int32;
  Base: Double;
begin
  Result := 1.0;
  Base := 10.0;
  N := Abs(Exponent);
  while N <> 0 do
  begin
    if (N and 1) <> 0 then Result := Result * Base;
    Base := Base * Base;
    N := N shr 1;
  end;
  if Exponent < 0 then Result := 1.0 / Result;
end;

function S67TextTryGetReal(var Text: TTextDescriptor; out Value: Double): Boolean;
var
  Index, FirstDigit, FractionDigits, Exponent, ExponentDigits: Int32;
  Negative, ExponentNegative, SeenDigit: Boolean;
  Ch: AnsiChar;
  Whole, Fraction, Scale: Double;
begin
  Result := False;
  Value := 0.0;
  if Text.StartPos = nil then Exit;
  Index := Text.CurrentPos;
  if Index < 1 then Index := 1;
  SkipSpaces(Text, Index);
  Negative := False;
  if Index <= Text.Length then
  begin
    Ch := Text.StartPos[Index - 1];
    if Ch in ['+', '-'] then
    begin
      Negative := Ch = '-';
      Inc(Index);
    end;
  end;

  Whole := 0.0;
  SeenDigit := False;
  FirstDigit := Index;
  while (Index <= Text.Length) and
        (Text.StartPos[Index - 1] in ['0'..'9']) do
  begin
    SeenDigit := True;
    Whole := Whole * 10.0 + (Ord(Text.StartPos[Index - 1]) - Ord('0'));
    Inc(Index);
  end;

  Fraction := 0.0;
  FractionDigits := 0;
  if (Index <= Text.Length) and (Text.StartPos[Index - 1] = '.') then
  begin
    Inc(Index);
    while (Index <= Text.Length) and
          (Text.StartPos[Index - 1] in ['0'..'9']) do
    begin
      SeenDigit := True;
      Fraction := Fraction * 10.0 +
        (Ord(Text.StartPos[Index - 1]) - Ord('0'));
      Inc(FractionDigits);
      Inc(Index);
    end;
  end;
  if not SeenDigit or ((Index = FirstDigit) and (FractionDigits = 0)) then Exit;

  Exponent := 0;
  if (Index <= Text.Length) and
     (Text.StartPos[Index - 1] in ['&', 'e', 'E']) then
  begin
    Inc(Index);
    if (Index <= Text.Length) and (Text.StartPos[Index - 1] = '&') then
      Inc(Index); { old double ampersand exponent marker }
    ExponentNegative := False;
    if Index <= Text.Length then
    begin
      Ch := Text.StartPos[Index - 1];
      if Ch in ['+', '-'] then
      begin
        ExponentNegative := Ch = '-';
        Inc(Index);
      end;
    end;
    ExponentDigits := 0;
    while (Index <= Text.Length) and
          (Text.StartPos[Index - 1] in ['0'..'9']) do
    begin
      if Exponent < 100000 then
        Exponent := Exponent * 10 +
          (Ord(Text.StartPos[Index - 1]) - Ord('0'));
      Inc(ExponentDigits);
      Inc(Index);
    end;
    if ExponentDigits = 0 then Exit;
    if ExponentNegative then Exponent := -Exponent;
  end;

  Scale := Pow10Integer(-FractionDigits);
  Value := Whole + Fraction * Scale;
  if Exponent <> 0 then Value := Value * Pow10Integer(Exponent);
  if Negative then Value := -Value;
  if IsNan(Value) or IsInfinite(Value) then Exit(False);
  Text.CurrentPos := Index;
  Result := True;
end;

function S67TextTryGetFrac(var Text: TTextDescriptor; out Value: Int64): Boolean;
var
  Index, First: Int32;
  Negative, SeenDigit, SeenMark: Boolean;
  Magnitude, Limit: QWord;
  Ch: AnsiChar;
  DigitValue: Byte;
begin
  Result := False;
  Value := 0;
  if Text.StartPos = nil then Exit;
  Index := Text.CurrentPos;
  if Index < 1 then Index := 1;
  while (Index <= Text.Length) and
        (Text.StartPos[Index - 1] in [' ', #9]) do Inc(Index);
  Negative := False;
  if Index <= Text.Length then
  begin
    Ch := Text.StartPos[Index - 1];
    if Ch in ['+', '-'] then
    begin
      Negative := Ch = '-';
      Inc(Index);
      while (Index <= Text.Length) and
            (Text.StartPos[Index - 1] in [' ', #9]) do Inc(Index);
    end;
  end;
  First := Index;
  SeenDigit := False;
  SeenMark := False;
  Magnitude := 0;
  if Negative then Limit := QWord(High(Int64)) + 1
  else Limit := QWord(High(Int64));
  while Index <= Text.Length do
  begin
    Ch := Text.StartPos[Index - 1];
    if Ch in ['0'..'9'] then
    begin
      SeenDigit := True;
      DigitValue := Ord(Ch) - Ord('0');
      if Magnitude > (Limit - QWord(DigitValue)) div 10 then Exit;
      Magnitude := Magnitude * 10 + QWord(DigitValue);
      Inc(Index);
      Continue;
    end;
    if Ch in [' ', #9] then
    begin
      Inc(Index);
      Continue;
    end;
    if (Ch in ['.', ',']) and not SeenMark then
    begin
      SeenMark := True;
      Inc(Index);
      Continue;
    end;
    Break;
  end;
  if not SeenDigit or (Index = First) then Exit;
  if Negative then
  begin
    if Magnitude = QWord(High(Int64)) + 1 then Value := Low(Int64)
    else Value := -Int64(Magnitude);
  end
  else Value := Int64(Magnitude);
  Text.CurrentPos := Index;
  Result := True;
end;

function S67TextGetInt(var Text: TTextDescriptor): Int64;
begin
  if not S67TextTryGetInt(Text, Result) then
    raise EConvertError.Create('text does not begin with an integer item');
end;

function S67TextGetReal(var Text: TTextDescriptor): Double;
begin
  if not S67TextTryGetReal(Text, Result) then
    raise EConvertError.Create('text does not begin with a real item');
end;

function S67TextGetFrac(var Text: TTextDescriptor): Int64;
begin
  if not S67TextTryGetFrac(Text, Result) then
    raise EConvertError.Create('text does not begin with a grouped item');
end;

function S67TextAssign(var Target: TTextDescriptor;
  const Source: TTextDescriptor): Boolean;
var
  I: Int32;
begin
  Result := (Target.Length >= Source.Length) and
    ((Target.Length = 0) or (Target.StartPos <> nil)) and
    ((Source.Length = 0) or (Source.StartPos <> nil));
  if not Result then Exit;
  for I := 0 to Source.Length - 1 do
    Target.StartPos[I] := Source.StartPos[I];
  for I := Source.Length to Target.Length - 1 do
    Target.StartPos[I] := ' ';
end;

function S67Blanks(var Arena: TS67Arena; Count: Int32): TTextDescriptor;
var
  Buffer: PAnsiChar;
begin
  if Count < 0 then raise ERangeError.Create('blanks requires n >= 0');
  if Count = 0 then
  begin
    S67TextInit(Result, nil, 0);
    Exit;
  end;
  Buffer := PAnsiChar(S67ArenaAlloc(Arena, SizeUInt(Count), 8));
  FillChar(Buffer^, Count, Ord(' '));
  S67TextInit(Result, Buffer, Count);
end;

function S67Copy(var Arena: TS67Arena;
  const Source: TTextDescriptor): TTextDescriptor;
var
  Buffer: PAnsiChar;
begin
  if Source.Length <= 0 then
  begin
    S67TextInit(Result, nil, 0);
    Exit;
  end;
  Buffer := PAnsiChar(S67ArenaAlloc(Arena, SizeUInt(Source.Length), 8));
  Move(Source.StartPos^, Buffer^, Source.Length);
  S67TextInit(Result, Buffer, Source.Length);
end;


procedure S67AppendWritableData(var Data: TByteBuffer;
  out Offsets: TS67NativeDataOffsets);
begin
  BufferAlign(Data, 8, 0);
  Offsets.ArenaCursor := Data.Count;
  BufferAppendQWord(Data, 0);
  Offsets.ArenaEnd := Data.Count;
  BufferAppendQWord(Data, 0);

  BufferAlign(Data, 8, 0);
  Offsets.SysInObject := Data.Count;
  BufferAppendZeros(Data, 24);
  Offsets.SysOutObject := Data.Count;
  BufferAppendZeros(Data, 24);

  BufferAlign(Data, 8, 0);
  BufferAppendZeros(Data, 16); { hidden main/flags }
  Offsets.SysInDescriptor := Data.Count;
  BufferAppendZeros(Data, S67_TEXT_DESCRIPTOR_SIZE);
  Offsets.InputBuffer := Data.Count;
  BufferAppendZeros(Data, S67_DEFAULT_IMAGE_LENGTH);

  BufferAlign(Data, 8, 0);
  BufferAppendZeros(Data, 16);
  Offsets.SysOutDescriptor := Data.Count;
  BufferAppendZeros(Data, S67_TEXT_DESCRIPTOR_SIZE);
  Offsets.OutputBuffer := Data.Count;
  BufferAppendZeros(Data, S67_DEFAULT_IMAGE_LENGTH);

  BufferAlign(Data, 8, 0);
  Offsets.InputEOF := Data.Count;
  BufferAppendQWord(Data, 0);
  Offsets.CurrentLowTen := Data.Count;
  BufferAppendQWord(Data, Ord('&'));
  Offsets.CurrentDecimalMark := Data.Count;
  BufferAppendQWord(Data, Ord('.'));
end;

procedure S67AllocateNativeLabels(var Assembler: TX64Assembler;
  out Labels: TS67NativeLabels);
begin
  Labels := Default(TS67NativeLabels);
  Labels.Init := X64NewLabel(Assembler);
  Labels.SysIn := X64NewLabel(Assembler);
  Labels.SysOut := X64NewLabel(Assembler);
  Labels.InImage := X64NewLabel(Assembler);
  Labels.InChar := X64NewLabel(Assembler);
  Labels.InInt := X64NewLabel(Assembler);
  Labels.InReal := X64NewLabel(Assembler);
  Labels.LastItem := X64NewLabel(Assembler);
  Labels.EndFile := X64NewLabel(Assembler);
  Labels.OutImage := X64NewLabel(Assembler);
  Labels.OutChar := X64NewLabel(Assembler);
  Labels.OutText := X64NewLabel(Assembler);
  Labels.InText := X64NewLabel(Assembler);
  Labels.InFrac := X64NewLabel(Assembler);
  Labels.OutInt := X64NewLabel(Assembler);
  Labels.OutFix := X64NewLabel(Assembler);
  Labels.OutReal := X64NewLabel(Assembler);
  Labels.OutFrac := X64NewLabel(Assembler);
  Labels.Field := X64NewLabel(Assembler);
  Labels.ArenaAlloc := X64NewLabel(Assembler);
  Labels.TextConstant := X64NewLabel(Assembler);
  Labels.TextStart := X64NewLabel(Assembler);
  Labels.TextLength := X64NewLabel(Assembler);
  Labels.TextMain := X64NewLabel(Assembler);
  Labels.TextPos := X64NewLabel(Assembler);
  Labels.TextSetPos := X64NewLabel(Assembler);
  Labels.TextMore := X64NewLabel(Assembler);
  Labels.TextGetChar := X64NewLabel(Assembler);
  Labels.TextPutChar := X64NewLabel(Assembler);
  Labels.TextSub := X64NewLabel(Assembler);
  Labels.TextStrip := X64NewLabel(Assembler);
  Labels.TextGetInt := X64NewLabel(Assembler);
  Labels.TextGetReal := X64NewLabel(Assembler);
  Labels.TextGetFrac := X64NewLabel(Assembler);
  Labels.TextPutInt := X64NewLabel(Assembler);
  Labels.TextPutFix := X64NewLabel(Assembler);
  Labels.TextPutReal := X64NewLabel(Assembler);
  Labels.TextPutFrac := X64NewLabel(Assembler);
  Labels.TextWrite := X64NewLabel(Assembler);
  Labels.TextBlanks := X64NewLabel(Assembler);
  Labels.TextCopy := X64NewLabel(Assembler);
  Labels.TextAssign := X64NewLabel(Assembler);
  Labels.TextConcat := X64NewLabel(Assembler);
  Labels.TextEqual := X64NewLabel(Assembler);
  Labels.TextLeftAdjust := X64NewLabel(Assembler);
  Labels.LowTen := X64NewLabel(Assembler);
  Labels.DecimalMark := X64NewLabel(Assembler);
  Labels.Upcase := X64NewLabel(Assembler);
  Labels.Lowcase := X64NewLabel(Assembler);
  Labels.MathSqrt := X64NewLabel(Assembler);
  Labels.MathSin := X64NewLabel(Assembler);
  Labels.MathCos := X64NewLabel(Assembler);
  Labels.MathTan := X64NewLabel(Assembler);
  Labels.MathArctan := X64NewLabel(Assembler);
  Labels.MathLn := X64NewLabel(Assembler);
  Labels.MathLog10 := X64NewLabel(Assembler);
  Labels.MathExp := X64NewLabel(Assembler);
end;

procedure EmitS67Init(var A: TX64Assembler; LabelId: Int32;
  const D: TS67NativeDataOffsets);
var
  FillInput, FillOutput, InputDone, OutputDone: Int32;
begin
  FillInput := X64NewLabel(A);
  FillOutput := X64NewLabel(A);
  InputDone := X64NewLabel(A);
  OutputDone := X64NewLabel(A);
  X64BindLabel(A, LabelId);

  X64LeaRegRipWritable(A, xrR8, D.SysInObject, 0);
  X64LeaRegRipWritable(A, xrR9, D.SysInDescriptor, 0);
  X64MovMemBaseDispReg(A, xrR8, 16, xrR9);
  X64MovMemBaseDispReg(A, xrR9, -16, xrR9);
  X64MovRegImm64(A, xrR10, 1);
  X64MovMemBaseDispReg(A, xrR9, -8, xrR10);
  X64LeaRegRipWritable(A, xrR11, D.InputBuffer, 0);
  X64MovMemBaseDispReg(A, xrR9, S67_TEXT_START_OFFSET, xrR11);
  X64MovMemBaseDispReg32(A, xrR9, S67_TEXT_POS_OFFSET, xrR10);
  X64MovRegImm64(A, xrR10, S67_DEFAULT_IMAGE_LENGTH);
  X64MovMemBaseDispReg32(A, xrR9, S67_TEXT_LENGTH_OFFSET, xrR10);

  X64LeaRegRipWritable(A, xrR8, D.SysOutObject, 0);
  X64LeaRegRipWritable(A, xrR9, D.SysOutDescriptor, 0);
  X64MovMemBaseDispReg(A, xrR8, 16, xrR9);
  X64MovMemBaseDispReg(A, xrR9, -16, xrR9);
  X64MovRegImm64(A, xrR10, 1);
  X64MovMemBaseDispReg(A, xrR9, -8, xrR10);
  X64LeaRegRipWritable(A, xrR11, D.OutputBuffer, 0);
  X64MovMemBaseDispReg(A, xrR9, S67_TEXT_START_OFFSET, xrR11);
  X64MovMemBaseDispReg32(A, xrR9, S67_TEXT_POS_OFFSET, xrR10);
  X64MovRegImm64(A, xrR10, S67_DEFAULT_IMAGE_LENGTH);
  X64MovMemBaseDispReg32(A, xrR9, S67_TEXT_LENGTH_OFFSET, xrR10);

  X64MovRegImm64(A, xrRAX, Ord(' '));
  X64LeaRegRipWritable(A, xrRDI, D.InputBuffer, 0);
  X64MovRegImm64(A, xrRCX, S67_DEFAULT_IMAGE_LENGTH);
  X64BindLabel(A, FillInput);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, InputDone);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRAX);
  X64AddRegImm32(A, xrRDI, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, FillInput);
  X64BindLabel(A, InputDone);

  X64LeaRegRipWritable(A, xrRDI, D.OutputBuffer, 0);
  X64MovRegImm64(A, xrRCX, S67_DEFAULT_IMAGE_LENGTH);
  X64BindLabel(A, FillOutput);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, OutputDone);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRAX);
  X64AddRegImm32(A, xrRDI, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, FillOutput);
  X64BindLabel(A, OutputDone);
  X64LeaRegRipWritable(A, xrRDI, D.InputEOF, 0);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64MovMemBaseDispReg(A, xrRDI, 0, xrRAX);
  X64Ret(A);
end;

procedure EmitS67SysIn(var A: TX64Assembler; LabelId: Int32;
  const D: TS67NativeDataOffsets);
begin
  X64BindLabel(A, LabelId);
  X64LeaRegRipWritable(A, xrRAX, D.SysInObject, 0);
  X64Ret(A);
end;

procedure EmitS67SysOut(var A: TX64Assembler; LabelId: Int32;
  const D: TS67NativeDataOffsets);
begin
  X64BindLabel(A, LabelId);
  X64LeaRegRipWritable(A, xrRAX, D.SysOutObject, 0);
  X64Ret(A);
end;

procedure EmitS67InImage(var A: TX64Assembler; LabelId: Int32;
  const D: TS67NativeDataOffsets; const Links: TS67NativeLinks);
const
  SYS_READ = 0;
var
  ReadLoop, GotByte, EndLine, AtCapacity, FillRest, Filled, SetEOF,
  SkipCR, FirstRead: Int32;
begin
  ReadLoop := X64NewLabel(A);
  GotByte := X64NewLabel(A);
  EndLine := X64NewLabel(A);
  AtCapacity := X64NewLabel(A);
  FillRest := X64NewLabel(A);
  Filled := X64NewLabel(A);
  SetEOF := X64NewLabel(A);
  SkipCR := X64NewLabel(A);
  FirstRead := X64NewLabel(A);
  X64BindLabel(A, LabelId);

  { Calling inimage after endfile is already true is an old Simula runtime error. }
  X64LeaRegRipWritable(A, xrRAX, D.InputEOF, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrRAX, 0);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, FirstRead);
  X64Jump(A, Links.PanicText);
  X64BindLabel(A, FirstRead);

  X64PushReg(A, xrRBP);
  X64MovRegReg(A, xrRBP, xrRSP);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64SubRegImm32(A, xrRSP, 16);
  X64LeaRegRipWritable(A, xrR12, D.InputBuffer, 0);
  X64XorRegReg(A, xrR13, xrR13);

  X64BindLabel(A, ReadLoop);
  X64MovRegImm64(A, xrRAX, SYS_READ);
  X64XorRegReg(A, xrRDI, xrRDI);
  X64LeaRegBaseDisp(A, xrRSI, xrRSP, 0);
  X64MovRegImm64(A, xrRDX, 1);
  X64Syscall(A);
  X64CmpRegImm32(A, xrRAX, 1);
  X64JumpCondition(A, xcEqual, GotByte);
  X64Jump(A, SetEOF);

  X64BindLabel(A, GotByte);
  X64MovRegMemBaseDisp8(A, xrRAX, xrRSP, 0);
  X64CmpRegImm32(A, xrRAX, 10);
  X64JumpCondition(A, xcEqual, EndLine);
  { Linux gives us LF. Ignore CR so CRLF input doesn't create a phantom blank image. }
  X64CmpRegImm32(A, xrRAX, 13);
  X64JumpCondition(A, xcEqual, SkipCR);
  X64CmpRegImm32(A, xrR13, S67_DEFAULT_IMAGE_LENGTH);
  X64JumpCondition(A, xcGreaterEqual, AtCapacity);
  X64MovRegReg(A, xrRCX, xrR12);
  X64AddRegReg(A, xrRCX, xrR13);
  X64MovMemBaseDispReg8(A, xrRCX, 0, xrRAX);
  X64AddRegImm32(A, xrR13, 1);
  X64BindLabel(A, AtCapacity);
  X64Jump(A, ReadLoop);
  X64BindLabel(A, SkipCR);
  X64Jump(A, ReadLoop);

  X64BindLabel(A, SetEOF);
  X64LeaRegRipWritable(A, xrRCX, D.InputEOF, 0);
  X64MovRegImm64(A, xrRAX, 1);
  X64MovMemBaseDispReg(A, xrRCX, 0, xrRAX);

  X64BindLabel(A, EndLine);
  X64MovRegReg(A, xrRCX, xrR13);
  X64BindLabel(A, FillRest);
  X64CmpRegImm32(A, xrRCX, S67_DEFAULT_IMAGE_LENGTH);
  X64JumpCondition(A, xcGreaterEqual, Filled);
  X64MovRegReg(A, xrRDX, xrR12);
  X64AddRegReg(A, xrRDX, xrRCX);
  X64MovRegImm64(A, xrRAX, Ord(' '));
  X64MovMemBaseDispReg8(A, xrRDX, 0, xrRAX);
  X64AddRegImm32(A, xrRCX, 1);
  X64Jump(A, FillRest);

  X64BindLabel(A, Filled);
  X64LeaRegRipWritable(A, xrRDI, D.SysInDescriptor, 0);
  X64MovRegImm64(A, xrRAX, 1);
  X64MovMemBaseDispReg32(A, xrRDI, S67_TEXT_POS_OFFSET, xrRAX);
  X64AddRegImm32(A, xrRSP, 16);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64Leave(A);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitS67InChar(var A: TX64Assembler; LabelId, InImageLabel,
  GetCharLabel: Int32; const D: TS67NativeDataOffsets;
  const Links: TS67NativeLinks);
var
  HaveChar, NeedImage: Int32;
begin
  HaveChar := X64NewLabel(A);
  NeedImage := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64LeaRegRipWritable(A, xrRDI, D.SysInDescriptor, 0);
  X64MovSXRegMemBaseDisp32(A, xrRAX, xrRDI, S67_TEXT_POS_OFFSET);
  X64MovSXRegMemBaseDisp32(A, xrRCX, xrRDI, S67_TEXT_LENGTH_OFFSET);
  X64CmpRegReg(A, xrRAX, xrRCX);
  X64JumpCondition(A, xcLessEqual, HaveChar);
  X64Jump(A, NeedImage);

  X64BindLabel(A, NeedImage);
  X64LeaRegRipWritable(A, xrRAX, D.InputEOF, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrRAX, 0);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcNotEqual, Links.PanicText);
  X64Call(A, InImageLabel);
  X64LeaRegRipWritable(A, xrRDI, D.SysInDescriptor, 0);

  X64BindLabel(A, HaveChar);
  X64Jump(A, GetCharLabel);
end;

procedure EmitS67InNumber(var A: TX64Assembler; LabelId, LastItemLabel,
  ParseLabel: Int32; const D: TS67NativeDataOffsets;
  const Links: TS67NativeLinks);
var
  HaveItem: Int32;
begin
  HaveItem := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64Call(A, LastItemLabel);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, HaveItem);
  X64Jump(A, Links.PanicText);
  X64BindLabel(A, HaveItem);
  X64LeaRegRipWritable(A, xrRDI, D.SysInDescriptor, 0);
  X64Jump(A, ParseLabel);
end;

procedure EmitS67LastItem(var A: TX64Assembler; LabelId, InImageLabel: Int32;
  const D: TS67NativeDataOffsets);
var
  Scan, IsLast, NotLast, SkipBlank, NeedImage: Int32;
begin
  Scan := X64NewLabel(A);
  IsLast := X64NewLabel(A);
  NotLast := X64NewLabel(A);
  SkipBlank := X64NewLabel(A);
  NeedImage := X64NewLabel(A);
  X64BindLabel(A, LabelId);

  X64BindLabel(A, Scan);
  X64LeaRegRipWritable(A, xrR8, D.SysInDescriptor, 0);
  X64MovSXRegMemBaseDisp32(A, xrRCX, xrR8, S67_TEXT_POS_OFFSET);
  X64MovSXRegMemBaseDisp32(A, xrRDX, xrR8, S67_TEXT_LENGTH_OFFSET);
  X64CmpRegReg(A, xrRCX, xrRDX);
  X64JumpCondition(A, xcGreater, NeedImage);
  X64MovRegMemBaseDisp(A, xrR9, xrR8, S67_TEXT_START_OFFSET);
  X64AddRegReg(A, xrR9, xrRCX);
  X64MovRegMemBaseDisp8(A, xrRAX, xrR9, -1);
  X64CmpRegImm32(A, xrRAX, Ord(' '));
  X64JumpCondition(A, xcEqual, SkipBlank);
  X64CmpRegImm32(A, xrRAX, 9);
  X64JumpCondition(A, xcNotEqual, NotLast);

  X64BindLabel(A, SkipBlank);
  X64AddRegImm32(A, xrRCX, 1);
  X64MovMemBaseDispReg32(A, xrR8, S67_TEXT_POS_OFFSET, xrRCX);
  X64Jump(A, Scan);

  X64BindLabel(A, NeedImage);
  X64LeaRegRipWritable(A, xrRAX, D.InputEOF, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrRAX, 0);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcNotEqual, IsLast);
  X64Call(A, InImageLabel);
  X64Jump(A, Scan);

  X64BindLabel(A, IsLast);
  X64MovRegImm64(A, xrRAX, 1);
  X64Ret(A);
  X64BindLabel(A, NotLast);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitS67EndFile(var A: TX64Assembler; LabelId: Int32;
  const D: TS67NativeDataOffsets);
begin
  X64BindLabel(A, LabelId);
  X64LeaRegRipWritable(A, xrRAX, D.InputEOF, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrRAX, 0);
  X64Ret(A);
end;

procedure EmitS67OutImage(var A: TX64Assembler; LabelId: Int32;
  const D: TS67NativeDataOffsets; const Links: TS67NativeLinks);
var
  TrimLoop, WriteLine, NewLineDone, FillLoop, Filled: Int32;
begin
  TrimLoop := X64NewLabel(A);
  WriteLine := X64NewLabel(A);
  NewLineDone := X64NewLabel(A);
  FillLoop := X64NewLabel(A);
  Filled := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64PushReg(A, xrRBP);
  X64MovRegReg(A, xrRBP, xrRSP);
  X64SubRegImm32(A, xrRSP, 16);
  X64LeaRegRipWritable(A, xrR8, D.SysOutDescriptor, 0);
  X64MovSXRegMemBaseDisp32(A, xrRCX, xrR8, S67_TEXT_POS_OFFSET);
  X64SubRegImm32(A, xrRCX, 1);
  X64LeaRegRipWritable(A, xrR9, D.OutputBuffer, 0);
  X64BindLabel(A, TrimLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, WriteLine);
  X64MovRegReg(A, xrR10, xrR9);
  X64AddRegReg(A, xrR10, xrRCX);
  X64MovRegMemBaseDisp8(A, xrRAX, xrR10, -1);
  X64CmpRegImm32(A, xrRAX, Ord(' '));
  X64JumpCondition(A, xcNotEqual, WriteLine);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, TrimLoop);
  X64BindLabel(A, WriteLine);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, NewLineDone);
  X64MovRegReg(A, xrRDI, xrR9);
  X64MovRegReg(A, xrRSI, xrRCX);
  X64Call(A, Links.WriteRaw);
  X64BindLabel(A, NewLineDone);
  X64MovRegImm64(A, xrRAX, 10);
  X64MovMemBaseDispReg8(A, xrRSP, 0, xrRAX);
  X64LeaRegBaseDisp(A, xrRDI, xrRSP, 0);
  X64MovRegImm64(A, xrRSI, 1);
  X64Call(A, Links.WriteRaw);

  X64LeaRegRipWritable(A, xrRDI, D.OutputBuffer, 0);
  X64MovRegImm64(A, xrRCX, S67_DEFAULT_IMAGE_LENGTH);
  X64MovRegImm64(A, xrRDX, Ord(' '));
  X64BindLabel(A, FillLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, Filled);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRDX);
  X64AddRegImm32(A, xrRDI, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, FillLoop);
  X64BindLabel(A, Filled);
  X64LeaRegRipWritable(A, xrR8, D.SysOutDescriptor, 0);
  X64MovRegImm64(A, xrRAX, 1);
  X64MovMemBaseDispReg32(A, xrR8, S67_TEXT_POS_OFFSET, xrRAX);
  X64AddRegImm32(A, xrRSP, 16);
  X64Leave(A);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitS67OutChar(var A: TX64Assembler; LabelId, OutImageLabel,
  PutCharLabel: Int32; const D: TS67NativeDataOffsets);
var
  HaveRoom: Int32;
begin
  HaveRoom := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64PushReg(A, xrR12);
  X64MovRegReg(A, xrR12, xrRSI);
  X64LeaRegRipWritable(A, xrRDI, D.SysOutDescriptor, 0);
  X64MovSXRegMemBaseDisp32(A, xrRAX, xrRDI, S67_TEXT_POS_OFFSET);
  X64CmpRegImm32(A, xrRAX, S67_DEFAULT_IMAGE_LENGTH);
  X64JumpCondition(A, xcLessEqual, HaveRoom);
  X64Call(A, OutImageLabel);
  X64BindLabel(A, HaveRoom);
  X64LeaRegRipWritable(A, xrRDI, D.SysOutDescriptor, 0);
  X64MovRegReg(A, xrRSI, xrR12);
  X64Call(A, PutCharLabel);
  X64PopReg(A, xrR12);
  X64Ret(A);
end;

procedure EmitS67OutText(var A: TX64Assembler; LabelId, OutImageLabel: Int32;
  const D: TS67NativeDataOffsets; const Links: TS67NativeLinks);
var
  LoopStart, HaveRoom, UseRemaining, HaveChunk, CopyLoop, AfterCopy,
  Done: Int32;
begin
  LoopStart := X64NewLabel(A);
  HaveRoom := X64NewLabel(A);
  UseRemaining := X64NewLabel(A);
  HaveChunk := X64NewLabel(A);
  CopyLoop := X64NewLabel(A);
  AfterCopy := X64NewLabel(A);
  Done := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64MovRegReg(A, xrR12, xrRSI);
  X64TestRegReg(A, xrR12, xrR12);
  X64JumpCondition(A, xcEqual, Done);
  X64MovRegMemBaseDisp(A, xrR13, xrR12, S67_TEXT_START_OFFSET);
  X64MovSXRegMemBaseDisp32(A, xrR14, xrR12, S67_TEXT_LENGTH_OFFSET);

  X64BindLabel(A, LoopStart);
  X64TestRegReg(A, xrR14, xrR14);
  X64JumpCondition(A, xcEqual, Done);
  X64LeaRegRipWritable(A, xrR8, D.SysOutDescriptor, 0);
  X64MovSXRegMemBaseDisp32(A, xrRAX, xrR8, S67_TEXT_POS_OFFSET);
  X64CmpRegImm32(A, xrRAX, S67_DEFAULT_IMAGE_LENGTH);
  X64JumpCondition(A, xcLessEqual, HaveRoom);
  X64Call(A, OutImageLabel);
  X64LeaRegRipWritable(A, xrR8, D.SysOutDescriptor, 0);
  X64MovSXRegMemBaseDisp32(A, xrRAX, xrR8, S67_TEXT_POS_OFFSET);

  X64BindLabel(A, HaveRoom);
  { r9 = number of characters still available in the current image. }
  X64MovRegImm64(A, xrR9, S67_DEFAULT_IMAGE_LENGTH + 1);
  X64SubRegReg(A, xrR9, xrRAX);
  X64MovRegReg(A, xrRCX, xrR9);
  X64CmpRegReg(A, xrR14, xrR9);
  X64JumpCondition(A, xcGreater, HaveChunk);
  X64BindLabel(A, UseRemaining);
  X64MovRegReg(A, xrRCX, xrR14);
  X64BindLabel(A, HaveChunk);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, Done);

  X64LeaRegRipWritable(A, xrRDX, D.OutputBuffer, 0);
  X64AddRegReg(A, xrRDX, xrRAX);
  X64SubRegImm32(A, xrRDX, 1);
  X64MovRegReg(A, xrR10, xrRCX);
  X64BindLabel(A, CopyLoop);
  X64MovRegMemBaseDisp8(A, xrR11, xrR13, 0);
  X64MovMemBaseDispReg8(A, xrRDX, 0, xrR11);
  X64AddRegImm32(A, xrR13, 1);
  X64AddRegImm32(A, xrRDX, 1);
  X64SubRegImm32(A, xrR10, 1);
  X64JumpCondition(A, xcNotEqual, CopyLoop);

  X64BindLabel(A, AfterCopy);
  X64AddRegReg(A, xrRAX, xrRCX);
  X64MovMemBaseDispReg32(A, xrR8, S67_TEXT_POS_OFFSET, xrRAX);
  X64SubRegReg(A, xrR14, xrRCX);
  X64TestRegReg(A, xrR14, xrR14);
  X64JumpCondition(A, xcEqual, Done);
  X64Call(A, OutImageLabel);
  X64Jump(A, LoopStart);

  X64BindLabel(A, Done);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitS67InText(var A: TX64Assembler; LabelId, InCharLabel,
  BlanksLabel, PutCharLabel: Int32; const Links: TS67NativeLinks);
var
  LoopStart, Done: Int32;
begin
  LoopStart := X64NewLabel(A);
  Done := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64PushReg(A, xrR12);
  X64MovRegReg(A, xrRDI, xrRSI);
  X64Call(A, BlanksLabel);
  X64MovRegReg(A, xrR12, xrRAX);
  X64TestRegReg(A, xrR12, xrR12);
  X64JumpCondition(A, xcEqual, Done);
  X64BindLabel(A, LoopStart);
  X64MovSXRegMemBaseDisp32(A, xrRAX, xrR12, S67_TEXT_POS_OFFSET);
  X64MovSXRegMemBaseDisp32(A, xrRCX, xrR12, S67_TEXT_LENGTH_OFFSET);
  X64CmpRegReg(A, xrRAX, xrRCX);
  X64JumpCondition(A, xcGreater, Done);
  X64Call(A, InCharLabel);
  X64MovRegReg(A, xrRDI, xrR12);
  X64MovRegReg(A, xrRSI, xrRAX);
  X64Call(A, PutCharLabel);
  X64Jump(A, LoopStart);
  X64BindLabel(A, Done);
  X64MovRegReg(A, xrRAX, xrR12);
  X64PopReg(A, xrR12);
  X64Ret(A);
end;

procedure EmitS67Field(var A: TX64Assembler; LabelId, OutImageLabel,
  TextSubLabel: Int32; const D: TS67NativeDataOffsets;
  const Links: TS67NativeLinks);
var
  HaveRoom: Int32;
begin
  HaveRoom := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64MovRegReg(A, xrR12, xrRSI);
  X64CmpRegImm32(A, xrR12, 1);
  X64JumpCondition(A, xcLess, Links.PanicText);
  X64CmpRegImm32(A, xrR12, S67_DEFAULT_IMAGE_LENGTH);
  X64JumpCondition(A, xcGreater, Links.PanicText);
  X64LeaRegRipWritable(A, xrR8, D.SysOutDescriptor, 0);
  X64MovSXRegMemBaseDisp32(A, xrR13, xrR8, S67_TEXT_POS_OFFSET);
  X64MovRegReg(A, xrRAX, xrR13);
  X64AddRegReg(A, xrRAX, xrR12);
  X64SubRegImm32(A, xrRAX, 1);
  X64CmpRegImm32(A, xrRAX, S67_DEFAULT_IMAGE_LENGTH);
  X64JumpCondition(A, xcLessEqual, HaveRoom);
  X64Call(A, OutImageLabel);
  X64LeaRegRipWritable(A, xrR8, D.SysOutDescriptor, 0);
  X64MovSXRegMemBaseDisp32(A, xrR13, xrR8, S67_TEXT_POS_OFFSET);
  X64BindLabel(A, HaveRoom);
  X64LeaRegRipWritable(A, xrRDI, D.SysOutDescriptor, 0);
  X64MovRegReg(A, xrRSI, xrR13);
  X64MovRegReg(A, xrRDX, xrR12);
  X64Call(A, TextSubLabel);
  X64MovRegReg(A, xrR9, xrR13);
  X64AddRegReg(A, xrR9, xrR12);
  X64LeaRegRipWritable(A, xrR8, D.SysOutDescriptor, 0);
  X64MovMemBaseDispReg32(A, xrR8, S67_TEXT_POS_OFFSET, xrR9);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64Ret(A);
end;

procedure EmitS67TextLeftAdjust(var A: TX64Assembler; LabelId: Int32);
var
  Scan, ScanDone, CopyLoop, FillLoop, Done: Int32;
begin
  Scan := X64NewLabel(A);
  ScanDone := X64NewLabel(A);
  CopyLoop := X64NewLabel(A);
  FillLoop := X64NewLabel(A);
  Done := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, Done);
  X64MovRegMemBaseDisp(A, xrR9, xrRDI, S67_TEXT_START_OFFSET);
  X64MovSXRegMemBaseDisp32(A, xrR10, xrRDI, S67_TEXT_LENGTH_OFFSET);
  X64XorRegReg(A, xrR8, xrR8);
  X64BindLabel(A, Scan);
  X64CmpRegReg(A, xrR8, xrR10);
  X64JumpCondition(A, xcGreaterEqual, Done);
  X64MovRegReg(A, xrRCX, xrR9);
  X64AddRegReg(A, xrRCX, xrR8);
  X64MovRegMemBaseDisp8(A, xrRAX, xrRCX, 0);
  X64CmpRegImm32(A, xrRAX, Ord(' '));
  X64JumpCondition(A, xcNotEqual, ScanDone);
  X64AddRegImm32(A, xrR8, 1);
  X64Jump(A, Scan);
  X64BindLabel(A, ScanDone);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Done);
  X64MovRegReg(A, xrRSI, xrR9);
  X64AddRegReg(A, xrRSI, xrR8);
  X64MovRegReg(A, xrRDX, xrR9);
  X64MovRegReg(A, xrRCX, xrR10);
  X64SubRegReg(A, xrRCX, xrR8);
  X64BindLabel(A, CopyLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, FillLoop);
  X64MovRegMemBaseDisp8(A, xrRAX, xrRSI, 0);
  X64MovMemBaseDispReg8(A, xrRDX, 0, xrRAX);
  X64AddRegImm32(A, xrRSI, 1);
  X64AddRegImm32(A, xrRDX, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, CopyLoop);
  X64BindLabel(A, FillLoop);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Done);
  X64MovRegImm64(A, xrRAX, Ord(' '));
  X64MovMemBaseDispReg8(A, xrRDX, 0, xrRAX);
  X64AddRegImm32(A, xrRDX, 1);
  X64SubRegImm32(A, xrR8, 1);
  X64Jump(A, FillLoop);
  X64BindLabel(A, Done);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitS67OutInt(var A: TX64Assembler; LabelId, FieldLabel,
  BlanksLabel, TextSubLabel, PutIntLabel, LeftAdjustLabel,
  OutTextLabel: Int32; const Links: TS67NativeLinks);
var
  FixedWidth, ExactWidth, RightDone, Scan, ScanDone: Int32;
begin
  FixedWidth := X64NewLabel(A);
  ExactWidth := X64NewLabel(A);
  RightDone := X64NewLabel(A);
  Scan := X64NewLabel(A);
  ScanDone := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64PushReg(A, xrR15);
  X64MovRegReg(A, xrR12, xrRDI); { receiver }
  X64MovRegReg(A, xrR13, xrRSI); { value }
  X64MovRegReg(A, xrR14, xrRDX); { width }
  X64TestRegReg(A, xrR14, xrR14);
  X64JumpCondition(A, xcEqual, ExactWidth);

  X64MovRegReg(A, xrRSI, xrR14);
  X64CmpRegImm32(A, xrRSI, 0);
  X64JumpCondition(A, xcGreater, FixedWidth);
  X64NegReg(A, xrRSI);
  X64JumpCondition(A, xcOverflow, Links.PanicText);
  X64BindLabel(A, FixedWidth);
  X64MovRegReg(A, xrRDI, xrR12);
  X64Call(A, FieldLabel);
  X64MovRegReg(A, xrR15, xrRAX);
  X64MovRegReg(A, xrRDI, xrR15);
  X64MovRegReg(A, xrRSI, xrR13);
  X64Call(A, PutIntLabel);
  X64CmpRegImm32(A, xrR14, 0);
  X64JumpCondition(A, xcGreater, RightDone);
  X64MovRegReg(A, xrRDI, xrR15);
  X64Call(A, LeftAdjustLabel);
  X64Jump(A, RightDone);

  X64BindLabel(A, ExactWidth);
  X64MovRegImm64(A, xrRDI, 32);
  X64Call(A, BlanksLabel);
  X64MovRegReg(A, xrR15, xrRAX);
  X64MovRegReg(A, xrRDI, xrR15);
  X64MovRegReg(A, xrRSI, xrR13);
  X64Call(A, PutIntLabel);
  X64MovRegMemBaseDisp(A, xrR8, xrR15, S67_TEXT_START_OFFSET);
  X64XorRegReg(A, xrR9, xrR9);
  X64BindLabel(A, Scan);
  X64CmpRegImm32(A, xrR9, 32);
  X64JumpCondition(A, xcGreaterEqual, Links.PanicText);
  X64MovRegReg(A, xrRCX, xrR8);
  X64AddRegReg(A, xrRCX, xrR9);
  X64MovRegMemBaseDisp8(A, xrRAX, xrRCX, 0);
  X64CmpRegImm32(A, xrRAX, Ord(' '));
  X64JumpCondition(A, xcNotEqual, ScanDone);
  X64AddRegImm32(A, xrR9, 1);
  X64Jump(A, Scan);
  X64BindLabel(A, ScanDone);
  X64MovRegReg(A, xrRDI, xrR15);
  X64MovRegReg(A, xrRSI, xrR9);
  X64AddRegImm32(A, xrRSI, 1);
  X64MovRegImm64(A, xrRDX, 32);
  X64SubRegReg(A, xrRDX, xrR9);
  X64Call(A, TextSubLabel);
  X64MovRegReg(A, xrRSI, xrRAX);
  X64MovRegReg(A, xrRDI, xrR12);
  X64Call(A, OutTextLabel);

  X64BindLabel(A, RightDone);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitS67OutRealLike(var A: TX64Assembler; LabelId, FieldLabel,
  BlanksLabel, TextSubLabel, EditorLabel, LeftAdjustLabel,
  OutTextLabel: Int32; const Links: TS67NativeLinks);
var
  FixedWidth, ExactWidth, RightDone, Scan, ScanDone: Int32;
begin
  FixedWidth := X64NewLabel(A);
  ExactWidth := X64NewLabel(A);
  RightDone := X64NewLabel(A);
  Scan := X64NewLabel(A);
  ScanDone := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64PushReg(A, xrR15);
  X64PushReg(A, xrRBX);
  X64MovRegReg(A, xrR12, xrRDI); { receiver }
  X64MovRegReg(A, xrR13, xrRSI); { real/integer payload }
  X64MovRegReg(A, xrR14, xrRDX); { editing n }
  X64MovRegReg(A, xrRBX, xrRCX); { field width }
  X64TestRegReg(A, xrRBX, xrRBX);
  X64JumpCondition(A, xcEqual, ExactWidth);

  X64MovRegReg(A, xrRSI, xrRBX);
  X64CmpRegImm32(A, xrRSI, 0);
  X64JumpCondition(A, xcGreater, FixedWidth);
  X64NegReg(A, xrRSI);
  X64JumpCondition(A, xcOverflow, Links.PanicText);
  X64BindLabel(A, FixedWidth);
  X64MovRegReg(A, xrRDI, xrR12);
  X64Call(A, FieldLabel);
  X64MovRegReg(A, xrR15, xrRAX);
  X64MovRegReg(A, xrRDI, xrR15);
  X64MovRegReg(A, xrRSI, xrR13);
  X64MovRegReg(A, xrRDX, xrR14);
  X64Call(A, EditorLabel);
  X64CmpRegImm32(A, xrRBX, 0);
  X64JumpCondition(A, xcGreater, RightDone);
  X64MovRegReg(A, xrRDI, xrR15);
  X64Call(A, LeftAdjustLabel);
  X64Jump(A, RightDone);

  X64BindLabel(A, ExactWidth);
  X64MovRegImm64(A, xrRDI, S67_DEFAULT_IMAGE_LENGTH);
  X64Call(A, BlanksLabel);
  X64MovRegReg(A, xrR15, xrRAX);
  X64MovRegReg(A, xrRDI, xrR15);
  X64MovRegReg(A, xrRSI, xrR13);
  X64MovRegReg(A, xrRDX, xrR14);
  X64Call(A, EditorLabel);
  X64MovRegMemBaseDisp(A, xrR8, xrR15, S67_TEXT_START_OFFSET);
  X64XorRegReg(A, xrR9, xrR9);
  X64BindLabel(A, Scan);
  X64CmpRegImm32(A, xrR9, S67_DEFAULT_IMAGE_LENGTH);
  X64JumpCondition(A, xcGreaterEqual, Links.PanicText);
  X64MovRegReg(A, xrRCX, xrR8);
  X64AddRegReg(A, xrRCX, xrR9);
  X64MovRegMemBaseDisp8(A, xrRAX, xrRCX, 0);
  X64CmpRegImm32(A, xrRAX, Ord(' '));
  X64JumpCondition(A, xcNotEqual, ScanDone);
  X64AddRegImm32(A, xrR9, 1);
  X64Jump(A, Scan);
  X64BindLabel(A, ScanDone);
  X64CmpRegImm32(A, xrRAX, Ord('*'));
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64MovRegReg(A, xrRDI, xrR15);
  X64MovRegReg(A, xrRSI, xrR9);
  X64AddRegImm32(A, xrRSI, 1);
  X64MovRegImm64(A, xrRDX, S67_DEFAULT_IMAGE_LENGTH);
  X64SubRegReg(A, xrRDX, xrR9);
  X64Call(A, TextSubLabel);
  X64MovRegReg(A, xrRSI, xrRAX);
  X64MovRegReg(A, xrRDI, xrR12);
  X64Call(A, OutTextLabel);

  X64BindLabel(A, RightDone);
  X64PopReg(A, xrRBX);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitS67ArenaAlloc(var A: TX64Assembler; LabelId: Int32;
  const D: TS67NativeDataOffsets; const Links: TS67NativeLinks);
var
  NeedPage, SizeReady, HaveSpace: Int32;
begin
  NeedPage := X64NewLabel(A);
  SizeReady := X64NewLabel(A);
  HaveSpace := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64AddRegImm32(A, xrRDI, 7);
  X64AndRegImm32(A, xrRDI, -8);
  X64PushReg(A, xrR12);
  X64MovRegReg(A, xrR12, xrRDI);
  X64LeaRegRipWritable(A, xrR10, D.ArenaCursor, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrR10, 0);
  X64LeaRegRipWritable(A, xrR11, D.ArenaEnd, 0);
  X64MovRegMemBaseDisp(A, xrRCX, xrR11, 0);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, NeedPage);
  X64MovRegReg(A, xrRDX, xrRAX);
  X64AddRegReg(A, xrRDX, xrR12);
  X64CmpRegReg(A, xrRDX, xrRCX);
  X64JumpCondition(A, xcBelowEqual, HaveSpace);

  X64BindLabel(A, NeedPage);
  X64MovRegImm64(A, xrRDI, 65536);
  X64CmpRegReg(A, xrR12, xrRDI);
  X64JumpCondition(A, xcBelowEqual, SizeReady);
  X64MovRegReg(A, xrRDI, xrR12);
  X64AddRegImm32(A, xrRDI, 4095);
  X64AndRegImm32(A, xrRDI, -4096);
  X64BindLabel(A, SizeReady);
  X64PushReg(A, xrRDI);
  X64Call(A, Links.Allocate);
  X64PopReg(A, xrRCX);
  X64MovRegReg(A, xrRDX, xrRAX);
  X64AddRegReg(A, xrRDX, xrRCX);
  X64LeaRegRipWritable(A, xrR11, D.ArenaEnd, 0);
  X64MovMemBaseDispReg(A, xrR11, 0, xrRDX);
  X64MovRegReg(A, xrRDX, xrRAX);
  X64AddRegReg(A, xrRDX, xrR12);
  X64LeaRegRipWritable(A, xrR10, D.ArenaCursor, 0);
  X64MovMemBaseDispReg(A, xrR10, 0, xrRDX);
  X64PopReg(A, xrR12);
  X64Ret(A);

  X64BindLabel(A, HaveSpace);
  X64MovMemBaseDispReg(A, xrR10, 0, xrRDX);
  X64PopReg(A, xrR12);
  X64Ret(A);
end;

procedure EmitS67TextConstant(var A: TX64Assembler; LabelId: Int32);
var
  Done, ConstantFrame: Int32;
begin
  Done := X64NewLabel(A);
  ConstantFrame := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, ConstantFrame);
  X64MovRegMemBaseDisp(A, xrRAX, xrRDI, -8);
  X64AndRegImm32(A, xrRAX, 1);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, ConstantFrame);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Jump(A, Done);
  X64BindLabel(A, ConstantFrame);
  X64MovRegImm64(A, xrRAX, 1);
  X64BindLabel(A, Done);
  X64Ret(A);
end;

procedure EmitS67TextStart(var A: TX64Assembler; LabelId: Int32);
var
  NilText, HaveMain, Done: Int32;
begin
  NilText := X64NewLabel(A);
  HaveMain := X64NewLabel(A);
  Done := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, NilText);
  X64MovRegMemBaseDisp(A, xrR8, xrRDI, -16);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcNotEqual, HaveMain);
  X64MovRegReg(A, xrR8, xrRDI);
  X64BindLabel(A, HaveMain);
  X64MovRegMemBaseDisp(A, xrRAX, xrRDI, S67_TEXT_START_OFFSET);
  X64MovRegMemBaseDisp(A, xrRCX, xrR8, S67_TEXT_START_OFFSET);
  X64SubRegReg(A, xrRAX, xrRCX);
  X64AddRegImm32(A, xrRAX, 1);
  X64Jump(A, Done);
  X64BindLabel(A, NilText);
  X64MovRegImm64(A, xrRAX, 1);
  X64BindLabel(A, Done);
  X64Ret(A);
end;

procedure EmitS67TextLength(var A: TX64Assembler; LabelId: Int32);
var
  Done: Int32;
begin
  Done := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, Done);
  X64MovSXRegMemBaseDisp32(A, xrRAX, xrRDI, S67_TEXT_LENGTH_OFFSET);
  X64BindLabel(A, Done);
  X64Ret(A);
end;

procedure EmitS67TextMain(var A: TX64Assembler; LabelId: Int32);
var
  Done, ReturnStored: Int32;
begin
  Done := X64NewLabel(A);
  ReturnStored := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, Done);
  X64MovRegMemBaseDisp(A, xrRAX, xrRDI, -16);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcNotEqual, ReturnStored);
  X64MovRegReg(A, xrRAX, xrRDI);
  X64BindLabel(A, ReturnStored);
  X64BindLabel(A, Done);
  X64Ret(A);
end;

procedure EmitS67TextPos(var A: TX64Assembler; LabelId: Int32);
var
  Done: Int32;
begin
  Done := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64MovRegImm64(A, xrRAX, 1);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, Done);
  X64MovSXRegMemBaseDisp32(A, xrRAX, xrRDI, S67_TEXT_POS_OFFSET);
  X64BindLabel(A, Done);
  X64Ret(A);
end;

procedure EmitS67TextSetPos(var A: TX64Assembler; LabelId: Int32);
var
  Clamp, Store, Done: Int32;
begin
  Clamp := X64NewLabel(A);
  Store := X64NewLabel(A);
  Done := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, Done);
  X64MovSXRegMemBaseDisp32(A, xrRCX, xrRDI, S67_TEXT_LENGTH_OFFSET);
  X64CmpRegImm32(A, xrRSI, 1);
  X64JumpCondition(A, xcLess, Clamp);
  X64MovRegReg(A, xrRDX, xrRCX);
  X64AddRegImm32(A, xrRDX, 1);
  X64CmpRegReg(A, xrRSI, xrRDX);
  X64JumpCondition(A, xcGreater, Clamp);
  X64Jump(A, Store);
  X64BindLabel(A, Clamp);
  X64MovRegReg(A, xrRSI, xrRCX);
  X64AddRegImm32(A, xrRSI, 1);
  X64BindLabel(A, Store);
  X64MovMemBaseDispReg32(A, xrRDI, S67_TEXT_POS_OFFSET, xrRSI);
  X64BindLabel(A, Done);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitS67TextMore(var A: TX64Assembler; LabelId: Int32);
var
  NoMore, Done: Int32;
begin
  NoMore := X64NewLabel(A);
  Done := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, NoMore);
  X64MovSXRegMemBaseDisp32(A, xrRAX, xrRDI, S67_TEXT_POS_OFFSET);
  X64CmpRegImm32(A, xrRAX, 1);
  X64JumpCondition(A, xcLess, NoMore);
  X64MovSXRegMemBaseDisp32(A, xrRCX, xrRDI, S67_TEXT_LENGTH_OFFSET);
  X64CmpRegReg(A, xrRAX, xrRCX);
  X64JumpCondition(A, xcGreater, NoMore);
  X64MovRegImm64(A, xrRAX, 1);
  X64Jump(A, Done);
  X64BindLabel(A, NoMore);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64BindLabel(A, Done);
  X64Ret(A);
end;

procedure EmitS67TextGetChar(var A: TX64Assembler; LabelId: Int32;
  const Links: TS67NativeLinks);
begin
  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64MovSXRegMemBaseDisp32(A, xrRCX, xrRDI, S67_TEXT_POS_OFFSET);
  X64CmpRegImm32(A, xrRCX, 1);
  X64JumpCondition(A, xcLess, Links.PanicText);
  X64MovSXRegMemBaseDisp32(A, xrRDX, xrRDI, S67_TEXT_LENGTH_OFFSET);
  X64CmpRegReg(A, xrRCX, xrRDX);
  X64JumpCondition(A, xcGreater, Links.PanicText);
  X64MovRegMemBaseDisp(A, xrRDX, xrRDI, S67_TEXT_START_OFFSET);
  X64AddRegReg(A, xrRDX, xrRCX);
  X64MovRegMemBaseDisp8(A, xrRAX, xrRDX, -1);
  X64AddRegImm32(A, xrRCX, 1);
  X64MovMemBaseDispReg32(A, xrRDI, S67_TEXT_POS_OFFSET, xrRCX);
  X64Ret(A);
end;

procedure EmitS67TextPutChar(var A: TX64Assembler; LabelId: Int32;
  const Links: TS67NativeLinks);
begin
  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64MovRegMemBaseDisp(A, xrRAX, xrRDI, -8);
  X64AndRegImm32(A, xrRAX, 1);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64MovSXRegMemBaseDisp32(A, xrRCX, xrRDI, S67_TEXT_POS_OFFSET);
  X64CmpRegImm32(A, xrRCX, 1);
  X64JumpCondition(A, xcLess, Links.PanicText);
  X64MovSXRegMemBaseDisp32(A, xrRDX, xrRDI, S67_TEXT_LENGTH_OFFSET);
  X64CmpRegReg(A, xrRCX, xrRDX);
  X64JumpCondition(A, xcGreater, Links.PanicText);
  X64MovRegMemBaseDisp(A, xrRDX, xrRDI, S67_TEXT_START_OFFSET);
  X64AddRegReg(A, xrRDX, xrRCX);
  X64MovMemBaseDispReg8(A, xrRDX, -1, xrRSI);
  X64AddRegImm32(A, xrRCX, 1);
  X64MovMemBaseDispReg32(A, xrRDI, S67_TEXT_POS_OFFSET, xrRCX);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitS67TextSub(var A: TX64Assembler; LabelId, ArenaLabel: Int32;
  const Links: TS67NativeLinks);
var
  MainReady, EmptyResult: Int32;
begin
  MainReady := X64NewLabel(A);
  EmptyResult := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64CmpRegImm32(A, xrRSI, 1);
  X64JumpCondition(A, xcLess, Links.PanicText);
  X64TestRegReg(A, xrRDX, xrRDX);
  X64JumpCondition(A, xcLess, Links.PanicText);
  X64MovSXRegMemBaseDisp32(A, xrRCX, xrRDI, S67_TEXT_LENGTH_OFFSET);
  X64MovRegReg(A, xrR8, xrRSI);
  X64AddRegReg(A, xrR8, xrRDX);
  X64JumpCondition(A, xcOverflow, Links.PanicText);
  X64SubRegImm32(A, xrR8, 1);
  X64CmpRegReg(A, xrR8, xrRCX);
  X64JumpCondition(A, xcGreater, Links.PanicText);
  X64TestRegReg(A, xrRDX, xrRDX);
  X64JumpCondition(A, xcEqual, EmptyResult);

  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64MovRegReg(A, xrR12, xrRDI);
  X64MovRegReg(A, xrR13, xrRSI);
  X64MovRegReg(A, xrR14, xrRDX);
  X64MovRegImm64(A, xrRDI, 32);
  X64Call(A, ArenaLabel);
  X64MovRegReg(A, xrR8, xrRAX);
  X64AddRegImm32(A, xrRAX, 16);
  X64MovRegMemBaseDisp(A, xrRCX, xrR12, -16);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcNotEqual, MainReady);
  X64MovRegReg(A, xrRCX, xrR12);
  X64BindLabel(A, MainReady);
  X64MovMemBaseDispReg(A, xrR8, 0, xrRCX);
  X64MovRegMemBaseDisp(A, xrRCX, xrR12, -8);
  X64MovMemBaseDispReg(A, xrR8, 8, xrRCX);
  X64MovRegMemBaseDisp(A, xrRCX, xrR12, S67_TEXT_START_OFFSET);
  X64AddRegReg(A, xrRCX, xrR13);
  X64SubRegImm32(A, xrRCX, 1);
  X64MovMemBaseDispReg(A, xrRAX, S67_TEXT_START_OFFSET, xrRCX);
  X64MovRegImm64(A, xrRCX, 1);
  X64MovMemBaseDispReg32(A, xrRAX, S67_TEXT_POS_OFFSET, xrRCX);
  X64MovMemBaseDispReg32(A, xrRAX, S67_TEXT_LENGTH_OFFSET, xrR14);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64Ret(A);

  X64BindLabel(A, EmptyResult);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitS67TextStrip(var A: TX64Assembler; LabelId, SubLabel: Int32);
var
  Scan, Found, EmptyResult: Int32;
begin
  Scan := X64NewLabel(A);
  Found := X64NewLabel(A);
  EmptyResult := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, EmptyResult);
  X64MovSXRegMemBaseDisp32(A, xrRDX, xrRDI, S67_TEXT_LENGTH_OFFSET);
  X64TestRegReg(A, xrRDX, xrRDX);
  X64JumpCondition(A, xcEqual, EmptyResult);
  X64MovRegMemBaseDisp(A, xrR8, xrRDI, S67_TEXT_START_OFFSET);
  X64BindLabel(A, Scan);
  X64MovRegReg(A, xrRCX, xrR8);
  X64AddRegReg(A, xrRCX, xrRDX);
  X64MovRegMemBaseDisp8(A, xrRAX, xrRCX, -1);
  X64CmpRegImm32(A, xrRAX, Ord(' '));
  X64JumpCondition(A, xcNotEqual, Found);
  X64SubRegImm32(A, xrRDX, 1);
  X64JumpCondition(A, xcNotEqual, Scan);
  X64Jump(A, EmptyResult);
  X64BindLabel(A, Found);
  X64MovRegImm64(A, xrRSI, 1);
  X64Jump(A, SubLabel);
  X64BindLabel(A, EmptyResult);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitS67TextGetInt(var A: TX64Assembler; LabelId: Int32;
  const Links: TS67NativeLinks);
var
  SkipSpace, SignReady, PositiveLoop, NegativeLoop, PositiveDone,
  NegativeDone, Commit, PositiveStart, NegativeStart, SkipOne: Int32;
begin
  SkipSpace := X64NewLabel(A);
  SignReady := X64NewLabel(A);
  PositiveLoop := X64NewLabel(A);
  NegativeLoop := X64NewLabel(A);
  PositiveDone := X64NewLabel(A);
  NegativeDone := X64NewLabel(A);
  Commit := X64NewLabel(A);
  PositiveStart := X64NewLabel(A);
  NegativeStart := X64NewLabel(A);
  SkipOne := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64PushReg(A, xrR15);
  X64MovRegReg(A, xrR12, xrRDI);
  X64MovRegMemBaseDisp(A, xrR13, xrR12, S67_TEXT_START_OFFSET);
  X64MovSXRegMemBaseDisp32(A, xrR14, xrR12, S67_TEXT_POS_OFFSET);
  X64MovSXRegMemBaseDisp32(A, xrR15, xrR12, S67_TEXT_LENGTH_OFFSET);
  X64CmpRegImm32(A, xrR14, 1);
  X64JumpCondition(A, xcLess, Links.PanicText);
  X64BindLabel(A, SkipSpace);
  X64CmpRegReg(A, xrR14, xrR15);
  X64JumpCondition(A, xcGreater, Links.PanicText);
  X64MovRegReg(A, xrRCX, xrR13);
  X64AddRegReg(A, xrRCX, xrR14);
  X64MovRegMemBaseDisp8(A, xrRDX, xrRCX, -1);
  X64CmpRegImm32(A, xrRDX, Ord(' '));
  X64JumpCondition(A, xcEqual, SkipOne);
  X64CmpRegImm32(A, xrRDX, 9);
  X64JumpCondition(A, xcNotEqual, SignReady);
  X64BindLabel(A, SkipOne);
  X64AddRegImm32(A, xrR14, 1);
  X64Jump(A, SkipSpace);

  X64BindLabel(A, SignReady);
  X64CmpRegImm32(A, xrRDX, Ord('-'));
  X64JumpCondition(A, xcEqual, NegativeStart);
  X64CmpRegImm32(A, xrRDX, Ord('+'));
  X64JumpCondition(A, xcNotEqual, PositiveStart);
  X64AddRegImm32(A, xrR14, 1);
  X64BindLabel(A, PositiveStart);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64XorRegReg(A, xrR8, xrR8);
  X64BindLabel(A, PositiveLoop);
  X64CmpRegReg(A, xrR14, xrR15);
  X64JumpCondition(A, xcGreater, PositiveDone);
  X64MovRegReg(A, xrRCX, xrR13);
  X64AddRegReg(A, xrRCX, xrR14);
  X64MovRegMemBaseDisp8(A, xrRDX, xrRCX, -1);
  X64CmpRegImm32(A, xrRDX, Ord('0'));
  X64JumpCondition(A, xcLess, PositiveDone);
  X64CmpRegImm32(A, xrRDX, Ord('9'));
  X64JumpCondition(A, xcGreater, PositiveDone);
  X64IMulRegRegImm32(A, xrRAX, xrRAX, 10);
  X64JumpCondition(A, xcOverflow, Links.PanicText);
  X64SubRegImm32(A, xrRDX, Ord('0'));
  X64AddRegReg(A, xrRAX, xrRDX);
  X64JumpCondition(A, xcOverflow, Links.PanicText);
  X64AddRegImm32(A, xrR8, 1);
  X64AddRegImm32(A, xrR14, 1);
  X64Jump(A, PositiveLoop);
  X64BindLabel(A, PositiveDone);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64Jump(A, Commit);

  X64BindLabel(A, NegativeStart);
  X64AddRegImm32(A, xrR14, 1);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64XorRegReg(A, xrR8, xrR8);
  X64BindLabel(A, NegativeLoop);
  X64CmpRegReg(A, xrR14, xrR15);
  X64JumpCondition(A, xcGreater, NegativeDone);
  X64MovRegReg(A, xrRCX, xrR13);
  X64AddRegReg(A, xrRCX, xrR14);
  X64MovRegMemBaseDisp8(A, xrRDX, xrRCX, -1);
  X64CmpRegImm32(A, xrRDX, Ord('0'));
  X64JumpCondition(A, xcLess, NegativeDone);
  X64CmpRegImm32(A, xrRDX, Ord('9'));
  X64JumpCondition(A, xcGreater, NegativeDone);
  X64IMulRegRegImm32(A, xrRAX, xrRAX, 10);
  X64JumpCondition(A, xcOverflow, Links.PanicText);
  X64SubRegImm32(A, xrRDX, Ord('0'));
  X64SubRegReg(A, xrRAX, xrRDX);
  X64JumpCondition(A, xcOverflow, Links.PanicText);
  X64AddRegImm32(A, xrR8, 1);
  X64AddRegImm32(A, xrR14, 1);
  X64Jump(A, NegativeLoop);
  X64BindLabel(A, NegativeDone);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Links.PanicText);

  X64BindLabel(A, Commit);
  X64MovMemBaseDispReg32(A, xrR12, S67_TEXT_POS_OFFSET, xrR14);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64Ret(A);
end;

procedure EmitS67TextGetFrac(var A: TX64Assembler; LabelId: Int32;
  const D: TS67NativeDataOffsets; const Links: TS67NativeLinks);
var
  SkipLeading, LeadingSkip, AfterSign, NegativeSign, PositiveSign,
  Scan, OtherChar, EmbeddedSkip, DecimalSeen, Finish, Commit: Int32;
begin
  SkipLeading := X64NewLabel(A);
  LeadingSkip := X64NewLabel(A);
  AfterSign := X64NewLabel(A);
  NegativeSign := X64NewLabel(A);
  PositiveSign := X64NewLabel(A);
  Scan := X64NewLabel(A);
  OtherChar := X64NewLabel(A);
  EmbeddedSkip := X64NewLabel(A);
  DecimalSeen := X64NewLabel(A);
  Finish := X64NewLabel(A);
  Commit := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64PushReg(A, xrRBX);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64PushReg(A, xrR15);
  X64MovRegReg(A, xrR12, xrRDI);
  X64MovRegMemBaseDisp(A, xrR13, xrR12, S67_TEXT_START_OFFSET);
  X64MovSXRegMemBaseDisp32(A, xrR14, xrR12, S67_TEXT_POS_OFFSET);
  X64MovSXRegMemBaseDisp32(A, xrR15, xrR12, S67_TEXT_LENGTH_OFFSET);
  X64LeaRegRipWritable(A, xrRBX, D.CurrentDecimalMark, 0);
  X64MovRegMemBaseDisp(A, xrRBX, xrRBX, 0);
  X64XorRegReg(A, xrR10, xrR10); { negative }

  X64BindLabel(A, SkipLeading);
  X64CmpRegReg(A, xrR14, xrR15);
  X64JumpCondition(A, xcGreater, Links.PanicText);
  X64MovRegReg(A, xrRCX, xrR13);
  X64AddRegReg(A, xrRCX, xrR14);
  X64MovRegMemBaseDisp8(A, xrRDX, xrRCX, -1);
  X64CmpRegImm32(A, xrRDX, Ord(' '));
  X64JumpCondition(A, xcEqual, LeadingSkip);
  X64CmpRegImm32(A, xrRDX, 9);
  X64JumpCondition(A, xcEqual, LeadingSkip);
  X64CmpRegImm32(A, xrRDX, Ord('-'));
  X64JumpCondition(A, xcEqual, NegativeSign);
  X64CmpRegImm32(A, xrRDX, Ord('+'));
  X64JumpCondition(A, xcEqual, PositiveSign);
  X64Jump(A, AfterSign);

  X64BindLabel(A, LeadingSkip);
  X64AddRegImm32(A, xrR14, 1);
  X64Jump(A, SkipLeading);
  X64BindLabel(A, NegativeSign);
  X64MovRegImm64(A, xrR10, 1);
  X64AddRegImm32(A, xrR14, 1);
  X64Jump(A, AfterSign);
  X64BindLabel(A, PositiveSign);
  X64AddRegImm32(A, xrR14, 1);

  X64BindLabel(A, AfterSign);
  X64XorRegReg(A, xrRAX, xrRAX); { negative accumulator }
  X64XorRegReg(A, xrR8, xrR8);   { digit count }
  X64XorRegReg(A, xrR9, xrR9);   { decimal mark seen }
  X64BindLabel(A, Scan);
  X64CmpRegReg(A, xrR14, xrR15);
  X64JumpCondition(A, xcGreater, Finish);
  X64MovRegReg(A, xrRCX, xrR13);
  X64AddRegReg(A, xrRCX, xrR14);
  X64MovRegMemBaseDisp8(A, xrRDX, xrRCX, -1);
  X64CmpRegImm32(A, xrRDX, Ord('0'));
  X64JumpCondition(A, xcLess, OtherChar);
  X64CmpRegImm32(A, xrRDX, Ord('9'));
  X64JumpCondition(A, xcGreater, OtherChar);
  X64IMulRegRegImm32(A, xrRAX, xrRAX, 10);
  X64JumpCondition(A, xcOverflow, Links.PanicText);
  X64SubRegImm32(A, xrRDX, Ord('0'));
  X64SubRegReg(A, xrRAX, xrRDX);
  X64JumpCondition(A, xcOverflow, Links.PanicText);
  X64AddRegImm32(A, xrR8, 1);
  X64AddRegImm32(A, xrR14, 1);
  X64Jump(A, Scan);

  X64BindLabel(A, OtherChar);
  X64CmpRegImm32(A, xrRDX, Ord(' '));
  X64JumpCondition(A, xcEqual, EmbeddedSkip);
  X64CmpRegImm32(A, xrRDX, 9);
  X64JumpCondition(A, xcEqual, EmbeddedSkip);
  X64CmpRegReg(A, xrRDX, xrRBX);
  X64JumpCondition(A, xcNotEqual, Finish);
  X64TestRegReg(A, xrR9, xrR9);
  X64JumpCondition(A, xcNotEqual, Finish);
  X64MovRegImm64(A, xrR9, 1);
  X64Jump(A, DecimalSeen);
  X64BindLabel(A, EmbeddedSkip);
  X64AddRegImm32(A, xrR14, 1);
  X64Jump(A, Scan);
  X64BindLabel(A, DecimalSeen);
  X64AddRegImm32(A, xrR14, 1);
  X64Jump(A, Scan);

  X64BindLabel(A, Finish);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64TestRegReg(A, xrR10, xrR10);
  X64JumpCondition(A, xcNotEqual, Commit);
  X64NegReg(A, xrRAX);
  X64JumpCondition(A, xcOverflow, Links.PanicText);
  X64BindLabel(A, Commit);
  X64MovMemBaseDispReg32(A, xrR12, S67_TEXT_POS_OFFSET, xrR14);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64PopReg(A, xrRBX);
  X64Ret(A);
end;

procedure EmitS67TextPutInt(var A: TX64Assembler; LabelId: Int32;
  const Links: TS67NativeLinks);
var
  FillLoop, FillDone, NegativeValue, MagnitudeReady, DigitLoop,
  DigitsDone, SignDone, StorePos, Overflow, StarLoop, StarDone: Int32;
begin
  FillLoop := X64NewLabel(A);
  FillDone := X64NewLabel(A);
  NegativeValue := X64NewLabel(A);
  MagnitudeReady := X64NewLabel(A);
  DigitLoop := X64NewLabel(A);
  DigitsDone := X64NewLabel(A);
  SignDone := X64NewLabel(A);
  StorePos := X64NewLabel(A);
  Overflow := X64NewLabel(A);
  StarLoop := X64NewLabel(A);
  StarDone := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64MovRegMemBaseDisp(A, xrRAX, xrRDI, -8);
  X64AndRegImm32(A, xrRAX, 1);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64PushReg(A, xrRBX);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64PushReg(A, xrR15);
  X64MovRegReg(A, xrR12, xrRDI);
  X64MovRegReg(A, xrR13, xrRSI);
  X64MovSXRegMemBaseDisp32(A, xrR14, xrR12, S67_TEXT_LENGTH_OFFSET);
  X64TestRegReg(A, xrR14, xrR14);
  X64JumpCondition(A, xcLessEqual, Links.PanicText);
  X64MovRegMemBaseDisp(A, xrR15, xrR12, S67_TEXT_START_OFFSET);
  X64MovRegReg(A, xrRDI, xrR15);
  X64MovRegReg(A, xrRCX, xrR14);
  X64MovRegImm64(A, xrRDX, Ord(' '));
  X64BindLabel(A, FillLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, FillDone);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRDX);
  X64AddRegImm32(A, xrRDI, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, FillLoop);
  X64BindLabel(A, FillDone);
  X64MovRegReg(A, xrRBX, xrR15);
  X64AddRegReg(A, xrRBX, xrR14); { one byte past frame }
  X64MovRegReg(A, xrRAX, xrR13);
  X64XorRegReg(A, xrR10, xrR10); { sign flag }
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcLess, NegativeValue);
  X64Jump(A, MagnitudeReady);
  X64BindLabel(A, NegativeValue);
  X64MovRegImm64(A, xrR10, 1);
  X64NegReg(A, xrRAX); { unsigned magnitude; MinInt deliberately wraps }
  X64BindLabel(A, MagnitudeReady);
  X64MovRegImm64(A, xrR11, 10);
  X64MovRegReg(A, xrRCX, xrR14); { free cells }
  X64BindLabel(A, DigitLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, Overflow);
  X64XorRegReg(A, xrRDX, xrRDX);
  X64DivReg(A, xrR11);
  X64AddRegImm32(A, xrRDX, Ord('0'));
  X64SubRegImm32(A, xrRBX, 1);
  X64MovMemBaseDispReg8(A, xrRBX, 0, xrRDX);
  X64SubRegImm32(A, xrRCX, 1);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcNotEqual, DigitLoop);
  X64BindLabel(A, DigitsDone);
  X64TestRegReg(A, xrR10, xrR10);
  X64JumpCondition(A, xcEqual, SignDone);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, Overflow);
  X64SubRegImm32(A, xrRBX, 1);
  X64MovRegImm64(A, xrRDX, Ord('-'));
  X64MovMemBaseDispReg8(A, xrRBX, 0, xrRDX);
  X64BindLabel(A, SignDone);
  X64Jump(A, StorePos);
  X64BindLabel(A, Overflow);
  X64MovRegReg(A, xrRDI, xrR15);
  X64MovRegReg(A, xrRCX, xrR14);
  X64MovRegImm64(A, xrRDX, Ord('*'));
  X64BindLabel(A, StarLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, StarDone);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRDX);
  X64AddRegImm32(A, xrRDI, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, StarLoop);
  X64BindLabel(A, StarDone);
  X64BindLabel(A, StorePos);
  X64MovRegReg(A, xrRAX, xrR14);
  X64AddRegImm32(A, xrRAX, 1);
  X64MovMemBaseDispReg32(A, xrR12, S67_TEXT_POS_OFFSET, xrRAX);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64PopReg(A, xrRBX);
  X64Ret(A);
end;

procedure EmitS67TextPutFix(var A: TX64Assembler; LabelId: Int32;
  const D: TS67NativeDataOffsets; const Links: TS67NativeLinks);
var
  FillLoop, FillDone, PowerLoop, PowerDone, FractionLoop, FractionDone,
  IntegerLoop, IntegerDone, NoSign, Overflow, StarLoop, StarDone,
  StorePos: Int32;
begin
  FillLoop := X64NewLabel(A);
  FillDone := X64NewLabel(A);
  PowerLoop := X64NewLabel(A);
  PowerDone := X64NewLabel(A);
  FractionLoop := X64NewLabel(A);
  FractionDone := X64NewLabel(A);
  IntegerLoop := X64NewLabel(A);
  IntegerDone := X64NewLabel(A);
  NoSign := X64NewLabel(A);
  Overflow := X64NewLabel(A);
  StarLoop := X64NewLabel(A);
  StarDone := X64NewLabel(A);
  StorePos := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64MovRegMemBaseDisp(A, xrRAX, xrRDI, -8);
  X64AndRegImm32(A, xrRAX, 1);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64TestRegReg(A, xrRDX, xrRDX);
  X64JumpCondition(A, xcLess, Links.PanicText);
  X64CmpRegImm32(A, xrRDX, 18);
  X64JumpCondition(A, xcGreater, Links.PanicText);
  X64PushReg(A, xrRBX);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64PushReg(A, xrR15);
  X64MovRegReg(A, xrR12, xrRDI);
  X64MovRegReg(A, xrR13, xrRSI); { IEEE bits }
  X64MovRegReg(A, xrR14, xrRDX); { decimals }
  X64MovSXRegMemBaseDisp32(A, xrR15, xrR12, S67_TEXT_LENGTH_OFFSET);
  X64TestRegReg(A, xrR15, xrR15);
  X64JumpCondition(A, xcLessEqual, Links.PanicText);
  X64MovRegMemBaseDisp(A, xrRBX, xrR12, S67_TEXT_START_OFFSET);

  X64MovRegReg(A, xrRDI, xrRBX);
  X64MovRegReg(A, xrRCX, xrR15);
  X64MovRegImm64(A, xrRAX, Ord(' '));
  X64BindLabel(A, FillLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, FillDone);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRAX);
  X64AddRegImm32(A, xrRDI, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, FillLoop);
  X64BindLabel(A, FillDone);

  X64MovRegReg(A, xrR10, xrR13);
  X64ShrRegImm8(A, xrR10, 63); { sign }
  X64MovRegReg(A, xrRAX, xrR13);
  X64ShlRegImm8(A, xrRAX, 1);
  X64ShrRegImm8(A, xrRAX, 1); { abs bits }
  X64MovQXMMReg(A, xrXMM0, xrRAX);
  X64MovRegImm64(A, xrR11, 1);
  X64MovRegReg(A, xrRCX, xrR14);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, PowerDone);
  X64BindLabel(A, PowerLoop);
  X64IMulRegRegImm32(A, xrR11, xrR11, 10);
  X64SubRegImm32(A, xrRCX, 1);
  X64JumpCondition(A, xcNotEqual, PowerLoop);
  X64BindLabel(A, PowerDone);
  X64CVTSI2SD(A, xrXMM1, xrR11);
  X64MulSD(A, xrXMM0, xrXMM1);
  X64MovRegImm64(A, xrRAX, QWord($3FE0000000000000)); { 0.5 }
  X64MovQXMMReg(A, xrXMM2, xrRAX);
  X64AddSD(A, xrXMM0, xrXMM2);
  X64CVTTSD2SI(A, xrRAX, xrXMM0);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcLess, Overflow);

  X64MovRegReg(A, xrR9, xrRBX);
  X64AddRegReg(A, xrR9, xrR15); { one past end }
  X64MovRegReg(A, xrR8, xrR15); { cells left }
  X64MovRegImm64(A, xrR11, 10);
  X64MovRegReg(A, xrRCX, xrR14);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, FractionDone);
  X64BindLabel(A, FractionLoop);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64XorRegReg(A, xrRDX, xrRDX);
  X64DivReg(A, xrR11);
  X64AddRegImm32(A, xrRDX, Ord('0'));
  X64SubRegImm32(A, xrR9, 1);
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64SubRegImm32(A, xrR8, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64JumpCondition(A, xcNotEqual, FractionLoop);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64LeaRegRipWritable(A, xrRDX, D.CurrentDecimalMark, 0);
  X64MovRegMemBaseDisp(A, xrRDX, xrRDX, 0);
  X64SubRegImm32(A, xrR9, 1);
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64SubRegImm32(A, xrR8, 1);
  X64BindLabel(A, FractionDone);

  { The scaled integer now contains only the integer part after n divisions. }
  X64BindLabel(A, IntegerLoop);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64XorRegReg(A, xrRDX, xrRDX);
  X64DivReg(A, xrR11);
  X64AddRegImm32(A, xrRDX, Ord('0'));
  X64SubRegImm32(A, xrR9, 1);
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64SubRegImm32(A, xrR8, 1);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcNotEqual, IntegerLoop);
  X64BindLabel(A, IntegerDone);
  X64TestRegReg(A, xrR10, xrR10);
  X64JumpCondition(A, xcEqual, NoSign);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64SubRegImm32(A, xrR9, 1);
  X64MovRegImm64(A, xrRDX, Ord('-'));
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64BindLabel(A, NoSign);
  X64Jump(A, StorePos);

  X64BindLabel(A, Overflow);
  X64MovRegReg(A, xrRDI, xrRBX);
  X64MovRegReg(A, xrRCX, xrR15);
  X64MovRegImm64(A, xrRDX, Ord('*'));
  X64BindLabel(A, StarLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, StarDone);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRDX);
  X64AddRegImm32(A, xrRDI, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, StarLoop);
  X64BindLabel(A, StarDone);
  X64BindLabel(A, StorePos);
  X64MovRegReg(A, xrRAX, xrR15);
  X64AddRegImm32(A, xrRAX, 1);
  X64MovMemBaseDispReg32(A, xrR12, S67_TEXT_POS_OFFSET, xrRAX);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64PopReg(A, xrRBX);
  X64Ret(A);
end;

procedure EmitS67TextPutReal(var A: TX64Assembler; LabelId: Int32;
  const D: TS67NativeDataOffsets; const Links: TS67NativeLinks);
var
  FillLoop, Filled, NormHigh, NormLow, Normalized, ScaleLoop, Scaled,
  PowLoop, PowDone, CarryDone, ExpLoop, ExpDone, ExpPositive,
  NZero, DigitLoop, DigitZero, DigitReady, MaybeDecimal, DecimalDone,
  WriteSign, SignDone, StorePos, Overflow, StarLoop, StarDone: Int32;
begin
  FillLoop := X64NewLabel(A);
  Filled := X64NewLabel(A);
  NormHigh := X64NewLabel(A);
  NormLow := X64NewLabel(A);
  Normalized := X64NewLabel(A);
  ScaleLoop := X64NewLabel(A);
  Scaled := X64NewLabel(A);
  PowLoop := X64NewLabel(A);
  PowDone := X64NewLabel(A);
  CarryDone := X64NewLabel(A);
  ExpLoop := X64NewLabel(A);
  ExpDone := X64NewLabel(A);
  ExpPositive := X64NewLabel(A);
  NZero := X64NewLabel(A);
  DigitLoop := X64NewLabel(A);
  DigitZero := X64NewLabel(A);
  DigitReady := X64NewLabel(A);
  MaybeDecimal := X64NewLabel(A);
  DecimalDone := X64NewLabel(A);
  WriteSign := X64NewLabel(A);
  SignDone := X64NewLabel(A);
  StorePos := X64NewLabel(A);
  Overflow := X64NewLabel(A);
  StarLoop := X64NewLabel(A);
  StarDone := X64NewLabel(A);

  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64CmpRegImm32(A, xrRDX, 0);
  X64JumpCondition(A, xcLess, Links.PanicText);
  X64MovRegMemBaseDisp(A, xrRAX, xrRDI, -8);
  X64AndRegImm32(A, xrRAX, 1);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64PushReg(A, xrRBX);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64PushReg(A, xrR15);
  X64MovRegReg(A, xrR12, xrRDI);
  X64MovRegReg(A, xrR13, xrRDX); { n }
  X64MovRegReg(A, xrR14, xrRSI);
  X64ShrRegImm8(A, xrR14, 63);   { sign }
  X64MovRegReg(A, xrRAX, xrRSI);
  X64ShlRegImm8(A, xrRAX, 1);
  X64ShrRegImm8(A, xrRAX, 1);    { abs bits }
  X64MovRegImm64(A, xrR11, QWord($7ff0000000000000));
  X64CmpRegReg(A, xrRAX, xrR11);
  X64JumpCondition(A, xcAboveEqual, Links.PanicText);
  X64MovQXMMReg(A, xrXMM0, xrRAX);

  X64MovRegMemBaseDisp(A, xrRBX, xrR12, S67_TEXT_START_OFFSET);
  X64MovSXRegMemBaseDisp32(A, xrR11, xrR12, S67_TEXT_LENGTH_OFFSET);
  X64MovRegReg(A, xrRDI, xrRBX);
  X64MovRegReg(A, xrRCX, xrR11);
  X64MovRegImm64(A, xrRDX, Ord(' '));
  X64BindLabel(A, FillLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, Filled);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRDX);
  X64AddRegImm32(A, xrRDI, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, FillLoop);

  X64BindLabel(A, Filled);
  X64XorRegReg(A, xrR15, xrR15); { exponent }
  X64MovRegImm64(A, xrRAX, QWord($4024000000000000));
  X64MovQXMMReg(A, xrXMM1, xrRAX); { 10.0 }
  X64MovRegImm64(A, xrRAX, QWord($3ff0000000000000));
  X64MovQXMMReg(A, xrXMM2, xrRAX); { 1.0 }
  X64MovQRegXMM(A, xrRAX, xrXMM0);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, Normalized);
  X64BindLabel(A, NormHigh);
  X64UComiSD(A, xrXMM0, xrXMM1);
  X64JumpCondition(A, xcBelow, NormLow);
  X64DivSD(A, xrXMM0, xrXMM1);
  X64AddRegImm32(A, xrR15, 1);
  X64Jump(A, NormHigh);
  X64BindLabel(A, NormLow);
  X64UComiSD(A, xrXMM0, xrXMM2);
  X64JumpCondition(A, xcAboveEqual, Normalized);
  X64MulSD(A, xrXMM0, xrXMM1);
  X64SubRegImm32(A, xrR15, 1);
  X64Jump(A, NormLow);

  X64BindLabel(A, Normalized);
  X64TestRegReg(A, xrR13, xrR13);
  X64JumpCondition(A, xcEqual, NZero);
  X64MovRegReg(A, xrR10, xrR13);
  X64CmpRegImm32(A, xrR10, 18);
  X64JumpCondition(A, xcLessEqual, Scaled);
  X64MovRegImm64(A, xrR10, 18);
  X64BindLabel(A, Scaled);
  X64MovRegReg(A, xrRCX, xrR10);
  X64SubRegImm32(A, xrRCX, 1);
  X64BindLabel(A, ScaleLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, PowDone);
  X64MulSD(A, xrXMM0, xrXMM1);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, ScaleLoop);
  X64BindLabel(A, PowDone);
  X64MovRegImm64(A, xrRAX, QWord($3fe0000000000000));
  X64MovQXMMReg(A, xrXMM3, xrRAX); { 0.5 }
  X64AddSD(A, xrXMM0, xrXMM3);
  X64CVTTSD2SI(A, xrRAX, xrXMM0);
  X64MovRegReg(A, xrR11, xrRAX); { mantissa integer }
  X64MovRegImm64(A, xrRDX, 1);
  X64MovRegReg(A, xrRCX, xrR10);
  X64BindLabel(A, PowLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, CarryDone);
  X64IMulRegRegImm32(A, xrRDX, xrRDX, 10);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, PowLoop);
  X64BindLabel(A, CarryDone);
  X64CmpRegReg(A, xrR11, xrRDX);
  X64JumpCondition(A, xcBelow, ExpDone);
  X64MovRegReg(A, xrRAX, xrR11);
  X64XorRegReg(A, xrRDX, xrRDX);
  X64MovRegImm64(A, xrRCX, 10);
  X64DivReg(A, xrRCX);
  X64MovRegReg(A, xrR11, xrRAX);
  X64AddRegImm32(A, xrR15, 1);
  X64Jump(A, ExpDone);

  X64BindLabel(A, NZero);
  X64XorRegReg(A, xrR10, xrR10);
  X64XorRegReg(A, xrR11, xrR11);

  X64BindLabel(A, ExpDone);
  X64MovRegReg(A, xrR9, xrRBX);
  X64MovSXRegMemBaseDisp32(A, xrR8, xrR12, S67_TEXT_LENGTH_OFFSET);
  X64AddRegReg(A, xrR9, xrR8);
  X64MovRegReg(A, xrRAX, xrR15);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcGreaterEqual, ExpPositive);
  X64NegReg(A, xrRAX);
  X64BindLabel(A, ExpPositive);
  X64CmpRegImm32(A, xrRAX, 999);
  X64JumpCondition(A, xcGreater, Links.PanicText);
  X64MovRegImm64(A, xrRCX, 3);
  X64MovRegImm64(A, xrRDX, 10);
  X64BindLabel(A, ExpLoop);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64XorRegReg(A, xrRDI, xrRDI);
  { div uses rdx, so keep divisor in rsi for this tiny loop }
  X64MovRegImm64(A, xrRSI, 10);
  X64XorRegReg(A, xrRDX, xrRDX);
  X64DivReg(A, xrRSI);
  X64AddRegImm32(A, xrRDX, Ord('0'));
  X64SubRegImm32(A, xrR9, 1);
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64SubRegImm32(A, xrR8, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64JumpCondition(A, xcNotEqual, ExpLoop);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64SubRegImm32(A, xrR9, 1);
  X64MovRegImm64(A, xrRDX, Ord('+'));
  X64CmpRegImm32(A, xrR15, 0);
  X64JumpCondition(A, xcGreaterEqual, DecimalDone);
  X64MovRegImm64(A, xrRDX, Ord('-'));
  X64BindLabel(A, DecimalDone);
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64SubRegImm32(A, xrR8, 1);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64LeaRegRipWritable(A, xrRDX, D.CurrentLowTen, 0);
  X64MovRegMemBaseDisp(A, xrRDX, xrRDX, 0);
  X64SubRegImm32(A, xrR9, 1);
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64SubRegImm32(A, xrR8, 1);

  X64TestRegReg(A, xrR13, xrR13);
  X64JumpCondition(A, xcEqual, WriteSign);
  X64MovRegReg(A, xrRAX, xrR11);
  X64MovRegReg(A, xrRCX, xrR13); { total digits still to write }
  X64MovRegReg(A, xrR15, xrR13);
  X64SubRegReg(A, xrR15, xrR10); { zero tail beyond 18 significant digits }
  X64BindLabel(A, DigitLoop);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64TestRegReg(A, xrR15, xrR15);
  X64JumpCondition(A, xcGreater, DigitZero);
  X64MovRegImm64(A, xrRSI, 10);
  X64XorRegReg(A, xrRDX, xrRDX);
  X64DivReg(A, xrRSI);
  X64AddRegImm32(A, xrRDX, Ord('0'));
  X64Jump(A, DigitReady);
  X64BindLabel(A, DigitZero);
  X64SubRegImm32(A, xrR15, 1);
  X64MovRegImm64(A, xrRDI, Ord('0'));
  X64MovRegReg(A, xrRDX, xrRDI);
  X64BindLabel(A, DigitReady);
  X64SubRegImm32(A, xrR9, 1);
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64SubRegImm32(A, xrR8, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64CmpRegImm32(A, xrRCX, 1);
  X64JumpCondition(A, xcNotEqual, MaybeDecimal);
  X64CmpRegImm32(A, xrR13, 1);
  X64JumpCondition(A, xcLessEqual, MaybeDecimal);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64LeaRegRipWritable(A, xrRDX, D.CurrentDecimalMark, 0);
  X64MovRegMemBaseDisp(A, xrRDX, xrRDX, 0);
  X64SubRegImm32(A, xrR9, 1);
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64SubRegImm32(A, xrR8, 1);
  X64BindLabel(A, MaybeDecimal);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcNotEqual, DigitLoop);
  X64Jump(A, WriteSign);

  X64BindLabel(A, WriteSign);
  X64TestRegReg(A, xrR14, xrR14);
  X64JumpCondition(A, xcEqual, SignDone);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64SubRegImm32(A, xrR9, 1);
  X64MovRegImm64(A, xrRDX, Ord('-'));
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64SubRegImm32(A, xrR8, 1);
  X64Jump(A, SignDone);
  X64BindLabel(A, SignDone);
  X64TestRegReg(A, xrR13, xrR13);
  X64JumpCondition(A, xcNotEqual, StorePos);
  { n=0 requires a sign part before the exponent, including '+' for non-negative. }
  X64TestRegReg(A, xrR14, xrR14);
  X64JumpCondition(A, xcNotEqual, StorePos);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64SubRegImm32(A, xrR9, 1);
  X64MovRegImm64(A, xrRDX, Ord('+'));
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64SubRegImm32(A, xrR8, 1);
  X64Jump(A, StorePos);

  X64BindLabel(A, Overflow);
  X64MovRegReg(A, xrRDI, xrRBX);
  X64MovSXRegMemBaseDisp32(A, xrRCX, xrR12, S67_TEXT_LENGTH_OFFSET);
  X64MovRegImm64(A, xrRDX, Ord('*'));
  X64BindLabel(A, StarLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, StarDone);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRDX);
  X64AddRegImm32(A, xrRDI, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, StarLoop);
  X64BindLabel(A, StarDone);

  X64BindLabel(A, StorePos);
  X64MovSXRegMemBaseDisp32(A, xrRAX, xrR12, S67_TEXT_LENGTH_OFFSET);
  X64AddRegImm32(A, xrRAX, 1);
  X64MovMemBaseDispReg32(A, xrR12, S67_TEXT_POS_OFFSET, xrRAX);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64PopReg(A, xrRBX);
  X64Ret(A);
end;

procedure EmitS67TextPutFrac(var A: TX64Assembler; LabelId: Int32;
  const D: TS67NativeDataOffsets; const Links: TS67NativeLinks);
var
  FillLoop, FillDone, NegativeValue, MagnitudeReady, PositiveScale,
  FractionGroupReady, FractionLoop, FractionNoSpace, FractionDone,
  IntegerLoop, IntegerNoSpace, IntegerDone, ZeroInteger, ScaleZeroLoop,
  ScaleZeroNoSpace, ScaleInsertSpace, ScaleZeroDone, NoSign, Overflow, StarLoop, StarDone,
  StorePos, TailReady: Int32;
begin
  FillLoop := X64NewLabel(A);
  FillDone := X64NewLabel(A);
  NegativeValue := X64NewLabel(A);
  MagnitudeReady := X64NewLabel(A);
  PositiveScale := X64NewLabel(A);
  FractionGroupReady := X64NewLabel(A);
  FractionLoop := X64NewLabel(A);
  FractionNoSpace := X64NewLabel(A);
  FractionDone := X64NewLabel(A);
  IntegerLoop := X64NewLabel(A);
  IntegerNoSpace := X64NewLabel(A);
  IntegerDone := X64NewLabel(A);
  ZeroInteger := X64NewLabel(A);
  ScaleZeroLoop := X64NewLabel(A);
  ScaleZeroNoSpace := X64NewLabel(A);
  ScaleInsertSpace := X64NewLabel(A);
  ScaleZeroDone := X64NewLabel(A);
  NoSign := X64NewLabel(A);
  Overflow := X64NewLabel(A);
  StarLoop := X64NewLabel(A);
  StarDone := X64NewLabel(A);
  StorePos := X64NewLabel(A);
  TailReady := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64MovRegMemBaseDisp(A, xrRAX, xrRDI, -8);
  X64AndRegImm32(A, xrRAX, 1);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64PushReg(A, xrRBX);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64PushReg(A, xrR15);
  X64MovRegReg(A, xrR12, xrRDI);
  X64MovRegReg(A, xrR13, xrRSI);
  X64MovRegReg(A, xrR14, xrRDX);
  X64MovSXRegMemBaseDisp32(A, xrR15, xrR12, S67_TEXT_LENGTH_OFFSET);
  X64TestRegReg(A, xrR15, xrR15);
  X64JumpCondition(A, xcLessEqual, Links.PanicText);
  X64MovRegMemBaseDisp(A, xrRBX, xrR12, S67_TEXT_START_OFFSET);

  X64MovRegReg(A, xrRDI, xrRBX);
  X64MovRegReg(A, xrRCX, xrR15);
  X64MovRegImm64(A, xrRAX, Ord(' '));
  X64BindLabel(A, FillLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, FillDone);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRAX);
  X64AddRegImm32(A, xrRDI, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, FillLoop);
  X64BindLabel(A, FillDone);

  X64MovRegReg(A, xrRAX, xrR13);
  X64XorRegReg(A, xrR10, xrR10);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcLess, NegativeValue);
  X64Jump(A, MagnitudeReady);
  X64BindLabel(A, NegativeValue);
  X64MovRegImm64(A, xrR10, 1);
  X64NegReg(A, xrRAX); { unsigned MinInt magnitude is intentional }
  X64BindLabel(A, MagnitudeReady);
  X64MovRegReg(A, xrR9, xrRBX);
  X64AddRegReg(A, xrR9, xrR15);
  X64MovRegReg(A, xrR8, xrR15);
  X64MovRegImm64(A, xrR11, 10);
  X64TestRegReg(A, xrR14, xrR14);
  X64JumpCondition(A, xcGreater, PositiveScale);

  { n <= 0: append -n zeros, then group the whole integer from the right. }
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, ZeroInteger);
  X64NegReg(A, xrR14);
  X64JumpCondition(A, xcOverflow, Overflow);
  X64MovRegImm64(A, xrRCX, 3);
  X64BindLabel(A, ScaleZeroLoop);
  X64TestRegReg(A, xrR14, xrR14);
  X64JumpCondition(A, xcEqual, ScaleZeroDone);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64SubRegImm32(A, xrR9, 1);
  X64MovRegImm64(A, xrRDX, Ord('0'));
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64SubRegImm32(A, xrR8, 1);
  X64SubRegImm32(A, xrR14, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcNotEqual, ScaleZeroNoSpace);
  X64TestRegReg(A, xrR14, xrR14);
  X64JumpCondition(A, xcNotEqual, ScaleInsertSpace);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, ScaleZeroNoSpace);
  X64BindLabel(A, ScaleInsertSpace);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64SubRegImm32(A, xrR9, 1);
  X64MovRegImm64(A, xrRDX, Ord(' '));
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64SubRegImm32(A, xrR8, 1);
  X64MovRegImm64(A, xrRCX, 3);
  X64BindLabel(A, ScaleZeroNoSpace);
  X64Jump(A, ScaleZeroLoop);
  X64BindLabel(A, ScaleZeroDone);
  X64Jump(A, IntegerLoop);

  X64BindLabel(A, ZeroInteger);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64SubRegImm32(A, xrR9, 1);
  X64MovRegImm64(A, xrRDX, Ord('0'));
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64SubRegImm32(A, xrR8, 1);
  X64Jump(A, IntegerDone);

  { n > 0: the right side has exactly n digits, grouped from the decimal mark. }
  X64BindLabel(A, PositiveScale);
  X64MovRegReg(A, xrRCX, xrR14);
  X64MovRegImm64(A, xrR11, 3);
  X64MovRegReg(A, xrRDX, xrRCX);
  X64MovRegReg(A, xrRAX, xrRDX);
  X64XorRegReg(A, xrRDX, xrRDX);
  X64DivReg(A, xrR11);
  X64MovRegReg(A, xrRCX, xrRDX); { first group from the right may be short }
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcNotEqual, TailReady);
  X64MovRegImm64(A, xrRCX, 3);
  X64BindLabel(A, TailReady);
  X64MovRegReg(A, xrRAX, xrR13);
  X64TestRegReg(A, xrR10, xrR10);
  X64JumpCondition(A, xcEqual, FractionGroupReady);
  X64NegReg(A, xrRAX);
  X64BindLabel(A, FractionGroupReady);
  X64MovRegImm64(A, xrR11, 10);
  X64BindLabel(A, FractionLoop);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64XorRegReg(A, xrRDX, xrRDX);
  X64DivReg(A, xrR11);
  X64AddRegImm32(A, xrRDX, Ord('0'));
  X64SubRegImm32(A, xrR9, 1);
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64SubRegImm32(A, xrR8, 1);
  X64SubRegImm32(A, xrR14, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64TestRegReg(A, xrR14, xrR14);
  X64JumpCondition(A, xcEqual, FractionDone);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcNotEqual, FractionNoSpace);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64SubRegImm32(A, xrR9, 1);
  X64MovRegImm64(A, xrRDX, Ord(' '));
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64SubRegImm32(A, xrR8, 1);
  X64MovRegImm64(A, xrRCX, 3);
  X64BindLabel(A, FractionNoSpace);
  X64Jump(A, FractionLoop);
  X64BindLabel(A, FractionDone);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64LeaRegRipWritable(A, xrRDX, D.CurrentDecimalMark, 0);
  X64MovRegMemBaseDisp(A, xrRDX, xrRDX, 0);
  X64SubRegImm32(A, xrR9, 1);
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64SubRegImm32(A, xrR8, 1);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, IntegerDone);
  X64MovRegImm64(A, xrRCX, 3);

  X64BindLabel(A, IntegerLoop);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64XorRegReg(A, xrRDX, xrRDX);
  X64DivReg(A, xrR11);
  X64AddRegImm32(A, xrRDX, Ord('0'));
  X64SubRegImm32(A, xrR9, 1);
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64SubRegImm32(A, xrR8, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, IntegerDone);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcNotEqual, IntegerNoSpace);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64SubRegImm32(A, xrR9, 1);
  X64MovRegImm64(A, xrRDX, Ord(' '));
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64SubRegImm32(A, xrR8, 1);
  X64MovRegImm64(A, xrRCX, 3);
  X64BindLabel(A, IntegerNoSpace);
  X64Jump(A, IntegerLoop);

  X64BindLabel(A, IntegerDone);
  X64TestRegReg(A, xrR10, xrR10);
  X64JumpCondition(A, xcEqual, NoSign);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Overflow);
  X64SubRegImm32(A, xrR9, 1);
  X64MovRegImm64(A, xrRDX, Ord('-'));
  X64MovMemBaseDispReg8(A, xrR9, 0, xrRDX);
  X64BindLabel(A, NoSign);
  X64Jump(A, StorePos);

  X64BindLabel(A, Overflow);
  X64MovRegReg(A, xrRDI, xrRBX);
  X64MovRegReg(A, xrRCX, xrR15);
  X64MovRegImm64(A, xrRDX, Ord('*'));
  X64BindLabel(A, StarLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, StarDone);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRDX);
  X64AddRegImm32(A, xrRDI, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, StarLoop);
  X64BindLabel(A, StarDone);
  X64BindLabel(A, StorePos);
  X64MovRegReg(A, xrRAX, xrR15);
  X64AddRegImm32(A, xrRAX, 1);
  X64MovMemBaseDispReg32(A, xrR12, S67_TEXT_POS_OFFSET, xrRAX);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64PopReg(A, xrRBX);
  X64Ret(A);
end;

procedure EmitS67TextGetReal(var A: TX64Assembler; LabelId: Int32;
  const D: TS67NativeDataOffsets; const Links: TS67NativeLinks);
var
  SkipSpace, SignReady, NumberStart, WholeLoop, FractionStart, FractionLoop,
  MantissaDone, ExponentStart, ExponentSignReady, ExponentLoop, ExponentDone,
  ScaleReady, ScalePositive, ScaleNegative, ScalePosLoop, ScaleNegLoop,
  ApplySign, Commit, NoExponent, MarkNegative, MarkExponentNegative,
  ExponentAfterMarker, SkipOneReal: Int32;
begin
  SkipSpace := X64NewLabel(A);
  SignReady := X64NewLabel(A);
  NumberStart := X64NewLabel(A);
  WholeLoop := X64NewLabel(A);
  FractionStart := X64NewLabel(A);
  FractionLoop := X64NewLabel(A);
  MantissaDone := X64NewLabel(A);
  ExponentStart := X64NewLabel(A);
  ExponentSignReady := X64NewLabel(A);
  ExponentLoop := X64NewLabel(A);
  ExponentDone := X64NewLabel(A);
  ScaleReady := X64NewLabel(A);
  ScalePositive := X64NewLabel(A);
  ScaleNegative := X64NewLabel(A);
  ScalePosLoop := X64NewLabel(A);
  ScaleNegLoop := X64NewLabel(A);
  ApplySign := X64NewLabel(A);
  Commit := X64NewLabel(A);
  NoExponent := X64NewLabel(A);
  MarkNegative := X64NewLabel(A);
  MarkExponentNegative := X64NewLabel(A);
  ExponentAfterMarker := X64NewLabel(A);
  SkipOneReal := X64NewLabel(A);

  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64PushReg(A, xrRBX);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64PushReg(A, xrR15);
  X64MovRegReg(A, xrR12, xrRDI);
  X64MovRegMemBaseDisp(A, xrR13, xrR12, S67_TEXT_START_OFFSET);
  X64MovSXRegMemBaseDisp32(A, xrR14, xrR12, S67_TEXT_POS_OFFSET);
  X64MovSXRegMemBaseDisp32(A, xrR15, xrR12, S67_TEXT_LENGTH_OFFSET);
  X64CmpRegImm32(A, xrR14, 1);
  X64JumpCondition(A, xcLess, Links.PanicText);
  X64XorRegReg(A, xrRBX, xrRBX); { bit 0 number sign, bit 1 exponent sign }

  X64BindLabel(A, SkipSpace);
  X64CmpRegReg(A, xrR14, xrR15);
  X64JumpCondition(A, xcGreater, Links.PanicText);
  X64MovRegReg(A, xrRCX, xrR13);
  X64AddRegReg(A, xrRCX, xrR14);
  X64MovRegMemBaseDisp8(A, xrRDX, xrRCX, -1);
  X64CmpRegImm32(A, xrRDX, Ord(' '));
  X64JumpCondition(A, xcEqual, SkipOneReal);
  X64CmpRegImm32(A, xrRDX, 9);
  X64JumpCondition(A, xcNotEqual, SignReady);
  X64BindLabel(A, SkipOneReal);
  X64AddRegImm32(A, xrR14, 1);
  X64Jump(A, SkipSpace);

  X64BindLabel(A, SignReady);
  X64CmpRegImm32(A, xrRDX, Ord('-'));
  X64JumpCondition(A, xcEqual, MarkNegative);
  X64CmpRegImm32(A, xrRDX, Ord('+'));
  X64JumpCondition(A, xcNotEqual, NumberStart);
  X64AddRegImm32(A, xrR14, 1);
  X64Jump(A, NumberStart);
  X64BindLabel(A, MarkNegative);
  X64MovRegImm64(A, xrRBX, 1);
  X64AddRegImm32(A, xrR14, 1);

  X64BindLabel(A, NumberStart);
  X64MovRegImm64(A, xrRAX, 0);
  X64MovQXMMReg(A, xrXMM0, xrRAX);
  X64MovRegImm64(A, xrRAX, QWord($4024000000000000)); { 10.0 }
  X64MovQXMMReg(A, xrXMM2, xrRAX);
  X64XorRegReg(A, xrR8, xrR8);  { digit count }
  X64XorRegReg(A, xrR9, xrR9);  { fractional digit count }

  X64BindLabel(A, WholeLoop);
  X64CmpRegReg(A, xrR14, xrR15);
  X64JumpCondition(A, xcGreater, MantissaDone);
  X64MovRegReg(A, xrRCX, xrR13);
  X64AddRegReg(A, xrRCX, xrR14);
  X64MovRegMemBaseDisp8(A, xrRDX, xrRCX, -1);
  X64LeaRegRipWritable(A, xrRAX, D.CurrentDecimalMark, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrRAX, 0);
  X64CmpRegReg(A, xrRDX, xrRAX);
  X64JumpCondition(A, xcEqual, FractionStart);
  X64CmpRegImm32(A, xrRDX, Ord('0'));
  X64JumpCondition(A, xcLess, MantissaDone);
  X64CmpRegImm32(A, xrRDX, Ord('9'));
  X64JumpCondition(A, xcGreater, MantissaDone);
  X64MulSD(A, xrXMM0, xrXMM2);
  X64SubRegImm32(A, xrRDX, Ord('0'));
  X64CVTSI2SD(A, xrXMM1, xrRDX);
  X64AddSD(A, xrXMM0, xrXMM1);
  X64AddRegImm32(A, xrR8, 1);
  X64AddRegImm32(A, xrR14, 1);
  X64Jump(A, WholeLoop);

  X64BindLabel(A, FractionStart);
  X64AddRegImm32(A, xrR14, 1);
  X64BindLabel(A, FractionLoop);
  X64CmpRegReg(A, xrR14, xrR15);
  X64JumpCondition(A, xcGreater, MantissaDone);
  X64MovRegReg(A, xrRCX, xrR13);
  X64AddRegReg(A, xrRCX, xrR14);
  X64MovRegMemBaseDisp8(A, xrRDX, xrRCX, -1);
  X64CmpRegImm32(A, xrRDX, Ord('0'));
  X64JumpCondition(A, xcLess, MantissaDone);
  X64CmpRegImm32(A, xrRDX, Ord('9'));
  X64JumpCondition(A, xcGreater, MantissaDone);
  X64MulSD(A, xrXMM0, xrXMM2);
  X64SubRegImm32(A, xrRDX, Ord('0'));
  X64CVTSI2SD(A, xrXMM1, xrRDX);
  X64AddSD(A, xrXMM0, xrXMM1);
  X64AddRegImm32(A, xrR8, 1);
  X64AddRegImm32(A, xrR9, 1);
  X64AddRegImm32(A, xrR14, 1);
  X64Jump(A, FractionLoop);

  X64BindLabel(A, MantissaDone);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64XorRegReg(A, xrR10, xrR10); { explicit exponent }
  X64CmpRegReg(A, xrR14, xrR15);
  X64JumpCondition(A, xcGreater, NoExponent);
  X64MovRegReg(A, xrRCX, xrR13);
  X64AddRegReg(A, xrRCX, xrR14);
  X64MovRegMemBaseDisp8(A, xrRDX, xrRCX, -1);
  X64LeaRegRipWritable(A, xrRAX, D.CurrentLowTen, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrRAX, 0);
  X64CmpRegReg(A, xrRDX, xrRAX);
  X64JumpCondition(A, xcNotEqual, NoExponent);

  X64BindLabel(A, ExponentStart);
  X64AddRegImm32(A, xrR14, 1);
  X64CmpRegReg(A, xrR14, xrR15);
  X64JumpCondition(A, xcGreater, Links.PanicText);
  { Accept the historical && exponent marker as one token. }
  X64MovRegReg(A, xrRCX, xrR13);
  X64AddRegReg(A, xrRCX, xrR14);
  X64MovRegMemBaseDisp8(A, xrRDX, xrRCX, -1);
  X64LeaRegRipWritable(A, xrRAX, D.CurrentLowTen, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrRAX, 0);
  X64CmpRegReg(A, xrRDX, xrRAX);
  X64JumpCondition(A, xcNotEqual, ExponentAfterMarker);
  X64AddRegImm32(A, xrR14, 1);
  X64CmpRegReg(A, xrR14, xrR15);
  X64JumpCondition(A, xcGreater, Links.PanicText);
  X64MovRegReg(A, xrRCX, xrR13);
  X64AddRegReg(A, xrRCX, xrR14);
  X64MovRegMemBaseDisp8(A, xrRDX, xrRCX, -1);
  X64BindLabel(A, ExponentAfterMarker);
  X64CmpRegImm32(A, xrRDX, Ord('-'));
  X64JumpCondition(A, xcEqual, MarkExponentNegative);
  X64CmpRegImm32(A, xrRDX, Ord('+'));
  X64JumpCondition(A, xcNotEqual, ExponentSignReady);
  X64AddRegImm32(A, xrR14, 1);
  X64Jump(A, ExponentSignReady);
  X64BindLabel(A, MarkExponentNegative);
  X64MovRegImm64(A, xrRAX, 2);
  X64OrRegReg(A, xrRBX, xrRAX);
  X64AddRegImm32(A, xrR14, 1);

  X64BindLabel(A, ExponentSignReady);
  X64XorRegReg(A, xrR11, xrR11); { exponent digit count }
  X64BindLabel(A, ExponentLoop);
  X64CmpRegReg(A, xrR14, xrR15);
  X64JumpCondition(A, xcGreater, ExponentDone);
  X64MovRegReg(A, xrRCX, xrR13);
  X64AddRegReg(A, xrRCX, xrR14);
  X64MovRegMemBaseDisp8(A, xrRDX, xrRCX, -1);
  X64CmpRegImm32(A, xrRDX, Ord('0'));
  X64JumpCondition(A, xcLess, ExponentDone);
  X64CmpRegImm32(A, xrRDX, Ord('9'));
  X64JumpCondition(A, xcGreater, ExponentDone);
  X64CmpRegImm32(A, xrR10, 4096);
  X64JumpCondition(A, xcGreaterEqual, ExponentDone);
  X64IMulRegRegImm32(A, xrR10, xrR10, 10);
  X64SubRegImm32(A, xrRDX, Ord('0'));
  X64AddRegReg(A, xrR10, xrRDX);
  X64AddRegImm32(A, xrR11, 1);
  X64AddRegImm32(A, xrR14, 1);
  X64Jump(A, ExponentLoop);
  X64BindLabel(A, ExponentDone);
  X64TestRegReg(A, xrR11, xrR11);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64MovRegReg(A, xrRAX, xrRBX);
  X64AndRegImm32(A, xrRAX, 2);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, ScaleReady);
  X64NegReg(A, xrR10);
  X64Jump(A, ScaleReady);

  X64BindLabel(A, NoExponent);
  X64XorRegReg(A, xrR10, xrR10);
  X64BindLabel(A, ScaleReady);
  X64SubRegReg(A, xrR10, xrR9);
  X64TestRegReg(A, xrR10, xrR10);
  X64JumpCondition(A, xcGreater, ScalePositive);
  X64JumpCondition(A, xcLess, ScaleNegative);
  X64Jump(A, ApplySign);
  X64BindLabel(A, ScalePositive);
  X64BindLabel(A, ScalePosLoop);
  X64MulSD(A, xrXMM0, xrXMM2);
  X64SubRegImm32(A, xrR10, 1);
  X64JumpCondition(A, xcNotEqual, ScalePosLoop);
  X64Jump(A, ApplySign);
  X64BindLabel(A, ScaleNegative);
  X64NegReg(A, xrR10);
  X64BindLabel(A, ScaleNegLoop);
  X64DivSD(A, xrXMM0, xrXMM2);
  X64SubRegImm32(A, xrR10, 1);
  X64JumpCondition(A, xcNotEqual, ScaleNegLoop);

  X64BindLabel(A, ApplySign);
  X64MovQRegXMM(A, xrRAX, xrXMM0);
  X64MovRegReg(A, xrRCX, xrRBX);
  X64AndRegImm32(A, xrRCX, 1);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, Commit);
  X64MovRegImm64(A, xrRDX, QWord($8000000000000000));
  X64XorRegReg(A, xrRAX, xrRDX);
  X64BindLabel(A, Commit);
  X64MovMemBaseDispReg32(A, xrR12, S67_TEXT_POS_OFFSET, xrR14);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64PopReg(A, xrRBX);
  X64Ret(A);
end;

procedure EmitS67TextWrite(var A: TX64Assembler; LabelId: Int32;
  const Links: TS67NativeLinks);
var
  Done: Int32;
begin
  Done := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, Done);
  X64MovSXRegMemBaseDisp32(A, xrRSI, xrRDI, S67_TEXT_LENGTH_OFFSET);
  X64MovRegMemBaseDisp(A, xrRDI, xrRDI, S67_TEXT_START_OFFSET);
  X64Call(A, Links.WriteRaw);
  X64BindLabel(A, Done);
  X64Ret(A);
end;

procedure EmitS67TextBlanks(var A: TX64Assembler; LabelId, ArenaLabel: Int32;
  const Links: TS67NativeLinks);
var
  FillLoop, Filled, EmptyResult: Int32;
begin
  FillLoop := X64NewLabel(A);
  Filled := X64NewLabel(A);
  EmptyResult := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcLess, Links.PanicText);
  X64JumpCondition(A, xcEqual, EmptyResult);
  X64PushReg(A, xrR12);
  X64MovRegReg(A, xrR12, xrRDI);
  X64AddRegImm32(A, xrRDI, 32);
  X64JumpCondition(A, xcOverflow, Links.PanicText);
  X64Call(A, ArenaLabel);
  X64MovRegReg(A, xrR8, xrRAX);
  X64AddRegImm32(A, xrRAX, 16);
  X64MovMemBaseDispReg(A, xrR8, 0, xrRAX); { main is the visible frame }
  X64MovRegImm64(A, xrRCX, 1);
  X64MovMemBaseDispReg(A, xrR8, 8, xrRCX); { writable }
  X64MovRegReg(A, xrRDX, xrR8);
  X64AddRegImm32(A, xrRDX, 32);
  X64MovMemBaseDispReg(A, xrRAX, S67_TEXT_START_OFFSET, xrRDX);
  X64MovMemBaseDispReg32(A, xrRAX, S67_TEXT_POS_OFFSET, xrRCX);
  X64MovMemBaseDispReg32(A, xrRAX, S67_TEXT_LENGTH_OFFSET, xrR12);
  X64MovRegReg(A, xrRDI, xrRDX);
  X64MovRegReg(A, xrRCX, xrR12);
  X64MovRegImm64(A, xrRDX, Ord(' '));
  X64BindLabel(A, FillLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, Filled);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRDX);
  X64AddRegImm32(A, xrRDI, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, FillLoop);
  X64BindLabel(A, Filled);
  X64PopReg(A, xrR12);
  X64Ret(A);
  X64BindLabel(A, EmptyResult);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitS67TextCopy(var A: TX64Assembler; LabelId, BlanksLabel: Int32);
var
  CopyLoop, Done, EmptyResult: Int32;
begin
  CopyLoop := X64NewLabel(A);
  Done := X64NewLabel(A);
  EmptyResult := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, EmptyResult);
  X64MovSXRegMemBaseDisp32(A, xrRAX, xrRDI, S67_TEXT_LENGTH_OFFSET);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, EmptyResult);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64MovRegReg(A, xrR12, xrRDI);
  X64MovRegReg(A, xrRDI, xrRAX);
  X64MovRegReg(A, xrR13, xrRDI);
  X64Call(A, BlanksLabel);
  X64MovRegReg(A, xrR8, xrRAX);
  X64MovRegMemBaseDisp(A, xrRSI, xrR12, S67_TEXT_START_OFFSET);
  X64MovRegMemBaseDisp(A, xrRDI, xrR8, S67_TEXT_START_OFFSET);
  X64MovRegReg(A, xrRCX, xrR13);
  X64BindLabel(A, CopyLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, Done);
  X64MovRegMemBaseDisp8(A, xrRDX, xrRSI, 0);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRDX);
  X64AddRegImm32(A, xrRSI, 1);
  X64AddRegImm32(A, xrRDI, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, CopyLoop);
  X64BindLabel(A, Done);
  X64MovRegReg(A, xrRAX, xrR8);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64Ret(A);
  X64BindLabel(A, EmptyResult);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitS67TextAssign(var A: TX64Assembler; LabelId: Int32;
  const Links: TS67NativeLinks);
var
  CopyLoop, FillLoop, DoneCopy, Done: Int32;
begin
  CopyLoop := X64NewLabel(A);
  FillLoop := X64NewLabel(A);
  DoneCopy := X64NewLabel(A);
  Done := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64MovRegMemBaseDisp(A, xrRAX, xrRDI, -8);
  X64AndRegImm32(A, xrRAX, 1);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64PushReg(A, xrR12);
  X64MovRegReg(A, xrR12, xrRDI);
  X64MovSXRegMemBaseDisp32(A, xrR8, xrR12, S67_TEXT_LENGTH_OFFSET);
  X64XorRegReg(A, xrR9, xrR9);
  X64TestRegReg(A, xrRSI, xrRSI);
  X64JumpCondition(A, xcEqual, DoneCopy);
  X64MovSXRegMemBaseDisp32(A, xrR9, xrRSI, S67_TEXT_LENGTH_OFFSET);
  X64CmpRegReg(A, xrR9, xrR8);
  X64JumpCondition(A, xcGreater, Links.PanicText);
  X64MovRegMemBaseDisp(A, xrR10, xrRSI, S67_TEXT_START_OFFSET);
  X64MovRegMemBaseDisp(A, xrR11, xrR12, S67_TEXT_START_OFFSET);
  X64MovRegReg(A, xrRCX, xrR9);
  X64BindLabel(A, CopyLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, DoneCopy);
  X64MovRegMemBaseDisp8(A, xrRAX, xrR10, 0);
  X64MovMemBaseDispReg8(A, xrR11, 0, xrRAX);
  X64AddRegImm32(A, xrR10, 1);
  X64AddRegImm32(A, xrR11, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, CopyLoop);
  X64BindLabel(A, DoneCopy);
  X64MovRegMemBaseDisp(A, xrR11, xrR12, S67_TEXT_START_OFFSET);
  X64AddRegReg(A, xrR11, xrR9);
  X64MovRegReg(A, xrRCX, xrR8);
  X64SubRegReg(A, xrRCX, xrR9);
  X64MovRegImm64(A, xrRDX, Ord(' '));
  X64BindLabel(A, FillLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, Done);
  X64MovMemBaseDispReg8(A, xrR11, 0, xrRDX);
  X64AddRegImm32(A, xrR11, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, FillLoop);
  X64BindLabel(A, Done);
  X64MovRegReg(A, xrRAX, xrR12);
  X64PopReg(A, xrR12);
  X64Ret(A);
end;

procedure EmitS67TextConcat(var A: TX64Assembler; LabelId, BlanksLabel: Int32;
  const Links: TS67NativeLinks);
var
  HaveLeftLength, HaveRightLength, LeftLoop, RightLoop, CopyRight,
  Finish, ReturnEmpty: Int32;
begin
  HaveLeftLength := X64NewLabel(A);
  HaveRightLength := X64NewLabel(A);
  LeftLoop := X64NewLabel(A);
  RightLoop := X64NewLabel(A);
  CopyRight := X64NewLabel(A);
  Finish := X64NewLabel(A);
  ReturnEmpty := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64PushReg(A, xrRBX);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64PushReg(A, xrR15);
  X64MovRegReg(A, xrR12, xrRDI);
  X64MovRegReg(A, xrR13, xrRSI);
  X64XorRegReg(A, xrR14, xrR14);
  X64XorRegReg(A, xrR15, xrR15);
  X64TestRegReg(A, xrR12, xrR12);
  X64JumpCondition(A, xcEqual, HaveLeftLength);
  X64MovSXRegMemBaseDisp32(A, xrR14, xrR12, S67_TEXT_LENGTH_OFFSET);
  X64BindLabel(A, HaveLeftLength);
  X64TestRegReg(A, xrR13, xrR13);
  X64JumpCondition(A, xcEqual, HaveRightLength);
  X64MovSXRegMemBaseDisp32(A, xrR15, xrR13, S67_TEXT_LENGTH_OFFSET);
  X64BindLabel(A, HaveRightLength);
  X64MovRegReg(A, xrRDI, xrR14);
  X64AddRegReg(A, xrRDI, xrR15);
  X64JumpCondition(A, xcOverflow, Links.PanicText);
  X64CmpRegImm32(A, xrRDI, High(Int32));
  X64JumpCondition(A, xcGreater, Links.PanicText);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, ReturnEmpty);
  X64Call(A, BlanksLabel);
  X64MovRegReg(A, xrRBX, xrRAX);
  X64MovRegMemBaseDisp(A, xrRDI, xrRBX, S67_TEXT_START_OFFSET);
  X64TestRegReg(A, xrR14, xrR14);
  X64JumpCondition(A, xcEqual, CopyRight);
  X64MovRegMemBaseDisp(A, xrRSI, xrR12, S67_TEXT_START_OFFSET);
  X64MovRegReg(A, xrRCX, xrR14);
  X64BindLabel(A, LeftLoop);
  X64MovRegMemBaseDisp8(A, xrRDX, xrRSI, 0);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRDX);
  X64AddRegImm32(A, xrRSI, 1);
  X64AddRegImm32(A, xrRDI, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64JumpCondition(A, xcNotEqual, LeftLoop);
  X64BindLabel(A, CopyRight);
  X64TestRegReg(A, xrR15, xrR15);
  X64JumpCondition(A, xcEqual, Finish);
  X64MovRegMemBaseDisp(A, xrRSI, xrR13, S67_TEXT_START_OFFSET);
  X64MovRegReg(A, xrRCX, xrR15);
  X64BindLabel(A, RightLoop);
  X64MovRegMemBaseDisp8(A, xrRDX, xrRSI, 0);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRDX);
  X64AddRegImm32(A, xrRSI, 1);
  X64AddRegImm32(A, xrRDI, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64JumpCondition(A, xcNotEqual, RightLoop);
  X64BindLabel(A, Finish);
  X64MovRegReg(A, xrRAX, xrRBX);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64PopReg(A, xrRBX);
  X64Ret(A);
  X64BindLabel(A, ReturnEmpty);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64PopReg(A, xrRBX);
  X64Ret(A);
end;

procedure EmitS67TextEqual(var A: TX64Assembler; LabelId: Int32);
var
  LeftNil, RightNil, LengthsReady, LoopStart, NotEqual, EqualResult,
  Done: Int32;
begin
  LeftNil := X64NewLabel(A);
  RightNil := X64NewLabel(A);
  LengthsReady := X64NewLabel(A);
  LoopStart := X64NewLabel(A);
  NotEqual := X64NewLabel(A);
  EqualResult := X64NewLabel(A);
  Done := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64XorRegReg(A, xrR8, xrR8);
  X64XorRegReg(A, xrR9, xrR9);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, LeftNil);
  X64MovSXRegMemBaseDisp32(A, xrR8, xrRDI, S67_TEXT_LENGTH_OFFSET);
  X64Jump(A, RightNil);
  X64BindLabel(A, LeftNil);
  X64XorRegReg(A, xrRDI, xrRDI);
  X64BindLabel(A, RightNil);
  X64TestRegReg(A, xrRSI, xrRSI);
  X64JumpCondition(A, xcEqual, LengthsReady);
  X64MovSXRegMemBaseDisp32(A, xrR9, xrRSI, S67_TEXT_LENGTH_OFFSET);
  X64BindLabel(A, LengthsReady);
  X64CmpRegReg(A, xrR8, xrR9);
  X64JumpCondition(A, xcNotEqual, NotEqual);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, EqualResult);
  X64MovRegMemBaseDisp(A, xrR10, xrRDI, S67_TEXT_START_OFFSET);
  X64MovRegMemBaseDisp(A, xrR11, xrRSI, S67_TEXT_START_OFFSET);
  X64MovRegReg(A, xrRCX, xrR8);
  X64BindLabel(A, LoopStart);
  X64MovRegMemBaseDisp8(A, xrRAX, xrR10, 0);
  X64MovRegMemBaseDisp8(A, xrRDX, xrR11, 0);
  X64CmpRegReg(A, xrRAX, xrRDX);
  X64JumpCondition(A, xcNotEqual, NotEqual);
  X64AddRegImm32(A, xrR10, 1);
  X64AddRegImm32(A, xrR11, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64JumpCondition(A, xcNotEqual, LoopStart);
  X64BindLabel(A, EqualResult);
  X64MovRegImm64(A, xrRAX, 1);
  X64Jump(A, Done);
  X64BindLabel(A, NotEqual);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64BindLabel(A, Done);
  X64Ret(A);
end;

procedure EmitS67LowTen(var A: TX64Assembler; LabelId: Int32;
  const D: TS67NativeDataOffsets; const Links: TS67NativeLinks);
var
  Legal: Int32;
begin
  Legal := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64CmpRegImm32(A, xrRDI, 32);
  X64JumpCondition(A, xcLess, Links.PanicText);
  X64CmpRegImm32(A, xrRDI, 126);
  X64JumpCondition(A, xcGreater, Links.PanicText);
  X64CmpRegImm32(A, xrRDI, Ord('0'));
  X64JumpCondition(A, xcLess, Legal);
  X64CmpRegImm32(A, xrRDI, Ord('9'));
  X64JumpCondition(A, xcLessEqual, Links.PanicText);
  X64BindLabel(A, Legal);
  X64CmpRegImm32(A, xrRDI, Ord('+'));
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64CmpRegImm32(A, xrRDI, Ord('-'));
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64CmpRegImm32(A, xrRDI, Ord('.'));
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64CmpRegImm32(A, xrRDI, Ord(','));
  X64JumpCondition(A, xcEqual, Links.PanicText);
  X64LeaRegRipWritable(A, xrRCX, D.CurrentLowTen, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrRCX, 0);
  X64MovMemBaseDispReg(A, xrRCX, 0, xrRDI);
  X64Ret(A);
end;

procedure EmitS67DecimalMark(var A: TX64Assembler; LabelId: Int32;
  const D: TS67NativeDataOffsets; const Links: TS67NativeLinks);
var
  Legal: Int32;
begin
  Legal := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64CmpRegImm32(A, xrRDI, Ord('.'));
  X64JumpCondition(A, xcEqual, Legal);
  X64CmpRegImm32(A, xrRDI, Ord(','));
  X64JumpCondition(A, xcNotEqual, Links.PanicText);
  X64BindLabel(A, Legal);
  X64LeaRegRipWritable(A, xrRCX, D.CurrentDecimalMark, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrRCX, 0);
  X64MovMemBaseDispReg(A, xrRCX, 0, xrRDI);
  X64Ret(A);
end;

procedure EmitS67CaseMap(var A: TX64Assembler; LabelId: Int32;
  ToUpper: Boolean; const Links: TS67NativeLinks);
var
  LoopStart, NextChar, ConvertChar, Finish, ReturnNil: Int32;
begin
  LoopStart := X64NewLabel(A);
  NextChar := X64NewLabel(A);
  ConvertChar := X64NewLabel(A);
  Finish := X64NewLabel(A);
  ReturnNil := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64MovRegReg(A, xrRAX, xrRDI);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, ReturnNil);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64PushReg(A, xrR15);
  X64MovRegReg(A, xrR12, xrRDI);
  X64MovRegMemBaseDisp(A, xrR13, xrR12, S67_TEXT_START_OFFSET);
  X64MovSXRegMemBaseDisp32(A, xrR14, xrR12, S67_TEXT_LENGTH_OFFSET);
  X64MovRegMemBaseDisp(A, xrR15, xrR12, -8);
  X64AndRegImm32(A, xrR15, 1);
  X64XorRegReg(A, xrRCX, xrRCX);
  X64BindLabel(A, LoopStart);
  X64CmpRegReg(A, xrRCX, xrR14);
  X64JumpCondition(A, xcGreaterEqual, Finish);
  X64MovRegReg(A, xrR8, xrR13);
  X64AddRegReg(A, xrR8, xrRCX);
  X64MovRegMemBaseDisp8(A, xrR9, xrR8, 0);
  if ToUpper then
  begin
    X64CmpRegImm32(A, xrR9, Ord('a'));
    X64JumpCondition(A, xcLess, NextChar);
    X64CmpRegImm32(A, xrR9, Ord('z'));
    X64JumpCondition(A, xcLessEqual, ConvertChar);
  end
  else
  begin
    X64CmpRegImm32(A, xrR9, Ord('A'));
    X64JumpCondition(A, xcLess, NextChar);
    X64CmpRegImm32(A, xrR9, Ord('Z'));
    X64JumpCondition(A, xcLessEqual, ConvertChar);
  end;
  X64Jump(A, NextChar);
  X64BindLabel(A, ConvertChar);
  X64TestRegReg(A, xrR15, xrR15);
  X64JumpCondition(A, xcEqual, Links.PanicText);
  if ToUpper then
    X64SubRegImm32(A, xrR9, 32)
  else
    X64AddRegImm32(A, xrR9, 32);
  X64MovMemBaseDispReg8(A, xrR8, 0, xrR9);
  X64BindLabel(A, NextChar);
  X64AddRegImm32(A, xrRCX, 1);
  X64Jump(A, LoopStart);
  X64BindLabel(A, Finish);
  X64MovSXRegMemBaseDisp32(A, xrRCX, xrR12, S67_TEXT_LENGTH_OFFSET);
  X64AddRegImm32(A, xrRCX, 1);
  X64MovMemBaseDispReg32(A, xrR12, S67_TEXT_POS_OFFSET, xrRCX);
  X64MovRegReg(A, xrRAX, xrR12);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64Ret(A);
  X64BindLabel(A, ReturnNil);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitS67MathX87(var A: TX64Assembler; LabelId: Int32; Kind: Byte);
begin
  X64BindLabel(A, LabelId);
  X64PushReg(A, xrRBP);
  X64MovRegReg(A, xrRBP, xrRSP);
  X64SubRegImm32(A, xrRSP, 16);
  X64MovMemBaseDispReg(A, xrRSP, 0, xrRDI);
  case Kind of
    0: begin { sqrt }
         X64EmitByte(A, $DD); X64EmitByte(A, $04); X64EmitByte(A, $24);
         X64EmitByte(A, $D9); X64EmitByte(A, $FA);
       end;
    1: begin { sin }
         X64EmitByte(A, $DD); X64EmitByte(A, $04); X64EmitByte(A, $24);
         X64EmitByte(A, $D9); X64EmitByte(A, $FE);
       end;
    2: begin { cos }
         X64EmitByte(A, $DD); X64EmitByte(A, $04); X64EmitByte(A, $24);
         X64EmitByte(A, $D9); X64EmitByte(A, $FF);
       end;
    3: begin { tan }
         X64EmitByte(A, $DD); X64EmitByte(A, $04); X64EmitByte(A, $24);
         X64EmitByte(A, $D9); X64EmitByte(A, $F2);
         X64EmitByte(A, $DD); X64EmitByte(A, $D8);
       end;
    4: begin { arctan }
         X64EmitByte(A, $DD); X64EmitByte(A, $04); X64EmitByte(A, $24);
         X64EmitByte(A, $D9); X64EmitByte(A, $E8);
         X64EmitByte(A, $D9); X64EmitByte(A, $F3);
       end;
    5: begin { ln }
         X64EmitByte(A, $D9); X64EmitByte(A, $ED);
         X64EmitByte(A, $DD); X64EmitByte(A, $04); X64EmitByte(A, $24);
         X64EmitByte(A, $D9); X64EmitByte(A, $F1);
       end;
    6: begin { log10 }
         X64EmitByte(A, $D9); X64EmitByte(A, $EC);
         X64EmitByte(A, $DD); X64EmitByte(A, $04); X64EmitByte(A, $24);
         X64EmitByte(A, $D9); X64EmitByte(A, $F1);
       end;
    7: begin { exp: 2^(x*log2(e)) }
         X64EmitByte(A, $D9); X64EmitByte(A, $EA);
         X64EmitByte(A, $DD); X64EmitByte(A, $04); X64EmitByte(A, $24);
         X64EmitByte(A, $DE); X64EmitByte(A, $C9);
         X64EmitByte(A, $D9); X64EmitByte(A, $C0);
         X64EmitByte(A, $D9); X64EmitByte(A, $FC);
         X64EmitByte(A, $D9); X64EmitByte(A, $C9);
         X64EmitByte(A, $D8); X64EmitByte(A, $E1);
         X64EmitByte(A, $D9); X64EmitByte(A, $F0);
         X64EmitByte(A, $D9); X64EmitByte(A, $E8);
         X64EmitByte(A, $DE); X64EmitByte(A, $C1);
         X64EmitByte(A, $D9); X64EmitByte(A, $FD);
         X64EmitByte(A, $DD); X64EmitByte(A, $D9);
       end;
  end;
  X64EmitByte(A, $DD); X64EmitByte(A, $1C); X64EmitByte(A, $24);
  X64MovRegMemBaseDisp(A, xrRAX, xrRSP, 0);
  X64AddRegImm32(A, xrRSP, 16);
  X64Leave(A);
  X64Ret(A);
end;

procedure S67EmitNative(var Assembler: TX64Assembler;
  const Labels: TS67NativeLabels; const Data: TS67NativeDataOffsets;
  const Links: TS67NativeLinks);
begin
  EmitS67Init(Assembler, Labels.Init, Data);
  EmitS67SysIn(Assembler, Labels.SysIn, Data);
  EmitS67SysOut(Assembler, Labels.SysOut, Data);
  EmitS67InImage(Assembler, Labels.InImage, Data, Links);
  EmitS67InChar(Assembler, Labels.InChar, Labels.InImage,
    Labels.TextGetChar, Data, Links);
  EmitS67LastItem(Assembler, Labels.LastItem, Labels.InImage, Data);
  EmitS67InNumber(Assembler, Labels.InInt, Labels.LastItem,
    Labels.TextGetInt, Data, Links);
  EmitS67InNumber(Assembler, Labels.InReal, Labels.LastItem,
    Labels.TextGetReal, Data, Links);
  EmitS67InNumber(Assembler, Labels.InFrac, Labels.LastItem,
    Labels.TextGetFrac, Data, Links);
  EmitS67EndFile(Assembler, Labels.EndFile, Data);
  EmitS67OutImage(Assembler, Labels.OutImage, Data, Links);
  EmitS67OutChar(Assembler, Labels.OutChar, Labels.OutImage,
    Labels.TextPutChar, Data);
  EmitS67OutText(Assembler, Labels.OutText, Labels.OutImage, Data, Links);
  EmitS67InText(Assembler, Labels.InText, Labels.InChar,
    Labels.TextBlanks, Labels.TextPutChar, Links);

  EmitS67ArenaAlloc(Assembler, Labels.ArenaAlloc, Data, Links);
  EmitS67TextConstant(Assembler, Labels.TextConstant);
  EmitS67TextStart(Assembler, Labels.TextStart);
  EmitS67TextLength(Assembler, Labels.TextLength);
  EmitS67TextMain(Assembler, Labels.TextMain);
  EmitS67TextPos(Assembler, Labels.TextPos);
  EmitS67TextSetPos(Assembler, Labels.TextSetPos);
  EmitS67TextMore(Assembler, Labels.TextMore);
  EmitS67TextGetChar(Assembler, Labels.TextGetChar, Links);
  EmitS67TextPutChar(Assembler, Labels.TextPutChar, Links);
  EmitS67TextSub(Assembler, Labels.TextSub, Labels.ArenaAlloc, Links);
  EmitS67TextStrip(Assembler, Labels.TextStrip, Labels.TextSub);
  EmitS67TextGetInt(Assembler, Labels.TextGetInt, Links);
  EmitS67TextGetFrac(Assembler, Labels.TextGetFrac, Data, Links);
  EmitS67TextGetReal(Assembler, Labels.TextGetReal, Data, Links);
  EmitS67TextPutInt(Assembler, Labels.TextPutInt, Links);
  EmitS67TextPutFix(Assembler, Labels.TextPutFix, Data, Links);
  EmitS67TextPutReal(Assembler, Labels.TextPutReal, Data, Links);
  EmitS67TextPutFrac(Assembler, Labels.TextPutFrac, Data, Links);
  EmitS67TextWrite(Assembler, Labels.TextWrite, Links);
  EmitS67TextBlanks(Assembler, Labels.TextBlanks, Labels.ArenaAlloc, Links);
  EmitS67TextCopy(Assembler, Labels.TextCopy, Labels.TextBlanks);
  EmitS67TextAssign(Assembler, Labels.TextAssign, Links);
  EmitS67TextConcat(Assembler, Labels.TextConcat, Labels.TextBlanks, Links);
  EmitS67TextEqual(Assembler, Labels.TextEqual);
  EmitS67TextLeftAdjust(Assembler, Labels.TextLeftAdjust);

  EmitS67Field(Assembler, Labels.Field, Labels.OutImage, Labels.TextSub,
    Data, Links);
  EmitS67OutInt(Assembler, Labels.OutInt, Labels.Field, Labels.TextBlanks,
    Labels.TextSub, Labels.TextPutInt, Labels.TextLeftAdjust,
    Labels.OutText, Links);
  EmitS67OutRealLike(Assembler, Labels.OutFix, Labels.Field,
    Labels.TextBlanks, Labels.TextSub, Labels.TextPutFix,
    Labels.TextLeftAdjust, Labels.OutText, Links);
  EmitS67OutRealLike(Assembler, Labels.OutReal, Labels.Field,
    Labels.TextBlanks, Labels.TextSub, Labels.TextPutReal,
    Labels.TextLeftAdjust, Labels.OutText, Links);
  EmitS67OutRealLike(Assembler, Labels.OutFrac, Labels.Field,
    Labels.TextBlanks, Labels.TextSub, Labels.TextPutFrac,
    Labels.TextLeftAdjust, Labels.OutText, Links);

  EmitS67LowTen(Assembler, Labels.LowTen, Data, Links);
  EmitS67DecimalMark(Assembler, Labels.DecimalMark, Data, Links);
  EmitS67CaseMap(Assembler, Labels.Upcase, True, Links);
  EmitS67CaseMap(Assembler, Labels.Lowcase, False, Links);
  EmitS67MathX87(Assembler, Labels.MathSqrt, 0);
  EmitS67MathX87(Assembler, Labels.MathSin, 1);
  EmitS67MathX87(Assembler, Labels.MathCos, 2);
  EmitS67MathX87(Assembler, Labels.MathTan, 3);
  EmitS67MathX87(Assembler, Labels.MathArctan, 4);
  EmitS67MathX87(Assembler, Labels.MathLn, 5);
  EmitS67MathX87(Assembler, Labels.MathLog10, 6);
  EmitS67MathX87(Assembler, Labels.MathExp, 7);
end;

end.

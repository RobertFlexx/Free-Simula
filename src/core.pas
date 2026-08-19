unit core;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, Classes;

const
  FSIM_VERSION_MAJOR = 3;
  FSIM_VERSION_MINOR = 0;
  FSIM_VERSION_PATCH = 0;
  FSIM_VERSION_STRING = '3.0.0';
  FSIM_TARGET_TRIPLE = 'x86_64-linux-fsim';
  FSIM_INVALID_INDEX = -1;
  FSIM_PAGE_SIZE = 4096;
  FSIM_MAX_IDENTIFIER = 255;
  FSIM_MAX_DIAGNOSTIC = 1023;

type
  TFSimDialect = (fdSimula67, fdFSim);
  TOptLevel = (ol0, ol1, ol2, ol3, olFast);
  TEmitKind = (ekExecutable, ekAssembly, ekRawBytes, ekIR, ekCheck);
  TDiagnosticFormat = (dgText, dgJSON);
  TDiagnosticSeverity = (dsNote, dsWarning, dsError, dsFatal);

  TSourcePos = packed record
    Offset: UInt32;
    Line: UInt32;
    Column: UInt32;
  end;

  TSourceSpan = packed record
    StartPos: TSourcePos;
    EndPos: TSourcePos;
  end;

  TByteArray = array of Byte;
  TInt32Array = array of Int32;
  TUInt32Array = array of UInt32;
  TInt64Array = array of Int64;

  TByteBuffer = record
    Data: TByteArray;
    Count: SizeInt;
  end;

  TStringPoolEntry = packed record
    Offset: UInt32;
    Length: UInt32;
    Hash: UInt32;
  end;

  TStringPool = record
    Bytes: TByteBuffer;
    Entries: array of TStringPoolEntry;
  end;

  TCompilerOptions = record
    Dialect: TFSimDialect;
    Optimization: TOptLevel;
    EmitKind: TEmitKind;
    InputPath: RawByteString;
    OutputPath: RawByteString;
    DumpTokens: Boolean;
    DumpAST: Boolean;
    DumpSymbols: Boolean;
    DumpIR: Boolean;
    DumpRegAlloc: Boolean;
    VerifyEachPass: Boolean;
    WarningsAsErrors: Boolean;
    DebugInfo: Boolean;
    StripSymbols: Boolean;
    ColorDiagnostics: Boolean;
    Deterministic: Boolean;
    BoundsChecks: Boolean;
    OverflowChecks: Boolean;
    NullChecks: Boolean;
    RTTIChecks: Boolean;
    ThreadingEnabled: Boolean;
    ExceptionsEnabled: Boolean;
    EntrySymbol: RawByteString;
    TargetTriple: RawByteString;
    DynamicLinker: RawByteString;
    CRuntimeLibrary: RawByteString;
    StandardLibraryPath: RawByteString;
    ModuleSearchPaths: array of RawByteString;
    DependencyFile: RawByteString;
    DiagnosticFormat: TDiagnosticFormat;
    UseStandardLibrary: Boolean;
    PrintSearchDirs: Boolean;
    PrintFeatures: Boolean;
  end;

procedure InitCompilerOptions(out Options: TCompilerOptions);
function DialectName(Dialect: TFSimDialect): RawByteString;
function OptLevelName(Level: TOptLevel): RawByteString;
function SourcePos(Line, Column, Offset: UInt32): TSourcePos; inline;
function SourceSpan(const A, B: TSourcePos): TSourceSpan; inline;
function AlignUp(Value, Alignment: QWord): QWord; inline;
function IsPowerOfTwo(Value: QWord): Boolean; inline;
function FNV1a32(Data: Pointer; Length: SizeUInt): UInt32;
function HashString(const S: RawByteString): UInt32;
function ASCIIEqualFold(const A, B: RawByteString): Boolean;
function LowerASCII(const S: RawByteString): RawByteString;
function LoadBinaryFile(const Path: RawByteString): RawByteString;
procedure SaveBinaryFile(const Path: RawByteString; const Data; Size: SizeUInt);
procedure BufferInit(var Buffer: TByteBuffer; InitialCapacity: SizeInt = 256);
procedure BufferClear(var Buffer: TByteBuffer);
procedure BufferReserve(var Buffer: TByteBuffer; Additional: SizeInt);
procedure BufferAppendByte(var Buffer: TByteBuffer; Value: Byte); inline;
procedure BufferAppendWord(var Buffer: TByteBuffer; Value: Word);
procedure BufferAppendDWord(var Buffer: TByteBuffer; Value: DWord);
procedure BufferAppendQWord(var Buffer: TByteBuffer; Value: QWord);
procedure BufferAppendInt32(var Buffer: TByteBuffer; Value: Int32);
procedure BufferAppendInt64(var Buffer: TByteBuffer; Value: Int64);
procedure BufferAppend(var Buffer: TByteBuffer; const Data; Size: SizeInt);
procedure BufferAppendZeros(var Buffer: TByteBuffer; Count: SizeInt);
procedure BufferAlign(var Buffer: TByteBuffer; Alignment: SizeInt; Fill: Byte = 0);
procedure BufferPatchDWord(var Buffer: TByteBuffer; Offset: SizeInt; Value: DWord);
procedure BufferPatchQWord(var Buffer: TByteBuffer; Offset: SizeInt; Value: QWord);
function StringPoolIntern(var Pool: TStringPool; const Value: RawByteString): Int32;
function StringPoolGet(const Pool: TStringPool; Index: Int32): RawByteString;
function StringPoolPointer(const Pool: TStringPool; Index: Int32): PAnsiChar;
function CheckedInt32(Value: Int64; const What: RawByteString): Int32;

implementation

procedure InitCompilerOptions(out Options: TCompilerOptions);
begin
  Options := Default(TCompilerOptions);
  Options.Dialect := fdFSim;
  Options.Optimization := ol1;
  Options.EmitKind := ekExecutable;
  Options.OutputPath := 'a.out';
  Options.EntrySymbol := '_start';
  Options.TargetTriple := FSIM_TARGET_TRIPLE;
  Options.CRuntimeLibrary := 'libc.so.6';
  Options.DiagnosticFormat := dgText;
  Options.UseStandardLibrary := True;
  Options.ColorDiagnostics := True;
  Options.Deterministic := True;
  Options.BoundsChecks := True;
  Options.OverflowChecks := True;
  Options.NullChecks := True;
  Options.RTTIChecks := True;
  Options.ThreadingEnabled := True;
  Options.ExceptionsEnabled := True;
end;

function DialectName(Dialect: TFSimDialect): RawByteString;
begin
  case Dialect of
    fdSimula67: Result := 'simula67';
    fdFSim: Result := 'fsim';
  else
    Result := 'unknown';
  end;
end;

function OptLevelName(Level: TOptLevel): RawByteString;
begin
  case Level of
    ol0: Result := 'O0';
    ol1: Result := 'O1';
    ol2: Result := 'O2';
    ol3: Result := 'O3';
    olFast: Result := 'Ofast';
  else
    Result := 'O?';
  end;
end;

function SourcePos(Line, Column, Offset: UInt32): TSourcePos; inline;
begin
  Result.Line := Line;
  Result.Column := Column;
  Result.Offset := Offset;
end;

function SourceSpan(const A, B: TSourcePos): TSourceSpan; inline;
begin
  Result.StartPos := A;
  Result.EndPos := B;
end;

function AlignUp(Value, Alignment: QWord): QWord; inline;
begin
  if Alignment = 0 then
    Exit(Value);
  Result := (Value + Alignment - 1) and not (Alignment - 1);
end;

function IsPowerOfTwo(Value: QWord): Boolean; inline;
begin
  Result := (Value <> 0) and ((Value and (Value - 1)) = 0);
end;

function FNV1a32(Data: Pointer; Length: SizeUInt): UInt32;
var
  P: PByte;
  I: SizeUInt;
  Product: QWord;
begin
  Result := UInt32($811C9DC5);
  if Length = 0 then
    Exit;
  if Data = nil then
    raise EArgumentException.Create('FNV1a32 data pointer is nil');
  P := PByte(Data);
  for I := 0 to Length - 1 do
  begin
    Result := Result xor UInt32(P[I]);
    { FNV-1a is defined modulo 2^32.  Computing the product in QWord and
      masking before narrowing preserves that definition while keeping the
      compiler's global overflow and range checks enabled. }
    Product := QWord(Result) * QWord(16777619);
    Result := UInt32(Product and QWord($FFFFFFFF));
  end;
end;

function HashString(const S: RawByteString): UInt32;
begin
  if Length(S) = 0 then
    Exit(UInt32($811C9DC5));
  Result := FNV1a32(@S[1], Length(S));
end;

function FoldASCII(C: AnsiChar): AnsiChar; inline;
begin
  if (C >= 'A') and (C <= 'Z') then
    Result := AnsiChar(Ord(C) + 32)
  else
    Result := C;
end;

function ASCIIEqualFold(const A, B: RawByteString): Boolean;
var
  I: SizeInt;
begin
  if Length(A) <> Length(B) then
    Exit(False);
  for I := 1 to Length(A) do
    if FoldASCII(A[I]) <> FoldASCII(B[I]) then
      Exit(False);
  Result := True;
end;

function LowerASCII(const S: RawByteString): RawByteString;
var
  I: SizeInt;
begin
  Result := '';
  SetLength(Result, Length(S));
  for I := 1 to Length(S) do
    Result[I] := FoldASCII(S[I]);
end;

function LoadBinaryFile(const Path: RawByteString): RawByteString;
var
  Stream: TFileStream;
  N: Int64;
begin
  Result := '';
  Stream := TFileStream.Create(Path, fmOpenRead or fmShareDenyWrite);
  try
    N := Stream.Size;
    if N < 0 then
      raise EReadError.Create('negative file size');
    if QWord(N) > QWord(High(SizeInt) - 1) then
      raise EReadError.CreateFmt('file is too large: %s', [Path]);
    SetLength(Result, SizeInt(N));
    if N > 0 then
      Stream.ReadBuffer(Result[1], SizeInt(N));
  finally
    Stream.Free;
  end;
end;

procedure SaveBinaryFile(const Path: RawByteString; const Data; Size: SizeUInt);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(Path, fmCreate);
  try
    if Size > 0 then
      Stream.WriteBuffer(Data, Size);
  finally
    Stream.Free;
  end;
end;

procedure BufferInit(var Buffer: TByteBuffer; InitialCapacity: SizeInt);
begin
  Buffer.Count := 0;
  if InitialCapacity < 0 then
    InitialCapacity := 0;
  SetLength(Buffer.Data, InitialCapacity);
end;

procedure BufferClear(var Buffer: TByteBuffer);
begin
  Buffer.Count := 0;
end;

procedure BufferReserve(var Buffer: TByteBuffer; Additional: SizeInt);
var
  Required: SizeInt;
  Capacity: SizeInt;
begin
  if Additional < 0 then
    raise ERangeError.Create('negative byte-buffer reservation');
  if Additional > High(SizeInt) - Buffer.Count then
    raise EOutOfMemory.Create('byte-buffer size overflow');
  Required := Buffer.Count + Additional;
  Capacity := Length(Buffer.Data);
  if Required <= Capacity then
    Exit;
  if Capacity < 256 then
    Capacity := 256;
  while Capacity < Required do
  begin
    if Capacity > High(SizeInt) div 2 then
    begin
      Capacity := Required;
      Break;
    end;
    Capacity := Capacity * 2;
  end;
  SetLength(Buffer.Data, Capacity);
end;

procedure BufferAppendByte(var Buffer: TByteBuffer; Value: Byte); inline;
begin
  BufferReserve(Buffer, 1);
  Buffer.Data[Buffer.Count] := Value;
  Inc(Buffer.Count);
end;

procedure BufferAppendWord(var Buffer: TByteBuffer; Value: Word);
begin
  BufferReserve(Buffer, 2);
  Buffer.Data[Buffer.Count] := Byte(Value);
  Buffer.Data[Buffer.Count + 1] := Byte(Value shr 8);
  Inc(Buffer.Count, 2);
end;

procedure BufferAppendDWord(var Buffer: TByteBuffer; Value: DWord);
begin
  BufferReserve(Buffer, 4);
  Buffer.Data[Buffer.Count] := Byte(Value);
  Buffer.Data[Buffer.Count + 1] := Byte(Value shr 8);
  Buffer.Data[Buffer.Count + 2] := Byte(Value shr 16);
  Buffer.Data[Buffer.Count + 3] := Byte(Value shr 24);
  Inc(Buffer.Count, 4);
end;

procedure BufferAppendQWord(var Buffer: TByteBuffer; Value: QWord);
var
  I: Integer;
begin
  BufferReserve(Buffer, 8);
  for I := 0 to 7 do
    Buffer.Data[Buffer.Count + I] := Byte(Value shr (I * 8));
  Inc(Buffer.Count, 8);
end;

procedure BufferAppendInt32(var Buffer: TByteBuffer; Value: Int32);
begin
  BufferAppendDWord(Buffer, DWord(Value));
end;

procedure BufferAppendInt64(var Buffer: TByteBuffer; Value: Int64);
begin
  BufferAppendQWord(Buffer, QWord(Value));
end;

procedure BufferAppend(var Buffer: TByteBuffer; const Data; Size: SizeInt);
begin
  if Size <= 0 then
    Exit;
  BufferReserve(Buffer, Size);
  Move(Data, Buffer.Data[Buffer.Count], Size);
  Inc(Buffer.Count, Size);
end;

procedure BufferAppendZeros(var Buffer: TByteBuffer; Count: SizeInt);
begin
  if Count <= 0 then
    Exit;
  BufferReserve(Buffer, Count);
  FillChar(Buffer.Data[Buffer.Count], Count, 0);
  Inc(Buffer.Count, Count);
end;

procedure BufferAlign(var Buffer: TByteBuffer; Alignment: SizeInt; Fill: Byte);
var
  Target: SizeInt;
begin
  if Alignment <= 1 then
    Exit;
  if not IsPowerOfTwo(Alignment) then
    raise ERangeError.Create('buffer alignment must be a power of two');
  Target := SizeInt(AlignUp(Buffer.Count, Alignment));
  while Buffer.Count < Target do
    BufferAppendByte(Buffer, Fill);
end;

procedure BufferPatchDWord(var Buffer: TByteBuffer; Offset: SizeInt; Value: DWord);
begin
  if (Offset < 0) or (Offset + 4 > Buffer.Count) then
    raise ERangeError.Create('DWord patch outside byte buffer');
  Buffer.Data[Offset] := Byte(Value);
  Buffer.Data[Offset + 1] := Byte(Value shr 8);
  Buffer.Data[Offset + 2] := Byte(Value shr 16);
  Buffer.Data[Offset + 3] := Byte(Value shr 24);
end;

procedure BufferPatchQWord(var Buffer: TByteBuffer; Offset: SizeInt; Value: QWord);
var
  I: Integer;
begin
  if (Offset < 0) or (Offset + 8 > Buffer.Count) then
    raise ERangeError.Create('QWord patch outside byte buffer');
  for I := 0 to 7 do
    Buffer.Data[Offset + I] := Byte(Value shr (I * 8));
end;

function StringPoolIntern(var Pool: TStringPool; const Value: RawByteString): Int32;
var
  I: Integer;
  H: UInt32;
  Entry: TStringPoolEntry;
begin
  H := HashString(Value);
  for I := 0 to High(Pool.Entries) do
    if (Pool.Entries[I].Hash = H) and
       (Pool.Entries[I].Length = UInt32(Length(Value))) then
      if (Length(Value) = 0) or CompareMem(
        @Pool.Bytes.Data[Pool.Entries[I].Offset], @Value[1], Length(Value)) then
        Exit(I);
  Entry.Offset := Pool.Bytes.Count;
  Entry.Length := Length(Value);
  Entry.Hash := H;
  if Length(Value) > 0 then
    BufferAppend(Pool.Bytes, Value[1], Length(Value));
  BufferAppendByte(Pool.Bytes, 0);
  Result := Length(Pool.Entries);
  SetLength(Pool.Entries, Result + 1);
  Pool.Entries[Result] := Entry;
end;

function StringPoolGet(const Pool: TStringPool; Index: Int32): RawByteString;
begin
  if (Index < 0) or (Index > High(Pool.Entries)) then
    raise ERangeError.Create('string-pool index outside range');
  SetString(Result, PAnsiChar(@Pool.Bytes.Data[Pool.Entries[Index].Offset]),
    Pool.Entries[Index].Length);
end;

function StringPoolPointer(const Pool: TStringPool; Index: Int32): PAnsiChar;
begin
  if (Index < 0) or (Index > High(Pool.Entries)) then
    Exit(nil);
  Result := PAnsiChar(@Pool.Bytes.Data[Pool.Entries[Index].Offset]);
end;

function CheckedInt32(Value: Int64; const What: RawByteString): Int32;
begin
  if (Value < Low(Int32)) or (Value > High(Int32)) then
    raise ERangeError.CreateFmt('%s does not fit in Int32', [What]);
  Result := Int32(Value);
end;

end.

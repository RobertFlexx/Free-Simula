unit elf;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, Classes, BaseUnix, core, diagnostics,
  symbols, ir, registers, x64, runtime, osruntime, s67runtime;

const
  ELF_BASE_ADDRESS = QWord($0000000000400000);
  ELF_TEXT_FILE_OFFSET = QWord($1000);
  ELF_PAGE_SIZE = QWord($1000);

  ELFCLASS64 = 2;
  ELFDATA2LSB = 1;
  EV_CURRENT = 1;
  ELFOSABI_SYSV = 0;
  ET_EXEC = 2;
  EM_X86_64 = 62;

  PT_LOAD = 1;
  PT_DYNAMIC = 2;
  PT_INTERP = 3;
  PF_X = 1;
  PF_W = 2;
  PF_R = 4;

  SHT_NULL = 0;
  SHT_PROGBITS = 1;
  SHT_SYMTAB = 2;
  SHT_STRTAB = 3;
  SHT_RELA = 4;
  SHT_HASH = 5;
  SHT_DYNAMIC = 6;
  SHT_NOBITS = 8;
  SHT_DYNSYM = 11;

  SHF_WRITE = 1;
  SHF_ALLOC = 2;
  SHF_EXECINSTR = 4;

  STB_LOCAL = 0;
  STB_GLOBAL = 1;
  STT_NOTYPE = 0;
  STT_OBJECT = 1;
  STT_FUNC = 2;
  STT_SECTION = 3;

  SHN_UNDEF = 0;

  DT_NULL = 0;
  DT_NEEDED = 1;
  DT_PLTRELSZ = 2;
  DT_HASH = 4;
  DT_STRTAB = 5;
  DT_SYMTAB = 6;
  DT_RELA = 7;
  DT_RELASZ = 8;
  DT_RELAENT = 9;
  DT_STRSZ = 10;
  DT_SYMENT = 11;
  DT_PLTREL = 20;
  DT_DEBUG = 21;
  DT_JMPREL = 23;
  DT_PLTGOT = 3;

  R_X86_64_GLOB_DAT = 6;
  R_X86_64_JUMP_SLOT = 7;

type
  TBackendSymbol = packed record
    Name: RawByteString;
    SectionIndex: Word;
    Bind: Byte;
    SymbolType: Byte;
    Value: QWord;
    Size: QWord;
  end;

  TBackendLayout = record
    FunctionLabels: TInt32Array;
    BlockLabels: TInt32Array;
    FunctionBySymbol: TInt32Array;
    ForeignExportLabels: TInt32Array;
    SymbolStackOffsets: TInt32Array;
    SymbolGlobalOffsets: TInt32Array;
    StringOffsets: TInt32Array;
    RTTIOffsets: TInt32Array;
    VMTOffsets: TInt32Array;
    FunctionFrameSizes: TUInt32Array;
    FunctionStackAdjust: TUInt32Array;
    FunctionSavedMasks: TUInt32Array;
    FunctionReceiverOffsets: TInt32Array;
    FunctionSRetOffsets: TInt32Array;
    ValueAggregateOffsets: TInt32Array;
  end;

  TNativeImage = record
    Text: TByteBuffer;
    ReadOnlyData: TByteBuffer;
    WritableData: TByteBuffer;
    Image: TByteBuffer;
    AssemblyText: RawByteString;
    EntryTextOffset: UInt32;
    BSSSize: UInt32;
    Symbols: array of TBackendSymbol;
  end;

procedure NativeImageInit(var Image: TNativeImage);
procedure NativeImageClear(var Image: TNativeImage);
procedure BuildNativeImage(var ProgramIR: TIRProgram;
  var Symbols: TSymbolTable; const Allocation: TRegisterAllocation;
  const Options: TCompilerOptions; var Diagnostics: TDiagnosticBag;
  out Image: TNativeImage);
procedure WriteNativeOutput(const Image: TNativeImage;
  const Options: TCompilerOptions);

implementation

type
  PUInt64Value = ^QWord;

  TForeignCallFixup = packed record
    PatchOffset: Int32;
    SourceEndOffset: Int32;
    ForeignIndex: Int32;
  end;

  TForeignArgClass = (facNoClass, facInteger, facSSE, facMemory);

  TCABILayout = packed record
    Size: UInt32;
    Alignment: UInt32;
    PartCount: Byte;
    Classes: array[0..1] of TForeignArgClass;
    Memory: Boolean;
  end;

  TForeignArgLocation = packed record
    ValueId: Int32;
    SourceType: Int32;
    ABIType: Int32;
    Layout: TCABILayout;
    RegisterIndex: array[0..1] of Int16;
    StackOffset: Int32;
    IsVariadic: Boolean;
  end;

  TCodeGenerator = record
    Assembler: TX64Assembler;
    ProgramIR: ^TIRProgram;
    Symbols: ^TSymbolTable;
    Allocation: ^TRegisterAllocation;
    Options: ^TCompilerOptions;
    Diagnostics: ^TDiagnosticBag;
    NativeImage: ^TNativeImage;
    Layout: TBackendLayout;
    RuntimeLabels: TRuntimeLabels;
    RuntimeData: TRuntimeDataOffsets;
    CurrentFunction: Int32;
    CurrentInstruction: Int32;
    CurrentEpilogueLabel: Int32;
    PendingParameters: TInt32Array;
    ForeignCalls: array of TForeignCallFixup;
    ProgramGlobalRootOffset: Int32;
    ProgramGlobalRootBytes: Int32;
  end;

function DetectHostDynamicLinker: RawByteString;
var
  OverridePath, Line, Candidate, ProfilePath: RawByteString;
  Maps: TStringList;
  I, SlashPos, LibcPos: Integer;

  function Existing(const Path: RawByteString): RawByteString;
  begin
    if (Path <> '') and FileExists(Path) then Result := Path
    else Result := '';
  end;

  function LoaderBesideLibrary(const LibraryPath: RawByteString): RawByteString;
  var
    DirectoryPath: RawByteString;
  begin
    Result := '';
    if LibraryPath = '' then Exit;
    DirectoryPath := ExtractFileDir(LibraryPath);
    if DirectoryPath = '' then Exit;
    Result := Existing(IncludeTrailingPathDelimiter(DirectoryPath) +
      'ld-linux-x86-64.so.2');
  end;

  function LoaderInProfile(const ProfileRoot: RawByteString): RawByteString;
  begin
    Result := '';
    if ProfileRoot = '' then Exit;
    Result := Existing(IncludeTrailingPathDelimiter(ProfileRoot) +
      'lib/ld-linux-x86-64.so.2');
    if Result <> '' then Exit;
    Result := Existing(IncludeTrailingPathDelimiter(ProfileRoot) +
      'lib64/ld-linux-x86-64.so.2');
  end;

  function LoaderFromColonPath(const SearchPath: RawByteString): RawByteString;
  var
    StartPos, EndPos: Integer;
    Entry: RawByteString;
  begin
    Result := '';
    StartPos := 1;
    while StartPos <= Length(SearchPath) do
    begin
      EndPos := StartPos;
      while (EndPos <= Length(SearchPath)) and (SearchPath[EndPos] <> ':') do
        Inc(EndPos);
      Entry := Copy(SearchPath, StartPos, EndPos - StartPos);
      if Entry <> '' then
      begin
        Result := Existing(IncludeTrailingPathDelimiter(Entry) +
          'ld-linux-x86-64.so.2');
        if Result <> '' then Exit;
      end;
      StartPos := EndPos + 1;
    end;
  end;

  function LoaderFromStore(const StoreRoot: RawByteString): RawByteString;
  var
    Search: TSearchRec;
    Pattern, DirectoryPath: RawByteString;
    Status: Integer;
  begin
    Result := '';
    if not DirectoryExists(StoreRoot) then Exit;
    Pattern := IncludeTrailingPathDelimiter(StoreRoot) + '*-glibc-*';
    Status := FindFirst(Pattern, faDirectory, Search);
    if Status <> 0 then Exit;
    try
      while Status = 0 do
      begin
        if (Search.Name <> '.') and (Search.Name <> '..') and
           ((Search.Attr and faDirectory) <> 0) then
        begin
          DirectoryPath := IncludeTrailingPathDelimiter(StoreRoot) + Search.Name;
          Result := LoaderInProfile(DirectoryPath);
          if Result <> '' then Exit;
        end;
        Status := FindNext(Search);
      end;
    finally
      FindClose(Search);
    end;
  end;

begin
  Result := '';
  { Keep the command-line option authoritative, but provide an environment
    escape hatch for build systems which cannot conveniently add argv flags. }
  OverridePath := GetEnvironmentVariable('FSIM_DYNAMIC_LINKER');
  Result := Existing(OverridePath);
  if Result <> '' then Exit;

  { On dynamically-linked hosts, /proc/self/maps is the strongest source of
    truth.  First look for the loader itself.  A statically-linked fsim may not
    map it, but can still map libc through another library, so also derive the
    sibling loader from a mapped libc.so.6 path. }
  if FileExists('/proc/self/maps') then
  begin
    Maps := TStringList.Create;
    try
      try
        Maps.LoadFromFile('/proc/self/maps');
        for I := 0 to Maps.Count - 1 do
        begin
          Line := RawByteString(Maps[I]);
          if Pos('/ld-linux-x86-64.so.2', Line) > 0 then
          begin
            SlashPos := Pos('/', Line);
            if SlashPos > 0 then
            begin
              Candidate := Trim(Copy(Line, SlashPos, MaxInt));
              if Pos(' (deleted)', Candidate) > 0 then
                Candidate := Copy(Candidate, 1, Pos(' (deleted)', Candidate) - 1);
              Result := Existing(Candidate);
              if Result <> '' then Exit;
            end;
          end;
        end;
        for I := 0 to Maps.Count - 1 do
        begin
          Line := RawByteString(Maps[I]);
          LibcPos := Pos('/libc.so.6', Line);
          if LibcPos <= 0 then Continue;
          SlashPos := Pos('/', Line);
          if SlashPos <= 0 then Continue;
          Candidate := Trim(Copy(Line, SlashPos, MaxInt));
          if Pos(' (deleted)', Candidate) > 0 then
            Candidate := Copy(Candidate, 1, Pos(' (deleted)', Candidate) - 1);
          Result := LoaderBesideLibrary(Candidate);
          if Result <> '' then Exit;
        end;
      except
        { /proc may be unavailable in a sandbox; continue with profile/store
          discovery rather than silently hard-coding an FHS interpreter. }
      end;
    finally
      Maps.Free;
    end;
  end;

  { Guix/Nix profiles are cheap to probe and cover the common non-FHS cases
    where fsim itself is statically linked and therefore has no loader mapping. }
  ProfilePath := GetEnvironmentVariable('GUIX_ENVIRONMENT');
  Result := LoaderInProfile(ProfilePath);
  if Result <> '' then Exit;
  ProfilePath := GetEnvironmentVariable('GUIX_PROFILE');
  Result := LoaderInProfile(ProfilePath);
  if Result <> '' then Exit;
  ProfilePath := GetEnvironmentVariable('HOME');
  if ProfilePath <> '' then
  begin
    Result := LoaderInProfile(IncludeTrailingPathDelimiter(ProfilePath) + '.guix-profile');
    if Result <> '' then Exit;
  end;
  Result := LoaderInProfile('/run/current-system/profile');
  if Result <> '' then Exit;
  Result := LoaderInProfile('/run/current-system/sw');
  if Result <> '' then Exit;
  Result := LoaderInProfile('/nix/var/nix/profiles/default');
  if Result <> '' then Exit;

  Result := LoaderFromColonPath(GetEnvironmentVariable('LD_LIBRARY_PATH'));
  if Result <> '' then Exit;
  Result := LoaderFromColonPath(GetEnvironmentVariable('LIBRARY_PATH'));
  if Result <> '' then Exit;

  { Last non-FHS fallback: locate the glibc package directly.  This is only
    reached when fsim is static and no active profile exposes the loader. }
  Result := LoaderFromStore('/gnu/store');
  if Result <> '' then Exit;
  Result := LoaderFromStore('/nix/store');
  if Result <> '' then Exit;

  Result := Existing('/lib64/ld-linux-x86-64.so.2');
  if Result <> '' then Exit;
  Result := Existing('/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2');
  if Result <> '' then Exit;
  Result := Existing('/lib/ld-linux-x86-64.so.2');
end;

procedure NativeImageInit(var Image: TNativeImage);
begin
  Image := Default(TNativeImage);
  BufferInit(Image.Text, 4096);
  BufferInit(Image.ReadOnlyData, 4096);
  BufferInit(Image.WritableData, 1024);
  BufferInit(Image.Image, 16384);
end;

procedure NativeImageClear(var Image: TNativeImage);
begin
  BufferClear(Image.Text);
  BufferClear(Image.ReadOnlyData);
  BufferClear(Image.WritableData);
  BufferClear(Image.Image);
  SetLength(Image.Symbols, 0);
  Image.AssemblyText := '';
  Image.EntryTextOffset := 0;
  Image.BSSSize := 0;
end;

function RegisterMaskBit(Reg: TX64Register): UInt32; inline;
begin
  Result := UInt32(1) shl Ord(Reg);
end;

function CountSavedRegisters(Mask: UInt32): Int32;
var
  R: TX64Register;
begin
  Result := 0;
  for R := xrRBX to xrR15 do
    if (R in [xrRBX, xrR12, xrR13, xrR14, xrR15]) and
       ((Mask and RegisterMaskBit(R)) <> 0) then
      Inc(Result);
end;

procedure AddBackendSymbol(var Image: TNativeImage; const Name: RawByteString;
  SectionIndex: Word; Bind, SymbolType: Byte; Value, Size: QWord);
var
  N: Integer;
begin
  N := Length(Image.Symbols);
  SetLength(Image.Symbols, N + 1);
  Image.Symbols[N].Name := Name;
  Image.Symbols[N].SectionIndex := SectionIndex;
  Image.Symbols[N].Bind := Bind;
  Image.Symbols[N].SymbolType := SymbolType;
  Image.Symbols[N].Value := Value;
  Image.Symbols[N].Size := Size;
end;

function AppendDescriptor(var Data: TByteBuffer;
  const Value: RawByteString): Int32;
begin
  BufferAlign(Data, 8, 0);
  Result := Data.Count;
  BufferAppendQWord(Data, Length(Value));
  if Length(Value) > 0 then
    BufferAppend(Data, Value[1], Length(Value));
  BufferAppendByte(Data, 0);
end;

function AppendS67TextDescriptor(var Data: TByteBuffer;
  const Value: RawByteString): Int32;
const
  RODATA_POINTER_MARKER = QWord($8000000000000000);
var
  ByteOffset: Int32;
begin
  BufferAlign(Data, 8, 0);
  Result := Data.Count + 16;
  BufferAppendQWord(Data, RODATA_POINTER_MARKER or QWord(Result));
  BufferAppendQWord(Data, 0); { immutable literal frame }
  ByteOffset := Result + S67_TEXT_DESCRIPTOR_SIZE;
  BufferAppendQWord(Data, RODATA_POINTER_MARKER or QWord(ByteOffset));
  BufferAppendDWord(Data, 1);
  BufferAppendDWord(Data, Length(Value));
  if Length(Value) > 0 then
    BufferAppend(Data, Value[1], Length(Value));
  BufferAppendByte(Data, 0);
end;

function FindFunctionBySymbol(const ProgramIR: TIRProgram;
  SymbolId: Int32): Int32;
var
  I: Integer;
begin
  for I := 0 to High(ProgramIR.Functions) do
    if ProgramIR.Functions[I].SymbolId = SymbolId then
      Exit(I);
  Result := IR_INVALID_FUNCTION;
end;

function RoutineOwnerForScope(const Table: TSymbolTable; ScopeId: Int32): Int32;
var
  Owner, Guard: Int32;
begin
  Guard := 0;
  while (ScopeId >= 0) and (ScopeId <= High(Table.Scopes)) and
        (Guard <= Length(Table.Scopes)) do
  begin
    Owner := Table.Scopes[ScopeId].OwnerSymbol;
    if (Owner >= 0) and (Owner <= High(Table.Symbols)) and
       (Table.Symbols[Owner].Kind in [skProgram, skProcedure, skFunction]) then
      Exit(Owner);
    ScopeId := Table.Scopes[ScopeId].ParentScope;
    Inc(Guard);
  end;
  Result := FSIM_INVALID_INDEX;
end;

function ScopeOwnedByRoutine(const Table: TSymbolTable; ScopeId,
  RoutineSymbol: Int32): Boolean;
begin
  Result := RoutineOwnerForScope(Table, ScopeId) = RoutineSymbol;
end;

function SymbolIsProgramGlobal(const Table: TSymbolTable; SymbolId: Int32): Boolean;
var
  Owner: Int32;
begin
  Result := False;
  if (SymbolId < 0) or (SymbolId > High(Table.Symbols)) then Exit;
  if Table.Symbols[SymbolId].Kind <> skVariable then Exit;
  Owner := Table.Symbols[SymbolId].OwnerSymbol;
  Result := (Owner >= 0) and (Owner <= High(Table.Symbols)) and
    (Table.Symbols[Owner].Kind = skProgram);
end;

function RuntimeTypeStorageSize(const Table: TSymbolTable;
  TypeId: Int32): UInt32;
var
  Info: TTypeInfo;
  Count, Total: QWord;
begin
  if (TypeId < 0) or (TypeId > High(Table.Types)) then
    Exit(8);
  Info := Table.Types[TypeId];
  case Info.Kind of
    tyVoid: Result := 0;
    tyBoolean, tyCharacter:
      Result := 1;
    tyInteger:
      if TypeId = FSIM_TYPE_SHORT_INTEGER then Result := 4 else Result := 8;
    tyCInteger, tyCReal, tyCPointer, tyCFunction, tyRecord:
      Result := Info.Size;
    tyArray:
      begin
        if tfRuntimeBound in Info.Flags then
          Exit(SizeOf(Pointer));
        if Info.UpperBound < Info.LowerBound then
          Exit(0);
        Count := QWord(Info.UpperBound - Info.LowerBound) + 1;
        Total := Count * RuntimeTypeStorageSize(Table, Info.ElementType);
        if Total > High(UInt32) then Result := High(UInt32)
        else Result := UInt32(Total);
      end;
  else
    Result := 8;
  end;
end;

function RuntimeTypeAlignment(const Table: TSymbolTable;
  TypeId: Int32): UInt32;
begin
  Result := RuntimeTypeStorageSize(Table, TypeId);
  if Result = 0 then Result := 1;
  if Result > 8 then Result := 8;
  if not IsPowerOfTwo(Result) then Result := 8;
end;

function TypeIsCRecord(const Table: TSymbolTable; TypeId: Int32): Boolean; inline;
begin
  Result := (TypeId >= 0) and (TypeId <= High(Table.Types)) and
    (Table.Types[TypeId].Kind = tyRecord) and
    (tfCLayout in Table.Types[TypeId].Flags);
end;

function TypeIsRecordValue(const Table: TSymbolTable; TypeId: Int32): Boolean; inline;
begin
  Result := (TypeId >= 0) and (TypeId <= High(Table.Types)) and
    (Table.Types[TypeId].Kind = tyRecord) and
    (tfComplete in Table.Types[TypeId].Flags);
end;

function TypeIsStaticArrayValue(const Table: TSymbolTable; TypeId: Int32): Boolean; inline;
begin
  Result := (TypeId >= 0) and (TypeId <= High(Table.Types)) and
    (Table.Types[TypeId].Kind = tyArray) and
    not (tfRuntimeBound in Table.Types[TypeId].Flags);
end;

procedure PrepareFunctionMaps(var G: TCodeGenerator);
var
  I, F, S, V, Slot, SpillBase, SavedCount, TypeId: Int32;
  Mask: UInt32;
  FrameBytes, StackAdjust, StorageBytes, StorageAlignment: UInt32;
begin
  SetLength(G.Layout.FunctionLabels, Length(G.ProgramIR^.Functions));
  SetLength(G.Layout.BlockLabels, Length(G.ProgramIR^.Blocks));
  SetLength(G.Layout.FunctionBySymbol, Length(G.Symbols^.Symbols));
  SetLength(G.Layout.ForeignExportLabels, Length(G.Symbols^.Symbols));
  SetLength(G.Layout.SymbolStackOffsets, Length(G.Symbols^.Symbols));
  SetLength(G.Layout.SymbolGlobalOffsets, Length(G.Symbols^.Symbols));
  SetLength(G.Layout.FunctionFrameSizes, Length(G.ProgramIR^.Functions));
  SetLength(G.Layout.FunctionStackAdjust, Length(G.ProgramIR^.Functions));
  SetLength(G.Layout.FunctionSavedMasks, Length(G.ProgramIR^.Functions));
  SetLength(G.Layout.FunctionReceiverOffsets, Length(G.ProgramIR^.Functions));
  SetLength(G.Layout.FunctionSRetOffsets, Length(G.ProgramIR^.Functions));
  SetLength(G.Layout.ValueAggregateOffsets, Length(G.ProgramIR^.Values));
  for I := 0 to High(G.Layout.ValueAggregateOffsets) do
    G.Layout.ValueAggregateOffsets[I] := 0;
  for I := 0 to High(G.Layout.FunctionBySymbol) do
  begin
    G.Layout.FunctionBySymbol[I] := IR_INVALID_FUNCTION;
    G.Layout.ForeignExportLabels[I] := FSIM_INVALID_INDEX;
    if sfForeignExport in G.Symbols^.Symbols[I].Flags then
      G.Layout.ForeignExportLabels[I] := X64NewLabel(G.Assembler);
  end;
  for I := 0 to High(G.Layout.SymbolStackOffsets) do
  begin
    G.Layout.SymbolStackOffsets[I] := 0;
    G.Layout.SymbolGlobalOffsets[I] := -1;
  end;
  for F := 0 to High(G.ProgramIR^.Functions) do
  begin
    G.Layout.FunctionLabels[F] := X64NewLabel(G.Assembler);
    if G.ProgramIR^.Functions[F].SymbolId >= 0 then
      G.Layout.FunctionBySymbol[G.ProgramIR^.Functions[F].SymbolId] := F;
  end;
  for I := 0 to High(G.ProgramIR^.Blocks) do
    G.Layout.BlockLabels[I] := X64NewLabel(G.Assembler);

  for F := 0 to High(G.ProgramIR^.Functions) do
  begin
    SpillBase := G.Allocation^.Functions[F].SpillSize;
    Slot := SpillBase;
    G.Layout.FunctionReceiverOffsets[F] := 0;
    G.Layout.FunctionSRetOffsets[F] := 0;
    if TypeIsRecordValue(G.Symbols^, G.ProgramIR^.Functions[F].ReturnType) then
    begin
      Slot := Int32(AlignUp(QWord(Slot), 8));
      Inc(Slot, 8);
      G.Layout.FunctionSRetOffsets[F] := Slot;
    end;
    if iffMethod in G.ProgramIR^.Functions[F].Flags then
    begin
      Inc(Slot, 8);
      G.Layout.FunctionReceiverOffsets[F] := Slot;
    end;
    for S := 0 to High(G.Symbols^.Symbols) do
      if (G.Symbols^.Symbols[S].Kind in [skVariable, skParameter]) and
         not SymbolIsProgramGlobal(G.Symbols^, S) and
         ScopeOwnedByRoutine(G.Symbols^, G.Symbols^.Symbols[S].ScopeId,
           G.ProgramIR^.Functions[F].SymbolId) then
      begin
        TypeId := G.Symbols^.Symbols[S].TypeId;
        StorageBytes := RuntimeTypeStorageSize(G.Symbols^, TypeId);
        if StorageBytes = 0 then StorageBytes := 1;
        StorageAlignment := RuntimeTypeAlignment(G.Symbols^, TypeId);
        Slot := Int32(AlignUp(QWord(Slot), StorageAlignment));
        Inc(Slot, Int32(StorageBytes));
        G.Layout.SymbolStackOffsets[S] := Slot;
      end;

    { Internal record values are represented by an address, but the bytes live
      in the caller frame.  This gives aggregate-returning helper functions a
      real value lifetime without heap traffic. }
    for V := G.ProgramIR^.Functions[F].FirstValue to
             G.ProgramIR^.Functions[F].FirstValue +
             G.ProgramIR^.Functions[F].ValueCount - 1 do
      if (V >= 0) and (V <= High(G.ProgramIR^.Values)) and
         TypeIsRecordValue(G.Symbols^, G.ProgramIR^.Values[V].TypeId) then
      begin
        TypeId := G.ProgramIR^.Values[V].TypeId;
        StorageBytes := RuntimeTypeStorageSize(G.Symbols^, TypeId);
        if StorageBytes = 0 then StorageBytes := 1;
        StorageAlignment := RuntimeTypeAlignment(G.Symbols^, TypeId);
        Slot := Int32(AlignUp(QWord(Slot), StorageAlignment));
        Inc(Slot, Int32(StorageBytes));
        G.Layout.ValueAggregateOffsets[V] := Slot;
      end;
    FrameBytes := UInt32(Slot);
    Mask := G.Allocation^.Functions[F].UsedRegisterMask;
    Mask := Mask and (RegisterMaskBit(xrRBX) or RegisterMaskBit(xrR12) or
      RegisterMaskBit(xrR13) or RegisterMaskBit(xrR14) or
      RegisterMaskBit(xrR15));
    SavedCount := CountSavedRegisters(Mask);
    StackAdjust := UInt32(AlignUp(FrameBytes, 16));
    if (SavedCount and 1) <> 0 then
      Inc(StackAdjust, 8);
    G.Layout.FunctionFrameSizes[F] := FrameBytes;
    G.Layout.FunctionStackAdjust[F] := StackAdjust;
    G.Layout.FunctionSavedMasks[F] := Mask;
  end;
end;

procedure PrepareReadOnlyData(var G: TCodeGenerator);
var
  I, C, Slot, FunctionId, ClassIndex, ParentIndex, TypeId: Int32;
  Value, Name: RawByteString;
  ParentPatch, VMTOffset: Int32;
  StorageBytes, StorageAlignment: UInt32;

  function EffectiveVirtualMethod(ClassSymbol, WantedSlot: Int32): Int32;
  var
    M, CI, Guard: Int32;
  begin
    Guard := 0;
    while (ClassSymbol >= 0) and (Guard <= Length(G.Symbols^.Classes)) do
    begin
      for M := High(G.Symbols^.Methods) downto 0 do
        if (G.Symbols^.Methods[M].OwnerClass = ClassSymbol) and
           (G.Symbols^.Methods[M].VMTSlot = WantedSlot) and
           not G.Symbols^.Methods[M].IsAbstract then
          Exit(G.Symbols^.Methods[M].SymbolId);
      CI := SymClassIndex(G.Symbols^, ClassSymbol);
      if CI < 0 then Break;
      ClassSymbol := G.Symbols^.Classes[CI].PrefixClass;
      Inc(Guard);
    end;
    Result := FSIM_INVALID_INDEX;
  end;
begin
  RuntimeAppendConstants(G.NativeImage^.ReadOnlyData, G.RuntimeData);
  RuntimeAppendWritableData(G.NativeImage^.WritableData, G.RuntimeData);
  S67AppendWritableData(G.NativeImage^.WritableData, G.RuntimeData.S67);
  OSAppendWritableData(G.NativeImage^.WritableData, G.RuntimeData.OS);

  { Keep the GC root range separate from runtime bookkeeping. }
  BufferAlign(G.NativeImage^.WritableData, 8, 0);
  G.ProgramGlobalRootOffset := G.NativeImage^.WritableData.Count;

  { Program-scope variables have process lifetime and are visible to nested
    routines.  They must not be addressed relative to whichever routine's RBP
    happens to be current; that made non-local state depend on stack-frame
    shape.  Give them stable writable-image storage instead. }
  for I := 0 to High(G.Symbols^.Symbols) do
    if SymbolIsProgramGlobal(G.Symbols^, I) then
    begin
      TypeId := G.Symbols^.Symbols[I].TypeId;
      StorageBytes := RuntimeTypeStorageSize(G.Symbols^, TypeId);
      if StorageBytes = 0 then StorageBytes := 1;
      StorageAlignment := RuntimeTypeAlignment(G.Symbols^, TypeId);
      if StorageAlignment = 0 then StorageAlignment := 1;
      BufferAlign(G.NativeImage^.WritableData, StorageAlignment, 0);
      G.Layout.SymbolGlobalOffsets[I] := G.NativeImage^.WritableData.Count;
      BufferAppendZeros(G.NativeImage^.WritableData, StorageBytes);
    end;
  G.ProgramGlobalRootBytes := G.NativeImage^.WritableData.Count -
    G.ProgramGlobalRootOffset;

  SetLength(G.Layout.StringOffsets,
    Length(G.ProgramIR^.Strings.Entries));
  for I := 0 to High(G.Layout.StringOffsets) do
  begin
    Value := StringPoolGet(G.ProgramIR^.Strings, I);
    if G.Options^.Dialect = fdSimula67 then
      G.Layout.StringOffsets[I] := AppendS67TextDescriptor(
        G.NativeImage^.ReadOnlyData, Value)
    else
      G.Layout.StringOffsets[I] := AppendDescriptor(
        G.NativeImage^.ReadOnlyData, Value);
  end;

  SetLength(G.Layout.RTTIOffsets, Length(G.Symbols^.Classes));
  SetLength(G.Layout.VMTOffsets, Length(G.Symbols^.Classes));
  for C := 0 to High(G.Symbols^.Classes) do
  begin
    BufferAlign(G.NativeImage^.ReadOnlyData, 8, 0);
    G.Layout.RTTIOffsets[C] := G.NativeImage^.ReadOnlyData.Count;
    ParentPatch := G.NativeImage^.ReadOnlyData.Count;
    BufferAppendQWord(G.NativeImage^.ReadOnlyData, 0); { parent RTTI pointer }
    BufferAppendQWord(G.NativeImage^.ReadOnlyData,
      G.Symbols^.Classes[C].InstanceSize);
    BufferAppendQWord(G.NativeImage^.ReadOnlyData,
      G.Symbols^.Classes[C].VMTSlotCount);
    Name := SymName(G.Symbols^, G.Symbols^.Classes[C].SymbolId);
    BufferAppendDWord(G.NativeImage^.ReadOnlyData, Length(Name));
    BufferAppendDWord(G.NativeImage^.ReadOnlyData, 0);
    if Length(Name) > 0 then
      BufferAppend(G.NativeImage^.ReadOnlyData, Name[1], Length(Name));
    BufferAppendByte(G.NativeImage^.ReadOnlyData, 0);
    { Parent is patched after the final rodata virtual address is known. }
    ParentIndex := SymClassIndex(G.Symbols^,
      G.Symbols^.Classes[C].PrefixClass);
    if ParentIndex >= 0 then
      BufferPatchQWord(G.NativeImage^.ReadOnlyData, ParentPatch,
        QWord(G.Layout.RTTIOffsets[ParentIndex]) or QWord($8000000000000000));
  end;

  for C := 0 to High(G.Symbols^.Classes) do
  begin
    BufferAlign(G.NativeImage^.ReadOnlyData, 8, 0);
    VMTOffset := G.NativeImage^.ReadOnlyData.Count;
    G.Layout.VMTOffsets[C] := VMTOffset;
    if G.Symbols^.Classes[C].VMTSlotCount > 0 then
      for Slot := 0 to Int32(G.Symbols^.Classes[C].VMTSlotCount) - 1 do
        BufferAppendQWord(G.NativeImage^.ReadOnlyData, 0);
    for Slot := 0 to Int32(G.Symbols^.Classes[C].VMTSlotCount) - 1 do
    begin
      FunctionId := EffectiveVirtualMethod(G.Symbols^.Classes[C].SymbolId,
        Slot);
      if FunctionId >= 0 then
      begin
        FunctionId := FindFunctionBySymbol(G.ProgramIR^, FunctionId);
        if FunctionId >= 0 then
          BufferPatchQWord(G.NativeImage^.ReadOnlyData,
            VMTOffset + Slot * 8,
            QWord(FunctionId) or QWord($4000000000000000));
      end;
    end;
  end;
end;

function ValueDefinition(const G: TCodeGenerator; ValueId: Int32): Int32;
begin
  if (ValueId < 0) or (ValueId > High(G.ProgramIR^.Values)) then
    Exit(FSIM_INVALID_INDEX);
  Result := G.ProgramIR^.Values[ValueId].DefInstruction;
end;

procedure LoadImmediateValue(var G: TCodeGenerator; ValueId: Int32;
  Target: TX64Register);
var
  Def: Int32;
  Instr: TIRInstruction;
  Bits: QWord;
begin
  Def := ValueDefinition(G, ValueId);
  if (Def < 0) or (Def > High(G.ProgramIR^.Instructions)) then
  begin
    X64XorRegReg(G.Assembler, Target, Target);
    Exit;
  end;
  Instr := G.ProgramIR^.Instructions[Def];
  case Instr.Op of
    irConstInt: X64MovRegImm64(G.Assembler, Target, QWord(Instr.Imm));
    irConstNull: X64XorRegReg(G.Assembler, Target, Target);
    irConstReal:
      begin
        Move(Instr.RealImm, Bits, SizeOf(Bits));
        X64MovRegImm64(G.Assembler, Target, Bits);
      end;
    irConstString:
      if (Instr.StringId >= 0) and
         (Instr.StringId <= High(G.Layout.StringOffsets)) then
        X64LeaRegRipData(G.Assembler, Target,
          G.Layout.StringOffsets[Instr.StringId], 0)
      else
        X64XorRegReg(G.Assembler, Target, Target);
  else
    X64XorRegReg(G.Assembler, Target, Target);
  end;
end;

procedure LoadValue(var G: TCodeGenerator; ValueId: Int32;
  Target: TX64Register);
var
  Location: TValueLocation;
begin
  if ValueId < 0 then
  begin
    X64XorRegReg(G.Assembler, Target, Target);
    Exit;
  end;
  Location := G.Allocation^.Locations[ValueId];
  case Location.Kind of
    vlRegister: X64MovRegReg(G.Assembler, Target, Location.RegisterId);
    vlStack: X64MovRegMemBaseDisp(G.Assembler, Target, xrRBP,
      -Location.StackOffset);
    vlImmediate: LoadImmediateValue(G, ValueId, Target);
  else
    LoadImmediateValue(G, ValueId, Target);
  end;
end;

procedure StoreValue(var G: TCodeGenerator; ValueId: Int32;
  Source: TX64Register);
var
  Location: TValueLocation;
begin
  if ValueId < 0 then Exit;
  Location := G.Allocation^.Locations[ValueId];
  case Location.Kind of
    vlRegister: X64MovRegReg(G.Assembler, Location.RegisterId, Source);
    vlStack: X64MovMemBaseDispReg(G.Assembler, xrRBP,
      -Location.StackOffset, Source);
    vlImmediate: ;
  else
    ;
  end;
end;

function SymbolFrameOffset(const G: TCodeGenerator; SymbolId: Int32): Int32;
begin
  if (SymbolId < 0) or (SymbolId > High(G.Layout.SymbolStackOffsets)) then
    Exit(0);
  Result := G.Layout.SymbolStackOffsets[SymbolId];
end;

function SymbolGlobalOffset(const G: TCodeGenerator; SymbolId: Int32): Int32;
begin
  if (SymbolId < 0) or (SymbolId > High(G.Layout.SymbolGlobalOffsets)) then
    Exit(-1);
  Result := G.Layout.SymbolGlobalOffsets[SymbolId];
end;

function FieldOffset(const G: TCodeGenerator; SymbolId: Int32): Int32;
begin
  if (SymbolId < 0) or (SymbolId > High(G.Symbols^.Symbols)) then
    Exit(0);
  Result := G.Symbols^.Symbols[SymbolId].StorageOffset;
end;

function ClassIndexForSymbol(const G: TCodeGenerator;
  ClassSymbol: Int32): Int32;
begin
  Result := SymClassIndex(G.Symbols^, ClassSymbol);
end;

procedure EmitCheckedOverflow(var G: TCodeGenerator);
begin
  if G.Options^.OverflowChecks then
    X64JumpCondition(G.Assembler, xcOverflow, G.RuntimeLabels.PanicOverflow);
end;

procedure EmitIntegerBinary(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  ZeroOkay, LoopLabel, DoneLabel, NegativePower, ModDone: Int32;
begin
  LoadValue(G, Instr.A, xrRAX);
  if (Instr.Op in [irShiftLeft, irShiftRight]) and
     (Instr.B < 0) and (Instr.Aux > 0) then
    X64MovRegImm64(G.Assembler, xrRCX, Instr.Aux)
  else
    LoadValue(G, Instr.B, xrRCX);
  case Instr.Op of
    irAddInt:
      begin
        X64AddRegReg(G.Assembler, xrRAX, xrRCX);
        EmitCheckedOverflow(G);
      end;
    irSubInt:
      begin
        X64SubRegReg(G.Assembler, xrRAX, xrRCX);
        EmitCheckedOverflow(G);
      end;
    irMulInt:
      begin
        X64IMulRegReg(G.Assembler, xrRAX, xrRCX);
        EmitCheckedOverflow(G);
      end;
    irDivInt, irModInt, irRemInt:
      begin
        ZeroOkay := X64NewLabel(G.Assembler);
        X64TestRegReg(G.Assembler, xrRCX, xrRCX);
        X64JumpCondition(G.Assembler, xcNotEqual, ZeroOkay);
        X64Jump(G.Assembler, G.RuntimeLabels.PanicOverflow);
        X64BindLabel(G.Assembler, ZeroOkay);
        X64CQO(G.Assembler);
        X64IDivReg(G.Assembler, xrRCX);
        if Instr.Op = irRemInt then
          X64MovRegReg(G.Assembler, xrRAX, xrRDX)
        else if Instr.Op = irModInt then
        begin
          { IDIV gives REM.  Simula MOD is the congruent value with the
            divisor's sign, so adjust only when a non-zero remainder and the
            divisor disagree.  these two operators really are different. }
          X64MovRegReg(G.Assembler, xrRAX, xrRDX);
          ModDone := X64NewLabel(G.Assembler);
          X64TestRegReg(G.Assembler, xrRAX, xrRAX);
          X64JumpCondition(G.Assembler, xcEqual, ModDone);
          X64MovRegReg(G.Assembler, xrR8, xrRAX);
          X64XorRegReg(G.Assembler, xrR8, xrRCX);
          X64TestRegReg(G.Assembler, xrR8, xrR8);
          X64JumpCondition(G.Assembler, xcNotSign, ModDone);
          X64AddRegReg(G.Assembler, xrRAX, xrRCX);
          X64BindLabel(G.Assembler, ModDone);
        end;
      end;
    irBitAnd: X64AndRegReg(G.Assembler, xrRAX, xrRCX);
    irBitOr: X64OrRegReg(G.Assembler, xrRAX, xrRCX);
    irBitXor: X64XorRegReg(G.Assembler, xrRAX, xrRCX);
    irShiftLeft:
      begin
        X64ShlRegCL(G.Assembler, xrRAX);
      end;
    irShiftRight:
      begin
        X64SarRegCL(G.Assembler, xrRAX);
      end;
    irPowerInt:
      begin
        LoopLabel := X64NewLabel(G.Assembler);
        DoneLabel := X64NewLabel(G.Assembler);
        NegativePower := X64NewLabel(G.Assembler);
        X64TestRegReg(G.Assembler, xrRCX, xrRCX);
        X64JumpCondition(G.Assembler, xcLess, NegativePower);
        X64MovRegReg(G.Assembler, xrRDX, xrRAX);
        X64MovRegImm64(G.Assembler, xrRAX, 1);
        X64TestRegReg(G.Assembler, xrRCX, xrRCX);
        X64JumpCondition(G.Assembler, xcEqual, DoneLabel);
        X64BindLabel(G.Assembler, LoopLabel);
        X64TestRegReg(G.Assembler, xrRCX, xrRCX);
        X64JumpCondition(G.Assembler, xcEqual, DoneLabel);
        X64MovRegReg(G.Assembler, xrR8, xrRCX);
        X64AndRegImm32(G.Assembler, xrR8, 1);
        ZeroOkay := X64NewLabel(G.Assembler);
        X64JumpCondition(G.Assembler, xcEqual, ZeroOkay);
        X64IMulRegReg(G.Assembler, xrRAX, xrRDX);
        EmitCheckedOverflow(G);
        X64BindLabel(G.Assembler, ZeroOkay);
        X64IMulRegReg(G.Assembler, xrRDX, xrRDX);
        EmitCheckedOverflow(G);
        X64ShrRegImm8(G.Assembler, xrRCX, 1);
        X64Jump(G.Assembler, LoopLabel);
        X64BindLabel(G.Assembler, NegativePower);
        X64XorRegReg(G.Assembler, xrRAX, xrRAX);
        X64BindLabel(G.Assembler, DoneLabel);
      end;
  end;
  StoreValue(G, Instr.Dst, xrRAX);
end;

procedure EmitComparison(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  Cond: TX64Condition;
begin
  LoadValue(G, Instr.A, xrRAX);
  LoadValue(G, Instr.B, xrRCX);
  X64CmpRegReg(G.Assembler, xrRAX, xrRCX);
  case Instr.Op of
    irCompareEqual: Cond := xcEqual;
    irCompareNotEqual: Cond := xcNotEqual;
    irCompareLess: Cond := xcLess;
    irCompareLessEqual: Cond := xcLessEqual;
    irCompareGreater: Cond := xcGreater;
    irCompareGreaterEqual: Cond := xcGreaterEqual;
  else
    Cond := xcEqual;
  end;
  X64SetCondition8(G.Assembler, Cond, xrRAX);
  X64MovZXReg8(G.Assembler, xrRAX, xrRAX);
  StoreValue(G, Instr.Dst, xrRAX);
end;

procedure EmitRealBinary(var G: TCodeGenerator;
  const Instr: TIRInstruction);
begin
  LoadValue(G, Instr.A, xrRAX);
  LoadValue(G, Instr.B, xrRCX);
  X64MovQXMMReg(G.Assembler, xrXMM0, xrRAX);
  X64MovQXMMReg(G.Assembler, xrXMM1, xrRCX);
  case Instr.Op of
    irAddReal: X64AddSD(G.Assembler, xrXMM0, xrXMM1);
    irSubReal: X64SubSD(G.Assembler, xrXMM0, xrXMM1);
    irMulReal: X64MulSD(G.Assembler, xrXMM0, xrXMM1);
    irDivReal: X64DivSD(G.Assembler, xrXMM0, xrXMM1);
  end;
  X64MovQRegXMM(G.Assembler, xrRAX, xrXMM0);
  StoreValue(G, Instr.Dst, xrRAX);
end;

procedure EmitRealPower(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  PositiveExponent, LoopLabel, DoneLabel, PositiveResult, FinishLabel: Int32;
  OneBits: QWord;
begin
  PositiveExponent := X64NewLabel(G.Assembler);
  LoopLabel := X64NewLabel(G.Assembler);
  DoneLabel := X64NewLabel(G.Assembler);
  PositiveResult := X64NewLabel(G.Assembler);
  FinishLabel := X64NewLabel(G.Assembler);
  OneBits := QWord($3FF0000000000000);
  LoadValue(G, Instr.A, xrRAX);
  X64MovQXMMReg(G.Assembler, xrXMM0, xrRAX);
  LoadValue(G, Instr.B, xrRCX);
  X64MovRegImm64(G.Assembler, xrRDX, OneBits);
  X64MovQXMMReg(G.Assembler, xrXMM1, xrRDX);
  X64XorRegReg(G.Assembler, xrR8, xrR8);
  X64TestRegReg(G.Assembler, xrRCX, xrRCX);
  X64JumpCondition(G.Assembler, xcGreaterEqual, PositiveExponent);
  X64NegReg(G.Assembler, xrRCX);
  X64MovRegImm64(G.Assembler, xrR8, 1);
  X64BindLabel(G.Assembler, PositiveExponent);
  X64BindLabel(G.Assembler, LoopLabel);
  X64TestRegReg(G.Assembler, xrRCX, xrRCX);
  X64JumpCondition(G.Assembler, xcEqual, DoneLabel);
  X64MulSD(G.Assembler, xrXMM1, xrXMM0);
  X64SubRegImm32(G.Assembler, xrRCX, 1);
  X64Jump(G.Assembler, LoopLabel);
  X64BindLabel(G.Assembler, DoneLabel);
  X64TestRegReg(G.Assembler, xrR8, xrR8);
  X64JumpCondition(G.Assembler, xcEqual, PositiveResult);
  X64MovRegImm64(G.Assembler, xrRDX, OneBits);
  X64MovQXMMReg(G.Assembler, xrXMM0, xrRDX);
  X64DivSD(G.Assembler, xrXMM0, xrXMM1);
  X64MovQRegXMM(G.Assembler, xrRAX, xrXMM0);
  X64Jump(G.Assembler, FinishLabel);
  X64BindLabel(G.Assembler, PositiveResult);
  X64MovQRegXMM(G.Assembler, xrRAX, xrXMM1);
  X64BindLabel(G.Assembler, FinishLabel);
  StoreValue(G, Instr.Dst, xrRAX);
end;

procedure EmitRealComparison(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  Cond: TX64Condition;
begin
  LoadValue(G, Instr.A, xrRAX);
  LoadValue(G, Instr.B, xrRCX);
  X64MovQXMMReg(G.Assembler, xrXMM0, xrRAX);
  X64MovQXMMReg(G.Assembler, xrXMM1, xrRCX);
  X64UComiSD(G.Assembler, xrXMM0, xrXMM1);
  case Instr.Op of
    irCompareEqual: Cond := xcEqual;
    irCompareNotEqual: Cond := xcNotEqual;
    irCompareLess: Cond := xcBelow;
    irCompareLessEqual: Cond := xcBelowEqual;
    irCompareGreater: Cond := xcAbove;
    irCompareGreaterEqual: Cond := xcAboveEqual;
  else
    Cond := xcEqual;
  end;
  X64SetCondition8(G.Assembler, Cond, xrRAX);
  X64MovZXReg8(G.Assembler, xrRAX, xrRAX);
  StoreValue(G, Instr.Dst, xrRAX);
end;

function IsCRecordType(const G: TCodeGenerator; TypeId: Int32): Boolean; inline;
begin
  Result := TypeIsCRecord(G.Symbols^, TypeId);
end;

function IsRecordValueType(const G: TCodeGenerator; TypeId: Int32): Boolean; inline;
begin
  Result := TypeIsRecordValue(G.Symbols^, TypeId);
end;

procedure EmitCopyBytes(var G: TCodeGenerator; Destination, Source: TX64Register;
  Size: UInt32);
var
  Offset: UInt32;
begin
  if Size = 0 then Exit;
  X64MovRegReg(G.Assembler, xrR10, Destination);
  X64MovRegReg(G.Assembler, xrR11, Source);
  Offset := 0;
  while Size - Offset >= 8 do
  begin
    X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrR11, Int32(Offset));
    X64MovMemBaseDispReg(G.Assembler, xrR10, Int32(Offset), xrRAX);
    Inc(Offset, 8);
  end;
  if Size - Offset >= 4 then
  begin
    X64MovZXRegMemBaseDisp32(G.Assembler, xrRAX, xrR11, Int32(Offset));
    X64MovMemBaseDispReg32(G.Assembler, xrR10, Int32(Offset), xrRAX);
    Inc(Offset, 4);
  end;
  if Size - Offset >= 2 then
  begin
    X64MovZXRegMemBaseDisp16(G.Assembler, xrRAX, xrR11, Int32(Offset));
    X64MovMemBaseDispReg16(G.Assembler, xrR10, Int32(Offset), xrRAX);
    Inc(Offset, 2);
  end;
  if Size - Offset >= 1 then
  begin
    X64MovRegMemBaseDisp8(G.Assembler, xrRAX, xrR11, Int32(Offset));
    X64MovMemBaseDispReg8(G.Assembler, xrR10, Int32(Offset), xrRAX);
  end;
end;

procedure EmitLoadAtAddress(var G: TCodeGenerator; Address: TX64Register;
  TypeId: Int32; Target: TX64Register);
var
  Size: UInt32;
  Info: TTypeInfo;
begin
  Size := RuntimeTypeStorageSize(G.Symbols^, TypeId);
  if (TypeId >= 0) and (TypeId <= High(G.Symbols^.Types)) then
    Info := G.Symbols^.Types[TypeId]
  else
    Info := Default(TTypeInfo);
  if IsRecordValueType(G, TypeId) or
     TypeIsStaticArrayValue(G.Symbols^, TypeId) then
  begin
    { Aggregate values are represented by the address of their storage.  This
      matters for nested static arrays: indexing board(i) yields a row array,
      so the next index must receive the row address rather than the first
      qword stored in that row. }
    X64MovRegReg(G.Assembler, Target, Address);
    Exit;
  end;
  if (Info.Kind = tyCReal) and (Size = 4) then
  begin
    X64MovZXRegMemBaseDisp32(G.Assembler, Target, Address, 0);
    X64MovQXMMReg(G.Assembler, xrXMM0, Target);
    X64CvtSS2SD(G.Assembler, xrXMM0, xrXMM0);
    X64MovQRegXMM(G.Assembler, Target, xrXMM0);
    Exit;
  end;
  case Size of
    1:
      if tfSigned in Info.Flags then
        X64MovSXRegMemBaseDisp8(G.Assembler, Target, Address, 0)
      else
        X64MovRegMemBaseDisp8(G.Assembler, Target, Address, 0);
    2:
      if tfSigned in Info.Flags then
        X64MovSXRegMemBaseDisp16(G.Assembler, Target, Address, 0)
      else
        X64MovZXRegMemBaseDisp16(G.Assembler, Target, Address, 0);
    4:
      if tfSigned in Info.Flags then
        X64MovSXRegMemBaseDisp32(G.Assembler, Target, Address, 0)
      else
        X64MovZXRegMemBaseDisp32(G.Assembler, Target, Address, 0);
  else
    X64MovRegMemBaseDisp(G.Assembler, Target, Address, 0);
  end;
end;

procedure EmitStoreAtAddress(var G: TCodeGenerator; Address: TX64Register;
  TypeId: Int32; Source: TX64Register);
var
  Size: UInt32;
  Info: TTypeInfo;
begin
  Size := RuntimeTypeStorageSize(G.Symbols^, TypeId);
  if (TypeId >= 0) and (TypeId <= High(G.Symbols^.Types)) then
    Info := G.Symbols^.Types[TypeId]
  else
    Info := Default(TTypeInfo);
  if IsRecordValueType(G, TypeId) or
     TypeIsStaticArrayValue(G.Symbols^, TypeId) then
  begin
    EmitCopyBytes(G, Address, Source, Size);
    Exit;
  end;
  if (Info.Kind = tyCReal) and (Size = 4) then
  begin
    { Do not use RAX as the float-bit scratch: field stores commonly pass the
      destination address in RAX.  Clobbering it with IEEE-754 bits turned a
      perfectly valid `record.x := c_float(...)` into a store through an
      address such as 0x3f800000.  R11 is scratch-only in this lowering path. }
    X64MovQXMMReg(G.Assembler, xrXMM0, Source);
    X64CvtSD2SS(G.Assembler, xrXMM0, xrXMM0);
    X64MovQRegXMM(G.Assembler, xrR11, xrXMM0);
    X64MovMemBaseDispReg32(G.Assembler, Address, 0, xrR11);
    Exit;
  end;
  case Size of
    1: X64MovMemBaseDispReg8(G.Assembler, Address, 0, Source);
    2: X64MovMemBaseDispReg16(G.Assembler, Address, 0, Source);
    4: X64MovMemBaseDispReg32(G.Assembler, Address, 0, Source);
  else
    X64MovMemBaseDispReg(G.Assembler, Address, 0, Source);
  end;
end;

procedure EmitArrayAddress(var G: TCodeGenerator; BaseValue, IndexValue: Int32;
  out ElementType: Int32); forward;
procedure AppendForeignGOTLoad(var G: TCodeGenerator;
  ForeignIndex: Int32); forward;

procedure EmitCAddressOf(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  Offset, ElementType: Int32;
begin
  case Instr.Aux of
    0:
      begin
        Offset := SymbolGlobalOffset(G, Instr.SymbolId);
        if Offset >= 0 then
          X64LeaRegRipWritable(G.Assembler, xrRAX, Offset, 0)
        else
        begin
          Offset := SymbolFrameOffset(G, Instr.SymbolId);
          if Offset <= 0 then
          begin
            AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
              'c_addr target has no addressable native storage');
            X64XorRegReg(G.Assembler, xrRAX, xrRAX);
          end
          else
            X64LeaRegBaseDisp(G.Assembler, xrRAX, xrRBP, -Offset);
        end;
      end;
    1:
      begin
        LoadValue(G, Instr.A, xrRAX);
        if G.Options^.NullChecks then
        begin
          X64MovRegReg(G.Assembler, xrRDI, xrRAX);
          X64Call(G.Assembler, G.RuntimeLabels.NullCheck);
        end;
        X64AddRegImm32(G.Assembler, xrRAX, FieldOffset(G, Instr.SymbolId));
      end;
    2:
      EmitArrayAddress(G, Instr.A, Instr.B, ElementType);
    3:
      begin
        Offset := SymForeignBinding(G.Symbols^, Instr.SymbolId);
        if (Offset < 0) or (Offset > High(G.Symbols^.ForeignBindings)) or
           (G.Symbols^.ForeignBindings[Offset].Kind <> fbObject) then
        begin
          AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
            'c_addr foreign target has no object binding');
          X64XorRegReg(G.Assembler, xrRAX, xrRAX);
        end
        else
          AppendForeignGOTLoad(G, Offset);
      end;
    4:
      begin
        if (Instr.SymbolId < 0) or
           (Instr.SymbolId > High(G.Layout.ForeignExportLabels)) or
           (G.Layout.ForeignExportLabels[Instr.SymbolId] < 0) then
        begin
          AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
            'c_addr exported callback has no C ABI adapter');
          X64XorRegReg(G.Assembler, xrRAX, xrRAX);
        end
        else
          X64LeaRegRipLabel(G.Assembler, xrRAX,
            G.Layout.ForeignExportLabels[Instr.SymbolId]);
      end;
    5:
      begin
        Offset := SymForeignBinding(G.Symbols^, Instr.SymbolId);
        if (Offset < 0) or (Offset > High(G.Symbols^.ForeignBindings)) or
           (G.Symbols^.ForeignBindings[Offset].Kind <> fbFunction) then
        begin
          AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
            'c_addr imported routine has no function binding');
          X64XorRegReg(G.Assembler, xrRAX, xrRAX);
        end
        else
          AppendForeignGOTLoad(G, Offset);
      end;
  else
    begin
      AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
        'unknown c_addr lowering mode');
      X64XorRegReg(G.Assembler, xrRAX, xrRAX);
    end;
  end;
  StoreValue(G, Instr.Dst, xrRAX);
end;

procedure EmitCIndirectLoad(var G: TCodeGenerator;
  const Instr: TIRInstruction);
begin
  LoadValue(G, Instr.A, xrRAX);
  if G.Options^.NullChecks then
  begin
    X64MovRegReg(G.Assembler, xrRDI, xrRAX);
    X64Call(G.Assembler, G.RuntimeLabels.NullCheck);
  end;
  EmitLoadAtAddress(G, xrRAX, Instr.TypeId, xrRAX);
  StoreValue(G, Instr.Dst, xrRAX);
end;

procedure EmitCIndirectStore(var G: TCodeGenerator;
  const Instr: TIRInstruction);
begin
  LoadValue(G, Instr.A, xrRAX);
  if G.Options^.NullChecks then
  begin
    X64MovRegReg(G.Assembler, xrRDI, xrRAX);
    X64Call(G.Assembler, G.RuntimeLabels.NullCheck);
  end;
  X64MovRegReg(G.Assembler, xrRDX, xrRAX);
  LoadValue(G, Instr.B, xrRCX);
  EmitStoreAtAddress(G, xrRDX, Instr.TypeId, xrRCX);
end;

procedure EmitCPointerOffset(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  ElementType: Int32;
  ElementSize: UInt32;
begin
  LoadValue(G, Instr.A, xrRAX);
  LoadValue(G, Instr.B, xrRCX);
  ElementType := FSIM_TYPE_INVALID;
  if (Instr.TypeId >= 0) and (Instr.TypeId <= High(G.Symbols^.Types)) and
     (G.Symbols^.Types[Instr.TypeId].Kind = tyCPointer) then
    ElementType := G.Symbols^.Types[Instr.TypeId].ElementType;
  ElementSize := RuntimeTypeStorageSize(G.Symbols^, ElementType);
  if ElementSize = 0 then ElementSize := 1;
  if ElementSize > 1 then
    X64IMulRegRegImm32(G.Assembler, xrRCX, xrRCX, Int32(ElementSize));
  X64AddRegReg(G.Assembler, xrRAX, xrRCX);
  StoreValue(G, Instr.Dst, xrRAX);
end;

procedure EmitProcedureAddress(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  FunctionId: Int32;
begin
  FunctionId := IR_INVALID_FUNCTION;
  if (Instr.SymbolId >= 0) and
     (Instr.SymbolId <= High(G.Layout.FunctionBySymbol)) then
    FunctionId := G.Layout.FunctionBySymbol[Instr.SymbolId];
  if FunctionId < 0 then
  begin
    AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
      'procedure value has no native body');
    X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  end
  else if (Instr.SymbolId >= 0) and
          (Instr.SymbolId <= High(G.Symbols^.Symbols)) and
          (G.Symbols^.Symbols[Instr.SymbolId].OwnerSymbol >= 0) and
          (G.Symbols^.Symbols[Instr.SymbolId].OwnerSymbol <=
            High(G.Symbols^.Symbols)) and
          (G.Symbols^.Symbols[G.Symbols^.Symbols[Instr.SymbolId].OwnerSymbol].Kind in
            [skClass, skProcessClass, skThreadClass]) then
  begin
    AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
      'bound method values need a receiver closure; use a non-method routine or lambda');
    X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  end
  else
    X64LeaRegRipLabel(G.Assembler, xrRAX, G.Layout.FunctionLabels[FunctionId]);
  StoreValue(G, Instr.Dst, xrRAX);
end;

procedure EmitLoadSymbol(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  Offset, TypeId: Int32;
begin
  Offset := SymbolFrameOffset(G, Instr.SymbolId);
  TypeId := Instr.TypeId;
  if (Instr.SymbolId >= 0) and
     (Instr.SymbolId <= High(G.Symbols^.Symbols)) then
    TypeId := G.Symbols^.Symbols[Instr.SymbolId].TypeId;
  if SymbolGlobalOffset(G, Instr.SymbolId) >= 0 then
  begin
    X64LeaRegRipWritable(G.Assembler, xrRDX,
      SymbolGlobalOffset(G, Instr.SymbolId), 0);
    if (TypeId >= 0) and (TypeId <= High(G.Symbols^.Types)) and
       (((G.Symbols^.Types[TypeId].Kind = tyArray) and
         not (tfRuntimeBound in G.Symbols^.Types[TypeId].Flags)) or
        IsRecordValueType(G, TypeId)) then
      X64MovRegReg(G.Assembler, xrRAX, xrRDX)
    else
      EmitLoadAtAddress(G, xrRDX, TypeId, xrRAX);
  end
  else if Offset > 0 then
  begin
    if (TypeId >= 0) and (TypeId <= High(G.Symbols^.Types)) and
       (((G.Symbols^.Types[TypeId].Kind = tyArray) and
         not (tfRuntimeBound in G.Symbols^.Types[TypeId].Flags)) or
        IsRecordValueType(G, TypeId)) then
      X64LeaRegBaseDisp(G.Assembler, xrRAX, xrRBP, -Offset)
    else
    begin
      X64LeaRegBaseDisp(G.Assembler, xrRDX, xrRBP, -Offset);
      EmitLoadAtAddress(G, xrRDX, TypeId, xrRAX);
    end;
  end
  else if (Instr.SymbolId >= 0) and
          (Instr.SymbolId <= High(G.Symbols^.Symbols)) and
          (G.Symbols^.Symbols[Instr.SymbolId].Kind in
            [skClass, skProcessClass, skThreadClass]) and
          (G.CurrentFunction >= 0) and
          (G.CurrentFunction <= High(G.Layout.FunctionReceiverOffsets)) and
          (G.Layout.FunctionReceiverOffsets[G.CurrentFunction] > 0) then
    X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRBP,
      -G.Layout.FunctionReceiverOffsets[G.CurrentFunction])
  else if (Instr.SymbolId >= 0) and
          (Instr.SymbolId <= High(G.Symbols^.Symbols)) and
          (G.Symbols^.Symbols[Instr.SymbolId].Kind in
            [skConstant, skEnumValue]) then
    X64MovRegImm64(G.Assembler, xrRAX,
      QWord(G.Symbols^.Symbols[Instr.SymbolId].ConstantInt))
  else
  begin
    if (Instr.SymbolId >= 0) and
       (Instr.SymbolId <= High(G.Symbols^.Symbols)) and
       (G.Symbols^.Symbols[Instr.SymbolId].Kind in [skVariable, skParameter]) then
      AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
        'symbol ''' + SymName(G.Symbols^, Instr.SymbolId) +
        ''' has no storage in the current native frame');
    X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  end;
  StoreValue(G, Instr.Dst, xrRAX);
end;

procedure EmitS67TextAssignAtAddress(var G: TCodeGenerator;
  AddressReg, SourceReg: TX64Register);
begin
  X64MovRegMemBaseDisp(G.Assembler, xrRDI, AddressReg, 0);
  X64MovRegReg(G.Assembler, xrRSI, SourceReg);
  X64Call(G.Assembler, G.RuntimeLabels.S67.TextAssign);
end;

procedure EmitStoreSymbol(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  Offset, TypeId: Int32;
begin
  Offset := SymbolFrameOffset(G, Instr.SymbolId);
  TypeId := Instr.TypeId;
  if (Instr.SymbolId >= 0) and
     (Instr.SymbolId <= High(G.Symbols^.Symbols)) then
    TypeId := G.Symbols^.Symbols[Instr.SymbolId].TypeId;
  LoadValue(G, Instr.A, xrRCX);
  if SymbolGlobalOffset(G, Instr.SymbolId) >= 0 then
  begin
    X64LeaRegRipWritable(G.Assembler, xrRDX,
      SymbolGlobalOffset(G, Instr.SymbolId), 0);
    if (G.Options^.Dialect = fdSimula67) and
       (TypeId = FSIM_TYPE_TEXT) and (Instr.Aux = 0) then
      EmitS67TextAssignAtAddress(G, xrRDX, xrRCX)
    else
      EmitStoreAtAddress(G, xrRDX, TypeId, xrRCX);
  end
  else if Offset > 0 then
  begin
    X64LeaRegBaseDisp(G.Assembler, xrRDX, xrRBP, -Offset);
    if (G.Options^.Dialect = fdSimula67) and
       (TypeId = FSIM_TYPE_TEXT) and (Instr.Aux = 0) then
      EmitS67TextAssignAtAddress(G, xrRDX, xrRCX)
    else
      EmitStoreAtAddress(G, xrRDX, TypeId, xrRCX);
  end
  else if (Instr.SymbolId >= 0) and
          (Instr.SymbolId <= High(G.Symbols^.Symbols)) then
    AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
      'assignment target ''' + SymName(G.Symbols^, Instr.SymbolId) +
      ''' has no storage in the current native frame');
end;

procedure EmitLoadField(var G: TCodeGenerator;
  const Instr: TIRInstruction);
begin
  LoadValue(G, Instr.A, xrRAX);
  if G.Options^.NullChecks then
  begin
    X64MovRegReg(G.Assembler, xrRDI, xrRAX);
    X64Call(G.Assembler, G.RuntimeLabels.NullCheck);
  end;
  X64AddRegImm32(G.Assembler, xrRAX, FieldOffset(G, Instr.SymbolId));
  if (Instr.TypeId >= 0) and (Instr.TypeId <= High(G.Symbols^.Types)) and
     (((G.Symbols^.Types[Instr.TypeId].Kind = tyArray) and
       not (tfRuntimeBound in G.Symbols^.Types[Instr.TypeId].Flags)) or
      IsRecordValueType(G, Instr.TypeId)) then
    StoreValue(G, Instr.Dst, xrRAX)
  else
  begin
    EmitLoadAtAddress(G, xrRAX, Instr.TypeId, xrRAX);
    StoreValue(G, Instr.Dst, xrRAX);
  end;
end;

procedure EmitStoreField(var G: TCodeGenerator;
  const Instr: TIRInstruction);
begin
  LoadValue(G, Instr.A, xrRAX);
  if G.Options^.NullChecks then
  begin
    X64MovRegReg(G.Assembler, xrRDI, xrRAX);
    X64Call(G.Assembler, G.RuntimeLabels.NullCheck);
  end;
  LoadValue(G, Instr.B, xrRCX);
  X64AddRegImm32(G.Assembler, xrRAX, FieldOffset(G, Instr.SymbolId));
  if (G.Options^.Dialect = fdSimula67) and
     (Instr.TypeId = FSIM_TYPE_TEXT) and (Instr.Aux = 0) then
    EmitS67TextAssignAtAddress(G, xrRAX, xrRCX)
  else
    EmitStoreAtAddress(G, xrRAX, Instr.TypeId, xrRCX);
end;

procedure EmitArrayAllocation(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  Info: TTypeInfo;
  ElementSize: UInt32;
begin
  if (Instr.TypeId < 0) or (Instr.TypeId > High(G.Symbols^.Types)) then
  begin
    X64Jump(G.Assembler, G.RuntimeLabels.PanicAllocation);
    Exit;
  end;
  Info := G.Symbols^.Types[Instr.TypeId];
  ElementSize := RuntimeTypeStorageSize(G.Symbols^, Info.ElementType);
  LoadValue(G, Instr.A, xrRCX);
  LoadValue(G, Instr.B, xrRDX);
  X64CmpRegReg(G.Assembler, xrRDX, xrRCX);
  X64JumpCondition(G.Assembler, xcLess, G.RuntimeLabels.PanicBounds);
  X64MovRegReg(G.Assembler, xrRDI, xrRDX);
  X64SubRegReg(G.Assembler, xrRDI, xrRCX);
  X64AddRegImm32(G.Assembler, xrRDI, 1);
  if ElementSize > 1 then
  begin
    X64IMulRegRegImm32(G.Assembler, xrRDI, xrRDI, Int32(ElementSize));
    EmitCheckedOverflow(G);
  end;
  X64AddRegImm32(G.Assembler, xrRDI, 24);
  EmitCheckedOverflow(G);
  X64Call(G.Assembler, G.RuntimeLabels.Allocate);
  X64LeaRegBaseDisp(G.Assembler, xrRDX, xrRAX, 24);
  X64MovMemBaseDispReg(G.Assembler, xrRAX, 0, xrRDX);
  LoadValue(G, Instr.A, xrRCX);
  X64MovMemBaseDispReg(G.Assembler, xrRAX, 8, xrRCX);
  LoadValue(G, Instr.B, xrRDX);
  X64MovMemBaseDispReg(G.Assembler, xrRAX, 16, xrRDX);
  StoreValue(G, Instr.Dst, xrRAX);
end;

procedure EmitHandleAllocation(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  ByteCount, Offset: Int64;
begin
  ByteCount := Instr.Imm;
  if ByteCount < 8 then ByteCount := 8;
  if ByteCount > High(Int32) then
  begin
    X64Jump(G.Assembler, G.RuntimeLabels.PanicAllocation);
    Exit;
  end;
  X64MovRegImm64(G.Assembler, xrRDI, QWord(ByteCount));
  X64Call(G.Assembler, G.RuntimeLabels.Allocate);
  { The slab allocator reserves bytes; it does not promise that reused bytes
    are zero.  Handles do promise a clean initial state.  Relying on fresh
    mmap pages made mutex/atomic startup accidentally depend on allocation
    history, which is exactly the kind of bug that only shows up at 2am. }
  X64XorRegReg(G.Assembler, xrRCX, xrRCX);
  Offset := 0;
  while Offset + 8 <= ByteCount do
  begin
    X64MovMemBaseDispReg(G.Assembler, xrRAX, Int32(Offset), xrRCX);
    Inc(Offset, 8);
  end;
  while Offset < ByteCount do
  begin
    X64MovMemBaseDispReg8(G.Assembler, xrRAX, Int32(Offset), xrRCX);
    Inc(Offset);
  end;
  StoreValue(G, Instr.Dst, xrRAX);
end;

procedure EmitObjectAllocation(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  ClassIndex: Int32;
begin
  ClassIndex := ClassIndexForSymbol(G, Instr.SymbolId);
  if ClassIndex < 0 then
  begin
    X64Jump(G.Assembler, G.RuntimeLabels.PanicAllocation);
    Exit;
  end;
  X64MovRegImm64(G.Assembler, xrRDI,
    G.Symbols^.Classes[ClassIndex].InstanceSize);
  X64Call(G.Assembler, G.RuntimeLabels.Allocate);
  StoreValue(G, Instr.Dst, xrRAX);
end;

procedure EmitObjectInitialization(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  ClassIndex: Int32;
begin
  ClassIndex := ClassIndexForSymbol(G, Instr.SymbolId);
  if ClassIndex < 0 then Exit;
  LoadValue(G, Instr.A, xrRAX);
  X64LeaRegRipData(G.Assembler, xrRCX,
    G.Layout.RTTIOffsets[ClassIndex], 0);
  X64MovMemBaseDispReg(G.Assembler, xrRAX, 0, xrRCX);
  if G.Symbols^.Classes[ClassIndex].VMTSlotCount > 0 then
    X64LeaRegRipData(G.Assembler, xrRCX,
      G.Layout.VMTOffsets[ClassIndex], 0)
  else
    X64XorRegReg(G.Assembler, xrRCX, xrRCX);
  X64MovMemBaseDispReg(G.Assembler, xrRAX, 8, xrRCX);
end;

procedure EmitQua(var G: TCodeGenerator; const Instr: TIRInstruction);
var
  ClassIndex, DoneLabel: Int32;
begin
  ClassIndex := ClassIndexForSymbol(G, Instr.SymbolId);
  LoadValue(G, Instr.A, xrRDI);
  DoneLabel := FSIM_INVALID_INDEX;
  if Instr.Aux <> 0 then
  begin
    { Narrowing reference assignment accepts NONE without invoking QUA's
      trapping semantics. }
    DoneLabel := X64NewLabel(G.Assembler);
    X64MovRegReg(G.Assembler, xrRAX, xrRDI);
    X64TestRegReg(G.Assembler, xrRDI, xrRDI);
    X64JumpCondition(G.Assembler, xcEqual, DoneLabel);
  end;
  if ClassIndex >= 0 then
    X64LeaRegRipData(G.Assembler, xrRSI,
      G.Layout.RTTIOffsets[ClassIndex], 0)
  else
    X64XorRegReg(G.Assembler, xrRSI, xrRSI);
  X64Call(G.Assembler, G.RuntimeLabels.QuaCheck);
  if DoneLabel >= 0 then
    X64BindLabel(G.Assembler, DoneLabel);
  StoreValue(G, Instr.Dst, xrRAX);
end;

procedure EmitTypeTest(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  ClassIndex: Int32;
  LoopLabel, SuccessLabel, FailureLabel, DoneLabel: Int32;
begin
  ClassIndex := ClassIndexForSymbol(G, Instr.SymbolId);
  LoopLabel := X64NewLabel(G.Assembler);
  SuccessLabel := X64NewLabel(G.Assembler);
  FailureLabel := X64NewLabel(G.Assembler);
  DoneLabel := X64NewLabel(G.Assembler);
  LoadValue(G, Instr.A, xrRDI);
  X64TestRegReg(G.Assembler, xrRDI, xrRDI);
  X64JumpCondition(G.Assembler, xcEqual, FailureLabel);
  if ClassIndex >= 0 then
    X64LeaRegRipData(G.Assembler, xrRSI,
      G.Layout.RTTIOffsets[ClassIndex], 0)
  else
    X64XorRegReg(G.Assembler, xrRSI, xrRSI);
  X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, 0);
  X64BindLabel(G.Assembler, LoopLabel);
  X64TestRegReg(G.Assembler, xrRAX, xrRAX);
  X64JumpCondition(G.Assembler, xcEqual, FailureLabel);
  X64CmpRegReg(G.Assembler, xrRAX, xrRSI);
  X64JumpCondition(G.Assembler, xcEqual, SuccessLabel);
  X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRAX, 0);
  X64Jump(G.Assembler, LoopLabel);
  X64BindLabel(G.Assembler, SuccessLabel);
  X64MovRegImm64(G.Assembler, xrRAX, 1);
  X64Jump(G.Assembler, DoneLabel);
  X64BindLabel(G.Assembler, FailureLabel);
  X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  X64BindLabel(G.Assembler, DoneLabel);
  StoreValue(G, Instr.Dst, xrRAX);
end;

procedure EmitTypeExact(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  ClassIndex: Int32;
  FailureLabel, DoneLabel: Int32;
begin
  ClassIndex := ClassIndexForSymbol(G, Instr.SymbolId);
  FailureLabel := X64NewLabel(G.Assembler);
  DoneLabel := X64NewLabel(G.Assembler);
  LoadValue(G, Instr.A, xrRDI);
  X64TestRegReg(G.Assembler, xrRDI, xrRDI);
  X64JumpCondition(G.Assembler, xcEqual, FailureLabel);
  X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, 0);
  if ClassIndex >= 0 then
    X64LeaRegRipData(G.Assembler, xrRSI,
      G.Layout.RTTIOffsets[ClassIndex], 0)
  else
    X64XorRegReg(G.Assembler, xrRSI, xrRSI);
  X64CmpRegReg(G.Assembler, xrRAX, xrRSI);
  X64MovRegImm64(G.Assembler, xrRAX, 0);
  X64SetCondition8(G.Assembler, xcEqual, xrRAX);
  X64Jump(G.Assembler, DoneLabel);
  X64BindLabel(G.Assembler, FailureLabel);
  X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  X64BindLabel(G.Assembler, DoneLabel);
  StoreValue(G, Instr.Dst, xrRAX);
end;

procedure EmitFutexWait(var G: TCodeGenerator; Address: TX64Register;
  Expected: TX64Register);
begin
  if Address <> xrRDI then
    X64MovRegReg(G.Assembler, xrRDI, Address);
  if Expected <> xrRDX then
    X64MovRegReg(G.Assembler, xrRDX, Expected);
  X64MovRegImm64(G.Assembler, xrRSI, 128); { FUTEX_WAIT_PRIVATE }
  X64XorRegReg(G.Assembler, xrR10, xrR10);
  X64XorRegReg(G.Assembler, xrR8, xrR8);
  X64XorRegReg(G.Assembler, xrR9, xrR9);
  X64MovRegImm64(G.Assembler, xrRAX, 202); { futex }
  X64Syscall(G.Assembler);
end;

procedure EmitFutexWakeOne(var G: TCodeGenerator; Address: TX64Register);
begin
  if Address <> xrRDI then
    X64MovRegReg(G.Assembler, xrRDI, Address);
  X64MovRegImm64(G.Assembler, xrRSI, 129); { FUTEX_WAKE_PRIVATE }
  X64MovRegImm64(G.Assembler, xrRDX, 1);
  X64XorRegReg(G.Assembler, xrR10, xrR10);
  X64XorRegReg(G.Assembler, xrR8, xrR8);
  X64XorRegReg(G.Assembler, xrR9, xrR9);
  X64MovRegImm64(G.Assembler, xrRAX, 202);
  X64Syscall(G.Assembler);
end;

procedure EmitFutexWakeAll(var G: TCodeGenerator; Address: TX64Register);
begin
  if Address <> xrRDI then
    X64MovRegReg(G.Assembler, xrRDI, Address);
  X64MovRegImm64(G.Assembler, xrRSI, 129); { FUTEX_WAKE_PRIVATE }
  X64MovRegImm64(G.Assembler, xrRDX, High(Int32));
  X64XorRegReg(G.Assembler, xrR10, xrR10);
  X64XorRegReg(G.Assembler, xrR8, xrR8);
  X64XorRegReg(G.Assembler, xrR9, xrR9);
  X64MovRegImm64(G.Assembler, xrRAX, 202);
  X64Syscall(G.Assembler);
end;

procedure EmitChannelSend(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  RetryLabel, AcquiredLabel: Int32;
begin
  RetryLabel := X64NewLabel(G.Assembler);
  AcquiredLabel := X64NewLabel(G.Assembler);
  LoadValue(G, Instr.A, xrRDI);
  if G.Options^.NullChecks then
  begin
    X64MovRegReg(G.Assembler, xrRAX, xrRDI);
    X64TestRegReg(G.Assembler, xrRAX, xrRAX);
    X64JumpCondition(G.Assembler, xcEqual, G.RuntimeLabels.PanicNull);
  end;
  X64BindLabel(G.Assembler, RetryLabel);
  X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  X64MovRegImm64(G.Assembler, xrRCX, 2);
  X64LockCmpXchgMemBaseDispReg(G.Assembler, xrRDI, 0, xrRCX);
  X64JumpCondition(G.Assembler, xcEqual, AcquiredLabel);
  X64MovRegReg(G.Assembler, xrRDX, xrRAX);
  EmitFutexWait(G, xrRDI, xrRDX);
  X64Jump(G.Assembler, RetryLabel);
  X64BindLabel(G.Assembler, AcquiredLabel);
  LoadValue(G, Instr.B, xrRDX);
  X64MovMemBaseDispReg(G.Assembler, xrRDI, 8, xrRDX);
  X64MemoryFence(G.Assembler);
  X64MovRegImm64(G.Assembler, xrRAX, 1);
  X64MovMemBaseDispReg(G.Assembler, xrRDI, 0, xrRAX);
  EmitFutexWakeAll(G, xrRDI);
end;

procedure EmitChannelReceive(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  RetryLabel, AcquiredLabel: Int32;
begin
  RetryLabel := X64NewLabel(G.Assembler);
  AcquiredLabel := X64NewLabel(G.Assembler);
  LoadValue(G, Instr.A, xrRDI);
  if G.Options^.NullChecks then
  begin
    X64TestRegReg(G.Assembler, xrRDI, xrRDI);
    X64JumpCondition(G.Assembler, xcEqual, G.RuntimeLabels.PanicNull);
  end;
  X64BindLabel(G.Assembler, RetryLabel);
  X64MovRegImm64(G.Assembler, xrRAX, 1);
  X64MovRegImm64(G.Assembler, xrRCX, 2);
  X64LockCmpXchgMemBaseDispReg(G.Assembler, xrRDI, 0, xrRCX);
  X64JumpCondition(G.Assembler, xcEqual, AcquiredLabel);
  X64MovRegReg(G.Assembler, xrRDX, xrRAX);
  EmitFutexWait(G, xrRDI, xrRDX);
  X64Jump(G.Assembler, RetryLabel);
  X64BindLabel(G.Assembler, AcquiredLabel);
  X64MovRegMemBaseDisp(G.Assembler, xrRDX, xrRDI, 8);
  X64MemoryFence(G.Assembler);
  X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  X64MovMemBaseDispReg(G.Assembler, xrRDI, 0, xrRAX);
  if Instr.Dst >= 0 then StoreValue(G, Instr.Dst, xrRDX);
  EmitFutexWakeAll(G, xrRDI);
end;

procedure EmitMutexLock(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  RetryLabel, AcquiredLabel: Int32;
begin
  RetryLabel := X64NewLabel(G.Assembler);
  AcquiredLabel := X64NewLabel(G.Assembler);
  LoadValue(G, Instr.A, xrRDI);
  if G.Options^.NullChecks then
  begin
    X64TestRegReg(G.Assembler, xrRDI, xrRDI);
    X64JumpCondition(G.Assembler, xcEqual, G.RuntimeLabels.PanicNull);
  end;
  X64BindLabel(G.Assembler, RetryLabel);
  X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  X64MovRegImm64(G.Assembler, xrRCX, 1);
  X64LockCmpXchgMemBaseDispReg(G.Assembler, xrRDI, 0, xrRCX);
  X64JumpCondition(G.Assembler, xcEqual, AcquiredLabel);
  X64MovRegImm64(G.Assembler, xrRDX, 1);
  EmitFutexWait(G, xrRDI, xrRDX);
  X64Jump(G.Assembler, RetryLabel);
  X64BindLabel(G.Assembler, AcquiredLabel);
  X64MemoryFence(G.Assembler);
end;

procedure EmitMutexUnlock(var G: TCodeGenerator;
  const Instr: TIRInstruction);
begin
  LoadValue(G, Instr.A, xrRDI);
  if G.Options^.NullChecks then
  begin
    X64TestRegReg(G.Assembler, xrRDI, xrRDI);
    X64JumpCondition(G.Assembler, xcEqual, G.RuntimeLabels.PanicNull);
  end;
  X64MemoryFence(G.Assembler);
  X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  X64MovMemBaseDispReg(G.Assembler, xrRDI, 0, xrRAX);
  EmitFutexWakeOne(G, xrRDI);
end;

procedure EmitThreadYield(var G: TCodeGenerator;
  const Instr: TIRInstruction);
begin
  X64MovRegImm64(G.Assembler, xrRAX, 24);
  X64Syscall(G.Assembler);
  if Instr.Dst >= 0 then StoreValue(G, Instr.Dst, xrRAX);
end;

procedure SetPendingParameter(var G: TCodeGenerator; Index, ValueId: Int32);
begin
  if Index < 0 then Exit;
  if Length(G.PendingParameters) <= Index then
    SetLength(G.PendingParameters, Index + 1);
  G.PendingParameters[Index] := ValueId;
end;

function ArgumentRegister(Index: Int32): TX64Register;
begin
  case Index of
    0: Result := xrRDI;
    1: Result := xrRSI;
    2: Result := xrRDX;
    3: Result := xrRCX;
    4: Result := xrR8;
    5: Result := xrR9;
  else
    Result := xrNone;
  end;
end;

function MaterializeCallArguments(var G: TCodeGenerator;
  ReceiverValue: Int32; HasReceiver: Boolean; SRetOffset: Int32;
  HasSRet: Boolean): Int32;
var
  I, Shift, ReceiverOrdinal, Ordinal, StackCount: Int32;
  Reg: TX64Register;
begin
  Shift := Ord(HasReceiver) + Ord(HasSRet);
  StackCount := Length(G.PendingParameters) + Shift - 6;
  if StackCount < 0 then StackCount := 0;
  Result := Int32(AlignUp(QWord(StackCount) * 8, 16));
  if Result > 0 then X64SubRegImm32(G.Assembler, xrRSP, Result);

  { Spill outgoing stack arguments first. Loading register arguments afterwards
    prevents a source reload from trampling an ABI register we already filled. }
  for I := 0 to High(G.PendingParameters) do
  begin
    Ordinal := I + Shift;
    if Ordinal >= 6 then
    begin
      LoadValue(G, G.PendingParameters[I], xrRAX);
      X64MovMemBaseDispReg(G.Assembler, xrRSP, (Ordinal - 6) * 8, xrRAX);
    end;
  end;

  if HasSRet then
  begin
    if SRetOffset <= 0 then
    begin
      AddError(G.Diagnostics^, dcBackendUnsupported,
        G.ProgramIR^.Instructions[G.CurrentInstruction].Span,
        'internal aggregate call has no caller return storage');
      X64XorRegReg(G.Assembler, xrRDI, xrRDI);
    end
    else
      X64LeaRegBaseDisp(G.Assembler, xrRDI, xrRBP, -SRetOffset);
  end;

  ReceiverOrdinal := Ord(HasSRet);
  if HasReceiver then
  begin
    Reg := ArgumentRegister(ReceiverOrdinal);
    if Reg <> xrNone then
      LoadValue(G, ReceiverValue, Reg)
    else
    begin
      LoadValue(G, ReceiverValue, xrRAX);
      X64MovMemBaseDispReg(G.Assembler, xrRSP,
        (ReceiverOrdinal - 6) * 8, xrRAX);
    end;
  end;
  for I := 0 to High(G.PendingParameters) do
  begin
    Reg := ArgumentRegister(I + Shift);
    if Reg <> xrNone then
      LoadValue(G, G.PendingParameters[I], Reg);
  end;
end;

procedure ClearPendingParameters(var G: TCodeGenerator);
begin
  SetLength(G.PendingParameters, 0);
end;


function CIntegerArgumentRegister(Index: Int32): TX64Register;
begin
  case Index of
    0: Result := xrRDI;
    1: Result := xrRSI;
    2: Result := xrRDX;
    3: Result := xrRCX;
    4: Result := xrR8;
    5: Result := xrR9;
  else
    Result := xrNone;
  end;
end;

function CSSEArgumentRegister(Index: Int32): TX64Register;
begin
  case Index of
    0: Result := xrXMM0;
    1: Result := xrXMM1;
    2: Result := xrXMM2;
    3: Result := xrXMM3;
    4: Result := xrXMM4;
    5: Result := xrXMM5;
    6: Result := xrXMM6;
    7: Result := xrXMM7;
  else
    Result := xrNone;
  end;
end;

function IsCFloatType(const G: TCodeGenerator; TypeId: Int32): Boolean;
begin
  Result := (TypeId >= 0) and (TypeId <= High(G.Symbols^.Types)) and
    (G.Symbols^.Types[TypeId].Kind = tyCReal) and
    (G.Symbols^.Types[TypeId].Size = 4);
end;

function IsCRealType(const G: TCodeGenerator; TypeId: Int32): Boolean;
begin
  Result := (TypeId >= 0) and (TypeId <= High(G.Symbols^.Types)) and
    (G.Symbols^.Types[TypeId].Kind = tyCReal);
end;

function IsCIntegerType(const G: TCodeGenerator; TypeId: Int32): Boolean;
begin
  Result := (TypeId >= 0) and (TypeId <= High(G.Symbols^.Types)) and
    (G.Symbols^.Types[TypeId].Kind = tyCInteger);
end;

function MergeForeignClass(Left, Right: TForeignArgClass): TForeignArgClass;
begin
  if Left = facNoClass then Exit(Right);
  if Right = facNoClass then Exit(Left);
  if (Left = facMemory) or (Right = facMemory) then Exit(facMemory);
  if (Left = facInteger) or (Right = facInteger) then Exit(facInteger);
  Result := facSSE;
end;

function ClassifyCABIAt(const G: TCodeGenerator; TypeId: Int32;
  BaseOffset: UInt32; var Layout: TCABILayout): Boolean;
var
  Info: TTypeInfo;
  Part, I, Owner, FieldType: Int32;
  ElemSize, Count, Offset: QWord;
  ClassValue: TForeignArgClass;
begin
  Result := False;
  if (TypeId < 0) or (TypeId > High(G.Symbols^.Types)) then Exit(True);
  Info := G.Symbols^.Types[TypeId];
  case Info.Kind of
    tyCInteger, tyCPointer, tyCFunction:
      ClassValue := facInteger;
    tyCReal:
      ClassValue := facSSE;
    tyArray:
      begin
        if tfRuntimeBound in Info.Flags then Exit(True);
        if Info.UpperBound < Info.LowerBound then Exit(False);
        ElemSize := RuntimeTypeStorageSize(G.Symbols^, Info.ElementType);
        Count := QWord(Info.UpperBound - Info.LowerBound) + 1;
        for I := 0 to Int32(Count) - 1 do
          if ClassifyCABIAt(G, Info.ElementType,
             BaseOffset + UInt32(QWord(I) * ElemSize), Layout) then Exit(True);
        Exit(False);
      end;
    tyRecord:
      begin
        if not (tfCLayout in Info.Flags) then Exit(True);
        Owner := Info.RefClassSymbol;
        for I := 0 to High(G.Symbols^.Symbols) do
          if (G.Symbols^.Symbols[I].OwnerSymbol = Owner) and
             (G.Symbols^.Symbols[I].Kind = skField) then
          begin
            FieldType := G.Symbols^.Symbols[I].TypeId;
            if (FieldType < 0) or (FieldType > High(G.Symbols^.Types)) then
              Exit(True);
            if (G.Symbols^.Types[FieldType].Alignment > 1) and
               ((G.Symbols^.Symbols[I].StorageOffset mod
                 G.Symbols^.Types[FieldType].Alignment) <> 0) then
              Exit(True);
            if ClassifyCABIAt(G, FieldType,
               BaseOffset + G.Symbols^.Symbols[I].StorageOffset, Layout) then
              Exit(True);
          end;
        Exit(False);
      end;
  else
    Exit(True);
  end;

  Offset := BaseOffset;
  Part := Int32(Offset div 8);
  if Part > 1 then Exit(True);
  Layout.Classes[Part] := MergeForeignClass(Layout.Classes[Part], ClassValue);
  if Layout.Classes[Part] = facMemory then Exit(True);
end;

function ClassifyCABIType(const G: TCodeGenerator; TypeId: Int32): TCABILayout;
var
  Info: TTypeInfo;
  I: Int32;
begin
  Result := Default(TCABILayout);
  Result.Classes[0] := facNoClass;
  Result.Classes[1] := facNoClass;
  if (TypeId < 0) or (TypeId > High(G.Symbols^.Types)) then
  begin
    Result.Memory := True;
    Exit;
  end;
  Info := G.Symbols^.Types[TypeId];
  Result.Size := RuntimeTypeStorageSize(G.Symbols^, TypeId);
  Result.Alignment := Info.Alignment;
  if Result.Alignment = 0 then Result.Alignment := 1;
  if Result.Size = 0 then
  begin
    Result.PartCount := 0;
    Exit;
  end;
  if (Result.Size > 16) or ClassifyCABIAt(G, TypeId, 0, Result) then
  begin
    Result.Memory := True;
    Result.PartCount := 0;
    Result.Classes[0] := facMemory;
    Result.Classes[1] := facMemory;
    Exit;
  end;
  Result.PartCount := Byte((Result.Size + 7) div 8);
  for I := 0 to Result.PartCount - 1 do
    if Result.Classes[I] = facNoClass then
      Result.Classes[I] := facInteger;
end;

function ForeignArgumentClass(const G: TCodeGenerator; ABIType: Int32): TForeignArgClass;
var
  Layout: TCABILayout;
begin
  Layout := ClassifyCABIType(G, ABIType);
  if Layout.Memory then Exit(facMemory);
  if Layout.PartCount = 0 then Exit(facNoClass);
  Result := Layout.Classes[0];
end;

procedure NormalizeCInteger(var G: TCodeGenerator; Reg: TX64Register;
  TypeId: Int32);
var
  Info: TTypeInfo;
begin
  if not IsCIntegerType(G, TypeId) then Exit;
  Info := G.Symbols^.Types[TypeId];
  case Info.Size of
    1:
      if tfSigned in Info.Flags then
      begin
        X64ShlRegImm8(G.Assembler, Reg, 56);
        X64SarRegImm8(G.Assembler, Reg, 56);
      end
      else
        X64AndRegImm32(G.Assembler, Reg, $FF);
    2:
      if tfSigned in Info.Flags then
      begin
        X64ShlRegImm8(G.Assembler, Reg, 48);
        X64SarRegImm8(G.Assembler, Reg, 48);
      end
      else
        X64AndRegImm32(G.Assembler, Reg, $FFFF);
    4:
      if tfSigned in Info.Flags then
      begin
        X64ShlRegImm8(G.Assembler, Reg, 32);
        X64SarRegImm8(G.Assembler, Reg, 32);
      end
      else
      begin
        X64ShlRegImm8(G.Assembler, Reg, 32);
        X64ShrRegImm8(G.Assembler, Reg, 32);
      end;
  end;
end;

procedure LoadCStringArgument(var G: TCodeGenerator; ValueId, SourceType: Int32;
  Target: TX64Register);
var
  DoneLabel: Int32;
begin
  LoadValue(G, ValueId, Target);
  if SourceType <> FSIM_TYPE_STRING then Exit;
  DoneLabel := X64NewLabel(G.Assembler);
  X64TestRegReg(G.Assembler, Target, Target);
  X64JumpCondition(G.Assembler, xcEqual, DoneLabel);
  { Native strings are [length:qword][bytes...][nul].  C sees only bytes. }
  X64AddRegImm32(G.Assembler, Target, 8);
  X64BindLabel(G.Assembler, DoneLabel);
end;

procedure LoadForeignIntegerArgument(var G: TCodeGenerator;
  const Arg: TForeignArgLocation; Target: TX64Register);
begin
  if Arg.ABIType = FSIM_TYPE_C_STRING then
    LoadCStringArgument(G, Arg.ValueId, Arg.SourceType, Target)
  else
  begin
    LoadValue(G, Arg.ValueId, Target);
    NormalizeCInteger(G, Target, Arg.ABIType);
  end;
end;

procedure LoadForeignSSEArgument(var G: TCodeGenerator;
  const Arg: TForeignArgLocation; TargetXMM: TX64Register);
begin
  LoadValue(G, Arg.ValueId, xrRAX);
  X64MovQXMMReg(G.Assembler, TargetXMM, xrRAX);
  if IsCFloatType(G, Arg.ABIType) and not Arg.IsVariadic then
    X64CvtSD2SS(G.Assembler, TargetXMM, TargetXMM);
end;


function EnsureForeignProcessExitBinding(var G: TCodeGenerator): Int32;
var
  I: Integer;
  B: TForeignBinding;
begin
  for I := 0 to High(G.Symbols^.ForeignBindings) do
  begin
    B := G.Symbols^.ForeignBindings[I];
    if (B.SymbolId = FSIM_INVALID_INDEX) and
       (StringPoolGet(G.Symbols^.Strings, B.LinkNameId) = 'exit') and
       (StringPoolGet(G.Symbols^.Strings, B.LibraryNameId) = G.Options^.CRuntimeLibrary) then
      Exit(I);
  end;
  Result := Length(G.Symbols^.ForeignBindings);
  SetLength(G.Symbols^.ForeignBindings, Result + 1);
  G.Symbols^.ForeignBindings[Result] := Default(TForeignBinding);
  G.Symbols^.ForeignBindings[Result].SymbolId := FSIM_INVALID_INDEX;
  G.Symbols^.ForeignBindings[Result].LinkNameId :=
    StringPoolIntern(G.Symbols^.Strings, 'exit');
  G.Symbols^.ForeignBindings[Result].LibraryNameId :=
    StringPoolIntern(G.Symbols^.Strings, G.Options^.CRuntimeLibrary);
  G.Symbols^.ForeignBindings[Result].Convention := fcCSystemVAMD64;
  G.Symbols^.ForeignBindings[Result].Kind := fbFunction;
  G.Symbols^.ForeignBindings[Result].FixedParameterCount := 1;
end;

procedure AppendForeignCallFixup(var G: TCodeGenerator; ForeignIndex: Int32);
var
  N: Integer;
begin
  { call qword ptr [rip+disp32].  The loader fills the GOT slot at startup, so
    there is no PLT trampoline on the hot path. }
  X64EmitByte(G.Assembler, $FF);
  X64EmitByte(G.Assembler, $15);
  N := Length(G.ForeignCalls);
  SetLength(G.ForeignCalls, N + 1);
  G.ForeignCalls[N].PatchOffset := G.Assembler.Code.Count;
  G.ForeignCalls[N].SourceEndOffset := G.Assembler.Code.Count + 4;
  G.ForeignCalls[N].ForeignIndex := ForeignIndex;
  X64EmitDWord(G.Assembler, 0);
end;

procedure AppendForeignGOTLoad(var G: TCodeGenerator;
  ForeignIndex: Int32);
var
  N: Integer;
begin
  { mov rax, qword ptr [rip+disp32]. the loader fills this slot before _start. }
  X64EmitByte(G.Assembler, $48);
  X64EmitByte(G.Assembler, $8B);
  X64EmitByte(G.Assembler, $05);
  N := Length(G.ForeignCalls);
  SetLength(G.ForeignCalls, N + 1);
  G.ForeignCalls[N].PatchOffset := G.Assembler.Code.Count;
  G.ForeignCalls[N].SourceEndOffset := G.Assembler.Code.Count + 4;
  G.ForeignCalls[N].ForeignIndex := ForeignIndex;
  X64EmitDWord(G.Assembler, 0);
end;

procedure EmitForeignDataLoad(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  ForeignIndex: Int32;
begin
  ForeignIndex := SymForeignBinding(G.Symbols^, Instr.SymbolId);
  if (ForeignIndex < 0) or
     (ForeignIndex > High(G.Symbols^.ForeignBindings)) or
     (G.Symbols^.ForeignBindings[ForeignIndex].Kind <> fbObject) then
  begin
    AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
      'foreign data symbol has no object binding');
    X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  end
  else
  begin
    AppendForeignGOTLoad(G, ForeignIndex);
    EmitLoadAtAddress(G, xrRAX, Instr.TypeId, xrRAX);
  end;
  StoreValue(G, Instr.Dst, xrRAX);
end;

procedure EmitForeignDataStore(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  ForeignIndex: Int32;
begin
  ForeignIndex := SymForeignBinding(G.Symbols^, Instr.SymbolId);
  if (ForeignIndex < 0) or
     (ForeignIndex > High(G.Symbols^.ForeignBindings)) or
     (G.Symbols^.ForeignBindings[ForeignIndex].Kind <> fbObject) then
  begin
    AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
      'foreign data symbol has no object binding');
    Exit;
  end;
  AppendForeignGOTLoad(G, ForeignIndex);
  X64MovRegReg(G.Assembler, xrRDX, xrRAX);
  LoadValue(G, Instr.A, xrRCX);
  EmitStoreAtAddress(G, xrRDX, Instr.TypeId, xrRCX);
end;

procedure LoadAggregateChunk(var G: TCodeGenerator; Address: TX64Register;
  Offset, Bytes: UInt32; Target: TX64Register);
var
  I: UInt32;
  Scratch: TX64Register;
begin
  X64XorRegReg(G.Assembler, Target, Target);
  if Bytes = 0 then Exit;
  case Bytes of
    1: X64MovRegMemBaseDisp8(G.Assembler, Target, Address, Int32(Offset));
    2: X64MovZXRegMemBaseDisp16(G.Assembler, Target, Address, Int32(Offset));
    4: X64MovZXRegMemBaseDisp32(G.Assembler, Target, Address, Int32(Offset));
    8: X64MovRegMemBaseDisp(G.Assembler, Target, Address, Int32(Offset));
  else
    begin
      if (Target <> xrR11) and (Address <> xrR11) then Scratch := xrR11
      else if (Target <> xrRCX) and (Address <> xrRCX) then Scratch := xrRCX
      else Scratch := xrRDX;
      for I := 0 to Bytes - 1 do
      begin
        X64MovRegMemBaseDisp8(G.Assembler, Scratch, Address,
          Int32(Offset + I));
        if I <> 0 then X64ShlRegImm8(G.Assembler, Scratch, Byte(I * 8));
        X64OrRegReg(G.Assembler, Target, Scratch);
      end;
    end;
  end;
end;

procedure StoreAggregateChunk(var G: TCodeGenerator; Address: TX64Register;
  Offset, Bytes: UInt32; Source: TX64Register);
var
  I: UInt32;
  Scratch: TX64Register;
begin
  if Bytes = 0 then Exit;
  case Bytes of
    1: X64MovMemBaseDispReg8(G.Assembler, Address, Int32(Offset), Source);
    2: X64MovMemBaseDispReg16(G.Assembler, Address, Int32(Offset), Source);
    4: X64MovMemBaseDispReg32(G.Assembler, Address, Int32(Offset), Source);
    8: X64MovMemBaseDispReg(G.Assembler, Address, Int32(Offset), Source);
  else
    begin
      if (Source <> xrR11) and (Address <> xrR11) then Scratch := xrR11
      else if (Source <> xrRCX) and (Address <> xrRCX) then Scratch := xrRCX
      else Scratch := xrRDX;
      X64MovRegReg(G.Assembler, Scratch, Source);
      for I := 0 to Bytes - 1 do
      begin
        X64MovMemBaseDispReg8(G.Assembler, Address, Int32(Offset + I), Scratch);
        if I + 1 < Bytes then X64ShrRegImm8(G.Assembler, Scratch, 8);
      end;
    end;
  end;
end;

procedure EmitForeignCallInstruction(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  ForeignIndex, FixedCount, I, J, GPCount, SSECount, StackUsed, StackBytes: Int32;
  ProcedureType, ABIType, SourceType, ReturnType: Int32;
  ReturnPointerOffset, ReturnRAXOffset, ReturnRDXOffset, ReturnGP, ReturnSSE: Int32;
  Args: array of TForeignArgLocation;
  Reg: TX64Register;
  Binding: TForeignBinding;
  IndirectCall, NeedsReturnStorage, NeedsVarArgVectorMetadata: Boolean;
  NeedGP, NeedSSE, GPProbe, SSEProbe: Int32;
  AlignValue, PartBytes, PartOffset: UInt32;
  ReturnLayout: TCABILayout;
begin
  Binding := Default(TForeignBinding);
  IndirectCall := Instr.Op = irCallForeignIndirect;
  if IndirectCall then
  begin
    ForeignIndex := FSIM_INVALID_INDEX;
    if (Instr.A < 0) or (Instr.A > High(G.ProgramIR^.Values)) then
    begin
      AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
        'indirect foreign call has no function pointer value');
      X64Int3(G.Assembler);
      Exit;
    end;
    ProcedureType := G.ProgramIR^.Values[Instr.A].TypeId;
    if (ProcedureType < 0) or (ProcedureType > High(G.Symbols^.Types)) or
       (G.Symbols^.Types[ProcedureType].Kind <> tyCFunction) then
    begin
      AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
        'indirect foreign call target is not a typed c_fn value');
      X64Int3(G.Assembler);
      Exit;
    end;
    FixedCount := G.Symbols^.Types[ProcedureType].ParameterCount;
    Binding.Convention := fcCSystemVAMD64;
    Binding.FixedParameterCount := FixedCount;
    Binding.Variadic := tfCVariadic in G.Symbols^.Types[ProcedureType].Flags;
    if G.Options^.NullChecks then
    begin
      LoadValue(G, Instr.A, xrRDI);
      X64Call(G.Assembler, G.RuntimeLabels.NullCheck);
    end;
  end
  else
  begin
    ForeignIndex := SymForeignBinding(G.Symbols^, Instr.SymbolId);
    if ForeignIndex = FSIM_INVALID_INDEX then
    begin
      AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
        'foreign routine has no C ABI binding metadata');
      X64Int3(G.Assembler);
      Exit;
    end;
    Binding := G.Symbols^.ForeignBindings[ForeignIndex];
    if Binding.Convention <> fcCSystemVAMD64 then
    begin
      AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
        'foreign routine uses an unsupported calling convention');
      X64Int3(G.Assembler);
      Exit;
    end;
    ProcedureType := G.Symbols^.Symbols[Instr.SymbolId].TypeId;
    FixedCount := Binding.FixedParameterCount;
  end;

  { Preserve the SysV varargs marker redundantly.  The foreign binding is the
    canonical source, but imported symbols and typed C callables also carry the
    fact in their symbol/type metadata.  Falling back to the actual/fixed count
    keeps an otherwise valid call from silently entering a C varargs callee with
    AL=0 if one metadata copy is stale. }
  NeedsVarArgVectorMetadata := Binding.Variadic or
    (Length(G.PendingParameters) > FixedCount);
  if (ProcedureType >= 0) and (ProcedureType <= High(G.Symbols^.Types)) and
     (tfCVariadic in G.Symbols^.Types[ProcedureType].Flags) then
    NeedsVarArgVectorMetadata := True;
  if (not IndirectCall) and (Instr.SymbolId >= 0) and
     (Instr.SymbolId <= High(G.Symbols^.Symbols)) and
     (sfVariadic in G.Symbols^.Symbols[Instr.SymbolId].Flags) then
    NeedsVarArgVectorMetadata := True;

  ReturnType := G.Symbols^.Types[ProcedureType].ReturnType;
  ReturnLayout := ClassifyCABIType(G, ReturnType);
  NeedsReturnStorage := IsCRecordType(G, ReturnType);
  GPCount := Ord(NeedsReturnStorage and ReturnLayout.Memory); { hidden sret in RDI }
  SSECount := 0;
  StackUsed := 0;
  SetLength(Args, Length(G.PendingParameters));

  for I := 0 to High(Args) do
  begin
    Args[I] := Default(TForeignArgLocation);
    Args[I].RegisterIndex[0] := -1;
    Args[I].RegisterIndex[1] := -1;
    Args[I].StackOffset := -1;
    Args[I].ValueId := G.PendingParameters[I];
    if (Args[I].ValueId >= 0) and
       (Args[I].ValueId <= High(G.ProgramIR^.Values)) then
      SourceType := G.ProgramIR^.Values[Args[I].ValueId].TypeId
    else
      SourceType := FSIM_TYPE_INVALID;
    Args[I].SourceType := SourceType;
    Args[I].IsVariadic := I >= FixedCount;
    if (I < FixedCount) and (ProcedureType >= 0) and
       (ProcedureType <= High(G.Symbols^.Types)) then
      ABIType := G.Symbols^.Parameters[
        G.Symbols^.Types[ProcedureType].ParameterStart + I].TypeId
    else
    begin
      ABIType := SourceType;
      if ABIType = FSIM_TYPE_C_FLOAT then ABIType := FSIM_TYPE_C_DOUBLE
      else if IsCIntegerType(G, ABIType) and
              (G.Symbols^.Types[ABIType].Size < 4) then
        ABIType := FSIM_TYPE_C_INT;
    end;
    Args[I].ABIType := ABIType;
    Args[I].Layout := ClassifyCABIType(G, ABIType);

    NeedGP := 0;
    NeedSSE := 0;
    if not Args[I].Layout.Memory then
      for J := 0 to Args[I].Layout.PartCount - 1 do
        if Args[I].Layout.Classes[J] = facSSE then Inc(NeedSSE)
        else if Args[I].Layout.Classes[J] = facInteger then Inc(NeedGP);
    if Args[I].Layout.Memory or (GPCount + NeedGP > 6) or
       (SSECount + NeedSSE > 8) then
    begin
      AlignValue := Args[I].Layout.Alignment;
      if AlignValue < 8 then AlignValue := 8;
      if AlignValue > 16 then AlignValue := 16;
      StackUsed := Int32(AlignUp(QWord(StackUsed), AlignValue));
      Args[I].StackOffset := StackUsed;
      Inc(StackUsed, Int32(AlignUp(Args[I].Layout.Size, 8)));
    end
    else
    begin
      GPProbe := GPCount;
      SSEProbe := SSECount;
      for J := 0 to Args[I].Layout.PartCount - 1 do
        if Args[I].Layout.Classes[J] = facSSE then
        begin
          Args[I].RegisterIndex[J] := SSEProbe;
          Inc(SSEProbe);
        end
        else if Args[I].Layout.Classes[J] = facInteger then
        begin
          Args[I].RegisterIndex[J] := GPProbe;
          Inc(GPProbe);
        end;
      GPCount := GPProbe;
      SSECount := SSEProbe;
    end;
  end;

  ReturnPointerOffset := -1;
  if NeedsReturnStorage then
  begin
    X64MovRegImm64(G.Assembler, xrRDI, ReturnLayout.Size);
    X64Call(G.Assembler, G.RuntimeLabels.Allocate);
    ReturnPointerOffset := Int32(AlignUp(QWord(StackUsed), 8));
    ReturnRAXOffset := ReturnPointerOffset + 8;
    ReturnRDXOffset := ReturnPointerOffset + 16;
    StackBytes := Int32(AlignUp(QWord(ReturnPointerOffset + 24), 16));
  end
  else
    StackBytes := Int32(AlignUp(QWord(StackUsed), 16));
  if StackBytes > 0 then X64SubRegImm32(G.Assembler, xrRSP, StackBytes);
  if NeedsReturnStorage then
    X64MovMemBaseDispReg(G.Assembler, xrRSP, ReturnPointerOffset, xrRAX);

  { Materialize stack arguments before ABI registers. }
  for I := 0 to High(Args) do
    if Args[I].StackOffset >= 0 then
    begin
      if IsCRecordType(G, Args[I].ABIType) then
      begin
        LoadValue(G, Args[I].ValueId, xrR9);
        X64LeaRegBaseDisp(G.Assembler, xrR8, xrRSP, Args[I].StackOffset);
        EmitCopyBytes(G, xrR8, xrR9, Args[I].Layout.Size);
      end
      else if Args[I].Layout.PartCount > 0 then
      begin
        if Args[I].Layout.Classes[0] = facSSE then
        begin
          LoadForeignSSEArgument(G, Args[I], xrXMM0);
          X64MovQRegXMM(G.Assembler, xrRAX, xrXMM0);
          if IsCFloatType(G, Args[I].ABIType) and not Args[I].IsVariadic then
            X64MovMemBaseDispReg32(G.Assembler, xrRSP,
              Args[I].StackOffset, xrRAX)
          else
            X64MovMemBaseDispReg(G.Assembler, xrRSP,
              Args[I].StackOffset, xrRAX);
        end
        else
        begin
          LoadForeignIntegerArgument(G, Args[I], xrRAX);
          X64MovMemBaseDispReg(G.Assembler, xrRSP,
            Args[I].StackOffset, xrRAX);
        end;
      end;
    end;

  { Register aggregates are loaded from their address one eightbyte at a time. }
  for I := 0 to High(Args) do
    if Args[I].StackOffset < 0 then
    begin
      if IsCRecordType(G, Args[I].ABIType) then
      begin
        LoadValue(G, Args[I].ValueId, xrR10);
        for J := 0 to Args[I].Layout.PartCount - 1 do
        begin
          PartOffset := UInt32(J * 8);
          PartBytes := Args[I].Layout.Size - PartOffset;
          if PartBytes > 8 then PartBytes := 8;
          if Args[I].Layout.Classes[J] = facSSE then
          begin
            LoadAggregateChunk(G, xrR10, PartOffset, PartBytes, xrRAX);
            Reg := CSSEArgumentRegister(Args[I].RegisterIndex[J]);
            X64MovQXMMReg(G.Assembler, Reg, xrRAX);
          end
          else
          begin
            Reg := CIntegerArgumentRegister(Args[I].RegisterIndex[J]);
            LoadAggregateChunk(G, xrR10, PartOffset, PartBytes, Reg);
          end;
        end;
      end
      else if Args[I].Layout.PartCount > 0 then
      begin
        if Args[I].Layout.Classes[0] = facSSE then
        begin
          Reg := CSSEArgumentRegister(Args[I].RegisterIndex[0]);
          LoadForeignSSEArgument(G, Args[I], Reg);
        end
        else
        begin
          Reg := CIntegerArgumentRegister(Args[I].RegisterIndex[0]);
          LoadForeignIntegerArgument(G, Args[I], Reg);
        end;
      end;
    end;

  if NeedsReturnStorage and ReturnLayout.Memory then
    X64MovRegMemBaseDisp(G.Assembler, xrRDI, xrRSP, ReturnPointerOffset);

  { Load an indirect target before touching RAX: LoadValue is allowed to use
    caller-saved scratch internally.  SysV varargs use AL for the number (or a
    legal upper bound) of vector argument registers in use.  We already know
    the exact allocator count here, so publish that rather than pessimistically
    forcing every vector-bearing call to 8. }
  if IndirectCall then
    LoadValue(G, Instr.A, xrR11);
  if NeedsVarArgVectorMetadata then
    X64MovRegImm32(G.Assembler, xrRAX, DWord(SSECount));
  if IndirectCall then
    X64CallReg(G.Assembler, xrR11)
  else
    AppendForeignCallFixup(G, ForeignIndex);

  if NeedsReturnStorage then
  begin
    X64MovMemBaseDispReg(G.Assembler, xrRSP, ReturnRAXOffset, xrRAX);
    X64MovMemBaseDispReg(G.Assembler, xrRSP, ReturnRDXOffset, xrRDX);
    X64MovRegMemBaseDisp(G.Assembler, xrR10, xrRSP, ReturnPointerOffset);
    if not ReturnLayout.Memory then
    begin
      ReturnGP := 0;
      ReturnSSE := 0;
      for J := 0 to ReturnLayout.PartCount - 1 do
      begin
        PartOffset := UInt32(J * 8);
        PartBytes := ReturnLayout.Size - PartOffset;
        if PartBytes > 8 then PartBytes := 8;
        if ReturnLayout.Classes[J] = facSSE then
        begin
          Reg := CSSEArgumentRegister(ReturnSSE);
          X64MovQRegXMM(G.Assembler, xrRAX, Reg);
          Inc(ReturnSSE);
        end
        else
        begin
          if ReturnGP = 0 then
            X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRSP, ReturnRAXOffset)
          else
            X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRSP, ReturnRDXOffset);
          Inc(ReturnGP);
        end;
        StoreAggregateChunk(G, xrR10, PartOffset, PartBytes, xrRAX);
      end;
    end;
    X64MovRegReg(G.Assembler, xrRAX, xrR10);
    if StackBytes > 0 then X64AddRegImm32(G.Assembler, xrRSP, StackBytes);
    if Instr.Dst >= 0 then StoreValue(G, Instr.Dst, xrRAX);
    Exit;
  end;

  if StackBytes > 0 then X64AddRegImm32(G.Assembler, xrRSP, StackBytes);
  if Instr.Dst >= 0 then
  begin
    ABIType := Instr.TypeId;
    if IsCRealType(G, ABIType) then
    begin
      if IsCFloatType(G, ABIType) then
        X64CvtSS2SD(G.Assembler, xrXMM0, xrXMM0);
      X64MovQRegXMM(G.Assembler, xrRAX, xrXMM0);
    end
    else
      NormalizeCInteger(G, xrRAX, ABIType);
    StoreValue(G, Instr.Dst, xrRAX);
  end;
end;

function ArrayTypeFromValue(const G: TCodeGenerator;
  ValueId: Int32): Int32;
begin
  if (ValueId < 0) or (ValueId > High(G.ProgramIR^.Values)) then
    Exit(FSIM_TYPE_INVALID);
  Result := G.ProgramIR^.Values[ValueId].TypeId;
  if (Result < 0) or (Result > High(G.Symbols^.Types)) or
     (G.Symbols^.Types[Result].Kind <> tyArray) then
    Result := FSIM_TYPE_INVALID;
end;

procedure EmitArrayAddress(var G: TCodeGenerator; BaseValue, IndexValue: Int32;
  out ElementType: Int32);
var
  ArrayType: Int32;
  Info: TTypeInfo;
  ElementSize: UInt32;
begin
  ArrayType := ArrayTypeFromValue(G, BaseValue);
  if ArrayType = FSIM_TYPE_INVALID then
  begin
    AddError(G.Diagnostics^, dcBackendUnsupported,
      G.ProgramIR^.Instructions[G.CurrentInstruction].Span,
      'array operation has no concrete array type');
    X64XorRegReg(G.Assembler, xrRAX, xrRAX);
    ElementType := FSIM_TYPE_INVALID;
    Exit;
  end;
  Info := G.Symbols^.Types[ArrayType];
  ElementType := Info.ElementType;
  LoadValue(G, BaseValue, xrRAX);
  if (tfRuntimeBound in Info.Flags) and G.Options^.NullChecks then
  begin
    X64MovRegReg(G.Assembler, xrRDI, xrRAX);
    X64Call(G.Assembler, G.RuntimeLabels.NullCheck);
  end;
  LoadValue(G, IndexValue, xrRCX);
  if tfRuntimeBound in Info.Flags then
  begin
    if G.Options^.BoundsChecks then
    begin
      X64MovRegMemBaseDisp(G.Assembler, xrRDX, xrRAX, 8);
      X64CmpRegReg(G.Assembler, xrRCX, xrRDX);
      X64JumpCondition(G.Assembler, xcLess, G.RuntimeLabels.PanicBounds);
      X64MovRegMemBaseDisp(G.Assembler, xrRDX, xrRAX, 16);
      X64CmpRegReg(G.Assembler, xrRCX, xrRDX);
      X64JumpCondition(G.Assembler, xcGreater, G.RuntimeLabels.PanicBounds);
    end;
    X64MovRegMemBaseDisp(G.Assembler, xrRDX, xrRAX, 8);
    X64SubRegReg(G.Assembler, xrRCX, xrRDX);
    X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRAX, 0);
  end
  else
  begin
    if G.Options^.BoundsChecks then
    begin
      X64MovRegImm64(G.Assembler, xrRDX, QWord(Info.LowerBound));
      X64CmpRegReg(G.Assembler, xrRCX, xrRDX);
      X64JumpCondition(G.Assembler, xcLess, G.RuntimeLabels.PanicBounds);
      X64MovRegImm64(G.Assembler, xrRDX, QWord(Info.UpperBound));
      X64CmpRegReg(G.Assembler, xrRCX, xrRDX);
      X64JumpCondition(G.Assembler, xcGreater, G.RuntimeLabels.PanicBounds);
    end;
    if Info.LowerBound <> 0 then
    begin
      X64MovRegImm64(G.Assembler, xrRDX, QWord(Info.LowerBound));
      X64SubRegReg(G.Assembler, xrRCX, xrRDX);
    end;
  end;
  ElementSize := RuntimeTypeStorageSize(G.Symbols^, ElementType);
  if ElementSize > 1 then
    X64IMulRegRegImm32(G.Assembler, xrRCX, xrRCX, Int32(ElementSize));
  X64AddRegReg(G.Assembler, xrRAX, xrRCX);
end;

procedure EmitLoadElement(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  ElementType: Int32;
begin
  EmitArrayAddress(G, Instr.A, Instr.B, ElementType);
  if ElementType <> FSIM_TYPE_INVALID then
    EmitLoadAtAddress(G, xrRAX, ElementType, xrRAX);
  StoreValue(G, Instr.Dst, xrRAX);
end;

procedure EmitStoreElement(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  ElementType: Int32;
begin
  EmitArrayAddress(G, Instr.A, Instr.B, ElementType);
  if ElementType <> FSIM_TYPE_INVALID then
  begin
    LoadValue(G, Instr.C, xrRCX);
    if (G.Options^.Dialect = fdSimula67) and
       (ElementType = FSIM_TYPE_TEXT) and (Instr.Aux = 0) then
      EmitS67TextAssignAtAddress(G, xrRAX, xrRCX)
    else
      EmitStoreAtAddress(G, xrRAX, ElementType, xrRCX);
  end;
end;

function NativeMemberOffset(const G: TCodeGenerator; ClassSymbol: Int32;
  const Name: RawByteString): Int32;
var
  SymbolId: Int32;
begin
  SymbolId := SymLookupMember(G.Symbols^, ClassSymbol, Name);
  if SymbolId < 0 then Exit(0);
  Result := FieldOffset(G, SymbolId);
end;

procedure EmitDetachLink(var G: TCodeGenerator; LinkClass, HeadClass: Int32);
var
  SucOffset, PredOffset, HeadOffset, FirstOffset, LastOffset,
  CardinalOffset: Int32;
  HasPred, HasSuc, CardinalDone, DoneLabel: Int32;
begin
  SucOffset := NativeMemberOffset(G, LinkClass, '$suc');
  PredOffset := NativeMemberOffset(G, LinkClass, '$pred');
  HeadOffset := NativeMemberOffset(G, LinkClass, '$head');
  FirstOffset := NativeMemberOffset(G, HeadClass, '$first');
  LastOffset := NativeMemberOffset(G, HeadClass, '$last');
  CardinalOffset := NativeMemberOffset(G, HeadClass, '$cardinal');
  HasPred := X64NewLabel(G.Assembler);
  HasSuc := X64NewLabel(G.Assembler);
  CardinalDone := X64NewLabel(G.Assembler);
  DoneLabel := X64NewLabel(G.Assembler);
  X64MovRegMemBaseDisp(G.Assembler, xrR8, xrRDI, HeadOffset);
  X64TestRegReg(G.Assembler, xrR8, xrR8);
  X64JumpCondition(G.Assembler, xcEqual, DoneLabel);
  X64MovRegMemBaseDisp(G.Assembler, xrR9, xrRDI, PredOffset);
  X64MovRegMemBaseDisp(G.Assembler, xrR10, xrRDI, SucOffset);
  X64TestRegReg(G.Assembler, xrR9, xrR9);
  X64JumpCondition(G.Assembler, xcNotEqual, HasPred);
  X64MovMemBaseDispReg(G.Assembler, xrR8, FirstOffset, xrR10);
  X64Jump(G.Assembler, HasSuc);
  X64BindLabel(G.Assembler, HasPred);
  X64MovMemBaseDispReg(G.Assembler, xrR9, SucOffset, xrR10);
  X64BindLabel(G.Assembler, HasSuc);
  X64TestRegReg(G.Assembler, xrR10, xrR10);
  HasSuc := X64NewLabel(G.Assembler);
  X64JumpCondition(G.Assembler, xcNotEqual, HasSuc);
  X64MovMemBaseDispReg(G.Assembler, xrR8, LastOffset, xrR9);
  X64Jump(G.Assembler, CardinalDone);
  X64BindLabel(G.Assembler, HasSuc);
  X64MovMemBaseDispReg(G.Assembler, xrR10, PredOffset, xrR9);
  X64BindLabel(G.Assembler, CardinalDone);
  X64MovRegMemBaseDisp(G.Assembler, xrR11, xrR8, CardinalOffset);
  X64TestRegReg(G.Assembler, xrR11, xrR11);
  CardinalDone := X64NewLabel(G.Assembler);
  X64JumpCondition(G.Assembler, xcEqual, CardinalDone);
  X64SubRegImm32(G.Assembler, xrR11, 1);
  X64MovMemBaseDispReg(G.Assembler, xrR8, CardinalOffset, xrR11);
  X64BindLabel(G.Assembler, CardinalDone);
  X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  X64MovMemBaseDispReg(G.Assembler, xrRDI, SucOffset, xrRAX);
  X64MovMemBaseDispReg(G.Assembler, xrRDI, PredOffset, xrRAX);
  X64MovMemBaseDispReg(G.Assembler, xrRDI, HeadOffset, xrRAX);
  X64BindLabel(G.Assembler, DoneLabel);
end;

function EmitNativeSimulaMethod(var G: TCodeGenerator;
  SymbolId: Int32): Boolean;
var
  OwnerSymbol, LinkClass, HeadClass, ProcessClass, SimulationClass: Int32;
  MethodName, OwnerName: RawByteString;
  SucOffset, PredOffset, HeadOffset, FirstOffset, LastOffset,
  CardinalOffset, StateOffset, TerminatedOffset, EventTimeOffset,
  CurrentTimeOffset, CurrentProcessOffset: Int32;
  NonEmptyLabel, DoneLabel, AbortLabel, LoopLabel, HasNeighborLabel: Int32;
begin
  Result := False;
  if (SymbolId < 0) or (SymbolId > High(G.Symbols^.Symbols)) then Exit;
  OwnerSymbol := G.Symbols^.Symbols[SymbolId].OwnerSymbol;
  if OwnerSymbol < 0 then Exit;
  MethodName := LowerASCII(SymName(G.Symbols^, SymbolId));
  OwnerName := LowerASCII(SymName(G.Symbols^, OwnerSymbol));
  LinkClass := SymLookupClass(G.Symbols^, 'link');
  HeadClass := SymLookupClass(G.Symbols^, 'head');
  ProcessClass := SymLookupClass(G.Symbols^, 'process');
  SimulationClass := SymLookupClass(G.Symbols^, 'simulation');

  if G.Options^.Dialect = fdSimula67 then
  begin
    if OwnerName = 'infile' then
    begin
      if MethodName = 'inimage' then
        X64Call(G.Assembler, G.RuntimeLabels.S67.InImage)
      else if MethodName = 'inchar' then
        X64Call(G.Assembler, G.RuntimeLabels.S67.InChar)
      else if MethodName = 'inint' then
        X64Call(G.Assembler, G.RuntimeLabels.S67.InInt)
      else if MethodName = 'inreal' then
        X64Call(G.Assembler, G.RuntimeLabels.S67.InReal)
      else if MethodName = 'infrac' then
        X64Call(G.Assembler, G.RuntimeLabels.S67.InFrac)
      else if MethodName = 'intext' then
        X64Call(G.Assembler, G.RuntimeLabels.S67.InText)
      else if MethodName = 'lastitem' then
        X64Call(G.Assembler, G.RuntimeLabels.S67.LastItem)
      else if MethodName = 'endfile' then
        X64Call(G.Assembler, G.RuntimeLabels.S67.EndFile)
      else
        Exit(False);
      Exit(True);
    end;

    if OwnerName = 'outfile' then
    begin
      if MethodName = 'outimage' then
        X64Call(G.Assembler, G.RuntimeLabels.S67.OutImage)
      else if MethodName = 'outchar' then
        X64Call(G.Assembler, G.RuntimeLabels.S67.OutChar)
      else if MethodName = 'outtext' then
        X64Call(G.Assembler, G.RuntimeLabels.S67.OutText)
      else if MethodName = 'field' then
        X64Call(G.Assembler, G.RuntimeLabels.S67.Field)
      else if MethodName = 'outint' then
        X64Call(G.Assembler, G.RuntimeLabels.S67.OutInt)
      else if MethodName = 'outfix' then
        X64Call(G.Assembler, G.RuntimeLabels.S67.OutFix)
      else if MethodName = 'outreal' then
        X64Call(G.Assembler, G.RuntimeLabels.S67.OutReal)
      else if MethodName = 'outfrac' then
        X64Call(G.Assembler, G.RuntimeLabels.S67.OutFrac)
      else
        Exit(False);
      Exit(True);
    end;
  end;

  if OwnerName = 'link' then
  begin
    SucOffset := NativeMemberOffset(G, LinkClass, '$suc');
    PredOffset := NativeMemberOffset(G, LinkClass, '$pred');
    HeadOffset := NativeMemberOffset(G, LinkClass, '$head');
    if MethodName = 'suc' then
      X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, SucOffset)
    else if MethodName = 'pred' then
      X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, PredOffset)
    else if MethodName = 'out' then
    begin
      EmitDetachLink(G, LinkClass, HeadClass);
      X64XorRegReg(G.Assembler, xrRAX, xrRAX);
    end
    else if MethodName = 'into' then
    begin
      if G.Options^.NullChecks then
      begin
        X64MovRegReg(G.Assembler, xrR10, xrRDI);
        X64MovRegReg(G.Assembler, xrRDI, xrRSI);
        X64Call(G.Assembler, G.RuntimeLabels.NullCheck);
        X64MovRegReg(G.Assembler, xrRDI, xrR10);
      end;
      EmitDetachLink(G, LinkClass, HeadClass);
      FirstOffset := NativeMemberOffset(G, HeadClass, '$first');
      LastOffset := NativeMemberOffset(G, HeadClass, '$last');
      CardinalOffset := NativeMemberOffset(G, HeadClass, '$cardinal');
      X64MovRegMemBaseDisp(G.Assembler, xrR8, xrRSI, LastOffset);
      NonEmptyLabel := X64NewLabel(G.Assembler);
      DoneLabel := X64NewLabel(G.Assembler);
      X64TestRegReg(G.Assembler, xrR8, xrR8);
      X64JumpCondition(G.Assembler, xcNotEqual, NonEmptyLabel);
      X64MovMemBaseDispReg(G.Assembler, xrRSI, FirstOffset, xrRDI);
      X64Jump(G.Assembler, DoneLabel);
      X64BindLabel(G.Assembler, NonEmptyLabel);
      X64MovMemBaseDispReg(G.Assembler, xrR8, SucOffset, xrRDI);
      X64BindLabel(G.Assembler, DoneLabel);
      X64MovMemBaseDispReg(G.Assembler, xrRDI, PredOffset, xrR8);
      X64XorRegReg(G.Assembler, xrRAX, xrRAX);
      X64MovMemBaseDispReg(G.Assembler, xrRDI, SucOffset, xrRAX);
      X64MovMemBaseDispReg(G.Assembler, xrRDI, HeadOffset, xrRSI);
      X64MovMemBaseDispReg(G.Assembler, xrRSI, LastOffset, xrRDI);
      X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRSI, CardinalOffset);
      X64AddRegImm32(G.Assembler, xrRAX, 1);
      X64MovMemBaseDispReg(G.Assembler, xrRSI, CardinalOffset, xrRAX);
      X64XorRegReg(G.Assembler, xrRAX, xrRAX);
    end
    else if (MethodName = 'follow') or (MethodName = 'precede') then
    begin
      EmitDetachLink(G, LinkClass, HeadClass);
      X64TestRegReg(G.Assembler, xrRSI, xrRSI);
      DoneLabel := X64NewLabel(G.Assembler);
      AbortLabel := X64NewLabel(G.Assembler);
      X64JumpCondition(G.Assembler, xcEqual, AbortLabel);
      X64MovRegMemBaseDisp(G.Assembler, xrR8, xrRSI, HeadOffset);
      X64TestRegReg(G.Assembler, xrR8, xrR8);
      X64JumpCondition(G.Assembler, xcEqual, AbortLabel);
      CardinalOffset := NativeMemberOffset(G, HeadClass, '$cardinal');
      if MethodName = 'follow' then
      begin
        X64MovRegMemBaseDisp(G.Assembler, xrR9, xrRSI, SucOffset);
        X64MovMemBaseDispReg(G.Assembler, xrRDI, PredOffset, xrRSI);
        X64MovMemBaseDispReg(G.Assembler, xrRDI, SucOffset, xrR9);
        X64MovMemBaseDispReg(G.Assembler, xrRSI, SucOffset, xrRDI);
        HasNeighborLabel := X64NewLabel(G.Assembler);
        X64TestRegReg(G.Assembler, xrR9, xrR9);
        X64JumpCondition(G.Assembler, xcNotEqual, HasNeighborLabel);
        LastOffset := NativeMemberOffset(G, HeadClass, '$last');
        X64MovMemBaseDispReg(G.Assembler, xrR8, LastOffset, xrRDI);
        X64Jump(G.Assembler, DoneLabel);
        X64BindLabel(G.Assembler, HasNeighborLabel);
        X64MovMemBaseDispReg(G.Assembler, xrR9, PredOffset, xrRDI);
      end
      else
      begin
        X64MovRegMemBaseDisp(G.Assembler, xrR9, xrRSI, PredOffset);
        X64MovMemBaseDispReg(G.Assembler, xrRDI, SucOffset, xrRSI);
        X64MovMemBaseDispReg(G.Assembler, xrRDI, PredOffset, xrR9);
        X64MovMemBaseDispReg(G.Assembler, xrRSI, PredOffset, xrRDI);
        HasNeighborLabel := X64NewLabel(G.Assembler);
        X64TestRegReg(G.Assembler, xrR9, xrR9);
        X64JumpCondition(G.Assembler, xcNotEqual, HasNeighborLabel);
        FirstOffset := NativeMemberOffset(G, HeadClass, '$first');
        X64MovMemBaseDispReg(G.Assembler, xrR8, FirstOffset, xrRDI);
        X64Jump(G.Assembler, DoneLabel);
        X64BindLabel(G.Assembler, HasNeighborLabel);
        X64MovMemBaseDispReg(G.Assembler, xrR9, SucOffset, xrRDI);
      end;
      X64BindLabel(G.Assembler, DoneLabel);
      X64MovMemBaseDispReg(G.Assembler, xrRDI, HeadOffset, xrR8);
      X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrR8, CardinalOffset);
      X64AddRegImm32(G.Assembler, xrRAX, 1);
      X64MovMemBaseDispReg(G.Assembler, xrR8, CardinalOffset, xrRAX);
      X64BindLabel(G.Assembler, AbortLabel);
      X64XorRegReg(G.Assembler, xrRAX, xrRAX);
    end
    else
      Exit;
    Exit(True);
  end;

  if OwnerName = 'head' then
  begin
    FirstOffset := NativeMemberOffset(G, HeadClass, '$first');
    LastOffset := NativeMemberOffset(G, HeadClass, '$last');
    CardinalOffset := NativeMemberOffset(G, HeadClass, '$cardinal');
    if MethodName = 'first' then
      X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, FirstOffset)
    else if MethodName = 'last' then
      X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, LastOffset)
    else if MethodName = 'cardinal' then
      X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, CardinalOffset)
    else if MethodName = 'empty' then
    begin
      X64MovRegMemBaseDisp(G.Assembler, xrRCX, xrRDI, FirstOffset);
      X64TestRegReg(G.Assembler, xrRCX, xrRCX);
      X64XorRegReg(G.Assembler, xrRAX, xrRAX);
      X64SetCondition8(G.Assembler, xcEqual, xrRAX);
    end
    else if MethodName = 'clear' then
    begin
      SucOffset := NativeMemberOffset(G, LinkClass, '$suc');
      PredOffset := NativeMemberOffset(G, LinkClass, '$pred');
      HeadOffset := NativeMemberOffset(G, LinkClass, '$head');
      LoopLabel := X64NewLabel(G.Assembler);
      DoneLabel := X64NewLabel(G.Assembler);
      X64MovRegMemBaseDisp(G.Assembler, xrR8, xrRDI, FirstOffset);
      X64BindLabel(G.Assembler, LoopLabel);
      X64TestRegReg(G.Assembler, xrR8, xrR8);
      X64JumpCondition(G.Assembler, xcEqual, DoneLabel);
      X64MovRegMemBaseDisp(G.Assembler, xrR9, xrR8, SucOffset);
      X64XorRegReg(G.Assembler, xrRAX, xrRAX);
      X64MovMemBaseDispReg(G.Assembler, xrR8, SucOffset, xrRAX);
      X64MovMemBaseDispReg(G.Assembler, xrR8, PredOffset, xrRAX);
      X64MovMemBaseDispReg(G.Assembler, xrR8, HeadOffset, xrRAX);
      X64MovRegReg(G.Assembler, xrR8, xrR9);
      X64Jump(G.Assembler, LoopLabel);
      X64BindLabel(G.Assembler, DoneLabel);
      X64XorRegReg(G.Assembler, xrRAX, xrRAX);
      X64MovMemBaseDispReg(G.Assembler, xrRDI, FirstOffset, xrRAX);
      X64MovMemBaseDispReg(G.Assembler, xrRDI, LastOffset, xrRAX);
      X64MovMemBaseDispReg(G.Assembler, xrRDI, CardinalOffset, xrRAX);
    end
    else
      Exit;
    Exit(True);
  end;

  if OwnerName = 'process' then
  begin
    StateOffset := NativeMemberOffset(G, ProcessClass, '$process_state');
    TerminatedOffset := NativeMemberOffset(G, ProcessClass, '$terminated');
    EventTimeOffset := NativeMemberOffset(G, ProcessClass, '$event_time');
    if MethodName = 'idle' then
    begin
      X64MovRegMemBaseDisp(G.Assembler, xrRCX, xrRDI, StateOffset);
      X64TestRegReg(G.Assembler, xrRCX, xrRCX);
      X64XorRegReg(G.Assembler, xrRAX, xrRAX);
      X64SetCondition8(G.Assembler, xcEqual, xrRAX);
    end
    else if MethodName = 'terminated' then
    begin
      X64XorRegReg(G.Assembler, xrRAX, xrRAX);
      X64MovRegMemBaseDisp8(G.Assembler, xrRAX, xrRDI, TerminatedOffset);
    end
    else if MethodName = 'evtime' then
      X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, EventTimeOffset)
    else if MethodName = 'nextev' then
    begin
      SucOffset := NativeMemberOffset(G, LinkClass, '$suc');
      X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, SucOffset);
    end
    else
      Exit;
    Exit(True);
  end;

  if OwnerName = 'simulation' then
  begin
    CurrentTimeOffset := NativeMemberOffset(G, SimulationClass, '$current_time');
    CurrentProcessOffset := NativeMemberOffset(G, SimulationClass, '$current_process');
    if MethodName = 'time' then
      X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, CurrentTimeOffset)
    else if MethodName = 'current' then
      X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, CurrentProcessOffset)
    else
      Exit;
    Exit(True);
  end;
end;

procedure EmitNativeHandleCheck(var G: TCodeGenerator;
  HandleReg: TX64Register);
begin
  if not G.Options^.NullChecks then Exit;
  X64TestRegReg(G.Assembler, HandleReg, HandleReg);
  X64JumpCondition(G.Assembler, xcEqual, G.RuntimeLabels.PanicNull);
end;

procedure EmitAtomicFetch(var G: TCodeGenerator; SubtractValue: Boolean);
var
  RetryLabel: Int32;
begin
  EmitNativeHandleCheck(G, xrRDI);
  RetryLabel := X64NewLabel(G.Assembler);
  X64BindLabel(G.Assembler, RetryLabel);
  X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, 0);
  X64MovRegReg(G.Assembler, xrRCX, xrRAX);
  if SubtractValue then
    X64SubRegReg(G.Assembler, xrRCX, xrRSI)
  else
    X64AddRegReg(G.Assembler, xrRCX, xrRSI);
  X64LockCmpXchgMemBaseDispReg(G.Assembler, xrRDI, 0, xrRCX);
  X64JumpCondition(G.Assembler, xcNotEqual, RetryLabel);
end;

procedure EmitSemaphoreWaitNative(var G: TCodeGenerator; TryOnly: Boolean);
var
  RetryLabel, WaitLabel, DoneLabel, FailedLabel: Int32;
begin
  EmitNativeHandleCheck(G, xrRDI);
  RetryLabel := X64NewLabel(G.Assembler);
  WaitLabel := X64NewLabel(G.Assembler);
  DoneLabel := X64NewLabel(G.Assembler);
  FailedLabel := X64NewLabel(G.Assembler);
  X64BindLabel(G.Assembler, RetryLabel);
  X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, 0);
  X64TestRegReg(G.Assembler, xrRAX, xrRAX);
  if TryOnly then
    X64JumpCondition(G.Assembler, xcEqual, FailedLabel)
  else
    X64JumpCondition(G.Assembler, xcEqual, WaitLabel);
  X64MovRegReg(G.Assembler, xrRCX, xrRAX);
  X64SubRegImm32(G.Assembler, xrRCX, 1);
  X64LockCmpXchgMemBaseDispReg(G.Assembler, xrRDI, 0, xrRCX);
  X64JumpCondition(G.Assembler, xcNotEqual, RetryLabel);
  if TryOnly then
    X64MovRegImm64(G.Assembler, xrRAX, 1)
  else
    X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  X64Jump(G.Assembler, DoneLabel);
  X64BindLabel(G.Assembler, WaitLabel);
  X64XorRegReg(G.Assembler, xrRDX, xrRDX);
  EmitFutexWait(G, xrRDI, xrRDX);
  X64Jump(G.Assembler, RetryLabel);
  X64BindLabel(G.Assembler, FailedLabel);
  X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  X64BindLabel(G.Assembler, DoneLabel);
end;

procedure EmitSemaphorePostNative(var G: TCodeGenerator);
var
  RetryLabel: Int32;
begin
  EmitNativeHandleCheck(G, xrRDI);
  RetryLabel := X64NewLabel(G.Assembler);
  X64BindLabel(G.Assembler, RetryLabel);
  X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, 0);
  X64MovRegReg(G.Assembler, xrRCX, xrRAX);
  X64AddRegImm32(G.Assembler, xrRCX, 1);
  X64LockCmpXchgMemBaseDispReg(G.Assembler, xrRDI, 0, xrRCX);
  X64JumpCondition(G.Assembler, xcNotEqual, RetryLabel);
  EmitFutexWakeOne(G, xrRDI);
  X64XorRegReg(G.Assembler, xrRAX, xrRAX);
end;

procedure EmitBarrierWaitNative(var G: TCodeGenerator);
var
  RetryArrival, Waiting, Leader, Done: Int32;
begin
  EmitNativeHandleCheck(G, xrRDI);
  RetryArrival := X64NewLabel(G.Assembler);
  Waiting := X64NewLabel(G.Assembler);
  Leader := X64NewLabel(G.Assembler);
  Done := X64NewLabel(G.Assembler);
  X64PushReg(G.Assembler, xrR12);
  X64PushReg(G.Assembler, xrR13);
  X64MovRegReg(G.Assembler, xrR12, xrRDI);
  X64MovRegMemBaseDisp(G.Assembler, xrRDX, xrR12, 0);
  X64CmpRegImm32(G.Assembler, xrRDX, 1);
  X64JumpCondition(G.Assembler, xcLess, G.RuntimeLabels.PanicThread);
  X64MovRegMemBaseDisp(G.Assembler, xrR13, xrR12, 16);
  X64BindLabel(G.Assembler, RetryArrival);
  X64LeaRegBaseDisp(G.Assembler, xrRDI, xrR12, 8);
  X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, 0);
  X64MovRegReg(G.Assembler, xrRCX, xrRAX);
  X64AddRegImm32(G.Assembler, xrRCX, 1);
  X64LockCmpXchgMemBaseDispReg(G.Assembler, xrRDI, 0, xrRCX);
  X64JumpCondition(G.Assembler, xcNotEqual, RetryArrival);
  X64MovRegMemBaseDisp(G.Assembler, xrRDX, xrR12, 0);
  X64CmpRegReg(G.Assembler, xrRCX, xrRDX);
  X64JumpCondition(G.Assembler, xcAboveEqual, Leader);

  X64BindLabel(G.Assembler, Waiting);
  X64LeaRegBaseDisp(G.Assembler, xrRDI, xrR12, 16);
  X64MovRegReg(G.Assembler, xrRDX, xrR13);
  EmitFutexWait(G, xrRDI, xrRDX);
  X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrR12, 16);
  X64CmpRegReg(G.Assembler, xrRAX, xrR13);
  X64JumpCondition(G.Assembler, xcEqual, Waiting);
  X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  X64Jump(G.Assembler, Done);

  X64BindLabel(G.Assembler, Leader);
  X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  X64MovMemBaseDispReg(G.Assembler, xrR12, 8, xrRAX);
  X64MovRegReg(G.Assembler, xrRCX, xrR13);
  X64AddRegImm32(G.Assembler, xrRCX, 1);
  X64MemoryFence(G.Assembler);
  X64MovMemBaseDispReg(G.Assembler, xrR12, 16, xrRCX);
  X64LeaRegBaseDisp(G.Assembler, xrRDI, xrR12, 16);
  EmitFutexWakeAll(G, xrRDI);
  X64MovRegImm64(G.Assembler, xrRAX, 1);

  X64BindLabel(G.Assembler, Done);
  X64PopReg(G.Assembler, xrR13);
  X64PopReg(G.Assembler, xrR12);
end;

procedure EmitConditionWaitNative(var G: TCodeGenerator);
var
  LockRetry, LockDone: Int32;
begin
  EmitNativeHandleCheck(G, xrRDI);
  EmitNativeHandleCheck(G, xrRSI);
  LockRetry := X64NewLabel(G.Assembler);
  LockDone := X64NewLabel(G.Assembler);
  X64PushReg(G.Assembler, xrR12);
  X64PushReg(G.Assembler, xrR13);
  X64PushReg(G.Assembler, xrR14);
  X64MovRegReg(G.Assembler, xrR12, xrRDI);
  X64MovRegReg(G.Assembler, xrR13, xrRSI);
  X64MovRegMemBaseDisp(G.Assembler, xrR14, xrR12, 0);
  X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  X64MovMemBaseDispReg(G.Assembler, xrR13, 0, xrRAX);
  EmitFutexWakeOne(G, xrR13);
  X64MovRegReg(G.Assembler, xrRDI, xrR12);
  X64MovRegReg(G.Assembler, xrRDX, xrR14);
  EmitFutexWait(G, xrRDI, xrRDX);

  X64BindLabel(G.Assembler, LockRetry);
  X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  X64MovRegImm64(G.Assembler, xrRCX, 1);
  X64LockCmpXchgMemBaseDispReg(G.Assembler, xrR13, 0, xrRCX);
  X64JumpCondition(G.Assembler, xcEqual, LockDone);
  X64MovRegImm64(G.Assembler, xrRDX, 1);
  EmitFutexWait(G, xrR13, xrRDX);
  X64Jump(G.Assembler, LockRetry);
  X64BindLabel(G.Assembler, LockDone);
  X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  X64PopReg(G.Assembler, xrR14);
  X64PopReg(G.Assembler, xrR13);
  X64PopReg(G.Assembler, xrR12);
end;

procedure EmitConditionWakeNative(var G: TCodeGenerator; WakeAll: Boolean);
var
  RetryLabel: Int32;
begin
  EmitNativeHandleCheck(G, xrRDI);
  RetryLabel := X64NewLabel(G.Assembler);
  X64BindLabel(G.Assembler, RetryLabel);
  X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, 0);
  X64MovRegReg(G.Assembler, xrRCX, xrRAX);
  X64AddRegImm32(G.Assembler, xrRCX, 1);
  X64LockCmpXchgMemBaseDispReg(G.Assembler, xrRDI, 0, xrRCX);
  X64JumpCondition(G.Assembler, xcNotEqual, RetryLabel);
  if WakeAll then EmitFutexWakeAll(G, xrRDI)
  else EmitFutexWakeOne(G, xrRDI);
  X64XorRegReg(G.Assembler, xrRAX, xrRAX);
end;

procedure EmitMonotonicNSNative(var G: TCodeGenerator);
var
  SuccessLabel: Int32;
begin
  SuccessLabel := X64NewLabel(G.Assembler);
  X64SubRegImm32(G.Assembler, xrRSP, 16);
  X64MovRegImm64(G.Assembler, xrRDI, 1); { CLOCK_MONOTONIC }
  X64MovRegReg(G.Assembler, xrRSI, xrRSP);
  X64MovRegImm64(G.Assembler, xrRAX, 228); { clock_gettime }
  X64Syscall(G.Assembler);
  X64TestRegReg(G.Assembler, xrRAX, xrRAX);
  X64JumpCondition(G.Assembler, xcEqual, SuccessLabel);
  X64AddRegImm32(G.Assembler, xrRSP, 16);
  X64Jump(G.Assembler, G.RuntimeLabels.PanicThread);
  X64BindLabel(G.Assembler, SuccessLabel);
  X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRSP, 0);
  X64IMulRegRegImm32(G.Assembler, xrRAX, xrRAX, 1000000000);
  X64MovRegMemBaseDisp(G.Assembler, xrRCX, xrRSP, 8);
  X64AddRegReg(G.Assembler, xrRAX, xrRCX);
  X64AddRegImm32(G.Assembler, xrRSP, 16);
end;

procedure EmitSleepNSNative(var G: TCodeGenerator);
var
  RetryLabel, DoneLabel: Int32;
begin
  RetryLabel := X64NewLabel(G.Assembler);
  DoneLabel := X64NewLabel(G.Assembler);
  X64CmpRegImm32(G.Assembler, xrRDI, 0);
  X64JumpCondition(G.Assembler, xcLess, G.RuntimeLabels.PanicThread);
  X64SubRegImm32(G.Assembler, xrRSP, 32);
  X64MovRegReg(G.Assembler, xrRAX, xrRDI);
  X64XorRegReg(G.Assembler, xrRDX, xrRDX);
  X64MovRegImm64(G.Assembler, xrR10, 1000000000);
  X64DivReg(G.Assembler, xrR10);
  X64MovMemBaseDispReg(G.Assembler, xrRSP, 0, xrRAX);
  X64MovMemBaseDispReg(G.Assembler, xrRSP, 8, xrRDX);
  X64BindLabel(G.Assembler, RetryLabel);
  X64MovRegReg(G.Assembler, xrRDI, xrRSP);
  X64LeaRegBaseDisp(G.Assembler, xrRSI, xrRSP, 16);
  X64MovRegImm64(G.Assembler, xrRAX, 35); { nanosleep }
  X64Syscall(G.Assembler);
  X64CmpRegImm32(G.Assembler, xrRAX, -4); { EINTR }
  X64JumpCondition(G.Assembler, xcNotEqual, DoneLabel);
  X64MovRegMemBaseDisp(G.Assembler, xrRCX, xrRSP, 16);
  X64MovMemBaseDispReg(G.Assembler, xrRSP, 0, xrRCX);
  X64MovRegMemBaseDisp(G.Assembler, xrRCX, xrRSP, 24);
  X64MovMemBaseDispReg(G.Assembler, xrRSP, 8, xrRCX);
  X64Jump(G.Assembler, RetryLabel);
  X64BindLabel(G.Assembler, DoneLabel);
  X64TestRegReg(G.Assembler, xrRAX, xrRAX);
  X64JumpCondition(G.Assembler, xcLess, G.RuntimeLabels.PanicThread);
  X64AddRegImm32(G.Assembler, xrRSP, 32);
  X64XorRegReg(G.Assembler, xrRAX, xrRAX);
end;

function EmitNativeFSimGlobal(var G: TCodeGenerator;
  SymbolId: Int32): Boolean;
var
  Name: RawByteString;
begin
  Result := False;
  if G.Options^.Dialect <> fdFSim then Exit;
  if (SymbolId < 0) or (SymbolId > High(G.Symbols^.Symbols)) then Exit;
  if G.Symbols^.Symbols[SymbolId].OwnerSymbol >= 0 then Exit;
  Name := SymName(G.Symbols^, SymbolId);

  if Name = 'os_argc' then
    X64Call(G.Assembler, G.RuntimeLabels.OS.ArgCount)
  else if Name = 'os_argv' then
    X64Call(G.Assembler, G.RuntimeLabels.OS.Argument)
  else if Name = 'os_dir_open' then
    X64Call(G.Assembler, G.RuntimeLabels.OS.DirOpen)
  else if Name = 'os_dir_open_at' then
    X64Call(G.Assembler, G.RuntimeLabels.OS.DirOpenAt)
  else if Name = 'os_dir_next' then
    X64Call(G.Assembler, G.RuntimeLabels.OS.DirNext)
  else if Name = 'os_dir_type' then
    X64Call(G.Assembler, G.RuntimeLabels.OS.DirType)
  else if Name = 'os_dir_close' then
    X64Call(G.Assembler, G.RuntimeLabels.OS.DirClose)
  else if Name = 'os_path_type' then
    X64Call(G.Assembler, G.RuntimeLabels.OS.PathType)
  else if Name = 'os_path_size' then
    X64Call(G.Assembler, G.RuntimeLabels.OS.PathSize)
  else if Name = 'os_path_join' then
    X64Call(G.Assembler, G.RuntimeLabels.OS.PathJoin)
  else if Name = 'os_path_basename' then
    X64Call(G.Assembler, G.RuntimeLabels.OS.PathBaseName)
  else if Name = 'os_write_path' then
    X64Call(G.Assembler, G.RuntimeLabels.OS.WritePath)
  else if Name = 'os_stderr_write' then
    X64Call(G.Assembler, G.RuntimeLabels.OS.StderrWrite)
  else if Name = 'gc_collect' then
    X64Call(G.Assembler, G.RuntimeLabels.GCCollect)
  else if Name = 'gc_pin' then
    X64Call(G.Assembler, G.RuntimeLabels.GCPin)
  else if Name = 'gc_unpin' then
    X64Call(G.Assembler, G.RuntimeLabels.GCUnpin)
  else if Name = 'gc_live_bytes' then
    X64Call(G.Assembler, G.RuntimeLabels.GCLiveBytes)
  else if Name = 'gc_reclaimed_bytes' then
    X64Call(G.Assembler, G.RuntimeLabels.GCReclaimedBytes)
  else if Name = 'gc_collection_count' then
    X64Call(G.Assembler, G.RuntimeLabels.GCCollectionCount)
  else if Name = 'gc_last_pause_ns' then
    X64Call(G.Assembler, G.RuntimeLabels.GCLastPauseNS)
  else if Name = 'gc_max_pause_ns' then
    X64Call(G.Assembler, G.RuntimeLabels.GCMaxPauseNS)
  else if Name = 'gc_total_pause_ns' then
    X64Call(G.Assembler, G.RuntimeLabels.GCTotalPauseNS)
  else if Name = 'atomic_load' then
  begin
    EmitNativeHandleCheck(G, xrRDI);
    X64MemoryFence(G.Assembler);
    X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, 0);
    X64MemoryFence(G.Assembler);
  end
  else if Name = 'atomic_store' then
  begin
    EmitNativeHandleCheck(G, xrRDI);
    X64MovRegReg(G.Assembler, xrRAX, xrRSI);
    X64XchgMemBaseDispReg(G.Assembler, xrRDI, 0, xrRAX);
    X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  end
  else if Name = 'atomic_exchange' then
  begin
    EmitNativeHandleCheck(G, xrRDI);
    X64MovRegReg(G.Assembler, xrRAX, xrRSI);
    X64XchgMemBaseDispReg(G.Assembler, xrRDI, 0, xrRAX);
  end
  else if Name = 'atomic_compare_exchange' then
  begin
    EmitNativeHandleCheck(G, xrRDI);
    X64MovRegReg(G.Assembler, xrRAX, xrRSI);
    X64LockCmpXchgMemBaseDispReg(G.Assembler, xrRDI, 0, xrRDX);
    X64MovRegImm64(G.Assembler, xrRCX, 0);
    X64SetCondition8(G.Assembler, xcEqual, xrRCX);
    X64MovRegReg(G.Assembler, xrRAX, xrRCX);
  end
  else if Name = 'atomic_fetch_add' then
    EmitAtomicFetch(G, False)
  else if Name = 'atomic_fetch_sub' then
    EmitAtomicFetch(G, True)
  else if Name = 'mutex_try_lock' then
  begin
    EmitNativeHandleCheck(G, xrRDI);
    X64XorRegReg(G.Assembler, xrRAX, xrRAX);
    X64MovRegImm64(G.Assembler, xrRCX, 1);
    X64LockCmpXchgMemBaseDispReg(G.Assembler, xrRDI, 0, xrRCX);
    X64MovRegImm64(G.Assembler, xrRCX, 0);
    X64SetCondition8(G.Assembler, xcEqual, xrRCX);
    X64MovRegReg(G.Assembler, xrRAX, xrRCX);
  end
  else if Name = 'semaphore_init' then
  begin
    EmitNativeHandleCheck(G, xrRDI);
    X64CmpRegImm32(G.Assembler, xrRSI, 0);
    X64JumpCondition(G.Assembler, xcLess, G.RuntimeLabels.PanicThread);
    X64MovRegReg(G.Assembler, xrRAX, xrRSI);
    X64XchgMemBaseDispReg(G.Assembler, xrRDI, 0, xrRAX);
    X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  end
  else if Name = 'semaphore_wait' then
    EmitSemaphoreWaitNative(G, False)
  else if Name = 'semaphore_try_wait' then
    EmitSemaphoreWaitNative(G, True)
  else if Name = 'semaphore_post' then
    EmitSemaphorePostNative(G)
  else if Name = 'barrier_init' then
  begin
    EmitNativeHandleCheck(G, xrRDI);
    X64CmpRegImm32(G.Assembler, xrRSI, 1);
    X64JumpCondition(G.Assembler, xcLess, G.RuntimeLabels.PanicThread);
    X64MovMemBaseDispReg(G.Assembler, xrRDI, 0, xrRSI);
    X64XorRegReg(G.Assembler, xrRAX, xrRAX);
    X64MovMemBaseDispReg(G.Assembler, xrRDI, 8, xrRAX);
    X64MovMemBaseDispReg(G.Assembler, xrRDI, 16, xrRAX);
  end
  else if Name = 'barrier_wait' then
    EmitBarrierWaitNative(G)
  else if Name = 'condition_wait' then
    EmitConditionWaitNative(G)
  else if Name = 'condition_signal' then
    EmitConditionWakeNative(G, False)
  else if Name = 'condition_broadcast' then
    EmitConditionWakeNative(G, True)
  else if Name = 'future_ready' then
  begin
    EmitNativeHandleCheck(G, xrRDI);
    X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, 0);
    X64CmpRegImm32(G.Assembler, xrRAX, FSIM_TASK_STATE_RUNNING);
    X64MovRegImm64(G.Assembler, xrRCX, 0);
    X64SetCondition8(G.Assembler, xcNotEqual, xrRCX);
    X64MovRegReg(G.Assembler, xrRAX, xrRCX);
  end
  else if Name = 'future_cancel_requested' then
  begin
    EmitNativeHandleCheck(G, xrRDI);
    X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, 48);
    X64TestRegReg(G.Assembler, xrRAX, xrRAX);
    X64MovRegImm64(G.Assembler, xrRCX, 0);
    X64SetCondition8(G.Assembler, xcNotEqual, xrRCX);
    X64MovRegReg(G.Assembler, xrRAX, xrRCX);
  end
  else if Name = 'future_state' then
  begin
    EmitNativeHandleCheck(G, xrRDI);
    X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, 0);
  end
  else if Name = 'future_thread_id' then
  begin
    EmitNativeHandleCheck(G, xrRDI);
    X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRDI, 16);
  end
  else if Name = 'thread_id' then
  begin
    X64MovRegImm64(G.Assembler, xrRAX, 186); { gettid }
    X64Syscall(G.Assembler);
  end
  else if Name = 'monotonic_ns' then
    EmitMonotonicNSNative(G)
  else if Name = 'sleep_ns' then
    EmitSleepNSNative(G)
  else
    Exit(False);
  Result := True;
end;

function EmitNativeSimula67Global(var G: TCodeGenerator;
  SymbolId: Int32): Boolean;
var
  Name: RawByteString;
  DoneLabel, LetterUpper, LetterDone, EntierDone, DivideOkay, ModDone,
  EpsilonFinite, EpsilonNonZero, EpsilonPositive, EpsilonDone: Int32;
begin
  Result := False;
  if G.Options^.Dialect <> fdSimula67 then Exit;
  if (SymbolId < 0) or (SymbolId > High(G.Symbols^.Symbols)) then Exit;
  if G.Symbols^.Symbols[SymbolId].OwnerSymbol >= 0 then Exit;
  Name := LowerASCII(SymName(G.Symbols^, SymbolId));

  if Name = 'sysin' then
    X64Call(G.Assembler, G.RuntimeLabels.S67.SysIn)
  else if Name = 'sysout' then
    X64Call(G.Assembler, G.RuntimeLabels.S67.SysOut)
  else if Name = 'blanks' then
    X64Call(G.Assembler, G.RuntimeLabels.S67.TextBlanks)
  else if Name = 'copy' then
    X64Call(G.Assembler, G.RuntimeLabels.S67.TextCopy)
  else if (Name = 'char') or (Name = 'isochar') then
  begin
    X64CmpRegImm32(G.Assembler, xrRDI, 0);
    X64JumpCondition(G.Assembler, xcLess, G.RuntimeLabels.PanicText);
    X64CmpRegImm32(G.Assembler, xrRDI, 255);
    X64JumpCondition(G.Assembler, xcGreater, G.RuntimeLabels.PanicText);
    X64MovRegReg(G.Assembler, xrRAX, xrRDI);
  end
  else if (Name = 'rank') or (Name = 'isorank') then
  begin
    X64MovRegReg(G.Assembler, xrRAX, xrRDI);
    X64AndRegImm32(G.Assembler, xrRAX, 255);
  end
  else if Name = 'digit' then
  begin
    DoneLabel := X64NewLabel(G.Assembler);
    X64XorRegReg(G.Assembler, xrRAX, xrRAX);
    X64CmpRegImm32(G.Assembler, xrRDI, Ord('0'));
    X64JumpCondition(G.Assembler, xcLess, DoneLabel);
    X64CmpRegImm32(G.Assembler, xrRDI, Ord('9'));
    X64SetCondition8(G.Assembler, xcLessEqual, xrRAX);
    X64BindLabel(G.Assembler, DoneLabel);
  end
  else if Name = 'letter' then
  begin
    LetterUpper := X64NewLabel(G.Assembler);
    LetterDone := X64NewLabel(G.Assembler);
    X64XorRegReg(G.Assembler, xrRAX, xrRAX);
    X64CmpRegImm32(G.Assembler, xrRDI, Ord('a'));
    X64JumpCondition(G.Assembler, xcLess, LetterUpper);
    X64CmpRegImm32(G.Assembler, xrRDI, Ord('z'));
    X64JumpCondition(G.Assembler, xcGreater, LetterUpper);
    X64MovRegImm64(G.Assembler, xrRAX, 1);
    X64Jump(G.Assembler, LetterDone);
    X64BindLabel(G.Assembler, LetterUpper);
    X64CmpRegImm32(G.Assembler, xrRDI, Ord('A'));
    X64JumpCondition(G.Assembler, xcLess, LetterDone);
    X64CmpRegImm32(G.Assembler, xrRDI, Ord('Z'));
    X64SetCondition8(G.Assembler, xcLessEqual, xrRAX);
    X64BindLabel(G.Assembler, LetterDone);
  end
  else if Name = 'lowten' then
    X64Call(G.Assembler, G.RuntimeLabels.S67.LowTen)
  else if Name = 'decimalmark' then
    X64Call(G.Assembler, G.RuntimeLabels.S67.DecimalMark)
  else if Name = 'upcase' then
    X64Call(G.Assembler, G.RuntimeLabels.S67.Upcase)
  else if Name = 'lowcase' then
    X64Call(G.Assembler, G.RuntimeLabels.S67.Lowcase)
  else if (Name = 'mod') or (Name = 'rem') then
  begin
    DivideOkay := X64NewLabel(G.Assembler);
    X64TestRegReg(G.Assembler, xrRSI, xrRSI);
    X64JumpCondition(G.Assembler, xcNotEqual, DivideOkay);
    X64Jump(G.Assembler, G.RuntimeLabels.PanicOverflow);
    X64BindLabel(G.Assembler, DivideOkay);
    X64MovRegReg(G.Assembler, xrRAX, xrRDI);
    X64CQO(G.Assembler);
    X64IDivReg(G.Assembler, xrRSI);
    X64MovRegReg(G.Assembler, xrRAX, xrRDX);
    if Name = 'mod' then
    begin
      ModDone := X64NewLabel(G.Assembler);
      X64TestRegReg(G.Assembler, xrRAX, xrRAX);
      X64JumpCondition(G.Assembler, xcEqual, ModDone);
      X64MovRegReg(G.Assembler, xrR8, xrRAX);
      X64XorRegReg(G.Assembler, xrR8, xrRSI);
      X64TestRegReg(G.Assembler, xrR8, xrR8);
      X64JumpCondition(G.Assembler, xcNotSign, ModDone);
      X64AddRegReg(G.Assembler, xrRAX, xrRSI);
      X64BindLabel(G.Assembler, ModDone);
    end;
  end
  else if Name = 'entier' then
  begin
    X64MovQXMMReg(G.Assembler, xrXMM0, xrRDI);
    X64CVTTSD2SI(G.Assembler, xrRAX, xrXMM0);
    X64CVTSI2SD(G.Assembler, xrXMM1, xrRAX);
    X64UComiSD(G.Assembler, xrXMM1, xrXMM0);
    EntierDone := X64NewLabel(G.Assembler);
    X64JumpCondition(G.Assembler, xcBelowEqual, EntierDone);
    X64SubRegImm32(G.Assembler, xrRAX, 1);
    X64BindLabel(G.Assembler, EntierDone);
  end
  else if (Name = 'addepsilon') or (Name = 'subepsilon') then
  begin
    { REAL is IEEE binary64 in the native ABI.  Move one representable value
      toward +infinity or -infinity without dragging libc into the runtime. }
    EpsilonFinite := X64NewLabel(G.Assembler);
    EpsilonNonZero := X64NewLabel(G.Assembler);
    EpsilonPositive := X64NewLabel(G.Assembler);
    EpsilonDone := X64NewLabel(G.Assembler);
    X64MovRegReg(G.Assembler, xrRAX, xrRDI);
    X64MovRegReg(G.Assembler, xrR8, xrRAX);
    X64MovRegImm64(G.Assembler, xrR9, QWord($7FF0000000000000));
    X64AndRegReg(G.Assembler, xrR8, xrR9);
    X64CmpRegReg(G.Assembler, xrR8, xrR9);
    X64JumpCondition(G.Assembler, xcNotEqual, EpsilonFinite);
    X64Jump(G.Assembler, EpsilonDone); { infinities and NaNs stay put }
    X64BindLabel(G.Assembler, EpsilonFinite);
    X64MovRegReg(G.Assembler, xrR8, xrRAX);
    X64MovRegImm64(G.Assembler, xrR9, QWord($7FFFFFFFFFFFFFFF));
    X64AndRegReg(G.Assembler, xrR8, xrR9);
    X64TestRegReg(G.Assembler, xrR8, xrR8);
    X64JumpCondition(G.Assembler, xcNotEqual, EpsilonNonZero);
    if Name = 'addepsilon' then
      X64MovRegImm64(G.Assembler, xrRAX, 1)
    else
      X64MovRegImm64(G.Assembler, xrRAX, QWord($8000000000000001));
    X64Jump(G.Assembler, EpsilonDone);
    X64BindLabel(G.Assembler, EpsilonNonZero);
    X64TestRegReg(G.Assembler, xrRAX, xrRAX);
    X64JumpCondition(G.Assembler, xcNotSign, EpsilonPositive);
    if Name = 'addepsilon' then
      X64SubRegImm32(G.Assembler, xrRAX, 1)
    else
      X64AddRegImm32(G.Assembler, xrRAX, 1);
    X64Jump(G.Assembler, EpsilonDone);
    X64BindLabel(G.Assembler, EpsilonPositive);
    if Name = 'addepsilon' then
      X64AddRegImm32(G.Assembler, xrRAX, 1)
    else
      X64SubRegImm32(G.Assembler, xrRAX, 1);
    X64BindLabel(G.Assembler, EpsilonDone);
  end
  else if Name = 'sqrt' then
    X64Call(G.Assembler, G.RuntimeLabels.S67.MathSqrt)
  else if Name = 'sin' then
    X64Call(G.Assembler, G.RuntimeLabels.S67.MathSin)
  else if Name = 'cos' then
    X64Call(G.Assembler, G.RuntimeLabels.S67.MathCos)
  else if Name = 'tan' then
    X64Call(G.Assembler, G.RuntimeLabels.S67.MathTan)
  else if Name = 'arctan' then
    X64Call(G.Assembler, G.RuntimeLabels.S67.MathArctan)
  else if Name = 'ln' then
    X64Call(G.Assembler, G.RuntimeLabels.S67.MathLn)
  else if Name = 'log10' then
    X64Call(G.Assembler, G.RuntimeLabels.S67.MathLog10)
  else if Name = 'exp' then
    X64Call(G.Assembler, G.RuntimeLabels.S67.MathExp)
  else
    Exit(False);
  Result := True;
end;

procedure EmitCallInstruction(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  FunctionId, ClassIndex, Slot, InternalStackBytes, SRetOffset: Int32;
  HasReceiver, HasSRet: Boolean;
begin
  HasReceiver := (Instr.A >= 0) and (Instr.Op <> irCallIndirect);
  if Instr.Op in [irCallForeign, irCallForeignIndirect] then
  begin
    EmitForeignCallInstruction(G, Instr);
    ClearPendingParameters(G);
    Exit;
  end;
  { R11 is deliberately not allocator-owned. Preserve an indirect target
    before argument materialisation; ABI argument setup is allowed to overwrite
    every normal call register and must not change where we jump. }
  if Instr.Op = irCallIndirect then
    LoadValue(G, Instr.A, xrR11);
  HasSRet := (Instr.Op in [irCall, irCallIndirect, irCallVirtual]) and
    IsRecordValueType(G, Instr.TypeId);
  SRetOffset := 0;
  if HasSRet and (Instr.Dst >= 0) and
     (Instr.Dst <= High(G.Layout.ValueAggregateOffsets)) then
    SRetOffset := G.Layout.ValueAggregateOffsets[Instr.Dst];
  InternalStackBytes := MaterializeCallArguments(G, Instr.A, HasReceiver,
    SRetOffset, HasSRet);
  if Instr.Op = irCallIndirect then
  begin
    if G.Options^.NullChecks then
    begin
      X64TestRegReg(G.Assembler, xrR11, xrR11);
      X64JumpCondition(G.Assembler, xcEqual, G.RuntimeLabels.PanicNull);
    end;
    X64CallReg(G.Assembler, xrR11);
  end
  else if Instr.Op = irCallVirtual then
  begin
    { MaterializeCallArguments already placed the receiver in RDI. Using that
      canonical ABI copy avoids reloading a register-allocation location after
      argument setup and keeps dispatch independent of allocator accidents. }
    if G.Options^.NullChecks then
    begin
      X64TestRegReg(G.Assembler, xrRDI, xrRDI);
      X64JumpCondition(G.Assembler, xcEqual, G.RuntimeLabels.PanicNull);
    end;
    X64MovRegReg(G.Assembler, xrRAX, xrRDI);
    X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRAX, 8);
    Slot := 0;
    if (Instr.SymbolId >= 0) and
       (Instr.SymbolId <= High(G.Symbols^.Symbols)) then
      Slot := G.Symbols^.Symbols[Instr.SymbolId].VMTSlot;
    X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRAX, Slot * 8);
    X64CallReg(G.Assembler, xrRAX);
  end
  else if Instr.Op = irCallNative then
  begin
    { Native declarations are resolved only to compiler-owned runtime entrypoints. }
    if not EmitNativeSimulaMethod(G, Instr.SymbolId) then
    begin
      if EmitNativeFSimGlobal(G, Instr.SymbolId) then
      begin
        { handled by the Free Simula runtime }
      end
      else if EmitNativeSimula67Global(G, Instr.SymbolId) then
      begin
        { handled by the strict Simula runtime }
      end
      else if (Instr.SymbolId >= 0) and
         ASCIIEqualFold(SymName(G.Symbols^, Instr.SymbolId), 'printinteger') then
        X64Call(G.Assembler, G.RuntimeLabels.PrintInteger)
      else if (Instr.SymbolId >= 0) and
         ASCIIEqualFold(SymName(G.Symbols^, Instr.SymbolId), 'printstring') then
        X64Call(G.Assembler, G.RuntimeLabels.PrintString)
      else
      begin
        AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
          'native declaration ''' + SymName(G.Symbols^, Instr.SymbolId) +
          ''' has no compiler-owned runtime implementation');
        X64Int3(G.Assembler);
      end;
    end;
  end
  else
  begin
    FunctionId := IR_INVALID_FUNCTION;
    if (Instr.SymbolId >= 0) and
       (Instr.SymbolId <= High(G.Layout.FunctionBySymbol)) then
      FunctionId := G.Layout.FunctionBySymbol[Instr.SymbolId];
    if FunctionId >= 0 then
      X64Call(G.Assembler, G.Layout.FunctionLabels[FunctionId])
    else
    begin
      ClassIndex := ClassIndexForSymbol(G, Instr.SymbolId);
      if ClassIndex >= 0 then
        X64Call(G.Assembler, G.RuntimeLabels.Allocate)
      else
      begin
        AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
          'call target has no native body or runtime implementation');
        X64Int3(G.Assembler);
      end;
    end;
  end;
  if InternalStackBytes > 0 then
    X64AddRegImm32(G.Assembler, xrRSP, InternalStackBytes);
  if Instr.Dst >= 0 then
    StoreValue(G, Instr.Dst, xrRAX);
  ClearPendingParameters(G);
end;

procedure EmitFunctionPrologue(var G: TCodeGenerator; FunctionId: Int32);
var
  Mask: UInt32;
  S, ParameterOrdinal, ABIShift: Int32;
  Reg: TX64Register;
  HasSRet: Boolean;

  procedure PushIfUsed(R: TX64Register);
  begin
    if (Mask and RegisterMaskBit(R)) <> 0 then
      X64PushReg(G.Assembler, R);
  end;

begin
  Mask := G.Layout.FunctionSavedMasks[FunctionId];
  X64PushReg(G.Assembler, xrRBP);
  X64MovRegReg(G.Assembler, xrRBP, xrRSP);
  { Keep compiler-owned frame slots directly below RBP and save callee-saved
    registers below that frame.  The old order pushed RBX/R12/... first, so
    spill slot [rbp-8] and the first saved register occupied the same bytes. }
  if G.Layout.FunctionStackAdjust[FunctionId] <> 0 then
    X64SubRegImm32(G.Assembler, xrRSP,
      G.Layout.FunctionStackAdjust[FunctionId]);
  PushIfUsed(xrRBX);
  PushIfUsed(xrR12);
  PushIfUsed(xrR13);
  PushIfUsed(xrR14);
  PushIfUsed(xrR15);

  HasSRet := G.Layout.FunctionSRetOffsets[FunctionId] > 0;
  ABIShift := Ord(HasSRet);
  if HasSRet then
    X64MovMemBaseDispReg(G.Assembler, xrRBP,
      -G.Layout.FunctionSRetOffsets[FunctionId], xrRDI);

  if G.Layout.FunctionReceiverOffsets[FunctionId] > 0 then
  begin
    Reg := ArgumentRegister(ABIShift);
    if Reg <> xrNone then
      X64MovMemBaseDispReg(G.Assembler, xrRBP,
        -G.Layout.FunctionReceiverOffsets[FunctionId], Reg)
    else
    begin
      X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRBP,
        16 + (ABIShift - 6) * 8);
      X64MovMemBaseDispReg(G.Assembler, xrRBP,
        -G.Layout.FunctionReceiverOffsets[FunctionId], xrRAX);
    end;
  end;

  for S := 0 to High(G.Symbols^.Symbols) do
    if (G.Symbols^.Symbols[S].Kind = skParameter) and
       ScopeOwnedByRoutine(G.Symbols^, G.Symbols^.Symbols[S].ScopeId,
         G.ProgramIR^.Functions[FunctionId].SymbolId) then
    begin
      ParameterOrdinal := G.Symbols^.Symbols[S].ParameterIndex + ABIShift;
      if iffMethod in G.ProgramIR^.Functions[FunctionId].Flags then
        Inc(ParameterOrdinal);
      Reg := ArgumentRegister(ParameterOrdinal);
      if (SymbolFrameOffset(G, S) > 0) then
      begin
        if Reg <> xrNone then
          X64MovRegReg(G.Assembler, xrRAX, Reg)
        else
          X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRBP,
            16 + (ParameterOrdinal - 6) * 8);
        { Do not use any SysV argument register as the address scratch here.
          Aggregate returns consume RDI for the hidden sret pointer, shifting
          user arguments onto RSI/RDX/RCX/... .  Using RDX as scratch while
          homing an earlier parameter destroyed a later argument before it had
          been saved (MakePair(a,b) returned garbage as a result).  R10 is
          caller-saved but is never an incoming argument register. }
        X64LeaRegBaseDisp(G.Assembler, xrR10, xrRBP,
          -SymbolFrameOffset(G, S));
        if IsRecordValueType(G, G.Symbols^.Symbols[S].TypeId) then
          EmitCopyBytes(G, xrR10, xrRAX,
            RuntimeTypeStorageSize(G.Symbols^, G.Symbols^.Symbols[S].TypeId))
        else
          { Parameter slots use the declared storage width.  Writing a full
            qword into a one-byte boolean/character slot at [rbp-1] overwrote
            the saved frame pointer and return address. }
          EmitStoreAtAddress(G, xrR10, G.Symbols^.Symbols[S].TypeId, xrRAX);
      end;
    end;
end;

procedure EmitFunctionEpilogue(var G: TCodeGenerator; FunctionId: Int32);
var
  Mask: UInt32;

  procedure PopIfUsed(R: TX64Register);
  begin
    if (Mask and RegisterMaskBit(R)) <> 0 then
      X64PopReg(G.Assembler, R);
  end;

begin
  Mask := G.Layout.FunctionSavedMasks[FunctionId];
  PopIfUsed(xrR15);
  PopIfUsed(xrR14);
  PopIfUsed(xrR13);
  PopIfUsed(xrR12);
  PopIfUsed(xrRBX);
  if G.Layout.FunctionStackAdjust[FunctionId] <> 0 then
    X64AddRegImm32(G.Assembler, xrRSP,
      G.Layout.FunctionStackAdjust[FunctionId]);
  X64PopReg(G.Assembler, xrRBP);
  X64Ret(G.Assembler);
end;

procedure EmitCriticalEnter(var G: TCodeGenerator);
var
  RetryLabel, WaitLabel, DoneLabel: Int32;
begin
  RetryLabel := X64NewLabel(G.Assembler);
  WaitLabel := X64NewLabel(G.Assembler);
  DoneLabel := X64NewLabel(G.Assembler);
  X64LeaRegRipWritable(G.Assembler, xrRDI, G.RuntimeData.CriticalLock, 0);
  X64BindLabel(G.Assembler, RetryLabel);
  X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  X64MovRegImm64(G.Assembler, xrRCX, 1);
  X64LockCmpXchgMemBaseDispReg(G.Assembler, xrRDI, 0, xrRCX);
  X64JumpCondition(G.Assembler, xcEqual, DoneLabel);
  X64BindLabel(G.Assembler, WaitLabel);
  X64MovRegImm64(G.Assembler, xrRDX, 1);
  EmitFutexWait(G, xrRDI, xrRDX);
  X64Jump(G.Assembler, RetryLabel);
  X64BindLabel(G.Assembler, DoneLabel);
  X64MemoryFence(G.Assembler);
end;

procedure EmitCriticalLeave(var G: TCodeGenerator);
begin
  X64MemoryFence(G.Assembler);
  X64LeaRegRipWritable(G.Assembler, xrRDI, G.RuntimeData.CriticalLock, 0);
  X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  X64XchgMemBaseDispReg(G.Assembler, xrRDI, 0, xrRAX);
  EmitFutexWakeOne(G, xrRDI);
end;

procedure EmitInstruction(var G: TCodeGenerator;
  const Instr: TIRInstruction);
var
  ClassIndex, TemporaryLabel: Int32;
begin
  if iifRemoved in Instr.Flags then Exit;
  case Instr.Op of
    irNop, irTryBegin, irTryEnd, irCatchBegin, irCatchEnd,
    irFinallyBegin, irFinallyEnd:
      X64Nop(G.Assembler);

    irDeferBegin:
      begin
        AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
          'defer requires scope-exit lowering and is not emitted as a no-op');
        X64Int3(G.Assembler);
      end;

    irDeferEnd:
      X64Nop(G.Assembler);

    irCriticalBegin:
      EmitCriticalEnter(G);

    irCriticalEnd:
      EmitCriticalLeave(G);

    irParallelBegin:
      begin
        AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
          'parallel block requires structured task lowering; use spawn/async and await until that lowering is available');
        X64Int3(G.Assembler);
      end;

    irParallelEnd:
      X64Nop(G.Assembler);

    irConstInt, irConstNull, irConstReal, irConstString:
      begin
        LoadImmediateValue(G, Instr.Dst, xrRAX);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irLoadReceiver:
      begin
        if G.Layout.FunctionReceiverOffsets[G.CurrentFunction] <= 0 then
          X64XorRegReg(G.Assembler, xrRAX, xrRAX)
        else
          X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRBP,
            -G.Layout.FunctionReceiverOffsets[G.CurrentFunction]);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irMove:
      begin
        LoadValue(G, Instr.A, xrRAX);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irLoadSymbol: EmitLoadSymbol(G, Instr);
    irStoreSymbol: EmitStoreSymbol(G, Instr);
    irLoadField: EmitLoadField(G, Instr);
    irStoreField: EmitStoreField(G, Instr);
    irLoadElement: EmitLoadElement(G, Instr);
    irStoreElement: EmitStoreElement(G, Instr);
    irAddressOf: EmitCAddressOf(G, Instr);
    irProcedureAddress: EmitProcedureAddress(G, Instr);
    irLoadIndirect: EmitCIndirectLoad(G, Instr);
    irStoreIndirect: EmitCIndirectStore(G, Instr);
    irLoadForeignData: EmitForeignDataLoad(G, Instr);
    irStoreForeignData: EmitForeignDataStore(G, Instr);
    irPointerOffset: EmitCPointerOffset(G, Instr);

    irAddInt, irSubInt, irMulInt, irDivInt, irModInt, irRemInt,
    irPowerInt, irShiftLeft, irShiftRight, irBitAnd, irBitOr, irBitXor:
      EmitIntegerBinary(G, Instr);

    irNegInt:
      begin
        LoadValue(G, Instr.A, xrRAX);
        X64NegReg(G.Assembler, xrRAX);
        EmitCheckedOverflow(G);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irLogicalNot:
      begin
        LoadValue(G, Instr.A, xrRAX);
        X64TestRegReg(G.Assembler, xrRAX, xrRAX);
        X64SetCondition8(G.Assembler, xcEqual, xrRAX);
        X64MovZXReg8(G.Assembler, xrRAX, xrRAX);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irAddReal, irSubReal, irMulReal, irDivReal:
      EmitRealBinary(G, Instr);
    irPowerReal:
      EmitRealPower(G, Instr);

    irNegReal:
      begin
        LoadValue(G, Instr.A, xrRAX);
        X64MovRegImm64(G.Assembler, xrRCX, QWord($8000000000000000));
        X64XorRegReg(G.Assembler, xrRAX, xrRCX);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irCompareEqual, irCompareNotEqual, irCompareLess, irCompareLessEqual,
    irCompareGreater, irCompareGreaterEqual:
      if (Instr.A >= 0) and
         ((G.ProgramIR^.Values[Instr.A].TypeId = FSIM_TYPE_REAL) or
          IsCRealType(G, G.ProgramIR^.Values[Instr.A].TypeId)) then
        EmitRealComparison(G, Instr)
      else
        EmitComparison(G, Instr);

    irConvertIntToReal:
      begin
        LoadValue(G, Instr.A, xrRAX);
        X64CVTSI2SD(G.Assembler, xrXMM0, xrRAX);
        X64MovQRegXMM(G.Assembler, xrRAX, xrXMM0);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irConvertRealToInt:
      begin
        LoadValue(G, Instr.A, xrRAX);
        X64MovQXMMReg(G.Assembler, xrXMM0, xrRAX);
        X64CVTTSD2SI(G.Assembler, xrRAX, xrXMM0);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irConvertIntWidth:
      begin
        LoadValue(G, Instr.A, xrRAX);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irStringDataPointer:
      begin
        LoadValue(G, Instr.A, xrRAX);
        if G.Options^.NullChecks then
        begin
          { A null string stays a null C pointer.  Ordinary fsim strings point
            at a length word followed by NUL-terminated bytes. }
        end;
        X64TestRegReg(G.Assembler, xrRAX, xrRAX);
        TemporaryLabel := X64NewLabel(G.Assembler);
        X64JumpCondition(G.Assembler, xcEqual, TemporaryLabel);
        X64AddRegImm32(G.Assembler, xrRAX, 8);
        X64BindLabel(G.Assembler, TemporaryLabel);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irStringConcat:
      begin
        LoadValue(G, Instr.A, xrRDI);
        LoadValue(G, Instr.B, xrRSI);
        X64Call(G.Assembler, G.RuntimeLabels.StringConcat);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irStringCompare:
      begin
        LoadValue(G, Instr.A, xrRDI);
        LoadValue(G, Instr.B, xrRSI);
        X64Call(G.Assembler, G.RuntimeLabels.StringEqual);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irStringLength:
      begin
        LoadValue(G, Instr.A, xrRDI);
        X64Call(G.Assembler, G.RuntimeLabels.StringLength);
        StoreValue(G, Instr.Dst, xrRAX);
      end;
    irStringByte:
      begin
        LoadValue(G, Instr.A, xrRDI);
        LoadValue(G, Instr.B, xrRSI);
        X64Call(G.Assembler, G.RuntimeLabels.OS.StringChar);
        StoreValue(G, Instr.Dst, xrRAX);
      end;
    irStringToInteger:
      begin
        LoadValue(G, Instr.A, xrRDI);
        LoadValue(G, Instr.B, xrRSI);
        X64Call(G.Assembler, G.RuntimeLabels.OS.ParseInt);
        StoreValue(G, Instr.Dst, xrRAX);
      end;
    irStringSlice:
      begin
        LoadValue(G, Instr.A, xrRDI);
        LoadValue(G, Instr.B, xrRSI);
        LoadValue(G, Instr.C, xrRDX);
        X64Call(G.Assembler, G.RuntimeLabels.StringSlice);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irTextConcat:
      begin
        LoadValue(G, Instr.A, xrRDI);
        LoadValue(G, Instr.B, xrRSI);
        X64Call(G.Assembler, G.RuntimeLabels.S67.TextConcat);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irTextCompare:
      begin
        LoadValue(G, Instr.A, xrRDI);
        LoadValue(G, Instr.B, xrRSI);
        X64Call(G.Assembler, G.RuntimeLabels.S67.TextEqual);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irTextConstant, irTextStart, irTextLength, irTextMain, irTextPos,
    irTextMore, irTextGetChar, irTextStrip, irTextGetInt, irTextGetReal,
    irTextGetFrac:
      begin
        LoadValue(G, Instr.A, xrRDI);
        case Instr.Op of
          irTextConstant: X64Call(G.Assembler, G.RuntimeLabels.S67.TextConstant);
          irTextStart: X64Call(G.Assembler, G.RuntimeLabels.S67.TextStart);
          irTextLength: X64Call(G.Assembler, G.RuntimeLabels.S67.TextLength);
          irTextMain: X64Call(G.Assembler, G.RuntimeLabels.S67.TextMain);
          irTextPos: X64Call(G.Assembler, G.RuntimeLabels.S67.TextPos);
          irTextMore: X64Call(G.Assembler, G.RuntimeLabels.S67.TextMore);
          irTextGetChar: X64Call(G.Assembler, G.RuntimeLabels.S67.TextGetChar);
          irTextStrip: X64Call(G.Assembler, G.RuntimeLabels.S67.TextStrip);
          irTextGetInt: X64Call(G.Assembler, G.RuntimeLabels.S67.TextGetInt);
          irTextGetReal: X64Call(G.Assembler, G.RuntimeLabels.S67.TextGetReal);
          irTextGetFrac: X64Call(G.Assembler, G.RuntimeLabels.S67.TextGetFrac);
        else
          ;
        end;
        if Instr.Dst >= 0 then StoreValue(G, Instr.Dst, xrRAX);
      end;

    irTextSetPos:
      begin
        LoadValue(G, Instr.A, xrRDI);
        LoadValue(G, Instr.B, xrRSI);
        X64Call(G.Assembler, G.RuntimeLabels.S67.TextSetPos);
        if Instr.Dst >= 0 then StoreValue(G, Instr.Dst, xrRAX);
      end;

    irTextPutChar:
      begin
        LoadValue(G, Instr.A, xrRDI);
        LoadValue(G, Instr.B, xrRSI);
        X64Call(G.Assembler, G.RuntimeLabels.S67.TextPutChar);
        if Instr.Dst >= 0 then StoreValue(G, Instr.Dst, xrRAX);
      end;

    irTextSub:
      begin
        LoadValue(G, Instr.A, xrRDI);
        LoadValue(G, Instr.B, xrRSI);
        LoadValue(G, Instr.C, xrRDX);
        X64Call(G.Assembler, G.RuntimeLabels.S67.TextSub);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irTextPutInt:
      begin
        LoadValue(G, Instr.A, xrRDI);
        LoadValue(G, Instr.B, xrRSI);
        X64Call(G.Assembler, G.RuntimeLabels.S67.TextPutInt);
        if Instr.Dst >= 0 then StoreValue(G, Instr.Dst, xrRAX);
      end;

    irTextPutFix, irTextPutReal, irTextPutFrac:
      begin
        LoadValue(G, Instr.A, xrRDI);
        LoadValue(G, Instr.B, xrRSI);
        LoadValue(G, Instr.C, xrRDX);
        case Instr.Op of
          irTextPutFix: X64Call(G.Assembler, G.RuntimeLabels.S67.TextPutFix);
          irTextPutReal: X64Call(G.Assembler, G.RuntimeLabels.S67.TextPutReal);
          irTextPutFrac: X64Call(G.Assembler, G.RuntimeLabels.S67.TextPutFrac);
        else
          ;
        end;
        if Instr.Dst >= 0 then StoreValue(G, Instr.Dst, xrRAX);
      end;

    irTextCopy:
      begin
        LoadValue(G, Instr.A, xrRDI);
        X64Call(G.Assembler, G.RuntimeLabels.S67.TextCopy);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irStringRetain, irStringRelease, irTextRetain, irTextRelease:
      ; { mmap-backed immutable literals and process-lifetime values require no refcount }

    irAllocObject: EmitObjectAllocation(G, Instr);
    irAllocArray: EmitArrayAllocation(G, Instr);
    irAllocHandle: EmitHandleAllocation(G, Instr);
    irInitObject: EmitObjectInitialization(G, Instr);
    irQuaCheck: EmitQua(G, Instr);
    irTypeTest: EmitTypeTest(G, Instr);
    irTypeExact: EmitTypeExact(G, Instr);

    irRTTIOf:
      begin
        LoadValue(G, Instr.A, xrRAX);
        if G.Options^.NullChecks then
        begin
          X64MovRegReg(G.Assembler, xrRDI, xrRAX);
          X64Call(G.Assembler, G.RuntimeLabels.NullCheck);
        end;
        X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRAX, 0);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irVMTLookup:
      begin
        LoadValue(G, Instr.A, xrRAX);
        X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRAX, 8);
        X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRAX, Instr.Aux * 8);
        StoreValue(G, Instr.Dst, xrRAX);
      end;

    irParameter:
      SetPendingParameter(G, Instr.Aux, Instr.A);

    irCall, irCallIndirect, irCallVirtual, irCallNative, irCallForeign,
    irCallForeignIndirect:
      EmitCallInstruction(G, Instr);

    irReturn:
      begin
        if (G.CurrentFunction >= 0) and
           (G.CurrentFunction <= High(G.ProgramIR^.Functions)) and
           IsRecordValueType(G, G.ProgramIR^.Functions[G.CurrentFunction].ReturnType) then
        begin
          if G.Layout.FunctionSRetOffsets[G.CurrentFunction] <= 0 then
          begin
            AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
              'aggregate-returning function has no hidden return slot');
            X64XorRegReg(G.Assembler, xrRAX, xrRAX);
          end
          else
          begin
            X64MovRegMemBaseDisp(G.Assembler, xrR10, xrRBP,
              -G.Layout.FunctionSRetOffsets[G.CurrentFunction]);
            if Instr.A >= 0 then
            begin
              LoadValue(G, Instr.A, xrR11);
              EmitCopyBytes(G, xrR10, xrR11,
                RuntimeTypeStorageSize(G.Symbols^,
                  G.ProgramIR^.Functions[G.CurrentFunction].ReturnType));
            end;
            X64MovRegReg(G.Assembler, xrRAX, xrR10);
          end;
        end
        else if Instr.A >= 0 then LoadValue(G, Instr.A, xrRAX)
        else X64XorRegReg(G.Assembler, xrRAX, xrRAX);
        X64Jump(G.Assembler, G.CurrentEpilogueLabel);
      end;

    irBranch:
      X64Jump(G.Assembler, G.Layout.BlockLabels[Instr.TargetBlock]);

    irBranchCond:
      begin
        LoadValue(G, Instr.A, xrRAX);
        X64TestRegReg(G.Assembler, xrRAX, xrRAX);
        X64JumpCondition(G.Assembler, xcNotEqual,
          G.Layout.BlockLabels[Instr.TargetBlock]);
        X64Jump(G.Assembler,
          G.Layout.BlockLabels[Instr.AlternateBlock]);
      end;

    irPrintText:
      begin
        if G.Options^.Dialect = fdSimula67 then
        begin
          { SysOut is a call and may clobber the argument registers.  Fetch
            the receiver first, then materialize the text argument. }
          X64Call(G.Assembler, G.RuntimeLabels.S67.SysOut);
          X64MovRegReg(G.Assembler, xrRDI, xrRAX);
          LoadValue(G, Instr.A, xrRSI);
          X64Call(G.Assembler, G.RuntimeLabels.S67.OutText);
        end
        else
        begin
          LoadValue(G, Instr.A, xrRDI);
          X64Call(G.Assembler, G.RuntimeLabels.PrintString);
        end;
      end;
    irPrintInteger:
      begin
        if (G.Options^.Dialect = fdSimula67) or (Instr.C >= 0) then
        begin
          { The two-argument form is classic Simula and remains accepted by
            fsim for source compatibility.  Materialize its operands only
            after SysOut, otherwise that call may destroy RSI/RDX. }
          X64Call(G.Assembler, G.RuntimeLabels.S67.SysOut);
          X64MovRegReg(G.Assembler, xrRDI, xrRAX);
          LoadValue(G, Instr.A, xrRSI);
          if Instr.C >= 0 then LoadValue(G, Instr.C, xrRDX)
          else X64XorRegReg(G.Assembler, xrRDX, xrRDX);
          X64Call(G.Assembler, G.RuntimeLabels.S67.OutInt);
        end
        else
        begin
          LoadValue(G, Instr.A, xrRDI);
          X64Call(G.Assembler, G.RuntimeLabels.PrintInteger);
        end;
      end;
    irPrintReal:
      begin
        if G.Options^.Dialect = fdSimula67 then
        begin
          X64Call(G.Assembler, G.RuntimeLabels.S67.SysOut);
          X64MovRegReg(G.Assembler, xrRDI, xrRAX);
          LoadValue(G, Instr.A, xrRSI);
          LoadValue(G, Instr.B, xrRDX);
          LoadValue(G, Instr.C, xrRCX);
          X64Call(G.Assembler, G.RuntimeLabels.S67.OutReal);
        end
        else
        begin
          LoadValue(G, Instr.A, xrRDI);
          X64Call(G.Assembler, G.RuntimeLabels.PrintReal);
        end;
      end;
    irPrintFixed:
      begin
        if G.Options^.Dialect = fdSimula67 then
        begin
          X64Call(G.Assembler, G.RuntimeLabels.S67.SysOut);
          X64MovRegReg(G.Assembler, xrRDI, xrRAX);
          LoadValue(G, Instr.A, xrRSI);
          LoadValue(G, Instr.B, xrRDX);
          LoadValue(G, Instr.C, xrRCX);
          X64Call(G.Assembler, G.RuntimeLabels.S67.OutFix);
        end
        else
        begin
          LoadValue(G, Instr.A, xrRDI);
          LoadValue(G, Instr.B, xrRSI);
          LoadValue(G, Instr.C, xrRDX);
          X64Call(G.Assembler, G.RuntimeLabels.PrintFixed);
        end;
      end;
    irPrintCharacter:
      begin
        if G.Options^.Dialect = fdSimula67 then
        begin
          X64Call(G.Assembler, G.RuntimeLabels.S67.SysOut);
          X64MovRegReg(G.Assembler, xrRDI, xrRAX);
          LoadValue(G, Instr.A, xrRSI);
          X64Call(G.Assembler, G.RuntimeLabels.S67.OutChar);
        end
        else
        begin
          LoadValue(G, Instr.A, xrRDI);
          X64Call(G.Assembler, G.RuntimeLabels.PrintCharacter);
        end;
      end;
    irPrintNewLine:
      if G.Options^.Dialect = fdSimula67 then
        X64Call(G.Assembler, G.RuntimeLabels.S67.OutImage)
      else
        X64Call(G.Assembler, G.RuntimeLabels.PrintNewLine);

    irAssert:
      begin
        LoadValue(G, Instr.A, xrRAX);
        X64TestRegReg(G.Assembler, xrRAX, xrRAX);
        X64JumpCondition(G.Assembler, xcEqual,
          G.RuntimeLabels.PanicAssert);
      end;

    irRaise:
      if Instr.TargetBlock >= 0 then
        X64Jump(G.Assembler, G.Layout.BlockLabels[Instr.TargetBlock])
      else
        X64Jump(G.Assembler, G.RuntimeLabels.Panic);

    irThreadSpawn:
      begin
        if Instr.SymbolId >= 0 then
        begin
          ClassIndex := FindFunctionBySymbol(G.ProgramIR^, Instr.SymbolId);
          if ClassIndex >= 0 then
            X64LeaRegRipLabel(G.Assembler, xrRDI,
              G.Layout.FunctionLabels[ClassIndex])
          else
            X64XorRegReg(G.Assembler, xrRDI, xrRDI);
        end
        else
          X64XorRegReg(G.Assembler, xrRDI, xrRDI);
        if Instr.A >= 0 then LoadValue(G, Instr.A, xrRSI)
        else X64XorRegReg(G.Assembler, xrRSI, xrRSI);
        X64MovRegImm64(G.Assembler, xrRDX, 1024 * 1024);
        X64Call(G.Assembler, G.RuntimeLabels.ThreadSpawn);
        if Instr.Dst >= 0 then StoreValue(G, Instr.Dst, xrRAX);
      end;

    irThreadJoin:
      begin
        if Instr.A >= 0 then LoadValue(G, Instr.A, xrRDI)
        else X64XorRegReg(G.Assembler, xrRDI, xrRDI);
        X64Call(G.Assembler, G.RuntimeLabels.ThreadJoin);
        if Instr.Dst >= 0 then StoreValue(G, Instr.Dst, xrRAX);
      end;

    irFutureAwait:
      begin
        if Instr.A >= 0 then LoadValue(G, Instr.A, xrRDI)
        else X64XorRegReg(G.Assembler, xrRDI, xrRDI);
        X64Call(G.Assembler, G.RuntimeLabels.FutureAwait);
        if Instr.Dst >= 0 then StoreValue(G, Instr.Dst, xrRAX);
      end;

    irThreadCancel:
      begin
        if Instr.A >= 0 then LoadValue(G, Instr.A, xrRDI)
        else X64XorRegReg(G.Assembler, xrRDI, xrRDI);
        X64Call(G.Assembler, G.RuntimeLabels.ThreadCancel);
        if Instr.Dst >= 0 then StoreValue(G, Instr.Dst, xrRAX);
      end;

    irThreadYield:
      EmitThreadYield(G, Instr);

    irChannelSend:
      EmitChannelSend(G, Instr);

    irChannelReceive:
      EmitChannelReceive(G, Instr);

    irMutexLock:
      EmitMutexLock(G, Instr);

    irMutexUnlock:
      EmitMutexUnlock(G, Instr);

    irMemoryFence:
      X64MemoryFence(G.Assembler);

    irProcessDetach, irProcessCall, irProcessResume, irProcessActivate,
    irProcessReactivate, irProcessDelay, irProcessHold,
    irProcessPassivate:
      begin
        AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
          'classic SIMULA process scheduling requires the cooperative process runtime, which is not yet safe for native emission');
        X64Int3(G.Assembler);
      end;

    irExitProcess:
      begin
        LoadValue(G, Instr.A, xrRDI);
        X64Jump(G.Assembler, G.RuntimeLabels.ExitProcess);
      end;

    irUnreachable:
      X64Int3(G.Assembler);
  else
    begin
      AddError(G.Diagnostics^, dcBackendUnsupported, Instr.Span,
        'x86-64 backend does not implement IR operation ' +
        IROpcodeName(Instr.Op));
      X64Int3(G.Assembler);
    end;
  end;
end;

procedure EmitFunction(var G: TCodeGenerator; FunctionId: Int32);
var
  B, I, FirstOffset: Int32;
  FunctionName: RawByteString;
begin
  G.CurrentFunction := FunctionId;
  G.CurrentEpilogueLabel := X64NewLabel(G.Assembler);
  ClearPendingParameters(G);
  X64BindLabel(G.Assembler, G.Layout.FunctionLabels[FunctionId]);
  FirstOffset := G.Assembler.Code.Count;
  EmitFunctionPrologue(G, FunctionId);
  for B := 0 to High(G.ProgramIR^.Blocks) do
    if G.ProgramIR^.Blocks[B].FunctionId = FunctionId then
    begin
      X64BindLabel(G.Assembler, G.Layout.BlockLabels[B]);
      for I := G.ProgramIR^.Blocks[B].FirstInstruction to
               G.ProgramIR^.Blocks[B].LastInstruction do
        if (I >= 0) and (I <= High(G.ProgramIR^.Instructions)) and
           (G.ProgramIR^.Instructions[I].BlockId = B) then
        begin
          G.CurrentInstruction := I;
          EmitInstruction(G, G.ProgramIR^.Instructions[I]);
        end;
    end;
  X64BindLabel(G.Assembler, G.CurrentEpilogueLabel);
  EmitFunctionEpilogue(G, FunctionId);
  FunctionName := StringPoolGet(G.ProgramIR^.Strings,
    G.ProgramIR^.Functions[FunctionId].NameId);
  if FunctionName = '' then FunctionName := 'function_' + IntToStr(FunctionId);
  AddBackendSymbol(G.NativeImage^, FunctionName, 1, STB_GLOBAL, STT_FUNC,
    FirstOffset, G.Assembler.Code.Count - FirstOffset);
end;

procedure EmitForeignExportAdapter(var G: TCodeGenerator; SymbolId: Int32);
var
  FunctionId, ProcedureType, ParameterStart, ParameterCount, I, J, TypeId: Int32;
  GPCount, SSECount, StackUsed, TempUsed, TempBytes, OutgoingBytes: Int32;
  NeedGP, NeedSSE, GPProbe, SSEProbe, CIncomingSRetOffset,
  InternalReturnOffset, InternalShift, InternalOrdinal: Int32;
  SlotSize, AlignValue, PartOffset, PartBytes: UInt32;
  Reg: TX64Register;
  Name: RawByteString;
  FirstOffset: Int32;
  Args: array of TForeignArgLocation;
  ParamOffsets: TInt32Array;
  ReturnLayout: TCABILayout;
  ReturnType, ReturnGP, ReturnSSE: Int32;
begin
  if (SymbolId < 0) or (SymbolId > High(G.Symbols^.Symbols)) or
     not (sfForeignExport in G.Symbols^.Symbols[SymbolId].Flags) then Exit;
  if (SymbolId > High(G.Layout.ForeignExportLabels)) or
     (G.Layout.ForeignExportLabels[SymbolId] < 0) then Exit;
  FunctionId := G.Layout.FunctionBySymbol[SymbolId];
  if FunctionId < 0 then
  begin
    AddError(G.Diagnostics^, dcBackendUnsupported,
      G.Symbols^.Symbols[SymbolId].SourceSpan,
      'foreign c export has no native function body');
    Exit;
  end;
  ProcedureType := G.Symbols^.Symbols[SymbolId].TypeId;
  if (ProcedureType < 0) or (ProcedureType > High(G.Symbols^.Types)) or
     (G.Symbols^.Types[ProcedureType].Kind <> tyProcedure) then Exit;
  ParameterStart := G.Symbols^.Types[ProcedureType].ParameterStart;
  ParameterCount := G.Symbols^.Types[ProcedureType].ParameterCount;
  ReturnType := G.Symbols^.Types[ProcedureType].ReturnType;
  ReturnLayout := ClassifyCABIType(G, ReturnType);

  SetLength(Args, ParameterCount);
  SetLength(ParamOffsets, ParameterCount);
  GPCount := Ord(IsCRecordType(G, ReturnType) and ReturnLayout.Memory);
  SSECount := 0;
  StackUsed := 0;
  TempUsed := 0;
  for I := 0 to ParameterCount - 1 do
  begin
    Args[I] := Default(TForeignArgLocation);
    Args[I].RegisterIndex[0] := -1;
    Args[I].RegisterIndex[1] := -1;
    Args[I].StackOffset := -1;
    TypeId := G.Symbols^.Parameters[ParameterStart + I].TypeId;
    Args[I].ABIType := TypeId;
    Args[I].Layout := ClassifyCABIType(G, TypeId);

    NeedGP := 0;
    NeedSSE := 0;
    if not Args[I].Layout.Memory then
      for J := 0 to Args[I].Layout.PartCount - 1 do
        if Args[I].Layout.Classes[J] = facSSE then Inc(NeedSSE)
        else if Args[I].Layout.Classes[J] = facInteger then Inc(NeedGP);
    if Args[I].Layout.Memory or (GPCount + NeedGP > 6) or
       (SSECount + NeedSSE > 8) then
    begin
      AlignValue := Args[I].Layout.Alignment;
      if AlignValue < 8 then AlignValue := 8;
      if AlignValue > 16 then AlignValue := 16;
      StackUsed := Int32(AlignUp(QWord(StackUsed), AlignValue));
      Args[I].StackOffset := StackUsed;
      Inc(StackUsed, Int32(AlignUp(Args[I].Layout.Size, 8)));
    end
    else
    begin
      GPProbe := GPCount;
      SSEProbe := SSECount;
      for J := 0 to Args[I].Layout.PartCount - 1 do
        if Args[I].Layout.Classes[J] = facSSE then
        begin
          Args[I].RegisterIndex[J] := SSEProbe;
          Inc(SSEProbe);
        end
        else
        begin
          Args[I].RegisterIndex[J] := GPProbe;
          Inc(GPProbe);
        end;
      GPCount := GPProbe;
      SSECount := SSEProbe;
    end;

    AlignValue := Args[I].Layout.Alignment;
    if AlignValue < 8 then AlignValue := 8;
    if AlignValue > 16 then AlignValue := 16;
    TempUsed := Int32(AlignUp(QWord(TempUsed), AlignValue));
    if IsCRecordType(G, TypeId) then
      SlotSize := Args[I].Layout.Size
    else
      SlotSize := 8;
    Inc(TempUsed, Int32(SlotSize));
    ParamOffsets[I] := TempUsed;
  end;
  CIncomingSRetOffset := 0;
  InternalReturnOffset := 0;
  InternalShift := Ord(IsRecordValueType(G, ReturnType));
  if IsCRecordType(G, ReturnType) then
  begin
    if ReturnLayout.Memory then
    begin
      { The C caller owns the MEMORY-class return buffer.  Preserve its hidden
        RDI value before capturing ordinary C arguments, and reuse the same
        storage as fsim's internal hidden-sret destination. }
      TempUsed := Int32(AlignUp(QWord(TempUsed), 8));
      Inc(TempUsed, 8);
      CIncomingSRetOffset := TempUsed;
    end
    else
    begin
      { Internal fsim returns every complete record through a hidden sret
        pointer, even when SysV returns that C record in registers.  Reserve a
        real local aggregate buffer so the internal function has somewhere to
        write before this adapter marshals the value into RAX/RDX/XMM0/XMM1. }
      AlignValue := ReturnLayout.Alignment;
      if AlignValue = 0 then AlignValue := 1;
      if AlignValue > 16 then AlignValue := 16;
      TempUsed := Int32(AlignUp(QWord(TempUsed), AlignValue));
      Inc(TempUsed, Int32(ReturnLayout.Size));
      InternalReturnOffset := TempUsed;
    end;
  end;
  TempBytes := Int32(AlignUp(QWord(TempUsed), 16));

  X64BindLabel(G.Assembler, G.Layout.ForeignExportLabels[SymbolId]);
  FirstOffset := G.Assembler.Code.Count;
  X64PushReg(G.Assembler, xrRBP);
  X64MovRegReg(G.Assembler, xrRBP, xrRSP);
  if TempBytes > 0 then X64SubRegImm32(G.Assembler, xrRSP, TempBytes);
  if CIncomingSRetOffset > 0 then
    X64MovMemBaseDispReg(G.Assembler, xrRBP, -CIncomingSRetOffset, xrRDI);

  { Capture every C argument before loading the internal fsim ABI registers. }
  for I := 0 to ParameterCount - 1 do
  begin
    TypeId := Args[I].ABIType;
    if IsCRecordType(G, TypeId) then
    begin
      X64LeaRegBaseDisp(G.Assembler, xrR10, xrRBP, -ParamOffsets[I]);
      if Args[I].StackOffset >= 0 then
      begin
        X64LeaRegBaseDisp(G.Assembler, xrR11, xrRBP,
          16 + Args[I].StackOffset);
        EmitCopyBytes(G, xrR10, xrR11, Args[I].Layout.Size);
      end
      else
        for J := 0 to Args[I].Layout.PartCount - 1 do
        begin
          PartOffset := UInt32(J * 8);
          PartBytes := Args[I].Layout.Size - PartOffset;
          if PartBytes > 8 then PartBytes := 8;
          if Args[I].Layout.Classes[J] = facSSE then
          begin
            Reg := CSSEArgumentRegister(Args[I].RegisterIndex[J]);
            X64MovQRegXMM(G.Assembler, xrRAX, Reg);
          end
          else
          begin
            Reg := CIntegerArgumentRegister(Args[I].RegisterIndex[J]);
            X64MovRegReg(G.Assembler, xrRAX, Reg);
          end;
          StoreAggregateChunk(G, xrR10, PartOffset, PartBytes, xrRAX);
        end;
      Continue;
    end;

    if Args[I].StackOffset >= 0 then
    begin
      X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRBP,
        16 + Args[I].StackOffset);
      if IsCFloatType(G, TypeId) then
      begin
        X64MovQXMMReg(G.Assembler, xrXMM0, xrRAX);
        X64CvtSS2SD(G.Assembler, xrXMM0, xrXMM0);
        X64MovQRegXMM(G.Assembler, xrRAX, xrXMM0);
      end
      else
        NormalizeCInteger(G, xrRAX, TypeId);
    end
    else if Args[I].Layout.Classes[0] = facSSE then
    begin
      Reg := CSSEArgumentRegister(Args[I].RegisterIndex[0]);
      if IsCFloatType(G, TypeId) then
        X64CvtSS2SD(G.Assembler, Reg, Reg);
      X64MovQRegXMM(G.Assembler, xrRAX, Reg);
    end
    else
    begin
      Reg := CIntegerArgumentRegister(Args[I].RegisterIndex[0]);
      X64MovRegReg(G.Assembler, xrRAX, Reg);
      NormalizeCInteger(G, xrRAX, TypeId);
    end;
    X64MovMemBaseDispReg(G.Assembler, xrRBP, -ParamOffsets[I], xrRAX);
  end;

  { The adapter crosses from the SysV C ABI into fsim's internal ABI.  Internal
    aggregate returns always consume argument ordinal zero (RDI) as a hidden
    sret pointer, so user parameters must be shifted just like an ordinary fsim
    call.  The old adapter forgot that shift for small C records such as
    struct Mixed, making the record argument masquerade as the return pointer. }
  OutgoingBytes := ParameterCount + InternalShift - 6;
  if OutgoingBytes < 0 then OutgoingBytes := 0;
  OutgoingBytes := Int32(AlignUp(QWord(OutgoingBytes) * 8, 16));
  if OutgoingBytes > 0 then X64SubRegImm32(G.Assembler, xrRSP, OutgoingBytes);

  if InternalShift <> 0 then
  begin
    if ReturnLayout.Memory then
      X64MovRegMemBaseDisp(G.Assembler, xrRDI, xrRBP, -CIncomingSRetOffset)
    else
      X64LeaRegBaseDisp(G.Assembler, xrRDI, xrRBP, -InternalReturnOffset);
  end;

  for I := 0 to ParameterCount - 1 do
  begin
    if IsCRecordType(G, Args[I].ABIType) then
      X64LeaRegBaseDisp(G.Assembler, xrRAX, xrRBP, -ParamOffsets[I])
    else
      X64MovRegMemBaseDisp(G.Assembler, xrRAX, xrRBP, -ParamOffsets[I]);
    InternalOrdinal := I + InternalShift;
    if InternalOrdinal < 6 then
    begin
      Reg := ArgumentRegister(InternalOrdinal);
      X64MovRegReg(G.Assembler, Reg, xrRAX);
    end
    else
      X64MovMemBaseDispReg(G.Assembler, xrRSP,
        (InternalOrdinal - 6) * 8, xrRAX);
  end;
  X64Call(G.Assembler, G.Layout.FunctionLabels[FunctionId]);
  if OutgoingBytes > 0 then X64AddRegImm32(G.Assembler, xrRSP, OutgoingBytes);

  if IsCRecordType(G, ReturnType) then
  begin
    if ReturnLayout.Memory then
    begin
      { The internal callee wrote directly into the C caller's hidden return
        buffer.  SysV requires the same address back in RAX. }
      X64MovRegMemBaseDisp(G.Assembler, xrR10, xrRBP, -CIncomingSRetOffset);
      X64MovRegReg(G.Assembler, xrRAX, xrR10);
    end
    else
    begin
      X64LeaRegBaseDisp(G.Assembler, xrR10, xrRBP, -InternalReturnOffset);
      ReturnSSE := 0;
      for J := 0 to ReturnLayout.PartCount - 1 do
        if ReturnLayout.Classes[J] = facSSE then
        begin
          PartOffset := UInt32(J * 8);
          PartBytes := ReturnLayout.Size - PartOffset;
          if PartBytes > 8 then PartBytes := 8;
          LoadAggregateChunk(G, xrR10, PartOffset, PartBytes, xrR11);
          Reg := CSSEArgumentRegister(ReturnSSE);
          X64MovQXMMReg(G.Assembler, Reg, xrR11);
          Inc(ReturnSSE);
        end;
      ReturnGP := 0;
      for J := 0 to ReturnLayout.PartCount - 1 do
        if ReturnLayout.Classes[J] = facInteger then
        begin
          PartOffset := UInt32(J * 8);
          PartBytes := ReturnLayout.Size - PartOffset;
          if PartBytes > 8 then PartBytes := 8;
          if ReturnGP = 0 then Reg := xrRAX else Reg := xrRDX;
          LoadAggregateChunk(G, xrR10, PartOffset, PartBytes, Reg);
          Inc(ReturnGP);
        end;
    end;
  end
  else if IsCRealType(G, ReturnType) then
  begin
    X64MovQXMMReg(G.Assembler, xrXMM0, xrRAX);
    if IsCFloatType(G, ReturnType) then
      X64CvtSD2SS(G.Assembler, xrXMM0, xrXMM0);
  end
  else
    NormalizeCInteger(G, xrRAX, ReturnType);

  if TempBytes > 0 then X64AddRegImm32(G.Assembler, xrRSP, TempBytes);
  X64PopReg(G.Assembler, xrRBP);
  X64Ret(G.Assembler);
  Name := 'cabi$' + SymName(G.Symbols^, SymbolId);
  AddBackendSymbol(G.NativeImage^, Name, 1, STB_LOCAL, STT_FUNC,
    FirstOffset, G.Assembler.Code.Count - FirstOffset);
end;

procedure EmitForeignExportAdapters(var G: TCodeGenerator);
var
  S: Int32;
begin
  for S := 0 to High(G.Symbols^.Symbols) do
    if sfForeignExport in G.Symbols^.Symbols[S].Flags then
      EmitForeignExportAdapter(G, S);
end;

procedure EmitStartup(var G: TCodeGenerator; out StartupLabel: Int32);
var
  ExitBinding: Int32;
begin
  StartupLabel := X64NewLabel(G.Assembler);
  X64BindLabel(G.Assembler, StartupLabel);
  { Record the original process stack boundary before any runtime helper
    pushes data.  The non-moving collector scans from its own RSP to here. }
  X64LeaRegRipWritable(G.Assembler, xrRAX, G.RuntimeData.GCStackTop, 0);
  X64MovMemBaseDispReg(G.Assembler, xrRAX, 0, xrRSP);
  OSEmitCaptureArgs(G.Assembler, G.RuntimeData.OS);
  X64XorRegReg(G.Assembler, xrRBP, xrRBP);
  if G.Options^.Dialect = fdSimula67 then
    X64Call(G.Assembler, G.RuntimeLabels.S67.Init);
  if G.ProgramIR^.EntryFunction >= 0 then
    X64Call(G.Assembler,
      G.Layout.FunctionLabels[G.ProgramIR^.EntryFunction])
  else
    X64XorRegReg(G.Assembler, xrRAX, xrRAX);
  X64MovRegReg(G.Assembler, xrRDI, xrRAX);
  if (Length(G.Symbols^.ForeignBindings) > 0) and
     (G.Options^.CRuntimeLibrary <> '') then
  begin
    { C libraries expect an orderly process exit for buffered streams, atexit
      handlers and finalizers.  The runtime library is configurable for musl
      and unusual systems instead of baking glibc into the ABI itself. }
    ExitBinding := EnsureForeignProcessExitBinding(G);
    AppendForeignCallFixup(G, ExitBinding);
    X64Int3(G.Assembler); { C exit is noreturn; trap if a broken runtime returns. }
  end
  else
    X64Jump(G.Assembler, G.RuntimeLabels.ExitProcess);
end;

procedure PatchReadOnlyPointers(var G: TCodeGenerator;
  TextVirtualAddress, ReadOnlyVirtualAddress: QWord);
var
  C, Slot, M, FunctionId, Offset, I: Int32;
  V: QWord;
begin
  if G.Options^.Dialect = fdSimula67 then
    for I := 0 to High(G.Layout.StringOffsets) do
    begin
      Offset := G.Layout.StringOffsets[I] - 16;
      V := PUInt64Value(@G.NativeImage^.ReadOnlyData.Data[Offset])^;
      if (V and QWord($8000000000000000)) <> 0 then
        BufferPatchQWord(G.NativeImage^.ReadOnlyData, Offset,
          ReadOnlyVirtualAddress +
          (V and QWord($7FFFFFFFFFFFFFFF)));
      Offset := G.Layout.StringOffsets[I] + S67_TEXT_START_OFFSET;
      V := PUInt64Value(@G.NativeImage^.ReadOnlyData.Data[Offset])^;
      if (V and QWord($8000000000000000)) <> 0 then
        BufferPatchQWord(G.NativeImage^.ReadOnlyData, Offset,
          ReadOnlyVirtualAddress +
          (V and QWord($7FFFFFFFFFFFFFFF)));
    end;

  for C := 0 to High(G.Symbols^.Classes) do
  begin
    V := PUInt64Value(@G.NativeImage^.ReadOnlyData.Data[
      G.Layout.RTTIOffsets[C]])^;
    if (V and QWord($8000000000000000)) <> 0 then
    begin
      Offset := Int32(V and QWord($7FFFFFFFFFFFFFFF));
      BufferPatchQWord(G.NativeImage^.ReadOnlyData,
        G.Layout.RTTIOffsets[C], ReadOnlyVirtualAddress + QWord(Offset));
    end;
    if G.Symbols^.Classes[C].VMTSlotCount > 0 then
      for Slot := 0 to Int32(G.Symbols^.Classes[C].VMTSlotCount) - 1 do
      begin
        Offset := G.Layout.VMTOffsets[C] + Slot * 8;
        V := PUInt64Value(@G.NativeImage^.ReadOnlyData.Data[Offset])^;
        if (V and QWord($4000000000000000)) <> 0 then
        begin
          FunctionId := Int32(V and QWord($3FFFFFFFFFFFFFFF));
          BufferPatchQWord(G.NativeImage^.ReadOnlyData, Offset,
            TextVirtualAddress + QWord(
              G.Assembler.Labels[G.Layout.FunctionLabels[FunctionId]].Offset));
        end;
      end;
  end;
end;

function AppendStringTableString(var Table: TByteBuffer;
  const Value: RawByteString): UInt32;
begin
  Result := Table.Count;
  if Length(Value) > 0 then BufferAppend(Table, Value[1], Length(Value));
  BufferAppendByte(Table, 0);
end;

procedure AppendElfSymbol(var Buffer: TByteBuffer; NameOffset: UInt32;
  Info, Other: Byte; SectionIndex: Word; Value, Size: QWord);
begin
  BufferAppendDWord(Buffer, NameOffset);
  BufferAppendByte(Buffer, Info);
  BufferAppendByte(Buffer, Other);
  BufferAppendWord(Buffer, SectionIndex);
  BufferAppendQWord(Buffer, Value);
  BufferAppendQWord(Buffer, Size);
end;

procedure AppendProgramHeader(var Buffer: TByteBuffer; SegmentType,
  Flags: DWord; FileOffset, VirtualAddress, PhysicalAddress, FileSize,
  MemorySize, Alignment: QWord);
begin
  BufferAppendDWord(Buffer, SegmentType);
  BufferAppendDWord(Buffer, Flags);
  BufferAppendQWord(Buffer, FileOffset);
  BufferAppendQWord(Buffer, VirtualAddress);
  BufferAppendQWord(Buffer, PhysicalAddress);
  BufferAppendQWord(Buffer, FileSize);
  BufferAppendQWord(Buffer, MemorySize);
  BufferAppendQWord(Buffer, Alignment);
end;

procedure AppendSectionHeader(var Buffer: TByteBuffer; Name, SectionType: DWord;
  Flags, Address, FileOffset, Size: QWord; Link, Info: DWord;
  AddressAlignment, EntrySize: QWord);
begin
  BufferAppendDWord(Buffer, Name);
  BufferAppendDWord(Buffer, SectionType);
  BufferAppendQWord(Buffer, Flags);
  BufferAppendQWord(Buffer, Address);
  BufferAppendQWord(Buffer, FileOffset);
  BufferAppendQWord(Buffer, Size);
  BufferAppendDWord(Buffer, Link);
  BufferAppendDWord(Buffer, Info);
  BufferAppendQWord(Buffer, AddressAlignment);
  BufferAppendQWord(Buffer, EntrySize);
end;


procedure AppendDynamicEntry(var Buffer: TByteBuffer; Tag: Int64; Value: QWord);
begin
  BufferAppendQWord(Buffer, QWord(Tag));
  BufferAppendQWord(Buffer, Value);
end;

procedure AppendRela(var Buffer: TByteBuffer; Offset, Info: QWord;
  Addend: Int64);
begin
  BufferAppendQWord(Buffer, Offset);
  BufferAppendQWord(Buffer, Info);
  BufferAppendQWord(Buffer, QWord(Addend));
end;

procedure AppendBuffer(var Destination: TByteBuffer; const Source: TByteBuffer);
begin
  if Source.Count > 0 then
    BufferAppend(Destination, Source.Data[0], Source.Count);
end;

function StringArrayIndex(const Values: array of RawByteString;
  const Value: RawByteString): Int32;
var
  I: Integer;
begin
  for I := 0 to High(Values) do
    if Values[I] = Value then Exit(I);
  Result := -1;
end;

procedure PatchForeignCalls(var G: TCodeGenerator; GOTAddress,
  TextAddress: QWord);
var
  I, ForeignIndex: Integer;
  Target, SourceEnd: QWord;
  Delta: Int64;
begin
  for I := 0 to High(G.ForeignCalls) do
  begin
    ForeignIndex := G.ForeignCalls[I].ForeignIndex;
    if (ForeignIndex < 0) or
       (ForeignIndex > High(G.Symbols^.ForeignBindings)) then Continue;
    Target := GOTAddress + QWord(ForeignIndex * 8);
    SourceEnd := TextAddress + QWord(G.ForeignCalls[I].SourceEndOffset);
    Delta := Int64(Target) - Int64(SourceEnd);
    if (Delta < Low(Int32)) or (Delta > High(Int32)) then
    begin
      AddError(G.Diagnostics^, dcBackendUnsupported, Default(TSourceSpan),
        'C GOT target is outside x86-64 RIP-relative call range');
      Continue;
    end;
    BufferPatchDWord(G.Assembler.Code, G.ForeignCalls[I].PatchOffset,
      DWord(Int32(Delta)));
  end;
end;

procedure BuildDynamicELFFile(var G: TCodeGenerator; StartupLabel: Int32);
var
  TextOffset, TextAddress, RodataOffset, RodataAddress, InterpOffset,
  InterpAddress, DynstrOffset, DynstrAddress, DynsymOffset, DynsymAddress,
  HashOffset, HashAddress, RelaOffset, RelaAddress, DataOffset, DataAddress,
  GOTOffset, GOTAddress, DynamicOffset, DynamicAddress, SymtabOffset,
  StrtabOffset, ShstrtabOffset, SectionHeaderOffset, RXFileSize, RWFileSize,
  BSSAddress: QWord;
  GOT, Dynamic, Dynstr, Dynsym, HashTable, Rela, Interp, Symtab, Strtab,
  Shstrtab, Header: TByteBuffer;
  Libraries: array of RawByteString;
  LibraryNameOffsets: array of UInt32;
  ForeignNameOffsets, ExportNameOffsets: array of UInt32;
  ExportSymbols: array of Int32;
  I, SymbolId, LabelId, ForeignCount, ExportCount, DynSymbolCount: Integer;
  Binding: TForeignBinding;
  LibraryName, LinkName, DynamicLinkerName: RawByteString;
  NameText, NameRodata, NameData, NameBSS, NameInterp, NameDynstr, NameDynsym,
  NameHash, NameRela, NameGOT, NameDynamic, NameSymtab, NameStrtab,
  NameShstrtab, NameOffset: UInt32;
  SymbolValue, SlotAddress: QWord;
  EIdentPadding: Byte;
  LinkerSpan: TSourceSpan;
begin
  LinkerSpan := Default(TSourceSpan);
  ForeignCount := Length(G.Symbols^.ForeignBindings);
  SetLength(ExportSymbols, 0);
  for SymbolId := 0 to High(G.Symbols^.Symbols) do
    if sfForeignExport in G.Symbols^.Symbols[SymbolId].Flags then
    begin
      if (SymbolId > High(G.Layout.ForeignExportLabels)) or
         (G.Layout.ForeignExportLabels[SymbolId] < 0) then
      begin
        AddError(G.Diagnostics^, dcBackendUnsupported,
          G.Symbols^.Symbols[SymbolId].SourceSpan,
          'foreign C export has no generated adapter');
        Continue;
      end;
      LabelId := G.Layout.ForeignExportLabels[SymbolId];
      if (LabelId > High(G.Assembler.Labels)) or
         not G.Assembler.Labels[LabelId].Bound then
      begin
        AddError(G.Diagnostics^, dcBackendUnsupported,
          G.Symbols^.Symbols[SymbolId].SourceSpan,
          'foreign C export adapter label was not bound');
        Continue;
      end;
      SetLength(ExportSymbols, Length(ExportSymbols) + 1);
      ExportSymbols[High(ExportSymbols)] := SymbolId;
    end;
  ExportCount := Length(ExportSymbols);
  DynSymbolCount := ForeignCount + ExportCount;
  if DynSymbolCount = 0 then Exit;

  SetLength(Libraries, 0);
  for I := 0 to ForeignCount - 1 do
  begin
    Binding := G.Symbols^.ForeignBindings[I];
    LibraryName := StringPoolGet(G.Symbols^.Strings, Binding.LibraryNameId);
    if StringArrayIndex(Libraries, LibraryName) < 0 then
    begin
      SetLength(Libraries, Length(Libraries) + 1);
      Libraries[High(Libraries)] := LibraryName;
    end;
  end;

  BufferInit(Interp, 64);
  DynamicLinkerName := G.Options^.DynamicLinker;
  if DynamicLinkerName = '' then DynamicLinkerName := DetectHostDynamicLinker;
  if DynamicLinkerName = '' then
  begin
    AddError(G.Diagnostics^, dcBackendUnsupported, LinkerSpan,
      'cannot locate the host ELF dynamic linker; use --dynamic-linker=PATH ' +
      'or FSIM_DYNAMIC_LINKER');
    Exit;
  end;
  BufferAppend(Interp, DynamicLinkerName[1], Length(DynamicLinkerName));
  BufferAppendByte(Interp, 0);

  BufferInit(Dynstr, 512);
  BufferAppendByte(Dynstr, 0);
  SetLength(LibraryNameOffsets, Length(Libraries));
  for I := 0 to High(Libraries) do
    LibraryNameOffsets[I] := AppendStringTableString(Dynstr, Libraries[I]);
  SetLength(ForeignNameOffsets, ForeignCount);
  for I := 0 to ForeignCount - 1 do
  begin
    LinkName := StringPoolGet(G.Symbols^.Strings,
      G.Symbols^.ForeignBindings[I].LinkNameId);
    ForeignNameOffsets[I] := AppendStringTableString(Dynstr, LinkName);
  end;
  SetLength(ExportNameOffsets, ExportCount);
  for I := 0 to ExportCount - 1 do
    ExportNameOffsets[I] := AppendStringTableString(Dynstr,
      SymName(G.Symbols^, ExportSymbols[I]));

  BufferInit(Dynsym, 24 * (DynSymbolCount + 1));
  AppendElfSymbol(Dynsym, 0, 0, 0, SHN_UNDEF, 0, 0);
  for I := 0 to ForeignCount - 1 do
  begin
    if G.Symbols^.ForeignBindings[I].Kind = fbObject then
      NameOffset := STT_OBJECT
    else
      NameOffset := STT_FUNC;
    AppendElfSymbol(Dynsym, ForeignNameOffsets[I],
      (STB_GLOBAL shl 4) or NameOffset, 0, SHN_UNDEF, 0, 0);
  end;
  for I := 0 to ExportCount - 1 do
  begin
    SymbolId := ExportSymbols[I];
    LabelId := G.Layout.ForeignExportLabels[SymbolId];
    SymbolValue := ELF_BASE_ADDRESS + ELF_TEXT_FILE_OFFSET +
      QWord(G.Assembler.Labels[LabelId].Offset);
    AppendElfSymbol(Dynsym, ExportNameOffsets[I],
      (STB_GLOBAL shl 4) or STT_FUNC, 0, 1, SymbolValue, 0);
  end;

  { A compact SysV hash chain keeps every import and exported callback
    discoverable without dragging in GNU-hash generation. }
  BufferInit(HashTable, 16 + 4 * DynSymbolCount);
  BufferAppendDWord(HashTable, 1);
  BufferAppendDWord(HashTable, DynSymbolCount + 1);
  if DynSymbolCount > 0 then BufferAppendDWord(HashTable, 1)
  else BufferAppendDWord(HashTable, 0);
  BufferAppendDWord(HashTable, 0);
  for I := 1 to DynSymbolCount do
    if I < DynSymbolCount then BufferAppendDWord(HashTable, I + 1)
    else BufferAppendDWord(HashTable, 0);

  TextOffset := ELF_TEXT_FILE_OFFSET;
  TextAddress := ELF_BASE_ADDRESS + TextOffset;
  RodataOffset := AlignUp(TextOffset + G.Assembler.Code.Count, 16);
  RodataAddress := ELF_BASE_ADDRESS + RodataOffset;
  InterpOffset := RodataOffset + G.NativeImage^.ReadOnlyData.Count;
  InterpAddress := ELF_BASE_ADDRESS + InterpOffset;
  DynstrOffset := InterpOffset + Interp.Count;
  DynstrAddress := ELF_BASE_ADDRESS + DynstrOffset;
  DynsymOffset := AlignUp(DynstrOffset + Dynstr.Count, 8);
  DynsymAddress := ELF_BASE_ADDRESS + DynsymOffset;
  HashOffset := AlignUp(DynsymOffset + Dynsym.Count, 8);
  HashAddress := ELF_BASE_ADDRESS + HashOffset;
  RelaOffset := AlignUp(HashOffset + HashTable.Count, 8);
  RelaAddress := ELF_BASE_ADDRESS + RelaOffset;
  RXFileSize := RelaOffset + QWord(ForeignCount * 24);
  DataOffset := AlignUp(RXFileSize, ELF_PAGE_SIZE);
  DataAddress := ELF_BASE_ADDRESS + DataOffset;
  GOTOffset := AlignUp(DataOffset + G.NativeImage^.WritableData.Count, 8);
  GOTAddress := ELF_BASE_ADDRESS + GOTOffset;
  DynamicOffset := AlignUp(GOTOffset + QWord(ForeignCount * 8), 8);
  DynamicAddress := ELF_BASE_ADDRESS + DynamicOffset;

  PatchForeignCalls(G, GOTAddress, TextAddress);
  BufferInit(GOT, ForeignCount * 8);
  BufferAppendZeros(GOT, ForeignCount * 8);

  BufferInit(Rela, ForeignCount * 24);
  for I := 0 to ForeignCount - 1 do
  begin
    SlotAddress := GOTAddress + QWord(I * 8);
    AppendRela(Rela, SlotAddress,
      (QWord(I + 1) shl 32) or R_X86_64_GLOB_DAT, 0);
  end;

  BufferInit(Dynamic, 512);
  for I := 0 to High(Libraries) do
    AppendDynamicEntry(Dynamic, DT_NEEDED, LibraryNameOffsets[I]);
  AppendDynamicEntry(Dynamic, DT_HASH, HashAddress);
  AppendDynamicEntry(Dynamic, DT_STRTAB, DynstrAddress);
  AppendDynamicEntry(Dynamic, DT_SYMTAB, DynsymAddress);
  AppendDynamicEntry(Dynamic, DT_STRSZ, Dynstr.Count);
  AppendDynamicEntry(Dynamic, DT_SYMENT, 24);
  AppendDynamicEntry(Dynamic, DT_RELA, RelaAddress);
  AppendDynamicEntry(Dynamic, DT_RELASZ, Rela.Count);
  AppendDynamicEntry(Dynamic, DT_RELAENT, 24);
  AppendDynamicEntry(Dynamic, DT_DEBUG, 0);
  AppendDynamicEntry(Dynamic, DT_NULL, 0);

  RWFileSize := (DynamicOffset - DataOffset) + Dynamic.Count;
  BSSAddress := DataAddress + RWFileSize;

  X64ResolveTextFixups(G.Assembler);
  X64ResolveDataFixups(G.Assembler, TextAddress, RodataAddress, DataAddress);
  PatchReadOnlyPointers(G, TextAddress, RodataAddress);
  G.NativeImage^.EntryTextOffset := G.Assembler.Labels[StartupLabel].Offset;
  G.NativeImage^.Text := G.Assembler.Code;

  BufferInit(Symtab, 1024);
  BufferInit(Strtab, 1024);
  BufferInit(Shstrtab, 512);
  BufferAppendByte(Strtab, 0);
  BufferAppendByte(Shstrtab, 0);
  NameText := AppendStringTableString(Shstrtab, '.text');
  NameRodata := AppendStringTableString(Shstrtab, '.rodata');
  NameData := AppendStringTableString(Shstrtab, '.data');
  NameBSS := AppendStringTableString(Shstrtab, '.bss');
  NameInterp := AppendStringTableString(Shstrtab, '.interp');
  NameDynstr := AppendStringTableString(Shstrtab, '.dynstr');
  NameDynsym := AppendStringTableString(Shstrtab, '.dynsym');
  NameHash := AppendStringTableString(Shstrtab, '.hash');
  NameRela := AppendStringTableString(Shstrtab, '.rela.dyn');
  NameGOT := AppendStringTableString(Shstrtab, '.got');
  NameDynamic := AppendStringTableString(Shstrtab, '.dynamic');
  NameSymtab := AppendStringTableString(Shstrtab, '.symtab');
  NameStrtab := AppendStringTableString(Shstrtab, '.strtab');
  NameShstrtab := AppendStringTableString(Shstrtab, '.shstrtab');

  AppendElfSymbol(Symtab, 0, 0, 0, SHN_UNDEF, 0, 0);
  AppendElfSymbol(Symtab, 0, (STB_LOCAL shl 4) or STT_SECTION, 0, 1,
    TextAddress, 0);
  AppendElfSymbol(Symtab, 0, (STB_LOCAL shl 4) or STT_SECTION, 0, 2,
    RodataAddress, 0);
  AppendElfSymbol(Symtab, 0, (STB_LOCAL shl 4) or STT_SECTION, 0, 3,
    DataAddress, 0);
  NameOffset := AppendStringTableString(Strtab, '_start');
  AppendElfSymbol(Symtab, NameOffset, (STB_GLOBAL shl 4) or STT_FUNC, 0, 1,
    TextAddress + G.NativeImage^.EntryTextOffset, 0);
  for I := 0 to High(G.NativeImage^.Symbols) do
  begin
    NameOffset := AppendStringTableString(Strtab, G.NativeImage^.Symbols[I].Name);
    SymbolValue := G.NativeImage^.Symbols[I].Value;
    if G.NativeImage^.Symbols[I].SectionIndex = 1 then Inc(SymbolValue, TextAddress)
    else if G.NativeImage^.Symbols[I].SectionIndex = 2 then Inc(SymbolValue, RodataAddress)
    else if G.NativeImage^.Symbols[I].SectionIndex = 3 then Inc(SymbolValue, DataAddress);
    AppendElfSymbol(Symtab, NameOffset,
      (G.NativeImage^.Symbols[I].Bind shl 4) or G.NativeImage^.Symbols[I].SymbolType,
      0, G.NativeImage^.Symbols[I].SectionIndex, SymbolValue,
      G.NativeImage^.Symbols[I].Size);
  end;

  SymtabOffset := AlignUp(DynamicOffset + Dynamic.Count, 8);
  StrtabOffset := SymtabOffset + Symtab.Count;
  ShstrtabOffset := StrtabOffset + Strtab.Count;
  SectionHeaderOffset := AlignUp(ShstrtabOffset + Shstrtab.Count, 8);

  BufferClear(G.NativeImage^.Image);
  BufferInit(Header, 512);
  BufferAppendByte(Header, $7F); BufferAppendByte(Header, Ord('E'));
  BufferAppendByte(Header, Ord('L')); BufferAppendByte(Header, Ord('F'));
  BufferAppendByte(Header, ELFCLASS64); BufferAppendByte(Header, ELFDATA2LSB);
  BufferAppendByte(Header, EV_CURRENT); BufferAppendByte(Header, ELFOSABI_SYSV);
  for EIdentPadding := 1 to 8 do BufferAppendByte(Header, 0);
  BufferAppendWord(Header, ET_EXEC); BufferAppendWord(Header, EM_X86_64);
  BufferAppendDWord(Header, EV_CURRENT);
  BufferAppendQWord(Header, TextAddress + G.NativeImage^.EntryTextOffset);
  BufferAppendQWord(Header, 64); BufferAppendQWord(Header, SectionHeaderOffset);
  BufferAppendDWord(Header, 0); BufferAppendWord(Header, 64);
  BufferAppendWord(Header, 56); BufferAppendWord(Header, 4);
  BufferAppendWord(Header, 64); BufferAppendWord(Header, 15);
  BufferAppendWord(Header, 14);
  AppendProgramHeader(Header, PT_LOAD, PF_R or PF_X, 0, ELF_BASE_ADDRESS,
    ELF_BASE_ADDRESS, RXFileSize, RXFileSize, ELF_PAGE_SIZE);
  AppendProgramHeader(Header, PT_LOAD, PF_R or PF_W, DataOffset, DataAddress,
    DataAddress, RWFileSize, RWFileSize + G.NativeImage^.BSSSize, ELF_PAGE_SIZE);
  AppendProgramHeader(Header, PT_INTERP, PF_R, InterpOffset, InterpAddress,
    InterpAddress, Interp.Count, Interp.Count, 1);
  AppendProgramHeader(Header, PT_DYNAMIC, PF_R or PF_W, DynamicOffset,
    DynamicAddress, DynamicAddress, Dynamic.Count, Dynamic.Count, 8);

  AppendBuffer(G.NativeImage^.Image, Header);
  if G.NativeImage^.Image.Count < TextOffset then
    BufferAppendZeros(G.NativeImage^.Image, TextOffset - G.NativeImage^.Image.Count);
  AppendBuffer(G.NativeImage^.Image, G.Assembler.Code);
  if G.NativeImage^.Image.Count < RodataOffset then
    BufferAppendZeros(G.NativeImage^.Image, RodataOffset - G.NativeImage^.Image.Count);
  AppendBuffer(G.NativeImage^.Image, G.NativeImage^.ReadOnlyData);
  if G.NativeImage^.Image.Count < InterpOffset then
    BufferAppendZeros(G.NativeImage^.Image, InterpOffset - G.NativeImage^.Image.Count);
  AppendBuffer(G.NativeImage^.Image, Interp);
  if G.NativeImage^.Image.Count < DynstrOffset then
    BufferAppendZeros(G.NativeImage^.Image, DynstrOffset - G.NativeImage^.Image.Count);
  AppendBuffer(G.NativeImage^.Image, Dynstr);
  if G.NativeImage^.Image.Count < DynsymOffset then
    BufferAppendZeros(G.NativeImage^.Image, DynsymOffset - G.NativeImage^.Image.Count);
  AppendBuffer(G.NativeImage^.Image, Dynsym);
  if G.NativeImage^.Image.Count < HashOffset then
    BufferAppendZeros(G.NativeImage^.Image, HashOffset - G.NativeImage^.Image.Count);
  AppendBuffer(G.NativeImage^.Image, HashTable);
  if G.NativeImage^.Image.Count < RelaOffset then
    BufferAppendZeros(G.NativeImage^.Image, RelaOffset - G.NativeImage^.Image.Count);
  AppendBuffer(G.NativeImage^.Image, Rela);
  if G.NativeImage^.Image.Count < DataOffset then
    BufferAppendZeros(G.NativeImage^.Image, DataOffset - G.NativeImage^.Image.Count);
  AppendBuffer(G.NativeImage^.Image, G.NativeImage^.WritableData);
  if G.NativeImage^.Image.Count < GOTOffset then
    BufferAppendZeros(G.NativeImage^.Image, GOTOffset - G.NativeImage^.Image.Count);
  AppendBuffer(G.NativeImage^.Image, GOT);
  if G.NativeImage^.Image.Count < DynamicOffset then
    BufferAppendZeros(G.NativeImage^.Image, DynamicOffset - G.NativeImage^.Image.Count);
  AppendBuffer(G.NativeImage^.Image, Dynamic);
  if G.NativeImage^.Image.Count < SymtabOffset then
    BufferAppendZeros(G.NativeImage^.Image, SymtabOffset - G.NativeImage^.Image.Count);
  AppendBuffer(G.NativeImage^.Image, Symtab);
  AppendBuffer(G.NativeImage^.Image, Strtab);
  AppendBuffer(G.NativeImage^.Image, Shstrtab);
  if G.NativeImage^.Image.Count < SectionHeaderOffset then
    BufferAppendZeros(G.NativeImage^.Image,
      SectionHeaderOffset - G.NativeImage^.Image.Count);

  AppendSectionHeader(G.NativeImage^.Image, 0, SHT_NULL, 0, 0, 0, 0, 0, 0, 0, 0);
  AppendSectionHeader(G.NativeImage^.Image, NameText, SHT_PROGBITS,
    SHF_ALLOC or SHF_EXECINSTR, TextAddress, TextOffset, G.Assembler.Code.Count,
    0, 0, 16, 0);
  AppendSectionHeader(G.NativeImage^.Image, NameRodata, SHT_PROGBITS,
    SHF_ALLOC, RodataAddress, RodataOffset, G.NativeImage^.ReadOnlyData.Count,
    0, 0, 8, 0);
  AppendSectionHeader(G.NativeImage^.Image, NameData, SHT_PROGBITS,
    SHF_ALLOC or SHF_WRITE, DataAddress, DataOffset,
    G.NativeImage^.WritableData.Count, 0, 0, 8, 0);
  AppendSectionHeader(G.NativeImage^.Image, NameBSS, SHT_NOBITS,
    SHF_ALLOC or SHF_WRITE, BSSAddress, DataOffset + RWFileSize,
    G.NativeImage^.BSSSize, 0, 0, 8, 0);
  AppendSectionHeader(G.NativeImage^.Image, NameInterp, SHT_PROGBITS,
    SHF_ALLOC, InterpAddress, InterpOffset, Interp.Count, 0, 0, 1, 0);
  AppendSectionHeader(G.NativeImage^.Image, NameDynstr, SHT_STRTAB,
    SHF_ALLOC, DynstrAddress, DynstrOffset, Dynstr.Count, 0, 0, 1, 0);
  AppendSectionHeader(G.NativeImage^.Image, NameDynsym, SHT_DYNSYM,
    SHF_ALLOC, DynsymAddress, DynsymOffset, Dynsym.Count, 6, 1, 8, 24);
  AppendSectionHeader(G.NativeImage^.Image, NameHash, SHT_HASH,
    SHF_ALLOC, HashAddress, HashOffset, HashTable.Count, 7, 0, 4, 4);
  AppendSectionHeader(G.NativeImage^.Image, NameRela, SHT_RELA,
    SHF_ALLOC, RelaAddress, RelaOffset, Rela.Count, 7, 0, 8, 24);
  AppendSectionHeader(G.NativeImage^.Image, NameGOT, SHT_PROGBITS,
    SHF_ALLOC or SHF_WRITE, GOTAddress, GOTOffset, GOT.Count, 0, 0, 8, 8);
  AppendSectionHeader(G.NativeImage^.Image, NameDynamic, SHT_DYNAMIC,
    SHF_ALLOC or SHF_WRITE, DynamicAddress, DynamicOffset, Dynamic.Count,
    6, 0, 8, 16);
  AppendSectionHeader(G.NativeImage^.Image, NameSymtab, SHT_SYMTAB,
    0, 0, SymtabOffset, Symtab.Count, 13, 4, 8, 24);
  AppendSectionHeader(G.NativeImage^.Image, NameStrtab, SHT_STRTAB,
    0, 0, StrtabOffset, Strtab.Count, 0, 0, 1, 0);
  AppendSectionHeader(G.NativeImage^.Image, NameShstrtab, SHT_STRTAB,
    0, 0, ShstrtabOffset, Shstrtab.Count, 0, 0, 1, 0);

  BufferClear(Header); BufferClear(GOT); BufferClear(Dynamic);
  BufferClear(Dynstr); BufferClear(Dynsym); BufferClear(HashTable);
  BufferClear(Rela); BufferClear(Interp); BufferClear(Symtab);
  BufferClear(Strtab); BufferClear(Shstrtab);
end;

procedure BuildELFFile(var G: TCodeGenerator; StartupLabel: Int32);
var
  TextOffset, TextAddress, RodataOffset, RodataAddress, DataOffset,
  DataAddress, SymtabOffset, StrtabOffset, ShstrtabOffset, SectionHeaderOffset,
  RXFileSize, RWFileSize: QWord;
  Symtab, Strtab, Shstrtab: TByteBuffer;
  NameText, NameRodata, NameData, NameBSS, NameSymtab, NameStrtab,
  NameShstrtab: UInt32;
  I: Integer;
  NameOffset: UInt32;
  SymbolValue: QWord;
  Header: TByteBuffer;
begin
  TextOffset := ELF_TEXT_FILE_OFFSET;
  TextAddress := ELF_BASE_ADDRESS + TextOffset;
  RodataOffset := AlignUp(TextOffset + G.Assembler.Code.Count, 16);
  RodataAddress := ELF_BASE_ADDRESS + RodataOffset;
  DataOffset := AlignUp(RodataOffset + G.NativeImage^.ReadOnlyData.Count,
    ELF_PAGE_SIZE);
  DataAddress := ELF_BASE_ADDRESS + DataOffset;

  X64ResolveTextFixups(G.Assembler);
  X64ResolveDataFixups(G.Assembler, TextAddress, RodataAddress, DataAddress);
  PatchReadOnlyPointers(G, TextAddress, RodataAddress);

  G.NativeImage^.EntryTextOffset :=
    G.Assembler.Labels[StartupLabel].Offset;
  G.NativeImage^.Text := G.Assembler.Code;

  BufferInit(Symtab, 1024);
  BufferInit(Strtab, 1024);
  BufferInit(Shstrtab, 256);
  BufferAppendByte(Strtab, 0);
  BufferAppendByte(Shstrtab, 0);
  NameText := AppendStringTableString(Shstrtab, '.text');
  NameRodata := AppendStringTableString(Shstrtab, '.rodata');
  NameData := AppendStringTableString(Shstrtab, '.data');
  NameBSS := AppendStringTableString(Shstrtab, '.bss');
  NameSymtab := AppendStringTableString(Shstrtab, '.symtab');
  NameStrtab := AppendStringTableString(Shstrtab, '.strtab');
  NameShstrtab := AppendStringTableString(Shstrtab, '.shstrtab');

  AppendElfSymbol(Symtab, 0, 0, 0, SHN_UNDEF, 0, 0);
  AppendElfSymbol(Symtab, 0, (STB_LOCAL shl 4) or STT_SECTION, 0, 1,
    TextAddress, 0);
  AppendElfSymbol(Symtab, 0, (STB_LOCAL shl 4) or STT_SECTION, 0, 2,
    RodataAddress, 0);
  AppendElfSymbol(Symtab, 0, (STB_LOCAL shl 4) or STT_SECTION, 0, 3,
    DataAddress, 0);
  NameOffset := AppendStringTableString(Strtab, '_start');
  AppendElfSymbol(Symtab, NameOffset, (STB_GLOBAL shl 4) or STT_FUNC, 0, 1,
    TextAddress + G.NativeImage^.EntryTextOffset, 0);
  for I := 0 to High(G.NativeImage^.Symbols) do
  begin
    NameOffset := AppendStringTableString(Strtab,
      G.NativeImage^.Symbols[I].Name);
    SymbolValue := G.NativeImage^.Symbols[I].Value;
    if G.NativeImage^.Symbols[I].SectionIndex = 1 then
      Inc(SymbolValue, TextAddress)
    else if G.NativeImage^.Symbols[I].SectionIndex = 2 then
      Inc(SymbolValue, RodataAddress)
    else if G.NativeImage^.Symbols[I].SectionIndex = 3 then
      Inc(SymbolValue, DataAddress);
    AppendElfSymbol(Symtab, NameOffset,
      (G.NativeImage^.Symbols[I].Bind shl 4) or
       G.NativeImage^.Symbols[I].SymbolType, 0,
      G.NativeImage^.Symbols[I].SectionIndex, SymbolValue,
      G.NativeImage^.Symbols[I].Size);
  end;

  SymtabOffset := AlignUp(DataOffset + G.NativeImage^.WritableData.Count, 8);
  StrtabOffset := SymtabOffset + Symtab.Count;
  ShstrtabOffset := StrtabOffset + Strtab.Count;
  SectionHeaderOffset := AlignUp(ShstrtabOffset + Shstrtab.Count, 8);
  RXFileSize := RodataOffset + G.NativeImage^.ReadOnlyData.Count;
  RWFileSize := G.NativeImage^.WritableData.Count;

  BufferClear(G.NativeImage^.Image);
  BufferInit(Header, 256);
  BufferAppendByte(Header, $7F);
  BufferAppendByte(Header, Ord('E'));
  BufferAppendByte(Header, Ord('L'));
  BufferAppendByte(Header, Ord('F'));
  BufferAppendByte(Header, ELFCLASS64);
  BufferAppendByte(Header, ELFDATA2LSB);
  BufferAppendByte(Header, EV_CURRENT);
  BufferAppendByte(Header, ELFOSABI_SYSV);
  BufferAppendZeros(Header, 8);
  BufferAppendWord(Header, ET_EXEC);
  BufferAppendWord(Header, EM_X86_64);
  BufferAppendDWord(Header, EV_CURRENT);
  BufferAppendQWord(Header,
    TextAddress + G.NativeImage^.EntryTextOffset);
  BufferAppendQWord(Header, 64);
  BufferAppendQWord(Header, SectionHeaderOffset);
  BufferAppendDWord(Header, 0);
  BufferAppendWord(Header, 64);
  BufferAppendWord(Header, 56);
  BufferAppendWord(Header, 2);
  BufferAppendWord(Header, 64);
  BufferAppendWord(Header, 8);
  BufferAppendWord(Header, 7);
  AppendProgramHeader(Header, PT_LOAD, PF_R or PF_X, 0, ELF_BASE_ADDRESS,
    ELF_BASE_ADDRESS, RXFileSize, RXFileSize, ELF_PAGE_SIZE);
  AppendProgramHeader(Header, PT_LOAD, PF_R or PF_W, DataOffset, DataAddress,
    DataAddress, RWFileSize, RWFileSize + G.NativeImage^.BSSSize,
    ELF_PAGE_SIZE);

  BufferAppend(G.NativeImage^.Image, Header.Data[0], Header.Count);
  if G.NativeImage^.Image.Count < TextOffset then
    BufferAppendZeros(G.NativeImage^.Image,
      TextOffset - G.NativeImage^.Image.Count);
  if G.Assembler.Code.Count > 0 then
    BufferAppend(G.NativeImage^.Image, G.Assembler.Code.Data[0],
      G.Assembler.Code.Count);
  if G.NativeImage^.Image.Count < RodataOffset then
    BufferAppendZeros(G.NativeImage^.Image,
      RodataOffset - G.NativeImage^.Image.Count);
  if G.NativeImage^.ReadOnlyData.Count > 0 then
    BufferAppend(G.NativeImage^.Image,
      G.NativeImage^.ReadOnlyData.Data[0],
      G.NativeImage^.ReadOnlyData.Count);
  if G.NativeImage^.Image.Count < DataOffset then
    BufferAppendZeros(G.NativeImage^.Image,
      DataOffset - G.NativeImage^.Image.Count);
  if G.NativeImage^.WritableData.Count > 0 then
    BufferAppend(G.NativeImage^.Image,
      G.NativeImage^.WritableData.Data[0],
      G.NativeImage^.WritableData.Count);
  if G.NativeImage^.Image.Count < SymtabOffset then
    BufferAppendZeros(G.NativeImage^.Image,
      SymtabOffset - G.NativeImage^.Image.Count);
  BufferAppend(G.NativeImage^.Image, Symtab.Data[0], Symtab.Count);
  BufferAppend(G.NativeImage^.Image, Strtab.Data[0], Strtab.Count);
  BufferAppend(G.NativeImage^.Image, Shstrtab.Data[0], Shstrtab.Count);
  if G.NativeImage^.Image.Count < SectionHeaderOffset then
    BufferAppendZeros(G.NativeImage^.Image,
      SectionHeaderOffset - G.NativeImage^.Image.Count);

  AppendSectionHeader(G.NativeImage^.Image, 0, SHT_NULL, 0, 0, 0, 0, 0, 0,
    0, 0);
  AppendSectionHeader(G.NativeImage^.Image, NameText, SHT_PROGBITS,
    SHF_ALLOC or SHF_EXECINSTR, TextAddress, TextOffset,
    G.Assembler.Code.Count, 0, 0, 16, 0);
  AppendSectionHeader(G.NativeImage^.Image, NameRodata, SHT_PROGBITS,
    SHF_ALLOC, RodataAddress, RodataOffset,
    G.NativeImage^.ReadOnlyData.Count, 0, 0, 8, 0);
  AppendSectionHeader(G.NativeImage^.Image, NameData, SHT_PROGBITS,
    SHF_ALLOC or SHF_WRITE, DataAddress, DataOffset,
    G.NativeImage^.WritableData.Count, 0, 0, 8, 0);
  AppendSectionHeader(G.NativeImage^.Image, NameBSS, SHT_NOBITS,
    SHF_ALLOC or SHF_WRITE, DataAddress + RWFileSize,
    DataOffset + RWFileSize, G.NativeImage^.BSSSize, 0, 0, 8, 0);
  AppendSectionHeader(G.NativeImage^.Image, NameSymtab, SHT_SYMTAB, 0, 0,
    SymtabOffset, Symtab.Count, 6, 4, 8, 24);
  AppendSectionHeader(G.NativeImage^.Image, NameStrtab, SHT_STRTAB, 0, 0,
    StrtabOffset, Strtab.Count, 0, 0, 1, 0);
  AppendSectionHeader(G.NativeImage^.Image, NameShstrtab, SHT_STRTAB, 0, 0,
    ShstrtabOffset, Shstrtab.Count, 0, 0, 1, 0);

  BufferClear(Header);
  BufferClear(Symtab);
  BufferClear(Strtab);
  BufferClear(Shstrtab);
end;

procedure BuildAssemblyListing(var G: TCodeGenerator);
var
  I, J, LineStart, LineEnd: Integer;
  S: RawByteString;
begin
  S := '; fsim ' + FSIM_VERSION_STRING + ' x86-64 resolved byte listing' +
    LineEnding;
  S := S + '; target ' + FSIM_TARGET_TRIPLE + LineEnding;
  for I := 0 to High(G.ProgramIR^.Instructions) do
    if not (iifRemoved in G.ProgramIR^.Instructions[I].Flags) then
      S := S + Format('; ir %6d  %-18s  dst=%d a=%d b=%d symbol=%d'#10,
        [I, IROpcodeName(G.ProgramIR^.Instructions[I].Op),
         G.ProgramIR^.Instructions[I].Dst,
         G.ProgramIR^.Instructions[I].A,
         G.ProgramIR^.Instructions[I].B,
         G.ProgramIR^.Instructions[I].SymbolId]);
  S := S + LineEnding + 'section .text' + LineEnding;
  I := 0;
  while I < G.Assembler.Code.Count do
  begin
    LineStart := I;
    LineEnd := I + 15;
    if LineEnd >= G.Assembler.Code.Count then
      LineEnd := G.Assembler.Code.Count - 1;
    S := S + Format('%8.8x:  ', [LineStart]);
    for J := LineStart to LineEnd do
      S := S + IntToHex(G.Assembler.Code.Data[J], 2) + ' ';
    S := S + LineEnding;
    I := LineEnd + 1;
  end;
  G.NativeImage^.AssemblyText := S;
end;

procedure BuildNativeImage(var ProgramIR: TIRProgram;
  var Symbols: TSymbolTable; const Allocation: TRegisterAllocation;
  const Options: TCompilerOptions; var Diagnostics: TDiagnosticBag;
  out Image: TNativeImage);
var
  G: TCodeGenerator;
  StartupLabel, F: Int32;
begin
  NativeImageInit(Image);
  G := Default(TCodeGenerator);
  X64Init(G.Assembler);
  G.ProgramIR := @ProgramIR;
  G.Symbols := @Symbols;
  G.Allocation := @Allocation;
  G.Options := @Options;
  G.Diagnostics := @Diagnostics;
  G.NativeImage := @Image;
  RuntimeAllocateLabels(G.Assembler, G.RuntimeLabels);
  PrepareFunctionMaps(G);
  PrepareReadOnlyData(G);
  EmitStartup(G, StartupLabel);
  RuntimeEmit(G.Assembler, G.RuntimeLabels, G.RuntimeData,
    G.ProgramGlobalRootOffset, G.ProgramGlobalRootBytes);
  for F := 0 to High(ProgramIR.Functions) do
    EmitFunction(G, F);
  EmitForeignExportAdapters(G);
  if Length(Symbols.ForeignBindings) > 0 then
    BuildDynamicELFFile(G, StartupLabel)
  else
  begin
    F := 0;
    while (F <= High(Symbols.Symbols)) and
          not (sfForeignExport in Symbols.Symbols[F].Flags) do Inc(F);
    if F <= High(Symbols.Symbols) then
      BuildDynamicELFFile(G, StartupLabel)
    else
      BuildELFFile(G, StartupLabel);
  end;
  BuildAssemblyListing(G);
end;

procedure WriteNativeOutput(const Image: TNativeImage;
  const Options: TCompilerOptions);
var
  OutputPath: RawByteString;
  EmptyByte: Byte;
begin
  EmptyByte := 0;
  OutputPath := Options.OutputPath;
  if OutputPath = '' then OutputPath := 'a.out';
  case Options.EmitKind of
    ekAssembly:
      SaveBinaryFile(OutputPath, Image.AssemblyText[1],
        Length(Image.AssemblyText));
    ekRawBytes:
      if Image.Text.Count > 0 then
        SaveBinaryFile(OutputPath, Image.Text.Data[0], Image.Text.Count)
      else
        SaveBinaryFile(OutputPath, EmptyByte, 0);
  else
    begin
      if Image.Image.Count > 0 then
        SaveBinaryFile(OutputPath, Image.Image.Data[0], Image.Image.Count)
      else
        SaveBinaryFile(OutputPath, EmptyByte, 0);
      fpChmod(OutputPath, &755);
    end;
  end;
end;

end.

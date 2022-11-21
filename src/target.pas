unit target;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, core, diagnostics;

type
  TTargetArchitecture = (
    taInvalid,
    taX86_64
  );

  TTargetOperatingSystem = (
    tosInvalid,
    tosLinux
  );

  TObjectFormat = (
    ofInvalid,
    ofELF64
  );

  TTargetEndian = (
    teLittle,
    teBig
  );

  TCPUFeature = (
    cfSSE2,
    cfSSE3,
    cfSSSE3,
    cfSSE41,
    cfSSE42,
    cfPOPCNT,
    cfAVX,
    cfAVX2,
    cfBMI1,
    cfBMI2,
    cfLZCNT,
    cfFMA,
    cfCX16,
    cfERMS,
    cfAES,
    cfPCLMUL,
    cfRDRAND,
    cfRDSEED
  );
  TCPUFeatures = set of TCPUFeature;

  TCodeModel = (
    cmSmall,
    cmKernel,
    cmMedium,
    cmLarge
  );

  TRelocationModel = (
    rmStatic,
    rmPositionIndependent
  );

  TCallingConvention = (
    ccFSim,
    ccSystemVAMD64,
    ccLinuxSyscall
  );

  TABIValueClass = (
    avcNoClass,
    avcInteger,
    avcSSE,
    avcSSEUp,
    avcMemory
  );

  TTargetRegisterClass = (
    trcNone,
    trcGeneralPurpose,
    trcFloatingPoint,
    trcVector,
    trcFlags,
    trcInstructionPointer,
    trcStackPointer
  );

  TTargetRegisterFlag = (
    trfAllocatable,
    trfCallerSaved,
    trfCalleeSaved,
    trfArgument,
    trfReturn,
    trfReserved,
    trfVolatile
  );
  TTargetRegisterFlags = set of TTargetRegisterFlag;

  TTargetRegister = packed record
    Number: UInt16;
    Encoding: UInt8;
    Width: UInt16;
    RegisterClass: TTargetRegisterClass;
    Flags: TTargetRegisterFlags;
    Name: array[0..15] of AnsiChar;
  end;

  TABIValueLayout = packed record
    FirstClass: TABIValueClass;
    SecondClass: TABIValueClass;
    Size: UInt32;
    Alignment: UInt32;
    RegisterCount: UInt8;
    Indirect: Boolean;
  end;

  TTargetDataLayout = packed record
    PointerSize: UInt8;
    PointerAlignment: UInt8;
    IntegerSize: UInt8;
    IntegerAlignment: UInt8;
    LongIntegerSize: UInt8;
    LongIntegerAlignment: UInt8;
    RealSize: UInt8;
    RealAlignment: UInt8;
    ObjectAlignment: UInt8;
    StackAlignment: UInt8;
    RedZoneSize: UInt16;
    MinimumFunctionAlignment: UInt8;
    PreferredFunctionAlignment: UInt8;
    Endian: TTargetEndian;
  end;

  TTargetDescriptor = record
    Architecture: TTargetArchitecture;
    OperatingSystem: TTargetOperatingSystem;
    ObjectFormat: TObjectFormat;
    CodeModel: TCodeModel;
    RelocationModel: TRelocationModel;
    CallingConvention: TCallingConvention;
    Features: TCPUFeatures;
    DataLayout: TTargetDataLayout;
    Registers: array of TTargetRegister;
    ArgumentRegisters: array of UInt16;
    FloatingArgumentRegisters: array of UInt16;
    CalleeSavedRegisters: array of UInt16;
    CallerSavedRegisters: array of UInt16;
    ReturnRegister: UInt16;
    FloatingReturnRegister: UInt16;
    StackRegister: UInt16;
    FrameRegister: UInt16;
  end;

  TELFSegmentPermission = (
    espRead,
    espWrite,
    espExecute
  );
  TELFSegmentPermissions = set of TELFSegmentPermission;

  TELFLayoutRequest = packed record
    HeaderSize: UInt64;
    TextSize: UInt64;
    ReadOnlySize: UInt64;
    DataSize: UInt64;
    BSSSize: UInt64;
    PageSize: UInt64;
    BaseAddress: UInt64;
  end;

  TELFLayoutResult = packed record
    HeaderOffset: UInt64;
    TextOffset: UInt64;
    ReadOnlyOffset: UInt64;
    DataOffset: UInt64;
    BSSOffset: UInt64;
    FileSize: UInt64;
    MemorySize: UInt64;
    HeaderAddress: UInt64;
    TextAddress: UInt64;
    ReadOnlyAddress: UInt64;
    DataAddress: UInt64;
    BSSAddress: UInt64;
  end;

const
  FSIM_LINUX_X86_64_BASE_ADDRESS = UInt64($0000000000400000);
  FSIM_LINUX_PAGE_SIZE = UInt64($1000);
  FSIM_AMD64_RED_ZONE_SIZE = 128;
  FSIM_AMD64_STACK_ALIGNMENT = 16;

  LINUX_SYS_READ = 0;
  LINUX_SYS_WRITE = 1;
  LINUX_SYS_MMAP = 9;
  LINUX_SYS_MUNMAP = 11;
  LINUX_SYS_SCHED_YIELD = 24;
  LINUX_SYS_NANOSLEEP = 35;
  LINUX_SYS_CLONE = 56;
  LINUX_SYS_EXIT = 60;
  LINUX_SYS_FUTEX = 202;
  LINUX_SYS_EXIT_GROUP = 231;
  LINUX_SYS_CLOCK_GETTIME = 228;
  LINUX_SYS_GETRANDOM = 318;

  LINUX_PROT_READ = 1;
  LINUX_PROT_WRITE = 2;
  LINUX_PROT_EXEC = 4;
  LINUX_MAP_PRIVATE = 2;
  LINUX_MAP_ANONYMOUS = $20;
  LINUX_MAP_STACK = $20000;

  LINUX_CLONE_VM = $00000100;
  LINUX_CLONE_FS = $00000200;
  LINUX_CLONE_FILES = $00000400;
  LINUX_CLONE_SIGHAND = $00000800;
  LINUX_CLONE_THREAD = $00010000;
  LINUX_CLONE_SYSVSEM = $00040000;
  LINUX_CLONE_SETTLS = $00080000;
  LINUX_CLONE_PARENT_SETTID = $00100000;
  LINUX_CLONE_CHILD_CLEARTID = $00200000;
  LINUX_CLONE_CHILD_SETTID = $01000000;

procedure TargetInitLinuxX86_64(var Target: TTargetDescriptor);
procedure TargetClear(var Target: TTargetDescriptor);
function TargetTriple(const Target: TTargetDescriptor): RawByteString;
function TargetArchitectureName(Value: TTargetArchitecture): RawByteString;
function TargetOperatingSystemName(Value: TTargetOperatingSystem): RawByteString;
function TargetObjectFormatName(Value: TObjectFormat): RawByteString;
function TargetCPUFeatureName(Value: TCPUFeature): RawByteString;
function TargetParseCPUFeature(const Name: RawByteString;
  out Feature: TCPUFeature): Boolean;
function TargetEnableFeature(var Target: TTargetDescriptor;
  const Name: RawByteString): Boolean;
function TargetDisableFeature(var Target: TTargetDescriptor;
  const Name: RawByteString): Boolean;
function TargetHasFeature(const Target: TTargetDescriptor;
  Feature: TCPUFeature): Boolean;
function TargetFeatureString(const Target: TTargetDescriptor): RawByteString;
function TargetRegisterName(const Target: TTargetDescriptor;
  RegisterNumber: UInt16): RawByteString;
function TargetFindRegister(const Target: TTargetDescriptor;
  const Name: RawByteString): Int32;
function TargetRegisterIsAllocatable(const Target: TTargetDescriptor;
  RegisterNumber: UInt16): Boolean;
function TargetRegisterIsCallerSaved(const Target: TTargetDescriptor;
  RegisterNumber: UInt16): Boolean;
function TargetRegisterIsCalleeSaved(const Target: TTargetDescriptor;
  RegisterNumber: UInt16): Boolean;
function TargetClassifyValue(Size, Alignment: UInt32; IsReal,
  IsAggregate: Boolean): TABIValueLayout;
function TargetStackArgumentOffset(ArgumentIndex, RegisterArgumentCount: UInt32;
  ValueSize, ValueAlignment: UInt32): UInt32;
function TargetAlign(Value, Alignment: UInt64): UInt64;
function TargetIsPowerOfTwo(Value: UInt64): Boolean;
function TargetELFPermissionFlags(Permissions: TELFSegmentPermissions): UInt32;
procedure TargetComputeELFLayout(const Request: TELFLayoutRequest;
  out Layout: TELFLayoutResult);
procedure TargetValidate(const Target: TTargetDescriptor;
  var Diagnostics: TDiagnosticBag);

implementation

function FoldASCII(const Value: RawByteString): RawByteString;
var
  I: SizeInt;
begin
  Result := Value;
  for I := 1 to Length(Result) do
    if (Result[I] >= 'A') and (Result[I] <= 'Z') then
      Result[I] := AnsiChar(Ord(Result[I]) + 32);
end;

procedure SetRegisterName(var RegisterInfo: TTargetRegister;
  const Name: RawByteString);
var
  Count: SizeInt;
begin
  FillChar(RegisterInfo.Name, SizeOf(RegisterInfo.Name), 0);
  Count := Length(Name);
  if Count > High(RegisterInfo.Name) then
    Count := High(RegisterInfo.Name);
  if Count > 0 then
    Move(Name[1], RegisterInfo.Name[0], Count);
end;

procedure ConfigureRegister(var Target: TTargetDescriptor; Number: UInt16;
  Encoding: UInt8; const Name: RawByteString; RegisterClass: TTargetRegisterClass;
  Width: UInt16; Flags: TTargetRegisterFlags);
begin
  if Length(Target.Registers) <= Number then
    SetLength(Target.Registers, Number + 1);
  FillChar(Target.Registers[Number], SizeOf(TTargetRegister), 0);
  Target.Registers[Number].Number := Number;
  Target.Registers[Number].Encoding := Encoding;
  Target.Registers[Number].Width := Width;
  Target.Registers[Number].RegisterClass := RegisterClass;
  Target.Registers[Number].Flags := Flags;
  SetRegisterName(Target.Registers[Number], Name);
end;

procedure AppendRegister(var Values: array of UInt16; var Count: SizeInt;
  Value: UInt16);
begin
  if Count <= High(Values) then
  begin
    Values[Count] := Value;
    Inc(Count);
  end;
end;

procedure TargetInitRegisterLists(var Target: TTargetDescriptor);
begin
  SetLength(Target.ArgumentRegisters, 6);
  Target.ArgumentRegisters[0] := 5;
  Target.ArgumentRegisters[1] := 4;
  Target.ArgumentRegisters[2] := 3;
  Target.ArgumentRegisters[3] := 2;
  Target.ArgumentRegisters[4] := 8;
  Target.ArgumentRegisters[5] := 9;

  SetLength(Target.FloatingArgumentRegisters, 8);
  Target.FloatingArgumentRegisters[0] := 16;
  Target.FloatingArgumentRegisters[1] := 17;
  Target.FloatingArgumentRegisters[2] := 18;
  Target.FloatingArgumentRegisters[3] := 19;
  Target.FloatingArgumentRegisters[4] := 20;
  Target.FloatingArgumentRegisters[5] := 21;
  Target.FloatingArgumentRegisters[6] := 22;
  Target.FloatingArgumentRegisters[7] := 23;

  SetLength(Target.CalleeSavedRegisters, 6);
  Target.CalleeSavedRegisters[0] := 1;
  Target.CalleeSavedRegisters[1] := 6;
  Target.CalleeSavedRegisters[2] := 12;
  Target.CalleeSavedRegisters[3] := 13;
  Target.CalleeSavedRegisters[4] := 14;
  Target.CalleeSavedRegisters[5] := 15;

  SetLength(Target.CallerSavedRegisters, 9);
  Target.CallerSavedRegisters[0] := 0;
  Target.CallerSavedRegisters[1] := 2;
  Target.CallerSavedRegisters[2] := 3;
  Target.CallerSavedRegisters[3] := 4;
  Target.CallerSavedRegisters[4] := 5;
  Target.CallerSavedRegisters[5] := 7;
  Target.CallerSavedRegisters[6] := 8;
  Target.CallerSavedRegisters[7] := 9;
  Target.CallerSavedRegisters[8] := 10;
end;

procedure TargetInitLinuxX86_64(var Target: TTargetDescriptor);
var
  Caller, Callee, Argument: TTargetRegisterFlags;
begin
  Target := Default(TTargetDescriptor);
  Target.Architecture := taX86_64;
  Target.OperatingSystem := tosLinux;
  Target.ObjectFormat := ofELF64;
  Target.CodeModel := cmSmall;
  Target.RelocationModel := rmStatic;
  Target.CallingConvention := ccSystemVAMD64;
  Target.Features := [cfSSE2, cfCX16];

  Target.DataLayout.PointerSize := 8;
  Target.DataLayout.PointerAlignment := 8;
  Target.DataLayout.IntegerSize := 8;
  Target.DataLayout.IntegerAlignment := 8;
  Target.DataLayout.LongIntegerSize := 8;
  Target.DataLayout.LongIntegerAlignment := 8;
  Target.DataLayout.RealSize := 8;
  Target.DataLayout.RealAlignment := 8;
  Target.DataLayout.ObjectAlignment := 16;
  Target.DataLayout.StackAlignment := FSIM_AMD64_STACK_ALIGNMENT;
  Target.DataLayout.RedZoneSize := FSIM_AMD64_RED_ZONE_SIZE;
  Target.DataLayout.MinimumFunctionAlignment := 1;
  Target.DataLayout.PreferredFunctionAlignment := 16;
  Target.DataLayout.Endian := teLittle;

  Caller := [trfAllocatable, trfCallerSaved];
  Callee := [trfAllocatable, trfCalleeSaved];
  Argument := [trfArgument];
  ConfigureRegister(Target, 0, 0, 'rax', trcGeneralPurpose, 64,
    Caller + [trfReturn]);
  ConfigureRegister(Target, 1, 3, 'rbx', trcGeneralPurpose, 64, Callee);
  ConfigureRegister(Target, 2, 1, 'rcx', trcGeneralPurpose, 64, Caller);
  ConfigureRegister(Target, 3, 2, 'rdx', trcGeneralPurpose, 64,
    Caller + Argument);
  ConfigureRegister(Target, 4, 6, 'rsi', trcGeneralPurpose, 64,
    Caller + Argument);
  ConfigureRegister(Target, 5, 7, 'rdi', trcGeneralPurpose, 64,
    Caller + Argument);
  ConfigureRegister(Target, 6, 5, 'rbp', trcGeneralPurpose, 64,
    Callee + [trfReserved]);
  ConfigureRegister(Target, 7, 4, 'rsp', trcStackPointer, 64,
    [trfReserved]);
  ConfigureRegister(Target, 8, 8, 'r8', trcGeneralPurpose, 64,
    Caller + Argument);
  ConfigureRegister(Target, 9, 9, 'r9', trcGeneralPurpose, 64,
    Caller + Argument);
  ConfigureRegister(Target, 10, 10, 'r10', trcGeneralPurpose, 64, Caller);
  ConfigureRegister(Target, 11, 11, 'r11', trcGeneralPurpose, 64, Caller);
  ConfigureRegister(Target, 12, 12, 'r12', trcGeneralPurpose, 64, Callee);
  ConfigureRegister(Target, 13, 13, 'r13', trcGeneralPurpose, 64, Callee);
  ConfigureRegister(Target, 14, 14, 'r14', trcGeneralPurpose, 64, Callee);
  ConfigureRegister(Target, 15, 15, 'r15', trcGeneralPurpose, 64, Callee);
  ConfigureRegister(Target, 16, 0, 'xmm0', trcFloatingPoint, 128,
    Caller + Argument + [trfReturn]);
  ConfigureRegister(Target, 17, 1, 'xmm1', trcFloatingPoint, 128,
    Caller + Argument);
  ConfigureRegister(Target, 18, 2, 'xmm2', trcFloatingPoint, 128,
    Caller + Argument);
  ConfigureRegister(Target, 19, 3, 'xmm3', trcFloatingPoint, 128,
    Caller + Argument);
  ConfigureRegister(Target, 20, 4, 'xmm4', trcFloatingPoint, 128,
    Caller + Argument);
  ConfigureRegister(Target, 21, 5, 'xmm5', trcFloatingPoint, 128,
    Caller + Argument);
  ConfigureRegister(Target, 22, 6, 'xmm6', trcFloatingPoint, 128,
    Caller + Argument);
  ConfigureRegister(Target, 23, 7, 'xmm7', trcFloatingPoint, 128,
    Caller + Argument);
  ConfigureRegister(Target, 24, 8, 'xmm8', trcFloatingPoint, 128, Caller);
  ConfigureRegister(Target, 25, 9, 'xmm9', trcFloatingPoint, 128, Caller);
  ConfigureRegister(Target, 26, 10, 'xmm10', trcFloatingPoint, 128, Caller);
  ConfigureRegister(Target, 27, 11, 'xmm11', trcFloatingPoint, 128, Caller);
  ConfigureRegister(Target, 28, 12, 'xmm12', trcFloatingPoint, 128, Caller);
  ConfigureRegister(Target, 29, 13, 'xmm13', trcFloatingPoint, 128, Caller);
  ConfigureRegister(Target, 30, 14, 'xmm14', trcFloatingPoint, 128, Caller);
  ConfigureRegister(Target, 31, 15, 'xmm15', trcFloatingPoint, 128, Caller);

  TargetInitRegisterLists(Target);
  Target.ReturnRegister := 0;
  Target.FloatingReturnRegister := 16;
  Target.StackRegister := 7;
  Target.FrameRegister := 6;
end;

procedure TargetClear(var Target: TTargetDescriptor);
begin
  SetLength(Target.Registers, 0);
  SetLength(Target.ArgumentRegisters, 0);
  SetLength(Target.FloatingArgumentRegisters, 0);
  SetLength(Target.CalleeSavedRegisters, 0);
  SetLength(Target.CallerSavedRegisters, 0);
  Target := Default(TTargetDescriptor);
end;

function TargetArchitectureName(Value: TTargetArchitecture): RawByteString;
begin
  case Value of
    taX86_64: Result := 'x86_64';
  else
    Result := 'invalid';
  end;
end;

function TargetOperatingSystemName(Value: TTargetOperatingSystem): RawByteString;
begin
  case Value of
    tosLinux: Result := 'linux';
  else
    Result := 'invalid';
  end;
end;

function TargetObjectFormatName(Value: TObjectFormat): RawByteString;
begin
  case Value of
    ofELF64: Result := 'elf64';
  else
    Result := 'invalid';
  end;
end;

function TargetTriple(const Target: TTargetDescriptor): RawByteString;
begin
  Result := TargetArchitectureName(Target.Architecture) + '-unknown-' +
    TargetOperatingSystemName(Target.OperatingSystem) + '-gnu';
end;

function TargetCPUFeatureName(Value: TCPUFeature): RawByteString;
begin
  case Value of
    cfSSE2: Result := 'sse2';
    cfSSE3: Result := 'sse3';
    cfSSSE3: Result := 'ssse3';
    cfSSE41: Result := 'sse4.1';
    cfSSE42: Result := 'sse4.2';
    cfPOPCNT: Result := 'popcnt';
    cfAVX: Result := 'avx';
    cfAVX2: Result := 'avx2';
    cfBMI1: Result := 'bmi1';
    cfBMI2: Result := 'bmi2';
    cfLZCNT: Result := 'lzcnt';
    cfFMA: Result := 'fma';
    cfCX16: Result := 'cx16';
    cfERMS: Result := 'erms';
    cfAES: Result := 'aes';
    cfPCLMUL: Result := 'pclmul';
    cfRDRAND: Result := 'rdrand';
    cfRDSEED: Result := 'rdseed';
  else
    Result := 'unknown';
  end;
end;

function TargetParseCPUFeature(const Name: RawByteString;
  out Feature: TCPUFeature): Boolean;
var
  Folded: RawByteString;
  Candidate: TCPUFeature;
begin
  Folded := FoldASCII(Name);
  for Candidate := Low(TCPUFeature) to High(TCPUFeature) do
    if TargetCPUFeatureName(Candidate) = Folded then
    begin
      Feature := Candidate;
      Exit(True);
    end;
  Feature := cfSSE2;
  Result := False;
end;

function TargetEnableFeature(var Target: TTargetDescriptor;
  const Name: RawByteString): Boolean;
var
  Feature: TCPUFeature;
begin
  Result := TargetParseCPUFeature(Name, Feature);
  if Result then Include(Target.Features, Feature);
end;

function TargetDisableFeature(var Target: TTargetDescriptor;
  const Name: RawByteString): Boolean;
var
  Feature: TCPUFeature;
begin
  Result := TargetParseCPUFeature(Name, Feature);
  if Result then Exclude(Target.Features, Feature);
end;

function TargetHasFeature(const Target: TTargetDescriptor;
  Feature: TCPUFeature): Boolean;
begin
  Result := Feature in Target.Features;
end;

function TargetFeatureString(const Target: TTargetDescriptor): RawByteString;
var
  Feature: TCPUFeature;
begin
  Result := '';
  for Feature := Low(TCPUFeature) to High(TCPUFeature) do
    if Feature in Target.Features then
    begin
      if Result <> '' then Result := Result + ',';
      Result := Result + TargetCPUFeatureName(Feature);
    end;
end;

function TargetRegisterName(const Target: TTargetDescriptor;
  RegisterNumber: UInt16): RawByteString;
var
  LengthValue: SizeInt;
begin
  Result := '';
  if RegisterNumber > High(Target.Registers) then Exit;
  LengthValue := 0;
  while (LengthValue <= High(Target.Registers[RegisterNumber].Name)) and
        (Target.Registers[RegisterNumber].Name[LengthValue] <> #0) do
    Inc(LengthValue);
  if LengthValue > 0 then
    SetString(Result, PAnsiChar(@Target.Registers[RegisterNumber].Name[0]),
      LengthValue);
end;

function TargetFindRegister(const Target: TTargetDescriptor;
  const Name: RawByteString): Int32;
var
  I: Int32;
  Folded: RawByteString;
begin
  Folded := FoldASCII(Name);
  for I := 0 to High(Target.Registers) do
    if TargetRegisterName(Target, I) = Folded then Exit(I);
  Result := -1;
end;

function TargetRegisterIsAllocatable(const Target: TTargetDescriptor;
  RegisterNumber: UInt16): Boolean;
begin
  Result := (RegisterNumber <= High(Target.Registers)) and
    (trfAllocatable in Target.Registers[RegisterNumber].Flags) and
    not (trfReserved in Target.Registers[RegisterNumber].Flags);
end;

function TargetRegisterIsCallerSaved(const Target: TTargetDescriptor;
  RegisterNumber: UInt16): Boolean;
begin
  Result := (RegisterNumber <= High(Target.Registers)) and
    (trfCallerSaved in Target.Registers[RegisterNumber].Flags);
end;

function TargetRegisterIsCalleeSaved(const Target: TTargetDescriptor;
  RegisterNumber: UInt16): Boolean;
begin
  Result := (RegisterNumber <= High(Target.Registers)) and
    (trfCalleeSaved in Target.Registers[RegisterNumber].Flags);
end;

function TargetClassifyValue(Size, Alignment: UInt32; IsReal,
  IsAggregate: Boolean): TABIValueLayout;
begin
  Result := Default(TABIValueLayout);
  Result.Size := Size;
  Result.Alignment := Alignment;
  if Result.Alignment = 0 then Result.Alignment := 1;
  if Size = 0 then
  begin
    Result.FirstClass := avcNoClass;
    Exit;
  end;
  if IsAggregate and ((Size > 16) or (Alignment > 16)) then
  begin
    Result.FirstClass := avcMemory;
    Result.Indirect := True;
    Exit;
  end;
  if IsReal and not IsAggregate then
    Result.FirstClass := avcSSE
  else
    Result.FirstClass := avcInteger;
  Result.RegisterCount := 1;
  if Size > 8 then
  begin
    if IsReal then Result.SecondClass := avcSSEUp
    else Result.SecondClass := avcInteger;
    Result.RegisterCount := 2;
  end;
end;

function TargetStackArgumentOffset(ArgumentIndex, RegisterArgumentCount: UInt32;
  ValueSize, ValueAlignment: UInt32): UInt32;
var
  StackIndex, SlotSize, AlignmentValue: UInt64;
begin
  if ArgumentIndex < RegisterArgumentCount then Exit(0);
  StackIndex := ArgumentIndex - RegisterArgumentCount;
  AlignmentValue := ValueAlignment;
  if AlignmentValue < 8 then AlignmentValue := 8;
  SlotSize := TargetAlign(ValueSize, AlignmentValue);
  if SlotSize < 8 then SlotSize := 8;
  Result := UInt32(16 + StackIndex * SlotSize);
end;

function TargetIsPowerOfTwo(Value: UInt64): Boolean;
begin
  Result := (Value <> 0) and ((Value and (Value - 1)) = 0);
end;

function TargetAlign(Value, Alignment: UInt64): UInt64;
begin
  if not TargetIsPowerOfTwo(Alignment) then
    raise ERangeError.Create('target alignment must be a nonzero power of two');
  if Value > High(UInt64) - (Alignment - 1) then
    raise ERangeError.Create('target alignment overflow');
  Result := (Value + Alignment - 1) and not (Alignment - 1);
end;

function TargetELFPermissionFlags(Permissions: TELFSegmentPermissions): UInt32;
begin
  Result := 0;
  if espExecute in Permissions then Result := Result or 1;
  if espWrite in Permissions then Result := Result or 2;
  if espRead in Permissions then Result := Result or 4;
end;

procedure TargetComputeELFLayout(const Request: TELFLayoutRequest;
  out Layout: TELFLayoutResult);
var
  PageSize, Cursor: UInt64;
begin
  Layout := Default(TELFLayoutResult);
  PageSize := Request.PageSize;
  if PageSize = 0 then PageSize := FSIM_LINUX_PAGE_SIZE;
  if not TargetIsPowerOfTwo(PageSize) then
    raise ERangeError.Create('ELF page size must be a power of two');
  Layout.HeaderOffset := 0;
  Layout.HeaderAddress := Request.BaseAddress;
  Cursor := TargetAlign(Request.HeaderSize, PageSize);
  Layout.TextOffset := Cursor;
  Layout.TextAddress := Request.BaseAddress + Cursor;
  Cursor := TargetAlign(Cursor + Request.TextSize, PageSize);
  Layout.ReadOnlyOffset := Cursor;
  Layout.ReadOnlyAddress := Request.BaseAddress + Cursor;
  Cursor := TargetAlign(Cursor + Request.ReadOnlySize, PageSize);
  Layout.DataOffset := Cursor;
  Layout.DataAddress := Request.BaseAddress + Cursor;
  Cursor := Cursor + Request.DataSize;
  Layout.FileSize := Cursor;
  Layout.BSSOffset := Cursor;
  Layout.BSSAddress := Request.BaseAddress + Cursor;
  Layout.MemorySize := Cursor + Request.BSSSize;
end;

procedure TargetValidate(const Target: TTargetDescriptor;
  var Diagnostics: TDiagnosticBag);
var
  I: Int32;
  EmptySpan: TSourceSpan;
begin
  EmptySpan := Default(TSourceSpan);
  if Target.Architecture <> taX86_64 then
    AddError(Diagnostics, dcBackendUnsupported, EmptySpan,
      'only the native x86-64 architecture is currently enabled');
  if Target.OperatingSystem <> tosLinux then
    AddError(Diagnostics, dcBackendUnsupported, EmptySpan,
      'only the Linux syscall ABI is currently enabled');
  if Target.ObjectFormat <> ofELF64 then
    AddError(Diagnostics, dcBackendUnsupported, EmptySpan,
      'only autonomous ELF64 output is currently enabled');
  if Target.DataLayout.Endian <> teLittle then
    AddError(Diagnostics, dcBackendUnsupported, EmptySpan,
      'x86-64 code generation requires little-endian layout');
  if Target.DataLayout.PointerSize <> 8 then
    AddError(Diagnostics, dcInternalError, EmptySpan,
      'x86-64 target pointer size must be eight bytes');
  if Target.DataLayout.StackAlignment <> 16 then
    AddError(Diagnostics, dcInternalError, EmptySpan,
      'System V AMD64 stack alignment must be sixteen bytes');
  if not TargetHasFeature(Target, cfSSE2) then
    AddError(Diagnostics, dcBackendUnsupported, EmptySpan,
      'the x86-64 backend requires SSE2 for real arithmetic');
  if Target.StackRegister > High(Target.Registers) then
    AddError(Diagnostics, dcInternalError, EmptySpan,
      'target stack register is outside the register table');
  if Target.FrameRegister > High(Target.Registers) then
    AddError(Diagnostics, dcInternalError, EmptySpan,
      'target frame register is outside the register table');
  for I := 0 to High(Target.ArgumentRegisters) do
    if Target.ArgumentRegisters[I] > High(Target.Registers) then
      AddError(Diagnostics, dcInternalError, EmptySpan,
        'argument register table contains an invalid register');
end;

end.

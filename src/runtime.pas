unit runtime;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, core, registers, x64, s67runtime, osruntime;

const
  LINUX_SYS_READ = 0;
  LINUX_SYS_WRITE = 1;
  LINUX_SYS_MMAP = 9;
  LINUX_SYS_MUNMAP = 11;
  LINUX_SYS_CLONE = 56;
  LINUX_SYS_EXIT = 60;
  LINUX_SYS_FUTEX = 202;

  LINUX_FUTEX_WAIT_PRIVATE = 128;
  LINUX_FUTEX_WAKE_PRIVATE = 129;

  FSIM_TASK_STATE_RUNNING = 0;
  FSIM_TASK_STATE_COMPLETED = 1;
  FSIM_TASK_STATE_CANCELLED = 2;
  FSIM_TASK_STATE_PANICKED = 3;
  FSIM_TASK_DESCRIPTOR_SIZE = 64;

  FSIM_HEAP_HEADER_SIZE = 32;
  FSIM_HEAP_ALLOCATED = 1;
  FSIM_HEAP_MARKED = 2;
  FSIM_HEAP_SCANNED = 4;
  FSIM_HEAP_LARGE = 8;
  FSIM_HEAP_PINNED = 16;
  FSIM_GC_ARENA_TRIGGER = 16;
  FSIM_HEAP_FREE_CLASSES = 12;

  LINUX_PROT_READ = 1;
  LINUX_PROT_WRITE = 2;
  LINUX_MAP_PRIVATE = 2;
  LINUX_MAP_ANONYMOUS = $20;

  LINUX_CLONE_VM = $00000100;
  LINUX_CLONE_FS = $00000200;
  LINUX_CLONE_FILES = $00000400;
  LINUX_CLONE_SIGHAND = $00000800;
  LINUX_CLONE_THREAD = $00010000;
  LINUX_CLONE_SYSVSEM = $00040000;
  LINUX_CLONE_CHILD_CLEARTID = $00200000;
  LINUX_CLONE_CHILD_SETTID = $01000000;
  LINUX_THREAD_FLAGS = LINUX_CLONE_VM or LINUX_CLONE_FS or
    LINUX_CLONE_FILES or LINUX_CLONE_SIGHAND or LINUX_CLONE_THREAD or
    LINUX_CLONE_SYSVSEM or LINUX_CLONE_CHILD_CLEARTID or
    LINUX_CLONE_CHILD_SETTID;

  FSIM_EXIT_RUNTIME = 70;
  FSIM_EXIT_NULL = 71;
  FSIM_EXIT_BOUNDS = 72;
  FSIM_EXIT_QUA = 73;
  FSIM_EXIT_OVERFLOW = 74;
  FSIM_EXIT_ALLOCATION = 75;
  FSIM_EXIT_ASSERT = 76;
  FSIM_EXIT_THREAD = 77;
  FSIM_EXIT_TEXT = 78;

type
  TRuntimeDataOffsets = packed record
    NewLineString: Int32;
    TrueString: Int32;
    FalseString: Int32;
    NullPanicString: Int32;
    BoundsPanicString: Int32;
    QuaPanicString: Int32;
    OverflowPanicString: Int32;
    AllocationPanicString: Int32;
    AssertPanicString: Int32;
    ThreadPanicString: Int32;
    TextPanicString: Int32;
    AllocatorLock: Int32;
    AllocatorCursor: Int32;
    AllocatorEnd: Int32;
    AllocatorHead: Int32;
    AllocatorFreeHead: Int32;
    GCStackTop: Int32;
    GCArenasSinceCollection: Int32;
    GCCollections: Int32;
    GCLiveBytes: Int32;
    GCReclaimedBytes: Int32;
    GCTaskHead: Int32;
    CriticalLock: Int32;
    S67: TS67NativeDataOffsets;
    OS: TOSNativeDataOffsets;
  end;

  TRuntimeLabels = packed record
    ExitProcess: Int32;
    WriteRaw: Int32;
    PrintString: Int32;
    PrintInteger: Int32;
    PrintReal: Int32;
    PrintFixed: Int32;
    PrintBoolean: Int32;
    PrintCharacter: Int32;
    PrintNewLine: Int32;
    Allocate: Int32;
    Free: Int32;
    GCMarkCandidate: Int32;
    GCCollect: Int32;
    GCPin: Int32;
    GCUnpin: Int32;
    GCLiveBytes: Int32;
    GCReclaimedBytes: Int32;
    GCCollectionCount: Int32;
    MemoryCopy: Int32;
    MemoryZero: Int32;
    StringConcat: Int32;
    StringEqual: Int32;
    StringLength: Int32;
    StringSlice: Int32;
    QuaCheck: Int32;
    NullCheck: Int32;
    BoundsCheck: Int32;
    Panic: Int32;
    PanicNull: Int32;
    PanicBounds: Int32;
    PanicQua: Int32;
    PanicOverflow: Int32;
    PanicAllocation: Int32;
    PanicAssert: Int32;
    PanicThread: Int32;
    PanicText: Int32;
    S67: TS67NativeLabels;
    OS: TOSNativeLabels;
    ThreadSpawn: Int32;
    ThreadJoin: Int32;
    ThreadCancel: Int32;
    FutureAwait: Int32;
    ThreadExit: Int32;
  end;

procedure RuntimeAllocateLabels(var Assembler: TX64Assembler;
  out Labels: TRuntimeLabels);
procedure RuntimeAppendConstants(var ReadOnlyData: TByteBuffer;
  out Offsets: TRuntimeDataOffsets);
procedure RuntimeAppendWritableData(var WritableData: TByteBuffer;
  var Offsets: TRuntimeDataOffsets);
procedure RuntimeEmit(var Assembler: TX64Assembler;
  const Labels: TRuntimeLabels; const Data: TRuntimeDataOffsets;
  WritableRootOffset, WritableRootBytes: Int32);

implementation

function AppendStringDescriptor(var Data: TByteBuffer;
  const Value: RawByteString): Int32;
begin
  BufferAlign(Data, 8, 0);
  Result := Data.Count;
  BufferAppendQWord(Data, Length(Value));
  if Length(Value) <> 0 then
    BufferAppend(Data, Value[1], Length(Value));
  BufferAppendByte(Data, 0);
end;

procedure RuntimeAppendConstants(var ReadOnlyData: TByteBuffer;
  out Offsets: TRuntimeDataOffsets);
begin
  FillChar(Offsets, SizeOf(Offsets), 0);
  Offsets.NewLineString := AppendStringDescriptor(ReadOnlyData, LineEnding);
  Offsets.TrueString := AppendStringDescriptor(ReadOnlyData, 'true');
  Offsets.FalseString := AppendStringDescriptor(ReadOnlyData, 'false');
  Offsets.NullPanicString := AppendStringDescriptor(ReadOnlyData,
    'fsim runtime: null reference violation' + LineEnding);
  Offsets.BoundsPanicString := AppendStringDescriptor(ReadOnlyData,
    'fsim runtime: index outside collection bounds' + LineEnding);
  Offsets.QuaPanicString := AppendStringDescriptor(ReadOnlyData,
    'fsim runtime: invalid QUA downcast' + LineEnding);
  Offsets.OverflowPanicString := AppendStringDescriptor(ReadOnlyData,
    'fsim runtime: checked integer overflow' + LineEnding);
  Offsets.AllocationPanicString := AppendStringDescriptor(ReadOnlyData,
    'fsim runtime: native allocation failed' + LineEnding);
  Offsets.AssertPanicString := AppendStringDescriptor(ReadOnlyData,
    'fsim runtime: assertion failed' + LineEnding);
  Offsets.ThreadPanicString := AppendStringDescriptor(ReadOnlyData,
    'fsim runtime: native thread creation failed' + LineEnding);
  Offsets.TextPanicString := AppendStringDescriptor(ReadOnlyData,
    'fsim runtime: invalid simula text operation' + LineEnding);
end;

procedure RuntimeAppendWritableData(var WritableData: TByteBuffer;
  var Offsets: TRuntimeDataOffsets);
begin
  BufferAlign(WritableData, 8, 0);
  Offsets.AllocatorLock := WritableData.Count;
  BufferAppendQWord(WritableData, 0);
  Offsets.AllocatorCursor := WritableData.Count;
  BufferAppendQWord(WritableData, 0);
  Offsets.AllocatorEnd := WritableData.Count;
  BufferAppendQWord(WritableData, 0);
  Offsets.AllocatorHead := WritableData.Count;
  BufferAppendQWord(WritableData, 0);
  Offsets.AllocatorFreeHead := WritableData.Count;
  BufferAppendQWord(WritableData, 0);
  BufferAppendQWord(WritableData, 0);
  BufferAppendQWord(WritableData, 0);
  BufferAppendQWord(WritableData, 0);
  BufferAppendQWord(WritableData, 0);
  BufferAppendQWord(WritableData, 0);
  BufferAppendQWord(WritableData, 0);
  BufferAppendQWord(WritableData, 0);
  BufferAppendQWord(WritableData, 0);
  BufferAppendQWord(WritableData, 0);
  BufferAppendQWord(WritableData, 0);
  BufferAppendQWord(WritableData, 0);
  Offsets.GCStackTop := WritableData.Count;
  BufferAppendQWord(WritableData, 0);
  Offsets.GCArenasSinceCollection := WritableData.Count;
  BufferAppendQWord(WritableData, 0);
  Offsets.GCCollections := WritableData.Count;
  BufferAppendQWord(WritableData, 0);
  Offsets.GCLiveBytes := WritableData.Count;
  BufferAppendQWord(WritableData, 0);
  Offsets.GCReclaimedBytes := WritableData.Count;
  BufferAppendQWord(WritableData, 0);
  Offsets.GCTaskHead := WritableData.Count;
  BufferAppendQWord(WritableData, 0);
  Offsets.CriticalLock := WritableData.Count;
  BufferAppendQWord(WritableData, 0);
end;

procedure RuntimeAllocateLabels(var Assembler: TX64Assembler;
  out Labels: TRuntimeLabels);
begin
  FillChar(Labels, SizeOf(Labels), 0);
  Labels.ExitProcess := X64NewLabel(Assembler);
  Labels.WriteRaw := X64NewLabel(Assembler);
  Labels.PrintString := X64NewLabel(Assembler);
  Labels.PrintInteger := X64NewLabel(Assembler);
  Labels.PrintReal := X64NewLabel(Assembler);
  Labels.PrintFixed := X64NewLabel(Assembler);
  Labels.PrintBoolean := X64NewLabel(Assembler);
  Labels.PrintCharacter := X64NewLabel(Assembler);
  Labels.PrintNewLine := X64NewLabel(Assembler);
  Labels.Allocate := X64NewLabel(Assembler);
  Labels.Free := X64NewLabel(Assembler);
  Labels.GCMarkCandidate := X64NewLabel(Assembler);
  Labels.GCCollect := X64NewLabel(Assembler);
  Labels.GCPin := X64NewLabel(Assembler);
  Labels.GCUnpin := X64NewLabel(Assembler);
  Labels.GCLiveBytes := X64NewLabel(Assembler);
  Labels.GCReclaimedBytes := X64NewLabel(Assembler);
  Labels.GCCollectionCount := X64NewLabel(Assembler);
  Labels.MemoryCopy := X64NewLabel(Assembler);
  Labels.MemoryZero := X64NewLabel(Assembler);
  Labels.StringConcat := X64NewLabel(Assembler);
  Labels.StringEqual := X64NewLabel(Assembler);
  Labels.StringLength := X64NewLabel(Assembler);
  Labels.StringSlice := X64NewLabel(Assembler);
  Labels.QuaCheck := X64NewLabel(Assembler);
  Labels.NullCheck := X64NewLabel(Assembler);
  Labels.BoundsCheck := X64NewLabel(Assembler);
  Labels.Panic := X64NewLabel(Assembler);
  Labels.PanicNull := X64NewLabel(Assembler);
  Labels.PanicBounds := X64NewLabel(Assembler);
  Labels.PanicQua := X64NewLabel(Assembler);
  Labels.PanicOverflow := X64NewLabel(Assembler);
  Labels.PanicAllocation := X64NewLabel(Assembler);
  Labels.PanicAssert := X64NewLabel(Assembler);
  Labels.PanicThread := X64NewLabel(Assembler);
  Labels.PanicText := X64NewLabel(Assembler);
  S67AllocateNativeLabels(Assembler, Labels.S67);
  OSAllocateNativeLabels(Assembler, Labels.OS);
  Labels.ThreadSpawn := X64NewLabel(Assembler);
  Labels.ThreadJoin := X64NewLabel(Assembler);
  Labels.ThreadCancel := X64NewLabel(Assembler);
  Labels.FutureAwait := X64NewLabel(Assembler);
  Labels.ThreadExit := X64NewLabel(Assembler);
end;

procedure EmitExit(var A: TX64Assembler; const L: TRuntimeLabels);
begin
  X64BindLabel(A, L.ExitProcess);
  X64MovRegImm64(A, xrRAX, LINUX_SYS_EXIT);
  X64Syscall(A);
  X64Int3(A);
end;

procedure EmitWriteRaw(var A: TX64Assembler; const L: TRuntimeLabels);
begin
  { rdi = byte pointer, rsi = byte count; returns bytes written or negative errno }
  X64BindLabel(A, L.WriteRaw);
  X64MovRegReg(A, xrRDX, xrRSI);
  X64MovRegReg(A, xrRSI, xrRDI);
  X64MovRegImm64(A, xrRDI, 1);
  X64MovRegImm64(A, xrRAX, LINUX_SYS_WRITE);
  X64Syscall(A);
  X64Ret(A);
end;

procedure EmitPrintString(var A: TX64Assembler; const L: TRuntimeLabels);
var
  EmptyLabel: Int32;
begin
  { rdi = pointer to [qword byte_length][UTF-8 bytes] }
  EmptyLabel := X64NewLabel(A);
  X64BindLabel(A, L.PrintString);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, EmptyLabel);
  X64MovRegMemBaseDisp(A, xrRSI, xrRDI, 0);
  X64AddRegImm32(A, xrRDI, 8);
  X64Call(A, L.WriteRaw);
  X64BindLabel(A, EmptyLabel);
  X64Ret(A);
end;

procedure EmitPrintInteger(var A: TX64Assembler; const L: TRuntimeLabels);
var
  NonZeroLabel, PositiveLabel, DigitLoop, DigitsDone: Int32;
begin
  { rdi = signed 64-bit integer }
  NonZeroLabel := X64NewLabel(A);
  PositiveLabel := X64NewLabel(A);
  DigitLoop := X64NewLabel(A);
  DigitsDone := X64NewLabel(A);
  X64BindLabel(A, L.PrintInteger);
  X64PushReg(A, xrRBP);
  X64MovRegReg(A, xrRBP, xrRSP);
  X64SubRegImm32(A, xrRSP, 80);
  X64MovRegReg(A, xrR8, xrRDI);
  X64LeaRegBaseDisp(A, xrRSI, xrRSP, 79);
  X64MovRegReg(A, xrRAX, xrRDI);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcNotEqual, NonZeroLabel);
  X64MovRegImm64(A, xrRDX, Ord('0'));
  X64MovMemBaseDispReg8(A, xrRSI, 0, xrRDX);
  X64MovRegImm64(A, xrRDX, 1);
  X64MovRegReg(A, xrRDI, xrRSI);
  X64Call(A, L.WriteRaw);
  X64Leave(A);
  X64Ret(A);

  X64BindLabel(A, NonZeroLabel);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcGreaterEqual, PositiveLabel);
  { Convert magnitude using unsigned two's-complement negation. This handles MinInt. }
  X64NegReg(A, xrRAX);
  X64BindLabel(A, PositiveLabel);
  X64MovRegImm64(A, xrR10, 10);
  X64BindLabel(A, DigitLoop);
  X64XorRegReg(A, xrRDX, xrRDX);
  X64DivReg(A, xrR10);
  X64AddRegImm32(A, xrRDX, Ord('0'));
  X64SubRegImm32(A, xrRSI, 1);
  X64MovMemBaseDispReg8(A, xrRSI, 0, xrRDX);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcNotEqual, DigitLoop);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcGreaterEqual, DigitsDone);
  X64MovRegImm64(A, xrRDX, Ord('-'));
  X64SubRegImm32(A, xrRSI, 1);
  X64MovMemBaseDispReg8(A, xrRSI, 0, xrRDX);
  X64BindLabel(A, DigitsDone);
  X64LeaRegBaseDisp(A, xrRDX, xrRSP, 79);
  X64SubRegReg(A, xrRDX, xrRSI);
  X64MovRegReg(A, xrRDI, xrRSI);
  X64MovRegReg(A, xrRSI, xrRDX);
  X64Call(A, L.WriteRaw);
  X64Leave(A);
  X64Ret(A);
end;

procedure EmitPrintReal(var A: TX64Assembler; const L: TRuntimeLabels);
var
  PositiveFraction, DigitLoop: Int32;
begin
  { rdi contains IEEE-754 binary64 bits. Format with six fractional digits. }
  PositiveFraction := X64NewLabel(A);
  DigitLoop := X64NewLabel(A);
  X64BindLabel(A, L.PrintReal);
  X64PushReg(A, xrRBP);
  X64MovRegReg(A, xrRBP, xrRSP);
  X64PushReg(A, xrRBX);
  X64SubRegImm32(A, xrRSP, 72);
  X64MovQXMMReg(A, xrXMM0, xrRDI);
  X64CVTTSD2SI(A, xrRBX, xrXMM0);
  X64MovRegReg(A, xrRDI, xrRBX);
  X64Call(A, L.PrintInteger);
  X64MovRegImm64(A, xrRDI, Ord('.'));
  X64Call(A, L.PrintCharacter);
  X64CVTSI2SD(A, xrXMM1, xrRBX);
  X64SubSD(A, xrXMM0, xrXMM1);
  X64MovRegImm64(A, xrRAX, QWord($412E848000000000)); { 1000000.0 }
  X64MovQXMMReg(A, xrXMM1, xrRAX);
  X64MulSD(A, xrXMM0, xrXMM1);
  X64CVTTSD2SI(A, xrRAX, xrXMM0);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcGreaterEqual, PositiveFraction);
  X64NegReg(A, xrRAX);
  X64BindLabel(A, PositiveFraction);
  X64LeaRegBaseDisp(A, xrRSI, xrRSP, 6);
  X64MovRegImm64(A, xrRCX, 6);
  X64MovRegImm64(A, xrR10, 10);
  { Fill six digits backwards, including leading zeros. }
  X64BindLabel(A, DigitLoop);
  X64XorRegReg(A, xrRDX, xrRDX);
  X64DivReg(A, xrR10);
  X64AddRegImm32(A, xrRDX, Ord('0'));
  X64SubRegImm32(A, xrRSI, 1);
  X64MovMemBaseDispReg8(A, xrRSI, 0, xrRDX);
  X64SubRegImm32(A, xrRCX, 1);
  X64JumpCondition(A, xcNotEqual, DigitLoop);
  X64MovRegReg(A, xrRDI, xrRSI);
  X64MovRegImm64(A, xrRSI, 6);
  X64Call(A, L.WriteRaw);
  X64AddRegImm32(A, xrRSP, 72);
  X64PopReg(A, xrRBX);
  X64Leave(A);
  X64Ret(A);
end;

procedure EmitPrintFixed(var A: TX64Assembler; const L: TRuntimeLabels);
var
  PositiveValue, DigitsClampedLow, DigitsClampedHigh, IntDigits,
  IntDigitLoop, IntDigitsDone, NoFraction, PowerLoop, FractionLoop,
  NoPad, PadLoop, NoSign: Int32;
begin
  { rdi = IEEE-754 binary64 bits, rsi = digits after the point, rdx = field
    width.  Right-justifies the sign and digits into the field and prints. }
  PositiveValue := X64NewLabel(A);
  DigitsClampedLow := X64NewLabel(A);
  DigitsClampedHigh := X64NewLabel(A);
  IntDigits := X64NewLabel(A);
  IntDigitLoop := X64NewLabel(A);
  IntDigitsDone := X64NewLabel(A);
  NoFraction := X64NewLabel(A);
  PowerLoop := X64NewLabel(A);
  FractionLoop := X64NewLabel(A);
  NoPad := X64NewLabel(A);
  PadLoop := X64NewLabel(A);
  NoSign := X64NewLabel(A);
  X64BindLabel(A, L.PrintFixed);
  X64PushReg(A, xrRBP);
  X64MovRegReg(A, xrRBP, xrRSP);
  X64PushReg(A, xrRBX);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64PushReg(A, xrR15);
  X64SubRegImm32(A, xrRSP, 176);
  X64MovRegReg(A, xrR12, xrRSI);
  X64MovRegReg(A, xrR13, xrRDX);
  X64CmpRegImm32(A, xrR12, 0);
  X64JumpCondition(A, xcGreaterEqual, DigitsClampedLow);
  X64XorRegReg(A, xrR12, xrR12);
  X64BindLabel(A, DigitsClampedLow);
  X64CmpRegImm32(A, xrR12, 18);
  X64JumpCondition(A, xcLessEqual, DigitsClampedHigh);
  X64MovRegImm64(A, xrR12, 18);
  X64BindLabel(A, DigitsClampedHigh);
  X64MovRegImm64(A, xrR10, 10);
  X64MovQXMMReg(A, xrXMM0, xrRDI);
  X64CVTTSD2SI(A, xrRBX, xrXMM0);
  X64MovRegReg(A, xrRAX, xrRDI);
  X64ShrRegImm8(A, xrRAX, 63);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, PositiveValue);
  X64MovRegImm64(A, xrR15, 1);
  X64CVTSI2SD(A, xrXMM1, xrRBX);
  X64SubSD(A, xrXMM0, xrXMM1);
  X64MovRegImm64(A, xrRAX, 0);
  X64MovQXMMReg(A, xrXMM2, xrRAX);
  X64SubSD(A, xrXMM2, xrXMM0);
  X64MovQRegXMM(A, xrRAX, xrXMM2);
  X64MovQXMMReg(A, xrXMM0, xrRAX);
  X64NegReg(A, xrRBX);
  X64CVTSI2SD(A, xrXMM1, xrRBX);
  X64AddSD(A, xrXMM0, xrXMM1);
  X64Jump(A, IntDigits);
  X64BindLabel(A, PositiveValue);
  X64MovRegImm64(A, xrR15, 0);
  X64CVTSI2SD(A, xrXMM1, xrRBX);
  X64SubSD(A, xrXMM0, xrXMM1);
  X64AddSD(A, xrXMM0, xrXMM1);
  X64BindLabel(A, IntDigits);
  X64LeaRegBaseDisp(A, xrR14, xrRSP, 127);
  X64TestRegReg(A, xrRBX, xrRBX);
  X64JumpCondition(A, xcNotEqual, IntDigitLoop);
  X64SubRegImm32(A, xrR14, 1);
  X64MovRegImm64(A, xrRDX, Ord('0'));
  X64MovMemBaseDispReg8(A, xrR14, 0, xrRDX);
  X64Jump(A, IntDigitsDone);
  X64BindLabel(A, IntDigitLoop);
  X64MovRegReg(A, xrRAX, xrRBX);
  X64XorRegReg(A, xrRDX, xrRDX);
  X64DivReg(A, xrR10);
  X64MovRegReg(A, xrRBX, xrRAX);
  X64AddRegImm32(A, xrRDX, Ord('0'));
  X64SubRegImm32(A, xrR14, 1);
  X64MovMemBaseDispReg8(A, xrR14, 0, xrRDX);
  X64TestRegReg(A, xrRBX, xrRBX);
  X64JumpCondition(A, xcNotEqual, IntDigitLoop);
  X64BindLabel(A, IntDigitsDone);
  X64MovRegReg(A, xrRBX, xrR14);
  X64LeaRegBaseDisp(A, xrRSI, xrRSP, 127);
  X64AddRegReg(A, xrRSI, xrR12);
  X64SubRegReg(A, xrRSI, xrRBX);
  X64MovRegReg(A, xrRBX, xrRSI);
  X64TestRegReg(A, xrR12, xrR12);
  X64JumpCondition(A, xcEqual, NoFraction);
  X64SubSD(A, xrXMM0, xrXMM1);
  X64MovRegImm64(A, xrRAX, 1);
  X64MovRegReg(A, xrRCX, xrR12);
  X64BindLabel(A, PowerLoop);
  X64IMulRegRegImm32(A, xrRAX, xrRAX, 10);
  X64SubRegImm32(A, xrRCX, 1);
  X64JumpCondition(A, xcNotEqual, PowerLoop);
  X64CVTSI2SD(A, xrXMM1, xrRAX);
  X64MulSD(A, xrXMM0, xrXMM1);
  X64CVTTSD2SI(A, xrRAX, xrXMM0);
  X64LeaRegBaseDisp(A, xrRDI, xrRSP, 127);
  X64MovRegImm64(A, xrRDX, Ord('.'));
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRDX);
  X64LeaRegBaseDisp(A, xrRSI, xrRSP, 127);
  X64AddRegReg(A, xrRSI, xrR12);
  X64MovRegReg(A, xrRCX, xrR12);
  X64BindLabel(A, FractionLoop);
  X64XorRegReg(A, xrRDX, xrRDX);
  X64DivReg(A, xrR10);
  X64AddRegImm32(A, xrRDX, Ord('0'));
  X64MovMemBaseDispReg8(A, xrRSI, 0, xrRDX);
  X64SubRegImm32(A, xrRSI, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64JumpCondition(A, xcNotEqual, FractionLoop);
  X64AddRegImm32(A, xrRBX, 1);
  X64BindLabel(A, NoFraction);
  X64MovRegReg(A, xrRAX, xrR13);
  X64SubRegReg(A, xrRAX, xrRBX);
  X64SubRegReg(A, xrRAX, xrR15);
  X64MovRegReg(A, xrR12, xrRAX);
  X64TestRegReg(A, xrR12, xrR12);
  X64JumpCondition(A, xcLessEqual, NoPad);
  X64BindLabel(A, PadLoop);
  X64MovRegImm64(A, xrRDI, 32);
  X64Call(A, L.PrintCharacter);
  X64SubRegImm32(A, xrR12, 1);
  X64JumpCondition(A, xcNotEqual, PadLoop);
  X64BindLabel(A, NoPad);
  X64TestRegReg(A, xrR15, xrR15);
  X64JumpCondition(A, xcEqual, NoSign);
  X64MovRegImm64(A, xrRDI, Ord('-'));
  X64Call(A, L.PrintCharacter);
  X64BindLabel(A, NoSign);
  X64MovRegReg(A, xrRDI, xrR14);
  X64MovRegReg(A, xrRSI, xrRBX);
  X64Call(A, L.WriteRaw);
  X64AddRegImm32(A, xrRSP, 176);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64PopReg(A, xrRBX);
  X64Leave(A);
  X64Ret(A);
end;

procedure EmitPrintBoolean(var A: TX64Assembler; const L: TRuntimeLabels;
  const D: TRuntimeDataOffsets);
var
  FalseLabel, ReadyLabel: Int32;
begin
  FalseLabel := X64NewLabel(A);
  ReadyLabel := X64NewLabel(A);
  X64BindLabel(A, L.PrintBoolean);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, FalseLabel);
  X64LeaRegRipData(A, xrRDI, D.TrueString, 0);
  X64Jump(A, ReadyLabel);
  X64BindLabel(A, FalseLabel);
  X64LeaRegRipData(A, xrRDI, D.FalseString, 0);
  X64BindLabel(A, ReadyLabel);
  X64Jump(A, L.PrintString);
end;

procedure EmitPrintCharacter(var A: TX64Assembler; const L: TRuntimeLabels);
begin
  { Character is currently a Unicode scalar constrained to ASCII in native I/O. }
  X64BindLabel(A, L.PrintCharacter);
  X64SubRegImm32(A, xrRSP, 8);
  X64MovMemBaseDispReg8(A, xrRSP, 0, xrRDI);
  X64MovRegReg(A, xrRDI, xrRSP);
  X64MovRegImm64(A, xrRSI, 1);
  X64Call(A, L.WriteRaw);
  X64AddRegImm32(A, xrRSP, 8);
  X64Ret(A);
end;

procedure EmitPrintNewLine(var A: TX64Assembler; const L: TRuntimeLabels;
  const D: TRuntimeDataOffsets);
begin
  X64BindLabel(A, L.PrintNewLine);
  X64LeaRegRipData(A, xrRDI, D.NewLineString, 0);
  X64Jump(A, L.PrintString);
end;

procedure EmitAllocate(var A: TX64Assembler; const L: TRuntimeLabels;
  const D: TRuntimeDataOffsets);
const
  SMALL_LIMIT = 32768;
  ARENA_BYTES = 1024 * 1024;
var
  NoAutoGC, SmallPath, ClassLoop, ClassReady, FreeRetry, NeedBump,
  ZeroLoop, ZeroDone, FastRetry, NeedRefill, LockRetry, LockHeld,
  RefillArena, RefillSuccess, ReleaseAndRetry, FreshLinkRetry,
  FreshReady, LargeMap, LargeSuccess, LargeLinkRetry, LargeReady: Int32;
begin
  { The hot path remains a slab bump-pointer CAS.  GC-reclaimed small blocks
    are kept in twelve power-of-two free lists (16 .. 32768 bytes), so reuse
    is also lock-free and never calls the kernel.  Large objects are separate
    mappings and can be returned to Linux by the collector. }
  NoAutoGC := X64NewLabel(A);
  SmallPath := X64NewLabel(A);
  ClassLoop := X64NewLabel(A);
  ClassReady := X64NewLabel(A);
  FreeRetry := X64NewLabel(A);
  NeedBump := X64NewLabel(A);
  ZeroLoop := X64NewLabel(A);
  ZeroDone := X64NewLabel(A);
  FastRetry := X64NewLabel(A);
  NeedRefill := X64NewLabel(A);
  LockRetry := X64NewLabel(A);
  LockHeld := X64NewLabel(A);
  RefillArena := X64NewLabel(A);
  RefillSuccess := X64NewLabel(A);
  ReleaseAndRetry := X64NewLabel(A);
  FreshLinkRetry := X64NewLabel(A);
  FreshReady := X64NewLabel(A);
  LargeMap := X64NewLabel(A);
  LargeSuccess := X64NewLabel(A);
  LargeLinkRetry := X64NewLabel(A);
  LargeReady := X64NewLabel(A);

  X64BindLabel(A, L.Allocate);
  { Collection is amortized by arena creation rather than every byte
    allocated.  If workers are alive GCCollect simply declines the cycle. }
  X64LeaRegRipWritable(A, xrR8, D.GCArenasSinceCollection, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrR8, 0);
  X64CmpRegImm32(A, xrRAX, FSIM_GC_ARENA_TRIGGER);
  X64JumpCondition(A, xcBelow, NoAutoGC);
  X64PushReg(A, xrRDI);
  X64Call(A, L.GCCollect);
  X64PopReg(A, xrRDI);
  X64BindLabel(A, NoAutoGC);

  X64CmpRegImm32(A, xrRDI, 16);
  X64JumpCondition(A, xcAboveEqual, FreshReady);
  X64MovRegImm64(A, xrRDI, 16);
  X64BindLabel(A, FreshReady);
  X64CmpRegImm32(A, xrRDI, SMALL_LIMIT);
  X64JumpCondition(A, xcBelowEqual, SmallPath);
  X64Jump(A, LargeMap);

  X64BindLabel(A, SmallPath);
  { Round small allocations to a power of two.  This makes reclaimed blocks
    reusable without a global search or allocator lock. }
  X64MovRegImm64(A, xrRSI, 16);
  X64XorRegReg(A, xrRDX, xrRDX); { size-class index }
  X64BindLabel(A, ClassLoop);
  X64CmpRegReg(A, xrRSI, xrRDI);
  X64JumpCondition(A, xcAboveEqual, ClassReady);
  X64ShlRegImm8(A, xrRSI, 1);
  X64AddRegImm32(A, xrRDX, 1);
  X64Jump(A, ClassLoop);
  X64BindLabel(A, ClassReady);

  { Try the matching free-list first. }
  X64LeaRegRipWritable(A, xrR9, D.AllocatorFreeHead, 0);
  X64ShlRegImm8(A, xrRDX, 3);
  X64AddRegReg(A, xrR9, xrRDX);
  X64BindLabel(A, FreeRetry);
  X64MovRegMemBaseDisp(A, xrRAX, xrR9, 0);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, NeedBump);
  X64MovRegMemBaseDisp(A, xrRCX, xrRAX, 8);
  X64LockCmpXchgMemBaseDispReg(A, xrR9, 0, xrRCX);
  X64JumpCondition(A, xcNotEqual, FreeRetry);
  { rax is the popped allocation header. }
  X64MovRegReg(A, xrR8, xrRAX);
  X64MovRegImm64(A, xrRCX, FSIM_HEAP_ALLOCATED);
  X64MovMemBaseDispReg(A, xrR8, 24, xrRCX);
  X64XorRegReg(A, xrRCX, xrRCX);
  X64MovMemBaseDispReg(A, xrR8, 8, xrRCX);
  { Recycled storage is cleared so allocation has the same semantics as
    freshly-mapped memory and stale references cannot keep objects alive. }
  X64LeaRegBaseDisp(A, xrRDX, xrR8, FSIM_HEAP_HEADER_SIZE);
  X64MovRegReg(A, xrRCX, xrRSI);
  X64ShrRegImm8(A, xrRCX, 3);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64BindLabel(A, ZeroLoop);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, ZeroDone);
  X64MovMemBaseDispReg(A, xrRDX, 0, xrRAX);
  X64AddRegImm32(A, xrRDX, 8);
  X64SubRegImm32(A, xrRCX, 1);
  X64Jump(A, ZeroLoop);
  X64BindLabel(A, ZeroDone);
  X64LeaRegBaseDisp(A, xrRAX, xrR8, FSIM_HEAP_HEADER_SIZE);
  X64Ret(A);

  X64BindLabel(A, NeedBump);
  X64LeaRegRipWritable(A, xrR9, D.AllocatorCursor, 0);
  X64LeaRegRipWritable(A, xrR10, D.AllocatorEnd, 0);
  X64AddRegImm32(A, xrRSI, FSIM_HEAP_HEADER_SIZE); { reservation bytes }

  X64BindLabel(A, FastRetry);
  X64MovRegMemBaseDisp(A, xrRAX, xrR9, 0);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, NeedRefill);
  X64MovRegReg(A, xrRCX, xrRAX);
  X64AddRegReg(A, xrRCX, xrRSI);
  X64MovRegMemBaseDisp(A, xrRDX, xrR10, 0);
  X64CmpRegReg(A, xrRCX, xrRDX);
  X64JumpCondition(A, xcAbove, NeedRefill);
  X64LockCmpXchgMemBaseDispReg(A, xrR9, 0, xrRCX);
  X64JumpCondition(A, xcNotEqual, FastRetry);
  { rax is the fresh header. Restore payload size from reservation bytes. }
  X64MovRegReg(A, xrR8, xrRAX);
  X64SubRegImm32(A, xrRSI, FSIM_HEAP_HEADER_SIZE);
  X64XorRegReg(A, xrRCX, xrRCX);
  X64MovMemBaseDispReg(A, xrR8, 8, xrRCX);
  X64MovMemBaseDispReg(A, xrR8, 16, xrRSI);
  X64MovRegImm64(A, xrRCX, FSIM_HEAP_ALLOCATED);
  X64MovMemBaseDispReg(A, xrR8, 24, xrRCX);
  { Every allocation is on an intrusive list used only by the collector. }
  X64LeaRegRipWritable(A, xrR9, D.AllocatorHead, 0);
  X64BindLabel(A, FreshLinkRetry);
  X64MovRegMemBaseDisp(A, xrRAX, xrR9, 0);
  X64MovMemBaseDispReg(A, xrR8, 0, xrRAX);
  X64MovRegReg(A, xrRCX, xrR8);
  X64LockCmpXchgMemBaseDispReg(A, xrR9, 0, xrRCX);
  X64JumpCondition(A, xcNotEqual, FreshLinkRetry);
  X64LeaRegBaseDisp(A, xrRAX, xrR8, FSIM_HEAP_HEADER_SIZE);
  X64Ret(A);

  X64BindLabel(A, NeedRefill);
  { rsi still includes the header. }
  X64LeaRegRipWritable(A, xrR8, D.AllocatorLock, 0);
  X64BindLabel(A, LockRetry);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64MovRegImm64(A, xrRCX, 1);
  X64LockCmpXchgMemBaseDispReg(A, xrR8, 0, xrRCX);
  X64JumpCondition(A, xcEqual, LockHeld);
  X64Pause(A);
  X64Jump(A, LockRetry);

  X64BindLabel(A, LockHeld);
  { Another allocator may have refilled while we waited. }
  X64LeaRegRipWritable(A, xrR9, D.AllocatorCursor, 0);
  X64LeaRegRipWritable(A, xrR10, D.AllocatorEnd, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrR9, 0);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, RefillArena);
  X64MovRegReg(A, xrRCX, xrRAX);
  X64AddRegReg(A, xrRCX, xrRSI);
  X64MovRegMemBaseDisp(A, xrRDX, xrR10, 0);
  X64CmpRegReg(A, xrRCX, xrRDX);
  X64JumpCondition(A, xcBelowEqual, ReleaseAndRetry);

  X64BindLabel(A, RefillArena);
  X64PushReg(A, xrRSI);
  X64XorRegReg(A, xrRDI, xrRDI);
  X64MovRegImm64(A, xrRSI, ARENA_BYTES);
  X64MovRegImm64(A, xrRDX, LINUX_PROT_READ or LINUX_PROT_WRITE);
  X64MovRegImm64(A, xrR10, LINUX_MAP_PRIVATE or LINUX_MAP_ANONYMOUS);
  X64MovRegImm64(A, xrR8, High(QWord));
  X64XorRegReg(A, xrR9, xrR9);
  X64MovRegImm64(A, xrRAX, LINUX_SYS_MMAP);
  X64Syscall(A);
  X64PopReg(A, xrRSI);
  X64CmpRegImm32(A, xrRAX, -4095);
  X64JumpCondition(A, xcBelow, RefillSuccess);
  X64LeaRegRipWritable(A, xrR8, D.AllocatorLock, 0);
  X64XorRegReg(A, xrRCX, xrRCX);
  X64MovMemBaseDispReg(A, xrR8, 0, xrRCX);
  X64Jump(A, L.PanicAllocation);

  X64BindLabel(A, RefillSuccess);
  X64MovRegReg(A, xrR11, xrRAX);
  X64LeaRegRipWritable(A, xrR9, D.AllocatorCursor, 0);
  X64LeaRegRipWritable(A, xrR10, D.AllocatorEnd, 0);
  X64MovMemBaseDispReg(A, xrR9, 0, xrR11);
  X64MovRegReg(A, xrRCX, xrR11);
  X64AddRegImm32(A, xrRCX, ARENA_BYTES);
  X64MovMemBaseDispReg(A, xrR10, 0, xrRCX);
  X64LeaRegRipWritable(A, xrR8, D.GCArenasSinceCollection, 0);
  X64MovRegMemBaseDisp(A, xrRCX, xrR8, 0);
  X64AddRegImm32(A, xrRCX, 1);
  X64MovMemBaseDispReg(A, xrR8, 0, xrRCX);

  X64BindLabel(A, ReleaseAndRetry);
  X64LeaRegRipWritable(A, xrR8, D.AllocatorLock, 0);
  X64MemoryFence(A);
  X64XorRegReg(A, xrRCX, xrRCX);
  X64XchgMemBaseDispReg(A, xrR8, 0, xrRCX);
  X64LeaRegRipWritable(A, xrR9, D.AllocatorCursor, 0);
  X64LeaRegRipWritable(A, xrR10, D.AllocatorEnd, 0);
  X64Jump(A, FastRetry);

  X64BindLabel(A, LargeMap);
  X64AddRegImm32(A, xrRDI, 15);
  X64AndRegImm32(A, xrRDI, -16);
  X64PushReg(A, xrRDI); { payload bytes }
  X64MovRegReg(A, xrRSI, xrRDI);
  X64AddRegImm32(A, xrRSI, FSIM_HEAP_HEADER_SIZE);
  X64XorRegReg(A, xrRDI, xrRDI);
  X64MovRegImm64(A, xrRDX, LINUX_PROT_READ or LINUX_PROT_WRITE);
  X64MovRegImm64(A, xrR10, LINUX_MAP_PRIVATE or LINUX_MAP_ANONYMOUS);
  X64MovRegImm64(A, xrR8, High(QWord));
  X64XorRegReg(A, xrR9, xrR9);
  X64MovRegImm64(A, xrRAX, LINUX_SYS_MMAP);
  X64Syscall(A);
  X64PopReg(A, xrRSI);
  X64CmpRegImm32(A, xrRAX, -4095);
  X64JumpCondition(A, xcBelow, LargeSuccess);
  X64Jump(A, L.PanicAllocation);

  X64BindLabel(A, LargeSuccess);
  X64MovRegReg(A, xrR8, xrRAX);
  X64XorRegReg(A, xrRCX, xrRCX);
  X64MovMemBaseDispReg(A, xrR8, 8, xrRCX);
  X64MovMemBaseDispReg(A, xrR8, 16, xrRSI);
  X64MovRegImm64(A, xrRCX, FSIM_HEAP_ALLOCATED or FSIM_HEAP_LARGE);
  X64MovMemBaseDispReg(A, xrR8, 24, xrRCX);
  X64LeaRegRipWritable(A, xrR9, D.AllocatorHead, 0);
  X64BindLabel(A, LargeLinkRetry);
  X64MovRegMemBaseDisp(A, xrRAX, xrR9, 0);
  X64MovMemBaseDispReg(A, xrR8, 0, xrRAX);
  X64MovRegReg(A, xrRCX, xrR8);
  X64LockCmpXchgMemBaseDispReg(A, xrR9, 0, xrRCX);
  X64JumpCondition(A, xcNotEqual, LargeLinkRetry);
  X64LeaRegRipWritable(A, xrR9, D.GCArenasSinceCollection, 0);
  X64MovRegMemBaseDisp(A, xrRCX, xrR9, 0);
  X64AddRegImm32(A, xrRCX, 1);
  X64MovMemBaseDispReg(A, xrR9, 0, xrRCX);
  X64LeaRegBaseDisp(A, xrRAX, xrR8, FSIM_HEAP_HEADER_SIZE);
  X64BindLabel(A, LargeReady);
  X64Ret(A);
end;

procedure EmitFree(var A: TX64Assembler; const L: TRuntimeLabels);
begin
  { Internal raw mapping release.  Managed user allocations are reclaimed by
    GCCollect; this label is deliberately not exposed as a language builtin. }
  X64BindLabel(A, L.Free);
  X64MovRegImm64(A, xrRAX, LINUX_SYS_MUNMAP);
  X64Syscall(A);
  X64Ret(A);
end;

procedure EmitGCMarkCandidate(var A: TX64Assembler; const L: TRuntimeLabels;
  const D: TRuntimeDataOffsets);
var
  LoopLabel, NextLabel, DoneLabel, FoundLabel: Int32;
begin
  { rdi may be an exact or interior managed pointer.  Interior recognition is
    intentional: strict SIMULA text frames and FFI pointer arithmetic can
    retain a managed mapping through a pointer into its payload. }
  LoopLabel := X64NewLabel(A);
  NextLabel := X64NewLabel(A);
  DoneLabel := X64NewLabel(A);
  FoundLabel := X64NewLabel(A);
  X64BindLabel(A, L.GCMarkCandidate);
  X64LeaRegRipWritable(A, xrR8, D.AllocatorHead, 0);
  X64MovRegMemBaseDisp(A, xrR8, xrR8, 0);
  X64BindLabel(A, LoopLabel);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, DoneLabel);
  X64MovRegMemBaseDisp(A, xrRAX, xrR8, 24);
  X64MovRegReg(A, xrRCX, xrRAX);
  X64AndRegImm32(A, xrRCX, FSIM_HEAP_ALLOCATED);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, NextLabel);
  X64LeaRegBaseDisp(A, xrR9, xrR8, FSIM_HEAP_HEADER_SIZE);
  X64CmpRegReg(A, xrRDI, xrR9);
  X64JumpCondition(A, xcBelow, NextLabel);
  X64MovRegMemBaseDisp(A, xrR10, xrR8, 16);
  X64AddRegReg(A, xrR10, xrR9);
  X64CmpRegReg(A, xrRDI, xrR10);
  X64JumpCondition(A, xcBelow, FoundLabel);
  X64BindLabel(A, NextLabel);
  X64MovRegMemBaseDisp(A, xrR8, xrR8, 0);
  X64Jump(A, LoopLabel);
  X64BindLabel(A, FoundLabel);
  X64MovRegImm64(A, xrRCX, FSIM_HEAP_MARKED);
  X64OrRegReg(A, xrRAX, xrRCX);
  X64MovMemBaseDispReg(A, xrR8, 24, xrRAX);
  X64BindLabel(A, DoneLabel);
  X64Ret(A);
end;

procedure EmitGCPinControl(var A: TX64Assembler; const L: TRuntimeLabels;
  const D: TRuntimeDataOffsets);
var
  CommonLabel, LoopLabel, NextLabel, FoundLabel, UpdateRetry,
  DoUnpin, DoneFalse, DoneTrue: Int32;
begin
  { A non-moving heap does not need pinning for address stability, but a C
    library may retain a managed pointer after the fsim call returns.  pin/unpin
    make that ownership explicit so a pointer held only by C remains a GC root. }
  CommonLabel := X64NewLabel(A);
  LoopLabel := X64NewLabel(A);
  NextLabel := X64NewLabel(A);
  FoundLabel := X64NewLabel(A);
  UpdateRetry := X64NewLabel(A);
  DoUnpin := X64NewLabel(A);
  DoneFalse := X64NewLabel(A);
  DoneTrue := X64NewLabel(A);

  X64BindLabel(A, L.GCPin);
  X64MovRegImm64(A, xrR11, 1);
  X64Jump(A, CommonLabel);
  X64BindLabel(A, L.GCUnpin);
  X64XorRegReg(A, xrR11, xrR11);

  X64BindLabel(A, CommonLabel);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, DoneFalse);
  X64LeaRegRipWritable(A, xrR8, D.AllocatorHead, 0);
  X64MovRegMemBaseDisp(A, xrR8, xrR8, 0);
  X64BindLabel(A, LoopLabel);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, DoneFalse);
  X64MovRegMemBaseDisp(A, xrRAX, xrR8, 24);
  X64MovRegReg(A, xrRCX, xrRAX);
  X64AndRegImm32(A, xrRCX, FSIM_HEAP_ALLOCATED);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, NextLabel);
  X64LeaRegBaseDisp(A, xrR9, xrR8, FSIM_HEAP_HEADER_SIZE);
  X64CmpRegReg(A, xrRDI, xrR9);
  X64JumpCondition(A, xcBelow, NextLabel);
  X64MovRegMemBaseDisp(A, xrR10, xrR8, 16);
  X64AddRegReg(A, xrR10, xrR9);
  X64CmpRegReg(A, xrRDI, xrR10);
  X64JumpCondition(A, xcBelow, FoundLabel);
  X64BindLabel(A, NextLabel);
  X64MovRegMemBaseDisp(A, xrR8, xrR8, 0);
  X64Jump(A, LoopLabel);

  X64BindLabel(A, FoundLabel);
  X64BindLabel(A, UpdateRetry);
  X64MovRegMemBaseDisp(A, xrRAX, xrR8, 24);
  X64MovRegReg(A, xrRCX, xrRAX);
  X64AndRegImm32(A, xrRCX, FSIM_HEAP_ALLOCATED);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, DoneFalse);
  X64TestRegReg(A, xrR11, xrR11);
  X64JumpCondition(A, xcEqual, DoUnpin);
  X64MovRegReg(A, xrRCX, xrRAX);
  X64MovRegImm64(A, xrR10, FSIM_HEAP_PINNED);
  X64OrRegReg(A, xrRCX, xrR10);
  X64LockCmpXchgMemBaseDispReg(A, xrR8, 24, xrRCX);
  X64JumpCondition(A, xcNotEqual, UpdateRetry);
  X64Jump(A, DoneTrue);

  X64BindLabel(A, DoUnpin);
  X64MovRegReg(A, xrRCX, xrRAX);
  X64AndRegImm32(A, xrRCX, not FSIM_HEAP_PINNED);
  X64LockCmpXchgMemBaseDispReg(A, xrR8, 24, xrRCX);
  X64JumpCondition(A, xcNotEqual, UpdateRetry);

  X64BindLabel(A, DoneTrue);
  X64MovRegImm64(A, xrRAX, 1);
  X64Ret(A);
  X64BindLabel(A, DoneFalse);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitGCCollect(var A: TX64Assembler; const L: TRuntimeLabels;
  const D: TRuntimeDataOffsets; WritableRootOffset, WritableRootBytes: Int32);
var
  TaskLoop, TaskDone, AbortLabel, ClearLoop, ClearNext, RootStackLoop,
  RootStackDone, RootDataLoop, RootDataDone, ClosureAgain, ClosureLoop,
  ClosureNext, ScanLoop, ScanDone, ClosureDone, SweepLoop, SweepLive,
  SweepDeadSmall, SweepDeadLarge, SweepUnallocated, SweepNext, SweepFinish,
  ClassLoop, ClassReady, LargeHasPrev, ReleaseLarge: Int32;
begin
  TaskLoop := X64NewLabel(A);
  TaskDone := X64NewLabel(A);
  AbortLabel := X64NewLabel(A);
  ClearLoop := X64NewLabel(A);
  ClearNext := X64NewLabel(A);
  RootStackLoop := X64NewLabel(A);
  RootStackDone := X64NewLabel(A);
  RootDataLoop := X64NewLabel(A);
  RootDataDone := X64NewLabel(A);
  ClosureAgain := X64NewLabel(A);
  ClosureLoop := X64NewLabel(A);
  ClosureNext := X64NewLabel(A);
  ScanLoop := X64NewLabel(A);
  ScanDone := X64NewLabel(A);
  ClosureDone := X64NewLabel(A);
  SweepLoop := X64NewLabel(A);
  SweepLive := X64NewLabel(A);
  SweepDeadSmall := X64NewLabel(A);
  SweepDeadLarge := X64NewLabel(A);
  SweepUnallocated := X64NewLabel(A);
  SweepNext := X64NewLabel(A);
  SweepFinish := X64NewLabel(A);
  ClassLoop := X64NewLabel(A);
  ClassReady := X64NewLabel(A);
  LargeHasPrev := X64NewLabel(A);
  ReleaseLarge := X64NewLabel(A);

  X64BindLabel(A, L.GCCollect);
  X64PushReg(A, xrRBX);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64PushReg(A, xrR15);

  { Collection is quiescent with respect to fsim native tasks.  Allocation
    itself remains concurrent; a collection simply skips if any clone still
    has a non-zero child TID. }
  X64LeaRegRipWritable(A, xrR12, D.GCTaskHead, 0);
  X64MovRegMemBaseDisp(A, xrR13, xrR12, 0);
  X64BindLabel(A, TaskLoop);
  X64TestRegReg(A, xrR13, xrR13);
  X64JumpCondition(A, xcEqual, TaskDone);
  X64MovRegMemBaseDisp(A, xrRAX, xrR13,
    FSIM_HEAP_HEADER_SIZE + 16);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcNotEqual, AbortLabel);
  X64MovRegMemBaseDisp(A, xrR13, xrR13, 8);
  X64Jump(A, TaskLoop);
  X64BindLabel(A, TaskDone);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64MovMemBaseDispReg(A, xrR12, 0, xrRAX); { retire completed task list }

  { Clear transient mark bits. }
  X64LeaRegRipWritable(A, xrR12, D.AllocatorHead, 0);
  X64MovRegMemBaseDisp(A, xrR12, xrR12, 0);
  X64BindLabel(A, ClearLoop);
  X64TestRegReg(A, xrR12, xrR12);
  X64JumpCondition(A, xcEqual, RootStackLoop);
  X64MovRegMemBaseDisp(A, xrRAX, xrR12, 24);
  X64AndRegImm32(A, xrRAX, -7);
  { Always persist the cleared transient bits.  Pinned blocks are then
    promoted back to marked roots below. }
  X64MovMemBaseDispReg(A, xrR12, 24, xrRAX);
  X64MovRegReg(A, xrRCX, xrRAX);
  X64AndRegImm32(A, xrRCX, FSIM_HEAP_PINNED);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, ClearNext);
  X64MovRegImm64(A, xrRCX, FSIM_HEAP_MARKED);
  X64OrRegReg(A, xrRAX, xrRCX);
  X64MovMemBaseDispReg(A, xrR12, 24, xrRAX);
  X64BindLabel(A, ClearNext);
  X64MovRegMemBaseDisp(A, xrR12, xrR12, 0);
  X64Jump(A, ClearLoop);

  { Conservative main-stack roots. }
  X64BindLabel(A, RootStackLoop);
  X64MovRegReg(A, xrR12, xrRSP);
  X64LeaRegRipWritable(A, xrR13, D.GCStackTop, 0);
  X64MovRegMemBaseDisp(A, xrR13, xrR13, 0);
  X64BindLabel(A, RootStackDone);
  X64CmpRegReg(A, xrR12, xrR13);
  X64JumpCondition(A, xcAboveEqual, RootDataLoop);
  X64MovRegMemBaseDisp(A, xrRDI, xrR12, 0);
  X64Call(A, L.GCMarkCandidate);
  X64AddRegImm32(A, xrR12, 8);
  X64Jump(A, RootStackDone);

  { Scan only program-owned writable roots.  Runtime allocator metadata lives
    in the same ELF segment, but scanning AllocatorHead/free-list/cursor state
    as roots would couple reachability to allocator internals and can retain
    otherwise dead objects through incidental interior-looking values. }
  X64BindLabel(A, RootDataLoop);
  X64LeaRegRipWritable(A, xrR12, WritableRootOffset, 0);
  X64MovRegReg(A, xrR13, xrR12);
  if (WritableRootBytes and not 7) > 0 then
    X64AddRegImm32(A, xrR13, WritableRootBytes and not 7);
  X64BindLabel(A, RootDataDone);
  X64CmpRegReg(A, xrR12, xrR13);
  X64JumpCondition(A, xcAboveEqual, ClosureAgain);
  X64MovRegMemBaseDisp(A, xrRDI, xrR12, 0);
  X64Call(A, L.GCMarkCandidate);
  X64AddRegImm32(A, xrR12, 8);
  X64Jump(A, RootDataDone);

  { Iterate marked-but-unscanned objects until the reachable closure is
    complete.  No recursion means collection cannot overflow the program
    stack on deep object graphs. }
  X64BindLabel(A, ClosureAgain);
  X64XorRegReg(A, xrR15, xrR15); { progress }
  X64LeaRegRipWritable(A, xrR12, D.AllocatorHead, 0);
  X64MovRegMemBaseDisp(A, xrR12, xrR12, 0);
  X64BindLabel(A, ClosureLoop);
  X64TestRegReg(A, xrR12, xrR12);
  X64JumpCondition(A, xcEqual, ClosureDone);
  X64MovRegMemBaseDisp(A, xrRAX, xrR12, 24);
  X64MovRegReg(A, xrRCX, xrRAX);
  X64AndRegImm32(A, xrRCX, FSIM_HEAP_ALLOCATED or FSIM_HEAP_MARKED);
  X64CmpRegImm32(A, xrRCX, FSIM_HEAP_ALLOCATED or FSIM_HEAP_MARKED);
  X64JumpCondition(A, xcNotEqual, ClosureNext);
  X64MovRegReg(A, xrRCX, xrRAX);
  X64AndRegImm32(A, xrRCX, FSIM_HEAP_SCANNED);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcNotEqual, ClosureNext);
  X64MovRegImm64(A, xrRCX, FSIM_HEAP_SCANNED);
  X64OrRegReg(A, xrRAX, xrRCX);
  X64MovMemBaseDispReg(A, xrR12, 24, xrRAX);
  X64MovRegImm64(A, xrR15, 1);
  X64LeaRegBaseDisp(A, xrR13, xrR12, FSIM_HEAP_HEADER_SIZE);
  X64MovRegMemBaseDisp(A, xrR14, xrR12, 16);
  X64AddRegReg(A, xrR14, xrR13);
  X64BindLabel(A, ScanLoop);
  X64CmpRegReg(A, xrR13, xrR14);
  X64JumpCondition(A, xcAboveEqual, ScanDone);
  X64MovRegMemBaseDisp(A, xrRDI, xrR13, 0);
  X64Call(A, L.GCMarkCandidate);
  X64AddRegImm32(A, xrR13, 8);
  X64Jump(A, ScanLoop);
  X64BindLabel(A, ScanDone);
  X64BindLabel(A, ClosureNext);
  X64MovRegMemBaseDisp(A, xrR12, xrR12, 0);
  X64Jump(A, ClosureLoop);
  X64BindLabel(A, ClosureDone);
  X64TestRegReg(A, xrR15, xrR15);
  X64JumpCondition(A, xcNotEqual, ClosureAgain);

  { Sweep.  r12=current header, r13=previous kept header, r14=next,
    rbx=reclaimed payload bytes, r15=live payload bytes. }
  X64XorRegReg(A, xrRBX, xrRBX);
  X64XorRegReg(A, xrR15, xrR15);
  X64XorRegReg(A, xrR13, xrR13);
  X64LeaRegRipWritable(A, xrR12, D.AllocatorHead, 0);
  X64MovRegMemBaseDisp(A, xrR12, xrR12, 0);
  X64BindLabel(A, SweepLoop);
  X64TestRegReg(A, xrR12, xrR12);
  X64JumpCondition(A, xcEqual, SweepFinish);
  X64MovRegMemBaseDisp(A, xrR14, xrR12, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrR12, 24);
  X64MovRegReg(A, xrRCX, xrRAX);
  X64AndRegImm32(A, xrRCX, FSIM_HEAP_ALLOCATED);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, SweepUnallocated);
  X64MovRegReg(A, xrRCX, xrRAX);
  X64AndRegImm32(A, xrRCX, FSIM_HEAP_MARKED);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcNotEqual, SweepLive);
  X64MovRegMemBaseDisp(A, xrR11, xrR12, 16); { payload bytes }
  X64AddRegReg(A, xrRBX, xrR11);
  X64MovRegReg(A, xrRCX, xrRAX);
  X64AndRegImm32(A, xrRCX, FSIM_HEAP_LARGE);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcNotEqual, SweepDeadLarge);
  X64Jump(A, SweepDeadSmall);

  X64BindLabel(A, SweepUnallocated);
  X64MovRegReg(A, xrR13, xrR12);
  X64Jump(A, SweepNext);

  X64BindLabel(A, SweepLive);
  X64MovRegMemBaseDisp(A, xrR11, xrR12, 16);
  X64AddRegReg(A, xrR15, xrR11);
  X64AndRegImm32(A, xrRAX, -7);
  X64MovMemBaseDispReg(A, xrR12, 24, xrRAX);
  X64MovRegReg(A, xrR13, xrR12);
  X64Jump(A, SweepNext);

  X64BindLabel(A, SweepDeadSmall);
  { Find the power-of-two class from the stored payload size. }
  X64MovRegImm64(A, xrRDX, 16);
  X64XorRegReg(A, xrRCX, xrRCX);
  X64BindLabel(A, ClassLoop);
  X64CmpRegReg(A, xrRDX, xrR11);
  X64JumpCondition(A, xcAboveEqual, ClassReady);
  X64ShlRegImm8(A, xrRDX, 1);
  X64AddRegImm32(A, xrRCX, 1);
  X64Jump(A, ClassLoop);
  X64BindLabel(A, ClassReady);
  X64ShlRegImm8(A, xrRCX, 3);
  X64LeaRegRipWritable(A, xrR9, D.AllocatorFreeHead, 0);
  X64AddRegReg(A, xrR9, xrRCX);
  X64MovRegMemBaseDisp(A, xrRAX, xrR9, 0);
  X64MovMemBaseDispReg(A, xrR12, 8, xrRAX);
  X64MovMemBaseDispReg(A, xrR9, 0, xrR12);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64MovMemBaseDispReg(A, xrR12, 24, xrRAX);
  X64MovRegReg(A, xrR13, xrR12); { stays on all-allocation list }
  X64Jump(A, SweepNext);

  X64BindLabel(A, SweepDeadLarge);
  { Remove from the intrusive list before munmap invalidates the header. }
  X64TestRegReg(A, xrR13, xrR13);
  X64JumpCondition(A, xcNotEqual, LargeHasPrev);
  X64LeaRegRipWritable(A, xrR9, D.AllocatorHead, 0);
  X64MovMemBaseDispReg(A, xrR9, 0, xrR14);
  X64Jump(A, ReleaseLarge);
  X64BindLabel(A, LargeHasPrev);
  X64MovMemBaseDispReg(A, xrR13, 0, xrR14);
  X64BindLabel(A, ReleaseLarge);
  X64MovRegReg(A, xrRDI, xrR12);
  X64MovRegReg(A, xrRSI, xrR11);
  X64AddRegImm32(A, xrRSI, FSIM_HEAP_HEADER_SIZE);
  X64MovRegImm64(A, xrRAX, LINUX_SYS_MUNMAP);
  X64Syscall(A);
  X64MovRegReg(A, xrR12, xrR14);
  X64Jump(A, SweepLoop);

  X64BindLabel(A, SweepNext);
  X64MovRegReg(A, xrR12, xrR14);
  X64Jump(A, SweepLoop);

  X64BindLabel(A, SweepFinish);
  X64LeaRegRipWritable(A, xrR9, D.GCLiveBytes, 0);
  X64MovMemBaseDispReg(A, xrR9, 0, xrR15);
  X64LeaRegRipWritable(A, xrR9, D.GCReclaimedBytes, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrR9, 0);
  X64AddRegReg(A, xrRAX, xrRBX);
  X64MovMemBaseDispReg(A, xrR9, 0, xrRAX);
  X64LeaRegRipWritable(A, xrR9, D.GCCollections, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrR9, 0);
  X64AddRegImm32(A, xrRAX, 1);
  X64MovMemBaseDispReg(A, xrR9, 0, xrRAX);
  X64LeaRegRipWritable(A, xrR9, D.GCArenasSinceCollection, 0);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64MovMemBaseDispReg(A, xrR9, 0, xrRAX);
  X64MovRegReg(A, xrRAX, xrRBX);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64PopReg(A, xrRBX);
  X64Ret(A);

  X64BindLabel(A, AbortLabel);
  { Avoid attempting a full heap walk on every allocation while a worker is
    intentionally long-lived.  The next arena budget schedules another try. }
  X64LeaRegRipWritable(A, xrR9, D.GCArenasSinceCollection, 0);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64MovMemBaseDispReg(A, xrR9, 0, xrRAX);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64PopReg(A, xrRBX);
  X64Ret(A);
end;

procedure EmitGCStats(var A: TX64Assembler; const L: TRuntimeLabels;
  const D: TRuntimeDataOffsets);
begin
  X64BindLabel(A, L.GCLiveBytes);
  X64LeaRegRipWritable(A, xrRAX, D.GCLiveBytes, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrRAX, 0);
  X64Ret(A);
  X64BindLabel(A, L.GCReclaimedBytes);
  X64LeaRegRipWritable(A, xrRAX, D.GCReclaimedBytes, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrRAX, 0);
  X64Ret(A);
  X64BindLabel(A, L.GCCollectionCount);
  X64LeaRegRipWritable(A, xrRAX, D.GCCollections, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrRAX, 0);
  X64Ret(A);
end;

procedure EmitMemoryCopy(var A: TX64Assembler; const L: TRuntimeLabels);
var
  LoopLabel, DoneLabel: Int32;
begin
  { rdi = destination, rsi = source, rdx = bytes }
  LoopLabel := X64NewLabel(A);
  DoneLabel := X64NewLabel(A);
  X64BindLabel(A, L.MemoryCopy);
  X64TestRegReg(A, xrRDX, xrRDX);
  X64JumpCondition(A, xcEqual, DoneLabel);
  X64BindLabel(A, LoopLabel);
  X64MovRegMemBaseDisp8(A, xrRAX, xrRSI, 0);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRAX);
  X64AddRegImm32(A, xrRSI, 1);
  X64AddRegImm32(A, xrRDI, 1);
  X64SubRegImm32(A, xrRDX, 1);
  X64JumpCondition(A, xcNotEqual, LoopLabel);
  X64BindLabel(A, DoneLabel);
  X64Ret(A);
end;

procedure EmitMemoryZero(var A: TX64Assembler; const L: TRuntimeLabels);
var
  LoopLabel, DoneLabel: Int32;
begin
  { rdi = destination, rsi = bytes }
  LoopLabel := X64NewLabel(A);
  DoneLabel := X64NewLabel(A);
  X64BindLabel(A, L.MemoryZero);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64TestRegReg(A, xrRSI, xrRSI);
  X64JumpCondition(A, xcEqual, DoneLabel);
  X64BindLabel(A, LoopLabel);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRAX);
  X64AddRegImm32(A, xrRDI, 1);
  X64SubRegImm32(A, xrRSI, 1);
  X64JumpCondition(A, xcNotEqual, LoopLabel);
  X64BindLabel(A, DoneLabel);
  X64Ret(A);
end;

procedure EmitStringLength(var A: TX64Assembler; const L: TRuntimeLabels);
var
  NullLabel: Int32;
begin
  NullLabel := X64NewLabel(A);
  X64BindLabel(A, L.StringLength);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, NullLabel);
  X64MovRegMemBaseDisp(A, xrRAX, xrRDI, 0);
  X64BindLabel(A, NullLabel);
  X64Ret(A);
end;

procedure EmitStringSlice(var A: TX64Assembler; const L: TRuntimeLabels);
var
  BoundsFail, BoundsOkay: Int32;
begin
  { rdi = string, rsi = zero-based start, rdx = byte count. }
  BoundsFail := X64NewLabel(A);
  BoundsOkay := X64NewLabel(A);
  X64BindLabel(A, L.StringSlice);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64MovRegReg(A, xrR12, xrRDI);
  X64MovRegReg(A, xrR13, xrRSI);
  X64MovRegReg(A, xrR14, xrRDX);
  X64TestRegReg(A, xrR13, xrR13);
  X64JumpCondition(A, xcLess, BoundsFail);
  X64TestRegReg(A, xrR14, xrR14);
  X64JumpCondition(A, xcLess, BoundsFail);
  X64XorRegReg(A, xrR8, xrR8);
  X64TestRegReg(A, xrR12, xrR12);
  X64JumpCondition(A, xcEqual, BoundsOkay);
  X64MovRegMemBaseDisp(A, xrR8, xrR12, 0);
  X64BindLabel(A, BoundsOkay);
  X64CmpRegReg(A, xrR13, xrR8);
  X64JumpCondition(A, xcAbove, BoundsFail);
  X64SubRegReg(A, xrR8, xrR13);
  X64CmpRegReg(A, xrR14, xrR8);
  X64JumpCondition(A, xcAbove, BoundsFail);
  X64MovRegReg(A, xrRDI, xrR14);
  X64AddRegImm32(A, xrRDI, 9);
  X64Call(A, L.Allocate);
  X64MovMemBaseDispReg(A, xrRAX, 0, xrR14);
  X64MovRegReg(A, xrR10, xrRAX);
  X64LeaRegBaseDisp(A, xrRDI, xrR10, 8);
  X64MovRegReg(A, xrRSI, xrR12);
  X64AddRegImm32(A, xrRSI, 8);
  X64AddRegReg(A, xrRSI, xrR13);
  X64MovRegReg(A, xrRDX, xrR14);
  X64Call(A, L.MemoryCopy);
  X64LeaRegBaseDisp(A, xrRCX, xrR10, 8);
  X64AddRegReg(A, xrRCX, xrR14);
  X64XorRegReg(A, xrRDX, xrRDX);
  X64MovMemBaseDispReg8(A, xrRCX, 0, xrRDX);
  X64MovRegReg(A, xrRAX, xrR10);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64Ret(A);
  X64BindLabel(A, BoundsFail);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64Jump(A, L.PanicBounds);
end;

procedure EmitStringConcat(var A: TX64Assembler; const L: TRuntimeLabels);
begin
  { rdi = left descriptor, rsi = right descriptor; returns owned descriptor }
  X64BindLabel(A, L.StringConcat);
  X64PushReg(A, xrRBP);
  X64MovRegReg(A, xrRBP, xrRSP);
  X64PushReg(A, xrRBX);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64MovRegReg(A, xrRBX, xrRDI);
  X64MovRegReg(A, xrR12, xrRSI);
  X64XorRegReg(A, xrR13, xrR13);
  X64TestRegReg(A, xrRBX, xrRBX);
  { Null descriptors are semantically empty; conditional loads use tiny branches. }
  { Branch labels are emitted inline to keep the ABI helper entirely local. }
  X64Call(A, L.StringLength);
  X64MovRegReg(A, xrR13, xrRAX);
  X64MovRegReg(A, xrRDI, xrR12);
  X64Call(A, L.StringLength);
  X64AddRegReg(A, xrR13, xrRAX);
  X64LeaRegBaseDisp(A, xrRDI, xrR13, 9);
  X64Call(A, L.Allocate);
  X64MovRegReg(A, xrR10, xrRAX);
  X64MovMemBaseDispReg(A, xrR10, 0, xrR13);
  X64LeaRegBaseDisp(A, xrRDI, xrR10, 8);
  X64MovRegReg(A, xrR11, xrRDI);
  X64TestRegReg(A, xrRBX, xrRBX);
  { Calling MemoryCopy with zero length is safe even for null source+8. }
  X64MovRegReg(A, xrRSI, xrRBX);
  X64AddRegImm32(A, xrRSI, 8);
  X64MovRegReg(A, xrRDX, xrR13);
  X64TestRegReg(A, xrRBX, xrRBX);
  { Recompute left length and copy left. }
  X64MovRegReg(A, xrRDI, xrRBX);
  X64Call(A, L.StringLength);
  X64MovRegReg(A, xrR13, xrRAX);
  X64MovRegReg(A, xrRDI, xrR11);
  X64MovRegReg(A, xrRSI, xrRBX);
  X64AddRegImm32(A, xrRSI, 8);
  X64MovRegReg(A, xrRDX, xrR13);
  X64Call(A, L.MemoryCopy);
  X64AddRegReg(A, xrR11, xrR13);
  X64MovRegReg(A, xrRDI, xrR12);
  X64Call(A, L.StringLength);
  X64MovRegReg(A, xrRDX, xrRAX);
  X64MovRegReg(A, xrRDI, xrR11);
  X64MovRegReg(A, xrRSI, xrR12);
  X64AddRegImm32(A, xrRSI, 8);
  X64Call(A, L.MemoryCopy);
  X64MovRegMemBaseDisp(A, xrRDX, xrR10, 0);
  X64LeaRegBaseDisp(A, xrRDI, xrR10, 8);
  X64AddRegReg(A, xrRDI, xrRDX);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRAX);
  X64MovRegReg(A, xrRAX, xrR10);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64PopReg(A, xrRBX);
  X64Leave(A);
  X64Ret(A);
end;

procedure EmitStringEqual(var A: TX64Assembler; const L: TRuntimeLabels);
var
  FalseLabel, TrueLabel, LoopLabel, DoneLabel: Int32;
begin
  FalseLabel := X64NewLabel(A);
  TrueLabel := X64NewLabel(A);
  LoopLabel := X64NewLabel(A);
  DoneLabel := X64NewLabel(A);
  X64BindLabel(A, L.StringEqual);
  X64CmpRegReg(A, xrRDI, xrRSI);
  X64JumpCondition(A, xcEqual, TrueLabel);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, FalseLabel);
  X64TestRegReg(A, xrRSI, xrRSI);
  X64JumpCondition(A, xcEqual, FalseLabel);
  X64MovRegMemBaseDisp(A, xrRDX, xrRDI, 0);
  X64MovRegMemBaseDisp(A, xrRCX, xrRSI, 0);
  X64CmpRegReg(A, xrRDX, xrRCX);
  X64JumpCondition(A, xcNotEqual, FalseLabel);
  X64AddRegImm32(A, xrRDI, 8);
  X64AddRegImm32(A, xrRSI, 8);
  X64TestRegReg(A, xrRDX, xrRDX);
  X64JumpCondition(A, xcEqual, TrueLabel);
  X64BindLabel(A, LoopLabel);
  X64MovRegMemBaseDisp8(A, xrRAX, xrRDI, 0);
  X64MovRegMemBaseDisp8(A, xrRCX, xrRSI, 0);
  X64CmpRegReg(A, xrRAX, xrRCX);
  X64JumpCondition(A, xcNotEqual, FalseLabel);
  X64AddRegImm32(A, xrRDI, 1);
  X64AddRegImm32(A, xrRSI, 1);
  X64SubRegImm32(A, xrRDX, 1);
  X64JumpCondition(A, xcNotEqual, LoopLabel);
  X64BindLabel(A, TrueLabel);
  X64MovRegImm64(A, xrRAX, 1);
  X64Jump(A, DoneLabel);
  X64BindLabel(A, FalseLabel);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64BindLabel(A, DoneLabel);
  X64Ret(A);
end;

procedure EmitNullAndBoundsChecks(var A: TX64Assembler;
  const L: TRuntimeLabels);
var
  NullOkay, BoundsBad: Int32;
begin
  NullOkay := X64NewLabel(A);
  X64BindLabel(A, L.NullCheck);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcNotEqual, NullOkay);
  X64Jump(A, L.PanicNull);
  X64BindLabel(A, NullOkay);
  X64MovRegReg(A, xrRAX, xrRDI);
  X64Ret(A);

  { rdi = signed index, rsi = exclusive length }
  BoundsBad := X64NewLabel(A);
  NullOkay := X64NewLabel(A);
  X64BindLabel(A, L.BoundsCheck);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcLess, BoundsBad);
  X64CmpRegReg(A, xrRDI, xrRSI);
  X64JumpCondition(A, xcBelow, NullOkay);
  X64BindLabel(A, BoundsBad);
  X64Jump(A, L.PanicBounds);
  X64BindLabel(A, NullOkay);
  X64MovRegReg(A, xrRAX, xrRDI);
  X64Ret(A);
end;

procedure EmitQuaCheck(var A: TX64Assembler; const L: TRuntimeLabels);
var
  LoopLabel, SuccessLabel, FailureLabel: Int32;
begin
  { rdi = object pointer, rsi = target RTTI pointer. RTTI[0] is parent RTTI. }
  LoopLabel := X64NewLabel(A);
  SuccessLabel := X64NewLabel(A);
  FailureLabel := X64NewLabel(A);
  X64BindLabel(A, L.QuaCheck);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, FailureLabel);
  X64MovRegMemBaseDisp(A, xrRAX, xrRDI, 0);
  X64BindLabel(A, LoopLabel);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, FailureLabel);
  X64CmpRegReg(A, xrRAX, xrRSI);
  X64JumpCondition(A, xcEqual, SuccessLabel);
  X64MovRegMemBaseDisp(A, xrRAX, xrRAX, 0);
  X64Jump(A, LoopLabel);
  X64BindLabel(A, SuccessLabel);
  X64MovRegReg(A, xrRAX, xrRDI);
  X64Ret(A);
  X64BindLabel(A, FailureLabel);
  X64Jump(A, L.PanicQua);
end;

procedure EmitPanic(var A: TX64Assembler; const L: TRuntimeLabels;
  const D: TRuntimeDataOffsets);

  procedure EmitSpecific(LabelId, DataOffset, ExitCode: Int32);
  begin
    X64BindLabel(A, LabelId);
    X64LeaRegRipData(A, xrRDI, DataOffset, 0);
    X64MovRegImm64(A, xrRSI, ExitCode);
    X64Jump(A, L.Panic);
  end;

begin
  { rdi = descriptor, rsi = status }
  X64BindLabel(A, L.Panic);
  X64PushReg(A, xrRSI);
  X64Call(A, L.PrintString);
  X64PopReg(A, xrRDI);
  X64Jump(A, L.ExitProcess);

  EmitSpecific(L.PanicNull, D.NullPanicString, FSIM_EXIT_NULL);
  EmitSpecific(L.PanicBounds, D.BoundsPanicString, FSIM_EXIT_BOUNDS);
  EmitSpecific(L.PanicQua, D.QuaPanicString, FSIM_EXIT_QUA);
  EmitSpecific(L.PanicOverflow, D.OverflowPanicString, FSIM_EXIT_OVERFLOW);
  EmitSpecific(L.PanicAllocation, D.AllocationPanicString,
    FSIM_EXIT_ALLOCATION);
  EmitSpecific(L.PanicAssert, D.AssertPanicString, FSIM_EXIT_ASSERT);
  EmitSpecific(L.PanicThread, D.ThreadPanicString, FSIM_EXIT_THREAD);
  EmitSpecific(L.PanicText, D.TextPanicString, FSIM_EXIT_TEXT);
end;

procedure EmitThreading(var A: TX64Assembler; const L: TRuntimeLabels;
  const D: TRuntimeDataOffsets);
var
  ChildLabel, ParentLabel, FailedLabel, StackReadyLabel: Int32;
  ChildCompleteLabel, ChildWakeLabel: Int32;
  JoinLoopLabel, JoinDoneLabel, JoinValidLabel, JoinTidLoopLabel,
  JoinTidDoneLabel, TaskListRetryLabel: Int32;
  CancelValidLabel, CancelReturnLabel: Int32;
begin
  { task descriptor layout:
      +0  qword state
      +8  qword result
      +16 qword native tid
      +24 qword stack bytes
      +32 qword entry address
      +40 qword argument
      +48 qword cancellation requested
      +56 qword reserved
    stack storage follows the descriptor. }

  ChildLabel := X64NewLabel(A);
  ParentLabel := X64NewLabel(A);
  FailedLabel := X64NewLabel(A);
  StackReadyLabel := X64NewLabel(A);
  ChildCompleteLabel := X64NewLabel(A);
  ChildWakeLabel := X64NewLabel(A);
  TaskListRetryLabel := X64NewLabel(A);

  { rdi = function pointer, rsi = argument, rdx = requested stack bytes;
    returns a shared task descriptor in rax. }
  X64BindLabel(A, L.ThreadSpawn);
  X64PushReg(A, xrRBP);
  X64MovRegReg(A, xrRBP, xrRSP);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64PushReg(A, xrR15);
  X64MovRegReg(A, xrR12, xrRDI);
  X64MovRegReg(A, xrR13, xrRSI);
  X64MovRegReg(A, xrR14, xrRDX);
  X64TestRegReg(A, xrR12, xrR12);
  X64JumpCondition(A, xcEqual, FailedLabel);
  X64CmpRegImm32(A, xrR14, 65536);
  X64JumpCondition(A, xcAboveEqual, StackReadyLabel);
  X64MovRegImm64(A, xrR14, 65536);
  X64BindLabel(A, StackReadyLabel);
  X64MovRegReg(A, xrRDI, xrR14);
  X64AddRegImm32(A, xrRDI, FSIM_TASK_DESCRIPTOR_SIZE);
  X64Call(A, L.Allocate);
  X64MovRegReg(A, xrR15, xrRAX);
  X64XorRegReg(A, xrRCX, xrRCX);
  X64MovMemBaseDispReg(A, xrR15, 0, xrRCX);
  X64MovMemBaseDispReg(A, xrR15, 8, xrRCX);
  X64MovMemBaseDispReg(A, xrR15, 16, xrRCX);
  X64MovMemBaseDispReg(A, xrR15, 48, xrRCX);
  X64MovMemBaseDispReg(A, xrR15, 56, xrRCX);
  X64MovMemBaseDispReg(A, xrR15, 24, xrR14);
  X64MovMemBaseDispReg(A, xrR15, 32, xrR12);
  X64MovMemBaseDispReg(A, xrR15, 40, xrR13);
  { Keep task allocation headers in a side list.  GC stores headers rather
    than payload pointers here so the bookkeeping itself is not a root. }
  X64MovRegReg(A, xrR8, xrR15);
  X64SubRegImm32(A, xrR8, FSIM_HEAP_HEADER_SIZE);
  X64LeaRegRipWritable(A, xrR9, D.GCTaskHead, 0);
  X64BindLabel(A, TaskListRetryLabel);
  X64MovRegMemBaseDisp(A, xrRAX, xrR9, 0);
  X64MovMemBaseDispReg(A, xrR8, 8, xrRAX);
  X64MovRegReg(A, xrRCX, xrR8);
  X64LockCmpXchgMemBaseDispReg(A, xrR9, 0, xrRCX);
  X64JumpCondition(A, xcNotEqual, TaskListRetryLabel);
  X64MovRegReg(A, xrRAX, xrR15);
  X64AddRegImm32(A, xrRAX, FSIM_TASK_DESCRIPTOR_SIZE);
  X64AddRegReg(A, xrRAX, xrR14);
  X64AndRegImm32(A, xrRAX, -16);
  X64MovRegReg(A, xrRSI, xrRAX);
  X64MovRegImm64(A, xrRDI, LINUX_THREAD_FLAGS);
  X64XorRegReg(A, xrRDX, xrRDX);
  X64LeaRegBaseDisp(A, xrR10, xrR15, 16); { CHILD_SETTID/CLEARTID word }
  X64XorRegReg(A, xrR8, xrR8);
  X64MovRegImm64(A, xrRAX, LINUX_SYS_CLONE);
  X64Syscall(A);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, ChildLabel);
  X64JumpCondition(A, xcLess, FailedLabel);

  X64BindLabel(A, ParentLabel);
  X64MovMemBaseDispReg(A, xrR15, 16, xrRAX);
  X64MovRegReg(A, xrRAX, xrR15);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64Leave(A);
  X64Ret(A);

  X64BindLabel(A, ChildLabel);
  X64MovRegReg(A, xrRDI, xrR13);
  X64CallReg(A, xrR12);
  X64MovMemBaseDispReg(A, xrR15, 8, xrRAX);
  X64MovRegMemBaseDisp(A, xrRCX, xrR15, 48);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64MovRegImm64(A, xrRCX, FSIM_TASK_STATE_COMPLETED);
  X64JumpCondition(A, xcEqual, ChildCompleteLabel);
  X64MovRegImm64(A, xrRCX, FSIM_TASK_STATE_CANCELLED);
  X64BindLabel(A, ChildCompleteLabel);
  X64XchgMemBaseDispReg(A, xrR15, 0, xrRCX);
  X64MemoryFence(A);
  X64BindLabel(A, ChildWakeLabel);
  X64LeaRegBaseDisp(A, xrRDI, xrR15, 0);
  X64MovRegImm64(A, xrRSI, LINUX_FUTEX_WAKE_PRIVATE);
  X64MovRegImm64(A, xrRDX, High(Int32));
  X64XorRegReg(A, xrR10, xrR10);
  X64XorRegReg(A, xrR8, xrR8);
  X64XorRegReg(A, xrR9, xrR9);
  X64MovRegImm64(A, xrRAX, LINUX_SYS_FUTEX);
  X64Syscall(A);
  X64XorRegReg(A, xrRDI, xrRDI);
  X64Jump(A, L.ThreadExit);

  X64BindLabel(A, FailedLabel);
  X64Jump(A, L.PanicThread);

  JoinLoopLabel := X64NewLabel(A);
  JoinDoneLabel := X64NewLabel(A);
  JoinValidLabel := X64NewLabel(A);
  JoinTidLoopLabel := X64NewLabel(A);
  JoinTidDoneLabel := X64NewLabel(A);
  { rdi = task descriptor; returns task result in rax. }
  X64BindLabel(A, L.ThreadJoin);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcNotEqual, JoinValidLabel);
  X64Jump(A, L.PanicThread);
  X64BindLabel(A, JoinValidLabel);
  X64PushReg(A, xrR12);
  X64MovRegReg(A, xrR12, xrRDI);
  X64BindLabel(A, JoinLoopLabel);
  X64MovRegMemBaseDisp(A, xrRAX, xrR12, 0);
  X64CmpRegImm32(A, xrRAX, FSIM_TASK_STATE_RUNNING);
  X64JumpCondition(A, xcNotEqual, JoinDoneLabel);
  X64LeaRegBaseDisp(A, xrRDI, xrR12, 0);
  X64MovRegImm64(A, xrRSI, LINUX_FUTEX_WAIT_PRIVATE);
  X64MovRegImm64(A, xrRDX, FSIM_TASK_STATE_RUNNING);
  X64XorRegReg(A, xrR10, xrR10);
  X64XorRegReg(A, xrR8, xrR8);
  X64XorRegReg(A, xrR9, xrR9);
  X64MovRegImm64(A, xrRAX, LINUX_SYS_FUTEX);
  X64Syscall(A);
  X64Jump(A, JoinLoopLabel);
  X64BindLabel(A, JoinDoneLabel);
  X64MemoryFence(A);
  { State is published before the worker executes SYS_exit.  Wait for the
    kernel's CLONE_CHILD_CLEARTID store as the definitive proof that the
    child no longer executes on the task stack. }
  X64BindLabel(A, JoinTidLoopLabel);
  X64MovRegMemBaseDisp(A, xrRAX, xrR12, 16);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, JoinTidDoneLabel);
  X64Pause(A);
  X64Jump(A, JoinTidLoopLabel);
  X64BindLabel(A, JoinTidDoneLabel);
  X64MemoryFence(A);
  X64MovRegMemBaseDisp(A, xrRAX, xrR12, 8);
  X64PopReg(A, xrR12);
  X64Ret(A);

  { Awaiting a task-backed future has the same descriptor ABI as join. }
  X64BindLabel(A, L.FutureAwait);
  X64Jump(A, L.ThreadJoin);

  CancelValidLabel := X64NewLabel(A);
  CancelReturnLabel := X64NewLabel(A);
  { rdi = task descriptor; atomically requests cancellation only while the
    task is running and returns the state observed before the request. }
  X64BindLabel(A, L.ThreadCancel);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcNotEqual, CancelValidLabel);
  X64Jump(A, L.PanicThread);
  X64BindLabel(A, CancelValidLabel);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64MovRegReg(A, xrR12, xrRDI);
  X64MovRegImm64(A, xrRAX, 1);
  X64XchgMemBaseDispReg(A, xrR12, 48, xrRAX);
  X64MovRegReg(A, xrR13, xrRAX);
  { A cancellation request is not task completion.  Join/await keeps waiting
    on state +0 until the worker actually returns and publishes a terminal
    state.  Waking completion waiters here was the old race. }
  X64BindLabel(A, CancelReturnLabel);
  X64MovRegReg(A, xrRAX, xrR13);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64Ret(A);

  X64BindLabel(A, L.ThreadExit);
  X64MovRegImm64(A, xrRAX, LINUX_SYS_EXIT);
  X64Syscall(A);
  X64Int3(A);
end;

procedure RuntimeEmit(var Assembler: TX64Assembler;
  const Labels: TRuntimeLabels; const Data: TRuntimeDataOffsets;
  WritableRootOffset, WritableRootBytes: Int32);
var
  S67Links: TS67NativeLinks;
  OSLinks: TOSNativeLinks;
begin
  EmitExit(Assembler, Labels);
  EmitWriteRaw(Assembler, Labels);
  EmitPrintString(Assembler, Labels);
  EmitPrintInteger(Assembler, Labels);
  EmitPrintReal(Assembler, Labels);
  EmitPrintFixed(Assembler, Labels);
  EmitPrintBoolean(Assembler, Labels, Data);
  EmitPrintCharacter(Assembler, Labels);
  EmitPrintNewLine(Assembler, Labels, Data);
  EmitAllocate(Assembler, Labels, Data);
  EmitFree(Assembler, Labels);
  EmitGCMarkCandidate(Assembler, Labels, Data);
  EmitGCPinControl(Assembler, Labels, Data);
  EmitGCCollect(Assembler, Labels, Data, WritableRootOffset, WritableRootBytes);
  EmitGCStats(Assembler, Labels, Data);
  EmitMemoryCopy(Assembler, Labels);
  EmitMemoryZero(Assembler, Labels);
  EmitStringLength(Assembler, Labels);
  EmitStringSlice(Assembler, Labels);
  EmitStringConcat(Assembler, Labels);
  EmitStringEqual(Assembler, Labels);
  EmitNullAndBoundsChecks(Assembler, Labels);
  EmitQuaCheck(Assembler, Labels);
  EmitPanic(Assembler, Labels, Data);
  S67Links := Default(TS67NativeLinks);
  S67Links.Allocate := Labels.Allocate;
  S67Links.WriteRaw := Labels.WriteRaw;
  S67Links.PanicText := Labels.PanicText;
  S67EmitNative(Assembler, Labels.S67, Data.S67, S67Links);
  OSLinks := Default(TOSNativeLinks);
  OSLinks.Allocate := Labels.Allocate;
  OSLinks.WriteRaw := Labels.WriteRaw;
  OSEmitNative(Assembler, Labels.OS, Data.OS, OSLinks);
  EmitThreading(Assembler, Labels, Data);
end;

end.

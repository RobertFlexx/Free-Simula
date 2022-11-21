unit osruntime;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  core, registers, x64;

const
  FSIM_OS_DIRENT_BUFFER_SIZE = 32768;
  FSIM_OS_DIR_NAME_MAX = 255;
  FSIM_OS_DIR_FD_OFFSET = 0;
  FSIM_OS_DIR_POS_OFFSET = 8;
  FSIM_OS_DIR_END_OFFSET = 16;
  FSIM_OS_DIR_TYPE_OFFSET = 24;
  FSIM_OS_DIR_NAME_OFFSET = 32;
  FSIM_OS_DIR_NAME_BYTES_OFFSET = 40;
  FSIM_OS_DIR_BUFFER_OFFSET = 296;
  FSIM_OS_DIR_HANDLE_SIZE = FSIM_OS_DIR_BUFFER_OFFSET + FSIM_OS_DIRENT_BUFFER_SIZE;

  FSIM_OS_TYPE_OTHER = 4;
  FSIM_OS_TYPE_FILE = 1;
  FSIM_OS_TYPE_DIRECTORY = 2;
  FSIM_OS_TYPE_SYMLINK = 3;

  LINUX_SYS_WRITE = 1;
  LINUX_SYS_WRITEV = 20;
  LINUX_SYS_CLOSE = 3;
  LINUX_SYS_OPENAT = 257;
  LINUX_SYS_GETDENTS64 = 217;
  LINUX_SYS_NEWFSTATAT = 262;

  LINUX_AT_FDCWD = -100;
  LINUX_AT_SYMLINK_NOFOLLOW = $100;
  LINUX_O_RDONLY = 0;
  LINUX_O_DIRECTORY = $10000;
  LINUX_O_CLOEXEC = $80000;

  LINUX_DT_UNKNOWN = 0;
  LINUX_DT_DIR = 4;
  LINUX_DT_REG = 8;
  LINUX_DT_LNK = 10;

  LINUX_S_IFMT = $F000;
  LINUX_S_IFDIR = $4000;
  LINUX_S_IFREG = $8000;
  LINUX_S_IFLNK = $A000;

  LINUX_STAT_MODE_OFFSET = 24;
  LINUX_STAT_SIZE_OFFSET = 48;
  LINUX_STAT_BUFFER_SIZE = 160;

type
  TOSNativeDataOffsets = packed record
    Argc: Int32;
    Argv: Int32;
  end;

  TOSNativeLabels = packed record
    ArgCount: Int32;
    Argument: Int32;
    DirOpen: Int32;
    DirOpenAt: Int32;
    DirNext: Int32;
    DirType: Int32;
    DirClose: Int32;
    PathType: Int32;
    PathSize: Int32;
    PathJoin: Int32;
    PathBaseName: Int32;
    StringChar: Int32;
    ParseInt: Int32;
    WritePath: Int32;
    StderrWrite: Int32;
  end;

  TOSNativeLinks = packed record
    Allocate: Int32;
    WriteRaw: Int32;
  end;

procedure OSAppendWritableData(var Data: TByteBuffer;
  out Offsets: TOSNativeDataOffsets);
procedure OSAllocateNativeLabels(var Assembler: TX64Assembler;
  out Labels: TOSNativeLabels);
procedure OSEmitCaptureArgs(var Assembler: TX64Assembler;
  const Data: TOSNativeDataOffsets);
procedure OSEmitNative(var Assembler: TX64Assembler;
  const Labels: TOSNativeLabels; const Data: TOSNativeDataOffsets;
  const Links: TOSNativeLinks);

implementation

procedure OSAppendWritableData(var Data: TByteBuffer;
  out Offsets: TOSNativeDataOffsets);
begin
  FillChar(Offsets, SizeOf(Offsets), 0);
  BufferAlign(Data, 8, 0);
  Offsets.Argc := Data.Count;
  BufferAppendQWord(Data, 0);
  Offsets.Argv := Data.Count;
  BufferAppendQWord(Data, 0);
end;

procedure OSAllocateNativeLabels(var Assembler: TX64Assembler;
  out Labels: TOSNativeLabels);
begin
  FillChar(Labels, SizeOf(Labels), 0);
  Labels.ArgCount := X64NewLabel(Assembler);
  Labels.Argument := X64NewLabel(Assembler);
  Labels.DirOpen := X64NewLabel(Assembler);
  Labels.DirOpenAt := X64NewLabel(Assembler);
  Labels.DirNext := X64NewLabel(Assembler);
  Labels.DirType := X64NewLabel(Assembler);
  Labels.DirClose := X64NewLabel(Assembler);
  Labels.PathType := X64NewLabel(Assembler);
  Labels.PathSize := X64NewLabel(Assembler);
  Labels.PathJoin := X64NewLabel(Assembler);
  Labels.PathBaseName := X64NewLabel(Assembler);
  Labels.StringChar := X64NewLabel(Assembler);
  Labels.ParseInt := X64NewLabel(Assembler);
  Labels.WritePath := X64NewLabel(Assembler);
  Labels.StderrWrite := X64NewLabel(Assembler);
end;

procedure OSEmitCaptureArgs(var Assembler: TX64Assembler;
  const Data: TOSNativeDataOffsets);
begin
  { Linux enters _start with argc at [rsp] and argv immediately after it. }
  X64MovRegMemBaseDisp(Assembler, xrRAX, xrRSP, 0);
  X64LeaRegRipWritable(Assembler, xrRCX, Data.Argc, 0);
  X64MovMemBaseDispReg(Assembler, xrRCX, 0, xrRAX);
  X64LeaRegBaseDisp(Assembler, xrRAX, xrRSP, 8);
  X64LeaRegRipWritable(Assembler, xrRCX, Data.Argv, 0);
  X64MovMemBaseDispReg(Assembler, xrRCX, 0, xrRAX);
end;

procedure EmitArgCount(var A: TX64Assembler; const L: TOSNativeLabels;
  const D: TOSNativeDataOffsets);
begin
  X64BindLabel(A, L.ArgCount);
  X64LeaRegRipWritable(A, xrRCX, D.Argc, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrRCX, 0);
  X64Ret(A);
end;

procedure EmitArgument(var A: TX64Assembler; const L: TOSNativeLabels;
  const D: TOSNativeDataOffsets; const Links: TOSNativeLinks);
var
  InvalidLabel, ScanLoop, ScanDone, CopyLoop, CopyDone, ReturnLabel: Int32;
begin
  InvalidLabel := X64NewLabel(A);
  ScanLoop := X64NewLabel(A);
  ScanDone := X64NewLabel(A);
  CopyLoop := X64NewLabel(A);
  CopyDone := X64NewLabel(A);
  ReturnLabel := X64NewLabel(A);

  { rdi = zero based argv index, returns an fsim string or nil. }
  X64BindLabel(A, L.Argument);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64PushReg(A, xrR15);
  X64CmpRegImm32(A, xrRDI, 0);
  X64JumpCondition(A, xcLess, InvalidLabel);
  X64LeaRegRipWritable(A, xrRCX, D.Argc, 0);
  X64MovRegMemBaseDisp(A, xrRAX, xrRCX, 0);
  X64CmpRegReg(A, xrRDI, xrRAX);
  X64JumpCondition(A, xcAboveEqual, InvalidLabel);

  X64LeaRegRipWritable(A, xrRCX, D.Argv, 0);
  X64MovRegMemBaseDisp(A, xrRCX, xrRCX, 0);
  X64MovRegMemIndex(A, xrR12, xrRCX, xrRDI, 8, 0);
  X64XorRegReg(A, xrR13, xrR13);
  X64BindLabel(A, ScanLoop);
  X64MovRegMemBaseDisp8(A, xrRAX, xrR12, 0);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, ScanDone);
  X64AddRegImm32(A, xrR12, 1);
  X64AddRegImm32(A, xrR13, 1);
  X64Jump(A, ScanLoop);

  X64BindLabel(A, ScanDone);
  X64SubRegReg(A, xrR12, xrR13);
  X64MovRegReg(A, xrRDI, xrR13);
  X64AddRegImm32(A, xrRDI, 9);
  { four saved registers leave rsp eight bytes off the call boundary. }
  X64SubRegImm32(A, xrRSP, 8);
  X64Call(A, Links.Allocate);
  X64AddRegImm32(A, xrRSP, 8);
  X64MovRegReg(A, xrR14, xrRAX);
  X64MovMemBaseDispReg(A, xrR14, 0, xrR13);
  X64LeaRegBaseDisp(A, xrR15, xrR14, 8);
  X64MovRegReg(A, xrRCX, xrR13);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, CopyDone);
  X64BindLabel(A, CopyLoop);
  X64MovRegMemBaseDisp8(A, xrRAX, xrR12, 0);
  X64MovMemBaseDispReg8(A, xrR15, 0, xrRAX);
  X64AddRegImm32(A, xrR12, 1);
  X64AddRegImm32(A, xrR15, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64JumpCondition(A, xcNotEqual, CopyLoop);
  X64BindLabel(A, CopyDone);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64MovMemBaseDispReg8(A, xrR15, 0, xrRAX);
  X64MovRegReg(A, xrRAX, xrR14);
  X64Jump(A, ReturnLabel);

  X64BindLabel(A, InvalidLabel);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64BindLabel(A, ReturnLabel);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64Ret(A);
end;

procedure EmitOpenCommon(var A: TX64Assembler; LabelId: Int32;
  ParentFromHandle: Boolean; const Links: TOSNativeLinks);
var
  FailedLabel, OpenReadyLabel: Int32;
begin
  FailedLabel := X64NewLabel(A);
  OpenReadyLabel := X64NewLabel(A);
  X64BindLabel(A, LabelId);
  X64PushReg(A, xrR12);
  if ParentFromHandle then
  begin
    { rdi = parent handle, rsi = entry name string }
    X64TestRegReg(A, xrRDI, xrRDI);
    X64JumpCondition(A, xcEqual, FailedLabel);
    X64MovRegMemBaseDisp(A, xrR12, xrRDI, FSIM_OS_DIR_FD_OFFSET);
    X64MovRegReg(A, xrRAX, xrRSI);
  end
  else
  begin
    { rdi = path string }
    X64MovRegImm64(A, xrR12, QWord($FFFFFFFFFFFFFF9C));
    X64MovRegReg(A, xrRAX, xrRDI);
  end;
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, FailedLabel);
  X64AddRegImm32(A, xrRAX, 8);
  X64MovRegReg(A, xrRSI, xrRAX);
  X64MovRegReg(A, xrRDI, xrR12);
  X64MovRegImm64(A, xrRDX, LINUX_O_RDONLY or LINUX_O_DIRECTORY or LINUX_O_CLOEXEC);
  X64XorRegReg(A, xrR10, xrR10);
  X64MovRegImm64(A, xrRAX, LINUX_SYS_OPENAT);
  X64Syscall(A);
  X64CmpRegImm32(A, xrRAX, 0);
  X64JumpCondition(A, xcLess, FailedLabel);
  X64MovRegReg(A, xrR12, xrRAX);
  X64MovRegImm64(A, xrRDI, FSIM_OS_DIR_HANDLE_SIZE);
  X64Call(A, Links.Allocate);
  X64MovMemBaseDispReg(A, xrRAX, FSIM_OS_DIR_FD_OFFSET, xrR12);
  X64Jump(A, OpenReadyLabel);

  X64BindLabel(A, FailedLabel);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64BindLabel(A, OpenReadyLabel);
  X64PopReg(A, xrR12);
  X64Ret(A);
end;

procedure EmitDirNext(var A: TX64Assembler; const L: TOSNativeLabels);
var
  AgainLabel, HaveRecordLabel, RefillLabel, EndLabel, CopyLoop,
  CopyDone, ReturnLabel, SkipLabel, NotDotLabel: Int32;
begin
  AgainLabel := X64NewLabel(A);
  HaveRecordLabel := X64NewLabel(A);
  RefillLabel := X64NewLabel(A);
  EndLabel := X64NewLabel(A);
  CopyLoop := X64NewLabel(A);
  CopyDone := X64NewLabel(A);
  ReturnLabel := X64NewLabel(A);
  SkipLabel := X64NewLabel(A);
  NotDotLabel := X64NewLabel(A);

  { rdi = directory handle, returns scratch string valid until next call. }
  X64BindLabel(A, L.DirNext);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, EndLabel);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64MovRegReg(A, xrR12, xrRDI);

  X64BindLabel(A, AgainLabel);
  X64MovRegMemBaseDisp(A, xrR13, xrR12, FSIM_OS_DIR_POS_OFFSET);
  X64MovRegMemBaseDisp(A, xrR14, xrR12, FSIM_OS_DIR_END_OFFSET);
  X64CmpRegReg(A, xrR13, xrR14);
  X64JumpCondition(A, xcBelow, HaveRecordLabel);

  X64BindLabel(A, RefillLabel);
  X64MovRegMemBaseDisp(A, xrRDI, xrR12, FSIM_OS_DIR_FD_OFFSET);
  X64LeaRegBaseDisp(A, xrRSI, xrR12, FSIM_OS_DIR_BUFFER_OFFSET);
  X64MovRegImm64(A, xrRDX, FSIM_OS_DIRENT_BUFFER_SIZE);
  X64MovRegImm64(A, xrRAX, LINUX_SYS_GETDENTS64);
  X64Syscall(A);
  X64CmpRegImm32(A, xrRAX, 0);
  X64JumpCondition(A, xcLessEqual, SkipLabel);
  X64XorRegReg(A, xrRCX, xrRCX);
  X64MovMemBaseDispReg(A, xrR12, FSIM_OS_DIR_POS_OFFSET, xrRCX);
  X64MovMemBaseDispReg(A, xrR12, FSIM_OS_DIR_END_OFFSET, xrRAX);
  X64XorRegReg(A, xrR13, xrR13);

  X64BindLabel(A, HaveRecordLabel);
  X64LeaRegBaseDisp(A, xrRCX, xrR12, FSIM_OS_DIR_BUFFER_OFFSET);
  X64AddRegReg(A, xrRCX, xrR13);
  X64MovRegMemBaseDisp(A, xrRDX, xrRCX, 16);
  X64AndRegImm32(A, xrRDX, $FFFF);
  X64AddRegReg(A, xrR13, xrRDX);
  X64MovMemBaseDispReg(A, xrR12, FSIM_OS_DIR_POS_OFFSET, xrR13);
  X64MovRegMemBaseDisp8(A, xrRAX, xrRCX, 18);
  X64MovMemBaseDispReg(A, xrR12, FSIM_OS_DIR_TYPE_OFFSET, xrRAX);
  X64LeaRegBaseDisp(A, xrRSI, xrRCX, 19);
  X64LeaRegBaseDisp(A, xrRDI, xrR12, FSIM_OS_DIR_NAME_BYTES_OFFSET);
  X64XorRegReg(A, xrRDX, xrRDX);

  X64BindLabel(A, CopyLoop);
  X64CmpRegImm32(A, xrRDX, FSIM_OS_DIR_NAME_MAX);
  X64JumpCondition(A, xcAboveEqual, CopyDone);
  X64MovRegMemBaseDisp8(A, xrRAX, xrRSI, 0);
  X64TestRegReg(A, xrRAX, xrRAX);
  X64JumpCondition(A, xcEqual, CopyDone);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRAX);
  X64AddRegImm32(A, xrRSI, 1);
  X64AddRegImm32(A, xrRDI, 1);
  X64AddRegImm32(A, xrRDX, 1);
  X64Jump(A, CopyLoop);

  X64BindLabel(A, CopyDone);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64MovMemBaseDispReg8(A, xrRDI, 0, xrRAX);
  X64MovMemBaseDispReg(A, xrR12, FSIM_OS_DIR_NAME_OFFSET, xrRDX);

  { Skip . and .. in the runtime, because every walker wants this. }
  X64CmpRegImm32(A, xrRDX, 1);
  X64JumpCondition(A, xcNotEqual, NotDotLabel);
  X64MovRegMemBaseDisp8(A, xrRAX, xrR12, FSIM_OS_DIR_NAME_BYTES_OFFSET);
  X64CmpRegImm32(A, xrRAX, Ord('.'));
  X64JumpCondition(A, xcEqual, AgainLabel);
  X64BindLabel(A, NotDotLabel);
  X64CmpRegImm32(A, xrRDX, 2);
  X64JumpCondition(A, xcNotEqual, ReturnLabel);
  X64MovRegMemBaseDisp8(A, xrRAX, xrR12, FSIM_OS_DIR_NAME_BYTES_OFFSET);
  X64CmpRegImm32(A, xrRAX, Ord('.'));
  X64JumpCondition(A, xcNotEqual, ReturnLabel);
  X64MovRegMemBaseDisp8(A, xrRAX, xrR12, FSIM_OS_DIR_NAME_BYTES_OFFSET + 1);
  X64CmpRegImm32(A, xrRAX, Ord('.'));
  X64JumpCondition(A, xcEqual, AgainLabel);

  X64BindLabel(A, ReturnLabel);
  X64LeaRegBaseDisp(A, xrRAX, xrR12, FSIM_OS_DIR_NAME_OFFSET);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64Ret(A);

  X64BindLabel(A, SkipLabel);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64BindLabel(A, EndLabel);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitModeToType(var A: TX64Assembler);
var
  IsDirLabel, IsFileLabel, IsLinkLabel, DoneLabel: Int32;
begin
  IsDirLabel := X64NewLabel(A);
  IsFileLabel := X64NewLabel(A);
  IsLinkLabel := X64NewLabel(A);
  DoneLabel := X64NewLabel(A);
  X64AndRegImm32(A, xrRAX, LINUX_S_IFMT);
  X64CmpRegImm32(A, xrRAX, LINUX_S_IFDIR);
  X64JumpCondition(A, xcEqual, IsDirLabel);
  X64CmpRegImm32(A, xrRAX, LINUX_S_IFREG);
  X64JumpCondition(A, xcEqual, IsFileLabel);
  X64CmpRegImm32(A, xrRAX, LINUX_S_IFLNK);
  X64JumpCondition(A, xcEqual, IsLinkLabel);
  X64MovRegImm64(A, xrRAX, FSIM_OS_TYPE_OTHER);
  X64Jump(A, DoneLabel);
  X64BindLabel(A, IsDirLabel);
  X64MovRegImm64(A, xrRAX, FSIM_OS_TYPE_DIRECTORY);
  X64Jump(A, DoneLabel);
  X64BindLabel(A, IsFileLabel);
  X64MovRegImm64(A, xrRAX, FSIM_OS_TYPE_FILE);
  X64Jump(A, DoneLabel);
  X64BindLabel(A, IsLinkLabel);
  X64MovRegImm64(A, xrRAX, FSIM_OS_TYPE_SYMLINK);
  X64BindLabel(A, DoneLabel);
end;

procedure EmitDirType(var A: TX64Assembler; const L: TOSNativeLabels);
var
  NeedStatLabel, TypeDirLabel, TypeFileLabel, TypeLinkLabel,
  TypeOtherLabel, DoneLabel, StatFailedLabel: Int32;
begin
  NeedStatLabel := X64NewLabel(A);
  TypeDirLabel := X64NewLabel(A);
  TypeFileLabel := X64NewLabel(A);
  TypeLinkLabel := X64NewLabel(A);
  TypeOtherLabel := X64NewLabel(A);
  DoneLabel := X64NewLabel(A);
  StatFailedLabel := X64NewLabel(A);

  X64BindLabel(A, L.DirType);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, TypeOtherLabel);
  X64MovRegMemBaseDisp(A, xrRAX, xrRDI, FSIM_OS_DIR_TYPE_OFFSET);
  X64CmpRegImm32(A, xrRAX, LINUX_DT_DIR);
  X64JumpCondition(A, xcEqual, TypeDirLabel);
  X64CmpRegImm32(A, xrRAX, LINUX_DT_REG);
  X64JumpCondition(A, xcEqual, TypeFileLabel);
  X64CmpRegImm32(A, xrRAX, LINUX_DT_LNK);
  X64JumpCondition(A, xcEqual, TypeLinkLabel);
  X64CmpRegImm32(A, xrRAX, LINUX_DT_UNKNOWN);
  X64JumpCondition(A, xcEqual, NeedStatLabel);
  X64Jump(A, TypeOtherLabel);

  X64BindLabel(A, NeedStatLabel);
  X64PushReg(A, xrR12);
  X64MovRegReg(A, xrR12, xrRDI);
  X64SubRegImm32(A, xrRSP, LINUX_STAT_BUFFER_SIZE);
  X64MovRegMemBaseDisp(A, xrRDI, xrR12, FSIM_OS_DIR_FD_OFFSET);
  X64LeaRegBaseDisp(A, xrRSI, xrR12, FSIM_OS_DIR_NAME_BYTES_OFFSET);
  X64MovRegReg(A, xrRDX, xrRSP);
  X64MovRegImm64(A, xrR10, LINUX_AT_SYMLINK_NOFOLLOW);
  X64MovRegImm64(A, xrRAX, LINUX_SYS_NEWFSTATAT);
  X64Syscall(A);
  X64CmpRegImm32(A, xrRAX, 0);
  X64JumpCondition(A, xcLess, StatFailedLabel);
  X64MovSXRegMemBaseDisp32(A, xrRAX, xrRSP, LINUX_STAT_MODE_OFFSET);
  X64AddRegImm32(A, xrRSP, LINUX_STAT_BUFFER_SIZE);
  X64PopReg(A, xrR12);
  EmitModeToType(A);
  X64Ret(A);

  X64BindLabel(A, StatFailedLabel);
  X64AddRegImm32(A, xrRSP, LINUX_STAT_BUFFER_SIZE);
  X64PopReg(A, xrR12);
  X64Jump(A, TypeOtherLabel);

  X64BindLabel(A, TypeDirLabel);
  X64MovRegImm64(A, xrRAX, FSIM_OS_TYPE_DIRECTORY);
  X64Jump(A, DoneLabel);
  X64BindLabel(A, TypeFileLabel);
  X64MovRegImm64(A, xrRAX, FSIM_OS_TYPE_FILE);
  X64Jump(A, DoneLabel);
  X64BindLabel(A, TypeLinkLabel);
  X64MovRegImm64(A, xrRAX, FSIM_OS_TYPE_SYMLINK);
  X64Jump(A, DoneLabel);
  X64BindLabel(A, TypeOtherLabel);
  X64MovRegImm64(A, xrRAX, FSIM_OS_TYPE_OTHER);
  X64BindLabel(A, DoneLabel);
  X64Ret(A);
end;

procedure EmitDirClose(var A: TX64Assembler; const L: TOSNativeLabels);
var
  DoneLabel: Int32;
begin
  DoneLabel := X64NewLabel(A);
  X64BindLabel(A, L.DirClose);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, DoneLabel);
  X64MovRegMemBaseDisp(A, xrRDI, xrRDI, FSIM_OS_DIR_FD_OFFSET);
  X64MovRegImm64(A, xrRAX, LINUX_SYS_CLOSE);
  X64Syscall(A);
  X64Ret(A);
  X64BindLabel(A, DoneLabel);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitPathType(var A: TX64Assembler; const L: TOSNativeLabels);
var
  NilLabel, StatFailedLabel: Int32;
begin
  NilLabel := X64NewLabel(A);
  StatFailedLabel := X64NewLabel(A);
  X64BindLabel(A, L.PathType);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, NilLabel);
  X64SubRegImm32(A, xrRSP, LINUX_STAT_BUFFER_SIZE);
  X64AddRegImm32(A, xrRDI, 8);
  X64MovRegReg(A, xrRSI, xrRDI);
  X64MovRegImm64(A, xrRDI, QWord($FFFFFFFFFFFFFF9C));
  X64MovRegReg(A, xrRDX, xrRSP);
  X64MovRegImm64(A, xrR10, LINUX_AT_SYMLINK_NOFOLLOW);
  X64MovRegImm64(A, xrRAX, LINUX_SYS_NEWFSTATAT);
  X64Syscall(A);
  X64CmpRegImm32(A, xrRAX, 0);
  X64JumpCondition(A, xcLess, StatFailedLabel);
  X64MovSXRegMemBaseDisp32(A, xrRAX, xrRSP, LINUX_STAT_MODE_OFFSET);
  X64AddRegImm32(A, xrRSP, LINUX_STAT_BUFFER_SIZE);
  EmitModeToType(A);
  X64Ret(A);
  X64BindLabel(A, StatFailedLabel);
  X64AddRegImm32(A, xrRSP, LINUX_STAT_BUFFER_SIZE);
  X64BindLabel(A, NilLabel);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitPathSize(var A: TX64Assembler; const L: TOSNativeLabels);
var
  NilLabel, FailedLabel, DoneLabel: Int32;
begin
  NilLabel := X64NewLabel(A);
  FailedLabel := X64NewLabel(A);
  DoneLabel := X64NewLabel(A);
  X64BindLabel(A, L.PathSize);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, NilLabel);
  X64SubRegImm32(A, xrRSP, LINUX_STAT_BUFFER_SIZE);
  X64AddRegImm32(A, xrRDI, 8);
  X64MovRegReg(A, xrRSI, xrRDI);
  X64MovRegImm64(A, xrRDI, QWord($FFFFFFFFFFFFFF9C));
  X64MovRegReg(A, xrRDX, xrRSP);
  X64MovRegImm64(A, xrR10, LINUX_AT_SYMLINK_NOFOLLOW);
  X64MovRegImm64(A, xrRAX, LINUX_SYS_NEWFSTATAT);
  X64Syscall(A);
  X64CmpRegImm32(A, xrRAX, 0);
  X64JumpCondition(A, xcLess, FailedLabel);
  X64MovRegMemBaseDisp(A, xrRAX, xrRSP, LINUX_STAT_SIZE_OFFSET);
  X64AddRegImm32(A, xrRSP, LINUX_STAT_BUFFER_SIZE);
  X64Jump(A, DoneLabel);
  X64BindLabel(A, FailedLabel);
  X64AddRegImm32(A, xrRSP, LINUX_STAT_BUFFER_SIZE);
  X64BindLabel(A, NilLabel);
  X64MovRegImm64(A, xrRAX, High(QWord));
  X64BindLabel(A, DoneLabel);
  X64Ret(A);
end;

procedure EmitPathJoin(var A: TX64Assembler; const L: TOSNativeLabels;
  const Links: TOSNativeLinks);
var
  ParentLenReady, NameLenReady, SlashReady, CopyParentLoop, ParentCopied,
  SlashCopied, CopyNameLoop, NameCopied: Int32;
begin
  ParentLenReady := X64NewLabel(A);
  NameLenReady := X64NewLabel(A);
  SlashReady := X64NewLabel(A);
  CopyParentLoop := X64NewLabel(A);
  ParentCopied := X64NewLabel(A);
  SlashCopied := X64NewLabel(A);
  CopyNameLoop := X64NewLabel(A);
  NameCopied := X64NewLabel(A);

  X64BindLabel(A, L.PathJoin);
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
  X64JumpCondition(A, xcEqual, ParentLenReady);
  X64MovRegMemBaseDisp(A, xrR14, xrR12, 0);
  X64BindLabel(A, ParentLenReady);
  X64TestRegReg(A, xrR13, xrR13);
  X64JumpCondition(A, xcEqual, NameLenReady);
  X64MovRegMemBaseDisp(A, xrR15, xrR13, 0);
  X64BindLabel(A, NameLenReady);

  X64XorRegReg(A, xrRBX, xrRBX);
  X64TestRegReg(A, xrR14, xrR14);
  X64JumpCondition(A, xcEqual, SlashReady);
  X64MovRegReg(A, xrRAX, xrR12);
  X64AddRegImm32(A, xrRAX, 8);
  X64AddRegReg(A, xrRAX, xrR14);
  X64SubRegImm32(A, xrRAX, 1);
  X64MovRegMemBaseDisp8(A, xrRCX, xrRAX, 0);
  X64CmpRegImm32(A, xrRCX, Ord('/'));
  X64JumpCondition(A, xcEqual, SlashReady);
  X64MovRegImm64(A, xrRBX, 1);
  X64BindLabel(A, SlashReady);

  X64MovRegReg(A, xrRDI, xrR14);
  X64AddRegReg(A, xrRDI, xrR15);
  X64AddRegReg(A, xrRDI, xrRBX);
  X64MovRegReg(A, xrRCX, xrRDI);
  X64AddRegImm32(A, xrRDI, 9);
  X64SubRegImm32(A, xrRSP, 16);
  X64MovMemBaseDispReg(A, xrRSP, 0, xrRCX);
  X64Call(A, Links.Allocate);
  X64MovRegMemBaseDisp(A, xrRCX, xrRSP, 0);
  X64AddRegImm32(A, xrRSP, 16);
  X64MovRegReg(A, xrR11, xrRAX);
  X64MovMemBaseDispReg(A, xrR11, 0, xrRCX);
  X64LeaRegBaseDisp(A, xrRDX, xrR11, 8);

  X64TestRegReg(A, xrR14, xrR14);
  X64JumpCondition(A, xcEqual, ParentCopied);
  X64LeaRegBaseDisp(A, xrRSI, xrR12, 8);
  X64MovRegReg(A, xrRCX, xrR14);
  X64BindLabel(A, CopyParentLoop);
  X64MovRegMemBaseDisp8(A, xrRAX, xrRSI, 0);
  X64MovMemBaseDispReg8(A, xrRDX, 0, xrRAX);
  X64AddRegImm32(A, xrRSI, 1);
  X64AddRegImm32(A, xrRDX, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64JumpCondition(A, xcNotEqual, CopyParentLoop);
  X64BindLabel(A, ParentCopied);

  X64TestRegReg(A, xrRBX, xrRBX);
  X64JumpCondition(A, xcEqual, SlashCopied);
  X64MovRegImm64(A, xrRAX, Ord('/'));
  X64MovMemBaseDispReg8(A, xrRDX, 0, xrRAX);
  X64AddRegImm32(A, xrRDX, 1);
  X64BindLabel(A, SlashCopied);

  X64TestRegReg(A, xrR15, xrR15);
  X64JumpCondition(A, xcEqual, NameCopied);
  X64LeaRegBaseDisp(A, xrRSI, xrR13, 8);
  X64MovRegReg(A, xrRCX, xrR15);
  X64BindLabel(A, CopyNameLoop);
  X64MovRegMemBaseDisp8(A, xrRAX, xrRSI, 0);
  X64MovMemBaseDispReg8(A, xrRDX, 0, xrRAX);
  X64AddRegImm32(A, xrRSI, 1);
  X64AddRegImm32(A, xrRDX, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64JumpCondition(A, xcNotEqual, CopyNameLoop);
  X64BindLabel(A, NameCopied);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64MovMemBaseDispReg8(A, xrRDX, 0, xrRAX);
  X64MovRegReg(A, xrRAX, xrR11);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64PopReg(A, xrRBX);
  X64Ret(A);
end;

procedure EmitPathBaseName(var A: TX64Assembler; const L: TOSNativeLabels;
  const Links: TOSNativeLinks);
var
  NilLabel, EmptyLabel, ScanLoop, FoundLabel, CopyLoop, CopyDone: Int32;
begin
  NilLabel := X64NewLabel(A);
  EmptyLabel := X64NewLabel(A);
  ScanLoop := X64NewLabel(A);
  FoundLabel := X64NewLabel(A);
  CopyLoop := X64NewLabel(A);
  CopyDone := X64NewLabel(A);
  X64BindLabel(A, L.PathBaseName);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, NilLabel);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64PushReg(A, xrR15);
  X64MovRegReg(A, xrR12, xrRDI);
  X64MovRegMemBaseDisp(A, xrR13, xrR12, 0);
  X64TestRegReg(A, xrR13, xrR13);
  X64JumpCondition(A, xcEqual, EmptyLabel);
  X64MovRegReg(A, xrR14, xrR13);
  X64BindLabel(A, ScanLoop);
  X64TestRegReg(A, xrR14, xrR14);
  X64JumpCondition(A, xcEqual, FoundLabel);
  X64MovRegReg(A, xrRAX, xrR12);
  X64AddRegImm32(A, xrRAX, 8);
  X64AddRegReg(A, xrRAX, xrR14);
  X64SubRegImm32(A, xrRAX, 1);
  X64MovRegMemBaseDisp8(A, xrRCX, xrRAX, 0);
  X64CmpRegImm32(A, xrRCX, Ord('/'));
  X64JumpCondition(A, xcEqual, FoundLabel);
  X64SubRegImm32(A, xrR14, 1);
  X64Jump(A, ScanLoop);

  X64BindLabel(A, FoundLabel);
  X64MovRegReg(A, xrR15, xrR13);
  X64SubRegReg(A, xrR15, xrR14);
  X64MovRegReg(A, xrRDI, xrR15);
  X64AddRegImm32(A, xrRDI, 9);
  X64SubRegImm32(A, xrRSP, 8);
  X64Call(A, Links.Allocate);
  X64AddRegImm32(A, xrRSP, 8);
  X64MovRegReg(A, xrR11, xrRAX);
  X64MovMemBaseDispReg(A, xrR11, 0, xrR15);
  X64LeaRegBaseDisp(A, xrRDX, xrR11, 8);
  X64LeaRegBaseDisp(A, xrRSI, xrR12, 8);
  X64AddRegReg(A, xrRSI, xrR14);
  X64MovRegReg(A, xrRCX, xrR15);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, CopyDone);
  X64BindLabel(A, CopyLoop);
  X64MovRegMemBaseDisp8(A, xrRDI, xrRSI, 0);
  X64MovMemBaseDispReg8(A, xrRDX, 0, xrRDI);
  X64AddRegImm32(A, xrRSI, 1);
  X64AddRegImm32(A, xrRDX, 1);
  X64SubRegImm32(A, xrRCX, 1);
  X64JumpCondition(A, xcNotEqual, CopyLoop);
  X64BindLabel(A, CopyDone);
  X64XorRegReg(A, xrRDI, xrRDI);
  X64MovMemBaseDispReg8(A, xrRDX, 0, xrRDI);
  X64MovRegReg(A, xrRAX, xrR11);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64Ret(A);

  X64BindLabel(A, EmptyLabel);
  X64PopReg(A, xrR15);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64BindLabel(A, NilLabel);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure EmitStringChar(var A: TX64Assembler; const L: TOSNativeLabels);
var
  InvalidLabel, DoneLabel: Int32;
begin
  InvalidLabel := X64NewLabel(A);
  DoneLabel := X64NewLabel(A);
  X64BindLabel(A, L.StringChar);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, InvalidLabel);
  X64CmpRegImm32(A, xrRSI, 0);
  X64JumpCondition(A, xcLess, InvalidLabel);
  X64MovRegMemBaseDisp(A, xrRAX, xrRDI, 0);
  X64CmpRegReg(A, xrRSI, xrRAX);
  X64JumpCondition(A, xcAboveEqual, InvalidLabel);
  X64LeaRegBaseDisp(A, xrRAX, xrRDI, 8);
  X64AddRegReg(A, xrRAX, xrRSI);
  X64MovRegMemBaseDisp8(A, xrRAX, xrRAX, 0);
  X64Jump(A, DoneLabel);
  X64BindLabel(A, InvalidLabel);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64BindLabel(A, DoneLabel);
  X64Ret(A);
end;

procedure EmitParseInt(var A: TX64Assembler; const L: TOSNativeLabels);
var
  BadLabel, SignReadyLabel, LoopLabel, DoneLabel: Int32;
begin
  BadLabel := X64NewLabel(A);
  SignReadyLabel := X64NewLabel(A);
  LoopLabel := X64NewLabel(A);
  DoneLabel := X64NewLabel(A);
  X64BindLabel(A, L.ParseInt);
  X64MovRegReg(A, xrR10, xrRSI);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, BadLabel);
  X64MovRegMemBaseDisp(A, xrR8, xrRDI, 0);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, BadLabel);
  X64LeaRegBaseDisp(A, xrR9, xrRDI, 8);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64XorRegReg(A, xrR11, xrR11);
  X64MovRegMemBaseDisp8(A, xrRCX, xrR9, 0);
  X64CmpRegImm32(A, xrRCX, Ord('-'));
  X64JumpCondition(A, xcNotEqual, SignReadyLabel);
  X64MovRegImm64(A, xrR11, 1);
  X64AddRegImm32(A, xrR9, 1);
  X64SubRegImm32(A, xrR8, 1);
  X64TestRegReg(A, xrR8, xrR8);
  X64JumpCondition(A, xcEqual, BadLabel);
  X64BindLabel(A, SignReadyLabel);
  X64BindLabel(A, LoopLabel);
  X64MovRegMemBaseDisp8(A, xrRCX, xrR9, 0);
  X64CmpRegImm32(A, xrRCX, Ord('0'));
  X64JumpCondition(A, xcLess, BadLabel);
  X64CmpRegImm32(A, xrRCX, Ord('9'));
  X64JumpCondition(A, xcGreater, BadLabel);
  X64IMulRegRegImm32(A, xrRAX, xrRAX, 10);
  X64SubRegImm32(A, xrRCX, Ord('0'));
  X64AddRegReg(A, xrRAX, xrRCX);
  X64AddRegImm32(A, xrR9, 1);
  X64SubRegImm32(A, xrR8, 1);
  X64JumpCondition(A, xcNotEqual, LoopLabel);
  X64TestRegReg(A, xrR11, xrR11);
  X64JumpCondition(A, xcEqual, DoneLabel);
  X64NegReg(A, xrRAX);
  X64Jump(A, DoneLabel);
  X64BindLabel(A, BadLabel);
  X64MovRegReg(A, xrRAX, xrR10);
  X64BindLabel(A, DoneLabel);
  X64Ret(A);
end;

procedure EmitWritePath(var A: TX64Assembler; const L: TOSNativeLabels;
  const Links: TOSNativeLinks);
var
  ParentReady, SlashReady, NameReady, TermReady: Int32;
begin
  ParentReady := X64NewLabel(A);
  SlashReady := X64NewLabel(A);
  NameReady := X64NewLabel(A);
  TermReady := X64NewLabel(A);
  X64BindLabel(A, L.WritePath);
  X64PushReg(A, xrR12);
  X64PushReg(A, xrR13);
  X64PushReg(A, xrR14);
  X64MovRegReg(A, xrR12, xrRDI);
  X64MovRegReg(A, xrR13, xrRSI);
  X64MovRegReg(A, xrR14, xrRDX);

  { Four iovecs plus two one-byte scratch values.  One writev beats doing
    three or four write syscalls for every single match. }
  X64SubRegImm32(A, xrRSP, 80);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64MovMemBaseDispReg(A, xrRSP, 0, xrRAX);
  X64MovMemBaseDispReg(A, xrRSP, 8, xrRAX);
  X64MovMemBaseDispReg(A, xrRSP, 16, xrRAX);
  X64MovMemBaseDispReg(A, xrRSP, 24, xrRAX);
  X64MovMemBaseDispReg(A, xrRSP, 32, xrRAX);
  X64MovMemBaseDispReg(A, xrRSP, 40, xrRAX);
  X64MovMemBaseDispReg(A, xrRSP, 48, xrRAX);
  X64MovMemBaseDispReg(A, xrRSP, 56, xrRAX);

  X64TestRegReg(A, xrR12, xrR12);
  X64JumpCondition(A, xcEqual, ParentReady);
  X64MovRegMemBaseDisp(A, xrRCX, xrR12, 0);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, ParentReady);
  X64LeaRegBaseDisp(A, xrRAX, xrR12, 8);
  X64MovMemBaseDispReg(A, xrRSP, 0, xrRAX);
  X64MovMemBaseDispReg(A, xrRSP, 8, xrRCX);
  X64BindLabel(A, ParentReady);

  { Slash is its own iovec so ordinary entries need no joined path string. }
  X64MovRegImm64(A, xrRAX, Ord('/'));
  X64MovMemBaseDispReg8(A, xrRSP, 64, xrRAX);
  X64LeaRegBaseDisp(A, xrRAX, xrRSP, 64);
  X64MovMemBaseDispReg(A, xrRSP, 16, xrRAX);
  X64TestRegReg(A, xrR12, xrR12);
  X64JumpCondition(A, xcEqual, SlashReady);
  X64MovRegMemBaseDisp(A, xrRCX, xrR12, 0);
  X64TestRegReg(A, xrRCX, xrRCX);
  X64JumpCondition(A, xcEqual, SlashReady);
  X64TestRegReg(A, xrR13, xrR13);
  X64JumpCondition(A, xcEqual, SlashReady);
  X64MovRegMemBaseDisp(A, xrRDX, xrR13, 0);
  X64TestRegReg(A, xrRDX, xrRDX);
  X64JumpCondition(A, xcEqual, SlashReady);
  X64LeaRegBaseDisp(A, xrRAX, xrR12, 8);
  X64AddRegReg(A, xrRAX, xrRCX);
  X64SubRegImm32(A, xrRAX, 1);
  X64MovRegMemBaseDisp8(A, xrRAX, xrRAX, 0);
  X64CmpRegImm32(A, xrRAX, Ord('/'));
  X64JumpCondition(A, xcEqual, SlashReady);
  X64MovRegImm64(A, xrRAX, 1);
  X64MovMemBaseDispReg(A, xrRSP, 24, xrRAX);
  X64BindLabel(A, SlashReady);

  X64TestRegReg(A, xrR13, xrR13);
  X64JumpCondition(A, xcEqual, NameReady);
  X64MovRegMemBaseDisp(A, xrRCX, xrR13, 0);
  X64LeaRegBaseDisp(A, xrRAX, xrR13, 8);
  X64MovMemBaseDispReg(A, xrRSP, 32, xrRAX);
  X64MovMemBaseDispReg(A, xrRSP, 40, xrRCX);
  X64BindLabel(A, NameReady);

  X64XorRegReg(A, xrRAX, xrRAX);
  X64MovMemBaseDispReg8(A, xrRSP, 65, xrRAX);
  X64TestRegReg(A, xrR14, xrR14);
  X64JumpCondition(A, xcNotEqual, TermReady);
  X64MovRegImm64(A, xrRAX, 10);
  X64MovMemBaseDispReg8(A, xrRSP, 65, xrRAX);
  X64Jump(A, TermReady);
  X64BindLabel(A, TermReady);
  X64LeaRegBaseDisp(A, xrRAX, xrRSP, 65);
  X64MovMemBaseDispReg(A, xrRSP, 48, xrRAX);
  X64MovRegImm64(A, xrRAX, 1);
  X64MovMemBaseDispReg(A, xrRSP, 56, xrRAX);

  X64MovRegImm64(A, xrRDI, 1);
  X64MovRegReg(A, xrRSI, xrRSP);
  X64MovRegImm64(A, xrRDX, 4);
  X64MovRegImm64(A, xrRAX, LINUX_SYS_WRITEV);
  X64Syscall(A);
  X64AddRegImm32(A, xrRSP, 80);
  X64PopReg(A, xrR14);
  X64PopReg(A, xrR13);
  X64PopReg(A, xrR12);
  X64Ret(A);
end;

procedure EmitStderrWrite(var A: TX64Assembler; const L: TOSNativeLabels);
var
  EmptyLabel: Int32;
begin
  EmptyLabel := X64NewLabel(A);
  X64BindLabel(A, L.StderrWrite);
  X64TestRegReg(A, xrRDI, xrRDI);
  X64JumpCondition(A, xcEqual, EmptyLabel);
  X64MovRegMemBaseDisp(A, xrRDX, xrRDI, 0);
  X64LeaRegBaseDisp(A, xrRSI, xrRDI, 8);
  X64MovRegImm64(A, xrRDI, 2);
  X64MovRegImm64(A, xrRAX, LINUX_SYS_WRITE);
  X64Syscall(A);
  X64Ret(A);
  X64BindLabel(A, EmptyLabel);
  X64XorRegReg(A, xrRAX, xrRAX);
  X64Ret(A);
end;

procedure OSEmitNative(var Assembler: TX64Assembler;
  const Labels: TOSNativeLabels; const Data: TOSNativeDataOffsets;
  const Links: TOSNativeLinks);
begin
  EmitArgCount(Assembler, Labels, Data);
  EmitArgument(Assembler, Labels, Data, Links);
  EmitOpenCommon(Assembler, Labels.DirOpen, False, Links);
  EmitOpenCommon(Assembler, Labels.DirOpenAt, True, Links);
  EmitDirNext(Assembler, Labels);
  EmitDirType(Assembler, Labels);
  EmitDirClose(Assembler, Labels);
  EmitPathType(Assembler, Labels);
  EmitPathSize(Assembler, Labels);
  EmitPathJoin(Assembler, Labels, Links);
  EmitPathBaseName(Assembler, Labels, Links);
  EmitStringChar(Assembler, Labels);
  EmitParseInt(Assembler, Labels);
  EmitWritePath(Assembler, Labels, Links);
  EmitStderrWrite(Assembler, Labels);
end;

end.

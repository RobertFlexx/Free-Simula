unit x64;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, core, registers;

type
  TX64Condition = (
    xcOverflow,
    xcNotOverflow,
    xcBelow,
    xcAboveEqual,
    xcEqual,
    xcNotEqual,
    xcBelowEqual,
    xcAbove,
    xcSign,
    xcNotSign,
    xcParity,
    xcNotParity,
    xcLess,
    xcGreaterEqual,
    xcLessEqual,
    xcGreater
  );

  TX64FixupKind = (
    xfkRel32Label,
    xfkRipData32,
    xfkAbs64Data,
    xfkRipWritable32,
    xfkAbs64Writable
  );

  TX64Fixup = packed record
    Kind: TX64FixupKind;
    PatchOffset: Int32;
    SourceEndOffset: Int32;
    TargetLabel: Int32;
    DataOffset: Int32;
    Addend: Int32;
  end;

  TX64Label = packed record
    Offset: Int32;
    Bound: Boolean;
  end;

  TX64Assembler = record
    Code: TByteBuffer;
    Labels: array of TX64Label;
    Fixups: array of TX64Fixup;
  end;

procedure X64Init(var Assembler: TX64Assembler);
procedure X64Clear(var Assembler: TX64Assembler);
function X64NewLabel(var Assembler: TX64Assembler): Int32;
procedure X64BindLabel(var Assembler: TX64Assembler; LabelId: Int32);
procedure X64ResolveTextFixups(var Assembler: TX64Assembler);
procedure X64ResolveDataFixups(var Assembler: TX64Assembler;
  TextVirtualAddress, DataVirtualAddress, WritableVirtualAddress: QWord);
procedure X64EmitByte(var Assembler: TX64Assembler; Value: Byte); inline;
procedure X64EmitWord(var Assembler: TX64Assembler; Value: Word);
procedure X64EmitDWord(var Assembler: TX64Assembler; Value: DWord);
procedure X64EmitQWord(var Assembler: TX64Assembler; Value: QWord);
procedure X64Nop(var Assembler: TX64Assembler);
procedure X64Int3(var Assembler: TX64Assembler);
procedure X64Ret(var Assembler: TX64Assembler);
procedure X64Syscall(var Assembler: TX64Assembler);
procedure X64Pause(var Assembler: TX64Assembler);
procedure X64MemoryFence(var Assembler: TX64Assembler);
procedure X64XchgMemBaseDispReg(var Assembler: TX64Assembler;
  Base: TX64Register; Disp: Int32; Reg: TX64Register);
procedure X64LockCmpXchgMemBaseDispReg(var Assembler: TX64Assembler;
  Base: TX64Register; Disp: Int32; Reg: TX64Register);
procedure X64Leave(var Assembler: TX64Assembler);
procedure X64PushReg(var Assembler: TX64Assembler; Reg: TX64Register);
procedure X64PopReg(var Assembler: TX64Assembler; Reg: TX64Register);
procedure X64MovRegImm64(var Assembler: TX64Assembler; Dst: TX64Register;
  Value: QWord);
procedure X64MovRegImm32(var Assembler: TX64Assembler; Dst: TX64Register;
  Value: DWord);
procedure X64MovRegReg(var Assembler: TX64Assembler; Dst, Src: TX64Register);
procedure X64MovRegMemBaseDisp(var Assembler: TX64Assembler;
  Dst, Base: TX64Register; Disp: Int32);
procedure X64MovMemBaseDispReg(var Assembler: TX64Assembler;
  Base: TX64Register; Disp: Int32; Src: TX64Register);
procedure X64MovRegMemBaseDisp8(var Assembler: TX64Assembler;
  Dst, Base: TX64Register; Disp: Int32);
procedure X64MovSXRegMemBaseDisp8(var Assembler: TX64Assembler;
  Dst, Base: TX64Register; Disp: Int32);
procedure X64MovZXRegMemBaseDisp16(var Assembler: TX64Assembler;
  Dst, Base: TX64Register; Disp: Int32);
procedure X64MovSXRegMemBaseDisp16(var Assembler: TX64Assembler;
  Dst, Base: TX64Register; Disp: Int32);
procedure X64MovZXRegMemBaseDisp32(var Assembler: TX64Assembler;
  Dst, Base: TX64Register; Disp: Int32);
procedure X64MovMemBaseDispReg8(var Assembler: TX64Assembler;
  Base: TX64Register; Disp: Int32; Src: TX64Register);
procedure X64MovMemBaseDispReg16(var Assembler: TX64Assembler;
  Base: TX64Register; Disp: Int32; Src: TX64Register);
procedure X64MovSXRegMemBaseDisp32(var Assembler: TX64Assembler;
  Dst, Base: TX64Register; Disp: Int32);
procedure X64MovMemBaseDispReg32(var Assembler: TX64Assembler;
  Base: TX64Register; Disp: Int32; Src: TX64Register);
procedure X64MovRegMemIndex(var Assembler: TX64Assembler; Dst,
  Base, Index: TX64Register; Scale: Byte; Disp: Int32);
procedure X64MovMemIndexReg(var Assembler: TX64Assembler; Base,
  Index: TX64Register; Scale: Byte; Disp: Int32; Src: TX64Register);
procedure X64LeaRegBaseDisp(var Assembler: TX64Assembler; Dst,
  Base: TX64Register; Disp: Int32);
procedure X64LeaRegRipData(var Assembler: TX64Assembler; Dst: TX64Register;
  DataOffset, Addend: Int32);
procedure X64LeaRegRipWritable(var Assembler: TX64Assembler;
  Dst: TX64Register; DataOffset, Addend: Int32);
procedure X64LeaRegRipLabel(var Assembler: TX64Assembler; Dst: TX64Register;
  LabelId: Int32; Addend: Int32 = 0);
procedure X64AddRegReg(var Assembler: TX64Assembler; Dst, Src: TX64Register);
procedure X64AddRegImm32(var Assembler: TX64Assembler; Dst: TX64Register;
  Value: Int32);
procedure X64SubRegReg(var Assembler: TX64Assembler; Dst, Src: TX64Register);
procedure X64SubRegImm32(var Assembler: TX64Assembler; Dst: TX64Register;
  Value: Int32);
procedure X64AndRegReg(var Assembler: TX64Assembler; Dst, Src: TX64Register);
procedure X64AndRegImm32(var Assembler: TX64Assembler; Dst: TX64Register;
  Value: Int32);
procedure X64OrRegReg(var Assembler: TX64Assembler; Dst, Src: TX64Register);
procedure X64XorRegReg(var Assembler: TX64Assembler; Dst, Src: TX64Register);
procedure X64XorRegImm32(var Assembler: TX64Assembler; Dst: TX64Register;
  Value: Int32);
procedure X64IMulRegReg(var Assembler: TX64Assembler; Dst, Src: TX64Register);
procedure X64IMulRegRegImm32(var Assembler: TX64Assembler; Dst,
  Src: TX64Register; Value: Int32);
procedure X64CQO(var Assembler: TX64Assembler);
procedure X64IDivReg(var Assembler: TX64Assembler; Divisor: TX64Register);
procedure X64DivReg(var Assembler: TX64Assembler; Divisor: TX64Register);
procedure X64NegReg(var Assembler: TX64Assembler; Reg: TX64Register);
procedure X64NotReg(var Assembler: TX64Assembler; Reg: TX64Register);
procedure X64ShlRegCL(var Assembler: TX64Assembler; Reg: TX64Register);
procedure X64ShrRegCL(var Assembler: TX64Assembler; Reg: TX64Register);
procedure X64SarRegCL(var Assembler: TX64Assembler; Reg: TX64Register);
procedure X64ShlRegImm8(var Assembler: TX64Assembler; Reg: TX64Register;
  Count: Byte);
procedure X64ShrRegImm8(var Assembler: TX64Assembler; Reg: TX64Register;
  Count: Byte);
procedure X64SarRegImm8(var Assembler: TX64Assembler; Reg: TX64Register;
  Count: Byte);
procedure X64CmpRegReg(var Assembler: TX64Assembler; Left,
  Right: TX64Register);
procedure X64CmpRegImm32(var Assembler: TX64Assembler; Left: TX64Register;
  Value: Int32);
procedure X64TestRegReg(var Assembler: TX64Assembler; Left,
  Right: TX64Register);
procedure X64SetCondition8(var Assembler: TX64Assembler;
  Condition: TX64Condition; Dst: TX64Register);
procedure X64MovZXReg8(var Assembler: TX64Assembler; Dst,
  Src: TX64Register);
procedure X64Jump(var Assembler: TX64Assembler; LabelId: Int32);
procedure X64JumpCondition(var Assembler: TX64Assembler;
  Condition: TX64Condition; LabelId: Int32);
procedure X64Call(var Assembler: TX64Assembler; LabelId: Int32);
procedure X64CallReg(var Assembler: TX64Assembler; Reg: TX64Register);
procedure X64JumpReg(var Assembler: TX64Assembler; Reg: TX64Register);
procedure X64MovQXMMReg(var Assembler: TX64Assembler; DstXMM,
  SrcGPR: TX64Register);
procedure X64MovQRegXMM(var Assembler: TX64Assembler; DstGPR,
  SrcXMM: TX64Register);
procedure X64CvtSD2SS(var Assembler: TX64Assembler; DstXMM,
  SrcXMM: TX64Register);
procedure X64CvtSS2SD(var Assembler: TX64Assembler; DstXMM,
  SrcXMM: TX64Register);
procedure X64AddSD(var Assembler: TX64Assembler; DstXMM,
  SrcXMM: TX64Register);
procedure X64SubSD(var Assembler: TX64Assembler; DstXMM,
  SrcXMM: TX64Register);
procedure X64MulSD(var Assembler: TX64Assembler; DstXMM,
  SrcXMM: TX64Register);
procedure X64DivSD(var Assembler: TX64Assembler; DstXMM,
  SrcXMM: TX64Register);
procedure X64UComiSD(var Assembler: TX64Assembler; LeftXMM,
  RightXMM: TX64Register);
procedure X64CVTSI2SD(var Assembler: TX64Assembler; DstXMM,
  SrcGPR: TX64Register);
procedure X64CVTTSD2SI(var Assembler: TX64Assembler; DstGPR,
  SrcXMM: TX64Register);

implementation

procedure X64Init(var Assembler: TX64Assembler);
begin
  Assembler := Default(TX64Assembler);
  BufferInit(Assembler.Code, 4096);
end;

procedure X64Clear(var Assembler: TX64Assembler);
begin
  BufferClear(Assembler.Code);
  SetLength(Assembler.Labels, 0);
  SetLength(Assembler.Fixups, 0);
end;

function X64NewLabel(var Assembler: TX64Assembler): Int32;
begin
  Result := Length(Assembler.Labels);
  SetLength(Assembler.Labels, Result + 1);
  Assembler.Labels[Result].Offset := -1;
  Assembler.Labels[Result].Bound := False;
end;

procedure X64BindLabel(var Assembler: TX64Assembler; LabelId: Int32);
begin
  if (LabelId < 0) or (LabelId > High(Assembler.Labels)) then
    raise ERangeError.Create('invalid x86-64 label');
  if Assembler.Labels[LabelId].Bound then
    raise EInvalidOp.Create('x86-64 label was bound twice');
  Assembler.Labels[LabelId].Offset := Assembler.Code.Count;
  Assembler.Labels[LabelId].Bound := True;
end;

procedure AddFixup(var Assembler: TX64Assembler; Kind: TX64FixupKind;
  PatchOffset, SourceEndOffset, TargetLabel, DataOffset, Addend: Int32);
var
  N: Integer;
begin
  N := Length(Assembler.Fixups);
  SetLength(Assembler.Fixups, N + 1);
  Assembler.Fixups[N].Kind := Kind;
  Assembler.Fixups[N].PatchOffset := PatchOffset;
  Assembler.Fixups[N].SourceEndOffset := SourceEndOffset;
  Assembler.Fixups[N].TargetLabel := TargetLabel;
  Assembler.Fixups[N].DataOffset := DataOffset;
  Assembler.Fixups[N].Addend := Addend;
end;

procedure X64ResolveTextFixups(var Assembler: TX64Assembler);
var
  I: Integer;
  Fixup: TX64Fixup;
  Delta: Int64;
begin
  for I := 0 to High(Assembler.Fixups) do
  begin
    Fixup := Assembler.Fixups[I];
    if Fixup.Kind <> xfkRel32Label then Continue;
    if (Fixup.TargetLabel < 0) or
       (Fixup.TargetLabel > High(Assembler.Labels)) or
       not Assembler.Labels[Fixup.TargetLabel].Bound then
      raise EInvalidOp.CreateFmt('unresolved x86-64 label %d',
        [Fixup.TargetLabel]);
    Delta := Int64(Assembler.Labels[Fixup.TargetLabel].Offset) +
      Fixup.Addend - Fixup.SourceEndOffset;
    if (Delta < Low(Int32)) or (Delta > High(Int32)) then
      raise ERangeError.Create('x86-64 relative branch exceeds 32-bit range');
    BufferPatchDWord(Assembler.Code, Fixup.PatchOffset, DWord(Int32(Delta)));
  end;
end;

procedure X64ResolveDataFixups(var Assembler: TX64Assembler;
  TextVirtualAddress, DataVirtualAddress, WritableVirtualAddress: QWord);
var
  I: Integer;
  Fixup: TX64Fixup;
  SourceAddress, TargetAddress: Int64;
  Delta: Int64;
begin
  for I := 0 to High(Assembler.Fixups) do
  begin
    Fixup := Assembler.Fixups[I];
    case Fixup.Kind of
      xfkRipData32:
        begin
          SourceAddress := Int64(TextVirtualAddress) + Fixup.SourceEndOffset;
          TargetAddress := Int64(DataVirtualAddress) + Fixup.DataOffset +
            Fixup.Addend;
          Delta := TargetAddress - SourceAddress;
          if (Delta < Low(Int32)) or (Delta > High(Int32)) then
            raise ERangeError.Create('RIP-relative data reference out of range');
          BufferPatchDWord(Assembler.Code, Fixup.PatchOffset,
            DWord(Int32(Delta)));
        end;
      xfkAbs64Data:
        BufferPatchQWord(Assembler.Code, Fixup.PatchOffset,
          DataVirtualAddress + QWord(Fixup.DataOffset + Fixup.Addend));
      xfkRipWritable32:
        begin
          SourceAddress := Int64(TextVirtualAddress) + Fixup.SourceEndOffset;
          TargetAddress := Int64(WritableVirtualAddress) + Fixup.DataOffset +
            Fixup.Addend;
          Delta := TargetAddress - SourceAddress;
          if (Delta < Low(Int32)) or (Delta > High(Int32)) then
            raise ERangeError.Create('RIP-relative writable data reference out of range');
          BufferPatchDWord(Assembler.Code, Fixup.PatchOffset,
            DWord(Int32(Delta)));
        end;
      xfkAbs64Writable:
        BufferPatchQWord(Assembler.Code, Fixup.PatchOffset,
          WritableVirtualAddress + QWord(Fixup.DataOffset + Fixup.Addend));
    end;
  end;
end;

procedure X64EmitByte(var Assembler: TX64Assembler; Value: Byte); inline;
begin
  BufferAppendByte(Assembler.Code, Value);
end;

procedure X64EmitWord(var Assembler: TX64Assembler; Value: Word);
begin
  BufferAppendWord(Assembler.Code, Value);
end;

procedure X64EmitDWord(var Assembler: TX64Assembler; Value: DWord);
begin
  BufferAppendDWord(Assembler.Code, Value);
end;

procedure X64EmitQWord(var Assembler: TX64Assembler; Value: QWord);
begin
  BufferAppendQWord(Assembler.Code, Value);
end;

procedure EmitRex(var Assembler: TX64Assembler; W: Boolean;
  RegField, IndexField, BaseField: TX64Register; Force: Boolean = False);
var
  Rex: Byte;
begin
  Rex := $40;
  if W then Rex := Rex or $08;
  if RegisterIsExtended(RegField) then Rex := Rex or $04;
  if RegisterIsExtended(IndexField) then Rex := Rex or $02;
  if RegisterIsExtended(BaseField) then Rex := Rex or $01;
  if Force or (Rex <> $40) then X64EmitByte(Assembler, Rex);
end;

procedure EmitModRM(var Assembler: TX64Assembler; ModBits, RegBits,
  RMBits: Byte); inline;
begin
  X64EmitByte(Assembler, Byte((ModBits shl 6) or ((RegBits and 7) shl 3) or
    (RMBits and 7)));
end;

procedure EmitSIB(var Assembler: TX64Assembler; Scale, IndexBits,
  BaseBits: Byte); inline;
begin
  X64EmitByte(Assembler, Byte((Scale shl 6) or ((IndexBits and 7) shl 3) or
    (BaseBits and 7)));
end;

function ScaleBits(Scale: Byte): Byte;
begin
  case Scale of
    1: Result := 0;
    2: Result := 1;
    4: Result := 2;
    8: Result := 3;
  else
    raise ERangeError.Create('x86-64 index scale must be 1, 2, 4, or 8');
  end;
end;

procedure EmitMemoryOperand(var Assembler: TX64Assembler; RegField: Byte;
  Base, Index: TX64Register; Scale: Byte; Disp: Int32);
var
  BaseCode, IndexCode, ModBits: Byte;
  HasIndex, NeedSIB: Boolean;
begin
  BaseCode := RegisterCode(Base);
  HasIndex := Index <> xrNone;
  if HasIndex then IndexCode := RegisterCode(Index) else IndexCode := 4;
  NeedSIB := HasIndex or (BaseCode = 4);
  if (Disp = 0) and (BaseCode <> 5) then
    ModBits := 0
  else if (Disp >= -128) and (Disp <= 127) then
    ModBits := 1
  else
    ModBits := 2;
  if NeedSIB then
  begin
    EmitModRM(Assembler, ModBits, RegField, 4);
    EmitSIB(Assembler, ScaleBits(Scale), IndexCode, BaseCode);
  end
  else
    EmitModRM(Assembler, ModBits, RegField, BaseCode);
  if ModBits = 1 then
    X64EmitByte(Assembler, Byte(ShortInt(Disp)))
  else if ModBits = 2 then
    X64EmitDWord(Assembler, DWord(Disp))
  else if (ModBits = 0) and (BaseCode = 5) then
    X64EmitDWord(Assembler, DWord(Disp));
end;

procedure X64Nop(var Assembler: TX64Assembler);
begin
  X64EmitByte(Assembler, $90);
end;

procedure X64Int3(var Assembler: TX64Assembler);
begin
  X64EmitByte(Assembler, $CC);
end;

procedure X64Ret(var Assembler: TX64Assembler);
begin
  X64EmitByte(Assembler, $C3);
end;

procedure X64Syscall(var Assembler: TX64Assembler);
begin
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, $05);
end;

procedure X64Pause(var Assembler: TX64Assembler);
begin
  X64EmitByte(Assembler, $F3);
  X64EmitByte(Assembler, $90);
end;

procedure X64MemoryFence(var Assembler: TX64Assembler);
begin
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, $AE);
  X64EmitByte(Assembler, $F0);
end;

procedure X64XchgMemBaseDispReg(var Assembler: TX64Assembler;
  Base: TX64Register; Disp: Int32; Reg: TX64Register);
begin
  EmitRex(Assembler, True, Reg, xrNone, Base);
  X64EmitByte(Assembler, $87);
  EmitMemoryOperand(Assembler, RegisterCode(Reg), Base, xrNone, 1, Disp);
end;

procedure X64LockCmpXchgMemBaseDispReg(var Assembler: TX64Assembler;
  Base: TX64Register; Disp: Int32; Reg: TX64Register);
begin
  X64EmitByte(Assembler, $F0);
  EmitRex(Assembler, True, Reg, xrNone, Base);
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, $B1);
  EmitMemoryOperand(Assembler, RegisterCode(Reg), Base, xrNone, 1, Disp);
end;

procedure X64Leave(var Assembler: TX64Assembler);
begin
  X64EmitByte(Assembler, $C9);
end;

procedure X64PushReg(var Assembler: TX64Assembler; Reg: TX64Register);
begin
  if RegisterIsExtended(Reg) then X64EmitByte(Assembler, $41);
  X64EmitByte(Assembler, $50 + RegisterCode(Reg));
end;

procedure X64PopReg(var Assembler: TX64Assembler; Reg: TX64Register);
begin
  if RegisterIsExtended(Reg) then X64EmitByte(Assembler, $41);
  X64EmitByte(Assembler, $58 + RegisterCode(Reg));
end;

procedure X64MovRegImm64(var Assembler: TX64Assembler; Dst: TX64Register;
  Value: QWord);
begin
  EmitRex(Assembler, True, xrNone, xrNone, Dst);
  X64EmitByte(Assembler, $B8 + RegisterCode(Dst));
  X64EmitQWord(Assembler, Value);
end;

procedure X64MovRegImm32(var Assembler: TX64Assembler; Dst: TX64Register;
  Value: DWord);
begin
  EmitRex(Assembler, False, xrNone, xrNone, Dst);
  X64EmitByte(Assembler, $B8 + RegisterCode(Dst));
  X64EmitDWord(Assembler, Value);
end;

procedure X64MovRegReg(var Assembler: TX64Assembler; Dst, Src: TX64Register);
begin
  if Dst = Src then Exit;
  EmitRex(Assembler, True, Src, xrNone, Dst);
  X64EmitByte(Assembler, $89);
  EmitModRM(Assembler, 3, RegisterCode(Src), RegisterCode(Dst));
end;

procedure X64MovRegMemBaseDisp(var Assembler: TX64Assembler;
  Dst, Base: TX64Register; Disp: Int32);
begin
  EmitRex(Assembler, True, Dst, xrNone, Base);
  X64EmitByte(Assembler, $8B);
  EmitMemoryOperand(Assembler, RegisterCode(Dst), Base, xrNone, 1, Disp);
end;

procedure X64MovMemBaseDispReg(var Assembler: TX64Assembler;
  Base: TX64Register; Disp: Int32; Src: TX64Register);
begin
  EmitRex(Assembler, True, Src, xrNone, Base);
  X64EmitByte(Assembler, $89);
  EmitMemoryOperand(Assembler, RegisterCode(Src), Base, xrNone, 1, Disp);
end;

procedure X64MovRegMemBaseDisp8(var Assembler: TX64Assembler;
  Dst, Base: TX64Register; Disp: Int32);
begin
  EmitRex(Assembler, True, Dst, xrNone, Base);
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, $B6);
  EmitMemoryOperand(Assembler, RegisterCode(Dst), Base, xrNone, 1, Disp);
end;

procedure X64MovSXRegMemBaseDisp8(var Assembler: TX64Assembler;
  Dst, Base: TX64Register; Disp: Int32);
begin
  EmitRex(Assembler, True, Dst, xrNone, Base);
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, $BE);
  EmitMemoryOperand(Assembler, RegisterCode(Dst), Base, xrNone, 1, Disp);
end;

procedure X64MovZXRegMemBaseDisp16(var Assembler: TX64Assembler;
  Dst, Base: TX64Register; Disp: Int32);
begin
  EmitRex(Assembler, True, Dst, xrNone, Base);
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, $B7);
  EmitMemoryOperand(Assembler, RegisterCode(Dst), Base, xrNone, 1, Disp);
end;

procedure X64MovSXRegMemBaseDisp16(var Assembler: TX64Assembler;
  Dst, Base: TX64Register; Disp: Int32);
begin
  EmitRex(Assembler, True, Dst, xrNone, Base);
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, $BF);
  EmitMemoryOperand(Assembler, RegisterCode(Dst), Base, xrNone, 1, Disp);
end;

procedure X64MovZXRegMemBaseDisp32(var Assembler: TX64Assembler;
  Dst, Base: TX64Register; Disp: Int32);
begin
  EmitRex(Assembler, False, Dst, xrNone, Base);
  X64EmitByte(Assembler, $8B);
  EmitMemoryOperand(Assembler, RegisterCode(Dst), Base, xrNone, 1, Disp);
end;

procedure X64MovMemBaseDispReg8(var Assembler: TX64Assembler;
  Base: TX64Register; Disp: Int32; Src: TX64Register);
begin
  EmitRex(Assembler, False, Src, xrNone, Base, RegisterCode(Src) >= 4);
  X64EmitByte(Assembler, $88);
  EmitMemoryOperand(Assembler, RegisterCode(Src), Base, xrNone, 1, Disp);
end;

procedure X64MovMemBaseDispReg16(var Assembler: TX64Assembler;
  Base: TX64Register; Disp: Int32; Src: TX64Register);
begin
  X64EmitByte(Assembler, $66);
  EmitRex(Assembler, False, Src, xrNone, Base);
  X64EmitByte(Assembler, $89);
  EmitMemoryOperand(Assembler, RegisterCode(Src), Base, xrNone, 1, Disp);
end;

procedure X64MovSXRegMemBaseDisp32(var Assembler: TX64Assembler;
  Dst, Base: TX64Register; Disp: Int32);
begin
  EmitRex(Assembler, True, Dst, xrNone, Base);
  X64EmitByte(Assembler, $63);
  EmitMemoryOperand(Assembler, RegisterCode(Dst), Base, xrNone, 1, Disp);
end;

procedure X64MovMemBaseDispReg32(var Assembler: TX64Assembler;
  Base: TX64Register; Disp: Int32; Src: TX64Register);
begin
  EmitRex(Assembler, False, Src, xrNone, Base);
  X64EmitByte(Assembler, $89);
  EmitMemoryOperand(Assembler, RegisterCode(Src), Base, xrNone, 1, Disp);
end;

procedure X64MovRegMemIndex(var Assembler: TX64Assembler; Dst,
  Base, Index: TX64Register; Scale: Byte; Disp: Int32);
begin
  EmitRex(Assembler, True, Dst, Index, Base);
  X64EmitByte(Assembler, $8B);
  EmitMemoryOperand(Assembler, RegisterCode(Dst), Base, Index, Scale, Disp);
end;

procedure X64MovMemIndexReg(var Assembler: TX64Assembler; Base,
  Index: TX64Register; Scale: Byte; Disp: Int32; Src: TX64Register);
begin
  EmitRex(Assembler, True, Src, Index, Base);
  X64EmitByte(Assembler, $89);
  EmitMemoryOperand(Assembler, RegisterCode(Src), Base, Index, Scale, Disp);
end;

procedure X64LeaRegBaseDisp(var Assembler: TX64Assembler; Dst,
  Base: TX64Register; Disp: Int32);
begin
  EmitRex(Assembler, True, Dst, xrNone, Base);
  X64EmitByte(Assembler, $8D);
  EmitMemoryOperand(Assembler, RegisterCode(Dst), Base, xrNone, 1, Disp);
end;

procedure X64LeaRegRipData(var Assembler: TX64Assembler; Dst: TX64Register;
  DataOffset, Addend: Int32);
var
  Patch: Int32;
begin
  EmitRex(Assembler, True, Dst, xrNone, xrNone);
  X64EmitByte(Assembler, $8D);
  EmitModRM(Assembler, 0, RegisterCode(Dst), 5);
  Patch := Assembler.Code.Count;
  X64EmitDWord(Assembler, 0);
  AddFixup(Assembler, xfkRipData32, Patch, Assembler.Code.Count, -1,
    DataOffset, Addend);
end;

procedure X64LeaRegRipWritable(var Assembler: TX64Assembler;
  Dst: TX64Register; DataOffset, Addend: Int32);
var
  Patch: Int32;
begin
  EmitRex(Assembler, True, Dst, xrNone, xrNone);
  X64EmitByte(Assembler, $8D);
  EmitModRM(Assembler, 0, RegisterCode(Dst), 5);
  Patch := Assembler.Code.Count;
  X64EmitDWord(Assembler, 0);
  AddFixup(Assembler, xfkRipWritable32, Patch, Assembler.Code.Count, -1,
    DataOffset, Addend);
end;

procedure EmitRegRegOp(var Assembler: TX64Assembler; Opcode: Byte;
  Dst, Src: TX64Register);
begin
  EmitRex(Assembler, True, Src, xrNone, Dst);
  X64EmitByte(Assembler, Opcode);
  EmitModRM(Assembler, 3, RegisterCode(Src), RegisterCode(Dst));
end;

procedure EmitRegImm32Group(var Assembler: TX64Assembler; Group: Byte;
  Dst: TX64Register; Value: Int32);
begin
  EmitRex(Assembler, True, xrNone, xrNone, Dst);
  X64EmitByte(Assembler, $81);
  EmitModRM(Assembler, 3, Group, RegisterCode(Dst));
  X64EmitDWord(Assembler, DWord(Value));
end;

procedure X64LeaRegRipLabel(var Assembler: TX64Assembler;
  Dst: TX64Register; LabelId: Int32; Addend: Int32);
var
  Patch: Int32;
begin
  EmitRex(Assembler, True, Dst, xrNone, xrNone);
  X64EmitByte(Assembler, $8D);
  EmitModRM(Assembler, 0, RegisterCode(Dst), 5);
  Patch := Assembler.Code.Count;
  X64EmitDWord(Assembler, 0);
  AddFixup(Assembler, xfkRel32Label, Patch, Assembler.Code.Count, LabelId,
    0, Addend);
end;

procedure X64AddRegReg(var Assembler: TX64Assembler; Dst, Src: TX64Register);
begin EmitRegRegOp(Assembler, $01, Dst, Src); end;
procedure X64AddRegImm32(var Assembler: TX64Assembler; Dst: TX64Register;
  Value: Int32);
begin EmitRegImm32Group(Assembler, 0, Dst, Value); end;
procedure X64SubRegReg(var Assembler: TX64Assembler; Dst, Src: TX64Register);
begin EmitRegRegOp(Assembler, $29, Dst, Src); end;
procedure X64SubRegImm32(var Assembler: TX64Assembler; Dst: TX64Register;
  Value: Int32);
begin EmitRegImm32Group(Assembler, 5, Dst, Value); end;
procedure X64AndRegReg(var Assembler: TX64Assembler; Dst, Src: TX64Register);
begin EmitRegRegOp(Assembler, $21, Dst, Src); end;
procedure X64AndRegImm32(var Assembler: TX64Assembler; Dst: TX64Register;
  Value: Int32);
begin EmitRegImm32Group(Assembler, 4, Dst, Value); end;
procedure X64OrRegReg(var Assembler: TX64Assembler; Dst, Src: TX64Register);
begin EmitRegRegOp(Assembler, $09, Dst, Src); end;
procedure X64XorRegReg(var Assembler: TX64Assembler; Dst, Src: TX64Register);
begin EmitRegRegOp(Assembler, $31, Dst, Src); end;
procedure X64XorRegImm32(var Assembler: TX64Assembler; Dst: TX64Register;
  Value: Int32);
begin EmitRegImm32Group(Assembler, 6, Dst, Value); end;

procedure X64IMulRegReg(var Assembler: TX64Assembler; Dst, Src: TX64Register);
begin
  EmitRex(Assembler, True, Dst, xrNone, Src);
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, $AF);
  EmitModRM(Assembler, 3, RegisterCode(Dst), RegisterCode(Src));
end;

procedure X64IMulRegRegImm32(var Assembler: TX64Assembler; Dst,
  Src: TX64Register; Value: Int32);
begin
  EmitRex(Assembler, True, Dst, xrNone, Src);
  X64EmitByte(Assembler, $69);
  EmitModRM(Assembler, 3, RegisterCode(Dst), RegisterCode(Src));
  X64EmitDWord(Assembler, DWord(Value));
end;

procedure X64CQO(var Assembler: TX64Assembler);
begin
  X64EmitByte(Assembler, $48);
  X64EmitByte(Assembler, $99);
end;

procedure X64IDivReg(var Assembler: TX64Assembler; Divisor: TX64Register);
begin
  EmitRex(Assembler, True, xrNone, xrNone, Divisor);
  X64EmitByte(Assembler, $F7);
  EmitModRM(Assembler, 3, 7, RegisterCode(Divisor));
end;

procedure X64DivReg(var Assembler: TX64Assembler; Divisor: TX64Register);
begin
  EmitRex(Assembler, True, xrNone, xrNone, Divisor);
  X64EmitByte(Assembler, $F7);
  EmitModRM(Assembler, 3, 6, RegisterCode(Divisor));
end;

procedure X64NegReg(var Assembler: TX64Assembler; Reg: TX64Register);
begin
  EmitRex(Assembler, True, xrNone, xrNone, Reg);
  X64EmitByte(Assembler, $F7);
  EmitModRM(Assembler, 3, 3, RegisterCode(Reg));
end;

procedure X64NotReg(var Assembler: TX64Assembler; Reg: TX64Register);
begin
  EmitRex(Assembler, True, xrNone, xrNone, Reg);
  X64EmitByte(Assembler, $F7);
  EmitModRM(Assembler, 3, 2, RegisterCode(Reg));
end;

procedure EmitShiftCL(var Assembler: TX64Assembler; Group: Byte;
  Reg: TX64Register);
begin
  EmitRex(Assembler, True, xrNone, xrNone, Reg);
  X64EmitByte(Assembler, $D3);
  EmitModRM(Assembler, 3, Group, RegisterCode(Reg));
end;

procedure EmitShiftImm(var Assembler: TX64Assembler; Group: Byte;
  Reg: TX64Register; Count: Byte);
begin
  EmitRex(Assembler, True, xrNone, xrNone, Reg);
  X64EmitByte(Assembler, $C1);
  EmitModRM(Assembler, 3, Group, RegisterCode(Reg));
  X64EmitByte(Assembler, Count);
end;

procedure X64ShlRegCL(var Assembler: TX64Assembler; Reg: TX64Register);
begin EmitShiftCL(Assembler, 4, Reg); end;
procedure X64ShrRegCL(var Assembler: TX64Assembler; Reg: TX64Register);
begin EmitShiftCL(Assembler, 5, Reg); end;
procedure X64SarRegCL(var Assembler: TX64Assembler; Reg: TX64Register);
begin EmitShiftCL(Assembler, 7, Reg); end;
procedure X64ShlRegImm8(var Assembler: TX64Assembler; Reg: TX64Register;
  Count: Byte);
begin EmitShiftImm(Assembler, 4, Reg, Count); end;
procedure X64ShrRegImm8(var Assembler: TX64Assembler; Reg: TX64Register;
  Count: Byte);
begin EmitShiftImm(Assembler, 5, Reg, Count); end;
procedure X64SarRegImm8(var Assembler: TX64Assembler; Reg: TX64Register;
  Count: Byte);
begin EmitShiftImm(Assembler, 7, Reg, Count); end;

procedure X64CmpRegReg(var Assembler: TX64Assembler; Left,
  Right: TX64Register);
begin EmitRegRegOp(Assembler, $39, Left, Right); end;

procedure X64CmpRegImm32(var Assembler: TX64Assembler; Left: TX64Register;
  Value: Int32);
begin EmitRegImm32Group(Assembler, 7, Left, Value); end;

procedure X64TestRegReg(var Assembler: TX64Assembler; Left,
  Right: TX64Register);
begin
  EmitRex(Assembler, True, Right, xrNone, Left);
  X64EmitByte(Assembler, $85);
  EmitModRM(Assembler, 3, RegisterCode(Right), RegisterCode(Left));
end;

procedure X64SetCondition8(var Assembler: TX64Assembler;
  Condition: TX64Condition; Dst: TX64Register);
begin
  EmitRex(Assembler, False, xrNone, xrNone, Dst,
    RegisterCode(Dst) >= 4);
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, $90 + Ord(Condition));
  EmitModRM(Assembler, 3, 0, RegisterCode(Dst));
end;

procedure X64MovZXReg8(var Assembler: TX64Assembler; Dst,
  Src: TX64Register);
begin
  EmitRex(Assembler, True, Dst, xrNone, Src, RegisterCode(Src) >= 4);
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, $B6);
  EmitModRM(Assembler, 3, RegisterCode(Dst), RegisterCode(Src));
end;

procedure EmitLabelRel32(var Assembler: TX64Assembler; LabelId: Int32);
var
  Patch: Int32;
begin
  Patch := Assembler.Code.Count;
  X64EmitDWord(Assembler, 0);
  AddFixup(Assembler, xfkRel32Label, Patch, Assembler.Code.Count, LabelId,
    0, 0);
end;

procedure X64Jump(var Assembler: TX64Assembler; LabelId: Int32);
begin
  X64EmitByte(Assembler, $E9);
  EmitLabelRel32(Assembler, LabelId);
end;

procedure X64JumpCondition(var Assembler: TX64Assembler;
  Condition: TX64Condition; LabelId: Int32);
begin
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, $80 + Ord(Condition));
  EmitLabelRel32(Assembler, LabelId);
end;

procedure X64Call(var Assembler: TX64Assembler; LabelId: Int32);
begin
  X64EmitByte(Assembler, $E8);
  EmitLabelRel32(Assembler, LabelId);
end;

procedure X64CallReg(var Assembler: TX64Assembler; Reg: TX64Register);
begin
  EmitRex(Assembler, True, xrNone, xrNone, Reg);
  X64EmitByte(Assembler, $FF);
  EmitModRM(Assembler, 3, 2, RegisterCode(Reg));
end;

procedure X64JumpReg(var Assembler: TX64Assembler; Reg: TX64Register);
begin
  EmitRex(Assembler, True, xrNone, xrNone, Reg);
  X64EmitByte(Assembler, $FF);
  EmitModRM(Assembler, 3, 4, RegisterCode(Reg));
end;

procedure X64MovQXMMReg(var Assembler: TX64Assembler; DstXMM,
  SrcGPR: TX64Register);
begin
  X64EmitByte(Assembler, $66);
  EmitRex(Assembler, True, DstXMM, xrNone, SrcGPR);
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, $6E);
  EmitModRM(Assembler, 3, RegisterCode(DstXMM), RegisterCode(SrcGPR));
end;

procedure X64MovQRegXMM(var Assembler: TX64Assembler; DstGPR,
  SrcXMM: TX64Register);
begin
  X64EmitByte(Assembler, $66);
  EmitRex(Assembler, True, SrcXMM, xrNone, DstGPR);
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, $7E);
  EmitModRM(Assembler, 3, RegisterCode(SrcXMM), RegisterCode(DstGPR));
end;

procedure EmitScalarDoubleOp(var Assembler: TX64Assembler; Opcode: Byte;
  DstXMM, SrcXMM: TX64Register);
begin
  X64EmitByte(Assembler, $F2);
  EmitRex(Assembler, False, DstXMM, xrNone, SrcXMM);
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, Opcode);
  EmitModRM(Assembler, 3, RegisterCode(DstXMM), RegisterCode(SrcXMM));
end;

procedure X64CvtSD2SS(var Assembler: TX64Assembler; DstXMM,
  SrcXMM: TX64Register);
begin
  X64EmitByte(Assembler, $F2);
  EmitRex(Assembler, False, DstXMM, xrNone, SrcXMM);
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, $5A);
  EmitModRM(Assembler, 3, RegisterCode(DstXMM), RegisterCode(SrcXMM));
end;

procedure X64CvtSS2SD(var Assembler: TX64Assembler; DstXMM,
  SrcXMM: TX64Register);
begin
  X64EmitByte(Assembler, $F3);
  EmitRex(Assembler, False, DstXMM, xrNone, SrcXMM);
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, $5A);
  EmitModRM(Assembler, 3, RegisterCode(DstXMM), RegisterCode(SrcXMM));
end;

procedure X64AddSD(var Assembler: TX64Assembler; DstXMM,
  SrcXMM: TX64Register);
begin EmitScalarDoubleOp(Assembler, $58, DstXMM, SrcXMM); end;
procedure X64SubSD(var Assembler: TX64Assembler; DstXMM,
  SrcXMM: TX64Register);
begin EmitScalarDoubleOp(Assembler, $5C, DstXMM, SrcXMM); end;
procedure X64MulSD(var Assembler: TX64Assembler; DstXMM,
  SrcXMM: TX64Register);
begin EmitScalarDoubleOp(Assembler, $59, DstXMM, SrcXMM); end;
procedure X64DivSD(var Assembler: TX64Assembler; DstXMM,
  SrcXMM: TX64Register);
begin EmitScalarDoubleOp(Assembler, $5E, DstXMM, SrcXMM); end;

procedure X64UComiSD(var Assembler: TX64Assembler; LeftXMM,
  RightXMM: TX64Register);
begin
  X64EmitByte(Assembler, $66);
  EmitRex(Assembler, False, LeftXMM, xrNone, RightXMM);
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, $2E);
  EmitModRM(Assembler, 3, RegisterCode(LeftXMM), RegisterCode(RightXMM));
end;

procedure X64CVTSI2SD(var Assembler: TX64Assembler; DstXMM,
  SrcGPR: TX64Register);
begin
  X64EmitByte(Assembler, $F2);
  EmitRex(Assembler, True, DstXMM, xrNone, SrcGPR);
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, $2A);
  EmitModRM(Assembler, 3, RegisterCode(DstXMM), RegisterCode(SrcGPR));
end;

procedure X64CVTTSD2SI(var Assembler: TX64Assembler; DstGPR,
  SrcXMM: TX64Register);
begin
  X64EmitByte(Assembler, $F2);
  EmitRex(Assembler, True, DstGPR, xrNone, SrcXMM);
  X64EmitByte(Assembler, $0F);
  X64EmitByte(Assembler, $2C);
  EmitModRM(Assembler, 3, RegisterCode(DstGPR), RegisterCode(SrcXMM));
end;

end.

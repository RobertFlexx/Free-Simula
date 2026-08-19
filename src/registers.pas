unit registers;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, core, ir;

type
  TX64Register = (
    xrNone,
    xrRAX,
    xrRCX,
    xrRDX,
    xrRBX,
    xrRSP,
    xrRBP,
    xrRSI,
    xrRDI,
    xrR8,
    xrR9,
    xrR10,
    xrR11,
    xrR12,
    xrR13,
    xrR14,
    xrR15,
    xrXMM0,
    xrXMM1,
    xrXMM2,
    xrXMM3,
    xrXMM4,
    xrXMM5,
    xrXMM6,
    xrXMM7
  );

  TValueLocationKind = (vlInvalid, vlRegister, vlStack, vlImmediate);

  TValueLocation = packed record
    Kind: TValueLocationKind;
    RegisterId: TX64Register;
    StackOffset: Int32;
    Size: UInt16;
    Alignment: UInt16;
  end;

  TLiveInterval = packed record
    ValueId: Int32;
    FunctionId: Int32;
    StartPosition: Int32;
    EndPosition: Int32;
    UseCount: UInt32;
    AssignedRegister: TX64Register;
    SpillOffset: Int32;
    CrossesCall: Boolean;
  end;

  TFunctionAllocation = packed record
    FunctionId: Int32;
    FrameSize: UInt32;
    SpillSize: UInt32;
    UsedRegisterMask: UInt32;
    SpillCount: UInt32;
  end;

  TRegisterAllocation = record
    Locations: array of TValueLocation;
    Intervals: array of TLiveInterval;
    Functions: array of TFunctionAllocation;
  end;

procedure AllocateRegisters(var ProgramIR: TIRProgram;
  out Allocation: TRegisterAllocation);
function RegisterName(RegisterId: TX64Register): RawByteString;
function RegisterCode(RegisterId: TX64Register): Byte;
function RegisterIsExtended(RegisterId: TX64Register): Boolean;
function RegisterIsXMM(RegisterId: TX64Register): Boolean;
function LocationText(const Location: TValueLocation): RawByteString;
procedure DumpRegisterAllocation(const ProgramIR: TIRProgram;
  const Allocation: TRegisterAllocation);

implementation

const
  ALLOCATABLE_GPRS: array[0..4] of TX64Register = (
    xrRBX, xrR12, xrR13, xrR14, xrR15
  );

function RegisterName(RegisterId: TX64Register): RawByteString;
begin
  case RegisterId of
    xrRAX: Result := 'rax';
    xrRCX: Result := 'rcx';
    xrRDX: Result := 'rdx';
    xrRBX: Result := 'rbx';
    xrRSP: Result := 'rsp';
    xrRBP: Result := 'rbp';
    xrRSI: Result := 'rsi';
    xrRDI: Result := 'rdi';
    xrR8: Result := 'r8';
    xrR9: Result := 'r9';
    xrR10: Result := 'r10';
    xrR11: Result := 'r11';
    xrR12: Result := 'r12';
    xrR13: Result := 'r13';
    xrR14: Result := 'r14';
    xrR15: Result := 'r15';
    xrXMM0: Result := 'xmm0';
    xrXMM1: Result := 'xmm1';
    xrXMM2: Result := 'xmm2';
    xrXMM3: Result := 'xmm3';
    xrXMM4: Result := 'xmm4';
    xrXMM5: Result := 'xmm5';
    xrXMM6: Result := 'xmm6';
    xrXMM7: Result := 'xmm7';
  else
    Result := '<none>';
  end;
end;

function RegisterCode(RegisterId: TX64Register): Byte;
begin
  case RegisterId of
    xrRAX: Result := 0;
    xrRCX: Result := 1;
    xrRDX: Result := 2;
    xrRBX: Result := 3;
    xrRSP: Result := 4;
    xrRBP: Result := 5;
    xrRSI: Result := 6;
    xrRDI: Result := 7;
    xrR8: Result := 0;
    xrR9: Result := 1;
    xrR10: Result := 2;
    xrR11: Result := 3;
    xrR12: Result := 4;
    xrR13: Result := 5;
    xrR14: Result := 6;
    xrR15: Result := 7;
    xrXMM0: Result := 0;
    xrXMM1: Result := 1;
    xrXMM2: Result := 2;
    xrXMM3: Result := 3;
    xrXMM4: Result := 4;
    xrXMM5: Result := 5;
    xrXMM6: Result := 6;
    xrXMM7: Result := 7;
  else
    Result := 0;
  end;
end;

function RegisterIsExtended(RegisterId: TX64Register): Boolean;
begin
  Result := RegisterId in [xrR8, xrR9, xrR10, xrR11, xrR12, xrR13, xrR14,
    xrR15];
end;

function RegisterIsXMM(RegisterId: TX64Register): Boolean;
begin
  Result := RegisterId in [xrXMM0, xrXMM1, xrXMM2, xrXMM3, xrXMM4, xrXMM5,
    xrXMM6, xrXMM7];
end;

function LocationText(const Location: TValueLocation): RawByteString;
begin
  case Location.Kind of
    vlRegister: Result := RegisterName(Location.RegisterId);
    vlStack: Result := '[rbp-' + IntToStr(Location.StackOffset) + ']';
    vlImmediate: Result := '<immediate>';
  else
    Result := '<invalid>';
  end;
end;

procedure BuildIntervals(const ProgramIR: TIRProgram;
  var Allocation: TRegisterAllocation);
var
  I, D: Integer;
begin
  SetLength(Allocation.Intervals, Length(ProgramIR.Values));
  SetLength(Allocation.Locations, Length(ProgramIR.Values));
  for I := 0 to High(ProgramIR.Values) do
  begin
    Allocation.Intervals[I] := Default(TLiveInterval);
    Allocation.Locations[I] := Default(TValueLocation);
    Allocation.Intervals[I].ValueId := I;
    Allocation.Intervals[I].FunctionId := ProgramIR.Values[I].FunctionId;
    Allocation.Intervals[I].StartPosition := ProgramIR.Values[I].DefInstruction;
    Allocation.Intervals[I].EndPosition := ProgramIR.Values[I].LastUse;
    if Allocation.Intervals[I].EndPosition <
       Allocation.Intervals[I].StartPosition then
      Allocation.Intervals[I].EndPosition :=
        Allocation.Intervals[I].StartPosition;
    Allocation.Intervals[I].UseCount := ProgramIR.Values[I].UseCount;
    Allocation.Intervals[I].AssignedRegister := xrNone;
    Allocation.Intervals[I].SpillOffset := 0;
    Allocation.Locations[I].Kind := vlInvalid;
    Allocation.Locations[I].Size := 8;
    Allocation.Locations[I].Alignment := 8;
    D := ProgramIR.Values[I].DefInstruction;
    if (D >= 0) and (D <= High(ProgramIR.Instructions)) and
       (ProgramIR.Instructions[D].Op in [irConstInt, irConstReal,
        irConstNull, irConstString]) and (ProgramIR.Values[I].UseCount = 1) then
      Allocation.Locations[I].Kind := vlImmediate;
  end;
end;

procedure SortIntervals(var Intervals: array of TLiveInterval;
  const ValueIds: TInt32Array);
var
  I, J: Integer;
  Temp: TLiveInterval;
begin
  for I := 1 to High(ValueIds) do
  begin
    J := I;
    while (J > 0) and
      ((Intervals[ValueIds[J - 1]].StartPosition >
        Intervals[ValueIds[J]].StartPosition) or
       ((Intervals[ValueIds[J - 1]].StartPosition =
         Intervals[ValueIds[J]].StartPosition) and
        (Intervals[ValueIds[J - 1]].EndPosition >
         Intervals[ValueIds[J]].EndPosition))) do
    begin
      Temp := Intervals[ValueIds[J - 1]];
      Intervals[ValueIds[J - 1]] := Intervals[ValueIds[J]];
      Intervals[ValueIds[J]] := Temp;
      Dec(J);
    end;
  end;
end;

procedure SortValueIdsByStart(const Intervals: array of TLiveInterval;
  var ValueIds: TInt32Array);
var
  I, J, Temp: Integer;
begin
  for I := 1 to High(ValueIds) do
  begin
    Temp := ValueIds[I];
    J := I - 1;
    while (J >= 0) and
      ((Intervals[ValueIds[J]].StartPosition > Intervals[Temp].StartPosition) or
       ((Intervals[ValueIds[J]].StartPosition = Intervals[Temp].StartPosition) and
        (Intervals[ValueIds[J]].EndPosition > Intervals[Temp].EndPosition))) do
    begin
      ValueIds[J + 1] := ValueIds[J];
      Dec(J);
    end;
    ValueIds[J + 1] := Temp;
  end;
end;

procedure SortActiveByEnd(const Intervals: array of TLiveInterval;
  var Active: TInt32Array);
var
  I, J, Temp: Integer;
begin
  for I := 1 to High(Active) do
  begin
    Temp := Active[I];
    J := I - 1;
    while (J >= 0) and
      (Intervals[Active[J]].EndPosition > Intervals[Temp].EndPosition) do
    begin
      Active[J + 1] := Active[J];
      Dec(J);
    end;
    Active[J + 1] := Temp;
  end;
end;

function RegisterBit(RegisterId: TX64Register): UInt32; inline;
begin
  Result := UInt32(1) shl Ord(RegisterId);
end;

procedure ExpireOldIntervals(var Allocation: TRegisterAllocation;
  CurrentValue: Int32; var Active: TInt32Array; var FreeMask: UInt32);
var
  I, KeepCount, ValueId: Integer;
begin
  KeepCount := 0;
  for I := 0 to High(Active) do
  begin
    ValueId := Active[I];
    if Allocation.Intervals[ValueId].EndPosition <
       Allocation.Intervals[CurrentValue].StartPosition then
      FreeMask := FreeMask or RegisterBit(
        Allocation.Intervals[ValueId].AssignedRegister)
    else
    begin
      Active[KeepCount] := ValueId;
      Inc(KeepCount);
    end;
  end;
  SetLength(Active, KeepCount);
end;

function TakeFreeRegister(var FreeMask: UInt32): TX64Register;
var
  I: Integer;
  R: TX64Register;
begin
  for I := 0 to High(ALLOCATABLE_GPRS) do
  begin
    R := ALLOCATABLE_GPRS[I];
    if (FreeMask and RegisterBit(R)) <> 0 then
    begin
      FreeMask := FreeMask and not RegisterBit(R);
      Exit(R);
    end;
  end;
  Result := xrNone;
end;

function AllocateSpill(var FunctionAllocation: TFunctionAllocation): Int32;
begin
  Inc(FunctionAllocation.SpillSize, 8);
  Inc(FunctionAllocation.SpillCount);
  Result := FunctionAllocation.SpillSize;
end;

procedure AssignRegister(var Allocation: TRegisterAllocation; ValueId: Int32;
  RegisterId: TX64Register; var FunctionAllocation: TFunctionAllocation);
begin
  Allocation.Intervals[ValueId].AssignedRegister := RegisterId;
  Allocation.Locations[ValueId].Kind := vlRegister;
  Allocation.Locations[ValueId].RegisterId := RegisterId;
  FunctionAllocation.UsedRegisterMask := FunctionAllocation.UsedRegisterMask or
    RegisterBit(RegisterId);
end;

procedure SpillValue(var Allocation: TRegisterAllocation; ValueId: Int32;
  var FunctionAllocation: TFunctionAllocation);
var
  Offset: Int32;
begin
  Offset := AllocateSpill(FunctionAllocation);
  Allocation.Intervals[ValueId].AssignedRegister := xrNone;
  Allocation.Intervals[ValueId].SpillOffset := Offset;
  Allocation.Locations[ValueId].Kind := vlStack;
  Allocation.Locations[ValueId].StackOffset := Offset;
end;

procedure AddActive(var Active: TInt32Array; ValueId: Int32;
  const Intervals: array of TLiveInterval);
begin
  SetLength(Active, Length(Active) + 1);
  Active[High(Active)] := ValueId;
  SortActiveByEnd(Intervals, Active);
end;

procedure ReplaceActive(var Active: TInt32Array; OldValue, NewValue: Int32;
  const Intervals: array of TLiveInterval);
var
  I: Integer;
begin
  for I := 0 to High(Active) do
    if Active[I] = OldValue then
    begin
      Active[I] := NewValue;
      SortActiveByEnd(Intervals, Active);
      Exit;
    end;
end;

procedure AllocateFunction(const ProgramIR: TIRProgram; FunctionId: Int32;
  var Allocation: TRegisterAllocation);
var
  ValueIds, Active: TInt32Array;
  I, ValueId, SpillCandidate: Integer;
  FreeMask: UInt32;
  RegisterId: TX64Register;
  FunctionAllocation: ^TFunctionAllocation;
begin
  SetLength(ValueIds, 0);
  for I := 0 to High(Allocation.Intervals) do
    if Allocation.Intervals[I].FunctionId = FunctionId then
    begin
      SetLength(ValueIds, Length(ValueIds) + 1);
      ValueIds[High(ValueIds)] := I;
    end;
  SortValueIdsByStart(Allocation.Intervals, ValueIds);
  SetLength(Active, 0);
  FreeMask := 0;
  for I := 0 to High(ALLOCATABLE_GPRS) do
    FreeMask := FreeMask or RegisterBit(ALLOCATABLE_GPRS[I]);
  FunctionAllocation := @Allocation.Functions[FunctionId];
  FunctionAllocation^.FunctionId := FunctionId;
  for I := 0 to High(ValueIds) do
  begin
    ValueId := ValueIds[I];
    if Allocation.Locations[ValueId].Kind = vlImmediate then
      Continue;
    ExpireOldIntervals(Allocation, ValueId, Active, FreeMask);
    RegisterId := TakeFreeRegister(FreeMask);
    if RegisterId <> xrNone then
    begin
      AssignRegister(Allocation, ValueId, RegisterId, FunctionAllocation^);
      AddActive(Active, ValueId, Allocation.Intervals);
      Continue;
    end;
    if Length(Active) = 0 then
    begin
      SpillValue(Allocation, ValueId, FunctionAllocation^);
      Continue;
    end;
    SpillCandidate := Active[High(Active)];
    if Allocation.Intervals[SpillCandidate].EndPosition >
       Allocation.Intervals[ValueId].EndPosition then
    begin
      RegisterId := Allocation.Intervals[SpillCandidate].AssignedRegister;
      SpillValue(Allocation, SpillCandidate, FunctionAllocation^);
      AssignRegister(Allocation, ValueId, RegisterId, FunctionAllocation^);
      ReplaceActive(Active, SpillCandidate, ValueId, Allocation.Intervals);
    end
    else
      SpillValue(Allocation, ValueId, FunctionAllocation^);
  end;
  FunctionAllocation^.FrameSize := AlignUp(FunctionAllocation^.SpillSize, 16);
  Allocation.Functions[FunctionId].FrameSize := FunctionAllocation^.FrameSize;
end;

procedure DetectCallCrossings(const ProgramIR: TIRProgram;
  var Allocation: TRegisterAllocation);
var
  I, J: Integer;
begin
  for I := 0 to High(ProgramIR.Instructions) do
    if not (iifRemoved in ProgramIR.Instructions[I].Flags) and
       (ProgramIR.Instructions[I].Op in [
        irCall, irCallIndirect, irCallVirtual, irCallNative,
        irCallForeign, irCallForeignIndirect,
        irPrintText, irPrintInteger, irPrintReal, irPrintFixed,
        irPrintCharacter, irPrintNewLine,
        irReadInteger, irReadReal, irReadCharacter, irReadText,
        irThreadSpawn, irThreadJoin, irThreadCancel, irThreadYield,
        irFutureAwait, irChannelSend, irChannelReceive,
        irMutexLock, irMutexUnlock, irCriticalBegin, irCriticalEnd,
        irProcessDetach, irProcessCall, irProcessResume, irProcessActivate,
        irProcessReactivate, irProcessDelay, irProcessHold,
        irProcessPassivate]) then
      for J := 0 to High(Allocation.Intervals) do
        if (Allocation.Intervals[J].FunctionId =
            ProgramIR.Instructions[I].FunctionId) and
           (Allocation.Intervals[J].StartPosition < I) and
           (Allocation.Intervals[J].EndPosition > I) then
          Allocation.Intervals[J].CrossesCall := True;
end;

procedure AllocateRegisters(var ProgramIR: TIRProgram;
  out Allocation: TRegisterAllocation);
var
  F: Integer;
begin
  Allocation := Default(TRegisterAllocation);
  IRComputeUseLists(ProgramIR);
  BuildIntervals(ProgramIR, Allocation);
  SetLength(Allocation.Functions, Length(ProgramIR.Functions));
  DetectCallCrossings(ProgramIR, Allocation);
  for F := 0 to High(ProgramIR.Functions) do
  begin
    AllocateFunction(ProgramIR, F, Allocation);
    ProgramIR.Functions[F].SpillStackSize := Allocation.Functions[F].SpillSize;
    ProgramIR.Functions[F].LocalStackSize := Allocation.Functions[F].FrameSize;
    if Allocation.Functions[F].FrameSize <> 0 then
      Include(ProgramIR.Functions[F].Flags, iffNeedsFrame);
  end;
end;

procedure DumpRegisterAllocation(const ProgramIR: TIRProgram;
  const Allocation: TRegisterAllocation);
var
  F, I: Integer;
begin
  for F := 0 to High(ProgramIR.Functions) do
  begin
    Writeln('allocation function #', F, ' frame=',
      Allocation.Functions[F].FrameSize, ' spill=',
      Allocation.Functions[F].SpillSize, ' spills=',
      Allocation.Functions[F].SpillCount);
    for I := 0 to High(Allocation.Intervals) do
      if Allocation.Intervals[I].FunctionId = F then
        Writeln('  %', I, ' [', Allocation.Intervals[I].StartPosition, ',',
          Allocation.Intervals[I].EndPosition, '] -> ',
          LocationText(Allocation.Locations[I]));
  end;
end;

end.

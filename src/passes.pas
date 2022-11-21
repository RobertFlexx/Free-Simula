unit passes;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, core, symbols, ir;

type
  TAdvancedOptimizationStats = packed record
    Iterations: UInt32;
    StrengthReductions: UInt32;
    DoubleNegationsRemoved: UInt32;
    LoadsForwarded: UInt32;
    StoresRemoved: UInt32;
    BranchesThreaded: UInt32;
    TailCallsDiscovered: UInt32;
    FunctionPropertiesUpdated: UInt32;
  end;

procedure RunAdvancedOptimizations(var ProgramIR: TIRProgram;
  const Symbols: TSymbolTable; Level: TOptLevel;
  out Stats: TAdvancedOptimizationStats);

implementation

const
  MAX_OPTIMIZATION_ITERATIONS = 8;

type
  TSymbolValueState = packed record
    Known: Boolean;
    ValueId: Int32;
    StoreInstruction: Int32;
  end;

function InstructionRemoved(const Inst: TIRInstruction): Boolean; inline;
begin
  Result := iifRemoved in Inst.Flags;
end;

function ValidValue(const ProgramIR: TIRProgram; ValueId: Int32): Boolean; inline;
begin
  Result := (ValueId >= 0) and (ValueId <= High(ProgramIR.Values));
end;

function ValidInstruction(const ProgramIR: TIRProgram;
  InstructionId: Int32): Boolean; inline;
begin
  Result := (InstructionId >= 0) and
    (InstructionId <= High(ProgramIR.Instructions));
end;

function ValidBlock(const ProgramIR: TIRProgram; BlockId: Int32): Boolean; inline;
begin
  Result := (BlockId >= 0) and (BlockId <= High(ProgramIR.Blocks));
end;

function ValidSymbol(const Symbols: TSymbolTable; SymbolId: Int32): Boolean; inline;
begin
  Result := (SymbolId >= 0) and (SymbolId <= High(Symbols.Symbols));
end;

function DefinitionInstruction(const ProgramIR: TIRProgram;
  ValueId: Int32): Int32; inline;
begin
  if ValidValue(ProgramIR, ValueId) then
    Result := ProgramIR.Values[ValueId].DefInstruction
  else
    Result := IR_INVALID_VALUE;
end;

function ConstantInteger(const ProgramIR: TIRProgram; ValueId: Int32;
  out Value: Int64): Boolean;
var
  Definition: Int32;
begin
  Result := False;
  Definition := DefinitionInstruction(ProgramIR, ValueId);
  if not ValidInstruction(ProgramIR, Definition) then Exit;
  if InstructionRemoved(ProgramIR.Instructions[Definition]) then Exit;
  if ProgramIR.Instructions[Definition].Op <> irConstInt then Exit;
  Value := ProgramIR.Instructions[Definition].Imm;
  Result := True;
end;

function IsPowerOfTwo(Value: Int64; out Shift: Int32): Boolean;
var
  Bits: QWord;
begin
  Result := False;
  Shift := 0;
  if Value <= 0 then Exit;
  Bits := QWord(Value);
  if (Bits and (Bits - 1)) <> 0 then Exit;
  while Bits > 1 do
  begin
    Bits := Bits shr 1;
    Inc(Shift);
  end;
  Result := True;
end;

procedure ClearDestinationMetadata(var ProgramIR: TIRProgram;
  InstructionId: Int32);
var
  Destination: Int32;
begin
  if not ValidInstruction(ProgramIR, InstructionId) then Exit;
  Destination := ProgramIR.Instructions[InstructionId].Dst;
  if ValidValue(ProgramIR, Destination) then
  begin
    ProgramIR.Values[Destination].ConstantKnown := False;
    ProgramIR.Values[Destination].ConstantInt := 0;
    ProgramIR.Values[Destination].ConstantReal := 0.0;
  end;
end;

procedure RewriteAsMove(var ProgramIR: TIRProgram; InstructionId,
  SourceValue: Int32);
var
  Inst: ^TIRInstruction;
begin
  if not ValidInstruction(ProgramIR, InstructionId) then Exit;
  Inst := @ProgramIR.Instructions[InstructionId];
  Inst^.Op := irMove;
  Inst^.A := SourceValue;
  Inst^.B := IR_INVALID_VALUE;
  Inst^.C := IR_INVALID_VALUE;
  Inst^.SymbolId := FSIM_INVALID_INDEX;
  Inst^.TargetBlock := IR_INVALID_BLOCK;
  Inst^.AlternateBlock := IR_INVALID_BLOCK;
  Inst^.Aux := 0;
  Inst^.StringId := FSIM_INVALID_INDEX;
  Inst^.Imm := 0;
  Inst^.RealImm := 0.0;
  Exclude(Inst^.Flags, iifSideEffect);
  Exclude(Inst^.Flags, iifMayTrap);
  Exclude(Inst^.Flags, iifTerminator);
  ClearDestinationMetadata(ProgramIR, InstructionId);
end;

procedure RewriteAsIntegerConstant(var ProgramIR: TIRProgram;
  InstructionId: Int32; Value: Int64);
var
  Inst: ^TIRInstruction;
  Destination: Int32;
begin
  if not ValidInstruction(ProgramIR, InstructionId) then Exit;
  Inst := @ProgramIR.Instructions[InstructionId];
  Destination := Inst^.Dst;
  Inst^.Op := irConstInt;
  Inst^.A := IR_INVALID_VALUE;
  Inst^.B := IR_INVALID_VALUE;
  Inst^.C := IR_INVALID_VALUE;
  Inst^.SymbolId := FSIM_INVALID_INDEX;
  Inst^.TargetBlock := IR_INVALID_BLOCK;
  Inst^.AlternateBlock := IR_INVALID_BLOCK;
  Inst^.Aux := 0;
  Inst^.StringId := FSIM_INVALID_INDEX;
  Inst^.Imm := Value;
  Inst^.RealImm := 0.0;
  Exclude(Inst^.Flags, iifSideEffect);
  Exclude(Inst^.Flags, iifMayTrap);
  Exclude(Inst^.Flags, iifTerminator);
  if ValidValue(ProgramIR, Destination) then
  begin
    ProgramIR.Values[Destination].ConstantKnown := True;
    ProgramIR.Values[Destination].ConstantInt := Value;
    ProgramIR.Values[Destination].ConstantReal := 0.0;
  end;
end;

procedure RemoveInstruction(var ProgramIR: TIRProgram; InstructionId: Int32);
begin
  if not ValidInstruction(ProgramIR, InstructionId) then Exit;
  Include(ProgramIR.Instructions[InstructionId].Flags, iifRemoved);
  ClearDestinationMetadata(ProgramIR, InstructionId);
end;

function IsLocalWritableSymbol(const Symbols: TSymbolTable;
  SymbolId: Int32): Boolean;
var
  TypeId: Int32;
begin
  Result := False;
  if not ValidSymbol(Symbols, SymbolId) then Exit;
  if not (Symbols.Symbols[SymbolId].Kind in [skVariable, skParameter]) then
    Exit;
  if sfAddressTaken in Symbols.Symbols[SymbolId].Flags then
    Exit;
  TypeId := Symbols.Symbols[SymbolId].TypeId;
  if (TypeId >= 0) and (TypeId <= High(Symbols.Types)) then
  begin
    if Symbols.Types[TypeId].Kind in [tyArray, tyRecord, tyProcedure, tyCFunction] then
      Exit;
    { Keep forwarding deliberately scalar. Procedure values are also excluded:
      even though a code pointer is one machine word, forwarding it across the
      lowered call/result boundary used to make first-class return values depend
      on optimizer lifetime accidents. }
    { Managed/reference values can carry
      runtime ownership or mutable state behind an otherwise innocent-looking
      symbol load, so treating them as SSA locals is too optimistic. }
    if (tfManaged in Symbols.Types[TypeId].Flags) or
       (tfReferenceType in Symbols.Types[TypeId].Flags) then
      Exit;
  end;
  Result := True;
end;

function IsMemoryBarrierOperation(Op: TIROpcode): Boolean;
begin
  case Op of
    irCall, irCallIndirect, irCallVirtual, irCallNative, irCallForeign, irCallForeignIndirect,
    irStoreField, irStoreElement, irStoreIndirect, irStoreForeignData,
    irTryBegin, irTryEnd, irCatchBegin, irCatchEnd,
    irFinallyBegin, irFinallyEnd, irRaise,
    irThreadSpawn, irThreadJoin, irThreadCancel,
    irFutureAwait, irChannelSend, irChannelReceive,
    irMutexLock, irMutexUnlock, irMemoryFence,
    irProcessDetach, irProcessResume, irProcessActivate,
    irProcessReactivate, irProcessDelay, irProcessHold,
    irProcessPassivate:
      Result := True;
  else
    Result := False;
  end;
end;

procedure ClearSymbolStates(var States: array of TSymbolValueState);
var
  Index: Int32;
begin
  for Index := 0 to High(States) do
  begin
    States[Index].Known := False;
    States[Index].ValueId := IR_INVALID_VALUE;
    States[Index].StoreInstruction := IR_INVALID_VALUE;
  end;
end;

procedure InvalidateSymbolState(var States: array of TSymbolValueState;
  SymbolId: Int32);
begin
  if (SymbolId < 0) or (SymbolId > High(States)) then Exit;
  States[SymbolId].Known := False;
  States[SymbolId].ValueId := IR_INVALID_VALUE;
  States[SymbolId].StoreInstruction := IR_INVALID_VALUE;
end;

procedure ForwardLocalLoadsAndRemoveDeadStores(var ProgramIR: TIRProgram;
  const Symbols: TSymbolTable; var Stats: TAdvancedOptimizationStats;
  out Changed: Boolean);
var
  States: array of TSymbolValueState;
  BlockId, InstructionId, SymbolId, PreviousStore: Int32;
  Inst: ^TIRInstruction;
begin
  if Length(Symbols.Symbols) = 0 then Exit;
  SetLength(States, Length(Symbols.Symbols));
  for BlockId := 0 to High(ProgramIR.Blocks) do
  begin
    ClearSymbolStates(States);
    if (ProgramIR.Blocks[BlockId].FirstInstruction < 0) or
       (ProgramIR.Blocks[BlockId].LastInstruction < 0) then Continue;
    for InstructionId := ProgramIR.Blocks[BlockId].FirstInstruction to
      ProgramIR.Blocks[BlockId].LastInstruction do
    begin
      if not ValidInstruction(ProgramIR, InstructionId) then Break;
      Inst := @ProgramIR.Instructions[InstructionId];
      if InstructionRemoved(Inst^) then Continue;
      if Inst^.BlockId <> BlockId then Continue;
      if IsMemoryBarrierOperation(Inst^.Op) or
         (iifVolatile in Inst^.Flags) then
      begin
        ClearSymbolStates(States);
        Continue;
      end;
      case Inst^.Op of
        irLoadSymbol:
          begin
            SymbolId := Inst^.SymbolId;
            if IsLocalWritableSymbol(Symbols, SymbolId) and
               (SymbolId <= High(States)) and States[SymbolId].Known and
               ValidValue(ProgramIR, States[SymbolId].ValueId) then
            begin
              RewriteAsMove(ProgramIR, InstructionId,
                States[SymbolId].ValueId);
              Inc(Stats.LoadsForwarded);
              Changed := True;
            end;
            if (SymbolId >= 0) and (SymbolId <= High(States)) then
              States[SymbolId].StoreInstruction := IR_INVALID_VALUE;
          end;
        irStoreSymbol:
          begin
            SymbolId := Inst^.SymbolId;
            if not IsLocalWritableSymbol(Symbols, SymbolId) then
            begin
              InvalidateSymbolState(States, SymbolId);
              Continue;
            end;
            PreviousStore := States[SymbolId].StoreInstruction;
            if ValidInstruction(ProgramIR, PreviousStore) and
               not InstructionRemoved(ProgramIR.Instructions[PreviousStore]) then
            begin
              RemoveInstruction(ProgramIR, PreviousStore);
              Inc(Stats.StoresRemoved);
              Changed := True;
            end;
            States[SymbolId].Known := ValidValue(ProgramIR, Inst^.A);
            States[SymbolId].ValueId := Inst^.A;
            States[SymbolId].StoreInstruction := InstructionId;
          end;
        irAddressOf:
          InvalidateSymbolState(States, Inst^.SymbolId);
      end;
    end;
  end;
  SetLength(States, 0);
end;

procedure ReduceIntegerStrength(var ProgramIR: TIRProgram;
  Aggressive: Boolean; var Stats: TAdvancedOptimizationStats;
  out Changed: Boolean);
var
  InstructionId, Shift: Int32;
  RightValue: Int64;
  Inst: ^TIRInstruction;
begin
  for InstructionId := 0 to High(ProgramIR.Instructions) do
  begin
    Inst := @ProgramIR.Instructions[InstructionId];
    if InstructionRemoved(Inst^) then Continue;
    if not (Inst^.Op in [irMulInt, irDivInt]) then Continue;
    if not ConstantInteger(ProgramIR, Inst^.B, RightValue) then Continue;
    if Inst^.Op = irDivInt then
    begin
      { signed division truncates toward zero. an arithmetic right shift does
        not do that for negative dividends, so the old -Ofast rewrite was
        just wrong. only the identity case is safe without range analysis. }
      if RightValue = 1 then
      begin
        RewriteAsMove(ProgramIR, InstructionId, Inst^.A);
        Inc(Stats.StrengthReductions);
        Changed := True;
      end;
      Continue;
    end;
    if not IsPowerOfTwo(RightValue, Shift) then Continue;
    if Shift = 0 then
      RewriteAsMove(ProgramIR, InstructionId, Inst^.A)
    else
    begin
      Inst^.Op := irShiftLeft;
      Inst^.B := IR_INVALID_VALUE;
      Inst^.Aux := Shift;
    end;
    Inc(Stats.StrengthReductions);
    Changed := True;
  end;
end;

procedure SimplifySelfComparisons(var ProgramIR: TIRProgram;
  var Stats: TAdvancedOptimizationStats; out Changed: Boolean);
var
  InstructionId, TypeId: Int32;
  Value: Int64;
  Inst: ^TIRInstruction;
begin
  for InstructionId := 0 to High(ProgramIR.Instructions) do
  begin
    Inst := @ProgramIR.Instructions[InstructionId];
    if InstructionRemoved(Inst^) or (Inst^.A <> Inst^.B) or
       not ValidValue(ProgramIR, Inst^.A) then Continue;
    TypeId := ProgramIR.Values[Inst^.A].TypeId;
    if TypeId = FSIM_TYPE_REAL then Continue;
    case Inst^.Op of
      irCompareEqual, irCompareLessEqual, irCompareGreaterEqual:
        Value := 1;
      irCompareNotEqual, irCompareLess, irCompareGreater:
        Value := 0;
    else
      Continue;
    end;
    RewriteAsIntegerConstant(ProgramIR, InstructionId, Value);
    Inc(Stats.StrengthReductions);
    Changed := True;
  end;
end;

procedure EliminateDoubleNegations(var ProgramIR: TIRProgram;
  var Stats: TAdvancedOptimizationStats; out Changed: Boolean);
var
  InstructionId, Definition: Int32;
  Inst, DefInst: ^TIRInstruction;
begin
  for InstructionId := 0 to High(ProgramIR.Instructions) do
  begin
    Inst := @ProgramIR.Instructions[InstructionId];
    if InstructionRemoved(Inst^) or
       not (Inst^.Op in [irNegInt, irNegReal, irLogicalNot]) then Continue;
    Definition := DefinitionInstruction(ProgramIR, Inst^.A);
    if not ValidInstruction(ProgramIR, Definition) then Continue;
    DefInst := @ProgramIR.Instructions[Definition];
    if InstructionRemoved(DefInst^) or (DefInst^.Op <> Inst^.Op) then Continue;
    RewriteAsMove(ProgramIR, InstructionId, DefInst^.A);
    Inc(Stats.DoubleNegationsRemoved);
    Changed := True;
  end;
end;

function SoleActiveBranch(const ProgramIR: TIRProgram; BlockId: Int32;
  out Destination: Int32): Boolean;
var
  InstructionId, ActiveCount: Int32;
  Inst: TIRInstruction;
begin
  Result := False;
  Destination := IR_INVALID_BLOCK;
  if not ValidBlock(ProgramIR, BlockId) then Exit;
  if ibfEntry in ProgramIR.Blocks[BlockId].Flags then Exit;
  if ibfExceptionHandler in ProgramIR.Blocks[BlockId].Flags then Exit;
  ActiveCount := 0;
  for InstructionId := ProgramIR.Blocks[BlockId].FirstInstruction to
    ProgramIR.Blocks[BlockId].LastInstruction do
  begin
    if not ValidInstruction(ProgramIR, InstructionId) then Break;
    Inst := ProgramIR.Instructions[InstructionId];
    if InstructionRemoved(Inst) or (Inst.BlockId <> BlockId) then Continue;
    if Inst.Op = irNop then Continue;
    Inc(ActiveCount);
    if (ActiveCount <> 1) or (Inst.Op <> irBranch) then Exit(False);
    Destination := Inst.TargetBlock;
  end;
  Result := (ActiveCount = 1) and ValidBlock(ProgramIR, Destination) and
    (Destination <> BlockId);
end;

function ThreadedTarget(const ProgramIR: TIRProgram; InitialTarget: Int32): Int32;
var
  Current, Next, Guard: Int32;
begin
  Current := InitialTarget;
  Guard := 0;
  while ValidBlock(ProgramIR, Current) and
        SoleActiveBranch(ProgramIR, Current, Next) do
  begin
    if Next = InitialTarget then Break;
    Current := Next;
    Inc(Guard);
    if Guard > Length(ProgramIR.Blocks) then Break;
  end;
  Result := Current;
end;

procedure ThreadBranches(var ProgramIR: TIRProgram;
  var Stats: TAdvancedOptimizationStats; out Changed: Boolean);
var
  InstructionId, NewTarget: Int32;
  Inst: ^TIRInstruction;
begin
  for InstructionId := 0 to High(ProgramIR.Instructions) do
  begin
    Inst := @ProgramIR.Instructions[InstructionId];
    if InstructionRemoved(Inst^) then Continue;
    case Inst^.Op of
      irBranch:
        begin
          NewTarget := ThreadedTarget(ProgramIR, Inst^.TargetBlock);
          if NewTarget <> Inst^.TargetBlock then
          begin
            Inst^.TargetBlock := NewTarget;
            Inc(Stats.BranchesThreaded);
            Changed := True;
          end;
        end;
      irBranchCond:
        begin
          NewTarget := ThreadedTarget(ProgramIR, Inst^.TargetBlock);
          if NewTarget <> Inst^.TargetBlock then
          begin
            Inst^.TargetBlock := NewTarget;
            Inc(Stats.BranchesThreaded);
            Changed := True;
          end;
          NewTarget := ThreadedTarget(ProgramIR, Inst^.AlternateBlock);
          if NewTarget <> Inst^.AlternateBlock then
          begin
            Inst^.AlternateBlock := NewTarget;
            Inc(Stats.BranchesThreaded);
            Changed := True;
          end;
        end;
    end;
  end;
  if Changed then IRBuildEdges(ProgramIR);
end;

function PreviousActiveInstruction(const ProgramIR: TIRProgram;
  InstructionId, BlockId: Int32): Int32;
begin
  Result := InstructionId - 1;
  while ValidInstruction(ProgramIR, Result) and
        (Result >= ProgramIR.Blocks[BlockId].FirstInstruction) do
  begin
    if (ProgramIR.Instructions[Result].BlockId = BlockId) and
       not InstructionRemoved(ProgramIR.Instructions[Result]) and
       (ProgramIR.Instructions[Result].Op <> irNop) then Exit;
    Dec(Result);
  end;
  Result := IR_INVALID_VALUE;
end;

procedure DiscoverTailCalls(var ProgramIR: TIRProgram;
  var Stats: TAdvancedOptimizationStats);
var
  InstructionId, Previous: Int32;
  ReturnInst, CallInst: ^TIRInstruction;
begin
  for InstructionId := 0 to High(ProgramIR.Instructions) do
  begin
    ReturnInst := @ProgramIR.Instructions[InstructionId];
    if InstructionRemoved(ReturnInst^) or (ReturnInst^.Op <> irReturn) or
       not ValidBlock(ProgramIR, ReturnInst^.BlockId) then Continue;
    Previous := PreviousActiveInstruction(ProgramIR, InstructionId,
      ReturnInst^.BlockId);
    if not ValidInstruction(ProgramIR, Previous) then Continue;
    CallInst := @ProgramIR.Instructions[Previous];
    if not (CallInst^.Op in [irCall, irCallIndirect, irCallVirtual, irCallNative, irCallForeign, irCallForeignIndirect]) then Continue;
    if (ReturnInst^.A >= 0) and (ReturnInst^.A <> CallInst^.Dst) then Continue;
    if not (iifTailCall in CallInst^.Flags) then
    begin
      Include(CallInst^.Flags, iifTailCall);
      Inc(Stats.TailCallsDiscovered);
    end;
  end;
end;

procedure InferFunctionProperties(var ProgramIR: TIRProgram;
  var Stats: TAdvancedOptimizationStats);
var
  FunctionId, InstructionId: Int32;
  HasCalls, NeedsFrame, HasExceptions, IsLeaf: Boolean;
  Inst: TIRInstruction;
begin
  for FunctionId := 0 to High(ProgramIR.Functions) do
  begin
    HasCalls := False;
    NeedsFrame := ProgramIR.Functions[FunctionId].LocalStackSize <> 0;
    HasExceptions := False;
    for InstructionId := 0 to High(ProgramIR.Instructions) do
    begin
      Inst := ProgramIR.Instructions[InstructionId];
      if InstructionRemoved(Inst) or (Inst.FunctionId <> FunctionId) then
        Continue;
      case Inst.Op of
        irCall, irCallIndirect, irCallVirtual, irCallNative, irCallForeign, irCallForeignIndirect, irThreadSpawn:
          HasCalls := True;
        irTryBegin, irTryEnd, irCatchBegin, irCatchEnd,
        irFinallyBegin, irFinallyEnd, irRaise:
          HasExceptions := True;
        irAllocObject, irAllocArray, irAllocHandle, irParameter:
          NeedsFrame := True;
      end;
    end;
    IsLeaf := not HasCalls;
    Exclude(ProgramIR.Functions[FunctionId].Flags, iffLeaf);
    Exclude(ProgramIR.Functions[FunctionId].Flags, iffHasCalls);
    Exclude(ProgramIR.Functions[FunctionId].Flags, iffHasExceptions);
    Exclude(ProgramIR.Functions[FunctionId].Flags, iffNeedsFrame);
    if IsLeaf then Include(ProgramIR.Functions[FunctionId].Flags, iffLeaf);
    if HasCalls then Include(ProgramIR.Functions[FunctionId].Flags, iffHasCalls);
    if HasExceptions then
      Include(ProgramIR.Functions[FunctionId].Flags, iffHasExceptions);
    if NeedsFrame then
      Include(ProgramIR.Functions[FunctionId].Flags, iffNeedsFrame);
    Inc(Stats.FunctionPropertiesUpdated);
  end;
end;

procedure RunAdvancedOptimizations(var ProgramIR: TIRProgram;
  const Symbols: TSymbolTable; Level: TOptLevel;
  out Stats: TAdvancedOptimizationStats);
var
  Iteration: Int32;
  Changed: Boolean;
  Aggressive: Boolean;
begin
  Stats := Default(TAdvancedOptimizationStats);
  if Level = ol0 then
  begin
    InferFunctionProperties(ProgramIR, Stats);
    Exit;
  end;
  Aggressive := Level = olFast;
  for Iteration := 1 to MAX_OPTIMIZATION_ITERATIONS do
  begin
    Changed := False;
    ReduceIntegerStrength(ProgramIR, Aggressive, Stats, Changed);
    SimplifySelfComparisons(ProgramIR, Stats, Changed);
    EliminateDoubleNegations(ProgramIR, Stats, Changed);
    ForwardLocalLoadsAndRemoveDeadStores(ProgramIR, Symbols, Stats, Changed);
    if Level in [ol2, ol3, olFast] then
      ThreadBranches(ProgramIR, Stats, Changed);
    Inc(Stats.Iterations);
    IRComputeUseLists(ProgramIR);
    if not Changed then Break;
  end;
  DiscoverTailCalls(ProgramIR, Stats);
  InferFunctionProperties(ProgramIR, Stats);
  IRBuildEdges(ProgramIR);
  IRComputeUseLists(ProgramIR);
end;

end.

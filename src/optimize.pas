unit optimize;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, core, diagnostics, symbols, ir,
  fold, flow, passes;

type
  TOptimizationStats = packed record
    PassesRun: UInt32;
    ConstantsFolded: UInt32;
    AlgebraicRewrites: UInt32;
    CopiesPropagated: UInt32;
    InstructionsRemoved: UInt32;
    BranchesFolded: UInt32;
    BlocksRemoved: UInt32;
    CommonExpressionsEliminated: UInt32;
    LoopInvariantsSimplified: UInt32;
    CanonicalRewrites: UInt32;
    DataFlowFunctions: UInt32;
    NaturalLoops: UInt32;
    AdvancedIterations: UInt32;
    StrengthReductions: UInt32;
    DoubleNegationsRemoved: UInt32;
    LoadsForwarded: UInt32;
    StoresRemovedAdvanced: UInt32;
    BranchesThreaded: UInt32;
    TailCallsDiscovered: UInt32;
  end;

procedure OptimizeProgram(var ProgramIR: TIRProgram;
  const Symbols: TSymbolTable; const Options: TCompilerOptions;
  var Diagnostics: TDiagnosticBag; out Stats: TOptimizationStats);

implementation

type
  TValueStateKind = (vskUnknown, vskOverdefined, vskInt, vskReal, vskNull,
    vskString);
  TValueState = packed record
    Kind: TValueStateKind;
    IntValue: Int64;
    RealValue: Double;
    StringId: Int32;
  end;

function IsRemoved(const Inst: TIRInstruction): Boolean; inline;
begin
  Result := iifRemoved in Inst.Flags;
end;

procedure RemoveInstruction(var Inst: TIRInstruction;
  var Stats: TOptimizationStats);
begin
  if not IsRemoved(Inst) then
  begin
    Include(Inst.Flags, iifRemoved);
    Inc(Stats.InstructionsRemoved);
  end;
end;

procedure RewriteAsMove(var Inst: TIRInstruction; Source: Int32);
begin
  Inst.Op := irMove;
  Inst.A := Source;
  Inst.B := IR_INVALID_VALUE;
  Inst.C := IR_INVALID_VALUE;
  Inst.SymbolId := FSIM_INVALID_INDEX;
  Inst.TargetBlock := IR_INVALID_BLOCK;
  Inst.AlternateBlock := IR_INVALID_BLOCK;
  Inst.Aux := 0;
  Inst.StringId := FSIM_INVALID_INDEX;
  Inst.Imm := 0;
  Inst.RealImm := 0.0;
  Inst.Flags := Inst.Flags - [iifSideEffect, iifMayTrap, iifTerminator];
end;

procedure RewriteAsConstInt(var Inst: TIRInstruction; Value: Int64);
begin
  Inst.Op := irConstInt;
  Inst.A := IR_INVALID_VALUE;
  Inst.B := IR_INVALID_VALUE;
  Inst.C := IR_INVALID_VALUE;
  Inst.SymbolId := FSIM_INVALID_INDEX;
  Inst.TargetBlock := IR_INVALID_BLOCK;
  Inst.AlternateBlock := IR_INVALID_BLOCK;
  Inst.Aux := 0;
  Inst.StringId := FSIM_INVALID_INDEX;
  Inst.Imm := Value;
  Inst.RealImm := 0.0;
  Inst.Flags := Inst.Flags - [iifSideEffect, iifMayTrap, iifTerminator];
end;

procedure RewriteAsConstReal(var Inst: TIRInstruction; Value: Double);
begin
  Inst.Op := irConstReal;
  Inst.A := IR_INVALID_VALUE;
  Inst.B := IR_INVALID_VALUE;
  Inst.C := IR_INVALID_VALUE;
  Inst.SymbolId := FSIM_INVALID_INDEX;
  Inst.TargetBlock := IR_INVALID_BLOCK;
  Inst.AlternateBlock := IR_INVALID_BLOCK;
  Inst.Aux := 0;
  Inst.StringId := FSIM_INVALID_INDEX;
  Inst.Imm := 0;
  Inst.RealImm := Value;
  Inst.Flags := Inst.Flags - [iifSideEffect, iifMayTrap, iifTerminator];
end;

function ResolveMove(const ProgramIR: TIRProgram; ValueId: Int32): Int32;
var
  Guard, Def: Integer;
begin
  Result := ValueId;
  Guard := 0;
  while (Result >= 0) and (Result <= High(ProgramIR.Values)) do
  begin
    Def := ProgramIR.Values[Result].DefInstruction;
    if (Def < 0) or (Def > High(ProgramIR.Instructions)) then Break;
    if IsRemoved(ProgramIR.Instructions[Def]) or
       (ProgramIR.Instructions[Def].Op <> irMove) then Break;
    if ProgramIR.Instructions[Def].A = Result then Break;
    { A move can be representation-preserving while still being type-bearing.
      C-real casts are the important example: c_double(1.5) uses the same bits
      as an fsim real, but the target type controls SysV variadic classification.
      Copy propagation must not erase that nominal/ABI tag. }
    if (ProgramIR.Instructions[Def].A < 0) or
       (ProgramIR.Instructions[Def].A > High(ProgramIR.Values)) or
       (ProgramIR.Values[Result].TypeId <>
        ProgramIR.Values[ProgramIR.Instructions[Def].A].TypeId) then Break;
    Result := ProgramIR.Instructions[Def].A;
    Inc(Guard);
    if Guard > Length(ProgramIR.Values) then Break;
  end;
end;

procedure CopyPropagation(var ProgramIR: TIRProgram;
  var Stats: TOptimizationStats);
var
  I, OldValue, NewValue: Integer;
begin
  IRComputeUseLists(ProgramIR);
  for I := 0 to High(ProgramIR.Instructions) do
    if not IsRemoved(ProgramIR.Instructions[I]) then
    begin
      OldValue := ProgramIR.Instructions[I].A;
      NewValue := ResolveMove(ProgramIR, OldValue);
      if NewValue <> OldValue then
      begin
        ProgramIR.Instructions[I].A := NewValue;
        Inc(Stats.CopiesPropagated);
      end;
      OldValue := ProgramIR.Instructions[I].B;
      NewValue := ResolveMove(ProgramIR, OldValue);
      if NewValue <> OldValue then
      begin
        ProgramIR.Instructions[I].B := NewValue;
        Inc(Stats.CopiesPropagated);
      end;
      OldValue := ProgramIR.Instructions[I].C;
      NewValue := ResolveMove(ProgramIR, OldValue);
      if NewValue <> OldValue then
      begin
        ProgramIR.Instructions[I].C := NewValue;
        Inc(Stats.CopiesPropagated);
      end;
    end;
  IRComputeUseLists(ProgramIR);
end;

procedure BuildValueStates(const ProgramIR: TIRProgram;
  out States: array of TValueState);
var
  I, D: Integer;
  Inst: TIRInstruction;
begin
  for I := 0 to High(States) do
  begin
    States[I].Kind := vskUnknown;
    States[I].StringId := FSIM_INVALID_INDEX;
  end;
  for I := 0 to High(ProgramIR.Values) do
  begin
    D := ProgramIR.Values[I].DefInstruction;
    if (D < 0) or (D > High(ProgramIR.Instructions)) then Continue;
    Inst := ProgramIR.Instructions[D];
    if IsRemoved(Inst) then Continue;
    case Inst.Op of
      irConstInt:
        begin
          States[I].Kind := vskInt;
          States[I].IntValue := Inst.Imm;
        end;
      irConstReal:
        begin
          States[I].Kind := vskReal;
          States[I].RealValue := Inst.RealImm;
        end;
      irConstNull: States[I].Kind := vskNull;
      irConstString:
        begin
          States[I].Kind := vskString;
          States[I].StringId := Inst.StringId;
        end;
    else
      States[I].Kind := vskOverdefined;
    end;
  end;
end;

function SafeAdd(A, B: Int64; out Value: Int64): Boolean;
begin
  {$push}{$Q+}
  try
    Value := A + B;
    Result := True;
  except
    on E: EIntOverflow do Result := False;
  end;
  {$pop}
end;

function SafeSub(A, B: Int64; out Value: Int64): Boolean;
begin
  {$push}{$Q+}
  try
    Value := A - B;
    Result := True;
  except
    on E: EIntOverflow do Result := False;
  end;
  {$pop}
end;

function SafeMul(A, B: Int64; out Value: Int64): Boolean;
begin
  {$push}{$Q+}
  try
    Value := A * B;
    Result := True;
  except
    on E: EIntOverflow do Result := False;
  end;
  {$pop}
end;

function IntegerPower(Base, Exponent: Int64; out Value: Int64): Boolean;
var
  Acc, Factor, Temp: Int64;
begin
  if Exponent < 0 then Exit(False);
  Acc := 1;
  Factor := Base;
  while Exponent > 0 do
  begin
    if (Exponent and 1) <> 0 then
    begin
      if not SafeMul(Acc, Factor, Temp) then Exit(False);
      Acc := Temp;
    end;
    Exponent := Exponent shr 1;
    if Exponent <> 0 then
    begin
      if not SafeMul(Factor, Factor, Temp) then Exit(False);
      Factor := Temp;
    end;
  end;
  Value := Acc;
  Result := True;
end;

function FoldIntegerInstruction(var Inst: TIRInstruction;
  const Left, Right: TValueState; const Options: TCompilerOptions;
  var Diagnostics: TDiagnosticBag): Boolean;
var
  Value: Int64;
  Shift: Byte;
  CanFold: Boolean;
begin
  Result := False;
  CanFold := True;
  Value := 0;
  case Inst.Op of
    irAddInt: CanFold := SafeAdd(Left.IntValue, Right.IntValue, Value);
    irSubInt: CanFold := SafeSub(Left.IntValue, Right.IntValue, Value);
    irMulInt: CanFold := SafeMul(Left.IntValue, Right.IntValue, Value);
    irDivInt:
      begin
        if Right.IntValue = 0 then
        begin
          AddError(Diagnostics, dcDivisionByZero, Inst.Span,
            'division by zero in constant expression');
          Exit(False);
        end;
        if (Left.IntValue = Low(Int64)) and (Right.IntValue = -1) then
          CanFold := False
        else
          Value := Left.IntValue div Right.IntValue;
      end;
    irModInt:
      begin
        if Right.IntValue = 0 then
        begin
          AddError(Diagnostics, dcDivisionByZero, Inst.Span,
            'modulo by zero in constant expression');
          Exit(False);
        end;
        Value := Left.IntValue mod Right.IntValue;
        if (Value <> 0) and ((Value < 0) <> (Right.IntValue < 0)) then
          Value := Value + Right.IntValue;
      end;
    irRemInt:
      begin
        if Right.IntValue = 0 then
        begin
          AddError(Diagnostics, dcDivisionByZero, Inst.Span,
            'remainder by zero in constant expression');
          Exit(False);
        end;
        Value := Left.IntValue mod Right.IntValue;
      end;
    irPowerInt: CanFold := IntegerPower(Left.IntValue, Right.IntValue, Value);
    irShiftLeft:
      begin
        Shift := Byte(Right.IntValue and 63);
        Value := Int64(QWord(Left.IntValue) shl Shift);
      end;
    irShiftRight:
      begin
        Shift := Byte(Right.IntValue and 63);
        Value := Left.IntValue shr Shift;
      end;
    irBitAnd: Value := Left.IntValue and Right.IntValue;
    irBitOr: Value := Left.IntValue or Right.IntValue;
    irBitXor: Value := Left.IntValue xor Right.IntValue;
    irCompareEqual: Value := Ord(Left.IntValue = Right.IntValue);
    irCompareNotEqual: Value := Ord(Left.IntValue <> Right.IntValue);
    irCompareLess: Value := Ord(Left.IntValue < Right.IntValue);
    irCompareLessEqual: Value := Ord(Left.IntValue <= Right.IntValue);
    irCompareGreater: Value := Ord(Left.IntValue > Right.IntValue);
    irCompareGreaterEqual: Value := Ord(Left.IntValue >= Right.IntValue);
  else
    CanFold := False;
  end;
  if not CanFold and Options.OverflowChecks then
  begin
    AddWarning(Diagnostics, dcOverflow, Inst.Span,
      'constant expression overflows signed 64-bit integer');
    Exit(False);
  end;
  if CanFold then
  begin
    RewriteAsConstInt(Inst, Value);
    Result := True;
  end;
end;

function FoldRealInstruction(var Inst: TIRInstruction;
  const Left, Right: TValueState; var Diagnostics: TDiagnosticBag): Boolean;
var
  Value: Double;
begin
  Result := True;
  case Inst.Op of
    irAddReal: Value := Left.RealValue + Right.RealValue;
    irSubReal: Value := Left.RealValue - Right.RealValue;
    irMulReal: Value := Left.RealValue * Right.RealValue;
    irDivReal:
      begin
        if Right.RealValue = 0.0 then
        begin
          AddError(Diagnostics, dcDivisionByZero, Inst.Span,
            'real division by zero in constant expression');
          Exit(False);
        end;
        Value := Left.RealValue / Right.RealValue;
      end;
    irCompareEqual: Value := Ord(Left.RealValue = Right.RealValue);
    irCompareNotEqual: Value := Ord(Left.RealValue <> Right.RealValue);
    irCompareLess: Value := Ord(Left.RealValue < Right.RealValue);
    irCompareLessEqual: Value := Ord(Left.RealValue <= Right.RealValue);
    irCompareGreater: Value := Ord(Left.RealValue > Right.RealValue);
    irCompareGreaterEqual: Value := Ord(Left.RealValue >= Right.RealValue);
  else
    Exit(False);
  end;
  if Inst.Op in [irCompareEqual, irCompareNotEqual, irCompareLess,
    irCompareLessEqual, irCompareGreater, irCompareGreaterEqual] then
    RewriteAsConstInt(Inst, Trunc(Value))
  else
    RewriteAsConstReal(Inst, Value);
end;

procedure ConstantFold(var ProgramIR: TIRProgram;
  const Options: TCompilerOptions; var Diagnostics: TDiagnosticBag;
  var Stats: TOptimizationStats);
var
  States: array of TValueState;
  I: Integer;
  Inst: ^TIRInstruction;
  Left, Right: TValueState;
  Changed: Boolean;
begin
  SetLength(States, Length(ProgramIR.Values));
  repeat
    Changed := False;
    BuildValueStates(ProgramIR, States);
    for I := 0 to High(ProgramIR.Instructions) do
    begin
      Inst := @ProgramIR.Instructions[I];
      if IsRemoved(Inst^) then Continue;
      if (Inst^.A >= 0) and (Inst^.A <= High(States)) then
        Left := States[Inst^.A]
      else
        Left.Kind := vskUnknown;
      if (Inst^.B >= 0) and (Inst^.B <= High(States)) then
        Right := States[Inst^.B]
      else
        Right.Kind := vskUnknown;
      case Inst^.Op of
        irNegInt:
          if Left.Kind = vskInt then
          begin
            if Left.IntValue <> Low(Int64) then
            begin
              RewriteAsConstInt(Inst^, -Left.IntValue);
              Inc(Stats.ConstantsFolded);
              Changed := True;
            end;
          end;
        irLogicalNot:
          if Left.Kind = vskInt then
          begin
            RewriteAsConstInt(Inst^, Ord(Left.IntValue = 0));
            Inc(Stats.ConstantsFolded);
            Changed := True;
          end;
        irAddInt, irSubInt, irMulInt, irDivInt, irModInt, irRemInt,
        irPowerInt, irShiftLeft, irShiftRight, irBitAnd, irBitOr, irBitXor,
        irCompareEqual, irCompareNotEqual, irCompareLess, irCompareLessEqual,
        irCompareGreater, irCompareGreaterEqual:
          if (Left.Kind = vskInt) and (Right.Kind = vskInt) and
             FoldIntegerInstruction(Inst^, Left, Right, Options, Diagnostics) then
          begin
            Inc(Stats.ConstantsFolded);
            Changed := True;
          end;
        irNegReal:
          if Left.Kind = vskReal then
          begin
            RewriteAsConstReal(Inst^, -Left.RealValue);
            Inc(Stats.ConstantsFolded);
            Changed := True;
          end;
        irAddReal, irSubReal, irMulReal, irDivReal:
          if (Left.Kind = vskReal) and (Right.Kind = vskReal) and
             FoldRealInstruction(Inst^, Left, Right, Diagnostics) then
          begin
            Inc(Stats.ConstantsFolded);
            Changed := True;
          end;
        irConvertIntToReal:
          if Left.Kind = vskInt then
          begin
            RewriteAsConstReal(Inst^, Left.IntValue);
            Inc(Stats.ConstantsFolded);
            Changed := True;
          end;
        irConvertRealToInt:
          if Left.Kind = vskReal then
          begin
            RewriteAsConstInt(Inst^, Trunc(Left.RealValue));
            Inc(Stats.ConstantsFolded);
            Changed := True;
          end;
        irMove:
          begin
            if Left.Kind = vskInt then
            begin
              RewriteAsConstInt(Inst^, Left.IntValue);
              Changed := True;
            end
            else if Left.Kind = vskReal then
            begin
              RewriteAsConstReal(Inst^, Left.RealValue);
              Changed := True;
            end;
          end;
      end;
    end;
  until not Changed;
  IRComputeUseLists(ProgramIR);
end;

function ConstantIntForValue(const ProgramIR: TIRProgram; ValueId: Int32;
  out Value: Int64): Boolean;
var
  D: Int32;
begin
  Result := False;
  if (ValueId < 0) or (ValueId > High(ProgramIR.Values)) then Exit;
  D := ProgramIR.Values[ValueId].DefInstruction;
  if (D < 0) or (D > High(ProgramIR.Instructions)) then Exit;
  if IsRemoved(ProgramIR.Instructions[D]) then Exit;
  if ProgramIR.Instructions[D].Op = irConstInt then
  begin
    Value := ProgramIR.Instructions[D].Imm;
    Result := True;
  end;
end;

procedure AlgebraicSimplification(var ProgramIR: TIRProgram;
  var Stats: TOptimizationStats);
var
  I: Integer;
  Inst: ^TIRInstruction;
  AConst, BConst: Boolean;
  AValue, BValue: Int64;
begin
  IRComputeUseLists(ProgramIR);
  for I := 0 to High(ProgramIR.Instructions) do
  begin
    Inst := @ProgramIR.Instructions[I];
    if IsRemoved(Inst^) then Continue;
    AConst := ConstantIntForValue(ProgramIR, Inst^.A, AValue);
    BConst := ConstantIntForValue(ProgramIR, Inst^.B, BValue);
    case Inst^.Op of
      irAddInt:
        begin
          if AConst and (AValue = 0) then
          begin RewriteAsMove(Inst^, Inst^.B); Inc(Stats.AlgebraicRewrites); end
          else if BConst and (BValue = 0) then
          begin RewriteAsMove(Inst^, Inst^.A); Inc(Stats.AlgebraicRewrites); end;
        end;
      irSubInt:
        if BConst and (BValue = 0) then
        begin RewriteAsMove(Inst^, Inst^.A); Inc(Stats.AlgebraicRewrites); end
        else if Inst^.A = Inst^.B then
        begin RewriteAsConstInt(Inst^, 0); Inc(Stats.AlgebraicRewrites); end;
      irMulInt:
        begin
          if (AConst and (AValue = 0)) or (BConst and (BValue = 0)) then
          begin RewriteAsConstInt(Inst^, 0); Inc(Stats.AlgebraicRewrites); end
          else if AConst and (AValue = 1) then
          begin RewriteAsMove(Inst^, Inst^.B); Inc(Stats.AlgebraicRewrites); end
          else if BConst and (BValue = 1) then
          begin RewriteAsMove(Inst^, Inst^.A); Inc(Stats.AlgebraicRewrites); end
          else if AConst and (AValue = -1) then
          begin Inst^.Op := irNegInt; Inst^.A := Inst^.B; Inst^.B := -1;
            Inc(Stats.AlgebraicRewrites); end
          else if BConst and (BValue = -1) then
          begin Inst^.Op := irNegInt; Inst^.B := -1;
            Inc(Stats.AlgebraicRewrites); end;
        end;
      irDivInt:
        if BConst and (BValue = 1) then
        begin RewriteAsMove(Inst^, Inst^.A); Inc(Stats.AlgebraicRewrites); end;
      irBitOr, irBitXor:
        begin
          if AConst and (AValue = 0) then
          begin RewriteAsMove(Inst^, Inst^.B); Inc(Stats.AlgebraicRewrites); end
          else if BConst and (BValue = 0) then
          begin RewriteAsMove(Inst^, Inst^.A); Inc(Stats.AlgebraicRewrites); end;
        end;
      irBitAnd:
        begin
          if (AConst and (AValue = 0)) or (BConst and (BValue = 0)) then
          begin RewriteAsConstInt(Inst^, 0); Inc(Stats.AlgebraicRewrites); end
          else if AConst and (AValue = -1) then
          begin RewriteAsMove(Inst^, Inst^.B); Inc(Stats.AlgebraicRewrites); end
          else if BConst and (BValue = -1) then
          begin RewriteAsMove(Inst^, Inst^.A); Inc(Stats.AlgebraicRewrites); end;
        end;
      irCompareEqual:
        if (Inst^.A = Inst^.B) and (Inst^.A >= 0) and
           (Inst^.A <= High(ProgramIR.Values)) and
           (ProgramIR.Values[Inst^.A].TypeId <> FSIM_TYPE_REAL) then
        begin RewriteAsConstInt(Inst^, 1); Inc(Stats.AlgebraicRewrites); end;
      irCompareNotEqual, irCompareLess, irCompareGreater:
        if (Inst^.A = Inst^.B) and (Inst^.A >= 0) and
           (Inst^.A <= High(ProgramIR.Values)) and
           (ProgramIR.Values[Inst^.A].TypeId <> FSIM_TYPE_REAL) then
        begin RewriteAsConstInt(Inst^, 0); Inc(Stats.AlgebraicRewrites); end;
      irCompareLessEqual, irCompareGreaterEqual:
        if (Inst^.A = Inst^.B) and (Inst^.A >= 0) and
           (Inst^.A <= High(ProgramIR.Values)) and
           (ProgramIR.Values[Inst^.A].TypeId <> FSIM_TYPE_REAL) then
        begin RewriteAsConstInt(Inst^, 1); Inc(Stats.AlgebraicRewrites); end;
    end;
  end;
  IRComputeUseLists(ProgramIR);
end;

procedure FoldConditionalBranches(var ProgramIR: TIRProgram;
  var Stats: TOptimizationStats);
var
  I: Integer;
  Value: Int64;
  Target: Int32;
begin
  IRComputeUseLists(ProgramIR);
  for I := 0 to High(ProgramIR.Instructions) do
    if not IsRemoved(ProgramIR.Instructions[I]) and
       (ProgramIR.Instructions[I].Op = irBranchCond) and
       ConstantIntForValue(ProgramIR, ProgramIR.Instructions[I].A, Value) then
    begin
      if Value <> 0 then
        Target := ProgramIR.Instructions[I].TargetBlock
      else
        Target := ProgramIR.Instructions[I].AlternateBlock;
      ProgramIR.Instructions[I].Op := irBranch;
      ProgramIR.Instructions[I].A := IR_INVALID_VALUE;
      ProgramIR.Instructions[I].TargetBlock := Target;
      ProgramIR.Instructions[I].AlternateBlock := IR_INVALID_BLOCK;
      Inc(Stats.BranchesFolded);
    end;
  IRBuildEdges(ProgramIR);
  IRComputeUseLists(ProgramIR);
end;

procedure MarkReachable(const ProgramIR: TIRProgram; EntryBlock: Int32;
  var Reachable: array of Boolean);
var
  Queue: TInt32Array;
  Head, Tail, B, I, S, FirstSuccessor, SuccessorCount: Integer;
begin
  if EntryBlock < 0 then Exit;
  if (EntryBlock > High(ProgramIR.Blocks)) or
     (EntryBlock > High(Reachable)) then
    raise EInvalidOp.CreateFmt('reachability entry block %d is invalid',
      [EntryBlock]);
  SetLength(Queue, Length(ProgramIR.Blocks));
  if Length(Queue) = 0 then Exit;
  Head := 0;
  Tail := 1;
  Queue[0] := EntryBlock;
  Reachable[EntryBlock] := True;
  while Head < Tail do
  begin
    B := Queue[Head];
    Inc(Head);
    if (B < 0) or (B > High(ProgramIR.Blocks)) then
      raise EInvalidOp.CreateFmt('reachability queue contains invalid block %d',
        [B]);
    FirstSuccessor := ProgramIR.Blocks[B].FirstSuccessor;
    SuccessorCount := ProgramIR.Blocks[B].SuccessorCount;
    if (FirstSuccessor < 0) or (SuccessorCount < 0) or
       (FirstSuccessor > Length(ProgramIR.Successors)) or
       (SuccessorCount > Length(ProgramIR.Successors) - FirstSuccessor) then
      raise EInvalidOp.CreateFmt('block %d has invalid successor slice %d+%d',
        [B, FirstSuccessor, SuccessorCount]);
    for I := 0 to SuccessorCount - 1 do
    begin
      S := ProgramIR.Successors[FirstSuccessor + I];
      if (S < 0) or (S > High(Reachable)) then
        raise EInvalidOp.CreateFmt('block %d references invalid successor %d',
          [B, S]);
      if not Reachable[S] then
      begin
        if Tail >= Length(Queue) then
          raise EInvalidOp.Create('reachability queue overflow');
        Reachable[S] := True;
        Queue[Tail] := S;
        Inc(Tail);
      end;
    end;
  end;
end;

procedure RemoveUnreachableBlocks(var ProgramIR: TIRProgram;
  var Stats: TOptimizationStats);
var
  Reachable: array of Boolean;
  F, B, I: Integer;
begin
  IRBuildEdges(ProgramIR);
  SetLength(Reachable, Length(ProgramIR.Blocks));
  for F := 0 to High(ProgramIR.Functions) do
    MarkReachable(ProgramIR, ProgramIR.Functions[F].EntryBlock, Reachable);
  for B := 0 to High(ProgramIR.Blocks) do
  begin
    if Reachable[B] then
    begin
      Include(ProgramIR.Blocks[B].Flags, ibfReachable);
      Continue;
    end;
    if ProgramIR.Blocks[B].FirstInstruction >= 0 then
    begin
      if (ProgramIR.Blocks[B].FirstInstruction > High(ProgramIR.Instructions)) or
         (ProgramIR.Blocks[B].LastInstruction <
          ProgramIR.Blocks[B].FirstInstruction) or
         (ProgramIR.Blocks[B].LastInstruction > High(ProgramIR.Instructions)) then
        raise EInvalidOp.CreateFmt('block %d has invalid instruction range %d..%d',
          [B, ProgramIR.Blocks[B].FirstInstruction,
           ProgramIR.Blocks[B].LastInstruction]);
      for I := ProgramIR.Blocks[B].FirstInstruction to
        ProgramIR.Blocks[B].LastInstruction do
        if ProgramIR.Instructions[I].BlockId = B then
          RemoveInstruction(ProgramIR.Instructions[I], Stats);
    end;
    Inc(Stats.BlocksRemoved);
  end;
  IRBuildEdges(ProgramIR);
  IRComputeUseLists(ProgramIR);
end;

procedure DeadCodeElimination(var ProgramIR: TIRProgram;
  var Stats: TOptimizationStats);
var
  I: Integer;
  Changed: Boolean;
  Inst: ^TIRInstruction;
begin
  repeat
    Changed := False;
    IRComputeUseLists(ProgramIR);
    for I := High(ProgramIR.Instructions) downto 0 do
    begin
      Inst := @ProgramIR.Instructions[I];
      if IsRemoved(Inst^) then Continue;
      if Inst^.Dst > High(ProgramIR.Values) then
        raise EInvalidOp.CreateFmt('dead-code elimination saw invalid value %d',
          [Inst^.Dst]);
      if (Inst^.Dst >= 0) and (Inst^.Dst <= High(ProgramIR.Values)) and
         (ProgramIR.Values[Inst^.Dst].UseCount = 0) and
         not IROpHasSideEffects(Inst^.Op) and not IROpMayTrap(Inst^.Op) then
      begin
        RemoveInstruction(Inst^, Stats);
        Changed := True;
      end;
      if (Inst^.Op = irMove) and (Inst^.Dst = Inst^.A) then
      begin
        RemoveInstruction(Inst^, Stats);
        Changed := True;
      end;
    end;
  until not Changed;
  IRComputeUseLists(ProgramIR);
end;

function IsCSECandidate(Op: TIROpcode): Boolean;
begin
  Result := Op in [irConstInt, irConstReal, irConstNull, irConstString,
    irAddInt, irSubInt, irMulInt, irDivInt, irModInt, irRemInt, irNegInt,
    irAddReal, irSubReal, irMulReal, irDivReal, irNegReal, irShiftLeft,
    irShiftRight, irBitAnd, irBitOr, irBitXor, irLogicalNot,
    irCompareEqual, irCompareNotEqual, irCompareLess, irCompareLessEqual,
    irCompareGreater, irCompareGreaterEqual, irConvertIntToReal,
    irConvertRealToInt, irConvertIntWidth, irStringLength, irStringByte,
    irStringToInteger, irRTTIOf];
end;

function SameExpression(const A, B: TIRInstruction): Boolean;
begin
  Result := (A.Op = B.Op) and (A.TypeId = B.TypeId) and
    (A.A = B.A) and (A.B = B.B) and (A.C = B.C) and
    (A.SymbolId = B.SymbolId) and (A.Aux = B.Aux) and
    (A.StringId = B.StringId) and (A.Imm = B.Imm) and
    (A.RealImm = B.RealImm);
end;

procedure LocalCommonSubexpressionElimination(var ProgramIR: TIRProgram;
  var Stats: TOptimizationStats);
var
  B, I, J, First, Last: Integer;
  Inst: ^TIRInstruction;
begin
  for B := 0 to High(ProgramIR.Blocks) do
  begin
    First := ProgramIR.Blocks[B].FirstInstruction;
    Last := ProgramIR.Blocks[B].LastInstruction;
    if First < 0 then Continue;
    for I := First to Last do
    begin
      Inst := @ProgramIR.Instructions[I];
      if IsRemoved(Inst^) or not IsCSECandidate(Inst^.Op) or
         (Inst^.Dst < 0) then Continue;
      for J := I - 1 downto First do
      begin
        if ProgramIR.Instructions[J].BlockId <> B then Continue;
        if IsRemoved(ProgramIR.Instructions[J]) then Continue;
        if IROpHasSideEffects(ProgramIR.Instructions[J].Op) then Break;
        if (ProgramIR.Instructions[J].Dst >= 0) and
           SameExpression(Inst^, ProgramIR.Instructions[J]) then
        begin
          RewriteAsMove(Inst^, ProgramIR.Instructions[J].Dst);
          Inc(Stats.CommonExpressionsEliminated);
          Break;
        end;
      end;
    end;
  end;
  IRComputeUseLists(ProgramIR);
end;

procedure ComputeLoopDepths(var ProgramIR: TIRProgram);
var
  I, FromBlock, ToBlock, B: Integer;
begin
  for B := 0 to High(ProgramIR.Blocks) do
    ProgramIR.Blocks[B].LoopDepth := 0;
  IRBuildEdges(ProgramIR);
  for I := 0 to High(ProgramIR.Edges) do
  begin
    FromBlock := ProgramIR.Edges[I].FromBlock;
    ToBlock := ProgramIR.Edges[I].ToBlock;
    if (FromBlock < 0) or (FromBlock > High(ProgramIR.Blocks)) or
       (ToBlock < 0) or (ToBlock > High(ProgramIR.Blocks)) then
      Continue;
    if (ProgramIR.Blocks[FromBlock].FunctionId =
        ProgramIR.Blocks[ToBlock].FunctionId) and
       (ToBlock <= FromBlock) then
    begin
      Include(ProgramIR.Blocks[ToBlock].Flags, ibfLoopHeader);
      for B := ToBlock to FromBlock do
        if ProgramIR.Blocks[B].FunctionId =
           ProgramIR.Blocks[FromBlock].FunctionId then
          Inc(ProgramIR.Blocks[B].LoopDepth);
      Include(ProgramIR.Blocks[FromBlock].Flags, ibfLoopLatch);
    end;
  end;
end;

procedure SimplifyLoopInvariants(var ProgramIR: TIRProgram;
  var Stats: TOptimizationStats);
var
  I: Integer;
  Inst: ^TIRInstruction;
  AValue, BValue: Int64;
begin
  ComputeLoopDepths(ProgramIR);
  for I := 0 to High(ProgramIR.Instructions) do
  begin
    Inst := @ProgramIR.Instructions[I];
    if IsRemoved(Inst^) then Continue;
    if (Inst^.BlockId < 0) or (Inst^.BlockId > High(ProgramIR.Blocks)) then
      Continue;
    if ProgramIR.Blocks[Inst^.BlockId].LoopDepth = 0 then Continue;
    if (Inst^.Op = irMulInt) and
       ConstantIntForValue(ProgramIR, Inst^.B, BValue) and
       (BValue > 0) and ((BValue and (BValue - 1)) = 0) then
    begin
      AValue := 0;
      while (Int64(1) shl AValue) <> BValue do Inc(AValue);
      Inst^.Op := irShiftLeft;
      Inst^.B := IR_INVALID_VALUE;
      Inst^.Aux := AValue;
      Inc(Stats.LoopInvariantsSimplified);
    end;
  end;
end;

procedure DeduplicateConstants(var ProgramIR: TIRProgram;
  var Stats: TOptimizationStats);
var
  F, I, J, First, Last: Integer;
  Inst: ^TIRInstruction;
begin
  for F := 0 to High(ProgramIR.Functions) do
  begin
    First := ProgramIR.Functions[F].FirstInstruction;
    if (First < 0) or (First > High(ProgramIR.Instructions)) or
       (ProgramIR.Functions[F].InstructionCount <= 0) then
      Continue;
    if ProgramIR.Functions[F].InstructionCount - 1 >
       High(ProgramIR.Instructions) - First then
      Last := High(ProgramIR.Instructions)
    else
      Last := First + ProgramIR.Functions[F].InstructionCount - 1;
    for I := First to Last do
    begin
      Inst := @ProgramIR.Instructions[I];
      if IsRemoved(Inst^) or not (Inst^.Op in [irConstInt, irConstReal,
        irConstString, irConstNull]) then Continue;
      for J := First to I - 1 do
        if not IsRemoved(ProgramIR.Instructions[J]) and
           SameExpression(Inst^, ProgramIR.Instructions[J]) then
        begin
          RewriteAsMove(Inst^, ProgramIR.Instructions[J].Dst);
          Inc(Stats.CommonExpressionsEliminated);
          Break;
        end;
    end;
  end;
end;

procedure VerifyAfterPass(const ProgramIR: TIRProgram;
  const Options: TCompilerOptions);
begin
  if Options.VerifyEachPass then
    IRVerify(ProgramIR);
end;

procedure RaiseOptimizationPassFailure(const PassName: RawByteString;
  E: Exception);
begin
  raise EInvalidOp.Create('optimization pass ' + PassName + ' failed: ' +
    E.Message);
end;

procedure RunCanonicalRules(var ProgramIR: TIRProgram;
  var Stats: TOptimizationStats);
var
  Rewrites: UInt32;
begin
  Rewrites := ApplySimpleFolds(ProgramIR);
  Inc(Stats.CanonicalRewrites, Rewrites);
  Inc(Stats.AlgebraicRewrites, Rewrites);
  Inc(Stats.PassesRun);
  if Rewrites <> 0 then IRComputeUseLists(ProgramIR);
end;

procedure RunGlobalDataFlow(var ProgramIR: TIRProgram;
  var Stats: TOptimizationStats);
var
  DataFlow: TProgramDataFlow;
  FunctionIndex, BlockIndex, GlobalBlock: Int32;
begin
  DataFlowInit(DataFlow);
  try
    IRBuildEdges(ProgramIR);
    DataFlowAnalyze(ProgramIR, DataFlow);
    Stats.DataFlowFunctions := Length(DataFlow.Functions);
    for FunctionIndex := 0 to High(DataFlow.Functions) do
    begin
      Inc(Stats.NaturalLoops, Length(DataFlow.Functions[FunctionIndex].Loops));
      for BlockIndex := 0 to High(DataFlow.Functions[FunctionIndex].Blocks) do
      begin
        GlobalBlock := DataFlow.Functions[FunctionIndex].Blocks[BlockIndex];
        if (GlobalBlock >= 0) and (GlobalBlock <= High(ProgramIR.Blocks)) and
           (BlockIndex <= High(DataFlow.Functions[FunctionIndex].BlockInfo)) then
        begin
          ProgramIR.Blocks[GlobalBlock].LoopDepth :=
            DataFlow.Functions[FunctionIndex].BlockInfo[BlockIndex].LoopDepth;
          if ProgramIR.Blocks[GlobalBlock].LoopDepth <> 0 then
            Include(ProgramIR.Blocks[GlobalBlock].Flags, ibfLoopHeader);
        end;
      end;
    end;
    Inc(Stats.PassesRun);
  finally
    DataFlowClear(DataFlow);
  end;
end;

procedure RunO1(var ProgramIR: TIRProgram; const Options: TCompilerOptions;
  var Diagnostics: TDiagnosticBag; var Stats: TOptimizationStats);
begin
  try
    CopyPropagation(ProgramIR, Stats); Inc(Stats.PassesRun);
    VerifyAfterPass(ProgramIR, Options);
  except
    on E: Exception do RaiseOptimizationPassFailure('copy-propagation', E);
  end;
  try
    ConstantFold(ProgramIR, Options, Diagnostics, Stats); Inc(Stats.PassesRun);
    VerifyAfterPass(ProgramIR, Options);
  except
    on E: Exception do RaiseOptimizationPassFailure('constant-fold', E);
  end;
  try
    AlgebraicSimplification(ProgramIR, Stats); Inc(Stats.PassesRun);
    VerifyAfterPass(ProgramIR, Options);
  except
    on E: Exception do RaiseOptimizationPassFailure('algebraic-simplification', E);
  end;
  try
    RunCanonicalRules(ProgramIR, Stats);
    VerifyAfterPass(ProgramIR, Options);
  except
    on E: Exception do RaiseOptimizationPassFailure('canonical-rules', E);
  end;
  try
    FoldConditionalBranches(ProgramIR, Stats); Inc(Stats.PassesRun);
  except
    on E: Exception do RaiseOptimizationPassFailure('branch-folding', E);
  end;
  try
    RemoveUnreachableBlocks(ProgramIR, Stats); Inc(Stats.PassesRun);
  except
    on E: Exception do RaiseOptimizationPassFailure('unreachable-blocks', E);
  end;
  try
    DeadCodeElimination(ProgramIR, Stats); Inc(Stats.PassesRun);
  except
    on E: Exception do RaiseOptimizationPassFailure('dead-code-elimination', E);
  end;
end;

procedure RunO2(var ProgramIR: TIRProgram; const Options: TCompilerOptions;
  var Diagnostics: TDiagnosticBag; var Stats: TOptimizationStats);
begin
  RunO1(ProgramIR, Options, Diagnostics, Stats);
  LocalCommonSubexpressionElimination(ProgramIR, Stats); Inc(Stats.PassesRun);
  CopyPropagation(ProgramIR, Stats); Inc(Stats.PassesRun);
  ConstantFold(ProgramIR, Options, Diagnostics, Stats); Inc(Stats.PassesRun);
  AlgebraicSimplification(ProgramIR, Stats); Inc(Stats.PassesRun);
  DeadCodeElimination(ProgramIR, Stats); Inc(Stats.PassesRun);
end;

procedure RunO3(var ProgramIR: TIRProgram; const Options: TCompilerOptions;
  var Diagnostics: TDiagnosticBag; var Stats: TOptimizationStats);
begin
  RunO2(ProgramIR, Options, Diagnostics, Stats);
  RunGlobalDataFlow(ProgramIR, Stats);
  ComputeLoopDepths(ProgramIR); Inc(Stats.PassesRun);
  SimplifyLoopInvariants(ProgramIR, Stats); Inc(Stats.PassesRun);
  DeduplicateConstants(ProgramIR, Stats); Inc(Stats.PassesRun);
  CopyPropagation(ProgramIR, Stats); Inc(Stats.PassesRun);
  ConstantFold(ProgramIR, Options, Diagnostics, Stats); Inc(Stats.PassesRun);
  LocalCommonSubexpressionElimination(ProgramIR, Stats); Inc(Stats.PassesRun);
  DeadCodeElimination(ProgramIR, Stats); Inc(Stats.PassesRun);
  FoldConditionalBranches(ProgramIR, Stats); Inc(Stats.PassesRun);
  RemoveUnreachableBlocks(ProgramIR, Stats); Inc(Stats.PassesRun);
end;

procedure RunOFast(var ProgramIR: TIRProgram; const Options: TCompilerOptions;
  var Diagnostics: TDiagnosticBag; var Stats: TOptimizationStats);
var
  I: Integer;
begin
  RunO3(ProgramIR, Options, Diagnostics, Stats);
  for I := 0 to High(ProgramIR.Instructions) do
    if not IsRemoved(ProgramIR.Instructions[I]) and
       (ProgramIR.Instructions[I].Op in [irAddInt, irSubInt, irMulInt,
        irAddReal, irSubReal, irMulReal, irDivReal]) then
    begin
      Include(ProgramIR.Instructions[I].Flags, iifNoOverflow);
      Include(ProgramIR.Instructions[I].Flags, iifFastMath);
    end;
  Inc(Stats.PassesRun);
end;

procedure CloneIRProgram(const Source: TIRProgram; out Dest: TIRProgram);
begin
  Dest := Default(TIRProgram);
  Dest.Functions := Copy(Source.Functions, 0, Length(Source.Functions));
  Dest.Blocks := Copy(Source.Blocks, 0, Length(Source.Blocks));
  Dest.Instructions := Copy(Source.Instructions, 0, Length(Source.Instructions));
  Dest.Values := Copy(Source.Values, 0, Length(Source.Values));
  Dest.Edges := Copy(Source.Edges, 0, Length(Source.Edges));
  Dest.Predecessors := Copy(Source.Predecessors, 0, Length(Source.Predecessors));
  Dest.Successors := Copy(Source.Successors, 0, Length(Source.Successors));
  Dest.Strings.Entries := Copy(Source.Strings.Entries, 0, Length(Source.Strings.Entries));
  Dest.Strings.Bytes.Data := Copy(Source.Strings.Bytes.Data, 0,
    Length(Source.Strings.Bytes.Data));
  Dest.Strings.Bytes.Count := Source.Strings.Bytes.Count;
  Dest.EntryFunction := Source.EntryFunction;
end;

procedure OptimizeProgram(var ProgramIR: TIRProgram;
  const Symbols: TSymbolTable; const Options: TCompilerOptions;
  var Diagnostics: TDiagnosticBag; out Stats: TOptimizationStats);
var
  Advanced: TAdvancedOptimizationStats;
  Backup: TIRProgram;
  FailureMessage: RawByteString;
  FailureSpan: TSourceSpan;
begin
  CloneIRProgram(ProgramIR, Backup);
  try
  Stats := Default(TOptimizationStats);
  try
    IRBuildEdges(ProgramIR);
    IRComputeUseLists(ProgramIR);
    IRVerify(ProgramIR);
  except
    on E: Exception do RaiseOptimizationPassFailure('initial-ir-validation', E);
  end;
  case Options.Optimization of
    ol0:
      begin
        RemoveUnreachableBlocks(ProgramIR, Stats);
        Inc(Stats.PassesRun);
      end;
    ol1: RunO1(ProgramIR, Options, Diagnostics, Stats);
    ol2: RunO2(ProgramIR, Options, Diagnostics, Stats);
    ol3: RunO3(ProgramIR, Options, Diagnostics, Stats);
    olFast: RunOFast(ProgramIR, Options, Diagnostics, Stats);
  end;
  try
    RunAdvancedOptimizations(ProgramIR, Symbols, Options.Optimization, Advanced);
  except
    on E: Exception do RaiseOptimizationPassFailure('advanced-pipeline', E);
  end;
  Inc(Stats.AdvancedIterations, Advanced.Iterations);
  Inc(Stats.StrengthReductions, Advanced.StrengthReductions);
  Inc(Stats.DoubleNegationsRemoved, Advanced.DoubleNegationsRemoved);
  Inc(Stats.LoadsForwarded, Advanced.LoadsForwarded);
  Inc(Stats.StoresRemovedAdvanced, Advanced.StoresRemoved);
  Inc(Stats.BranchesThreaded, Advanced.BranchesThreaded);
  Inc(Stats.TailCallsDiscovered, Advanced.TailCallsDiscovered);
  Inc(Stats.PassesRun, Advanced.Iterations + 2);
  try
    IRBuildEdges(ProgramIR);
    IRComputeUseLists(ProgramIR);
    IRVerify(ProgramIR);
  except
    on E: Exception do RaiseOptimizationPassFailure('final-ir-validation', E);
  end;
  if Length(Symbols.Symbols) = 0 then
    ;
  except
    on E: Exception do
    begin
      FailureMessage := E.Message;
      ProgramIR := Backup;
      { Optimization is never allowed to turn a valid source program into an
        internal compiler crash.  Keep the original lowered IR and continue.
        -Werror deliberately promotes this warning for compiler developers. }
      IRComputeUseLists(ProgramIR);
      IRVerify(ProgramIR);
      FailureSpan := Default(TSourceSpan);
      AddWarning(Diagnostics, dcInternalError, FailureSpan,
        'optimizer recovered by using unoptimized IR: ' + FailureMessage);
      Stats := Default(TOptimizationStats);
    end;
  end;
end;

end.

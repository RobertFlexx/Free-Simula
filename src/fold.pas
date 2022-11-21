unit fold;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  core, ir;

function ApplySimpleFolds(var ProgramIR: TIRProgram): UInt32;

implementation

function TryIntegerConstant(const ProgramIR: TIRProgram; ValueId: Int32;
  out Value: Int64): Boolean;
var
  DefInstruction: Int32;
begin
  Result := False;
  Value := 0;
  if (ValueId < 0) or (ValueId >= Length(ProgramIR.Values)) then Exit;
  DefInstruction := ProgramIR.Values[ValueId].DefInstruction;
  if (DefInstruction < 0) or
     (DefInstruction >= Length(ProgramIR.Instructions)) then Exit;
  if iifRemoved in ProgramIR.Instructions[DefInstruction].Flags then Exit;
  if ProgramIR.Instructions[DefInstruction].Op <> irConstInt then Exit;
  Value := ProgramIR.Instructions[DefInstruction].Imm;
  Result := True;
end;

procedure MakeMove(var Inst: TIRInstruction; Source: Int32);
begin
  Inst.Op := irMove;
  Inst.A := Source;
  Inst.B := IR_INVALID_VALUE;
  Inst.C := IR_INVALID_VALUE;
  Inst.Imm := 0;
  Inst.RealImm := 0.0;
  Exclude(Inst.Flags, iifMayTrap);
end;

procedure MakeIntegerConstant(var Inst: TIRInstruction; Value: Int64);
begin
  Inst.Op := irConstInt;
  Inst.A := IR_INVALID_VALUE;
  Inst.B := IR_INVALID_VALUE;
  Inst.C := IR_INVALID_VALUE;
  Inst.Imm := Value;
  Inst.RealImm := 0.0;
  Exclude(Inst.Flags, iifMayTrap);
end;

function FoldRight(var Inst: TIRInstruction; Value: Int64): Boolean;
begin
  Result := True;
  case Inst.Op of
    irAddInt, irSubInt:
      if Value = 0 then MakeMove(Inst, Inst.A) else Result := False;
    irMulInt:
      if Value = 0 then MakeIntegerConstant(Inst, 0)
      else if Value = 1 then MakeMove(Inst, Inst.A)
      else Result := False;
    irDivInt:
      if Value = 1 then MakeMove(Inst, Inst.A) else Result := False;
    irModInt, irRemInt:
      if (Value = 1) or (Value = -1) then MakeIntegerConstant(Inst, 0)
      else Result := False;
    irBitAnd:
      if Value = 0 then MakeIntegerConstant(Inst, 0)
      else if Value = -1 then MakeMove(Inst, Inst.A)
      else Result := False;
    irBitOr, irBitXor, irShiftLeft, irShiftRight:
      if Value = 0 then MakeMove(Inst, Inst.A) else Result := False;
  else
    Result := False;
  end;
end;

function FoldLeft(var Inst: TIRInstruction; Value: Int64): Boolean;
begin
  Result := True;
  case Inst.Op of
    irAddInt:
      if Value = 0 then MakeMove(Inst, Inst.B) else Result := False;
    irMulInt:
      if Value = 0 then MakeIntegerConstant(Inst, 0)
      else if Value = 1 then MakeMove(Inst, Inst.B)
      else Result := False;
    irBitAnd:
      if Value = 0 then MakeIntegerConstant(Inst, 0)
      else if Value = -1 then MakeMove(Inst, Inst.B)
      else Result := False;
    irBitOr, irBitXor:
      if Value = 0 then MakeMove(Inst, Inst.B) else Result := False;
  else
    Result := False;
  end;
end;

function ApplySimpleFolds(var ProgramIR: TIRProgram): UInt32;
var
  I: SizeInt;
  LeftValue, RightValue: Int64;
  HasLeft, HasRight: Boolean;
begin
  Result := 0;
  for I := 0 to High(ProgramIR.Instructions) do
  begin
    if iifRemoved in ProgramIR.Instructions[I].Flags then Continue;
    HasLeft := TryIntegerConstant(ProgramIR,
      ProgramIR.Instructions[I].A, LeftValue);
    HasRight := TryIntegerConstant(ProgramIR,
      ProgramIR.Instructions[I].B, RightValue);

    { right side first on purpose. the old table did that too and a couple of
      weird IR shapes depend on it, changing that for style points would suck. }
    if HasRight and FoldRight(ProgramIR.Instructions[I], RightValue) then
    begin
      Inc(Result);
      Continue;
    end;
    if HasLeft and FoldLeft(ProgramIR.Instructions[I], LeftValue) then
      Inc(Result);
  end;
end;

end.

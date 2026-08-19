program test_optimizer_advanced;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

uses
  SysUtils, core, diagnostics, symbols, ir,
  passes;

var
  TestDiagnostics: TDiagnosticBag;
  TestSymbols: TSymbolTable;
  ProgramIR: TIRProgram;
  Stats: TAdvancedOptimizationStats;
  FunctionId, BlockId: Int32;
  LeftValue, RightValue, ResultValue: Int32;
  LeftInstruction, RightInstruction, MultiplyInstruction: Int32;
  Span: TSourceSpan;
begin
  DiagnosticsInit(TestDiagnostics);
  SymTableInit(TestSymbols, TestDiagnostics, fdFSim);
  IRInit(ProgramIR);
  try
    Span := SourceSpan(SourcePos(1, 1, 0), SourcePos(1, 2, 1));
    FunctionId := IRNewFunction(ProgramIR, FSIM_INVALID_INDEX,
      FSIM_INVALID_INDEX, FSIM_TYPE_INTEGER, [iffEntry]);
    BlockId := IRNewBlock(ProgramIR, FunctionId, [ibfEntry]);
    LeftValue := IRNewValue(ProgramIR, FunctionId, FSIM_TYPE_INTEGER);
    LeftInstruction := IREmit(ProgramIR, FunctionId, BlockId, irConstInt,
      LeftValue, IR_INVALID_VALUE, IR_INVALID_VALUE, IR_INVALID_VALUE,
      FSIM_TYPE_INTEGER, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
      IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 7, 0.0, Span);
    RightValue := IRNewValue(ProgramIR, FunctionId, FSIM_TYPE_INTEGER);
    RightInstruction := IREmit(ProgramIR, FunctionId, BlockId, irConstInt,
      RightValue, IR_INVALID_VALUE, IR_INVALID_VALUE, IR_INVALID_VALUE,
      FSIM_TYPE_INTEGER, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
      IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 8, 0.0, Span);
    ResultValue := IRNewValue(ProgramIR, FunctionId, FSIM_TYPE_INTEGER);
    MultiplyInstruction := IREmit(ProgramIR, FunctionId, BlockId, irMulInt,
      ResultValue, LeftValue, RightValue, IR_INVALID_VALUE,
      FSIM_TYPE_INTEGER, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
      IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0, Span);
    IREmit(ProgramIR, FunctionId, BlockId, irReturn, IR_INVALID_VALUE,
      ResultValue, IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_INTEGER,
      FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
      FSIM_INVALID_INDEX, 0, 0.0, Span, [iifTerminator]);
    IRComputeUseLists(ProgramIR);
    RunAdvancedOptimizations(ProgramIR, TestSymbols, ol2, Stats);
    if ProgramIR.Instructions[LeftInstruction].Op <> irConstInt then Halt(1);
    if ProgramIR.Instructions[RightInstruction].Op <> irConstInt then Halt(2);
    if ProgramIR.Instructions[MultiplyInstruction].Op <> irShiftLeft then Halt(3);
    if ProgramIR.Instructions[MultiplyInstruction].B <> IR_INVALID_VALUE then Halt(4);
    if ProgramIR.Instructions[MultiplyInstruction].Aux <> 3 then Halt(5);
    if Stats.StrengthReductions = 0 then Halt(6);
  finally
    IRClear(ProgramIR);
    SymTableClear(TestSymbols);
    DiagnosticsClear(TestDiagnostics);
  end;
end.

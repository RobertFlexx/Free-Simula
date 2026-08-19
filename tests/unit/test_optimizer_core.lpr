program test_optimizer_core;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

uses
  core, diagnostics, symbols, ir, optimize;

var
  TestDiagnostics: TDiagnosticBag;
  TestSymbols: TSymbolTable;
  ProgramIR: TIRProgram;
  Options: TCompilerOptions;
  Stats: TOptimizationStats;
  FunctionId, BlockId: Int32;
  RealValue, CompareValue: Int32;
  CompareInstruction: Int32;
  Span: TSourceSpan;
begin
  DiagnosticsInit(TestDiagnostics);
  SymTableInit(TestSymbols, TestDiagnostics, fdFSim);
  IRInit(ProgramIR);
  InitCompilerOptions(Options);
  Options.Optimization := ol1;
  try
    Span := SourceSpan(SourcePos(1, 1, 0), SourcePos(1, 2, 1));
    FunctionId := IRNewFunction(ProgramIR, FSIM_INVALID_INDEX,
      FSIM_INVALID_INDEX, FSIM_TYPE_BOOLEAN, [iffEntry]);
    BlockId := IRNewBlock(ProgramIR, FunctionId, [ibfEntry]);
    RealValue := IRNewValue(ProgramIR, FunctionId, FSIM_TYPE_REAL);
    IREmit(ProgramIR, FunctionId, BlockId, irLoadSymbol, RealValue,
      IR_INVALID_VALUE, IR_INVALID_VALUE, IR_INVALID_VALUE,
      FSIM_TYPE_REAL, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
      IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0, Span);
    CompareValue := IRNewValue(ProgramIR, FunctionId, FSIM_TYPE_BOOLEAN);
    CompareInstruction := IREmit(ProgramIR, FunctionId, BlockId,
      irCompareEqual, CompareValue, RealValue, RealValue, IR_INVALID_VALUE,
      FSIM_TYPE_BOOLEAN, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
      IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0, Span);
    IREmit(ProgramIR, FunctionId, BlockId, irReturn, IR_INVALID_VALUE,
      CompareValue, IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN,
      FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
      FSIM_INVALID_INDEX, 0, 0.0, Span, [iifTerminator]);
    IRComputeUseLists(ProgramIR);
    OptimizeProgram(ProgramIR, TestSymbols, Options, TestDiagnostics, Stats);
    if ProgramIR.Instructions[CompareInstruction].Op <> irCompareEqual then Halt(1);
  finally
    IRClear(ProgramIR);
    SymTableClear(TestSymbols);
    DiagnosticsClear(TestDiagnostics);
  end;
end.

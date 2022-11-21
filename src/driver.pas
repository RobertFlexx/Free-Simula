unit driver;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  cli;

function RunCompiler(const Config: TCommandLine): Integer;

implementation

uses
  SysUtils, core, diagnostics, arena, utf8, dialect, classic, tasking, target,
  lexer, imports, ast, symbols, parser, semantics, ir, optimize, registers,
  x64, runtime, elf;

type
  TCompilerStage = (
    csStartup, csInitialization, csModuleDiscovery, csModuleLoading, csParsing,
    csSemanticAnalysis, csIRLowering, csOptimization, csRegisterAllocation,
    csNativeCodeGeneration, csOutputWriting
  );

  TDriverState = record
    Options: TCompilerOptions;
    Diagnostics: TDiagnosticBag;
    Tree: TAST;
    Symbols: TSymbolTable;
    Parser: TParser;
    Semantic: TSemanticAnalyzer;
    IR: TIRProgram;
    IRBuilder: TIRBuilder;
    OptimizationStats: TOptimizationStats;
    Allocation: TRegisterAllocation;
    NativeImage: TNativeImage;
    Source: RawByteString;
    ModuleLoader: TModuleLoader;
    ShowStats: Boolean;
    Quiet: Boolean;
    TraceStages: Boolean;
    Stage: TCompilerStage;
  end;

function CompilerStageName(Stage: TCompilerStage): RawByteString;
begin
  case Stage of
    csStartup: Result := 'startup';
    csInitialization: Result := 'pipeline initialization';
    csModuleDiscovery: Result := 'module search-path discovery';
    csModuleLoading: Result := 'module loading';
    csParsing: Result := 'lexing and parsing';
    csSemanticAnalysis: Result := 'semantic analysis';
    csIRLowering: Result := 'IR lowering';
    csOptimization: Result := 'optimization';
    csRegisterAllocation: Result := 'register allocation';
    csNativeCodeGeneration: Result := 'native code generation';
    csOutputWriting: Result := 'output writing';
  else
    Result := 'unknown stage';
  end;
end;

procedure EnterStage(var State: TDriverState; Stage: TCompilerStage);
begin
  State.Stage := Stage;
  if State.TraceStages then
    Writeln(StdErr, 'fsim: stage: ', CompilerStageName(Stage));
end;

procedure DumpTokenStream(const State: TDriverState);
var
  Lexer: TLexer;
  TemporaryDiagnostics: TDiagnosticBag;
  Text: RawByteString;
begin
  DiagnosticsInit(TemporaryDiagnostics);
  LexerInit(Lexer, PAnsiChar(State.Source), Length(State.Source),
    State.Options.Dialect, TemporaryDiagnostics);
  repeat
    Text := TokenText(Lexer.Current);
    Write(Lexer.Current.Span.StartPos.Line:6, ':',
      Lexer.Current.Span.StartPos.Column:4, '  ',
      TokenKindName(Lexer.Current.Kind):22);
    if Text <> '' then Write('  ''', Text, '''');
    if Lexer.Current.Kind = tkIntegerLiteral then
      Write('  value=', Lexer.Current.IntValue)
    else if Lexer.Current.Kind = tkRealLiteral then
      Write('  value=', Lexer.Current.RealValue:0:12);
    Writeln;
    if Lexer.Current.Kind <> tkEOF then LexerNext(Lexer);
  until Lexer.Current.Kind = tkEOF;
end;

procedure InitializePipeline(var State: TDriverState);
begin
  DiagnosticsInit(State.Diagnostics);
  DialectValidateOptions(State.Options, State.Diagnostics);
  ASTInit(State.Tree);
  SymTableInit(State.Symbols, State.Diagnostics, State.Options.Dialect);
  IRInit(State.IR);
  ModuleLoaderInit(State.ModuleLoader, State.Diagnostics, State.Options.Dialect);
end;

procedure ClearPipeline(var State: TDriverState);
begin
  ModuleLoaderClear(State.ModuleLoader);
  NativeImageClear(State.NativeImage);
  IRClear(State.IR);
  SymTableClear(State.Symbols);
  ASTClear(State.Tree);
  DiagnosticsClear(State.Diagnostics);
  SetLength(State.Allocation.Locations, 0);
  SetLength(State.Allocation.Intervals, 0);
  SetLength(State.Allocation.Functions, 0);
end;

procedure AddStandardLibraryCandidates(var State: TDriverState);
var
  ExecutableDirectory, Candidate, EnvironmentPath: RawByteString;
  I: SizeInt;
begin
  for I := 0 to High(State.Options.ModuleSearchPaths) do
    ModuleLoaderAddSearchPath(State.ModuleLoader,
      State.Options.ModuleSearchPaths[I]);
  if not State.Options.UseStandardLibrary then Exit;
  if State.Options.StandardLibraryPath <> '' then
    ModuleLoaderAddSearchPath(State.ModuleLoader,
      State.Options.StandardLibraryPath);
  EnvironmentPath := GetEnvironmentVariable('FSIM_STDLIB');
  if EnvironmentPath <> '' then
    ModuleLoaderAddSearchPath(State.ModuleLoader, EnvironmentPath);
  ExecutableDirectory := ExtractFilePath(ExpandFileName(ParamStr(0)));
  Candidate := ExpandFileName(ExecutableDirectory + '../share/fsim/stdlib');
  if DirectoryExists(Candidate) then
    ModuleLoaderAddSearchPath(State.ModuleLoader, Candidate);
  Candidate := ExpandFileName(ExecutableDirectory + '../stdlib');
  if DirectoryExists(Candidate) then
    ModuleLoaderAddSearchPath(State.ModuleLoader, Candidate);
  Candidate := ExpandFileName('stdlib');
  if DirectoryExists(Candidate) then
    ModuleLoaderAddSearchPath(State.ModuleLoader, Candidate);
end;

procedure PrintDialectInfo(Dialect: TFSimDialect);
begin
  Writeln('dialect: ', DialectName(Dialect));
  if Dialect = fdSimula67 then
    Writeln('extensions: off')
  else
    Writeln('classic simula syntax: on');
end;

function DiagnosticsFailed(const State: TDriverState): Boolean;
begin
  Result := HasErrors(State.Diagnostics) or
    (State.Options.WarningsAsErrors and (State.Diagnostics.WarningCount <> 0));
end;

procedure FlushDiagnostics(const State: TDriverState);
begin
  if Length(State.Diagnostics.Items) = 0 then Exit;
  case State.Options.DiagnosticFormat of
    dgJSON:
      PrintDiagnosticsJSON(State.Diagnostics, State.Options.InputPath,
        State.Options.WarningsAsErrors);
  else
    PrintDiagnostics(State.Diagnostics, State.Options.InputPath,
      State.Options.ColorDiagnostics, State.Options.WarningsAsErrors);
  end;
end;

procedure PrintStatistics(const State: TDriverState);
begin
  Writeln('fsim compilation statistics');
  Writeln('  dialect:                 ', DialectName(State.Options.Dialect));
  Writeln('  target:                  ', State.Options.TargetTriple);
  Writeln('  optimization:            ', OptLevelName(State.Options.Optimization));
  Writeln('  modules loaded:          ', Length(State.ModuleLoader.Modules));
  Writeln('  source bytes:            ', Length(State.Source));
  Writeln('  parsed declarations:     ', State.Parser.ParsedDeclarationCount);
  Writeln('  parsed statements:       ', State.Parser.ParsedStatementCount);
  Writeln('  AST nodes:               ', Length(State.Tree.Nodes));
  Writeln('  symbols:                 ', Length(State.Symbols.Symbols));
  Writeln('  types:                   ', Length(State.Symbols.Types));
  Writeln('  classes:                 ', Length(State.Symbols.Classes));
  Writeln('  IR functions:            ', Length(State.IR.Functions));
  Writeln('  IR blocks:               ', Length(State.IR.Blocks));
  Writeln('  IR instructions:         ', Length(State.IR.Instructions));
  Writeln('  IR values:               ', Length(State.IR.Values));
  Writeln('  optimization passes:     ', State.OptimizationStats.PassesRun);
  Writeln('  constants folded:        ', State.OptimizationStats.ConstantsFolded);
  Writeln('  algebraic rewrites:      ', State.OptimizationStats.AlgebraicRewrites);
  Writeln('  copies propagated:       ', State.OptimizationStats.CopiesPropagated);
  Writeln('  instructions removed:    ', State.OptimizationStats.InstructionsRemoved);
  Writeln('  branches folded:         ', State.OptimizationStats.BranchesFolded);
  Writeln('  blocks removed:          ', State.OptimizationStats.BlocksRemoved);
  Writeln('  CSE eliminations:        ',
    State.OptimizationStats.CommonExpressionsEliminated);
  Writeln('  loop simplifications:    ',
    State.OptimizationStats.LoopInvariantsSimplified);
  Writeln('  canonical rewrites:      ',
    State.OptimizationStats.CanonicalRewrites);
  Writeln('  data-flow functions:     ',
    State.OptimizationStats.DataFlowFunctions);
  Writeln('  natural loops:           ',
    State.OptimizationStats.NaturalLoops);
  Writeln('  advanced iterations:     ',
    State.OptimizationStats.AdvancedIterations);
  Writeln('  strength reductions:     ',
    State.OptimizationStats.StrengthReductions);
  Writeln('  double negations removed:',
    State.OptimizationStats.DoubleNegationsRemoved);
  Writeln('  loads forwarded:         ',
    State.OptimizationStats.LoadsForwarded);
  Writeln('  redundant stores removed:',
    State.OptimizationStats.StoresRemovedAdvanced);
  Writeln('  branches threaded:       ',
    State.OptimizationStats.BranchesThreaded);
  Writeln('  tail calls discovered:   ',
    State.OptimizationStats.TailCallsDiscovered);
  Writeln('  emitted text bytes:      ', State.NativeImage.Text.Count);
  Writeln('  emitted rodata bytes:    ', State.NativeImage.ReadOnlyData.Count);
  Writeln('  executable image bytes:  ', State.NativeImage.Image.Count);
  Writeln('  diagnostics:             ', State.Diagnostics.ErrorCount,
    ' error(s), ', State.Diagnostics.WarningCount, ' warning(s)');
end;


function RunPipeline(var State: TDriverState): Integer;
begin
  Result := 1;
  EnterStage(State, csInitialization);
  InitializePipeline(State);
  try
    EnterStage(State, csModuleDiscovery);
    AddStandardLibraryCandidates(State);
    if State.Options.PrintSearchDirs then
    begin
      ModuleLoaderPrintSearchPaths(State.ModuleLoader);
      Exit(0);
    end;
    if State.Options.PrintFeatures then
    begin
      PrintDialectInfo(State.Options.Dialect);
      Exit(0);
    end;

    EnterStage(State, csModuleLoading);
    State.Source := ModuleLoaderLoad(State.ModuleLoader, State.Options.InputPath);
    if State.Options.DependencyFile <> '' then
      ModuleLoaderWriteDependencyFile(State.ModuleLoader,
        State.Options.DependencyFile, State.Options.OutputPath);
    if (State.Source = '') or DiagnosticsFailed(State) then
    begin
      FlushDiagnostics(State);
      Exit(1);
    end;
    if State.Options.DumpTokens then DumpTokenStream(State);

    EnterStage(State, csParsing);
    ParserInit(State.Parser, PAnsiChar(State.Source), Length(State.Source),
      State.Tree, State.Symbols, State.Diagnostics, State.Options);
    ParseCompilationUnit(State.Parser);
    if not HasErrors(State.Diagnostics) then ASTVerify(State.Tree);
    if State.Options.DumpAST then ASTDump(State.Tree);
    if DiagnosticsFailed(State) then
    begin
      FlushDiagnostics(State);
      Exit(1);
    end;

    EnterStage(State, csSemanticAnalysis);
    SemanticInit(State.Semantic, State.Tree, State.Symbols,
      State.Diagnostics, State.Options);
    AnalyzeCompilationUnit(State.Semantic);
    if State.Options.DumpSymbols then SymDump(State.Symbols);
    if DiagnosticsFailed(State) then
    begin
      FlushDiagnostics(State);
      Exit(1);
    end;

    if State.Options.EmitKind = ekCheck then
    begin
      FlushDiagnostics(State);
      if State.ShowStats then PrintStatistics(State);
      if not State.Quiet then
        Writeln('fsim: ok  ', State.Options.InputPath);
      Exit(0);
    end;

    EnterStage(State, csIRLowering);
    IRBuilderInit(State.IRBuilder, State.IR, State.Tree, State.Symbols,
      State.Diagnostics, State.Options);
    LowerCompilationUnit(State.IRBuilder);
    if DiagnosticsFailed(State) then
    begin
      FlushDiagnostics(State);
      Exit(1);
    end;

    EnterStage(State, csOptimization);
    OptimizeProgram(State.IR, State.Symbols, State.Options,
      State.Diagnostics, State.OptimizationStats);
    if State.Options.DumpIR then IRDump(State.IR, State.Symbols);
    if DiagnosticsFailed(State) then
    begin
      FlushDiagnostics(State);
      Exit(1);
    end;
    if State.Options.EmitKind = ekIR then
    begin
      FlushDiagnostics(State);
      if State.ShowStats then PrintStatistics(State);
      Exit(0);
    end;

    EnterStage(State, csRegisterAllocation);
    AllocateRegisters(State.IR, State.Allocation);
    if State.Options.DumpRegAlloc then
      DumpRegisterAllocation(State.IR, State.Allocation);

    EnterStage(State, csNativeCodeGeneration);
    BuildNativeImage(State.IR, State.Symbols, State.Allocation,
      State.Options, State.Diagnostics, State.NativeImage);
    if DiagnosticsFailed(State) then
    begin
      FlushDiagnostics(State);
      Exit(1);
    end;
    EnterStage(State, csOutputWriting);
    WriteNativeOutput(State.NativeImage, State.Options);
    FlushDiagnostics(State);
    if State.ShowStats then PrintStatistics(State);
    if not State.Quiet then
      Writeln('fsim: ', State.Options.InputPath, ' -> ', State.Options.OutputPath);
    Result := 0;
  finally
    ClearPipeline(State);
  end;
end;

function RunCompiler(const Config: TCommandLine): Integer;
var
  State: TDriverState;
begin
  State := Default(TDriverState);
  State.Options := Config.Options;
  State.ShowStats := Config.ShowStats;
  State.Quiet := Config.Quiet;
  State.TraceStages := Config.TraceStages;
  State.Stage := csStartup;
  try
    Result := RunPipeline(State);
  except
    on E: Exception do
    begin
      Writeln(StdErr, 'fsim: internal error in ', CompilerStageName(State.Stage),
        ': ', E.Message);
      if State.Options.InputPath <> '' then
        Writeln(StdErr, 'fsim: input was ', State.Options.InputPath);
      Result := 3;
    end;
  end;
end;

end.

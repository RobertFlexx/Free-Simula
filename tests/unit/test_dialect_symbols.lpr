program test_dialect_symbols;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

uses
  SysUtils, core, diagnostics, symbols;

procedure Fail(Code: Integer; const MessageText: RawByteString);
begin
  Writeln(StdErr, 'dialect symbol test failed: ', MessageText);
  Halt(Code);
end;

var
  TestDiagnostics: TDiagnosticBag;
  StrictSymbols, ModernSymbols: TSymbolTable;
  LowerId, UpperId, FutureA, FutureB, RefClass, RefA, RefB,
  CPtrA, CPtrB, CFnA, CFnB, CParamStart: Int32;
begin
  DiagnosticsInit(TestDiagnostics);
  SymTableInit(StrictSymbols, TestDiagnostics, fdSimula67);
  SymTableInit(ModernSymbols, TestDiagnostics, fdFSim);
  try
    LowerId := SymLookup(StrictSymbols, 'sysout');
    UpperId := SymLookup(StrictSymbols, 'SYSOUT');
    if LowerId < 0 then Fail(1, 'strict environment did not inject sysout');
    if UpperId <> LowerId then Fail(2, 'strict lookup is not case-insensitive');
    if SymLookup(StrictSymbols, 'BlAnKs') < 0 then
      Fail(3, 'strict environment did not inject blanks');
    if SymLookup(StrictSymbols, 'Simulation') < 0 then
      Fail(4, 'strict environment did not inject Simulation');

    if SymLookup(ModernSymbols, 'sysout') >= 0 then
      Fail(5, 'legacy sysout leaked into -std=fsim');
    if SymLookup(ModernSymbols, 'blanks') >= 0 then
      Fail(6, 'legacy blanks leaked into -std=fsim');
    if SymLookupClass(ModernSymbols, 'Simulation') < 0 then
      Fail(7, 'classic Simulation compatibility class missing from -std=fsim');
    if SymLookup(ModernSymbols, 'atomic_load') < 0 then
      Fail(8, 'modern atomic runtime was not injected');
    if SymLookup(StrictSymbols, 'atomic_load') >= 0 then
      Fail(9, 'modern atomic runtime leaked into -std=simula67');
    if SymLookup(ModernSymbols, 'c_int') < 0 then
      Fail(14, 'modern C ABI types were not injected');
    if SymLookup(ModernSymbols, 'c_fn') < 0 then
      Fail(15, 'modern C function-pointer type was not injected');
    if SymLookup(StrictSymbols, 'c_int') >= 0 then
      Fail(16, 'C ABI type c_int leaked into -std=simula67');
    if SymLookup(StrictSymbols, 'c_ptr') >= 0 then
      Fail(17, 'C ABI type c_ptr leaked into -std=simula67');
    if ModernSymbols.Types[FSIM_TYPE_C_INT].Size <> 4 then
      Fail(18, 'c_int is not 32-bit on the SysV AMD64 target');
    if ModernSymbols.Types[FSIM_TYPE_C_LONG].Size <> 8 then
      Fail(19, 'c_long is not LP64 on the SysV AMD64 target');
    if ModernSymbols.Types[FSIM_TYPE_C_PTR].Size <> 8 then
      Fail(20, 'C pointer is not 64-bit on the AMD64 target');

    CPtrA := SymMakeCPointerType(ModernSymbols, FSIM_TYPE_C_INT);
    CPtrB := SymMakeCPointerType(ModernSymbols, FSIM_TYPE_C_INT);
    if not SymTypeEqual(ModernSymbols, CPtrA, CPtrB) then
      Fail(21, 'c_ptr(c_int) type identity is not structural');
    CParamStart := Length(ModernSymbols.Parameters);
    SymAddParameter(ModernSymbols, '', FSIM_TYPE_C_INT, pmValue,
      FSIM_INVALID_INDEX, FSIM_INVALID_INDEX);
    CFnA := SymMakeCFunctionType(ModernSymbols, FSIM_TYPE_C_INT,
      CParamStart, 1, False);
    CFnB := SymMakeCFunctionType(ModernSymbols, FSIM_TYPE_C_INT,
      CParamStart, 1, False);
    if not SymTypeEqual(ModernSymbols, CFnA, CFnB) then
      Fail(22, 'typed C function-pointer identity is not structural');

    FutureA := SymMakeFutureType(ModernSymbols, FSIM_TYPE_INTEGER);
    FutureB := SymMakeFutureType(ModernSymbols, FSIM_TYPE_INTEGER);
    if not SymTypeEqual(ModernSymbols, FutureA, FutureB) then
      Fail(10, 'future(integer) type identity is not structural');
    if not SymCanAssign(ModernSymbols, FutureA, FutureB, True) then
      Fail(11, 'future(integer) reference assignment rejects itself');

    RefClass := SymLookupClass(ModernSymbols, 'does_not_exist');
    if RefClass >= 0 then Fail(12, 'impossible class lookup succeeded');
    RefA := FSIM_TYPE_MUTEX;
    RefB := FSIM_TYPE_MUTEX;
    if not SymTypeEqual(ModernSymbols, RefA, RefB) then
      Fail(13, 'builtin reference-like type does not equal itself');
  finally
    SymTableClear(StrictSymbols);
    SymTableClear(ModernSymbols);
    DiagnosticsClear(TestDiagnostics);
  end;
end.

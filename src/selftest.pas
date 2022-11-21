unit selftest;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

function RunSelfTest: Integer;

implementation

uses
  core, diagnostics, symbols;

function RunSelfTest: Integer;
var
  Diag: TDiagnosticBag;
  Table: TSymbolTable;
begin
  Result := 1;
  if HashString('Integer') <> UInt32($D9A953E5) then
  begin
    Writeln(StdErr, 'fsim: self-test: hash check failed');
    Exit;
  end;
  if HashString('_start') <> UInt32($9F3231DE) then
  begin
    Writeln(StdErr, 'fsim: self-test: entry hash check failed');
    Exit;
  end;

  DiagnosticsInit(Diag);
  try
    SymTableInit(Table, Diag);
    try
      SymVerify(Table);
      if HasErrors(Diag) then
      begin
        Writeln(StdErr, 'fsim: self-test: symbol table failed');
        Exit;
      end;
      if Length(Table.Types) < FSIM_FIRST_USER_TYPE then
      begin
        Writeln(StdErr, 'fsim: self-test: built in types are incomplete');
        Exit;
      end;
    finally
      SymTableClear(Table);
    end;
  finally
    DiagnosticsClear(Diag);
  end;
  Writeln('fsim: self-test passed');
  Result := 0;
end;

end.

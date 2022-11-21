unit dialect;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  core, diagnostics;

procedure DialectValidateOptions(var Options: TCompilerOptions;
  var Diagnostics: TDiagnosticBag);

implementation

procedure DialectValidateOptions(var Options: TCompilerOptions;
  var Diagnostics: TDiagnosticBag);
var
  EmptySpan: TSourceSpan;
begin
  EmptySpan := Default(TSourceSpan);
  if Options.Dialect <> fdSimula67 then Exit;

  { classic mode means classic mode. silently letting modern runtime bits leak in
    here made strict testing pretty damn meaningless. }
  if Options.ThreadingEnabled then
  begin
    AddWarning(Diagnostics, dcDialectViolation, EmptySpan,
      'native threading disabled by -std=simula67');
    Options.ThreadingEnabled := False;
  end;
  if Options.ExceptionsEnabled then
  begin
    AddWarning(Diagnostics, dcDialectViolation, EmptySpan,
      'structured exceptions disabled by -std=simula67');
    Options.ExceptionsEnabled := False;
  end;
end;

end.

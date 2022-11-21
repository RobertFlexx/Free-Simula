program fsim;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

uses
  cli, driver, selftest;

var
  Config: TCommandLine;
begin
  ParseCommandLine(Config);
  if Config.ShowHelp then
  begin
    PrintHelp;
    Halt(0);
  end;
  if Config.ShowVersion then
  begin
    PrintVersion;
    Halt(0);
  end;
  if Config.ShowSelfTest then Halt(RunSelfTest);
  Halt(RunCompiler(Config));
end.

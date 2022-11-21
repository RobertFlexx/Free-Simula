unit cli;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, core;

type
  TCommandLine = record
    Options: TCompilerOptions;
    ShowHelp: Boolean;
    ShowVersion: Boolean;
    ShowSelfTest: Boolean;
    ShowStats: Boolean;
    Quiet: Boolean;
    TraceStages: Boolean;
  end;

procedure ParseCommandLine(out Config: TCommandLine);
procedure PrintHelp;
procedure PrintVersion;

implementation

procedure PrintVersion;
begin
  Writeln('fsim ', FSIM_VERSION_STRING, ' (', FSIM_TARGET_TRIPLE, ')');
end;

procedure PrintHelp;
begin
  Writeln('fsim ', FSIM_VERSION_STRING, '  free simula compiler');
  Writeln;
  Writeln('usage: fsim [options] file.sim');
  Writeln;
  Writeln('language');
  Writeln('  -std=fsim          simula plus the modern dialect  default');
  Writeln('  -std=simula67      strict classic source checks');
  Writeln;
  Writeln('build');
  Writeln('  -o FILE            output file  default a.out');
  Writeln('  --check            parse and type check only');
  Writeln('  -S                 write assembly form');
  Writeln('  -O0 .. -O3         optimization level');
  Writeln('  -Ofast             faster math and fewer overflow checks');
  Writeln('  -I DIR             add an import path');
  Writeln('  --stdlib-path=DIR  use a different standard library');
  Writeln('  --no-stdlib        do not search the standard library');
  Writeln('  --dynamic-linker=P override ELF interpreter for C FFI binaries');
  Writeln('  --c-runtime=LIB    C runtime used for orderly FFI process exit');
  Writeln('  --c-raw-exit       keep raw syscall exit even when C FFI is used');
  Writeln('  -g                 keep debug symbols');
  Writeln('  -s                 strip optional symbols');
  Writeln;
  Writeln('diagnostics');
  Writeln('  -Werror            warnings are errors');
  Writeln('  --diagnostics=json emit json diagnostics');
  Writeln('  --color            force color');
  Writeln('  --no-color         never use color');
  Writeln('  -q, --quiet        no success message');
  Writeln;
  Writeln('other');
  Writeln('  --version          print version');
  Writeln('  -h, --help         print this help');
end;

procedure CommandLineError(const MessageText: RawByteString);
begin
  Writeln(StdErr, 'fsim: ', MessageText);
  Writeln(StdErr, 'try fsim --help');
  Halt(2);
end;

function StartsWith(const Value, Prefix: RawByteString): Boolean; inline;
begin
  Result := (Length(Value) >= Length(Prefix)) and
    (Copy(Value, 1, Length(Prefix)) = Prefix);
end;

function DefaultOutputFor(const InputPath, Extension: RawByteString): RawByteString;
var
  Directory, BaseName: RawByteString;
begin
  Directory := ExtractFilePath(InputPath);
  BaseName := ChangeFileExt(ExtractFileName(InputPath), '');
  Result := Directory + BaseName + Extension;
end;

procedure AddOptionSearchPath(var Options: TCompilerOptions;
  const Path: RawByteString);
var
  I, N: SizeInt;
  Expanded: RawByteString;
begin
  if Path = '' then Exit;
  Expanded := ExpandFileName(Path);
  for I := 0 to High(Options.ModuleSearchPaths) do
    if ASCIIEqualFold(Options.ModuleSearchPaths[I], Expanded) then Exit;
  N := Length(Options.ModuleSearchPaths);
  SetLength(Options.ModuleSearchPaths, N + 1);
  Options.ModuleSearchPaths[N] := Expanded;
end;

procedure AddSearchPathList(var Options: TCompilerOptions;
  const Paths: RawByteString);
var
  I, Start: SizeInt;
  Separator: AnsiChar;
  Item: RawByteString;
begin
{$IFDEF WINDOWS}
  Separator := ';';
{$ELSE}
  Separator := ':';
{$ENDIF}
  Start := 1;
  I := 1;
  while I <= Length(Paths) do
  begin
    if Paths[I] = Separator then
    begin
      Item := Copy(Paths, Start, I - Start);
      if Item <> '' then AddOptionSearchPath(Options, Item);
      Start := I + 1;
    end;
    Inc(I);
  end;
  Item := Copy(Paths, Start, Length(Paths) - Start + 1);
  if Item <> '' then AddOptionSearchPath(Options, Item);
end;

procedure ValidateTarget(const TargetName: RawByteString);
var
  Lower: RawByteString;
begin
  Lower := LowerASCII(TargetName);
  if (Lower <> LowerASCII(FSIM_TARGET_TRIPLE)) and
     (Lower <> 'x86_64-linux') and (Lower <> 'amd64-linux') then
    CommandLineError('unsupported target ''' + TargetName + '''');
end;

procedure ParseCommandLine(out Config: TCommandLine);
var
  I: Integer;
  Arg, Value: RawByteString;
  OutputExplicit, AutoDependencyFile: Boolean;
begin
  Config := Default(TCommandLine);
  InitCompilerOptions(Config.Options);
  if (GetEnvironmentVariable('NO_COLOR') <> '') or
     ASCIIEqualFold(GetEnvironmentVariable('TERM'), 'dumb') then
    Config.Options.ColorDiagnostics := False;

  OutputExplicit := False;
  AutoDependencyFile := False;
  AddSearchPathList(Config.Options, GetEnvironmentVariable('FSIM_PATH'));
  I := 1;
  while I <= ParamCount do
  begin
    Arg := ParamStr(I);
    if (Arg = '-h') or (Arg = '--help') then
      Config.ShowHelp := True
    else if Arg = '--version' then
      Config.ShowVersion := True
    else if Arg = '--self-test' then
      Config.ShowSelfTest := True
    else if StartsWith(Arg, '-std=') then
    begin
      Value := LowerASCII(Copy(Arg, 6, MaxInt));
      if Value = 'simula67' then
      begin
        Config.Options.Dialect := fdSimula67;
        Config.Options.ThreadingEnabled := False;
        Config.Options.ExceptionsEnabled := False;
      end
      else if Value = 'fsim' then
      begin
        Config.Options.Dialect := fdFSim;
        Config.Options.ThreadingEnabled := True;
        Config.Options.ExceptionsEnabled := True;
      end
      else
        CommandLineError('unknown language dialect ''' + Value + '''');
    end
    else if Arg = '-I' then
    begin
      Inc(I);
      if I > ParamCount then CommandLineError('-I needs a directory');
      AddOptionSearchPath(Config.Options, ParamStr(I));
    end
    else if StartsWith(Arg, '-I') and (Length(Arg) > 2) then
      AddOptionSearchPath(Config.Options, Copy(Arg, 3, MaxInt))
    else if StartsWith(Arg, '--stdlib-path=') then
      Config.Options.StandardLibraryPath := Copy(Arg, 16, MaxInt)
    else if Arg = '--no-stdlib' then
      Config.Options.UseStandardLibrary := False
    else if Arg = '--print-search-dirs' then
      Config.Options.PrintSearchDirs := True
    else if Arg = '--print-features' then
      Config.Options.PrintFeatures := True { old scripts used this, keep it quiet and boring }
    else if Arg = '-MD' then
      AutoDependencyFile := True
    else if Arg = '-MF' then
    begin
      Inc(I);
      if I > ParamCount then CommandLineError('-MF needs a file');
      Config.Options.DependencyFile := ParamStr(I);
    end
    else if StartsWith(Arg, '--depfile=') then
      Config.Options.DependencyFile := Copy(Arg, 11, MaxInt)
    else if Arg = '-o' then
    begin
      Inc(I);
      if I > ParamCount then CommandLineError('-o needs a file');
      Config.Options.OutputPath := ParamStr(I);
      OutputExplicit := True;
    end
    else if StartsWith(Arg, '-o') and (Length(Arg) > 2) then
    begin
      Config.Options.OutputPath := Copy(Arg, 3, MaxInt);
      OutputExplicit := True;
    end
    else if Arg = '-S' then
      Config.Options.EmitKind := ekAssembly
    else if Arg = '--emit-raw' then
      Config.Options.EmitKind := ekRawBytes
    else if Arg = '--emit-ir' then
    begin
      Config.Options.EmitKind := ekIR;
      Config.Options.DumpIR := True;
    end
    else if Arg = '--check' then
      Config.Options.EmitKind := ekCheck
    else if StartsWith(Arg, '--target=') then
    begin
      Config.Options.TargetTriple := Copy(Arg, 10, MaxInt);
      ValidateTarget(Config.Options.TargetTriple);
    end
    else if StartsWith(Arg, '--dynamic-linker=') then
    begin
      Config.Options.DynamicLinker := Copy(Arg, 18, MaxInt);
      if Config.Options.DynamicLinker = '' then
        CommandLineError('--dynamic-linker needs a path');
    end
    else if StartsWith(Arg, '--c-runtime=') then
    begin
      Config.Options.CRuntimeLibrary := Copy(Arg, 13, MaxInt);
      if Config.Options.CRuntimeLibrary = '' then
        CommandLineError('--c-runtime needs a library name or path');
    end
    else if Arg = '--c-raw-exit' then
      Config.Options.CRuntimeLibrary := ''
    else if Arg = '-O0' then Config.Options.Optimization := ol0
    else if Arg = '-O1' then Config.Options.Optimization := ol1
    else if Arg = '-O2' then Config.Options.Optimization := ol2
    else if Arg = '-O3' then Config.Options.Optimization := ol3
    else if Arg = '-Ofast' then
    begin
      Config.Options.Optimization := olFast;
      Config.Options.OverflowChecks := False;
    end
    else if StartsWith(Arg, '--diagnostics=') then
    begin
      Value := LowerASCII(Copy(Arg, 15, MaxInt));
      if Value = 'text' then Config.Options.DiagnosticFormat := dgText
      else if Value = 'json' then
      begin
        Config.Options.DiagnosticFormat := dgJSON;
        Config.Options.ColorDiagnostics := False;
      end
      else CommandLineError('unknown diagnostic format ''' + Value + '''');
    end
    else if Arg = '--dump-tokens' then Config.Options.DumpTokens := True
    else if Arg = '--dump-ast' then Config.Options.DumpAST := True
    else if Arg = '--dump-symbols' then Config.Options.DumpSymbols := True
    else if Arg = '--dump-regalloc' then Config.Options.DumpRegAlloc := True
    else if Arg = '--verify-each-pass' then Config.Options.VerifyEachPass := True
    else if Arg = '--stats' then Config.ShowStats := True
    else if Arg = '--trace-stages' then Config.TraceStages := True
    else if Arg = '-Werror' then Config.Options.WarningsAsErrors := True
    else if Arg = '-g' then Config.Options.DebugInfo := True
    else if Arg = '-s' then Config.Options.StripSymbols := True
    else if (Arg = '-q') or (Arg = '--quiet') then Config.Quiet := True
    else if Arg = '--no-color' then Config.Options.ColorDiagnostics := False
    else if Arg = '--color' then Config.Options.ColorDiagnostics := True
    else if Arg = '--no-bounds-checks' then Config.Options.BoundsChecks := False
    else if Arg = '--no-overflow-checks' then Config.Options.OverflowChecks := False
    else if Arg = '--no-null-checks' then Config.Options.NullChecks := False
    else if Arg = '--no-rtti-checks' then Config.Options.RTTIChecks := False
    else if Arg = '--no-threads' then Config.Options.ThreadingEnabled := False
    else if Arg = '--no-exceptions' then Config.Options.ExceptionsEnabled := False
    else if StartsWith(Arg, '--entry=') then
      Config.Options.EntrySymbol := Copy(Arg, 9, MaxInt)
    else if (Length(Arg) > 0) and (Arg[1] = '-') then
      CommandLineError('unknown option ''' + Arg + '''')
    else if Config.Options.InputPath = '' then
      Config.Options.InputPath := Arg
    else
      CommandLineError('only one input file is supported');
    Inc(I);
  end;

  if Config.ShowHelp or Config.ShowVersion or Config.ShowSelfTest then Exit;
  if not (Config.Options.PrintSearchDirs or Config.Options.PrintFeatures) then
  begin
    if Config.Options.InputPath = '' then CommandLineError('no input file');
    if not FileExists(Config.Options.InputPath) then
      CommandLineError('input file not found: ' + Config.Options.InputPath);
  end;

  if not OutputExplicit then
    case Config.Options.EmitKind of
      ekAssembly: Config.Options.OutputPath :=
        DefaultOutputFor(Config.Options.InputPath, '.s');
      ekRawBytes: Config.Options.OutputPath :=
        DefaultOutputFor(Config.Options.InputPath, '.bin');
    else
      Config.Options.OutputPath := 'a.out';
    end;
  if AutoDependencyFile and (Config.Options.DependencyFile = '') then
    Config.Options.DependencyFile := Config.Options.OutputPath + '.d';
end;

end.

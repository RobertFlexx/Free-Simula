unit imports;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}
{$pointermath on}

interface

uses
  SysUtils, Classes, core, diagnostics;

type
  TModuleState = (msUnseen, msLoading, msLoaded, msFailed);

  TModuleRecord = packed record
    PathId: Int32;
    State: TModuleState;
    SourceOffset: UInt32;
    SourceLength: UInt32;
    ImportCount: UInt32;
  end;

  TModuleLoader = record
    Strings: TStringPool;
    Modules: array of TModuleRecord;
    SearchPaths: array of RawByteString;
    CombinedSource: TByteBuffer;
    Diagnostics: ^TDiagnosticBag;
    Dialect: TFSimDialect;
  end;

procedure ModuleLoaderInit(var Loader: TModuleLoader;
  var Diagnostics: TDiagnosticBag; Dialect: TFSimDialect);
procedure ModuleLoaderClear(var Loader: TModuleLoader);
procedure ModuleLoaderAddSearchPath(var Loader: TModuleLoader;
  const Path: RawByteString);
function ModuleLoaderLoad(var Loader: TModuleLoader;
  const MainPath: RawByteString): RawByteString;
procedure ModuleLoaderWriteDependencyFile(const Loader: TModuleLoader;
  const DependencyPath, TargetPath: RawByteString);
procedure ModuleLoaderPrintSearchPaths(const Loader: TModuleLoader);

implementation

type
  TImportRecord = record
    Path: RawByteString;
    StartOffset: SizeInt;
    EndOffset: SizeInt;
    Line: UInt32;
    Column: UInt32;
  end;

  TImportArray = array of TImportRecord;

function IsAbsolutePath(const Path: RawByteString): Boolean;
begin
{$IFDEF WINDOWS}
  Result := (Length(Path) >= 3) and (Path[2] = ':') and
    (Path[3] in ['\', '/']);
{$ELSE}
  Result := (Path <> '') and (Path[1] = '/');
{$ENDIF}
end;

function IsIdentifierStart(C: AnsiChar): Boolean; inline;
begin
  Result := (C = '_') or (C in ['A'..'Z', 'a'..'z']);
end;

function IsIdentifierContinue(C: AnsiChar): Boolean; inline;
begin
  Result := IsIdentifierStart(C) or (C in ['0'..'9']);
end;

procedure AdvancePosition(C: AnsiChar; var Line, Column: UInt32); inline;
begin
  if C = #10 then
  begin
    Inc(Line);
    Column := 1;
  end
  else
    Inc(Column);
end;

function DecodeQuotedPath(const Source: RawByteString; StartOffset: SizeInt;
  out EndOffset: SizeInt; out Value: RawByteString): Boolean;
var
  I: SizeInt;
  Quote, Escaped: AnsiChar;
begin
  Result := False;
  Value := '';
  EndOffset := StartOffset;
  if (StartOffset < 1) or (StartOffset > Length(Source)) or
     not (Source[StartOffset] in ['''', '"']) then
    Exit;
  Quote := Source[StartOffset];
  I := StartOffset + 1;
  while I <= Length(Source) do
  begin
    if Source[I] = Quote then
    begin
      EndOffset := I + 1;
      Exit(True);
    end;
    if Source[I] = '\' then
    begin
      Inc(I);
      if I > Length(Source) then Exit;
      case Source[I] of
        'n': Escaped := #10;
        'r': Escaped := #13;
        't': Escaped := #9;
        '\': Escaped := '\';
        '''': Escaped := '''';
        '"': Escaped := '"';
      else
        Escaped := Source[I];
      end;
      Value := Value + Escaped;
    end
    else
      Value := Value + Source[I];
    Inc(I);
  end;
end;

function DecodeModuleName(const Source: RawByteString; StartOffset: SizeInt;
  out EndOffset: SizeInt; out Value: RawByteString): Boolean;
var
  I: SizeInt;
  SegmentStart: Boolean;
begin
  Result := False;
  Value := '';
  EndOffset := StartOffset;
  I := StartOffset;
  SegmentStart := True;
  while I <= Length(Source) do
  begin
    if SegmentStart then
    begin
      if not IsIdentifierStart(Source[I]) then Exit;
      SegmentStart := False;
    end;
    while (I <= Length(Source)) and IsIdentifierContinue(Source[I]) do
    begin
      Value := Value + Source[I];
      Inc(I);
    end;
    if (I <= Length(Source)) and (Source[I] = '.') then
    begin
      Value := Value + PathDelim;
      Inc(I);
      SegmentStart := True;
      Continue;
    end;
    Break;
  end;
  if SegmentStart or (Value = '') then Exit;
  EndOffset := I;
  Result := True;
end;

procedure AddImport(var Imports: TImportArray; const Path: RawByteString;
  StartOffset, EndOffset: SizeInt; Line, Column: UInt32);
var
  N: SizeInt;
begin
  N := Length(Imports);
  SetLength(Imports, N + 1);
  Imports[N] := Default(TImportRecord);
  Imports[N].Path := Path;
  Imports[N].StartOffset := StartOffset;
  Imports[N].EndOffset := EndOffset;
  Imports[N].Line := Line;
  Imports[N].Column := Column;
end;

procedure SkipWhitespace(const Source: RawByteString; var Offset: SizeInt;
  var Line, Column: UInt32);
begin
  while (Offset <= Length(Source)) and (Source[Offset] <= ' ') do
  begin
    AdvancePosition(Source[Offset], Line, Column);
    Inc(Offset);
  end;
end;

procedure AdvanceRange(const Source: RawByteString; var Offset: SizeInt;
  PastEnd: SizeInt; var Line, Column: UInt32);
begin
  while (Offset < PastEnd) and (Offset <= Length(Source)) do
  begin
    AdvancePosition(Source[Offset], Line, Column);
    Inc(Offset);
  end;
end;

procedure ScanImports(const Source: RawByteString; out Imports: TImportArray;
  out ModuleDeclStart, ModuleDeclEnd: SizeInt; out ModuleName: RawByteString);
var
  I, Start, WordLength, ValueEnd, ModuleNameStart: SizeInt;
  Line, Column, StartLine, StartColumn: UInt32;
  C, Quote: AnsiChar;
  Value, WordText: RawByteString;
  InComment: Boolean;
begin
  SetLength(Imports, 0);
  ModuleDeclStart := 0;
  ModuleDeclEnd := 0;
  ModuleName := '';
  I := 1;
  Line := 1;
  Column := 1;
  InComment := False;
  while I <= Length(Source) do
  begin
    C := Source[I];
    if InComment then
    begin
      AdvancePosition(C, Line, Column);
      Inc(I);
      if C = ';' then InComment := False;
      Continue;
    end;
    if C = '!' then
    begin
      InComment := True;
      AdvancePosition(C, Line, Column);
      Inc(I);
      Continue;
    end;
    if C in ['''', '"'] then
    begin
      Quote := C;
      AdvancePosition(C, Line, Column);
      Inc(I);
      while I <= Length(Source) do
      begin
        C := Source[I];
        AdvancePosition(C, Line, Column);
        Inc(I);
        if C = '\' then
        begin
          if I <= Length(Source) then
          begin
            AdvancePosition(Source[I], Line, Column);
            Inc(I);
          end;
        end
        else if C = Quote then
          Break;
      end;
      Continue;
    end;
    if IsIdentifierStart(C) then
    begin
      Start := I;
      StartLine := Line;
      StartColumn := Column;
      while (I <= Length(Source)) and IsIdentifierContinue(Source[I]) do
      begin
        AdvancePosition(Source[I], Line, Column);
        Inc(I);
      end;
      WordLength := I - Start;
      WordText := Copy(Source, Start, WordLength);
      if ASCIIEqualFold(WordText, 'comment') then
      begin
        InComment := True;
        Continue;
      end;
      if ASCIIEqualFold(WordText, 'module') and (ModuleDeclStart = 0) then
      begin
        SkipWhitespace(Source, I, Line, Column);
        if (I <= Length(Source)) and IsIdentifierStart(Source[I]) then
        begin
          ModuleNameStart := I;
          while (I <= Length(Source)) and
                (IsIdentifierContinue(Source[I]) or (Source[I] = '.')) do
          begin
            AdvancePosition(Source[I], Line, Column);
            Inc(I);
          end;
          ModuleName := Copy(Source, ModuleNameStart, I - ModuleNameStart);
          SkipWhitespace(Source, I, Line, Column);
          if (I <= Length(Source)) and (Source[I] = ';') then
          begin
            AdvancePosition(Source[I], Line, Column);
            Inc(I);
            ModuleDeclStart := Start;
            ModuleDeclEnd := I;
          end;
        end;
        Continue;
      end;
      if ASCIIEqualFold(WordText, 'import') then
      begin
        SkipWhitespace(Source, I, Line, Column);
        Value := '';
        ValueEnd := I;
        if (I <= Length(Source)) and (Source[I] in ['''', '"']) then
        begin
          if DecodeQuotedPath(Source, I, ValueEnd, Value) then
            AdvanceRange(Source, I, ValueEnd, Line, Column);
        end
        else if (I <= Length(Source)) and IsIdentifierStart(Source[I]) then
        begin
          if DecodeModuleName(Source, I, ValueEnd, Value) then
          begin
            AdvanceRange(Source, I, ValueEnd, Line, Column);
            if ExtractFileExt(Value) = '' then
              Value := LowerASCII(Value) + '.sim';
          end;
        end;
        SkipWhitespace(Source, I, Line, Column);
        if (Value <> '') and (I <= Length(Source)) and (Source[I] = ';') then
        begin
          AdvancePosition(Source[I], Line, Column);
          Inc(I);
          AddImport(Imports, Value, Start, I, StartLine, StartColumn);
        end;
      end;
      Continue;
    end;
    AdvancePosition(C, Line, Column);
    Inc(I);
  end;
end;

procedure ModuleLoaderInit(var Loader: TModuleLoader;
  var Diagnostics: TDiagnosticBag; Dialect: TFSimDialect);
begin
  Loader := Default(TModuleLoader);
  BufferInit(Loader.Strings.Bytes, 1024);
  BufferInit(Loader.CombinedSource, 4096);
  Loader.Diagnostics := @Diagnostics;
  Loader.Dialect := Dialect;
end;

procedure ModuleLoaderClear(var Loader: TModuleLoader);
begin
  SetLength(Loader.Modules, 0);
  SetLength(Loader.SearchPaths, 0);
  SetLength(Loader.Strings.Entries, 0);
  BufferClear(Loader.Strings.Bytes);
  BufferClear(Loader.CombinedSource);
  Loader.Diagnostics := nil;
end;

procedure ModuleLoaderAddSearchPath(var Loader: TModuleLoader;
  const Path: RawByteString);
var
  I, N: SizeInt;
  Expanded: RawByteString;
begin
  if Path = '' then Exit;
  Expanded := IncludeTrailingPathDelimiter(ExpandFileName(Path));
  for I := 0 to High(Loader.SearchPaths) do
    if ASCIIEqualFold(Loader.SearchPaths[I], Expanded) then Exit;
  N := Length(Loader.SearchPaths);
  SetLength(Loader.SearchPaths, N + 1);
  Loader.SearchPaths[N] := Expanded;
end;

function FindModule(const Loader: TModuleLoader;
  const CanonicalPath: RawByteString): Int32;
var
  I: SizeInt;
begin
  for I := 0 to High(Loader.Modules) do
    if ASCIIEqualFold(StringPoolGet(Loader.Strings,
      Loader.Modules[I].PathId), CanonicalPath) then
      Exit(I);
  Result := FSIM_INVALID_INDEX;
end;

function AddModule(var Loader: TModuleLoader;
  const CanonicalPath: RawByteString): Int32;
begin
  Result := Length(Loader.Modules);
  SetLength(Loader.Modules, Result + 1);
  Loader.Modules[Result] := Default(TModuleRecord);
  Loader.Modules[Result].PathId := StringPoolIntern(Loader.Strings,
    CanonicalPath);
  Loader.Modules[Result].State := msUnseen;
end;

function TryCandidate(const BasePath, RequestedPath: RawByteString;
  out Resolved: RawByteString): Boolean;
var
  Candidate, WithExtension, LowerCandidate: RawByteString;
begin
  Resolved := '';
  Candidate := ExpandFileName(IncludeTrailingPathDelimiter(BasePath) + RequestedPath);
  if FileExists(Candidate) then
  begin
    Resolved := Candidate;
    Exit(True);
  end;
  if ExtractFileExt(Candidate) = '' then
  begin
    WithExtension := Candidate + '.sim';
    if FileExists(WithExtension) then
    begin
      Resolved := ExpandFileName(WithExtension);
      Exit(True);
    end;
  end;
  LowerCandidate := IncludeTrailingPathDelimiter(ExtractFilePath(Candidate)) +
    LowerASCII(ExtractFileName(Candidate));
  if FileExists(LowerCandidate) then
  begin
    Resolved := ExpandFileName(LowerCandidate);
    Exit(True);
  end;
  if ExtractFileExt(LowerCandidate) = '' then
  begin
    WithExtension := LowerCandidate + '.sim';
    if FileExists(WithExtension) then
    begin
      Resolved := ExpandFileName(WithExtension);
      Exit(True);
    end;
  end;
  Result := False;
end;

function TryModuleDeclaration(const BasePath, RequestedPath: RawByteString;
  out Resolved: RawByteString): Boolean;
var
  Search: TSearchRec;
  Directory, Candidate, Wanted, Source, DeclaredName: RawByteString;
  Imports: TImportArray;
  ModuleStart, ModuleEnd: SizeInt;
begin
  Result := False;
  Resolved := '';
  Wanted := ChangeFileExt(ExtractFileName(RequestedPath), '');
  if Wanted = '' then Exit;
  Directory := IncludeTrailingPathDelimiter(BasePath);
  if FindFirst(Directory + '*.sim', faAnyFile and not faDirectory, Search) <> 0 then
    Exit;
  try
    repeat
      Candidate := ExpandFileName(Directory + Search.Name);
      try
        Source := LoadBinaryFile(Candidate);
      except
        Continue;
      end;
      ScanImports(Source, Imports, ModuleStart, ModuleEnd, DeclaredName);
      if (DeclaredName <> '') and ASCIIEqualFold(DeclaredName, Wanted) then
      begin
        Resolved := Candidate;
        Exit(True);
      end;
    until FindNext(Search) <> 0;
  finally
    FindClose(Search);
  end;
end;

function ResolveImport(const Loader: TModuleLoader; const ImporterPath,
  RequestedPath: RawByteString): RawByteString;
var
  I: SizeInt;
  BasePath, Candidate: RawByteString;
begin
  Result := '';
  if RequestedPath = '' then Exit;
  if IsAbsolutePath(RequestedPath) then
  begin
    Candidate := ExpandFileName(RequestedPath);
    if FileExists(Candidate) then Exit(Candidate);
    if (ExtractFileExt(Candidate) = '') and FileExists(Candidate + '.sim') then
      Exit(ExpandFileName(Candidate + '.sim'));
    Exit;
  end;
  BasePath := ExtractFilePath(ImporterPath);
  if TryCandidate(BasePath, RequestedPath, Candidate) then Exit(Candidate);
  if TryModuleDeclaration(BasePath, RequestedPath, Candidate) then Exit(Candidate);
  for I := 0 to High(Loader.SearchPaths) do
  begin
    if TryCandidate(Loader.SearchPaths[I], RequestedPath, Candidate) then
      Exit(Candidate);
    if TryModuleDeclaration(Loader.SearchPaths[I], RequestedPath, Candidate) then
      Exit(Candidate);
  end;
end;

procedure AppendSourceRange(var Destination: TByteBuffer;
  const Source: RawByteString; FirstOffset, PastEndOffset: SizeInt);
begin
  if FirstOffset < 1 then FirstOffset := 1;
  if PastEndOffset > Length(Source) + 1 then
    PastEndOffset := Length(Source) + 1;
  if PastEndOffset > FirstOffset then
    BufferAppend(Destination, Source[FirstOffset], PastEndOffset - FirstOffset);
end;

procedure AppendBoundaryComment(var Destination: TByteBuffer;
  const Prefix, Path: RawByteString);
var
  Text: RawByteString;
begin
  Text := LineEnding + '! ' + Prefix + ' ' + Path + ';' + LineEnding;
  if Text <> '' then
    BufferAppend(Destination, Text[1], Length(Text));
end;

function MakeSpan(Line, Column: UInt32): TSourceSpan;
begin
  Result.StartPos := SourcePos(Line, Column, 0);
  Result.EndPos := Result.StartPos;
end;

procedure LoadModuleRecursive(var Loader: TModuleLoader;
  const CanonicalPath: RawByteString);
var
  ModuleId, I: Int32;
  Source, ResolvedPath, DeclaredModuleName: RawByteString;
  Imports: TImportArray;
  ModuleStart, ModuleEnd, Cursor: SizeInt;
  ImportSpan: TSourceSpan;
begin
  ModuleId := FindModule(Loader, CanonicalPath);
  if ModuleId < 0 then ModuleId := AddModule(Loader, CanonicalPath);
  case Loader.Modules[ModuleId].State of
    msLoaded: Exit;
    msLoading:
      begin
        AddError(Loader.Diagnostics^, dcImportCycle, MakeSpan(1, 1),
          'cyclic module import involving ''' + CanonicalPath + '''');
        Loader.Modules[ModuleId].State := msFailed;
        Exit;
      end;
    msFailed: Exit;
  end;
  Loader.Modules[ModuleId].State := msLoading;
  try
    Source := LoadBinaryFile(CanonicalPath);
  except
    on E: Exception do
    begin
      AddError(Loader.Diagnostics^, dcImportNotFound, MakeSpan(1, 1),
        'cannot read module ''' + CanonicalPath + ''': ' + E.Message);
      Loader.Modules[ModuleId].State := msFailed;
      Exit;
    end;
  end;
  ScanImports(Source, Imports, ModuleStart, ModuleEnd, DeclaredModuleName);
  Loader.Modules[ModuleId].ImportCount := Length(Imports);
  for I := 0 to High(Imports) do
  begin
    ResolvedPath := ResolveImport(Loader, CanonicalPath, Imports[I].Path);
    if ResolvedPath = '' then
    begin
      ImportSpan := MakeSpan(Imports[I].Line, Imports[I].Column);
      AddError(Loader.Diagnostics^, dcImportNotFound, ImportSpan,
        'cannot resolve imported module ''' + Imports[I].Path +
        ''' from ''' + CanonicalPath + '''');
      Loader.Modules[ModuleId].State := msFailed;
    end
    else
    begin
      LoadModuleRecursive(Loader, ResolvedPath);
      if (FindModule(Loader, ResolvedPath) >= 0) and
         (Loader.Modules[FindModule(Loader, ResolvedPath)].State = msFailed) then
        Loader.Modules[ModuleId].State := msFailed;
    end;
  end;
  if Loader.Modules[ModuleId].State = msFailed then Exit;
  Loader.Modules[ModuleId].SourceOffset := Loader.CombinedSource.Count;
  AppendBoundaryComment(Loader.CombinedSource, 'begin source', CanonicalPath);
  Cursor := 1;
  if (ModuleStart > 0) and (ModuleEnd > ModuleStart) then
  begin
    AppendSourceRange(Loader.CombinedSource, Source, Cursor, ModuleStart);
    Cursor := ModuleEnd;
  end;
  for I := 0 to High(Imports) do
  begin
    if Imports[I].StartOffset >= Cursor then
      AppendSourceRange(Loader.CombinedSource, Source, Cursor,
        Imports[I].StartOffset);
    Cursor := Imports[I].EndOffset;
  end;
  AppendSourceRange(Loader.CombinedSource, Source, Cursor, Length(Source) + 1);
  { Do not put the keyword END in the synthetic trailer.  The classic lexer
    intentionally treats text after a bare END up to the next semicolon as an
    end-comment; a trailer named `end source` therefore surfaced its own END as
    a second source token.  The closing marker does not need the path because
    the opening marker already records it. }
  AppendBoundaryComment(Loader.CombinedSource, 'source boundary close', '');
  Loader.Modules[ModuleId].SourceLength := Loader.CombinedSource.Count -
    Loader.Modules[ModuleId].SourceOffset;
  Loader.Modules[ModuleId].State := msLoaded;
end;

function ModuleLoaderLoad(var Loader: TModuleLoader;
  const MainPath: RawByteString): RawByteString;
var
  CanonicalPath: RawByteString;
begin
  BufferClear(Loader.CombinedSource);
  SetLength(Loader.Modules, 0);
  SetLength(Loader.Strings.Entries, 0);
  BufferClear(Loader.Strings.Bytes);
  CanonicalPath := ExpandFileName(MainPath);
  ModuleLoaderAddSearchPath(Loader, ExtractFilePath(CanonicalPath));
  LoadModuleRecursive(Loader, CanonicalPath);
  SetLength(Result, Loader.CombinedSource.Count);
  if Loader.CombinedSource.Count > 0 then
    Move(Loader.CombinedSource.Data[0], Result[1], Loader.CombinedSource.Count);
end;

function EscapeMakePath(const Path: RawByteString): RawByteString;
var
  I: SizeInt;
begin
  Result := '';
  for I := 1 to Length(Path) do
    case Path[I] of
      ' ', '#', ':': Result := Result + '\' + Path[I];
      '$': Result := Result + '$$';
      '\': Result := Result + '/';
    else
      Result := Result + Path[I];
    end;
end;

procedure ModuleLoaderWriteDependencyFile(const Loader: TModuleLoader;
  const DependencyPath, TargetPath: RawByteString);
var
  Stream: TFileStream;
  I: SizeInt;
  Line, Path: RawByteString;
begin
  if DependencyPath = '' then Exit;
  Line := EscapeMakePath(TargetPath) + ':';
  for I := 0 to High(Loader.Modules) do
    if Loader.Modules[I].State = msLoaded then
    begin
      Path := StringPoolGet(Loader.Strings, Loader.Modules[I].PathId);
      Line := Line + ' ' + EscapeMakePath(Path);
    end;
  Line := Line + LineEnding;
  ForceDirectories(ExtractFileDir(ExpandFileName(DependencyPath)));
  Stream := TFileStream.Create(DependencyPath, fmCreate);
  try
    if Line <> '' then Stream.WriteBuffer(Line[1], Length(Line));
  finally
    Stream.Free;
  end;
end;

procedure ModuleLoaderPrintSearchPaths(const Loader: TModuleLoader);
var
  I: SizeInt;
begin
  for I := 0 to High(Loader.SearchPaths) do
    Writeln(Loader.SearchPaths[I]);
end;

end.

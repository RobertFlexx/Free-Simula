unit diagnostics;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, core;

type
  TDiagnosticCode = (
    dcNone,
    dcUnexpectedCharacter,
    dcUnterminatedComment,
    dcUnterminatedString,
    dcInvalidEscape,
    dcInvalidNumber,
    dcUnexpectedToken,
    dcExpectedToken,
    dcDuplicateSymbol,
    dcUnknownSymbol,
    dcUnknownType,
    dcImportNotFound,
    dcImportCycle,
    dcTypeMismatch,
    dcInvalidAssignment,
    dcInvalidReferenceAssignment,
    dcInvalidValueAssignment,
    dcInvalidPrefix,
    dcInheritanceCycle,
    dcVirtualOrder,
    dcVirtualMismatch,
    dcVisibilityViolation,
    dcDialectViolation,
    dcInvalidQua,
    dcInvalidCall,
    dcInvalidReturn,
    dcInvalidControlFlow,
    dcUnreachableCode,
    dcOverflow,
    dcDivisionByZero,
    dcBackendFailure,
    dcBackendUnsupported,
    dcInternalError
  );

  TDiagnostic = packed record
    Severity: TDiagnosticSeverity;
    Code: TDiagnosticCode;
    Span: TSourceSpan;
    MessageLength: UInt16;
    MessageText: array[0..FSIM_MAX_DIAGNOSTIC] of AnsiChar;
  end;

  TDiagnosticBag = record
    Items: array of TDiagnostic;
    ErrorCount: UInt32;
    WarningCount: UInt32;
    FatalCount: UInt32;
  end;

procedure DiagnosticsInit(var Bag: TDiagnosticBag);
procedure DiagnosticsClear(var Bag: TDiagnosticBag);
procedure AddDiagnostic(var Bag: TDiagnosticBag; Severity: TDiagnosticSeverity;
  Code: TDiagnosticCode; const Span: TSourceSpan; const MessageText: RawByteString);
procedure AddError(var Bag: TDiagnosticBag; Code: TDiagnosticCode;
  const Span: TSourceSpan; const MessageText: RawByteString);
procedure AddWarning(var Bag: TDiagnosticBag; Code: TDiagnosticCode;
  const Span: TSourceSpan; const MessageText: RawByteString);
procedure AddFatal(var Bag: TDiagnosticBag; Code: TDiagnosticCode;
  const Span: TSourceSpan; const MessageText: RawByteString);
function HasErrors(const Bag: TDiagnosticBag): Boolean; inline;
function SeverityName(Severity: TDiagnosticSeverity): RawByteString;
function DiagnosticCodeName(Code: TDiagnosticCode): RawByteString;
function DiagnosticMessage(const Diagnostic: TDiagnostic): RawByteString;
procedure PrintDiagnostics(const Bag: TDiagnosticBag; const FileName: RawByteString;
  UseColor: Boolean; WarningsAsErrors: Boolean);
procedure PrintDiagnosticsJSON(const Bag: TDiagnosticBag;
  const FileName: RawByteString; WarningsAsErrors: Boolean);

implementation

procedure DiagnosticsInit(var Bag: TDiagnosticBag);
begin
  Bag := Default(TDiagnosticBag);
end;

procedure DiagnosticsClear(var Bag: TDiagnosticBag);
begin
  SetLength(Bag.Items, 0);
  Bag.ErrorCount := 0;
  Bag.WarningCount := 0;
  Bag.FatalCount := 0;
end;

procedure AddDiagnostic(var Bag: TDiagnosticBag; Severity: TDiagnosticSeverity;
  Code: TDiagnosticCode; const Span: TSourceSpan; const MessageText: RawByteString);
var
  N: Integer;
  L: SizeInt;
begin
  N := Length(Bag.Items);
  SetLength(Bag.Items, N + 1);
  Bag.Items[N] := Default(TDiagnostic);
  Bag.Items[N].Severity := Severity;
  Bag.Items[N].Code := Code;
  Bag.Items[N].Span := Span;
  L := Length(MessageText);
  if L > FSIM_MAX_DIAGNOSTIC then
    L := FSIM_MAX_DIAGNOSTIC;
  Bag.Items[N].MessageLength := L;
  if L > 0 then
    Move(MessageText[1], Bag.Items[N].MessageText[0], L);
  case Severity of
    dsWarning: Inc(Bag.WarningCount);
    dsError: Inc(Bag.ErrorCount);
    dsFatal:
      begin
        Inc(Bag.ErrorCount);
        Inc(Bag.FatalCount);
      end;
  end;
end;

procedure AddError(var Bag: TDiagnosticBag; Code: TDiagnosticCode;
  const Span: TSourceSpan; const MessageText: RawByteString);
begin
  AddDiagnostic(Bag, dsError, Code, Span, MessageText);
end;

procedure AddWarning(var Bag: TDiagnosticBag; Code: TDiagnosticCode;
  const Span: TSourceSpan; const MessageText: RawByteString);
begin
  AddDiagnostic(Bag, dsWarning, Code, Span, MessageText);
end;

procedure AddFatal(var Bag: TDiagnosticBag; Code: TDiagnosticCode;
  const Span: TSourceSpan; const MessageText: RawByteString);
begin
  AddDiagnostic(Bag, dsFatal, Code, Span, MessageText);
end;

function HasErrors(const Bag: TDiagnosticBag): Boolean; inline;
begin
  Result := Bag.ErrorCount <> 0;
end;

function SeverityName(Severity: TDiagnosticSeverity): RawByteString;
begin
  case Severity of
    dsNote: Result := 'note';
    dsWarning: Result := 'warning';
    dsError: Result := 'error';
    dsFatal: Result := 'fatal error';
  else
    Result := 'diagnostic';
  end;
end;

function DiagnosticCodeName(Code: TDiagnosticCode): RawByteString;
begin
  case Code of
    dcNone: Result := 'none';
    dcUnexpectedCharacter: Result := 'unexpected-character';
    dcUnterminatedComment: Result := 'unterminated-comment';
    dcUnterminatedString: Result := 'unterminated-string';
    dcInvalidEscape: Result := 'invalid-escape';
    dcInvalidNumber: Result := 'invalid-number';
    dcUnexpectedToken: Result := 'unexpected-token';
    dcExpectedToken: Result := 'expected-token';
    dcDuplicateSymbol: Result := 'duplicate-symbol';
    dcUnknownSymbol: Result := 'unknown-symbol';
    dcUnknownType: Result := 'unknown-type';
    dcImportNotFound: Result := 'import-not-found';
    dcImportCycle: Result := 'import-cycle';
    dcTypeMismatch: Result := 'type-mismatch';
    dcInvalidAssignment: Result := 'invalid-assignment';
    dcInvalidReferenceAssignment: Result := 'invalid-reference-assignment';
    dcInvalidValueAssignment: Result := 'invalid-value-assignment';
    dcInvalidPrefix: Result := 'invalid-prefix';
    dcInheritanceCycle: Result := 'inheritance-cycle';
    dcVirtualOrder: Result := 'virtual-order';
    dcVirtualMismatch: Result := 'virtual-mismatch';
    dcVisibilityViolation: Result := 'visibility-violation';
    dcDialectViolation: Result := 'dialect-violation';
    dcInvalidQua: Result := 'invalid-qua';
    dcInvalidCall: Result := 'invalid-call';
    dcInvalidReturn: Result := 'invalid-return';
    dcInvalidControlFlow: Result := 'invalid-control-flow';
    dcUnreachableCode: Result := 'unreachable-code';
    dcOverflow: Result := 'overflow';
    dcDivisionByZero: Result := 'division-by-zero';
    dcBackendFailure: Result := 'backend-failure';
    dcBackendUnsupported: Result := 'backend-unsupported';
    dcInternalError: Result := 'internal-error';
  else
    Result := 'unknown';
  end;
end;

function DiagnosticMessage(const Diagnostic: TDiagnostic): RawByteString;
begin
  SetString(Result, PAnsiChar(@Diagnostic.MessageText[0]), Diagnostic.MessageLength);
end;

function ColorForSeverity(Severity: TDiagnosticSeverity): RawByteString;
begin
  case Severity of
    dsNote: Result := #27'[36m';
    dsWarning: Result := #27'[33m';
    dsError, dsFatal: Result := #27'[31m';
  else
    Result := '';
  end;
end;

procedure PrintDiagnostics(const Bag: TDiagnosticBag; const FileName: RawByteString;
  UseColor: Boolean; WarningsAsErrors: Boolean);
var
  I: Integer;
  D: TDiagnostic;
  EffectiveSeverity: TDiagnosticSeverity;
  Prefix, Reset: RawByteString;
begin
  for I := 0 to High(Bag.Items) do
  begin
    D := Bag.Items[I];
    EffectiveSeverity := D.Severity;
    if WarningsAsErrors and (EffectiveSeverity = dsWarning) then
      EffectiveSeverity := dsError;
    if UseColor then
    begin
      Prefix := ColorForSeverity(EffectiveSeverity);
      Reset := #27'[0m';
    end
    else
    begin
      Prefix := '';
      Reset := '';
    end;
    Write(StdErr, FileName, ':', D.Span.StartPos.Line, ':',
      D.Span.StartPos.Column, ': ', Prefix, SeverityName(EffectiveSeverity), Reset,
      ' [', DiagnosticCodeName(D.Code), ']: ', DiagnosticMessage(D));
    Writeln(StdErr);
  end;
end;

function JSONEscape(const Value: RawByteString): RawByteString;
var
  I: SizeInt;
  C: Byte;
const
  HexDigits: array[0..15] of AnsiChar =
    ('0', '1', '2', '3', '4', '5', '6', '7',
     '8', '9', 'a', 'b', 'c', 'd', 'e', 'f');
begin
  Result := '';
  for I := 1 to Length(Value) do
  begin
    C := Byte(Value[I]);
    case C of
      8: Result := Result + '\b';
      9: Result := Result + '\t';
      10: Result := Result + '\n';
      12: Result := Result + '\f';
      13: Result := Result + '\r';
      34: Result := Result + '\"';
      92: Result := Result + '\\';
    else
      if C < 32 then
        Result := Result + '\u00' + HexDigits[C shr 4] + HexDigits[C and 15]
      else
        Result := Result + AnsiChar(C);
    end;
  end;
end;

procedure PrintDiagnosticsJSON(const Bag: TDiagnosticBag;
  const FileName: RawByteString; WarningsAsErrors: Boolean);
var
  I: Integer;
  D: TDiagnostic;
  EffectiveSeverity: TDiagnosticSeverity;
  EffectiveErrors: UInt32;
begin
  EffectiveErrors := Bag.ErrorCount;
  if WarningsAsErrors then
    Inc(EffectiveErrors, Bag.WarningCount);
  Write(StdErr, '{"diagnostics":[');
  for I := 0 to High(Bag.Items) do
  begin
    if I <> 0 then Write(StdErr, ',');
    D := Bag.Items[I];
    EffectiveSeverity := D.Severity;
    if WarningsAsErrors and (EffectiveSeverity = dsWarning) then
      EffectiveSeverity := dsError;
    Write(StdErr, '{"file":"', JSONEscape(FileName), '",');
    Write(StdErr, '"line":', D.Span.StartPos.Line, ',');
    Write(StdErr, '"column":', D.Span.StartPos.Column, ',');
    Write(StdErr, '"endLine":', D.Span.EndPos.Line, ',');
    Write(StdErr, '"endColumn":', D.Span.EndPos.Column, ',');
    Write(StdErr, '"severity":"', JSONEscape(SeverityName(EffectiveSeverity)), '",');
    Write(StdErr, '"code":"', JSONEscape(DiagnosticCodeName(D.Code)), '",');
    Write(StdErr, '"message":"', JSONEscape(DiagnosticMessage(D)), '"}');
  end;
  Writeln(StdErr, '],"errors":', EffectiveErrors,
    ',"warnings":', Bag.WarningCount, ',"fatals":', Bag.FatalCount, '}');
end;

end.

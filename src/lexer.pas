unit lexer;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}
{$pointermath on}

interface

uses
  SysUtils, core, diagnostics, utf8;

const
  FSIM_MAX_TOKEN_TEXT = 255;

type
  TTokenKind = (
    tkInvalid,
    tkEOF,
    tkIdentifier,
    tkIntegerLiteral,
    tkRealLiteral,
    tkStringLiteral,
    tkCharacterLiteral,
    tkSemicolon,
    tkColon,
    tkComma,
    tkDot,
    tkRange,
    tkEllipsis,
    tkLParen,
    tkRParen,
    tkLBracket,
    tkRBracket,
    tkAssignValue,
    tkAssignReference,
    tkArrow,
    tkPlus,
    tkMinus,
    tkStar,
    tkSlash,
    tkIntegerDivide,
    tkPower,
    tkConcat,
    tkEqual,
    tkNotEqual,
    tkReferenceEqual,
    tkReferenceNotEqual,
    tkLess,
    tkLessEqual,
    tkGreater,
    tkGreaterEqual,
    tkProgram,
    tkBegin,
    tkEnd,
    tkClass,
    tkProcess,
    tkThread,
    tkTask,
    tkVirtual,
    tkProcedure,
    tkLambda,
    tkFunction,
    tkIs,
    tkPublic,
    tkPrivate,
    tkProtected,
    tkInteger,
    tkLong,
    tkShort,
    tkReal,
    tkBoolean,
    tkCharacter,
    tkText,
    tkString,
    tkRef,
    tkHead,
    tkLink,
    tkIf,
    tkThen,
    tkElse,
    tkWhile,
    tkDo,
    tkFor,
    tkStep,
    tkUntil,
    tkGo,
    tkTo,
    tkOf,
    tkSwitch,
    tkLabel,
    tkTrue,
    tkFalse,
    tkNot,
    tkAnd,
    tkOr,
    tkEqv,
    tkImp,
    tkNew,
    tkThis,
    tkNone,
    tkNoText,
    tkQua,
    tkIn,
    tkInspect,
    tkWhen,
    tkOtherwise,
    tkDetach,
    tkResume,
    tkActivate,
    tkReactivate,
    tkDelay,
    tkHold,
    tkPassivate,
    tkCancel,
    tkBefore,
    tkAfter,
    tkAt,
    tkPrior,
    tkAsync,
    tkSpawn,
    tkJoin,
    tkAwait,
    tkYield,
    tkChannel,
    tkSend,
    tkReceive,
    tkSelect,
    tkTimeout,
    tkLock,
    tkUnlock,
    tkMutex,
    tkFuture,
    tkParallel,
    tkCritical,
    tkDefer,
    tkCase,
    tkRepeat,
    tkWith,
    tkVar,
    tkThreadLocal,
    tkSemaphore,
    tkBarrier,
    tkCondition,
    tkOnce,
    tkPure,
    tkNoReturn,
    tkSystemCall,
    tkInterface,
    tkTrait,
    tkSealed,
    tkMatch,
    tkTry,
    tkCatch,
    tkFinally,
    tkRaise,
    tkArray,
    tkValue,
    tkName,
    tkExternal,
    tkForeign,
    tkFrom,
    tkHidden,
    tkInner,
    tkOwn,
    tkReturn,
    tkExit,
    tkBreak,
    tkContinue,
    tkAssert,
    tkConst,
    tkType,
    tkRecord,
    tkEnum,
    tkGeneric,
    tkWhere,
    tkImport,
    tkModule,
    tkExport,
    tkNative,
    tkInline,
    tkOverride,
    tkFinal,
    tkAbstract,
    tkSynchronized,
    tkAtomic,
    tkVolatile,
    tkSizeOf,
    tkTypeOf,
    tkLow,
    tkHigh,
    tkOrd,
    tkChr,
    tkAbs,
    tkMin,
    tkMax,
    tkShl,
    tkShr,
    tkXor,
    tkMod,
    tkRem,
    tkOutText,
    tkOutInt,
    tkOutReal,
    tkOutFix,
    tkOutChar,
    tkOutImage,
    tkInInt,
    tkInReal,
    tkInChar,
    tkInText,
    tkCommentKeyword
  );

  TTokenFlag = (
    tfNone,
    tfTruncated,
    tfContainsEscape,
    tfModernOnly
  );
  TTokenFlags = set of TTokenFlag;

  TToken = packed record
    Kind: TTokenKind;
    Flags: TTokenFlags;
    Span: TSourceSpan;
    TextLength: UInt16;
    Text: array[0..FSIM_MAX_TOKEN_TEXT] of AnsiChar;
    IntValue: Int64;
    RealValue: Double;
  end;

  TLexer = record
    Source: PAnsiChar;
    SourceLength: SizeUInt;
    Cur: PAnsiChar;
    Limit: PAnsiChar;
    Offset: UInt32;
    Line: UInt32;
    Column: UInt32;
    Dialect: TFSimDialect;
    Current: TToken;
    Diagnostics: ^TDiagnosticBag;
    TokenCount: QWord;
    SkipEndComment: Boolean;
  end;

procedure LexerInit(var Lexer: TLexer; Source: PAnsiChar; SourceLength: SizeUInt;
  Dialect: TFSimDialect; var Diagnostics: TDiagnosticBag);
procedure LexerNext(var Lexer: TLexer);
function TokenKindName(Kind: TTokenKind): RawByteString;
function TokenText(const Token: TToken): RawByteString;
function TokenIsModernOnly(Kind: TTokenKind): Boolean;
function TokenStartsType(Kind: TTokenKind): Boolean;
function TokenStartsDeclaration(Kind: TTokenKind): Boolean;
function TokenStartsStatement(Kind: TTokenKind): Boolean;
function TokenIsComparison(Kind: TTokenKind): Boolean;
function TokenIsAssignment(Kind: TTokenKind): Boolean;

implementation

function ASCIIToLower(C: AnsiChar): AnsiChar; inline;
begin
  if (C >= 'A') and (C <= 'Z') then
    Result := AnsiChar(Ord(C) + 32)
  else
    Result := C;
end;

function IsASCIIAlpha(C: AnsiChar): Boolean; inline;
begin
  Result := ((C >= 'a') and (C <= 'z')) or
    ((C >= 'A') and (C <= 'Z')) or (C = '_');
end;

function IsASCIIDigit(C: AnsiChar): Boolean; inline;
begin
  Result := (C >= '0') and (C <= '9');
end;

function IsASCIIHex(C: AnsiChar): Boolean; inline;
begin
  Result := IsASCIIDigit(C) or ((C >= 'a') and (C <= 'f')) or
    ((C >= 'A') and (C <= 'F'));
end;

function HexValue(C: AnsiChar): Integer; inline;
begin
  if (C >= '0') and (C <= '9') then
    Exit(Ord(C) - Ord('0'));
  if (C >= 'a') and (C <= 'f') then
    Exit(Ord(C) - Ord('a') + 10);
  if (C >= 'A') and (C <= 'F') then
    Exit(Ord(C) - Ord('A') + 10);
  Result := -1;
end;

function IsIdentifierContinue(C: AnsiChar): Boolean; inline;
begin
  Result := IsASCIIAlpha(C) or IsASCIIDigit(C) or (C = '_');
end;

function DecodeUnicodeIdentifier(const Lexer: TLexer; RequireStart: Boolean;
  out Width: SizeUInt): Boolean;
var
  CodePoint: UInt32;
  Available: SizeUInt;
begin
  Width := 0;
  if (Lexer.Dialect <> fdFSim) or (Lexer.Cur >= Lexer.Limit) or
     (Ord(Lexer.Cur^) < $80) then Exit(False);
  Available := SizeUInt(Lexer.Limit - Lexer.Cur);
  if not UTF8Decode(Lexer.Cur, Available, CodePoint, Width) then Exit(False);
  if RequireStart then
    Result := UnicodeIsIdentifierStart(CodePoint)
  else
    Result := UnicodeIsIdentifierContinue(CodePoint);
end;

function CurrentPos(const Lexer: TLexer): TSourcePos; inline;
begin
  Result.Offset := Lexer.Offset;
  Result.Line := Lexer.Line;
  Result.Column := Lexer.Column;
end;

function Peek(const Lexer: TLexer; Distance: SizeUInt = 0): AnsiChar; inline;
var
  P: PAnsiChar;
begin
  P := Lexer.Cur + Distance;
  if P >= Lexer.Limit then
    Exit(#0);
  Result := P^;
end;

function Advance(var Lexer: TLexer): AnsiChar; inline;
begin
  if Lexer.Cur >= Lexer.Limit then
    Exit(#0);
  Result := Lexer.Cur^;
  Inc(Lexer.Cur);
  Inc(Lexer.Offset);
  if Result = #10 then
  begin
    Inc(Lexer.Line);
    Lexer.Column := 1;
  end
  else
    Inc(Lexer.Column);
end;

procedure AdvanceBytes(var Lexer: TLexer; Count: SizeUInt); inline;
var
  Index: SizeUInt;
begin
  if Count = 0 then Exit;
  for Index := 1 to Count do Advance(Lexer);
end;

procedure BeginToken(var Lexer: TLexer; Kind: TTokenKind);
begin
  Lexer.Current := Default(TToken);
  Lexer.Current.Kind := Kind;
  Lexer.Current.Span.StartPos := CurrentPos(Lexer);
end;

procedure EndToken(var Lexer: TLexer);
begin
  Lexer.Current.Span.EndPos := CurrentPos(Lexer);
  if TokenIsModernOnly(Lexer.Current.Kind) then
    Include(Lexer.Current.Flags, tfModernOnly);
  Inc(Lexer.TokenCount);
end;

procedure SetTokenText(var Token: TToken; Start: PAnsiChar; LengthValue: SizeUInt);
var
  N: SizeUInt;
begin
  N := LengthValue;
  if N > FSIM_MAX_TOKEN_TEXT then
  begin
    N := FSIM_MAX_TOKEN_TEXT;
    Include(Token.Flags, tfTruncated);
  end;
  Token.TextLength := N;
  FillChar(Token.Text, SizeOf(Token.Text), 0);
  if N > 0 then
    Move(Start^, Token.Text[0], N);
end;

procedure SetDecodedTokenText(var Token: TToken; const Value: RawByteString);
var
  N: SizeInt;
begin
  N := Length(Value);
  if N > FSIM_MAX_TOKEN_TEXT then
  begin
    N := FSIM_MAX_TOKEN_TEXT;
    Include(Token.Flags, tfTruncated);
  end;
  Token.TextLength := N;
  FillChar(Token.Text, SizeOf(Token.Text), 0);
  if N > 0 then
    Move(Value[1], Token.Text[0], N);
end;

procedure LexerError(var Lexer: TLexer; Code: TDiagnosticCode;
  const StartPos, EndPos: TSourcePos; const MessageText: RawByteString);
begin
  if Lexer.Diagnostics <> nil then
    AddError(Lexer.Diagnostics^, Code, SourceSpan(StartPos, EndPos), MessageText);
end;

function EqualKeyword(Start: PAnsiChar; LengthValue: SizeUInt;
  const Keyword: RawByteString): Boolean;
var
  I: SizeUInt;
begin
  if LengthValue <> SizeUInt(Length(Keyword)) then
    Exit(False);
  if LengthValue = 0 then
    Exit(True);
  for I := 0 to LengthValue - 1 do
    if ASCIIToLower(Start[I]) <> Keyword[I + 1] then
      Exit(False);
  Result := True;
end;

function KeywordKind(Start: PAnsiChar; LengthValue: SizeUInt): TTokenKind;
var
  Initial: AnsiChar;
begin
  Result := tkIdentifier;
  if LengthValue = 0 then Exit;
  Initial := ASCIIToLower(Start[0]);
  case Initial of
    'a':
      begin
        if EqualKeyword(Start, LengthValue, 'abs') then Exit(tkAbs);
        if EqualKeyword(Start, LengthValue, 'abstract') then Exit(tkAbstract);
        if EqualKeyword(Start, LengthValue, 'activate') then Exit(tkActivate);
        if EqualKeyword(Start, LengthValue, 'after') then Exit(tkAfter);
        if EqualKeyword(Start, LengthValue, 'and') then Exit(tkAnd);
        if EqualKeyword(Start, LengthValue, 'array') then Exit(tkArray);
        if EqualKeyword(Start, LengthValue, 'assert') then Exit(tkAssert);
        if EqualKeyword(Start, LengthValue, 'at') then Exit(tkAt);
        if EqualKeyword(Start, LengthValue, 'atomic') then Exit(tkAtomic);
        if EqualKeyword(Start, LengthValue, 'async') then Exit(tkAsync);
        if EqualKeyword(Start, LengthValue, 'await') then Exit(tkAwait);
      end;
    'b':
      begin
        if EqualKeyword(Start, LengthValue, 'barrier') then Exit(tkBarrier);
        if EqualKeyword(Start, LengthValue, 'before') then Exit(tkBefore);
        if EqualKeyword(Start, LengthValue, 'begin') then Exit(tkBegin);
        if EqualKeyword(Start, LengthValue, 'boolean') then Exit(tkBoolean);
        if EqualKeyword(Start, LengthValue, 'break') then Exit(tkBreak);
      end;
    'c':
      begin
        if EqualKeyword(Start, LengthValue, 'cancel') then Exit(tkCancel);
        if EqualKeyword(Start, LengthValue, 'case') then Exit(tkCase);
        if EqualKeyword(Start, LengthValue, 'catch') then Exit(tkCatch);
        if EqualKeyword(Start, LengthValue, 'channel') then Exit(tkChannel);
        if EqualKeyword(Start, LengthValue, 'character') then Exit(tkCharacter);
        if EqualKeyword(Start, LengthValue, 'chr') then Exit(tkChr);
        if EqualKeyword(Start, LengthValue, 'class') then Exit(tkClass);
        if EqualKeyword(Start, LengthValue, 'comment') then Exit(tkCommentKeyword);
        if EqualKeyword(Start, LengthValue, 'condition') then Exit(tkCondition);
        if EqualKeyword(Start, LengthValue, 'const') then Exit(tkConst);
        if EqualKeyword(Start, LengthValue, 'continue') then Exit(tkContinue);
        if EqualKeyword(Start, LengthValue, 'critical') then Exit(tkCritical);
      end;
    'd':
      begin
        if EqualKeyword(Start, LengthValue, 'defer') then Exit(tkDefer);
        if EqualKeyword(Start, LengthValue, 'delay') then Exit(tkDelay);
        if EqualKeyword(Start, LengthValue, 'detach') then Exit(tkDetach);
        if EqualKeyword(Start, LengthValue, 'div') then Exit(tkIntegerDivide);
        if EqualKeyword(Start, LengthValue, 'do') then Exit(tkDo);
      end;
    'e':
      begin
        if EqualKeyword(Start, LengthValue, 'else') then Exit(tkElse);
        if EqualKeyword(Start, LengthValue, 'end') then Exit(tkEnd);
        if EqualKeyword(Start, LengthValue, 'enum') then Exit(tkEnum);
        if EqualKeyword(Start, LengthValue, 'eqv') then Exit(tkEqv);
        if EqualKeyword(Start, LengthValue, 'exit') then Exit(tkExit);
        if EqualKeyword(Start, LengthValue, 'export') then Exit(tkExport);
        if EqualKeyword(Start, LengthValue, 'external') then Exit(tkExternal);
      end;
    'f':
      begin
        if EqualKeyword(Start, LengthValue, 'false') then Exit(tkFalse);
        if EqualKeyword(Start, LengthValue, 'foreign') then Exit(tkForeign);
        if EqualKeyword(Start, LengthValue, 'from') then Exit(tkFrom);
        if EqualKeyword(Start, LengthValue, 'final') then Exit(tkFinal);
        if EqualKeyword(Start, LengthValue, 'finally') then Exit(tkFinally);
        if EqualKeyword(Start, LengthValue, 'for') then Exit(tkFor);
        if EqualKeyword(Start, LengthValue, 'function') then Exit(tkFunction);
        if EqualKeyword(Start, LengthValue, 'future') then Exit(tkFuture);
      end;
    'g':
      begin
        if EqualKeyword(Start, LengthValue, 'generic') then Exit(tkGeneric);
        if EqualKeyword(Start, LengthValue, 'go') then Exit(tkGo);
      end;
    'h':
      begin
        if EqualKeyword(Start, LengthValue, 'head') then Exit(tkHead);
        if EqualKeyword(Start, LengthValue, 'hidden') then Exit(tkHidden);
        if EqualKeyword(Start, LengthValue, 'high') then Exit(tkHigh);
        if EqualKeyword(Start, LengthValue, 'hold') then Exit(tkHold);
      end;
    'i':
      begin
        if EqualKeyword(Start, LengthValue, 'if') then Exit(tkIf);
        if EqualKeyword(Start, LengthValue, 'imp') then Exit(tkImp);
        if EqualKeyword(Start, LengthValue, 'import') then Exit(tkImport);
        if EqualKeyword(Start, LengthValue, 'in') then Exit(tkIn);
        if EqualKeyword(Start, LengthValue, 'inchar') then Exit(tkInChar);
        if EqualKeyword(Start, LengthValue, 'inint') then Exit(tkInInt);
        if EqualKeyword(Start, LengthValue, 'inline') then Exit(tkInline);
        if EqualKeyword(Start, LengthValue, 'inner') then Exit(tkInner);
        if EqualKeyword(Start, LengthValue, 'inreal') then Exit(tkInReal);
        if EqualKeyword(Start, LengthValue, 'inspect') then Exit(tkInspect);
        if EqualKeyword(Start, LengthValue, 'integer') then Exit(tkInteger);
        if EqualKeyword(Start, LengthValue, 'interface') then Exit(tkInterface);
        if EqualKeyword(Start, LengthValue, 'intext') then Exit(tkInText);
        if EqualKeyword(Start, LengthValue, 'is') then Exit(tkIs);
      end;
    'j':
      begin
        if EqualKeyword(Start, LengthValue, 'join') then Exit(tkJoin);
      end;
    'l':
      begin
        if EqualKeyword(Start, LengthValue, 'lambda') then Exit(tkLambda);
        if EqualKeyword(Start, LengthValue, 'link') then Exit(tkLink);
        if EqualKeyword(Start, LengthValue, 'label') then Exit(tkLabel);
        if EqualKeyword(Start, LengthValue, 'lock') then Exit(tkLock);
        if EqualKeyword(Start, LengthValue, 'long') then Exit(tkLong);
        if EqualKeyword(Start, LengthValue, 'low') then Exit(tkLow);
      end;
    'm':
      begin
        if EqualKeyword(Start, LengthValue, 'match') then Exit(tkMatch);
        if EqualKeyword(Start, LengthValue, 'max') then Exit(tkMax);
        if EqualKeyword(Start, LengthValue, 'min') then Exit(tkMin);
        if EqualKeyword(Start, LengthValue, 'mod') then Exit(tkMod);
        if EqualKeyword(Start, LengthValue, 'module') then Exit(tkModule);
        if EqualKeyword(Start, LengthValue, 'mutex') then Exit(tkMutex);
      end;
    'n':
      begin
        if EqualKeyword(Start, LengthValue, 'name') then Exit(tkName);
        if EqualKeyword(Start, LengthValue, 'native') then Exit(tkNative);
        if EqualKeyword(Start, LengthValue, 'new') then Exit(tkNew);
        if EqualKeyword(Start, LengthValue, 'none') then Exit(tkNone);
        if EqualKeyword(Start, LengthValue, 'notext') then Exit(tkNoText);
        if EqualKeyword(Start, LengthValue, 'noreturn') then Exit(tkNoReturn);
        if EqualKeyword(Start, LengthValue, 'not') then Exit(tkNot);
      end;
    'o':
      begin
        if EqualKeyword(Start, LengthValue, 'of') then Exit(tkOf);
        if EqualKeyword(Start, LengthValue, 'once') then Exit(tkOnce);
        if EqualKeyword(Start, LengthValue, 'or') then Exit(tkOr);
        if EqualKeyword(Start, LengthValue, 'ord') then Exit(tkOrd);
        if EqualKeyword(Start, LengthValue, 'otherwise') then Exit(tkOtherwise);
        if EqualKeyword(Start, LengthValue, 'outchar') then Exit(tkOutChar);
        if EqualKeyword(Start, LengthValue, 'outfix') then Exit(tkOutFix);
        if EqualKeyword(Start, LengthValue, 'outimage') then Exit(tkOutImage);
        if EqualKeyword(Start, LengthValue, 'outint') then Exit(tkOutInt);
        if EqualKeyword(Start, LengthValue, 'outreal') then Exit(tkOutReal);
        if EqualKeyword(Start, LengthValue, 'outtext') then Exit(tkOutText);
        if EqualKeyword(Start, LengthValue, 'override') then Exit(tkOverride);
        if EqualKeyword(Start, LengthValue, 'own') then Exit(tkOwn);
      end;
    'p':
      begin
        if EqualKeyword(Start, LengthValue, 'parallel') then Exit(tkParallel);
        if EqualKeyword(Start, LengthValue, 'passivate') then Exit(tkPassivate);
        if EqualKeyword(Start, LengthValue, 'prior') then Exit(tkPrior);
        if EqualKeyword(Start, LengthValue, 'private') then Exit(tkPrivate);
        if EqualKeyword(Start, LengthValue, 'procedure') then Exit(tkProcedure);
        if EqualKeyword(Start, LengthValue, 'process') then Exit(tkProcess);
        if EqualKeyword(Start, LengthValue, 'program') then Exit(tkProgram);
        if EqualKeyword(Start, LengthValue, 'protected') then Exit(tkProtected);
        if EqualKeyword(Start, LengthValue, 'public') then Exit(tkPublic);
        if EqualKeyword(Start, LengthValue, 'pure') then Exit(tkPure);
      end;
    'q':
      begin
        if EqualKeyword(Start, LengthValue, 'qua') then Exit(tkQua);
      end;
    'r':
      begin
        if EqualKeyword(Start, LengthValue, 'raise') then Exit(tkRaise);
        if EqualKeyword(Start, LengthValue, 'reactivate') then Exit(tkReactivate);
        if EqualKeyword(Start, LengthValue, 'real') then Exit(tkReal);
        if EqualKeyword(Start, LengthValue, 'receive') then Exit(tkReceive);
        if EqualKeyword(Start, LengthValue, 'record') then Exit(tkRecord);
        if EqualKeyword(Start, LengthValue, 'ref') then Exit(tkRef);
        if EqualKeyword(Start, LengthValue, 'rem') then Exit(tkRem);
        if EqualKeyword(Start, LengthValue, 'repeat') then Exit(tkRepeat);
        if EqualKeyword(Start, LengthValue, 'resume') then Exit(tkResume);
        if EqualKeyword(Start, LengthValue, 'return') then Exit(tkReturn);
      end;
    's':
      begin
        if EqualKeyword(Start, LengthValue, 'sealed') then Exit(tkSealed);
        if EqualKeyword(Start, LengthValue, 'select') then Exit(tkSelect);
        if EqualKeyword(Start, LengthValue, 'semaphore') then Exit(tkSemaphore);
        if EqualKeyword(Start, LengthValue, 'send') then Exit(tkSend);
        if EqualKeyword(Start, LengthValue, 'shl') then Exit(tkShl);
        if EqualKeyword(Start, LengthValue, 'short') then Exit(tkShort);
        if EqualKeyword(Start, LengthValue, 'shr') then Exit(tkShr);
        if EqualKeyword(Start, LengthValue, 'sizeof') then Exit(tkSizeOf);
        if EqualKeyword(Start, LengthValue, 'spawn') then Exit(tkSpawn);
        if EqualKeyword(Start, LengthValue, 'step') then Exit(tkStep);
        if EqualKeyword(Start, LengthValue, 'string') then Exit(tkString);
        if EqualKeyword(Start, LengthValue, 'switch') then Exit(tkSwitch);
        if EqualKeyword(Start, LengthValue, 'synchronized') then Exit(tkSynchronized);
        if EqualKeyword(Start, LengthValue, 'syscall') then Exit(tkSystemCall);
        if EqualKeyword(Start, LengthValue, 'systemcall') then Exit(tkSystemCall);
      end;
    't':
      begin
        if EqualKeyword(Start, LengthValue, 'task') then Exit(tkTask);
        if EqualKeyword(Start, LengthValue, 'text') then Exit(tkText);
        if EqualKeyword(Start, LengthValue, 'then') then Exit(tkThen);
        if EqualKeyword(Start, LengthValue, 'this') then Exit(tkThis);
        if EqualKeyword(Start, LengthValue, 'thread') then Exit(tkThread);
        if EqualKeyword(Start, LengthValue, 'threadlocal') then Exit(tkThreadLocal);
        if EqualKeyword(Start, LengthValue, 'timeout') then Exit(tkTimeout);
        if EqualKeyword(Start, LengthValue, 'to') then Exit(tkTo);
        if EqualKeyword(Start, LengthValue, 'trait') then Exit(tkTrait);
        if EqualKeyword(Start, LengthValue, 'true') then Exit(tkTrue);
        if EqualKeyword(Start, LengthValue, 'try') then Exit(tkTry);
        if EqualKeyword(Start, LengthValue, 'type') then Exit(tkType);
        if EqualKeyword(Start, LengthValue, 'typeof') then Exit(tkTypeOf);
      end;
    'u':
      begin
        if EqualKeyword(Start, LengthValue, 'unlock') then Exit(tkUnlock);
        if EqualKeyword(Start, LengthValue, 'until') then Exit(tkUntil);
      end;
    'v':
      begin
        if EqualKeyword(Start, LengthValue, 'value') then Exit(tkValue);
        if EqualKeyword(Start, LengthValue, 'var') then Exit(tkVar);
        if EqualKeyword(Start, LengthValue, 'virtual') then Exit(tkVirtual);
        if EqualKeyword(Start, LengthValue, 'volatile') then Exit(tkVolatile);
      end;
    'w':
      begin
        if EqualKeyword(Start, LengthValue, 'when') then Exit(tkWhen);
        if EqualKeyword(Start, LengthValue, 'where') then Exit(tkWhere);
        if EqualKeyword(Start, LengthValue, 'while') then Exit(tkWhile);
        if EqualKeyword(Start, LengthValue, 'with') then Exit(tkWith);
      end;
    'x':
      begin
        if EqualKeyword(Start, LengthValue, 'xor') then Exit(tkXor);
      end;
    'y':
      begin
        if EqualKeyword(Start, LengthValue, 'yield') then Exit(tkYield);
      end;
  end;
end;

procedure SkipHorizontalWhitespace(var Lexer: TLexer);
begin
  while Peek(Lexer) in [#9, #11, #12, #13, ' '] do
    Advance(Lexer);
end;

procedure SkipWhitespace(var Lexer: TLexer);
begin
  while True do
  begin
    SkipHorizontalWhitespace(Lexer);
    if Peek(Lexer) = #10 then
      Advance(Lexer)
    else
      Break;
  end;
end;

procedure SkipCommentBody(var Lexer: TLexer; const StartPos: TSourcePos);
begin
  while (Peek(Lexer) <> #0) and (Peek(Lexer) <> ';') do
    Advance(Lexer);
  if Peek(Lexer) = #0 then
    LexerError(Lexer, dcUnterminatedComment, StartPos, CurrentPos(Lexer),
      'comment must terminate at the next semicolon')
  else
    Advance(Lexer); { the semicolon belongs to the comment. yes really }
end;

procedure SkipClassicEndComment(var Lexer: TLexer);
var
  Start: PAnsiChar;
  Len, I: SizeUInt;
  Kind: TTokenKind;
begin
  { old simula lets people write `end foo;` and foo is commentary. dropping
    this rule broke a depressing amount of otherwise boring old source. }
  Lexer.SkipEndComment := False;
  while Peek(Lexer) <> #0 do
  begin
    SkipWhitespace(Lexer);
    if (Peek(Lexer) = #0) or (Peek(Lexer) = ';') then
      Exit;
    if IsASCIIAlpha(Peek(Lexer)) then
    begin
      Start := Lexer.Cur;
      Len := 0;
      while Start + Len < Lexer.Limit do
      begin
        if not IsIdentifierContinue(PAnsiChar(Start + Len)^) then
          Break;
        Inc(Len);
      end;
      Kind := KeywordKind(Start, Len);
      if Kind in [tkEnd, tkElse, tkWhen, tkOtherwise] then
        Exit;
      for I := 1 to Len do
        Advance(Lexer);
    end
    else
      Advance(Lexer);
  end;
end;

procedure ScanIdentifier(var Lexer: TLexer);
var
  Start: PAnsiChar;
  Len: SizeUInt;
  Kind: TTokenKind;
  StartPos: TSourcePos;
begin
  StartPos := CurrentPos(Lexer);
  Start := Lexer.Cur;
  while True do
  begin
    if IsIdentifierContinue(Peek(Lexer)) then
      Advance(Lexer)
    else if DecodeUnicodeIdentifier(Lexer, False, Len) then
      AdvanceBytes(Lexer, Len)
    else
      Break;
  end;
  Len := Lexer.Cur - Start;
  Kind := KeywordKind(Start, Len);
  if Kind = tkCommentKeyword then
  begin
    SkipCommentBody(Lexer, StartPos);
    LexerNext(Lexer);
    Exit;
  end;
  BeginToken(Lexer, Kind);
  Lexer.Current.Span.StartPos := StartPos;
  SetTokenText(Lexer.Current, Start, Len);
  EndToken(Lexer);
  if Kind = tkEnd then
    Lexer.SkipEndComment := True;
end;

function DigitValueForBase(C: AnsiChar; Base: Integer): Integer;
begin
  if Base = 16 then
    Exit(HexValue(C));
  if IsASCIIDigit(C) then
    Result := Ord(C) - Ord('0')
  else
    Result := -1;
  if Result >= Base then
    Result := -1;
end;

procedure ScanNumber(var Lexer: TLexer);
var
  Start: PAnsiChar;
  StartPos: TSourcePos;
  Base: Integer;
  Digit, DigitsRead: Integer;
  Value: QWord;
  Overflowed, IsReal: Boolean;
  TextValue, Normalized: RawByteString;
  Code, I: Integer;
  C: AnsiChar;

  procedure ReadExponent;
  begin
    IsReal := True;
    if Peek(Lexer) = '&' then
    begin
      Advance(Lexer);
      if Peek(Lexer) = '&' then
        Advance(Lexer);
    end
    else
      Advance(Lexer);
    if Peek(Lexer) in ['+', '-'] then
      Advance(Lexer);
    if not IsASCIIDigit(Peek(Lexer)) then
      LexerError(Lexer, dcInvalidNumber, StartPos, CurrentPos(Lexer),
        'expected exponent digits');
    while IsASCIIDigit(Peek(Lexer)) or (Peek(Lexer) = '_') do
      Advance(Lexer);
  end;

begin
  StartPos := CurrentPos(Lexer);
  Start := Lexer.Cur;
  Base := 10;
  IsReal := False;
  Overflowed := False;

  { fsim keeps the newer 0x/0b/0o spellings, the R forms below are the
    actual simula ones. both are cheap to support so there is no reason to
    make old code rewrite its constants. }
  if (Peek(Lexer) = '0') and (ASCIIToLower(Peek(Lexer, 1)) = 'x') then
  begin
    Base := 16;
    Advance(Lexer); Advance(Lexer);
  end
  else if (Peek(Lexer) = '0') and (ASCIIToLower(Peek(Lexer, 1)) = 'b') then
  begin
    Base := 2;
    Advance(Lexer); Advance(Lexer);
  end
  else if (Peek(Lexer) = '0') and (ASCIIToLower(Peek(Lexer, 1)) = 'o') then
  begin
    Base := 8;
    Advance(Lexer); Advance(Lexer);
  end
  else if ((Peek(Lexer) in ['2', '4', '8']) and
           (ASCIIToLower(Peek(Lexer, 1)) = 'r')) then
  begin
    Base := Ord(Peek(Lexer)) - Ord('0');
    Advance(Lexer); Advance(Lexer);
  end
  else if (Peek(Lexer) = '1') and (Peek(Lexer, 1) = '6') and
          (ASCIIToLower(Peek(Lexer, 2)) = 'r') then
  begin
    Base := 16;
    Advance(Lexer); Advance(Lexer); Advance(Lexer);
  end;

  Value := 0;
  DigitsRead := 0;
  if (Base = 10) and (Peek(Lexer) = '.') then
  begin
    IsReal := True;
    Advance(Lexer);
    while IsASCIIDigit(Peek(Lexer)) or (Peek(Lexer) = '_') do
    begin
      if Peek(Lexer) <> '_' then Inc(DigitsRead);
      Advance(Lexer);
    end;
  end
  else
  begin
    while True do
    begin
      C := Peek(Lexer);
      if C = '_' then
      begin
        Advance(Lexer);
        Continue;
      end;
      Digit := DigitValueForBase(C, Base);
      if Digit < 0 then
        Break;
      Inc(DigitsRead);
      if Value > (High(QWord) - QWord(Digit)) div QWord(Base) then
        Overflowed := True
      else
        Value := Value * QWord(Base) + QWord(Digit);
      Advance(Lexer);
    end;
  end;

  if DigitsRead = 0 then
    LexerError(Lexer, dcInvalidNumber, StartPos, CurrentPos(Lexer),
      'numeric literal has no digits');

  if Base = 10 then
  begin
    if not IsReal and (Peek(Lexer) = '.') and (Peek(Lexer, 1) <> '.') and
       IsASCIIDigit(Peek(Lexer, 1)) then
    begin
      IsReal := True;
      Advance(Lexer);
      while IsASCIIDigit(Peek(Lexer)) or (Peek(Lexer) = '_') do
        Advance(Lexer);
    end;
    if ASCIIToLower(Peek(Lexer)) = 'e' then
      ReadExponent
    else if Peek(Lexer) = '&' then
      ReadExponent;
  end;

  if IsReal then
  begin
    BeginToken(Lexer, tkRealLiteral);
    Lexer.Current.Span.StartPos := StartPos;
    SetString(TextValue, Start, Lexer.Cur - Start);
    TextValue := StringReplace(TextValue, '_', '', [rfReplaceAll]);
    Normalized := '';
    I := 1;
    if (Length(TextValue) > 0) and (TextValue[1] = '.') then
      Normalized := '0';
    while I <= Length(TextValue) do
    begin
      if TextValue[I] = '&' then
      begin
        Normalized := Normalized + 'e';
        Inc(I);
        if (I <= Length(TextValue)) and (TextValue[I] = '&') then
          Inc(I);
      end
      else
      begin
        Normalized := Normalized + TextValue[I];
        Inc(I);
      end;
    end;
    Val(Normalized, Lexer.Current.RealValue, Code);
    if Code <> 0 then
      LexerError(Lexer, dcInvalidNumber, StartPos, CurrentPos(Lexer),
        'invalid real literal');
    SetTokenText(Lexer.Current, Start, Lexer.Cur - Start);
  end
  else
  begin
    BeginToken(Lexer, tkIntegerLiteral);
    Lexer.Current.Span.StartPos := StartPos;
    if Overflowed or (Value > QWord(High(Int64))) then
    begin
      Lexer.Current.IntValue := High(Int64);
      LexerError(Lexer, dcOverflow, StartPos, CurrentPos(Lexer),
        'integer literal exceeds signed 64-bit range');
    end
    else
      Lexer.Current.IntValue := Int64(Value);
    SetTokenText(Lexer.Current, Start, Lexer.Cur - Start);
  end;
  EndToken(Lexer);
end;

procedure ScanExponentOnly(var Lexer: TLexer);
var
  Start: PAnsiChar;
  StartPos: TSourcePos;
  TextValue, Normalized: RawByteString;
  I, Code: Integer;
begin
  StartPos := CurrentPos(Lexer);
  Start := Lexer.Cur;
  Advance(Lexer);
  if Peek(Lexer) = '&' then Advance(Lexer);
  if Peek(Lexer) in ['+', '-'] then Advance(Lexer);
  if not IsASCIIDigit(Peek(Lexer)) then
  begin
    { not a number after all, caller should only send valid exponent starts }
    BeginToken(Lexer, tkInvalid);
    Lexer.Current.Span.StartPos := StartPos;
    EndToken(Lexer);
    Exit;
  end;
  while IsASCIIDigit(Peek(Lexer)) or (Peek(Lexer) = '_') do
    Advance(Lexer);
  SetString(TextValue, Start, Lexer.Cur - Start);
  TextValue := StringReplace(TextValue, '_', '', [rfReplaceAll]);
  Normalized := '1e';
  I := 2;
  if (I <= Length(TextValue)) and (TextValue[I] = '&') then Inc(I);
  while I <= Length(TextValue) do
  begin
    Normalized := Normalized + TextValue[I];
    Inc(I);
  end;
  BeginToken(Lexer, tkRealLiteral);
  Lexer.Current.Span.StartPos := StartPos;
  Val(Normalized, Lexer.Current.RealValue, Code);
  if Code <> 0 then
    LexerError(Lexer, dcInvalidNumber, StartPos, CurrentPos(Lexer),
      'invalid exponent-only real literal');
  SetTokenText(Lexer.Current, Start, Lexer.Cur - Start);
  EndToken(Lexer);
end;

procedure AppendUTF8(var Value: RawByteString; CodePoint: UInt32);
var
  N: SizeInt;
begin
  N := Length(Value);
  if CodePoint <= $7F then
  begin
    SetLength(Value, N + 1);
    Value[N + 1] := AnsiChar(CodePoint);
  end
  else if CodePoint <= $7FF then
  begin
    SetLength(Value, N + 2);
    Value[N + 1] := AnsiChar($C0 or (CodePoint shr 6));
    Value[N + 2] := AnsiChar($80 or (CodePoint and $3F));
  end
  else if CodePoint <= $FFFF then
  begin
    SetLength(Value, N + 3);
    Value[N + 1] := AnsiChar($E0 or (CodePoint shr 12));
    Value[N + 2] := AnsiChar($80 or ((CodePoint shr 6) and $3F));
    Value[N + 3] := AnsiChar($80 or (CodePoint and $3F));
  end
  else if CodePoint <= $10FFFF then
  begin
    SetLength(Value, N + 4);
    Value[N + 1] := AnsiChar($F0 or (CodePoint shr 18));
    Value[N + 2] := AnsiChar($80 or ((CodePoint shr 12) and $3F));
    Value[N + 3] := AnsiChar($80 or ((CodePoint shr 6) and $3F));
    Value[N + 4] := AnsiChar($80 or (CodePoint and $3F));
  end;
end;

procedure ScanQuotedLiteral(var Lexer: TLexer; Quote: AnsiChar; IsCharacter: Boolean);
var
  StartPos: TSourcePos;
  Value: RawByteString;
  C: AnsiChar;
  CodePoint: UInt32;
  I, Digits: Integer;
  Closed: Boolean;
begin
  StartPos := CurrentPos(Lexer);
  BeginToken(Lexer, tkStringLiteral);
  Lexer.Current.Span.StartPos := StartPos;
  if IsCharacter then
    Lexer.Current.Kind := tkCharacterLiteral;
  Advance(Lexer);
  Value := '';
  Closed := False;
  while Peek(Lexer) <> #0 do
  begin
    C := Advance(Lexer);
    if C = Quote then
    begin
      if Peek(Lexer) = Quote then
      begin
        Advance(Lexer);
        Value := Value + Quote;
        Continue;
      end;
      Closed := True;
      Break;
    end;
    if C in [#10, #13] then
    begin
      LexerError(Lexer, dcUnterminatedString, StartPos, CurrentPos(Lexer),
        'literal cannot cross a physical line');
      Break;
    end;
    if (C = '!') and IsASCIIDigit(Peek(Lexer)) then
    begin
      { !65! is not an escape invented by us, it is old simula's way of
        spelling a byte. malformed ones stay literal like the standard says. }
      CodePoint := 0;
      Digits := 0;
      while (Digits < 3) and IsASCIIDigit(Peek(Lexer, Digits)) do
      begin
        CodePoint := CodePoint * 10 + UInt32(Ord(Peek(Lexer, Digits)) - Ord('0'));
        Inc(Digits);
      end;
      if (Digits > 0) and (Peek(Lexer, Digits) = '!') and (CodePoint < 256) then
      begin
        for I := 1 to Digits + 1 do Advance(Lexer);
        Value := Value + AnsiChar(CodePoint);
        Continue;
      end;
      Value := Value + C;
      Continue;
    end;
    if (C = '\') and (Lexer.Dialect = fdFSim) then
    begin
      Include(Lexer.Current.Flags, tfContainsEscape);
      C := Advance(Lexer);
      case C of
        'n': Value := Value + #10;
        'r': Value := Value + #13;
        't': Value := Value + #9;
        '0': Value := Value + #0;
        '\': Value := Value + '\';
        '''': Value := Value + '''';
        '"': Value := Value + '"';
        'x':
          begin
            CodePoint := 0;
            Digits := 2;
            for I := 1 to Digits do
            begin
              if not IsASCIIHex(Peek(Lexer)) then
              begin
                LexerError(Lexer, dcInvalidEscape, StartPos, CurrentPos(Lexer),
                  'expected two hexadecimal digits after \x');
                Break;
              end;
              CodePoint := CodePoint * 16 + UInt32(HexValue(Advance(Lexer)));
            end;
            AppendUTF8(Value, CodePoint);
          end;
        'u':
          begin
            CodePoint := 0;
            Digits := 4;
            for I := 1 to Digits do
            begin
              if not IsASCIIHex(Peek(Lexer)) then
              begin
                LexerError(Lexer, dcInvalidEscape, StartPos, CurrentPos(Lexer),
                  'expected four hexadecimal digits after \u');
                Break;
              end;
              CodePoint := CodePoint * 16 + UInt32(HexValue(Advance(Lexer)));
            end;
            if (CodePoint >= $D800) and (CodePoint <= $DFFF) then
              LexerError(Lexer, dcInvalidEscape, StartPos, CurrentPos(Lexer),
                'UTF-16 surrogate is not a Unicode scalar value')
            else
              AppendUTF8(Value, CodePoint);
          end;
      else
        LexerError(Lexer, dcInvalidEscape, StartPos, CurrentPos(Lexer),
          'unknown escape sequence');
        Value := Value + C;
      end;
    end
    else
      Value := Value + C;
  end;
  if not Closed then
    LexerError(Lexer, dcUnterminatedString, StartPos, CurrentPos(Lexer),
      'unterminated quoted literal');
  if IsCharacter and (Length(Value) <> 1) then
    LexerError(Lexer, dcInvalidNumber, StartPos, CurrentPos(Lexer),
      'character literal must contain exactly one byte');
  SetDecodedTokenText(Lexer.Current, Value);
  if IsCharacter and (Length(Value) > 0) then
    Lexer.Current.IntValue := Ord(Value[1]);
  EndToken(Lexer);
end;

procedure ScanPunctuation(var Lexer: TLexer);
var
  C: AnsiChar;
  Start: PAnsiChar;
  StartPos: TSourcePos;
begin
  StartPos := CurrentPos(Lexer);
  Start := Lexer.Cur;
  C := Advance(Lexer);
  case C of
    ';': BeginToken(Lexer, tkSemicolon);
    ':':
      begin
        if Peek(Lexer) = '=' then
        begin
          Advance(Lexer);
          BeginToken(Lexer, tkAssignValue);
        end
        else if Peek(Lexer) = '-' then
        begin
          Advance(Lexer);
          BeginToken(Lexer, tkAssignReference);
        end
        else
          BeginToken(Lexer, tkColon);
      end;
    ',': BeginToken(Lexer, tkComma);
    '.':
      begin
        if Peek(Lexer) = '.' then
        begin
          Advance(Lexer);
          if Peek(Lexer) = '.' then
          begin
            Advance(Lexer);
            BeginToken(Lexer, tkEllipsis);
          end
          else
            BeginToken(Lexer, tkRange);
        end
        else
          BeginToken(Lexer, tkDot);
      end;
    '(': BeginToken(Lexer, tkLParen);
    ')': BeginToken(Lexer, tkRParen);
    '[': BeginToken(Lexer, tkLBracket);
    ']': BeginToken(Lexer, tkRBracket);
    '+': BeginToken(Lexer, tkPlus);
    '&': BeginToken(Lexer, tkConcat);
    '-': BeginToken(Lexer, tkMinus);
    '*':
      begin
        if Peek(Lexer) = '*' then
        begin
          Advance(Lexer);
          BeginToken(Lexer, tkPower);
        end
        else
          BeginToken(Lexer, tkStar);
      end;
    '/':
      begin
        if Peek(Lexer) = '/' then
        begin
          Advance(Lexer);
          BeginToken(Lexer, tkIntegerDivide);
        end
        else if Peek(Lexer) = '=' then
        begin
          Advance(Lexer);
          BeginToken(Lexer, tkNotEqual);
        end
        else
          BeginToken(Lexer, tkSlash);
      end;
    '=':
      begin
        if Peek(Lexer) = '>' then
        begin
          Advance(Lexer);
          BeginToken(Lexer, tkArrow);
        end
        else if Peek(Lexer) = '=' then
        begin
          Advance(Lexer);
          BeginToken(Lexer, tkReferenceEqual);
        end
        else if (Peek(Lexer) = '/') and (Peek(Lexer, 1) = '=') then
        begin
          Advance(Lexer);
          Advance(Lexer);
          BeginToken(Lexer, tkReferenceNotEqual);
        end
        else
          BeginToken(Lexer, tkEqual);
      end;
    '<':
      begin
        if Peek(Lexer) = '=' then
        begin
          Advance(Lexer);
          BeginToken(Lexer, tkLessEqual);
        end
        else if Peek(Lexer) = '>' then
        begin
          Advance(Lexer);
          BeginToken(Lexer, tkNotEqual);
        end
        else
          BeginToken(Lexer, tkLess);
      end;
    '>':
      begin
        if Peek(Lexer) = '=' then
        begin
          Advance(Lexer);
          BeginToken(Lexer, tkGreaterEqual);
        end
        else
          BeginToken(Lexer, tkGreater);
      end;
  else
    BeginToken(Lexer, tkInvalid);
    LexerError(Lexer, dcUnexpectedCharacter, StartPos, CurrentPos(Lexer),
      'unexpected character with byte value ' + IntToStr(Ord(C)));
  end;
  Lexer.Current.Span.StartPos := StartPos;
  SetTokenText(Lexer.Current, Start, Lexer.Cur - Start);
  EndToken(Lexer);
end;

procedure LexerInit(var Lexer: TLexer; Source: PAnsiChar; SourceLength: SizeUInt;
  Dialect: TFSimDialect; var Diagnostics: TDiagnosticBag);
begin
  Lexer := Default(TLexer);
  Lexer.Source := Source;
  Lexer.SourceLength := SourceLength;
  Lexer.Cur := Source;
  Lexer.Limit := Source + SourceLength;
  Lexer.Offset := 0;
  Lexer.Line := 1;
  Lexer.Column := 1;
  Lexer.Dialect := Dialect;
  Lexer.Diagnostics := @Diagnostics;
  LexerNext(Lexer);
end;

procedure LexerNext(var Lexer: TLexer);
var
  C: AnsiChar;
  StartPos: TSourcePos;
  UnicodeWidth: SizeUInt;
begin
  if Lexer.SkipEndComment then
    SkipClassicEndComment(Lexer);
  SkipWhitespace(Lexer);
  { percent lines were implementation directives on old systems. they have
    no portable meaning, so ignoring the whole line is considerably less
    stupid than treating one as a modulo expression at column one. }
  while (Lexer.Column = 1) and (Peek(Lexer) = '%') do
  begin
    while not (Peek(Lexer) in [#0, #10]) do
      Advance(Lexer);
    if Peek(Lexer) = #10 then Advance(Lexer);
    SkipWhitespace(Lexer);
  end;
  C := Peek(Lexer);
  if C = #0 then
  begin
    BeginToken(Lexer, tkEOF);
    EndToken(Lexer);
    Exit;
  end;
  if C = '!' then
  begin
    StartPos := CurrentPos(Lexer);
    Advance(Lexer);
    SkipCommentBody(Lexer, StartPos);
    LexerNext(Lexer);
    Exit;
  end;
  if IsASCIIAlpha(C) or (C = '_') or DecodeUnicodeIdentifier(Lexer, True,
    UnicodeWidth) then
  begin
    ScanIdentifier(Lexer);
    Exit;
  end;
  if IsASCIIDigit(C) or ((C = '.') and IsASCIIDigit(Peek(Lexer, 1))) then
  begin
    ScanNumber(Lexer);
    Exit;
  end;
  if (C = '&') and
     (IsASCIIDigit(Peek(Lexer, 1)) or
      ((Peek(Lexer, 1) in ['+', '-']) and IsASCIIDigit(Peek(Lexer, 2))) or
      ((Peek(Lexer, 1) = '&') and
       (IsASCIIDigit(Peek(Lexer, 2)) or
        ((Peek(Lexer, 2) in ['+', '-']) and IsASCIIDigit(Peek(Lexer, 3)))))) then
  begin
    ScanExponentOnly(Lexer);
    Exit;
  end;
  if C = '"' then
  begin
    ScanQuotedLiteral(Lexer, '"', False);
    Exit;
  end;
  if C = '''' then
  begin
    ScanQuotedLiteral(Lexer, '''', True);
    Exit;
  end;
  ScanPunctuation(Lexer);
end;

function TokenText(const Token: TToken): RawByteString;
begin
  SetString(Result, PAnsiChar(@Token.Text[0]), Token.TextLength);
end;

function TokenIsModernOnly(Kind: TTokenKind): Boolean;
begin
  Result := Kind in [
    tkThread, tkPublic, tkPrivate, tkProtected, tkString,
    tkTry, tkCatch, tkFinally, tkRaise, tkReturn, tkBreak, tkContinue,
    tkAssert, tkConst, tkType, tkRecord, tkEnum, tkGeneric, tkWhere,
    tkImport, tkModule, tkExport, tkNative, tkInline, tkOverride, tkFinal,
    tkAbstract, tkSynchronized, tkAtomic, tkVolatile, tkSizeOf, tkTypeOf,
    tkShl, tkShr, tkXor, tkTask, tkCancel, tkAsync, tkSpawn, tkJoin,
    tkAwait, tkYield, tkChannel, tkSend, tkReceive, tkSelect, tkTimeout,
    tkLock, tkUnlock, tkMutex, tkFuture, tkParallel, tkCritical, tkDefer,
    tkCase, tkRepeat, tkWith, tkVar, tkThreadLocal, tkSemaphore, tkBarrier,
    tkCondition, tkOnce, tkPure, tkNoReturn, tkSystemCall, tkInterface,
    tkTrait, tkSealed, tkMatch, tkForeign, tkFrom
  ];
end;

function TokenStartsType(Kind: TTokenKind): Boolean;
begin
  Result := Kind in [tkInteger, tkLong, tkShort, tkReal, tkBoolean,
    tkCharacter, tkText, tkString, tkRef, tkHead, tkLink, tkArray,
    tkChannel, tkMutex, tkFuture, tkSemaphore, tkBarrier, tkCondition,
    tkAtomic];
end;

function TokenStartsDeclaration(Kind: TTokenKind): Boolean;
begin
  Result := TokenStartsType(Kind) or (Kind in [tkOwn, tkConst, tkProcedure,
    tkFunction, tkClass, tkProcess, tkThread, tkTask, tkSwitch, tkLabel,
    tkType, tkRecord, tkEnum, tkVar, tkThreadLocal, tkExternal, tkForeign]);
end;

function TokenStartsStatement(Kind: TTokenKind): Boolean;
begin
  Result := Kind in [tkIdentifier, tkBegin, tkIf, tkWhile, tkFor, tkGo,
    tkInspect, tkDetach, tkResume, tkActivate, tkReactivate, tkDelay, tkHold,
    tkPassivate, tkCancel, tkTry, tkRaise, tkReturn, tkExit, tkBreak,
    tkContinue, tkAssert, tkOutText, tkOutInt, tkOutReal, tkOutFix, tkOutChar,
    tkOutImage, tkAsync, tkSpawn, tkJoin, tkYield, tkSend, tkReceive, tkLock,
    tkUnlock, tkParallel, tkCritical, tkSynchronized, tkDefer, tkRepeat, tkCase, tkWith];
end;

function TokenIsComparison(Kind: TTokenKind): Boolean;
begin
  Result := Kind in [tkEqual, tkNotEqual, tkReferenceEqual,
    tkReferenceNotEqual, tkLess, tkLessEqual, tkGreater, tkGreaterEqual];
end;

function TokenIsAssignment(Kind: TTokenKind): Boolean;
begin
  Result := Kind in [tkAssignValue, tkAssignReference];
end;

function TokenKindName(Kind: TTokenKind): RawByteString;
begin
  case Kind of
    tkInvalid: Result := 'invalid token';
    tkEOF: Result := 'end of file';
    tkIdentifier: Result := 'identifier';
    tkIntegerLiteral: Result := 'integer literal';
    tkRealLiteral: Result := 'real literal';
    tkStringLiteral: Result := 'string literal';
    tkCharacterLiteral: Result := 'character literal';
    tkSemicolon: Result := ''';''';
    tkColon: Result := ''':''';
    tkComma: Result := ''',''';
    tkDot: Result := '''.''';
    tkRange: Result := '''..''';
    tkEllipsis: Result := '''...''';
    tkLParen: Result := '''(''';
    tkRParen: Result := ''')''';
    tkLBracket: Result := '''[''';
    tkRBracket: Result := ''']''';
    tkAssignValue: Result := ''':=''';
    tkAssignReference: Result := ''':-''';
    tkArrow: Result := '''=>''';
    tkPlus: Result := '''+''';
    tkMinus: Result := '''-''';
    tkStar: Result := '''*''';
    tkSlash: Result := '''/''';
    tkIntegerDivide: Result := '''//''';
    tkPower: Result := '''**''';
    tkConcat: Result := '''&''';
    tkEqual: Result := '''=''';
    tkNotEqual: Result := '''<>''';
    tkReferenceEqual: Result := '''==''';
    tkReferenceNotEqual: Result := '''=/=''';
    tkLess: Result := '''<''';
    tkLessEqual: Result := '''<=''';
    tkGreater: Result := '''>''';
    tkGreaterEqual: Result := '''>=''';
    tkProgram: Result := '''program''';
    tkBegin: Result := '''begin''';
    tkEnd: Result := '''end''';
    tkClass: Result := '''class''';
    tkProcess: Result := '''process''';
    tkThread: Result := '''thread''';
    tkTask: Result := '''task''';
    tkVirtual: Result := '''virtual''';
    tkProcedure: Result := '''procedure''';
    tkLambda: Result := '''lambda''';
    tkFunction: Result := '''function''';
    tkIs: Result := '''is''';
    tkPublic: Result := '''public''';
    tkPrivate: Result := '''private''';
    tkProtected: Result := '''protected''';
    tkInteger: Result := '''integer''';
    tkLong: Result := '''long''';
    tkShort: Result := '''short''';
    tkReal: Result := '''real''';
    tkBoolean: Result := '''boolean''';
    tkCharacter: Result := '''character''';
    tkText: Result := '''text''';
    tkString: Result := '''string''';
    tkRef: Result := '''ref''';
    tkHead: Result := '''head''';
    tkLink: Result := '''link''';
    tkIf: Result := '''if''';
    tkThen: Result := '''then''';
    tkElse: Result := '''else''';
    tkWhile: Result := '''while''';
    tkDo: Result := '''do''';
    tkFor: Result := '''for''';
    tkStep: Result := '''step''';
    tkUntil: Result := '''until''';
    tkGo: Result := '''go''';
    tkTo: Result := '''to''';
    tkOf: Result := '''of''';
    tkSwitch: Result := '''switch''';
    tkLabel: Result := '''label''';
    tkTrue: Result := '''true''';
    tkFalse: Result := '''false''';
    tkNot: Result := '''not''';
    tkAnd: Result := '''and''';
    tkOr: Result := '''or''';
    tkEqv: Result := '''eqv''';
    tkImp: Result := '''imp''';
    tkNew: Result := '''new''';
    tkThis: Result := '''this''';
    tkNone: Result := '''none''';
    tkNoText: Result := '''notext''';
    tkQua: Result := '''qua''';
    tkIn: Result := '''in''';
    tkInspect: Result := '''inspect''';
    tkWhen: Result := '''when''';
    tkOtherwise: Result := '''otherwise''';
    tkDetach: Result := '''detach''';
    tkResume: Result := '''resume''';
    tkActivate: Result := '''activate''';
    tkReactivate: Result := '''reactivate''';
    tkDelay: Result := '''delay''';
    tkHold: Result := '''hold''';
    tkPassivate: Result := '''passivate''';
    tkCancel: Result := '''cancel''';
    tkBefore: Result := '''before''';
    tkAfter: Result := '''after''';
    tkAt: Result := '''at''';
    tkPrior: Result := '''prior''';
    tkAsync: Result := '''async''';
    tkSpawn: Result := '''spawn''';
    tkJoin: Result := '''join''';
    tkAwait: Result := '''await''';
    tkYield: Result := '''yield''';
    tkChannel: Result := '''channel''';
    tkSend: Result := '''send''';
    tkReceive: Result := '''receive''';
    tkSelect: Result := '''select''';
    tkTimeout: Result := '''timeout''';
    tkLock: Result := '''lock''';
    tkUnlock: Result := '''unlock''';
    tkMutex: Result := '''mutex''';
    tkFuture: Result := '''future''';
    tkParallel: Result := '''parallel''';
    tkCritical: Result := '''critical''';
    tkDefer: Result := '''defer''';
    tkCase: Result := '''case''';
    tkRepeat: Result := '''repeat''';
    tkWith: Result := '''with''';
    tkVar: Result := '''var''';
    tkThreadLocal: Result := '''threadlocal''';
    tkSemaphore: Result := '''semaphore''';
    tkBarrier: Result := '''barrier''';
    tkCondition: Result := '''condition''';
    tkOnce: Result := '''once''';
    tkPure: Result := '''pure''';
    tkNoReturn: Result := '''noreturn''';
    tkSystemCall: Result := '''systemcall''';
    tkInterface: Result := '''interface''';
    tkTrait: Result := '''trait''';
    tkSealed: Result := '''sealed''';
    tkMatch: Result := '''match''';
    tkTry: Result := '''try''';
    tkCatch: Result := '''catch''';
    tkFinally: Result := '''finally''';
    tkRaise: Result := '''raise''';
    tkArray: Result := '''array''';
    tkValue: Result := '''value''';
    tkName: Result := '''name''';
    tkExternal: Result := '''external''';
    tkForeign: Result := '''foreign''';
    tkFrom: Result := '''from''';
    tkHidden: Result := '''hidden''';
    tkInner: Result := '''inner''';
    tkOwn: Result := '''own''';
    tkReturn: Result := '''return''';
    tkExit: Result := '''exit''';
    tkBreak: Result := '''break''';
    tkContinue: Result := '''continue''';
    tkAssert: Result := '''assert''';
    tkConst: Result := '''const''';
    tkType: Result := '''type''';
    tkRecord: Result := '''record''';
    tkEnum: Result := '''enum''';
    tkGeneric: Result := '''generic''';
    tkWhere: Result := '''where''';
    tkImport: Result := '''import''';
    tkModule: Result := '''module''';
    tkExport: Result := '''export''';
    tkNative: Result := '''native''';
    tkInline: Result := '''inline''';
    tkOverride: Result := '''override''';
    tkFinal: Result := '''final''';
    tkAbstract: Result := '''abstract''';
    tkSynchronized: Result := '''synchronized''';
    tkAtomic: Result := '''atomic''';
    tkVolatile: Result := '''volatile''';
    tkSizeOf: Result := '''sizeof''';
    tkTypeOf: Result := '''typeof''';
    tkLow: Result := '''low''';
    tkHigh: Result := '''high''';
    tkOrd: Result := '''ord''';
    tkChr: Result := '''chr''';
    tkAbs: Result := '''abs''';
    tkMin: Result := '''min''';
    tkMax: Result := '''max''';
    tkShl: Result := '''shl''';
    tkShr: Result := '''shr''';
    tkXor: Result := '''xor''';
    tkMod: Result := '''mod''';
    tkRem: Result := '''rem''';
    tkOutText: Result := '''outtext''';
    tkOutInt: Result := '''outint''';
    tkOutReal: Result := '''outreal''';
    tkOutFix: Result := '''outfix''';
    tkOutChar: Result := '''outchar''';
    tkOutImage: Result := '''outimage''';
    tkInInt: Result := '''inint''';
    tkInReal: Result := '''inreal''';
    tkInChar: Result := '''inchar''';
    tkInText: Result := '''intext''';
    tkCommentKeyword: Result := '''comment''';
  else
    Result := 'token';
  end;
end;

end.

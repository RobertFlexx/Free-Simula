unit parser;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, core, diagnostics, lexer, ast,
  symbols, classic;

type
  TParser = record
    Lexer: TLexer;
    Current: TToken;
    Lookahead: TToken;
    Previous: TToken;
    Tree: ^TAST;
    Symbols: ^TSymbolTable;
    Diagnostics: ^TDiagnosticBag;
    Options: ^TCompilerOptions;
    CurrentVisibility: TVisibility;
    CurrentClass: Int32;
    CurrentRoutine: Int32;
    CurrentBlock: Int32;
    LoopDepth: Int32;
    ErrorRecovery: Boolean;
    ParsedStatementCount: QWord;
    ParsedDeclarationCount: QWord;
    LambdaCounter: QWord;
  end;

procedure ParserInit(var Parser: TParser; Source: PAnsiChar;
  SourceLength: SizeUInt; var Tree: TAST; var Symbols: TSymbolTable;
  var Diagnostics: TDiagnosticBag; var Options: TCompilerOptions);
function ParseCompilationUnit(var Parser: TParser): Int32;

implementation

procedure Advance(var Parser: TParser); forward;
function At(const Parser: TParser; Kind: TTokenKind): Boolean; forward;
function LookAt(const Parser: TParser; Kind: TTokenKind): Boolean; forward;
function Accept(var Parser: TParser; Kind: TTokenKind): Boolean; forward;
procedure ParserError(var Parser: TParser; Code: TDiagnosticCode;
  const MessageText: RawByteString); forward;
function Expect(var Parser: TParser; Kind: TTokenKind): Boolean; forward;
function ExpectIdentifier(var Parser: TParser; out Name: RawByteString;
  out Span: TSourceSpan): Boolean; forward;
function ExpectRoutineIdentifier(var Parser: TParser; out Name: RawByteString;
  out Span: TSourceSpan): Boolean; forward;
function ExpectClassIdentifier(var Parser: TParser;
  out Name: RawByteString; out Span: TSourceSpan): Boolean; forward;
function ParseType(var Parser: TParser): Int32; forward;
function ParseSignedConstantInteger(var Parser: TParser; out Value: Int64): Boolean; forward;
function CurrentTokenIsTypeAlias(const Parser: TParser): Boolean; forward;
function ParseParameterList(var Parser: TParser; ProcedureNode: Int32;
  out ParameterStart, ParameterCount: Int32): Boolean; forward;

function ParserInClassBody(const Parser: TParser): Boolean;
begin
  Result := (Parser.Symbols <> nil) and
    (Parser.Symbols^.CurrentScope >= 0) and
    (Parser.Symbols^.CurrentScope <= High(Parser.Symbols^.Scopes)) and
    (Parser.Symbols^.Scopes[Parser.Symbols^.CurrentScope].Kind = scClass);
end;

function TokenCanNameClass(Kind: TTokenKind): Boolean;
begin
  Result := Kind in [tkIdentifier, tkLink, tkHead, tkProcess];
end;

function TokenCanBeIdentifier(const Parser: TParser; Kind: TTokenKind): Boolean;
begin
  { Several words are keywords only in a particular syntactic position.
    Treat them as contextual identifiers when a declaration/name is required.
    This matters for perfectly ordinary names such as `value`, `step`, `task`
    and C fields such as `low`.  Do not make the lexer context-sensitive. }
  Result := (Kind = tkIdentifier) or
    (Kind in [tkName, tkValue, tkHead, tkLow, tkCondition, tkStep, tkTask,
      tkSend, tkReceive, tkCancel, tkJoin, tkIs]);
end;

function TokenResolvesAsIdentifier(const Parser: TParser; Kind: TTokenKind): Boolean;
var
  Name: RawByteString;
begin
  if Kind = tkIdentifier then Exit(True);
  if not TokenCanBeIdentifier(Parser, Kind) then Exit(False);
  Name := TokenText(Parser.Current);
  Result := (Parser.Symbols <> nil) and
    (SymLookup(Parser.Symbols^, Name) >= 0);
  if (not Result) and (Parser.Symbols <> nil) and
     (Parser.CurrentClass >= 0) then
    Result := SymLookupMember(Parser.Symbols^, Parser.CurrentClass, Name) >= 0;
end;

function TokenCanNameMember(const Parser: TParser; Kind: TTokenKind): Boolean;
begin
  { A few old BASICIO names have dedicated statement tokens. after a dot they
    are just ordinary attribute names though. keeping that distinction here
    avoids teaching the lexer some horrible context-sensitive trick. }
  Result := TokenCanBeIdentifier(Parser, Kind) or
    (Kind in [tkOutText, tkOutInt, tkOutReal, tkOutFix, tkOutChar, tkOutImage,
      tkInInt, tkInReal, tkInChar, tkInText]);
end;

type
  TClassicFormal = record
    Name: RawByteString;
    Span: TSourceSpan;
    TypeId: Int32;
    Mode: TPassingMode;
    TypeSpecified: Boolean;
    ModeSpecified: Boolean;
  end;
  TClassicFormalArray = array of TClassicFormal;

  TClassicProtection = record
    Name: RawByteString;
    Span: TSourceSpan;
    IsProtected: Boolean;
    IsHidden: Boolean;
  end;
  TClassicProtectionArray = array of TClassicProtection;

function ClassicFormalIndex(const Formals: TClassicFormalArray;
  const Name: RawByteString): Int32;
var
  I: Integer;
begin
  for I := 0 to High(Formals) do
    if ASCIIEqualFold(Formals[I].Name, Name) then Exit(I);
  Result := FSIM_INVALID_INDEX;
end;

function ParameterListIsClassic(const Parser: TParser): Boolean;
var
  Probe: TParser;
begin
  Result := False;
  if not At(Parser, tkLParen) or
     not TokenCanBeIdentifier(Parser, Parser.Lookahead.Kind) then Exit;
  Probe := Parser;
  Advance(Probe);
  if not TokenCanBeIdentifier(Probe, Probe.Current.Kind) then Exit;
  Advance(Probe);
  Result := Probe.Current.Kind in [tkComma, tkRParen];
end;

procedure ParseClassicFormalNames(var Parser: TParser;
  out Formals: TClassicFormalArray);
var
  Name: RawByteString;
  Span: TSourceSpan;
  Index: Int32;
begin
  SetLength(Formals, 0);
  Expect(Parser, tkLParen);
  if Accept(Parser, tkRParen) then Exit;
  repeat
    if not ExpectIdentifier(Parser, Name, Span) then Break;
    if ClassicFormalIndex(Formals, Name) >= 0 then
      AddError(Parser.Diagnostics^, dcDuplicateSymbol, Span,
        'duplicate formal parameter ''' + Name + '''')
    else
    begin
      Index := Length(Formals);
      SetLength(Formals, Index + 1);
      Formals[Index] := Default(TClassicFormal);
      Formals[Index].Name := Name;
      Formals[Index].Span := Span;
      Formals[Index].TypeId := FSIM_TYPE_INVALID;
      Formals[Index].Mode := pmValue;
    end;
  until not Accept(Parser, tkComma);
  Expect(Parser, tkRParen);
end;

function FormalDefaultMode(const Symbols: TSymbolTable;
  TypeId: Int32): TPassingMode;
begin
  if (TypeId >= 0) and (TypeId <= High(Symbols.Types)) and
     ((tfReferenceType in Symbols.Types[TypeId].Flags) or
      (Symbols.Types[TypeId].Kind in [tyText, tyString, tyArray,
       tyProcedure])) then
    Result := pmReference
  else
    Result := pmValue;
end;

procedure ApplyFormalModeClause(var Parser: TParser;
  var Formals: TClassicFormalArray; Mode: TPassingMode;
  ClassParameters: Boolean);
var
  Name: RawByteString;
  Span: TSourceSpan;
  Index: Int32;
begin
  if ClassParameters and (Mode = pmName) then
    ParserError(Parser, dcDialectViolation,
      'class parameters cannot use call-by-name');
  Advance(Parser);
  repeat
    if not ExpectIdentifier(Parser, Name, Span) then Break;
    Index := ClassicFormalIndex(Formals, Name);
    if Index < 0 then
      AddError(Parser.Diagnostics^, dcUnknownSymbol, Span,
        'mode clause names unknown formal parameter ''' + Name + '''')
    else if Formals[Index].ModeSpecified then
      AddError(Parser.Diagnostics^, dcDuplicateSymbol, Span,
        'formal parameter mode is specified more than once for ''' + Name + '''')
    else
    begin
      Formals[Index].Mode := Mode;
      Formals[Index].ModeSpecified := True;
    end;
  until not Accept(Parser, tkComma);
  Expect(Parser, tkSemicolon);
end;

procedure ApplyFormalTypeNames(var Parser: TParser;
  var Formals: TClassicFormalArray; TypeId: Int32);
var
  Name: RawByteString;
  Span: TSourceSpan;
  Index: Int32;
begin
  repeat
    if not ExpectIdentifier(Parser, Name, Span) then Break;
    Index := ClassicFormalIndex(Formals, Name);
    if Index < 0 then
      AddError(Parser.Diagnostics^, dcUnknownSymbol, Span,
        'type specification names unknown formal parameter ''' + Name + '''')
    else if Formals[Index].TypeSpecified then
      AddError(Parser.Diagnostics^, dcDuplicateSymbol, Span,
        'formal parameter type is specified more than once for ''' + Name + '''')
    else
    begin
      Formals[Index].TypeId := TypeId;
      Formals[Index].TypeSpecified := True;
    end;
  until not Accept(Parser, tkComma);
  Expect(Parser, tkSemicolon);
end;

procedure ParseClassicFormalSpecifications(var Parser: TParser;
  var Formals: TClassicFormalArray; ClassParameters: Boolean);
var
  TypeId, ReturnType: Int32;
  IsArray: Boolean;
begin
  while True do
  begin
    if At(Parser, tkValue) then
    begin
      ApplyFormalModeClause(Parser, Formals, pmValue, ClassParameters);
      Continue;
    end;
    if At(Parser, tkName) then
    begin
      ApplyFormalModeClause(Parser, Formals, pmName, ClassParameters);
      Continue;
    end;
    IsArray := False;
    ReturnType := FSIM_TYPE_VOID;
    if At(Parser, tkArray) then
    begin
      Advance(Parser);
      TypeId := FSIM_TYPE_REAL;
      IsArray := True;
    end
    else if At(Parser, tkLabel) or At(Parser, tkSwitch) then
    begin
      Advance(Parser);
      TypeId := FSIM_TYPE_INTEGER;
    end
    else if At(Parser, tkProcedure) then
    begin
      Advance(Parser);
      TypeId := SymMakeProcedureType(Parser.Symbols^, FSIM_TYPE_VOID,
        Length(Parser.Symbols^.Parameters), 0, True);
    end
    else if TokenStartsType(Parser.Current.Kind) or
            CurrentTokenIsTypeAlias(Parser) then
    begin
      TypeId := ParseType(Parser);
      if Accept(Parser, tkArray) then IsArray := True
      else if Accept(Parser, tkProcedure) then
      begin
        ReturnType := TypeId;
        TypeId := SymMakeProcedureType(Parser.Symbols^, ReturnType,
          Length(Parser.Symbols^.Parameters), 0, True);
      end;
    end
    else
      Break;
    if IsArray then
      TypeId := SymMakeArrayType(Parser.Symbols^, TypeId, 0, -1);
    ApplyFormalTypeNames(Parser, Formals, TypeId);
  end;
end;

procedure RegisterClassicFormals(var Parser: TParser; OwnerNode,
  OwnerSymbol: Int32; var Formals: TClassicFormalArray;
  ClassParameters: Boolean; out ParameterStart, ParameterCount: Int32);
var
  I, Node, SymbolId, TypeId: Int32;
  Kind: TSymbolKind;
  Visibility: TVisibility;
begin
  ParameterStart := Length(Parser.Symbols^.Parameters);
  ParameterCount := Length(Formals);
  for I := 0 to High(Formals) do
  begin
    if not Formals[I].TypeSpecified then
    begin
      AddError(Parser.Diagnostics^, dcUnknownType, Formals[I].Span,
        'formal parameter ''' + Formals[I].Name + ''' has no type specification');
      Formals[I].TypeId := FSIM_TYPE_REAL;
    end;
    TypeId := Formals[I].TypeId;
    if not Formals[I].ModeSpecified then
      Formals[I].Mode := FormalDefaultMode(Parser.Symbols^, TypeId);
    Node := ASTAddNamedNode(Parser.Tree^, nkParameterDecl,
      Formals[I].Span, Formals[I].Name);
    Parser.Tree^.Nodes[Node].TypeId := TypeId;
    if Formals[I].Mode = pmValue then
      Include(Parser.Tree^.Nodes[Node].Flags, nfValueParameter)
    else if Formals[I].Mode = pmName then
      Include(Parser.Tree^.Nodes[Node].Flags, nfNameParameter);
    if ClassParameters then
    begin
      Kind := skField;
      Visibility := visPublic;
    end
    else
    begin
      Kind := skParameter;
      Visibility := visPrivate;
    end;
    SymbolId := SymAdd(Parser.Symbols^, Formals[I].Name, Kind, TypeId,
      Visibility, [sfMutable], Node, Formals[I].Span);
    Parser.Tree^.Nodes[Node].SymbolId := SymbolId;
    if SymbolId >= 0 then
    begin
      Parser.Symbols^.Symbols[SymbolId].ParameterIndex := I;
      if Formals[I].Mode = pmValue then
        Include(Parser.Symbols^.Symbols[SymbolId].Flags, sfValueParameter)
      else if Formals[I].Mode = pmName then
        Include(Parser.Symbols^.Symbols[SymbolId].Flags, sfNameParameter);
      if ClassParameters then
        SymAddField(Parser.Symbols^, OwnerSymbol, SymbolId, TypeId, visPublic);
    end;
    SymAddParameter(Parser.Symbols^, Formals[I].Name, TypeId,
      Formals[I].Mode, SymbolId, FSIM_INVALID_INDEX);
    ASTAppendChild(Parser.Tree^, OwnerNode, Node);
  end;
  if ClassParameters then
    SymSetClassParameters(Parser.Symbols^, OwnerSymbol,
      ParameterStart, ParameterCount);
end;

procedure Advance(var Parser: TParser);
begin
  Parser.Previous := Parser.Current;
  Parser.Current := Parser.Lookahead;
  LexerNext(Parser.Lexer);
  Parser.Lookahead := Parser.Lexer.Current;
  Parser.ErrorRecovery := False;
end;

function At(const Parser: TParser; Kind: TTokenKind): Boolean; inline;
begin
  Result := Parser.Current.Kind = Kind;
end;

function LookAt(const Parser: TParser; Kind: TTokenKind): Boolean; inline;
begin
  Result := Parser.Lookahead.Kind = Kind;
end;

function Accept(var Parser: TParser; Kind: TTokenKind): Boolean;
begin
  Result := At(Parser, Kind);
  if Result then
    Advance(Parser);
end;

procedure ParserErrorAt(var Parser: TParser; const Token: TToken;
  Code: TDiagnosticCode; const MessageText: RawByteString);
begin
  if Parser.ErrorRecovery then
    Exit;
  AddError(Parser.Diagnostics^, Code, Token.Span, MessageText);
  Parser.ErrorRecovery := True;
end;

procedure ParserError(var Parser: TParser; Code: TDiagnosticCode;
  const MessageText: RawByteString);
begin
  ParserErrorAt(Parser, Parser.Current, Code, MessageText);
end;

procedure DialectError(var Parser: TParser; const FeatureName: RawByteString);
begin
  if Parser.Options^.Dialect = fdSimula67 then
    ParserError(Parser, dcDialectViolation,
      FeatureName + ' is unavailable in -std=simula67');
end;

procedure CheckIdentifierDialect(var Parser: TParser; const Name: RawByteString;
  const Span: TSourceSpan);
begin
  if (Parser.Options^.Dialect = fdSimula67) and (Pos('_', Name) > 0) then
    AddError(Parser.Diagnostics^, dcDialectViolation, Span,
      'underscore identifiers are a Free Simula extension; use letters and digits in -std=simula67');
end;

function Expect(var Parser: TParser; Kind: TTokenKind): Boolean;
begin
  if At(Parser, Kind) then
  begin
    Advance(Parser);
    Exit(True);
  end;
  ParserError(Parser, dcExpectedToken,
    'expected ' + TokenKindName(Kind) + ', found ' +
    TokenKindName(Parser.Current.Kind));
  Result := False;
end;

function ExpectIdentifier(var Parser: TParser; out Name: RawByteString;
  out Span: TSourceSpan): Boolean;
begin
  Span := Parser.Current.Span;
  if not TokenCanBeIdentifier(Parser, Parser.Current.Kind) then
  begin
    ParserError(Parser, dcExpectedToken,
      'expected identifier, found ' + TokenKindName(Parser.Current.Kind));
    Name := '';
    Exit(False);
  end;
  Name := TokenText(Parser.Current);
  CheckIdentifierDialect(Parser, Name, Span);
  Advance(Parser);
  Result := True;
end;

function ExpectRoutineIdentifier(var Parser: TParser; out Name: RawByteString;
  out Span: TSourceSpan): Boolean;
begin
  Span := Parser.Current.Span;
  if not (TokenCanBeIdentifier(Parser, Parser.Current.Kind) or
      (Parser.Current.Kind in [tkAbs, tkMin, tkMax, tkMod, tkRem])) then
  begin
    ParserError(Parser, dcExpectedToken,
      'expected routine name, found ' + TokenKindName(Parser.Current.Kind));
    Name := '';
    Exit(False);
  end;
  Name := TokenText(Parser.Current);
  CheckIdentifierDialect(Parser, Name, Span);
  Advance(Parser);
  Result := True;
end;

function ExpectClassIdentifier(var Parser: TParser;
  out Name: RawByteString; out Span: TSourceSpan): Boolean;
begin
  Span := Parser.Current.Span;
  if not (Parser.Current.Kind in [tkIdentifier, tkLink, tkHead, tkProcess]) then
  begin
    ParserError(Parser, dcExpectedToken,
      'expected class identifier, found ' +
      TokenKindName(Parser.Current.Kind));
    Name := '';
    Exit(False);
  end;
  Name := TokenText(Parser.Current);
  CheckIdentifierDialect(Parser, Name, Span);
  Advance(Parser);
  Result := True;
end;

procedure Synchronize(var Parser: TParser);
begin
  Parser.ErrorRecovery := False;
  while not At(Parser, tkEOF) do
  begin
    if Parser.Previous.Kind = tkSemicolon then
      Exit;
    if Parser.Current.Kind in [tkClass, tkProcess, tkThread, tkTask, tkProcedure,
      tkFunction, tkInteger, tkLong, tkShort, tkReal, tkBoolean, tkCharacter,
      tkText, tkString, tkRef, tkHead, tkLink, tkBegin, tkIf, tkWhile, tkFor,
      tkTry, tkReturn, tkEnd, tkPublic, tkPrivate, tkProtected] then
      Exit;
    Advance(Parser);
  end;
end;

function NodeSpanFrom(const StartToken, EndToken: TToken): TSourceSpan; inline;
begin
  Result.StartPos := StartToken.Span.StartPos;
  Result.EndPos := EndToken.Span.EndPos;
end;

function MakeNode(var Parser: TParser; Kind: TASTNodeKind;
  const StartToken: TToken): Int32;
begin
  Result := ASTAddNode(Parser.Tree^, Kind,
    SourceSpan(StartToken.Span.StartPos, Parser.Previous.Span.EndPos));
end;

function MakeNamedNode(var Parser: TParser; Kind: TASTNodeKind;
  const StartToken: TToken; const Name: RawByteString): Int32;
begin
  Result := ASTAddNamedNode(Parser.Tree^, Kind,
    SourceSpan(StartToken.Span.StartPos, Parser.Previous.Span.EndPos), Name);
end;

function ParseType(var Parser: TParser): Int32;
var
  Start: TToken;
  Name: RawByteString;
  Span: TSourceSpan;
  ClassSymbol: Int32;
  ElementType, ReturnType, ParameterStart, ParameterCount, ParameterType: Int32;
  LowerBound, UpperBound: Int64;
  Variadic: Boolean;
  ParameterMode: TPassingMode;
  ParameterTypes: array of Int32;
  ParameterModes: array of TPassingMode;
  I: Int32;
begin
  Start := Parser.Current;
  case Parser.Current.Kind of
    tkInteger:
      begin
        Advance(Parser);
        Result := FSIM_TYPE_INTEGER;
      end;
    tkLong:
      begin
        Advance(Parser);
        if Accept(Parser, tkReal) then
          { the backend real is already 64 bit. old simula calls this long real,
            pretending the spelling never existed was a stupid incompatibility. }
          Result := FSIM_TYPE_REAL
        else
        begin
          Expect(Parser, tkInteger);
          Result := FSIM_TYPE_LONG_INTEGER;
        end;
      end;
    tkShort:
      begin
        Advance(Parser);
        Expect(Parser, tkInteger);
        Result := FSIM_TYPE_SHORT_INTEGER;
      end;
    tkReal:
      begin
        Advance(Parser);
        Result := FSIM_TYPE_REAL;
      end;
    tkBoolean:
      begin
        Advance(Parser);
        Result := FSIM_TYPE_BOOLEAN;
      end;
    tkCharacter:
      begin
        Advance(Parser);
        Result := FSIM_TYPE_CHARACTER;
      end;
    tkText:
      begin
        Advance(Parser);
        Result := FSIM_TYPE_TEXT;
        if Accept(Parser, tkLParen) then
        begin
          if not At(Parser, tkIntegerLiteral) then
            ParserError(Parser, dcExpectedToken,
              'text length must be an integer literal')
          else
            Advance(Parser);
          Expect(Parser, tkRParen);
        end;
      end;
    tkString:
      begin
        DialectError(Parser, 'dynamic string');
        Advance(Parser);
        Result := FSIM_TYPE_STRING;
      end;
    tkHead:
      begin
        Advance(Parser);
        Result := FSIM_TYPE_HEAD;
      end;
    tkLink:
      begin
        Advance(Parser);
        Result := FSIM_TYPE_LINK;
      end;
    tkChannel:
      begin
        DialectError(Parser, 'typed channel');
        Advance(Parser);
        ElementType := FSIM_TYPE_INTEGER;
        if Accept(Parser, tkLParen) then
        begin
          ElementType := ParseType(Parser);
          Expect(Parser, tkRParen);
        end
        else if Accept(Parser, tkOf) then
          ElementType := ParseType(Parser);
        Result := SymMakeChannelType(Parser.Symbols^, ElementType);
      end;
    tkFuture:
      begin
        DialectError(Parser, 'typed future');
        Advance(Parser);
        ElementType := FSIM_TYPE_INTEGER;
        if Accept(Parser, tkLParen) then
        begin
          ElementType := ParseType(Parser);
          Expect(Parser, tkRParen);
        end
        else if Accept(Parser, tkOf) then
          ElementType := ParseType(Parser);
        Result := SymMakeFutureType(Parser.Symbols^, ElementType);
      end;
    tkMutex:
      begin
        DialectError(Parser, 'mutex type');
        Advance(Parser);
        Result := FSIM_TYPE_MUTEX;
      end;
    tkSemaphore:
      begin
        DialectError(Parser, 'semaphore type');
        Advance(Parser);
        Result := FSIM_TYPE_SEMAPHORE;
      end;
    tkBarrier:
      begin
        DialectError(Parser, 'barrier type');
        Advance(Parser);
        Result := FSIM_TYPE_BARRIER;
      end;
    tkCondition:
      begin
        DialectError(Parser, 'condition type');
        Advance(Parser);
        Result := FSIM_TYPE_CONDITION;
      end;
    tkAtomic:
      begin
        DialectError(Parser, 'atomic type');
        Advance(Parser);
        ElementType := FSIM_TYPE_INTEGER;
        if Accept(Parser, tkLParen) then
        begin
          ElementType := ParseType(Parser);
          Expect(Parser, tkRParen);
        end;
        if ElementType <> FSIM_TYPE_INTEGER then
        begin
          AddError(Parser.Diagnostics^, dcTypeMismatch, Parser.Previous.Span,
            'atomic currently requires integer storage');
          Result := FSIM_TYPE_INVALID;
        end
        else
          Result := FSIM_TYPE_ATOMIC;
      end;
    tkProcedure:
      begin
        DialectError(Parser, 'first-class procedure type');
        Advance(Parser);
        SetLength(ParameterTypes, 0);
        SetLength(ParameterModes, 0);
        Expect(Parser, tkLParen);
        if not At(Parser, tkRParen) then
        begin
          repeat
            ParameterMode := pmValue;
            if Accept(Parser, tkValue) then ParameterMode := pmValue
            else if Accept(Parser, tkName) then ParameterMode := pmName
            else if At(Parser, tkRef) and not LookAt(Parser, tkLParen) then
            begin
              Advance(Parser);
              ParameterMode := pmReference;
            end;
            ParameterType := ParseType(Parser);
            SetLength(ParameterTypes, Length(ParameterTypes) + 1);
            SetLength(ParameterModes, Length(ParameterModes) + 1);
            ParameterTypes[High(ParameterTypes)] := ParameterType;
            ParameterModes[High(ParameterModes)] := ParameterMode;
          until not Accept(Parser, tkComma);
        end;
        Expect(Parser, tkRParen);
        ReturnType := FSIM_TYPE_VOID;
        if Accept(Parser, tkColon) then ReturnType := ParseType(Parser);
        { Nested callable types may append their own parameter descriptors while
          being parsed. Append this callable's descriptors only after every
          nested type is complete. }
        ParameterStart := Length(Parser.Symbols^.Parameters);
        ParameterCount := Length(ParameterTypes);
        for I := 0 to ParameterCount - 1 do
          SymAddParameter(Parser.Symbols^, '', ParameterTypes[I],
            ParameterModes[I], FSIM_INVALID_INDEX, FSIM_INVALID_INDEX);
        Result := SymMakeProcedureType(Parser.Symbols^, ReturnType,
          ParameterStart, ParameterCount);
      end;
    tkRef:
      begin
        Advance(Parser);
        Expect(Parser, tkLParen);
        if ExpectClassIdentifier(Parser, Name, Span) then
        begin
          ClassSymbol := SymLookupClass(Parser.Symbols^, Name);
          if ClassSymbol < 0 then
          begin
            AddError(Parser.Diagnostics^, dcUnknownType, Span,
              'unknown class ''' + Name + ''' in reference type');
            Result := FSIM_TYPE_INVALID;
          end
          else
            Result := SymMakeReferenceType(Parser.Symbols^, ClassSymbol);
        end
        else
          Result := FSIM_TYPE_INVALID;
        Expect(Parser, tkRParen);
      end;
    tkArray:
      begin
        Advance(Parser);
        Expect(Parser, tkLBracket);
        LowerBound := 0;
        UpperBound := -1;
        ParseSignedConstantInteger(Parser, LowerBound);
        Expect(Parser, tkColon);
        ParseSignedConstantInteger(Parser, UpperBound);
        Expect(Parser, tkRBracket);
        if Accept(Parser, tkOf) then
          ;
        ElementType := ParseType(Parser);
        if (ElementType < 0) or (ElementType > High(Parser.Symbols^.Types)) or
           (ElementType = FSIM_TYPE_VOID) or
           not (tfComplete in Parser.Symbols^.Types[ElementType].Flags) then
        begin
          ParserErrorAt(Parser, Start, dcTypeMismatch,
            'array element type must be a complete value type');
          Result := FSIM_TYPE_INVALID;
        end
        else
          Result := SymMakeArrayType(Parser.Symbols^, ElementType,
            LowerBound, UpperBound);
      end;
    tkIdentifier:
      begin
        Name := TokenText(Parser.Current);
        Span := Parser.Current.Span;
        ClassSymbol := SymLookup(Parser.Symbols^, Name);
        if (ClassSymbol < 0) or
           (Parser.Symbols^.Symbols[ClassSymbol].Kind <> skType) then
        begin
          AddError(Parser.Diagnostics^, dcUnknownType, Span,
            'unknown type ''' + Name + '''');
          Result := FSIM_TYPE_INVALID;
          Advance(Parser);
        end
        else
        begin
          Result := Parser.Symbols^.Symbols[ClassSymbol].TypeId;
          Advance(Parser);
          if (Result = FSIM_TYPE_C_PTR) and Accept(Parser, tkLParen) then
          begin
            DialectError(Parser, 'typed C pointer');
            ElementType := ParseType(Parser);
            Expect(Parser, tkRParen);
            if ElementType = FSIM_TYPE_VOID then
              Result := FSIM_TYPE_C_PTR
            else if not SymIsCPointeeType(Parser.Symbols^, ElementType) then
            begin
              AddError(Parser.Diagnostics^, dcTypeMismatch, Span,
                'c_ptr(T) requires a C-layout element type, got ' +
                TypeName(Parser.Symbols^, ElementType));
              Result := FSIM_TYPE_INVALID;
            end
            else
              Result := SymMakeCPointerType(Parser.Symbols^, ElementType);
          end
          else if (Result = FSIM_TYPE_C_FN) and Accept(Parser, tkLParen) then
          begin
            DialectError(Parser, 'typed C function pointer');
            SetLength(ParameterTypes, 0);
            Variadic := False;
            if not At(Parser, tkRParen) then
            begin
              repeat
                if Accept(Parser, tkEllipsis) then
                begin
                  Variadic := True;
                  Break;
                end;
                ParameterType := ParseType(Parser);
                if not SymIsCABIType(Parser.Symbols^, ParameterType, False) then
                  AddError(Parser.Diagnostics^, dcTypeMismatch, Span,
                    'c_fn parameter needs a C ABI type, got ' +
                    TypeName(Parser.Symbols^, ParameterType));
                SetLength(ParameterTypes, Length(ParameterTypes) + 1);
                ParameterTypes[High(ParameterTypes)] := ParameterType;
                if At(Parser, tkEllipsis) then
                begin
                  Advance(Parser);
                  Variadic := True;
                  Break;
                end;
              until not Accept(Parser, tkComma);
            end;
            Expect(Parser, tkRParen);
            Expect(Parser, tkColon);
            ReturnType := ParseType(Parser);
            if not SymIsCABIType(Parser.Symbols^, ReturnType, True) then
              AddError(Parser.Diagnostics^, dcTypeMismatch, Span,
                'c_fn return type needs a C ABI type, got ' +
                TypeName(Parser.Symbols^, ReturnType));
            ParameterStart := Length(Parser.Symbols^.Parameters);
            ParameterCount := Length(ParameterTypes);
            for I := 0 to ParameterCount - 1 do
              SymAddParameter(Parser.Symbols^, '', ParameterTypes[I], pmValue,
                FSIM_INVALID_INDEX, FSIM_INVALID_INDEX);
            Result := SymMakeCFunctionType(Parser.Symbols^, ReturnType,
              ParameterStart, ParameterCount, Variadic);
          end;
        end;
      end;
  else
    begin
      ParserError(Parser, dcExpectedToken,
        'expected a type, found ' + TokenKindName(Parser.Current.Kind));
      if not At(Parser, tkEOF) then
        Advance(Parser);
      Result := FSIM_TYPE_INVALID;
    end;
  end;
  if Start.Kind = tkInvalid then
    Result := FSIM_TYPE_INVALID;
end;

function CurrentTokenIsTypeAlias(const Parser: TParser): Boolean;
var
  SymbolId: Int32;
begin
  Result := False;
  if Parser.Current.Kind <> tkIdentifier then
    Exit;
  SymbolId := SymLookup(Parser.Symbols^, TokenText(Parser.Current));
  Result := (SymbolId >= 0) and
    (Parser.Symbols^.Symbols[SymbolId].Kind = skType);
end;

function ParserStartsDeclaration(const Parser: TParser): Boolean;
begin
  { Contextual keywords stop being declaration starters once a symbol with
    that spelling is visible.  Without this, `task :- ...` after `var task`
    gets reparsed as the beginning of `Task Class`. }
  if (Parser.Current.Kind <> tkIdentifier) and
     TokenResolvesAsIdentifier(Parser, Parser.Current.Kind) then
    Exit(False);
  Result := TokenStartsDeclaration(Parser.Current.Kind) or
    CurrentTokenIsTypeAlias(Parser);
end;

function ParseExpression(var Parser: TParser): Int32; forward;
function ParseStatement(var Parser: TParser): Int32; forward;
function ParseDeclaration(var Parser: TParser; ParentNode: Int32): Int32; forward;

function ParseArgumentList(var Parser: TParser; CallNode: Int32): Int32;
var
  ArgumentNode: Int32;
begin
  Result := 0;
  if At(Parser, tkRParen) then
    Exit;
  repeat
    ArgumentNode := ParseExpression(Parser);
    if ArgumentNode <> FSIM_INVALID_INDEX then
    begin
      ASTAppendChild(Parser.Tree^, CallNode, ArgumentNode);
      Inc(Result);
    end;
  until not Accept(Parser, tkComma);
end;

function ParsePrimary(var Parser: TParser): Int32;
var
  Start: TToken;
  Name: RawByteString;
  Span: TSourceSpan;
  Node, ClassSymbol, ConversionType: Int32;
  LambdaRoutineNode, LambdaSymbol, SavedRoutine, SavedClass: Int32;
  ParameterStart, ParameterCount, ReturnType, ProcedureType: Int32;
  ConversionHasSuffix: Boolean;
begin
  Start := Parser.Current;

  { In fsim, the built-in scalar type words are also conversion constructors.
    C ABI types already take this path through normal type symbols; keeping the
    primitive spellings here makes `real(x)` and `integer(x)` behave the same
    way instead of making the lexer choice leak into the language. }
  if Parser.Options^.Dialect = fdFSim then
  begin
    ConversionType := FSIM_TYPE_INVALID;
    ConversionHasSuffix := False;
    case Parser.Current.Kind of
      tkInteger: ConversionType := FSIM_TYPE_INTEGER;
      tkReal: ConversionType := FSIM_TYPE_REAL;
      tkBoolean: ConversionType := FSIM_TYPE_BOOLEAN;
      tkCharacter: ConversionType := FSIM_TYPE_CHARACTER;
      tkLong:
        if LookAt(Parser, tkInteger) then
        begin
          ConversionType := FSIM_TYPE_LONG_INTEGER;
          ConversionHasSuffix := True;
        end
        else if LookAt(Parser, tkReal) then
        begin
          ConversionType := FSIM_TYPE_REAL;
          ConversionHasSuffix := True;
        end;
      tkShort:
        if LookAt(Parser, tkInteger) then
        begin
          ConversionType := FSIM_TYPE_SHORT_INTEGER;
          ConversionHasSuffix := True;
        end;
    end;
    if ConversionType <> FSIM_TYPE_INVALID then
    begin
      Advance(Parser);
      if ConversionHasSuffix then Advance(Parser);
      if not Accept(Parser, tkLParen) then
      begin
        ParserErrorAt(Parser, Start, dcExpectedToken,
          'a scalar type name in expression position must be followed by ''(''');
        Exit(FSIM_INVALID_INDEX);
      end;
      Node := MakeNode(Parser, nkConversionExpr, Start);
      Parser.Tree^.Nodes[Node].TypeId := ConversionType;
      ASTAppendChild(Parser.Tree^, Node, ParseExpression(Parser));
      if Accept(Parser, tkComma) then
      begin
        ParserError(Parser, dcInvalidCall,
          'type conversion accepts exactly one operand');
        while not At(Parser, tkRParen) and not At(Parser, tkEOF) do
          Advance(Parser);
      end;
      Expect(Parser, tkRParen);
      Exit(Node);
    end;
  end;
  if (Parser.Current.Kind <> tkIdentifier) and
     TokenResolvesAsIdentifier(Parser, Parser.Current.Kind) then
  begin
    Name := TokenText(Parser.Current);
    Advance(Parser);
    Node := MakeNamedNode(Parser, nkIdentifierExpr, Start, Name);
    Include(Parser.Tree^.Nodes[Node].Flags, nfLValue);
    Exit(Node);
  end;
  case Parser.Current.Kind of
    tkIntegerLiteral:
      begin
        Advance(Parser);
        Node := MakeNode(Parser, nkIntegerLiteralExpr, Start);
        Parser.Tree^.Nodes[Node].IntValue := Start.IntValue;
        Parser.Tree^.Nodes[Node].TypeId := FSIM_TYPE_INTEGER;
        Exit(Node);
      end;
    tkRealLiteral:
      begin
        Advance(Parser);
        Node := MakeNode(Parser, nkRealLiteralExpr, Start);
        Parser.Tree^.Nodes[Node].RealValue := Start.RealValue;
        Parser.Tree^.Nodes[Node].TypeId := FSIM_TYPE_REAL;
        Exit(Node);
      end;
    tkCharacterLiteral:
      begin
        Advance(Parser);
        Node := MakeNode(Parser, nkCharacterLiteralExpr, Start);
        Parser.Tree^.Nodes[Node].IntValue := Start.IntValue;
        Parser.Tree^.Nodes[Node].TypeId := FSIM_TYPE_CHARACTER;
        Exit(Node);
      end;
    tkStringLiteral:
      begin
        Name := TokenText(Start);
        Span := Start.Span;
        Advance(Parser);
        while At(Parser, tkStringLiteral) do
        begin
          { adjacent simple strings are one string in simula, this looks odd
            until you meet old listings that wrap every long message this way }
          Name := Name + TokenText(Parser.Current);
          Span.EndPos := Parser.Current.Span.EndPos;
          Advance(Parser);
        end;
        Node := MakeNode(Parser, nkStringLiteralExpr, Start);
        Parser.Tree^.Nodes[Node].Span := Span;
        Parser.Tree^.Nodes[Node].StringId := StringPoolIntern(
          Parser.Tree^.Strings, Name);
        if Parser.Options^.Dialect = fdSimula67 then
          Parser.Tree^.Nodes[Node].TypeId := FSIM_TYPE_TEXT
        else
          Parser.Tree^.Nodes[Node].TypeId := FSIM_TYPE_STRING;
        Exit(Node);
      end;
    tkTrue, tkFalse:
      begin
        Advance(Parser);
        Node := MakeNode(Parser, nkBooleanLiteralExpr, Start);
        Parser.Tree^.Nodes[Node].IntValue := Ord(Start.Kind = tkTrue);
        Parser.Tree^.Nodes[Node].TypeId := FSIM_TYPE_BOOLEAN;
        Exit(Node);
      end;
    tkNone:
      begin
        Advance(Parser);
        Node := MakeNode(Parser, nkNoneExpr, Start);
        Parser.Tree^.Nodes[Node].TypeId := FSIM_TYPE_VOID;
        Exit(Node);
      end;
    tkNoText:
      begin
        Advance(Parser);
        Node := MakeNode(Parser, nkStringLiteralExpr, Start);
        Parser.Tree^.Nodes[Node].StringId := StringPoolIntern(
          Parser.Tree^.Strings, '');
        Parser.Tree^.Nodes[Node].TypeId := FSIM_TYPE_TEXT;
        Exit(Node);
      end;
    tkThis:
      begin
        Advance(Parser);
        ClassSymbol := Parser.CurrentClass;
        Name := '';
        if Parser.Current.Kind in [tkIdentifier, tkLink, tkHead, tkProcess] then
        begin
          Name := TokenText(Parser.Current);
          Span := Parser.Current.Span;
          Advance(Parser);
          ClassSymbol := SymLookupClass(Parser.Symbols^, Name);
          if ClassSymbol < 0 then
            AddError(Parser.Diagnostics^, dcUnknownType, Span,
              'unknown class ''' + Name + ''' after ''this''');
        end
        else if Parser.Options^.Dialect = fdSimula67 then
          ParserErrorAt(Parser, Start, dcExpectedToken,
            'classic Simula requires ''this ClassName''');
        Node := MakeNamedNode(Parser, nkThisExpr, Start, Name);
        Parser.Tree^.Nodes[Node].SymbolId := ClassSymbol;
        if Parser.CurrentClass >= 0 then
        begin
          if (ClassSymbol >= 0) and
             not SymIsDerivedFrom(Parser.Symbols^, Parser.CurrentClass,
               ClassSymbol) then
            AddError(Parser.Diagnostics^, dcTypeMismatch, Start.Span,
              '''this '' qualifier must name the current class or a prefix class');
          if ClassSymbol < 0 then ClassSymbol := Parser.CurrentClass;
          Parser.Tree^.Nodes[Node].TypeId := SymMakeReferenceType(
            Parser.Symbols^, ClassSymbol);
        end
        else
          ParserErrorAt(Parser, Start, dcInvalidControlFlow,
            '''this'' is only valid inside a class');
        Exit(Node);
      end;
    tkLambda:
      begin
        if Parser.Options^.Dialect = fdSimula67 then
          ParserErrorAt(Parser, Start, dcDialectViolation,
            'lambda expressions are a Free Simula extension');
        Advance(Parser);
        Inc(Parser.LambdaCounter);
        Name := '$lambda$' + IntToStr(Parser.LambdaCounter);
        Node := MakeNamedNode(Parser, nkLambdaExpr, Start, Name);
        LambdaRoutineNode := ASTAddNamedNode(Parser.Tree^, nkFunctionDecl,
          Start.Span, Name);
        Include(Parser.Tree^.Nodes[LambdaRoutineNode].Flags, nfSynthetic);
        LambdaSymbol := SymAdd(Parser.Symbols^, Name, skFunction,
          FSIM_TYPE_INVALID, visPrivate, [sfDefined, sfSynthetic],
          LambdaRoutineNode, Start.Span);
        Parser.Tree^.Nodes[LambdaRoutineNode].SymbolId := LambdaSymbol;
        Parser.Tree^.Nodes[Node].SymbolId := LambdaSymbol;
        Parser.Tree^.Nodes[Node].BodyNode := LambdaRoutineNode;
        ASTAppendChild(Parser.Tree^, Node, LambdaRoutineNode);

        SavedRoutine := Parser.CurrentRoutine;
        SavedClass := Parser.Symbols^.CurrentClass;
        Parser.CurrentRoutine := LambdaSymbol;
        Parser.Symbols^.CurrentRoutine := LambdaSymbol;
        SymEnterScope(Parser.Symbols^, scFunction, LambdaSymbol);
        Parser.Tree^.Nodes[LambdaRoutineNode].Aux := Parser.Symbols^.CurrentScope;
        ParseParameterList(Parser, LambdaRoutineNode, ParameterStart,
          ParameterCount);
        if not Accept(Parser, tkColon) then
          ParserError(Parser, dcExpectedToken,
            'lambda result type is required before =>');
        ReturnType := ParseType(Parser);
        ProcedureType := SymMakeProcedureType(Parser.Symbols^, ReturnType,
          ParameterStart, ParameterCount);
        Parser.Tree^.Nodes[LambdaRoutineNode].TypeId := ProcedureType;
        Parser.Tree^.Nodes[Node].TypeId := ProcedureType;
        if LambdaSymbol >= 0 then
          Parser.Symbols^.Symbols[LambdaSymbol].TypeId := ProcedureType;
        Expect(Parser, tkArrow);
        ConversionType := ASTAddNode(Parser.Tree^, nkReturnStatement, Start.Span);
        ASTAppendChild(Parser.Tree^, ConversionType, ParseExpression(Parser));
        ASTAppendChild(Parser.Tree^, LambdaRoutineNode, ConversionType);
        Parser.Tree^.Nodes[LambdaRoutineNode].BodyNode := ConversionType;
        if LambdaSymbol >= 0 then
          Parser.Symbols^.Symbols[LambdaSymbol].BodyNode := ConversionType;
        SymLeaveScope(Parser.Symbols^);
        Parser.CurrentRoutine := SavedRoutine;
        Parser.Symbols^.CurrentRoutine := SavedRoutine;
        Parser.Symbols^.CurrentClass := SavedClass;
        Parser.Tree^.Nodes[Node].Span.EndPos := Parser.Previous.Span.EndPos;
        Exit(Node);
      end;
    tkIdentifier, tkAbs, tkMin, tkMax, tkMod, tkRem:
      begin
        { MOD and REM are both infix operators and standard-environment
          function names.  At primary position the grammar is unambiguous. }
        Name := TokenText(Parser.Current);
        Advance(Parser);
        Node := MakeNamedNode(Parser, nkIdentifierExpr, Start, Name);
        Include(Parser.Tree^.Nodes[Node].Flags, nfLValue);
        Exit(Node);
      end;
    tkNew:
      begin
        Advance(Parser);
        if ExpectClassIdentifier(Parser, Name, Span) then
        begin
          ClassSymbol := SymLookupClass(Parser.Symbols^, Name);
          if ClassSymbol < 0 then
            AddError(Parser.Diagnostics^, dcUnknownType, Span,
              'unknown class ''' + Name + '''')
          else
            ;
        end
        else
          ClassSymbol := FSIM_INVALID_INDEX;
        Node := MakeNamedNode(Parser, nkNewExpr, Start, Name);
        Parser.Tree^.Nodes[Node].SymbolId := ClassSymbol;
        if Accept(Parser, tkLParen) then
        begin
          ParseArgumentList(Parser, Node);
          Expect(Parser, tkRParen);
        end;
        Exit(Node);
      end;
    tkIf:
      begin
        Advance(Parser);
        Node := MakeNode(Parser, nkConditionalExpr, Start);
        ASTAppendChild(Parser.Tree^, Node, ParseExpression(Parser));
        Expect(Parser, tkThen);
        ASTAppendChild(Parser.Tree^, Node, ParseExpression(Parser));
        Expect(Parser, tkElse);
        ASTAppendChild(Parser.Tree^, Node, ParseExpression(Parser));
        Exit(Node);
      end;
    tkLParen:
      begin
        Advance(Parser);
        Node := ParseExpression(Parser);
        Expect(Parser, tkRParen);
        Exit(Node);
      end;
    tkSizeOf, tkTypeOf:
      begin
        DialectError(Parser, TokenKindName(Parser.Current.Kind));
        Advance(Parser);
        if Start.Kind = tkSizeOf then
          Node := MakeNode(Parser, nkSizeOfExpr, Start)
        else
          Node := MakeNode(Parser, nkTypeOfExpr, Start);
        Expect(Parser, tkLParen);
        ASTAppendChild(Parser.Tree^, Node, ParseExpression(Parser));
        Expect(Parser, tkRParen);
        Exit(Node);
      end;
  else
    ParserError(Parser, dcUnexpectedToken,
      'expected expression, found ' + TokenKindName(Parser.Current.Kind));
    if not At(Parser, tkEOF) then
      Advance(Parser);
    Result := FSIM_INVALID_INDEX;
  end;
end;

function ParserNodeArrayType(const Parser: TParser; Node: Int32): Int32;
var
  SymbolId, TypeId: Int32;
  Name: RawByteString;
begin
  Result := FSIM_TYPE_INVALID;
  if (Node < 0) or (Node > High(Parser.Tree^.Nodes)) then Exit;
  SymbolId := Parser.Tree^.Nodes[Node].SymbolId;
  if (SymbolId < 0) and
     (Parser.Tree^.Nodes[Node].Kind = nkIdentifierExpr) then
  begin
    Name := ASTNodeName(Parser.Tree^, Node);
    SymbolId := SymLookup(Parser.Symbols^, Name);
    if (SymbolId < 0) and (Parser.CurrentClass >= 0) then
      SymbolId := SymLookupMember(Parser.Symbols^, Parser.CurrentClass, Name);
  end;
  if (SymbolId < 0) or (SymbolId > High(Parser.Symbols^.Symbols)) then Exit;
  TypeId := Parser.Symbols^.Symbols[SymbolId].TypeId;
  if (TypeId >= 0) and (TypeId <= High(Parser.Symbols^.Types)) and
     (Parser.Symbols^.Types[TypeId].Kind = tyArray) then
    Result := TypeId;
end;

function ParserNodeTypeId(const Parser: TParser; Node: Int32): Int32;
var
  SymbolId: Int32;
  Name: RawByteString;
begin
  Result := FSIM_TYPE_INVALID;
  if (Node < 0) or (Node > High(Parser.Tree^.Nodes)) or
     (Parser.Tree^.Nodes[Node].Kind <> nkIdentifierExpr) then Exit;
  SymbolId := Parser.Tree^.Nodes[Node].SymbolId;
  if SymbolId < 0 then
  begin
    Name := ASTNodeName(Parser.Tree^, Node);
    SymbolId := SymLookup(Parser.Symbols^, Name);
  end;
  if (SymbolId >= 0) and (SymbolId <= High(Parser.Symbols^.Symbols)) and
     (Parser.Symbols^.Symbols[SymbolId].Kind = skType) then
    Result := Parser.Symbols^.Symbols[SymbolId].TypeId;
end;

function ParsePostfix(var Parser: TParser): Int32;
var
  Base, Node, IndexNode, CastType, ElementType: Int32;
  Start: TToken;
  Name: RawByteString;
  Span: TSourceSpan;
begin
  Base := ParsePrimary(Parser);
  while Base <> FSIM_INVALID_INDEX do
  begin
    if Accept(Parser, tkLParen) then
    begin
      Start := Parser.Previous;
      CastType := ParserNodeTypeId(Parser, Base);
      { c_ptr(T)(value) is a typed C pointer conversion, not a call on the
        result of c_ptr(T).  The first parentheses belong to the type
        constructor; ordinary c_ptr(value) keeps using the generic pointer
        conversion below. }
      if (CastType >= 0) and (CastType <= High(Parser.Symbols^.Types)) and
         (Parser.Symbols^.Types[CastType].Kind = tyCPointer) and
         (Parser.Symbols^.Types[CastType].ElementType = FSIM_TYPE_INVALID) and
         (TokenStartsType(Parser.Current.Kind) or CurrentTokenIsTypeAlias(Parser)) then
      begin
        ElementType := ParseType(Parser);
        Expect(Parser, tkRParen);
        CastType := SymMakeCPointerType(Parser.Symbols^, ElementType);
        if not Accept(Parser, tkLParen) then
        begin
          ParserError(Parser, dcExpectedToken,
            'typed c_ptr(T) in expression position must be followed by a value in parentheses');
          Base := FSIM_INVALID_INDEX;
          Continue;
        end;
        DialectError(Parser, 'explicit C pointer conversion');
        Node := MakeNode(Parser, nkConversionExpr, Start);
        Parser.Tree^.Nodes[Node].TypeId := CastType;
        IndexNode := ParseExpression(Parser);
        if IndexNode >= 0 then ASTAppendChild(Parser.Tree^, Node, IndexNode);
        if Accept(Parser, tkComma) then
          ParserError(Parser, dcInvalidCall,
            'type conversion accepts exactly one operand');
        Expect(Parser, tkRParen);
        Base := Node;
      end
      else if CastType <> FSIM_TYPE_INVALID then
      begin
        DialectError(Parser, 'explicit type conversion');
        Node := MakeNode(Parser, nkConversionExpr, Start);
        Parser.Tree^.Nodes[Node].TypeId := CastType;
        IndexNode := ParseExpression(Parser);
        if IndexNode >= 0 then ASTAppendChild(Parser.Tree^, Node, IndexNode);
        if Accept(Parser, tkComma) then
          ParserError(Parser, dcInvalidCall,
            'type conversion accepts exactly one operand');
        Expect(Parser, tkRParen);
        Base := Node;
      end
      else if ParserNodeArrayType(Parser, Base) <> FSIM_TYPE_INVALID then
      begin
        repeat
          IndexNode := ParseExpression(Parser);
          Node := MakeNode(Parser, nkIndexExpr, Start);
          Include(Parser.Tree^.Nodes[Node].Flags, nfLValue);
          ASTAppendChild(Parser.Tree^, Node, Base);
          if IndexNode >= 0 then ASTAppendChild(Parser.Tree^, Node, IndexNode);
          Base := Node;
        until not Accept(Parser, tkComma);
        Expect(Parser, tkRParen);
      end
      else
      begin
        Node := MakeNode(Parser, nkCallExpr, Start);
        ASTAppendChild(Parser.Tree^, Node, Base);
        if Parser.Tree^.Nodes[Base].Kind = nkIdentifierExpr then
        begin
          Name := ASTNodeName(Parser.Tree^, Base);
          if ASCIIEqualFold(Name, 'c_addr') then
            Parser.Tree^.Nodes[Node].Aux := FSIM_C_INTRINSIC_ADDR
          else if ASCIIEqualFold(Name, 'c_sizeof') then
            Parser.Tree^.Nodes[Node].Aux := FSIM_C_INTRINSIC_SIZEOF
          else if ASCIIEqualFold(Name, 'c_alignof') then
            Parser.Tree^.Nodes[Node].Aux := FSIM_C_INTRINSIC_ALIGNOF
          else if ASCIIEqualFold(Name, 'c_offsetof') then
            Parser.Tree^.Nodes[Node].Aux := FSIM_C_INTRINSIC_OFFSETOF;
        end;
        ParseArgumentList(Parser, Node);
        Expect(Parser, tkRParen);
        Base := Node;
      end;
    end
    else if Accept(Parser, tkDot) then
    begin
      Start := Parser.Previous;
      Span := Parser.Current.Span;
      if not TokenCanNameMember(Parser, Parser.Current.Kind) then
      begin
        ParserError(Parser, dcExpectedToken,
          'expected member name, found ' + TokenKindName(Parser.Current.Kind));
        Exit(Base);
      end;
      Name := TokenText(Parser.Current);
      Advance(Parser);
      Node := MakeNamedNode(Parser, nkMemberExpr, Start, Name);
      Include(Parser.Tree^.Nodes[Node].Flags, nfLValue);
      ASTAppendChild(Parser.Tree^, Node, Base);
      Base := Node;
    end
    else if Accept(Parser, tkLBracket) then
    begin
      Start := Parser.Previous;
      IndexNode := ParseExpression(Parser);
      Expect(Parser, tkRBracket);
      Node := MakeNode(Parser, nkIndexExpr, Start);
      Include(Parser.Tree^.Nodes[Node].Flags, nfLValue);
      ASTAppendChild(Parser.Tree^, Node, Base);
      if IndexNode <> FSIM_INVALID_INDEX then
        ASTAppendChild(Parser.Tree^, Node, IndexNode);
      Base := Node;
    end
    else if Accept(Parser, tkQua) then
    begin
      Start := Parser.Previous;
      if not ExpectClassIdentifier(Parser, Name, Span) then
        Exit(Base);
      Node := MakeNamedNode(Parser, nkQuaExpr, Start, Name);
      ASTAppendChild(Parser.Tree^, Node, Base);
      Base := Node;
    end
    else
      Break;
  end;
  Result := Base;
end;

function ParseUnary(var Parser: TParser): Int32;
var
  Start: TToken;
  Node, Operand: Int32;
  Op: TUnaryOperator;
begin
  Start := Parser.Current;
  case Parser.Current.Kind of
    tkAwait, tkAsync, tkSpawn, tkReceive:
      begin
        DialectError(Parser, TokenKindName(Parser.Current.Kind));
        Advance(Parser);
        if Accept(Parser, tkLParen) then
        begin
          Operand := ParseExpression(Parser);
          Expect(Parser, tkRParen);
        end
        else
          Operand := ParseUnary(Parser);
        case Start.Kind of
          tkAwait: Node := MakeNode(Parser, nkAwaitExpr, Start);
          tkAsync, tkSpawn: Node := MakeNode(Parser, nkSpawnExpr, Start);
        else
          Node := MakeNode(Parser, nkReceiveExpr, Start);
        end;
        if Operand <> FSIM_INVALID_INDEX then
          ASTAppendChild(Parser.Tree^, Node, Operand);
        Exit(Node);
      end;
    tkPlus: Op := uoPositive;
    tkMinus: Op := uoNegative;
    tkNot: Op := uoLogicalNot;
  else
    Exit(ParsePostfix(Parser));
  end;
  Advance(Parser);
  Operand := ParseUnary(Parser);
  Node := MakeNode(Parser, nkUnaryExpr, Start);
  Parser.Tree^.Nodes[Node].Aux := Ord(Op);
  if Operand <> FSIM_INVALID_INDEX then
    ASTAppendChild(Parser.Tree^, Node, Operand);
  Result := Node;
end;

function MakeBinary(var Parser: TParser; Left: Int32; Op: TBinaryOperator;
  const Start: TToken; Right: Int32): Int32;
begin
  Result := MakeNode(Parser, nkBinaryExpr, Start);
  Parser.Tree^.Nodes[Result].Aux := Ord(Op);
  if Left <> FSIM_INVALID_INDEX then
    ASTAppendChild(Parser.Tree^, Result, Left);
  if Right <> FSIM_INVALID_INDEX then
    ASTAppendChild(Parser.Tree^, Result, Right);
end;

function ParsePower(var Parser: TParser): Int32;
var
  Left, Right: Int32;
  Start: TToken;
begin
  Left := ParseUnary(Parser);
  if At(Parser, tkPower) then
  begin
    Start := Parser.Current;
    Advance(Parser);
    Right := ParsePower(Parser);
    Left := MakeBinary(Parser, Left, boPower, Start, Right);
  end;
  Result := Left;
end;

function ParseMultiplicative(var Parser: TParser): Int32;
var
  Left, Right: Int32;
  Start: TToken;
  Op: TBinaryOperator;
begin
  Left := ParsePower(Parser);
  while Parser.Current.Kind in [tkStar, tkSlash, tkIntegerDivide, tkMod, tkRem] do
  begin
    Start := Parser.Current;
    case Parser.Current.Kind of
      tkStar: Op := boMultiply;
      tkSlash: Op := boRealDivide;
      tkIntegerDivide: Op := boIntegerDivide;
      tkMod: Op := boModulo;
    else
      Op := boRemainder;
    end;
    Advance(Parser);
    Right := ParsePower(Parser);
    Left := MakeBinary(Parser, Left, Op, Start, Right);
  end;
  Result := Left;
end;

function ParseAdditive(var Parser: TParser): Int32;
var
  Left, Right: Int32;
  Start: TToken;
  Op: TBinaryOperator;
begin
  Left := ParseMultiplicative(Parser);
  while Parser.Current.Kind in [tkPlus, tkMinus] do
  begin
    Start := Parser.Current;
    if Parser.Current.Kind = tkPlus then
      Op := boAdd
    else
      Op := boSubtract;
    Advance(Parser);
    Right := ParseMultiplicative(Parser);
    Left := MakeBinary(Parser, Left, Op, Start, Right);
  end;
  Result := Left;
end;

function ParseShift(var Parser: TParser): Int32;
var
  Left, Right: Int32;
  Start: TToken;
  Op: TBinaryOperator;
begin
  Left := ParseAdditive(Parser);
  while Parser.Current.Kind in [tkShl, tkShr] do
  begin
    DialectError(Parser, 'bit shifts');
    Start := Parser.Current;
    if Parser.Current.Kind = tkShl then
      Op := boShiftLeft
    else
      Op := boShiftRight;
    Advance(Parser);
    Right := ParseAdditive(Parser);
    Left := MakeBinary(Parser, Left, Op, Start, Right);
  end;
  Result := Left;
end;

function ParseConcat(var Parser: TParser): Int32;
var
  Left, Right: Int32;
  Start: TToken;
begin
  Left := ParseShift(Parser);
  while At(Parser, tkConcat) do
  begin
    Start := Parser.Current;
    Advance(Parser);
    Right := ParseShift(Parser);
    Left := MakeBinary(Parser, Left, boConcat, Start, Right);
  end;
  Result := Left;
end;

function ParseComparison(var Parser: TParser): Int32;
var
  Left, Right, TestNode, ClassSymbol: Int32;
  Start: TToken;
  Op: TBinaryOperator;
  ClassName: RawByteString;
  ClassSpan: TSourceSpan;
begin
  Left := ParseConcat(Parser);
  while TokenIsComparison(Parser.Current.Kind) or
        (Parser.Current.Kind in [tkIs, tkIn]) do
  begin
    Start := Parser.Current;
    if Parser.Current.Kind in [tkIs, tkIn] then
    begin
      Advance(Parser);
      if not ExpectClassIdentifier(Parser, ClassName, ClassSpan) then
        ClassName := '<error-class>';
      ClassSymbol := SymLookupClass(Parser.Symbols^, ClassName);
      if ClassSymbol < 0 then
        AddError(Parser.Diagnostics^, dcUnknownType, ClassSpan,
          'unknown class ''' + ClassName + ''' in object relation');
      TestNode := ASTAddNamedNode(Parser.Tree^, nkObjectTestExpr,
        SourceSpan(Start.Span.StartPos, ClassSpan.EndPos), ClassName);
      Parser.Tree^.Nodes[TestNode].Aux := Ord(Start.Kind = tkIn);
      Parser.Tree^.Nodes[TestNode].SymbolId := ClassSymbol;
      ASTAppendChild(Parser.Tree^, TestNode, Left);
      Left := TestNode;
      Continue;
    end;
    case Parser.Current.Kind of
      tkEqual: Op := boEqual;
      tkNotEqual: Op := boNotEqual;
      tkReferenceEqual: Op := boReferenceEqual;
      tkReferenceNotEqual: Op := boReferenceNotEqual;
      tkLess: Op := boLess;
      tkLessEqual: Op := boLessEqual;
      tkGreater: Op := boGreater;
    else
      Op := boGreaterEqual;
    end;
    Advance(Parser);
    Right := ParseConcat(Parser);
    Left := MakeBinary(Parser, Left, Op, Start, Right);
  end;
  Result := Left;
end;

function ParseLogicalAnd(var Parser: TParser): Int32;
var
  Left, Right: Int32;
  Start: TToken;
begin
  Left := ParseComparison(Parser);
  while At(Parser, tkAnd) and not LookAt(Parser, tkThen) do
  begin
    Start := Parser.Current;
    Advance(Parser);
    Right := ParseComparison(Parser);
    Left := MakeBinary(Parser, Left, boLogicalAnd, Start, Right);
  end;
  Result := Left;
end;

function ParseLogicalOr(var Parser: TParser): Int32;
var
  Left, Right: Int32;
  Start: TToken;
  Op: TBinaryOperator;
begin
  Left := ParseLogicalAnd(Parser);
  while (Parser.Current.Kind in [tkOr, tkXor]) and
        not (At(Parser, tkOr) and LookAt(Parser, tkElse)) do
  begin
    Start := Parser.Current;
    if Parser.Current.Kind = tkXor then
    begin
      DialectError(Parser, 'xor');
      Op := boBitwiseXor;
    end
    else
      Op := boLogicalOr;
    Advance(Parser);
    Right := ParseLogicalAnd(Parser);
    Left := MakeBinary(Parser, Left, Op, Start, Right);
  end;
  Result := Left;
end;

function ParseImplication(var Parser: TParser): Int32;
var
  Left, Right: Int32;
  Start: TToken;
begin
  Left := ParseLogicalOr(Parser);
  while At(Parser, tkImp) do
  begin
    Start := Parser.Current;
    Advance(Parser);
    Right := ParseLogicalOr(Parser);
    Left := MakeBinary(Parser, Left, boImplication, Start, Right);
  end;
  Result := Left;
end;

function ParseEquivalence(var Parser: TParser): Int32;
var
  Left, Right: Int32;
  Start: TToken;
begin
  Left := ParseImplication(Parser);
  while At(Parser, tkEqv) do
  begin
    Start := Parser.Current;
    Advance(Parser);
    Right := ParseImplication(Parser);
    Left := MakeBinary(Parser, Left, boEquivalence, Start, Right);
  end;
  Result := Left;
end;

function MakeBoolLiteral(var Parser: TParser; Value: Boolean;
  const Start: TToken): Int32;
begin
  Result := MakeNode(Parser, nkBooleanLiteralExpr, Start);
  Parser.Tree^.Nodes[Result].IntValue := Ord(Value);
  Parser.Tree^.Nodes[Result].TypeId := FSIM_TYPE_BOOLEAN;
end;

function MakeShortCircuit(var Parser: TParser; Left, Right: Int32;
  IsAnd: Boolean; const Start: TToken): Int32;
var
  FixedValue: Int32;
begin
  Result := MakeNode(Parser, nkConditionalExpr, Start);
  if Left >= 0 then
    Parser.Tree^.Nodes[Result].Span.StartPos := Parser.Tree^.Nodes[Left].Span.StartPos;
  ASTAppendChild(Parser.Tree^, Result, Left);
  if IsAnd then
  begin
    ASTAppendChild(Parser.Tree^, Result, Right);
    FixedValue := MakeBoolLiteral(Parser, False, Start);
    ASTAppendChild(Parser.Tree^, Result, FixedValue);
  end
  else
  begin
    FixedValue := MakeBoolLiteral(Parser, True, Start);
    ASTAppendChild(Parser.Tree^, Result, FixedValue);
    ASTAppendChild(Parser.Tree^, Result, Right);
  end;
end;

function ParseConditionalAnd(var Parser: TParser): Int32;
var
  Left, Right: Int32;
  Start: TToken;
begin
  Left := ParseEquivalence(Parser);
  while At(Parser, tkAnd) and LookAt(Parser, tkThen) do
  begin
    Start := Parser.Current;
    Advance(Parser);
    Expect(Parser, tkThen);
    Right := ParseEquivalence(Parser);
    Left := MakeShortCircuit(Parser, Left, Right, True, Start);
  end;
  Result := Left;
end;

function ParseConditionalOr(var Parser: TParser): Int32;
var
  Left, Right: Int32;
  Start: TToken;
begin
  Left := ParseConditionalAnd(Parser);
  while At(Parser, tkOr) and LookAt(Parser, tkElse) do
  begin
    Start := Parser.Current;
    Advance(Parser);
    Expect(Parser, tkElse);
    Right := ParseConditionalAnd(Parser);
    Left := MakeShortCircuit(Parser, Left, Right, False, Start);
  end;
  Result := Left;
end;

function ParseExpression(var Parser: TParser): Int32;
begin
  Result := ParseConditionalOr(Parser);
end;

procedure AppendClassicProtection(var Protections: TClassicProtectionArray;
  const Name: RawByteString; const Span: TSourceSpan; IsProtected,
  IsHidden: Boolean);
var
  Index: Int32;
begin
  Index := Length(Protections);
  SetLength(Protections, Index + 1);
  Protections[Index] := Default(TClassicProtection);
  Protections[Index].Name := Name;
  Protections[Index].Span := Span;
  Protections[Index].IsProtected := IsProtected;
  Protections[Index].IsHidden := IsHidden;
end;

procedure ParseClassicProtectionPart(var Parser: TParser; ParentNode: Int32;
  var Protections: TClassicProtectionArray);
var
  Start: TToken;
  Name: RawByteString;
  NameSpan: TSourceSpan;
  SectionNode, NameNode: Int32;
  IsProtected, IsHidden: Boolean;
begin
  while Parser.Current.Kind in [tkProtected, tkHidden] do
  begin
    Start := Parser.Current;
    IsProtected := False;
    IsHidden := False;
    while Parser.Current.Kind in [tkProtected, tkHidden] do
    begin
      if At(Parser, tkProtected) then
      begin
        if IsProtected then
          ParserError(Parser, dcExpectedToken,
            'duplicate ''protected'' modifier in class protection part');
        IsProtected := True;
      end
      else
      begin
        if IsHidden then
          ParserError(Parser, dcExpectedToken,
            'duplicate ''hidden'' modifier in class protection part');
        IsHidden := True;
      end;
      Advance(Parser);
    end;
    SectionNode := MakeNode(Parser, nkVisibilitySection, Start);
    if IsProtected then
      Include(Parser.Tree^.Nodes[SectionNode].Flags, nfProtected);
    if IsHidden then
      Include(Parser.Tree^.Nodes[SectionNode].Flags, nfPrivate);
    Parser.Tree^.Nodes[SectionNode].Aux := Ord(IsProtected) or
      (Ord(IsHidden) shl 1);
    ASTAppendChild(Parser.Tree^, ParentNode, SectionNode);
    repeat
      if not ExpectIdentifier(Parser, Name, NameSpan) then
        Break;
      AppendClassicProtection(Protections, Name, NameSpan, IsProtected,
        IsHidden);
      NameNode := ASTAddNamedNode(Parser.Tree^, nkIdentifierExpr, NameSpan,
        Name);
      ASTAppendChild(Parser.Tree^, SectionNode, NameNode);
    until not Accept(Parser, tkComma);
    Expect(Parser, tkSemicolon);
  end;
end;

function AttributeHasProtectedDeclaration(const Symbols: TSymbolTable;
  AttributeSymbol: Int32): Boolean;
var
  I: Integer;
begin
  if (AttributeSymbol >= 0) and (AttributeSymbol <= High(Symbols.Symbols)) and
     (Symbols.Symbols[AttributeSymbol].Visibility = visProtected) then
    Exit(True);
  for I := 0 to High(Symbols.Protections) do
    if (Symbols.Protections[I].AttributeSymbol = AttributeSymbol) and
       Symbols.Protections[I].IsProtected then
      Exit(True);
  Result := False;
end;

procedure UpdateAttributeVisibility(var Symbols: TSymbolTable;
  AttributeSymbol: Int32; Visibility: TVisibility);
var
  I: Integer;
begin
  if (AttributeSymbol < 0) or (AttributeSymbol > High(Symbols.Symbols)) then
    Exit;
  Symbols.Symbols[AttributeSymbol].Visibility := Visibility;
  for I := 0 to High(Symbols.Fields) do
    if Symbols.Fields[I].SymbolId = AttributeSymbol then
      Symbols.Fields[I].Visibility := Visibility;
  for I := 0 to High(Symbols.Methods) do
    if Symbols.Methods[I].SymbolId = AttributeSymbol then
      Symbols.Methods[I].Visibility := Visibility;
end;

procedure ApplyClassicProtections(var Parser: TParser; ClassSymbol: Int32;
  const Protections: TClassicProtectionArray);
var
  I: Integer;
  AttributeSymbol, DeclaringClass: Int32;
  Visibility: TVisibility;
begin
  if ClassSymbol < 0 then
    Exit;
  for I := 0 to High(Protections) do
  begin
    AttributeSymbol := SymLookupMember(Parser.Symbols^, ClassSymbol,
      Protections[I].Name);
    if AttributeSymbol < 0 then
    begin
      AddError(Parser.Diagnostics^, dcUnknownSymbol, Protections[I].Span,
        'class protection names no attribute ''' + Protections[I].Name + '''');
      Continue;
    end;
    DeclaringClass := Parser.Symbols^.Symbols[AttributeSymbol].OwnerSymbol;
    if Protections[I].IsProtected and (DeclaringClass <> ClassSymbol) then
    begin
      AddError(Parser.Diagnostics^, dcVisibilityViolation,
        Protections[I].Span,
        '''protected'' may only name an attribute declared at this prefix level');
      Continue;
    end;
    if Protections[I].IsHidden and
       not (Protections[I].IsProtected or
         AttributeHasProtectedDeclaration(Parser.Symbols^, AttributeSymbol)) then
    begin
      AddError(Parser.Diagnostics^, dcVisibilityViolation,
        Protections[I].Span,
        '''hidden'' requires an attribute that is protected here or in a prefix');
      Continue;
    end;
    SymAddProtection(Parser.Symbols^, ClassSymbol, AttributeSymbol,
      Protections[I].IsProtected, Protections[I].IsHidden);
    if DeclaringClass = ClassSymbol then
    begin
      if Protections[I].IsHidden then
        Visibility := visPrivate
      else if Protections[I].IsProtected then
        Visibility := visProtected
      else
        Visibility := visPublic;
      UpdateAttributeVisibility(Parser.Symbols^, AttributeSymbol, Visibility);
    end;
  end;
end;

function ParseVisibilitySection(var Parser: TParser; ParentNode: Int32): Int32;
var
  Start: TToken;
  Visibility: TVisibility;
begin
  Start := Parser.Current;
  case Parser.Current.Kind of
    tkPublic: Visibility := visPublic;
    tkPrivate: Visibility := visPrivate;
    tkProtected: Visibility := visProtected;
  else
    Visibility := visPublic;
  end;
  DialectError(Parser, 'class visibility sections');
  Advance(Parser);
  Expect(Parser, tkColon);
  Parser.CurrentVisibility := Visibility;
  Result := MakeNode(Parser, nkVisibilitySection, Start);
  Parser.Tree^.Nodes[Result].Aux := Ord(Visibility);
  ASTAppendChild(Parser.Tree^, ParentNode, Result);
end;

function ParseVariableDeclaration(var Parser: TParser; ParentNode,
  TypeId: Int32; IsOwn: Boolean): Int32;
var
  Start: TToken;
  Name: RawByteString;
  NameSpan: TSourceSpan;
  Node, FirstNode, SymbolId: Int32;
  Kind: TSymbolKind;
  Flags: TSymbolFlags;
begin
  Start := Parser.Previous;
  FirstNode := FSIM_INVALID_INDEX;
  repeat
    if not ExpectIdentifier(Parser, Name, NameSpan) then
      Break;
    Node := ASTAddNamedNode(Parser.Tree^, nkVariableDecl,
      SourceSpan(Start.Span.StartPos, NameSpan.EndPos), Name);
    Parser.Tree^.Nodes[Node].TypeId := TypeId;
    if IsOwn then
      Include(Parser.Tree^.Nodes[Node].Flags, nfOwn);
    if ParserInClassBody(Parser) then
      Kind := skField
    else
      Kind := skVariable;
    Flags := [sfMutable];
    if IsOwn then Include(Flags, sfOwn);
    SymbolId := SymAdd(Parser.Symbols^, Name, Kind, TypeId,
      Parser.CurrentVisibility, Flags, Node, Parser.Tree^.Nodes[Node].Span);
    Parser.Tree^.Nodes[Node].SymbolId := SymbolId;
    if (SymbolId >= 0) and (TypeId >= 0) and
       (TypeId <= High(Parser.Symbols^.Types)) and
       (TypeId <> FSIM_TYPE_INVALID) then
    begin
      if Kind = skField then
        SymAddField(Parser.Symbols^, Parser.CurrentClass, SymbolId, TypeId,
          Parser.CurrentVisibility)
      else
        SymAllocateLocal(Parser.Symbols^, SymbolId);
    end;
    ASTAppendChild(Parser.Tree^, ParentNode, Node);
    if FirstNode = FSIM_INVALID_INDEX then
      FirstNode := Node;
    Inc(Parser.ParsedDeclarationCount);
  until not Accept(Parser, tkComma);
  Expect(Parser, tkSemicolon);
  Result := FirstNode;
end;

function ParsePascalVariableDeclaration(var Parser: TParser;
  ParentNode: Int32; IsThreadLocal: Boolean): Int32;
var
  Start: TToken;
  Names: array of RawByteString;
  Spans: array of TSourceSpan;
  Name: RawByteString;
  NameSpan: TSourceSpan;
  TypeId, Node, SymbolId, Initializer, I: Int32;
  Kind: TSymbolKind;
  Flags: TSymbolFlags;
begin
  Start := Parser.Current;
  DialectError(Parser, 'Pascal-style variable declarations');
  if IsThreadLocal then
  begin
    Expect(Parser, tkThreadLocal);
    Accept(Parser, tkVar);
  end
  else
    Expect(Parser, tkVar);
  SetLength(Names, 0);
  SetLength(Spans, 0);
  repeat
    if not ExpectIdentifier(Parser, Name, NameSpan) then Break;
    SetLength(Names, Length(Names) + 1);
    SetLength(Spans, Length(Spans) + 1);
    Names[High(Names)] := Name;
    Spans[High(Spans)] := NameSpan;
  until not Accept(Parser, tkComma);
  Expect(Parser, tkColon);
  TypeId := ParseType(Parser);
  Initializer := FSIM_INVALID_INDEX;
  if Accept(Parser, tkAssignValue) then
  begin
    if Length(Names) <> 1 then
      ParserError(Parser, dcInvalidAssignment,
        'a shared initializer requires exactly one declared variable');
    Initializer := ParseExpression(Parser);
  end;
  Expect(Parser, tkSemicolon);
  Result := FSIM_INVALID_INDEX;
  for I := 0 to High(Names) do
  begin
    Node := ASTAddNamedNode(Parser.Tree^, nkVariableDecl,
      SourceSpan(Start.Span.StartPos, Spans[I].EndPos), Names[I]);
    Parser.Tree^.Nodes[Node].TypeId := TypeId;
    if IsThreadLocal then
      Parser.Tree^.Nodes[Node].Aux := 1;
    if (Initializer >= 0) and (I = 0) then
      ASTAppendChild(Parser.Tree^, Node, Initializer);
    if ParserInClassBody(Parser) then Kind := skField else Kind := skVariable;
    Flags := [sfMutable];
    if IsThreadLocal then Include(Flags, sfThreadLocal);
    SymbolId := SymAdd(Parser.Symbols^, Names[I], Kind, TypeId,
      Parser.CurrentVisibility, Flags, Node, Parser.Tree^.Nodes[Node].Span);
    Parser.Tree^.Nodes[Node].SymbolId := SymbolId;
    if SymbolId >= 0 then
    begin
      if Kind = skField then
        SymAddField(Parser.Symbols^, Parser.CurrentClass, SymbolId, TypeId,
          Parser.CurrentVisibility)
      else
        SymAllocateLocal(Parser.Symbols^, SymbolId);
    end;
    ASTAppendChild(Parser.Tree^, ParentNode, Node);
    if Result < 0 then Result := Node;
    Inc(Parser.ParsedDeclarationCount);
  end;
end;

function ParseParameterList(var Parser: TParser; ProcedureNode: Int32;
  out ParameterStart, ParameterCount: Int32): Boolean;
var
  TypeId, Node, SymbolId, I: Int32;
  Mode: TPassingMode;
  Name: RawByteString;
  NameSpan: TSourceSpan;
  Start: TToken;
  Names: array of RawByteString;
  Types: array of Int32;
  Modes: array of TPassingMode;
  ParameterSymbols: array of Int32;
begin
  Result := True;
  ParameterStart := FSIM_INVALID_INDEX;
  ParameterCount := 0;
  SetLength(Names, 0);
  SetLength(Types, 0);
  SetLength(Modes, 0);
  SetLength(ParameterSymbols, 0);
  if not Accept(Parser, tkLParen) then
  begin
    ParameterStart := Length(Parser.Symbols^.Parameters);
    Exit;
  end;
  if not Accept(Parser, tkRParen) then
  begin
    repeat
      Start := Parser.Current;
      Mode := pmValue;
      if At(Parser, tkValue) and not LookAt(Parser, tkColon) then
      begin
        Advance(Parser);
        Mode := pmValue;
      end
      else if At(Parser, tkName) and not LookAt(Parser, tkColon) then
      begin
        Advance(Parser);
        Mode := pmName;
      end
      else if At(Parser, tkRef) and not LookAt(Parser, tkLParen) then
      begin
        Advance(Parser);
        Mode := pmReference;
      end;
      if TokenCanBeIdentifier(Parser, Parser.Current.Kind) and
         LookAt(Parser, tkColon) then
      begin
        DialectError(Parser, 'Pascal-style parameter declarations');
        if not ExpectIdentifier(Parser, Name, NameSpan) then
        begin
          Result := False;
          Break;
        end;
        Expect(Parser, tkColon);
        TypeId := ParseType(Parser);
      end
      else
      begin
        TypeId := ParseType(Parser);
        if not ExpectIdentifier(Parser, Name, NameSpan) then
        begin
          Result := False;
          Break;
        end;
      end;
      Node := ASTAddNamedNode(Parser.Tree^, nkParameterDecl,
        SourceSpan(Start.Span.StartPos, NameSpan.EndPos), Name);
      Parser.Tree^.Nodes[Node].TypeId := TypeId;
      case Mode of
        pmValue: Include(Parser.Tree^.Nodes[Node].Flags, nfValueParameter);
        pmName: Include(Parser.Tree^.Nodes[Node].Flags, nfNameParameter);
      end;
      SymbolId := SymAdd(Parser.Symbols^, Name, skParameter, TypeId,
        visPrivate, [], Node, Parser.Tree^.Nodes[Node].Span);
      Parser.Tree^.Nodes[Node].SymbolId := SymbolId;
      ASTAppendChild(Parser.Tree^, ProcedureNode, Node);
      SetLength(Names, Length(Names) + 1);
      SetLength(Types, Length(Types) + 1);
      SetLength(Modes, Length(Modes) + 1);
      SetLength(ParameterSymbols, Length(ParameterSymbols) + 1);
      Names[High(Names)] := Name;
      Types[High(Types)] := TypeId;
      Modes[High(Modes)] := Mode;
      ParameterSymbols[High(ParameterSymbols)] := SymbolId;
    until not Accept(Parser, tkComma);
    Expect(Parser, tkRParen);
  end;
  ParameterStart := Length(Parser.Symbols^.Parameters);
  ParameterCount := Length(Types);
  for I := 0 to ParameterCount - 1 do
  begin
    SymbolId := ParameterSymbols[I];
    if SymbolId >= 0 then
    begin
      Parser.Symbols^.Symbols[SymbolId].ParameterIndex := I;
      case Modes[I] of
        pmValue: Include(Parser.Symbols^.Symbols[SymbolId].Flags,
          sfValueParameter);
        pmName: Include(Parser.Symbols^.Symbols[SymbolId].Flags,
          sfNameParameter);
      end;
    end;
    SymAddParameter(Parser.Symbols^, Names[I], Types[I], Modes[I], SymbolId,
      FSIM_INVALID_INDEX);
  end;
end;

function FindVirtualSpec(const Parser: TParser; ClassSymbol: Int32;
  const Name: RawByteString): Int32;
var
  Member: Int32;
begin
  { A concrete implementation still carries sfVirtual, and a subclass must
    inherit that contract. Looking only for a virtual-spec symbol owned by the
    current class made overrides silently become non-virtual. }
  Member := SymLookupMember(Parser.Symbols^, ClassSymbol, Name);
  if (Member >= 0) and
     ((Parser.Symbols^.Symbols[Member].Kind = skVirtualSpec) or
      (sfVirtual in Parser.Symbols^.Symbols[Member].Flags)) then
    Exit(Member);
  Result := FSIM_INVALID_INDEX;
end;

function ParseProcedureDeclaration(var Parser: TParser; ParentNode,
  ReturnType: Int32; IsFunction: Boolean): Int32;
var
  Start: TToken;
  Name, EndName: RawByteString;
  NameSpan, EndSpan: TSourceSpan;
  Node, SymbolId, PreviousRoutine, ProcedureType: Int32;
  ParameterStart, ParameterCount: Int32;
  SavedClass: Int32;
  Flags: TSymbolFlags;
  Kind: TSymbolKind;
  BodyNode: Int32;
  VirtualSpec: Int32;
  ClassicHeader: Boolean;
  ClassicFormals: TClassicFormalArray;
begin
  Start := Parser.Current;
  if IsFunction then
    Expect(Parser, tkFunction)
  else
    Expect(Parser, tkProcedure);
  if not ExpectRoutineIdentifier(Parser, Name, NameSpan) then
    Name := '<error-procedure>';
  if IsFunction then
    Node := ASTAddNamedNode(Parser.Tree^, nkFunctionDecl,
      SourceSpan(Start.Span.StartPos, NameSpan.EndPos), Name)
  else
    Node := ASTAddNamedNode(Parser.Tree^, nkProcedureDecl,
      SourceSpan(Start.Span.StartPos, NameSpan.EndPos), Name);
  Flags := [sfDefined];
  VirtualSpec := FSIM_INVALID_INDEX;
  if Parser.CurrentClass >= 0 then
  begin
    VirtualSpec := FindVirtualSpec(Parser, Parser.CurrentClass, Name);
    if VirtualSpec >= 0 then
    begin
      Include(Flags, sfVirtual);
      Include(Parser.Tree^.Nodes[Node].Flags, nfVirtual);
    end;
  end;
  if IsFunction then Kind := skFunction else Kind := skProcedure;
  SymbolId := SymAdd(Parser.Symbols^, Name, Kind, FSIM_TYPE_INVALID,
    Parser.CurrentVisibility, Flags, Node, Parser.Tree^.Nodes[Node].Span);
  Parser.Tree^.Nodes[Node].SymbolId := SymbolId;
  ASTAppendChild(Parser.Tree^, ParentNode, Node);
  PreviousRoutine := Parser.CurrentRoutine;
  SavedClass := Parser.Symbols^.CurrentClass;
  Parser.CurrentRoutine := SymbolId;
  Parser.Symbols^.CurrentRoutine := SymbolId;
  SymEnterScope(Parser.Symbols^,
    TScopeKind(Ord(scProcedure) + Ord(IsFunction)), SymbolId);
  Parser.Tree^.Nodes[Node].Aux := Parser.Symbols^.CurrentScope;

  ClassicHeader := ParameterListIsClassic(Parser);
  SetLength(ClassicFormals, 0);
  if ClassicHeader then
  begin
    ParseClassicFormalNames(Parser, ClassicFormals);
    ParameterStart := Length(Parser.Symbols^.Parameters);
    ParameterCount := 0;
  end
  else
    ParseParameterList(Parser, Node, ParameterStart, ParameterCount);

  if IsFunction and Accept(Parser, tkColon) then
  begin
    DialectError(Parser, 'Pascal-style function return types');
    ReturnType := ParseType(Parser);
  end;
  Expect(Parser, tkSemicolon);

  if ClassicHeader then
  begin
    ParseClassicFormalSpecifications(Parser, ClassicFormals, False);
    RegisterClassicFormals(Parser, Node, SymbolId, ClassicFormals, False,
      ParameterStart, ParameterCount);
  end;

  ProcedureType := SymMakeProcedureType(Parser.Symbols^, ReturnType,
    ParameterStart, ParameterCount);
  if SymbolId >= 0 then
    Parser.Symbols^.Symbols[SymbolId].TypeId := ProcedureType;
  Parser.Tree^.Nodes[Node].TypeId := ProcedureType;

  if Accept(Parser, tkIs) then
  begin
    if IsFunction then Expect(Parser, tkFunction)
    else Expect(Parser, tkProcedure);
    if At(Parser, tkIdentifier) then Advance(Parser);
    Expect(Parser, tkSemicolon);
  end;

  if TokenStartsStatement(Parser.Current.Kind) then
  begin
    BodyNode := ParseStatement(Parser);
    if BodyNode >= 0 then
      ASTAppendChild(Parser.Tree^, Node, BodyNode);
    if SymbolId >= 0 then
      Parser.Symbols^.Symbols[SymbolId].BodyNode := BodyNode;
    Parser.Tree^.Nodes[Node].BodyNode := BodyNode;
  end
  else if not (sfAbstract in Flags) then
    ParserError(Parser, dcExpectedToken,
      'procedure body must be a statement, normally a begin/end block');

  if At(Parser, tkIdentifier) then
  begin
    EndName := TokenText(Parser.Current);
    EndSpan := Parser.Current.Span;
    Advance(Parser);
    if not ASCIIEqualFold(EndName, Name) then
      AddError(Parser.Diagnostics^, dcExpectedToken, EndSpan,
        'end identifier ''' + EndName + ''' does not match procedure ''' +
        Name + '''');
  end;
  Accept(Parser, tkSemicolon);
  SymLeaveScope(Parser.Symbols^);
  Parser.CurrentRoutine := PreviousRoutine;
  Parser.Symbols^.CurrentRoutine := PreviousRoutine;
  Parser.Symbols^.CurrentClass := SavedClass;
  if (Parser.CurrentClass >= 0) and (SymbolId >= 0) then
    SymAddMethod(Parser.Symbols^, Parser.CurrentClass, SymbolId, ProcedureType,
      Parser.CurrentVisibility, sfVirtual in Flags, False, False, False);
  Inc(Parser.ParsedDeclarationCount);
  Result := Node;
end;

function ParseVirtualSection(var Parser: TParser; ClassNode,
  ClassSymbol: Int32): Int32;
var
  Start, SpecStart: TToken;
  SectionNode, SpecNode, SymbolId: Int32;
  Name, AliasName: RawByteString;
  NameSpan, AliasSpan: TSourceSpan;
  ReturnType, ProcedureType: Int32;
  IsFunction, IsLegacyAlias, IsProcedureSpec: Boolean;
  SymbolKind: TSymbolKind;
begin
  Start := Parser.Current;
  Expect(Parser, tkVirtual);
  Expect(Parser, tkColon);
  SectionNode := MakeNode(Parser, nkVirtualSection, Start);
  ASTAppendChild(Parser.Tree^, ClassNode, SectionNode);

  while Parser.Current.Kind in [tkProcedure, tkFunction, tkInteger, tkReal,
    tkBoolean, tkCharacter, tkText, tkString, tkRef, tkLabel, tkSwitch] do
  begin
    SpecStart := Parser.Current;
    ReturnType := FSIM_TYPE_VOID;
    IsFunction := False;
    IsProcedureSpec := True;
    SymbolKind := skVirtualSpec;

    if Accept(Parser, tkLabel) then
    begin
      IsProcedureSpec := False;
      SymbolKind := skLabel;
      ReturnType := FSIM_TYPE_INTEGER;
    end
    else if Accept(Parser, tkSwitch) then
    begin
      IsProcedureSpec := False;
      SymbolKind := skSwitch;
      ReturnType := FSIM_TYPE_INTEGER;
    end
    else
    begin
      if TokenStartsType(Parser.Current.Kind) then
      begin
        ReturnType := ParseType(Parser);
        IsFunction := True;
      end;
      if At(Parser, tkFunction) then
      begin
        DialectError(Parser, 'function keyword in virtual specifications');
        IsFunction := True;
        Advance(Parser);
      end
      else
        Expect(Parser, tkProcedure);
    end;

    if not ExpectIdentifier(Parser, Name, NameSpan) then
      Name := '<error-virtual>';

    IsLegacyAlias := Accept(Parser, tkIs);
    if IsLegacyAlias then
    begin
      DialectError(Parser, 'legacy repeated virtual specification');
      if IsProcedureSpec then
      begin
        if IsFunction and At(Parser, tkFunction) then
          Advance(Parser)
        else
          Expect(Parser, tkProcedure);
      end;
      if not ExpectIdentifier(Parser, AliasName, AliasSpan) then
        AliasName := '';
      if (AliasName <> '') and not ASCIIEqualFold(Name, AliasName) then
        AddError(Parser.Diagnostics^, dcVirtualMismatch, AliasSpan,
          'virtual specification name must repeat ''' + Name + '''');
      Expect(Parser, tkSemicolon);
      Expect(Parser, tkSemicolon);
    end
    else
      Expect(Parser, tkSemicolon);

    SpecNode := ASTAddNamedNode(Parser.Tree^, nkVirtualSpec,
      SourceSpan(SpecStart.Span.StartPos, Parser.Previous.Span.EndPos), Name);
    Include(Parser.Tree^.Nodes[SpecNode].Flags, nfVirtual);
    Include(Parser.Tree^.Nodes[SpecNode].Flags, nfAbstract);
    if IsProcedureSpec then
      ProcedureType := SymMakeProcedureType(Parser.Symbols^, ReturnType,
        Length(Parser.Symbols^.Parameters), 0)
    else
      ProcedureType := ReturnType;
    Parser.Tree^.Nodes[SpecNode].TypeId := ProcedureType;
    Parser.Tree^.Nodes[SpecNode].Aux := Ord(SymbolKind);
    SymbolId := SymAdd(Parser.Symbols^, Name, SymbolKind, ProcedureType,
      Parser.CurrentVisibility, [sfVirtual, sfAbstract], SpecNode,
      Parser.Tree^.Nodes[SpecNode].Span);
    Parser.Tree^.Nodes[SpecNode].SymbolId := SymbolId;
    if IsProcedureSpec and (SymbolId >= 0) then
      SymAddMethod(Parser.Symbols^, ClassSymbol, SymbolId, ProcedureType,
        Parser.CurrentVisibility, True, False, True, False);
    ASTAppendChild(Parser.Tree^, SectionNode, SpecNode);
  end;
  Result := SectionNode;
end;

function ParseClassDeclaration(var Parser: TParser; ParentNode: Int32;
  PrefixName: RawByteString; HasPrefix, IsProcess, IsThread: Boolean): Int32;
var
  Start: TToken;
  Name, EndName: RawByteString;
  NameSpan, EndSpan: TSourceSpan;
  Node, ClassSymbol, PrefixSymbol, PreviousClass, ClassScope: Int32;
  Kind: TSymbolKind;
  Flags: TSymbolFlags;
  SavedVisibility: TVisibility;
  Child, ParameterStart, ParameterCount: Int32;
  ClassicFormals: TClassicFormalArray;
  ClassicProtections: TClassicProtectionArray;
begin
  Start := Parser.Current;
  if HasPrefix then
  begin
    Start := Parser.Previous;
    Expect(Parser, tkClass);
  end
  else if IsThread then
  begin
    if At(Parser, tkTask) then
    begin
      DialectError(Parser, 'task class');
      Expect(Parser, tkTask);
    end
    else
    begin
      DialectError(Parser, 'thread class');
      Expect(Parser, tkThread);
    end;
    Expect(Parser, tkClass);
  end
  else
    Expect(Parser, tkClass);
  if not ExpectClassIdentifier(Parser, Name, NameSpan) then
    Name := '<error-class>';
  SetLength(ClassicFormals, 0);
  SetLength(ClassicProtections, 0);
  if At(Parser, tkLParen) then
    ParseClassicFormalNames(Parser, ClassicFormals);
  Expect(Parser, tkSemicolon);

  PrefixSymbol := FSIM_INVALID_INDEX;
  if HasPrefix then
  begin
    PrefixSymbol := SymLookupClass(Parser.Symbols^, PrefixName);
    if PrefixSymbol < 0 then
      AddError(Parser.Diagnostics^, dcInvalidPrefix, Start.Span,
        'prefix class ''' + PrefixName + ''' must be declared before ''' +
        Name + '''');
  end;
  if IsProcess then
  begin
    Kind := skProcessClass;
    Node := ASTAddNamedNode(Parser.Tree^, nkProcessClassDecl,
      SourceSpan(Start.Span.StartPos, NameSpan.EndPos), Name);
    Include(Parser.Tree^.Nodes[Node].Flags, nfProcessClass);
  end
  else if IsThread then
  begin
    Kind := skThreadClass;
    Node := ASTAddNamedNode(Parser.Tree^, nkThreadClassDecl,
      SourceSpan(Start.Span.StartPos, NameSpan.EndPos), Name);
    Include(Parser.Tree^.Nodes[Node].Flags, nfThreadClass);
  end
  else
  begin
    Kind := skClass;
    Node := ASTAddNamedNode(Parser.Tree^, nkClassDecl,
      SourceSpan(Start.Span.StartPos, NameSpan.EndPos), Name);
  end;
  Flags := [sfDefined, sfRuntimeRequired];
  ClassSymbol := SymAdd(Parser.Symbols^, Name, Kind, FSIM_TYPE_INVALID,
    visPublic, Flags, Node, Parser.Tree^.Nodes[Node].Span);
  Parser.Tree^.Nodes[Node].SymbolId := ClassSymbol;
  Parser.Tree^.Nodes[Node].A := PrefixSymbol;
  ASTAppendChild(Parser.Tree^, ParentNode, Node);
  if ClassSymbol >= 0 then
    SymRegisterClass(Parser.Symbols^, ClassSymbol, PrefixSymbol, IsProcess,
      IsThread);
  PreviousClass := Parser.CurrentClass;
  SavedVisibility := Parser.CurrentVisibility;
  Parser.CurrentClass := ClassSymbol;
  Parser.Symbols^.CurrentClass := ClassSymbol;
  Parser.CurrentVisibility := visPublic;
  ClassScope := SymEnterScope(Parser.Symbols^, scClass, ClassSymbol);
  Parser.Tree^.Nodes[Node].C := ClassScope;

  if Length(ClassicFormals) > 0 then
  begin
    ParseClassicFormalSpecifications(Parser, ClassicFormals, True);
    RegisterClassicFormals(Parser, Node, ClassSymbol, ClassicFormals, True,
      ParameterStart, ParameterCount);
  end
  else if ClassSymbol >= 0 then
    SymSetClassParameters(Parser.Symbols^, ClassSymbol,
      Length(Parser.Symbols^.Parameters), 0);

  if Parser.Current.Kind in [tkProtected, tkHidden] then
    ParseClassicProtectionPart(Parser, Node, ClassicProtections);
  if At(Parser, tkVirtual) then
    ParseVirtualSection(Parser, Node, ClassSymbol);
  if not Expect(Parser, tkBegin) then
  begin
    SymLeaveScope(Parser.Symbols^);
    Parser.CurrentClass := PreviousClass;
    Parser.CurrentVisibility := SavedVisibility;
    Exit(Node);
  end;
  while not At(Parser, tkEnd) and not At(Parser, tkEOF) do
  begin
    if Parser.Current.Kind in [tkPublic, tkPrivate, tkProtected] then
      ParseVisibilitySection(Parser, Node)
    else if At(Parser, tkVirtual) then
    begin
      ParserError(Parser, dcVirtualOrder,
        'Virtual: section must appear immediately after the class header');
      ParseVirtualSection(Parser, Node, ClassSymbol);
    end
    else if ParserStartsDeclaration(Parser) or
      (TokenCanNameClass(Parser.Current.Kind) and LookAt(Parser, tkClass)) then
      ParseDeclaration(Parser, Node)
    else
    begin
      Child := ParseStatement(Parser);
      if Child >= 0 then
        ASTAppendChild(Parser.Tree^, Node, Child);
      Accept(Parser, tkSemicolon);
    end;
    if Parser.ErrorRecovery then
      Synchronize(Parser);
  end;
  Expect(Parser, tkEnd);
  if At(Parser, tkIdentifier) then
  begin
    EndName := TokenText(Parser.Current);
    EndSpan := Parser.Current.Span;
    Advance(Parser);
    if not ASCIIEqualFold(EndName, Name) then
      AddError(Parser.Diagnostics^, dcExpectedToken, EndSpan,
        'end identifier ''' + EndName + ''' does not match class ''' +
        Name + '''');
  end;
  Accept(Parser, tkSemicolon);
  if ClassSymbol >= 0 then
  begin
    ApplyClassicProtections(Parser, ClassSymbol, ClassicProtections);
    SymFinalizeClass(Parser.Symbols^, ClassSymbol);
  end;
  SymLeaveScope(Parser.Symbols^);
  Parser.Symbols^.CurrentScope := Parser.Symbols^.Scopes[ClassScope].ParentScope;
  Parser.CurrentClass := PreviousClass;
  Parser.Symbols^.CurrentClass := PreviousClass;
  Parser.CurrentVisibility := SavedVisibility;
  Inc(Parser.ParsedDeclarationCount);
  Result := Node;
end;

function ParseConstantDeclaration(var Parser: TParser;
  ParentNode: Int32): Int32;
var
  Start: TToken;
  Name, TypeNameText: RawByteString;
  NameSpan: TSourceSpan;
  Node, SymbolId, TypeId, Initializer, AliasSymbol: Int32;
begin
  Start := Parser.Current;
  DialectError(Parser, 'typed constant declarations');
  Expect(Parser, tkConst);
  TypeId := FSIM_TYPE_INVALID;
  if TokenStartsType(Parser.Current.Kind) then
    TypeId := ParseType(Parser)
  else if CurrentTokenIsTypeAlias(Parser) then
  begin
    TypeNameText := TokenText(Parser.Current);
    AliasSymbol := SymLookup(Parser.Symbols^, TypeNameText);
    TypeId := Parser.Symbols^.Symbols[AliasSymbol].TypeId;
    Advance(Parser);
  end;
  if not ExpectIdentifier(Parser, Name, NameSpan) then
    Name := '<error-constant>';
  Expect(Parser, tkEqual);
  Initializer := ParseExpression(Parser);
  Expect(Parser, tkSemicolon);
  Node := ASTAddNamedNode(Parser.Tree^, nkConstantDecl,
    SourceSpan(Start.Span.StartPos, Parser.Previous.Span.EndPos), Name);
  Parser.Tree^.Nodes[Node].TypeId := TypeId;
  Include(Parser.Tree^.Nodes[Node].Flags, nfConstant);
  if Initializer >= 0 then
    ASTAppendChild(Parser.Tree^, Node, Initializer);
  SymbolId := SymAdd(Parser.Symbols^, Name, skConstant, TypeId,
    Parser.CurrentVisibility, [sfDefined, sfFinal], Node,
    Parser.Tree^.Nodes[Node].Span);
  Parser.Tree^.Nodes[Node].SymbolId := SymbolId;
  if SymbolId >= 0 then
  begin
    if (Initializer >= 0) and (TypeId = FSIM_TYPE_INVALID) then
      case Parser.Tree^.Nodes[Initializer].Kind of
        nkIntegerLiteralExpr: TypeId := FSIM_TYPE_INTEGER;
        nkRealLiteralExpr: TypeId := FSIM_TYPE_REAL;
        nkBooleanLiteralExpr: TypeId := FSIM_TYPE_BOOLEAN;
        nkCharacterLiteralExpr: TypeId := FSIM_TYPE_CHARACTER;
        nkStringLiteralExpr:
          if Parser.Options^.Dialect = fdSimula67 then
            TypeId := FSIM_TYPE_TEXT
          else
            TypeId := FSIM_TYPE_STRING;
      end;
    Parser.Tree^.Nodes[Node].TypeId := TypeId;
    Parser.Symbols^.Symbols[SymbolId].TypeId := TypeId;
    if Initializer >= 0 then
      case Parser.Tree^.Nodes[Initializer].Kind of
        nkIntegerLiteralExpr, nkBooleanLiteralExpr, nkCharacterLiteralExpr:
          Parser.Symbols^.Symbols[SymbolId].ConstantInt :=
            Parser.Tree^.Nodes[Initializer].IntValue;
        nkRealLiteralExpr:
          Parser.Symbols^.Symbols[SymbolId].ConstantReal :=
            Parser.Tree^.Nodes[Initializer].RealValue;
        nkStringLiteralExpr:
          Parser.Symbols^.Symbols[SymbolId].ConstantString :=
            Parser.Tree^.Nodes[Initializer].StringId;
      end;
  end;
  ASTAppendChild(Parser.Tree^, ParentNode, Node);
  Inc(Parser.ParsedDeclarationCount);
  Result := Node;
end;

function ParseTypeAliasDeclaration(var Parser: TParser;
  ParentNode: Int32): Int32;
var
  Start: TToken;
  Name, FieldName: RawByteString;
  NameSpan, FieldSpan: TSourceSpan;
  Node, SymbolId, TypeId, FieldNode, FieldSymbol, FieldType: Int32;
  Info: TTypeInfo;
  Offset, FieldSize: QWord;
  FieldAlignment: UInt32;
begin
  Start := Parser.Current;
  DialectError(Parser, 'type aliases');
  Expect(Parser, tkType);
  if not ExpectIdentifier(Parser, Name, NameSpan) then
    Name := '<error-type>';
  Expect(Parser, tkEqual);

  if At(Parser, tkRecord) then
  begin
    { Native records are nominal value types.  Give the type a symbol before
      parsing fields so field ownership/member lookup is identical to classes
      and C records rather than bolting names onto the global scope. }
    Advance(Parser);
    Info := Default(TTypeInfo);
    Info.Kind := tyRecord;
    Info.Flags := [tfValueType, tfComplete, tfRuntimeVisible];
    Info.NameId := StringPoolIntern(Parser.Symbols^.Strings, Name);
    Info.Size := 0;
    Info.Alignment := 1;
    Info.ElementType := FSIM_TYPE_INVALID;
    Info.ReturnType := FSIM_TYPE_INVALID;
    Info.RefClassSymbol := FSIM_INVALID_INDEX;
    Info.ParameterStart := FSIM_INVALID_INDEX;
    Info.LowerBound := 0;
    Info.UpperBound := -1;
    TypeId := SymAddType(Parser.Symbols^, Info);

    Node := ASTAddNamedNode(Parser.Tree^, nkTypeDecl,
      SourceSpan(Start.Span.StartPos, NameSpan.EndPos), Name);
    Parser.Tree^.Nodes[Node].TypeId := TypeId;
    SymbolId := SymAdd(Parser.Symbols^, Name, skType, TypeId,
      Parser.CurrentVisibility, [sfDefined], Node,
      Parser.Tree^.Nodes[Node].Span);
    Parser.Tree^.Nodes[Node].SymbolId := SymbolId;
    if SymbolId >= 0 then
      Parser.Symbols^.Types[TypeId].RefClassSymbol := SymbolId;
    ASTAppendChild(Parser.Tree^, ParentNode, Node);

    SymEnterScope(Parser.Symbols^, scBlock, SymbolId);
    while not At(Parser, tkEnd) and not At(Parser, tkEOF) do
    begin
      Accept(Parser, tkVar);
      if TokenCanBeIdentifier(Parser, Parser.Current.Kind) and
         LookAt(Parser, tkColon) then
      begin
        if not ExpectIdentifier(Parser, FieldName, FieldSpan) then Break;
        Expect(Parser, tkColon);
        FieldType := ParseType(Parser);
      end
      else
      begin
        FieldType := ParseType(Parser);
        if not ExpectIdentifier(Parser, FieldName, FieldSpan) then Break;
      end;

      if (FieldType < 0) or (FieldType > High(Parser.Symbols^.Types)) or
         not (tfComplete in Parser.Symbols^.Types[FieldType].Flags) or
         (FieldType = FSIM_TYPE_VOID) then
      begin
        AddError(Parser.Diagnostics^, dcTypeMismatch, FieldSpan,
          'record field ''' + FieldName + ''' needs a complete value type');
        FieldSize := 0;
        FieldAlignment := 1;
      end
      else if tfManaged in Parser.Symbols^.Types[FieldType].Flags then
      begin
        { Managed record fields need generated retain/release/copy glue.  Do
          not pretend a byte copy is correct until that glue exists. }
        AddError(Parser.Diagnostics^, dcBackendUnsupported, FieldSpan,
          'managed record fields are not lowered yet; use a scalar, reference, fixed array, or record field');
        FieldSize := Parser.Symbols^.Types[FieldType].Size;
        FieldAlignment := Parser.Symbols^.Types[FieldType].Alignment;
      end
      else
      begin
        FieldSize := Parser.Symbols^.Types[FieldType].Size;
        FieldAlignment := Parser.Symbols^.Types[FieldType].Alignment;
      end;
      if FieldAlignment = 0 then FieldAlignment := 1;
      Offset := AlignUp(Parser.Symbols^.Types[TypeId].Size, FieldAlignment);
      if (Offset > High(UInt32)) or (FieldSize > High(UInt32) - Offset) then
        raise ERangeError.Create('record layout exceeds 4 GiB');

      FieldNode := ASTAddNamedNode(Parser.Tree^, nkVariableDecl, FieldSpan,
        FieldName);
      Parser.Tree^.Nodes[FieldNode].TypeId := FieldType;
      FieldSymbol := SymAdd(Parser.Symbols^, FieldName, skField, FieldType,
        visPublic, [sfDefined, sfMutable], FieldNode,
        Parser.Tree^.Nodes[FieldNode].Span);
      Parser.Tree^.Nodes[FieldNode].SymbolId := FieldSymbol;
      ASTAppendChild(Parser.Tree^, Node, FieldNode);
      if FieldSymbol >= 0 then
      begin
        Parser.Symbols^.Symbols[FieldSymbol].StorageOffset := UInt32(Offset);
        Parser.Symbols^.Symbols[FieldSymbol].StorageSize := UInt32(FieldSize);
      end;
      Parser.Symbols^.Types[TypeId].Size := UInt32(Offset + FieldSize);
      if FieldAlignment > Parser.Symbols^.Types[TypeId].Alignment then
        Parser.Symbols^.Types[TypeId].Alignment := FieldAlignment;
      Accept(Parser, tkSemicolon);
    end;
    SymLeaveScope(Parser.Symbols^);
    Expect(Parser, tkEnd);
    Expect(Parser, tkSemicolon);
    if Parser.Symbols^.Types[TypeId].Alignment > 1 then
      Parser.Symbols^.Types[TypeId].Size := UInt32(AlignUp(
        Parser.Symbols^.Types[TypeId].Size,
        Parser.Symbols^.Types[TypeId].Alignment));
    Parser.Tree^.Nodes[Node].Span.EndPos := Parser.Previous.Span.EndPos;
    Inc(Parser.ParsedDeclarationCount);
    Exit(Node);
  end;

  TypeId := ParseType(Parser);
  Expect(Parser, tkSemicolon);
  Node := ASTAddNamedNode(Parser.Tree^, nkTypeDecl,
    SourceSpan(Start.Span.StartPos, Parser.Previous.Span.EndPos), Name);
  Parser.Tree^.Nodes[Node].TypeId := TypeId;
  SymbolId := SymAdd(Parser.Symbols^, Name, skType, TypeId,
    Parser.CurrentVisibility, [sfDefined], Node,
    Parser.Tree^.Nodes[Node].Span);
  Parser.Tree^.Nodes[Node].SymbolId := SymbolId;
  ASTAppendChild(Parser.Tree^, ParentNode, Node);
  Inc(Parser.ParsedDeclarationCount);
  Result := Node;
end;

function ParseEnumDeclaration(var Parser: TParser;
  ParentNode: Int32): Int32;
var
  Start, ItemToken: TToken;
  Name, ItemName: RawByteString;
  NameSpan, ItemSpan: TSourceSpan;
  Node, TypeSymbol, EnumType, ItemNode, ItemSymbol: Int32;
  Info: TTypeInfo;
  NextValue: Int64;
begin
  Start := Parser.Current;
  DialectError(Parser, 'enumeration declarations');
  Expect(Parser, tkEnum);
  if not ExpectIdentifier(Parser, Name, NameSpan) then
    Name := '<error-enum>';
  Info := Default(TTypeInfo);
  Info.Kind := tyEnum;
  Info.Flags := [tfValueType, tfComplete, tfRuntimeVisible];
  Info.NameId := StringPoolIntern(Parser.Symbols^.Strings, Name);
  Info.Size := 8;
  Info.Alignment := 8;
  Info.ElementType := FSIM_TYPE_INVALID;
  Info.ReturnType := FSIM_TYPE_INVALID;
  Info.RefClassSymbol := FSIM_INVALID_INDEX;
  Info.ParameterStart := FSIM_INVALID_INDEX;
  Info.LowerBound := 0;
  Info.UpperBound := -1;
  EnumType := SymAddType(Parser.Symbols^, Info);
  Node := ASTAddNamedNode(Parser.Tree^, nkTypeDecl,
    SourceSpan(Start.Span.StartPos, NameSpan.EndPos), Name);
  Parser.Tree^.Nodes[Node].TypeId := EnumType;
  TypeSymbol := SymAdd(Parser.Symbols^, Name, skType, EnumType,
    Parser.CurrentVisibility, [sfDefined], Node,
    Parser.Tree^.Nodes[Node].Span);
  Parser.Tree^.Nodes[Node].SymbolId := TypeSymbol;
  ASTAppendChild(Parser.Tree^, ParentNode, Node);
  if Accept(Parser, tkLParen) then
    ItemToken := Parser.Previous
  else
  begin
    Expect(Parser, tkBegin);
    ItemToken := Parser.Previous;
  end;
  NextValue := 0;
  while not At(Parser, tkRParen) and not At(Parser, tkEnd) and
        not At(Parser, tkEOF) do
  begin
    ItemToken := Parser.Current;
    if not ExpectIdentifier(Parser, ItemName, ItemSpan) then
      Break;
    if Accept(Parser, tkEqual) then
    begin
      if At(Parser, tkIntegerLiteral) then
      begin
        NextValue := Parser.Current.IntValue;
        Advance(Parser);
      end
      else
        ParserError(Parser, dcExpectedToken,
          'enumeration value must be an integer literal');
    end;
    ItemNode := ASTAddNamedNode(Parser.Tree^, nkConstantDecl,
      SourceSpan(ItemToken.Span.StartPos, ItemSpan.EndPos), ItemName);
    Parser.Tree^.Nodes[ItemNode].TypeId := EnumType;
    Parser.Tree^.Nodes[ItemNode].IntValue := NextValue;
    Include(Parser.Tree^.Nodes[ItemNode].Flags, nfConstant);
    ItemSymbol := SymAdd(Parser.Symbols^, ItemName, skEnumValue, EnumType,
      Parser.CurrentVisibility, [sfDefined, sfFinal], ItemNode,
      Parser.Tree^.Nodes[ItemNode].Span);
    Parser.Tree^.Nodes[ItemNode].SymbolId := ItemSymbol;
    if ItemSymbol >= 0 then
      Parser.Symbols^.Symbols[ItemSymbol].ConstantInt := NextValue;
    ASTAppendChild(Parser.Tree^, Node, ItemNode);
    Inc(NextValue);
    if not Accept(Parser, tkComma) then
      Break;
  end;
  if At(Parser, tkRParen) then
    Advance(Parser)
  else
    Expect(Parser, tkEnd);
  Expect(Parser, tkSemicolon);
  Parser.Tree^.Nodes[Node].Span.EndPos := Parser.Previous.Span.EndPos;
  Inc(Parser.ParsedDeclarationCount);
  Result := Node;
end;

function ParseLabelDeclaration(var Parser: TParser;
  ParentNode: Int32): Int32;
var
  Start: TToken;
  Name: RawByteString;
  NameSpan: TSourceSpan;
  Container, Node, SymbolId: Int32;
begin
  Start := Parser.Current;
  Expect(Parser, tkLabel);
  Container := MakeNode(Parser, nkLabelDecl, Start);
  ASTAppendChild(Parser.Tree^, ParentNode, Container);
  repeat
    if not ExpectIdentifier(Parser, Name, NameSpan) then
      Break;
    Node := ASTAddNamedNode(Parser.Tree^, nkLabelDecl, NameSpan, Name);
    SymbolId := SymAdd(Parser.Symbols^, Name, skLabel, FSIM_TYPE_VOID,
      Parser.CurrentVisibility, [sfDefined], Node, NameSpan);
    Parser.Tree^.Nodes[Node].SymbolId := SymbolId;
    ASTAppendChild(Parser.Tree^, Container, Node);
  until not Accept(Parser, tkComma);
  Expect(Parser, tkSemicolon);
  Parser.Tree^.Nodes[Container].Span.EndPos := Parser.Previous.Span.EndPos;
  Inc(Parser.ParsedDeclarationCount);
  Result := Container;
end;

function ParseSwitchDeclaration(var Parser: TParser;
  ParentNode: Int32): Int32;
var
  Start: TToken;
  Name: RawByteString;
  NameSpan: TSourceSpan;
  Node, TargetNode, SymbolId: Int32;
begin
  Start := Parser.Current;
  Expect(Parser, tkSwitch);
  if not ExpectIdentifier(Parser, Name, NameSpan) then
    Name := '<error-switch>';
  Expect(Parser, tkAssignValue);
  Node := ASTAddNamedNode(Parser.Tree^, nkSwitchDecl,
    SourceSpan(Start.Span.StartPos, NameSpan.EndPos), Name);
  SymbolId := SymAdd(Parser.Symbols^, Name, skSwitch, FSIM_TYPE_INTEGER,
    Parser.CurrentVisibility, [sfDefined], Node, Parser.Tree^.Nodes[Node].Span);
  Parser.Tree^.Nodes[Node].SymbolId := SymbolId;
  ASTAppendChild(Parser.Tree^, ParentNode, Node);
  repeat
    { The SIMULA switch list contains designational expressions, not merely
      label names.  Parse the normal conditional/call expression grammar and
      let semantic analysis restrict the accepted expression forms. }
    TargetNode := ParseExpression(Parser);
    if TargetNode >= 0 then
      ASTAppendChild(Parser.Tree^, Node, TargetNode);
  until not Accept(Parser, tkComma);
  Expect(Parser, tkSemicolon);
  Parser.Tree^.Nodes[Node].Span.EndPos := Parser.Previous.Span.EndPos;
  Inc(Parser.ParsedDeclarationCount);
  Result := Node;
end;

function ParseSignedConstantInteger(var Parser: TParser;
  out Value: Int64): Boolean;
var
  Negative: Boolean;
  SymbolId: Int32;
begin
  Negative := Accept(Parser, tkMinus);
  if At(Parser, tkIntegerLiteral) then
  begin
    Value := Parser.Current.IntValue;
    Advance(Parser);
    if Negative then Value := -Value;
    Exit(True);
  end;
  if At(Parser, tkIdentifier) then
  begin
    SymbolId := SymLookup(Parser.Symbols^, TokenText(Parser.Current));
    if (SymbolId >= 0) and
       (Parser.Symbols^.Symbols[SymbolId].Kind in [skConstant, skEnumValue]) then
    begin
      Value := Parser.Symbols^.Symbols[SymbolId].ConstantInt;
      Advance(Parser);
      if Negative then Value := -Value;
      Exit(True);
    end;
  end;
  ParserError(Parser, dcExpectedToken,
    'array bounds must be constant integer expressions');
  Value := 0;
  Result := False;
end;

function TryConstantIntegerNode(const Parser: TParser; Node: Int32;
  out Value: Int64): Boolean;
var
  Child, SymbolId: Int32;
begin
  Result := False;
  Value := 0;
  if (Node < 0) or (Node > High(Parser.Tree^.Nodes)) then Exit;
  case Parser.Tree^.Nodes[Node].Kind of
    nkIntegerLiteralExpr:
      begin
        Value := Parser.Tree^.Nodes[Node].IntValue;
        Exit(True);
      end;
    nkIdentifierExpr:
      begin
        SymbolId := Parser.Tree^.Nodes[Node].SymbolId;
        if (SymbolId >= 0) and (SymbolId <= High(Parser.Symbols^.Symbols)) and
           (Parser.Symbols^.Symbols[SymbolId].Kind in [skConstant, skEnumValue]) then
        begin
          Value := Parser.Symbols^.Symbols[SymbolId].ConstantInt;
          Exit(True);
        end;
      end;
    nkUnaryExpr:
      begin
        Child := Parser.Tree^.Nodes[Node].FirstChild;
        if not TryConstantIntegerNode(Parser, Child, Value) then Exit;
        case TUnaryOperator(Parser.Tree^.Nodes[Node].Aux) of
          uoPositive: Exit(True);
          uoNegative:
            begin
              if Value = Low(Int64) then Exit(False);
              Value := -Value;
              Exit(True);
            end;
        end;
      end;
  end;
end;

function ParseClassicArrayDeclaration(var Parser: TParser; ParentNode,
  ElementType: Int32; IsOwn: Boolean): Int32;
type
  TStringArray = array of RawByteString;
  TSpanArray = array of TSourceSpan;
  TInt64Array = array of Int64;
var
  Start: TToken;
  Names: TStringArray;
  NameSpans: TSpanArray;
  LowerNodes, UpperNodes: TInt32Array;
  LowerValues, UpperValues: TInt64Array;
  Name: RawByteString;
  NameSpan: TSourceSpan;
  Node, SymbolId, ArrayType, DimensionCount, I, N, BoundNode: Int32;
  Kind: TSymbolKind;
  Flags: TSymbolFlags;
  AllConstant, DynamicBounds: Boolean;
begin
  Start := Parser.Current;
  Expect(Parser, tkArray);
  SetLength(Names, 0);
  SetLength(NameSpans, 0);
  repeat
    if not ExpectIdentifier(Parser, Name, NameSpan) then Break;
    N := Length(Names);
    SetLength(Names, N + 1);
    SetLength(NameSpans, N + 1);
    Names[N] := Name;
    NameSpans[N] := NameSpan;
    if not Accept(Parser, tkComma) then Break;
    if not At(Parser, tkIdentifier) then
    begin
      ParserError(Parser, dcExpectedToken,
        'expected another array identifier before the bound pair');
      Break;
    end;
  until False;

  Expect(Parser, tkLBracket);
  SetLength(LowerNodes, 0);
  SetLength(UpperNodes, 0);
  SetLength(LowerValues, 0);
  SetLength(UpperValues, 0);
  AllConstant := True;
  repeat
    BoundNode := ParseExpression(Parser);
    N := Length(LowerNodes);
    SetLength(LowerNodes, N + 1);
    SetLength(LowerValues, N + 1);
    LowerNodes[N] := BoundNode;
    if not TryConstantIntegerNode(Parser, BoundNode, LowerValues[N]) then
      AllConstant := False;
    Expect(Parser, tkColon);
    BoundNode := ParseExpression(Parser);
    SetLength(UpperNodes, N + 1);
    SetLength(UpperValues, N + 1);
    UpperNodes[N] := BoundNode;
    if not TryConstantIntegerNode(Parser, BoundNode, UpperValues[N]) then
      AllConstant := False;
  until not Accept(Parser, tkComma);
  Expect(Parser, tkRBracket);
  Expect(Parser, tkSemicolon);

  DimensionCount := Length(LowerNodes);
  DynamicBounds := not AllConstant;
  ArrayType := ElementType;
  if DynamicBounds then
  begin
    if DimensionCount <> 1 then
      ParserErrorAt(Parser, Start, dcBackendUnsupported,
        'runtime-bounded arrays currently require exactly one dimension');
    ArrayType := SymMakeDynamicArrayType(Parser.Symbols^, ElementType);
  end
  else
    for I := DimensionCount - 1 downto 0 do
      ArrayType := SymMakeArrayType(Parser.Symbols^, ArrayType,
        LowerValues[I], UpperValues[I]);

  Result := FSIM_INVALID_INDEX;
  for I := 0 to High(Names) do
  begin
    Node := ASTAddNamedNode(Parser.Tree^, nkVariableDecl,
      SourceSpan(Start.Span.StartPos, Parser.Previous.Span.EndPos), Names[I]);
    Parser.Tree^.Nodes[Node].TypeId := ArrayType;
    Parser.Tree^.Nodes[Node].Aux := DimensionCount;
    if IsOwn then Include(Parser.Tree^.Nodes[Node].Flags, nfOwn);
    if DynamicBounds and (DimensionCount > 0) then
    begin
      if I = 0 then
      begin
        ASTAppendChild(Parser.Tree^, Node, LowerNodes[0]);
        ASTAppendChild(Parser.Tree^, Node, UpperNodes[0]);
      end
      else
      begin
        ASTAppendChild(Parser.Tree^, Node,
          ASTCloneSubtree(Parser.Tree^, LowerNodes[0]));
        ASTAppendChild(Parser.Tree^, Node,
          ASTCloneSubtree(Parser.Tree^, UpperNodes[0]));
      end;
    end;
    if ParserInClassBody(Parser) then Kind := skField else Kind := skVariable;
    Flags := [sfMutable];
    if IsOwn then Include(Flags, sfOwn);
    SymbolId := SymAdd(Parser.Symbols^, Names[I], Kind, ArrayType,
      Parser.CurrentVisibility, Flags, Node, Parser.Tree^.Nodes[Node].Span);
    Parser.Tree^.Nodes[Node].SymbolId := SymbolId;
    if SymbolId >= 0 then
    begin
      if Kind = skField then
        SymAddField(Parser.Symbols^, Parser.CurrentClass, SymbolId, ArrayType,
          Parser.CurrentVisibility)
      else
        SymAllocateLocal(Parser.Symbols^, SymbolId);
    end;
    ASTAppendChild(Parser.Tree^, ParentNode, Node);
    if Result < 0 then Result := Node;
    Inc(Parser.ParsedDeclarationCount);
  end;
end;


function ParseForeignDeclaration(var Parser: TParser;
  ParentNode: Int32): Int32;
var
  Start: TToken;
  AbiName, LibraryName, LocalName, LinkName: RawByteString;
  NameSpan: TSourceSpan;
  Node, SymbolId, ReturnType, ProcedureType, ParameterStart,
  ParameterCount, TypeId: Int32;
  IsFunction, Variadic, IsExport, IsPacked, IsOpaque: Boolean;

  function ParseForeignParameters(RoutineNode: Int32;
    out FirstParameter, Count: Int32; out HasVarArgs: Boolean): Boolean;
  var
    ParamName: RawByteString;
    ParamSpan: TSourceSpan;
    ParamNode, I: Int32;
    ParamNames: array of RawByteString;
    ParamTypes: array of Int32;
  begin
    Result := True;
    FirstParameter := FSIM_INVALID_INDEX;
    Count := 0;
    HasVarArgs := False;
    SetLength(ParamNames, 0);
    SetLength(ParamTypes, 0);
    if not Expect(Parser, tkLParen) then Exit(False);
    if not Accept(Parser, tkRParen) then
    begin
      repeat
        if Accept(Parser, tkEllipsis) then
        begin
          HasVarArgs := True;
          Break;
        end;
        if TokenCanBeIdentifier(Parser, Parser.Current.Kind) and
           LookAt(Parser, tkColon) then
        begin
          if not ExpectIdentifier(Parser, ParamName, ParamSpan) then Exit(False);
          Expect(Parser, tkColon);
          TypeId := ParseType(Parser);
        end
        else
        begin
          TypeId := ParseType(Parser);
          if not ExpectIdentifier(Parser, ParamName, ParamSpan) then Exit(False);
        end;
        if not SymIsCABIType(Parser.Symbols^, TypeId, False) then
          AddError(Parser.Diagnostics^, dcTypeMismatch, ParamSpan,
            'foreign c parameter ''' + ParamName + ''' needs an explicit c_* ABI type, got ' +
            TypeName(Parser.Symbols^, TypeId));
        ParamNode := ASTAddNamedNode(Parser.Tree^, nkParameterDecl,
          ParamSpan, ParamName);
        Parser.Tree^.Nodes[ParamNode].TypeId := TypeId;
        Include(Parser.Tree^.Nodes[ParamNode].Flags, nfValueParameter);
        ASTAppendChild(Parser.Tree^, RoutineNode, ParamNode);
        SetLength(ParamNames, Length(ParamNames) + 1);
        SetLength(ParamTypes, Length(ParamTypes) + 1);
        ParamNames[High(ParamNames)] := ParamName;
        ParamTypes[High(ParamTypes)] := TypeId;
        if At(Parser, tkEllipsis) then
        begin
          Advance(Parser);
          HasVarArgs := True;
          Break;
        end;
      until not Accept(Parser, tkComma);
      Expect(Parser, tkRParen);
    end;
    FirstParameter := Length(Parser.Symbols^.Parameters);
    Count := Length(ParamTypes);
    for I := 0 to Count - 1 do
      SymAddParameter(Parser.Symbols^, ParamNames[I], ParamTypes[I], pmValue,
        FSIM_INVALID_INDEX, FSIM_INVALID_INDEX);
  end;

  function ParseCRecordType(IsUnion, PackedLayout, OpaqueLayout: Boolean): Int32;
  var
    RecordName, FieldName: RawByteString;
    RecordSpan, FieldSpan: TSourceSpan;
    TypeNode, TypeSymbol, RecordType, FieldNode, FieldSymbol, FieldType: Int32;
    Info: TTypeInfo;
    Offset, FieldSize: QWord;
    FieldAlignment: UInt32;
  begin
    Result := FSIM_INVALID_INDEX;
    if IsUnion then
      Advance(Parser)
    else
      Expect(Parser, tkRecord);
    if not ExpectIdentifier(Parser, RecordName, RecordSpan) then
      RecordName := '<error-c-record>';

    Info := Default(TTypeInfo);
    Info.Kind := tyRecord;
    Info.Flags := [tfValueType, tfCLayout];
    if not OpaqueLayout then Include(Info.Flags, tfComplete);
    if IsUnion then Include(Info.Flags, tfCUnion);
    Info.NameId := StringPoolIntern(Parser.Symbols^.Strings, RecordName);
    Info.Size := 0;
    Info.Alignment := 1;
    Info.ElementType := FSIM_TYPE_INVALID;
    Info.ReturnType := FSIM_TYPE_INVALID;
    Info.RefClassSymbol := FSIM_INVALID_INDEX;
    Info.ParameterStart := FSIM_INVALID_INDEX;
    Info.LowerBound := 0;
    Info.UpperBound := -1;
    RecordType := SymAddType(Parser.Symbols^, Info);

    TypeNode := ASTAddNamedNode(Parser.Tree^, nkTypeDecl,
      SourceSpan(Start.Span.StartPos, RecordSpan.EndPos), RecordName);
    Parser.Tree^.Nodes[TypeNode].TypeId := RecordType;
    TypeSymbol := SymAdd(Parser.Symbols^, RecordName, skType, RecordType,
      Parser.CurrentVisibility, [sfDefined], TypeNode,
      Parser.Tree^.Nodes[TypeNode].Span);
    Parser.Tree^.Nodes[TypeNode].SymbolId := TypeSymbol;
    if TypeSymbol >= 0 then
      Parser.Symbols^.Types[RecordType].RefClassSymbol := TypeSymbol;
    ASTAppendChild(Parser.Tree^, ParentNode, TypeNode);

    if OpaqueLayout then
    begin
      Parser.Symbols^.Types[RecordType].Size := 0;
      Parser.Symbols^.Types[RecordType].Alignment := 1;
      Expect(Parser, tkSemicolon);
      Inc(Parser.ParsedDeclarationCount);
      Exit(TypeNode);
    end;

    Expect(Parser, tkBegin);
    SymEnterScope(Parser.Symbols^, scBlock, TypeSymbol);
    while not At(Parser, tkEnd) and not At(Parser, tkEOF) do
    begin
      Accept(Parser, tkVar);
      if TokenCanBeIdentifier(Parser, Parser.Current.Kind) and
         LookAt(Parser, tkColon) then
      begin
        if not ExpectIdentifier(Parser, FieldName, FieldSpan) then Break;
        Expect(Parser, tkColon);
        FieldType := ParseType(Parser);
      end
      else
      begin
        FieldType := ParseType(Parser);
        if not ExpectIdentifier(Parser, FieldName, FieldSpan) then Break;
      end;
      if not SymIsCStorageType(Parser.Symbols^, FieldType) then
        AddError(Parser.Diagnostics^, dcTypeMismatch, FieldSpan,
          'C record field ''' + FieldName + ''' needs a complete fixed C-layout type, got ' +
          TypeName(Parser.Symbols^, FieldType));
      Expect(Parser, tkSemicolon);

      FieldNode := ASTAddNamedNode(Parser.Tree^, nkVariableDecl, FieldSpan,
        FieldName);
      Parser.Tree^.Nodes[FieldNode].TypeId := FieldType;
      FieldSymbol := SymAdd(Parser.Symbols^, FieldName, skField, FieldType,
        visPublic, [sfDefined, sfMutable], FieldNode,
        Parser.Tree^.Nodes[FieldNode].Span);
      Parser.Tree^.Nodes[FieldNode].SymbolId := FieldSymbol;
      ASTAppendChild(Parser.Tree^, TypeNode, FieldNode);
      if FieldSymbol < 0 then Continue;

      FieldSize := Parser.Symbols^.Types[FieldType].Size;
      FieldAlignment := Parser.Symbols^.Types[FieldType].Alignment;
      if FieldAlignment = 0 then FieldAlignment := 1;
      if PackedLayout then FieldAlignment := 1;
      if IsUnion then Offset := 0
      else if PackedLayout then Offset := Parser.Symbols^.Types[RecordType].Size
      else Offset := AlignUp(Parser.Symbols^.Types[RecordType].Size,
        FieldAlignment);
      if Offset > High(UInt32) then
        raise ERangeError.Create('C record layout exceeds 4 GiB');
      Parser.Symbols^.Symbols[FieldSymbol].StorageOffset := UInt32(Offset);
      Parser.Symbols^.Symbols[FieldSymbol].StorageSize := UInt32(FieldSize);
      if IsUnion then
      begin
        if FieldSize > Parser.Symbols^.Types[RecordType].Size then
          Parser.Symbols^.Types[RecordType].Size := UInt32(FieldSize);
      end
      else
        Parser.Symbols^.Types[RecordType].Size := UInt32(Offset + FieldSize);
      if FieldAlignment > Parser.Symbols^.Types[RecordType].Alignment then
        Parser.Symbols^.Types[RecordType].Alignment := FieldAlignment;
    end;
    SymLeaveScope(Parser.Symbols^);
    Expect(Parser, tkEnd);
    Accept(Parser, tkSemicolon);
    if PackedLayout then
      Parser.Symbols^.Types[RecordType].Alignment := 1
    else if Parser.Symbols^.Types[RecordType].Alignment > 1 then
      Parser.Symbols^.Types[RecordType].Size := UInt32(AlignUp(
        Parser.Symbols^.Types[RecordType].Size,
        Parser.Symbols^.Types[RecordType].Alignment));
    Inc(Parser.ParsedDeclarationCount);
    Result := TypeNode;
  end;

begin
  Result := FSIM_INVALID_INDEX;
  Start := Parser.Current;
  DialectError(Parser, 'C foreign blocks');
  Expect(Parser, tkForeign);
  if not ExpectIdentifier(Parser, AbiName, NameSpan) then Exit;
  if LowerASCII(AbiName) <> 'c' then
    AddError(Parser.Diagnostics^, dcBackendUnsupported, NameSpan,
      'only the c foreign ABI is available on this target');

  IsExport := Accept(Parser, tkExport);
  if IsExport then
  begin
    if not (Parser.Current.Kind in [tkFunction, tkProcedure]) then
    begin
      ParserError(Parser, dcExpectedToken,
        'foreign c export expects a function or procedure declaration');
      Exit;
    end;
    IsFunction := Parser.Current.Kind = tkFunction;
    Node := ParseProcedureDeclaration(Parser, ParentNode, FSIM_TYPE_VOID,
      IsFunction);
    if (Node >= 0) and (Node <= High(Parser.Tree^.Nodes)) then
    begin
      SymbolId := Parser.Tree^.Nodes[Node].SymbolId;
      if (SymbolId >= 0) and (SymbolId <= High(Parser.Symbols^.Symbols)) then
      begin
        Include(Parser.Symbols^.Symbols[SymbolId].Flags, sfForeignExport);
        if Parser.Symbols^.Symbols[SymbolId].OwnerSymbol >= 0 then
          AddError(Parser.Diagnostics^, dcBackendUnsupported, NameSpan,
            'foreign c export currently requires a top-level routine without an implicit object receiver');
        ProcedureType := Parser.Symbols^.Symbols[SymbolId].TypeId;
        if (ProcedureType >= 0) and (ProcedureType <= High(Parser.Symbols^.Types)) and
           (Parser.Symbols^.Types[ProcedureType].Kind = tyProcedure) then
        begin
          ReturnType := Parser.Symbols^.Types[ProcedureType].ReturnType;
          if not SymIsCABIType(Parser.Symbols^, ReturnType, True) then
            AddError(Parser.Diagnostics^, dcTypeMismatch, NameSpan,
              'foreign c export return type needs an explicit C ABI type, got ' +
              TypeName(Parser.Symbols^, ReturnType));
          ParameterStart := Parser.Symbols^.Types[ProcedureType].ParameterStart;
          ParameterCount := Parser.Symbols^.Types[ProcedureType].ParameterCount;
          for TypeId := 0 to ParameterCount - 1 do
            if (Parser.Symbols^.Parameters[ParameterStart + TypeId].Mode <> pmValue) or
               not SymIsCABIType(Parser.Symbols^,
                 Parser.Symbols^.Parameters[ParameterStart + TypeId].TypeId, False) then
              AddError(Parser.Diagnostics^, dcTypeMismatch, NameSpan,
                'foreign c export parameters must be value parameters with explicit C ABI types');
        end;
      end;
    end;
    Exit(Node);
  end;

  IsPacked := False;
  IsOpaque := False;
  while At(Parser, tkIdentifier) and
        (ASCIIEqualFold(TokenText(Parser.Current), 'packed') or
         ASCIIEqualFold(TokenText(Parser.Current), 'opaque')) do
  begin
    if ASCIIEqualFold(TokenText(Parser.Current), 'packed') then
      IsPacked := True
    else
      IsOpaque := True;
    Advance(Parser);
  end;
  if IsPacked and IsOpaque then
    AddError(Parser.Diagnostics^, dcDialectViolation, NameSpan,
      'a C record cannot be both packed and opaque');
  if At(Parser, tkRecord) then
    Exit(ParseCRecordType(False, IsPacked, IsOpaque));
  if At(Parser, tkIdentifier) and
     ASCIIEqualFold(TokenText(Parser.Current), 'union') then
    Exit(ParseCRecordType(True, IsPacked, IsOpaque));
  if IsPacked or IsOpaque then
    AddError(Parser.Diagnostics^, dcExpectedToken, Parser.Current.Span,
      'packed/opaque after foreign c must describe a record or union');
  Expect(Parser, tkFrom);
  if not At(Parser, tkStringLiteral) then
  begin
    ParserError(Parser, dcExpectedToken,
      'foreign c from expects a shared-library name');
    Exit;
  end;
  LibraryName := TokenText(Parser.Current);
  Advance(Parser);
  Expect(Parser, tkBegin);
  while not At(Parser, tkEnd) and not At(Parser, tkEOF) do
  begin
    if Accept(Parser, tkVar) then
    begin
      if not ExpectIdentifier(Parser, LocalName, NameSpan) then
        LocalName := '<error-foreign-data>';
      Expect(Parser, tkColon);
      TypeId := ParseType(Parser);
      if not SymIsCABIType(Parser.Symbols^, TypeId, False) then
        AddError(Parser.Diagnostics^, dcTypeMismatch, NameSpan,
          'foreign c data ''' + LocalName + ''' needs an explicit c_* ABI type, got ' +
          TypeName(Parser.Symbols^, TypeId));
      LinkName := LocalName;
      if Accept(Parser, tkEqual) then
      begin
        if At(Parser, tkStringLiteral) then
        begin
          LinkName := TokenText(Parser.Current);
          Advance(Parser);
        end
        else
          ParserError(Parser, dcExpectedToken,
            'foreign data symbol identification must be a string');
      end;
      Expect(Parser, tkSemicolon);
      Node := ASTAddNamedNode(Parser.Tree^, nkVariableDecl,
        SourceSpan(Start.Span.StartPos, NameSpan.EndPos), LocalName);
      Parser.Tree^.Nodes[Node].TypeId := TypeId;
      SymbolId := SymAdd(Parser.Symbols^, LocalName, skVariable, TypeId,
        Parser.CurrentVisibility, [sfDefined, sfImported, sfForeign, sfMutable],
        Node, Parser.Tree^.Nodes[Node].Span);
      Parser.Tree^.Nodes[Node].SymbolId := SymbolId;
      if SymbolId >= 0 then
        SymAddForeignBinding(Parser.Symbols^, SymbolId, LinkName, LibraryName,
          False, fbObject);
      ASTAppendChild(Parser.Tree^, ParentNode, Node);
      if Result < 0 then Result := Node;
      Inc(Parser.ParsedDeclarationCount);
      Continue;
    end;
    ReturnType := FSIM_TYPE_VOID;
    IsFunction := False;
    if Accept(Parser, tkFunction) then
      IsFunction := True
    else if Accept(Parser, tkProcedure) then
      IsFunction := False
    else if TokenStartsType(Parser.Current.Kind) or CurrentTokenIsTypeAlias(Parser) then
    begin
      ReturnType := ParseType(Parser);
      IsFunction := True;
      Expect(Parser, tkProcedure);
    end
    else
    begin
      ParserError(Parser, dcExpectedToken,
        'foreign block expects function or procedure declaration');
      Synchronize(Parser);
      if At(Parser, tkSemicolon) then Advance(Parser);
      Continue;
    end;

    if not ExpectRoutineIdentifier(Parser, LocalName, NameSpan) then
      LocalName := '<error-foreign>';
    if IsFunction then
      Node := ASTAddNamedNode(Parser.Tree^, nkFunctionDecl,
        SourceSpan(Start.Span.StartPos, NameSpan.EndPos), LocalName)
    else
      Node := ASTAddNamedNode(Parser.Tree^, nkProcedureDecl,
        SourceSpan(Start.Span.StartPos, NameSpan.EndPos), LocalName);
    Include(Parser.Tree^.Nodes[Node].Flags, nfNative);
    ParseForeignParameters(Node, ParameterStart, ParameterCount, Variadic);
    if IsFunction and Accept(Parser, tkColon) then
      ReturnType := ParseType(Parser)
    else if IsFunction and (ReturnType = FSIM_TYPE_VOID) then
    begin
      ParserError(Parser, dcExpectedToken,
        'foreign function needs an explicit return type');
      ReturnType := FSIM_TYPE_INVALID;
    end;
    if IsFunction and not SymIsCABIType(Parser.Symbols^, ReturnType, False) then
      AddError(Parser.Diagnostics^, dcTypeMismatch, NameSpan,
        'foreign c function ''' + LocalName + ''' needs an explicit c_* ABI return type, got ' +
        TypeName(Parser.Symbols^, ReturnType));
    LinkName := LocalName;
    if Accept(Parser, tkEqual) then
    begin
      if At(Parser, tkStringLiteral) then
      begin
        LinkName := TokenText(Parser.Current);
        Advance(Parser);
      end
      else
        ParserError(Parser, dcExpectedToken,
          'foreign symbol identification must be a string');
    end;
    Expect(Parser, tkSemicolon);

    ProcedureType := SymMakeProcedureType(Parser.Symbols^, ReturnType,
      ParameterStart, ParameterCount);
    { Imported C routines are represented by ordinary routine symbols plus C ABI
      binding metadata.  Keep the ellipsis bit on the type as well so the
      signature remains self-describing through later lowering/copying passes. }
    if Variadic then
      Include(Parser.Symbols^.Types[ProcedureType].Flags, tfCVariadic);
    Parser.Tree^.Nodes[Node].TypeId := ProcedureType;
    if IsFunction then
      SymbolId := SymAdd(Parser.Symbols^, LocalName, skFunction,
        ProcedureType, Parser.CurrentVisibility,
        [sfDefined, sfImported, sfForeign], Node,
        Parser.Tree^.Nodes[Node].Span)
    else
      SymbolId := SymAdd(Parser.Symbols^, LocalName, skProcedure,
        ProcedureType, Parser.CurrentVisibility,
        [sfDefined, sfImported, sfForeign], Node,
        Parser.Tree^.Nodes[Node].Span);
    Parser.Tree^.Nodes[Node].SymbolId := SymbolId;
    if SymbolId >= 0 then
      SymAddForeignBinding(Parser.Symbols^, SymbolId, LinkName, LibraryName,
        Variadic);
    ASTAppendChild(Parser.Tree^, ParentNode, Node);
    if Result < 0 then Result := Node;
    Inc(Parser.ParsedDeclarationCount);
  end;
  Expect(Parser, tkEnd);
  Accept(Parser, tkSemicolon);
end;

function ParseExternalDeclaration(var Parser: TParser;
  ParentNode: Int32): Int32;
var
  Start: TToken;
  Name: RawByteString;
  NameSpan: TSourceSpan;
  Node, SymbolId, ReturnType, ProcedureType, FirstNode: Int32;
  IsClass: Boolean;

  procedure SkipExternalIdentification;
  begin
    if Accept(Parser, tkEqual) then
    begin
      if At(Parser, tkStringLiteral) then
        Advance(Parser)
      else
        ParserError(Parser, dcExpectedToken,
          'external identification must be a string');
    end;
  end;

  procedure AddClassItem;
  begin
    if not ExpectIdentifier(Parser, Name, NameSpan) then
      Name := '<error-external-class>';
    Node := ASTAddNamedNode(Parser.Tree^, nkClassDecl,
      SourceSpan(Start.Span.StartPos, NameSpan.EndPos), Name);
    Include(Parser.Tree^.Nodes[Node].Flags, nfNative);
    SymbolId := SymAdd(Parser.Symbols^, Name, skClass, FSIM_TYPE_INVALID,
      visPublic, [sfDefined, sfImported], Node, Parser.Tree^.Nodes[Node].Span);
    Parser.Tree^.Nodes[Node].SymbolId := SymbolId;
    ASTAppendChild(Parser.Tree^, ParentNode, Node);
    if SymbolId >= 0 then
    begin
      SymRegisterClass(Parser.Symbols^, SymbolId, FSIM_INVALID_INDEX, False, False);
      SymSetClassParameters(Parser.Symbols^, SymbolId,
        Length(Parser.Symbols^.Parameters), 0);
      SymFinalizeClass(Parser.Symbols^, SymbolId);
    end;
    SkipExternalIdentification;
    Inc(Parser.ParsedDeclarationCount);
    if FirstNode < 0 then FirstNode := Node;
  end;

  procedure AddProcedureItem;
  var
    Kind: TSymbolKind;
  begin
    if not ExpectIdentifier(Parser, Name, NameSpan) then
      Name := '<error-external-procedure>';
    if ReturnType = FSIM_TYPE_VOID then Kind := skProcedure else Kind := skFunction;
    if Kind = skFunction then
      Node := ASTAddNamedNode(Parser.Tree^, nkFunctionDecl,
        SourceSpan(Start.Span.StartPos, NameSpan.EndPos), Name)
    else
      Node := ASTAddNamedNode(Parser.Tree^, nkProcedureDecl,
        SourceSpan(Start.Span.StartPos, NameSpan.EndPos), Name);
    Include(Parser.Tree^.Nodes[Node].Flags, nfNative);
    ProcedureType := SymMakeProcedureType(Parser.Symbols^, ReturnType,
      Length(Parser.Symbols^.Parameters), 0);
    Parser.Tree^.Nodes[Node].TypeId := ProcedureType;
    SymbolId := SymAdd(Parser.Symbols^, Name, Kind, ProcedureType,
      Parser.CurrentVisibility, [sfDefined, sfImported], Node,
      Parser.Tree^.Nodes[Node].Span);
    Parser.Tree^.Nodes[Node].SymbolId := SymbolId;
    ASTAppendChild(Parser.Tree^, ParentNode, Node);
    SkipExternalIdentification;
    Inc(Parser.ParsedDeclarationCount);
    if FirstNode < 0 then FirstNode := Node;
  end;

begin
  Result := FSIM_INVALID_INDEX;
  FirstNode := FSIM_INVALID_INDEX;
  Start := Parser.Current;
  Expect(Parser, tkExternal);
  ReturnType := FSIM_TYPE_VOID;
  IsClass := Accept(Parser, tkClass);
  if not IsClass then
  begin
    if TokenStartsType(Parser.Current.Kind) then
      ReturnType := ParseType(Parser)
    else if Parser.Current.Kind = tkIdentifier then
    begin
      { the optional "kind" is implementation-defined in the standard,
        usually old compiler names like fortran. we just consume it here,
        pretending we can link every 1970s object format would be nuts. }
      Advance(Parser);
      if TokenStartsType(Parser.Current.Kind) then
        ReturnType := ParseType(Parser);
    end;
    Expect(Parser, tkProcedure);
  end;
  repeat
    if IsClass then AddClassItem else AddProcedureItem;
  until not Accept(Parser, tkComma);
  if Accept(Parser, tkIs) then
  begin
    ParserError(Parser, dcBackendUnsupported,
      'external procedure specifications with inline foreign signatures are unsupported');
    while not At(Parser, tkSemicolon) and not At(Parser, tkEOF) do
      Advance(Parser);
  end;
  Expect(Parser, tkSemicolon);
  Result := FirstNode;
end;

function ParseDeclaration(var Parser: TParser; ParentNode: Int32): Int32;
var
  IsOwn: Boolean;
  TypeId: Int32;
  PrefixName: RawByteString;
  PrefixSpan: TSourceSpan;
  Start: TToken;
begin
  IsOwn := Accept(Parser, tkOwn);
  if IsOwn and (Parser.Options^.Dialect = fdSimula67) then
    AddError(Parser.Diagnostics^, dcDialectViolation, Parser.Previous.Span,
      '''own'' is an ALGOL extension, not SIMULA 67');
  if TokenCanNameClass(Parser.Current.Kind) and LookAt(Parser, tkClass) then
  begin
    Start := Parser.Current;
    PrefixName := TokenText(Parser.Current);
    PrefixSpan := Parser.Current.Span;
    Advance(Parser);
    Result := ParseClassDeclaration(Parser, ParentNode, PrefixName, True,
      ASCIIEqualFold(PrefixName, 'process'), False);
    if PrefixSpan.StartPos.Offset = Start.Span.StartPos.Offset then
      ;
    Exit;
  end;
  case Parser.Current.Kind of
    tkExternal:
      Exit(ParseExternalDeclaration(Parser, ParentNode));
    tkForeign:
      Exit(ParseForeignDeclaration(Parser, ParentNode));
    tkConst:
      Exit(ParseConstantDeclaration(Parser, ParentNode));
    tkType:
      Exit(ParseTypeAliasDeclaration(Parser, ParentNode));
    tkEnum:
      Exit(ParseEnumDeclaration(Parser, ParentNode));
    tkVar:
      Exit(ParsePascalVariableDeclaration(Parser, ParentNode, False));
    tkThreadLocal:
      Exit(ParsePascalVariableDeclaration(Parser, ParentNode, True));
    tkRecord:
      begin
        DialectError(Parser, 'record declarations');
        ParserError(Parser, dcBackendUnsupported,
          'record value layout is reserved but unavailable in the current native ABI');
        Advance(Parser);
        Exit(FSIM_INVALID_INDEX);
      end;
    tkClass:
      Exit(ParseClassDeclaration(Parser, ParentNode, '', False, False, False));
    tkProcess:
      Exit(ParseClassDeclaration(Parser, ParentNode, '', False, True, False));
    tkThread, tkTask:
      Exit(ParseClassDeclaration(Parser, ParentNode, '', False, False, True));
    tkLabel:
      Exit(ParseLabelDeclaration(Parser, ParentNode));
    tkSwitch:
      Exit(ParseSwitchDeclaration(Parser, ParentNode));
    tkArray:
      begin
        if LookAt(Parser, tkIdentifier) then
          Exit(ParseClassicArrayDeclaration(Parser, ParentNode,
            FSIM_TYPE_REAL, IsOwn));
        TypeId := ParseType(Parser);
        Exit(ParseVariableDeclaration(Parser, ParentNode, TypeId, IsOwn));
      end;
    tkProcedure:
      Exit(ParseProcedureDeclaration(Parser, ParentNode, FSIM_TYPE_VOID, False));
    tkFunction:
      Exit(ParseProcedureDeclaration(Parser, ParentNode, FSIM_TYPE_VOID, True));
  end;
  if TokenStartsType(Parser.Current.Kind) or CurrentTokenIsTypeAlias(Parser) then
  begin
    TypeId := ParseType(Parser);
    if At(Parser, tkProcedure) then
      Exit(ParseProcedureDeclaration(Parser, ParentNode, TypeId, False));
    if At(Parser, tkFunction) then
      Exit(ParseProcedureDeclaration(Parser, ParentNode, TypeId, True));
    if At(Parser, tkArray) then
      Exit(ParseClassicArrayDeclaration(Parser, ParentNode, TypeId, IsOwn));
    Exit(ParseVariableDeclaration(Parser, ParentNode, TypeId, IsOwn));
  end;
  ParserError(Parser, dcUnexpectedToken,
    'expected declaration, found ' + TokenKindName(Parser.Current.Kind));
  if not At(Parser, tkEOF) then
    Advance(Parser);
  Result := FSIM_INVALID_INDEX;
end;

function ParseBlockStatement(var Parser: TParser): Int32;
var
  Start: TToken;
  Node, Child, PreviousBlock, ScopeId: Int32;
  DeclarationsOpen: Boolean;
begin
  Start := Parser.Current;
  Expect(Parser, tkBegin);
  Node := MakeNode(Parser, nkBlockStatement, Start);
  PreviousBlock := Parser.CurrentBlock;
  Parser.CurrentBlock := Node;
  ScopeId := SymEnterScope(Parser.Symbols^, scBlock, Parser.CurrentRoutine);
  Parser.Tree^.Nodes[Node].Aux := ScopeId;
  DeclarationsOpen := True;
  while not At(Parser, tkEnd) and not At(Parser, tkEOF) do
  begin
    if DeclarationsOpen and (ParserStartsDeclaration(Parser) or
       (TokenCanNameClass(Parser.Current.Kind) and LookAt(Parser, tkClass))) then
      ParseDeclaration(Parser, Node)
    else
    begin
      DeclarationsOpen := False;
      Child := ParseStatement(Parser);
      if Child >= 0 then
        ASTAppendChild(Parser.Tree^, Node, Child);
      if not Accept(Parser, tkSemicolon) and
         not At(Parser, tkEnd) and not At(Parser, tkElse) and
         not At(Parser, tkCatch) and not At(Parser, tkFinally) then
        ParserError(Parser, dcExpectedToken,
          'expected semicolon between statements');
    end;
    if Parser.ErrorRecovery then
      Synchronize(Parser);
  end;
  Expect(Parser, tkEnd);
  Parser.Tree^.Nodes[Node].Span.EndPos := Parser.Previous.Span.EndPos;
  SymLeaveScope(Parser.Symbols^);
  Parser.Symbols^.CurrentScope := Parser.Symbols^.Scopes[ScopeId].ParentScope;
  Parser.CurrentBlock := PreviousBlock;
  Result := Node;
end;

function ParseIfStatement(var Parser: TParser): Int32;
var
  Start: TToken;
  Node, ConditionNode, ThenNode, ElseNode: Int32;
begin
  Start := Parser.Current;
  Expect(Parser, tkIf);
  ConditionNode := ParseExpression(Parser);
  Expect(Parser, tkThen);
  ThenNode := ParseStatement(Parser);
  Node := MakeNode(Parser, nkIfStatement, Start);
  if ConditionNode >= 0 then ASTAppendChild(Parser.Tree^, Node, ConditionNode);
  if ThenNode >= 0 then ASTAppendChild(Parser.Tree^, Node, ThenNode);
  if Accept(Parser, tkElse) then
  begin
    ElseNode := ParseStatement(Parser);
    if ElseNode >= 0 then ASTAppendChild(Parser.Tree^, Node, ElseNode);
  end;
  Result := Node;
end;

function ParseWhileStatement(var Parser: TParser): Int32;
var
  Start: TToken;
  Node, ConditionNode, BodyNode: Int32;
begin
  Start := Parser.Current;
  Expect(Parser, tkWhile);
  ConditionNode := ParseExpression(Parser);
  Expect(Parser, tkDo);
  Inc(Parser.LoopDepth);
  BodyNode := ParseStatement(Parser);
  Dec(Parser.LoopDepth);
  Node := MakeNode(Parser, nkWhileStatement, Start);
  if ConditionNode >= 0 then ASTAppendChild(Parser.Tree^, Node, ConditionNode);
  if BodyNode >= 0 then ASTAppendChild(Parser.Tree^, Node, BodyNode);
  Result := Node;
end;

function ParseForStatement(var Parser: TParser): Int32;
var
  Start, ElementStart: TToken;
  Node, VariableNode, ElementNode, FirstNode, StepNode, UntilNode,
  ConditionNode, BodyNode: Int32;
  Name: RawByteString;
  NameSpan: TSourceSpan;
  IsReferenceFor: Boolean;
begin
  Start := Parser.Current;
  Expect(Parser, tkFor);
  if ExpectIdentifier(Parser, Name, NameSpan) then
  begin
    VariableNode := ASTAddNamedNode(Parser.Tree^, nkIdentifierExpr,
      NameSpan, Name);
    Include(Parser.Tree^.Nodes[VariableNode].Flags, nfLValue);
  end
  else
    VariableNode := FSIM_INVALID_INDEX;
  IsReferenceFor := At(Parser, tkAssignReference);
  if IsReferenceFor then
    Expect(Parser, tkAssignReference)
  else
    Expect(Parser, tkAssignValue);
  Node := MakeNode(Parser, nkForStatement, Start);
  Parser.Tree^.Nodes[Node].Aux := Ord(IsReferenceFor);
  if VariableNode >= 0 then ASTAppendChild(Parser.Tree^, Node, VariableNode);
  repeat
    ElementStart := Parser.Current;
    FirstNode := ParseExpression(Parser);
    if Accept(Parser, tkStep) then
    begin
      if IsReferenceFor then
        ParserErrorAt(Parser, ElementStart, dcTypeMismatch,
          'reference for-lists do not permit step-until elements');
      StepNode := ParseExpression(Parser);
      Expect(Parser, tkUntil);
      UntilNode := ParseExpression(Parser);
      ElementNode := MakeNode(Parser, nkForStepUntilElement, ElementStart);
      if FirstNode >= 0 then ASTAppendChild(Parser.Tree^, ElementNode, FirstNode);
      if StepNode >= 0 then ASTAppendChild(Parser.Tree^, ElementNode, StepNode);
      if UntilNode >= 0 then ASTAppendChild(Parser.Tree^, ElementNode, UntilNode);
    end
    else if Accept(Parser, tkWhile) then
    begin
      ConditionNode := ParseExpression(Parser);
      ElementNode := MakeNode(Parser, nkForWhileElement, ElementStart);
      if FirstNode >= 0 then ASTAppendChild(Parser.Tree^, ElementNode, FirstNode);
      if ConditionNode >= 0 then
        ASTAppendChild(Parser.Tree^, ElementNode, ConditionNode);
    end
    else
    begin
      ElementNode := MakeNode(Parser, nkForValueElement, ElementStart);
      if FirstNode >= 0 then ASTAppendChild(Parser.Tree^, ElementNode, FirstNode);
    end;
    Parser.Tree^.Nodes[ElementNode].Aux := Ord(IsReferenceFor);
    ASTAppendChild(Parser.Tree^, Node, ElementNode);
  until not Accept(Parser, tkComma);
  Expect(Parser, tkDo);
  Inc(Parser.LoopDepth);
  BodyNode := ParseStatement(Parser);
  Dec(Parser.LoopDepth);
  Parser.Tree^.Nodes[Node].BodyNode := BodyNode;
  if BodyNode >= 0 then ASTAppendChild(Parser.Tree^, Node, BodyNode);
  Parser.Tree^.Nodes[Node].Span.EndPos := Parser.Previous.Span.EndPos;
  Result := Node;
end;

function ParseGotoStatement(var Parser: TParser): Int32;
var
  Start: TToken;
  TargetNode: Int32;
begin
  Start := Parser.Current;
  Expect(Parser, tkGo);
  Expect(Parser, tkTo);
  TargetNode := ParseExpression(Parser);
  Result := MakeNode(Parser, nkGotoStatement, Start);
  if TargetNode >= 0 then
  begin
    ASTAppendChild(Parser.Tree^, Result, TargetNode);
    Parser.Tree^.Nodes[Result].Span.EndPos :=
      Parser.Tree^.Nodes[TargetNode].Span.EndPos;
  end;
end;

function ParseInspectStatement(var Parser: TParser): Int32;
var
  Start, ClauseStart: TToken;
  SubjectNode, ClauseNode, BodyNode, OtherwiseNode: Int32;
  ClassName: RawByteString;
  ClassSpan: TSourceSpan;
begin
  Start := Parser.Current;
  Expect(Parser, tkInspect);
  SubjectNode := ParseExpression(Parser);
  Result := MakeNode(Parser, nkInspectStatement, Start);
  if SubjectNode >= 0 then ASTAppendChild(Parser.Tree^, Result, SubjectNode);
  if Accept(Parser, tkDo) then
  begin
    ClauseNode := MakeNode(Parser, nkWhenClause, Parser.Previous);
    Parser.Tree^.Nodes[ClauseNode].NameId := StringPoolIntern(
      Parser.Tree^.Strings, '$do');
    BodyNode := ParseStatement(Parser);
    if BodyNode >= 0 then ASTAppendChild(Parser.Tree^, ClauseNode, BodyNode);
    ASTAppendChild(Parser.Tree^, Result, ClauseNode);
  end;
  while Accept(Parser, tkWhen) do
  begin
    ClauseStart := Parser.Previous;
    if not ExpectIdentifier(Parser, ClassName, ClassSpan) then
      ClassName := '<error-class>';
    ClauseNode := ASTAddNamedNode(Parser.Tree^, nkWhenClause,
      SourceSpan(ClauseStart.Span.StartPos, ClassSpan.EndPos), ClassName);
    Expect(Parser, tkDo);
    BodyNode := ParseStatement(Parser);
    if BodyNode >= 0 then ASTAppendChild(Parser.Tree^, ClauseNode, BodyNode);
    ASTAppendChild(Parser.Tree^, Result, ClauseNode);
  end;
  if Accept(Parser, tkOtherwise) then
  begin
    OtherwiseNode := MakeNode(Parser, nkWhenClause, Parser.Previous);
    Parser.Tree^.Nodes[OtherwiseNode].NameId := StringPoolIntern(
      Parser.Tree^.Strings, 'otherwise');
    BodyNode := ParseStatement(Parser);
    if BodyNode >= 0 then ASTAppendChild(Parser.Tree^, OtherwiseNode, BodyNode);
    ASTAppendChild(Parser.Tree^, Result, OtherwiseNode);
  end;
end;

function ParseActivationStatement(var Parser: TParser;
  Reactivate: Boolean): Int32;
var
  Start: TToken;
  TargetNode, TimeNode, RelativeNode: Int32;
  Mode: TActivationMode;
  Flags: TActivationFlags;
begin
  Start := Parser.Current;
  if Reactivate then
    Expect(Parser, tkReactivate)
  else
    Expect(Parser, tkActivate);
  TargetNode := ParseExpression(Parser);
  Mode := amDirect;
  Flags := [];
  TimeNode := FSIM_INVALID_INDEX;
  RelativeNode := FSIM_INVALID_INDEX;
  case Parser.Current.Kind of
    tkAt:
      begin
        Mode := amAt;
        Advance(Parser);
        TimeNode := ParseExpression(Parser);
      end;
    tkDelay:
      begin
        Mode := amDelay;
        Advance(Parser);
        TimeNode := ParseExpression(Parser);
      end;
    tkBefore:
      begin
        Mode := amBefore;
        Advance(Parser);
        RelativeNode := ParseExpression(Parser);
      end;
    tkAfter:
      begin
        Mode := amAfter;
        Advance(Parser);
        RelativeNode := ParseExpression(Parser);
      end;
  end;
  if Accept(Parser, tkPrior) then Include(Flags, afPrior);
  if Reactivate then Include(Flags, afReactivate);
  if Reactivate then
    Result := MakeNode(Parser, nkReactivateStatement, Start)
  else
    Result := MakeNode(Parser, nkActivateStatement, Start);
  Parser.Tree^.Nodes[Result].Aux := EncodeActivationAux(Mode, Flags);
  if TargetNode >= 0 then ASTAppendChild(Parser.Tree^, Result, TargetNode);
  if TimeNode >= 0 then ASTAppendChild(Parser.Tree^, Result, TimeNode);
  if RelativeNode >= 0 then ASTAppendChild(Parser.Tree^, Result, RelativeNode);
end;

function ParseModernUnaryStatement(var Parser: TParser;
  Kind: TASTNodeKind; RequiresExpression: Boolean): Int32;
var
  Start: TToken;
  ExprNode: Int32;
begin
  Start := Parser.Current;
  DialectError(Parser, TokenKindName(Start.Kind));
  Advance(Parser);
  Result := MakeNode(Parser, Kind, Start);
  if RequiresExpression then
  begin
    if Accept(Parser, tkLParen) then
    begin
      ExprNode := ParseExpression(Parser);
      Expect(Parser, tkRParen);
    end
    else
      ExprNode := ParseExpression(Parser);
    if ExprNode >= 0 then ASTAppendChild(Parser.Tree^, Result, ExprNode);
  end;
end;

function ParseSendStatement(var Parser: TParser): Int32;
var
  Start: TToken;
  ChannelNode, ValueNode: Int32;
begin
  Start := Parser.Current;
  DialectError(Parser, 'channel send');
  Expect(Parser, tkSend);
  Expect(Parser, tkLParen);
  ChannelNode := ParseExpression(Parser);
  Expect(Parser, tkComma);
  ValueNode := ParseExpression(Parser);
  Expect(Parser, tkRParen);
  Result := MakeNode(Parser, nkSendStatement, Start);
  if ChannelNode >= 0 then ASTAppendChild(Parser.Tree^, Result, ChannelNode);
  if ValueNode >= 0 then ASTAppendChild(Parser.Tree^, Result, ValueNode);
end;

function ParseWrappedStatement(var Parser: TParser;
  Kind: TASTNodeKind): Int32;
var
  Start: TToken;
  BodyNode: Int32;
begin
  Start := Parser.Current;
  DialectError(Parser, TokenKindName(Start.Kind));
  Advance(Parser);
  BodyNode := ParseStatement(Parser);
  Result := MakeNode(Parser, Kind, Start);
  if BodyNode >= 0 then ASTAppendChild(Parser.Tree^, Result, BodyNode);
end;

function ParseRepeatStatement(var Parser: TParser): Int32;
var
  Start: TToken;
  ListNode, Child, ConditionNode: Int32;
begin
  Start := Parser.Current;
  DialectError(Parser, 'repeat/until');
  Expect(Parser, tkRepeat);
  Result := MakeNode(Parser, nkRepeatStatement, Start);
  ListNode := MakeNode(Parser, nkStatementList, Start);
  while not At(Parser, tkUntil) and not At(Parser, tkEOF) do
  begin
    Child := ParseStatement(Parser);
    if Child >= 0 then ASTAppendChild(Parser.Tree^, ListNode, Child);
    if not Accept(Parser, tkSemicolon) and not At(Parser, tkUntil) then
      ParserError(Parser, dcExpectedToken,
        'expected semicolon or until in repeat statement');
    if Parser.ErrorRecovery then Synchronize(Parser);
  end;
  Expect(Parser, tkUntil);
  ConditionNode := ParseExpression(Parser);
  ASTAppendChild(Parser.Tree^, Result, ListNode);
  if ConditionNode >= 0 then ASTAppendChild(Parser.Tree^, Result, ConditionNode);
end;

function ParseCaseStatement(var Parser: TParser): Int32;
var
  Start, ClauseStart: TToken;
  SelectorNode, ClauseNode, ValueNode, BodyNode: Int32;
begin
  Start := Parser.Current;
  DialectError(Parser, 'case statement');
  Expect(Parser, tkCase);
  SelectorNode := ParseExpression(Parser);
  Expect(Parser, tkOf);
  Result := MakeNode(Parser, nkCaseStatement, Start);
  if SelectorNode >= 0 then ASTAppendChild(Parser.Tree^, Result, SelectorNode);
  while not At(Parser, tkEnd) and not At(Parser, tkOtherwise) and
        not At(Parser, tkEOF) do
  begin
    ClauseStart := Parser.Current;
    ClauseNode := MakeNode(Parser, nkCaseClause, ClauseStart);
    repeat
      ValueNode := ParseExpression(Parser);
      if ValueNode >= 0 then ASTAppendChild(Parser.Tree^, ClauseNode, ValueNode);
    until not Accept(Parser, tkComma);
    Expect(Parser, tkColon);
    BodyNode := ParseStatement(Parser);
    if BodyNode >= 0 then
    begin
      Parser.Tree^.Nodes[ClauseNode].BodyNode := BodyNode;
      ASTAppendChild(Parser.Tree^, ClauseNode, BodyNode);
    end;
    ASTAppendChild(Parser.Tree^, Result, ClauseNode);
    Accept(Parser, tkSemicolon);
  end;
  if Accept(Parser, tkOtherwise) then
  begin
    ClauseNode := MakeNode(Parser, nkCaseClause, Parser.Previous);
    Parser.Tree^.Nodes[ClauseNode].NameId := StringPoolIntern(
      Parser.Tree^.Strings, 'otherwise');
    BodyNode := ParseStatement(Parser);
    if BodyNode >= 0 then ASTAppendChild(Parser.Tree^, ClauseNode, BodyNode);
    ASTAppendChild(Parser.Tree^, Result, ClauseNode);
    Accept(Parser, tkSemicolon);
  end;
  Expect(Parser, tkEnd);
end;

function ParseWithStatement(var Parser: TParser): Int32;
var
  Start: TToken;
  SubjectNode, BodyNode: Int32;
begin
  Start := Parser.Current;
  DialectError(Parser, 'with statement');
  Expect(Parser, tkWith);
  SubjectNode := ParseExpression(Parser);
  Expect(Parser, tkDo);
  BodyNode := ParseStatement(Parser);
  Result := MakeNode(Parser, nkWithStatement, Start);
  if SubjectNode >= 0 then ASTAppendChild(Parser.Tree^, Result, SubjectNode);
  if BodyNode >= 0 then ASTAppendChild(Parser.Tree^, Result, BodyNode);
end;

function ParseTryStatement(var Parser: TParser): Int32;
var
  Start: TToken;
  Node, BodyNode, CatchNode, FinallyNode, CatchBody: Int32;
  ExceptionType: Int32;
  Name: RawByteString;
  NameSpan: TSourceSpan;
begin
  Start := Parser.Current;
  DialectError(Parser, 'try/catch/finally');
  Expect(Parser, tkTry);
  BodyNode := ParseStatement(Parser);
  Node := MakeNode(Parser, nkTryStatement, Start);
  if BodyNode >= 0 then ASTAppendChild(Parser.Tree^, Node, BodyNode);
  while Accept(Parser, tkCatch) do
  begin
    CatchNode := MakeNode(Parser, nkCatchClause, Parser.Previous);
    if Accept(Parser, tkLParen) then
    begin
      ExceptionType := ParseType(Parser);
      Parser.Tree^.Nodes[CatchNode].TypeId := ExceptionType;
      if ExpectIdentifier(Parser, Name, NameSpan) then
        Parser.Tree^.Nodes[CatchNode].NameId := StringPoolIntern(
          Parser.Tree^.Strings, Name);
      Expect(Parser, tkRParen);
    end;
    CatchBody := ParseStatement(Parser);
    if CatchBody >= 0 then ASTAppendChild(Parser.Tree^, CatchNode, CatchBody);
    ASTAppendChild(Parser.Tree^, Node, CatchNode);
  end;
  if Accept(Parser, tkFinally) then
  begin
    FinallyNode := MakeNode(Parser, nkFinallyClause, Parser.Previous);
    CatchBody := ParseStatement(Parser);
    if CatchBody >= 0 then ASTAppendChild(Parser.Tree^, FinallyNode, CatchBody);
    ASTAppendChild(Parser.Tree^, Node, FinallyNode);
  end;
  Result := Node;
end;

function ParseOutputStatement(var Parser: TParser): Int32;
var
  Start: TToken;
  Node, ExprNode: Int32;
  OutputKind: TOutputKind;
begin
  Start := Parser.Current;
  case Parser.Current.Kind of
    tkOutText: OutputKind := okText;
    tkOutInt: OutputKind := okInteger;
    tkOutReal: OutputKind := okReal;
    tkOutFix: OutputKind := okFixed;
    tkOutChar: OutputKind := okCharacter;
  else
    OutputKind := okImage;
  end;
  Advance(Parser);
  Node := MakeNode(Parser, nkOutputStatement, Start);
  Parser.Tree^.Nodes[Node].Aux := Ord(OutputKind);
  if OutputKind <> okImage then
  begin
    Expect(Parser, tkLParen);
    ExprNode := ParseExpression(Parser);
    if ExprNode >= 0 then ASTAppendChild(Parser.Tree^, Node, ExprNode);
    while Accept(Parser, tkComma) do
    begin
      ExprNode := ParseExpression(Parser);
      if ExprNode >= 0 then ASTAppendChild(Parser.Tree^, Node, ExprNode);
    end;
    Expect(Parser, tkRParen);
  end;
  Result := Node;
end;

function ParseSimpleKeywordStatement(var Parser: TParser;
  Kind: TASTNodeKind; RequiresExpression: Boolean): Int32;
var
  Start: TToken;
  ExprNode: Int32;
begin
  Start := Parser.Current;
  Advance(Parser);
  Result := MakeNode(Parser, Kind, Start);
  if RequiresExpression then
  begin
    ExprNode := ParseExpression(Parser);
    if ExprNode >= 0 then ASTAppendChild(Parser.Tree^, Result, ExprNode);
  end;
end;

function ParseIdentifierStatement(var Parser: TParser): Int32;
var
  Start: TToken;
  LeftNode, RightNode, Node: Int32;
  Name: RawByteString;
begin
  Start := Parser.Current;
  Name := TokenText(Parser.Current);
  { Standard SIMULA defines CALL as a sequencing procedure.  Keep it
    contextual so modern fsim programs may still use `call` as an ordinary
    identifier. }
  if (Parser.Options^.Dialect = fdSimula67) and
     ASCIIEqualFold(Name, 'call') then
  begin
    Advance(Parser);
    Node := MakeNode(Parser, nkCallStatement, Start);
    RightNode := ParseExpression(Parser);
    if RightNode >= 0 then ASTAppendChild(Parser.Tree^, Node, RightNode);
    Exit(Node);
  end;
  if LookAt(Parser, tkColon) then
  begin
    Advance(Parser);
    Expect(Parser, tkColon);
    Node := MakeNamedNode(Parser, nkLabelStatement, Start, Name);
    LeftNode := SymLookup(Parser.Symbols^, Name);
    if LeftNode < 0 then
      LeftNode := SymAdd(Parser.Symbols^, Name, skLabel, FSIM_TYPE_VOID,
        Parser.CurrentVisibility, [sfDefined], Node, Parser.Tree^.Nodes[Node].Span)
    else if Parser.Symbols^.Symbols[LeftNode].Kind <> skLabel then
      ParserErrorAt(Parser, Start, dcTypeMismatch,
        '''' + Name + ''' is not a label');
    Parser.Tree^.Nodes[Node].SymbolId := LeftNode;
    if TokenStartsStatement(Parser.Current.Kind) or
       TokenResolvesAsIdentifier(Parser, Parser.Current.Kind) then
    begin
      RightNode := ParseStatement(Parser);
      if RightNode >= 0 then ASTAppendChild(Parser.Tree^, Node, RightNode);
    end;
    Exit(Node);
  end;
  LeftNode := ParsePostfix(Parser);
  if TokenIsAssignment(Parser.Current.Kind) then
  begin
    if Parser.Current.Kind = tkAssignValue then
      Node := MakeNode(Parser, nkAssignmentStatement, Start)
    else
      Node := MakeNode(Parser, nkReferenceAssignmentStatement, Start);
    Advance(Parser);
    RightNode := ParseExpression(Parser);
    if LeftNode >= 0 then ASTAppendChild(Parser.Tree^, Node, LeftNode);
    if RightNode >= 0 then ASTAppendChild(Parser.Tree^, Node, RightNode);
    Exit(Node);
  end;
  Node := MakeNamedNode(Parser, nkExpressionStatement, Start, Name);
  if LeftNode >= 0 then ASTAppendChild(Parser.Tree^, Node, LeftNode);
  Result := Node;
end;

function ParseStatement(var Parser: TParser): Int32;
var
  Start: TToken;
  ExprNode: Int32;
begin
  Inc(Parser.ParsedStatementCount);
  if (Parser.Current.Kind <> tkIdentifier) and
     TokenResolvesAsIdentifier(Parser, Parser.Current.Kind) then
    Exit(ParseIdentifierStatement(Parser));
  case Parser.Current.Kind of
    tkSemicolon:
      begin
        Start := Parser.Current;
        Advance(Parser);
        Exit(MakeNode(Parser, nkEmptyStatement, Start));
      end;
    tkBegin: Exit(ParseBlockStatement(Parser));
    tkIf: Exit(ParseIfStatement(Parser));
    tkWhile: Exit(ParseWhileStatement(Parser));
    tkFor: Exit(ParseForStatement(Parser));
    tkGo: Exit(ParseGotoStatement(Parser));
    tkInspect: Exit(ParseInspectStatement(Parser));
    tkRepeat: Exit(ParseRepeatStatement(Parser));
    tkCase: Exit(ParseCaseStatement(Parser));
    tkWith: Exit(ParseWithStatement(Parser));
    tkTry: Exit(ParseTryStatement(Parser));
    tkOutText, tkOutInt, tkOutReal, tkOutFix, tkOutChar, tkOutImage:
      Exit(ParseOutputStatement(Parser));
    tkDetach:
      Exit(ParseSimpleKeywordStatement(Parser, nkDetachStatement, False));
    tkResume:
      Exit(ParseSimpleKeywordStatement(Parser, nkResumeStatement, True));
    tkActivate: Exit(ParseActivationStatement(Parser, False));
    tkReactivate: Exit(ParseActivationStatement(Parser, True));
    tkDelay:
      Exit(ParseSimpleKeywordStatement(Parser, nkDelayStatement, True));
    tkHold:
      Exit(ParseSimpleKeywordStatement(Parser, nkHoldStatement, True));
    tkPassivate:
      Exit(ParseSimpleKeywordStatement(Parser, nkPassivateStatement, False));
    tkCancel: Exit(ParseModernUnaryStatement(Parser, nkCancelStatement, True));
    tkAsync, tkSpawn: Exit(ParseModernUnaryStatement(Parser, nkSpawnStatement, True));
    tkJoin: Exit(ParseModernUnaryStatement(Parser, nkJoinStatement, True));
    tkYield: Exit(ParseModernUnaryStatement(Parser, nkYieldStatement, False));
    tkReceive: Exit(ParseModernUnaryStatement(Parser, nkReceiveStatement, True));
    tkLock: Exit(ParseModernUnaryStatement(Parser, nkLockStatement, True));
    tkUnlock: Exit(ParseModernUnaryStatement(Parser, nkUnlockStatement, True));
    tkSend: Exit(ParseSendStatement(Parser));
    tkParallel: Exit(ParseWrappedStatement(Parser, nkParallelStatement));
    tkCritical, tkSynchronized: Exit(ParseWrappedStatement(Parser, nkCriticalStatement));
    tkDefer: Exit(ParseWrappedStatement(Parser, nkDeferStatement));
    tkInner: Exit(ParseSimpleKeywordStatement(Parser, nkInnerStatement, False));
    tkRaise:
      begin
        DialectError(Parser, 'raise');
        Exit(ParseSimpleKeywordStatement(Parser, nkRaiseStatement, True));
      end;
    tkReturn:
      begin
        DialectError(Parser, 'return');
        Start := Parser.Current;
        Advance(Parser);
        Result := MakeNode(Parser, nkReturnStatement, Start);
        if not (Parser.Current.Kind in [tkSemicolon, tkEnd, tkElse, tkCatch,
          tkFinally]) then
        begin
          ExprNode := ParseExpression(Parser);
          if ExprNode >= 0 then ASTAppendChild(Parser.Tree^, Result, ExprNode);
        end;
        Exit;
      end;
    tkExit:
      begin
        Start := Parser.Current;
        Advance(Parser);
        Result := MakeNode(Parser, nkExitStatement, Start);
        if Accept(Parser, tkLParen) then
        begin
          ExprNode := ParseExpression(Parser);
          if ExprNode >= 0 then ASTAppendChild(Parser.Tree^, Result, ExprNode);
          Expect(Parser, tkRParen);
        end;
        Exit;
      end;
    tkBreak:
      begin
        DialectError(Parser, 'break');
        Start := Parser.Current;
        Advance(Parser);
        if Parser.LoopDepth = 0 then
          ParserErrorAt(Parser, Start, dcInvalidControlFlow,
            'break is only valid inside a loop');
        Exit(MakeNode(Parser, nkBreakStatement, Start));
      end;
    tkContinue:
      begin
        DialectError(Parser, 'continue');
        Start := Parser.Current;
        Advance(Parser);
        if Parser.LoopDepth = 0 then
          ParserErrorAt(Parser, Start, dcInvalidControlFlow,
            'continue is only valid inside a loop');
        Exit(MakeNode(Parser, nkContinueStatement, Start));
      end;
    tkAssert:
      begin
        DialectError(Parser, 'assert');
        Start := Parser.Current;
        Advance(Parser);
        Result := MakeNode(Parser, nkAssertStatement, Start);
        Expect(Parser, tkLParen);
        ExprNode := ParseExpression(Parser);
        if ExprNode >= 0 then ASTAppendChild(Parser.Tree^, Result, ExprNode);
        Expect(Parser, tkRParen);
        Exit;
      end;
    tkIdentifier: Exit(ParseIdentifierStatement(Parser));
  else
    Start := Parser.Current;
    ParserError(Parser, dcUnexpectedToken,
      'unexpected token at statement start: ' + TokenKindName(Start.Kind));
    if not At(Parser, tkEOF) then Advance(Parser);
    Result := MakeNode(Parser, nkEmptyStatement, Start);
  end;
end;

procedure ParserInit(var Parser: TParser; Source: PAnsiChar;
  SourceLength: SizeUInt; var Tree: TAST; var Symbols: TSymbolTable;
  var Diagnostics: TDiagnosticBag; var Options: TCompilerOptions);
begin
  Parser := Default(TParser);
  Parser.Tree := @Tree;
  Parser.Symbols := @Symbols;
  Parser.Diagnostics := @Diagnostics;
  Parser.Options := @Options;
  Parser.CurrentVisibility := visPublic;
  Parser.CurrentClass := FSIM_INVALID_INDEX;
  Parser.CurrentRoutine := FSIM_INVALID_INDEX;
  Parser.CurrentBlock := FSIM_INVALID_INDEX;
  LexerInit(Parser.Lexer, Source, SourceLength, Options.Dialect, Diagnostics);
  Parser.Current := Parser.Lexer.Current;
  LexerNext(Parser.Lexer);
  Parser.Lookahead := Parser.Lexer.Current;
  Parser.Previous := Default(TToken);
end;

function ParsePrefixedProgramBlock(var Parser: TParser; Root: Int32;
  const PrefixName: RawByteString; const PrefixSpan: TSourceSpan): Int32;
var
  Node, ProgramSymbol, PreviousRoutine, PreviousClass, PrefixSymbol,
  ArgumentNode: Int32;
  Name: RawByteString;
begin
  PrefixSymbol := SymLookupClass(Parser.Symbols^, PrefixName);
  Name := '$main';
  Advance(Parser);
  Node := ASTAddNamedNode(Parser.Tree^, nkProgramDecl, PrefixSpan, Name);
  Parser.Tree^.Nodes[Node].A := PrefixSymbol;
  Include(Parser.Tree^.Nodes[Node].Flags, nfSynthetic);
  ProgramSymbol := SymAdd(Parser.Symbols^, Name, skProgram,
    FSIM_TYPE_VOID, visPublic, [sfDefined, sfExported, sfSynthetic], Node,
    PrefixSpan);
  Parser.Tree^.Nodes[Node].SymbolId := ProgramSymbol;
  ASTAppendChild(Parser.Tree^, Root, Node);
  PreviousRoutine := Parser.CurrentRoutine;
  PreviousClass := Parser.CurrentClass;
  Parser.CurrentRoutine := ProgramSymbol;
  Parser.Symbols^.CurrentRoutine := ProgramSymbol;
  Parser.CurrentClass := PrefixSymbol;
  Parser.Symbols^.CurrentClass := PrefixSymbol;
  SymEnterScope(Parser.Symbols^, scProgram, ProgramSymbol);
  Parser.Tree^.Nodes[Node].Aux := Parser.Symbols^.CurrentScope;
  if Accept(Parser, tkLParen) then
  begin
    if not At(Parser, tkRParen) then
      repeat
        ArgumentNode := ParseExpression(Parser);
        ASTAppendChild(Parser.Tree^, Node, ArgumentNode);
      until not Accept(Parser, tkComma);
    Expect(Parser, tkRParen);
  end;
  if At(Parser, tkBegin) then
  begin
    Parser.Tree^.Nodes[Node].BodyNode := ParseBlockStatement(Parser);
    ASTAppendChild(Parser.Tree^, Node, Parser.Tree^.Nodes[Node].BodyNode);
  end
  else
    ParserError(Parser, dcExpectedToken,
      'a prefixed block must be followed by begin/end');
  Accept(Parser, tkSemicolon);
  SymLeaveScope(Parser.Symbols^);
  Parser.CurrentRoutine := PreviousRoutine;
  Parser.Symbols^.CurrentRoutine := PreviousRoutine;
  Parser.CurrentClass := PreviousClass;
  Parser.Symbols^.CurrentClass := PreviousClass;
  Result := Node;
end;

function ParseCompilationUnit(var Parser: TParser): Int32;
var
  Start: TToken;
  Root, Node, ProgramSymbol, PreviousRoutine: Int32;
  Name: RawByteString;
  NameSpan: TSourceSpan;
begin
  Start := Parser.Current;
  Root := ASTAddNode(Parser.Tree^, nkCompilationUnit,
    SourceSpan(Start.Span.StartPos, Start.Span.EndPos));
  Parser.Tree^.Root := Root;
  if Accept(Parser, tkProgram) then
  begin
    if not ExpectIdentifier(Parser, Name, NameSpan) then
      Name := 'anonymous';
    Expect(Parser, tkSemicolon);
    Node := ASTAddNamedNode(Parser.Tree^, nkProgramDecl,
      SourceSpan(Start.Span.StartPos, NameSpan.EndPos), Name);
    ProgramSymbol := SymAdd(Parser.Symbols^, Name, skProgram,
      FSIM_TYPE_VOID, visPublic, [sfDefined, sfExported], Node,
      Parser.Tree^.Nodes[Node].Span);
    Parser.Tree^.Nodes[Node].SymbolId := ProgramSymbol;
    ASTAppendChild(Parser.Tree^, Root, Node);
    PreviousRoutine := Parser.CurrentRoutine;
    Parser.CurrentRoutine := ProgramSymbol;
    Parser.Symbols^.CurrentRoutine := ProgramSymbol;
    SymEnterScope(Parser.Symbols^, scProgram, ProgramSymbol);
    Parser.Tree^.Nodes[Node].Aux := Parser.Symbols^.CurrentScope;

    { A named fsim program is a real compilation unit, not just a decorative
      header.  Declarations live between the header and the executable block,
      like you would expect from the ALGOL/Pascal side of the family. }
    while not At(Parser, tkBegin) and not At(Parser, tkEOF) do
    begin
      if ParserStartsDeclaration(Parser) or
         (TokenCanNameClass(Parser.Current.Kind) and LookAt(Parser, tkClass)) then
        ParseDeclaration(Parser, Node)
      else
      begin
        ParserError(Parser, dcUnexpectedToken,
          'expected declaration or program body, found ' +
          TokenKindName(Parser.Current.Kind));
        Synchronize(Parser);
        if not At(Parser, tkBegin) and not At(Parser, tkEOF) and
           not ParserStartsDeclaration(Parser) then
          Advance(Parser);
      end;
    end;

    if At(Parser, tkBegin) then
    begin
      Parser.Tree^.Nodes[Node].BodyNode := ParseBlockStatement(Parser);
      ASTAppendChild(Parser.Tree^, Node, Parser.Tree^.Nodes[Node].BodyNode);
    end
    else
      ParserError(Parser, dcExpectedToken,
        'program declaration must be followed by a begin/end block');
    Accept(Parser, tkSemicolon);
    SymLeaveScope(Parser.Symbols^);
    Parser.CurrentRoutine := PreviousRoutine;
    Parser.Symbols^.CurrentRoutine := PreviousRoutine;
  end
  else
  begin
    while not At(Parser, tkEOF) do
    begin
      if TokenCanNameClass(Parser.Current.Kind) and
         (SymLookupClass(Parser.Symbols^, TokenText(Parser.Current)) >= 0) and
         (Parser.Lookahead.Kind in [tkBegin, tkLParen]) then
        ParsePrefixedProgramBlock(Parser, Root, TokenText(Parser.Current),
          Parser.Current.Span)
      else if ParserStartsDeclaration(Parser) or
         (TokenCanNameClass(Parser.Current.Kind) and LookAt(Parser, tkClass)) then
        ParseDeclaration(Parser, Root)
      else if At(Parser, tkProgram) then
      begin
        { Free Simula historically permits library/class/procedure declarations
          before the named program block.  Keep those declarations in the
          compilation-unit scope and make the program scope a child of it. }
        Start := Parser.Current;
        Advance(Parser);
        if not ExpectIdentifier(Parser, Name, NameSpan) then
          Name := 'anonymous';
        Expect(Parser, tkSemicolon);
        Node := ASTAddNamedNode(Parser.Tree^, nkProgramDecl,
          SourceSpan(Start.Span.StartPos, NameSpan.EndPos), Name);
        ProgramSymbol := SymAdd(Parser.Symbols^, Name, skProgram,
          FSIM_TYPE_VOID, visPublic, [sfDefined, sfExported], Node,
          Parser.Tree^.Nodes[Node].Span);
        Parser.Tree^.Nodes[Node].SymbolId := ProgramSymbol;
        ASTAppendChild(Parser.Tree^, Root, Node);
        PreviousRoutine := Parser.CurrentRoutine;
        Parser.CurrentRoutine := ProgramSymbol;
        Parser.Symbols^.CurrentRoutine := ProgramSymbol;
        SymEnterScope(Parser.Symbols^, scProgram, ProgramSymbol);
        Parser.Tree^.Nodes[Node].Aux := Parser.Symbols^.CurrentScope;
        while not At(Parser, tkBegin) and not At(Parser, tkEOF) do
        begin
          if ParserStartsDeclaration(Parser) or
             (TokenCanNameClass(Parser.Current.Kind) and
              LookAt(Parser, tkClass)) then
            ParseDeclaration(Parser, Node)
          else
          begin
            ParserError(Parser, dcUnexpectedToken,
              'expected declaration or program body, found ' +
              TokenKindName(Parser.Current.Kind));
            Synchronize(Parser);
            if not At(Parser, tkBegin) and not At(Parser, tkEOF) and
               not ParserStartsDeclaration(Parser) then
              Advance(Parser);
          end;
        end;
        if At(Parser, tkBegin) then
        begin
          Parser.Tree^.Nodes[Node].BodyNode := ParseBlockStatement(Parser);
          ASTAppendChild(Parser.Tree^, Node,
            Parser.Tree^.Nodes[Node].BodyNode);
        end
        else
          ParserError(Parser, dcExpectedToken,
            'program declaration must be followed by a begin/end block');
        Accept(Parser, tkSemicolon);
        SymLeaveScope(Parser.Symbols^);
        Parser.CurrentRoutine := PreviousRoutine;
        Parser.Symbols^.CurrentRoutine := PreviousRoutine;
      end
      else if At(Parser, tkBegin) then
      begin
        Name := '$main';
        Node := ASTAddNamedNode(Parser.Tree^, nkProgramDecl,
          Parser.Current.Span, Name);
        ProgramSymbol := SymAdd(Parser.Symbols^, Name, skProgram,
          FSIM_TYPE_VOID, visPublic, [sfDefined, sfExported, sfSynthetic], Node,
          Parser.Tree^.Nodes[Node].Span);
        Parser.Tree^.Nodes[Node].SymbolId := ProgramSymbol;
        ASTAppendChild(Parser.Tree^, Root, Node);
        PreviousRoutine := Parser.CurrentRoutine;
        Parser.CurrentRoutine := ProgramSymbol;
        Parser.Symbols^.CurrentRoutine := ProgramSymbol;
        SymEnterScope(Parser.Symbols^, scProgram, ProgramSymbol);
        Parser.Tree^.Nodes[Node].Aux := Parser.Symbols^.CurrentScope;
        Parser.Tree^.Nodes[Node].BodyNode := ParseBlockStatement(Parser);
        ASTAppendChild(Parser.Tree^, Node, Parser.Tree^.Nodes[Node].BodyNode);
        Accept(Parser, tkSemicolon);
        SymLeaveScope(Parser.Symbols^);
        Parser.CurrentRoutine := PreviousRoutine;
        Parser.Symbols^.CurrentRoutine := PreviousRoutine;
      end
      else
      begin
        ParserError(Parser, dcUnexpectedToken,
          'expected declaration or main block, found ' +
          TokenKindName(Parser.Current.Kind));
        Advance(Parser);
      end;
      if Parser.ErrorRecovery then
        Synchronize(Parser);
    end;
  end;
  Parser.Tree^.Nodes[Root].Span.EndPos := Parser.Current.Span.EndPos;
  ASTVerify(Parser.Tree^);
  Result := Root;
end;

end.

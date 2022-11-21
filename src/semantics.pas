unit semantics;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, core, diagnostics, ast, symbols;

type
  TSemanticAnalyzer = record
    Tree: ^TAST;
    Symbols: ^TSymbolTable;
    Diagnostics: ^TDiagnosticBag;
    Options: ^TCompilerOptions;
    CurrentScope: Int32;
    CurrentClass: Int32;
    CurrentRoutine: Int32;
    LoopDepth: Int32;
    TryDepth: Int32;
    Reachable: Boolean;
    NoImplicitCall: Int32;
  end;

procedure SemanticInit(var Analyzer: TSemanticAnalyzer; var Tree: TAST;
  var Symbols: TSymbolTable; var Diagnostics: TDiagnosticBag;
  var Options: TCompilerOptions);
procedure AnalyzeCompilationUnit(var Analyzer: TSemanticAnalyzer);

implementation

function ChildAt(const Analyzer: TSemanticAnalyzer; Node, Index: Int32): Int32;
begin
  Result := ASTChildAt(Analyzer.Tree^, Node, Index);
end;

function NodeName(const Analyzer: TSemanticAnalyzer; Node: Int32): RawByteString;
begin
  Result := ASTNodeName(Analyzer.Tree^, Node);
end;

procedure ErrorNode(var Analyzer: TSemanticAnalyzer; Node: Int32;
  Code: TDiagnosticCode; const MessageText: RawByteString);
begin
  AddError(Analyzer.Diagnostics^, Code, Analyzer.Tree^.Nodes[Node].Span,
    MessageText);
end;

procedure WarningNode(var Analyzer: TSemanticAnalyzer; Node: Int32;
  Code: TDiagnosticCode; const MessageText: RawByteString);
begin
  AddWarning(Analyzer.Diagnostics^, Code, Analyzer.Tree^.Nodes[Node].Span,
    MessageText);
end;

function IsIntegerType(const Analyzer: TSemanticAnalyzer; TypeId: Int32): Boolean;
begin
  Result := (TypeId >= 0) and (TypeId <= High(Analyzer.Symbols^.Types)) and
    (Analyzer.Symbols^.Types[TypeId].Kind in [tyInteger, tyCInteger]);
end;

function IsNumericType(const Analyzer: TSemanticAnalyzer; TypeId: Int32): Boolean;
begin
  Result := (TypeId >= 0) and (TypeId <= High(Analyzer.Symbols^.Types)) and
    (Analyzer.Symbols^.Types[TypeId].Kind in
      [tyInteger, tyCInteger, tyReal, tyCReal]);
end;

function IsBooleanLike(const Analyzer: TSemanticAnalyzer; TypeId: Int32): Boolean;
begin
  Result := (TypeId = FSIM_TYPE_BOOLEAN) or IsIntegerType(Analyzer, TypeId);
end;

function IsReferenceType(const Analyzer: TSemanticAnalyzer; TypeId: Int32): Boolean;
begin
  Result := (TypeId >= 0) and (TypeId <= High(Analyzer.Symbols^.Types)) and
    (tfReferenceType in Analyzer.Symbols^.Types[TypeId].Flags);
end;

function IsIncompleteCRecord(const Analyzer: TSemanticAnalyzer;
  TypeId: Int32): Boolean;
begin
  Result := (TypeId >= 0) and (TypeId <= High(Analyzer.Symbols^.Types)) and
    (Analyzer.Symbols^.Types[TypeId].Kind = tyRecord) and
    (tfCLayout in Analyzer.Symbols^.Types[TypeId].Flags) and
    not (tfComplete in Analyzer.Symbols^.Types[TypeId].Flags);
end;

function CanConvertNode(const Analyzer: TSemanticAnalyzer; TargetType,
  ValueNode, ValueType: Int32): Boolean;
begin
  if (ValueNode >= 0) and
     (Analyzer.Tree^.Nodes[ValueNode].Kind = nkNoneExpr) then
    Exit(SymIsReferenceType(Analyzer.Symbols^, TargetType));
  Result := SymCanConvert(Analyzer.Symbols^, TargetType, ValueType);
end;

function AnalyzeExpression(var Analyzer: TSemanticAnalyzer; Node: Int32): Int32; forward;
procedure AnalyzeRoutine(var Analyzer: TSemanticAnalyzer; Node: Int32); forward;
procedure AnalyzeCondition(var Analyzer: TSemanticAnalyzer; Node: Int32); forward;
function AnalyzeSpawnOperand(var Analyzer: TSemanticAnalyzer;
  SpawnNode: Int32): Int32; forward;
procedure AnalyzeNode(var Analyzer: TSemanticAnalyzer; Node: Int32); forward;

function RoutineOwnerForScope(const Symbols: TSymbolTable; ScopeId: Int32): Int32;
var
  Owner, Guard: Int32;
begin
  Guard := 0;
  while (ScopeId >= 0) and (ScopeId <= High(Symbols.Scopes)) and
        (Guard <= Length(Symbols.Scopes)) do
  begin
    Owner := Symbols.Scopes[ScopeId].OwnerSymbol;
    if (Owner >= 0) and (Owner <= High(Symbols.Symbols)) and
       (Symbols.Symbols[Owner].Kind in [skProgram, skProcedure, skFunction]) then
      Exit(Owner);
    ScopeId := Symbols.Scopes[ScopeId].ParentScope;
    Inc(Guard);
  end;
  Result := FSIM_INVALID_INDEX;
end;

function CurrentRoutineIsLambda(const Analyzer: TSemanticAnalyzer): Boolean;
var
  SymbolId: Int32;
  Name: RawByteString;
begin
  SymbolId := Analyzer.CurrentRoutine;
  Result := False;
  if (SymbolId < 0) or (SymbolId > High(Analyzer.Symbols^.Symbols)) then Exit;
  if not (sfSynthetic in Analyzer.Symbols^.Symbols[SymbolId].Flags) then Exit;
  Name := SymName(Analyzer.Symbols^, SymbolId);
  Result := Copy(Name, 1, 8) = '$lambda$';
end;

function ResolveIdentifier(var Analyzer: TSemanticAnalyzer; Node: Int32): Int32;
var
  Name: RawByteString;
  SymbolId, OwnerSymbol: Int32;
begin
  Name := NodeName(Analyzer, Node);
  SymbolId := SymLookup(Analyzer.Symbols^, Name, Analyzer.CurrentScope);
  if (SymbolId < 0) and (Analyzer.CurrentClass >= 0) then
    SymbolId := SymLookupMember(Analyzer.Symbols^, Analyzer.CurrentClass, Name);
  if SymbolId < 0 then
  begin
    ErrorNode(Analyzer, Node, dcUnknownSymbol,
      'unknown identifier ''' + Name + '''');
    Analyzer.Tree^.Nodes[Node].TypeId := FSIM_TYPE_INVALID;
    Exit(FSIM_INVALID_INDEX);
  end;
  if CurrentRoutineIsLambda(Analyzer) then
  begin
    if (Analyzer.Symbols^.Symbols[SymbolId].Kind in [skVariable, skParameter]) and
       (RoutineOwnerForScope(Analyzer.Symbols^,
          Analyzer.Symbols^.Symbols[SymbolId].ScopeId) >= 0) and
       (RoutineOwnerForScope(Analyzer.Symbols^,
          Analyzer.Symbols^.Symbols[SymbolId].ScopeId) <> Analyzer.CurrentRoutine) then
      ErrorNode(Analyzer, Node, dcBackendUnsupported,
        'lambda captures are not lowered yet; pass ''' + Name +
        ''' as an explicit lambda parameter');
    OwnerSymbol := Analyzer.Symbols^.Symbols[SymbolId].OwnerSymbol;
    if (OwnerSymbol >= 0) and (OwnerSymbol <= High(Analyzer.Symbols^.Symbols)) and
       (Analyzer.Symbols^.Symbols[OwnerSymbol].Kind in
         [skClass, skProcessClass, skThreadClass]) then
      ErrorNode(Analyzer, Node, dcBackendUnsupported,
        'lambda cannot capture class member ''' + Name +
        ''' until receiver closures are available');
  end;
  if (Analyzer.Symbols^.Symbols[SymbolId].OwnerSymbol >= 0) and
     (Analyzer.Symbols^.Symbols[SymbolId].OwnerSymbol <=
       High(Analyzer.Symbols^.Symbols)) and
     (Analyzer.Symbols^.Symbols[Analyzer.Symbols^.Symbols[SymbolId].OwnerSymbol].Kind in
       [skClass, skProcessClass, skThreadClass]) and
     not SymCanAccessMember(Analyzer.Symbols^, Analyzer.CurrentClass, SymbolId) then
    ErrorNode(Analyzer, Node, dcVisibilityViolation,
      'attribute ''' + Name + ''' is not visible at this prefix level');
  Analyzer.Tree^.Nodes[Node].SymbolId := SymbolId;
  Analyzer.Tree^.Nodes[Node].TypeId := Analyzer.Symbols^.Symbols[SymbolId].TypeId;
  Include(Analyzer.Symbols^.Symbols[SymbolId].Flags, sfReferenced);
  Result := SymbolId;
end;

function TextIntrinsicByName(const Name: RawByteString): TTextIntrinsic;
begin
  if ASCIIEqualFold(Name, 'constant') then Result := tiConstant
  else if ASCIIEqualFold(Name, 'start') then Result := tiStart
  else if ASCIIEqualFold(Name, 'length') then Result := tiLength
  else if ASCIIEqualFold(Name, 'main') then Result := tiMain
  else if ASCIIEqualFold(Name, 'pos') then Result := tiPos
  else if ASCIIEqualFold(Name, 'setpos') then Result := tiSetPos
  else if ASCIIEqualFold(Name, 'more') then Result := tiMore
  else if ASCIIEqualFold(Name, 'getchar') then Result := tiGetChar
  else if ASCIIEqualFold(Name, 'putchar') then Result := tiPutChar
  else if ASCIIEqualFold(Name, 'sub') then Result := tiSub
  else if ASCIIEqualFold(Name, 'strip') then Result := tiStrip
  else if ASCIIEqualFold(Name, 'getint') then Result := tiGetInt
  else if ASCIIEqualFold(Name, 'getreal') then Result := tiGetReal
  else if ASCIIEqualFold(Name, 'getfrac') then Result := tiGetFrac
  else if ASCIIEqualFold(Name, 'putint') then Result := tiPutInt
  else if ASCIIEqualFold(Name, 'putfix') then Result := tiPutFix
  else if ASCIIEqualFold(Name, 'putreal') then Result := tiPutReal
  else if ASCIIEqualFold(Name, 'putfrac') then Result := tiPutFrac
  else Result := tiNone;
end;

function TextIntrinsicResultType(Intrinsic: TTextIntrinsic): Int32;
begin
  case Intrinsic of
    tiStart, tiLength, tiPos, tiGetInt, tiGetFrac: Result := FSIM_TYPE_INTEGER;
    tiConstant, tiMore: Result := FSIM_TYPE_BOOLEAN;
    tiGetChar: Result := FSIM_TYPE_CHARACTER;
    tiMain, tiSub, tiStrip: Result := FSIM_TYPE_TEXT;
    tiGetReal: Result := FSIM_TYPE_REAL;
    tiSetPos, tiPutChar, tiPutInt, tiPutFix, tiPutReal, tiPutFrac:
      Result := FSIM_TYPE_VOID;
  else
    Result := FSIM_TYPE_INVALID;
  end;
end;

function TextIntrinsicArgumentCount(Intrinsic: TTextIntrinsic): Int32;
begin
  case Intrinsic of
    tiSetPos, tiPutChar, tiPutInt: Result := 1;
    tiSub, tiPutFix, tiPutReal, tiPutFrac: Result := 2;
  else
    Result := 0;
  end;
end;

function TextIntrinsicArgumentType(Intrinsic: TTextIntrinsic;
  Index: Int32): Int32;
begin
  case Intrinsic of
    tiSetPos, tiSub, tiPutInt, tiPutFrac: Result := FSIM_TYPE_INTEGER;
    tiPutChar: Result := FSIM_TYPE_CHARACTER;
    tiPutFix, tiPutReal:
      if Index = 0 then Result := FSIM_TYPE_REAL else Result := FSIM_TYPE_INTEGER;
  else
    Result := FSIM_TYPE_INVALID;
  end;
end;

function AnalyzeMember(var Analyzer: TSemanticAnalyzer; Node: Int32): Int32;
var
  BaseNode, BaseType, ClassSymbol, MemberSymbol, DeclaringClass: Int32;
  Name: RawByteString;
  Intrinsic: TTextIntrinsic;
begin
  BaseNode := ChildAt(Analyzer, Node, 0);
  { NoImplicitCall belongs to the expression that is itself being used as a
    callable value.  It must not leak into the receiver of a member chain.
    In classic Simula, sysout/sysin are zero-argument environment routines
    returning file references, so sysout.outtext(...) needs the receiver call
    to happen even while the outer outtext member is being analyzed as a
    callee.  The same rule also makes f().member work for any zero-argument
    function returning an object. }
  if Analyzer.NoImplicitCall > 0 then
  begin
    Dec(Analyzer.NoImplicitCall);
    BaseType := AnalyzeExpression(Analyzer, BaseNode);
    Inc(Analyzer.NoImplicitCall);
  end
  else
    BaseType := AnalyzeExpression(Analyzer, BaseNode);
  Name := NodeName(Analyzer, Node);

  if BaseType = FSIM_TYPE_STRING then
  begin
    if ASCIIEqualFold(Name, 'length') then
    begin
      Analyzer.Tree^.Nodes[Node].Aux := Ord(tiLength);
      Analyzer.Tree^.Nodes[Node].TypeId := FSIM_TYPE_INTEGER;
      Exclude(Analyzer.Tree^.Nodes[Node].Flags, nfLValue);
      Exit(FSIM_TYPE_INTEGER);
    end;
    ErrorNode(Analyzer, Node, dcUnknownSymbol,
      'string has no member named ''' + Name + '''');
    Analyzer.Tree^.Nodes[Node].TypeId := FSIM_TYPE_INVALID;
    Exit(FSIM_TYPE_INVALID);
  end;

  if BaseType = FSIM_TYPE_TEXT then
  begin
    Intrinsic := TextIntrinsicByName(Name);
    { Free Simula deliberately remains source-compatible with classic TEXT.
      The lowering already implements these attributes; hiding them in the
      modern dialect only made valid Simula libraries fail semantically. }
    if Intrinsic = tiNone then
    begin
      ErrorNode(Analyzer, Node, dcUnknownSymbol,
        'text has no member named ''' + Name + ''' in this dialect');
      Analyzer.Tree^.Nodes[Node].TypeId := FSIM_TYPE_INVALID;
      Exit(FSIM_TYPE_INVALID);
    end;
    if TextIntrinsicArgumentCount(Intrinsic) <> 0 then
    begin
      ErrorNode(Analyzer, Node, dcInvalidCall,
        'text attribute ''' + Name + ''' requires arguments');
      Analyzer.Tree^.Nodes[Node].TypeId := FSIM_TYPE_INVALID;
      Exit(FSIM_TYPE_INVALID);
    end;
    Analyzer.Tree^.Nodes[Node].Aux := Ord(Intrinsic);
    Result := TextIntrinsicResultType(Intrinsic);
    Analyzer.Tree^.Nodes[Node].TypeId := Result;
    Exclude(Analyzer.Tree^.Nodes[Node].Flags, nfLValue);
    Exit;
  end;

  if (BaseType >= 0) and (BaseType <= High(Analyzer.Symbols^.Types)) and
     (Analyzer.Symbols^.Types[BaseType].Kind = tyRecord) then
  begin
    ClassSymbol := Analyzer.Symbols^.Types[BaseType].RefClassSymbol;
    MemberSymbol := SymLookupMember(Analyzer.Symbols^, ClassSymbol, Name);
    if MemberSymbol < 0 then
    begin
      ErrorNode(Analyzer, Node, dcUnknownSymbol,
        'record ''' + TypeName(Analyzer.Symbols^, BaseType) +
        ''' has no member named ''' + Name + '''');
      Analyzer.Tree^.Nodes[Node].TypeId := FSIM_TYPE_INVALID;
      Exit(FSIM_TYPE_INVALID);
    end;
    Analyzer.Tree^.Nodes[Node].SymbolId := MemberSymbol;
    Analyzer.Tree^.Nodes[Node].TypeId := Analyzer.Symbols^.Symbols[MemberSymbol].TypeId;
    Include(Analyzer.Tree^.Nodes[Node].Flags, nfLValue);
    Include(Analyzer.Symbols^.Symbols[MemberSymbol].Flags, sfReferenced);
    Exit(Analyzer.Tree^.Nodes[Node].TypeId);
  end;

  if not IsReferenceType(Analyzer, BaseType) or
     (Analyzer.Symbols^.Types[BaseType].Kind <> tyReference) then
  begin
    ErrorNode(Analyzer, Node, dcTypeMismatch,
      'member access requires a class reference or C-layout record');
    Analyzer.Tree^.Nodes[Node].TypeId := FSIM_TYPE_INVALID;
    Exit(FSIM_TYPE_INVALID);
  end;
  ClassSymbol := Analyzer.Symbols^.Types[BaseType].RefClassSymbol;
  MemberSymbol := SymLookupMember(Analyzer.Symbols^, ClassSymbol, Name);
  if MemberSymbol < 0 then
  begin
    ErrorNode(Analyzer, Node, dcUnknownSymbol,
      'class ''' + SymName(Analyzer.Symbols^, ClassSymbol) +
      ''' has no member named ''' + Name + '''');
    Analyzer.Tree^.Nodes[Node].TypeId := FSIM_TYPE_INVALID;
    Exit(FSIM_TYPE_INVALID);
  end;
  DeclaringClass := Analyzer.Symbols^.Symbols[MemberSymbol].OwnerSymbol;
  if (DeclaringClass >= 0) and not SymCanAccessMember(Analyzer.Symbols^,
    Analyzer.CurrentClass, MemberSymbol) then
    ErrorNode(Analyzer, Node, dcVisibilityViolation,
      'member ''' + Name + ''' is not accessible here');
  Analyzer.Tree^.Nodes[Node].SymbolId := MemberSymbol;
  Analyzer.Tree^.Nodes[Node].TypeId := Analyzer.Symbols^.Symbols[MemberSymbol].TypeId;
  Include(Analyzer.Symbols^.Symbols[MemberSymbol].Flags, sfReferenced);
  Result := Analyzer.Tree^.Nodes[Node].TypeId;
  if (Analyzer.NoImplicitCall = 0) and (Result >= 0) and
     (Result <= High(Analyzer.Symbols^.Types)) and
     (Analyzer.Symbols^.Types[Result].Kind = tyProcedure) and
     (Analyzer.Symbols^.Types[Result].ParameterCount = 0) then
  begin
    Result := Analyzer.Symbols^.Types[Result].ReturnType;
    Analyzer.Tree^.Nodes[Node].TypeId := Result;
    Include(Analyzer.Tree^.Nodes[Node].Flags, nfImplicitCall);
  end;
end;

function AnalyzeUnary(var Analyzer: TSemanticAnalyzer; Node: Int32): Int32;
var
  Operand, OperandType: Int32;
  Op: TUnaryOperator;
begin
  Operand := ChildAt(Analyzer, Node, 0);
  OperandType := AnalyzeExpression(Analyzer, Operand);
  Op := TUnaryOperator(Analyzer.Tree^.Nodes[Node].Aux);
  case Op of
    uoPositive, uoNegative:
      if not IsNumericType(Analyzer, OperandType) then
        ErrorNode(Analyzer, Node, dcTypeMismatch,
          'unary numeric operator requires an integer or real operand');
    uoLogicalNot:
      if not IsBooleanLike(Analyzer, OperandType) then
        ErrorNode(Analyzer, Node, dcTypeMismatch,
          '''not'' requires a boolean or integer operand');
  end;
  if Op = uoLogicalNot then
    Result := FSIM_TYPE_BOOLEAN
  else
    Result := OperandType;
  Analyzer.Tree^.Nodes[Node].TypeId := Result;
end;

function AnalyzeBinary(var Analyzer: TSemanticAnalyzer; Node: Int32): Int32;
var
  LeftNode, RightNode, LeftType, RightType, CommonType: Int32;
  Op: TBinaryOperator;
begin
  LeftNode := ChildAt(Analyzer, Node, 0);
  RightNode := ChildAt(Analyzer, Node, 1);
  LeftType := AnalyzeExpression(Analyzer, LeftNode);
  RightType := AnalyzeExpression(Analyzer, RightNode);
  Op := TBinaryOperator(Analyzer.Tree^.Nodes[Node].Aux);
  case Op of
    boConcat:
      begin
        if not (LeftType in [FSIM_TYPE_TEXT, FSIM_TYPE_STRING]) or
           not (RightType in [FSIM_TYPE_TEXT, FSIM_TYPE_STRING]) then
        begin
          ErrorNode(Analyzer, Node, dcTypeMismatch,
            '''&'' requires text operands');
          Result := FSIM_TYPE_INVALID;
        end
        else if Analyzer.Options^.Dialect = fdSimula67 then
          Result := FSIM_TYPE_TEXT
        else if (LeftType = FSIM_TYPE_STRING) or (RightType = FSIM_TYPE_STRING) then
          Result := FSIM_TYPE_STRING
        else
          Result := FSIM_TYPE_TEXT;
      end;
    boAdd, boSubtract, boMultiply, boRealDivide, boIntegerDivide,
    boModulo, boRemainder, boPower:
      begin
        if (Op = boAdd) and
           (LeftType in [FSIM_TYPE_TEXT, FSIM_TYPE_STRING]) and
           (RightType in [FSIM_TYPE_TEXT, FSIM_TYPE_STRING]) then
        begin
          if Analyzer.Options^.Dialect = fdSimula67 then
          begin
            ErrorNode(Analyzer, Node, dcDialectViolation,
              'dynamic text concatenation is unavailable in simula67 mode');
            Result := FSIM_TYPE_INVALID;
          end
          else
            Result := FSIM_TYPE_STRING;
        end
        else if not IsNumericType(Analyzer, LeftType) or
           not IsNumericType(Analyzer, RightType) then
        begin
          ErrorNode(Analyzer, Node, dcTypeMismatch,
            'arithmetic operator requires numeric operands');
          Result := FSIM_TYPE_INVALID;
        end
        else if (Op = boPower) and not IsIntegerType(Analyzer, RightType) then
        begin
          ErrorNode(Analyzer, RightNode, dcTypeMismatch,
            'power exponent must be an integer');
          Result := FSIM_TYPE_INVALID;
        end
        else if Op = boRealDivide then
          Result := FSIM_TYPE_REAL
        else if (Op = boPower) and (LeftType = FSIM_TYPE_REAL) then
          Result := FSIM_TYPE_REAL
        else
          Result := SymCommonType(Analyzer.Symbols^, LeftType, RightType);
      end;
    boShiftLeft, boShiftRight, boBitwiseAnd, boBitwiseOr, boBitwiseXor:
      begin
        if not IsIntegerType(Analyzer, LeftType) or
           not IsIntegerType(Analyzer, RightType) then
          ErrorNode(Analyzer, Node, dcTypeMismatch,
            'bitwise operator requires integer operands');
        Result := SymCommonType(Analyzer.Symbols^, LeftType, RightType);
      end;
    boEqual, boNotEqual:
      begin
        CommonType := SymCommonType(Analyzer.Symbols^, LeftType, RightType);
        if CommonType = FSIM_TYPE_INVALID then
          ErrorNode(Analyzer, Node, dcTypeMismatch,
            'equality operands have incompatible types')
        else if (Analyzer.Options^.Dialect = fdSimula67) and
          ((tfReferenceType in Analyzer.Symbols^.Types[LeftType].Flags) or
           (tfReferenceType in Analyzer.Symbols^.Types[RightType].Flags)) then
          ErrorNode(Analyzer, Node, dcTypeMismatch,
            'object references use == and =/=; = and <> compare values');
        Result := FSIM_TYPE_BOOLEAN;
      end;
    boReferenceEqual, boReferenceNotEqual:
      begin
        if (Analyzer.Tree^.Nodes[LeftNode].Kind = nkNoneExpr) and
           IsReferenceType(Analyzer, RightType) then
          CommonType := RightType
        else if (Analyzer.Tree^.Nodes[RightNode].Kind = nkNoneExpr) and
                IsReferenceType(Analyzer, LeftType) then
          CommonType := LeftType
        else if not IsReferenceType(Analyzer, LeftType) or
                not IsReferenceType(Analyzer, RightType) then
        begin
          CommonType := FSIM_TYPE_INVALID;
          ErrorNode(Analyzer, Node, dcTypeMismatch,
            'reference identity comparison requires reference operands');
        end
        else
          CommonType := SymCommonType(Analyzer.Symbols^, LeftType, RightType);
        if (CommonType = FSIM_TYPE_INVALID) and
           ((Analyzer.Tree^.Nodes[LeftNode].Kind <> nkNoneExpr) and
            (Analyzer.Tree^.Nodes[RightNode].Kind <> nkNoneExpr)) and
           IsReferenceType(Analyzer, LeftType) and IsReferenceType(Analyzer, RightType) then
          ErrorNode(Analyzer, Node, dcTypeMismatch,
            'reference identity operands have unrelated types');
        Result := FSIM_TYPE_BOOLEAN;
      end;
    boLess, boLessEqual, boGreater, boGreaterEqual:
      begin
        if not IsNumericType(Analyzer, LeftType) or
           not IsNumericType(Analyzer, RightType) then
          ErrorNode(Analyzer, Node, dcTypeMismatch,
            'ordered comparison requires numeric operands');
        Result := FSIM_TYPE_BOOLEAN;
      end;
    boLogicalAnd, boLogicalOr:
      begin
        { Free Pascal-style integer AND/OR are useful in the modern dialect,
          but classic SIMULA keeps these as boolean operators only. }
        if (Analyzer.Options^.Dialect = fdFSim) and
           IsIntegerType(Analyzer, LeftType) and IsIntegerType(Analyzer, RightType) then
          Result := SymCommonType(Analyzer.Symbols^, LeftType, RightType)
        else
        begin
          if not IsBooleanLike(Analyzer, LeftType) or
             not IsBooleanLike(Analyzer, RightType) then
            ErrorNode(Analyzer, Node, dcTypeMismatch,
              'and/or require boolean operands (or integers in fsim mode)');
          Result := FSIM_TYPE_BOOLEAN;
        end;
      end;
    boEquivalence, boImplication:
      begin
        if not IsBooleanLike(Analyzer, LeftType) or
           not IsBooleanLike(Analyzer, RightType) then
          ErrorNode(Analyzer, Node, dcTypeMismatch,
            'logical operator requires boolean operands');
        Result := FSIM_TYPE_BOOLEAN;
      end;
  else
    Result := FSIM_TYPE_INVALID;
  end;
  Analyzer.Tree^.Nodes[Node].TypeId := Result;
end;

function TryAnalyzeStringCall(var Analyzer: TSemanticAnalyzer;
  Node, CalleeNode: Int32; out ResultType: Int32): Boolean;
var
  BaseNode, BaseType, ArgumentNode, ArgumentType, ActualCount: Int32;
  Name: RawByteString;
  Intrinsic: TStringIntrinsic;
begin
  Result := False;
  ResultType := FSIM_TYPE_INVALID;
  if (CalleeNode < 0) or
     (Analyzer.Tree^.Nodes[CalleeNode].Kind <> nkMemberExpr) then Exit;
  BaseNode := ChildAt(Analyzer, CalleeNode, 0);
  BaseType := AnalyzeExpression(Analyzer, BaseNode);
  if BaseType <> FSIM_TYPE_STRING then Exit;
  if Analyzer.Options^.Dialect <> fdFSim then Exit;
  Name := NodeName(Analyzer, CalleeNode);
  if ASCIIEqualFold(Name, 'byte') then
  begin
    Intrinsic := siByte;
    ResultType := FSIM_TYPE_CHARACTER;
  end
  else if ASCIIEqualFold(Name, 'byte_value') then
  begin
    Intrinsic := siByteValue;
    ResultType := FSIM_TYPE_INTEGER;
  end
  else if ASCIIEqualFold(Name, 'to_integer') then
  begin
    Intrinsic := siToInteger;
    ResultType := FSIM_TYPE_INTEGER;
  end
  else if ASCIIEqualFold(Name, 'slice') then
  begin
    Intrinsic := siSlice;
    ResultType := FSIM_TYPE_STRING;
  end
  else
    Exit;

  ArgumentNode := Analyzer.Tree^.Nodes[CalleeNode].NextSibling;
  ActualCount := 0;
  while ArgumentNode >= 0 do
  begin
    ArgumentType := AnalyzeExpression(Analyzer, ArgumentNode);
    if not IsIntegerType(Analyzer, ArgumentType) then
      ErrorNode(Analyzer, ArgumentNode, dcTypeMismatch,
        'string.' + Name + ' arguments must be integers');
    Inc(ActualCount);
    ArgumentNode := Analyzer.Tree^.Nodes[ArgumentNode].NextSibling;
  end;
  if Intrinsic = siSlice then ArgumentType := 2 else ArgumentType := 1;
  if ActualCount <> ArgumentType then
    ErrorNode(Analyzer, Node, dcInvalidCall,
      'string.' + Name + ' expects ' + IntToStr(ArgumentType) +
      ' argument(s), got ' + IntToStr(ActualCount));

  Analyzer.Tree^.Nodes[CalleeNode].Aux := Ord(Intrinsic);
  Analyzer.Tree^.Nodes[CalleeNode].TypeId := ResultType;
  Exclude(Analyzer.Tree^.Nodes[CalleeNode].Flags, nfLValue);
  Analyzer.Tree^.Nodes[Node].Aux := Ord(Intrinsic);
  Analyzer.Tree^.Nodes[Node].TypeId := ResultType;
  Result := True;
end;

function TryAnalyzeTextCall(var Analyzer: TSemanticAnalyzer;
  Node, CalleeNode: Int32; out ResultType: Int32): Boolean;
var
  BaseNode, BaseType, ArgumentNode, ArgumentType, ExpectedType: Int32;
  ExpectedCount, ActualCount: Int32;
  Name: RawByteString;
  Intrinsic: TTextIntrinsic;
begin
  Result := False;
  ResultType := FSIM_TYPE_INVALID;
  if (CalleeNode < 0) or
     (Analyzer.Tree^.Nodes[CalleeNode].Kind <> nkMemberExpr) then Exit;
  BaseNode := ChildAt(Analyzer, CalleeNode, 0);
  BaseType := AnalyzeExpression(Analyzer, BaseNode);
  if BaseType <> FSIM_TYPE_TEXT then Exit;
  if Analyzer.Options^.Dialect <> fdSimula67 then Exit;
  Name := NodeName(Analyzer, CalleeNode);
  Intrinsic := TextIntrinsicByName(Name);
  if Intrinsic = tiNone then Exit;

  ExpectedCount := TextIntrinsicArgumentCount(Intrinsic);
  ArgumentNode := Analyzer.Tree^.Nodes[CalleeNode].NextSibling;
  ActualCount := 0;
  while ArgumentNode >= 0 do
  begin
    ArgumentType := AnalyzeExpression(Analyzer, ArgumentNode);
    if ActualCount < ExpectedCount then
    begin
      ExpectedType := TextIntrinsicArgumentType(Intrinsic, ActualCount);
      if (ExpectedType <> FSIM_TYPE_INVALID) and
         not CanConvertNode(Analyzer, ExpectedType, ArgumentNode, ArgumentType) then
        ErrorNode(Analyzer, ArgumentNode, dcTypeMismatch,
          'argument ' + IntToStr(ActualCount + 1) + ' to text.' + Name +
          ' has type ' + TypeName(Analyzer.Symbols^, ArgumentType) +
          ', expected ' + TypeName(Analyzer.Symbols^, ExpectedType));
    end;
    Inc(ActualCount);
    ArgumentNode := Analyzer.Tree^.Nodes[ArgumentNode].NextSibling;
  end;
  if ActualCount <> ExpectedCount then
    ErrorNode(Analyzer, Node, dcInvalidCall,
      'text.' + Name + ' expects ' + IntToStr(ExpectedCount) +
      ' arguments, got ' + IntToStr(ActualCount));

  Analyzer.Tree^.Nodes[CalleeNode].Aux := Ord(Intrinsic);
  Analyzer.Tree^.Nodes[CalleeNode].TypeId := TextIntrinsicResultType(Intrinsic);
  Exclude(Analyzer.Tree^.Nodes[CalleeNode].Flags, nfLValue);
  ResultType := TextIntrinsicResultType(Intrinsic);
  Analyzer.Tree^.Nodes[Node].Aux := Ord(Intrinsic);
  Analyzer.Tree^.Nodes[Node].TypeId := ResultType;
  Result := True;
end;

function TryAnalyzeCInteropCall(var Analyzer: TSemanticAnalyzer;
  Node, CalleeNode: Int32; out ResultType: Int32): Boolean;
var
  Name, FieldName: RawByteString;
  BaseNode, BaseType, ElementType, ArgumentNode, ArgumentType, ActualCount,
  SymbolId, IntrinsicType, FieldSymbol: Int32;
begin
  Result := False;
  ResultType := FSIM_TYPE_INVALID;
  if Analyzer.Options^.Dialect <> fdFSim then Exit;
  if (CalleeNode < 0) or (CalleeNode > High(Analyzer.Tree^.Nodes)) then Exit;

  if Analyzer.Tree^.Nodes[CalleeNode].Kind = nkIdentifierExpr then
  begin
    Name := NodeName(Analyzer, CalleeNode);
    ArgumentNode := Analyzer.Tree^.Nodes[CalleeNode].NextSibling;
    if (Analyzer.Tree^.Nodes[Node].Aux in [FSIM_C_INTRINSIC_SIZEOF, FSIM_C_INTRINSIC_ALIGNOF]) or
       ASCIIEqualFold(Name, 'c_sizeof') or ASCIIEqualFold(Name, 'c_alignof') then
    begin
      if (ArgumentNode < 0) or
         (Analyzer.Tree^.Nodes[ArgumentNode].NextSibling >= 0) then
      begin
        ErrorNode(Analyzer, Node, dcInvalidCall,
          Name + ' expects exactly one C type or value');
        IntrinsicType := FSIM_TYPE_INVALID;
      end
      else if Analyzer.Tree^.Nodes[ArgumentNode].Kind = nkIdentifierExpr then
      begin
        SymbolId := SymLookup(Analyzer.Symbols^, NodeName(Analyzer, ArgumentNode));
        if (SymbolId >= 0) and
           (Analyzer.Symbols^.Symbols[SymbolId].Kind = skType) then
          IntrinsicType := Analyzer.Symbols^.Symbols[SymbolId].TypeId
        else
          IntrinsicType := AnalyzeExpression(Analyzer, ArgumentNode);
      end
      else
        IntrinsicType := AnalyzeExpression(Analyzer, ArgumentNode);
      if not SymIsCStorageType(Analyzer.Symbols^, IntrinsicType) then
        ErrorNode(Analyzer, ArgumentNode, dcTypeMismatch,
          Name + ' requires a complete fixed C-layout type or value');
      Analyzer.Tree^.Nodes[Node].A := IntrinsicType;
      if (Analyzer.Tree^.Nodes[Node].Aux = FSIM_C_INTRINSIC_SIZEOF) or
         ASCIIEqualFold(Name, 'c_sizeof') then
        Analyzer.Tree^.Nodes[Node].Aux := FSIM_C_INTRINSIC_SIZEOF
      else
        Analyzer.Tree^.Nodes[Node].Aux := FSIM_C_INTRINSIC_ALIGNOF;
      Analyzer.Tree^.Nodes[Node].TypeId := FSIM_TYPE_C_SIZE;
      ResultType := FSIM_TYPE_C_SIZE;
      Exit(True);
    end;
    if (Analyzer.Tree^.Nodes[Node].Aux = FSIM_C_INTRINSIC_OFFSETOF) or
       ASCIIEqualFold(Name, 'c_offsetof') then
    begin
      if (ArgumentNode < 0) or
         (Analyzer.Tree^.Nodes[ArgumentNode].NextSibling < 0) or
         (Analyzer.Tree^.Nodes[Analyzer.Tree^.Nodes[ArgumentNode].NextSibling].NextSibling >= 0) then
      begin
        ErrorNode(Analyzer, Node, dcInvalidCall,
          'c_offsetof expects a C record type and field name');
        IntrinsicType := FSIM_TYPE_INVALID;
        FieldName := '';
      end
      else
      begin
        SymbolId := SymLookup(Analyzer.Symbols^, NodeName(Analyzer, ArgumentNode));
        if (SymbolId >= 0) and (Analyzer.Symbols^.Symbols[SymbolId].Kind = skType) then
          IntrinsicType := Analyzer.Symbols^.Symbols[SymbolId].TypeId
        else
          IntrinsicType := FSIM_TYPE_INVALID;
        ArgumentNode := Analyzer.Tree^.Nodes[ArgumentNode].NextSibling;
        if Analyzer.Tree^.Nodes[ArgumentNode].Kind = nkStringLiteralExpr then
          FieldName := ASTNodeString(Analyzer.Tree^, ArgumentNode)
        else
        begin
          ErrorNode(Analyzer, ArgumentNode, dcTypeMismatch,
            'c_offsetof field name must be a string literal');
          FieldName := '';
        end;
      end;
      FieldSymbol := FSIM_INVALID_INDEX;
      if (IntrinsicType >= 0) and (IntrinsicType <= High(Analyzer.Symbols^.Types)) and
         (Analyzer.Symbols^.Types[IntrinsicType].Kind = tyRecord) and
         (tfCLayout in Analyzer.Symbols^.Types[IntrinsicType].Flags) then
        FieldSymbol := SymLookupMember(Analyzer.Symbols^,
          Analyzer.Symbols^.Types[IntrinsicType].RefClassSymbol, FieldName)
      else
        ErrorNode(Analyzer, Node, dcTypeMismatch,
          'c_offsetof first argument must name a C-layout record');
      if FieldSymbol < 0 then
        ErrorNode(Analyzer, Node, dcUnknownSymbol,
          'C record has no field named ''' + FieldName + '''');
      Analyzer.Tree^.Nodes[Node].A := IntrinsicType;
      Analyzer.Tree^.Nodes[Node].SymbolId := FieldSymbol;
      Analyzer.Tree^.Nodes[Node].Aux := FSIM_C_INTRINSIC_OFFSETOF;
      Analyzer.Tree^.Nodes[Node].TypeId := FSIM_TYPE_C_SIZE;
      ResultType := FSIM_TYPE_C_SIZE;
      Exit(True);
    end;
    if (Analyzer.Tree^.Nodes[Node].Aux <> FSIM_C_INTRINSIC_ADDR) and
       not ASCIIEqualFold(Name, 'c_addr') then Exit;
    if (ArgumentNode < 0) or
       (Analyzer.Tree^.Nodes[ArgumentNode].NextSibling >= 0) then
    begin
      ErrorNode(Analyzer, Node, dcInvalidCall,
        'c_addr expects exactly one C ABI lvalue');
      Analyzer.Tree^.Nodes[Node].TypeId := FSIM_TYPE_C_PTR;
      ResultType := FSIM_TYPE_C_PTR;
      Exit(True);
    end;
    Inc(Analyzer.NoImplicitCall);
    ArgumentType := AnalyzeExpression(Analyzer, ArgumentNode);
    Dec(Analyzer.NoImplicitCall);
    SymbolId := Analyzer.Tree^.Nodes[ArgumentNode].SymbolId;
    if (SymbolId >= 0) and (SymbolId <= High(Analyzer.Symbols^.Symbols)) and
       (Analyzer.Symbols^.Symbols[SymbolId].Kind in [skProcedure, skFunction]) and
       ((sfForeign in Analyzer.Symbols^.Symbols[SymbolId].Flags) or
        (sfForeignExport in Analyzer.Symbols^.Symbols[SymbolId].Flags)) then
    begin
      if (ArgumentType < 0) or (ArgumentType > High(Analyzer.Symbols^.Types)) or
         (Analyzer.Symbols^.Types[ArgumentType].Kind <> tyProcedure) then
        ResultType := FSIM_TYPE_C_FN
      else
        ResultType := SymMakeCFunctionType(Analyzer.Symbols^,
          Analyzer.Symbols^.Types[ArgumentType].ReturnType,
          Analyzer.Symbols^.Types[ArgumentType].ParameterStart,
          Analyzer.Symbols^.Types[ArgumentType].ParameterCount,
          sfVariadic in Analyzer.Symbols^.Symbols[SymbolId].Flags);
    end
    else
    begin
      if not (nfLValue in Analyzer.Tree^.Nodes[ArgumentNode].Flags) then
        ErrorNode(Analyzer, ArgumentNode, dcInvalidAssignment,
          'c_addr operand must be C storage or a foreign/exported C routine');
      if not SymIsCABIType(Analyzer.Symbols^, ArgumentType, False) then
        ErrorNode(Analyzer, ArgumentNode, dcTypeMismatch,
          'c_addr requires storage with an explicit c_* ABI type, got ' +
          TypeName(Analyzer.Symbols^, ArgumentType));
      if SymIsCABIType(Analyzer.Symbols^, ArgumentType, False) then
        ResultType := SymMakeCPointerType(Analyzer.Symbols^, ArgumentType)
      else
        ResultType := FSIM_TYPE_C_PTR;
    end;
    if (SymbolId >= 0) and (SymbolId <= High(Analyzer.Symbols^.Symbols)) then
      Include(Analyzer.Symbols^.Symbols[SymbolId].Flags, sfAddressTaken);
    Analyzer.Tree^.Nodes[CalleeNode].Aux := FSIM_C_INTRINSIC_ADDR;
    Analyzer.Tree^.Nodes[Node].Aux := FSIM_C_INTRINSIC_ADDR;
    Analyzer.Tree^.Nodes[Node].TypeId := ResultType;
    Exit(True);
  end;

  if Analyzer.Tree^.Nodes[CalleeNode].Kind <> nkMemberExpr then Exit;
  BaseNode := ChildAt(Analyzer, CalleeNode, 0);
  BaseType := AnalyzeExpression(Analyzer, BaseNode);
  if (BaseType < 0) or (BaseType > High(Analyzer.Symbols^.Types)) or
     (Analyzer.Symbols^.Types[BaseType].Kind <> tyCPointer) then Exit;
  ElementType := Analyzer.Symbols^.Types[BaseType].ElementType;
  Name := NodeName(Analyzer, CalleeNode);
  ArgumentNode := Analyzer.Tree^.Nodes[CalleeNode].NextSibling;
  ActualCount := 0;
  while ArgumentNode >= 0 do
  begin
    Inc(ActualCount);
    ArgumentNode := Analyzer.Tree^.Nodes[ArgumentNode].NextSibling;
  end;

  if ASCIIEqualFold(Name, 'load') then
  begin
    if (ElementType = FSIM_TYPE_INVALID) or
       not SymIsCStorageType(Analyzer.Symbols^, ElementType) then
      ErrorNode(Analyzer, CalleeNode, dcTypeMismatch,
        'load needs a typed pointer to complete C storage')
    else if ActualCount <> 0 then
      ErrorNode(Analyzer, Node, dcInvalidCall, 'c_ptr.load expects no arguments');
    ResultType := ElementType;
    Analyzer.Tree^.Nodes[CalleeNode].Aux := FSIM_C_INTRINSIC_LOAD;
    Analyzer.Tree^.Nodes[Node].Aux := FSIM_C_INTRINSIC_LOAD;
  end
  else if ASCIIEqualFold(Name, 'store') then
  begin
    if (ElementType = FSIM_TYPE_INVALID) or
       not SymIsCStorageType(Analyzer.Symbols^, ElementType) then
      ErrorNode(Analyzer, CalleeNode, dcTypeMismatch,
        'store needs a typed pointer to complete C storage');
    if ActualCount <> 1 then
      ErrorNode(Analyzer, Node, dcInvalidCall, 'c_ptr.store expects one argument')
    else
    begin
      ArgumentNode := Analyzer.Tree^.Nodes[CalleeNode].NextSibling;
      ArgumentType := AnalyzeExpression(Analyzer, ArgumentNode);
      if (ElementType <> FSIM_TYPE_INVALID) and
         not SymCanCArgumentConvert(Analyzer.Symbols^, ElementType, ArgumentType) then
        ErrorNode(Analyzer, ArgumentNode, dcTypeMismatch,
          'c_ptr.store value has type ' + TypeName(Analyzer.Symbols^, ArgumentType) +
          ', expected ' + TypeName(Analyzer.Symbols^, ElementType));
    end;
    ResultType := FSIM_TYPE_VOID;
    Analyzer.Tree^.Nodes[CalleeNode].Aux := FSIM_C_INTRINSIC_STORE;
    Analyzer.Tree^.Nodes[Node].Aux := FSIM_C_INTRINSIC_STORE;
  end
  else if ASCIIEqualFold(Name, 'offset') then
  begin
    if (ElementType = FSIM_TYPE_INVALID) or
       not SymIsCStorageType(Analyzer.Symbols^, ElementType) then
      ErrorNode(Analyzer, CalleeNode, dcTypeMismatch,
        'offset needs a typed pointer to complete C storage');
    if ActualCount <> 1 then
      ErrorNode(Analyzer, Node, dcInvalidCall, 'c_ptr.offset expects one integer argument')
    else
    begin
      ArgumentNode := Analyzer.Tree^.Nodes[CalleeNode].NextSibling;
      ArgumentType := AnalyzeExpression(Analyzer, ArgumentNode);
      if not IsIntegerType(Analyzer, ArgumentType) then
        ErrorNode(Analyzer, ArgumentNode, dcTypeMismatch,
          'c_ptr.offset argument must be an integer');
    end;
    ResultType := BaseType;
    Analyzer.Tree^.Nodes[CalleeNode].Aux := FSIM_C_INTRINSIC_OFFSET;
    Analyzer.Tree^.Nodes[Node].Aux := FSIM_C_INTRINSIC_OFFSET;
  end
  else
    Exit;

  Analyzer.Tree^.Nodes[CalleeNode].TypeId := ResultType;
  Exclude(Analyzer.Tree^.Nodes[CalleeNode].Flags, nfLValue);
  Analyzer.Tree^.Nodes[Node].TypeId := ResultType;
  Result := True;
end;

function AnalyzeCall(var Analyzer: TSemanticAnalyzer; Node: Int32): Int32;
var
  CalleeNode, CalleeType, CalleeSymbol, ArgumentNode, ParameterIndex,
  ArgumentType, IndexedType, InferredParameterStart, ExpectedArgumentType: Int32;
  TypeInfo: TTypeInfo;
  ActualCount: Int32;
  UnspecifiedExternal, ForeignCall, VariadicCall, InferProcedureSignature,
  SuppressImplicitCall: Boolean;
begin
  CalleeNode := ChildAt(Analyzer, Node, 0);
  if TryAnalyzeCInteropCall(Analyzer, Node, CalleeNode, Result) then Exit;
  if TryAnalyzeStringCall(Analyzer, Node, CalleeNode, Result) then Exit;
  if TryAnalyzeTextCall(Analyzer, Node, CalleeNode, Result) then Exit;
  Inc(Analyzer.NoImplicitCall);
  CalleeType := AnalyzeExpression(Analyzer, CalleeNode);
  Dec(Analyzer.NoImplicitCall);
  if (CalleeType >= 0) and (CalleeType <= High(Analyzer.Symbols^.Types)) and
     (Analyzer.Symbols^.Types[CalleeType].Kind = tyArray) then
  begin
    ArgumentNode := Analyzer.Tree^.Nodes[CalleeNode].NextSibling;
    IndexedType := CalleeType;
    ActualCount := 0;
    if ArgumentNode < 0 then
      ErrorNode(Analyzer, Node, dcInvalidCall,
        'an array reference needs at least one index');
    while ArgumentNode >= 0 do
    begin
      ArgumentType := AnalyzeExpression(Analyzer, ArgumentNode);
      if not IsIntegerType(Analyzer, ArgumentType) then
        ErrorNode(Analyzer, ArgumentNode, dcTypeMismatch,
          'array index must be an integer');
      if (IndexedType < 0) or (IndexedType > High(Analyzer.Symbols^.Types)) or
         (Analyzer.Symbols^.Types[IndexedType].Kind <> tyArray) then
        ErrorNode(Analyzer, ArgumentNode, dcInvalidCall,
          'too many indices for this array')
      else
        IndexedType := Analyzer.Symbols^.Types[IndexedType].ElementType;
      Inc(ActualCount);
      ArgumentNode := Analyzer.Tree^.Nodes[ArgumentNode].NextSibling;
    end;
    if (IndexedType >= 0) and (IndexedType <= High(Analyzer.Symbols^.Types)) and
       (Analyzer.Symbols^.Types[IndexedType].Kind = tyArray) then
      ErrorNode(Analyzer, Node, dcInvalidCall,
        'not enough indices for this array');
    Analyzer.Tree^.Nodes[Node].Kind := nkIndexExpr;
    Include(Analyzer.Tree^.Nodes[Node].Flags, nfLValue);
    Result := IndexedType;
    Analyzer.Tree^.Nodes[Node].TypeId := Result;
    Exit;
  end;
  if (CalleeType < 0) or (CalleeType > High(Analyzer.Symbols^.Types)) or
     not (Analyzer.Symbols^.Types[CalleeType].Kind in [tyProcedure, tyCFunction]) then
  begin
    ErrorNode(Analyzer, Node, dcInvalidCall,
      'called expression is not a procedure or function');
    Analyzer.Tree^.Nodes[Node].TypeId := FSIM_TYPE_INVALID;
    Exit(FSIM_TYPE_INVALID);
  end;
  TypeInfo := Analyzer.Symbols^.Types[CalleeType];
  InferProcedureSignature := (TypeInfo.Kind = tyProcedure) and
    (tfUnspecifiedSignature in TypeInfo.Flags);
  InferredParameterStart := Length(Analyzer.Symbols^.Parameters);
  CalleeSymbol := Analyzer.Tree^.Nodes[CalleeNode].SymbolId;
  ForeignCall := (Analyzer.Symbols^.Types[CalleeType].Kind = tyCFunction) or
    ((CalleeSymbol >= 0) and
     (CalleeSymbol <= High(Analyzer.Symbols^.Symbols)) and
     (sfForeign in Analyzer.Symbols^.Symbols[CalleeSymbol].Flags));
  VariadicCall := ((Analyzer.Symbols^.Types[CalleeType].Kind = tyCFunction) and
    (tfCVariadic in TypeInfo.Flags)) or
    ((CalleeSymbol >= 0) and (CalleeSymbol <= High(Analyzer.Symbols^.Symbols)) and
     (sfVariadic in Analyzer.Symbols^.Symbols[CalleeSymbol].Flags));
  UnspecifiedExternal := (CalleeSymbol >= 0) and
    (CalleeSymbol <= High(Analyzer.Symbols^.Symbols)) and
    (sfImported in Analyzer.Symbols^.Symbols[CalleeSymbol].Flags) and
    not ForeignCall;
  ArgumentNode := Analyzer.Tree^.Nodes[CalleeNode].NextSibling;
  ActualCount := 0;
  while ArgumentNode <> FSIM_INVALID_INDEX do
  begin
    SuppressImplicitCall := False;
    ExpectedArgumentType := FSIM_TYPE_INVALID;
    if not InferProcedureSignature and
       (ActualCount < TypeInfo.ParameterCount) then
    begin
      ParameterIndex := TypeInfo.ParameterStart + ActualCount;
      ExpectedArgumentType := Analyzer.Symbols^.Parameters[ParameterIndex].TypeId;
      SuppressImplicitCall := (ExpectedArgumentType >= 0) and
        (ExpectedArgumentType <= High(Analyzer.Symbols^.Types)) and
        (Analyzer.Symbols^.Types[ExpectedArgumentType].Kind = tyProcedure);
    end;
    if SuppressImplicitCall then Inc(Analyzer.NoImplicitCall);
    ArgumentType := AnalyzeExpression(Analyzer, ArgumentNode);
    if SuppressImplicitCall then Dec(Analyzer.NoImplicitCall);
    if InferProcedureSignature then
      SymAddParameter(Analyzer.Symbols^, '', ArgumentType, pmValue,
        FSIM_INVALID_INDEX, FSIM_INVALID_INDEX);
    if not InferProcedureSignature and not UnspecifiedExternal and
       (ActualCount < TypeInfo.ParameterCount) then
    begin
      ParameterIndex := TypeInfo.ParameterStart + ActualCount;
      if not (((ActualCount = 0) and (CalleeSymbol >= 0) and
        (CalleeSymbol <= High(Analyzer.Symbols^.Symbols)) and
        ((SymName(Analyzer.Symbols^, CalleeSymbol) = 'future_ready') or
         (SymName(Analyzer.Symbols^, CalleeSymbol) = 'future_cancel_requested') or
         (SymName(Analyzer.Symbols^, CalleeSymbol) = 'future_state') or
         (SymName(Analyzer.Symbols^, CalleeSymbol) = 'future_thread_id')) and
        (ArgumentType >= 0) and (ArgumentType <= High(Analyzer.Symbols^.Types)) and
        (Analyzer.Symbols^.Types[ArgumentType].Kind = tyFuture)) or
        ((ForeignCall and SymCanCArgumentConvert(Analyzer.Symbols^,
            Analyzer.Symbols^.Parameters[ParameterIndex].TypeId, ArgumentType)) or
         ((not ForeignCall) and CanConvertNode(Analyzer,
            Analyzer.Symbols^.Parameters[ParameterIndex].TypeId, ArgumentNode, ArgumentType)))) then
        ErrorNode(Analyzer, ArgumentNode, dcTypeMismatch,
          'argument ' + IntToStr(ActualCount + 1) + ' has type ' +
          TypeName(Analyzer.Symbols^, ArgumentType) + ', expected ' +
          TypeName(Analyzer.Symbols^,
            Analyzer.Symbols^.Parameters[ParameterIndex].TypeId));
    end;
    if VariadicCall and (ActualCount >= TypeInfo.ParameterCount) and
       not SymIsCABIType(Analyzer.Symbols^, ArgumentType, False) then
      ErrorNode(Analyzer, ArgumentNode, dcTypeMismatch,
        'variadic C arguments need an explicit c_* type; cast this value before passing it');
    Inc(ActualCount);
    ArgumentNode := Analyzer.Tree^.Nodes[ArgumentNode].NextSibling;
  end;
  if InferProcedureSignature then
  begin
    Analyzer.Symbols^.Types[CalleeType].ParameterStart := InferredParameterStart;
    Analyzer.Symbols^.Types[CalleeType].ParameterCount := ActualCount;
    Exclude(Analyzer.Symbols^.Types[CalleeType].Flags, tfUnspecifiedSignature);
    TypeInfo := Analyzer.Symbols^.Types[CalleeType];
  end;
  if not UnspecifiedExternal then
  begin
    if VariadicCall then
    begin
      if ActualCount < TypeInfo.ParameterCount then
        ErrorNode(Analyzer, Node, dcInvalidCall,
          'variadic foreign call supplies ' + IntToStr(ActualCount) +
          ' arguments, expected at least ' + IntToStr(TypeInfo.ParameterCount));
    end
    else if ActualCount <> TypeInfo.ParameterCount then
      ErrorNode(Analyzer, Node, dcInvalidCall,
        'call supplies ' + IntToStr(ActualCount) + ' arguments, expected ' +
        IntToStr(TypeInfo.ParameterCount));
  end;
  Result := TypeInfo.ReturnType;
  Analyzer.Tree^.Nodes[Node].TypeId := Result;
end;

function AnalyzeQua(var Analyzer: TSemanticAnalyzer; Node: Int32): Int32;
var
  OperandNode, OperandType, SourceClass, TargetClass: Int32;
  TargetName: RawByteString;
begin
  OperandNode := ChildAt(Analyzer, Node, 0);
  OperandType := AnalyzeExpression(Analyzer, OperandNode);
  TargetName := NodeName(Analyzer, Node);
  TargetClass := SymLookupClass(Analyzer.Symbols^, TargetName);
  if TargetClass < 0 then
  begin
    ErrorNode(Analyzer, Node, dcUnknownType,
      'unknown QUA target class ''' + TargetName + '''');
    Exit(FSIM_TYPE_INVALID);
  end;
  if not IsReferenceType(Analyzer, OperandType) or
     (Analyzer.Symbols^.Types[OperandType].Kind <> tyReference) then
  begin
    ErrorNode(Analyzer, Node, dcInvalidQua,
      'QUA operand must be a class reference');
    Exit(FSIM_TYPE_INVALID);
  end;
  SourceClass := Analyzer.Symbols^.Types[OperandType].RefClassSymbol;
  if not SymIsDerivedFrom(Analyzer.Symbols^, SourceClass, TargetClass) and
     not SymIsDerivedFrom(Analyzer.Symbols^, TargetClass, SourceClass) then
    ErrorNode(Analyzer, Node, dcInvalidQua,
      'QUA types ''' + SymName(Analyzer.Symbols^, SourceClass) + ''' and ''' +
      TargetName + ''' are unrelated');
  Analyzer.Tree^.Nodes[Node].SymbolId := TargetClass;
  Result := SymMakeReferenceType(Analyzer.Symbols^, TargetClass);
  Analyzer.Tree^.Nodes[Node].TypeId := Result;
end;

function AnalyzeObjectTest(var Analyzer: TSemanticAnalyzer;
  Node: Int32): Int32;
var
  OperandNode, OperandType, SourceClass, TargetClass: Int32;
begin
  OperandNode := ChildAt(Analyzer, Node, 0);
  OperandType := AnalyzeExpression(Analyzer, OperandNode);
  TargetClass := Analyzer.Tree^.Nodes[Node].SymbolId;
  if TargetClass < 0 then
    TargetClass := SymLookupClass(Analyzer.Symbols^, NodeName(Analyzer, Node));
  if TargetClass < 0 then
    ErrorNode(Analyzer, Node, dcUnknownType,
      'unknown object-test class ''' + NodeName(Analyzer, Node) + '''');
  if not IsReferenceType(Analyzer, OperandType) or
     (Analyzer.Symbols^.Types[OperandType].Kind <> tyReference) then
    ErrorNode(Analyzer, OperandNode, dcTypeMismatch,
      '''is'' and ''in'' require a class reference operand')
  else if TargetClass >= 0 then
  begin
    SourceClass := Analyzer.Symbols^.Types[OperandType].RefClassSymbol;
    if not SymIsDerivedFrom(Analyzer.Symbols^, SourceClass, TargetClass) and
       not SymIsDerivedFrom(Analyzer.Symbols^, TargetClass, SourceClass) then
      ErrorNode(Analyzer, Node, dcTypeMismatch,
        'object relation compares unrelated class hierarchies');
  end;
  Analyzer.Tree^.Nodes[Node].SymbolId := TargetClass;
  Analyzer.Tree^.Nodes[Node].TypeId := FSIM_TYPE_BOOLEAN;
  Result := FSIM_TYPE_BOOLEAN;
end;

function AnalyzeConditional(var Analyzer: TSemanticAnalyzer;
  Node: Int32): Int32;
var
  ConditionNode, ThenNode, ElseNode, ThenType, ElseType: Int32;
begin
  ConditionNode := ChildAt(Analyzer, Node, 0);
  ThenNode := ChildAt(Analyzer, Node, 1);
  ElseNode := ChildAt(Analyzer, Node, 2);
  if not IsBooleanLike(Analyzer,
    AnalyzeExpression(Analyzer, ConditionNode)) then
    ErrorNode(Analyzer, ConditionNode, dcTypeMismatch,
      'conditional expression condition must be boolean');
  ThenType := AnalyzeExpression(Analyzer, ThenNode);
  ElseType := AnalyzeExpression(Analyzer, ElseNode);
  if (Analyzer.Tree^.Nodes[ThenNode].Kind = nkNoneExpr) and
     IsReferenceType(Analyzer, ElseType) then
    Result := ElseType
  else if (Analyzer.Tree^.Nodes[ElseNode].Kind = nkNoneExpr) and
          IsReferenceType(Analyzer, ThenType) then
    Result := ThenType
  else
    Result := SymCommonType(Analyzer.Symbols^, ThenType, ElseType);
  if Result = FSIM_TYPE_INVALID then
    ErrorNode(Analyzer, Node, dcTypeMismatch,
      'conditional expression branches have incompatible types ' +
      TypeName(Analyzer.Symbols^, ThenType) + ' and ' +
      TypeName(Analyzer.Symbols^, ElseType));
  Analyzer.Tree^.Nodes[Node].TypeId := Result;
end;

function AnalyzeConversion(var Analyzer: TSemanticAnalyzer;
  Node: Int32): Int32;
var
  Operand, SourceType, TargetType: Int32;
  SourceKind, TargetKind: TTypeKind;
begin
  Operand := ChildAt(Analyzer, Node, 0);
  SourceType := AnalyzeExpression(Analyzer, Operand);
  TargetType := Analyzer.Tree^.Nodes[Node].TypeId;
  Result := TargetType;
  if (SourceType < 0) or (TargetType < 0) or
     (SourceType > High(Analyzer.Symbols^.Types)) or
     (TargetType > High(Analyzer.Symbols^.Types)) then Exit;
  SourceKind := Analyzer.Symbols^.Types[SourceType].Kind;
  TargetKind := Analyzer.Symbols^.Types[TargetType].Kind;
  if SymTypeEqual(Analyzer.Symbols^, TargetType, SourceType) then Exit;
  if (TargetKind in [tyInteger, tyCInteger]) and
     (SourceKind in [tyInteger, tyCInteger, tyReal, tyCReal, tyBoolean,
       tyCharacter]) then Exit;
  if (TargetKind in [tyReal, tyCReal]) and
     (SourceKind in [tyInteger, tyCInteger, tyReal, tyCReal, tyBoolean,
       tyCharacter]) then Exit;
  if (TargetKind = tyBoolean) and
     (SourceKind in [tyInteger, tyCInteger, tyBoolean, tyCharacter]) then Exit;
  if (TargetKind = tyCharacter) and
     (SourceKind in [tyInteger, tyCInteger, tyBoolean, tyCharacter]) then Exit;
  if (TargetKind = tyCPointer) and
     ((SourceKind in [tyCPointer, tyInteger, tyCInteger]) or
      (SourceType = FSIM_TYPE_VOID) or
      ((TargetType = FSIM_TYPE_C_STRING) and
       (SourceType = FSIM_TYPE_STRING))) then Exit;
  if (SourceKind = tyCPointer) and
     (TargetKind in [tyInteger, tyCInteger]) then Exit;
  ErrorNode(Analyzer, Node, dcTypeMismatch,
    'cannot explicitly convert ' + TypeName(Analyzer.Symbols^, SourceType) +
    ' to ' + TypeName(Analyzer.Symbols^, TargetType));
end;

function AnalyzeExpression(var Analyzer: TSemanticAnalyzer; Node: Int32): Int32;
var
  ClassSymbol, Child, ChildType, ClassIndex, ParameterIndex: Int32;
begin
  if Node = FSIM_INVALID_INDEX then
    Exit(FSIM_TYPE_INVALID);
  case Analyzer.Tree^.Nodes[Node].Kind of
    nkLambdaExpr:
      begin
        Child := Analyzer.Tree^.Nodes[Node].BodyNode;
        if (Child < 0) or (Child > High(Analyzer.Tree^.Nodes)) then
        begin
          ErrorNode(Analyzer, Node, dcInternalError,
            'lambda is missing its synthetic routine body');
          Result := FSIM_TYPE_INVALID;
        end
        else
        begin
          AnalyzeRoutine(Analyzer, Child);
          Result := Analyzer.Tree^.Nodes[Node].TypeId;
        end;
      end;
    nkIdentifierExpr:
      begin
        ResolveIdentifier(Analyzer, Node);
        Result := Analyzer.Tree^.Nodes[Node].TypeId;
        if (Analyzer.NoImplicitCall = 0) and (Result >= 0) and
           (Result <= High(Analyzer.Symbols^.Types)) and
           (Analyzer.Symbols^.Types[Result].Kind = tyProcedure) and
           (Analyzer.Symbols^.Types[Result].ParameterCount = 0) then
        begin
          Result := Analyzer.Symbols^.Types[Result].ReturnType;
          Analyzer.Tree^.Nodes[Node].TypeId := Result;
          Include(Analyzer.Tree^.Nodes[Node].Flags, nfImplicitCall);
        end;
      end;
    nkIntegerLiteralExpr, nkRealLiteralExpr, nkBooleanLiteralExpr,
    nkCharacterLiteralExpr, nkStringLiteralExpr:
      Result := Analyzer.Tree^.Nodes[Node].TypeId;
    nkNoneExpr:
      Result := FSIM_TYPE_VOID;
    nkThisExpr:
      begin
        if CurrentRoutineIsLambda(Analyzer) then
          ErrorNode(Analyzer, Node, dcBackendUnsupported,
            'lambda cannot capture ''this'' until receiver closures are available');
        if Analyzer.CurrentClass < 0 then
        begin
          ErrorNode(Analyzer, Node, dcInvalidControlFlow,
            '''this'' is unavailable outside a class');
          Result := FSIM_TYPE_INVALID;
        end
        else
        begin
          ClassSymbol := Analyzer.Tree^.Nodes[Node].SymbolId;
          if ClassSymbol < 0 then ClassSymbol := Analyzer.CurrentClass;
          if not SymIsDerivedFrom(Analyzer.Symbols^, Analyzer.CurrentClass,
            ClassSymbol) then
          begin
            ErrorNode(Analyzer, Node, dcTypeMismatch,
              '''this'' qualifier is not a prefix of the current class');
            ClassSymbol := Analyzer.CurrentClass;
          end;
          Result := SymMakeReferenceType(Analyzer.Symbols^, ClassSymbol);
          Analyzer.Tree^.Nodes[Node].SymbolId := ClassSymbol;
        end;
        Analyzer.Tree^.Nodes[Node].TypeId := Result;
      end;
    nkNewExpr:
      begin
        ClassSymbol := Analyzer.Tree^.Nodes[Node].SymbolId;
        if ClassSymbol < 0 then
          ClassSymbol := SymLookupClass(Analyzer.Symbols^, NodeName(Analyzer, Node));
        if ClassSymbol < 0 then
          Result := FSIM_TYPE_INVALID
        else
          Result := SymMakeReferenceType(Analyzer.Symbols^, ClassSymbol);
        Analyzer.Tree^.Nodes[Node].TypeId := Result;
        Child := Analyzer.Tree^.Nodes[Node].FirstChild;
        ChildType := 0;
        while Child >= 0 do
        begin
          Result := AnalyzeExpression(Analyzer, Child);
          if (ClassSymbol >= 0) and
             not (sfImported in Analyzer.Symbols^.Symbols[ClassSymbol].Flags) then
          begin
            ClassIndex := SymClassIndex(Analyzer.Symbols^, ClassSymbol);
            if (ClassIndex >= 0) and
               (ChildType < Analyzer.Symbols^.Classes[ClassIndex].ParameterCount) then
            begin
              ParameterIndex := Analyzer.Symbols^.Classes[ClassIndex].ParameterStart +
                ChildType;
              if not CanConvertNode(Analyzer,
                Analyzer.Symbols^.Parameters[ParameterIndex].TypeId, Child, Result) then
                ErrorNode(Analyzer, Child, dcTypeMismatch,
                  'class argument ' + IntToStr(ChildType + 1) +
                  ' has an incompatible type');
            end;
          end;
          Inc(ChildType);
          Child := Analyzer.Tree^.Nodes[Child].NextSibling;
        end;
        if ClassSymbol >= 0 then
        begin
          ClassIndex := SymClassIndex(Analyzer.Symbols^, ClassSymbol);
          if not (sfImported in Analyzer.Symbols^.Symbols[ClassSymbol].Flags) and
             (ClassIndex >= 0) and
             (ChildType <> Analyzer.Symbols^.Classes[ClassIndex].ParameterCount) then
            ErrorNode(Analyzer, Node, dcInvalidCall,
              'object generator supplies ' + IntToStr(ChildType) +
              ' arguments, expected ' +
              IntToStr(Analyzer.Symbols^.Classes[ClassIndex].ParameterCount));
          Result := SymMakeReferenceType(Analyzer.Symbols^, ClassSymbol);
          Analyzer.Tree^.Nodes[Node].TypeId := Result;
        end;
      end;
    nkUnaryExpr: Result := AnalyzeUnary(Analyzer, Node);
    nkBinaryExpr: Result := AnalyzeBinary(Analyzer, Node);
    nkMemberExpr: Result := AnalyzeMember(Analyzer, Node);
    nkCallExpr: Result := AnalyzeCall(Analyzer, Node);
    nkQuaExpr: Result := AnalyzeQua(Analyzer, Node);
    nkObjectTestExpr: Result := AnalyzeObjectTest(Analyzer, Node);
    nkConditionalExpr: Result := AnalyzeConditional(Analyzer, Node);
    nkConversionExpr: Result := AnalyzeConversion(Analyzer, Node);
    nkAwaitExpr:
      begin
        Child := ChildAt(Analyzer, Node, 0);
        ChildType := AnalyzeExpression(Analyzer, Child);
        if Analyzer.Options^.Dialect = fdSimula67 then
          ErrorNode(Analyzer, Node, dcDialectViolation,
            'await is unavailable in simula67 mode');
        if (ChildType >= 0) and (ChildType <= High(Analyzer.Symbols^.Types)) and
           (Analyzer.Symbols^.Types[ChildType].Kind = tyFuture) then
          Result := Analyzer.Symbols^.Types[ChildType].ElementType
        else
        begin
          ErrorNode(Analyzer, Child, dcTypeMismatch,
            'await requires a future value');
          Result := FSIM_TYPE_INVALID;
        end;
        Analyzer.Tree^.Nodes[Node].TypeId := Result;
      end;
    nkSpawnExpr:
      begin
        Child := ChildAt(Analyzer, Node, 0);
        ChildType := AnalyzeSpawnOperand(Analyzer, Node);
        if Analyzer.Options^.Dialect = fdSimula67 then
          ErrorNode(Analyzer, Node, dcDialectViolation,
            'spawn is unavailable in simula67 mode');
        Result := SymMakeFutureType(Analyzer.Symbols^, ChildType);
        Analyzer.Tree^.Nodes[Node].TypeId := Result;
      end;
    nkReceiveExpr:
      begin
        Child := ChildAt(Analyzer, Node, 0);
        ChildType := AnalyzeExpression(Analyzer, Child);
        if Analyzer.Options^.Dialect = fdSimula67 then
          ErrorNode(Analyzer, Node, dcDialectViolation,
            'channel receive is unavailable in simula67 mode');
        if (ChildType >= 0) and (ChildType <= High(Analyzer.Symbols^.Types)) and
           (Analyzer.Symbols^.Types[ChildType].Kind = tyChannel) then
          Result := Analyzer.Symbols^.Types[ChildType].ElementType
        else
        begin
          ErrorNode(Analyzer, Child, dcTypeMismatch,
            'receive requires a channel value');
          Result := FSIM_TYPE_INVALID;
        end;
        Analyzer.Tree^.Nodes[Node].TypeId := Result;
      end;
    nkIndexExpr:
      begin
        Child := ChildAt(Analyzer, Node, 0);
        ChildType := AnalyzeExpression(Analyzer, Child);
        if (ChildType < 0) or (ChildType > High(Analyzer.Symbols^.Types)) or
           (Analyzer.Symbols^.Types[ChildType].Kind <> tyArray) then
        begin
          ErrorNode(Analyzer, Node, dcTypeMismatch,
            'indexing requires an array operand');
          Result := FSIM_TYPE_INVALID;
        end
        else
          Result := Analyzer.Symbols^.Types[ChildType].ElementType;
        Child := ChildAt(Analyzer, Node, 1);
        ChildType := AnalyzeExpression(Analyzer, Child);
        if not IsIntegerType(Analyzer, ChildType) then
          ErrorNode(Analyzer, Child, dcTypeMismatch,
            'array index must be an integer');
        Analyzer.Tree^.Nodes[Node].TypeId := Result;
      end;
    nkSizeOfExpr:
      begin
        Child := ChildAt(Analyzer, Node, 0);
        AnalyzeExpression(Analyzer, Child);
        Result := FSIM_TYPE_INTEGER;
        Analyzer.Tree^.Nodes[Node].TypeId := Result;
      end;
    nkTypeOfExpr:
      begin
        Child := ChildAt(Analyzer, Node, 0);
        AnalyzeExpression(Analyzer, Child);
        Result := FSIM_TYPE_INTEGER;
        Analyzer.Tree^.Nodes[Node].TypeId := Result;
      end;
  else
    begin
      ErrorNode(Analyzer, Node, dcInternalError,
        'node is not valid in expression context');
      Result := FSIM_TYPE_INVALID;
    end;
  end;
end;

procedure AnalyzeAssignment(var Analyzer: TSemanticAnalyzer; Node: Int32;
  IsReferenceAssignment: Boolean);
var
  LeftNode, RightNode, LeftType, RightType, SymbolId,
  TargetClass, SourceClass: Int32;
begin
  LeftNode := ChildAt(Analyzer, Node, 0);
  RightNode := ChildAt(Analyzer, Node, 1);
  Inc(Analyzer.NoImplicitCall);
  LeftType := AnalyzeExpression(Analyzer, LeftNode);
  Dec(Analyzer.NoImplicitCall);
  SymbolId := Analyzer.Tree^.Nodes[LeftNode].SymbolId;
  if (SymbolId >= 0) and (SymbolId = Analyzer.CurrentRoutine) and
     (Analyzer.Symbols^.Types[Analyzer.Symbols^.Symbols[SymbolId].TypeId].Kind =
       tyProcedure) and
     (Analyzer.Symbols^.Types[Analyzer.Symbols^.Symbols[SymbolId].TypeId].ReturnType <>
       FSIM_TYPE_VOID) then
  begin
    LeftType := Analyzer.Symbols^.Types[
      Analyzer.Symbols^.Symbols[SymbolId].TypeId].ReturnType;
    Analyzer.Tree^.Nodes[LeftNode].TypeId := LeftType;
    Include(Analyzer.Tree^.Nodes[LeftNode].Flags, nfLValue);
  end;
  if (SymbolId >= 0) and (SymbolId <= High(Analyzer.Symbols^.Symbols)) and
     (Analyzer.Symbols^.Symbols[SymbolId].Kind = skParameter) and
     (LeftType >= 0) and (LeftType <= High(Analyzer.Symbols^.Types)) and
     (Analyzer.Symbols^.Types[LeftType].Kind = tyProcedure) then
    ErrorNode(Analyzer, LeftNode, dcInvalidAssignment,
      'procedure parameters are not assignable');
  if (LeftType >= 0) and (LeftType <= High(Analyzer.Symbols^.Types)) and
     (Analyzer.Symbols^.Types[LeftType].Kind = tyProcedure) then
    Inc(Analyzer.NoImplicitCall);
  RightType := AnalyzeExpression(Analyzer, RightNode);
  if (LeftType >= 0) and (LeftType <= High(Analyzer.Symbols^.Types)) and
     (Analyzer.Symbols^.Types[LeftType].Kind = tyProcedure) then
    Dec(Analyzer.NoImplicitCall);
  if not (nfLValue in Analyzer.Tree^.Nodes[LeftNode].Flags) then
    ErrorNode(Analyzer, LeftNode, dcInvalidAssignment,
      'assignment target is not assignable');
  if IsReferenceAssignment and
     (LeftType >= 0) and (LeftType <= High(Analyzer.Symbols^.Types)) and
     (RightType >= 0) and (RightType <= High(Analyzer.Symbols^.Types)) and
     (Analyzer.Symbols^.Types[LeftType].Kind = tyReference) and
     (Analyzer.Symbols^.Types[RightType].Kind = tyReference) then
  begin
    TargetClass := Analyzer.Symbols^.Types[LeftType].RefClassSymbol;
    SourceClass := Analyzer.Symbols^.Types[RightType].RefClassSymbol;
    if SymIsDerivedFrom(Analyzer.Symbols^, TargetClass, SourceClass) and
       not SymIsDerivedFrom(Analyzer.Symbols^, SourceClass, TargetClass) then
      { C stores the class required by the checked narrowing assignment.
        NONE remains assignable and is accepted by the backend check. }
      Analyzer.Tree^.Nodes[Node].C := TargetClass;
  end;
  if not SymCanAssign(Analyzer.Symbols^, LeftType, RightType,
    IsReferenceAssignment) then
  begin
    if IsReferenceAssignment then
      ErrorNode(Analyzer, Node, dcInvalidReferenceAssignment,
        ''':-'' requires compatible reference operands; target is ' +
        TypeName(Analyzer.Symbols^, LeftType) + ', source is ' +
        TypeName(Analyzer.Symbols^, RightType))
    else
      ErrorNode(Analyzer, Node, dcInvalidValueAssignment,
        ''':='' requires compatible value operands; target is ' +
        TypeName(Analyzer.Symbols^, LeftType) + ', source is ' +
        TypeName(Analyzer.Symbols^, RightType));
  end;
  SymbolId := Analyzer.Tree^.Nodes[LeftNode].SymbolId;
  if SymbolId >= 0 then
  begin
    Include(Analyzer.Symbols^.Symbols[SymbolId].Flags, sfAssigned);
    if sfFinal in Analyzer.Symbols^.Symbols[SymbolId].Flags then
      ErrorNode(Analyzer, LeftNode, dcInvalidAssignment,
        'cannot assign to final symbol ''' +
        SymName(Analyzer.Symbols^, SymbolId) + '''');
  end;
end;

procedure AnalyzeCondition(var Analyzer: TSemanticAnalyzer; Node: Int32);
var
  TypeId: Int32;
begin
  TypeId := AnalyzeExpression(Analyzer, Node);
  if not IsBooleanLike(Analyzer, TypeId) then
    ErrorNode(Analyzer, Node, dcTypeMismatch,
      'condition must be boolean');
end;

procedure AnalyzeOutput(var Analyzer: TSemanticAnalyzer; Node: Int32);
var
  Arg1, Arg2, Arg3, Child, TypeId, ArgCount: Int32;
  Kind: TOutputKind;

  procedure RequireInteger(Argument: Int32; const What: RawByteString);
  var
    T: Int32;
  begin
    if Argument < 0 then Exit;
    T := AnalyzeExpression(Analyzer, Argument);
    if not IsIntegerType(Analyzer, T) then
      ErrorNode(Analyzer, Argument, dcTypeMismatch,
        What + ' must be an integer');
  end;

begin
  Kind := TOutputKind(Analyzer.Tree^.Nodes[Node].Aux);
  Arg1 := ChildAt(Analyzer, Node, 0);
  Arg2 := ChildAt(Analyzer, Node, 1);
  Arg3 := ChildAt(Analyzer, Node, 2);
  ArgCount := 0;
  Child := Analyzer.Tree^.Nodes[Node].FirstChild;
  while Child >= 0 do
  begin
    Inc(ArgCount);
    Child := Analyzer.Tree^.Nodes[Child].NextSibling;
  end;

  if Kind = okImage then
  begin
    if ArgCount <> 0 then
      ErrorNode(Analyzer, Node, dcInvalidCall,
        'outimage takes no arguments');
    Exit;
  end;
  if Arg1 < 0 then
  begin
    ErrorNode(Analyzer, Node, dcInvalidCall,
      'output routine requires an argument');
    Exit;
  end;

  TypeId := AnalyzeExpression(Analyzer, Arg1);
  case Kind of
    okText:
      begin
        if not (TypeId in [FSIM_TYPE_TEXT, FSIM_TYPE_STRING]) then
          ErrorNode(Analyzer, Arg1, dcTypeMismatch,
            'outtext requires text or string');
        if ArgCount <> 1 then
          ErrorNode(Analyzer, Node, dcInvalidCall,
            'outtext takes one argument');
      end;
    okInteger:
      begin
        if not IsIntegerType(Analyzer, TypeId) then
          ErrorNode(Analyzer, Arg1, dcTypeMismatch,
            'outint requires an integer');
        { Keep the Simula form available in fsim too.  One argument is the
          convenient modern spelling; the optional width preserves classic
          source compatibility without changing the value type. }
        if not (ArgCount in [1, 2]) then
          ErrorNode(Analyzer, Node, dcInvalidCall,
            'outint requires (value [, width])');
        RequireInteger(Arg2, 'outint width');
      end;
    okReal:
      begin
        if not IsNumericType(Analyzer, TypeId) then
          ErrorNode(Analyzer, Arg1, dcTypeMismatch,
            'outreal requires a numeric value');
        if Analyzer.Options^.Dialect = fdSimula67 then
        begin
          if ArgCount <> 3 then
            ErrorNode(Analyzer, Node, dcInvalidCall,
              'outreal requires (value, digits, width)');
          RequireInteger(Arg2, 'outreal digits');
          RequireInteger(Arg3, 'outreal width');
        end
        else if ArgCount <> 1 then
          ErrorNode(Analyzer, Node, dcInvalidCall,
            'outreal takes one argument in -std=fsim');
      end;
    okFixed:
      begin
        if not IsNumericType(Analyzer, TypeId) then
          ErrorNode(Analyzer, Arg1, dcTypeMismatch,
            'outfix requires a numeric value');
        if ArgCount <> 3 then
          ErrorNode(Analyzer, Node, dcInvalidCall,
            'outfix requires (value, digits, width)');
        RequireInteger(Arg2, 'outfix digits');
        RequireInteger(Arg3, 'outfix width');
      end;
    okCharacter:
      begin
        if TypeId <> FSIM_TYPE_CHARACTER then
          ErrorNode(Analyzer, Arg1, dcTypeMismatch,
            'outchar requires a character');
        if ArgCount <> 1 then
          ErrorNode(Analyzer, Node, dcInvalidCall,
            'outchar takes one argument');
      end;
  end;

  { Analyze extras too, even after an arity error. diagnostics are much less
    confusing when a bad extra expression still gets its own type/name check. }
  Child := Analyzer.Tree^.Nodes[Arg1].NextSibling;
  if (Kind in [okInteger, okReal, okFixed]) and (Child >= 0) then
    Child := Analyzer.Tree^.Nodes[Child].NextSibling;
  if (Kind in [okReal, okFixed]) and (Child >= 0) then
    Child := Analyzer.Tree^.Nodes[Child].NextSibling;
  while Child >= 0 do
  begin
    AnalyzeExpression(Analyzer, Child);
    Child := Analyzer.Tree^.Nodes[Child].NextSibling;
  end;
end;

procedure AnalyzeReturn(var Analyzer: TSemanticAnalyzer; Node: Int32);
var
  RoutineType, ExpectedType, ValueNode, ValueType: Int32;
begin
  if Analyzer.CurrentRoutine < 0 then
  begin
    ErrorNode(Analyzer, Node, dcInvalidReturn,
      'return is only valid inside a routine');
    Exit;
  end;
  RoutineType := Analyzer.Symbols^.Symbols[Analyzer.CurrentRoutine].TypeId;
  if (RoutineType < 0) or
     (Analyzer.Symbols^.Types[RoutineType].Kind <> tyProcedure) then
  begin
    ErrorNode(Analyzer, Node, dcInternalError,
      'current routine has no procedure type');
    Exit;
  end;
  ExpectedType := Analyzer.Symbols^.Types[RoutineType].ReturnType;
  Analyzer.Tree^.Nodes[Node].TypeId := ExpectedType;
  ValueNode := ChildAt(Analyzer, Node, 0);
  if ValueNode < 0 then
  begin
    if ExpectedType <> FSIM_TYPE_VOID then
      ErrorNode(Analyzer, Node, dcInvalidReturn,
        'function must return a value of type ' +
        TypeName(Analyzer.Symbols^, ExpectedType));
  end
  else
  begin
    if (ExpectedType >= 0) and (ExpectedType <= High(Analyzer.Symbols^.Types)) and
       (Analyzer.Symbols^.Types[ExpectedType].Kind = tyProcedure) then
      Inc(Analyzer.NoImplicitCall);
    ValueType := AnalyzeExpression(Analyzer, ValueNode);
    if (ExpectedType >= 0) and (ExpectedType <= High(Analyzer.Symbols^.Types)) and
       (Analyzer.Symbols^.Types[ExpectedType].Kind = tyProcedure) then
      Dec(Analyzer.NoImplicitCall);
    if ExpectedType = FSIM_TYPE_VOID then
      ErrorNode(Analyzer, Node, dcInvalidReturn,
        'procedure cannot return a value')
    else if not CanConvertNode(Analyzer, ExpectedType, ValueNode, ValueType) then
      ErrorNode(Analyzer, ValueNode, dcInvalidReturn,
        'returned value has type ' + TypeName(Analyzer.Symbols^, ValueType) +
        ', expected ' + TypeName(Analyzer.Symbols^, ExpectedType));
  end;
  Analyzer.Reachable := False;
end;

procedure AnalyzeBlock(var Analyzer: TSemanticAnalyzer; Node: Int32);
var
  SavedScope: Int32;
  Child: Int32;
begin
  SavedScope := Analyzer.CurrentScope;
  if Analyzer.Tree^.Nodes[Node].Aux >= 0 then
    Analyzer.CurrentScope := Analyzer.Tree^.Nodes[Node].Aux;
  Child := Analyzer.Tree^.Nodes[Node].FirstChild;
  while Child >= 0 do
  begin
    if not Analyzer.Reachable and
       not (Analyzer.Tree^.Nodes[Child].Kind in [nkVariableDecl,
         nkProcedureDecl, nkFunctionDecl, nkClassDecl, nkProcessClassDecl,
         nkThreadClassDecl]) then
      WarningNode(Analyzer, Child, dcUnreachableCode,
        'statement is unreachable');
    AnalyzeNode(Analyzer, Child);
    Child := Analyzer.Tree^.Nodes[Child].NextSibling;
  end;
  Analyzer.CurrentScope := SavedScope;
end;

procedure AnalyzeRoutine(var Analyzer: TSemanticAnalyzer; Node: Int32);
var
  SavedScope, SavedRoutine, SavedClass: Int32;
  Child, PrefixClass, ClassIndex, ArgumentCount, ArgumentType,
  ParameterIndex, RoutineType, ParamStart, ParamCount, I: Int32;
  SavedReachable: Boolean;
begin
  SavedScope := Analyzer.CurrentScope;
  SavedRoutine := Analyzer.CurrentRoutine;
  SavedClass := Analyzer.CurrentClass;
  SavedReachable := Analyzer.Reachable;
  Analyzer.CurrentRoutine := Analyzer.Tree^.Nodes[Node].SymbolId;
  Analyzer.CurrentScope := Analyzer.Tree^.Nodes[Node].Aux;
  if (Analyzer.CurrentRoutine >= 0) and
     (Analyzer.CurrentRoutine <= High(Analyzer.Symbols^.Symbols)) then
  begin
    RoutineType := Analyzer.Symbols^.Symbols[Analyzer.CurrentRoutine].TypeId;
    if (RoutineType >= 0) and
       (RoutineType <= High(Analyzer.Symbols^.Types)) and
       (Analyzer.Symbols^.Types[RoutineType].Kind = tyProcedure) then
    begin
      if IsIncompleteCRecord(Analyzer,
         Analyzer.Symbols^.Types[RoutineType].ReturnType) then
        ErrorNode(Analyzer, Node, dcTypeMismatch,
          'a routine cannot return an opaque C record by value');
      ParamStart := Analyzer.Symbols^.Types[RoutineType].ParameterStart;
      ParamCount := Analyzer.Symbols^.Types[RoutineType].ParameterCount;
      for I := 0 to ParamCount - 1 do
        if IsIncompleteCRecord(Analyzer,
           Analyzer.Symbols^.Parameters[ParamStart + I].TypeId) then
          ErrorNode(Analyzer, Node, dcTypeMismatch,
            'a routine cannot take an opaque C record by value; use c_ptr(T)');
    end;
  end;
  if (Analyzer.Tree^.Nodes[Node].Kind = nkProgramDecl) and
     (Analyzer.Tree^.Nodes[Node].A >= 0) then
    Analyzer.CurrentClass := Analyzer.Tree^.Nodes[Node].A;
  Analyzer.Reachable := True;
  PrefixClass := Analyzer.Tree^.Nodes[Node].A;
  Child := Analyzer.Tree^.Nodes[Node].FirstChild;
  if (Analyzer.Tree^.Nodes[Node].Kind = nkProgramDecl) and
     (PrefixClass >= 0) then
  begin
    ClassIndex := SymClassIndex(Analyzer.Symbols^, PrefixClass);
    ArgumentCount := 0;
    while (Child >= 0) and
          (Child <> Analyzer.Tree^.Nodes[Node].BodyNode) do
    begin
      ArgumentType := AnalyzeExpression(Analyzer, Child);
      if (ClassIndex >= 0) and
         (ArgumentCount < Analyzer.Symbols^.Classes[ClassIndex].ParameterCount) then
      begin
        ParameterIndex := Analyzer.Symbols^.Classes[ClassIndex].ParameterStart +
          ArgumentCount;
        if not CanConvertNode(Analyzer,
          Analyzer.Symbols^.Parameters[ParameterIndex].TypeId, Child, ArgumentType) then
          ErrorNode(Analyzer, Child, dcTypeMismatch,
            'prefixed block argument ' + IntToStr(ArgumentCount + 1) +
            ' has an incompatible type');
      end;
      Inc(ArgumentCount);
      Child := Analyzer.Tree^.Nodes[Child].NextSibling;
    end;
    if (ClassIndex >= 0) and
       (ArgumentCount <> Analyzer.Symbols^.Classes[ClassIndex].ParameterCount) then
      ErrorNode(Analyzer, Node, dcInvalidCall,
        'prefixed block supplies ' + IntToStr(ArgumentCount) +
        ' arguments, expected ' +
        IntToStr(Analyzer.Symbols^.Classes[ClassIndex].ParameterCount));
  end;
  while Child >= 0 do
  begin
    if Analyzer.Tree^.Nodes[Child].Kind <> nkParameterDecl then
      AnalyzeNode(Analyzer, Child);
    Child := Analyzer.Tree^.Nodes[Child].NextSibling;
  end;
  Analyzer.CurrentScope := SavedScope;
  Analyzer.CurrentRoutine := SavedRoutine;
  Analyzer.CurrentClass := SavedClass;
  Analyzer.Reachable := SavedReachable;
end;

function CountClassInnerStatements(const Analyzer: TSemanticAnalyzer;
  Node: Int32): Int32;
var
  Child: Int32;
begin
  Result := 0;
  if (Node < 0) or (Node > High(Analyzer.Tree^.Nodes)) then Exit;
  case Analyzer.Tree^.Nodes[Node].Kind of
    nkProcedureDecl, nkFunctionDecl, nkClassDecl, nkProcessClassDecl,
    nkThreadClassDecl:
      Exit;
    nkInnerStatement:
      begin
        Result := 1;
        Exit;
      end;
  end;
  Child := Analyzer.Tree^.Nodes[Node].FirstChild;
  while Child >= 0 do
  begin
    Inc(Result, CountClassInnerStatements(Analyzer, Child));
    Child := Analyzer.Tree^.Nodes[Child].NextSibling;
  end;
end;

procedure AnalyzeClass(var Analyzer: TSemanticAnalyzer; Node: Int32);
var
  SavedClass, SavedScope, InnerCount: Int32;
  Child: Int32;
begin
  SavedClass := Analyzer.CurrentClass;
  SavedScope := Analyzer.CurrentScope;
  Analyzer.CurrentClass := Analyzer.Tree^.Nodes[Node].SymbolId;
  Analyzer.CurrentScope := Analyzer.Tree^.Nodes[Node].C;
  InnerCount := CountClassInnerStatements(Analyzer, Node);
  if InnerCount > 1 then
    ErrorNode(Analyzer, Node, dcInvalidControlFlow,
      'a class body may contain at most one inner statement');
  Child := Analyzer.Tree^.Nodes[Node].FirstChild;
  while Child >= 0 do
  begin
    AnalyzeNode(Analyzer, Child);
    Child := Analyzer.Tree^.Nodes[Child].NextSibling;
  end;
  Analyzer.CurrentClass := SavedClass;
  Analyzer.CurrentScope := SavedScope;
end;

procedure AnalyzeIf(var Analyzer: TSemanticAnalyzer; Node: Int32);
var
  ConditionNode, ThenNode, ElseNode: Int32;
  SavedReachable, ThenReachable, ElseReachable: Boolean;
begin
  ConditionNode := ChildAt(Analyzer, Node, 0);
  ThenNode := ChildAt(Analyzer, Node, 1);
  ElseNode := ChildAt(Analyzer, Node, 2);
  AnalyzeCondition(Analyzer, ConditionNode);
  SavedReachable := Analyzer.Reachable;
  AnalyzeNode(Analyzer, ThenNode);
  ThenReachable := Analyzer.Reachable;
  Analyzer.Reachable := SavedReachable;
  if ElseNode >= 0 then
  begin
    AnalyzeNode(Analyzer, ElseNode);
    ElseReachable := Analyzer.Reachable;
  end
  else
    ElseReachable := SavedReachable;
  Analyzer.Reachable := ThenReachable or ElseReachable;
end;

procedure AnalyzeFor(var Analyzer: TSemanticAnalyzer; Node: Int32);
var
  VariableNode, ElementNode, ValueNode, StepNode, UntilNode,
  ConditionNode, BodyNode, VariableType, ValueType, StepType,
  UntilType: Int32;
  IsReferenceFor: Boolean;
begin
  VariableNode := ChildAt(Analyzer, Node, 0);
  if (VariableNode < 0) or (VariableNode > High(Analyzer.Tree^.Nodes)) then
  begin
    ErrorNode(Analyzer, Node, dcInvalidAssignment,
      'for statement is missing its controlled quantity');
    Exit;
  end;
  VariableType := AnalyzeExpression(Analyzer, VariableNode);
  if not (nfLValue in Analyzer.Tree^.Nodes[VariableNode].Flags) then
    ErrorNode(Analyzer, Node, dcInvalidAssignment,
      'for controlled quantity must be an assignable simple variable');
  IsReferenceFor := Analyzer.Tree^.Nodes[Node].Aux <> 0;
  ElementNode := Analyzer.Tree^.Nodes[VariableNode].NextSibling;
  BodyNode := Analyzer.Tree^.Nodes[Node].BodyNode;
  while (ElementNode >= 0) and (ElementNode <> BodyNode) do
  begin
    ValueNode := ChildAt(Analyzer, ElementNode, 0);
    ValueType := AnalyzeExpression(Analyzer, ValueNode);
    if not SymCanAssign(Analyzer.Symbols^, VariableType, ValueType,
      IsReferenceFor) then
      ErrorNode(Analyzer, ValueNode, dcTypeMismatch,
        'for-list value of type ' + TypeName(Analyzer.Symbols^, ValueType) +
        ' cannot be assigned to ' + TypeName(Analyzer.Symbols^, VariableType));
    case Analyzer.Tree^.Nodes[ElementNode].Kind of
      nkForStepUntilElement:
        begin
          if IsReferenceFor then
            ErrorNode(Analyzer, ElementNode, dcTypeMismatch,
              'reference for-lists do not permit step-until elements');
          StepNode := ChildAt(Analyzer, ElementNode, 1);
          UntilNode := ChildAt(Analyzer, ElementNode, 2);
          StepType := AnalyzeExpression(Analyzer, StepNode);
          UntilType := AnalyzeExpression(Analyzer, UntilNode);
          if not IsNumericType(Analyzer, VariableType) or
             not IsNumericType(Analyzer, ValueType) or
             not IsNumericType(Analyzer, StepType) or
             not IsNumericType(Analyzer, UntilType) then
            ErrorNode(Analyzer, ElementNode, dcTypeMismatch,
              'step-until for-list elements require arithmetic operands');
        end;
      nkForWhileElement:
        begin
          ConditionNode := ChildAt(Analyzer, ElementNode, 1);
          AnalyzeCondition(Analyzer, ConditionNode);
        end;
      nkForValueElement:
        ;
    else
      ErrorNode(Analyzer, ElementNode, dcInternalError,
        'invalid for-list element');
    end;
    ElementNode := Analyzer.Tree^.Nodes[ElementNode].NextSibling;
  end;
  if (BodyNode < 0) or (BodyNode > High(Analyzer.Tree^.Nodes)) then
  begin
    ErrorNode(Analyzer, Node, dcExpectedToken,
      'for statement is missing its controlled statement');
    Exit;
  end;
  Inc(Analyzer.LoopDepth);
  AnalyzeNode(Analyzer, BodyNode);
  Dec(Analyzer.LoopDepth);
  Analyzer.Reachable := True;
end;

procedure AnalyzeLoop(var Analyzer: TSemanticAnalyzer; Node: Int32;
  IsForLoop: Boolean);
begin
  if IsForLoop then
    AnalyzeFor(Analyzer, Node)
  else
  begin
    Inc(Analyzer.LoopDepth);
    AnalyzeCondition(Analyzer, ChildAt(Analyzer, Node, 0));
    AnalyzeNode(Analyzer, ChildAt(Analyzer, Node, 1));
    Dec(Analyzer.LoopDepth);
    Analyzer.Reachable := True;
  end;
end;

procedure AnalyzeTry(var Analyzer: TSemanticAnalyzer; Node: Int32);
var
  Child: Int32;
begin
  Inc(Analyzer.TryDepth);
  Child := Analyzer.Tree^.Nodes[Node].FirstChild;
  while Child >= 0 do
  begin
    AnalyzeNode(Analyzer, Child);
    Analyzer.Reachable := True;
    Child := Analyzer.Tree^.Nodes[Child].NextSibling;
  end;
  Dec(Analyzer.TryDepth);
end;

procedure AnalyzeVariableDeclaration(var Analyzer: TSemanticAnalyzer;
  Node: Int32);
var
  Initializer, InitializerType, DeclaredType: Int32;
begin
  DeclaredType := Analyzer.Tree^.Nodes[Node].TypeId;
  if IsIncompleteCRecord(Analyzer, DeclaredType) then
    ErrorNode(Analyzer, Node, dcTypeMismatch,
      'opaque C records have no local storage; use c_ptr(' +
      TypeName(Analyzer.Symbols^, DeclaredType) + ')');
  Initializer := ChildAt(Analyzer, Node, 0);
  if Initializer < 0 then Exit;
  if (DeclaredType >= 0) and
     (DeclaredType <= High(Analyzer.Symbols^.Types)) and
     (Analyzer.Symbols^.Types[DeclaredType].Kind = tyArray) and
     (tfRuntimeBound in Analyzer.Symbols^.Types[DeclaredType].Flags) then
  begin
    InitializerType := AnalyzeExpression(Analyzer, Initializer);
    if not IsIntegerType(Analyzer, InitializerType) then
      ErrorNode(Analyzer, Initializer, dcTypeMismatch,
        'array lower bound must be integer');
    Initializer := ChildAt(Analyzer, Node, 1);
    InitializerType := AnalyzeExpression(Analyzer, Initializer);
    if not IsIntegerType(Analyzer, InitializerType) then
      ErrorNode(Analyzer, Initializer, dcTypeMismatch,
        'array upper bound must be integer');
    Exit;
  end;
  if (DeclaredType >= 0) and (DeclaredType <= High(Analyzer.Symbols^.Types)) and
     (Analyzer.Symbols^.Types[DeclaredType].Kind = tyProcedure) then
    Inc(Analyzer.NoImplicitCall);
  InitializerType := AnalyzeExpression(Analyzer, Initializer);
  if (DeclaredType >= 0) and (DeclaredType <= High(Analyzer.Symbols^.Types)) and
     (Analyzer.Symbols^.Types[DeclaredType].Kind = tyProcedure) then
    Dec(Analyzer.NoImplicitCall);
  if not SymCanAssign(Analyzer.Symbols^, DeclaredType,
    InitializerType, False) then
    ErrorNode(Analyzer, Initializer, dcTypeMismatch,
      'initializer type ' + TypeName(Analyzer.Symbols^, InitializerType) +
      ' is not assignable to variable type ' +
      TypeName(Analyzer.Symbols^, DeclaredType));
end;

procedure AnalyzeConstant(var Analyzer: TSemanticAnalyzer; Node: Int32);
var
  Initializer, InitializerType, DeclaredType, SymbolId: Int32;
begin
  Initializer := ChildAt(Analyzer, Node, 0);
  if Initializer < 0 then
    Exit;
  DeclaredType := Analyzer.Tree^.Nodes[Node].TypeId;
  if (DeclaredType >= 0) and (DeclaredType <= High(Analyzer.Symbols^.Types)) and
     (Analyzer.Symbols^.Types[DeclaredType].Kind = tyProcedure) then
    Inc(Analyzer.NoImplicitCall);
  InitializerType := AnalyzeExpression(Analyzer, Initializer);
  if (DeclaredType >= 0) and (DeclaredType <= High(Analyzer.Symbols^.Types)) and
     (Analyzer.Symbols^.Types[DeclaredType].Kind = tyProcedure) then
    Dec(Analyzer.NoImplicitCall);
  SymbolId := Analyzer.Tree^.Nodes[Node].SymbolId;
  if DeclaredType = FSIM_TYPE_INVALID then
  begin
    DeclaredType := InitializerType;
    Analyzer.Tree^.Nodes[Node].TypeId := DeclaredType;
    if SymbolId >= 0 then
      Analyzer.Symbols^.Symbols[SymbolId].TypeId := DeclaredType;
  end
  else if not SymCanAssign(Analyzer.Symbols^, DeclaredType,
    InitializerType, False) then
    ErrorNode(Analyzer, Initializer, dcTypeMismatch,
      'constant initializer type ' + TypeName(Analyzer.Symbols^,
      InitializerType) + ' is not assignable to ' +
      TypeName(Analyzer.Symbols^, DeclaredType));
end;

function AnalyzeDesignationalExpression(var Analyzer: TSemanticAnalyzer;
  Node, RootSwitch, Depth: Int32): Boolean;
var
  CalleeNode, ArgumentNode, SymbolId, ArgumentType, ArgumentCount,
  ConditionNode, ThenNode, ElseNode: Int32;
  Name: RawByteString;
begin
  Result := False;
  if (Node < 0) or (Node > High(Analyzer.Tree^.Nodes)) then
  begin
    ErrorNode(Analyzer, RootSwitch, dcExpectedToken,
      'missing designational expression');
    Exit;
  end;
  if Depth > 64 then
  begin
    ErrorNode(Analyzer, Node, dcInvalidControlFlow,
      'switch designator nesting exceeds 64 levels');
    Exit;
  end;
  case Analyzer.Tree^.Nodes[Node].Kind of
    nkIdentifierExpr:
      begin
        Name := NodeName(Analyzer, Node);
        SymbolId := SymLookup(Analyzer.Symbols^, Name, Analyzer.CurrentScope);
        if SymbolId < 0 then
          ErrorNode(Analyzer, Node, dcUnknownSymbol,
            'unknown designational identifier ' + Name)
        else if Analyzer.Symbols^.Symbols[SymbolId].Kind <> skLabel then
          ErrorNode(Analyzer, Node, dcTypeMismatch,
            'designational identifier ' + Name + ' is not a label')
        else
        begin
          Analyzer.Tree^.Nodes[Node].SymbolId := SymbolId;
          Analyzer.Tree^.Nodes[Node].TypeId := FSIM_TYPE_INTEGER;
          Include(Analyzer.Symbols^.Symbols[SymbolId].Flags, sfReferenced);
          Result := True;
        end;
      end;
    nkCallExpr:
      begin
        CalleeNode := ChildAt(Analyzer, Node, 0);
        if (CalleeNode < 0) or
           (Analyzer.Tree^.Nodes[CalleeNode].Kind <> nkIdentifierExpr) then
        begin
          ErrorNode(Analyzer, Node, dcInvalidCall,
            'switch designator must name a declared switch');
          Exit;
        end;
        Name := NodeName(Analyzer, CalleeNode);
        SymbolId := SymLookup(Analyzer.Symbols^, Name, Analyzer.CurrentScope);
        if (SymbolId < 0) or
           (Analyzer.Symbols^.Symbols[SymbolId].Kind <> skSwitch) then
        begin
          ErrorNode(Analyzer, CalleeNode, dcTypeMismatch,
            'designator ' + Name + ' is not a switch');
          Exit;
        end;
        if SymbolId = RootSwitch then
        begin
          ErrorNode(Analyzer, Node, dcInvalidControlFlow,
            'switch declaration recursively references itself');
          Exit;
        end;
        Analyzer.Tree^.Nodes[CalleeNode].SymbolId := SymbolId;
        Analyzer.Tree^.Nodes[Node].SymbolId := SymbolId;
        Include(Analyzer.Symbols^.Symbols[SymbolId].Flags, sfReferenced);
        ArgumentNode := Analyzer.Tree^.Nodes[CalleeNode].NextSibling;
        ArgumentCount := 0;
        while ArgumentNode >= 0 do
        begin
          ArgumentType := AnalyzeExpression(Analyzer, ArgumentNode);
          if not IsIntegerType(Analyzer, ArgumentType) then
            ErrorNode(Analyzer, ArgumentNode, dcTypeMismatch,
              'switch subscript must be an integer');
          Inc(ArgumentCount);
          ArgumentNode := Analyzer.Tree^.Nodes[ArgumentNode].NextSibling;
        end;
        if ArgumentCount <> 1 then
          ErrorNode(Analyzer, Node, dcInvalidCall,
            'switch designator requires exactly one subscript')
        else
          Result := True;
        Analyzer.Tree^.Nodes[Node].TypeId := FSIM_TYPE_INTEGER;
      end;
    nkConditionalExpr:
      begin
        ConditionNode := ChildAt(Analyzer, Node, 0);
        ThenNode := ChildAt(Analyzer, Node, 1);
        ElseNode := ChildAt(Analyzer, Node, 2);
        AnalyzeCondition(Analyzer, ConditionNode);
        Result := AnalyzeDesignationalExpression(Analyzer, ThenNode,
          RootSwitch, Depth + 1);
        if not AnalyzeDesignationalExpression(Analyzer, ElseNode,
          RootSwitch, Depth + 1) then
          Result := False;
        Analyzer.Tree^.Nodes[Node].TypeId := FSIM_TYPE_INTEGER;
      end;
  else
    ErrorNode(Analyzer, Node, dcTypeMismatch,
      'expression is not a label, switch designator, or conditional designator');
  end;
end;

procedure AnalyzeGoto(var Analyzer: TSemanticAnalyzer; Node: Int32);
var
  TargetNode: Int32;
begin
  TargetNode := ChildAt(Analyzer, Node, 0);
  AnalyzeDesignationalExpression(Analyzer, TargetNode,
    FSIM_INVALID_INDEX, 0);
  Analyzer.Reachable := False;
end;

procedure AnalyzeLabel(var Analyzer: TSemanticAnalyzer; Node: Int32);
var
  Child: Int32;
begin
  Analyzer.Reachable := True;
  Child := ChildAt(Analyzer, Node, 0);
  if Child >= 0 then AnalyzeNode(Analyzer, Child);
end;

procedure AnalyzeInspect(var Analyzer: TSemanticAnalyzer; Node: Int32);
var
  SubjectNode, SubjectType, Clause, ClassSymbol, Body: Int32;
  Name: RawByteString;
begin
  SubjectNode := ChildAt(Analyzer, Node, 0);
  SubjectType := AnalyzeExpression(Analyzer, SubjectNode);
  if not IsReferenceType(Analyzer, SubjectType) then
    ErrorNode(Analyzer, SubjectNode, dcTypeMismatch,
      'inspect requires an object reference');
  Clause := Analyzer.Tree^.Nodes[SubjectNode].NextSibling;
  while Clause >= 0 do
  begin
    Name := NodeName(Analyzer, Clause);
    if Name <> 'otherwise' then
    begin
      ClassSymbol := SymLookupClass(Analyzer.Symbols^, Name);
      if ClassSymbol < 0 then
        ErrorNode(Analyzer, Clause, dcUnknownType,
          'unknown class ''' + Name + ''' in when clause')
      else
        Analyzer.Tree^.Nodes[Clause].SymbolId := ClassSymbol;
    end;
    Body := ChildAt(Analyzer, Clause, 0);
    if Body >= 0 then AnalyzeNode(Analyzer, Body);
    Analyzer.Reachable := True;
    Clause := Analyzer.Tree^.Nodes[Clause].NextSibling;
  end;
end;

procedure AnalyzeActivation(var Analyzer: TSemanticAnalyzer; Node: Int32);
var
  Child, TypeId: Int32;
begin
  Child := ChildAt(Analyzer, Node, 0);
  TypeId := AnalyzeExpression(Analyzer, Child);
  if not IsReferenceType(Analyzer, TypeId) then
    ErrorNode(Analyzer, Child, dcTypeMismatch,
      'activation target must be a process reference');
  Child := ChildAt(Analyzer, Node, 1);
  if Child >= 0 then
  begin
    TypeId := AnalyzeExpression(Analyzer, Child);
    if not IsNumericType(Analyzer, TypeId) and
       not IsReferenceType(Analyzer, TypeId) then
      ErrorNode(Analyzer, Child, dcTypeMismatch,
        'activation clause requires a time or process reference');
  end;
end;

procedure AnalyzeRepeat(var Analyzer: TSemanticAnalyzer; Node: Int32);
begin
  Inc(Analyzer.LoopDepth);
  AnalyzeNode(Analyzer, ChildAt(Analyzer, Node, 0));
  AnalyzeCondition(Analyzer, ChildAt(Analyzer, Node, 1));
  Dec(Analyzer.LoopDepth);
  Analyzer.Reachable := True;
end;

procedure AnalyzeCase(var Analyzer: TSemanticAnalyzer; Node: Int32);
var
  Selector, SelectorType, Clause, Child, Body: Int32;
begin
  Selector := ChildAt(Analyzer, Node, 0);
  SelectorType := AnalyzeExpression(Analyzer, Selector);
  Clause := Analyzer.Tree^.Nodes[Selector].NextSibling;
  while Clause >= 0 do
  begin
    Child := Analyzer.Tree^.Nodes[Clause].FirstChild;
    Body := Analyzer.Tree^.Nodes[Clause].BodyNode;
    while Child >= 0 do
    begin
      if Child = Body then
        AnalyzeNode(Analyzer, Child)
      else if not SymCanAssign(Analyzer.Symbols^, SelectorType,
        AnalyzeExpression(Analyzer, Child), False) then
        ErrorNode(Analyzer, Child, dcTypeMismatch,
          'case label type does not match selector');
      Child := Analyzer.Tree^.Nodes[Child].NextSibling;
    end;
    Analyzer.Reachable := True;
    Clause := Analyzer.Tree^.Nodes[Clause].NextSibling;
  end;
end;


function AnalyzeSpawnOperand(var Analyzer: TSemanticAnalyzer;
  SpawnNode: Int32): Int32;
var
  OperandNode, CalleeNode, ArgumentNode, ArgumentCount: Int32;
begin
  OperandNode := ChildAt(Analyzer, SpawnNode, 0);
  Result := AnalyzeExpression(Analyzer, OperandNode);
  if OperandNode < 0 then
  begin
    ErrorNode(Analyzer, SpawnNode, dcInvalidCall,
      'spawn requires a procedure or function call');
    Exit;
  end;
  if Analyzer.Tree^.Nodes[OperandNode].Kind <> nkCallExpr then
  begin
    ErrorNode(Analyzer, OperandNode, dcInvalidCall,
      'spawn operand must be a procedure or function call');
    Exit;
  end;
  CalleeNode := ChildAt(Analyzer, OperandNode, 0);
  if (CalleeNode < 0) or
     (Analyzer.Tree^.Nodes[CalleeNode].SymbolId < 0) then
  begin
    ErrorNode(Analyzer, OperandNode, dcInvalidCall,
      'spawn entry routine could not be resolved');
    Exit;
  end;
  ArgumentCount := 0;
  ArgumentNode := Analyzer.Tree^.Nodes[CalleeNode].NextSibling;
  while ArgumentNode >= 0 do
  begin
    Inc(ArgumentCount);
    ArgumentNode := Analyzer.Tree^.Nodes[ArgumentNode].NextSibling;
  end;
  if Analyzer.Tree^.Nodes[CalleeNode].Kind = nkMemberExpr then
  begin
    if ArgumentCount <> 0 then
      ErrorNode(Analyzer, OperandNode, dcInvalidCall,
        'spawned methods currently accept only their object receiver');
  end
  else if ArgumentCount > 1 then
    ErrorNode(Analyzer, OperandNode, dcInvalidCall,
      'spawned routines currently accept at most one native-word argument');
end;

procedure AnalyzeFutureOperation(var Analyzer: TSemanticAnalyzer;
  Node: Int32; const OperationName: RawByteString);
var
  OperandNode, TypeId: Int32;
begin
  if Analyzer.Options^.Dialect = fdSimula67 then
    ErrorNode(Analyzer, Node, dcDialectViolation,
      OperationName + ' is unavailable in simula67 mode');
  OperandNode := ChildAt(Analyzer, Node, 0);
  TypeId := AnalyzeExpression(Analyzer, OperandNode);
  if (TypeId < 0) or (TypeId > High(Analyzer.Symbols^.Types)) or
     not ((Analyzer.Symbols^.Types[TypeId].Kind = tyFuture) or
       IsIntegerType(Analyzer, TypeId)) then
    ErrorNode(Analyzer, OperandNode, dcTypeMismatch,
      OperationName + ' requires a future or native task handle');
end;

procedure AnalyzeHandleOperation(var Analyzer: TSemanticAnalyzer;
  Node: Int32; RequiredKind: TTypeKind; const OperationName: RawByteString);
var
  OperandNode, TypeId: Int32;
begin
  if Analyzer.Options^.Dialect = fdSimula67 then
    ErrorNode(Analyzer, Node, dcDialectViolation,
      OperationName + ' is unavailable in simula67 mode');
  OperandNode := ChildAt(Analyzer, Node, 0);
  TypeId := AnalyzeExpression(Analyzer, OperandNode);
  if (TypeId < 0) or (TypeId > High(Analyzer.Symbols^.Types)) or
     (Analyzer.Symbols^.Types[TypeId].Kind <> RequiredKind) then
    ErrorNode(Analyzer, OperandNode, dcTypeMismatch,
      OperationName + ' requires ' + TypeName(Analyzer.Symbols^, TypeId));
end;

procedure AnalyzeModernOperation(var Analyzer: TSemanticAnalyzer;
  Node: Int32; RequireReference, RequireInteger: Boolean);
var
  Child, TypeId: Int32;
begin
  if Analyzer.Options^.Dialect = fdSimula67 then
    ErrorNode(Analyzer, Node, dcDialectViolation,
      ASTKindName(Analyzer.Tree^.Nodes[Node].Kind) +
      ' is unavailable in simula67 mode');
  Child := ChildAt(Analyzer, Node, 0);
  if Child >= 0 then
  begin
    TypeId := AnalyzeExpression(Analyzer, Child);
    if RequireReference and not IsReferenceType(Analyzer, TypeId) and
       not IsIntegerType(Analyzer, TypeId) then
      ErrorNode(Analyzer, Child, dcTypeMismatch,
        'operation requires a reference or native handle');
    if RequireInteger and not IsIntegerType(Analyzer, TypeId) then
      ErrorNode(Analyzer, Child, dcTypeMismatch,
        'operation requires an integer-compatible operand');
  end;
end;

procedure AnalyzeSend(var Analyzer: TSemanticAnalyzer; Node: Int32);
var
  ChannelNode, PayloadNode, ChannelType, PayloadType, ElementType: Int32;
begin
  if Analyzer.Options^.Dialect = fdSimula67 then
    ErrorNode(Analyzer, Node, dcDialectViolation,
      'channel send is unavailable in simula67 mode');
  ChannelNode := ChildAt(Analyzer, Node, 0);
  PayloadNode := ChildAt(Analyzer, Node, 1);
  ChannelType := AnalyzeExpression(Analyzer, ChannelNode);
  PayloadType := AnalyzeExpression(Analyzer, PayloadNode);
  if (ChannelType < 0) or (ChannelType > High(Analyzer.Symbols^.Types)) or
     (Analyzer.Symbols^.Types[ChannelType].Kind <> tyChannel) then
    ErrorNode(Analyzer, ChannelNode, dcTypeMismatch,
      'send requires a channel as its first operand')
  else
  begin
    ElementType := Analyzer.Symbols^.Types[ChannelType].ElementType;
    if not SymCanAssign(Analyzer.Symbols^, ElementType, PayloadType, False) then
      ErrorNode(Analyzer, PayloadNode, dcTypeMismatch,
        'channel payload type ' + TypeName(Analyzer.Symbols^, PayloadType) +
        ' is not assignable to ' + TypeName(Analyzer.Symbols^, ElementType));
  end;
end;

procedure AnalyzeWrapped(var Analyzer: TSemanticAnalyzer; Node: Int32);
begin
  if Analyzer.Options^.Dialect = fdSimula67 then
    ErrorNode(Analyzer, Node, dcDialectViolation,
      ASTKindName(Analyzer.Tree^.Nodes[Node].Kind) +
      ' is unavailable in simula67 mode');
  AnalyzeNode(Analyzer, ChildAt(Analyzer, Node, 0));
end;

procedure AnalyzeSwitchDeclaration(var Analyzer: TSemanticAnalyzer;
  Node: Int32);
var
  Child, RootSwitch: Int32;
begin
  RootSwitch := Analyzer.Tree^.Nodes[Node].SymbolId;
  Child := Analyzer.Tree^.Nodes[Node].FirstChild;
  while Child >= 0 do
  begin
    AnalyzeDesignationalExpression(Analyzer, Child, RootSwitch, 0);
    Child := Analyzer.Tree^.Nodes[Child].NextSibling;
  end;
end;

procedure AnalyzeNode(var Analyzer: TSemanticAnalyzer; Node: Int32);
var
  Child, TypeId: Int32;
begin
  if Node < 0 then
    Exit;
  case Analyzer.Tree^.Nodes[Node].Kind of
    nkCompilationUnit:
      begin
        Child := Analyzer.Tree^.Nodes[Node].FirstChild;
        while Child >= 0 do
        begin
          AnalyzeNode(Analyzer, Child);
          Child := Analyzer.Tree^.Nodes[Child].NextSibling;
        end;
      end;
    nkProgramDecl, nkProcedureDecl, nkFunctionDecl:
      AnalyzeRoutine(Analyzer, Node);
    nkClassDecl, nkProcessClassDecl, nkThreadClassDecl:
      AnalyzeClass(Analyzer, Node);
    nkBlock, nkBlockStatement, nkStatementList:
      AnalyzeBlock(Analyzer, Node);
    nkVirtualSection, nkVisibilitySection,
    nkParameterDecl, nkVirtualSpec, nkTypeDecl, nkLabelDecl, nkEmptyStatement:
      ;
    nkVariableDecl:
      AnalyzeVariableDeclaration(Analyzer, Node);
    nkConstantDecl:
      AnalyzeConstant(Analyzer, Node);
    nkSwitchDecl:
      AnalyzeSwitchDeclaration(Analyzer, Node);
    nkAssignmentStatement:
      AnalyzeAssignment(Analyzer, Node, False);
    nkReferenceAssignmentStatement:
      AnalyzeAssignment(Analyzer, Node, True);
    nkIfStatement:
      AnalyzeIf(Analyzer, Node);
    nkWhileStatement:
      AnalyzeLoop(Analyzer, Node, False);
    nkForStatement:
      AnalyzeLoop(Analyzer, Node, True);
    nkRepeatStatement:
      AnalyzeRepeat(Analyzer, Node);
    nkGotoStatement:
      AnalyzeGoto(Analyzer, Node);
    nkLabelStatement:
      AnalyzeLabel(Analyzer, Node);
    nkInspectStatement:
      AnalyzeInspect(Analyzer, Node);
    nkCaseStatement:
      AnalyzeCase(Analyzer, Node);
    nkWithStatement:
      begin
        AnalyzeExpression(Analyzer, ChildAt(Analyzer, Node, 0));
        AnalyzeNode(Analyzer, ChildAt(Analyzer, Node, 1));
      end;
    nkTryStatement:
      AnalyzeTry(Analyzer, Node);
    nkCatchClause, nkFinallyClause:
      begin
        Child := Analyzer.Tree^.Nodes[Node].FirstChild;
        while Child >= 0 do
        begin
          AnalyzeNode(Analyzer, Child);
          Child := Analyzer.Tree^.Nodes[Child].NextSibling;
        end;
      end;
    nkRaiseStatement:
      begin
        Child := ChildAt(Analyzer, Node, 0);
        TypeId := AnalyzeExpression(Analyzer, Child);
        if not IsReferenceType(Analyzer, TypeId) then
          ErrorNode(Analyzer, Node, dcTypeMismatch,
            'raised value must be an exception reference');
        if (Analyzer.TryDepth = 0) and
           (Analyzer.CurrentRoutine >= 0) and
           (Analyzer.CurrentRoutine <= High(Analyzer.Symbols^.Symbols)) then
          Include(Analyzer.Symbols^.Symbols[Analyzer.CurrentRoutine].Flags,
            sfRuntimeRequired);
        Analyzer.Reachable := False;
      end;
    nkReturnStatement:
      AnalyzeReturn(Analyzer, Node);
    nkExitStatement:
      begin
        Child := ChildAt(Analyzer, Node, 0);
        if Child >= 0 then
        begin
          TypeId := AnalyzeExpression(Analyzer, Child);
          if not IsIntegerType(Analyzer, TypeId) then
            ErrorNode(Analyzer, Child, dcTypeMismatch,
              'exit status must be an integer');
        end;
        Analyzer.Reachable := False;
      end;
    nkBreakStatement:
      begin
        if Analyzer.LoopDepth = 0 then
          ErrorNode(Analyzer, Node, dcInvalidControlFlow,
            'break is not inside a loop');
        Analyzer.Reachable := False;
      end;
    nkContinueStatement:
      begin
        if Analyzer.LoopDepth = 0 then
          ErrorNode(Analyzer, Node, dcInvalidControlFlow,
            'continue is not inside a loop');
        Analyzer.Reachable := False;
      end;
    nkAssertStatement:
      AnalyzeCondition(Analyzer, ChildAt(Analyzer, Node, 0));
    nkOutputStatement:
      AnalyzeOutput(Analyzer, Node);
    nkExpressionStatement:
      AnalyzeExpression(Analyzer, ChildAt(Analyzer, Node, 0));
    nkDetachStatement, nkPassivateStatement:
      begin
        if Analyzer.CurrentClass < 0 then
          ErrorNode(Analyzer, Node, dcInvalidControlFlow,
            'process operation requires a process-class context');
      end;
    nkResumeStatement:
      begin
        TypeId := AnalyzeExpression(Analyzer, ChildAt(Analyzer, Node, 0));
        if not IsReferenceType(Analyzer, TypeId) then
          ErrorNode(Analyzer, Node, dcTypeMismatch,
            'process operation requires a process reference');
      end;
    nkActivateStatement, nkReactivateStatement:
      AnalyzeActivation(Analyzer, Node);
    nkCancelStatement:
      AnalyzeFutureOperation(Analyzer, Node, 'cancel');
    nkJoinStatement:
      AnalyzeFutureOperation(Analyzer, Node, 'join');
    nkReceiveStatement:
      AnalyzeHandleOperation(Analyzer, Node, tyChannel, 'receive');
    nkLockStatement:
      AnalyzeHandleOperation(Analyzer, Node, tyMutex, 'lock');
    nkUnlockStatement:
      AnalyzeHandleOperation(Analyzer, Node, tyMutex, 'unlock');
    nkSpawnStatement:
      begin
        if Analyzer.Options^.Dialect = fdSimula67 then
          ErrorNode(Analyzer, Node, dcDialectViolation,
            'spawn is unavailable in simula67 mode');
        AnalyzeSpawnOperand(Analyzer, Node);
      end;
    nkYieldStatement:
      AnalyzeModernOperation(Analyzer, Node, False, False);
    nkSendStatement:
      AnalyzeSend(Analyzer, Node);
    nkParallelStatement, nkCriticalStatement, nkDeferStatement:
      AnalyzeWrapped(Analyzer, Node);
    nkInnerStatement:
      begin
        if Analyzer.CurrentClass < 0 then
          ErrorNode(Analyzer, Node, dcInvalidControlFlow,
            'inner is only valid inside a prefixed class');
      end;
    nkDelayStatement, nkHoldStatement:
      begin
        TypeId := AnalyzeExpression(Analyzer, ChildAt(Analyzer, Node, 0));
        if not IsNumericType(Analyzer, TypeId) then
          ErrorNode(Analyzer, Node, dcTypeMismatch,
            'delay duration must be numeric');
      end;
  else
    AnalyzeExpression(Analyzer, Node);
  end;
end;

procedure VerifyInheritance(var Analyzer: TSemanticAnalyzer);
var
  I, Child, Parent, Guard: Integer;
begin
  for I := 0 to High(Analyzer.Symbols^.Classes) do
  begin
    Child := Analyzer.Symbols^.Classes[I].SymbolId;
    Parent := Analyzer.Symbols^.Classes[I].PrefixClass;
    Guard := 0;
    while Parent >= 0 do
    begin
      if Parent = Child then
      begin
        AddError(Analyzer.Diagnostics^, dcInheritanceCycle,
          Analyzer.Symbols^.Symbols[Child].SourceSpan,
          'inheritance cycle contains class ''' +
          SymName(Analyzer.Symbols^, Child) + '''');
        Break;
      end;
      Parent := Analyzer.Symbols^.Symbols[Parent].PrefixClass;
      Inc(Guard);
      if Guard > Length(Analyzer.Symbols^.Symbols) then
      begin
        AddError(Analyzer.Diagnostics^, dcInheritanceCycle,
          Analyzer.Symbols^.Symbols[Child].SourceSpan,
          'inheritance chain is cyclic');
        Break;
      end;
    end;
  end;
end;

procedure VerifyVirtualMethods(var Analyzer: TSemanticAnalyzer);
var
  I, J, SymbolId, Owner, ImplementationSymbol: Integer;
  Name: RawByteString;
begin
  for I := 0 to High(Analyzer.Symbols^.Symbols) do
    if Analyzer.Symbols^.Symbols[I].Kind = skVirtualSpec then
    begin
      SymbolId := I;
      Owner := Analyzer.Symbols^.Symbols[SymbolId].OwnerSymbol;
      Name := SymName(Analyzer.Symbols^, SymbolId);
      ImplementationSymbol := FSIM_INVALID_INDEX;
      for J := 0 to High(Analyzer.Symbols^.Symbols) do
        if (J <> SymbolId) and
           (Analyzer.Symbols^.Symbols[J].OwnerSymbol = Owner) and
           (Analyzer.Symbols^.Symbols[J].Kind in [skProcedure, skFunction]) and
           ASCIIEqualFold(SymName(Analyzer.Symbols^, J), Name) then
        begin
          ImplementationSymbol := J;
          Break;
        end;
      if ImplementationSymbol >= 0 then
      begin
        if not SymTypeEqual(Analyzer.Symbols^,
          Analyzer.Symbols^.Symbols[SymbolId].TypeId,
          Analyzer.Symbols^.Symbols[ImplementationSymbol].TypeId) then
          AddError(Analyzer.Diagnostics^, dcVirtualMismatch,
            Analyzer.Symbols^.Symbols[ImplementationSymbol].SourceSpan,
            'implementation of virtual method ''' + Name +
            ''' has a different signature');
      end;
    end;
end;

procedure SemanticInit(var Analyzer: TSemanticAnalyzer; var Tree: TAST;
  var Symbols: TSymbolTable; var Diagnostics: TDiagnosticBag;
  var Options: TCompilerOptions);
begin
  Analyzer := Default(TSemanticAnalyzer);
  Analyzer.Tree := @Tree;
  Analyzer.Symbols := @Symbols;
  Analyzer.Diagnostics := @Diagnostics;
  Analyzer.Options := @Options;
  Analyzer.CurrentScope := 0;
  Analyzer.CurrentClass := FSIM_INVALID_INDEX;
  Analyzer.CurrentRoutine := FSIM_INVALID_INDEX;
  Analyzer.Reachable := True;
end;

procedure AnalyzeCompilationUnit(var Analyzer: TSemanticAnalyzer);
begin
  VerifyInheritance(Analyzer);
  AnalyzeNode(Analyzer, Analyzer.Tree^.Root);
  VerifyVirtualMethods(Analyzer);
  SymVerify(Analyzer.Symbols^);
end;

end.

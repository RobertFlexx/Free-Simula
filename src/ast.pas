unit ast;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, core;

type
  TASTNodeKind = (
    nkInvalid,
    nkCompilationUnit,
    nkModuleDecl,
    nkImportDecl,
    nkProgramDecl,
    nkBlock,
    nkClassDecl,
    nkProcessClassDecl,
    nkThreadClassDecl,
    nkVirtualSection,
    nkVirtualSpec,
    nkProcedureDecl,
    nkFunctionDecl,
    nkParameterDecl,
    nkVariableDecl,
    nkConstantDecl,
    nkSwitchDecl,
    nkLabelDecl,
    nkTypeDecl,
    nkArrayType,
    nkReferenceType,
    nkVisibilitySection,
    nkStatementList,
    nkEmptyStatement,
    nkBlockStatement,
    nkAssignmentStatement,
    nkReferenceAssignmentStatement,
    nkIfStatement,
    nkWhileStatement,
    nkForStatement,
    nkForValueElement,
    nkForStepUntilElement,
    nkForWhileElement,
    nkGotoStatement,
    nkLabelStatement,
    nkInspectStatement,
    nkWhenClause,
    nkTryStatement,
    nkCatchClause,
    nkFinallyClause,
    nkRaiseStatement,
    nkReturnStatement,
    nkExitStatement,
    nkBreakStatement,
    nkContinueStatement,
    nkAssertStatement,
    nkDetachStatement,
    nkCallStatement,
    nkResumeStatement,
    nkActivateStatement,
    nkReactivateStatement,
    nkDelayStatement,
    nkHoldStatement,
    nkPassivateStatement,
    nkCancelStatement,
    nkInnerStatement,
    nkSpawnStatement,
    nkJoinStatement,
    nkYieldStatement,
    nkSendStatement,
    nkReceiveStatement,
    nkLockStatement,
    nkUnlockStatement,
    nkParallelStatement,
    nkCriticalStatement,
    nkDeferStatement,
    nkRepeatStatement,
    nkCaseStatement,
    nkCaseClause,
    nkWithStatement,
    nkOutputStatement,
    nkInputStatement,
    nkExpressionStatement,
    nkLambdaExpr,
    nkIdentifierExpr,
    nkIntegerLiteralExpr,
    nkRealLiteralExpr,
    nkBooleanLiteralExpr,
    nkCharacterLiteralExpr,
    nkStringLiteralExpr,
    nkNoneExpr,
    nkThisExpr,
    nkNewExpr,
    nkUnaryExpr,
    nkBinaryExpr,
    nkCallExpr,
    nkMemberExpr,
    nkIndexExpr,
    nkQuaExpr,
    nkObjectTestExpr,
    nkAwaitExpr,
    nkReceiveExpr,
    nkSpawnExpr,
    nkConditionalExpr,
    nkConversionExpr,
    nkSizeOfExpr,
    nkTypeOfExpr,
    nkArrayLiteralExpr
  );

  TASTNodeFlag = (
    nfNone,
    nfPublic,
    nfPrivate,
    nfProtected,
    nfVirtual,
    nfOverride,
    nfAbstract,
    nfFinal,
    nfInline,
    nfNative,
    nfOwn,
    nfValueParameter,
    nfNameParameter,
    nfProcessClass,
    nfThreadClass,
    nfSynthetic,
    nfLValue,
    nfConstant,
    nfTerminated,
    nfImplicitCall
  );
  TASTNodeFlags = set of TASTNodeFlag;

  TUnaryOperator = (
    uoInvalid,
    uoPositive,
    uoNegative,
    uoLogicalNot,
    uoBitwiseNot
  );

  TBinaryOperator = (
    boInvalid,
    boAdd,
    boSubtract,
    boMultiply,
    boRealDivide,
    boIntegerDivide,
    boModulo,
    boRemainder,
    boPower,
    boConcat,
    boShiftLeft,
    boShiftRight,
    boBitwiseAnd,
    boBitwiseOr,
    boBitwiseXor,
    boEqual,
    boNotEqual,
    boReferenceEqual,
    boReferenceNotEqual,
    boLess,
    boLessEqual,
    boGreater,
    boGreaterEqual,
    boLogicalAnd,
    boLogicalOr,
    boEquivalence,
    boImplication
  );

  TOutputKind = (
    okText,
    okInteger,
    okReal,
    okFixed,
    okCharacter,
    okImage
  );

  TStringIntrinsic = (
    siNone,
    siByte,
    siByteValue,
    siToInteger,
    siSlice
  );

  TTextIntrinsic = (
    tiNone,
    tiConstant,
    tiStart,
    tiLength,
    tiMain,
    tiPos,
    tiSetPos,
    tiMore,
    tiGetChar,
    tiPutChar,
    tiSub,
    tiStrip,
    tiGetInt,
    tiGetReal,
    tiGetFrac,
    tiPutInt,
    tiPutFix,
    tiPutReal,
    tiPutFrac
  );


  TASTNode = packed record
    Kind: TASTNodeKind;
    Flags: TASTNodeFlags;
    Span: TSourceSpan;
    TypeId: Int32;
    SymbolId: Int32;
    BodyNode: Int32;
    Parent: Int32;
    FirstChild: Int32;
    LastChild: Int32;
    NextSibling: Int32;
    A: Int32;
    B: Int32;
    C: Int32;
    Aux: Int32;
    NameId: Int32;
    StringId: Int32;
    IntValue: Int64;
    RealValue: Double;
  end;

  TAST = record
    Nodes: array of TASTNode;
    Strings: TStringPool;
    Root: Int32;
  end;

procedure ASTInit(var Tree: TAST);
procedure ASTClear(var Tree: TAST);
function ASTAddNode(var Tree: TAST; Kind: TASTNodeKind;
  const Span: TSourceSpan): Int32;
function ASTAddNamedNode(var Tree: TAST; Kind: TASTNodeKind;
  const Span: TSourceSpan; const Name: RawByteString): Int32;
procedure ASTAppendChild(var Tree: TAST; Parent, Child: Int32);
procedure ASTPrependChild(var Tree: TAST; Parent, Child: Int32);
function ASTCloneSubtree(var Tree: TAST; Node: Int32): Int32;
function ASTChildCount(const Tree: TAST; Parent: Int32): Int32;
function ASTChildAt(const Tree: TAST; Parent, Index: Int32): Int32;
function ASTNodeName(const Tree: TAST; Node: Int32): RawByteString;
function ASTNodeString(const Tree: TAST; Node: Int32): RawByteString;
function ASTKindName(Kind: TASTNodeKind): RawByteString;
function UnaryOperatorName(Op: TUnaryOperator): RawByteString;
function BinaryOperatorName(Op: TBinaryOperator): RawByteString;
procedure ASTDump(const Tree: TAST; Node: Int32 = -1; Indent: Int32 = 0);
procedure ASTVerify(const Tree: TAST);

implementation

procedure ASTInit(var Tree: TAST);
begin
  Tree := Default(TAST);
  BufferInit(Tree.Strings.Bytes, 1024);
  Tree.Root := FSIM_INVALID_INDEX;
end;

procedure ASTClear(var Tree: TAST);
begin
  SetLength(Tree.Nodes, 0);
  SetLength(Tree.Strings.Entries, 0);
  BufferClear(Tree.Strings.Bytes);
  Tree.Root := FSIM_INVALID_INDEX;
end;

function ASTAddNode(var Tree: TAST; Kind: TASTNodeKind;
  const Span: TSourceSpan): Int32;
begin
  Result := Length(Tree.Nodes);
  SetLength(Tree.Nodes, Result + 1);
  Tree.Nodes[Result] := Default(TASTNode);
  Tree.Nodes[Result].Kind := Kind;
  Tree.Nodes[Result].Span := Span;
  Tree.Nodes[Result].TypeId := FSIM_INVALID_INDEX;
  Tree.Nodes[Result].SymbolId := FSIM_INVALID_INDEX;
  Tree.Nodes[Result].BodyNode := FSIM_INVALID_INDEX;
  Tree.Nodes[Result].Parent := FSIM_INVALID_INDEX;
  Tree.Nodes[Result].FirstChild := FSIM_INVALID_INDEX;
  Tree.Nodes[Result].LastChild := FSIM_INVALID_INDEX;
  Tree.Nodes[Result].NextSibling := FSIM_INVALID_INDEX;
  Tree.Nodes[Result].A := FSIM_INVALID_INDEX;
  Tree.Nodes[Result].B := FSIM_INVALID_INDEX;
  Tree.Nodes[Result].C := FSIM_INVALID_INDEX;
  Tree.Nodes[Result].Aux := FSIM_INVALID_INDEX;
  Tree.Nodes[Result].NameId := FSIM_INVALID_INDEX;
  Tree.Nodes[Result].StringId := FSIM_INVALID_INDEX;
end;

function ASTAddNamedNode(var Tree: TAST; Kind: TASTNodeKind;
  const Span: TSourceSpan; const Name: RawByteString): Int32;
begin
  Result := ASTAddNode(Tree, Kind, Span);
  Tree.Nodes[Result].NameId := StringPoolIntern(Tree.Strings, Name);
end;

procedure CheckNodeIndex(const Tree: TAST; Node: Int32);
begin
  if (Node < 0) or (Node > High(Tree.Nodes)) then
    raise ERangeError.CreateFmt('AST node index %d outside range', [Node]);
end;

procedure ASTAppendChild(var Tree: TAST; Parent, Child: Int32);
begin
  CheckNodeIndex(Tree, Parent);
  CheckNodeIndex(Tree, Child);
  if Tree.Nodes[Child].Parent <> FSIM_INVALID_INDEX then
    raise EInvalidOp.Create('AST child already has a parent');
  Tree.Nodes[Child].Parent := Parent;
  if Tree.Nodes[Parent].FirstChild = FSIM_INVALID_INDEX then
  begin
    Tree.Nodes[Parent].FirstChild := Child;
    Tree.Nodes[Parent].LastChild := Child;
  end
  else
  begin
    Tree.Nodes[Tree.Nodes[Parent].LastChild].NextSibling := Child;
    Tree.Nodes[Parent].LastChild := Child;
  end;
end;

procedure ASTPrependChild(var Tree: TAST; Parent, Child: Int32);
begin
  CheckNodeIndex(Tree, Parent);
  CheckNodeIndex(Tree, Child);
  if Tree.Nodes[Child].Parent <> FSIM_INVALID_INDEX then
    raise EInvalidOp.Create('AST child already has a parent');
  Tree.Nodes[Child].Parent := Parent;
  Tree.Nodes[Child].NextSibling := Tree.Nodes[Parent].FirstChild;
  Tree.Nodes[Parent].FirstChild := Child;
  if Tree.Nodes[Parent].LastChild = FSIM_INVALID_INDEX then
    Tree.Nodes[Parent].LastChild := Child;
end;

function ASTCloneSubtree(var Tree: TAST; Node: Int32): Int32;
var
  Child, CopyChild: Int32;
begin
  CheckNodeIndex(Tree, Node);
  Result := Length(Tree.Nodes);
  SetLength(Tree.Nodes, Result + 1);
  Tree.Nodes[Result] := Tree.Nodes[Node];
  Tree.Nodes[Result].Parent := FSIM_INVALID_INDEX;
  Tree.Nodes[Result].FirstChild := FSIM_INVALID_INDEX;
  Tree.Nodes[Result].LastChild := FSIM_INVALID_INDEX;
  Tree.Nodes[Result].NextSibling := FSIM_INVALID_INDEX;
  Child := Tree.Nodes[Node].FirstChild;
  while Child >= 0 do
  begin
    CopyChild := ASTCloneSubtree(Tree, Child);
    ASTAppendChild(Tree, Result, CopyChild);
    Child := Tree.Nodes[Child].NextSibling;
  end;
end;

function ASTChildCount(const Tree: TAST; Parent: Int32): Int32;
var
  Child: Int32;
begin
  CheckNodeIndex(Tree, Parent);
  Result := 0;
  Child := Tree.Nodes[Parent].FirstChild;
  while Child <> FSIM_INVALID_INDEX do
  begin
    Inc(Result);
    Child := Tree.Nodes[Child].NextSibling;
  end;
end;

function ASTChildAt(const Tree: TAST; Parent, Index: Int32): Int32;
var
  Child: Int32;
begin
  CheckNodeIndex(Tree, Parent);
  if Index < 0 then
    Exit(FSIM_INVALID_INDEX);
  Child := Tree.Nodes[Parent].FirstChild;
  while (Child <> FSIM_INVALID_INDEX) and (Index > 0) do
  begin
    Child := Tree.Nodes[Child].NextSibling;
    Dec(Index);
  end;
  Result := Child;
end;

function ASTNodeName(const Tree: TAST; Node: Int32): RawByteString;
begin
  CheckNodeIndex(Tree, Node);
  if Tree.Nodes[Node].NameId = FSIM_INVALID_INDEX then
    Exit('');
  Result := StringPoolGet(Tree.Strings, Tree.Nodes[Node].NameId);
end;

function ASTNodeString(const Tree: TAST; Node: Int32): RawByteString;
begin
  CheckNodeIndex(Tree, Node);
  if Tree.Nodes[Node].StringId = FSIM_INVALID_INDEX then
    Exit('');
  Result := StringPoolGet(Tree.Strings, Tree.Nodes[Node].StringId);
end;

function ASTKindName(Kind: TASTNodeKind): RawByteString;
begin
  case Kind of
    nkInvalid: Result := 'Invalid';
    nkCompilationUnit: Result := 'CompilationUnit';
    nkModuleDecl: Result := 'ModuleDecl';
    nkImportDecl: Result := 'ImportDecl';
    nkProgramDecl: Result := 'ProgramDecl';
    nkBlock: Result := 'Block';
    nkClassDecl: Result := 'ClassDecl';
    nkProcessClassDecl: Result := 'ProcessClassDecl';
    nkThreadClassDecl: Result := 'ThreadClassDecl';
    nkVirtualSection: Result := 'VirtualSection';
    nkVirtualSpec: Result := 'VirtualSpec';
    nkProcedureDecl: Result := 'ProcedureDecl';
    nkFunctionDecl: Result := 'FunctionDecl';
    nkParameterDecl: Result := 'ParameterDecl';
    nkVariableDecl: Result := 'VariableDecl';
    nkConstantDecl: Result := 'ConstantDecl';
    nkSwitchDecl: Result := 'switch declaration';
    nkLabelDecl: Result := 'label declaration';
    nkTypeDecl: Result := 'TypeDecl';
    nkArrayType: Result := 'ArrayType';
    nkReferenceType: Result := 'ReferenceType';
    nkVisibilitySection: Result := 'VisibilitySection';
    nkStatementList: Result := 'StatementList';
    nkEmptyStatement: Result := 'EmptyStatement';
    nkBlockStatement: Result := 'BlockStatement';
    nkAssignmentStatement: Result := 'AssignmentStatement';
    nkReferenceAssignmentStatement: Result := 'ReferenceAssignmentStatement';
    nkIfStatement: Result := 'IfStatement';
    nkWhileStatement: Result := 'WhileStatement';
    nkForStatement: Result := 'ForStatement';
    nkForValueElement: Result := 'ForValueElement';
    nkForStepUntilElement: Result := 'ForStepUntilElement';
    nkForWhileElement: Result := 'ForWhileElement';
    nkGotoStatement: Result := 'GotoStatement';
    nkLabelStatement: Result := 'LabelStatement';
    nkInspectStatement: Result := 'InspectStatement';
    nkWhenClause: Result := 'WhenClause';
    nkTryStatement: Result := 'TryStatement';
    nkCatchClause: Result := 'CatchClause';
    nkFinallyClause: Result := 'FinallyClause';
    nkRaiseStatement: Result := 'RaiseStatement';
    nkReturnStatement: Result := 'ReturnStatement';
    nkExitStatement: Result := 'ExitStatement';
    nkBreakStatement: Result := 'BreakStatement';
    nkContinueStatement: Result := 'ContinueStatement';
    nkAssertStatement: Result := 'AssertStatement';
    nkDetachStatement: Result := 'DetachStatement';
    nkCallStatement: Result := 'CallStatement';
    nkResumeStatement: Result := 'ResumeStatement';
    nkActivateStatement: Result := 'ActivateStatement';
    nkReactivateStatement: Result := 'ReactivateStatement';
    nkDelayStatement: Result := 'DelayStatement';
    nkHoldStatement: Result := 'HoldStatement';
    nkPassivateStatement: Result := 'PassivateStatement';
    nkCancelStatement: Result := 'cancel statement';
    nkInnerStatement: Result := 'inner statement';
    nkSpawnStatement: Result := 'spawn statement';
    nkJoinStatement: Result := 'join statement';
    nkYieldStatement: Result := 'yield statement';
    nkSendStatement: Result := 'send statement';
    nkReceiveStatement: Result := 'receive statement';
    nkLockStatement: Result := 'lock statement';
    nkUnlockStatement: Result := 'unlock statement';
    nkParallelStatement: Result := 'parallel statement';
    nkCriticalStatement: Result := 'critical statement';
    nkDeferStatement: Result := 'defer statement';
    nkRepeatStatement: Result := 'repeat statement';
    nkCaseStatement: Result := 'case statement';
    nkCaseClause: Result := 'case clause';
    nkWithStatement: Result := 'with statement';
    nkOutputStatement: Result := 'OutputStatement';
    nkInputStatement: Result := 'InputStatement';
    nkExpressionStatement: Result := 'ExpressionStatement';
    nkIdentifierExpr: Result := 'IdentifierExpr';
    nkIntegerLiteralExpr: Result := 'IntegerLiteralExpr';
    nkRealLiteralExpr: Result := 'RealLiteralExpr';
    nkBooleanLiteralExpr: Result := 'BooleanLiteralExpr';
    nkCharacterLiteralExpr: Result := 'CharacterLiteralExpr';
    nkStringLiteralExpr: Result := 'StringLiteralExpr';
    nkNoneExpr: Result := 'NoneExpr';
    nkThisExpr: Result := 'ThisExpr';
    nkNewExpr: Result := 'NewExpr';
    nkUnaryExpr: Result := 'UnaryExpr';
    nkBinaryExpr: Result := 'BinaryExpr';
    nkCallExpr: Result := 'CallExpr';
    nkMemberExpr: Result := 'MemberExpr';
    nkIndexExpr: Result := 'IndexExpr';
    nkQuaExpr: Result := 'QuaExpr';
    nkObjectTestExpr: Result := 'object test expression';
    nkAwaitExpr: Result := 'await expression';
    nkReceiveExpr: Result := 'receive expression';
    nkSpawnExpr: Result := 'spawn expression';
    nkConditionalExpr: Result := 'ConditionalExpr';
    nkConversionExpr: Result := 'ConversionExpr';
    nkSizeOfExpr: Result := 'SizeOfExpr';
    nkTypeOfExpr: Result := 'TypeOfExpr';
    nkArrayLiteralExpr: Result := 'ArrayLiteralExpr';
  else
    Result := 'UnknownNode';
  end;
end;

function UnaryOperatorName(Op: TUnaryOperator): RawByteString;
begin
  case Op of
    uoPositive: Result := '+';
    uoNegative: Result := '-';
    uoLogicalNot: Result := 'not';
    uoBitwiseNot: Result := 'bitnot';
  else
    Result := '?';
  end;
end;

function BinaryOperatorName(Op: TBinaryOperator): RawByteString;
begin
  case Op of
    boAdd: Result := '+';
    boSubtract: Result := '-';
    boMultiply: Result := '*';
    boRealDivide: Result := '/';
    boIntegerDivide: Result := '//';
    boModulo: Result := 'mod';
    boRemainder: Result := 'rem';
    boPower: Result := '**';
    boConcat: Result := '&';
    boShiftLeft: Result := 'shl';
    boShiftRight: Result := 'shr';
    boBitwiseAnd: Result := 'bitand';
    boBitwiseOr: Result := 'bitor';
    boBitwiseXor: Result := 'xor';
    boEqual: Result := '=';
    boNotEqual: Result := '<>';
    boReferenceEqual: Result := '==';
    boReferenceNotEqual: Result := '=/=';
    boLess: Result := '<';
    boLessEqual: Result := '<=';
    boGreater: Result := '>';
    boGreaterEqual: Result := '>=';
    boLogicalAnd: Result := 'and';
    boLogicalOr: Result := 'or';
    boEquivalence: Result := 'eqv';
    boImplication: Result := 'imp';
  else
    Result := '?';
  end;
end;

procedure DumpIndent(Indent: Int32);
var
  I: Integer;
begin
  for I := 1 to Indent do
    Write('  ');
end;

procedure ASTDump(const Tree: TAST; Node: Int32; Indent: Int32);
var
  Child: Int32;
  Name, LiteralText: RawByteString;
begin
  if Node = FSIM_INVALID_INDEX then
    Node := Tree.Root;
  if Node = FSIM_INVALID_INDEX then
  begin
    Writeln('<empty AST>');
    Exit;
  end;
  CheckNodeIndex(Tree, Node);
  DumpIndent(Indent);
  Write(Node:5, ' ', ASTKindName(Tree.Nodes[Node].Kind));
  Name := ASTNodeName(Tree, Node);
  if Name <> '' then
    Write(' name="', Name, '"');
  case Tree.Nodes[Node].Kind of
    nkIntegerLiteralExpr, nkBooleanLiteralExpr, nkCharacterLiteralExpr:
      Write(' value=', Tree.Nodes[Node].IntValue);
    nkRealLiteralExpr:
      Write(' value=', Tree.Nodes[Node].RealValue:0:8);
    nkStringLiteralExpr:
      begin
        LiteralText := ASTNodeString(Tree, Node);
        Write(' value="', LiteralText, '"');
      end;
    nkUnaryExpr:
      Write(' op=', UnaryOperatorName(TUnaryOperator(Tree.Nodes[Node].Aux)));
    nkBinaryExpr:
      Write(' op=', BinaryOperatorName(TBinaryOperator(Tree.Nodes[Node].Aux)));
  end;
  if Tree.Nodes[Node].TypeId <> FSIM_INVALID_INDEX then
    Write(' type=', Tree.Nodes[Node].TypeId);
  if Tree.Nodes[Node].SymbolId <> FSIM_INVALID_INDEX then
    Write(' symbol=', Tree.Nodes[Node].SymbolId);
  Writeln;
  Child := Tree.Nodes[Node].FirstChild;
  while Child <> FSIM_INVALID_INDEX do
  begin
    ASTDump(Tree, Child, Indent + 1);
    Child := Tree.Nodes[Child].NextSibling;
  end;
end;

procedure ASTVerify(const Tree: TAST);
var
  I, Child, Last, Count, Guard: Int32;
begin
  if Tree.Root <> FSIM_INVALID_INDEX then
    CheckNodeIndex(Tree, Tree.Root);
  for I := 0 to High(Tree.Nodes) do
  begin
    if Tree.Nodes[I].Parent <> FSIM_INVALID_INDEX then
      CheckNodeIndex(Tree, Tree.Nodes[I].Parent);
    if Tree.Nodes[I].FirstChild <> FSIM_INVALID_INDEX then
      CheckNodeIndex(Tree, Tree.Nodes[I].FirstChild);
    if Tree.Nodes[I].LastChild <> FSIM_INVALID_INDEX then
      CheckNodeIndex(Tree, Tree.Nodes[I].LastChild);
    if Tree.Nodes[I].NextSibling <> FSIM_INVALID_INDEX then
      CheckNodeIndex(Tree, Tree.Nodes[I].NextSibling);
    Child := Tree.Nodes[I].FirstChild;
    Last := FSIM_INVALID_INDEX;
    Count := 0;
    Guard := 0;
    while Child <> FSIM_INVALID_INDEX do
    begin
      if Tree.Nodes[Child].Parent <> I then
        raise EInvalidOp.CreateFmt('AST parent mismatch at node %d', [Child]);
      Last := Child;
      Child := Tree.Nodes[Child].NextSibling;
      Inc(Count);
      Inc(Guard);
      if Guard > Length(Tree.Nodes) then
        raise EInvalidOp.Create('AST sibling cycle detected');
    end;
    if Last <> Tree.Nodes[I].LastChild then
      raise EInvalidOp.CreateFmt('AST last-child mismatch at node %d', [I]);
    if (Count = 0) and (Tree.Nodes[I].LastChild <> FSIM_INVALID_INDEX) then
      raise EInvalidOp.CreateFmt('AST empty child list has a tail at node %d', [I]);
  end;
end;

end.

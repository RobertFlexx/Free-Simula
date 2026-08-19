program test_lexer;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

uses
  SysUtils, core, diagnostics, lexer;

const
  Source: RawByteString =
    'begin process class procedure function inspect when activate reactivate ' +
    'label switch public private protected thread task channel future mutex ' +
    'value := 42; reference :- none; ! punctuation comment; ' +
    'comment keyword comment; end';

  BoundarySource: RawByteString =
    'begin end' + LineEnding + '! source boundary close ;' + LineEnding;

  UnderscoreSource: RawByteString = 'enemy_kind _private_name value_2';
  CommentContinuationSource: RawByteString =
    '! comment stops here; integer value_after_comment;';

type
  TExpectedToken = packed record
    Kind: TTokenKind;
    Text: string[32];
  end;

const
  Expected: array[0..28] of TExpectedToken = (
    (Kind: tkBegin; Text: 'begin'),
    (Kind: tkProcess; Text: 'process'),
    (Kind: tkClass; Text: 'class'),
    (Kind: tkProcedure; Text: 'procedure'),
    (Kind: tkFunction; Text: 'function'),
    (Kind: tkInspect; Text: 'inspect'),
    (Kind: tkWhen; Text: 'when'),
    (Kind: tkActivate; Text: 'activate'),
    (Kind: tkReactivate; Text: 'reactivate'),
    (Kind: tkLabel; Text: 'label'),
    (Kind: tkSwitch; Text: 'switch'),
    (Kind: tkPublic; Text: 'public'),
    (Kind: tkPrivate; Text: 'private'),
    (Kind: tkProtected; Text: 'protected'),
    (Kind: tkThread; Text: 'thread'),
    (Kind: tkTask; Text: 'task'),
    (Kind: tkChannel; Text: 'channel'),
    (Kind: tkFuture; Text: 'future'),
    (Kind: tkMutex; Text: 'mutex'),
    (Kind: tkValue; Text: 'value'),
    (Kind: tkAssignValue; Text: ':='),
    (Kind: tkIntegerLiteral; Text: '42'),
    (Kind: tkSemicolon; Text: ';'),
    (Kind: tkIdentifier; Text: 'reference'),
    (Kind: tkAssignReference; Text: ':-'),
    (Kind: tkNone; Text: 'none'),
    (Kind: tkSemicolon; Text: ';'),
    (Kind: tkEnd; Text: 'end'),
    (Kind: tkEOF; Text: '')
  );

procedure Fail(Index: Integer; const MessageText: RawByteString);
begin
  Writeln(StdErr, 'lexer test failed at token ', Index, ': ', MessageText);
  Halt(Index + 1);
end;

var
  TestLexer: TLexer;
  TestDiagnostics: TDiagnosticBag;
  Index: Integer;
  ActualText: RawByteString;
begin
  DiagnosticsInit(TestDiagnostics);
  try
    LexerInit(TestLexer, PAnsiChar(Source), Length(Source), fdFSim, TestDiagnostics);
    for Index := 0 to 28 do
    begin
      if TestLexer.Current.Kind <> Expected[Index].Kind then
        Fail(Index, 'expected ' + TokenKindName(Expected[Index].Kind) +
          ', got ' + TokenKindName(TestLexer.Current.Kind));
      ActualText := TokenText(TestLexer.Current);
      if ActualText <> RawByteString(Expected[Index].Text) then
        Fail(Index, 'expected text ''' + Expected[Index].Text +
          ''', got ''' + ActualText + '''');
      if TestLexer.Current.Kind <> tkEOF then
        LexerNext(TestLexer);
    end;
    if TestLexer.Current.Kind <> tkEOF then
      Fail(29, 'scanner did not remain at EOF');
    if HasErrors(TestDiagnostics) then
      Fail(30, 'unexpected scanner diagnostic');

    { ModuleLoader wraps sources in synthetic bang comments.  Its closing
      marker must not contain a control-flow keyword which the classic END
      comment scanner can expose as a second source token. }
    LexerInit(TestLexer, PAnsiChar(BoundarySource), Length(BoundarySource),
      fdSimula67, TestDiagnostics);
    if TestLexer.Current.Kind <> tkBegin then
      Fail(31, 'boundary regression did not start with begin');
    LexerNext(TestLexer);
    if TestLexer.Current.Kind <> tkEnd then
      Fail(32, 'boundary regression did not reach language end');
    LexerNext(TestLexer);
    if TestLexer.Current.Kind <> tkSemicolon then
      Fail(33, 'module boundary did not reduce to a harmless separator');
    LexerNext(TestLexer);
    if TestLexer.Current.Kind <> tkEOF then
      Fail(34, 'module boundary text leaked into the token stream');
    if HasErrors(TestDiagnostics) then
      Fail(35, 'boundary regression produced an unexpected scanner diagnostic');

    DiagnosticsClear(TestDiagnostics);
    DiagnosticsInit(TestDiagnostics);
    LexerInit(TestLexer, PAnsiChar(UnderscoreSource), Length(UnderscoreSource),
      fdFSim, TestDiagnostics);
    if (TestLexer.Current.Kind <> tkIdentifier) or
       (TokenText(TestLexer.Current) <> 'enemy_kind') then
      Fail(36, 'underscore identifier was split by the lexer');
    LexerNext(TestLexer);
    if (TestLexer.Current.Kind <> tkIdentifier) or
       (TokenText(TestLexer.Current) <> '_private_name') then
      Fail(37, 'leading underscore identifier was not preserved');
    LexerNext(TestLexer);
    if (TestLexer.Current.Kind <> tkIdentifier) or
       (TokenText(TestLexer.Current) <> 'value_2') then
      Fail(38, 'identifier underscore/digit continuation was not preserved');
    LexerNext(TestLexer);
    if TestLexer.Current.Kind <> tkEOF then
      Fail(39, 'underscore source did not terminate cleanly');
    if HasErrors(TestDiagnostics) then
      Fail(40, 'underscore lexer source produced a diagnostic');

    DiagnosticsClear(TestDiagnostics);
    DiagnosticsInit(TestDiagnostics);
    LexerInit(TestLexer, PAnsiChar(CommentContinuationSource),
      Length(CommentContinuationSource), fdSimula67, TestDiagnostics);
    if TestLexer.Current.Kind <> tkInteger then
      Fail(41, 'text after a ! comment semicolon was incorrectly kept inside the comment');
    LexerNext(TestLexer);
    if (TestLexer.Current.Kind <> tkIdentifier) or
       (TokenText(TestLexer.Current) <> 'value_after_comment') then
      Fail(42, 'comment continuation source did not resume with the following identifier');
    LexerNext(TestLexer);
    if TestLexer.Current.Kind <> tkSemicolon then
      Fail(43, 'comment continuation source lost the following semicolon');
    LexerNext(TestLexer);
    if TestLexer.Current.Kind <> tkEOF then
      Fail(44, 'comment continuation source did not terminate cleanly');
    if HasErrors(TestDiagnostics) then
      Fail(45, 'comment continuation source produced an unexpected scanner diagnostic');
  finally
    DiagnosticsClear(TestDiagnostics);
  end;
end.

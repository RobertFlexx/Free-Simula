unit classic;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, core, diagnostics, symbols;

type
  TActivationMode = (
    amDirect,
    amAt,
    amDelay,
    amBefore,
    amAfter
  );

  TActivationFlag = (
    afNone,
    afPrior,
    afReactivate
  );
  TActivationFlags = set of TActivationFlag;

  TActivationClause = packed record
    Mode: TActivationMode;
    Flags: TActivationFlags;
    ProcessNode: Int32;
    TimeNode: Int32;
    RelativeNode: Int32;
    Span: TSourceSpan;
  end;

  TClassicTextFrame = packed record
    BufferStringId: Int32;
    StartOffset: UInt32;
    FrameLength: UInt32;
    Position: UInt32;
    Writable: Boolean;
    FixedLength: Boolean;
  end;

  TSwitchElementKind = (
    sekLabel,
    sekSwitchElement,
    sekConditional
  );

  TSwitchElement = packed record
    Kind: TSwitchElementKind;
    TargetSymbol: Int32;
    SelectorNode: Int32;
    TrueTarget: Int32;
    FalseTarget: Int32;
    Span: TSourceSpan;
  end;

  TSwitchDescriptor = record
    SymbolId: Int32;
    ScopeId: Int32;
    Elements: array of TSwitchElement;
  end;

  TSimulationLinkState = (
    slsDetached,
    slsQueued,
    slsCurrent,
    slsTerminated
  );

  TSimulationLinkDescriptor = packed record
    ObjectSymbol: Int32;
    HeadSymbol: Int32;
    PredecessorSymbol: Int32;
    SuccessorSymbol: Int32;
    State: TSimulationLinkState;
    ScheduledTimeBits: QWord;
    SequenceNumber: QWord;
  end;

  TClassicModel = record
    Activations: array of TActivationClause;
    Switches: array of TSwitchDescriptor;
    TextFrames: array of TClassicTextFrame;
    Links: array of TSimulationLinkDescriptor;
    NextSequenceNumber: QWord;
  end;

procedure ClassicModelInit(var Model: TClassicModel);
procedure ClassicModelClear(var Model: TClassicModel);
function EncodeActivationAux(Mode: TActivationMode;
  Flags: TActivationFlags): Int32;
procedure DecodeActivationAux(Value: Int32; out Mode: TActivationMode;
  out Flags: TActivationFlags);
function ClassicAddActivation(var Model: TClassicModel;
  const Clause: TActivationClause): Int32;
function ClassicAddSwitch(var Model: TClassicModel; SymbolId,
  ScopeId: Int32): Int32;
procedure ClassicAddSwitchElement(var Model: TClassicModel;
  SwitchIndex: Int32; const Element: TSwitchElement);
function ClassicFindSwitch(const Model: TClassicModel;
  SymbolId: Int32): Int32;
function ClassicAddTextFrame(var Model: TClassicModel;
  BufferStringId: Int32; StartOffset, FrameLength: UInt32;
  Writable, FixedLength: Boolean): Int32;
function ClassicTextMore(const Model: TClassicModel;
  FrameIndex: Int32): Boolean;
function ClassicTextRemaining(const Model: TClassicModel;
  FrameIndex: Int32): UInt32;
function ClassicTextSetPosition(var Model: TClassicModel;
  FrameIndex: Int32; NewPosition: UInt32): Boolean;
function ClassicTextSubFrame(var Model: TClassicModel;
  FrameIndex: Int32; RelativeStart, LengthValue: UInt32;
  out ResultFrame: Int32): Boolean;
function ClassicAddLink(var Model: TClassicModel;
  ObjectSymbol: Int32): Int32;
function ClassicQueueFirst(const Model: TClassicModel;
  HeadSymbol: Int32): Int32;
function ClassicQueueLast(const Model: TClassicModel;
  HeadSymbol: Int32): Int32;
function ClassicQueueCardinal(const Model: TClassicModel;
  HeadSymbol: Int32): UInt32;
function ClassicQueueEmpty(const Model: TClassicModel;
  HeadSymbol: Int32): Boolean;
procedure ClassicQueueDetach(var Model: TClassicModel;
  LinkIndex: Int32);
procedure ClassicQueueInto(var Model: TClassicModel;
  LinkIndex: Int32; HeadSymbol: Int32);
procedure ClassicQueuePrecede(var Model: TClassicModel;
  LinkIndex, ExistingLinkIndex: Int32);
procedure ClassicQueueFollow(var Model: TClassicModel;
  LinkIndex, ExistingLinkIndex: Int32);
procedure ClassicValidateActivation(const Clause: TActivationClause;
  Dialect: TFSimDialect; var Diagnostics: TDiagnosticBag);
procedure ClassicValidateTextFrame(const Frame: TClassicTextFrame;
  Dialect: TFSimDialect; const Span: TSourceSpan;
  var Diagnostics: TDiagnosticBag);
procedure ClassicValidateSwitch(const Model: TClassicModel;
  SwitchIndex: Int32; const Symbols: TSymbolTable;
  var Diagnostics: TDiagnosticBag);

implementation

const
  ACTIVATION_MODE_MASK = $0000000F;
  ACTIVATION_PRIOR_BIT = $00000100;
  ACTIVATION_REACTIVATE_BIT = $00000200;

procedure ClassicModelInit(var Model: TClassicModel);
begin
  Model := Default(TClassicModel);
  Model.NextSequenceNumber := 1;
end;

procedure ClassicModelClear(var Model: TClassicModel);
var
  Index: Int32;
begin
  for Index := 0 to High(Model.Switches) do
    SetLength(Model.Switches[Index].Elements, 0);
  SetLength(Model.Activations, 0);
  SetLength(Model.Switches, 0);
  SetLength(Model.TextFrames, 0);
  SetLength(Model.Links, 0);
  Model.NextSequenceNumber := 1;
end;

function EncodeActivationAux(Mode: TActivationMode;
  Flags: TActivationFlags): Int32;
begin
  Result := Ord(Mode) and ACTIVATION_MODE_MASK;
  if afPrior in Flags then Result := Result or ACTIVATION_PRIOR_BIT;
  if afReactivate in Flags then Result := Result or ACTIVATION_REACTIVATE_BIT;
end;

procedure DecodeActivationAux(Value: Int32; out Mode: TActivationMode;
  out Flags: TActivationFlags);
var
  ModeValue: Int32;
begin
  ModeValue := Value and ACTIVATION_MODE_MASK;
  if (ModeValue < Ord(Low(TActivationMode))) or
     (ModeValue > Ord(High(TActivationMode))) then
    Mode := amDirect
  else
    Mode := TActivationMode(ModeValue);
  Flags := [];
  if (Value and ACTIVATION_PRIOR_BIT) <> 0 then Include(Flags, afPrior);
  if (Value and ACTIVATION_REACTIVATE_BIT) <> 0 then
    Include(Flags, afReactivate);
end;

function ClassicAddActivation(var Model: TClassicModel;
  const Clause: TActivationClause): Int32;
begin
  Result := Length(Model.Activations);
  SetLength(Model.Activations, Result + 1);
  Model.Activations[Result] := Clause;
end;

function ClassicAddSwitch(var Model: TClassicModel; SymbolId,
  ScopeId: Int32): Int32;
begin
  Result := Length(Model.Switches);
  SetLength(Model.Switches, Result + 1);
  Model.Switches[Result] := Default(TSwitchDescriptor);
  Model.Switches[Result].SymbolId := SymbolId;
  Model.Switches[Result].ScopeId := ScopeId;
end;

procedure ClassicAddSwitchElement(var Model: TClassicModel;
  SwitchIndex: Int32; const Element: TSwitchElement);
var
  Index: Int32;
begin
  if (SwitchIndex < 0) or (SwitchIndex > High(Model.Switches)) then
    raise ERangeError.CreateFmt('switch index %d is out of range', [SwitchIndex]);
  Index := Length(Model.Switches[SwitchIndex].Elements);
  SetLength(Model.Switches[SwitchIndex].Elements, Index + 1);
  Model.Switches[SwitchIndex].Elements[Index] := Element;
end;

function ClassicFindSwitch(const Model: TClassicModel;
  SymbolId: Int32): Int32;
var
  Index: Int32;
begin
  for Index := 0 to High(Model.Switches) do
    if Model.Switches[Index].SymbolId = SymbolId then Exit(Index);
  Result := FSIM_INVALID_INDEX;
end;

function ClassicAddTextFrame(var Model: TClassicModel;
  BufferStringId: Int32; StartOffset, FrameLength: UInt32;
  Writable, FixedLength: Boolean): Int32;
begin
  Result := Length(Model.TextFrames);
  SetLength(Model.TextFrames, Result + 1);
  Model.TextFrames[Result] := Default(TClassicTextFrame);
  Model.TextFrames[Result].BufferStringId := BufferStringId;
  Model.TextFrames[Result].StartOffset := StartOffset;
  Model.TextFrames[Result].FrameLength := FrameLength;
  Model.TextFrames[Result].Writable := Writable;
  Model.TextFrames[Result].FixedLength := FixedLength;
end;

function ValidFrameIndex(const Model: TClassicModel;
  FrameIndex: Int32): Boolean; inline;
begin
  Result := (FrameIndex >= 0) and (FrameIndex <= High(Model.TextFrames));
end;

function ClassicTextMore(const Model: TClassicModel;
  FrameIndex: Int32): Boolean;
begin
  Result := ValidFrameIndex(Model, FrameIndex) and
    (Model.TextFrames[FrameIndex].Position <
     Model.TextFrames[FrameIndex].FrameLength);
end;

function ClassicTextRemaining(const Model: TClassicModel;
  FrameIndex: Int32): UInt32;
begin
  if not ValidFrameIndex(Model, FrameIndex) then Exit(0);
  if Model.TextFrames[FrameIndex].Position >=
     Model.TextFrames[FrameIndex].FrameLength then Exit(0);
  Result := Model.TextFrames[FrameIndex].FrameLength -
    Model.TextFrames[FrameIndex].Position;
end;

function ClassicTextSetPosition(var Model: TClassicModel;
  FrameIndex: Int32; NewPosition: UInt32): Boolean;
begin
  Result := ValidFrameIndex(Model, FrameIndex) and
    (NewPosition <= Model.TextFrames[FrameIndex].FrameLength);
  if Result then Model.TextFrames[FrameIndex].Position := NewPosition;
end;

function ClassicTextSubFrame(var Model: TClassicModel;
  FrameIndex: Int32; RelativeStart, LengthValue: UInt32;
  out ResultFrame: Int32): Boolean;
var
  Parent: TClassicTextFrame;
  EndPosition: QWord;
begin
  ResultFrame := FSIM_INVALID_INDEX;
  if not ValidFrameIndex(Model, FrameIndex) then Exit(False);
  Parent := Model.TextFrames[FrameIndex];
  EndPosition := QWord(RelativeStart) + QWord(LengthValue);
  if (RelativeStart > Parent.FrameLength) or
     (EndPosition > Parent.FrameLength) then Exit(False);
  ResultFrame := ClassicAddTextFrame(Model, Parent.BufferStringId,
    Parent.StartOffset + RelativeStart, LengthValue, Parent.Writable,
    True);
  Result := True;
end;

function ClassicAddLink(var Model: TClassicModel;
  ObjectSymbol: Int32): Int32;
begin
  Result := Length(Model.Links);
  SetLength(Model.Links, Result + 1);
  Model.Links[Result] := Default(TSimulationLinkDescriptor);
  Model.Links[Result].ObjectSymbol := ObjectSymbol;
  Model.Links[Result].HeadSymbol := FSIM_INVALID_INDEX;
  Model.Links[Result].PredecessorSymbol := FSIM_INVALID_INDEX;
  Model.Links[Result].SuccessorSymbol := FSIM_INVALID_INDEX;
  Model.Links[Result].State := slsDetached;
  Model.Links[Result].SequenceNumber := Model.NextSequenceNumber;
  Inc(Model.NextSequenceNumber);
end;

function FindLinkByObject(const Model: TClassicModel;
  ObjectSymbol: Int32): Int32;
var
  Index: Int32;
begin
  for Index := 0 to High(Model.Links) do
    if Model.Links[Index].ObjectSymbol = ObjectSymbol then Exit(Index);
  Result := FSIM_INVALID_INDEX;
end;

function ClassicQueueFirst(const Model: TClassicModel;
  HeadSymbol: Int32): Int32;
var
  Index: Int32;
begin
  Result := FSIM_INVALID_INDEX;
  for Index := 0 to High(Model.Links) do
    if (Model.Links[Index].HeadSymbol = HeadSymbol) and
       (Model.Links[Index].PredecessorSymbol = FSIM_INVALID_INDEX) and
       (Model.Links[Index].State = slsQueued) then
      Exit(Index);
end;

function ClassicQueueLast(const Model: TClassicModel;
  HeadSymbol: Int32): Int32;
var
  Index: Int32;
begin
  Result := FSIM_INVALID_INDEX;
  for Index := 0 to High(Model.Links) do
    if (Model.Links[Index].HeadSymbol = HeadSymbol) and
       (Model.Links[Index].SuccessorSymbol = FSIM_INVALID_INDEX) and
       (Model.Links[Index].State = slsQueued) then
      Exit(Index);
end;

function ClassicQueueCardinal(const Model: TClassicModel;
  HeadSymbol: Int32): UInt32;
var
  Index: Int32;
begin
  Result := 0;
  for Index := 0 to High(Model.Links) do
    if (Model.Links[Index].HeadSymbol = HeadSymbol) and
       (Model.Links[Index].State = slsQueued) then Inc(Result);
end;

function ClassicQueueEmpty(const Model: TClassicModel;
  HeadSymbol: Int32): Boolean;
begin
  Result := ClassicQueueCardinal(Model, HeadSymbol) = 0;
end;

procedure DisconnectNeighbors(var Model: TClassicModel; LinkIndex: Int32);
var
  PredIndex, SuccIndex: Int32;
begin
  PredIndex := FindLinkByObject(Model,
    Model.Links[LinkIndex].PredecessorSymbol);
  SuccIndex := FindLinkByObject(Model,
    Model.Links[LinkIndex].SuccessorSymbol);
  if PredIndex >= 0 then
    Model.Links[PredIndex].SuccessorSymbol :=
      Model.Links[LinkIndex].SuccessorSymbol;
  if SuccIndex >= 0 then
    Model.Links[SuccIndex].PredecessorSymbol :=
      Model.Links[LinkIndex].PredecessorSymbol;
end;

procedure ClassicQueueDetach(var Model: TClassicModel;
  LinkIndex: Int32);
begin
  if (LinkIndex < 0) or (LinkIndex > High(Model.Links)) then
    raise ERangeError.CreateFmt('link index %d is out of range', [LinkIndex]);
  if Model.Links[LinkIndex].State = slsQueued then
    DisconnectNeighbors(Model, LinkIndex);
  Model.Links[LinkIndex].HeadSymbol := FSIM_INVALID_INDEX;
  Model.Links[LinkIndex].PredecessorSymbol := FSIM_INVALID_INDEX;
  Model.Links[LinkIndex].SuccessorSymbol := FSIM_INVALID_INDEX;
  Model.Links[LinkIndex].State := slsDetached;
end;

procedure ClassicQueueInto(var Model: TClassicModel;
  LinkIndex: Int32; HeadSymbol: Int32);
var
  LastIndex: Int32;
begin
  ClassicQueueDetach(Model, LinkIndex);
  LastIndex := ClassicQueueLast(Model, HeadSymbol);
  Model.Links[LinkIndex].HeadSymbol := HeadSymbol;
  Model.Links[LinkIndex].State := slsQueued;
  if LastIndex >= 0 then
  begin
    Model.Links[LinkIndex].PredecessorSymbol :=
      Model.Links[LastIndex].ObjectSymbol;
    Model.Links[LastIndex].SuccessorSymbol :=
      Model.Links[LinkIndex].ObjectSymbol;
  end;
end;

procedure ClassicQueuePrecede(var Model: TClassicModel;
  LinkIndex, ExistingLinkIndex: Int32);
var
  PredIndex: Int32;
begin
  if (ExistingLinkIndex < 0) or
     (ExistingLinkIndex > High(Model.Links)) then
    raise ERangeError.CreateFmt('existing link index %d is out of range',
      [ExistingLinkIndex]);
  ClassicQueueDetach(Model, LinkIndex);
  Model.Links[LinkIndex].HeadSymbol :=
    Model.Links[ExistingLinkIndex].HeadSymbol;
  Model.Links[LinkIndex].State := slsQueued;
  Model.Links[LinkIndex].SuccessorSymbol :=
    Model.Links[ExistingLinkIndex].ObjectSymbol;
  Model.Links[LinkIndex].PredecessorSymbol :=
    Model.Links[ExistingLinkIndex].PredecessorSymbol;
  PredIndex := FindLinkByObject(Model,
    Model.Links[ExistingLinkIndex].PredecessorSymbol);
  if PredIndex >= 0 then
    Model.Links[PredIndex].SuccessorSymbol :=
      Model.Links[LinkIndex].ObjectSymbol;
  Model.Links[ExistingLinkIndex].PredecessorSymbol :=
    Model.Links[LinkIndex].ObjectSymbol;
end;

procedure ClassicQueueFollow(var Model: TClassicModel;
  LinkIndex, ExistingLinkIndex: Int32);
var
  SuccIndex: Int32;
begin
  if (ExistingLinkIndex < 0) or
     (ExistingLinkIndex > High(Model.Links)) then
    raise ERangeError.CreateFmt('existing link index %d is out of range',
      [ExistingLinkIndex]);
  ClassicQueueDetach(Model, LinkIndex);
  Model.Links[LinkIndex].HeadSymbol :=
    Model.Links[ExistingLinkIndex].HeadSymbol;
  Model.Links[LinkIndex].State := slsQueued;
  Model.Links[LinkIndex].PredecessorSymbol :=
    Model.Links[ExistingLinkIndex].ObjectSymbol;
  Model.Links[LinkIndex].SuccessorSymbol :=
    Model.Links[ExistingLinkIndex].SuccessorSymbol;
  SuccIndex := FindLinkByObject(Model,
    Model.Links[ExistingLinkIndex].SuccessorSymbol);
  if SuccIndex >= 0 then
    Model.Links[SuccIndex].PredecessorSymbol :=
      Model.Links[LinkIndex].ObjectSymbol;
  Model.Links[ExistingLinkIndex].SuccessorSymbol :=
    Model.Links[LinkIndex].ObjectSymbol;
end;

procedure ClassicValidateActivation(const Clause: TActivationClause;
  Dialect: TFSimDialect; var Diagnostics: TDiagnosticBag);
begin
  if Clause.ProcessNode < 0 then
    AddError(Diagnostics, dcInvalidControlFlow, Clause.Span,
      'activation requires a process expression');
  case Clause.Mode of
    amAt, amDelay:
      if Clause.TimeNode < 0 then
        AddError(Diagnostics, dcInvalidControlFlow, Clause.Span,
          'timed activation requires a time expression');
    amBefore, amAfter:
      if Clause.RelativeNode < 0 then
        AddError(Diagnostics, dcInvalidControlFlow, Clause.Span,
          'relative activation requires another process expression');
  end;
  if (afPrior in Clause.Flags) and not (Clause.Mode in [amAt, amDelay]) then
    AddError(Diagnostics, dcInvalidControlFlow, Clause.Span,
      'prior is valid only with at or delay activation');
  if (Dialect = fdSimula67) and (afReactivate in Clause.Flags) and
     (Clause.Mode = amDirect) then
    AddWarning(Diagnostics, dcInvalidControlFlow, Clause.Span,
      'direct reactivation removes and reinserts the process at current simulation time');
end;

procedure ClassicValidateTextFrame(const Frame: TClassicTextFrame;
  Dialect: TFSimDialect; const Span: TSourceSpan;
  var Diagnostics: TDiagnosticBag);
begin
  if (Dialect = fdSimula67) and not Frame.FixedLength then
    AddError(Diagnostics, dcDialectViolation, Span,
      'Simula 67 text frames have fixed frame length');
  if QWord(Frame.StartOffset) + QWord(Frame.FrameLength) > High(UInt32) then
    AddError(Diagnostics, dcOverflow, Span,
      'text frame extent exceeds the implementation limit');
  if Frame.Position > Frame.FrameLength then
    AddError(Diagnostics, dcInvalidControlFlow, Span,
      'text frame position lies beyond the frame');
end;

procedure ClassicValidateSwitch(const Model: TClassicModel;
  SwitchIndex: Int32; const Symbols: TSymbolTable;
  var Diagnostics: TDiagnosticBag);
var
  ElementIndex, SymbolId: Int32;
  Span: TSourceSpan;
begin
  Span := Default(TSourceSpan);
  if (SwitchIndex < 0) or (SwitchIndex > High(Model.Switches)) then
  begin
    AddError(Diagnostics, dcInternalError, Span,
      'invalid switch descriptor index');
    Exit;
  end;
  for ElementIndex := 0 to High(Model.Switches[SwitchIndex].Elements) do
  begin
    SymbolId := Model.Switches[SwitchIndex].Elements[ElementIndex].TargetSymbol;
    Span := Model.Switches[SwitchIndex].Elements[ElementIndex].Span;
    if (SymbolId < 0) or (SymbolId > High(Symbols.Symbols)) then
      AddError(Diagnostics, dcUnknownSymbol, Span,
        'switch element does not resolve to a label')
    else if Symbols.Symbols[SymbolId].Kind <> skLabel then
      AddError(Diagnostics, dcTypeMismatch, Span,
        'switch elements must designate labels');
  end;
end;

end.

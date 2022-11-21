unit flow;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, core, ir;

type
  TIRBitSet = record
    Words: array of QWord;
    BitCount: Int32;
  end;

  TBlockDataFlow = packed record
    Reachable: Boolean;
    ReversePostOrder: Int32;
    ImmediateDominator: Int32;
    DominatorDepth: Int32;
    LoopHeader: Int32;
    LoopDepth: Int32;
    FirstUse: Int32;
    LastUse: Int32;
  end;

  TLoopDescriptor = packed record
    HeaderBlock: Int32;
    LatchBlock: Int32;
    ParentLoop: Int32;
    Depth: Int32;
    MemberCount: Int32;
    ExitCount: Int32;
  end;

  TFunctionDataFlow = record
    FunctionId: Int32;
    EntryBlock: Int32;
    Blocks: array of Int32;
    ReversePostOrder: array of Int32;
    BlockInfo: array of TBlockDataFlow;
    Dominators: array of TIRBitSet;
    LiveIn: array of TIRBitSet;
    LiveOut: array of TIRBitSet;
    BlockUses: array of TIRBitSet;
    Defines: array of TIRBitSet;
    Loops: array of TLoopDescriptor;
  end;

  TProgramDataFlow = record
    Functions: array of TFunctionDataFlow;
  end;

procedure BitSetInit(var SetValue: TIRBitSet; BitCount: Int32);
procedure BitSetClear(var SetValue: TIRBitSet);
procedure BitSetFill(var SetValue: TIRBitSet);
procedure BitSetInclude(var SetValue: TIRBitSet; BitIndex: Int32);
procedure BitSetExclude(var SetValue: TIRBitSet; BitIndex: Int32);
function BitSetContains(const SetValue: TIRBitSet; BitIndex: Int32): Boolean;
function BitSetUnionInto(var Destination: TIRBitSet;
  const Source: TIRBitSet): Boolean;
function BitSetIntersectInto(var Destination: TIRBitSet;
  const Source: TIRBitSet): Boolean;
function BitSetSubtractInto(var Destination: TIRBitSet;
  const Source: TIRBitSet): Boolean;
function BitSetEqual(const A, B: TIRBitSet): Boolean;
function BitSetCount(const SetValue: TIRBitSet): Int32;
procedure DataFlowInit(var DataFlow: TProgramDataFlow);
procedure DataFlowClear(var DataFlow: TProgramDataFlow);
procedure DataFlowAnalyze(const ProgramIR: TIRProgram;
  var DataFlow: TProgramDataFlow);
function DataFlowDominates(const DataFlow: TProgramDataFlow;
  FunctionId, DominatorBlock, BlockId: Int32): Boolean;
function DataFlowLoopDepth(const DataFlow: TProgramDataFlow;
  FunctionId, BlockId: Int32): Int32;
function DataFlowValueLiveAtExit(const DataFlow: TProgramDataFlow;
  FunctionId, BlockId, ValueId: Int32): Boolean;

implementation

function WordCountFor(Bits: Int32): Int32; inline;
begin
  if Bits <= 0 then Exit(0);
  Result := (Bits + 63) shr 6;
end;

procedure BitSetInit(var SetValue: TIRBitSet; BitCount: Int32);
begin
  if BitCount < 0 then
    raise ERangeError.Create('negative bit-set size');
  SetValue.BitCount := BitCount;
  SetLength(SetValue.Words, WordCountFor(BitCount));
  if Length(SetValue.Words) <> 0 then
    FillChar(SetValue.Words[0], Length(SetValue.Words) * SizeOf(QWord), 0);
end;

procedure BitSetClear(var SetValue: TIRBitSet);
begin
  if Length(SetValue.Words) <> 0 then
    FillChar(SetValue.Words[0], Length(SetValue.Words) * SizeOf(QWord), 0);
end;

procedure BitSetFill(var SetValue: TIRBitSet);
var
  LastBits: Int32;
begin
  if Length(SetValue.Words) = 0 then Exit;
  FillChar(SetValue.Words[0], Length(SetValue.Words) * SizeOf(QWord), $FF);
  LastBits := SetValue.BitCount and 63;
  if LastBits <> 0 then
    SetValue.Words[High(SetValue.Words)] := (QWord(1) shl LastBits) - 1;
end;

procedure CheckBitIndex(const SetValue: TIRBitSet; BitIndex: Int32); inline;
begin
  if (BitIndex < 0) or (BitIndex >= SetValue.BitCount) then
    raise ERangeError.CreateFmt('bit index %d outside 0..%d',
      [BitIndex, SetValue.BitCount - 1]);
end;

procedure BitSetInclude(var SetValue: TIRBitSet; BitIndex: Int32);
begin
  CheckBitIndex(SetValue, BitIndex);
  SetValue.Words[BitIndex shr 6] := SetValue.Words[BitIndex shr 6] or
    (QWord(1) shl (BitIndex and 63));
end;

procedure BitSetExclude(var SetValue: TIRBitSet; BitIndex: Int32);
begin
  CheckBitIndex(SetValue, BitIndex);
  SetValue.Words[BitIndex shr 6] := SetValue.Words[BitIndex shr 6] and not
    (QWord(1) shl (BitIndex and 63));
end;

function BitSetContains(const SetValue: TIRBitSet; BitIndex: Int32): Boolean;
begin
  if (BitIndex < 0) or (BitIndex >= SetValue.BitCount) then Exit(False);
  Result := (SetValue.Words[BitIndex shr 6] and
    (QWord(1) shl (BitIndex and 63))) <> 0;
end;

procedure RequireCompatible(const A, B: TIRBitSet); inline;
begin
  if A.BitCount <> B.BitCount then
    raise ERangeError.Create('incompatible bit-set sizes');
end;

function BitSetUnionInto(var Destination: TIRBitSet;
  const Source: TIRBitSet): Boolean;
var
  Index: Int32;
  OldWord, NewWord: QWord;
begin
  RequireCompatible(Destination, Source);
  Result := False;
  for Index := 0 to High(Destination.Words) do
  begin
    OldWord := Destination.Words[Index];
    NewWord := OldWord or Source.Words[Index];
    Destination.Words[Index] := NewWord;
    Result := Result or (NewWord <> OldWord);
  end;
end;

function BitSetIntersectInto(var Destination: TIRBitSet;
  const Source: TIRBitSet): Boolean;
var
  Index: Int32;
  OldWord, NewWord: QWord;
begin
  RequireCompatible(Destination, Source);
  Result := False;
  for Index := 0 to High(Destination.Words) do
  begin
    OldWord := Destination.Words[Index];
    NewWord := OldWord and Source.Words[Index];
    Destination.Words[Index] := NewWord;
    Result := Result or (NewWord <> OldWord);
  end;
end;

function BitSetSubtractInto(var Destination: TIRBitSet;
  const Source: TIRBitSet): Boolean;
var
  Index: Int32;
  OldWord, NewWord: QWord;
begin
  RequireCompatible(Destination, Source);
  Result := False;
  for Index := 0 to High(Destination.Words) do
  begin
    OldWord := Destination.Words[Index];
    NewWord := OldWord and not Source.Words[Index];
    Destination.Words[Index] := NewWord;
    Result := Result or (NewWord <> OldWord);
  end;
end;

function BitSetEqual(const A, B: TIRBitSet): Boolean;
var
  Index: Int32;
begin
  if A.BitCount <> B.BitCount then Exit(False);
  for Index := 0 to High(A.Words) do
    if A.Words[Index] <> B.Words[Index] then Exit(False);
  Result := True;
end;

function PopCount64(Value: QWord): Int32; inline;
begin
  Result := 0;
  while Value <> 0 do
  begin
    Value := Value and (Value - 1);
    Inc(Result);
  end;
end;

function BitSetCount(const SetValue: TIRBitSet): Int32;
var
  Index: Int32;
begin
  Result := 0;
  for Index := 0 to High(SetValue.Words) do
    Inc(Result, PopCount64(SetValue.Words[Index]));
end;

procedure CopyBitSet(const Source: TIRBitSet; out Destination: TIRBitSet);
begin
  Destination.BitCount := Source.BitCount;
  SetLength(Destination.Words, Length(Source.Words));
  if Length(Source.Words) <> 0 then
    Move(Source.Words[0], Destination.Words[0],
      Length(Source.Words) * SizeOf(QWord));
end;

procedure AssignBitSet(var Destination: TIRBitSet; const Source: TIRBitSet);
begin
  if Destination.BitCount <> Source.BitCount then
    BitSetInit(Destination, Source.BitCount);
  if Length(Source.Words) <> 0 then
    Move(Source.Words[0], Destination.Words[0],
      Length(Source.Words) * SizeOf(QWord));
end;

procedure DataFlowInit(var DataFlow: TProgramDataFlow);
begin
  DataFlow := Default(TProgramDataFlow);
end;

procedure ClearFunction(var FunctionFlow: TFunctionDataFlow);
var
  Index: Int32;
begin
  for Index := 0 to High(FunctionFlow.Dominators) do
    SetLength(FunctionFlow.Dominators[Index].Words, 0);
  for Index := 0 to High(FunctionFlow.LiveIn) do
    SetLength(FunctionFlow.LiveIn[Index].Words, 0);
  for Index := 0 to High(FunctionFlow.LiveOut) do
    SetLength(FunctionFlow.LiveOut[Index].Words, 0);
  for Index := 0 to High(FunctionFlow.BlockUses) do
    SetLength(FunctionFlow.BlockUses[Index].Words, 0);
  for Index := 0 to High(FunctionFlow.Defines) do
    SetLength(FunctionFlow.Defines[Index].Words, 0);
  SetLength(FunctionFlow.Blocks, 0);
  SetLength(FunctionFlow.ReversePostOrder, 0);
  SetLength(FunctionFlow.BlockInfo, 0);
  SetLength(FunctionFlow.Dominators, 0);
  SetLength(FunctionFlow.LiveIn, 0);
  SetLength(FunctionFlow.LiveOut, 0);
  SetLength(FunctionFlow.BlockUses, 0);
  SetLength(FunctionFlow.Defines, 0);
  SetLength(FunctionFlow.Loops, 0);
end;

procedure DataFlowClear(var DataFlow: TProgramDataFlow);
var
  Index: Int32;
begin
  for Index := 0 to High(DataFlow.Functions) do
    ClearFunction(DataFlow.Functions[Index]);
  SetLength(DataFlow.Functions, 0);
end;

function LocalBlockIndex(const Flow: TFunctionDataFlow;
  GlobalBlock: Int32): Int32;
var
  Index: Int32;
begin
  for Index := 0 to High(Flow.Blocks) do
    if Flow.Blocks[Index] = GlobalBlock then Exit(Index);
  Result := FSIM_INVALID_INDEX;
end;

procedure CollectFunctionBlocks(const ProgramIR: TIRProgram;
  FunctionId: Int32; var Flow: TFunctionDataFlow);
var
  BlockId, Count: Int32;
begin
  Flow.FunctionId := FunctionId;
  Flow.EntryBlock := ProgramIR.Functions[FunctionId].EntryBlock;
  Count := 0;
  for BlockId := 0 to High(ProgramIR.Blocks) do
    if ProgramIR.Blocks[BlockId].FunctionId = FunctionId then Inc(Count);
  SetLength(Flow.Blocks, Count);
  Count := 0;
  for BlockId := 0 to High(ProgramIR.Blocks) do
    if ProgramIR.Blocks[BlockId].FunctionId = FunctionId then
    begin
      Flow.Blocks[Count] := BlockId;
      Inc(Count);
    end;
  SetLength(Flow.BlockInfo, Length(Flow.Blocks));
  if Length(Flow.BlockInfo) <> 0 then
    FillChar(Flow.BlockInfo[0], Length(Flow.BlockInfo) * SizeOf(TBlockDataFlow), 0);
  for BlockId := 0 to High(Flow.BlockInfo) do
  begin
    Flow.BlockInfo[BlockId].ReversePostOrder := FSIM_INVALID_INDEX;
    Flow.BlockInfo[BlockId].ImmediateDominator := FSIM_INVALID_INDEX;
    Flow.BlockInfo[BlockId].LoopHeader := FSIM_INVALID_INDEX;
    Flow.BlockInfo[BlockId].FirstUse := FSIM_INVALID_INDEX;
    Flow.BlockInfo[BlockId].LastUse := FSIM_INVALID_INDEX;
  end;
end;

procedure DepthFirstOrder(const ProgramIR: TIRProgram;
  var Flow: TFunctionDataFlow; LocalBlock: Int32;
  var Visited: array of Boolean; var PostOrder: array of Int32;
  var PostCount: Int32);
var
  GlobalBlock, EdgeIndex, SuccessorGlobal, SuccessorLocal: Int32;
begin
  if (LocalBlock < 0) or (LocalBlock > High(Visited)) or Visited[LocalBlock] then Exit;
  Visited[LocalBlock] := True;
  Flow.BlockInfo[LocalBlock].Reachable := True;
  GlobalBlock := Flow.Blocks[LocalBlock];
  for EdgeIndex := 0 to High(ProgramIR.Edges) do
    if ProgramIR.Edges[EdgeIndex].FromBlock = GlobalBlock then
    begin
      SuccessorGlobal := ProgramIR.Edges[EdgeIndex].ToBlock;
      SuccessorLocal := LocalBlockIndex(Flow, SuccessorGlobal);
      if SuccessorLocal >= 0 then
        DepthFirstOrder(ProgramIR, Flow, SuccessorLocal, Visited, PostOrder, PostCount);
    end;
  PostOrder[PostCount] := LocalBlock;
  Inc(PostCount);
end;

procedure ComputeReversePostOrder(const ProgramIR: TIRProgram;
  var Flow: TFunctionDataFlow);
var
  Visited: array of Boolean;
  PostOrder: array of Int32;
  EntryLocal, PostCount, Index, LocalBlock: Int32;
begin
  SetLength(Visited, Length(Flow.Blocks));
  SetLength(PostOrder, Length(Flow.Blocks));
  SetLength(Flow.ReversePostOrder, 0);
  EntryLocal := LocalBlockIndex(Flow, Flow.EntryBlock);
  PostCount := 0;
  if EntryLocal >= 0 then
    DepthFirstOrder(ProgramIR, Flow, EntryLocal, Visited, PostOrder, PostCount);
  SetLength(Flow.ReversePostOrder, PostCount);
  for Index := 0 to PostCount - 1 do
  begin
    LocalBlock := PostOrder[PostCount - Index - 1];
    Flow.ReversePostOrder[Index] := LocalBlock;
    Flow.BlockInfo[LocalBlock].ReversePostOrder := Index;
  end;
end;

procedure InitializeDominators(var Flow: TFunctionDataFlow);
var
  BlockIndex, EntryLocal: Int32;
begin
  SetLength(Flow.Dominators, Length(Flow.Blocks));
  EntryLocal := LocalBlockIndex(Flow, Flow.EntryBlock);
  for BlockIndex := 0 to High(Flow.Blocks) do
  begin
    BitSetInit(Flow.Dominators[BlockIndex], Length(Flow.Blocks));
    if not Flow.BlockInfo[BlockIndex].Reachable then Continue;
    if BlockIndex = EntryLocal then
      BitSetInclude(Flow.Dominators[BlockIndex], BlockIndex)
    else
      BitSetFill(Flow.Dominators[BlockIndex]);
  end;
end;

procedure ComputeDominators(const ProgramIR: TIRProgram;
  var Flow: TFunctionDataFlow);
var
  Changed, HavePredecessor: Boolean;
  RPOIndex, LocalBlock, GlobalBlock, EdgeIndex, PredLocal: Int32;
  NewSet: TIRBitSet;
begin
  InitializeDominators(Flow);
  repeat
    Changed := False;
    for RPOIndex := 1 to High(Flow.ReversePostOrder) do
    begin
      LocalBlock := Flow.ReversePostOrder[RPOIndex];
      GlobalBlock := Flow.Blocks[LocalBlock];
      BitSetInit(NewSet, Length(Flow.Blocks));
      HavePredecessor := False;
      for EdgeIndex := 0 to High(ProgramIR.Edges) do
        if ProgramIR.Edges[EdgeIndex].ToBlock = GlobalBlock then
        begin
          PredLocal := LocalBlockIndex(Flow, ProgramIR.Edges[EdgeIndex].FromBlock);
          if (PredLocal < 0) or not Flow.BlockInfo[PredLocal].Reachable then Continue;
          if not HavePredecessor then
          begin
            AssignBitSet(NewSet, Flow.Dominators[PredLocal]);
            HavePredecessor := True;
          end
          else
            BitSetIntersectInto(NewSet, Flow.Dominators[PredLocal]);
        end;
      if not HavePredecessor then BitSetClear(NewSet);
      BitSetInclude(NewSet, LocalBlock);
      if not BitSetEqual(NewSet, Flow.Dominators[LocalBlock]) then
      begin
        AssignBitSet(Flow.Dominators[LocalBlock], NewSet);
        Changed := True;
      end;
      SetLength(NewSet.Words, 0);
    end;
  until not Changed;
end;

function StrictDominatorDepth(const Flow: TFunctionDataFlow;
  BlockIndex: Int32): Int32;
begin
  Result := BitSetCount(Flow.Dominators[BlockIndex]) - 1;
  if Result < 0 then Result := 0;
end;

procedure ComputeImmediateDominators(var Flow: TFunctionDataFlow);
var
  BlockIndex, Candidate, Other, Best: Int32;
  IsImmediate: Boolean;
begin
  for BlockIndex := 0 to High(Flow.Blocks) do
  begin
    Flow.BlockInfo[BlockIndex].DominatorDepth := StrictDominatorDepth(Flow, BlockIndex);
    if Flow.Blocks[BlockIndex] = Flow.EntryBlock then Continue;
    Best := FSIM_INVALID_INDEX;
    for Candidate := 0 to High(Flow.Blocks) do
    begin
      if (Candidate = BlockIndex) or
        not BitSetContains(Flow.Dominators[BlockIndex], Candidate) then Continue;
      IsImmediate := True;
      for Other := 0 to High(Flow.Blocks) do
        if (Other <> Candidate) and (Other <> BlockIndex) and
          BitSetContains(Flow.Dominators[BlockIndex], Other) and
          BitSetContains(Flow.Dominators[Other], Candidate) then
        begin
          IsImmediate := False;
          Break;
        end;
      if IsImmediate then
      begin
        Best := Candidate;
        Break;
      end;
    end;
    if Best >= 0 then
      Flow.BlockInfo[BlockIndex].ImmediateDominator := Flow.Blocks[Best];
  end;
end;

procedure AddLoop(var Flow: TFunctionDataFlow; HeaderLocal, LatchLocal: Int32);
var
  LoopIndex: Int32;
begin
  LoopIndex := Length(Flow.Loops);
  SetLength(Flow.Loops, LoopIndex + 1);
  Flow.Loops[LoopIndex] := Default(TLoopDescriptor);
  Flow.Loops[LoopIndex].HeaderBlock := Flow.Blocks[HeaderLocal];
  Flow.Loops[LoopIndex].LatchBlock := Flow.Blocks[LatchLocal];
  Flow.Loops[LoopIndex].ParentLoop := FSIM_INVALID_INDEX;
  Flow.Loops[LoopIndex].Depth := 1;
end;

procedure DiscoverLoops(const ProgramIR: TIRProgram;
  var Flow: TFunctionDataFlow);
var
  EdgeIndex, FromLocal, ToLocal, LoopIndex, BlockIndex: Int32;
begin
  SetLength(Flow.Loops, 0);
  for EdgeIndex := 0 to High(ProgramIR.Edges) do
  begin
    FromLocal := LocalBlockIndex(Flow, ProgramIR.Edges[EdgeIndex].FromBlock);
    ToLocal := LocalBlockIndex(Flow, ProgramIR.Edges[EdgeIndex].ToBlock);
    if (FromLocal < 0) or (ToLocal < 0) then Continue;
    if BitSetContains(Flow.Dominators[FromLocal], ToLocal) then
      AddLoop(Flow, ToLocal, FromLocal);
  end;
  for LoopIndex := 0 to High(Flow.Loops) do
    for BlockIndex := 0 to High(Flow.Blocks) do
      if BitSetContains(Flow.Dominators[BlockIndex],
        LocalBlockIndex(Flow, Flow.Loops[LoopIndex].HeaderBlock)) and
        (Flow.BlockInfo[BlockIndex].ReversePostOrder <=
         Flow.BlockInfo[LocalBlockIndex(Flow, Flow.Loops[LoopIndex].LatchBlock)].ReversePostOrder) then
      begin
        Inc(Flow.Loops[LoopIndex].MemberCount);
        Inc(Flow.BlockInfo[BlockIndex].LoopDepth);
        if Flow.BlockInfo[BlockIndex].LoopHeader < 0 then
          Flow.BlockInfo[BlockIndex].LoopHeader := Flow.Loops[LoopIndex].HeaderBlock;
      end;
end;

procedure MarkUse(var Flow: TFunctionDataFlow; BlockLocal, ValueId: Int32);
begin
  if (ValueId < 0) or (ValueId >= Flow.BlockUses[BlockLocal].BitCount) then Exit;
  if not BitSetContains(Flow.Defines[BlockLocal], ValueId) then
    BitSetInclude(Flow.BlockUses[BlockLocal], ValueId);
end;

procedure BuildUseDef(const ProgramIR: TIRProgram;
  var Flow: TFunctionDataFlow);
var
  BlockLocal, InstructionIndex, GlobalBlock: Int32;
  Inst: TIRInstruction;
begin
  SetLength(Flow.BlockUses, Length(Flow.Blocks));
  SetLength(Flow.Defines, Length(Flow.Blocks));
  SetLength(Flow.LiveIn, Length(Flow.Blocks));
  SetLength(Flow.LiveOut, Length(Flow.Blocks));
  for BlockLocal := 0 to High(Flow.Blocks) do
  begin
    BitSetInit(Flow.BlockUses[BlockLocal], Length(ProgramIR.Values));
    BitSetInit(Flow.Defines[BlockLocal], Length(ProgramIR.Values));
    BitSetInit(Flow.LiveIn[BlockLocal], Length(ProgramIR.Values));
    BitSetInit(Flow.LiveOut[BlockLocal], Length(ProgramIR.Values));
    GlobalBlock := Flow.Blocks[BlockLocal];
    for InstructionIndex := 0 to High(ProgramIR.Instructions) do
    begin
      Inst := ProgramIR.Instructions[InstructionIndex];
      if (Inst.BlockId <> GlobalBlock) or (iifRemoved in Inst.Flags) then Continue;
      MarkUse(Flow, BlockLocal, Inst.A);
      MarkUse(Flow, BlockLocal, Inst.B);
      MarkUse(Flow, BlockLocal, Inst.C);
      if (Inst.Dst >= 0) and (Inst.Dst < Length(ProgramIR.Values)) then
        BitSetInclude(Flow.Defines[BlockLocal], Inst.Dst);
    end;
  end;
end;

procedure ComputeLiveness(const ProgramIR: TIRProgram;
  var Flow: TFunctionDataFlow);
var
  Changed: Boolean;
  RPOIndex, BlockLocal, GlobalBlock, EdgeIndex, SuccessorLocal: Int32;
  NewIn, NewOut: TIRBitSet;
begin
  repeat
    Changed := False;
    for RPOIndex := High(Flow.ReversePostOrder) downto 0 do
    begin
      BlockLocal := Flow.ReversePostOrder[RPOIndex];
      GlobalBlock := Flow.Blocks[BlockLocal];
      BitSetInit(NewOut, Length(ProgramIR.Values));
      for EdgeIndex := 0 to High(ProgramIR.Edges) do
        if ProgramIR.Edges[EdgeIndex].FromBlock = GlobalBlock then
        begin
          SuccessorLocal := LocalBlockIndex(Flow,
            ProgramIR.Edges[EdgeIndex].ToBlock);
          if SuccessorLocal >= 0 then
            BitSetUnionInto(NewOut, Flow.LiveIn[SuccessorLocal]);
        end;
      AssignBitSet(NewIn, NewOut);
      BitSetSubtractInto(NewIn, Flow.Defines[BlockLocal]);
      BitSetUnionInto(NewIn, Flow.BlockUses[BlockLocal]);
      if not BitSetEqual(NewOut, Flow.LiveOut[BlockLocal]) then
      begin
        AssignBitSet(Flow.LiveOut[BlockLocal], NewOut);
        Changed := True;
      end;
      if not BitSetEqual(NewIn, Flow.LiveIn[BlockLocal]) then
      begin
        AssignBitSet(Flow.LiveIn[BlockLocal], NewIn);
        Changed := True;
      end;
      SetLength(NewIn.Words, 0);
      SetLength(NewOut.Words, 0);
    end;
  until not Changed;
end;

procedure AnalyzeFunction(const ProgramIR: TIRProgram;
  FunctionId: Int32; var Flow: TFunctionDataFlow);
begin
  CollectFunctionBlocks(ProgramIR, FunctionId, Flow);
  ComputeReversePostOrder(ProgramIR, Flow);
  ComputeDominators(ProgramIR, Flow);
  ComputeImmediateDominators(Flow);
  DiscoverLoops(ProgramIR, Flow);
  BuildUseDef(ProgramIR, Flow);
  ComputeLiveness(ProgramIR, Flow);
end;

procedure DataFlowAnalyze(const ProgramIR: TIRProgram;
  var DataFlow: TProgramDataFlow);
var
  FunctionId: Int32;
begin
  DataFlowClear(DataFlow);
  SetLength(DataFlow.Functions, Length(ProgramIR.Functions));
  for FunctionId := 0 to High(ProgramIR.Functions) do
    AnalyzeFunction(ProgramIR, FunctionId, DataFlow.Functions[FunctionId]);
end;

function DataFlowDominates(const DataFlow: TProgramDataFlow;
  FunctionId, DominatorBlock, BlockId: Int32): Boolean;
var
  DominatorLocal, BlockLocal: Int32;
begin
  if (FunctionId < 0) or (FunctionId > High(DataFlow.Functions)) then Exit(False);
  DominatorLocal := LocalBlockIndex(DataFlow.Functions[FunctionId], DominatorBlock);
  BlockLocal := LocalBlockIndex(DataFlow.Functions[FunctionId], BlockId);
  Result := (DominatorLocal >= 0) and (BlockLocal >= 0) and
    BitSetContains(DataFlow.Functions[FunctionId].Dominators[BlockLocal],
      DominatorLocal);
end;

function DataFlowLoopDepth(const DataFlow: TProgramDataFlow;
  FunctionId, BlockId: Int32): Int32;
var
  Local: Int32;
begin
  Result := 0;
  if (FunctionId < 0) or (FunctionId > High(DataFlow.Functions)) then Exit;
  Local := LocalBlockIndex(DataFlow.Functions[FunctionId], BlockId);
  if Local >= 0 then
    Result := DataFlow.Functions[FunctionId].BlockInfo[Local].LoopDepth;
end;

function DataFlowValueLiveAtExit(const DataFlow: TProgramDataFlow;
  FunctionId, BlockId, ValueId: Int32): Boolean;
var
  Local: Int32;
begin
  Result := False;
  if (FunctionId < 0) or (FunctionId > High(DataFlow.Functions)) then Exit;
  Local := LocalBlockIndex(DataFlow.Functions[FunctionId], BlockId);
  if Local >= 0 then
    Result := BitSetContains(DataFlow.Functions[FunctionId].LiveOut[Local], ValueId);
end;

end.

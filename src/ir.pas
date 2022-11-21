unit ir;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, core, diagnostics, ast, symbols;

const
  IR_INVALID_VALUE = -1;
  IR_INVALID_BLOCK = -1;
  IR_INVALID_FUNCTION = -1;

type
  TIROpcode = (
    irNop,
    irConstInt,
    irConstReal,
    irConstString,
    irConstNull,
    irMove,
    irLoadReceiver,
    irLoadSymbol,
    irStoreSymbol,
    irLoadField,
    irStoreField,
    irLoadElement,
    irStoreElement,
    irAddressOf,
    irProcedureAddress,
    irLoadIndirect,
    irStoreIndirect,
    irLoadForeignData,
    irStoreForeignData,
    irPointerOffset,
    irAddInt,
    irSubInt,
    irMulInt,
    irDivInt,
    irModInt,
    irRemInt,
    irNegInt,
    irAddReal,
    irSubReal,
    irMulReal,
    irDivReal,
    irNegReal,
    irPowerInt,
    irPowerReal,
    irShiftLeft,
    irShiftRight,
    irBitAnd,
    irBitOr,
    irBitXor,
    irLogicalNot,
    irCompareEqual,
    irCompareNotEqual,
    irCompareLess,
    irCompareLessEqual,
    irCompareGreater,
    irCompareGreaterEqual,
    irConvertIntToReal,
    irConvertRealToInt,
    irConvertIntWidth,
    irStringConcat,
    irStringCompare,
    irStringLength,
    irStringByte,
    irStringToInteger,
    irStringSlice,
    irStringDataPointer,
    irTextConcat,
    irTextCompare,
    irTextConstant,
    irTextStart,
    irTextLength,
    irTextMain,
    irTextPos,
    irTextSetPos,
    irTextMore,
    irTextGetChar,
    irTextPutChar,
    irTextSub,
    irTextStrip,
    irTextCopy,
    irTextGetInt,
    irTextGetReal,
    irTextGetFrac,
    irTextPutInt,
    irTextPutFix,
    irTextPutReal,
    irTextPutFrac,
    irTextRetain,
    irTextRelease,
    irStringRetain,
    irStringRelease,
    irAllocObject,
    irAllocArray,
    irAllocHandle,
    irInitObject,
    irQuaCheck,
    irRTTIOf,
    irTypeTest,
    irTypeExact,
    irVMTLookup,
    irParameter,
    irCall,
    irCallIndirect,
    irCallVirtual,
    irCallNative,
    irCallForeign,
    irCallForeignIndirect,
    irReturn,
    irBranch,
    irBranchCond,
    irSwitch,
    irPhi,
    irPrintText,
    irPrintInteger,
    irPrintReal,
    irPrintFixed,
    irPrintCharacter,
    irPrintNewLine,
    irReadInteger,
    irReadReal,
    irReadCharacter,
    irReadText,
    irAssert,
    irTryBegin,
    irTryEnd,
    irCatchBegin,
    irCatchEnd,
    irFinallyBegin,
    irFinallyEnd,
    irRaise,
    irThreadSpawn,
    irThreadJoin,
    irThreadCancel,
    irThreadYield,
    irFutureAwait,
    irChannelSend,
    irChannelReceive,
    irMutexLock,
    irMutexUnlock,
    irParallelBegin,
    irParallelEnd,
    irCriticalBegin,
    irCriticalEnd,
    irDeferBegin,
    irDeferEnd,
    irMemoryFence,
    irProcessDetach,
    irProcessResume,
    irProcessActivate,
    irProcessReactivate,
    irProcessDelay,
    irProcessHold,
    irProcessPassivate,
    irExitProcess,
    irUnreachable
  );

  TIRInstructionFlag = (
    iifNone,
    iifTerminator,
    iifSideEffect,
    iifMayTrap,
    iifVolatile,
    iifRemoved,
    iifSynthetic,
    iifNoOverflow,
    iifFastMath,
    iifTailCall
  );
  TIRInstructionFlags = set of TIRInstructionFlag;

  TIRInstruction = packed record
    Op: TIROpcode;
    Flags: TIRInstructionFlags;
    BlockId: Int32;
    FunctionId: Int32;
    Dst: Int32;
    A: Int32;
    B: Int32;
    C: Int32;
    TypeId: Int32;
    SymbolId: Int32;
    TargetBlock: Int32;
    AlternateBlock: Int32;
    Aux: Int32;
    StringId: Int32;
    Imm: Int64;
    RealImm: Double;
    Span: TSourceSpan;
  end;

  TIRBlockFlag = (
    ibfNone,
    ibfEntry,
    ibfExit,
    ibfLoopHeader,
    ibfLoopLatch,
    ibfExceptionHandler,
    ibfReachable,
    ibfSealed
  );
  TIRBlockFlags = set of TIRBlockFlag;

  TIRBasicBlock = packed record
    FunctionId: Int32;
    FirstInstruction: Int32;
    LastInstruction: Int32;
    FirstPredecessor: Int32;
    PredecessorCount: Int32;
    FirstSuccessor: Int32;
    SuccessorCount: Int32;
    Dominator: Int32;
    LoopDepth: Int16;
    Flags: TIRBlockFlags;
  end;

  TIREdge = packed record
    FromBlock: Int32;
    ToBlock: Int32;
  end;

  TIRFunctionFlag = (
    iffNone,
    iffEntry,
    iffMethod,
    iffVirtual,
    iffProcess,
    iffThread,
    iffLeaf,
    iffHasCalls,
    iffHasExceptions,
    iffNeedsFrame,
    iffExported
  );
  TIRFunctionFlags = set of TIRFunctionFlag;

  TIRFunction = packed record
    SymbolId: Int32;
    NameId: Int32;
    ReturnType: Int32;
    FirstBlock: Int32;
    BlockCount: Int32;
    EntryBlock: Int32;
    ExitBlock: Int32;
    FirstInstruction: Int32;
    InstructionCount: Int32;
    FirstValue: Int32;
    ValueCount: Int32;
    LocalStackSize: UInt32;
    SpillStackSize: UInt32;
    ParameterCount: UInt16;
    Flags: TIRFunctionFlags;
  end;

  TIRValueInfo = packed record
    TypeId: Int32;
    DefInstruction: Int32;
    FirstUse: Int32;
    LastUse: Int32;
    UseCount: UInt32;
    FunctionId: Int32;
    ConstantKnown: Boolean;
    ConstantInt: Int64;
    ConstantReal: Double;
  end;

  TIRProgram = record
    Functions: array of TIRFunction;
    Blocks: array of TIRBasicBlock;
    Instructions: array of TIRInstruction;
    Values: array of TIRValueInfo;
    Edges: array of TIREdge;
    Predecessors: TInt32Array;
    Successors: TInt32Array;
    Strings: TStringPool;
    EntryFunction: Int32;
  end;

  TIRBuilder = record
    ProgramIR: ^TIRProgram;
    Tree: ^TAST;
    Symbols: ^TSymbolTable;
    Diagnostics: ^TDiagnosticBag;
    Options: ^TCompilerOptions;
    CurrentFunction: Int32;
    CurrentBlock: Int32;
    CurrentResultValue: Int32;
    CurrentReceiverValue: Int32;
    BreakTargets: TInt32Array;
    ContinueTargets: TInt32Array;
    ExceptionTargets: TInt32Array;
    LabelSymbols: TInt32Array;
    LabelBlocks: TInt32Array;
  end;

procedure IRInit(var ProgramIR: TIRProgram);
procedure IRClear(var ProgramIR: TIRProgram);
function IRNewFunction(var ProgramIR: TIRProgram; SymbolId, NameId,
  ReturnType: Int32; Flags: TIRFunctionFlags): Int32;
function IRNewBlock(var ProgramIR: TIRProgram; FunctionId: Int32;
  Flags: TIRBlockFlags = []): Int32;
function IRNewValue(var ProgramIR: TIRProgram; FunctionId, TypeId: Int32): Int32;
function IREmit(var ProgramIR: TIRProgram; FunctionId, BlockId: Int32;
  Op: TIROpcode; Dst, A, B, C, TypeId, SymbolId, TargetBlock,
  AlternateBlock, Aux, StringId: Int32; Imm: Int64; RealImm: Double;
  const Span: TSourceSpan; Flags: TIRInstructionFlags = []): Int32;
function IRBlockTerminated(const ProgramIR: TIRProgram; BlockId: Int32): Boolean;
function IROpcodeName(Op: TIROpcode): RawByteString;
function IROpHasSideEffects(Op: TIROpcode): Boolean;
function IROpIsTerminator(Op: TIROpcode): Boolean;
function IROpMayTrap(Op: TIROpcode): Boolean;
procedure IRBuildEdges(var ProgramIR: TIRProgram);
procedure IRComputeUseLists(var ProgramIR: TIRProgram);
procedure IRVerify(const ProgramIR: TIRProgram);
procedure IRDump(const ProgramIR: TIRProgram; const Symbols: TSymbolTable);
procedure IRBuilderInit(var Builder: TIRBuilder; var ProgramIR: TIRProgram;
  var Tree: TAST; var Symbols: TSymbolTable; var Diagnostics: TDiagnosticBag;
  var Options: TCompilerOptions);
procedure LowerCompilationUnit(var Builder: TIRBuilder);

implementation

procedure IRInit(var ProgramIR: TIRProgram);
begin
  ProgramIR := Default(TIRProgram);
  BufferInit(ProgramIR.Strings.Bytes, 1024);
  ProgramIR.EntryFunction := IR_INVALID_FUNCTION;
end;

procedure IRClear(var ProgramIR: TIRProgram);
begin
  SetLength(ProgramIR.Functions, 0);
  SetLength(ProgramIR.Blocks, 0);
  SetLength(ProgramIR.Instructions, 0);
  SetLength(ProgramIR.Values, 0);
  SetLength(ProgramIR.Edges, 0);
  SetLength(ProgramIR.Predecessors, 0);
  SetLength(ProgramIR.Successors, 0);
  SetLength(ProgramIR.Strings.Entries, 0);
  BufferClear(ProgramIR.Strings.Bytes);
  ProgramIR.EntryFunction := IR_INVALID_FUNCTION;
end;

function IRNewFunction(var ProgramIR: TIRProgram; SymbolId, NameId,
  ReturnType: Int32; Flags: TIRFunctionFlags): Int32;
begin
  Result := Length(ProgramIR.Functions);
  SetLength(ProgramIR.Functions, Result + 1);
  ProgramIR.Functions[Result] := Default(TIRFunction);
  ProgramIR.Functions[Result].SymbolId := SymbolId;
  ProgramIR.Functions[Result].NameId := NameId;
  ProgramIR.Functions[Result].ReturnType := ReturnType;
  ProgramIR.Functions[Result].FirstBlock := Length(ProgramIR.Blocks);
  ProgramIR.Functions[Result].EntryBlock := IR_INVALID_BLOCK;
  ProgramIR.Functions[Result].ExitBlock := IR_INVALID_BLOCK;
  ProgramIR.Functions[Result].FirstInstruction := Length(ProgramIR.Instructions);
  ProgramIR.Functions[Result].FirstValue := Length(ProgramIR.Values);
  ProgramIR.Functions[Result].Flags := Flags;
end;

function IRNewBlock(var ProgramIR: TIRProgram; FunctionId: Int32;
  Flags: TIRBlockFlags): Int32;
begin
  if (FunctionId < 0) or (FunctionId > High(ProgramIR.Functions)) then
    raise ERangeError.Create('IR block has invalid function');
  Result := Length(ProgramIR.Blocks);
  SetLength(ProgramIR.Blocks, Result + 1);
  ProgramIR.Blocks[Result] := Default(TIRBasicBlock);
  ProgramIR.Blocks[Result].FunctionId := FunctionId;
  ProgramIR.Blocks[Result].FirstInstruction := IR_INVALID_VALUE;
  ProgramIR.Blocks[Result].LastInstruction := IR_INVALID_VALUE;
  ProgramIR.Blocks[Result].FirstPredecessor := IR_INVALID_VALUE;
  ProgramIR.Blocks[Result].FirstSuccessor := IR_INVALID_VALUE;
  ProgramIR.Blocks[Result].Dominator := IR_INVALID_BLOCK;
  ProgramIR.Blocks[Result].Flags := Flags;
  Inc(ProgramIR.Functions[FunctionId].BlockCount);
  if ProgramIR.Functions[FunctionId].EntryBlock = IR_INVALID_BLOCK then
  begin
    ProgramIR.Functions[FunctionId].EntryBlock := Result;
    Include(ProgramIR.Blocks[Result].Flags, ibfEntry);
  end;
end;

function IRNewValue(var ProgramIR: TIRProgram; FunctionId, TypeId: Int32): Int32;
begin
  Result := Length(ProgramIR.Values);
  SetLength(ProgramIR.Values, Result + 1);
  ProgramIR.Values[Result] := Default(TIRValueInfo);
  ProgramIR.Values[Result].TypeId := TypeId;
  ProgramIR.Values[Result].DefInstruction := IR_INVALID_VALUE;
  ProgramIR.Values[Result].FirstUse := IR_INVALID_VALUE;
  ProgramIR.Values[Result].LastUse := IR_INVALID_VALUE;
  ProgramIR.Values[Result].FunctionId := FunctionId;
  Inc(ProgramIR.Functions[FunctionId].ValueCount);
end;

function IROpHasSideEffects(Op: TIROpcode): Boolean;
begin
  Result := Op in [irStoreSymbol, irStoreField, irStoreElement, irStoreIndirect, irStoreForeignData,
    irStringRetain, irStringRelease, irStringSlice, irTextConcat, irTextSetPos, irTextGetChar,
    irTextPutChar, irTextGetInt, irTextGetReal, irTextGetFrac, irTextPutInt,
    irTextPutFix, irTextPutReal, irTextPutFrac, irTextRetain, irTextRelease,
    irAllocHandle, irInitObject, irTextCopy, irCall, irCallIndirect, irCallVirtual,
    irCallNative, irCallForeign, irCallForeignIndirect, irReturn, irBranch, irBranchCond, irSwitch, irPrintText,
    irPrintInteger, irPrintReal, irPrintFixed, irPrintCharacter, irPrintNewLine,
    irReadInteger, irReadReal, irReadCharacter, irReadText, irAssert,
    irTryBegin, irTryEnd, irCatchBegin, irCatchEnd, irFinallyBegin,
    irFinallyEnd, irRaise, irThreadSpawn, irThreadJoin, irThreadCancel,
    irThreadYield, irFutureAwait, irChannelSend, irChannelReceive,
    irMutexLock, irMutexUnlock, irParallelBegin, irParallelEnd,
    irCriticalBegin, irCriticalEnd, irDeferBegin, irDeferEnd, irMemoryFence,
    irProcessDetach,
    irProcessResume, irProcessActivate, irProcessReactivate, irProcessDelay,
    irProcessHold, irProcessPassivate, irExitProcess, irUnreachable];
end;

function IROpIsTerminator(Op: TIROpcode): Boolean;
begin
  Result := Op in [irReturn, irBranch, irBranchCond, irSwitch,
    irRaise, irExitProcess, irUnreachable];
end;

function IROpMayTrap(Op: TIROpcode): Boolean;
begin
  Result := Op in [irDivInt, irModInt, irRemInt, irDivReal, irLoadField,
    irStoreField, irLoadElement, irStoreElement, irLoadIndirect, irStoreIndirect, irAllocObject, irAllocArray,
    irAllocHandle, irQuaCheck, irStringSlice, irTextConcat, irTextGetChar, irTextPutChar, irTextSub,
    irTextStrip, irTextCopy, irTextGetInt, irTextGetReal, irTextGetFrac, irTextPutInt,
    irTextPutFix, irTextPutReal, irTextPutFrac,
    irCall, irCallIndirect, irCallVirtual, irCallNative, irCallForeign, irCallForeignIndirect, irAssert, irRaise,
    irThreadSpawn, irThreadJoin, irFutureAwait, irChannelSend,
    irChannelReceive, irMutexLock, irProcessResume, irProcessActivate, irProcessReactivate];
end;

function IREmit(var ProgramIR: TIRProgram; FunctionId, BlockId: Int32;
  Op: TIROpcode; Dst, A, B, C, TypeId, SymbolId, TargetBlock,
  AlternateBlock, Aux, StringId: Int32; Imm: Int64; RealImm: Double;
  const Span: TSourceSpan; Flags: TIRInstructionFlags): Int32;
begin
  if (BlockId < 0) or (BlockId > High(ProgramIR.Blocks)) then
    raise ERangeError.Create('IR instruction has invalid block');
  if ProgramIR.Blocks[BlockId].FunctionId <> FunctionId then
    raise EInvalidOp.Create('IR instruction function/block mismatch');
  Result := Length(ProgramIR.Instructions);
  SetLength(ProgramIR.Instructions, Result + 1);
  ProgramIR.Instructions[Result] := Default(TIRInstruction);
  ProgramIR.Instructions[Result].Op := Op;
  ProgramIR.Instructions[Result].Flags := Flags;
  if IROpHasSideEffects(Op) then Include(ProgramIR.Instructions[Result].Flags,
    iifSideEffect);
  if IROpIsTerminator(Op) then Include(ProgramIR.Instructions[Result].Flags,
    iifTerminator);
  if IROpMayTrap(Op) then Include(ProgramIR.Instructions[Result].Flags,
    iifMayTrap);
  ProgramIR.Instructions[Result].BlockId := BlockId;
  ProgramIR.Instructions[Result].FunctionId := FunctionId;
  ProgramIR.Instructions[Result].Dst := Dst;
  ProgramIR.Instructions[Result].A := A;
  ProgramIR.Instructions[Result].B := B;
  ProgramIR.Instructions[Result].C := C;
  ProgramIR.Instructions[Result].TypeId := TypeId;
  ProgramIR.Instructions[Result].SymbolId := SymbolId;
  ProgramIR.Instructions[Result].TargetBlock := TargetBlock;
  ProgramIR.Instructions[Result].AlternateBlock := AlternateBlock;
  ProgramIR.Instructions[Result].Aux := Aux;
  ProgramIR.Instructions[Result].StringId := StringId;
  ProgramIR.Instructions[Result].Imm := Imm;
  ProgramIR.Instructions[Result].RealImm := RealImm;
  ProgramIR.Instructions[Result].Span := Span;
  if ProgramIR.Blocks[BlockId].FirstInstruction = IR_INVALID_VALUE then
    ProgramIR.Blocks[BlockId].FirstInstruction := Result;
  ProgramIR.Blocks[BlockId].LastInstruction := Result;
  Inc(ProgramIR.Functions[FunctionId].InstructionCount);
  if Dst >= 0 then
  begin
    if Dst > High(ProgramIR.Values) then
      raise ERangeError.Create('IR destination value outside range');
    ProgramIR.Values[Dst].DefInstruction := Result;
  end;
end;

function IRBlockTerminated(const ProgramIR: TIRProgram; BlockId: Int32): Boolean;
var
  First, Last, InstructionId: Int32;
begin
  Result := False;
  if (BlockId < 0) or (BlockId > High(ProgramIR.Blocks)) then
    Exit;
  First := ProgramIR.Blocks[BlockId].FirstInstruction;
  Last := ProgramIR.Blocks[BlockId].LastInstruction;
  if (First < 0) or (Last < First) or
     (Last > High(ProgramIR.Instructions)) then
    Exit;
  for InstructionId := Last downto First do
    if (ProgramIR.Instructions[InstructionId].BlockId = BlockId) and
       not (iifRemoved in ProgramIR.Instructions[InstructionId].Flags) then
      Exit(IROpIsTerminator(ProgramIR.Instructions[InstructionId].Op));
end;

function IROpcodeName(Op: TIROpcode): RawByteString;
begin
  case Op of
    irNop: Result := 'nop';
    irConstInt: Result := 'const.i';
    irConstReal: Result := 'const.r';
    irConstString: Result := 'const.str';
    irConstNull: Result := 'const.null';
    irMove: Result := 'move';
    irLoadReceiver: Result := 'receiver.load';
    irLoadSymbol: Result := 'load.sym';
    irStoreSymbol: Result := 'store.sym';
    irLoadField: Result := 'load.field';
    irStoreField: Result := 'store.field';
    irLoadElement: Result := 'load.elem';
    irStoreElement: Result := 'store.elem';
    irAddressOf: Result := 'address.of';
    irProcedureAddress: Result := 'procedure.addr';
    irLoadIndirect: Result := 'load.indirect';
    irStoreIndirect: Result := 'store.indirect';
    irLoadForeignData: Result := 'load.foreign.data';
    irStoreForeignData: Result := 'store.foreign.data';
    irPointerOffset: Result := 'pointer.offset';
    irAddInt: Result := 'add.i';
    irSubInt: Result := 'sub.i';
    irMulInt: Result := 'mul.i';
    irDivInt: Result := 'div.i';
    irModInt: Result := 'mod.i';
    irRemInt: Result := 'rem.i';
    irNegInt: Result := 'neg.i';
    irAddReal: Result := 'add.r';
    irSubReal: Result := 'sub.r';
    irMulReal: Result := 'mul.r';
    irDivReal: Result := 'div.r';
    irNegReal: Result := 'neg.r';
    irPowerInt: Result := 'pow.i';
    irPowerReal: Result := 'pow.r';
    irShiftLeft: Result := 'shl';
    irShiftRight: Result := 'shr';
    irBitAnd: Result := 'and.bits';
    irBitOr: Result := 'or.bits';
    irBitXor: Result := 'xor.bits';
    irLogicalNot: Result := 'not';
    irCompareEqual: Result := 'cmp.eq';
    irCompareNotEqual: Result := 'cmp.ne';
    irCompareLess: Result := 'cmp.lt';
    irCompareLessEqual: Result := 'cmp.le';
    irCompareGreater: Result := 'cmp.gt';
    irCompareGreaterEqual: Result := 'cmp.ge';
    irConvertIntToReal: Result := 'conv.i.r';
    irConvertRealToInt: Result := 'conv.r.i';
    irConvertIntWidth: Result := 'conv.i.width';
    irStringConcat: Result := 'str.concat';
    irStringCompare: Result := 'str.compare';
    irStringLength: Result := 'str.length';
    irStringByte: Result := 'str.byte';
    irStringToInteger: Result := 'str.to_integer';
    irStringSlice: Result := 'str.slice';
    irTextConcat: Result := 'text.concat';
    irTextCompare: Result := 'text.compare';
    irTextConstant: Result := 'text.constant';
    irTextStart: Result := 'text.start';
    irTextLength: Result := 'text.length';
    irTextMain: Result := 'text.main';
    irTextPos: Result := 'text.pos';
    irTextSetPos: Result := 'text.setpos';
    irTextMore: Result := 'text.more';
    irTextGetChar: Result := 'text.getchar';
    irTextPutChar: Result := 'text.putchar';
    irTextSub: Result := 'text.sub';
    irTextStrip: Result := 'text.strip';
    irTextCopy: Result := 'text.copy';
    irTextGetInt: Result := 'text.getint';
    irTextGetReal: Result := 'text.getreal';
    irTextGetFrac: Result := 'text.getfrac';
    irTextPutInt: Result := 'text.putint';
    irTextPutFix: Result := 'text.putfix';
    irTextPutReal: Result := 'text.putreal';
    irTextPutFrac: Result := 'text.putfrac';
    irTextRetain: Result := 'text.retain';
    irTextRelease: Result := 'text.release';
    irStringRetain: Result := 'str.retain';
    irStringRelease: Result := 'str.release';
    irAllocObject: Result := 'object.alloc';
    irAllocArray: Result := 'array.alloc';
    irAllocHandle: Result := 'handle.alloc';
    irInitObject: Result := 'object.init';
    irQuaCheck: Result := 'qua.check';
    irRTTIOf: Result := 'rtti.of';
    irTypeTest: Result := 'rtti.in';
    irTypeExact: Result := 'rtti.is';
    irVMTLookup: Result := 'vmt.lookup';
    irParameter: Result := 'param';
    irCall: Result := 'call';
    irCallIndirect: Result := 'call.indirect';
    irCallVirtual: Result := 'call.virtual';
    irCallNative: Result := 'call.native';
    irCallForeign: Result := 'call.foreign';
    irCallForeignIndirect: Result := 'call.foreign.indirect';
    irReturn: Result := 'return';
    irBranch: Result := 'br';
    irBranchCond: Result := 'br.cond';
    irSwitch: Result := 'switch';
    irPhi: Result := 'phi';
    irPrintText: Result := 'print.text';
    irPrintInteger: Result := 'print.int';
    irPrintReal: Result := 'print.real';
    irPrintFixed: Result := 'print.fixed';
    irPrintCharacter: Result := 'print.char';
    irPrintNewLine: Result := 'print.nl';
    irReadInteger: Result := 'read.int';
    irReadReal: Result := 'read.real';
    irReadCharacter: Result := 'read.char';
    irReadText: Result := 'read.text';
    irAssert: Result := 'assert';
    irTryBegin: Result := 'try.begin';
    irTryEnd: Result := 'try.end';
    irCatchBegin: Result := 'catch.begin';
    irCatchEnd: Result := 'catch.end';
    irFinallyBegin: Result := 'finally.begin';
    irFinallyEnd: Result := 'finally.end';
    irRaise: Result := 'raise';
    irThreadSpawn: Result := 'thread.spawn';
    irThreadJoin: Result := 'thread.join';
    irThreadCancel: Result := 'thread.cancel';
    irThreadYield: Result := 'thread.yield';
    irFutureAwait: Result := 'future.await';
    irChannelSend: Result := 'channel.send';
    irChannelReceive: Result := 'channel.receive';
    irMutexLock: Result := 'mutex.lock';
    irMutexUnlock: Result := 'mutex.unlock';
    irParallelBegin: Result := 'parallel.begin';
    irParallelEnd: Result := 'parallel.end';
    irCriticalBegin: Result := 'critical.begin';
    irCriticalEnd: Result := 'critical.end';
    irDeferBegin: Result := 'defer.begin';
    irDeferEnd: Result := 'defer.end';
    irMemoryFence: Result := 'memory.fence';
    irProcessDetach: Result := 'process.detach';
    irProcessResume: Result := 'process.resume';
    irProcessActivate: Result := 'process.activate';
    irProcessReactivate: Result := 'process.reactivate';
    irProcessDelay: Result := 'process.delay';
    irProcessHold: Result := 'process.hold';
    irProcessPassivate: Result := 'process.passivate';
    irExitProcess: Result := 'exit';
    irUnreachable: Result := 'unreachable';
  else
    Result := '?';
  end;
end;

procedure AddEdge(var ProgramIR: TIRProgram; FromBlock, ToBlock: Int32);
var
  N: Integer;
begin
  if (FromBlock < 0) or (ToBlock < 0) then
    Exit;
  if (FromBlock > High(ProgramIR.Blocks)) or
     (ToBlock > High(ProgramIR.Blocks)) then
    raise EInvalidOp.CreateFmt('IR edge %d -> %d references invalid block',
      [FromBlock, ToBlock]);
  N := Length(ProgramIR.Edges);
  SetLength(ProgramIR.Edges, N + 1);
  ProgramIR.Edges[N].FromBlock := FromBlock;
  ProgramIR.Edges[N].ToBlock := ToBlock;
end;

procedure IRBuildEdges(var ProgramIR: TIRProgram);
var
  I, J, P, S, Last: Integer;
  Inst: TIRInstruction;
begin
  SetLength(ProgramIR.Edges, 0);
  for I := 0 to High(ProgramIR.Blocks) do
  begin
    ProgramIR.Blocks[I].PredecessorCount := 0;
    ProgramIR.Blocks[I].SuccessorCount := 0;
    Last := ProgramIR.Blocks[I].LastInstruction;
    if Last < 0 then Continue;
    if ProgramIR.Blocks[I].FirstInstruction < 0 then
      raise EInvalidOp.CreateFmt('block %d has a last instruction but no first instruction',
        [I]);
    if Last > High(ProgramIR.Instructions) then
      raise EInvalidOp.CreateFmt('block %d has invalid last instruction %d',
        [I, Last]);
    while (Last >= ProgramIR.Blocks[I].FirstInstruction) and
          ((ProgramIR.Instructions[Last].BlockId <> I) or
           (iifRemoved in ProgramIR.Instructions[Last].Flags)) do
      Dec(Last);
    if (Last < 0) or
       (Last < ProgramIR.Blocks[I].FirstInstruction) then
      Continue;
    Inst := ProgramIR.Instructions[Last];
    case Inst.Op of
      irBranch: AddEdge(ProgramIR, I, Inst.TargetBlock);
      irBranchCond:
        begin
          AddEdge(ProgramIR, I, Inst.TargetBlock);
          AddEdge(ProgramIR, I, Inst.AlternateBlock);
        end;
    end;
  end;
  for I := 0 to High(ProgramIR.Edges) do
  begin
    Inc(ProgramIR.Blocks[ProgramIR.Edges[I].FromBlock].SuccessorCount);
    Inc(ProgramIR.Blocks[ProgramIR.Edges[I].ToBlock].PredecessorCount);
  end;
  P := 0;
  S := 0;
  for I := 0 to High(ProgramIR.Blocks) do
  begin
    ProgramIR.Blocks[I].FirstPredecessor := P;
    ProgramIR.Blocks[I].FirstSuccessor := S;
    Inc(P, ProgramIR.Blocks[I].PredecessorCount);
    Inc(S, ProgramIR.Blocks[I].SuccessorCount);
    ProgramIR.Blocks[I].PredecessorCount := 0;
    ProgramIR.Blocks[I].SuccessorCount := 0;
  end;
  SetLength(ProgramIR.Predecessors, P);
  SetLength(ProgramIR.Successors, S);
  for J := 0 to High(ProgramIR.Edges) do
  begin
    I := ProgramIR.Edges[J].ToBlock;
    P := ProgramIR.Blocks[I].FirstPredecessor +
      ProgramIR.Blocks[I].PredecessorCount;
    ProgramIR.Predecessors[P] := ProgramIR.Edges[J].FromBlock;
    Inc(ProgramIR.Blocks[I].PredecessorCount);
    I := ProgramIR.Edges[J].FromBlock;
    S := ProgramIR.Blocks[I].FirstSuccessor +
      ProgramIR.Blocks[I].SuccessorCount;
    ProgramIR.Successors[S] := ProgramIR.Edges[J].ToBlock;
    Inc(ProgramIR.Blocks[I].SuccessorCount);
  end;
end;

procedure NoteUse(var ProgramIR: TIRProgram; ValueId, InstructionId: Int32);
begin
  if ValueId < 0 then Exit;
  if ValueId > High(ProgramIR.Values) then
    raise EInvalidOp.Create('IR use references invalid value');
  if ProgramIR.Values[ValueId].FirstUse < 0 then
    ProgramIR.Values[ValueId].FirstUse := InstructionId;
  ProgramIR.Values[ValueId].LastUse := InstructionId;
  Inc(ProgramIR.Values[ValueId].UseCount);
end;

procedure IRComputeUseLists(var ProgramIR: TIRProgram);
var
  I: Integer;
begin
  for I := 0 to High(ProgramIR.Values) do
  begin
    ProgramIR.Values[I].FirstUse := IR_INVALID_VALUE;
    ProgramIR.Values[I].LastUse := IR_INVALID_VALUE;
    ProgramIR.Values[I].UseCount := 0;
  end;
  for I := 0 to High(ProgramIR.Instructions) do
    if not (iifRemoved in ProgramIR.Instructions[I].Flags) then
    begin
      NoteUse(ProgramIR, ProgramIR.Instructions[I].A, I);
      NoteUse(ProgramIR, ProgramIR.Instructions[I].B, I);
      NoteUse(ProgramIR, ProgramIR.Instructions[I].C, I);
    end;
end;

procedure IRVerify(const ProgramIR: TIRProgram);
var
  I, B, F, Last: Integer;
  Inst: TIRInstruction;
begin
  for I := 0 to High(ProgramIR.Instructions) do
  begin
    Inst := ProgramIR.Instructions[I];
    if (Inst.FunctionId < 0) or (Inst.FunctionId > High(ProgramIR.Functions)) then
      raise EInvalidOp.CreateFmt('instruction %d has invalid function', [I]);
    if (Inst.BlockId < 0) or (Inst.BlockId > High(ProgramIR.Blocks)) then
      raise EInvalidOp.CreateFmt('instruction %d has invalid block', [I]);
    if ProgramIR.Blocks[Inst.BlockId].FunctionId <> Inst.FunctionId then
      raise EInvalidOp.CreateFmt('instruction %d function/block mismatch', [I]);
    if (Inst.Dst >= 0) and (Inst.Dst > High(ProgramIR.Values)) then
      raise EInvalidOp.CreateFmt('instruction %d has invalid destination', [I]);
    if (Inst.A > High(ProgramIR.Values)) or (Inst.B > High(ProgramIR.Values)) or
       (Inst.C > High(ProgramIR.Values)) then
      raise EInvalidOp.CreateFmt('instruction %d has invalid operand', [I]);
    if (Inst.TargetBlock >= 0) and
       (Inst.TargetBlock > High(ProgramIR.Blocks)) then
      raise EInvalidOp.CreateFmt('instruction %d has invalid branch target', [I]);
    if (Inst.AlternateBlock >= 0) and
       (Inst.AlternateBlock > High(ProgramIR.Blocks)) then
      raise EInvalidOp.CreateFmt('instruction %d has invalid alternate target', [I]);
  end;
  for F := 0 to High(ProgramIR.Functions) do
    if (ProgramIR.Functions[F].EntryBlock < 0) or
       (ProgramIR.Functions[F].EntryBlock > High(ProgramIR.Blocks)) then
      raise EInvalidOp.CreateFmt('function %d has invalid entry block %d',
        [F, ProgramIR.Functions[F].EntryBlock]);
  for B := 0 to High(ProgramIR.Blocks) do
  begin
    F := ProgramIR.Blocks[B].FunctionId;
    if (F < 0) or (F > High(ProgramIR.Functions)) then
      raise EInvalidOp.CreateFmt('block %d has invalid function', [B]);
    if (ProgramIR.Blocks[B].FirstInstruction < IR_INVALID_VALUE) or
       (ProgramIR.Blocks[B].LastInstruction < IR_INVALID_VALUE) or
       (ProgramIR.Blocks[B].FirstInstruction > High(ProgramIR.Instructions)) or
       (ProgramIR.Blocks[B].LastInstruction > High(ProgramIR.Instructions)) then
      raise EInvalidOp.CreateFmt('block %d has invalid instruction bounds %d..%d',
        [B, ProgramIR.Blocks[B].FirstInstruction,
         ProgramIR.Blocks[B].LastInstruction]);
    Last := ProgramIR.Blocks[B].LastInstruction;
    if Last >= 0 then
    begin
      while (Last >= ProgramIR.Blocks[B].FirstInstruction) and
            ((ProgramIR.Instructions[Last].BlockId <> B) or
             (iifRemoved in ProgramIR.Instructions[Last].Flags)) do
        Dec(Last);
      if (Last >= ProgramIR.Blocks[B].FirstInstruction) and
         not IRBlockTerminated(ProgramIR, B) and
         not (ibfExit in ProgramIR.Blocks[B].Flags) then
        raise EInvalidOp.CreateFmt('block %d lacks a terminator', [B]);
    end;
  end;
end;

function ValueText(ValueId: Int32): RawByteString;
begin
  if ValueId < 0 then Result := '-' else Result := '%' + IntToStr(ValueId);
end;

procedure IRDump(const ProgramIR: TIRProgram; const Symbols: TSymbolTable);
var
  F, B, I: Integer;
  FunctionName: RawByteString;
  Inst: TIRInstruction;
begin
  for F := 0 to High(ProgramIR.Functions) do
  begin
    if ProgramIR.Functions[F].SymbolId >= 0 then
      FunctionName := SymName(Symbols, ProgramIR.Functions[F].SymbolId)
    else
      FunctionName := StringPoolGet(ProgramIR.Strings,
        ProgramIR.Functions[F].NameId);
    Writeln('function @', FunctionName, ' #', F, ' {');
    for B := ProgramIR.Functions[F].FirstBlock to
      ProgramIR.Functions[F].FirstBlock + ProgramIR.Functions[F].BlockCount - 1 do
    begin
      Writeln('  block.', B, ':');
      if ProgramIR.Blocks[B].FirstInstruction >= 0 then
        for I := ProgramIR.Blocks[B].FirstInstruction to
          ProgramIR.Blocks[B].LastInstruction do
        begin
          Inst := ProgramIR.Instructions[I];
          if Inst.BlockId <> B then Continue;
          Write('    ', I:5, ' ');
          if Inst.Dst >= 0 then Write(ValueText(Inst.Dst), ' = ');
          Write(IROpcodeName(Inst.Op));
          if Inst.A >= 0 then Write(' ', ValueText(Inst.A));
          if Inst.B >= 0 then Write(', ', ValueText(Inst.B));
          if Inst.C >= 0 then Write(', ', ValueText(Inst.C));
          if Inst.SymbolId >= 0 then
            Write(' @', SymName(Symbols, Inst.SymbolId));
          if Inst.StringId >= 0 then
            Write(' "', StringPoolGet(ProgramIR.Strings, Inst.StringId), '"');
          if Inst.Op = irConstInt then Write(' ', Inst.Imm);
          if Inst.Op = irConstReal then Write(' ', Inst.RealImm:0:8);
          if Inst.TargetBlock >= 0 then Write(' block.', Inst.TargetBlock);
          if Inst.AlternateBlock >= 0 then Write(', block.', Inst.AlternateBlock);
          if iifRemoved in Inst.Flags then Write(' ; removed');
          Writeln;
        end;
    end;
    Writeln('}');
  end;
end;

procedure IRBuilderInit(var Builder: TIRBuilder; var ProgramIR: TIRProgram;
  var Tree: TAST; var Symbols: TSymbolTable; var Diagnostics: TDiagnosticBag;
  var Options: TCompilerOptions);
begin
  Builder := Default(TIRBuilder);
  Builder.ProgramIR := @ProgramIR;
  Builder.Tree := @Tree;
  Builder.Symbols := @Symbols;
  Builder.Diagnostics := @Diagnostics;
  Builder.Options := @Options;
  Builder.CurrentFunction := IR_INVALID_FUNCTION;
  Builder.CurrentBlock := IR_INVALID_BLOCK;
end;

function NewValue(var Builder: TIRBuilder; TypeId: Int32): Int32; inline;
begin
  Result := IRNewValue(Builder.ProgramIR^, Builder.CurrentFunction, TypeId);
end;

function Emit(var Builder: TIRBuilder; Op: TIROpcode; Dst, A, B, C,
  TypeId, SymbolId, TargetBlock, AlternateBlock, Aux, StringId: Int32;
  Imm: Int64; RealImm: Double; const Span: TSourceSpan;
  Flags: TIRInstructionFlags = []): Int32; inline;
begin
  Result := IREmit(Builder.ProgramIR^, Builder.CurrentFunction,
    Builder.CurrentBlock, Op, Dst, A, B, C, TypeId, SymbolId, TargetBlock,
    AlternateBlock, Aux, StringId, Imm, RealImm, Span, Flags);
end;

procedure SetBlock(var Builder: TIRBuilder; BlockId: Int32);
begin
  if (BlockId < 0) or (BlockId > High(Builder.ProgramIR^.Blocks)) then
    raise ERangeError.Create('cannot select invalid IR block');
  Builder.CurrentBlock := BlockId;
end;

function NewBlock(var Builder: TIRBuilder; Flags: TIRBlockFlags = []): Int32;
begin
  Result := IRNewBlock(Builder.ProgramIR^, Builder.CurrentFunction, Flags);
end;

procedure EmitBranchIfNeeded(var Builder: TIRBuilder; TargetBlock: Int32;
  const Span: TSourceSpan);
begin
  if not IRBlockTerminated(Builder.ProgramIR^, Builder.CurrentBlock) then
    Emit(Builder, irBranch, IR_INVALID_VALUE, IR_INVALID_VALUE,
      IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID, FSIM_INVALID_INDEX,
      TargetBlock, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0, Span);
end;

procedure PushTarget(var Targets: TInt32Array; Value: Int32);
begin
  SetLength(Targets, Length(Targets) + 1);
  Targets[High(Targets)] := Value;
end;

procedure PopTarget(var Targets: TInt32Array);
begin
  if Length(Targets) = 0 then
    raise EInvalidOp.Create('target stack underflow');
  SetLength(Targets, Length(Targets) - 1);
end;

function TopTarget(const Targets: TInt32Array): Int32;
begin
  if Length(Targets) = 0 then Exit(IR_INVALID_BLOCK);
  Result := Targets[High(Targets)];
end;

function LabelBlock(var Builder: TIRBuilder; SymbolId: Int32): Int32;
var
  I, N: Int32;
begin
  for I := 0 to High(Builder.LabelSymbols) do
    if Builder.LabelSymbols[I] = SymbolId then
      Exit(Builder.LabelBlocks[I]);
  Result := NewBlock(Builder);
  N := Length(Builder.LabelSymbols);
  SetLength(Builder.LabelSymbols, N + 1);
  SetLength(Builder.LabelBlocks, N + 1);
  Builder.LabelSymbols[N] := SymbolId;
  Builder.LabelBlocks[N] := Result;
end;

procedure ResetFunctionLabels(var Builder: TIRBuilder);
begin
  SetLength(Builder.LabelSymbols, 0);
  SetLength(Builder.LabelBlocks, 0);
end;

function LowerExpression(var Builder: TIRBuilder; Node: Int32): Int32; forward;
procedure LowerNode(var Builder: TIRBuilder; Node: Int32); forward;

function CoerceValue(var Builder: TIRBuilder; ValueId, SourceType,
  TargetType: Int32; const Span: TSourceSpan): Int32;
var
  ZeroValue, MaskValue: Int32;
begin
  Result := ValueId;
  if (ValueId < 0) or (SourceType = TargetType) or
     (SourceType < 0) or (TargetType < 0) or
     (SourceType > High(Builder.Symbols^.Types)) or
     (TargetType > High(Builder.Symbols^.Types)) then
    Exit;

  if (Builder.Symbols^.Types[SourceType].Kind in [tyInteger, tyCInteger,
       tyBoolean, tyCharacter]) and
     (Builder.Symbols^.Types[TargetType].Kind in [tyReal, tyCReal]) then
  begin
    Result := NewValue(Builder, TargetType);
    Emit(Builder, irConvertIntToReal, Result, ValueId, IR_INVALID_VALUE,
      IR_INVALID_VALUE, TargetType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
      IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0, Span);
  end
  else if (Builder.Symbols^.Types[SourceType].Kind in [tyReal, tyCReal]) and
          (Builder.Symbols^.Types[TargetType].Kind in [tyInteger, tyCInteger]) then
  begin
    Result := NewValue(Builder, TargetType);
    Emit(Builder, irConvertRealToInt, Result, ValueId, IR_INVALID_VALUE,
      IR_INVALID_VALUE, TargetType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
      IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0, Span);
  end
  else if (Builder.Symbols^.Types[SourceType].Kind in [tyInteger, tyCInteger,
            tyBoolean, tyCharacter]) and
          (Builder.Symbols^.Types[TargetType].Kind in [tyInteger, tyCInteger]) then
  begin
    Result := NewValue(Builder, TargetType);
    Emit(Builder, irConvertIntWidth, Result, ValueId, IR_INVALID_VALUE,
      IR_INVALID_VALUE, TargetType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
      IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0, Span);
  end
  else if (Builder.Symbols^.Types[TargetType].Kind = tyBoolean) and
          (Builder.Symbols^.Types[SourceType].Kind in [tyInteger, tyCInteger,
            tyBoolean, tyCharacter]) then
  begin
    ZeroValue := NewValue(Builder, SourceType);
    Emit(Builder, irConstInt, ZeroValue, IR_INVALID_VALUE, IR_INVALID_VALUE,
      IR_INVALID_VALUE, SourceType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
      IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0, Span);
    Result := NewValue(Builder, TargetType);
    Emit(Builder, irCompareNotEqual, Result, ValueId, ZeroValue,
      IR_INVALID_VALUE, TargetType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
      IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0, Span);
  end
  else if (Builder.Symbols^.Types[TargetType].Kind = tyCharacter) and
          (Builder.Symbols^.Types[SourceType].Kind in [tyInteger, tyCInteger,
            tyBoolean, tyCharacter]) then
  begin
    MaskValue := NewValue(Builder, SourceType);
    Emit(Builder, irConstInt, MaskValue, IR_INVALID_VALUE, IR_INVALID_VALUE,
      IR_INVALID_VALUE, SourceType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
      IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 255, 0.0, Span);
    Result := NewValue(Builder, TargetType);
    Emit(Builder, irBitAnd, Result, ValueId, MaskValue, IR_INVALID_VALUE,
      TargetType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
      FSIM_INVALID_INDEX, 0, 0.0, Span);
  end
  else if (Builder.Symbols^.Types[SourceType].Kind in [tyReal, tyCReal]) and
          (Builder.Symbols^.Types[TargetType].Kind in [tyReal, tyCReal]) then
  begin
    { Reals use one canonical internal double representation, including
      c_float values between ABI/storage boundaries.  The conversion may not
      need arithmetic, but it absolutely must produce a value carrying the
      target type.  Otherwise c_double(1.5) can collapse back to an fsim real;
      fixed C parameters mask that mistake with their declared ABI type while
      variadic C arguments must classify the actual IR value themselves. }
    Result := NewValue(Builder, TargetType);
    Emit(Builder, irMove, Result, ValueId, IR_INVALID_VALUE, IR_INVALID_VALUE,
      TargetType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
      FSIM_INVALID_INDEX, 0, 0.0, Span);
  end
  else if (SourceType = FSIM_TYPE_STRING) and
          (TargetType = FSIM_TYPE_C_STRING) then
  begin
    Result := NewValue(Builder, TargetType);
    Emit(Builder, irStringDataPointer, Result, ValueId, IR_INVALID_VALUE,
      IR_INVALID_VALUE, TargetType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
      IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0, Span);
  end
  else if (Builder.Symbols^.Types[SourceType].Kind in [tyCPointer, tyCFunction]) and
          (Builder.Symbols^.Types[TargetType].Kind in [tyCPointer, tyCFunction]) then
  begin
    Result := NewValue(Builder, TargetType);
    Emit(Builder, irMove, Result, ValueId, IR_INVALID_VALUE, IR_INVALID_VALUE,
      TargetType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
      FSIM_INVALID_INDEX, 0, 0.0, Span);
  end
  else if ((Builder.Symbols^.Types[SourceType].Kind in [tyInteger, tyCInteger]) and
           (Builder.Symbols^.Types[TargetType].Kind = tyCPointer)) or
          ((Builder.Symbols^.Types[SourceType].Kind in [tyCPointer, tyCFunction]) and
           (Builder.Symbols^.Types[TargetType].Kind in [tyInteger, tyCInteger])) or
          ((SourceType = FSIM_TYPE_VOID) and
           (Builder.Symbols^.Types[TargetType].Kind = tyCPointer)) then
  begin
    Result := NewValue(Builder, TargetType);
    Emit(Builder, irMove, Result, ValueId, IR_INVALID_VALUE, IR_INVALID_VALUE,
      TargetType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
      FSIM_INVALID_INDEX, 0, 0.0, Span);
  end;
end;
procedure LowerClassConstruction(var Builder: TIRBuilder;
  ClassSymbol, ReceiverValue: Int32; ContinuationNode: Int32 = FSIM_INVALID_INDEX); forward;

function LoadCurrentReceiver(var Builder: TIRBuilder; TypeId, ClassSymbol: Int32;
  const Span: TSourceSpan): Int32;
begin
  if Builder.CurrentReceiverValue >= 0 then
    Exit(Builder.CurrentReceiverValue);
  Result := NewValue(Builder, TypeId);
  Emit(Builder, irLoadReceiver, Result, IR_INVALID_VALUE, IR_INVALID_VALUE,
    IR_INVALID_VALUE, TypeId, ClassSymbol, IR_INVALID_BLOCK,
    IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0, Span);
end;

function LowerIdentifier(var Builder: TIRBuilder; Node: Int32): Int32;
var
  SymbolId, TypeId, StringId, ReceiverValue, ReceiverType: Int32;
  Kind: TSymbolKind;
  ValueText: RawByteString;
begin
  SymbolId := Builder.Tree^.Nodes[Node].SymbolId;
  TypeId := Builder.Tree^.Nodes[Node].TypeId;
  if (SymbolId >= 0) and (SymbolId <= High(Builder.Symbols^.Symbols)) then
  begin
    Kind := Builder.Symbols^.Symbols[SymbolId].Kind;
    if Kind in [skConstant, skEnumValue] then
    begin
      Result := NewValue(Builder, TypeId);
      if TypeId = FSIM_TYPE_REAL then
        Emit(Builder, irConstReal, Result, IR_INVALID_VALUE, IR_INVALID_VALUE,
          IR_INVALID_VALUE, TypeId, SymbolId, IR_INVALID_BLOCK,
          IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0,
          Builder.Symbols^.Symbols[SymbolId].ConstantReal,
          Builder.Tree^.Nodes[Node].Span)
      else if TypeId in [FSIM_TYPE_TEXT, FSIM_TYPE_STRING] then
      begin
        ValueText := '';
        if Builder.Symbols^.Symbols[SymbolId].DeclNode >= 0 then
        begin
          StringId := ASTChildAt(Builder.Tree^,
            Builder.Symbols^.Symbols[SymbolId].DeclNode, 0);
          if StringId >= 0 then
            ValueText := ASTNodeString(Builder.Tree^, StringId);
        end;
        StringId := StringPoolIntern(Builder.ProgramIR^.Strings, ValueText);
        Emit(Builder, irConstString, Result, IR_INVALID_VALUE,
          IR_INVALID_VALUE, IR_INVALID_VALUE, TypeId, SymbolId,
          IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, StringId, 0, 0.0,
          Builder.Tree^.Nodes[Node].Span);
      end
      else
        Emit(Builder, irConstInt, Result, IR_INVALID_VALUE, IR_INVALID_VALUE,
          IR_INVALID_VALUE, TypeId, SymbolId, IR_INVALID_BLOCK,
          IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX,
          Builder.Symbols^.Symbols[SymbolId].ConstantInt, 0.0,
          Builder.Tree^.Nodes[Node].Span);
      Exit;
    end;
    if Kind in [skProcedure, skFunction] then
    begin
      Result := NewValue(Builder, TypeId);
      Emit(Builder, irProcedureAddress, Result, IR_INVALID_VALUE,
        IR_INVALID_VALUE, IR_INVALID_VALUE, TypeId, SymbolId,
        IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
        Builder.Tree^.Nodes[Node].Span);
      Exit;
    end;
    if (Kind = skVariable) and
       (sfForeign in Builder.Symbols^.Symbols[SymbolId].Flags) then
    begin
      Result := NewValue(Builder, TypeId);
      Emit(Builder, irLoadForeignData, Result, IR_INVALID_VALUE,
        IR_INVALID_VALUE, IR_INVALID_VALUE, TypeId, SymbolId,
        IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
        Builder.Tree^.Nodes[Node].Span);
      Exit;
    end;
    if Kind = skField then
    begin
      ReceiverType := SymMakeReferenceType(Builder.Symbols^,
        Builder.Symbols^.Symbols[SymbolId].OwnerSymbol);
      ReceiverValue := LoadCurrentReceiver(Builder, ReceiverType,
        Builder.Symbols^.Symbols[SymbolId].OwnerSymbol,
        Builder.Tree^.Nodes[Node].Span);
      Result := NewValue(Builder, TypeId);
      Emit(Builder, irLoadField, Result, ReceiverValue, IR_INVALID_VALUE,
        IR_INVALID_VALUE, TypeId, SymbolId, IR_INVALID_BLOCK,
        IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
        Builder.Tree^.Nodes[Node].Span);
      Exit;
    end;
  end;
  Result := NewValue(Builder, TypeId);
  Emit(Builder, irLoadSymbol, Result, IR_INVALID_VALUE, IR_INVALID_VALUE,
    IR_INVALID_VALUE, TypeId, SymbolId, IR_INVALID_BLOCK, IR_INVALID_BLOCK,
    0, FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
end;

function LowerMember(var Builder: TIRBuilder; Node: Int32): Int32;
var
  BaseNode, BaseValue, BaseType, SymbolId, TypeId, AuxValue: Int32;
  Intrinsic: TTextIntrinsic;
  Op: TIROpcode;
begin
  BaseNode := ASTChildAt(Builder.Tree^, Node, 0);
  BaseValue := LowerExpression(Builder, BaseNode);
  BaseType := Builder.Tree^.Nodes[BaseNode].TypeId;
  SymbolId := Builder.Tree^.Nodes[Node].SymbolId;
  TypeId := Builder.Tree^.Nodes[Node].TypeId;
  AuxValue := Builder.Tree^.Nodes[Node].Aux;

  { Aux is shared scratch space on AST nodes and ordinary members leave it at
    FSIM_INVALID_INDEX.  Never reinterpret that sentinel as an enum.  More
    importantly, only string/text bases can carry these intrinsics at all. }
  if (BaseType in [FSIM_TYPE_STRING, FSIM_TYPE_TEXT]) and
     (AuxValue >= Ord(Low(TTextIntrinsic))) and
     (AuxValue <= Ord(High(TTextIntrinsic))) then
    Intrinsic := TTextIntrinsic(AuxValue)
  else
    Intrinsic := tiNone;

  if Intrinsic <> tiNone then
  begin
    if BaseType = FSIM_TYPE_STRING then
      Op := irStringLength
    else
      case Intrinsic of
        tiConstant: Op := irTextConstant;
        tiStart: Op := irTextStart;
        tiLength: Op := irTextLength;
        tiMain: Op := irTextMain;
        tiPos: Op := irTextPos;
        tiMore: Op := irTextMore;
        tiGetChar: Op := irTextGetChar;
        tiStrip: Op := irTextStrip;
        tiGetInt: Op := irTextGetInt;
        tiGetReal: Op := irTextGetReal;
        tiGetFrac: Op := irTextGetFrac;
      else
        raise EInvalidOp.Create('text intrinsic requires explicit arguments');
      end;
    Result := NewValue(Builder, TypeId);
    Emit(Builder, Op, Result, BaseValue, IR_INVALID_VALUE, IR_INVALID_VALUE,
      TypeId, FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK,
      0, FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
    Exit;
  end;

  Result := NewValue(Builder, TypeId);
  Emit(Builder, irLoadField, Result, BaseValue, IR_INVALID_VALUE,
    IR_INVALID_VALUE, TypeId, SymbolId, IR_INVALID_BLOCK, IR_INVALID_BLOCK,
    0, FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
end;

function LowerBinary(var Builder: TIRBuilder; Node: Int32): Int32;
var
  LeftNode, RightNode, LeftValue, RightValue, TypeId: Int32;
  Op: TBinaryOperator;
  IROp: TIROpcode;
  RealResult, RealComparison: Boolean;
begin
  LeftNode := ASTChildAt(Builder.Tree^, Node, 0);
  RightNode := ASTChildAt(Builder.Tree^, Node, 1);
  LeftValue := LowerExpression(Builder, LeftNode);
  RightValue := LowerExpression(Builder, RightNode);
  TypeId := Builder.Tree^.Nodes[Node].TypeId;
  Op := TBinaryOperator(Builder.Tree^.Nodes[Node].Aux);
  RealResult := (TypeId >= 0) and (TypeId <= High(Builder.Symbols^.Types)) and
    (Builder.Symbols^.Types[TypeId].Kind in [tyReal, tyCReal]);
  RealComparison :=
    ((Builder.Tree^.Nodes[LeftNode].TypeId >= 0) and
     (Builder.Tree^.Nodes[LeftNode].TypeId <= High(Builder.Symbols^.Types)) and
     (Builder.Symbols^.Types[Builder.Tree^.Nodes[LeftNode].TypeId].Kind in
       [tyReal, tyCReal])) or
    ((Builder.Tree^.Nodes[RightNode].TypeId >= 0) and
     (Builder.Tree^.Nodes[RightNode].TypeId <= High(Builder.Symbols^.Types)) and
     (Builder.Symbols^.Types[Builder.Tree^.Nodes[RightNode].TypeId].Kind in
       [tyReal, tyCReal]));

  { Semantic analysis permits ordinary integer-to-real widening.  The old
    lowering forgot to materialize it, so mixed arithmetic could feed integer
    bits straight into an SSE double operation.  nasty bug, very boring fix. }
  if (Op in [boAdd, boSubtract, boMultiply, boRealDivide]) and
     RealResult then
  begin
    LeftValue := CoerceValue(Builder, LeftValue,
      Builder.Tree^.Nodes[LeftNode].TypeId, FSIM_TYPE_REAL,
      Builder.Tree^.Nodes[LeftNode].Span);
    RightValue := CoerceValue(Builder, RightValue,
      Builder.Tree^.Nodes[RightNode].TypeId, FSIM_TYPE_REAL,
      Builder.Tree^.Nodes[RightNode].Span);
  end
  else if (Op = boPower) and RealResult then
    LeftValue := CoerceValue(Builder, LeftValue,
      Builder.Tree^.Nodes[LeftNode].TypeId, FSIM_TYPE_REAL,
      Builder.Tree^.Nodes[LeftNode].Span)
  else if (Op in [boEqual, boNotEqual, boLess, boLessEqual,
      boGreater, boGreaterEqual]) and RealComparison then
  begin
    { IR real values are canonical 64-bit doubles even when the source type is
      C float. Use REAL as the comparison working type so mixed C integer/real
      expressions never fall into the integer comparator. }
    LeftValue := CoerceValue(Builder, LeftValue,
      Builder.Tree^.Nodes[LeftNode].TypeId, FSIM_TYPE_REAL,
      Builder.Tree^.Nodes[LeftNode].Span);
    RightValue := CoerceValue(Builder, RightValue,
      Builder.Tree^.Nodes[RightNode].TypeId, FSIM_TYPE_REAL,
      Builder.Tree^.Nodes[RightNode].Span);
  end;

  case Op of
    boConcat:
      if TypeId = FSIM_TYPE_TEXT then IROp := irTextConcat
      else IROp := irStringConcat;
    boAdd:
      if RealResult then IROp := irAddReal
      else if TypeId = FSIM_TYPE_STRING then IROp := irStringConcat
      else IROp := irAddInt;
    boSubtract: if RealResult then IROp := irSubReal else IROp := irSubInt;
    boMultiply: if RealResult then IROp := irMulReal else IROp := irMulInt;
    boRealDivide: IROp := irDivReal;
    boIntegerDivide: IROp := irDivInt;
    boModulo: IROp := irModInt;
    boRemainder: IROp := irRemInt;
    boPower: if RealResult then IROp := irPowerReal else IROp := irPowerInt;
    boShiftLeft: IROp := irShiftLeft;
    boShiftRight: IROp := irShiftRight;
    boBitwiseAnd, boLogicalAnd: IROp := irBitAnd;
    boBitwiseOr, boLogicalOr: IROp := irBitOr;
    boBitwiseXor: IROp := irBitXor;
    boReferenceEqual: IROp := irCompareEqual;
    boReferenceNotEqual: IROp := irCompareNotEqual;
    boEqual, boEquivalence:
      if Builder.Tree^.Nodes[LeftNode].TypeId = FSIM_TYPE_TEXT then
        IROp := irTextCompare
      else if Builder.Tree^.Nodes[LeftNode].TypeId = FSIM_TYPE_STRING then
        IROp := irStringCompare
      else
        IROp := irCompareEqual;
    boNotEqual:
      if Builder.Tree^.Nodes[LeftNode].TypeId in
        [FSIM_TYPE_TEXT, FSIM_TYPE_STRING] then
      begin
        Result := NewValue(Builder, FSIM_TYPE_BOOLEAN);
        if Builder.Tree^.Nodes[LeftNode].TypeId = FSIM_TYPE_TEXT then
          IROp := irTextCompare
        else
          IROp := irStringCompare;
        Emit(Builder, IROp, Result, LeftValue, RightValue,
          IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN, FSIM_INVALID_INDEX,
          IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX,
          0, 0.0, Builder.Tree^.Nodes[Node].Span);
        LeftValue := Result;
        RightValue := IR_INVALID_VALUE;
        IROp := irLogicalNot;
      end
      else
        IROp := irCompareNotEqual;
    boLess: IROp := irCompareLess;
    boLessEqual: IROp := irCompareLessEqual;
    boGreater: IROp := irCompareGreater;
    boGreaterEqual: IROp := irCompareGreaterEqual;
    boImplication:
      begin
        Result := NewValue(Builder, FSIM_TYPE_BOOLEAN);
        Emit(Builder, irLogicalNot, Result,
          LeftValue, IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN,
          FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
          FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
        LeftValue := Result;
        IROp := irBitOr;
      end;
  else
    IROp := irNop;
  end;
  Result := NewValue(Builder, TypeId);
  Emit(Builder, IROp, Result, LeftValue, RightValue, IR_INVALID_VALUE,
    TypeId, FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
    FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
end;

function LowerImplicitCall(var Builder: TIRBuilder; Node: Int32;
  ReceiverNode: Int32): Int32;
var
  SymbolId, ReceiverValue, OwnerSymbol, ReceiverType, ProcedureType: Int32;
  Op: TIROpcode;
begin
  SymbolId := Builder.Tree^.Nodes[Node].SymbolId;
  ReceiverValue := IR_INVALID_VALUE;
  ProcedureType := FSIM_TYPE_INVALID;
  if (SymbolId >= 0) and (SymbolId <= High(Builder.Symbols^.Symbols)) then
    ProcedureType := Builder.Symbols^.Symbols[SymbolId].TypeId;

  if (SymbolId >= 0) and (SymbolId <= High(Builder.Symbols^.Symbols)) and
     (Builder.Symbols^.Symbols[SymbolId].Kind in [skParameter, skVariable]) and
     (ProcedureType >= 0) and (ProcedureType <= High(Builder.Symbols^.Types)) and
     (Builder.Symbols^.Types[ProcedureType].Kind = tyProcedure) then
  begin
    ReceiverValue := NewValue(Builder, ProcedureType);
    Emit(Builder, irLoadSymbol, ReceiverValue, IR_INVALID_VALUE,
      IR_INVALID_VALUE, IR_INVALID_VALUE, ProcedureType, SymbolId,
      IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
      Builder.Tree^.Nodes[Node].Span);
    Op := irCallIndirect;
  end
  else
  begin
    if ReceiverNode >= 0 then
      ReceiverValue := LowerExpression(Builder, ReceiverNode)
    else if (SymbolId >= 0) and (SymbolId <= High(Builder.Symbols^.Symbols)) then
    begin
      OwnerSymbol := Builder.Symbols^.Symbols[SymbolId].OwnerSymbol;
      if (OwnerSymbol >= 0) and
         (Builder.Symbols^.Symbols[OwnerSymbol].Kind in
           [skClass, skProcessClass, skThreadClass]) then
      begin
        ReceiverType := SymMakeReferenceType(Builder.Symbols^, OwnerSymbol);
        ReceiverValue := LoadCurrentReceiver(Builder, ReceiverType,
          OwnerSymbol, Builder.Tree^.Nodes[Node].Span);
      end;
    end;
    if (SymbolId >= 0) and (SymbolId <= High(Builder.Symbols^.Symbols)) and
       (sfVirtual in Builder.Symbols^.Symbols[SymbolId].Flags) then
      Op := irCallVirtual
    else if (SymbolId >= 0) and
       (sfNative in Builder.Symbols^.Symbols[SymbolId].Flags) then
      Op := irCallNative
    else
      Op := irCall;
  end;
  Result := NewValue(Builder, Builder.Tree^.Nodes[Node].TypeId);
  Emit(Builder, Op, Result, ReceiverValue, IR_INVALID_VALUE,
    IR_INVALID_VALUE, Builder.Tree^.Nodes[Node].TypeId, SymbolId,
    IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
    Builder.Tree^.Nodes[Node].Span);
  Exclude(Builder.ProgramIR^.Functions[Builder.CurrentFunction].Flags, iffLeaf);
  Include(Builder.ProgramIR^.Functions[Builder.CurrentFunction].Flags,
    iffHasCalls);
end;

function LowerStringCall(var Builder: TIRBuilder; Node,
  CalleeNode: Int32; Intrinsic: TStringIntrinsic): Int32;
var
  BaseNode, BaseValue, ArgValue, ArgValue2, Child, TypeId: Int32;
  Op: TIROpcode;
begin
  BaseNode := ASTChildAt(Builder.Tree^, CalleeNode, 0);
  BaseValue := LowerExpression(Builder, BaseNode);
  Child := Builder.Tree^.Nodes[CalleeNode].NextSibling;
  ArgValue := IR_INVALID_VALUE;
  ArgValue2 := IR_INVALID_VALUE;
  if Child >= 0 then
  begin
    ArgValue := LowerExpression(Builder, Child);
    Child := Builder.Tree^.Nodes[Child].NextSibling;
  end;
  if Child >= 0 then ArgValue2 := LowerExpression(Builder, Child);
  case Intrinsic of
    siByte, siByteValue: Op := irStringByte;
    siToInteger: Op := irStringToInteger;
    siSlice: Op := irStringSlice;
  else
    raise EInvalidOp.Create('invalid string call intrinsic');
  end;
  TypeId := Builder.Tree^.Nodes[Node].TypeId;
  Result := NewValue(Builder, TypeId);
  Emit(Builder, Op, Result, BaseValue, ArgValue, ArgValue2, TypeId,
    FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
    FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
end;

function LowerTextCall(var Builder: TIRBuilder; Node,
  CalleeNode: Int32; Intrinsic: TTextIntrinsic): Int32;
var
  BaseNode, BaseValue, Arg1, Arg2, Child, TypeId: Int32;
  Op: TIROpcode;
begin
  BaseNode := ASTChildAt(Builder.Tree^, CalleeNode, 0);
  BaseValue := LowerExpression(Builder, BaseNode);
  Arg1 := IR_INVALID_VALUE;
  Arg2 := IR_INVALID_VALUE;
  Child := Builder.Tree^.Nodes[CalleeNode].NextSibling;
  if Child >= 0 then
  begin
    Arg1 := LowerExpression(Builder, Child);
    Child := Builder.Tree^.Nodes[Child].NextSibling;
  end;
  if Child >= 0 then Arg2 := LowerExpression(Builder, Child);

  case Intrinsic of
    tiConstant: Op := irTextConstant;
    tiStart: Op := irTextStart;
    tiLength: Op := irTextLength;
    tiMain: Op := irTextMain;
    tiPos: Op := irTextPos;
    tiSetPos: Op := irTextSetPos;
    tiMore: Op := irTextMore;
    tiGetChar: Op := irTextGetChar;
    tiPutChar: Op := irTextPutChar;
    tiSub: Op := irTextSub;
    tiStrip: Op := irTextStrip;
    tiGetInt: Op := irTextGetInt;
    tiGetReal: Op := irTextGetReal;
    tiGetFrac: Op := irTextGetFrac;
    tiPutInt: Op := irTextPutInt;
    tiPutFix: Op := irTextPutFix;
    tiPutReal: Op := irTextPutReal;
    tiPutFrac: Op := irTextPutFrac;
  else
    raise EInvalidOp.Create('invalid text call intrinsic');
  end;

  TypeId := Builder.Tree^.Nodes[Node].TypeId;
  if TypeId = FSIM_TYPE_VOID then Result := IR_INVALID_VALUE
  else Result := NewValue(Builder, TypeId);
  Emit(Builder, Op, Result, BaseValue, Arg1, Arg2, TypeId,
    FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
    FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
end;

function TryLowerCInteropCall(var Builder: TIRBuilder;
  Node, CalleeNode: Int32; out ResultValue: Int32): Boolean;
var
  Name: RawByteString;
  ArgumentNode, BaseNode, IndexNode, BaseValue, IndexValue, Value,
  SymbolId, OwnerSymbol, ReceiverType, ElementType, PointerType: Int32;
begin
  Result := False;
  ResultValue := IR_INVALID_VALUE;
  if Builder.Options^.Dialect <> fdFSim then Exit;
  if (CalleeNode < 0) or (CalleeNode > High(Builder.Tree^.Nodes)) then Exit;

  if (Builder.Tree^.Nodes[CalleeNode].Kind = nkIdentifierExpr) and
     (Builder.Tree^.Nodes[Node].Aux in [FSIM_C_INTRINSIC_SIZEOF,
       FSIM_C_INTRINSIC_ALIGNOF, FSIM_C_INTRINSIC_OFFSETOF]) then
  begin
    ResultValue := NewValue(Builder, FSIM_TYPE_C_SIZE);
    if Builder.Tree^.Nodes[Node].Aux = FSIM_C_INTRINSIC_SIZEOF then
      Value := Builder.Symbols^.Types[Builder.Tree^.Nodes[Node].A].Size
    else if Builder.Tree^.Nodes[Node].Aux = FSIM_C_INTRINSIC_ALIGNOF then
      Value := Builder.Symbols^.Types[Builder.Tree^.Nodes[Node].A].Alignment
    else if (Builder.Tree^.Nodes[Node].SymbolId >= 0) and
            (Builder.Tree^.Nodes[Node].SymbolId <= High(Builder.Symbols^.Symbols)) then
      Value := Builder.Symbols^.Symbols[Builder.Tree^.Nodes[Node].SymbolId].StorageOffset
    else
      Value := 0;
    Emit(Builder, irConstInt, ResultValue, IR_INVALID_VALUE, IR_INVALID_VALUE,
      IR_INVALID_VALUE, FSIM_TYPE_C_SIZE, FSIM_INVALID_INDEX,
      IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, Value, 0.0,
      Builder.Tree^.Nodes[Node].Span);
    Exit(True);
  end;

  if (Builder.Tree^.Nodes[CalleeNode].Kind = nkIdentifierExpr) and
     (Builder.Tree^.Nodes[Node].Aux = FSIM_C_INTRINSIC_ADDR) then
  begin
    ArgumentNode := Builder.Tree^.Nodes[CalleeNode].NextSibling;
    PointerType := Builder.Tree^.Nodes[Node].TypeId;
    ResultValue := NewValue(Builder, PointerType);
    case Builder.Tree^.Nodes[ArgumentNode].Kind of
      nkIdentifierExpr:
        begin
          SymbolId := Builder.Tree^.Nodes[ArgumentNode].SymbolId;
          if (SymbolId >= 0) and
             (sfForeignExport in Builder.Symbols^.Symbols[SymbolId].Flags) and
             (Builder.Symbols^.Symbols[SymbolId].Kind in [skProcedure, skFunction]) then
            Emit(Builder, irAddressOf, ResultValue, IR_INVALID_VALUE,
              IR_INVALID_VALUE, IR_INVALID_VALUE, PointerType, SymbolId,
              IR_INVALID_BLOCK, IR_INVALID_BLOCK, 4, FSIM_INVALID_INDEX,
              0, 0.0, Builder.Tree^.Nodes[Node].Span)
          else if (SymbolId >= 0) and
             (sfForeign in Builder.Symbols^.Symbols[SymbolId].Flags) and
             (Builder.Symbols^.Symbols[SymbolId].Kind in [skProcedure, skFunction]) then
            Emit(Builder, irAddressOf, ResultValue, IR_INVALID_VALUE,
              IR_INVALID_VALUE, IR_INVALID_VALUE, PointerType, SymbolId,
              IR_INVALID_BLOCK, IR_INVALID_BLOCK, 5, FSIM_INVALID_INDEX,
              0, 0.0, Builder.Tree^.Nodes[Node].Span)
          else if (SymbolId >= 0) and
             (sfForeign in Builder.Symbols^.Symbols[SymbolId].Flags) and
             (Builder.Symbols^.Symbols[SymbolId].Kind = skVariable) then
            Emit(Builder, irAddressOf, ResultValue, IR_INVALID_VALUE,
              IR_INVALID_VALUE, IR_INVALID_VALUE, PointerType, SymbolId,
              IR_INVALID_BLOCK, IR_INVALID_BLOCK, 3, FSIM_INVALID_INDEX,
              0, 0.0, Builder.Tree^.Nodes[Node].Span)
          else if (SymbolId >= 0) and
             (Builder.Symbols^.Symbols[SymbolId].Kind = skField) then
          begin
            OwnerSymbol := Builder.Symbols^.Symbols[SymbolId].OwnerSymbol;
            ReceiverType := SymMakeReferenceType(Builder.Symbols^, OwnerSymbol);
            BaseValue := LoadCurrentReceiver(Builder, ReceiverType, OwnerSymbol,
              Builder.Tree^.Nodes[ArgumentNode].Span);
            Emit(Builder, irAddressOf, ResultValue, BaseValue, IR_INVALID_VALUE,
              IR_INVALID_VALUE, PointerType, SymbolId, IR_INVALID_BLOCK,
              IR_INVALID_BLOCK, 1, FSIM_INVALID_INDEX, 0, 0.0,
              Builder.Tree^.Nodes[Node].Span);
          end
          else
            Emit(Builder, irAddressOf, ResultValue, IR_INVALID_VALUE,
              IR_INVALID_VALUE, IR_INVALID_VALUE, PointerType, SymbolId,
              IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX,
              0, 0.0, Builder.Tree^.Nodes[Node].Span);
        end;
      nkMemberExpr:
        begin
          BaseNode := ASTChildAt(Builder.Tree^, ArgumentNode, 0);
          BaseValue := LowerExpression(Builder, BaseNode);
          SymbolId := Builder.Tree^.Nodes[ArgumentNode].SymbolId;
          Emit(Builder, irAddressOf, ResultValue, BaseValue, IR_INVALID_VALUE,
            IR_INVALID_VALUE, PointerType, SymbolId, IR_INVALID_BLOCK,
            IR_INVALID_BLOCK, 1, FSIM_INVALID_INDEX, 0, 0.0,
            Builder.Tree^.Nodes[Node].Span);
        end;
      nkIndexExpr:
        begin
          BaseNode := ASTChildAt(Builder.Tree^, ArgumentNode, 0);
          IndexNode := Builder.Tree^.Nodes[BaseNode].NextSibling;
          BaseValue := LowerExpression(Builder, BaseNode);
          IndexValue := LowerExpression(Builder, IndexNode);
          Emit(Builder, irAddressOf, ResultValue, BaseValue, IndexValue,
            IR_INVALID_VALUE, PointerType, FSIM_INVALID_INDEX,
            IR_INVALID_BLOCK, IR_INVALID_BLOCK, 2, FSIM_INVALID_INDEX,
            0, 0.0, Builder.Tree^.Nodes[Node].Span);
        end;
    else
      begin
        AddError(Builder.Diagnostics^, dcBackendUnsupported,
          Builder.Tree^.Nodes[ArgumentNode].Span,
          'c_addr lowering needs a variable, field, or array element');
        Emit(Builder, irConstNull, ResultValue, IR_INVALID_VALUE,
          IR_INVALID_VALUE, IR_INVALID_VALUE, PointerType, FSIM_INVALID_INDEX,
          IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX,
          0, 0.0, Builder.Tree^.Nodes[Node].Span);
      end;
    end;
    Exit(True);
  end;

  if Builder.Tree^.Nodes[CalleeNode].Kind <> nkMemberExpr then Exit;
  BaseNode := ASTChildAt(Builder.Tree^, CalleeNode, 0);
  if (BaseNode < 0) or
     (Builder.Tree^.Nodes[BaseNode].TypeId < 0) or
     (Builder.Tree^.Nodes[BaseNode].TypeId > High(Builder.Symbols^.Types)) or
     (Builder.Symbols^.Types[Builder.Tree^.Nodes[BaseNode].TypeId].Kind <> tyCPointer) then
    Exit;
  BaseValue := LowerExpression(Builder, BaseNode);
  ElementType := Builder.Symbols^.Types[Builder.Tree^.Nodes[BaseNode].TypeId].ElementType;
  Name := ASTNodeName(Builder.Tree^, CalleeNode);

  if (Builder.Tree^.Nodes[Node].Aux = FSIM_C_INTRINSIC_LOAD) and
     ASCIIEqualFold(Name, 'load') then
  begin
    ResultValue := NewValue(Builder, ElementType);
    Emit(Builder, irLoadIndirect, ResultValue, BaseValue, IR_INVALID_VALUE,
      IR_INVALID_VALUE, ElementType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
      IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
      Builder.Tree^.Nodes[Node].Span);
    Exit(True);
  end;
  if (Builder.Tree^.Nodes[Node].Aux = FSIM_C_INTRINSIC_STORE) and
     ASCIIEqualFold(Name, 'store') then
  begin
    ArgumentNode := Builder.Tree^.Nodes[CalleeNode].NextSibling;
    Value := LowerExpression(Builder, ArgumentNode);
    Value := CoerceValue(Builder, Value, Builder.Tree^.Nodes[ArgumentNode].TypeId,
      ElementType, Builder.Tree^.Nodes[ArgumentNode].Span);
    Emit(Builder, irStoreIndirect, IR_INVALID_VALUE, BaseValue, Value,
      IR_INVALID_VALUE, ElementType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
      IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
      Builder.Tree^.Nodes[Node].Span);
    ResultValue := IR_INVALID_VALUE;
    Exit(True);
  end;
  if (Builder.Tree^.Nodes[Node].Aux = FSIM_C_INTRINSIC_OFFSET) and
     ASCIIEqualFold(Name, 'offset') then
  begin
    ArgumentNode := Builder.Tree^.Nodes[CalleeNode].NextSibling;
    IndexValue := LowerExpression(Builder, ArgumentNode);
    ResultValue := NewValue(Builder, Builder.Tree^.Nodes[Node].TypeId);
    Emit(Builder, irPointerOffset, ResultValue, BaseValue, IndexValue,
      IR_INVALID_VALUE, Builder.Tree^.Nodes[Node].TypeId, FSIM_INVALID_INDEX,
      IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
      Builder.Tree^.Nodes[Node].Span);
    Exit(True);
  end;
end;

function LowerCall(var Builder: TIRBuilder; Node: Int32): Int32;
var
  CalleeNode, CalleeSymbol, CalleeType, ProcedureType, Child, ArgValue,
  ArgValueType, ArgIndex, ReceiverValue, OwnerSymbol, ReceiverType,
  ParameterType, FormalParameterIndex: Int32;
  ParameterMode: TPassingMode;
  CalleeKind: TSymbolKind;
  Op: TIROpcode;
  Flags: TIRInstructionFlags;
  ArgValues: array of Int32;
  ArgTypes: array of Int32;
  ArgSpans: array of TSourceSpan;
begin
  CalleeNode := ASTChildAt(Builder.Tree^, Node, 0);
  if TryLowerCInteropCall(Builder, Node, CalleeNode, Result) then Exit;
  if (Builder.Tree^.Nodes[CalleeNode].Kind = nkMemberExpr) and
     (Builder.Tree^.Nodes[ASTChildAt(Builder.Tree^, CalleeNode, 0)].TypeId =
       FSIM_TYPE_STRING) and
     (Builder.Tree^.Nodes[CalleeNode].Aux <> Ord(siNone)) then
    Exit(LowerStringCall(Builder, Node, CalleeNode,
      TStringIntrinsic(Builder.Tree^.Nodes[CalleeNode].Aux)));
  if (Builder.Tree^.Nodes[CalleeNode].Kind = nkMemberExpr) and
     (Builder.Tree^.Nodes[CalleeNode].Aux <> Ord(tiNone)) and
     (Builder.Tree^.Nodes[ASTChildAt(Builder.Tree^, CalleeNode, 0)].TypeId =
       FSIM_TYPE_TEXT) then
    Exit(LowerTextCall(Builder, Node, CalleeNode,
      TTextIntrinsic(Builder.Tree^.Nodes[CalleeNode].Aux)));

  CalleeSymbol := Builder.Tree^.Nodes[CalleeNode].SymbolId;
  CalleeType := Builder.Tree^.Nodes[Node].TypeId;
  ProcedureType := Builder.Tree^.Nodes[CalleeNode].TypeId;
  CalleeKind := skInvalid;
  if (CalleeSymbol >= 0) and (CalleeSymbol <= High(Builder.Symbols^.Symbols)) then
    CalleeKind := Builder.Symbols^.Symbols[CalleeSymbol].Kind;
  if (CalleeSymbol >= 0) and
     (CalleeSymbol <= High(Builder.Symbols^.Symbols)) and
     (sfImported in Builder.Symbols^.Symbols[CalleeSymbol].Flags) and
     not (sfForeign in Builder.Symbols^.Symbols[CalleeSymbol].Flags) then
    AddError(Builder.Diagnostics^, dcBackendUnsupported,
      Builder.Tree^.Nodes[Node].Span,
      'external procedure ''' + SymName(Builder.Symbols^, CalleeSymbol) +
      ''' needs a target-specific linker binding');

  ReceiverValue := IR_INVALID_VALUE;
  { Evaluate an indirect callee before any arguments. The old lowering emitted
    irParameter as soon as each argument was evaluated and only loaded the
    function pointer afterwards. Because irParameter is a deferred pseudo-op,
    register allocation was then free to reuse an argument register before the
    call actually consumed it. Nested calls in later arguments were even worse.
    Calls now obey one simple invariant: evaluate callee/arguments first, then
    emit all parameters contiguously immediately before the call. }
  if (ProcedureType >= 0) and
     (ProcedureType <= High(Builder.Symbols^.Types)) and
     (Builder.Symbols^.Types[ProcedureType].Kind = tyCFunction) then
  begin
    ReceiverValue := LowerExpression(Builder, CalleeNode);
    Op := irCallForeignIndirect;
  end
  else if (ProcedureType >= 0) and
     (ProcedureType <= High(Builder.Symbols^.Types)) and
     (Builder.Symbols^.Types[ProcedureType].Kind = tyProcedure) and
     not (CalleeKind in [skProcedure, skFunction]) then
  begin
    ReceiverValue := LowerExpression(Builder, CalleeNode);
    Op := irCallIndirect;
  end
  else
  begin
    if Builder.Tree^.Nodes[CalleeNode].Kind = nkMemberExpr then
      ReceiverValue := LowerExpression(Builder,
        ASTChildAt(Builder.Tree^, CalleeNode, 0))
    else if (CalleeSymbol >= 0) and
      (CalleeSymbol <= High(Builder.Symbols^.Symbols)) then
    begin
      OwnerSymbol := Builder.Symbols^.Symbols[CalleeSymbol].OwnerSymbol;
      if (OwnerSymbol >= 0) and
         (Builder.Symbols^.Symbols[OwnerSymbol].Kind in
           [skClass, skProcessClass, skThreadClass]) then
      begin
        ReceiverType := SymMakeReferenceType(Builder.Symbols^, OwnerSymbol);
        ReceiverValue := LoadCurrentReceiver(Builder, ReceiverType,
          OwnerSymbol, Builder.Tree^.Nodes[CalleeNode].Span);
      end;
    end;
    if (CalleeSymbol >= 0) and
       (sfVirtual in Builder.Symbols^.Symbols[CalleeSymbol].Flags) then
      Op := irCallVirtual
    else if (CalleeSymbol >= 0) and
       (sfForeign in Builder.Symbols^.Symbols[CalleeSymbol].Flags) then
      Op := irCallForeign
    else if (CalleeSymbol >= 0) and
       (sfNative in Builder.Symbols^.Symbols[CalleeSymbol].Flags) then
      Op := irCallNative
    else
      Op := irCall;
  end;

  SetLength(ArgValues, 0);
  SetLength(ArgTypes, 0);
  SetLength(ArgSpans, 0);
  Child := Builder.Tree^.Nodes[CalleeNode].NextSibling;
  ArgIndex := 0;
  while Child >= 0 do
  begin
    ArgValue := LowerExpression(Builder, Child);
    ArgValueType := Builder.Tree^.Nodes[Child].TypeId;
    if (ArgValue >= 0) and (ArgValue <= High(Builder.ProgramIR^.Values)) then
      ArgValueType := Builder.ProgramIR^.Values[ArgValue].TypeId;
    if (ProcedureType >= 0) and
       (ProcedureType <= High(Builder.Symbols^.Types)) and
       (Builder.Symbols^.Types[ProcedureType].Kind in [tyProcedure, tyCFunction]) and
       (ArgIndex < Builder.Symbols^.Types[ProcedureType].ParameterCount) then
    begin
      FormalParameterIndex :=
        Builder.Symbols^.Types[ProcedureType].ParameterStart + ArgIndex;
      ParameterType := Builder.Symbols^.Parameters[FormalParameterIndex].TypeId;
      ParameterMode := Builder.Symbols^.Parameters[FormalParameterIndex].Mode;
      { Coerce from what lowering actually produced, not merely from the AST's
        intended type.  That catches representation-preserving casts whose only
        observable effect is the ABI/type tag. }
      ArgValue := CoerceValue(Builder, ArgValue, ArgValueType, ParameterType,
        Builder.Tree^.Nodes[Child].Span);
      { Standard SIMULA value TEXT parameters are initialized as if by
        ``formal :- copy(actual)''.  A TEXT reference parameter receives the
        descriptor pointer unchanged.  Do the copy before the generic
        parameter pseudo-op so the native calling convention still only sees
        the normal pointer-sized TEXT representation. }
      if (Builder.Options^.Dialect = fdSimula67) and
         (ParameterType = FSIM_TYPE_TEXT) and (ParameterMode = pmValue) then
      begin
        ArgValueType := NewValue(Builder, FSIM_TYPE_TEXT);
        Emit(Builder, irTextCopy, ArgValueType, ArgValue, IR_INVALID_VALUE,
          IR_INVALID_VALUE, FSIM_TYPE_TEXT, FSIM_INVALID_INDEX,
          IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
          Builder.Tree^.Nodes[Child].Span);
        ArgValue := ArgValueType;
      end;
    end;
    SetLength(ArgValues, Length(ArgValues) + 1);
    SetLength(ArgTypes, Length(ArgTypes) + 1);
    SetLength(ArgSpans, Length(ArgSpans) + 1);
    ArgValues[High(ArgValues)] := ArgValue;
    if (ArgValue >= 0) and (ArgValue <= High(Builder.ProgramIR^.Values)) then
      ArgTypes[High(ArgTypes)] := Builder.ProgramIR^.Values[ArgValue].TypeId
    else
      ArgTypes[High(ArgTypes)] := Builder.Tree^.Nodes[Child].TypeId;
    ArgSpans[High(ArgSpans)] := Builder.Tree^.Nodes[Child].Span;
    Inc(ArgIndex);
    Child := Builder.Tree^.Nodes[Child].NextSibling;
  end;

  for ArgIndex := 0 to High(ArgValues) do
    Emit(Builder, irParameter, IR_INVALID_VALUE, ArgValues[ArgIndex],
      IR_INVALID_VALUE, IR_INVALID_VALUE, ArgTypes[ArgIndex],
      FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, ArgIndex,
      FSIM_INVALID_INDEX, 0, 0.0, ArgSpans[ArgIndex]);

  if CalleeType = FSIM_TYPE_VOID then
    Result := IR_INVALID_VALUE
  else
    Result := NewValue(Builder, CalleeType);
  Flags := [];
  Emit(Builder, Op, Result, ReceiverValue, IR_INVALID_VALUE, IR_INVALID_VALUE,
    CalleeType, CalleeSymbol, IR_INVALID_BLOCK, IR_INVALID_BLOCK,
    Length(ArgValues), FSIM_INVALID_INDEX, 0, 0.0,
    Builder.Tree^.Nodes[Node].Span, Flags);
  Exclude(Builder.ProgramIR^.Functions[Builder.CurrentFunction].Flags, iffLeaf);
  Include(Builder.ProgramIR^.Functions[Builder.CurrentFunction].Flags,
    iffHasCalls);
end;

function LowerThreadSpawnOperand(var Builder: TIRBuilder;
  OperandNode, ResultType: Int32): Int32;
var
  CalleeNode, CalleeSymbol, ArgumentNode, ArgumentValue: Int32;
begin
  CalleeSymbol := FSIM_INVALID_INDEX;
  ArgumentValue := IR_INVALID_VALUE;
  if OperandNode < 0 then
  begin
    Result := NewValue(Builder, ResultType);
    Emit(Builder, irThreadSpawn, Result, IR_INVALID_VALUE, IR_INVALID_VALUE,
      IR_INVALID_VALUE, ResultType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
      IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Builder.Tree^.Root].Span);
    Exit;
  end;

  if Builder.Tree^.Nodes[OperandNode].Kind = nkCallExpr then
  begin
    CalleeNode := ASTChildAt(Builder.Tree^, OperandNode, 0);
    if CalleeNode >= 0 then
      CalleeSymbol := Builder.Tree^.Nodes[CalleeNode].SymbolId;
    if (CalleeNode >= 0) and
       (Builder.Tree^.Nodes[CalleeNode].Kind = nkMemberExpr) then
      ArgumentNode := ASTChildAt(Builder.Tree^, CalleeNode, 0)
    else if CalleeNode >= 0 then
      ArgumentNode := Builder.Tree^.Nodes[CalleeNode].NextSibling
    else
      ArgumentNode := FSIM_INVALID_INDEX;
    if ArgumentNode >= 0 then
      ArgumentValue := LowerExpression(Builder, ArgumentNode);
  end
  else
  begin
    CalleeSymbol := Builder.Tree^.Nodes[OperandNode].SymbolId;
    ArgumentValue := LowerExpression(Builder, OperandNode);
  end;

  Result := NewValue(Builder, ResultType);
  Emit(Builder, irThreadSpawn, Result, ArgumentValue, IR_INVALID_VALUE,
    IR_INVALID_VALUE, ResultType, CalleeSymbol, IR_INVALID_BLOCK,
    IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
    Builder.Tree^.Nodes[OperandNode].Span);
  Exclude(Builder.ProgramIR^.Functions[Builder.CurrentFunction].Flags, iffLeaf);
  Include(Builder.ProgramIR^.Functions[Builder.CurrentFunction].Flags,
    iffHasCalls);
end;

function LowerConditionalExpression(var Builder: TIRBuilder;
  Node: Int32): Int32;
var
  ConditionValue, ThenValue, ElseValue: Int32;
  ThenBlock, ElseBlock, MergeBlock: Int32;
begin
  ConditionValue := LowerExpression(Builder,
    ASTChildAt(Builder.Tree^, Node, 0));
  ThenBlock := NewBlock(Builder);
  ElseBlock := NewBlock(Builder);
  MergeBlock := NewBlock(Builder);
  Result := NewValue(Builder, Builder.Tree^.Nodes[Node].TypeId);
  Emit(Builder, irBranchCond, IR_INVALID_VALUE, ConditionValue,
    IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN,
    FSIM_INVALID_INDEX, ThenBlock, ElseBlock, 0, FSIM_INVALID_INDEX,
    0, 0.0, Builder.Tree^.Nodes[Node].Span);
  SetBlock(Builder, ThenBlock);
  ThenValue := LowerExpression(Builder, ASTChildAt(Builder.Tree^, Node, 1));
  Emit(Builder, irMove, Result, ThenValue, IR_INVALID_VALUE,
    IR_INVALID_VALUE, Builder.Tree^.Nodes[Node].TypeId, FSIM_INVALID_INDEX,
    IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
    Builder.Tree^.Nodes[Node].Span);
  EmitBranchIfNeeded(Builder, MergeBlock, Builder.Tree^.Nodes[Node].Span);
  SetBlock(Builder, ElseBlock);
  ElseValue := LowerExpression(Builder, ASTChildAt(Builder.Tree^, Node, 2));
  Emit(Builder, irMove, Result, ElseValue, IR_INVALID_VALUE,
    IR_INVALID_VALUE, Builder.Tree^.Nodes[Node].TypeId, FSIM_INVALID_INDEX,
    IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
    Builder.Tree^.Nodes[Node].Span);
  EmitBranchIfNeeded(Builder, MergeBlock, Builder.Tree^.Nodes[Node].Span);
  SetBlock(Builder, MergeBlock);
end;

function LowerExpression(var Builder: TIRBuilder; Node: Int32): Int32;
var
  TypeId, OperandNode, OperandValue, BaseValue, IndexValue, ClassSymbol,
  StringId, ClassIndex, ParameterIndex, ArgumentNode, ArgumentValue,
  IndexNode, ArrayType, ElementType, FormalParameterIndex, StoreAux,
  CopiedValue: Int32;
  ParameterMode: TPassingMode;
  Op: TUnaryOperator;
begin
  if Node < 0 then Exit(IR_INVALID_VALUE);
  TypeId := Builder.Tree^.Nodes[Node].TypeId;
  case Builder.Tree^.Nodes[Node].Kind of
    nkLambdaExpr:
      begin
        Result := NewValue(Builder, Builder.Tree^.Nodes[Node].TypeId);
        Emit(Builder, irProcedureAddress, Result, IR_INVALID_VALUE,
          IR_INVALID_VALUE, IR_INVALID_VALUE, Builder.Tree^.Nodes[Node].TypeId,
          Builder.Tree^.Nodes[Node].SymbolId, IR_INVALID_BLOCK,
          IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
          Builder.Tree^.Nodes[Node].Span);
        Exit;
      end;
    nkIdentifierExpr:
      if nfImplicitCall in Builder.Tree^.Nodes[Node].Flags then
        Exit(LowerImplicitCall(Builder, Node, FSIM_INVALID_INDEX))
      else
        Exit(LowerIdentifier(Builder, Node));
    nkIntegerLiteralExpr, nkBooleanLiteralExpr, nkCharacterLiteralExpr:
      begin
        Result := NewValue(Builder, TypeId);
        Emit(Builder, irConstInt, Result, IR_INVALID_VALUE, IR_INVALID_VALUE,
          IR_INVALID_VALUE, TypeId, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
          IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX,
          Builder.Tree^.Nodes[Node].IntValue, 0.0,
          Builder.Tree^.Nodes[Node].Span);
      end;
    nkRealLiteralExpr:
      begin
        Result := NewValue(Builder, TypeId);
        Emit(Builder, irConstReal, Result, IR_INVALID_VALUE, IR_INVALID_VALUE,
          IR_INVALID_VALUE, TypeId, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
          IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0,
          Builder.Tree^.Nodes[Node].RealValue, Builder.Tree^.Nodes[Node].Span);
      end;
    nkStringLiteralExpr:
      begin
        StringId := StringPoolIntern(Builder.ProgramIR^.Strings,
          ASTNodeString(Builder.Tree^, Node));
        Result := NewValue(Builder, TypeId);
        Emit(Builder, irConstString, Result, IR_INVALID_VALUE,
          IR_INVALID_VALUE, IR_INVALID_VALUE, TypeId, FSIM_INVALID_INDEX,
          IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, StringId, 0, 0.0,
          Builder.Tree^.Nodes[Node].Span);
      end;
    nkNoneExpr:
      begin
        Result := NewValue(Builder, TypeId);
        Emit(Builder, irConstNull, Result, IR_INVALID_VALUE,
          IR_INVALID_VALUE, IR_INVALID_VALUE, TypeId, FSIM_INVALID_INDEX,
          IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
          Builder.Tree^.Nodes[Node].Span);
      end;
    nkThisExpr:
      begin
        Result := LoadCurrentReceiver(Builder, TypeId,
          Builder.Tree^.Nodes[Node].SymbolId,
          Builder.Tree^.Nodes[Node].Span);
      end;
    nkUnaryExpr:
      begin
        OperandNode := ASTChildAt(Builder.Tree^, Node, 0);
        OperandValue := LowerExpression(Builder, OperandNode);
        Op := TUnaryOperator(Builder.Tree^.Nodes[Node].Aux);
        if Op = uoPositive then Exit(OperandValue);
        Result := NewValue(Builder, TypeId);
        if Op = uoLogicalNot then
          Emit(Builder, irLogicalNot, Result, OperandValue, IR_INVALID_VALUE,
            IR_INVALID_VALUE, TypeId, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
            IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
            Builder.Tree^.Nodes[Node].Span)
        else if TypeId = FSIM_TYPE_REAL then
          Emit(Builder, irNegReal, Result, OperandValue, IR_INVALID_VALUE,
            IR_INVALID_VALUE, TypeId, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
            IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
            Builder.Tree^.Nodes[Node].Span)
        else
          Emit(Builder, irNegInt, Result, OperandValue, IR_INVALID_VALUE,
            IR_INVALID_VALUE, TypeId, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
            IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
            Builder.Tree^.Nodes[Node].Span);
      end;
    nkBinaryExpr: Exit(LowerBinary(Builder, Node));
    nkMemberExpr:
      if nfImplicitCall in Builder.Tree^.Nodes[Node].Flags then
        Exit(LowerImplicitCall(Builder, Node,
          ASTChildAt(Builder.Tree^, Node, 0)))
      else
        Exit(LowerMember(Builder, Node));
    nkIndexExpr:
      begin
        OperandNode := ASTChildAt(Builder.Tree^, Node, 0);
        BaseValue := LowerExpression(Builder, OperandNode);
        ArrayType := Builder.Tree^.Nodes[OperandNode].TypeId;
        IndexNode := Builder.Tree^.Nodes[OperandNode].NextSibling;
        Result := BaseValue;
        while IndexNode >= 0 do
        begin
          IndexValue := LowerExpression(Builder, IndexNode);
          if (ArrayType >= 0) and (ArrayType <= High(Builder.Symbols^.Types)) and
             (Builder.Symbols^.Types[ArrayType].Kind = tyArray) then
            ElementType := Builder.Symbols^.Types[ArrayType].ElementType
          else
            ElementType := TypeId;
          Result := NewValue(Builder, ElementType);
          Emit(Builder, irLoadElement, Result, BaseValue, IndexValue,
            IR_INVALID_VALUE, ElementType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
            IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
            Builder.Tree^.Nodes[IndexNode].Span);
          BaseValue := Result;
          ArrayType := ElementType;
          IndexNode := Builder.Tree^.Nodes[IndexNode].NextSibling;
        end;
      end;
    nkConversionExpr:
      begin
        OperandNode := ASTChildAt(Builder.Tree^, Node, 0);
        OperandValue := LowerExpression(Builder, OperandNode);
        Result := CoerceValue(Builder, OperandValue,
          Builder.Tree^.Nodes[OperandNode].TypeId, TypeId,
          Builder.Tree^.Nodes[Node].Span);
      end;
    nkCallExpr: Exit(LowerCall(Builder, Node));
    nkNewExpr:
      begin
        ClassSymbol := Builder.Tree^.Nodes[Node].SymbolId;
        if (ClassSymbol >= 0) and
           (ClassSymbol <= High(Builder.Symbols^.Symbols)) and
           (sfImported in Builder.Symbols^.Symbols[ClassSymbol].Flags) then
          AddError(Builder.Diagnostics^, dcBackendUnsupported,
            Builder.Tree^.Nodes[Node].Span,
            'external class ''' + SymName(Builder.Symbols^, ClassSymbol) +
            ''' needs a target-specific object binding');
        Result := NewValue(Builder, TypeId);
        Emit(Builder, irAllocObject, Result, IR_INVALID_VALUE,
          IR_INVALID_VALUE, IR_INVALID_VALUE, TypeId, ClassSymbol,
          IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
          Builder.Tree^.Nodes[Node].Span);
        Emit(Builder, irInitObject, IR_INVALID_VALUE, Result,
          IR_INVALID_VALUE, IR_INVALID_VALUE, TypeId, ClassSymbol,
          IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
          Builder.Tree^.Nodes[Node].Span);
        ClassIndex := SymClassIndex(Builder.Symbols^, ClassSymbol);
        ArgumentNode := Builder.Tree^.Nodes[Node].FirstChild;
        ParameterIndex := 0;
        while (ArgumentNode >= 0) and (ClassIndex >= 0) and
              (ParameterIndex < Builder.Symbols^.Classes[ClassIndex].ParameterCount) do
        begin
          ArgumentValue := LowerExpression(Builder, ArgumentNode);
          FormalParameterIndex :=
            Builder.Symbols^.Classes[ClassIndex].ParameterStart + ParameterIndex;
          StoreAux := 0;
          if (Builder.Options^.Dialect = fdSimula67) and
             (Builder.Symbols^.Parameters[FormalParameterIndex].TypeId =
               FSIM_TYPE_TEXT) then
          begin
            ParameterMode := Builder.Symbols^.Parameters[FormalParameterIndex].Mode;
            if ParameterMode = pmValue then
            begin
              CopiedValue := NewValue(Builder, FSIM_TYPE_TEXT);
              Emit(Builder, irTextCopy, CopiedValue, ArgumentValue,
                IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_TEXT,
                FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
                FSIM_INVALID_INDEX, 0, 0.0,
                Builder.Tree^.Nodes[ArgumentNode].Span);
              ArgumentValue := CopiedValue;
            end;
            { Constructor parameter transmission initializes an empty field.
              Both reference TEXT and value TEXT (after copy above) therefore
              use reference assignment; ordinary TEXT value assignment needs
              an already existing writable frame and is invalid here. }
            StoreAux := 1;
          end;
          Emit(Builder, irStoreField, IR_INVALID_VALUE, Result, ArgumentValue,
            IR_INVALID_VALUE,
            Builder.Symbols^.Parameters[FormalParameterIndex].TypeId,
            Builder.Symbols^.Parameters[FormalParameterIndex].SymbolId,
            IR_INVALID_BLOCK, IR_INVALID_BLOCK, StoreAux, FSIM_INVALID_INDEX,
            0, 0.0, Builder.Tree^.Nodes[ArgumentNode].Span);
          Inc(ParameterIndex);
          ArgumentNode := Builder.Tree^.Nodes[ArgumentNode].NextSibling;
        end;
        LowerClassConstruction(Builder, ClassSymbol, Result, FSIM_INVALID_INDEX);
      end;
    nkQuaExpr:
      begin
        OperandValue := LowerExpression(Builder, ASTChildAt(Builder.Tree^, Node, 0));
        Result := NewValue(Builder, TypeId);
        Emit(Builder, irQuaCheck, Result, OperandValue, IR_INVALID_VALUE,
          IR_INVALID_VALUE, TypeId, Builder.Tree^.Nodes[Node].SymbolId,
          IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
          Builder.Tree^.Nodes[Node].Span);
      end;
    nkObjectTestExpr:
      begin
        OperandValue := LowerExpression(Builder,
          ASTChildAt(Builder.Tree^, Node, 0));
        Result := NewValue(Builder, FSIM_TYPE_BOOLEAN);
        if Builder.Tree^.Nodes[Node].Aux <> 0 then
          Emit(Builder, irTypeTest, Result, OperandValue, IR_INVALID_VALUE,
            IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN,
            Builder.Tree^.Nodes[Node].SymbolId, IR_INVALID_BLOCK,
            IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
            Builder.Tree^.Nodes[Node].Span)
        else
          Emit(Builder, irTypeExact, Result, OperandValue, IR_INVALID_VALUE,
            IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN,
            Builder.Tree^.Nodes[Node].SymbolId, IR_INVALID_BLOCK,
            IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
            Builder.Tree^.Nodes[Node].Span);
      end;
    nkConditionalExpr: Exit(LowerConditionalExpression(Builder, Node));
    nkAwaitExpr:
      begin
        OperandValue := LowerExpression(Builder,
          ASTChildAt(Builder.Tree^, Node, 0));
        Result := NewValue(Builder, TypeId);
        Emit(Builder, irFutureAwait, Result, OperandValue, IR_INVALID_VALUE,
          IR_INVALID_VALUE, TypeId, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
          IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
          Builder.Tree^.Nodes[Node].Span);
      end;
    nkSpawnExpr:
      begin
        OperandNode := ASTChildAt(Builder.Tree^, Node, 0);
        Result := LowerThreadSpawnOperand(Builder, OperandNode, TypeId);
      end;
    nkReceiveExpr:
      begin
        OperandValue := LowerExpression(Builder,
          ASTChildAt(Builder.Tree^, Node, 0));
        Result := NewValue(Builder, TypeId);
        Emit(Builder, irChannelReceive, Result, OperandValue,
          IR_INVALID_VALUE, IR_INVALID_VALUE, TypeId, FSIM_INVALID_INDEX,
          IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
          Builder.Tree^.Nodes[Node].Span);
      end;
    nkSizeOfExpr:
      begin
        OperandNode := ASTChildAt(Builder.Tree^, Node, 0);
        Result := NewValue(Builder, FSIM_TYPE_INTEGER);
        Emit(Builder, irConstInt, Result, IR_INVALID_VALUE, IR_INVALID_VALUE,
          IR_INVALID_VALUE, FSIM_TYPE_INTEGER, FSIM_INVALID_INDEX,
          IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX,
          Builder.Symbols^.Types[Builder.Tree^.Nodes[OperandNode].TypeId].Size,
          0.0, Builder.Tree^.Nodes[Node].Span);
      end;
    nkTypeOfExpr:
      begin
        OperandNode := ASTChildAt(Builder.Tree^, Node, 0);
        OperandValue := LowerExpression(Builder, OperandNode);
        Result := NewValue(Builder, FSIM_TYPE_INTEGER);
        Emit(Builder, irRTTIOf, Result, OperandValue, IR_INVALID_VALUE,
          IR_INVALID_VALUE, FSIM_TYPE_INTEGER, FSIM_INVALID_INDEX,
          IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
          Builder.Tree^.Nodes[Node].Span);
      end;
  else
    begin
      AddError(Builder.Diagnostics^, dcInternalError,
        Builder.Tree^.Nodes[Node].Span,
        'cannot lower AST expression kind ' +
        ASTKindName(Builder.Tree^.Nodes[Node].Kind));
      Result := IR_INVALID_VALUE;
    end;
  end;
end;

procedure LowerAssignment(var Builder: TIRBuilder; Node: Int32);
var
  LeftNode, RightNode, RightValue, CheckedValue, BaseValue, IndexValue,
  SymbolId, ReceiverType, OperandNode, IndexNode, NextIndex, ArrayType,
  ElementType, LoadedValue: Int32;
begin
  LeftNode := ASTChildAt(Builder.Tree^, Node, 0);
  RightNode := ASTChildAt(Builder.Tree^, Node, 1);
  RightValue := LowerExpression(Builder, RightNode);
  if Builder.Tree^.Nodes[Node].Kind = nkAssignmentStatement then
    RightValue := CoerceValue(Builder, RightValue,
      Builder.Tree^.Nodes[RightNode].TypeId,
      Builder.Tree^.Nodes[LeftNode].TypeId,
      Builder.Tree^.Nodes[RightNode].Span);
  if (Builder.Tree^.Nodes[Node].Kind = nkReferenceAssignmentStatement) and
     (Builder.Tree^.Nodes[Node].C >= 0) then
  begin
    CheckedValue := NewValue(Builder, Builder.Tree^.Nodes[LeftNode].TypeId);
    Emit(Builder, irQuaCheck, CheckedValue, RightValue, IR_INVALID_VALUE,
      IR_INVALID_VALUE, Builder.Tree^.Nodes[LeftNode].TypeId,
      Builder.Tree^.Nodes[Node].C, IR_INVALID_BLOCK, IR_INVALID_BLOCK,
      1, FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
    RightValue := CheckedValue;
  end;
  case Builder.Tree^.Nodes[LeftNode].Kind of
    nkIdentifierExpr:
      begin
        SymbolId := Builder.Tree^.Nodes[LeftNode].SymbolId;
        if (Builder.CurrentFunction >= 0) and
           (SymbolId = Builder.ProgramIR^.Functions[
             Builder.CurrentFunction].SymbolId) and
           (Builder.CurrentResultValue >= 0) then
          Emit(Builder, irMove, Builder.CurrentResultValue, RightValue,
            IR_INVALID_VALUE, IR_INVALID_VALUE,
            Builder.Tree^.Nodes[LeftNode].TypeId, SymbolId,
            IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX,
            0, 0.0, Builder.Tree^.Nodes[Node].Span)
        else if (SymbolId >= 0) and
          (sfForeign in Builder.Symbols^.Symbols[SymbolId].Flags) and
          (Builder.Symbols^.Symbols[SymbolId].Kind = skVariable) then
          Emit(Builder, irStoreForeignData, IR_INVALID_VALUE, RightValue,
            IR_INVALID_VALUE, IR_INVALID_VALUE,
            Builder.Tree^.Nodes[LeftNode].TypeId, SymbolId, IR_INVALID_BLOCK,
            IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
            Builder.Tree^.Nodes[Node].Span)
        else if (SymbolId >= 0) and
          (Builder.Symbols^.Symbols[SymbolId].Kind = skField) then
        begin
          ReceiverType := SymMakeReferenceType(Builder.Symbols^,
            Builder.Symbols^.Symbols[SymbolId].OwnerSymbol);
          BaseValue := LoadCurrentReceiver(Builder, ReceiverType,
            Builder.Symbols^.Symbols[SymbolId].OwnerSymbol,
            Builder.Tree^.Nodes[Node].Span);
          Emit(Builder, irStoreField, IR_INVALID_VALUE, BaseValue, RightValue,
            IR_INVALID_VALUE, Builder.Tree^.Nodes[LeftNode].TypeId, SymbolId,
            IR_INVALID_BLOCK, IR_INVALID_BLOCK,
            Ord(Builder.Tree^.Nodes[Node].Kind = nkReferenceAssignmentStatement),
            FSIM_INVALID_INDEX,
            0, 0.0, Builder.Tree^.Nodes[Node].Span);
        end
        else
          Emit(Builder, irStoreSymbol, IR_INVALID_VALUE, RightValue,
            IR_INVALID_VALUE, IR_INVALID_VALUE,
            Builder.Tree^.Nodes[LeftNode].TypeId, SymbolId, IR_INVALID_BLOCK,
            IR_INVALID_BLOCK, Ord(Builder.Tree^.Nodes[Node].Kind =
            nkReferenceAssignmentStatement), FSIM_INVALID_INDEX, 0, 0.0,
            Builder.Tree^.Nodes[Node].Span);
      end;
    nkMemberExpr:
      begin
        BaseValue := LowerExpression(Builder,
          ASTChildAt(Builder.Tree^, LeftNode, 0));
        SymbolId := Builder.Tree^.Nodes[LeftNode].SymbolId;
        Emit(Builder, irStoreField, IR_INVALID_VALUE, BaseValue, RightValue,
          IR_INVALID_VALUE, Builder.Tree^.Nodes[LeftNode].TypeId, SymbolId,
          IR_INVALID_BLOCK, IR_INVALID_BLOCK,
          Ord(Builder.Tree^.Nodes[Node].Kind = nkReferenceAssignmentStatement),
          FSIM_INVALID_INDEX, 0, 0.0,
          Builder.Tree^.Nodes[Node].Span);
      end;
    nkIndexExpr:
      begin
        OperandNode := ASTChildAt(Builder.Tree^, LeftNode, 0);
        BaseValue := LowerExpression(Builder, OperandNode);
        ArrayType := Builder.Tree^.Nodes[OperandNode].TypeId;
        IndexNode := Builder.Tree^.Nodes[OperandNode].NextSibling;
        while IndexNode >= 0 do
        begin
          NextIndex := Builder.Tree^.Nodes[IndexNode].NextSibling;
          IndexValue := LowerExpression(Builder, IndexNode);
          if NextIndex < 0 then
          begin
            Emit(Builder, irStoreElement, IR_INVALID_VALUE, BaseValue, IndexValue,
              RightValue, Builder.Tree^.Nodes[LeftNode].TypeId,
              FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK,
              Ord(Builder.Tree^.Nodes[Node].Kind = nkReferenceAssignmentStatement),
              FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
            Break;
          end;
          if (ArrayType >= 0) and (ArrayType <= High(Builder.Symbols^.Types)) and
             (Builder.Symbols^.Types[ArrayType].Kind = tyArray) then
            ElementType := Builder.Symbols^.Types[ArrayType].ElementType
          else
            ElementType := Builder.Tree^.Nodes[LeftNode].TypeId;
          LoadedValue := NewValue(Builder, ElementType);
          Emit(Builder, irLoadElement, LoadedValue, BaseValue, IndexValue,
            IR_INVALID_VALUE, ElementType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
            IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
            Builder.Tree^.Nodes[IndexNode].Span);
          BaseValue := LoadedValue;
          ArrayType := ElementType;
          IndexNode := NextIndex;
        end;
      end;
  end;
end;

procedure LowerIf(var Builder: TIRBuilder; Node: Int32);
var
  ConditionValue, ThenBlock, ElseBlock, MergeBlock, ThenNode, ElseNode: Int32;
begin
  ConditionValue := LowerExpression(Builder, ASTChildAt(Builder.Tree^, Node, 0));
  ThenNode := ASTChildAt(Builder.Tree^, Node, 1);
  ElseNode := ASTChildAt(Builder.Tree^, Node, 2);
  ThenBlock := NewBlock(Builder);
  if ElseNode >= 0 then ElseBlock := NewBlock(Builder)
  else ElseBlock := IR_INVALID_BLOCK;
  MergeBlock := NewBlock(Builder);
  if ElseBlock < 0 then ElseBlock := MergeBlock;
  Emit(Builder, irBranchCond, IR_INVALID_VALUE, ConditionValue,
    IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN,
    FSIM_INVALID_INDEX, ThenBlock, ElseBlock, 0, FSIM_INVALID_INDEX, 0, 0.0,
    Builder.Tree^.Nodes[Node].Span);
  SetBlock(Builder, ThenBlock);
  LowerNode(Builder, ThenNode);
  EmitBranchIfNeeded(Builder, MergeBlock, Builder.Tree^.Nodes[Node].Span);
  if ElseNode >= 0 then
  begin
    SetBlock(Builder, ElseBlock);
    LowerNode(Builder, ElseNode);
    EmitBranchIfNeeded(Builder, MergeBlock, Builder.Tree^.Nodes[Node].Span);
  end;
  SetBlock(Builder, MergeBlock);
end;

procedure LowerWhile(var Builder: TIRBuilder; Node: Int32);
var
  HeaderBlock, BodyBlock, ExitBlock, ConditionValue: Int32;
begin
  HeaderBlock := NewBlock(Builder, [ibfLoopHeader]);
  BodyBlock := NewBlock(Builder);
  ExitBlock := NewBlock(Builder);
  EmitBranchIfNeeded(Builder, HeaderBlock, Builder.Tree^.Nodes[Node].Span);
  SetBlock(Builder, HeaderBlock);
  ConditionValue := LowerExpression(Builder, ASTChildAt(Builder.Tree^, Node, 0));
  Emit(Builder, irBranchCond, IR_INVALID_VALUE, ConditionValue,
    IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN,
    FSIM_INVALID_INDEX, BodyBlock, ExitBlock, 0, FSIM_INVALID_INDEX, 0, 0.0,
    Builder.Tree^.Nodes[Node].Span);
  PushTarget(Builder.BreakTargets, ExitBlock);
  PushTarget(Builder.ContinueTargets, HeaderBlock);
  SetBlock(Builder, BodyBlock);
  LowerNode(Builder, ASTChildAt(Builder.Tree^, Node, 1));
  Include(Builder.ProgramIR^.Blocks[Builder.CurrentBlock].Flags, ibfLoopLatch);
  EmitBranchIfNeeded(Builder, HeaderBlock, Builder.Tree^.Nodes[Node].Span);
  PopTarget(Builder.ContinueTargets);
  PopTarget(Builder.BreakTargets);
  SetBlock(Builder, ExitBlock);
end;

procedure LowerFor(var Builder: TIRBuilder; Node: Int32);
var
  VariableNode, ElementNode, NextElement, BodyNode, SymbolId, VariableType,
  ExitBlock, NextBlock: Int32;
  IsReferenceFor: Boolean;

  procedure StoreControlled(Value: Int32; const Span: TSourceSpan);
  begin
    Emit(Builder, irStoreSymbol, IR_INVALID_VALUE, Value, IR_INVALID_VALUE,
      IR_INVALID_VALUE, VariableType, SymbolId, IR_INVALID_BLOCK,
      IR_INVALID_BLOCK, Ord(IsReferenceFor), FSIM_INVALID_INDEX, 0, 0.0,
      Span);
  end;

  function EmitZero(const Span: TSourceSpan): Int32;
  begin
    Result := NewValue(Builder, VariableType);
    if VariableType = FSIM_TYPE_REAL then
      Emit(Builder, irConstReal, Result, IR_INVALID_VALUE, IR_INVALID_VALUE,
        IR_INVALID_VALUE, VariableType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
        IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0, Span)
    else
      Emit(Builder, irConstInt, Result, IR_INVALID_VALUE, IR_INVALID_VALUE,
        IR_INVALID_VALUE, VariableType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
        IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0, Span);
  end;

  procedure LowerValueElement(Element, FollowingBlock: Int32);
  var
    Value: Int32;
  begin
    Value := LowerExpression(Builder, ASTChildAt(Builder.Tree^, Element, 0));
    StoreControlled(Value, Builder.Tree^.Nodes[Element].Span);
    PushTarget(Builder.ContinueTargets, FollowingBlock);
    LowerNode(Builder, BodyNode);
    EmitBranchIfNeeded(Builder, FollowingBlock,
      Builder.Tree^.Nodes[Element].Span);
    PopTarget(Builder.ContinueTargets);
  end;

  procedure LowerWhileElement(Element, FollowingBlock: Int32);
  var
    HeaderBlock, ControlledBlock, Value, Condition: Int32;
  begin
    HeaderBlock := NewBlock(Builder, [ibfLoopHeader]);
    ControlledBlock := NewBlock(Builder);
    EmitBranchIfNeeded(Builder, HeaderBlock, Builder.Tree^.Nodes[Element].Span);
    SetBlock(Builder, HeaderBlock);
    Value := LowerExpression(Builder, ASTChildAt(Builder.Tree^, Element, 0));
    StoreControlled(Value, Builder.Tree^.Nodes[Element].Span);
    Condition := LowerExpression(Builder,
      ASTChildAt(Builder.Tree^, Element, 1));
    Emit(Builder, irBranchCond, IR_INVALID_VALUE, Condition,
      IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN,
      FSIM_INVALID_INDEX, ControlledBlock, FollowingBlock, 0,
      FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Element].Span);
    SetBlock(Builder, ControlledBlock);
    PushTarget(Builder.ContinueTargets, HeaderBlock);
    LowerNode(Builder, BodyNode);
    Include(Builder.ProgramIR^.Blocks[Builder.CurrentBlock].Flags,
      ibfLoopLatch);
    EmitBranchIfNeeded(Builder, HeaderBlock,
      Builder.Tree^.Nodes[Element].Span);
    PopTarget(Builder.ContinueTargets);
  end;

  procedure LowerStepUntilElement(Element, FollowingBlock: Int32);
  var
    InitialNode, StepNode, UntilNode: Int32;
    InitialValue, StepValue, UntilValue, CurrentValue, NextValue,
    ZeroValue, StepNonNegative, ContinueValue: Int32;
    HeaderBlock, PositiveTestBlock, NegativeTestBlock, ControlledBlock,
    LatchBlock: Int32;
    AddOp: TIROpcode;
  begin
    InitialNode := ASTChildAt(Builder.Tree^, Element, 0);
    StepNode := ASTChildAt(Builder.Tree^, Element, 1);
    UntilNode := ASTChildAt(Builder.Tree^, Element, 2);
    InitialValue := LowerExpression(Builder, InitialNode);
    StoreControlled(InitialValue, Builder.Tree^.Nodes[Element].Span);
    HeaderBlock := NewBlock(Builder, [ibfLoopHeader]);
    PositiveTestBlock := NewBlock(Builder);
    NegativeTestBlock := NewBlock(Builder);
    ControlledBlock := NewBlock(Builder);
    LatchBlock := NewBlock(Builder, [ibfLoopLatch]);
    EmitBranchIfNeeded(Builder, HeaderBlock, Builder.Tree^.Nodes[Element].Span);

    SetBlock(Builder, HeaderBlock);
    StepValue := LowerExpression(Builder, StepNode);
    UntilValue := LowerExpression(Builder, UntilNode);
    CurrentValue := LowerIdentifier(Builder, VariableNode);
    ZeroValue := EmitZero(Builder.Tree^.Nodes[Element].Span);
    StepNonNegative := NewValue(Builder, FSIM_TYPE_BOOLEAN);
    Emit(Builder, irCompareGreaterEqual, StepNonNegative, StepValue,
      ZeroValue, IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN, FSIM_INVALID_INDEX,
      IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
      Builder.Tree^.Nodes[Element].Span);
    Emit(Builder, irBranchCond, IR_INVALID_VALUE, StepNonNegative,
      IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN,
      FSIM_INVALID_INDEX, PositiveTestBlock, NegativeTestBlock, 0,
      FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Element].Span);

    SetBlock(Builder, PositiveTestBlock);
    ContinueValue := NewValue(Builder, FSIM_TYPE_BOOLEAN);
    Emit(Builder, irCompareLessEqual, ContinueValue, CurrentValue,
      UntilValue, IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN, FSIM_INVALID_INDEX,
      IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
      Builder.Tree^.Nodes[Element].Span);
    Emit(Builder, irBranchCond, IR_INVALID_VALUE, ContinueValue,
      IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN,
      FSIM_INVALID_INDEX, ControlledBlock, FollowingBlock, 0,
      FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Element].Span);

    SetBlock(Builder, NegativeTestBlock);
    ContinueValue := NewValue(Builder, FSIM_TYPE_BOOLEAN);
    Emit(Builder, irCompareGreaterEqual, ContinueValue, CurrentValue,
      UntilValue, IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN, FSIM_INVALID_INDEX,
      IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
      Builder.Tree^.Nodes[Element].Span);
    Emit(Builder, irBranchCond, IR_INVALID_VALUE, ContinueValue,
      IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN,
      FSIM_INVALID_INDEX, ControlledBlock, FollowingBlock, 0,
      FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Element].Span);

    SetBlock(Builder, ControlledBlock);
    PushTarget(Builder.ContinueTargets, LatchBlock);
    LowerNode(Builder, BodyNode);
    EmitBranchIfNeeded(Builder, LatchBlock,
      Builder.Tree^.Nodes[Element].Span);
    PopTarget(Builder.ContinueTargets);

    SetBlock(Builder, LatchBlock);
    CurrentValue := LowerIdentifier(Builder, VariableNode);
    NextValue := NewValue(Builder, VariableType);
    if VariableType = FSIM_TYPE_REAL then AddOp := irAddReal else AddOp := irAddInt;
    Emit(Builder, AddOp, NextValue, CurrentValue, StepValue,
      IR_INVALID_VALUE, VariableType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
      IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
      Builder.Tree^.Nodes[Element].Span);
    StoreControlled(NextValue, Builder.Tree^.Nodes[Element].Span);
    EmitBranchIfNeeded(Builder, HeaderBlock, Builder.Tree^.Nodes[Element].Span);
  end;

begin
  VariableNode := ASTChildAt(Builder.Tree^, Node, 0);
  if (VariableNode < 0) or (VariableNode > High(Builder.Tree^.Nodes)) then Exit;
  SymbolId := Builder.Tree^.Nodes[VariableNode].SymbolId;
  VariableType := Builder.Tree^.Nodes[VariableNode].TypeId;
  if (SymbolId < 0) or (VariableType < 0) or
     (VariableType > High(Builder.Symbols^.Types)) then Exit;
  IsReferenceFor := Builder.Tree^.Nodes[Node].Aux <> 0;
  BodyNode := Builder.Tree^.Nodes[Node].BodyNode;
  if (BodyNode < 0) or (BodyNode > High(Builder.Tree^.Nodes)) then Exit;
  ExitBlock := NewBlock(Builder);
  PushTarget(Builder.BreakTargets, ExitBlock);
  ElementNode := Builder.Tree^.Nodes[VariableNode].NextSibling;
  while (ElementNode >= 0) and (ElementNode <> BodyNode) do
  begin
    NextElement := Builder.Tree^.Nodes[ElementNode].NextSibling;
    if (NextElement < 0) or (NextElement = BodyNode) then
      NextBlock := ExitBlock
    else
      NextBlock := NewBlock(Builder);
    case Builder.Tree^.Nodes[ElementNode].Kind of
      nkForValueElement:
        LowerValueElement(ElementNode, NextBlock);
      nkForWhileElement:
        LowerWhileElement(ElementNode, NextBlock);
      nkForStepUntilElement:
        LowerStepUntilElement(ElementNode, NextBlock);
    end;
    if NextBlock <> ExitBlock then SetBlock(Builder, NextBlock);
    ElementNode := NextElement;
  end;
  PopTarget(Builder.BreakTargets);
  SetBlock(Builder, ExitBlock);
end;

procedure LowerOutput(var Builder: TIRBuilder; Node: Int32);
var
  Kind: TOutputKind;
  Value, Digits, Width, Arg: Int32;
  Op: TIROpcode;
begin
  Kind := TOutputKind(Builder.Tree^.Nodes[Node].Aux);
  if Kind = okImage then
  begin
    Emit(Builder, irPrintNewLine, IR_INVALID_VALUE, IR_INVALID_VALUE,
      IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID,
      FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
      FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
    Exit;
  end;

  Arg := ASTChildAt(Builder.Tree^, Node, 0);
  Value := LowerExpression(Builder, Arg);
  Digits := IR_INVALID_VALUE;
  Width := IR_INVALID_VALUE;

  if Kind in [okReal, okFixed] then
  begin
    Digits := LowerExpression(Builder, ASTChildAt(Builder.Tree^, Node, 1));
    Width := LowerExpression(Builder, ASTChildAt(Builder.Tree^, Node, 2));
  end
  else if (Kind = okInteger) and
          (ASTChildAt(Builder.Tree^, Node, 1) >= 0) then
    Width := LowerExpression(Builder, ASTChildAt(Builder.Tree^, Node, 1));

  case Kind of
    okText: Op := irPrintText;
    okInteger: Op := irPrintInteger;
    okReal: Op := irPrintReal;
    okFixed: Op := irPrintFixed;
    okCharacter: Op := irPrintCharacter;
  else
    Op := irNop;
  end;
  Emit(Builder, Op, IR_INVALID_VALUE, Value, Digits, Width,
    Builder.Tree^.Nodes[Arg].TypeId, FSIM_INVALID_INDEX,
    IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX,
    0, 0.0, Builder.Tree^.Nodes[Node].Span);
end;

procedure LowerRepeat(var Builder: TIRBuilder; Node: Int32);
var
  BodyBlock, TestBlock, ExitBlock, ConditionValue: Int32;
begin
  BodyBlock := NewBlock(Builder);
  TestBlock := NewBlock(Builder, [ibfLoopLatch]);
  ExitBlock := NewBlock(Builder);
  EmitBranchIfNeeded(Builder, BodyBlock, Builder.Tree^.Nodes[Node].Span);
  PushTarget(Builder.BreakTargets, ExitBlock);
  PushTarget(Builder.ContinueTargets, TestBlock);
  SetBlock(Builder, BodyBlock);
  LowerNode(Builder, ASTChildAt(Builder.Tree^, Node, 0));
  EmitBranchIfNeeded(Builder, TestBlock, Builder.Tree^.Nodes[Node].Span);
  SetBlock(Builder, TestBlock);
  ConditionValue := LowerExpression(Builder,
    ASTChildAt(Builder.Tree^, Node, 1));
  Emit(Builder, irBranchCond, IR_INVALID_VALUE, ConditionValue,
    IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN,
    FSIM_INVALID_INDEX, ExitBlock, BodyBlock, 0, FSIM_INVALID_INDEX, 0, 0.0,
    Builder.Tree^.Nodes[Node].Span);
  PopTarget(Builder.ContinueTargets);
  PopTarget(Builder.BreakTargets);
  SetBlock(Builder, ExitBlock);
end;

procedure LowerDesignationalBranch(var Builder: TIRBuilder;
  Node, Depth: Int32);
var
  CalleeNode, IndexNode, SwitchSymbol, SwitchDecl, ElementNode,
  IndexValue, OrdinalValue, TestValue, ConditionValue, TargetBlock,
  NextTestBlock, ThenBlock, ElseBlock, FalseValue, Ordinal: Int32;
begin
  if (Node < 0) or (Node > High(Builder.Tree^.Nodes)) then Exit;
  if Depth > 64 then
  begin
    AddError(Builder.Diagnostics^, dcInvalidControlFlow,
      Builder.Tree^.Nodes[Node].Span,
      'switch designator nesting exceeds 64 levels');
    Emit(Builder, irUnreachable, IR_INVALID_VALUE, IR_INVALID_VALUE,
      IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID,
      FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
      FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
    Exit;
  end;
  case Builder.Tree^.Nodes[Node].Kind of
    nkIdentifierExpr:
      begin
        TargetBlock := LabelBlock(Builder,
          Builder.Tree^.Nodes[Node].SymbolId);
        Emit(Builder, irBranch, IR_INVALID_VALUE, IR_INVALID_VALUE,
          IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID,
          Builder.Tree^.Nodes[Node].SymbolId, TargetBlock,
          IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
          Builder.Tree^.Nodes[Node].Span);
      end;
    nkConditionalExpr:
      begin
        ConditionValue := LowerExpression(Builder,
          ASTChildAt(Builder.Tree^, Node, 0));
        ThenBlock := NewBlock(Builder);
        ElseBlock := NewBlock(Builder);
        Emit(Builder, irBranchCond, IR_INVALID_VALUE, ConditionValue,
          IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN,
          FSIM_INVALID_INDEX, ThenBlock, ElseBlock, 0,
          FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
        SetBlock(Builder, ThenBlock);
        LowerDesignationalBranch(Builder,
          ASTChildAt(Builder.Tree^, Node, 1), Depth + 1);
        SetBlock(Builder, ElseBlock);
        LowerDesignationalBranch(Builder,
          ASTChildAt(Builder.Tree^, Node, 2), Depth + 1);
      end;
    nkCallExpr:
      begin
        CalleeNode := ASTChildAt(Builder.Tree^, Node, 0);
        SwitchSymbol := Builder.Tree^.Nodes[Node].SymbolId;
        if (SwitchSymbol < 0) and (CalleeNode >= 0) then
          SwitchSymbol := Builder.Tree^.Nodes[CalleeNode].SymbolId;
        if (SwitchSymbol < 0) or
           (SwitchSymbol > High(Builder.Symbols^.Symbols)) then Exit;
        SwitchDecl := Builder.Symbols^.Symbols[SwitchSymbol].DeclNode;
        IndexNode := FSIM_INVALID_INDEX;
        if CalleeNode >= 0 then
          IndexNode := Builder.Tree^.Nodes[CalleeNode].NextSibling;
        if (SwitchDecl < 0) or (IndexNode < 0) then Exit;
        IndexValue := LowerExpression(Builder, IndexNode);
        ElementNode := Builder.Tree^.Nodes[SwitchDecl].FirstChild;
        Ordinal := 1;
        while ElementNode >= 0 do
        begin
          OrdinalValue := NewValue(Builder, FSIM_TYPE_INTEGER);
          Emit(Builder, irConstInt, OrdinalValue, IR_INVALID_VALUE,
            IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_INTEGER,
            FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
            FSIM_INVALID_INDEX, Ordinal, 0.0,
            Builder.Tree^.Nodes[ElementNode].Span);
          TestValue := NewValue(Builder, FSIM_TYPE_BOOLEAN);
          Emit(Builder, irCompareEqual, TestValue, IndexValue, OrdinalValue,
            IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN, FSIM_INVALID_INDEX,
            IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0,
            0.0, Builder.Tree^.Nodes[ElementNode].Span);
          TargetBlock := NewBlock(Builder);
          NextTestBlock := NewBlock(Builder);
          Emit(Builder, irBranchCond, IR_INVALID_VALUE, TestValue,
            IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN,
            FSIM_INVALID_INDEX, TargetBlock, NextTestBlock, 0,
            FSIM_INVALID_INDEX, 0, 0.0,
            Builder.Tree^.Nodes[ElementNode].Span);
          SetBlock(Builder, TargetBlock);
          LowerDesignationalBranch(Builder, ElementNode, Depth + 1);
          SetBlock(Builder, NextTestBlock);
          Inc(Ordinal);
          ElementNode := Builder.Tree^.Nodes[ElementNode].NextSibling;
        end;
        FalseValue := NewValue(Builder, FSIM_TYPE_BOOLEAN);
        Emit(Builder, irConstInt, FalseValue, IR_INVALID_VALUE,
          IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN,
          FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
          FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
        Emit(Builder, irAssert, IR_INVALID_VALUE, FalseValue,
          IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID,
          FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
          FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
        Emit(Builder, irUnreachable, IR_INVALID_VALUE, IR_INVALID_VALUE,
          IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID,
          FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
          FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
      end;
  else
    begin
      AddError(Builder.Diagnostics^, dcInvalidControlFlow,
        Builder.Tree^.Nodes[Node].Span,
        'cannot lower non-designational expression in go to');
      Emit(Builder, irUnreachable, IR_INVALID_VALUE, IR_INVALID_VALUE,
        IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID,
        FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
        FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
    end;
  end;
end;

procedure LowerGoto(var Builder: TIRBuilder; Node: Int32);
var
  TargetNode: Int32;
begin
  TargetNode := ASTChildAt(Builder.Tree^, Node, 0);
  LowerDesignationalBranch(Builder, TargetNode, 0);
end;

procedure LowerLabel(var Builder: TIRBuilder; Node: Int32);
var
  TargetBlock, BodyNode: Int32;
begin
  TargetBlock := LabelBlock(Builder, Builder.Tree^.Nodes[Node].SymbolId);
  EmitBranchIfNeeded(Builder, TargetBlock, Builder.Tree^.Nodes[Node].Span);
  SetBlock(Builder, TargetBlock);
  BodyNode := ASTChildAt(Builder.Tree^, Node, 0);
  if BodyNode >= 0 then LowerNode(Builder, BodyNode);
end;

procedure LowerInspect(var Builder: TIRBuilder; Node: Int32);
var
  SubjectNode, SubjectValue, Clause, BodyNode, TestValue, ThenValue: Int32;
  BodyBlock, NextBlock, MergeBlock: Int32;
  IsOtherwise: Boolean;
begin
  SubjectNode := ASTChildAt(Builder.Tree^, Node, 0);
  SubjectValue := LowerExpression(Builder, SubjectNode);
  MergeBlock := NewBlock(Builder);
  Clause := Builder.Tree^.Nodes[SubjectNode].NextSibling;
  while Clause >= 0 do
  begin
    IsOtherwise := ASTNodeName(Builder.Tree^, Clause) = 'otherwise';
    BodyNode := ASTChildAt(Builder.Tree^, Clause, 0);
    BodyBlock := NewBlock(Builder);
    if IsOtherwise then
      EmitBranchIfNeeded(Builder, BodyBlock, Builder.Tree^.Nodes[Clause].Span)
    else
    begin
      NextBlock := NewBlock(Builder);
      TestValue := NewValue(Builder, FSIM_TYPE_BOOLEAN);
      if ASTNodeName(Builder.Tree^, Clause) = '$do' then
      begin
        ThenValue := NewValue(Builder, Builder.Tree^.Nodes[SubjectNode].TypeId);
        Emit(Builder, irConstNull, ThenValue, IR_INVALID_VALUE,
          IR_INVALID_VALUE, IR_INVALID_VALUE,
          Builder.Tree^.Nodes[SubjectNode].TypeId, FSIM_INVALID_INDEX,
          IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX,
          0, 0.0, Builder.Tree^.Nodes[Clause].Span);
        Emit(Builder, irCompareNotEqual, TestValue, SubjectValue, ThenValue,
          IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN, FSIM_INVALID_INDEX,
          IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX,
          0, 0.0, Builder.Tree^.Nodes[Clause].Span);
      end
      else
        Emit(Builder, irTypeTest, TestValue, SubjectValue, IR_INVALID_VALUE,
          IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN,
          Builder.Tree^.Nodes[Clause].SymbolId, IR_INVALID_BLOCK,
          IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
          Builder.Tree^.Nodes[Clause].Span);
      Emit(Builder, irBranchCond, IR_INVALID_VALUE, TestValue,
        IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN,
        FSIM_INVALID_INDEX, BodyBlock, NextBlock, 0, FSIM_INVALID_INDEX,
        0, 0.0, Builder.Tree^.Nodes[Clause].Span);
    end;
    SetBlock(Builder, BodyBlock);
    LowerNode(Builder, BodyNode);
    EmitBranchIfNeeded(Builder, MergeBlock, Builder.Tree^.Nodes[Clause].Span);
    if IsOtherwise then
    begin
      Clause := FSIM_INVALID_INDEX;
      Break;
    end;
    SetBlock(Builder, NextBlock);
    Clause := Builder.Tree^.Nodes[Clause].NextSibling;
  end;
  EmitBranchIfNeeded(Builder, MergeBlock, Builder.Tree^.Nodes[Node].Span);
  SetBlock(Builder, MergeBlock);
end;

procedure LowerCase(var Builder: TIRBuilder; Node: Int32);
var
  SelectorNode, SelectorValue, Clause, Child, BodyNode: Int32;
  TestValue, CaseValue, ClauseBlock, NextTestBlock, MergeBlock: Int32;
  IsOtherwise: Boolean;
begin
  SelectorNode := ASTChildAt(Builder.Tree^, Node, 0);
  SelectorValue := LowerExpression(Builder, SelectorNode);
  MergeBlock := NewBlock(Builder);
  Clause := Builder.Tree^.Nodes[SelectorNode].NextSibling;
  while Clause >= 0 do
  begin
    IsOtherwise := ASTNodeName(Builder.Tree^, Clause) = 'otherwise';
    BodyNode := Builder.Tree^.Nodes[Clause].BodyNode;
    if BodyNode < 0 then BodyNode := ASTChildAt(Builder.Tree^, Clause, 0);
    ClauseBlock := NewBlock(Builder);
    if IsOtherwise then
      EmitBranchIfNeeded(Builder, ClauseBlock, Builder.Tree^.Nodes[Clause].Span)
    else
    begin
      Child := Builder.Tree^.Nodes[Clause].FirstChild;
      while (Child >= 0) and (Child <> BodyNode) do
      begin
        CaseValue := LowerExpression(Builder, Child);
        TestValue := NewValue(Builder, FSIM_TYPE_BOOLEAN);
        Emit(Builder, irCompareEqual, TestValue, SelectorValue, CaseValue,
          IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN, FSIM_INVALID_INDEX,
          IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0,
          0.0, Builder.Tree^.Nodes[Child].Span);
        NextTestBlock := NewBlock(Builder);
        Emit(Builder, irBranchCond, IR_INVALID_VALUE, TestValue,
          IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_BOOLEAN,
          FSIM_INVALID_INDEX, ClauseBlock, NextTestBlock, 0,
          FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Child].Span);
        SetBlock(Builder, NextTestBlock);
        Child := Builder.Tree^.Nodes[Child].NextSibling;
      end;
    end;
    SetBlock(Builder, ClauseBlock);
    LowerNode(Builder, BodyNode);
    EmitBranchIfNeeded(Builder, MergeBlock, Builder.Tree^.Nodes[Clause].Span);
    if IsOtherwise then Break;
    Clause := Builder.Tree^.Nodes[Clause].NextSibling;
  end;
  EmitBranchIfNeeded(Builder, MergeBlock, Builder.Tree^.Nodes[Node].Span);
  SetBlock(Builder, MergeBlock);
end;

procedure LowerActivation(var Builder: TIRBuilder; Node: Int32;
  Op: TIROpcode);
var
  TargetValue, ClauseValue: Int32;
begin
  TargetValue := LowerExpression(Builder, ASTChildAt(Builder.Tree^, Node, 0));
  ClauseValue := IR_INVALID_VALUE;
  if ASTChildAt(Builder.Tree^, Node, 1) >= 0 then
    ClauseValue := LowerExpression(Builder, ASTChildAt(Builder.Tree^, Node, 1));
  Emit(Builder, Op, IR_INVALID_VALUE, TargetValue, ClauseValue,
    IR_INVALID_VALUE, FSIM_TYPE_VOID, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
    IR_INVALID_BLOCK, Builder.Tree^.Nodes[Node].Aux, FSIM_INVALID_INDEX, 0,
    0.0, Builder.Tree^.Nodes[Node].Span);
end;

procedure LowerModernUnary(var Builder: TIRBuilder; Node: Int32;
  Op: TIROpcode; ProducesValue: Boolean);
var
  OperandNode, OperandValue, ResultValue, OperandSymbol: Int32;
begin
  OperandNode := ASTChildAt(Builder.Tree^, Node, 0);
  OperandSymbol := FSIM_INVALID_INDEX;
  if Op = irThreadSpawn then
  begin
    if ProducesValue then
      ResultValue := Builder.Tree^.Nodes[Node].TypeId
    else
      ResultValue := FSIM_TYPE_LONG_INTEGER;
    LowerThreadSpawnOperand(Builder, OperandNode, ResultValue);
    Exit;
  end;
  if OperandNode >= 0 then
  begin
    OperandValue := LowerExpression(Builder, OperandNode);
    OperandSymbol := Builder.Tree^.Nodes[OperandNode].SymbolId;
  end
  else
    OperandValue := IR_INVALID_VALUE;
  if ProducesValue then ResultValue := NewValue(Builder,
    Builder.Tree^.Nodes[Node].TypeId)
  else ResultValue := IR_INVALID_VALUE;
  Emit(Builder, Op, ResultValue, OperandValue, IR_INVALID_VALUE,
    IR_INVALID_VALUE, Builder.Tree^.Nodes[Node].TypeId,
    OperandSymbol, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
    FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
end;

procedure LowerSend(var Builder: TIRBuilder; Node: Int32);
var
  ChannelValue, PayloadValue: Int32;
begin
  ChannelValue := LowerExpression(Builder, ASTChildAt(Builder.Tree^, Node, 0));
  PayloadValue := LowerExpression(Builder, ASTChildAt(Builder.Tree^, Node, 1));
  Emit(Builder, irChannelSend, IR_INVALID_VALUE, ChannelValue, PayloadValue,
    IR_INVALID_VALUE, FSIM_TYPE_VOID, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
    IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
    Builder.Tree^.Nodes[Node].Span);
end;

procedure LowerWrapped(var Builder: TIRBuilder; Node: Int32;
  BeginOp, EndOp: TIROpcode);
begin
  Emit(Builder, BeginOp, IR_INVALID_VALUE, IR_INVALID_VALUE,
    IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID, FSIM_INVALID_INDEX,
    IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
    Builder.Tree^.Nodes[Node].Span);
  LowerNode(Builder, ASTChildAt(Builder.Tree^, Node, 0));
  if not IRBlockTerminated(Builder.ProgramIR^, Builder.CurrentBlock) then
    Emit(Builder, EndOp, IR_INVALID_VALUE, IR_INVALID_VALUE,
      IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID, FSIM_INVALID_INDEX,
      IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
      Builder.Tree^.Nodes[Node].Span);
end;

procedure LowerTry(var Builder: TIRBuilder; Node: Int32);
var
  BodyNode, Child, HandlerBlock, FinallyBlock, ContinueBlock: Int32;
begin
  BodyNode := ASTChildAt(Builder.Tree^, Node, 0);
  HandlerBlock := NewBlock(Builder, [ibfExceptionHandler]);
  FinallyBlock := IR_INVALID_BLOCK;
  Child := Builder.Tree^.Nodes[BodyNode].NextSibling;
  while Child >= 0 do
  begin
    if Builder.Tree^.Nodes[Child].Kind = nkFinallyClause then
      FinallyBlock := NewBlock(Builder);
    Child := Builder.Tree^.Nodes[Child].NextSibling;
  end;
  ContinueBlock := NewBlock(Builder);
  PushTarget(Builder.ExceptionTargets, HandlerBlock);
  Emit(Builder, irTryBegin, IR_INVALID_VALUE, IR_INVALID_VALUE,
    IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID, FSIM_INVALID_INDEX,
    HandlerBlock, FinallyBlock, 0, FSIM_INVALID_INDEX, 0, 0.0,
    Builder.Tree^.Nodes[Node].Span);
  LowerNode(Builder, BodyNode);
  Emit(Builder, irTryEnd, IR_INVALID_VALUE, IR_INVALID_VALUE,
    IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID, FSIM_INVALID_INDEX,
    IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
    Builder.Tree^.Nodes[Node].Span);
  PopTarget(Builder.ExceptionTargets);
  if FinallyBlock >= 0 then
    EmitBranchIfNeeded(Builder, FinallyBlock, Builder.Tree^.Nodes[Node].Span)
  else
    EmitBranchIfNeeded(Builder, ContinueBlock, Builder.Tree^.Nodes[Node].Span);
  SetBlock(Builder, HandlerBlock);
  Child := Builder.Tree^.Nodes[BodyNode].NextSibling;
  while Child >= 0 do
  begin
    if Builder.Tree^.Nodes[Child].Kind = nkCatchClause then
      LowerNode(Builder, Child);
    Child := Builder.Tree^.Nodes[Child].NextSibling;
  end;
  if FinallyBlock >= 0 then
    EmitBranchIfNeeded(Builder, FinallyBlock, Builder.Tree^.Nodes[Node].Span)
  else
    EmitBranchIfNeeded(Builder, ContinueBlock, Builder.Tree^.Nodes[Node].Span);
  if FinallyBlock >= 0 then
  begin
    SetBlock(Builder, FinallyBlock);
    Child := Builder.Tree^.Nodes[BodyNode].NextSibling;
    while Child >= 0 do
    begin
      if Builder.Tree^.Nodes[Child].Kind = nkFinallyClause then
        LowerNode(Builder, Child);
      Child := Builder.Tree^.Nodes[Child].NextSibling;
    end;
    EmitBranchIfNeeded(Builder, ContinueBlock, Builder.Tree^.Nodes[Node].Span);
  end;
  SetBlock(Builder, ContinueBlock);
end;

procedure LowerNode(var Builder: TIRBuilder; Node: Int32);
var
  Child, Value, Target, BaseValue, IndexValue: Int32;
begin
  if Node < 0 then Exit;
  case Builder.Tree^.Nodes[Node].Kind of
    nkBlock, nkBlockStatement, nkStatementList:
      begin
        Child := Builder.Tree^.Nodes[Node].FirstChild;
        while Child >= 0 do
        begin
          if IRBlockTerminated(Builder.ProgramIR^, Builder.CurrentBlock) and
             (Builder.Tree^.Nodes[Child].Kind <> nkLabelStatement) then
          begin
            Child := Builder.Tree^.Nodes[Child].NextSibling;
            Continue;
          end;
          LowerNode(Builder, Child);
          Child := Builder.Tree^.Nodes[Child].NextSibling;
        end;
      end;
    nkParameterDecl, nkVisibilitySection, nkVirtualSection,
    nkVirtualSpec, nkLabelDecl, nkSwitchDecl, nkEmptyStatement:
      ;
    nkVariableDecl:
      begin
        Child := ASTChildAt(Builder.Tree^, Node, 0);
        if (Builder.Tree^.Nodes[Node].TypeId >= 0) and
           (Builder.Tree^.Nodes[Node].TypeId <= High(Builder.Symbols^.Types)) and
           (Builder.Symbols^.Types[Builder.Tree^.Nodes[Node].TypeId].Kind = tyArray) and
           (tfRuntimeBound in Builder.Symbols^.Types[
             Builder.Tree^.Nodes[Node].TypeId].Flags) then
        begin
          BaseValue := LowerExpression(Builder, Child);
          IndexValue := LowerExpression(Builder, ASTChildAt(Builder.Tree^, Node, 1));
          Value := NewValue(Builder, Builder.Tree^.Nodes[Node].TypeId);
          Emit(Builder, irAllocArray, Value, BaseValue, IndexValue,
            IR_INVALID_VALUE, Builder.Tree^.Nodes[Node].TypeId,
            Builder.Tree^.Nodes[Node].SymbolId, IR_INVALID_BLOCK,
            IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
            Builder.Tree^.Nodes[Node].Span);
          if (Builder.Tree^.Nodes[Node].SymbolId >= 0) and
             (Builder.Symbols^.Symbols[
               Builder.Tree^.Nodes[Node].SymbolId].Kind = skField) then
          begin
            BaseValue := LoadCurrentReceiver(Builder,
              SymMakeReferenceType(Builder.Symbols^,
                Builder.Symbols^.Symbols[
                  Builder.Tree^.Nodes[Node].SymbolId].OwnerSymbol),
              Builder.Symbols^.Symbols[
                Builder.Tree^.Nodes[Node].SymbolId].OwnerSymbol,
              Builder.Tree^.Nodes[Node].Span);
            Emit(Builder, irStoreField, IR_INVALID_VALUE, BaseValue, Value,
              IR_INVALID_VALUE, Builder.Tree^.Nodes[Node].TypeId,
              Builder.Tree^.Nodes[Node].SymbolId, IR_INVALID_BLOCK,
              IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
              Builder.Tree^.Nodes[Node].Span);
          end
          else
            Emit(Builder, irStoreSymbol, IR_INVALID_VALUE, Value,
              IR_INVALID_VALUE, IR_INVALID_VALUE,
              Builder.Tree^.Nodes[Node].TypeId,
              Builder.Tree^.Nodes[Node].SymbolId, IR_INVALID_BLOCK,
              IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
              Builder.Tree^.Nodes[Node].Span);
        end
        else if (Builder.Tree^.Nodes[Node].TypeId >= 0) and
          (Builder.Tree^.Nodes[Node].TypeId <= High(Builder.Symbols^.Types)) and
          (Builder.Symbols^.Types[Builder.Tree^.Nodes[Node].TypeId].Kind in
            [tyChannel, tyMutex, tySemaphore, tyBarrier, tyCondition, tyAtomic]) then
        begin
          Value := NewValue(Builder, Builder.Tree^.Nodes[Node].TypeId);
          Emit(Builder, irAllocHandle, Value, IR_INVALID_VALUE,
            IR_INVALID_VALUE, IR_INVALID_VALUE,
            Builder.Tree^.Nodes[Node].TypeId,
            Builder.Tree^.Nodes[Node].SymbolId, IR_INVALID_BLOCK,
            IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX,
            Builder.Symbols^.Types[Builder.Tree^.Nodes[Node].TypeId].Size,
            0.0, Builder.Tree^.Nodes[Node].Span);
          if (Builder.Tree^.Nodes[Node].SymbolId >= 0) and
             (Builder.Symbols^.Symbols[
               Builder.Tree^.Nodes[Node].SymbolId].Kind = skField) then
          begin
            BaseValue := LoadCurrentReceiver(Builder,
              SymMakeReferenceType(Builder.Symbols^,
                Builder.Symbols^.Symbols[
                  Builder.Tree^.Nodes[Node].SymbolId].OwnerSymbol),
              Builder.Symbols^.Symbols[
                Builder.Tree^.Nodes[Node].SymbolId].OwnerSymbol,
              Builder.Tree^.Nodes[Node].Span);
            Emit(Builder, irStoreField, IR_INVALID_VALUE, BaseValue, Value,
              IR_INVALID_VALUE, Builder.Tree^.Nodes[Node].TypeId,
              Builder.Tree^.Nodes[Node].SymbolId, IR_INVALID_BLOCK,
              IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
              Builder.Tree^.Nodes[Node].Span);
          end
          else
            Emit(Builder, irStoreSymbol, IR_INVALID_VALUE, Value,
              IR_INVALID_VALUE, IR_INVALID_VALUE,
              Builder.Tree^.Nodes[Node].TypeId,
              Builder.Tree^.Nodes[Node].SymbolId, IR_INVALID_BLOCK,
              IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
              Builder.Tree^.Nodes[Node].Span);
        end
        else if Child >= 0 then
        begin
          Value := LowerExpression(Builder, Child);
          Value := CoerceValue(Builder, Value,
            Builder.Tree^.Nodes[Child].TypeId,
            Builder.Tree^.Nodes[Node].TypeId,
            Builder.Tree^.Nodes[Child].Span);
          if (Builder.Tree^.Nodes[Node].SymbolId >= 0) and
             (Builder.Symbols^.Symbols[
               Builder.Tree^.Nodes[Node].SymbolId].Kind = skField) then
          begin
            BaseValue := LoadCurrentReceiver(Builder,
              SymMakeReferenceType(Builder.Symbols^,
                Builder.Symbols^.Symbols[
                  Builder.Tree^.Nodes[Node].SymbolId].OwnerSymbol),
              Builder.Symbols^.Symbols[
                Builder.Tree^.Nodes[Node].SymbolId].OwnerSymbol,
              Builder.Tree^.Nodes[Node].Span);
            Emit(Builder, irStoreField, IR_INVALID_VALUE, BaseValue, Value,
              IR_INVALID_VALUE, Builder.Tree^.Nodes[Node].TypeId,
              Builder.Tree^.Nodes[Node].SymbolId, IR_INVALID_BLOCK,
              IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
              Builder.Tree^.Nodes[Node].Span);
          end
          else
            Emit(Builder, irStoreSymbol, IR_INVALID_VALUE, Value,
              IR_INVALID_VALUE, IR_INVALID_VALUE,
              Builder.Tree^.Nodes[Node].TypeId,
              Builder.Tree^.Nodes[Node].SymbolId, IR_INVALID_BLOCK,
              IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
              Builder.Tree^.Nodes[Node].Span);
        end;
      end;
    nkAssignmentStatement, nkReferenceAssignmentStatement:
      LowerAssignment(Builder, Node);
    nkIfStatement: LowerIf(Builder, Node);
    nkWhileStatement: LowerWhile(Builder, Node);
    nkForStatement: LowerFor(Builder, Node);
    nkRepeatStatement: LowerRepeat(Builder, Node);
    nkGotoStatement: LowerGoto(Builder, Node);
    nkLabelStatement: LowerLabel(Builder, Node);
    nkInspectStatement: LowerInspect(Builder, Node);
    nkCaseStatement: LowerCase(Builder, Node);
    nkWithStatement:
      begin
        LowerExpression(Builder, ASTChildAt(Builder.Tree^, Node, 0));
        LowerNode(Builder, ASTChildAt(Builder.Tree^, Node, 1));
      end;
    nkTryStatement: LowerTry(Builder, Node);
    nkCatchClause:
      begin
        Emit(Builder, irCatchBegin, IR_INVALID_VALUE, IR_INVALID_VALUE,
          IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID,
          FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
          FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
        Child := Builder.Tree^.Nodes[Node].FirstChild;
        while Child >= 0 do
        begin
          LowerNode(Builder, Child);
          Child := Builder.Tree^.Nodes[Child].NextSibling;
        end;
        Emit(Builder, irCatchEnd, IR_INVALID_VALUE, IR_INVALID_VALUE,
          IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID,
          FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
          FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
      end;
    nkFinallyClause:
      begin
        Emit(Builder, irFinallyBegin, IR_INVALID_VALUE, IR_INVALID_VALUE,
          IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID,
          FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
          FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
        Child := Builder.Tree^.Nodes[Node].FirstChild;
        while Child >= 0 do
        begin
          LowerNode(Builder, Child);
          Child := Builder.Tree^.Nodes[Child].NextSibling;
        end;
        Emit(Builder, irFinallyEnd, IR_INVALID_VALUE, IR_INVALID_VALUE,
          IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID,
          FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
          FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
      end;
    nkRaiseStatement:
      begin
        Value := LowerExpression(Builder, ASTChildAt(Builder.Tree^, Node, 0));
        Emit(Builder, irRaise, IR_INVALID_VALUE, Value, IR_INVALID_VALUE,
          IR_INVALID_VALUE, FSIM_TYPE_VOID, FSIM_INVALID_INDEX,
          TopTarget(Builder.ExceptionTargets), IR_INVALID_BLOCK, 0,
          FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
      end;
    nkReturnStatement:
      begin
        Child := ASTChildAt(Builder.Tree^, Node, 0);
        if Child >= 0 then
        begin
          Value := LowerExpression(Builder, Child);
          Value := CoerceValue(Builder, Value,
            Builder.Tree^.Nodes[Child].TypeId,
            Builder.Tree^.Nodes[Node].TypeId,
            Builder.Tree^.Nodes[Child].Span);
        end
        else Value := IR_INVALID_VALUE;
        Emit(Builder, irReturn, IR_INVALID_VALUE, Value, IR_INVALID_VALUE,
          IR_INVALID_VALUE, Builder.Tree^.Nodes[Node].TypeId,
          FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
          FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
      end;
    nkExitStatement:
      begin
        Child := ASTChildAt(Builder.Tree^, Node, 0);
        if Child >= 0 then Value := LowerExpression(Builder, Child)
        else
        begin
          Value := NewValue(Builder, FSIM_TYPE_INTEGER);
          Emit(Builder, irConstInt, Value, IR_INVALID_VALUE, IR_INVALID_VALUE,
            IR_INVALID_VALUE, FSIM_TYPE_INTEGER, FSIM_INVALID_INDEX,
            IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
            Builder.Tree^.Nodes[Node].Span);
        end;
        Emit(Builder, irExitProcess, IR_INVALID_VALUE, Value,
          IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID,
          FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
          FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
      end;
    nkBreakStatement:
      begin
        Target := TopTarget(Builder.BreakTargets);
        Emit(Builder, irBranch, IR_INVALID_VALUE, IR_INVALID_VALUE,
          IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID,
          FSIM_INVALID_INDEX, Target, IR_INVALID_BLOCK, 0,
          FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
      end;
    nkContinueStatement:
      begin
        Target := TopTarget(Builder.ContinueTargets);
        Emit(Builder, irBranch, IR_INVALID_VALUE, IR_INVALID_VALUE,
          IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID,
          FSIM_INVALID_INDEX, Target, IR_INVALID_BLOCK, 0,
          FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
      end;
    nkAssertStatement:
      begin
        Value := LowerExpression(Builder, ASTChildAt(Builder.Tree^, Node, 0));
        Emit(Builder, irAssert, IR_INVALID_VALUE, Value, IR_INVALID_VALUE,
          IR_INVALID_VALUE, FSIM_TYPE_VOID, FSIM_INVALID_INDEX,
          IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
          Builder.Tree^.Nodes[Node].Span);
      end;
    nkOutputStatement: LowerOutput(Builder, Node);
    nkExpressionStatement:
      LowerExpression(Builder, ASTChildAt(Builder.Tree^, Node, 0));
    nkDetachStatement:
      Emit(Builder, irProcessDetach, IR_INVALID_VALUE, IR_INVALID_VALUE,
        IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID,
        FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
        FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
    nkResumeStatement:
      LowerActivation(Builder, Node, irProcessResume);
    nkActivateStatement:
      LowerActivation(Builder, Node, irProcessActivate);
    nkReactivateStatement:
      LowerActivation(Builder, Node, irProcessReactivate);
    nkDelayStatement:
      LowerActivation(Builder, Node, irProcessDelay);
    nkHoldStatement:
      LowerActivation(Builder, Node, irProcessHold);
    nkCancelStatement:
      LowerModernUnary(Builder, Node, irThreadCancel, False);
    nkSpawnStatement:
      LowerModernUnary(Builder, Node, irThreadSpawn, False);
    nkJoinStatement:
      LowerModernUnary(Builder, Node, irThreadJoin, False);
    nkYieldStatement:
      LowerModernUnary(Builder, Node, irThreadYield, False);
    nkReceiveStatement:
      LowerModernUnary(Builder, Node, irChannelReceive, False);
    nkLockStatement:
      LowerModernUnary(Builder, Node, irMutexLock, False);
    nkUnlockStatement:
      LowerModernUnary(Builder, Node, irMutexUnlock, False);
    nkSendStatement:
      LowerSend(Builder, Node);
    nkParallelStatement:
      LowerWrapped(Builder, Node, irParallelBegin, irParallelEnd);
    nkCriticalStatement:
      LowerWrapped(Builder, Node, irCriticalBegin, irCriticalEnd);
    nkDeferStatement:
      LowerWrapped(Builder, Node, irDeferBegin, irDeferEnd);
    nkInnerStatement:
      Emit(Builder, irNop, IR_INVALID_VALUE, IR_INVALID_VALUE,
        IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID,
        FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
        FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span,
        [iifSynthetic]);
    nkPassivateStatement:
      Emit(Builder, irProcessPassivate, IR_INVALID_VALUE, IR_INVALID_VALUE,
        IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID,
        FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
        FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
  end;
end;

procedure LowerClassConstruction(var Builder: TIRBuilder;
  ClassSymbol, ReceiverValue: Int32; ContinuationNode: Int32);
var
  Chain: TInt32Array;
  SavedReceiver: Int32;

  procedure BuildChain(SymbolId: Int32);
  var
    ClassIndex, PrefixClass, Count, I: Int32;
  begin
    SetLength(Chain, 0);
    while SymbolId >= 0 do
    begin
      ClassIndex := SymClassIndex(Builder.Symbols^, SymbolId);
      if ClassIndex < 0 then Break;
      Count := Length(Chain);
      SetLength(Chain, Count + 1);
      Chain[Count] := SymbolId;
      PrefixClass := Builder.Symbols^.Classes[ClassIndex].PrefixClass;
      SymbolId := PrefixClass;
    end;
    for I := 0 to (Length(Chain) div 2) - 1 do
    begin
      SymbolId := Chain[I];
      Chain[I] := Chain[High(Chain) - I];
      Chain[High(Chain) - I] := SymbolId;
    end;
  end;

  procedure LowerContinuation(Level: Int32); forward;

  procedure LowerClassChild(Child, Level: Int32; var InnerSeen: Boolean);
  var
    Nested: Int32;
  begin
    if (Child < 0) or (Child > High(Builder.Tree^.Nodes)) then Exit;
    case Builder.Tree^.Nodes[Child].Kind of
      nkParameterDecl, nkVisibilitySection, nkVirtualSection, nkVirtualSpec,
      nkProcedureDecl, nkFunctionDecl, nkClassDecl, nkProcessClassDecl,
      nkThreadClassDecl, nkTypeDecl, nkLabelDecl, nkSwitchDecl:
        Exit;
      nkInnerStatement:
        begin
          InnerSeen := True;
          LowerContinuation(Level + 1);
          Exit;
        end;
      nkBlock, nkBlockStatement, nkStatementList:
        begin
          Nested := Builder.Tree^.Nodes[Child].FirstChild;
          while Nested >= 0 do
          begin
            LowerClassChild(Nested, Level, InnerSeen);
            if IRBlockTerminated(Builder.ProgramIR^, Builder.CurrentBlock) then
              Exit;
            Nested := Builder.Tree^.Nodes[Nested].NextSibling;
          end;
          Exit;
        end;
    else
      LowerNode(Builder, Child);
    end;
  end;

  procedure LowerContinuation(Level: Int32);
  var
    ClassNode, Child: Int32;
    InnerSeen: Boolean;
  begin
    if Level >= Length(Chain) then
    begin
      if ContinuationNode >= 0 then
        LowerNode(Builder, ContinuationNode);
      Exit;
    end;
    if (Chain[Level] < 0) or
       (Chain[Level] > High(Builder.Symbols^.Symbols)) then Exit;
    ClassNode := Builder.Symbols^.Symbols[Chain[Level]].DeclNode;
    if (ClassNode < 0) or (ClassNode > High(Builder.Tree^.Nodes)) then
    begin
      LowerContinuation(Level + 1);
      Exit;
    end;
    InnerSeen := False;
    Child := Builder.Tree^.Nodes[ClassNode].FirstChild;
    while Child >= 0 do
    begin
      LowerClassChild(Child, Level, InnerSeen);
      if IRBlockTerminated(Builder.ProgramIR^, Builder.CurrentBlock) then Exit;
      Child := Builder.Tree^.Nodes[Child].NextSibling;
    end;
    { A non-split prefix body behaves as though '; inner' occurred directly
      before its final end. }
    if not InnerSeen then
      LowerContinuation(Level + 1);
  end;

begin
  BuildChain(ClassSymbol);
  if Length(Chain) = 0 then Exit;
  SavedReceiver := Builder.CurrentReceiverValue;
  Builder.CurrentReceiverValue := ReceiverValue;
  LowerContinuation(0);
  Builder.CurrentReceiverValue := SavedReceiver;
end;

function RoutineReturnType(const Builder: TIRBuilder; SymbolId: Int32): Int32;
var
  TypeId: Int32;
begin
  if SymbolId < 0 then Exit(FSIM_TYPE_VOID);
  TypeId := Builder.Symbols^.Symbols[SymbolId].TypeId;
  if (TypeId >= 0) and (TypeId <= High(Builder.Symbols^.Types)) and
     (Builder.Symbols^.Types[TypeId].Kind = tyProcedure) then
    Result := Builder.Symbols^.Types[TypeId].ReturnType
  else
    Result := FSIM_TYPE_VOID;
end;

procedure LowerRoutine(var Builder: TIRBuilder; Node: Int32; IsEntry: Boolean);
var
  SymbolId, FunctionId, EntryBlock, BodyNode, ReturnValue,
  DeclaredReturnType, PrefixClass, PrefixType, ClassIndex, ArgumentNode,
  ArgumentValue, ParameterIndex, RoutineType, FormalIndex,
  FormalParameterIndex, StoreAux, CopiedValue: Int32;
  ParameterMode: TPassingMode;
  Flags: TIRFunctionFlags;
  Name: RawByteString;
begin
  SymbolId := Builder.Tree^.Nodes[Node].SymbolId;
  Name := ASTNodeName(Builder.Tree^, Node);
  if (SymbolId >= 0) and (SymbolId <= High(Builder.Symbols^.Symbols)) then
  begin
    RoutineType := Builder.Symbols^.Symbols[SymbolId].TypeId;
    if (RoutineType >= 0) and (RoutineType <= High(Builder.Symbols^.Types)) and
       (Builder.Symbols^.Types[RoutineType].Kind = tyProcedure) then
      for FormalIndex := 0 to
        Builder.Symbols^.Types[RoutineType].ParameterCount - 1 do
        if Builder.Symbols^.Parameters[
          Builder.Symbols^.Types[RoutineType].ParameterStart +
          FormalIndex].Mode = pmName then
          AddError(Builder.Diagnostics^, dcBackendUnsupported,
            Builder.Tree^.Nodes[Node].Span,
            'native call-by-name lowering requires thunk environments and is currently unavailable for native emission');
  end;
  Flags := [iffLeaf];
  if IsEntry then Include(Flags, iffEntry);
  if SymbolId >= 0 then
  begin
    if (Builder.Symbols^.Symbols[SymbolId].OwnerSymbol >= 0) and
       (Builder.Symbols^.Symbols[
         Builder.Symbols^.Symbols[SymbolId].OwnerSymbol].Kind in
         [skClass, skProcessClass, skThreadClass]) then
      Include(Flags, iffMethod);
    if sfVirtual in Builder.Symbols^.Symbols[SymbolId].Flags then
      Include(Flags, iffVirtual);
    if sfExported in Builder.Symbols^.Symbols[SymbolId].Flags then
      Include(Flags, iffExported);
  end;
  FunctionId := IRNewFunction(Builder.ProgramIR^, SymbolId,
    StringPoolIntern(Builder.ProgramIR^.Strings, Name),
    RoutineReturnType(Builder, SymbolId), Flags);
  if IsEntry then Builder.ProgramIR^.EntryFunction := FunctionId;
  Builder.CurrentFunction := FunctionId;
  Builder.CurrentResultValue := IR_INVALID_VALUE;
  Builder.CurrentReceiverValue := IR_INVALID_VALUE;
  ResetFunctionLabels(Builder);
  EntryBlock := IRNewBlock(Builder.ProgramIR^, FunctionId, [ibfEntry]);
  Builder.CurrentBlock := EntryBlock;
  BodyNode := Builder.Tree^.Nodes[Node].BodyNode;
  if BodyNode < 0 then
  begin
    BodyNode := Builder.Tree^.Nodes[Node].FirstChild;
    while (BodyNode >= 0) and
      (Builder.Tree^.Nodes[BodyNode].Kind = nkParameterDecl) do
      BodyNode := Builder.Tree^.Nodes[BodyNode].NextSibling;
  end;
  PrefixClass := Builder.Tree^.Nodes[Node].A;
  if IsEntry and (PrefixClass >= 0) then
  begin
    PrefixType := SymMakeReferenceType(Builder.Symbols^, PrefixClass);
    Builder.CurrentReceiverValue := NewValue(Builder, PrefixType);
    Emit(Builder, irAllocObject, Builder.CurrentReceiverValue,
      IR_INVALID_VALUE, IR_INVALID_VALUE, IR_INVALID_VALUE, PrefixType,
      PrefixClass, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
      FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
    Emit(Builder, irInitObject, IR_INVALID_VALUE,
      Builder.CurrentReceiverValue, IR_INVALID_VALUE, IR_INVALID_VALUE,
      PrefixType, PrefixClass, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
      FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
    ClassIndex := SymClassIndex(Builder.Symbols^, PrefixClass);
    ArgumentNode := Builder.Tree^.Nodes[Node].FirstChild;
    ParameterIndex := 0;
    while (ArgumentNode >= 0) and (ArgumentNode <> Builder.Tree^.Nodes[Node].BodyNode) and
          (ClassIndex >= 0) and
          (ParameterIndex < Builder.Symbols^.Classes[ClassIndex].ParameterCount) do
    begin
      ArgumentValue := LowerExpression(Builder, ArgumentNode);
      FormalParameterIndex :=
        Builder.Symbols^.Classes[ClassIndex].ParameterStart + ParameterIndex;
      StoreAux := 0;
      if (Builder.Options^.Dialect = fdSimula67) and
         (Builder.Symbols^.Parameters[FormalParameterIndex].TypeId =
           FSIM_TYPE_TEXT) then
      begin
        ParameterMode := Builder.Symbols^.Parameters[FormalParameterIndex].Mode;
        if ParameterMode = pmValue then
        begin
          CopiedValue := NewValue(Builder, FSIM_TYPE_TEXT);
          Emit(Builder, irTextCopy, CopiedValue, ArgumentValue,
            IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_TEXT,
            FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
            FSIM_INVALID_INDEX, 0, 0.0,
            Builder.Tree^.Nodes[ArgumentNode].Span);
          ArgumentValue := CopiedValue;
        end;
        StoreAux := 1;
      end;
      Emit(Builder, irStoreField, IR_INVALID_VALUE,
        Builder.CurrentReceiverValue, ArgumentValue, IR_INVALID_VALUE,
        Builder.Symbols^.Parameters[FormalParameterIndex].TypeId,
        Builder.Symbols^.Parameters[FormalParameterIndex].SymbolId,
        IR_INVALID_BLOCK, IR_INVALID_BLOCK, StoreAux,
        FSIM_INVALID_INDEX, 0, 0.0,
        Builder.Tree^.Nodes[ArgumentNode].Span);
      Inc(ParameterIndex);
      ArgumentNode := Builder.Tree^.Nodes[ArgumentNode].NextSibling;
    end;
    LowerClassConstruction(Builder, PrefixClass,
      Builder.CurrentReceiverValue, BodyNode);
    BodyNode := FSIM_INVALID_INDEX;
  end;
  DeclaredReturnType := RoutineReturnType(Builder, SymbolId);
  if (not IsEntry) and (DeclaredReturnType <> FSIM_TYPE_VOID) then
  begin
    Builder.CurrentResultValue := NewValue(Builder, DeclaredReturnType);
    if DeclaredReturnType = FSIM_TYPE_REAL then
      Emit(Builder, irConstReal, Builder.CurrentResultValue,
        IR_INVALID_VALUE, IR_INVALID_VALUE, IR_INVALID_VALUE,
        DeclaredReturnType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
        IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
        Builder.Tree^.Nodes[Node].Span)
    else if (DeclaredReturnType in [FSIM_TYPE_TEXT, FSIM_TYPE_STRING]) or
      ((DeclaredReturnType >= 0) and
       (DeclaredReturnType <= High(Builder.Symbols^.Types)) and
       (tfReferenceType in Builder.Symbols^.Types[DeclaredReturnType].Flags)) then
      Emit(Builder, irConstNull, Builder.CurrentResultValue,
        IR_INVALID_VALUE, IR_INVALID_VALUE, IR_INVALID_VALUE,
        DeclaredReturnType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
        IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
        Builder.Tree^.Nodes[Node].Span)
    else
      Emit(Builder, irConstInt, Builder.CurrentResultValue,
        IR_INVALID_VALUE, IR_INVALID_VALUE, IR_INVALID_VALUE,
        DeclaredReturnType, FSIM_INVALID_INDEX, IR_INVALID_BLOCK,
        IR_INVALID_BLOCK, 0, FSIM_INVALID_INDEX, 0, 0.0,
        Builder.Tree^.Nodes[Node].Span);
  end;
  if BodyNode >= 0 then LowerNode(Builder, BodyNode);
  if not IRBlockTerminated(Builder.ProgramIR^, Builder.CurrentBlock) then
  begin
    if IsEntry then
    begin
      ReturnValue := NewValue(Builder, FSIM_TYPE_INTEGER);
      Emit(Builder, irConstInt, ReturnValue, IR_INVALID_VALUE,
        IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_INTEGER,
        FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
        FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
      Emit(Builder, irExitProcess, IR_INVALID_VALUE, ReturnValue,
        IR_INVALID_VALUE, IR_INVALID_VALUE, FSIM_TYPE_VOID,
        FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
        FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
    end
    else
      Emit(Builder, irReturn, IR_INVALID_VALUE, Builder.CurrentResultValue,
        IR_INVALID_VALUE, IR_INVALID_VALUE, DeclaredReturnType,
        FSIM_INVALID_INDEX, IR_INVALID_BLOCK, IR_INVALID_BLOCK, 0,
        FSIM_INVALID_INDEX, 0, 0.0, Builder.Tree^.Nodes[Node].Span);
  end;
  Builder.ProgramIR^.Functions[FunctionId].ExitBlock := Builder.CurrentBlock;
  Include(Builder.ProgramIR^.Blocks[Builder.CurrentBlock].Flags, ibfExit);
end;

procedure WalkRoutines(var Builder: TIRBuilder; Node: Int32;
  var EntrySeen: Boolean);
var
  Child: Int32;
begin
  case Builder.Tree^.Nodes[Node].Kind of
    nkProgramDecl:
      begin
        LowerRoutine(Builder, Node, not EntrySeen);
        EntrySeen := True;
      end;
    nkProcedureDecl, nkFunctionDecl:
      if (Builder.Tree^.Nodes[Node].SymbolId < 0) or
         not (sfImported in Builder.Symbols^.Symbols[
           Builder.Tree^.Nodes[Node].SymbolId].Flags) then
        LowerRoutine(Builder, Node, False);
  end;
  Child := Builder.Tree^.Nodes[Node].FirstChild;
  while Child >= 0 do
  begin
    WalkRoutines(Builder, Child, EntrySeen);
    Child := Builder.Tree^.Nodes[Child].NextSibling;
  end;
end;

procedure LowerCompilationUnit(var Builder: TIRBuilder);
var
  EntrySeen: Boolean;
begin
  EntrySeen := False;
  WalkRoutines(Builder, Builder.Tree^.Root, EntrySeen);
  if not EntrySeen then
    AddError(Builder.Diagnostics^, dcInvalidControlFlow,
      Builder.Tree^.Nodes[Builder.Tree^.Root].Span,
      'compilation unit does not contain an executable program block');
  IRBuildEdges(Builder.ProgramIR^);
  IRComputeUseLists(Builder.ProgramIR^);
  IRVerify(Builder.ProgramIR^);
end;

end.

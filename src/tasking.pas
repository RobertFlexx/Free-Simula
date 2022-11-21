unit tasking;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, core, diagnostics;

type
  TMemoryOrder = (
    moRelaxed,
    moAcquire,
    moRelease,
    moAcquireRelease,
    moSequentiallyConsistent
  );

  TConcurrencyPrimitiveKind = (
    cpkTask,
    cpkFuture,
    cpkChannel,
    cpkMutex,
    cpkReadWriteLock,
    cpkSemaphore,
    cpkBarrier,
    cpkConditionVariable,
    cpkOnce,
    cpkAtomic
  );

  TTaskState = (
    tsCreated,
    tsRunnable,
    tsRunning,
    tsWaiting,
    tsCompleted,
    tsCancelled,
    tsPanicked
  );

  TChannelMode = (
    cmRendezvous,
    cmBounded,
    cmUnbounded
  );

  TChannelDirection = (
    cdBidirectional,
    cdSendOnly,
    cdReceiveOnly
  );

  TLockMode = (
    lmExclusive,
    lmShared,
    lmUpgradeable
  );

  TTaskFlag = (
    ttfNone,
    ttfDetached,
    ttfJoinable,
    ttfCancellable,
    ttfDaemon,
    ttfProcessCompatible,
    ttfHasResult,
    ttfHasException
  );
  TTaskFlags = set of TTaskFlag;

  TTaskDescriptor = packed record
    SymbolId: Int32;
    EntrySymbol: Int32;
    ResultType: Int32;
    ArgumentType: Int32;
    State: TTaskState;
    Flags: TTaskFlags;
    StackSize: UInt32;
    Priority: Int16;
    AffinityIndex: Int16;
    SourceNode: Int32;
  end;

  TFutureDescriptor = packed record
    SymbolId: Int32;
    ValueType: Int32;
    ProducerTask: Int32;
    StateWordOffset: UInt32;
    ValueOffset: UInt32;
    ExceptionOffset: UInt32;
    WaiterHeadOffset: UInt32;
    SourceNode: Int32;
  end;

  TChannelDescriptor = packed record
    SymbolId: Int32;
    ElementType: Int32;
    Capacity: UInt32;
    Mode: TChannelMode;
    Direction: TChannelDirection;
    ElementSize: UInt32;
    ElementAlignment: UInt32;
    RingOffset: UInt32;
    HeadOffset: UInt32;
    TailOffset: UInt32;
    CountOffset: UInt32;
    ClosedOffset: UInt32;
    SendWaitersOffset: UInt32;
    ReceiveWaitersOffset: UInt32;
    SourceNode: Int32;
  end;

  TMutexDescriptor = packed record
    SymbolId: Int32;
    Recursive: Boolean;
    Fair: Boolean;
    SpinCount: UInt16;
    StateOffset: UInt32;
    OwnerOffset: UInt32;
    RecursionOffset: UInt32;
    WaiterOffset: UInt32;
    SourceNode: Int32;
  end;

  TAtomicDescriptor = packed record
    SymbolId: Int32;
    ValueType: Int32;
    Width: UInt8;
    Alignment: UInt8;
    SignedValue: Boolean;
    LockFree: Boolean;
    DefaultLoadOrder: TMemoryOrder;
    DefaultStoreOrder: TMemoryOrder;
    SourceNode: Int32;
  end;

  TBarrierDescriptor = packed record
    SymbolId: Int32;
    ParticipantCount: UInt32;
    CounterOffset: UInt32;
    GenerationOffset: UInt32;
    WaiterOffset: UInt32;
    SourceNode: Int32;
  end;

  TConcurrencyRegistry = record
    Tasks: array of TTaskDescriptor;
    Futures: array of TFutureDescriptor;
    Channels: array of TChannelDescriptor;
    Mutexes: array of TMutexDescriptor;
    Atomics: array of TAtomicDescriptor;
    Barriers: array of TBarrierDescriptor;
  end;

procedure ConcurrencyRegistryInit(var Registry: TConcurrencyRegistry);
procedure ConcurrencyRegistryClear(var Registry: TConcurrencyRegistry);
function AddTaskDescriptor(var Registry: TConcurrencyRegistry;
  const Descriptor: TTaskDescriptor): Int32;
function AddFutureDescriptor(var Registry: TConcurrencyRegistry;
  const Descriptor: TFutureDescriptor): Int32;
function AddChannelDescriptor(var Registry: TConcurrencyRegistry;
  const Descriptor: TChannelDescriptor): Int32;
function AddMutexDescriptor(var Registry: TConcurrencyRegistry;
  const Descriptor: TMutexDescriptor): Int32;
function AddAtomicDescriptor(var Registry: TConcurrencyRegistry;
  const Descriptor: TAtomicDescriptor): Int32;
function AddBarrierDescriptor(var Registry: TConcurrencyRegistry;
  const Descriptor: TBarrierDescriptor): Int32;
function FindTaskDescriptor(const Registry: TConcurrencyRegistry;
  SymbolId: Int32): Int32;
function FindFutureDescriptor(const Registry: TConcurrencyRegistry;
  SymbolId: Int32): Int32;
function FindChannelDescriptor(const Registry: TConcurrencyRegistry;
  SymbolId: Int32): Int32;
function FindMutexDescriptor(const Registry: TConcurrencyRegistry;
  SymbolId: Int32): Int32;
function FindAtomicDescriptor(const Registry: TConcurrencyRegistry;
  SymbolId: Int32): Int32;
function FindBarrierDescriptor(const Registry: TConcurrencyRegistry;
  SymbolId: Int32): Int32;
function MemoryOrderName(Order: TMemoryOrder): RawByteString;
function MemoryOrderAllowsLoad(Order: TMemoryOrder): Boolean;
function MemoryOrderAllowsStore(Order: TMemoryOrder): Boolean;
function MemoryOrderIsAtLeast(Order, Required: TMemoryOrder): Boolean;
function TaskTransitionAllowed(FromState, ToState: TTaskState): Boolean;
function TransitionTask(var Registry: TConcurrencyRegistry;
  TaskIndex: Int32; NewState: TTaskState): Boolean;
function ChannelStorageBytes(const Descriptor: TChannelDescriptor): QWord;
procedure LayoutChannel(var Descriptor: TChannelDescriptor;
  BaseOffset: UInt32);
procedure LayoutFuture(var Descriptor: TFutureDescriptor;
  BaseOffset, ValueSize, ValueAlignment: UInt32);
procedure LayoutMutex(var Descriptor: TMutexDescriptor;
  BaseOffset: UInt32);
procedure LayoutBarrier(var Descriptor: TBarrierDescriptor;
  BaseOffset: UInt32);
procedure ValidateTaskDescriptor(const Descriptor: TTaskDescriptor;
  const Span: TSourceSpan; var Diagnostics: TDiagnosticBag);
procedure ValidateFutureDescriptor(const Descriptor: TFutureDescriptor;
  const Span: TSourceSpan; var Diagnostics: TDiagnosticBag);
procedure ValidateChannelDescriptor(const Descriptor: TChannelDescriptor;
  const Span: TSourceSpan; var Diagnostics: TDiagnosticBag);
procedure ValidateMutexDescriptor(const Descriptor: TMutexDescriptor;
  const Span: TSourceSpan; var Diagnostics: TDiagnosticBag);
procedure ValidateAtomicDescriptor(const Descriptor: TAtomicDescriptor;
  const Span: TSourceSpan; var Diagnostics: TDiagnosticBag);
procedure ValidateBarrierDescriptor(const Descriptor: TBarrierDescriptor;
  const Span: TSourceSpan; var Diagnostics: TDiagnosticBag);
procedure ValidateAtomicLoadOrder(Order: TMemoryOrder;
  const Span: TSourceSpan; var Diagnostics: TDiagnosticBag);
procedure ValidateAtomicStoreOrder(Order: TMemoryOrder;
  const Span: TSourceSpan; var Diagnostics: TDiagnosticBag);
procedure ValidateCompareExchangeOrders(SuccessOrder, FailureOrder: TMemoryOrder;
  const Span: TSourceSpan; var Diagnostics: TDiagnosticBag);

implementation

const
  TASK_MINIMUM_STACK = 65536;
  TASK_MAXIMUM_STACK = UInt32(1024) * 1024 * 1024;
  CHANNEL_HEADER_SIZE = 64;
  FUTURE_HEADER_SIZE = 32;
  MUTEX_STORAGE_SIZE = 32;
  BARRIER_STORAGE_SIZE = 24;

procedure ConcurrencyRegistryInit(var Registry: TConcurrencyRegistry);
begin
  Registry := Default(TConcurrencyRegistry);
end;

procedure ConcurrencyRegistryClear(var Registry: TConcurrencyRegistry);
begin
  SetLength(Registry.Tasks, 0);
  SetLength(Registry.Futures, 0);
  SetLength(Registry.Channels, 0);
  SetLength(Registry.Mutexes, 0);
  SetLength(Registry.Atomics, 0);
  SetLength(Registry.Barriers, 0);
end;

function AddTaskDescriptor(var Registry: TConcurrencyRegistry;
  const Descriptor: TTaskDescriptor): Int32;
begin
  Result := Length(Registry.Tasks);
  SetLength(Registry.Tasks, Result + 1);
  Registry.Tasks[Result] := Descriptor;
end;

function AddFutureDescriptor(var Registry: TConcurrencyRegistry;
  const Descriptor: TFutureDescriptor): Int32;
begin
  Result := Length(Registry.Futures);
  SetLength(Registry.Futures, Result + 1);
  Registry.Futures[Result] := Descriptor;
end;

function AddChannelDescriptor(var Registry: TConcurrencyRegistry;
  const Descriptor: TChannelDescriptor): Int32;
begin
  Result := Length(Registry.Channels);
  SetLength(Registry.Channels, Result + 1);
  Registry.Channels[Result] := Descriptor;
end;

function AddMutexDescriptor(var Registry: TConcurrencyRegistry;
  const Descriptor: TMutexDescriptor): Int32;
begin
  Result := Length(Registry.Mutexes);
  SetLength(Registry.Mutexes, Result + 1);
  Registry.Mutexes[Result] := Descriptor;
end;

function AddAtomicDescriptor(var Registry: TConcurrencyRegistry;
  const Descriptor: TAtomicDescriptor): Int32;
begin
  Result := Length(Registry.Atomics);
  SetLength(Registry.Atomics, Result + 1);
  Registry.Atomics[Result] := Descriptor;
end;

function AddBarrierDescriptor(var Registry: TConcurrencyRegistry;
  const Descriptor: TBarrierDescriptor): Int32;
begin
  Result := Length(Registry.Barriers);
  SetLength(Registry.Barriers, Result + 1);
  Registry.Barriers[Result] := Descriptor;
end;

function FindTaskDescriptor(const Registry: TConcurrencyRegistry;
  SymbolId: Int32): Int32;
var Index: Int32;
begin
  for Index := 0 to High(Registry.Tasks) do
    if Registry.Tasks[Index].SymbolId = SymbolId then Exit(Index);
  Result := FSIM_INVALID_INDEX;
end;

function FindFutureDescriptor(const Registry: TConcurrencyRegistry;
  SymbolId: Int32): Int32;
var Index: Int32;
begin
  for Index := 0 to High(Registry.Futures) do
    if Registry.Futures[Index].SymbolId = SymbolId then Exit(Index);
  Result := FSIM_INVALID_INDEX;
end;

function FindChannelDescriptor(const Registry: TConcurrencyRegistry;
  SymbolId: Int32): Int32;
var Index: Int32;
begin
  for Index := 0 to High(Registry.Channels) do
    if Registry.Channels[Index].SymbolId = SymbolId then Exit(Index);
  Result := FSIM_INVALID_INDEX;
end;

function FindMutexDescriptor(const Registry: TConcurrencyRegistry;
  SymbolId: Int32): Int32;
var Index: Int32;
begin
  for Index := 0 to High(Registry.Mutexes) do
    if Registry.Mutexes[Index].SymbolId = SymbolId then Exit(Index);
  Result := FSIM_INVALID_INDEX;
end;

function FindAtomicDescriptor(const Registry: TConcurrencyRegistry;
  SymbolId: Int32): Int32;
var Index: Int32;
begin
  for Index := 0 to High(Registry.Atomics) do
    if Registry.Atomics[Index].SymbolId = SymbolId then Exit(Index);
  Result := FSIM_INVALID_INDEX;
end;

function FindBarrierDescriptor(const Registry: TConcurrencyRegistry;
  SymbolId: Int32): Int32;
var Index: Int32;
begin
  for Index := 0 to High(Registry.Barriers) do
    if Registry.Barriers[Index].SymbolId = SymbolId then Exit(Index);
  Result := FSIM_INVALID_INDEX;
end;

function MemoryOrderName(Order: TMemoryOrder): RawByteString;
begin
  case Order of
    moRelaxed: Result := 'relaxed';
    moAcquire: Result := 'acquire';
    moRelease: Result := 'release';
    moAcquireRelease: Result := 'acquire_release';
    moSequentiallyConsistent: Result := 'sequentially_consistent';
  else
    Result := 'invalid';
  end;
end;

function MemoryOrderAllowsLoad(Order: TMemoryOrder): Boolean;
begin
  Result := Order in [moRelaxed, moAcquire, moAcquireRelease,
    moSequentiallyConsistent];
end;

function MemoryOrderAllowsStore(Order: TMemoryOrder): Boolean;
begin
  Result := Order in [moRelaxed, moRelease, moAcquireRelease,
    moSequentiallyConsistent];
end;

function MemoryOrderRank(Order: TMemoryOrder): Int32;
begin
  case Order of
    moRelaxed: Result := 0;
    moAcquire, moRelease: Result := 1;
    moAcquireRelease: Result := 2;
    moSequentiallyConsistent: Result := 3;
  else
    Result := -1;
  end;
end;

function MemoryOrderIsAtLeast(Order, Required: TMemoryOrder): Boolean;
begin
  Result := MemoryOrderRank(Order) >= MemoryOrderRank(Required);
end;

function TaskTransitionAllowed(FromState, ToState: TTaskState): Boolean;
begin
  case FromState of
    tsCreated:
      Result := ToState in [tsRunnable, tsCancelled];
    tsRunnable:
      Result := ToState in [tsRunning, tsCancelled];
    tsRunning:
      Result := ToState in [tsRunnable, tsWaiting, tsCompleted,
        tsCancelled, tsPanicked];
    tsWaiting:
      Result := ToState in [tsRunnable, tsCancelled, tsPanicked];
    tsCompleted, tsCancelled, tsPanicked:
      Result := False;
  else
    Result := False;
  end;
end;

function TransitionTask(var Registry: TConcurrencyRegistry;
  TaskIndex: Int32; NewState: TTaskState): Boolean;
begin
  Result := (TaskIndex >= 0) and (TaskIndex <= High(Registry.Tasks)) and
    TaskTransitionAllowed(Registry.Tasks[TaskIndex].State, NewState);
  if Result then Registry.Tasks[TaskIndex].State := NewState;
end;

function ChannelStorageBytes(const Descriptor: TChannelDescriptor): QWord;
begin
  Result := CHANNEL_HEADER_SIZE;
  if Descriptor.Mode = cmBounded then
    Inc(Result, QWord(Descriptor.Capacity) * QWord(Descriptor.ElementSize));
end;

function AlignOffset(Value, Alignment: UInt32): UInt32;
begin
  if Alignment <= 1 then Exit(Value);
  Result := UInt32(AlignUp(Value, Alignment));
end;

procedure LayoutChannel(var Descriptor: TChannelDescriptor;
  BaseOffset: UInt32);
var
  Cursor: UInt32;
begin
  Cursor := AlignOffset(BaseOffset, 8);
  Descriptor.HeadOffset := Cursor;
  Inc(Cursor, 8);
  Descriptor.TailOffset := Cursor;
  Inc(Cursor, 8);
  Descriptor.CountOffset := Cursor;
  Inc(Cursor, 8);
  Descriptor.ClosedOffset := Cursor;
  Inc(Cursor, 4);
  Descriptor.SendWaitersOffset := AlignOffset(Cursor, 8);
  Cursor := Descriptor.SendWaitersOffset + 8;
  Descriptor.ReceiveWaitersOffset := Cursor;
  Cursor := Cursor + 8;
  Descriptor.RingOffset := AlignOffset(Cursor,
    Descriptor.ElementAlignment);
end;

procedure LayoutFuture(var Descriptor: TFutureDescriptor;
  BaseOffset, ValueSize, ValueAlignment: UInt32);
var
  Cursor: UInt32;
begin
  Cursor := AlignOffset(BaseOffset, 4);
  Descriptor.StateWordOffset := Cursor;
  Inc(Cursor, 4);
  Cursor := AlignOffset(Cursor, 8);
  Descriptor.ExceptionOffset := Cursor;
  Inc(Cursor, 8);
  Descriptor.WaiterHeadOffset := Cursor;
  Inc(Cursor, 8);
  Descriptor.ValueOffset := AlignOffset(Cursor, ValueAlignment);
  if ValueSize = 0 then
    Descriptor.ValueOffset := AlignOffset(BaseOffset + FUTURE_HEADER_SIZE,
      ValueAlignment);
end;

procedure LayoutMutex(var Descriptor: TMutexDescriptor;
  BaseOffset: UInt32);
begin
  Descriptor.StateOffset := AlignOffset(BaseOffset, 4);
  Descriptor.OwnerOffset := AlignOffset(Descriptor.StateOffset + 4, 8);
  Descriptor.RecursionOffset := Descriptor.OwnerOffset + 8;
  Descriptor.WaiterOffset := AlignOffset(Descriptor.RecursionOffset + 4, 8);
  if Descriptor.WaiterOffset + 8 < BaseOffset + MUTEX_STORAGE_SIZE then
    Descriptor.WaiterOffset := BaseOffset + MUTEX_STORAGE_SIZE - 8;
end;

procedure LayoutBarrier(var Descriptor: TBarrierDescriptor;
  BaseOffset: UInt32);
begin
  Descriptor.CounterOffset := AlignOffset(BaseOffset, 4);
  Descriptor.GenerationOffset := Descriptor.CounterOffset + 4;
  Descriptor.WaiterOffset := AlignOffset(Descriptor.GenerationOffset + 4, 8);
  if Descriptor.WaiterOffset + 8 < BaseOffset + BARRIER_STORAGE_SIZE then
    Descriptor.WaiterOffset := BaseOffset + BARRIER_STORAGE_SIZE - 8;
end;

procedure ValidateTaskDescriptor(const Descriptor: TTaskDescriptor;
  const Span: TSourceSpan; var Diagnostics: TDiagnosticBag);
begin
  if Descriptor.EntrySymbol < 0 then
    AddError(Diagnostics, dcUnknownSymbol, Span,
      'task entry routine is unresolved');
  if Descriptor.StackSize < TASK_MINIMUM_STACK then
    AddError(Diagnostics, dcInvalidControlFlow, Span,
      'task stack must be at least 65536 bytes');
  if Descriptor.StackSize > TASK_MAXIMUM_STACK then
    AddError(Diagnostics, dcInvalidControlFlow, Span,
      'task stack exceeds the one-gibibyte implementation limit');
  if (ttfDetached in Descriptor.Flags) and
     (ttfJoinable in Descriptor.Flags) then
    AddError(Diagnostics, dcInvalidControlFlow, Span,
      'a task cannot be both detached and joinable');
  if (Descriptor.Priority < -20) or (Descriptor.Priority > 19) then
    AddError(Diagnostics, dcInvalidControlFlow, Span,
      'task priority must lie in the native range -20 through 19');
end;

procedure ValidateFutureDescriptor(const Descriptor: TFutureDescriptor;
  const Span: TSourceSpan; var Diagnostics: TDiagnosticBag);
begin
  if Descriptor.ValueType < 0 then
    AddError(Diagnostics, dcUnknownType, Span,
      'future value type is unresolved');
  if Descriptor.ProducerTask < 0 then
    AddWarning(Diagnostics, dcInvalidControlFlow, Span,
      'future has no statically known producer task');
  if Descriptor.ValueOffset < FUTURE_HEADER_SIZE then
    AddError(Diagnostics, dcInternalError, Span,
      'future value overlaps its synchronization header');
end;

procedure ValidateChannelDescriptor(const Descriptor: TChannelDescriptor;
  const Span: TSourceSpan; var Diagnostics: TDiagnosticBag);
begin
  if Descriptor.ElementType < 0 then
    AddError(Diagnostics, dcUnknownType, Span,
      'channel element type is unresolved');
  if Descriptor.ElementSize = 0 then
    AddError(Diagnostics, dcTypeMismatch, Span,
      'channel element type has zero storage size');
  if not IsPowerOfTwo(Descriptor.ElementAlignment) then
    AddError(Diagnostics, dcTypeMismatch, Span,
      'channel element alignment must be a power of two');
  case Descriptor.Mode of
    cmRendezvous:
      if Descriptor.Capacity <> 0 then
        AddError(Diagnostics, dcInvalidControlFlow, Span,
          'rendezvous channels must have zero capacity');
    cmBounded:
      if Descriptor.Capacity = 0 then
        AddError(Diagnostics, dcInvalidControlFlow, Span,
          'bounded channels require positive capacity');
    cmUnbounded:
      if Descriptor.Capacity <> 0 then
        AddWarning(Diagnostics, dcInvalidControlFlow, Span,
          'unbounded channel capacity hint is ignored');
  end;
  if ChannelStorageBytes(Descriptor) > High(UInt32) then
    AddError(Diagnostics, dcOverflow, Span,
      'channel storage exceeds the four-gibibyte object limit');
end;

procedure ValidateMutexDescriptor(const Descriptor: TMutexDescriptor;
  const Span: TSourceSpan; var Diagnostics: TDiagnosticBag);
begin
  if Descriptor.SpinCount > 32768 then
    AddWarning(Diagnostics, dcInvalidControlFlow, Span,
      'large mutex spin count may starve peer threads');
  if Descriptor.Recursive and Descriptor.Fair then
    AddWarning(Diagnostics, dcInvalidControlFlow, Span,
      'fair recursive mutexes carry additional ownership overhead');
  if Descriptor.WaiterOffset <= Descriptor.OwnerOffset then
    AddError(Diagnostics, dcInternalError, Span,
      'mutex storage layout overlaps ownership state');
end;

procedure ValidateAtomicDescriptor(const Descriptor: TAtomicDescriptor;
  const Span: TSourceSpan; var Diagnostics: TDiagnosticBag);
begin
  if not (Descriptor.Width in [1, 2, 4, 8]) then
    AddError(Diagnostics, dcTypeMismatch, Span,
      'native atomics support widths of 1, 2, 4, or 8 bytes');
  if Descriptor.Alignment < Descriptor.Width then
    AddError(Diagnostics, dcTypeMismatch, Span,
      'atomic alignment must be at least its access width');
  if not Descriptor.LockFree and (Descriptor.Width <= 8) then
    AddWarning(Diagnostics, dcInvalidControlFlow, Span,
      'naturally aligned scalar atomic unexpectedly requires a lock');
  ValidateAtomicLoadOrder(Descriptor.DefaultLoadOrder, Span, Diagnostics);
  ValidateAtomicStoreOrder(Descriptor.DefaultStoreOrder, Span, Diagnostics);
end;

procedure ValidateBarrierDescriptor(const Descriptor: TBarrierDescriptor;
  const Span: TSourceSpan; var Diagnostics: TDiagnosticBag);
begin
  if Descriptor.ParticipantCount < 2 then
    AddError(Diagnostics, dcInvalidControlFlow, Span,
      'barrier requires at least two participants');
  if Descriptor.WaiterOffset <= Descriptor.GenerationOffset then
    AddError(Diagnostics, dcInternalError, Span,
      'barrier storage layout overlaps generation state');
end;

procedure ValidateAtomicLoadOrder(Order: TMemoryOrder;
  const Span: TSourceSpan; var Diagnostics: TDiagnosticBag);
begin
  if not MemoryOrderAllowsLoad(Order) then
    AddError(Diagnostics, dcInvalidControlFlow, Span,
      MemoryOrderName(Order) + ' is invalid for an atomic load');
end;

procedure ValidateAtomicStoreOrder(Order: TMemoryOrder;
  const Span: TSourceSpan; var Diagnostics: TDiagnosticBag);
begin
  if not MemoryOrderAllowsStore(Order) then
    AddError(Diagnostics, dcInvalidControlFlow, Span,
      MemoryOrderName(Order) + ' is invalid for an atomic store');
end;

procedure ValidateCompareExchangeOrders(SuccessOrder, FailureOrder: TMemoryOrder;
  const Span: TSourceSpan; var Diagnostics: TDiagnosticBag);
begin
  if FailureOrder in [moRelease, moAcquireRelease] then
    AddError(Diagnostics, dcInvalidControlFlow, Span,
      'compare-exchange failure order cannot contain release semantics');
  if not MemoryOrderAllowsLoad(FailureOrder) then
    AddError(Diagnostics, dcInvalidControlFlow, Span,
      'compare-exchange failure order must be a valid load order');
  if not MemoryOrderIsAtLeast(SuccessOrder, FailureOrder) then
    AddError(Diagnostics, dcInvalidControlFlow, Span,
      'compare-exchange failure order is stronger than success order');
end;

end.

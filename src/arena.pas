unit arena;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, core;

const
  FSIM_ARENA_BLOCK_SHIFT = 20;
  FSIM_ARENA_OFFSET_MASK = (QWord(1) shl FSIM_ARENA_BLOCK_SHIFT) - 1;

type
  TArenaOffset = QWord;
  TArenaBlock = packed record
    Base: PByte;
    Capacity: SizeUInt;
    Used: SizeUInt;
  end;
  TArena = record
    Blocks: array of TArenaBlock;
    DefaultBlockSize: SizeUInt;
    TotalReserved: QWord;
    TotalUsed: QWord;
    AllocationCount: QWord;
  end;

procedure ArenaInit(var Arena: TArena; DefaultBlockSize: SizeUInt = 1024 * 1024);
procedure ArenaDone(var Arena: TArena);
procedure ArenaReset(var Arena: TArena);
function ArenaAlloc(var Arena: TArena; Size: SizeUInt; Alignment: SizeUInt = 8): TArenaOffset;
function ArenaAllocZero(var Arena: TArena; Size: SizeUInt; Alignment: SizeUInt = 8): TArenaOffset;
function ArenaPtr(var Arena: TArena; Offset: TArenaOffset): Pointer;
function ArenaConstPtr(const Arena: TArena; Offset: TArenaOffset): Pointer;
function ArenaStore(var Arena: TArena; const Data; Size: SizeUInt; Alignment: SizeUInt = 1): TArenaOffset;
function ArenaStoreString(var Arena: TArena; const Value: RawByteString): TArenaOffset;
function ArenaString(var Arena: TArena; Offset: TArenaOffset): PAnsiChar;

implementation

procedure ArenaInit(var Arena: TArena; DefaultBlockSize: SizeUInt);
begin
  Arena := Default(TArena);
  if DefaultBlockSize < FSIM_PAGE_SIZE then
    DefaultBlockSize := FSIM_PAGE_SIZE;
  Arena.DefaultBlockSize := AlignUp(DefaultBlockSize, FSIM_PAGE_SIZE);
end;

procedure FreeBlock(var Block: TArenaBlock);
begin
  if Block.Base <> nil then
    FreeMem(Block.Base);
  Block := Default(TArenaBlock);
end;

procedure ArenaDone(var Arena: TArena);
var
  I: Integer;
begin
  for I := 0 to High(Arena.Blocks) do
    FreeBlock(Arena.Blocks[I]);
  SetLength(Arena.Blocks, 0);
  Arena.TotalReserved := 0;
  Arena.TotalUsed := 0;
  Arena.AllocationCount := 0;
end;

procedure ArenaReset(var Arena: TArena);
var
  I: Integer;
begin
  for I := 0 to High(Arena.Blocks) do
    Arena.Blocks[I].Used := 0;
  Arena.TotalUsed := 0;
  Arena.AllocationCount := 0;
end;

function AddBlock(var Arena: TArena; Minimum: SizeUInt): Int32;
var
  Capacity: SizeUInt;
  N: Integer;
begin
  Capacity := Arena.DefaultBlockSize;
  if Capacity < Minimum then
    Capacity := AlignUp(Minimum, FSIM_PAGE_SIZE);
  if Capacity > FSIM_ARENA_OFFSET_MASK + 1 then
    raise EOutOfMemory.Create('single arena allocation exceeds addressable block size');
  N := Length(Arena.Blocks);
  if N = High(Integer) then
    raise EOutOfMemory.Create('arena block index exhausted');
  SetLength(Arena.Blocks, N + 1);
  Arena.Blocks[N] := Default(TArenaBlock);
  GetMem(Arena.Blocks[N].Base, Capacity);
  if Arena.Blocks[N].Base = nil then
    raise EOutOfMemory.Create('cannot allocate arena block');
  Arena.Blocks[N].Capacity := Capacity;
  Arena.Blocks[N].Used := 0;
  Inc(Arena.TotalReserved, Capacity);
  Result := N;
end;

function AlignedBlockOffset(const Block: TArenaBlock;
  Alignment: SizeUInt): SizeUInt; inline;
var
  BaseAddress, CurrentAddress, AlignedAddress: QWord;
begin
  BaseAddress := QWord(PtrUInt(Block.Base));
  CurrentAddress := BaseAddress + QWord(Block.Used);
  if CurrentAddress < BaseAddress then
    raise ERangeError.Create('arena address arithmetic overflow');
  AlignedAddress := AlignUp(CurrentAddress, Alignment);
  if AlignedAddress < BaseAddress then
    raise ERangeError.Create('arena alignment arithmetic overflow');
  Result := SizeUInt(AlignedAddress - BaseAddress);
end;

function ArenaAlloc(var Arena: TArena; Size: SizeUInt; Alignment: SizeUInt): TArenaOffset;
var
  BlockIndex: Int32;
  Start, Minimum: SizeUInt;
  Block: ^TArenaBlock;
begin
  if Size = 0 then
    Size := 1;
  if (Alignment = 0) or not IsPowerOfTwo(Alignment) then
    raise ERangeError.Create('arena alignment must be a nonzero power of two');
  if Alignment > FSIM_ARENA_OFFSET_MASK + 1 then
    raise ERangeError.Create('arena alignment exceeds addressable block size');
  if Size > FSIM_ARENA_OFFSET_MASK + 1 then
    raise EOutOfMemory.Create('arena allocation exceeds addressable block size');
  if Size > High(SizeUInt) - (Alignment - 1) then
    raise EOutOfMemory.Create('arena allocation size overflow');
  Minimum := Size + Alignment - 1;
  if Length(Arena.Blocks) = 0 then
    AddBlock(Arena, Minimum);
  BlockIndex := High(Arena.Blocks);
  Block := @Arena.Blocks[BlockIndex];
  Start := AlignedBlockOffset(Block^, Alignment);
  if (Start > Block^.Capacity) or (Size > Block^.Capacity - Start) then
  begin
    BlockIndex := AddBlock(Arena, Minimum);
    Block := @Arena.Blocks[BlockIndex];
    Start := AlignedBlockOffset(Block^, Alignment);
    if (Start > Block^.Capacity) or (Size > Block^.Capacity - Start) then
      raise EOutOfMemory.Create('new arena block cannot satisfy allocation');
  end;
  Block^.Used := Start + Size;
  Inc(Arena.TotalUsed, Size);
  Inc(Arena.AllocationCount);
  Result := (QWord(BlockIndex) shl FSIM_ARENA_BLOCK_SHIFT) or QWord(Start);
end;

function ArenaAllocZero(var Arena: TArena; Size: SizeUInt; Alignment: SizeUInt): TArenaOffset;
var
  P: Pointer;
begin
  Result := ArenaAlloc(Arena, Size, Alignment);
  P := ArenaPtr(Arena, Result);
  FillChar(P^, Size, 0);
end;

function ArenaPtr(var Arena: TArena; Offset: TArenaOffset): Pointer;
var
  BlockIndex: QWord;
  InnerOffset: QWord;
begin
  BlockIndex := Offset shr FSIM_ARENA_BLOCK_SHIFT;
  InnerOffset := Offset and FSIM_ARENA_OFFSET_MASK;
  if BlockIndex >= QWord(Length(Arena.Blocks)) then
    raise ERangeError.Create('arena block index outside range');
  if InnerOffset >= Arena.Blocks[BlockIndex].Used then
    raise ERangeError.Create('arena offset is not currently allocated');
  Result := Arena.Blocks[BlockIndex].Base + InnerOffset;
end;

function ArenaConstPtr(const Arena: TArena; Offset: TArenaOffset): Pointer;
var
  BlockIndex: QWord;
  InnerOffset: QWord;
begin
  BlockIndex := Offset shr FSIM_ARENA_BLOCK_SHIFT;
  InnerOffset := Offset and FSIM_ARENA_OFFSET_MASK;
  if BlockIndex >= QWord(Length(Arena.Blocks)) then
    raise ERangeError.Create('arena block index outside range');
  if InnerOffset >= Arena.Blocks[BlockIndex].Used then
    raise ERangeError.Create('arena offset is not currently allocated');
  Result := Arena.Blocks[BlockIndex].Base + InnerOffset;
end;

function ArenaStore(var Arena: TArena; const Data; Size: SizeUInt; Alignment: SizeUInt): TArenaOffset;
var
  P: Pointer;
begin
  Result := ArenaAlloc(Arena, Size, Alignment);
  P := ArenaPtr(Arena, Result);
  if Size > 0 then
    Move(Data, P^, Size);
end;

function ArenaStoreString(var Arena: TArena; const Value: RawByteString): TArenaOffset;
var
  P: PAnsiChar;
begin
  Result := ArenaAlloc(Arena, Length(Value) + 1, 1);
  P := PAnsiChar(ArenaPtr(Arena, Result));
  if Length(Value) > 0 then
    Move(Value[1], P^, Length(Value));
  P[Length(Value)] := #0;
end;

function ArenaString(var Arena: TArena; Offset: TArenaOffset): PAnsiChar;
begin
  Result := PAnsiChar(ArenaPtr(Arena, Offset));
end;

end.

program test_arena;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

uses
  SysUtils, core, arena;

var
  TestArena: TArena;
  First, Second, Zeroed: TArenaOffset;
  P: PByte;
  I: Integer;
begin
  ArenaInit(TestArena, 1024 * 1024);
  try
    First := ArenaAlloc(TestArena, 32, 16);
    Second := ArenaAlloc(TestArena, 64, 32);
    if First = Second then Halt(1);
    P := PByte(ArenaPtr(TestArena, First));
    if P = nil then Halt(2);
    P^ := 123;
    if PByte(ArenaPtr(TestArena, First))^ <> 123 then Halt(3);
    if (PtrUInt(ArenaPtr(TestArena, First)) and 15) <> 0 then Halt(4);
    if (PtrUInt(ArenaPtr(TestArena, Second)) and 31) <> 0 then Halt(5);
    Zeroed := ArenaAllocZero(TestArena, 64, 8);
    P := PByte(ArenaPtr(TestArena, Zeroed));
    for I := 0 to 63 do
      if P[I] <> 0 then Halt(6);
    if TestArena.TotalUsed < 160 then Halt(7);
    if TestArena.AllocationCount <> 3 then Halt(8);
    ArenaReset(TestArena);
    if TestArena.TotalUsed <> 0 then Halt(9);
    if TestArena.AllocationCount <> 0 then Halt(10);
    try
      ArenaPtr(TestArena, First);
      Halt(11);
    except
      on E: ERangeError do
        ;
    end;
  finally
    ArenaDone(TestArena);
  end;
end.

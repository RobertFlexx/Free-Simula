program test_common;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

uses
  SysUtils, core;

procedure Fail(Code: Integer; const MessageText: RawByteString);
begin
  Writeln(StdErr, 'common test failed: ', MessageText);
  Halt(Code);
end;

procedure CheckHash(const Value: RawByteString; Expected: UInt32; Code: Integer);
var
  Actual: UInt32;
begin
  Actual := HashString(Value);
  if Actual <> Expected then
    Fail(Code, 'FNV-1a mismatch for ''' + Value + ''': got ' +
      IntToHex(Actual, 8) + ', expected ' + IntToHex(Expected, 8));
end;

var
  Pool: TStringPool;
  First, Duplicate, Empty: Int32;
  Buffer: TByteBuffer;
begin
  CheckHash('', UInt32($811C9DC5), 1);
  CheckHash('Integer', UInt32($D9A953E5), 2);
  CheckHash('integer', UInt32($BFD2C445), 3);
  CheckHash('fsim', UInt32($25544568), 4);
  CheckHash('_start', UInt32($9F3231DE), 5);
  CheckHash('Boolean', UInt32($EC95435F), 6);

  Pool := Default(TStringPool);
  BufferInit(Pool.Bytes, 8);
  First := StringPoolIntern(Pool, 'Integer');
  Duplicate := StringPoolIntern(Pool, 'Integer');
  Empty := StringPoolIntern(Pool, '');
  if First <> Duplicate then Fail(7, 'duplicate string was not interned');
  if StringPoolGet(Pool, First) <> 'Integer' then Fail(8, 'string retrieval failed');
  if StringPoolGet(Pool, Empty) <> '' then Fail(9, 'empty string retrieval failed');
  if StringPoolPointer(Pool, First) = nil then Fail(10, 'string pointer is nil');
  SetLength(Pool.Entries, 0);
  SetLength(Pool.Bytes.Data, 0);

  BufferInit(Buffer, 1);
  BufferAppendDWord(Buffer, DWord($89ABCDEF));
  BufferAlign(Buffer, 16, Byte($CC));
  if Buffer.Count <> 16 then Fail(11, 'buffer alignment failed');
  if (Buffer.Data[0] <> $EF) or (Buffer.Data[1] <> $CD) or
     (Buffer.Data[2] <> $AB) or (Buffer.Data[3] <> $89) then
    Fail(12, 'little-endian DWord emission failed');
  SetLength(Buffer.Data, 0);
end.

unit unicode;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

type
  TUnicodeRange = packed record
    FirstCodePoint: UInt32;
    LastCodePoint: UInt32;
  end;

  TUnicodeMapping = packed record
    SourceCodePoint: UInt32;
    TargetCodePoint: UInt32;
  end;

const
  UNICODE_IDENTIFIER_START_RANGES: array[0..663] of TUnicodeRange = (
    (
      FirstCodePoint: $00000041;
      LastCodePoint: $0000005A
    ),
    (
      FirstCodePoint: $0000005F;
      LastCodePoint: $0000005F
    ),
    (
      FirstCodePoint: $00000061;
      LastCodePoint: $0000007A
    ),
    (
      FirstCodePoint: $000000AA;
      LastCodePoint: $000000AA
    ),
    (
      FirstCodePoint: $000000B5;
      LastCodePoint: $000000B5
    ),
    (
      FirstCodePoint: $000000BA;
      LastCodePoint: $000000BA
    ),
    (
      FirstCodePoint: $000000C0;
      LastCodePoint: $000000D6
    ),
    (
      FirstCodePoint: $000000D8;
      LastCodePoint: $000000F6
    ),
    (
      FirstCodePoint: $000000F8;
      LastCodePoint: $000002C1
    ),
    (
      FirstCodePoint: $000002C6;
      LastCodePoint: $000002D1
    ),
    (
      FirstCodePoint: $000002E0;
      LastCodePoint: $000002E4
    ),
    (
      FirstCodePoint: $000002EC;
      LastCodePoint: $000002EC
    ),
    (
      FirstCodePoint: $000002EE;
      LastCodePoint: $000002EE
    ),
    (
      FirstCodePoint: $00000370;
      LastCodePoint: $00000374
    ),
    (
      FirstCodePoint: $00000376;
      LastCodePoint: $00000377
    ),
    (
      FirstCodePoint: $0000037A;
      LastCodePoint: $0000037D
    ),
    (
      FirstCodePoint: $0000037F;
      LastCodePoint: $0000037F
    ),
    (
      FirstCodePoint: $00000386;
      LastCodePoint: $00000386
    ),
    (
      FirstCodePoint: $00000388;
      LastCodePoint: $0000038A
    ),
    (
      FirstCodePoint: $0000038C;
      LastCodePoint: $0000038C
    ),
    (
      FirstCodePoint: $0000038E;
      LastCodePoint: $000003A1
    ),
    (
      FirstCodePoint: $000003A3;
      LastCodePoint: $000003F5
    ),
    (
      FirstCodePoint: $000003F7;
      LastCodePoint: $00000481
    ),
    (
      FirstCodePoint: $0000048A;
      LastCodePoint: $0000052F
    ),
    (
      FirstCodePoint: $00000531;
      LastCodePoint: $00000556
    ),
    (
      FirstCodePoint: $00000559;
      LastCodePoint: $00000559
    ),
    (
      FirstCodePoint: $00000560;
      LastCodePoint: $00000588
    ),
    (
      FirstCodePoint: $000005D0;
      LastCodePoint: $000005EA
    ),
    (
      FirstCodePoint: $000005EF;
      LastCodePoint: $000005F2
    ),
    (
      FirstCodePoint: $00000620;
      LastCodePoint: $0000064A
    ),
    (
      FirstCodePoint: $0000066E;
      LastCodePoint: $0000066F
    ),
    (
      FirstCodePoint: $00000671;
      LastCodePoint: $000006D3
    ),
    (
      FirstCodePoint: $000006D5;
      LastCodePoint: $000006D5
    ),
    (
      FirstCodePoint: $000006E5;
      LastCodePoint: $000006E6
    ),
    (
      FirstCodePoint: $000006EE;
      LastCodePoint: $000006EF
    ),
    (
      FirstCodePoint: $000006FA;
      LastCodePoint: $000006FC
    ),
    (
      FirstCodePoint: $000006FF;
      LastCodePoint: $000006FF
    ),
    (
      FirstCodePoint: $00000710;
      LastCodePoint: $00000710
    ),
    (
      FirstCodePoint: $00000712;
      LastCodePoint: $0000072F
    ),
    (
      FirstCodePoint: $0000074D;
      LastCodePoint: $000007A5
    ),
    (
      FirstCodePoint: $000007B1;
      LastCodePoint: $000007B1
    ),
    (
      FirstCodePoint: $000007CA;
      LastCodePoint: $000007EA
    ),
    (
      FirstCodePoint: $000007F4;
      LastCodePoint: $000007F5
    ),
    (
      FirstCodePoint: $000007FA;
      LastCodePoint: $000007FA
    ),
    (
      FirstCodePoint: $00000800;
      LastCodePoint: $00000815
    ),
    (
      FirstCodePoint: $0000081A;
      LastCodePoint: $0000081A
    ),
    (
      FirstCodePoint: $00000824;
      LastCodePoint: $00000824
    ),
    (
      FirstCodePoint: $00000828;
      LastCodePoint: $00000828
    ),
    (
      FirstCodePoint: $00000840;
      LastCodePoint: $00000858
    ),
    (
      FirstCodePoint: $00000860;
      LastCodePoint: $0000086A
    ),
    (
      FirstCodePoint: $00000870;
      LastCodePoint: $00000887
    ),
    (
      FirstCodePoint: $00000889;
      LastCodePoint: $0000088E
    ),
    (
      FirstCodePoint: $000008A0;
      LastCodePoint: $000008C9
    ),
    (
      FirstCodePoint: $00000904;
      LastCodePoint: $00000939
    ),
    (
      FirstCodePoint: $0000093D;
      LastCodePoint: $0000093D
    ),
    (
      FirstCodePoint: $00000950;
      LastCodePoint: $00000950
    ),
    (
      FirstCodePoint: $00000958;
      LastCodePoint: $00000961
    ),
    (
      FirstCodePoint: $00000971;
      LastCodePoint: $00000980
    ),
    (
      FirstCodePoint: $00000985;
      LastCodePoint: $0000098C
    ),
    (
      FirstCodePoint: $0000098F;
      LastCodePoint: $00000990
    ),
    (
      FirstCodePoint: $00000993;
      LastCodePoint: $000009A8
    ),
    (
      FirstCodePoint: $000009AA;
      LastCodePoint: $000009B0
    ),
    (
      FirstCodePoint: $000009B2;
      LastCodePoint: $000009B2
    ),
    (
      FirstCodePoint: $000009B6;
      LastCodePoint: $000009B9
    ),
    (
      FirstCodePoint: $000009BD;
      LastCodePoint: $000009BD
    ),
    (
      FirstCodePoint: $000009CE;
      LastCodePoint: $000009CE
    ),
    (
      FirstCodePoint: $000009DC;
      LastCodePoint: $000009DD
    ),
    (
      FirstCodePoint: $000009DF;
      LastCodePoint: $000009E1
    ),
    (
      FirstCodePoint: $000009F0;
      LastCodePoint: $000009F1
    ),
    (
      FirstCodePoint: $000009FC;
      LastCodePoint: $000009FC
    ),
    (
      FirstCodePoint: $00000A05;
      LastCodePoint: $00000A0A
    ),
    (
      FirstCodePoint: $00000A0F;
      LastCodePoint: $00000A10
    ),
    (
      FirstCodePoint: $00000A13;
      LastCodePoint: $00000A28
    ),
    (
      FirstCodePoint: $00000A2A;
      LastCodePoint: $00000A30
    ),
    (
      FirstCodePoint: $00000A32;
      LastCodePoint: $00000A33
    ),
    (
      FirstCodePoint: $00000A35;
      LastCodePoint: $00000A36
    ),
    (
      FirstCodePoint: $00000A38;
      LastCodePoint: $00000A39
    ),
    (
      FirstCodePoint: $00000A59;
      LastCodePoint: $00000A5C
    ),
    (
      FirstCodePoint: $00000A5E;
      LastCodePoint: $00000A5E
    ),
    (
      FirstCodePoint: $00000A72;
      LastCodePoint: $00000A74
    ),
    (
      FirstCodePoint: $00000A85;
      LastCodePoint: $00000A8D
    ),
    (
      FirstCodePoint: $00000A8F;
      LastCodePoint: $00000A91
    ),
    (
      FirstCodePoint: $00000A93;
      LastCodePoint: $00000AA8
    ),
    (
      FirstCodePoint: $00000AAA;
      LastCodePoint: $00000AB0
    ),
    (
      FirstCodePoint: $00000AB2;
      LastCodePoint: $00000AB3
    ),
    (
      FirstCodePoint: $00000AB5;
      LastCodePoint: $00000AB9
    ),
    (
      FirstCodePoint: $00000ABD;
      LastCodePoint: $00000ABD
    ),
    (
      FirstCodePoint: $00000AD0;
      LastCodePoint: $00000AD0
    ),
    (
      FirstCodePoint: $00000AE0;
      LastCodePoint: $00000AE1
    ),
    (
      FirstCodePoint: $00000AF9;
      LastCodePoint: $00000AF9
    ),
    (
      FirstCodePoint: $00000B05;
      LastCodePoint: $00000B0C
    ),
    (
      FirstCodePoint: $00000B0F;
      LastCodePoint: $00000B10
    ),
    (
      FirstCodePoint: $00000B13;
      LastCodePoint: $00000B28
    ),
    (
      FirstCodePoint: $00000B2A;
      LastCodePoint: $00000B30
    ),
    (
      FirstCodePoint: $00000B32;
      LastCodePoint: $00000B33
    ),
    (
      FirstCodePoint: $00000B35;
      LastCodePoint: $00000B39
    ),
    (
      FirstCodePoint: $00000B3D;
      LastCodePoint: $00000B3D
    ),
    (
      FirstCodePoint: $00000B5C;
      LastCodePoint: $00000B5D
    ),
    (
      FirstCodePoint: $00000B5F;
      LastCodePoint: $00000B61
    ),
    (
      FirstCodePoint: $00000B71;
      LastCodePoint: $00000B71
    ),
    (
      FirstCodePoint: $00000B83;
      LastCodePoint: $00000B83
    ),
    (
      FirstCodePoint: $00000B85;
      LastCodePoint: $00000B8A
    ),
    (
      FirstCodePoint: $00000B8E;
      LastCodePoint: $00000B90
    ),
    (
      FirstCodePoint: $00000B92;
      LastCodePoint: $00000B95
    ),
    (
      FirstCodePoint: $00000B99;
      LastCodePoint: $00000B9A
    ),
    (
      FirstCodePoint: $00000B9C;
      LastCodePoint: $00000B9C
    ),
    (
      FirstCodePoint: $00000B9E;
      LastCodePoint: $00000B9F
    ),
    (
      FirstCodePoint: $00000BA3;
      LastCodePoint: $00000BA4
    ),
    (
      FirstCodePoint: $00000BA8;
      LastCodePoint: $00000BAA
    ),
    (
      FirstCodePoint: $00000BAE;
      LastCodePoint: $00000BB9
    ),
    (
      FirstCodePoint: $00000BD0;
      LastCodePoint: $00000BD0
    ),
    (
      FirstCodePoint: $00000C05;
      LastCodePoint: $00000C0C
    ),
    (
      FirstCodePoint: $00000C0E;
      LastCodePoint: $00000C10
    ),
    (
      FirstCodePoint: $00000C12;
      LastCodePoint: $00000C28
    ),
    (
      FirstCodePoint: $00000C2A;
      LastCodePoint: $00000C39
    ),
    (
      FirstCodePoint: $00000C3D;
      LastCodePoint: $00000C3D
    ),
    (
      FirstCodePoint: $00000C58;
      LastCodePoint: $00000C5A
    ),
    (
      FirstCodePoint: $00000C5D;
      LastCodePoint: $00000C5D
    ),
    (
      FirstCodePoint: $00000C60;
      LastCodePoint: $00000C61
    ),
    (
      FirstCodePoint: $00000C80;
      LastCodePoint: $00000C80
    ),
    (
      FirstCodePoint: $00000C85;
      LastCodePoint: $00000C8C
    ),
    (
      FirstCodePoint: $00000C8E;
      LastCodePoint: $00000C90
    ),
    (
      FirstCodePoint: $00000C92;
      LastCodePoint: $00000CA8
    ),
    (
      FirstCodePoint: $00000CAA;
      LastCodePoint: $00000CB3
    ),
    (
      FirstCodePoint: $00000CB5;
      LastCodePoint: $00000CB9
    ),
    (
      FirstCodePoint: $00000CBD;
      LastCodePoint: $00000CBD
    ),
    (
      FirstCodePoint: $00000CDD;
      LastCodePoint: $00000CDE
    ),
    (
      FirstCodePoint: $00000CE0;
      LastCodePoint: $00000CE1
    ),
    (
      FirstCodePoint: $00000CF1;
      LastCodePoint: $00000CF2
    ),
    (
      FirstCodePoint: $00000D04;
      LastCodePoint: $00000D0C
    ),
    (
      FirstCodePoint: $00000D0E;
      LastCodePoint: $00000D10
    ),
    (
      FirstCodePoint: $00000D12;
      LastCodePoint: $00000D3A
    ),
    (
      FirstCodePoint: $00000D3D;
      LastCodePoint: $00000D3D
    ),
    (
      FirstCodePoint: $00000D4E;
      LastCodePoint: $00000D4E
    ),
    (
      FirstCodePoint: $00000D54;
      LastCodePoint: $00000D56
    ),
    (
      FirstCodePoint: $00000D5F;
      LastCodePoint: $00000D61
    ),
    (
      FirstCodePoint: $00000D7A;
      LastCodePoint: $00000D7F
    ),
    (
      FirstCodePoint: $00000D85;
      LastCodePoint: $00000D96
    ),
    (
      FirstCodePoint: $00000D9A;
      LastCodePoint: $00000DB1
    ),
    (
      FirstCodePoint: $00000DB3;
      LastCodePoint: $00000DBB
    ),
    (
      FirstCodePoint: $00000DBD;
      LastCodePoint: $00000DBD
    ),
    (
      FirstCodePoint: $00000DC0;
      LastCodePoint: $00000DC6
    ),
    (
      FirstCodePoint: $00000E01;
      LastCodePoint: $00000E30
    ),
    (
      FirstCodePoint: $00000E32;
      LastCodePoint: $00000E33
    ),
    (
      FirstCodePoint: $00000E40;
      LastCodePoint: $00000E46
    ),
    (
      FirstCodePoint: $00000E81;
      LastCodePoint: $00000E82
    ),
    (
      FirstCodePoint: $00000E84;
      LastCodePoint: $00000E84
    ),
    (
      FirstCodePoint: $00000E86;
      LastCodePoint: $00000E8A
    ),
    (
      FirstCodePoint: $00000E8C;
      LastCodePoint: $00000EA3
    ),
    (
      FirstCodePoint: $00000EA5;
      LastCodePoint: $00000EA5
    ),
    (
      FirstCodePoint: $00000EA7;
      LastCodePoint: $00000EB0
    ),
    (
      FirstCodePoint: $00000EB2;
      LastCodePoint: $00000EB3
    ),
    (
      FirstCodePoint: $00000EBD;
      LastCodePoint: $00000EBD
    ),
    (
      FirstCodePoint: $00000EC0;
      LastCodePoint: $00000EC4
    ),
    (
      FirstCodePoint: $00000EC6;
      LastCodePoint: $00000EC6
    ),
    (
      FirstCodePoint: $00000EDC;
      LastCodePoint: $00000EDF
    ),
    (
      FirstCodePoint: $00000F00;
      LastCodePoint: $00000F00
    ),
    (
      FirstCodePoint: $00000F40;
      LastCodePoint: $00000F47
    ),
    (
      FirstCodePoint: $00000F49;
      LastCodePoint: $00000F6C
    ),
    (
      FirstCodePoint: $00000F88;
      LastCodePoint: $00000F8C
    ),
    (
      FirstCodePoint: $00001000;
      LastCodePoint: $0000102A
    ),
    (
      FirstCodePoint: $0000103F;
      LastCodePoint: $0000103F
    ),
    (
      FirstCodePoint: $00001050;
      LastCodePoint: $00001055
    ),
    (
      FirstCodePoint: $0000105A;
      LastCodePoint: $0000105D
    ),
    (
      FirstCodePoint: $00001061;
      LastCodePoint: $00001061
    ),
    (
      FirstCodePoint: $00001065;
      LastCodePoint: $00001066
    ),
    (
      FirstCodePoint: $0000106E;
      LastCodePoint: $00001070
    ),
    (
      FirstCodePoint: $00001075;
      LastCodePoint: $00001081
    ),
    (
      FirstCodePoint: $0000108E;
      LastCodePoint: $0000108E
    ),
    (
      FirstCodePoint: $000010A0;
      LastCodePoint: $000010C5
    ),
    (
      FirstCodePoint: $000010C7;
      LastCodePoint: $000010C7
    ),
    (
      FirstCodePoint: $000010CD;
      LastCodePoint: $000010CD
    ),
    (
      FirstCodePoint: $000010D0;
      LastCodePoint: $000010FA
    ),
    (
      FirstCodePoint: $000010FC;
      LastCodePoint: $00001248
    ),
    (
      FirstCodePoint: $0000124A;
      LastCodePoint: $0000124D
    ),
    (
      FirstCodePoint: $00001250;
      LastCodePoint: $00001256
    ),
    (
      FirstCodePoint: $00001258;
      LastCodePoint: $00001258
    ),
    (
      FirstCodePoint: $0000125A;
      LastCodePoint: $0000125D
    ),
    (
      FirstCodePoint: $00001260;
      LastCodePoint: $00001288
    ),
    (
      FirstCodePoint: $0000128A;
      LastCodePoint: $0000128D
    ),
    (
      FirstCodePoint: $00001290;
      LastCodePoint: $000012B0
    ),
    (
      FirstCodePoint: $000012B2;
      LastCodePoint: $000012B5
    ),
    (
      FirstCodePoint: $000012B8;
      LastCodePoint: $000012BE
    ),
    (
      FirstCodePoint: $000012C0;
      LastCodePoint: $000012C0
    ),
    (
      FirstCodePoint: $000012C2;
      LastCodePoint: $000012C5
    ),
    (
      FirstCodePoint: $000012C8;
      LastCodePoint: $000012D6
    ),
    (
      FirstCodePoint: $000012D8;
      LastCodePoint: $00001310
    ),
    (
      FirstCodePoint: $00001312;
      LastCodePoint: $00001315
    ),
    (
      FirstCodePoint: $00001318;
      LastCodePoint: $0000135A
    ),
    (
      FirstCodePoint: $00001380;
      LastCodePoint: $0000138F
    ),
    (
      FirstCodePoint: $000013A0;
      LastCodePoint: $000013F5
    ),
    (
      FirstCodePoint: $000013F8;
      LastCodePoint: $000013FD
    ),
    (
      FirstCodePoint: $00001401;
      LastCodePoint: $0000166C
    ),
    (
      FirstCodePoint: $0000166F;
      LastCodePoint: $0000167F
    ),
    (
      FirstCodePoint: $00001681;
      LastCodePoint: $0000169A
    ),
    (
      FirstCodePoint: $000016A0;
      LastCodePoint: $000016EA
    ),
    (
      FirstCodePoint: $000016EE;
      LastCodePoint: $000016F8
    ),
    (
      FirstCodePoint: $00001700;
      LastCodePoint: $00001711
    ),
    (
      FirstCodePoint: $0000171F;
      LastCodePoint: $00001731
    ),
    (
      FirstCodePoint: $00001740;
      LastCodePoint: $00001751
    ),
    (
      FirstCodePoint: $00001760;
      LastCodePoint: $0000176C
    ),
    (
      FirstCodePoint: $0000176E;
      LastCodePoint: $00001770
    ),
    (
      FirstCodePoint: $00001780;
      LastCodePoint: $000017B3
    ),
    (
      FirstCodePoint: $000017D7;
      LastCodePoint: $000017D7
    ),
    (
      FirstCodePoint: $000017DC;
      LastCodePoint: $000017DC
    ),
    (
      FirstCodePoint: $00001820;
      LastCodePoint: $00001878
    ),
    (
      FirstCodePoint: $00001880;
      LastCodePoint: $00001884
    ),
    (
      FirstCodePoint: $00001887;
      LastCodePoint: $000018A8
    ),
    (
      FirstCodePoint: $000018AA;
      LastCodePoint: $000018AA
    ),
    (
      FirstCodePoint: $000018B0;
      LastCodePoint: $000018F5
    ),
    (
      FirstCodePoint: $00001900;
      LastCodePoint: $0000191E
    ),
    (
      FirstCodePoint: $00001950;
      LastCodePoint: $0000196D
    ),
    (
      FirstCodePoint: $00001970;
      LastCodePoint: $00001974
    ),
    (
      FirstCodePoint: $00001980;
      LastCodePoint: $000019AB
    ),
    (
      FirstCodePoint: $000019B0;
      LastCodePoint: $000019C9
    ),
    (
      FirstCodePoint: $00001A00;
      LastCodePoint: $00001A16
    ),
    (
      FirstCodePoint: $00001A20;
      LastCodePoint: $00001A54
    ),
    (
      FirstCodePoint: $00001AA7;
      LastCodePoint: $00001AA7
    ),
    (
      FirstCodePoint: $00001B05;
      LastCodePoint: $00001B33
    ),
    (
      FirstCodePoint: $00001B45;
      LastCodePoint: $00001B4C
    ),
    (
      FirstCodePoint: $00001B83;
      LastCodePoint: $00001BA0
    ),
    (
      FirstCodePoint: $00001BAE;
      LastCodePoint: $00001BAF
    ),
    (
      FirstCodePoint: $00001BBA;
      LastCodePoint: $00001BE5
    ),
    (
      FirstCodePoint: $00001C00;
      LastCodePoint: $00001C23
    ),
    (
      FirstCodePoint: $00001C4D;
      LastCodePoint: $00001C4F
    ),
    (
      FirstCodePoint: $00001C5A;
      LastCodePoint: $00001C7D
    ),
    (
      FirstCodePoint: $00001C80;
      LastCodePoint: $00001C88
    ),
    (
      FirstCodePoint: $00001C90;
      LastCodePoint: $00001CBA
    ),
    (
      FirstCodePoint: $00001CBD;
      LastCodePoint: $00001CBF
    ),
    (
      FirstCodePoint: $00001CE9;
      LastCodePoint: $00001CEC
    ),
    (
      FirstCodePoint: $00001CEE;
      LastCodePoint: $00001CF3
    ),
    (
      FirstCodePoint: $00001CF5;
      LastCodePoint: $00001CF6
    ),
    (
      FirstCodePoint: $00001CFA;
      LastCodePoint: $00001CFA
    ),
    (
      FirstCodePoint: $00001D00;
      LastCodePoint: $00001DBF
    ),
    (
      FirstCodePoint: $00001E00;
      LastCodePoint: $00001F15
    ),
    (
      FirstCodePoint: $00001F18;
      LastCodePoint: $00001F1D
    ),
    (
      FirstCodePoint: $00001F20;
      LastCodePoint: $00001F45
    ),
    (
      FirstCodePoint: $00001F48;
      LastCodePoint: $00001F4D
    ),
    (
      FirstCodePoint: $00001F50;
      LastCodePoint: $00001F57
    ),
    (
      FirstCodePoint: $00001F59;
      LastCodePoint: $00001F59
    ),
    (
      FirstCodePoint: $00001F5B;
      LastCodePoint: $00001F5B
    ),
    (
      FirstCodePoint: $00001F5D;
      LastCodePoint: $00001F5D
    ),
    (
      FirstCodePoint: $00001F5F;
      LastCodePoint: $00001F7D
    ),
    (
      FirstCodePoint: $00001F80;
      LastCodePoint: $00001FB4
    ),
    (
      FirstCodePoint: $00001FB6;
      LastCodePoint: $00001FBC
    ),
    (
      FirstCodePoint: $00001FBE;
      LastCodePoint: $00001FBE
    ),
    (
      FirstCodePoint: $00001FC2;
      LastCodePoint: $00001FC4
    ),
    (
      FirstCodePoint: $00001FC6;
      LastCodePoint: $00001FCC
    ),
    (
      FirstCodePoint: $00001FD0;
      LastCodePoint: $00001FD3
    ),
    (
      FirstCodePoint: $00001FD6;
      LastCodePoint: $00001FDB
    ),
    (
      FirstCodePoint: $00001FE0;
      LastCodePoint: $00001FEC
    ),
    (
      FirstCodePoint: $00001FF2;
      LastCodePoint: $00001FF4
    ),
    (
      FirstCodePoint: $00001FF6;
      LastCodePoint: $00001FFC
    ),
    (
      FirstCodePoint: $00002071;
      LastCodePoint: $00002071
    ),
    (
      FirstCodePoint: $0000207F;
      LastCodePoint: $0000207F
    ),
    (
      FirstCodePoint: $00002090;
      LastCodePoint: $0000209C
    ),
    (
      FirstCodePoint: $00002102;
      LastCodePoint: $00002102
    ),
    (
      FirstCodePoint: $00002107;
      LastCodePoint: $00002107
    ),
    (
      FirstCodePoint: $0000210A;
      LastCodePoint: $00002113
    ),
    (
      FirstCodePoint: $00002115;
      LastCodePoint: $00002115
    ),
    (
      FirstCodePoint: $00002119;
      LastCodePoint: $0000211D
    ),
    (
      FirstCodePoint: $00002124;
      LastCodePoint: $00002124
    ),
    (
      FirstCodePoint: $00002126;
      LastCodePoint: $00002126
    ),
    (
      FirstCodePoint: $00002128;
      LastCodePoint: $00002128
    ),
    (
      FirstCodePoint: $0000212A;
      LastCodePoint: $0000212D
    ),
    (
      FirstCodePoint: $0000212F;
      LastCodePoint: $00002139
    ),
    (
      FirstCodePoint: $0000213C;
      LastCodePoint: $0000213F
    ),
    (
      FirstCodePoint: $00002145;
      LastCodePoint: $00002149
    ),
    (
      FirstCodePoint: $0000214E;
      LastCodePoint: $0000214E
    ),
    (
      FirstCodePoint: $00002160;
      LastCodePoint: $00002188
    ),
    (
      FirstCodePoint: $00002C00;
      LastCodePoint: $00002CE4
    ),
    (
      FirstCodePoint: $00002CEB;
      LastCodePoint: $00002CEE
    ),
    (
      FirstCodePoint: $00002CF2;
      LastCodePoint: $00002CF3
    ),
    (
      FirstCodePoint: $00002D00;
      LastCodePoint: $00002D25
    ),
    (
      FirstCodePoint: $00002D27;
      LastCodePoint: $00002D27
    ),
    (
      FirstCodePoint: $00002D2D;
      LastCodePoint: $00002D2D
    ),
    (
      FirstCodePoint: $00002D30;
      LastCodePoint: $00002D67
    ),
    (
      FirstCodePoint: $00002D6F;
      LastCodePoint: $00002D6F
    ),
    (
      FirstCodePoint: $00002D80;
      LastCodePoint: $00002D96
    ),
    (
      FirstCodePoint: $00002DA0;
      LastCodePoint: $00002DA6
    ),
    (
      FirstCodePoint: $00002DA8;
      LastCodePoint: $00002DAE
    ),
    (
      FirstCodePoint: $00002DB0;
      LastCodePoint: $00002DB6
    ),
    (
      FirstCodePoint: $00002DB8;
      LastCodePoint: $00002DBE
    ),
    (
      FirstCodePoint: $00002DC0;
      LastCodePoint: $00002DC6
    ),
    (
      FirstCodePoint: $00002DC8;
      LastCodePoint: $00002DCE
    ),
    (
      FirstCodePoint: $00002DD0;
      LastCodePoint: $00002DD6
    ),
    (
      FirstCodePoint: $00002DD8;
      LastCodePoint: $00002DDE
    ),
    (
      FirstCodePoint: $00002E2F;
      LastCodePoint: $00002E2F
    ),
    (
      FirstCodePoint: $00003005;
      LastCodePoint: $00003007
    ),
    (
      FirstCodePoint: $00003021;
      LastCodePoint: $00003029
    ),
    (
      FirstCodePoint: $00003031;
      LastCodePoint: $00003035
    ),
    (
      FirstCodePoint: $00003038;
      LastCodePoint: $0000303C
    ),
    (
      FirstCodePoint: $00003041;
      LastCodePoint: $00003096
    ),
    (
      FirstCodePoint: $0000309D;
      LastCodePoint: $0000309F
    ),
    (
      FirstCodePoint: $000030A1;
      LastCodePoint: $000030FA
    ),
    (
      FirstCodePoint: $000030FC;
      LastCodePoint: $000030FF
    ),
    (
      FirstCodePoint: $00003105;
      LastCodePoint: $0000312F
    ),
    (
      FirstCodePoint: $00003131;
      LastCodePoint: $0000318E
    ),
    (
      FirstCodePoint: $000031A0;
      LastCodePoint: $000031BF
    ),
    (
      FirstCodePoint: $000031F0;
      LastCodePoint: $000031FF
    ),
    (
      FirstCodePoint: $00003400;
      LastCodePoint: $00004DBF
    ),
    (
      FirstCodePoint: $00004E00;
      LastCodePoint: $0000A48C
    ),
    (
      FirstCodePoint: $0000A4D0;
      LastCodePoint: $0000A4FD
    ),
    (
      FirstCodePoint: $0000A500;
      LastCodePoint: $0000A60C
    ),
    (
      FirstCodePoint: $0000A610;
      LastCodePoint: $0000A61F
    ),
    (
      FirstCodePoint: $0000A62A;
      LastCodePoint: $0000A62B
    ),
    (
      FirstCodePoint: $0000A640;
      LastCodePoint: $0000A66E
    ),
    (
      FirstCodePoint: $0000A67F;
      LastCodePoint: $0000A69D
    ),
    (
      FirstCodePoint: $0000A6A0;
      LastCodePoint: $0000A6EF
    ),
    (
      FirstCodePoint: $0000A717;
      LastCodePoint: $0000A71F
    ),
    (
      FirstCodePoint: $0000A722;
      LastCodePoint: $0000A788
    ),
    (
      FirstCodePoint: $0000A78B;
      LastCodePoint: $0000A7CA
    ),
    (
      FirstCodePoint: $0000A7D0;
      LastCodePoint: $0000A7D1
    ),
    (
      FirstCodePoint: $0000A7D3;
      LastCodePoint: $0000A7D3
    ),
    (
      FirstCodePoint: $0000A7D5;
      LastCodePoint: $0000A7D9
    ),
    (
      FirstCodePoint: $0000A7F2;
      LastCodePoint: $0000A801
    ),
    (
      FirstCodePoint: $0000A803;
      LastCodePoint: $0000A805
    ),
    (
      FirstCodePoint: $0000A807;
      LastCodePoint: $0000A80A
    ),
    (
      FirstCodePoint: $0000A80C;
      LastCodePoint: $0000A822
    ),
    (
      FirstCodePoint: $0000A840;
      LastCodePoint: $0000A873
    ),
    (
      FirstCodePoint: $0000A882;
      LastCodePoint: $0000A8B3
    ),
    (
      FirstCodePoint: $0000A8F2;
      LastCodePoint: $0000A8F7
    ),
    (
      FirstCodePoint: $0000A8FB;
      LastCodePoint: $0000A8FB
    ),
    (
      FirstCodePoint: $0000A8FD;
      LastCodePoint: $0000A8FE
    ),
    (
      FirstCodePoint: $0000A90A;
      LastCodePoint: $0000A925
    ),
    (
      FirstCodePoint: $0000A930;
      LastCodePoint: $0000A946
    ),
    (
      FirstCodePoint: $0000A960;
      LastCodePoint: $0000A97C
    ),
    (
      FirstCodePoint: $0000A984;
      LastCodePoint: $0000A9B2
    ),
    (
      FirstCodePoint: $0000A9CF;
      LastCodePoint: $0000A9CF
    ),
    (
      FirstCodePoint: $0000A9E0;
      LastCodePoint: $0000A9E4
    ),
    (
      FirstCodePoint: $0000A9E6;
      LastCodePoint: $0000A9EF
    ),
    (
      FirstCodePoint: $0000A9FA;
      LastCodePoint: $0000A9FE
    ),
    (
      FirstCodePoint: $0000AA00;
      LastCodePoint: $0000AA28
    ),
    (
      FirstCodePoint: $0000AA40;
      LastCodePoint: $0000AA42
    ),
    (
      FirstCodePoint: $0000AA44;
      LastCodePoint: $0000AA4B
    ),
    (
      FirstCodePoint: $0000AA60;
      LastCodePoint: $0000AA76
    ),
    (
      FirstCodePoint: $0000AA7A;
      LastCodePoint: $0000AA7A
    ),
    (
      FirstCodePoint: $0000AA7E;
      LastCodePoint: $0000AAAF
    ),
    (
      FirstCodePoint: $0000AAB1;
      LastCodePoint: $0000AAB1
    ),
    (
      FirstCodePoint: $0000AAB5;
      LastCodePoint: $0000AAB6
    ),
    (
      FirstCodePoint: $0000AAB9;
      LastCodePoint: $0000AABD
    ),
    (
      FirstCodePoint: $0000AAC0;
      LastCodePoint: $0000AAC0
    ),
    (
      FirstCodePoint: $0000AAC2;
      LastCodePoint: $0000AAC2
    ),
    (
      FirstCodePoint: $0000AADB;
      LastCodePoint: $0000AADD
    ),
    (
      FirstCodePoint: $0000AAE0;
      LastCodePoint: $0000AAEA
    ),
    (
      FirstCodePoint: $0000AAF2;
      LastCodePoint: $0000AAF4
    ),
    (
      FirstCodePoint: $0000AB01;
      LastCodePoint: $0000AB06
    ),
    (
      FirstCodePoint: $0000AB09;
      LastCodePoint: $0000AB0E
    ),
    (
      FirstCodePoint: $0000AB11;
      LastCodePoint: $0000AB16
    ),
    (
      FirstCodePoint: $0000AB20;
      LastCodePoint: $0000AB26
    ),
    (
      FirstCodePoint: $0000AB28;
      LastCodePoint: $0000AB2E
    ),
    (
      FirstCodePoint: $0000AB30;
      LastCodePoint: $0000AB5A
    ),
    (
      FirstCodePoint: $0000AB5C;
      LastCodePoint: $0000AB69
    ),
    (
      FirstCodePoint: $0000AB70;
      LastCodePoint: $0000ABE2
    ),
    (
      FirstCodePoint: $0000AC00;
      LastCodePoint: $0000D7A3
    ),
    (
      FirstCodePoint: $0000D7B0;
      LastCodePoint: $0000D7C6
    ),
    (
      FirstCodePoint: $0000D7CB;
      LastCodePoint: $0000D7FB
    ),
    (
      FirstCodePoint: $0000F900;
      LastCodePoint: $0000FA6D
    ),
    (
      FirstCodePoint: $0000FA70;
      LastCodePoint: $0000FAD9
    ),
    (
      FirstCodePoint: $0000FB00;
      LastCodePoint: $0000FB06
    ),
    (
      FirstCodePoint: $0000FB13;
      LastCodePoint: $0000FB17
    ),
    (
      FirstCodePoint: $0000FB1D;
      LastCodePoint: $0000FB1D
    ),
    (
      FirstCodePoint: $0000FB1F;
      LastCodePoint: $0000FB28
    ),
    (
      FirstCodePoint: $0000FB2A;
      LastCodePoint: $0000FB36
    ),
    (
      FirstCodePoint: $0000FB38;
      LastCodePoint: $0000FB3C
    ),
    (
      FirstCodePoint: $0000FB3E;
      LastCodePoint: $0000FB3E
    ),
    (
      FirstCodePoint: $0000FB40;
      LastCodePoint: $0000FB41
    ),
    (
      FirstCodePoint: $0000FB43;
      LastCodePoint: $0000FB44
    ),
    (
      FirstCodePoint: $0000FB46;
      LastCodePoint: $0000FBB1
    ),
    (
      FirstCodePoint: $0000FBD3;
      LastCodePoint: $0000FD3D
    ),
    (
      FirstCodePoint: $0000FD50;
      LastCodePoint: $0000FD8F
    ),
    (
      FirstCodePoint: $0000FD92;
      LastCodePoint: $0000FDC7
    ),
    (
      FirstCodePoint: $0000FDF0;
      LastCodePoint: $0000FDFB
    ),
    (
      FirstCodePoint: $0000FE70;
      LastCodePoint: $0000FE74
    ),
    (
      FirstCodePoint: $0000FE76;
      LastCodePoint: $0000FEFC
    ),
    (
      FirstCodePoint: $0000FF21;
      LastCodePoint: $0000FF3A
    ),
    (
      FirstCodePoint: $0000FF41;
      LastCodePoint: $0000FF5A
    ),
    (
      FirstCodePoint: $0000FF66;
      LastCodePoint: $0000FFBE
    ),
    (
      FirstCodePoint: $0000FFC2;
      LastCodePoint: $0000FFC7
    ),
    (
      FirstCodePoint: $0000FFCA;
      LastCodePoint: $0000FFCF
    ),
    (
      FirstCodePoint: $0000FFD2;
      LastCodePoint: $0000FFD7
    ),
    (
      FirstCodePoint: $0000FFDA;
      LastCodePoint: $0000FFDC
    ),
    (
      FirstCodePoint: $00010000;
      LastCodePoint: $0001000B
    ),
    (
      FirstCodePoint: $0001000D;
      LastCodePoint: $00010026
    ),
    (
      FirstCodePoint: $00010028;
      LastCodePoint: $0001003A
    ),
    (
      FirstCodePoint: $0001003C;
      LastCodePoint: $0001003D
    ),
    (
      FirstCodePoint: $0001003F;
      LastCodePoint: $0001004D
    ),
    (
      FirstCodePoint: $00010050;
      LastCodePoint: $0001005D
    ),
    (
      FirstCodePoint: $00010080;
      LastCodePoint: $000100FA
    ),
    (
      FirstCodePoint: $00010140;
      LastCodePoint: $00010174
    ),
    (
      FirstCodePoint: $00010280;
      LastCodePoint: $0001029C
    ),
    (
      FirstCodePoint: $000102A0;
      LastCodePoint: $000102D0
    ),
    (
      FirstCodePoint: $00010300;
      LastCodePoint: $0001031F
    ),
    (
      FirstCodePoint: $0001032D;
      LastCodePoint: $0001034A
    ),
    (
      FirstCodePoint: $00010350;
      LastCodePoint: $00010375
    ),
    (
      FirstCodePoint: $00010380;
      LastCodePoint: $0001039D
    ),
    (
      FirstCodePoint: $000103A0;
      LastCodePoint: $000103C3
    ),
    (
      FirstCodePoint: $000103C8;
      LastCodePoint: $000103CF
    ),
    (
      FirstCodePoint: $000103D1;
      LastCodePoint: $000103D5
    ),
    (
      FirstCodePoint: $00010400;
      LastCodePoint: $0001049D
    ),
    (
      FirstCodePoint: $000104B0;
      LastCodePoint: $000104D3
    ),
    (
      FirstCodePoint: $000104D8;
      LastCodePoint: $000104FB
    ),
    (
      FirstCodePoint: $00010500;
      LastCodePoint: $00010527
    ),
    (
      FirstCodePoint: $00010530;
      LastCodePoint: $00010563
    ),
    (
      FirstCodePoint: $00010570;
      LastCodePoint: $0001057A
    ),
    (
      FirstCodePoint: $0001057C;
      LastCodePoint: $0001058A
    ),
    (
      FirstCodePoint: $0001058C;
      LastCodePoint: $00010592
    ),
    (
      FirstCodePoint: $00010594;
      LastCodePoint: $00010595
    ),
    (
      FirstCodePoint: $00010597;
      LastCodePoint: $000105A1
    ),
    (
      FirstCodePoint: $000105A3;
      LastCodePoint: $000105B1
    ),
    (
      FirstCodePoint: $000105B3;
      LastCodePoint: $000105B9
    ),
    (
      FirstCodePoint: $000105BB;
      LastCodePoint: $000105BC
    ),
    (
      FirstCodePoint: $00010600;
      LastCodePoint: $00010736
    ),
    (
      FirstCodePoint: $00010740;
      LastCodePoint: $00010755
    ),
    (
      FirstCodePoint: $00010760;
      LastCodePoint: $00010767
    ),
    (
      FirstCodePoint: $00010780;
      LastCodePoint: $00010785
    ),
    (
      FirstCodePoint: $00010787;
      LastCodePoint: $000107B0
    ),
    (
      FirstCodePoint: $000107B2;
      LastCodePoint: $000107BA
    ),
    (
      FirstCodePoint: $00010800;
      LastCodePoint: $00010805
    ),
    (
      FirstCodePoint: $00010808;
      LastCodePoint: $00010808
    ),
    (
      FirstCodePoint: $0001080A;
      LastCodePoint: $00010835
    ),
    (
      FirstCodePoint: $00010837;
      LastCodePoint: $00010838
    ),
    (
      FirstCodePoint: $0001083C;
      LastCodePoint: $0001083C
    ),
    (
      FirstCodePoint: $0001083F;
      LastCodePoint: $00010855
    ),
    (
      FirstCodePoint: $00010860;
      LastCodePoint: $00010876
    ),
    (
      FirstCodePoint: $00010880;
      LastCodePoint: $0001089E
    ),
    (
      FirstCodePoint: $000108E0;
      LastCodePoint: $000108F2
    ),
    (
      FirstCodePoint: $000108F4;
      LastCodePoint: $000108F5
    ),
    (
      FirstCodePoint: $00010900;
      LastCodePoint: $00010915
    ),
    (
      FirstCodePoint: $00010920;
      LastCodePoint: $00010939
    ),
    (
      FirstCodePoint: $00010980;
      LastCodePoint: $000109B7
    ),
    (
      FirstCodePoint: $000109BE;
      LastCodePoint: $000109BF
    ),
    (
      FirstCodePoint: $00010A00;
      LastCodePoint: $00010A00
    ),
    (
      FirstCodePoint: $00010A10;
      LastCodePoint: $00010A13
    ),
    (
      FirstCodePoint: $00010A15;
      LastCodePoint: $00010A17
    ),
    (
      FirstCodePoint: $00010A19;
      LastCodePoint: $00010A35
    ),
    (
      FirstCodePoint: $00010A60;
      LastCodePoint: $00010A7C
    ),
    (
      FirstCodePoint: $00010A80;
      LastCodePoint: $00010A9C
    ),
    (
      FirstCodePoint: $00010AC0;
      LastCodePoint: $00010AC7
    ),
    (
      FirstCodePoint: $00010AC9;
      LastCodePoint: $00010AE4
    ),
    (
      FirstCodePoint: $00010B00;
      LastCodePoint: $00010B35
    ),
    (
      FirstCodePoint: $00010B40;
      LastCodePoint: $00010B55
    ),
    (
      FirstCodePoint: $00010B60;
      LastCodePoint: $00010B72
    ),
    (
      FirstCodePoint: $00010B80;
      LastCodePoint: $00010B91
    ),
    (
      FirstCodePoint: $00010C00;
      LastCodePoint: $00010C48
    ),
    (
      FirstCodePoint: $00010C80;
      LastCodePoint: $00010CB2
    ),
    (
      FirstCodePoint: $00010CC0;
      LastCodePoint: $00010CF2
    ),
    (
      FirstCodePoint: $00010D00;
      LastCodePoint: $00010D23
    ),
    (
      FirstCodePoint: $00010E80;
      LastCodePoint: $00010EA9
    ),
    (
      FirstCodePoint: $00010EB0;
      LastCodePoint: $00010EB1
    ),
    (
      FirstCodePoint: $00010F00;
      LastCodePoint: $00010F1C
    ),
    (
      FirstCodePoint: $00010F27;
      LastCodePoint: $00010F27
    ),
    (
      FirstCodePoint: $00010F30;
      LastCodePoint: $00010F45
    ),
    (
      FirstCodePoint: $00010F70;
      LastCodePoint: $00010F81
    ),
    (
      FirstCodePoint: $00010FB0;
      LastCodePoint: $00010FC4
    ),
    (
      FirstCodePoint: $00010FE0;
      LastCodePoint: $00010FF6
    ),
    (
      FirstCodePoint: $00011003;
      LastCodePoint: $00011037
    ),
    (
      FirstCodePoint: $00011071;
      LastCodePoint: $00011072
    ),
    (
      FirstCodePoint: $00011075;
      LastCodePoint: $00011075
    ),
    (
      FirstCodePoint: $00011083;
      LastCodePoint: $000110AF
    ),
    (
      FirstCodePoint: $000110D0;
      LastCodePoint: $000110E8
    ),
    (
      FirstCodePoint: $00011103;
      LastCodePoint: $00011126
    ),
    (
      FirstCodePoint: $00011144;
      LastCodePoint: $00011144
    ),
    (
      FirstCodePoint: $00011147;
      LastCodePoint: $00011147
    ),
    (
      FirstCodePoint: $00011150;
      LastCodePoint: $00011172
    ),
    (
      FirstCodePoint: $00011176;
      LastCodePoint: $00011176
    ),
    (
      FirstCodePoint: $00011183;
      LastCodePoint: $000111B2
    ),
    (
      FirstCodePoint: $000111C1;
      LastCodePoint: $000111C4
    ),
    (
      FirstCodePoint: $000111DA;
      LastCodePoint: $000111DA
    ),
    (
      FirstCodePoint: $000111DC;
      LastCodePoint: $000111DC
    ),
    (
      FirstCodePoint: $00011200;
      LastCodePoint: $00011211
    ),
    (
      FirstCodePoint: $00011213;
      LastCodePoint: $0001122B
    ),
    (
      FirstCodePoint: $0001123F;
      LastCodePoint: $00011240
    ),
    (
      FirstCodePoint: $00011280;
      LastCodePoint: $00011286
    ),
    (
      FirstCodePoint: $00011288;
      LastCodePoint: $00011288
    ),
    (
      FirstCodePoint: $0001128A;
      LastCodePoint: $0001128D
    ),
    (
      FirstCodePoint: $0001128F;
      LastCodePoint: $0001129D
    ),
    (
      FirstCodePoint: $0001129F;
      LastCodePoint: $000112A8
    ),
    (
      FirstCodePoint: $000112B0;
      LastCodePoint: $000112DE
    ),
    (
      FirstCodePoint: $00011305;
      LastCodePoint: $0001130C
    ),
    (
      FirstCodePoint: $0001130F;
      LastCodePoint: $00011310
    ),
    (
      FirstCodePoint: $00011313;
      LastCodePoint: $00011328
    ),
    (
      FirstCodePoint: $0001132A;
      LastCodePoint: $00011330
    ),
    (
      FirstCodePoint: $00011332;
      LastCodePoint: $00011333
    ),
    (
      FirstCodePoint: $00011335;
      LastCodePoint: $00011339
    ),
    (
      FirstCodePoint: $0001133D;
      LastCodePoint: $0001133D
    ),
    (
      FirstCodePoint: $00011350;
      LastCodePoint: $00011350
    ),
    (
      FirstCodePoint: $0001135D;
      LastCodePoint: $00011361
    ),
    (
      FirstCodePoint: $00011400;
      LastCodePoint: $00011434
    ),
    (
      FirstCodePoint: $00011447;
      LastCodePoint: $0001144A
    ),
    (
      FirstCodePoint: $0001145F;
      LastCodePoint: $00011461
    ),
    (
      FirstCodePoint: $00011480;
      LastCodePoint: $000114AF
    ),
    (
      FirstCodePoint: $000114C4;
      LastCodePoint: $000114C5
    ),
    (
      FirstCodePoint: $000114C7;
      LastCodePoint: $000114C7
    ),
    (
      FirstCodePoint: $00011580;
      LastCodePoint: $000115AE
    ),
    (
      FirstCodePoint: $000115D8;
      LastCodePoint: $000115DB
    ),
    (
      FirstCodePoint: $00011600;
      LastCodePoint: $0001162F
    ),
    (
      FirstCodePoint: $00011644;
      LastCodePoint: $00011644
    ),
    (
      FirstCodePoint: $00011680;
      LastCodePoint: $000116AA
    ),
    (
      FirstCodePoint: $000116B8;
      LastCodePoint: $000116B8
    ),
    (
      FirstCodePoint: $00011700;
      LastCodePoint: $0001171A
    ),
    (
      FirstCodePoint: $00011740;
      LastCodePoint: $00011746
    ),
    (
      FirstCodePoint: $00011800;
      LastCodePoint: $0001182B
    ),
    (
      FirstCodePoint: $000118A0;
      LastCodePoint: $000118DF
    ),
    (
      FirstCodePoint: $000118FF;
      LastCodePoint: $00011906
    ),
    (
      FirstCodePoint: $00011909;
      LastCodePoint: $00011909
    ),
    (
      FirstCodePoint: $0001190C;
      LastCodePoint: $00011913
    ),
    (
      FirstCodePoint: $00011915;
      LastCodePoint: $00011916
    ),
    (
      FirstCodePoint: $00011918;
      LastCodePoint: $0001192F
    ),
    (
      FirstCodePoint: $0001193F;
      LastCodePoint: $0001193F
    ),
    (
      FirstCodePoint: $00011941;
      LastCodePoint: $00011941
    ),
    (
      FirstCodePoint: $000119A0;
      LastCodePoint: $000119A7
    ),
    (
      FirstCodePoint: $000119AA;
      LastCodePoint: $000119D0
    ),
    (
      FirstCodePoint: $000119E1;
      LastCodePoint: $000119E1
    ),
    (
      FirstCodePoint: $000119E3;
      LastCodePoint: $000119E3
    ),
    (
      FirstCodePoint: $00011A00;
      LastCodePoint: $00011A00
    ),
    (
      FirstCodePoint: $00011A0B;
      LastCodePoint: $00011A32
    ),
    (
      FirstCodePoint: $00011A3A;
      LastCodePoint: $00011A3A
    ),
    (
      FirstCodePoint: $00011A50;
      LastCodePoint: $00011A50
    ),
    (
      FirstCodePoint: $00011A5C;
      LastCodePoint: $00011A89
    ),
    (
      FirstCodePoint: $00011A9D;
      LastCodePoint: $00011A9D
    ),
    (
      FirstCodePoint: $00011AB0;
      LastCodePoint: $00011AF8
    ),
    (
      FirstCodePoint: $00011C00;
      LastCodePoint: $00011C08
    ),
    (
      FirstCodePoint: $00011C0A;
      LastCodePoint: $00011C2E
    ),
    (
      FirstCodePoint: $00011C40;
      LastCodePoint: $00011C40
    ),
    (
      FirstCodePoint: $00011C72;
      LastCodePoint: $00011C8F
    ),
    (
      FirstCodePoint: $00011D00;
      LastCodePoint: $00011D06
    ),
    (
      FirstCodePoint: $00011D08;
      LastCodePoint: $00011D09
    ),
    (
      FirstCodePoint: $00011D0B;
      LastCodePoint: $00011D30
    ),
    (
      FirstCodePoint: $00011D46;
      LastCodePoint: $00011D46
    ),
    (
      FirstCodePoint: $00011D60;
      LastCodePoint: $00011D65
    ),
    (
      FirstCodePoint: $00011D67;
      LastCodePoint: $00011D68
    ),
    (
      FirstCodePoint: $00011D6A;
      LastCodePoint: $00011D89
    ),
    (
      FirstCodePoint: $00011D98;
      LastCodePoint: $00011D98
    ),
    (
      FirstCodePoint: $00011EE0;
      LastCodePoint: $00011EF2
    ),
    (
      FirstCodePoint: $00011F02;
      LastCodePoint: $00011F02
    ),
    (
      FirstCodePoint: $00011F04;
      LastCodePoint: $00011F10
    ),
    (
      FirstCodePoint: $00011F12;
      LastCodePoint: $00011F33
    ),
    (
      FirstCodePoint: $00011FB0;
      LastCodePoint: $00011FB0
    ),
    (
      FirstCodePoint: $00012000;
      LastCodePoint: $00012399
    ),
    (
      FirstCodePoint: $00012400;
      LastCodePoint: $0001246E
    ),
    (
      FirstCodePoint: $00012480;
      LastCodePoint: $00012543
    ),
    (
      FirstCodePoint: $00012F90;
      LastCodePoint: $00012FF0
    ),
    (
      FirstCodePoint: $00013000;
      LastCodePoint: $0001342F
    ),
    (
      FirstCodePoint: $00013441;
      LastCodePoint: $00013446
    ),
    (
      FirstCodePoint: $00014400;
      LastCodePoint: $00014646
    ),
    (
      FirstCodePoint: $00016800;
      LastCodePoint: $00016A38
    ),
    (
      FirstCodePoint: $00016A40;
      LastCodePoint: $00016A5E
    ),
    (
      FirstCodePoint: $00016A70;
      LastCodePoint: $00016ABE
    ),
    (
      FirstCodePoint: $00016AD0;
      LastCodePoint: $00016AED
    ),
    (
      FirstCodePoint: $00016B00;
      LastCodePoint: $00016B2F
    ),
    (
      FirstCodePoint: $00016B40;
      LastCodePoint: $00016B43
    ),
    (
      FirstCodePoint: $00016B63;
      LastCodePoint: $00016B77
    ),
    (
      FirstCodePoint: $00016B7D;
      LastCodePoint: $00016B8F
    ),
    (
      FirstCodePoint: $00016E40;
      LastCodePoint: $00016E7F
    ),
    (
      FirstCodePoint: $00016F00;
      LastCodePoint: $00016F4A
    ),
    (
      FirstCodePoint: $00016F50;
      LastCodePoint: $00016F50
    ),
    (
      FirstCodePoint: $00016F93;
      LastCodePoint: $00016F9F
    ),
    (
      FirstCodePoint: $00016FE0;
      LastCodePoint: $00016FE1
    ),
    (
      FirstCodePoint: $00016FE3;
      LastCodePoint: $00016FE3
    ),
    (
      FirstCodePoint: $00017000;
      LastCodePoint: $000187F7
    ),
    (
      FirstCodePoint: $00018800;
      LastCodePoint: $00018CD5
    ),
    (
      FirstCodePoint: $00018D00;
      LastCodePoint: $00018D08
    ),
    (
      FirstCodePoint: $0001AFF0;
      LastCodePoint: $0001AFF3
    ),
    (
      FirstCodePoint: $0001AFF5;
      LastCodePoint: $0001AFFB
    ),
    (
      FirstCodePoint: $0001AFFD;
      LastCodePoint: $0001AFFE
    ),
    (
      FirstCodePoint: $0001B000;
      LastCodePoint: $0001B122
    ),
    (
      FirstCodePoint: $0001B132;
      LastCodePoint: $0001B132
    ),
    (
      FirstCodePoint: $0001B150;
      LastCodePoint: $0001B152
    ),
    (
      FirstCodePoint: $0001B155;
      LastCodePoint: $0001B155
    ),
    (
      FirstCodePoint: $0001B164;
      LastCodePoint: $0001B167
    ),
    (
      FirstCodePoint: $0001B170;
      LastCodePoint: $0001B2FB
    ),
    (
      FirstCodePoint: $0001BC00;
      LastCodePoint: $0001BC6A
    ),
    (
      FirstCodePoint: $0001BC70;
      LastCodePoint: $0001BC7C
    ),
    (
      FirstCodePoint: $0001BC80;
      LastCodePoint: $0001BC88
    ),
    (
      FirstCodePoint: $0001BC90;
      LastCodePoint: $0001BC99
    ),
    (
      FirstCodePoint: $0001D400;
      LastCodePoint: $0001D454
    ),
    (
      FirstCodePoint: $0001D456;
      LastCodePoint: $0001D49C
    ),
    (
      FirstCodePoint: $0001D49E;
      LastCodePoint: $0001D49F
    ),
    (
      FirstCodePoint: $0001D4A2;
      LastCodePoint: $0001D4A2
    ),
    (
      FirstCodePoint: $0001D4A5;
      LastCodePoint: $0001D4A6
    ),
    (
      FirstCodePoint: $0001D4A9;
      LastCodePoint: $0001D4AC
    ),
    (
      FirstCodePoint: $0001D4AE;
      LastCodePoint: $0001D4B9
    ),
    (
      FirstCodePoint: $0001D4BB;
      LastCodePoint: $0001D4BB
    ),
    (
      FirstCodePoint: $0001D4BD;
      LastCodePoint: $0001D4C3
    ),
    (
      FirstCodePoint: $0001D4C5;
      LastCodePoint: $0001D505
    ),
    (
      FirstCodePoint: $0001D507;
      LastCodePoint: $0001D50A
    ),
    (
      FirstCodePoint: $0001D50D;
      LastCodePoint: $0001D514
    ),
    (
      FirstCodePoint: $0001D516;
      LastCodePoint: $0001D51C
    ),
    (
      FirstCodePoint: $0001D51E;
      LastCodePoint: $0001D539
    ),
    (
      FirstCodePoint: $0001D53B;
      LastCodePoint: $0001D53E
    ),
    (
      FirstCodePoint: $0001D540;
      LastCodePoint: $0001D544
    ),
    (
      FirstCodePoint: $0001D546;
      LastCodePoint: $0001D546
    ),
    (
      FirstCodePoint: $0001D54A;
      LastCodePoint: $0001D550
    ),
    (
      FirstCodePoint: $0001D552;
      LastCodePoint: $0001D6A5
    ),
    (
      FirstCodePoint: $0001D6A8;
      LastCodePoint: $0001D6C0
    ),
    (
      FirstCodePoint: $0001D6C2;
      LastCodePoint: $0001D6DA
    ),
    (
      FirstCodePoint: $0001D6DC;
      LastCodePoint: $0001D6FA
    ),
    (
      FirstCodePoint: $0001D6FC;
      LastCodePoint: $0001D714
    ),
    (
      FirstCodePoint: $0001D716;
      LastCodePoint: $0001D734
    ),
    (
      FirstCodePoint: $0001D736;
      LastCodePoint: $0001D74E
    ),
    (
      FirstCodePoint: $0001D750;
      LastCodePoint: $0001D76E
    ),
    (
      FirstCodePoint: $0001D770;
      LastCodePoint: $0001D788
    ),
    (
      FirstCodePoint: $0001D78A;
      LastCodePoint: $0001D7A8
    ),
    (
      FirstCodePoint: $0001D7AA;
      LastCodePoint: $0001D7C2
    ),
    (
      FirstCodePoint: $0001D7C4;
      LastCodePoint: $0001D7CB
    ),
    (
      FirstCodePoint: $0001DF00;
      LastCodePoint: $0001DF1E
    ),
    (
      FirstCodePoint: $0001DF25;
      LastCodePoint: $0001DF2A
    ),
    (
      FirstCodePoint: $0001E030;
      LastCodePoint: $0001E06D
    ),
    (
      FirstCodePoint: $0001E100;
      LastCodePoint: $0001E12C
    ),
    (
      FirstCodePoint: $0001E137;
      LastCodePoint: $0001E13D
    ),
    (
      FirstCodePoint: $0001E14E;
      LastCodePoint: $0001E14E
    ),
    (
      FirstCodePoint: $0001E290;
      LastCodePoint: $0001E2AD
    ),
    (
      FirstCodePoint: $0001E2C0;
      LastCodePoint: $0001E2EB
    ),
    (
      FirstCodePoint: $0001E4D0;
      LastCodePoint: $0001E4EB
    ),
    (
      FirstCodePoint: $0001E7E0;
      LastCodePoint: $0001E7E6
    ),
    (
      FirstCodePoint: $0001E7E8;
      LastCodePoint: $0001E7EB
    ),
    (
      FirstCodePoint: $0001E7ED;
      LastCodePoint: $0001E7EE
    ),
    (
      FirstCodePoint: $0001E7F0;
      LastCodePoint: $0001E7FE
    ),
    (
      FirstCodePoint: $0001E800;
      LastCodePoint: $0001E8C4
    ),
    (
      FirstCodePoint: $0001E900;
      LastCodePoint: $0001E943
    ),
    (
      FirstCodePoint: $0001E94B;
      LastCodePoint: $0001E94B
    ),
    (
      FirstCodePoint: $0001EE00;
      LastCodePoint: $0001EE03
    ),
    (
      FirstCodePoint: $0001EE05;
      LastCodePoint: $0001EE1F
    ),
    (
      FirstCodePoint: $0001EE21;
      LastCodePoint: $0001EE22
    ),
    (
      FirstCodePoint: $0001EE24;
      LastCodePoint: $0001EE24
    ),
    (
      FirstCodePoint: $0001EE27;
      LastCodePoint: $0001EE27
    ),
    (
      FirstCodePoint: $0001EE29;
      LastCodePoint: $0001EE32
    ),
    (
      FirstCodePoint: $0001EE34;
      LastCodePoint: $0001EE37
    ),
    (
      FirstCodePoint: $0001EE39;
      LastCodePoint: $0001EE39
    ),
    (
      FirstCodePoint: $0001EE3B;
      LastCodePoint: $0001EE3B
    ),
    (
      FirstCodePoint: $0001EE42;
      LastCodePoint: $0001EE42
    ),
    (
      FirstCodePoint: $0001EE47;
      LastCodePoint: $0001EE47
    ),
    (
      FirstCodePoint: $0001EE49;
      LastCodePoint: $0001EE49
    ),
    (
      FirstCodePoint: $0001EE4B;
      LastCodePoint: $0001EE4B
    ),
    (
      FirstCodePoint: $0001EE4D;
      LastCodePoint: $0001EE4F
    ),
    (
      FirstCodePoint: $0001EE51;
      LastCodePoint: $0001EE52
    ),
    (
      FirstCodePoint: $0001EE54;
      LastCodePoint: $0001EE54
    ),
    (
      FirstCodePoint: $0001EE57;
      LastCodePoint: $0001EE57
    ),
    (
      FirstCodePoint: $0001EE59;
      LastCodePoint: $0001EE59
    ),
    (
      FirstCodePoint: $0001EE5B;
      LastCodePoint: $0001EE5B
    ),
    (
      FirstCodePoint: $0001EE5D;
      LastCodePoint: $0001EE5D
    ),
    (
      FirstCodePoint: $0001EE5F;
      LastCodePoint: $0001EE5F
    ),
    (
      FirstCodePoint: $0001EE61;
      LastCodePoint: $0001EE62
    ),
    (
      FirstCodePoint: $0001EE64;
      LastCodePoint: $0001EE64
    ),
    (
      FirstCodePoint: $0001EE67;
      LastCodePoint: $0001EE6A
    ),
    (
      FirstCodePoint: $0001EE6C;
      LastCodePoint: $0001EE72
    ),
    (
      FirstCodePoint: $0001EE74;
      LastCodePoint: $0001EE77
    ),
    (
      FirstCodePoint: $0001EE79;
      LastCodePoint: $0001EE7C
    ),
    (
      FirstCodePoint: $0001EE7E;
      LastCodePoint: $0001EE7E
    ),
    (
      FirstCodePoint: $0001EE80;
      LastCodePoint: $0001EE89
    ),
    (
      FirstCodePoint: $0001EE8B;
      LastCodePoint: $0001EE9B
    ),
    (
      FirstCodePoint: $0001EEA1;
      LastCodePoint: $0001EEA3
    ),
    (
      FirstCodePoint: $0001EEA5;
      LastCodePoint: $0001EEA9
    ),
    (
      FirstCodePoint: $0001EEAB;
      LastCodePoint: $0001EEBB
    ),
    (
      FirstCodePoint: $00020000;
      LastCodePoint: $0002A6DF
    ),
    (
      FirstCodePoint: $0002A700;
      LastCodePoint: $0002B739
    ),
    (
      FirstCodePoint: $0002B740;
      LastCodePoint: $0002B81D
    ),
    (
      FirstCodePoint: $0002B820;
      LastCodePoint: $0002CEA1
    ),
    (
      FirstCodePoint: $0002CEB0;
      LastCodePoint: $0002EBE0
    ),
    (
      FirstCodePoint: $0002EBF0;
      LastCodePoint: $0002EE5D
    ),
    (
      FirstCodePoint: $0002F800;
      LastCodePoint: $0002FA1D
    ),
    (
      FirstCodePoint: $00030000;
      LastCodePoint: $0003134A
    ),
    (
      FirstCodePoint: $00031350;
      LastCodePoint: $000323AF
    )
  );

  UNICODE_IDENTIFIER_CONTINUE_RANGES: array[0..770] of TUnicodeRange = (
    (
      FirstCodePoint: $00000030;
      LastCodePoint: $00000039
    ),
    (
      FirstCodePoint: $00000041;
      LastCodePoint: $0000005A
    ),
    (
      FirstCodePoint: $0000005F;
      LastCodePoint: $0000005F
    ),
    (
      FirstCodePoint: $00000061;
      LastCodePoint: $0000007A
    ),
    (
      FirstCodePoint: $000000AA;
      LastCodePoint: $000000AA
    ),
    (
      FirstCodePoint: $000000B5;
      LastCodePoint: $000000B5
    ),
    (
      FirstCodePoint: $000000BA;
      LastCodePoint: $000000BA
    ),
    (
      FirstCodePoint: $000000C0;
      LastCodePoint: $000000D6
    ),
    (
      FirstCodePoint: $000000D8;
      LastCodePoint: $000000F6
    ),
    (
      FirstCodePoint: $000000F8;
      LastCodePoint: $000002C1
    ),
    (
      FirstCodePoint: $000002C6;
      LastCodePoint: $000002D1
    ),
    (
      FirstCodePoint: $000002E0;
      LastCodePoint: $000002E4
    ),
    (
      FirstCodePoint: $000002EC;
      LastCodePoint: $000002EC
    ),
    (
      FirstCodePoint: $000002EE;
      LastCodePoint: $000002EE
    ),
    (
      FirstCodePoint: $00000300;
      LastCodePoint: $00000374
    ),
    (
      FirstCodePoint: $00000376;
      LastCodePoint: $00000377
    ),
    (
      FirstCodePoint: $0000037A;
      LastCodePoint: $0000037D
    ),
    (
      FirstCodePoint: $0000037F;
      LastCodePoint: $0000037F
    ),
    (
      FirstCodePoint: $00000386;
      LastCodePoint: $00000386
    ),
    (
      FirstCodePoint: $00000388;
      LastCodePoint: $0000038A
    ),
    (
      FirstCodePoint: $0000038C;
      LastCodePoint: $0000038C
    ),
    (
      FirstCodePoint: $0000038E;
      LastCodePoint: $000003A1
    ),
    (
      FirstCodePoint: $000003A3;
      LastCodePoint: $000003F5
    ),
    (
      FirstCodePoint: $000003F7;
      LastCodePoint: $00000481
    ),
    (
      FirstCodePoint: $00000483;
      LastCodePoint: $00000487
    ),
    (
      FirstCodePoint: $0000048A;
      LastCodePoint: $0000052F
    ),
    (
      FirstCodePoint: $00000531;
      LastCodePoint: $00000556
    ),
    (
      FirstCodePoint: $00000559;
      LastCodePoint: $00000559
    ),
    (
      FirstCodePoint: $00000560;
      LastCodePoint: $00000588
    ),
    (
      FirstCodePoint: $00000591;
      LastCodePoint: $000005BD
    ),
    (
      FirstCodePoint: $000005BF;
      LastCodePoint: $000005BF
    ),
    (
      FirstCodePoint: $000005C1;
      LastCodePoint: $000005C2
    ),
    (
      FirstCodePoint: $000005C4;
      LastCodePoint: $000005C5
    ),
    (
      FirstCodePoint: $000005C7;
      LastCodePoint: $000005C7
    ),
    (
      FirstCodePoint: $000005D0;
      LastCodePoint: $000005EA
    ),
    (
      FirstCodePoint: $000005EF;
      LastCodePoint: $000005F2
    ),
    (
      FirstCodePoint: $00000610;
      LastCodePoint: $0000061A
    ),
    (
      FirstCodePoint: $00000620;
      LastCodePoint: $00000669
    ),
    (
      FirstCodePoint: $0000066E;
      LastCodePoint: $000006D3
    ),
    (
      FirstCodePoint: $000006D5;
      LastCodePoint: $000006DC
    ),
    (
      FirstCodePoint: $000006DF;
      LastCodePoint: $000006E8
    ),
    (
      FirstCodePoint: $000006EA;
      LastCodePoint: $000006FC
    ),
    (
      FirstCodePoint: $000006FF;
      LastCodePoint: $000006FF
    ),
    (
      FirstCodePoint: $00000710;
      LastCodePoint: $0000074A
    ),
    (
      FirstCodePoint: $0000074D;
      LastCodePoint: $000007B1
    ),
    (
      FirstCodePoint: $000007C0;
      LastCodePoint: $000007F5
    ),
    (
      FirstCodePoint: $000007FA;
      LastCodePoint: $000007FA
    ),
    (
      FirstCodePoint: $000007FD;
      LastCodePoint: $000007FD
    ),
    (
      FirstCodePoint: $00000800;
      LastCodePoint: $0000082D
    ),
    (
      FirstCodePoint: $00000840;
      LastCodePoint: $0000085B
    ),
    (
      FirstCodePoint: $00000860;
      LastCodePoint: $0000086A
    ),
    (
      FirstCodePoint: $00000870;
      LastCodePoint: $00000887
    ),
    (
      FirstCodePoint: $00000889;
      LastCodePoint: $0000088E
    ),
    (
      FirstCodePoint: $00000898;
      LastCodePoint: $000008E1
    ),
    (
      FirstCodePoint: $000008E3;
      LastCodePoint: $00000963
    ),
    (
      FirstCodePoint: $00000966;
      LastCodePoint: $0000096F
    ),
    (
      FirstCodePoint: $00000971;
      LastCodePoint: $00000983
    ),
    (
      FirstCodePoint: $00000985;
      LastCodePoint: $0000098C
    ),
    (
      FirstCodePoint: $0000098F;
      LastCodePoint: $00000990
    ),
    (
      FirstCodePoint: $00000993;
      LastCodePoint: $000009A8
    ),
    (
      FirstCodePoint: $000009AA;
      LastCodePoint: $000009B0
    ),
    (
      FirstCodePoint: $000009B2;
      LastCodePoint: $000009B2
    ),
    (
      FirstCodePoint: $000009B6;
      LastCodePoint: $000009B9
    ),
    (
      FirstCodePoint: $000009BC;
      LastCodePoint: $000009C4
    ),
    (
      FirstCodePoint: $000009C7;
      LastCodePoint: $000009C8
    ),
    (
      FirstCodePoint: $000009CB;
      LastCodePoint: $000009CE
    ),
    (
      FirstCodePoint: $000009D7;
      LastCodePoint: $000009D7
    ),
    (
      FirstCodePoint: $000009DC;
      LastCodePoint: $000009DD
    ),
    (
      FirstCodePoint: $000009DF;
      LastCodePoint: $000009E3
    ),
    (
      FirstCodePoint: $000009E6;
      LastCodePoint: $000009F1
    ),
    (
      FirstCodePoint: $000009FC;
      LastCodePoint: $000009FC
    ),
    (
      FirstCodePoint: $000009FE;
      LastCodePoint: $000009FE
    ),
    (
      FirstCodePoint: $00000A01;
      LastCodePoint: $00000A03
    ),
    (
      FirstCodePoint: $00000A05;
      LastCodePoint: $00000A0A
    ),
    (
      FirstCodePoint: $00000A0F;
      LastCodePoint: $00000A10
    ),
    (
      FirstCodePoint: $00000A13;
      LastCodePoint: $00000A28
    ),
    (
      FirstCodePoint: $00000A2A;
      LastCodePoint: $00000A30
    ),
    (
      FirstCodePoint: $00000A32;
      LastCodePoint: $00000A33
    ),
    (
      FirstCodePoint: $00000A35;
      LastCodePoint: $00000A36
    ),
    (
      FirstCodePoint: $00000A38;
      LastCodePoint: $00000A39
    ),
    (
      FirstCodePoint: $00000A3C;
      LastCodePoint: $00000A3C
    ),
    (
      FirstCodePoint: $00000A3E;
      LastCodePoint: $00000A42
    ),
    (
      FirstCodePoint: $00000A47;
      LastCodePoint: $00000A48
    ),
    (
      FirstCodePoint: $00000A4B;
      LastCodePoint: $00000A4D
    ),
    (
      FirstCodePoint: $00000A51;
      LastCodePoint: $00000A51
    ),
    (
      FirstCodePoint: $00000A59;
      LastCodePoint: $00000A5C
    ),
    (
      FirstCodePoint: $00000A5E;
      LastCodePoint: $00000A5E
    ),
    (
      FirstCodePoint: $00000A66;
      LastCodePoint: $00000A75
    ),
    (
      FirstCodePoint: $00000A81;
      LastCodePoint: $00000A83
    ),
    (
      FirstCodePoint: $00000A85;
      LastCodePoint: $00000A8D
    ),
    (
      FirstCodePoint: $00000A8F;
      LastCodePoint: $00000A91
    ),
    (
      FirstCodePoint: $00000A93;
      LastCodePoint: $00000AA8
    ),
    (
      FirstCodePoint: $00000AAA;
      LastCodePoint: $00000AB0
    ),
    (
      FirstCodePoint: $00000AB2;
      LastCodePoint: $00000AB3
    ),
    (
      FirstCodePoint: $00000AB5;
      LastCodePoint: $00000AB9
    ),
    (
      FirstCodePoint: $00000ABC;
      LastCodePoint: $00000AC5
    ),
    (
      FirstCodePoint: $00000AC7;
      LastCodePoint: $00000AC9
    ),
    (
      FirstCodePoint: $00000ACB;
      LastCodePoint: $00000ACD
    ),
    (
      FirstCodePoint: $00000AD0;
      LastCodePoint: $00000AD0
    ),
    (
      FirstCodePoint: $00000AE0;
      LastCodePoint: $00000AE3
    ),
    (
      FirstCodePoint: $00000AE6;
      LastCodePoint: $00000AEF
    ),
    (
      FirstCodePoint: $00000AF9;
      LastCodePoint: $00000AFF
    ),
    (
      FirstCodePoint: $00000B01;
      LastCodePoint: $00000B03
    ),
    (
      FirstCodePoint: $00000B05;
      LastCodePoint: $00000B0C
    ),
    (
      FirstCodePoint: $00000B0F;
      LastCodePoint: $00000B10
    ),
    (
      FirstCodePoint: $00000B13;
      LastCodePoint: $00000B28
    ),
    (
      FirstCodePoint: $00000B2A;
      LastCodePoint: $00000B30
    ),
    (
      FirstCodePoint: $00000B32;
      LastCodePoint: $00000B33
    ),
    (
      FirstCodePoint: $00000B35;
      LastCodePoint: $00000B39
    ),
    (
      FirstCodePoint: $00000B3C;
      LastCodePoint: $00000B44
    ),
    (
      FirstCodePoint: $00000B47;
      LastCodePoint: $00000B48
    ),
    (
      FirstCodePoint: $00000B4B;
      LastCodePoint: $00000B4D
    ),
    (
      FirstCodePoint: $00000B55;
      LastCodePoint: $00000B57
    ),
    (
      FirstCodePoint: $00000B5C;
      LastCodePoint: $00000B5D
    ),
    (
      FirstCodePoint: $00000B5F;
      LastCodePoint: $00000B63
    ),
    (
      FirstCodePoint: $00000B66;
      LastCodePoint: $00000B6F
    ),
    (
      FirstCodePoint: $00000B71;
      LastCodePoint: $00000B71
    ),
    (
      FirstCodePoint: $00000B82;
      LastCodePoint: $00000B83
    ),
    (
      FirstCodePoint: $00000B85;
      LastCodePoint: $00000B8A
    ),
    (
      FirstCodePoint: $00000B8E;
      LastCodePoint: $00000B90
    ),
    (
      FirstCodePoint: $00000B92;
      LastCodePoint: $00000B95
    ),
    (
      FirstCodePoint: $00000B99;
      LastCodePoint: $00000B9A
    ),
    (
      FirstCodePoint: $00000B9C;
      LastCodePoint: $00000B9C
    ),
    (
      FirstCodePoint: $00000B9E;
      LastCodePoint: $00000B9F
    ),
    (
      FirstCodePoint: $00000BA3;
      LastCodePoint: $00000BA4
    ),
    (
      FirstCodePoint: $00000BA8;
      LastCodePoint: $00000BAA
    ),
    (
      FirstCodePoint: $00000BAE;
      LastCodePoint: $00000BB9
    ),
    (
      FirstCodePoint: $00000BBE;
      LastCodePoint: $00000BC2
    ),
    (
      FirstCodePoint: $00000BC6;
      LastCodePoint: $00000BC8
    ),
    (
      FirstCodePoint: $00000BCA;
      LastCodePoint: $00000BCD
    ),
    (
      FirstCodePoint: $00000BD0;
      LastCodePoint: $00000BD0
    ),
    (
      FirstCodePoint: $00000BD7;
      LastCodePoint: $00000BD7
    ),
    (
      FirstCodePoint: $00000BE6;
      LastCodePoint: $00000BEF
    ),
    (
      FirstCodePoint: $00000C00;
      LastCodePoint: $00000C0C
    ),
    (
      FirstCodePoint: $00000C0E;
      LastCodePoint: $00000C10
    ),
    (
      FirstCodePoint: $00000C12;
      LastCodePoint: $00000C28
    ),
    (
      FirstCodePoint: $00000C2A;
      LastCodePoint: $00000C39
    ),
    (
      FirstCodePoint: $00000C3C;
      LastCodePoint: $00000C44
    ),
    (
      FirstCodePoint: $00000C46;
      LastCodePoint: $00000C48
    ),
    (
      FirstCodePoint: $00000C4A;
      LastCodePoint: $00000C4D
    ),
    (
      FirstCodePoint: $00000C55;
      LastCodePoint: $00000C56
    ),
    (
      FirstCodePoint: $00000C58;
      LastCodePoint: $00000C5A
    ),
    (
      FirstCodePoint: $00000C5D;
      LastCodePoint: $00000C5D
    ),
    (
      FirstCodePoint: $00000C60;
      LastCodePoint: $00000C63
    ),
    (
      FirstCodePoint: $00000C66;
      LastCodePoint: $00000C6F
    ),
    (
      FirstCodePoint: $00000C80;
      LastCodePoint: $00000C83
    ),
    (
      FirstCodePoint: $00000C85;
      LastCodePoint: $00000C8C
    ),
    (
      FirstCodePoint: $00000C8E;
      LastCodePoint: $00000C90
    ),
    (
      FirstCodePoint: $00000C92;
      LastCodePoint: $00000CA8
    ),
    (
      FirstCodePoint: $00000CAA;
      LastCodePoint: $00000CB3
    ),
    (
      FirstCodePoint: $00000CB5;
      LastCodePoint: $00000CB9
    ),
    (
      FirstCodePoint: $00000CBC;
      LastCodePoint: $00000CC4
    ),
    (
      FirstCodePoint: $00000CC6;
      LastCodePoint: $00000CC8
    ),
    (
      FirstCodePoint: $00000CCA;
      LastCodePoint: $00000CCD
    ),
    (
      FirstCodePoint: $00000CD5;
      LastCodePoint: $00000CD6
    ),
    (
      FirstCodePoint: $00000CDD;
      LastCodePoint: $00000CDE
    ),
    (
      FirstCodePoint: $00000CE0;
      LastCodePoint: $00000CE3
    ),
    (
      FirstCodePoint: $00000CE6;
      LastCodePoint: $00000CEF
    ),
    (
      FirstCodePoint: $00000CF1;
      LastCodePoint: $00000CF3
    ),
    (
      FirstCodePoint: $00000D00;
      LastCodePoint: $00000D0C
    ),
    (
      FirstCodePoint: $00000D0E;
      LastCodePoint: $00000D10
    ),
    (
      FirstCodePoint: $00000D12;
      LastCodePoint: $00000D44
    ),
    (
      FirstCodePoint: $00000D46;
      LastCodePoint: $00000D48
    ),
    (
      FirstCodePoint: $00000D4A;
      LastCodePoint: $00000D4E
    ),
    (
      FirstCodePoint: $00000D54;
      LastCodePoint: $00000D57
    ),
    (
      FirstCodePoint: $00000D5F;
      LastCodePoint: $00000D63
    ),
    (
      FirstCodePoint: $00000D66;
      LastCodePoint: $00000D6F
    ),
    (
      FirstCodePoint: $00000D7A;
      LastCodePoint: $00000D7F
    ),
    (
      FirstCodePoint: $00000D81;
      LastCodePoint: $00000D83
    ),
    (
      FirstCodePoint: $00000D85;
      LastCodePoint: $00000D96
    ),
    (
      FirstCodePoint: $00000D9A;
      LastCodePoint: $00000DB1
    ),
    (
      FirstCodePoint: $00000DB3;
      LastCodePoint: $00000DBB
    ),
    (
      FirstCodePoint: $00000DBD;
      LastCodePoint: $00000DBD
    ),
    (
      FirstCodePoint: $00000DC0;
      LastCodePoint: $00000DC6
    ),
    (
      FirstCodePoint: $00000DCA;
      LastCodePoint: $00000DCA
    ),
    (
      FirstCodePoint: $00000DCF;
      LastCodePoint: $00000DD4
    ),
    (
      FirstCodePoint: $00000DD6;
      LastCodePoint: $00000DD6
    ),
    (
      FirstCodePoint: $00000DD8;
      LastCodePoint: $00000DDF
    ),
    (
      FirstCodePoint: $00000DE6;
      LastCodePoint: $00000DEF
    ),
    (
      FirstCodePoint: $00000DF2;
      LastCodePoint: $00000DF3
    ),
    (
      FirstCodePoint: $00000E01;
      LastCodePoint: $00000E3A
    ),
    (
      FirstCodePoint: $00000E40;
      LastCodePoint: $00000E4E
    ),
    (
      FirstCodePoint: $00000E50;
      LastCodePoint: $00000E59
    ),
    (
      FirstCodePoint: $00000E81;
      LastCodePoint: $00000E82
    ),
    (
      FirstCodePoint: $00000E84;
      LastCodePoint: $00000E84
    ),
    (
      FirstCodePoint: $00000E86;
      LastCodePoint: $00000E8A
    ),
    (
      FirstCodePoint: $00000E8C;
      LastCodePoint: $00000EA3
    ),
    (
      FirstCodePoint: $00000EA5;
      LastCodePoint: $00000EA5
    ),
    (
      FirstCodePoint: $00000EA7;
      LastCodePoint: $00000EBD
    ),
    (
      FirstCodePoint: $00000EC0;
      LastCodePoint: $00000EC4
    ),
    (
      FirstCodePoint: $00000EC6;
      LastCodePoint: $00000EC6
    ),
    (
      FirstCodePoint: $00000EC8;
      LastCodePoint: $00000ECE
    ),
    (
      FirstCodePoint: $00000ED0;
      LastCodePoint: $00000ED9
    ),
    (
      FirstCodePoint: $00000EDC;
      LastCodePoint: $00000EDF
    ),
    (
      FirstCodePoint: $00000F00;
      LastCodePoint: $00000F00
    ),
    (
      FirstCodePoint: $00000F18;
      LastCodePoint: $00000F19
    ),
    (
      FirstCodePoint: $00000F20;
      LastCodePoint: $00000F29
    ),
    (
      FirstCodePoint: $00000F35;
      LastCodePoint: $00000F35
    ),
    (
      FirstCodePoint: $00000F37;
      LastCodePoint: $00000F37
    ),
    (
      FirstCodePoint: $00000F39;
      LastCodePoint: $00000F39
    ),
    (
      FirstCodePoint: $00000F3E;
      LastCodePoint: $00000F47
    ),
    (
      FirstCodePoint: $00000F49;
      LastCodePoint: $00000F6C
    ),
    (
      FirstCodePoint: $00000F71;
      LastCodePoint: $00000F84
    ),
    (
      FirstCodePoint: $00000F86;
      LastCodePoint: $00000F97
    ),
    (
      FirstCodePoint: $00000F99;
      LastCodePoint: $00000FBC
    ),
    (
      FirstCodePoint: $00000FC6;
      LastCodePoint: $00000FC6
    ),
    (
      FirstCodePoint: $00001000;
      LastCodePoint: $00001049
    ),
    (
      FirstCodePoint: $00001050;
      LastCodePoint: $0000109D
    ),
    (
      FirstCodePoint: $000010A0;
      LastCodePoint: $000010C5
    ),
    (
      FirstCodePoint: $000010C7;
      LastCodePoint: $000010C7
    ),
    (
      FirstCodePoint: $000010CD;
      LastCodePoint: $000010CD
    ),
    (
      FirstCodePoint: $000010D0;
      LastCodePoint: $000010FA
    ),
    (
      FirstCodePoint: $000010FC;
      LastCodePoint: $00001248
    ),
    (
      FirstCodePoint: $0000124A;
      LastCodePoint: $0000124D
    ),
    (
      FirstCodePoint: $00001250;
      LastCodePoint: $00001256
    ),
    (
      FirstCodePoint: $00001258;
      LastCodePoint: $00001258
    ),
    (
      FirstCodePoint: $0000125A;
      LastCodePoint: $0000125D
    ),
    (
      FirstCodePoint: $00001260;
      LastCodePoint: $00001288
    ),
    (
      FirstCodePoint: $0000128A;
      LastCodePoint: $0000128D
    ),
    (
      FirstCodePoint: $00001290;
      LastCodePoint: $000012B0
    ),
    (
      FirstCodePoint: $000012B2;
      LastCodePoint: $000012B5
    ),
    (
      FirstCodePoint: $000012B8;
      LastCodePoint: $000012BE
    ),
    (
      FirstCodePoint: $000012C0;
      LastCodePoint: $000012C0
    ),
    (
      FirstCodePoint: $000012C2;
      LastCodePoint: $000012C5
    ),
    (
      FirstCodePoint: $000012C8;
      LastCodePoint: $000012D6
    ),
    (
      FirstCodePoint: $000012D8;
      LastCodePoint: $00001310
    ),
    (
      FirstCodePoint: $00001312;
      LastCodePoint: $00001315
    ),
    (
      FirstCodePoint: $00001318;
      LastCodePoint: $0000135A
    ),
    (
      FirstCodePoint: $0000135D;
      LastCodePoint: $0000135F
    ),
    (
      FirstCodePoint: $00001380;
      LastCodePoint: $0000138F
    ),
    (
      FirstCodePoint: $000013A0;
      LastCodePoint: $000013F5
    ),
    (
      FirstCodePoint: $000013F8;
      LastCodePoint: $000013FD
    ),
    (
      FirstCodePoint: $00001401;
      LastCodePoint: $0000166C
    ),
    (
      FirstCodePoint: $0000166F;
      LastCodePoint: $0000167F
    ),
    (
      FirstCodePoint: $00001681;
      LastCodePoint: $0000169A
    ),
    (
      FirstCodePoint: $000016A0;
      LastCodePoint: $000016EA
    ),
    (
      FirstCodePoint: $000016EE;
      LastCodePoint: $000016F8
    ),
    (
      FirstCodePoint: $00001700;
      LastCodePoint: $00001715
    ),
    (
      FirstCodePoint: $0000171F;
      LastCodePoint: $00001734
    ),
    (
      FirstCodePoint: $00001740;
      LastCodePoint: $00001753
    ),
    (
      FirstCodePoint: $00001760;
      LastCodePoint: $0000176C
    ),
    (
      FirstCodePoint: $0000176E;
      LastCodePoint: $00001770
    ),
    (
      FirstCodePoint: $00001772;
      LastCodePoint: $00001773
    ),
    (
      FirstCodePoint: $00001780;
      LastCodePoint: $000017D3
    ),
    (
      FirstCodePoint: $000017D7;
      LastCodePoint: $000017D7
    ),
    (
      FirstCodePoint: $000017DC;
      LastCodePoint: $000017DD
    ),
    (
      FirstCodePoint: $000017E0;
      LastCodePoint: $000017E9
    ),
    (
      FirstCodePoint: $0000180B;
      LastCodePoint: $0000180D
    ),
    (
      FirstCodePoint: $0000180F;
      LastCodePoint: $00001819
    ),
    (
      FirstCodePoint: $00001820;
      LastCodePoint: $00001878
    ),
    (
      FirstCodePoint: $00001880;
      LastCodePoint: $000018AA
    ),
    (
      FirstCodePoint: $000018B0;
      LastCodePoint: $000018F5
    ),
    (
      FirstCodePoint: $00001900;
      LastCodePoint: $0000191E
    ),
    (
      FirstCodePoint: $00001920;
      LastCodePoint: $0000192B
    ),
    (
      FirstCodePoint: $00001930;
      LastCodePoint: $0000193B
    ),
    (
      FirstCodePoint: $00001946;
      LastCodePoint: $0000196D
    ),
    (
      FirstCodePoint: $00001970;
      LastCodePoint: $00001974
    ),
    (
      FirstCodePoint: $00001980;
      LastCodePoint: $000019AB
    ),
    (
      FirstCodePoint: $000019B0;
      LastCodePoint: $000019C9
    ),
    (
      FirstCodePoint: $000019D0;
      LastCodePoint: $000019D9
    ),
    (
      FirstCodePoint: $00001A00;
      LastCodePoint: $00001A1B
    ),
    (
      FirstCodePoint: $00001A20;
      LastCodePoint: $00001A5E
    ),
    (
      FirstCodePoint: $00001A60;
      LastCodePoint: $00001A7C
    ),
    (
      FirstCodePoint: $00001A7F;
      LastCodePoint: $00001A89
    ),
    (
      FirstCodePoint: $00001A90;
      LastCodePoint: $00001A99
    ),
    (
      FirstCodePoint: $00001AA7;
      LastCodePoint: $00001AA7
    ),
    (
      FirstCodePoint: $00001AB0;
      LastCodePoint: $00001ABD
    ),
    (
      FirstCodePoint: $00001ABF;
      LastCodePoint: $00001ACE
    ),
    (
      FirstCodePoint: $00001B00;
      LastCodePoint: $00001B4C
    ),
    (
      FirstCodePoint: $00001B50;
      LastCodePoint: $00001B59
    ),
    (
      FirstCodePoint: $00001B6B;
      LastCodePoint: $00001B73
    ),
    (
      FirstCodePoint: $00001B80;
      LastCodePoint: $00001BF3
    ),
    (
      FirstCodePoint: $00001C00;
      LastCodePoint: $00001C37
    ),
    (
      FirstCodePoint: $00001C40;
      LastCodePoint: $00001C49
    ),
    (
      FirstCodePoint: $00001C4D;
      LastCodePoint: $00001C7D
    ),
    (
      FirstCodePoint: $00001C80;
      LastCodePoint: $00001C88
    ),
    (
      FirstCodePoint: $00001C90;
      LastCodePoint: $00001CBA
    ),
    (
      FirstCodePoint: $00001CBD;
      LastCodePoint: $00001CBF
    ),
    (
      FirstCodePoint: $00001CD0;
      LastCodePoint: $00001CD2
    ),
    (
      FirstCodePoint: $00001CD4;
      LastCodePoint: $00001CFA
    ),
    (
      FirstCodePoint: $00001D00;
      LastCodePoint: $00001F15
    ),
    (
      FirstCodePoint: $00001F18;
      LastCodePoint: $00001F1D
    ),
    (
      FirstCodePoint: $00001F20;
      LastCodePoint: $00001F45
    ),
    (
      FirstCodePoint: $00001F48;
      LastCodePoint: $00001F4D
    ),
    (
      FirstCodePoint: $00001F50;
      LastCodePoint: $00001F57
    ),
    (
      FirstCodePoint: $00001F59;
      LastCodePoint: $00001F59
    ),
    (
      FirstCodePoint: $00001F5B;
      LastCodePoint: $00001F5B
    ),
    (
      FirstCodePoint: $00001F5D;
      LastCodePoint: $00001F5D
    ),
    (
      FirstCodePoint: $00001F5F;
      LastCodePoint: $00001F7D
    ),
    (
      FirstCodePoint: $00001F80;
      LastCodePoint: $00001FB4
    ),
    (
      FirstCodePoint: $00001FB6;
      LastCodePoint: $00001FBC
    ),
    (
      FirstCodePoint: $00001FBE;
      LastCodePoint: $00001FBE
    ),
    (
      FirstCodePoint: $00001FC2;
      LastCodePoint: $00001FC4
    ),
    (
      FirstCodePoint: $00001FC6;
      LastCodePoint: $00001FCC
    ),
    (
      FirstCodePoint: $00001FD0;
      LastCodePoint: $00001FD3
    ),
    (
      FirstCodePoint: $00001FD6;
      LastCodePoint: $00001FDB
    ),
    (
      FirstCodePoint: $00001FE0;
      LastCodePoint: $00001FEC
    ),
    (
      FirstCodePoint: $00001FF2;
      LastCodePoint: $00001FF4
    ),
    (
      FirstCodePoint: $00001FF6;
      LastCodePoint: $00001FFC
    ),
    (
      FirstCodePoint: $0000203F;
      LastCodePoint: $00002040
    ),
    (
      FirstCodePoint: $00002054;
      LastCodePoint: $00002054
    ),
    (
      FirstCodePoint: $00002071;
      LastCodePoint: $00002071
    ),
    (
      FirstCodePoint: $0000207F;
      LastCodePoint: $0000207F
    ),
    (
      FirstCodePoint: $00002090;
      LastCodePoint: $0000209C
    ),
    (
      FirstCodePoint: $000020D0;
      LastCodePoint: $000020DC
    ),
    (
      FirstCodePoint: $000020E1;
      LastCodePoint: $000020E1
    ),
    (
      FirstCodePoint: $000020E5;
      LastCodePoint: $000020F0
    ),
    (
      FirstCodePoint: $00002102;
      LastCodePoint: $00002102
    ),
    (
      FirstCodePoint: $00002107;
      LastCodePoint: $00002107
    ),
    (
      FirstCodePoint: $0000210A;
      LastCodePoint: $00002113
    ),
    (
      FirstCodePoint: $00002115;
      LastCodePoint: $00002115
    ),
    (
      FirstCodePoint: $00002119;
      LastCodePoint: $0000211D
    ),
    (
      FirstCodePoint: $00002124;
      LastCodePoint: $00002124
    ),
    (
      FirstCodePoint: $00002126;
      LastCodePoint: $00002126
    ),
    (
      FirstCodePoint: $00002128;
      LastCodePoint: $00002128
    ),
    (
      FirstCodePoint: $0000212A;
      LastCodePoint: $0000212D
    ),
    (
      FirstCodePoint: $0000212F;
      LastCodePoint: $00002139
    ),
    (
      FirstCodePoint: $0000213C;
      LastCodePoint: $0000213F
    ),
    (
      FirstCodePoint: $00002145;
      LastCodePoint: $00002149
    ),
    (
      FirstCodePoint: $0000214E;
      LastCodePoint: $0000214E
    ),
    (
      FirstCodePoint: $00002160;
      LastCodePoint: $00002188
    ),
    (
      FirstCodePoint: $00002C00;
      LastCodePoint: $00002CE4
    ),
    (
      FirstCodePoint: $00002CEB;
      LastCodePoint: $00002CF3
    ),
    (
      FirstCodePoint: $00002D00;
      LastCodePoint: $00002D25
    ),
    (
      FirstCodePoint: $00002D27;
      LastCodePoint: $00002D27
    ),
    (
      FirstCodePoint: $00002D2D;
      LastCodePoint: $00002D2D
    ),
    (
      FirstCodePoint: $00002D30;
      LastCodePoint: $00002D67
    ),
    (
      FirstCodePoint: $00002D6F;
      LastCodePoint: $00002D6F
    ),
    (
      FirstCodePoint: $00002D7F;
      LastCodePoint: $00002D96
    ),
    (
      FirstCodePoint: $00002DA0;
      LastCodePoint: $00002DA6
    ),
    (
      FirstCodePoint: $00002DA8;
      LastCodePoint: $00002DAE
    ),
    (
      FirstCodePoint: $00002DB0;
      LastCodePoint: $00002DB6
    ),
    (
      FirstCodePoint: $00002DB8;
      LastCodePoint: $00002DBE
    ),
    (
      FirstCodePoint: $00002DC0;
      LastCodePoint: $00002DC6
    ),
    (
      FirstCodePoint: $00002DC8;
      LastCodePoint: $00002DCE
    ),
    (
      FirstCodePoint: $00002DD0;
      LastCodePoint: $00002DD6
    ),
    (
      FirstCodePoint: $00002DD8;
      LastCodePoint: $00002DDE
    ),
    (
      FirstCodePoint: $00002DE0;
      LastCodePoint: $00002DFF
    ),
    (
      FirstCodePoint: $00002E2F;
      LastCodePoint: $00002E2F
    ),
    (
      FirstCodePoint: $00003005;
      LastCodePoint: $00003007
    ),
    (
      FirstCodePoint: $00003021;
      LastCodePoint: $0000302F
    ),
    (
      FirstCodePoint: $00003031;
      LastCodePoint: $00003035
    ),
    (
      FirstCodePoint: $00003038;
      LastCodePoint: $0000303C
    ),
    (
      FirstCodePoint: $00003041;
      LastCodePoint: $00003096
    ),
    (
      FirstCodePoint: $00003099;
      LastCodePoint: $0000309A
    ),
    (
      FirstCodePoint: $0000309D;
      LastCodePoint: $0000309F
    ),
    (
      FirstCodePoint: $000030A1;
      LastCodePoint: $000030FA
    ),
    (
      FirstCodePoint: $000030FC;
      LastCodePoint: $000030FF
    ),
    (
      FirstCodePoint: $00003105;
      LastCodePoint: $0000312F
    ),
    (
      FirstCodePoint: $00003131;
      LastCodePoint: $0000318E
    ),
    (
      FirstCodePoint: $000031A0;
      LastCodePoint: $000031BF
    ),
    (
      FirstCodePoint: $000031F0;
      LastCodePoint: $000031FF
    ),
    (
      FirstCodePoint: $00003400;
      LastCodePoint: $00004DBF
    ),
    (
      FirstCodePoint: $00004E00;
      LastCodePoint: $0000A48C
    ),
    (
      FirstCodePoint: $0000A4D0;
      LastCodePoint: $0000A4FD
    ),
    (
      FirstCodePoint: $0000A500;
      LastCodePoint: $0000A60C
    ),
    (
      FirstCodePoint: $0000A610;
      LastCodePoint: $0000A62B
    ),
    (
      FirstCodePoint: $0000A640;
      LastCodePoint: $0000A66F
    ),
    (
      FirstCodePoint: $0000A674;
      LastCodePoint: $0000A67D
    ),
    (
      FirstCodePoint: $0000A67F;
      LastCodePoint: $0000A6F1
    ),
    (
      FirstCodePoint: $0000A717;
      LastCodePoint: $0000A71F
    ),
    (
      FirstCodePoint: $0000A722;
      LastCodePoint: $0000A788
    ),
    (
      FirstCodePoint: $0000A78B;
      LastCodePoint: $0000A7CA
    ),
    (
      FirstCodePoint: $0000A7D0;
      LastCodePoint: $0000A7D1
    ),
    (
      FirstCodePoint: $0000A7D3;
      LastCodePoint: $0000A7D3
    ),
    (
      FirstCodePoint: $0000A7D5;
      LastCodePoint: $0000A7D9
    ),
    (
      FirstCodePoint: $0000A7F2;
      LastCodePoint: $0000A827
    ),
    (
      FirstCodePoint: $0000A82C;
      LastCodePoint: $0000A82C
    ),
    (
      FirstCodePoint: $0000A840;
      LastCodePoint: $0000A873
    ),
    (
      FirstCodePoint: $0000A880;
      LastCodePoint: $0000A8C5
    ),
    (
      FirstCodePoint: $0000A8D0;
      LastCodePoint: $0000A8D9
    ),
    (
      FirstCodePoint: $0000A8E0;
      LastCodePoint: $0000A8F7
    ),
    (
      FirstCodePoint: $0000A8FB;
      LastCodePoint: $0000A8FB
    ),
    (
      FirstCodePoint: $0000A8FD;
      LastCodePoint: $0000A92D
    ),
    (
      FirstCodePoint: $0000A930;
      LastCodePoint: $0000A953
    ),
    (
      FirstCodePoint: $0000A960;
      LastCodePoint: $0000A97C
    ),
    (
      FirstCodePoint: $0000A980;
      LastCodePoint: $0000A9C0
    ),
    (
      FirstCodePoint: $0000A9CF;
      LastCodePoint: $0000A9D9
    ),
    (
      FirstCodePoint: $0000A9E0;
      LastCodePoint: $0000A9FE
    ),
    (
      FirstCodePoint: $0000AA00;
      LastCodePoint: $0000AA36
    ),
    (
      FirstCodePoint: $0000AA40;
      LastCodePoint: $0000AA4D
    ),
    (
      FirstCodePoint: $0000AA50;
      LastCodePoint: $0000AA59
    ),
    (
      FirstCodePoint: $0000AA60;
      LastCodePoint: $0000AA76
    ),
    (
      FirstCodePoint: $0000AA7A;
      LastCodePoint: $0000AAC2
    ),
    (
      FirstCodePoint: $0000AADB;
      LastCodePoint: $0000AADD
    ),
    (
      FirstCodePoint: $0000AAE0;
      LastCodePoint: $0000AAEF
    ),
    (
      FirstCodePoint: $0000AAF2;
      LastCodePoint: $0000AAF6
    ),
    (
      FirstCodePoint: $0000AB01;
      LastCodePoint: $0000AB06
    ),
    (
      FirstCodePoint: $0000AB09;
      LastCodePoint: $0000AB0E
    ),
    (
      FirstCodePoint: $0000AB11;
      LastCodePoint: $0000AB16
    ),
    (
      FirstCodePoint: $0000AB20;
      LastCodePoint: $0000AB26
    ),
    (
      FirstCodePoint: $0000AB28;
      LastCodePoint: $0000AB2E
    ),
    (
      FirstCodePoint: $0000AB30;
      LastCodePoint: $0000AB5A
    ),
    (
      FirstCodePoint: $0000AB5C;
      LastCodePoint: $0000AB69
    ),
    (
      FirstCodePoint: $0000AB70;
      LastCodePoint: $0000ABEA
    ),
    (
      FirstCodePoint: $0000ABEC;
      LastCodePoint: $0000ABED
    ),
    (
      FirstCodePoint: $0000ABF0;
      LastCodePoint: $0000ABF9
    ),
    (
      FirstCodePoint: $0000AC00;
      LastCodePoint: $0000D7A3
    ),
    (
      FirstCodePoint: $0000D7B0;
      LastCodePoint: $0000D7C6
    ),
    (
      FirstCodePoint: $0000D7CB;
      LastCodePoint: $0000D7FB
    ),
    (
      FirstCodePoint: $0000F900;
      LastCodePoint: $0000FA6D
    ),
    (
      FirstCodePoint: $0000FA70;
      LastCodePoint: $0000FAD9
    ),
    (
      FirstCodePoint: $0000FB00;
      LastCodePoint: $0000FB06
    ),
    (
      FirstCodePoint: $0000FB13;
      LastCodePoint: $0000FB17
    ),
    (
      FirstCodePoint: $0000FB1D;
      LastCodePoint: $0000FB28
    ),
    (
      FirstCodePoint: $0000FB2A;
      LastCodePoint: $0000FB36
    ),
    (
      FirstCodePoint: $0000FB38;
      LastCodePoint: $0000FB3C
    ),
    (
      FirstCodePoint: $0000FB3E;
      LastCodePoint: $0000FB3E
    ),
    (
      FirstCodePoint: $0000FB40;
      LastCodePoint: $0000FB41
    ),
    (
      FirstCodePoint: $0000FB43;
      LastCodePoint: $0000FB44
    ),
    (
      FirstCodePoint: $0000FB46;
      LastCodePoint: $0000FBB1
    ),
    (
      FirstCodePoint: $0000FBD3;
      LastCodePoint: $0000FD3D
    ),
    (
      FirstCodePoint: $0000FD50;
      LastCodePoint: $0000FD8F
    ),
    (
      FirstCodePoint: $0000FD92;
      LastCodePoint: $0000FDC7
    ),
    (
      FirstCodePoint: $0000FDF0;
      LastCodePoint: $0000FDFB
    ),
    (
      FirstCodePoint: $0000FE00;
      LastCodePoint: $0000FE0F
    ),
    (
      FirstCodePoint: $0000FE20;
      LastCodePoint: $0000FE2F
    ),
    (
      FirstCodePoint: $0000FE33;
      LastCodePoint: $0000FE34
    ),
    (
      FirstCodePoint: $0000FE4D;
      LastCodePoint: $0000FE4F
    ),
    (
      FirstCodePoint: $0000FE70;
      LastCodePoint: $0000FE74
    ),
    (
      FirstCodePoint: $0000FE76;
      LastCodePoint: $0000FEFC
    ),
    (
      FirstCodePoint: $0000FF10;
      LastCodePoint: $0000FF19
    ),
    (
      FirstCodePoint: $0000FF21;
      LastCodePoint: $0000FF3A
    ),
    (
      FirstCodePoint: $0000FF3F;
      LastCodePoint: $0000FF3F
    ),
    (
      FirstCodePoint: $0000FF41;
      LastCodePoint: $0000FF5A
    ),
    (
      FirstCodePoint: $0000FF66;
      LastCodePoint: $0000FFBE
    ),
    (
      FirstCodePoint: $0000FFC2;
      LastCodePoint: $0000FFC7
    ),
    (
      FirstCodePoint: $0000FFCA;
      LastCodePoint: $0000FFCF
    ),
    (
      FirstCodePoint: $0000FFD2;
      LastCodePoint: $0000FFD7
    ),
    (
      FirstCodePoint: $0000FFDA;
      LastCodePoint: $0000FFDC
    ),
    (
      FirstCodePoint: $00010000;
      LastCodePoint: $0001000B
    ),
    (
      FirstCodePoint: $0001000D;
      LastCodePoint: $00010026
    ),
    (
      FirstCodePoint: $00010028;
      LastCodePoint: $0001003A
    ),
    (
      FirstCodePoint: $0001003C;
      LastCodePoint: $0001003D
    ),
    (
      FirstCodePoint: $0001003F;
      LastCodePoint: $0001004D
    ),
    (
      FirstCodePoint: $00010050;
      LastCodePoint: $0001005D
    ),
    (
      FirstCodePoint: $00010080;
      LastCodePoint: $000100FA
    ),
    (
      FirstCodePoint: $00010140;
      LastCodePoint: $00010174
    ),
    (
      FirstCodePoint: $000101FD;
      LastCodePoint: $000101FD
    ),
    (
      FirstCodePoint: $00010280;
      LastCodePoint: $0001029C
    ),
    (
      FirstCodePoint: $000102A0;
      LastCodePoint: $000102D0
    ),
    (
      FirstCodePoint: $000102E0;
      LastCodePoint: $000102E0
    ),
    (
      FirstCodePoint: $00010300;
      LastCodePoint: $0001031F
    ),
    (
      FirstCodePoint: $0001032D;
      LastCodePoint: $0001034A
    ),
    (
      FirstCodePoint: $00010350;
      LastCodePoint: $0001037A
    ),
    (
      FirstCodePoint: $00010380;
      LastCodePoint: $0001039D
    ),
    (
      FirstCodePoint: $000103A0;
      LastCodePoint: $000103C3
    ),
    (
      FirstCodePoint: $000103C8;
      LastCodePoint: $000103CF
    ),
    (
      FirstCodePoint: $000103D1;
      LastCodePoint: $000103D5
    ),
    (
      FirstCodePoint: $00010400;
      LastCodePoint: $0001049D
    ),
    (
      FirstCodePoint: $000104A0;
      LastCodePoint: $000104A9
    ),
    (
      FirstCodePoint: $000104B0;
      LastCodePoint: $000104D3
    ),
    (
      FirstCodePoint: $000104D8;
      LastCodePoint: $000104FB
    ),
    (
      FirstCodePoint: $00010500;
      LastCodePoint: $00010527
    ),
    (
      FirstCodePoint: $00010530;
      LastCodePoint: $00010563
    ),
    (
      FirstCodePoint: $00010570;
      LastCodePoint: $0001057A
    ),
    (
      FirstCodePoint: $0001057C;
      LastCodePoint: $0001058A
    ),
    (
      FirstCodePoint: $0001058C;
      LastCodePoint: $00010592
    ),
    (
      FirstCodePoint: $00010594;
      LastCodePoint: $00010595
    ),
    (
      FirstCodePoint: $00010597;
      LastCodePoint: $000105A1
    ),
    (
      FirstCodePoint: $000105A3;
      LastCodePoint: $000105B1
    ),
    (
      FirstCodePoint: $000105B3;
      LastCodePoint: $000105B9
    ),
    (
      FirstCodePoint: $000105BB;
      LastCodePoint: $000105BC
    ),
    (
      FirstCodePoint: $00010600;
      LastCodePoint: $00010736
    ),
    (
      FirstCodePoint: $00010740;
      LastCodePoint: $00010755
    ),
    (
      FirstCodePoint: $00010760;
      LastCodePoint: $00010767
    ),
    (
      FirstCodePoint: $00010780;
      LastCodePoint: $00010785
    ),
    (
      FirstCodePoint: $00010787;
      LastCodePoint: $000107B0
    ),
    (
      FirstCodePoint: $000107B2;
      LastCodePoint: $000107BA
    ),
    (
      FirstCodePoint: $00010800;
      LastCodePoint: $00010805
    ),
    (
      FirstCodePoint: $00010808;
      LastCodePoint: $00010808
    ),
    (
      FirstCodePoint: $0001080A;
      LastCodePoint: $00010835
    ),
    (
      FirstCodePoint: $00010837;
      LastCodePoint: $00010838
    ),
    (
      FirstCodePoint: $0001083C;
      LastCodePoint: $0001083C
    ),
    (
      FirstCodePoint: $0001083F;
      LastCodePoint: $00010855
    ),
    (
      FirstCodePoint: $00010860;
      LastCodePoint: $00010876
    ),
    (
      FirstCodePoint: $00010880;
      LastCodePoint: $0001089E
    ),
    (
      FirstCodePoint: $000108E0;
      LastCodePoint: $000108F2
    ),
    (
      FirstCodePoint: $000108F4;
      LastCodePoint: $000108F5
    ),
    (
      FirstCodePoint: $00010900;
      LastCodePoint: $00010915
    ),
    (
      FirstCodePoint: $00010920;
      LastCodePoint: $00010939
    ),
    (
      FirstCodePoint: $00010980;
      LastCodePoint: $000109B7
    ),
    (
      FirstCodePoint: $000109BE;
      LastCodePoint: $000109BF
    ),
    (
      FirstCodePoint: $00010A00;
      LastCodePoint: $00010A03
    ),
    (
      FirstCodePoint: $00010A05;
      LastCodePoint: $00010A06
    ),
    (
      FirstCodePoint: $00010A0C;
      LastCodePoint: $00010A13
    ),
    (
      FirstCodePoint: $00010A15;
      LastCodePoint: $00010A17
    ),
    (
      FirstCodePoint: $00010A19;
      LastCodePoint: $00010A35
    ),
    (
      FirstCodePoint: $00010A38;
      LastCodePoint: $00010A3A
    ),
    (
      FirstCodePoint: $00010A3F;
      LastCodePoint: $00010A3F
    ),
    (
      FirstCodePoint: $00010A60;
      LastCodePoint: $00010A7C
    ),
    (
      FirstCodePoint: $00010A80;
      LastCodePoint: $00010A9C
    ),
    (
      FirstCodePoint: $00010AC0;
      LastCodePoint: $00010AC7
    ),
    (
      FirstCodePoint: $00010AC9;
      LastCodePoint: $00010AE6
    ),
    (
      FirstCodePoint: $00010B00;
      LastCodePoint: $00010B35
    ),
    (
      FirstCodePoint: $00010B40;
      LastCodePoint: $00010B55
    ),
    (
      FirstCodePoint: $00010B60;
      LastCodePoint: $00010B72
    ),
    (
      FirstCodePoint: $00010B80;
      LastCodePoint: $00010B91
    ),
    (
      FirstCodePoint: $00010C00;
      LastCodePoint: $00010C48
    ),
    (
      FirstCodePoint: $00010C80;
      LastCodePoint: $00010CB2
    ),
    (
      FirstCodePoint: $00010CC0;
      LastCodePoint: $00010CF2
    ),
    (
      FirstCodePoint: $00010D00;
      LastCodePoint: $00010D27
    ),
    (
      FirstCodePoint: $00010D30;
      LastCodePoint: $00010D39
    ),
    (
      FirstCodePoint: $00010E80;
      LastCodePoint: $00010EA9
    ),
    (
      FirstCodePoint: $00010EAB;
      LastCodePoint: $00010EAC
    ),
    (
      FirstCodePoint: $00010EB0;
      LastCodePoint: $00010EB1
    ),
    (
      FirstCodePoint: $00010EFD;
      LastCodePoint: $00010F1C
    ),
    (
      FirstCodePoint: $00010F27;
      LastCodePoint: $00010F27
    ),
    (
      FirstCodePoint: $00010F30;
      LastCodePoint: $00010F50
    ),
    (
      FirstCodePoint: $00010F70;
      LastCodePoint: $00010F85
    ),
    (
      FirstCodePoint: $00010FB0;
      LastCodePoint: $00010FC4
    ),
    (
      FirstCodePoint: $00010FE0;
      LastCodePoint: $00010FF6
    ),
    (
      FirstCodePoint: $00011000;
      LastCodePoint: $00011046
    ),
    (
      FirstCodePoint: $00011066;
      LastCodePoint: $00011075
    ),
    (
      FirstCodePoint: $0001107F;
      LastCodePoint: $000110BA
    ),
    (
      FirstCodePoint: $000110C2;
      LastCodePoint: $000110C2
    ),
    (
      FirstCodePoint: $000110D0;
      LastCodePoint: $000110E8
    ),
    (
      FirstCodePoint: $000110F0;
      LastCodePoint: $000110F9
    ),
    (
      FirstCodePoint: $00011100;
      LastCodePoint: $00011134
    ),
    (
      FirstCodePoint: $00011136;
      LastCodePoint: $0001113F
    ),
    (
      FirstCodePoint: $00011144;
      LastCodePoint: $00011147
    ),
    (
      FirstCodePoint: $00011150;
      LastCodePoint: $00011173
    ),
    (
      FirstCodePoint: $00011176;
      LastCodePoint: $00011176
    ),
    (
      FirstCodePoint: $00011180;
      LastCodePoint: $000111C4
    ),
    (
      FirstCodePoint: $000111C9;
      LastCodePoint: $000111CC
    ),
    (
      FirstCodePoint: $000111CE;
      LastCodePoint: $000111DA
    ),
    (
      FirstCodePoint: $000111DC;
      LastCodePoint: $000111DC
    ),
    (
      FirstCodePoint: $00011200;
      LastCodePoint: $00011211
    ),
    (
      FirstCodePoint: $00011213;
      LastCodePoint: $00011237
    ),
    (
      FirstCodePoint: $0001123E;
      LastCodePoint: $00011241
    ),
    (
      FirstCodePoint: $00011280;
      LastCodePoint: $00011286
    ),
    (
      FirstCodePoint: $00011288;
      LastCodePoint: $00011288
    ),
    (
      FirstCodePoint: $0001128A;
      LastCodePoint: $0001128D
    ),
    (
      FirstCodePoint: $0001128F;
      LastCodePoint: $0001129D
    ),
    (
      FirstCodePoint: $0001129F;
      LastCodePoint: $000112A8
    ),
    (
      FirstCodePoint: $000112B0;
      LastCodePoint: $000112EA
    ),
    (
      FirstCodePoint: $000112F0;
      LastCodePoint: $000112F9
    ),
    (
      FirstCodePoint: $00011300;
      LastCodePoint: $00011303
    ),
    (
      FirstCodePoint: $00011305;
      LastCodePoint: $0001130C
    ),
    (
      FirstCodePoint: $0001130F;
      LastCodePoint: $00011310
    ),
    (
      FirstCodePoint: $00011313;
      LastCodePoint: $00011328
    ),
    (
      FirstCodePoint: $0001132A;
      LastCodePoint: $00011330
    ),
    (
      FirstCodePoint: $00011332;
      LastCodePoint: $00011333
    ),
    (
      FirstCodePoint: $00011335;
      LastCodePoint: $00011339
    ),
    (
      FirstCodePoint: $0001133B;
      LastCodePoint: $00011344
    ),
    (
      FirstCodePoint: $00011347;
      LastCodePoint: $00011348
    ),
    (
      FirstCodePoint: $0001134B;
      LastCodePoint: $0001134D
    ),
    (
      FirstCodePoint: $00011350;
      LastCodePoint: $00011350
    ),
    (
      FirstCodePoint: $00011357;
      LastCodePoint: $00011357
    ),
    (
      FirstCodePoint: $0001135D;
      LastCodePoint: $00011363
    ),
    (
      FirstCodePoint: $00011366;
      LastCodePoint: $0001136C
    ),
    (
      FirstCodePoint: $00011370;
      LastCodePoint: $00011374
    ),
    (
      FirstCodePoint: $00011400;
      LastCodePoint: $0001144A
    ),
    (
      FirstCodePoint: $00011450;
      LastCodePoint: $00011459
    ),
    (
      FirstCodePoint: $0001145E;
      LastCodePoint: $00011461
    ),
    (
      FirstCodePoint: $00011480;
      LastCodePoint: $000114C5
    ),
    (
      FirstCodePoint: $000114C7;
      LastCodePoint: $000114C7
    ),
    (
      FirstCodePoint: $000114D0;
      LastCodePoint: $000114D9
    ),
    (
      FirstCodePoint: $00011580;
      LastCodePoint: $000115B5
    ),
    (
      FirstCodePoint: $000115B8;
      LastCodePoint: $000115C0
    ),
    (
      FirstCodePoint: $000115D8;
      LastCodePoint: $000115DD
    ),
    (
      FirstCodePoint: $00011600;
      LastCodePoint: $00011640
    ),
    (
      FirstCodePoint: $00011644;
      LastCodePoint: $00011644
    ),
    (
      FirstCodePoint: $00011650;
      LastCodePoint: $00011659
    ),
    (
      FirstCodePoint: $00011680;
      LastCodePoint: $000116B8
    ),
    (
      FirstCodePoint: $000116C0;
      LastCodePoint: $000116C9
    ),
    (
      FirstCodePoint: $00011700;
      LastCodePoint: $0001171A
    ),
    (
      FirstCodePoint: $0001171D;
      LastCodePoint: $0001172B
    ),
    (
      FirstCodePoint: $00011730;
      LastCodePoint: $00011739
    ),
    (
      FirstCodePoint: $00011740;
      LastCodePoint: $00011746
    ),
    (
      FirstCodePoint: $00011800;
      LastCodePoint: $0001183A
    ),
    (
      FirstCodePoint: $000118A0;
      LastCodePoint: $000118E9
    ),
    (
      FirstCodePoint: $000118FF;
      LastCodePoint: $00011906
    ),
    (
      FirstCodePoint: $00011909;
      LastCodePoint: $00011909
    ),
    (
      FirstCodePoint: $0001190C;
      LastCodePoint: $00011913
    ),
    (
      FirstCodePoint: $00011915;
      LastCodePoint: $00011916
    ),
    (
      FirstCodePoint: $00011918;
      LastCodePoint: $00011935
    ),
    (
      FirstCodePoint: $00011937;
      LastCodePoint: $00011938
    ),
    (
      FirstCodePoint: $0001193B;
      LastCodePoint: $00011943
    ),
    (
      FirstCodePoint: $00011950;
      LastCodePoint: $00011959
    ),
    (
      FirstCodePoint: $000119A0;
      LastCodePoint: $000119A7
    ),
    (
      FirstCodePoint: $000119AA;
      LastCodePoint: $000119D7
    ),
    (
      FirstCodePoint: $000119DA;
      LastCodePoint: $000119E1
    ),
    (
      FirstCodePoint: $000119E3;
      LastCodePoint: $000119E4
    ),
    (
      FirstCodePoint: $00011A00;
      LastCodePoint: $00011A3E
    ),
    (
      FirstCodePoint: $00011A47;
      LastCodePoint: $00011A47
    ),
    (
      FirstCodePoint: $00011A50;
      LastCodePoint: $00011A99
    ),
    (
      FirstCodePoint: $00011A9D;
      LastCodePoint: $00011A9D
    ),
    (
      FirstCodePoint: $00011AB0;
      LastCodePoint: $00011AF8
    ),
    (
      FirstCodePoint: $00011C00;
      LastCodePoint: $00011C08
    ),
    (
      FirstCodePoint: $00011C0A;
      LastCodePoint: $00011C36
    ),
    (
      FirstCodePoint: $00011C38;
      LastCodePoint: $00011C40
    ),
    (
      FirstCodePoint: $00011C50;
      LastCodePoint: $00011C59
    ),
    (
      FirstCodePoint: $00011C72;
      LastCodePoint: $00011C8F
    ),
    (
      FirstCodePoint: $00011C92;
      LastCodePoint: $00011CA7
    ),
    (
      FirstCodePoint: $00011CA9;
      LastCodePoint: $00011CB6
    ),
    (
      FirstCodePoint: $00011D00;
      LastCodePoint: $00011D06
    ),
    (
      FirstCodePoint: $00011D08;
      LastCodePoint: $00011D09
    ),
    (
      FirstCodePoint: $00011D0B;
      LastCodePoint: $00011D36
    ),
    (
      FirstCodePoint: $00011D3A;
      LastCodePoint: $00011D3A
    ),
    (
      FirstCodePoint: $00011D3C;
      LastCodePoint: $00011D3D
    ),
    (
      FirstCodePoint: $00011D3F;
      LastCodePoint: $00011D47
    ),
    (
      FirstCodePoint: $00011D50;
      LastCodePoint: $00011D59
    ),
    (
      FirstCodePoint: $00011D60;
      LastCodePoint: $00011D65
    ),
    (
      FirstCodePoint: $00011D67;
      LastCodePoint: $00011D68
    ),
    (
      FirstCodePoint: $00011D6A;
      LastCodePoint: $00011D8E
    ),
    (
      FirstCodePoint: $00011D90;
      LastCodePoint: $00011D91
    ),
    (
      FirstCodePoint: $00011D93;
      LastCodePoint: $00011D98
    ),
    (
      FirstCodePoint: $00011DA0;
      LastCodePoint: $00011DA9
    ),
    (
      FirstCodePoint: $00011EE0;
      LastCodePoint: $00011EF6
    ),
    (
      FirstCodePoint: $00011F00;
      LastCodePoint: $00011F10
    ),
    (
      FirstCodePoint: $00011F12;
      LastCodePoint: $00011F3A
    ),
    (
      FirstCodePoint: $00011F3E;
      LastCodePoint: $00011F42
    ),
    (
      FirstCodePoint: $00011F50;
      LastCodePoint: $00011F59
    ),
    (
      FirstCodePoint: $00011FB0;
      LastCodePoint: $00011FB0
    ),
    (
      FirstCodePoint: $00012000;
      LastCodePoint: $00012399
    ),
    (
      FirstCodePoint: $00012400;
      LastCodePoint: $0001246E
    ),
    (
      FirstCodePoint: $00012480;
      LastCodePoint: $00012543
    ),
    (
      FirstCodePoint: $00012F90;
      LastCodePoint: $00012FF0
    ),
    (
      FirstCodePoint: $00013000;
      LastCodePoint: $0001342F
    ),
    (
      FirstCodePoint: $00013440;
      LastCodePoint: $00013455
    ),
    (
      FirstCodePoint: $00014400;
      LastCodePoint: $00014646
    ),
    (
      FirstCodePoint: $00016800;
      LastCodePoint: $00016A38
    ),
    (
      FirstCodePoint: $00016A40;
      LastCodePoint: $00016A5E
    ),
    (
      FirstCodePoint: $00016A60;
      LastCodePoint: $00016A69
    ),
    (
      FirstCodePoint: $00016A70;
      LastCodePoint: $00016ABE
    ),
    (
      FirstCodePoint: $00016AC0;
      LastCodePoint: $00016AC9
    ),
    (
      FirstCodePoint: $00016AD0;
      LastCodePoint: $00016AED
    ),
    (
      FirstCodePoint: $00016AF0;
      LastCodePoint: $00016AF4
    ),
    (
      FirstCodePoint: $00016B00;
      LastCodePoint: $00016B36
    ),
    (
      FirstCodePoint: $00016B40;
      LastCodePoint: $00016B43
    ),
    (
      FirstCodePoint: $00016B50;
      LastCodePoint: $00016B59
    ),
    (
      FirstCodePoint: $00016B63;
      LastCodePoint: $00016B77
    ),
    (
      FirstCodePoint: $00016B7D;
      LastCodePoint: $00016B8F
    ),
    (
      FirstCodePoint: $00016E40;
      LastCodePoint: $00016E7F
    ),
    (
      FirstCodePoint: $00016F00;
      LastCodePoint: $00016F4A
    ),
    (
      FirstCodePoint: $00016F4F;
      LastCodePoint: $00016F87
    ),
    (
      FirstCodePoint: $00016F8F;
      LastCodePoint: $00016F9F
    ),
    (
      FirstCodePoint: $00016FE0;
      LastCodePoint: $00016FE1
    ),
    (
      FirstCodePoint: $00016FE3;
      LastCodePoint: $00016FE4
    ),
    (
      FirstCodePoint: $00016FF0;
      LastCodePoint: $00016FF1
    ),
    (
      FirstCodePoint: $00017000;
      LastCodePoint: $000187F7
    ),
    (
      FirstCodePoint: $00018800;
      LastCodePoint: $00018CD5
    ),
    (
      FirstCodePoint: $00018D00;
      LastCodePoint: $00018D08
    ),
    (
      FirstCodePoint: $0001AFF0;
      LastCodePoint: $0001AFF3
    ),
    (
      FirstCodePoint: $0001AFF5;
      LastCodePoint: $0001AFFB
    ),
    (
      FirstCodePoint: $0001AFFD;
      LastCodePoint: $0001AFFE
    ),
    (
      FirstCodePoint: $0001B000;
      LastCodePoint: $0001B122
    ),
    (
      FirstCodePoint: $0001B132;
      LastCodePoint: $0001B132
    ),
    (
      FirstCodePoint: $0001B150;
      LastCodePoint: $0001B152
    ),
    (
      FirstCodePoint: $0001B155;
      LastCodePoint: $0001B155
    ),
    (
      FirstCodePoint: $0001B164;
      LastCodePoint: $0001B167
    ),
    (
      FirstCodePoint: $0001B170;
      LastCodePoint: $0001B2FB
    ),
    (
      FirstCodePoint: $0001BC00;
      LastCodePoint: $0001BC6A
    ),
    (
      FirstCodePoint: $0001BC70;
      LastCodePoint: $0001BC7C
    ),
    (
      FirstCodePoint: $0001BC80;
      LastCodePoint: $0001BC88
    ),
    (
      FirstCodePoint: $0001BC90;
      LastCodePoint: $0001BC99
    ),
    (
      FirstCodePoint: $0001BC9D;
      LastCodePoint: $0001BC9E
    ),
    (
      FirstCodePoint: $0001CF00;
      LastCodePoint: $0001CF2D
    ),
    (
      FirstCodePoint: $0001CF30;
      LastCodePoint: $0001CF46
    ),
    (
      FirstCodePoint: $0001D165;
      LastCodePoint: $0001D169
    ),
    (
      FirstCodePoint: $0001D16D;
      LastCodePoint: $0001D172
    ),
    (
      FirstCodePoint: $0001D17B;
      LastCodePoint: $0001D182
    ),
    (
      FirstCodePoint: $0001D185;
      LastCodePoint: $0001D18B
    ),
    (
      FirstCodePoint: $0001D1AA;
      LastCodePoint: $0001D1AD
    ),
    (
      FirstCodePoint: $0001D242;
      LastCodePoint: $0001D244
    ),
    (
      FirstCodePoint: $0001D400;
      LastCodePoint: $0001D454
    ),
    (
      FirstCodePoint: $0001D456;
      LastCodePoint: $0001D49C
    ),
    (
      FirstCodePoint: $0001D49E;
      LastCodePoint: $0001D49F
    ),
    (
      FirstCodePoint: $0001D4A2;
      LastCodePoint: $0001D4A2
    ),
    (
      FirstCodePoint: $0001D4A5;
      LastCodePoint: $0001D4A6
    ),
    (
      FirstCodePoint: $0001D4A9;
      LastCodePoint: $0001D4AC
    ),
    (
      FirstCodePoint: $0001D4AE;
      LastCodePoint: $0001D4B9
    ),
    (
      FirstCodePoint: $0001D4BB;
      LastCodePoint: $0001D4BB
    ),
    (
      FirstCodePoint: $0001D4BD;
      LastCodePoint: $0001D4C3
    ),
    (
      FirstCodePoint: $0001D4C5;
      LastCodePoint: $0001D505
    ),
    (
      FirstCodePoint: $0001D507;
      LastCodePoint: $0001D50A
    ),
    (
      FirstCodePoint: $0001D50D;
      LastCodePoint: $0001D514
    ),
    (
      FirstCodePoint: $0001D516;
      LastCodePoint: $0001D51C
    ),
    (
      FirstCodePoint: $0001D51E;
      LastCodePoint: $0001D539
    ),
    (
      FirstCodePoint: $0001D53B;
      LastCodePoint: $0001D53E
    ),
    (
      FirstCodePoint: $0001D540;
      LastCodePoint: $0001D544
    ),
    (
      FirstCodePoint: $0001D546;
      LastCodePoint: $0001D546
    ),
    (
      FirstCodePoint: $0001D54A;
      LastCodePoint: $0001D550
    ),
    (
      FirstCodePoint: $0001D552;
      LastCodePoint: $0001D6A5
    ),
    (
      FirstCodePoint: $0001D6A8;
      LastCodePoint: $0001D6C0
    ),
    (
      FirstCodePoint: $0001D6C2;
      LastCodePoint: $0001D6DA
    ),
    (
      FirstCodePoint: $0001D6DC;
      LastCodePoint: $0001D6FA
    ),
    (
      FirstCodePoint: $0001D6FC;
      LastCodePoint: $0001D714
    ),
    (
      FirstCodePoint: $0001D716;
      LastCodePoint: $0001D734
    ),
    (
      FirstCodePoint: $0001D736;
      LastCodePoint: $0001D74E
    ),
    (
      FirstCodePoint: $0001D750;
      LastCodePoint: $0001D76E
    ),
    (
      FirstCodePoint: $0001D770;
      LastCodePoint: $0001D788
    ),
    (
      FirstCodePoint: $0001D78A;
      LastCodePoint: $0001D7A8
    ),
    (
      FirstCodePoint: $0001D7AA;
      LastCodePoint: $0001D7C2
    ),
    (
      FirstCodePoint: $0001D7C4;
      LastCodePoint: $0001D7CB
    ),
    (
      FirstCodePoint: $0001D7CE;
      LastCodePoint: $0001D7FF
    ),
    (
      FirstCodePoint: $0001DA00;
      LastCodePoint: $0001DA36
    ),
    (
      FirstCodePoint: $0001DA3B;
      LastCodePoint: $0001DA6C
    ),
    (
      FirstCodePoint: $0001DA75;
      LastCodePoint: $0001DA75
    ),
    (
      FirstCodePoint: $0001DA84;
      LastCodePoint: $0001DA84
    ),
    (
      FirstCodePoint: $0001DA9B;
      LastCodePoint: $0001DA9F
    ),
    (
      FirstCodePoint: $0001DAA1;
      LastCodePoint: $0001DAAF
    ),
    (
      FirstCodePoint: $0001DF00;
      LastCodePoint: $0001DF1E
    ),
    (
      FirstCodePoint: $0001DF25;
      LastCodePoint: $0001DF2A
    ),
    (
      FirstCodePoint: $0001E000;
      LastCodePoint: $0001E006
    ),
    (
      FirstCodePoint: $0001E008;
      LastCodePoint: $0001E018
    ),
    (
      FirstCodePoint: $0001E01B;
      LastCodePoint: $0001E021
    ),
    (
      FirstCodePoint: $0001E023;
      LastCodePoint: $0001E024
    ),
    (
      FirstCodePoint: $0001E026;
      LastCodePoint: $0001E02A
    ),
    (
      FirstCodePoint: $0001E030;
      LastCodePoint: $0001E06D
    ),
    (
      FirstCodePoint: $0001E08F;
      LastCodePoint: $0001E08F
    ),
    (
      FirstCodePoint: $0001E100;
      LastCodePoint: $0001E12C
    ),
    (
      FirstCodePoint: $0001E130;
      LastCodePoint: $0001E13D
    ),
    (
      FirstCodePoint: $0001E140;
      LastCodePoint: $0001E149
    ),
    (
      FirstCodePoint: $0001E14E;
      LastCodePoint: $0001E14E
    ),
    (
      FirstCodePoint: $0001E290;
      LastCodePoint: $0001E2AE
    ),
    (
      FirstCodePoint: $0001E2C0;
      LastCodePoint: $0001E2F9
    ),
    (
      FirstCodePoint: $0001E4D0;
      LastCodePoint: $0001E4F9
    ),
    (
      FirstCodePoint: $0001E7E0;
      LastCodePoint: $0001E7E6
    ),
    (
      FirstCodePoint: $0001E7E8;
      LastCodePoint: $0001E7EB
    ),
    (
      FirstCodePoint: $0001E7ED;
      LastCodePoint: $0001E7EE
    ),
    (
      FirstCodePoint: $0001E7F0;
      LastCodePoint: $0001E7FE
    ),
    (
      FirstCodePoint: $0001E800;
      LastCodePoint: $0001E8C4
    ),
    (
      FirstCodePoint: $0001E8D0;
      LastCodePoint: $0001E8D6
    ),
    (
      FirstCodePoint: $0001E900;
      LastCodePoint: $0001E94B
    ),
    (
      FirstCodePoint: $0001E950;
      LastCodePoint: $0001E959
    ),
    (
      FirstCodePoint: $0001EE00;
      LastCodePoint: $0001EE03
    ),
    (
      FirstCodePoint: $0001EE05;
      LastCodePoint: $0001EE1F
    ),
    (
      FirstCodePoint: $0001EE21;
      LastCodePoint: $0001EE22
    ),
    (
      FirstCodePoint: $0001EE24;
      LastCodePoint: $0001EE24
    ),
    (
      FirstCodePoint: $0001EE27;
      LastCodePoint: $0001EE27
    ),
    (
      FirstCodePoint: $0001EE29;
      LastCodePoint: $0001EE32
    ),
    (
      FirstCodePoint: $0001EE34;
      LastCodePoint: $0001EE37
    ),
    (
      FirstCodePoint: $0001EE39;
      LastCodePoint: $0001EE39
    ),
    (
      FirstCodePoint: $0001EE3B;
      LastCodePoint: $0001EE3B
    ),
    (
      FirstCodePoint: $0001EE42;
      LastCodePoint: $0001EE42
    ),
    (
      FirstCodePoint: $0001EE47;
      LastCodePoint: $0001EE47
    ),
    (
      FirstCodePoint: $0001EE49;
      LastCodePoint: $0001EE49
    ),
    (
      FirstCodePoint: $0001EE4B;
      LastCodePoint: $0001EE4B
    ),
    (
      FirstCodePoint: $0001EE4D;
      LastCodePoint: $0001EE4F
    ),
    (
      FirstCodePoint: $0001EE51;
      LastCodePoint: $0001EE52
    ),
    (
      FirstCodePoint: $0001EE54;
      LastCodePoint: $0001EE54
    ),
    (
      FirstCodePoint: $0001EE57;
      LastCodePoint: $0001EE57
    ),
    (
      FirstCodePoint: $0001EE59;
      LastCodePoint: $0001EE59
    ),
    (
      FirstCodePoint: $0001EE5B;
      LastCodePoint: $0001EE5B
    ),
    (
      FirstCodePoint: $0001EE5D;
      LastCodePoint: $0001EE5D
    ),
    (
      FirstCodePoint: $0001EE5F;
      LastCodePoint: $0001EE5F
    ),
    (
      FirstCodePoint: $0001EE61;
      LastCodePoint: $0001EE62
    ),
    (
      FirstCodePoint: $0001EE64;
      LastCodePoint: $0001EE64
    ),
    (
      FirstCodePoint: $0001EE67;
      LastCodePoint: $0001EE6A
    ),
    (
      FirstCodePoint: $0001EE6C;
      LastCodePoint: $0001EE72
    ),
    (
      FirstCodePoint: $0001EE74;
      LastCodePoint: $0001EE77
    ),
    (
      FirstCodePoint: $0001EE79;
      LastCodePoint: $0001EE7C
    ),
    (
      FirstCodePoint: $0001EE7E;
      LastCodePoint: $0001EE7E
    ),
    (
      FirstCodePoint: $0001EE80;
      LastCodePoint: $0001EE89
    ),
    (
      FirstCodePoint: $0001EE8B;
      LastCodePoint: $0001EE9B
    ),
    (
      FirstCodePoint: $0001EEA1;
      LastCodePoint: $0001EEA3
    ),
    (
      FirstCodePoint: $0001EEA5;
      LastCodePoint: $0001EEA9
    ),
    (
      FirstCodePoint: $0001EEAB;
      LastCodePoint: $0001EEBB
    ),
    (
      FirstCodePoint: $0001FBF0;
      LastCodePoint: $0001FBF9
    ),
    (
      FirstCodePoint: $00020000;
      LastCodePoint: $0002A6DF
    ),
    (
      FirstCodePoint: $0002A700;
      LastCodePoint: $0002B739
    ),
    (
      FirstCodePoint: $0002B740;
      LastCodePoint: $0002B81D
    ),
    (
      FirstCodePoint: $0002B820;
      LastCodePoint: $0002CEA1
    ),
    (
      FirstCodePoint: $0002CEB0;
      LastCodePoint: $0002EBE0
    ),
    (
      FirstCodePoint: $0002EBF0;
      LastCodePoint: $0002EE5D
    ),
    (
      FirstCodePoint: $0002F800;
      LastCodePoint: $0002FA1D
    ),
    (
      FirstCodePoint: $00030000;
      LastCodePoint: $0003134A
    ),
    (
      FirstCodePoint: $00031350;
      LastCodePoint: $000323AF
    ),
    (
      FirstCodePoint: $000E0100;
      LastCodePoint: $000E01EF
    )
  );

  UNICODE_WHITESPACE_RANGES: array[0..9] of TUnicodeRange = (
    (
      FirstCodePoint: $00000009;
      LastCodePoint: $0000000D
    ),
    (
      FirstCodePoint: $0000001C;
      LastCodePoint: $00000020
    ),
    (
      FirstCodePoint: $00000085;
      LastCodePoint: $00000085
    ),
    (
      FirstCodePoint: $000000A0;
      LastCodePoint: $000000A0
    ),
    (
      FirstCodePoint: $00001680;
      LastCodePoint: $00001680
    ),
    (
      FirstCodePoint: $00002000;
      LastCodePoint: $0000200A
    ),
    (
      FirstCodePoint: $00002028;
      LastCodePoint: $00002029
    ),
    (
      FirstCodePoint: $0000202F;
      LastCodePoint: $0000202F
    ),
    (
      FirstCodePoint: $0000205F;
      LastCodePoint: $0000205F
    ),
    (
      FirstCodePoint: $00003000;
      LastCodePoint: $00003000
    )
  );

  UNICODE_SIMPLE_LOWER_MAP: array[0..1431] of TUnicodeMapping = (
    (
      SourceCodePoint: $00000041;
      TargetCodePoint: $00000061
    ),
    (
      SourceCodePoint: $00000042;
      TargetCodePoint: $00000062
    ),
    (
      SourceCodePoint: $00000043;
      TargetCodePoint: $00000063
    ),
    (
      SourceCodePoint: $00000044;
      TargetCodePoint: $00000064
    ),
    (
      SourceCodePoint: $00000045;
      TargetCodePoint: $00000065
    ),
    (
      SourceCodePoint: $00000046;
      TargetCodePoint: $00000066
    ),
    (
      SourceCodePoint: $00000047;
      TargetCodePoint: $00000067
    ),
    (
      SourceCodePoint: $00000048;
      TargetCodePoint: $00000068
    ),
    (
      SourceCodePoint: $00000049;
      TargetCodePoint: $00000069
    ),
    (
      SourceCodePoint: $0000004A;
      TargetCodePoint: $0000006A
    ),
    (
      SourceCodePoint: $0000004B;
      TargetCodePoint: $0000006B
    ),
    (
      SourceCodePoint: $0000004C;
      TargetCodePoint: $0000006C
    ),
    (
      SourceCodePoint: $0000004D;
      TargetCodePoint: $0000006D
    ),
    (
      SourceCodePoint: $0000004E;
      TargetCodePoint: $0000006E
    ),
    (
      SourceCodePoint: $0000004F;
      TargetCodePoint: $0000006F
    ),
    (
      SourceCodePoint: $00000050;
      TargetCodePoint: $00000070
    ),
    (
      SourceCodePoint: $00000051;
      TargetCodePoint: $00000071
    ),
    (
      SourceCodePoint: $00000052;
      TargetCodePoint: $00000072
    ),
    (
      SourceCodePoint: $00000053;
      TargetCodePoint: $00000073
    ),
    (
      SourceCodePoint: $00000054;
      TargetCodePoint: $00000074
    ),
    (
      SourceCodePoint: $00000055;
      TargetCodePoint: $00000075
    ),
    (
      SourceCodePoint: $00000056;
      TargetCodePoint: $00000076
    ),
    (
      SourceCodePoint: $00000057;
      TargetCodePoint: $00000077
    ),
    (
      SourceCodePoint: $00000058;
      TargetCodePoint: $00000078
    ),
    (
      SourceCodePoint: $00000059;
      TargetCodePoint: $00000079
    ),
    (
      SourceCodePoint: $0000005A;
      TargetCodePoint: $0000007A
    ),
    (
      SourceCodePoint: $000000C0;
      TargetCodePoint: $000000E0
    ),
    (
      SourceCodePoint: $000000C1;
      TargetCodePoint: $000000E1
    ),
    (
      SourceCodePoint: $000000C2;
      TargetCodePoint: $000000E2
    ),
    (
      SourceCodePoint: $000000C3;
      TargetCodePoint: $000000E3
    ),
    (
      SourceCodePoint: $000000C4;
      TargetCodePoint: $000000E4
    ),
    (
      SourceCodePoint: $000000C5;
      TargetCodePoint: $000000E5
    ),
    (
      SourceCodePoint: $000000C6;
      TargetCodePoint: $000000E6
    ),
    (
      SourceCodePoint: $000000C7;
      TargetCodePoint: $000000E7
    ),
    (
      SourceCodePoint: $000000C8;
      TargetCodePoint: $000000E8
    ),
    (
      SourceCodePoint: $000000C9;
      TargetCodePoint: $000000E9
    ),
    (
      SourceCodePoint: $000000CA;
      TargetCodePoint: $000000EA
    ),
    (
      SourceCodePoint: $000000CB;
      TargetCodePoint: $000000EB
    ),
    (
      SourceCodePoint: $000000CC;
      TargetCodePoint: $000000EC
    ),
    (
      SourceCodePoint: $000000CD;
      TargetCodePoint: $000000ED
    ),
    (
      SourceCodePoint: $000000CE;
      TargetCodePoint: $000000EE
    ),
    (
      SourceCodePoint: $000000CF;
      TargetCodePoint: $000000EF
    ),
    (
      SourceCodePoint: $000000D0;
      TargetCodePoint: $000000F0
    ),
    (
      SourceCodePoint: $000000D1;
      TargetCodePoint: $000000F1
    ),
    (
      SourceCodePoint: $000000D2;
      TargetCodePoint: $000000F2
    ),
    (
      SourceCodePoint: $000000D3;
      TargetCodePoint: $000000F3
    ),
    (
      SourceCodePoint: $000000D4;
      TargetCodePoint: $000000F4
    ),
    (
      SourceCodePoint: $000000D5;
      TargetCodePoint: $000000F5
    ),
    (
      SourceCodePoint: $000000D6;
      TargetCodePoint: $000000F6
    ),
    (
      SourceCodePoint: $000000D8;
      TargetCodePoint: $000000F8
    ),
    (
      SourceCodePoint: $000000D9;
      TargetCodePoint: $000000F9
    ),
    (
      SourceCodePoint: $000000DA;
      TargetCodePoint: $000000FA
    ),
    (
      SourceCodePoint: $000000DB;
      TargetCodePoint: $000000FB
    ),
    (
      SourceCodePoint: $000000DC;
      TargetCodePoint: $000000FC
    ),
    (
      SourceCodePoint: $000000DD;
      TargetCodePoint: $000000FD
    ),
    (
      SourceCodePoint: $000000DE;
      TargetCodePoint: $000000FE
    ),
    (
      SourceCodePoint: $00000100;
      TargetCodePoint: $00000101
    ),
    (
      SourceCodePoint: $00000102;
      TargetCodePoint: $00000103
    ),
    (
      SourceCodePoint: $00000104;
      TargetCodePoint: $00000105
    ),
    (
      SourceCodePoint: $00000106;
      TargetCodePoint: $00000107
    ),
    (
      SourceCodePoint: $00000108;
      TargetCodePoint: $00000109
    ),
    (
      SourceCodePoint: $0000010A;
      TargetCodePoint: $0000010B
    ),
    (
      SourceCodePoint: $0000010C;
      TargetCodePoint: $0000010D
    ),
    (
      SourceCodePoint: $0000010E;
      TargetCodePoint: $0000010F
    ),
    (
      SourceCodePoint: $00000110;
      TargetCodePoint: $00000111
    ),
    (
      SourceCodePoint: $00000112;
      TargetCodePoint: $00000113
    ),
    (
      SourceCodePoint: $00000114;
      TargetCodePoint: $00000115
    ),
    (
      SourceCodePoint: $00000116;
      TargetCodePoint: $00000117
    ),
    (
      SourceCodePoint: $00000118;
      TargetCodePoint: $00000119
    ),
    (
      SourceCodePoint: $0000011A;
      TargetCodePoint: $0000011B
    ),
    (
      SourceCodePoint: $0000011C;
      TargetCodePoint: $0000011D
    ),
    (
      SourceCodePoint: $0000011E;
      TargetCodePoint: $0000011F
    ),
    (
      SourceCodePoint: $00000120;
      TargetCodePoint: $00000121
    ),
    (
      SourceCodePoint: $00000122;
      TargetCodePoint: $00000123
    ),
    (
      SourceCodePoint: $00000124;
      TargetCodePoint: $00000125
    ),
    (
      SourceCodePoint: $00000126;
      TargetCodePoint: $00000127
    ),
    (
      SourceCodePoint: $00000128;
      TargetCodePoint: $00000129
    ),
    (
      SourceCodePoint: $0000012A;
      TargetCodePoint: $0000012B
    ),
    (
      SourceCodePoint: $0000012C;
      TargetCodePoint: $0000012D
    ),
    (
      SourceCodePoint: $0000012E;
      TargetCodePoint: $0000012F
    ),
    (
      SourceCodePoint: $00000132;
      TargetCodePoint: $00000133
    ),
    (
      SourceCodePoint: $00000134;
      TargetCodePoint: $00000135
    ),
    (
      SourceCodePoint: $00000136;
      TargetCodePoint: $00000137
    ),
    (
      SourceCodePoint: $00000139;
      TargetCodePoint: $0000013A
    ),
    (
      SourceCodePoint: $0000013B;
      TargetCodePoint: $0000013C
    ),
    (
      SourceCodePoint: $0000013D;
      TargetCodePoint: $0000013E
    ),
    (
      SourceCodePoint: $0000013F;
      TargetCodePoint: $00000140
    ),
    (
      SourceCodePoint: $00000141;
      TargetCodePoint: $00000142
    ),
    (
      SourceCodePoint: $00000143;
      TargetCodePoint: $00000144
    ),
    (
      SourceCodePoint: $00000145;
      TargetCodePoint: $00000146
    ),
    (
      SourceCodePoint: $00000147;
      TargetCodePoint: $00000148
    ),
    (
      SourceCodePoint: $0000014A;
      TargetCodePoint: $0000014B
    ),
    (
      SourceCodePoint: $0000014C;
      TargetCodePoint: $0000014D
    ),
    (
      SourceCodePoint: $0000014E;
      TargetCodePoint: $0000014F
    ),
    (
      SourceCodePoint: $00000150;
      TargetCodePoint: $00000151
    ),
    (
      SourceCodePoint: $00000152;
      TargetCodePoint: $00000153
    ),
    (
      SourceCodePoint: $00000154;
      TargetCodePoint: $00000155
    ),
    (
      SourceCodePoint: $00000156;
      TargetCodePoint: $00000157
    ),
    (
      SourceCodePoint: $00000158;
      TargetCodePoint: $00000159
    ),
    (
      SourceCodePoint: $0000015A;
      TargetCodePoint: $0000015B
    ),
    (
      SourceCodePoint: $0000015C;
      TargetCodePoint: $0000015D
    ),
    (
      SourceCodePoint: $0000015E;
      TargetCodePoint: $0000015F
    ),
    (
      SourceCodePoint: $00000160;
      TargetCodePoint: $00000161
    ),
    (
      SourceCodePoint: $00000162;
      TargetCodePoint: $00000163
    ),
    (
      SourceCodePoint: $00000164;
      TargetCodePoint: $00000165
    ),
    (
      SourceCodePoint: $00000166;
      TargetCodePoint: $00000167
    ),
    (
      SourceCodePoint: $00000168;
      TargetCodePoint: $00000169
    ),
    (
      SourceCodePoint: $0000016A;
      TargetCodePoint: $0000016B
    ),
    (
      SourceCodePoint: $0000016C;
      TargetCodePoint: $0000016D
    ),
    (
      SourceCodePoint: $0000016E;
      TargetCodePoint: $0000016F
    ),
    (
      SourceCodePoint: $00000170;
      TargetCodePoint: $00000171
    ),
    (
      SourceCodePoint: $00000172;
      TargetCodePoint: $00000173
    ),
    (
      SourceCodePoint: $00000174;
      TargetCodePoint: $00000175
    ),
    (
      SourceCodePoint: $00000176;
      TargetCodePoint: $00000177
    ),
    (
      SourceCodePoint: $00000178;
      TargetCodePoint: $000000FF
    ),
    (
      SourceCodePoint: $00000179;
      TargetCodePoint: $0000017A
    ),
    (
      SourceCodePoint: $0000017B;
      TargetCodePoint: $0000017C
    ),
    (
      SourceCodePoint: $0000017D;
      TargetCodePoint: $0000017E
    ),
    (
      SourceCodePoint: $00000181;
      TargetCodePoint: $00000253
    ),
    (
      SourceCodePoint: $00000182;
      TargetCodePoint: $00000183
    ),
    (
      SourceCodePoint: $00000184;
      TargetCodePoint: $00000185
    ),
    (
      SourceCodePoint: $00000186;
      TargetCodePoint: $00000254
    ),
    (
      SourceCodePoint: $00000187;
      TargetCodePoint: $00000188
    ),
    (
      SourceCodePoint: $00000189;
      TargetCodePoint: $00000256
    ),
    (
      SourceCodePoint: $0000018A;
      TargetCodePoint: $00000257
    ),
    (
      SourceCodePoint: $0000018B;
      TargetCodePoint: $0000018C
    ),
    (
      SourceCodePoint: $0000018E;
      TargetCodePoint: $000001DD
    ),
    (
      SourceCodePoint: $0000018F;
      TargetCodePoint: $00000259
    ),
    (
      SourceCodePoint: $00000190;
      TargetCodePoint: $0000025B
    ),
    (
      SourceCodePoint: $00000191;
      TargetCodePoint: $00000192
    ),
    (
      SourceCodePoint: $00000193;
      TargetCodePoint: $00000260
    ),
    (
      SourceCodePoint: $00000194;
      TargetCodePoint: $00000263
    ),
    (
      SourceCodePoint: $00000196;
      TargetCodePoint: $00000269
    ),
    (
      SourceCodePoint: $00000197;
      TargetCodePoint: $00000268
    ),
    (
      SourceCodePoint: $00000198;
      TargetCodePoint: $00000199
    ),
    (
      SourceCodePoint: $0000019C;
      TargetCodePoint: $0000026F
    ),
    (
      SourceCodePoint: $0000019D;
      TargetCodePoint: $00000272
    ),
    (
      SourceCodePoint: $0000019F;
      TargetCodePoint: $00000275
    ),
    (
      SourceCodePoint: $000001A0;
      TargetCodePoint: $000001A1
    ),
    (
      SourceCodePoint: $000001A2;
      TargetCodePoint: $000001A3
    ),
    (
      SourceCodePoint: $000001A4;
      TargetCodePoint: $000001A5
    ),
    (
      SourceCodePoint: $000001A6;
      TargetCodePoint: $00000280
    ),
    (
      SourceCodePoint: $000001A7;
      TargetCodePoint: $000001A8
    ),
    (
      SourceCodePoint: $000001A9;
      TargetCodePoint: $00000283
    ),
    (
      SourceCodePoint: $000001AC;
      TargetCodePoint: $000001AD
    ),
    (
      SourceCodePoint: $000001AE;
      TargetCodePoint: $00000288
    ),
    (
      SourceCodePoint: $000001AF;
      TargetCodePoint: $000001B0
    ),
    (
      SourceCodePoint: $000001B1;
      TargetCodePoint: $0000028A
    ),
    (
      SourceCodePoint: $000001B2;
      TargetCodePoint: $0000028B
    ),
    (
      SourceCodePoint: $000001B3;
      TargetCodePoint: $000001B4
    ),
    (
      SourceCodePoint: $000001B5;
      TargetCodePoint: $000001B6
    ),
    (
      SourceCodePoint: $000001B7;
      TargetCodePoint: $00000292
    ),
    (
      SourceCodePoint: $000001B8;
      TargetCodePoint: $000001B9
    ),
    (
      SourceCodePoint: $000001BC;
      TargetCodePoint: $000001BD
    ),
    (
      SourceCodePoint: $000001C4;
      TargetCodePoint: $000001C6
    ),
    (
      SourceCodePoint: $000001C5;
      TargetCodePoint: $000001C6
    ),
    (
      SourceCodePoint: $000001C7;
      TargetCodePoint: $000001C9
    ),
    (
      SourceCodePoint: $000001C8;
      TargetCodePoint: $000001C9
    ),
    (
      SourceCodePoint: $000001CA;
      TargetCodePoint: $000001CC
    ),
    (
      SourceCodePoint: $000001CB;
      TargetCodePoint: $000001CC
    ),
    (
      SourceCodePoint: $000001CD;
      TargetCodePoint: $000001CE
    ),
    (
      SourceCodePoint: $000001CF;
      TargetCodePoint: $000001D0
    ),
    (
      SourceCodePoint: $000001D1;
      TargetCodePoint: $000001D2
    ),
    (
      SourceCodePoint: $000001D3;
      TargetCodePoint: $000001D4
    ),
    (
      SourceCodePoint: $000001D5;
      TargetCodePoint: $000001D6
    ),
    (
      SourceCodePoint: $000001D7;
      TargetCodePoint: $000001D8
    ),
    (
      SourceCodePoint: $000001D9;
      TargetCodePoint: $000001DA
    ),
    (
      SourceCodePoint: $000001DB;
      TargetCodePoint: $000001DC
    ),
    (
      SourceCodePoint: $000001DE;
      TargetCodePoint: $000001DF
    ),
    (
      SourceCodePoint: $000001E0;
      TargetCodePoint: $000001E1
    ),
    (
      SourceCodePoint: $000001E2;
      TargetCodePoint: $000001E3
    ),
    (
      SourceCodePoint: $000001E4;
      TargetCodePoint: $000001E5
    ),
    (
      SourceCodePoint: $000001E6;
      TargetCodePoint: $000001E7
    ),
    (
      SourceCodePoint: $000001E8;
      TargetCodePoint: $000001E9
    ),
    (
      SourceCodePoint: $000001EA;
      TargetCodePoint: $000001EB
    ),
    (
      SourceCodePoint: $000001EC;
      TargetCodePoint: $000001ED
    ),
    (
      SourceCodePoint: $000001EE;
      TargetCodePoint: $000001EF
    ),
    (
      SourceCodePoint: $000001F1;
      TargetCodePoint: $000001F3
    ),
    (
      SourceCodePoint: $000001F2;
      TargetCodePoint: $000001F3
    ),
    (
      SourceCodePoint: $000001F4;
      TargetCodePoint: $000001F5
    ),
    (
      SourceCodePoint: $000001F6;
      TargetCodePoint: $00000195
    ),
    (
      SourceCodePoint: $000001F7;
      TargetCodePoint: $000001BF
    ),
    (
      SourceCodePoint: $000001F8;
      TargetCodePoint: $000001F9
    ),
    (
      SourceCodePoint: $000001FA;
      TargetCodePoint: $000001FB
    ),
    (
      SourceCodePoint: $000001FC;
      TargetCodePoint: $000001FD
    ),
    (
      SourceCodePoint: $000001FE;
      TargetCodePoint: $000001FF
    ),
    (
      SourceCodePoint: $00000200;
      TargetCodePoint: $00000201
    ),
    (
      SourceCodePoint: $00000202;
      TargetCodePoint: $00000203
    ),
    (
      SourceCodePoint: $00000204;
      TargetCodePoint: $00000205
    ),
    (
      SourceCodePoint: $00000206;
      TargetCodePoint: $00000207
    ),
    (
      SourceCodePoint: $00000208;
      TargetCodePoint: $00000209
    ),
    (
      SourceCodePoint: $0000020A;
      TargetCodePoint: $0000020B
    ),
    (
      SourceCodePoint: $0000020C;
      TargetCodePoint: $0000020D
    ),
    (
      SourceCodePoint: $0000020E;
      TargetCodePoint: $0000020F
    ),
    (
      SourceCodePoint: $00000210;
      TargetCodePoint: $00000211
    ),
    (
      SourceCodePoint: $00000212;
      TargetCodePoint: $00000213
    ),
    (
      SourceCodePoint: $00000214;
      TargetCodePoint: $00000215
    ),
    (
      SourceCodePoint: $00000216;
      TargetCodePoint: $00000217
    ),
    (
      SourceCodePoint: $00000218;
      TargetCodePoint: $00000219
    ),
    (
      SourceCodePoint: $0000021A;
      TargetCodePoint: $0000021B
    ),
    (
      SourceCodePoint: $0000021C;
      TargetCodePoint: $0000021D
    ),
    (
      SourceCodePoint: $0000021E;
      TargetCodePoint: $0000021F
    ),
    (
      SourceCodePoint: $00000220;
      TargetCodePoint: $0000019E
    ),
    (
      SourceCodePoint: $00000222;
      TargetCodePoint: $00000223
    ),
    (
      SourceCodePoint: $00000224;
      TargetCodePoint: $00000225
    ),
    (
      SourceCodePoint: $00000226;
      TargetCodePoint: $00000227
    ),
    (
      SourceCodePoint: $00000228;
      TargetCodePoint: $00000229
    ),
    (
      SourceCodePoint: $0000022A;
      TargetCodePoint: $0000022B
    ),
    (
      SourceCodePoint: $0000022C;
      TargetCodePoint: $0000022D
    ),
    (
      SourceCodePoint: $0000022E;
      TargetCodePoint: $0000022F
    ),
    (
      SourceCodePoint: $00000230;
      TargetCodePoint: $00000231
    ),
    (
      SourceCodePoint: $00000232;
      TargetCodePoint: $00000233
    ),
    (
      SourceCodePoint: $0000023A;
      TargetCodePoint: $00002C65
    ),
    (
      SourceCodePoint: $0000023B;
      TargetCodePoint: $0000023C
    ),
    (
      SourceCodePoint: $0000023D;
      TargetCodePoint: $0000019A
    ),
    (
      SourceCodePoint: $0000023E;
      TargetCodePoint: $00002C66
    ),
    (
      SourceCodePoint: $00000241;
      TargetCodePoint: $00000242
    ),
    (
      SourceCodePoint: $00000243;
      TargetCodePoint: $00000180
    ),
    (
      SourceCodePoint: $00000244;
      TargetCodePoint: $00000289
    ),
    (
      SourceCodePoint: $00000245;
      TargetCodePoint: $0000028C
    ),
    (
      SourceCodePoint: $00000246;
      TargetCodePoint: $00000247
    ),
    (
      SourceCodePoint: $00000248;
      TargetCodePoint: $00000249
    ),
    (
      SourceCodePoint: $0000024A;
      TargetCodePoint: $0000024B
    ),
    (
      SourceCodePoint: $0000024C;
      TargetCodePoint: $0000024D
    ),
    (
      SourceCodePoint: $0000024E;
      TargetCodePoint: $0000024F
    ),
    (
      SourceCodePoint: $00000370;
      TargetCodePoint: $00000371
    ),
    (
      SourceCodePoint: $00000372;
      TargetCodePoint: $00000373
    ),
    (
      SourceCodePoint: $00000376;
      TargetCodePoint: $00000377
    ),
    (
      SourceCodePoint: $0000037F;
      TargetCodePoint: $000003F3
    ),
    (
      SourceCodePoint: $00000386;
      TargetCodePoint: $000003AC
    ),
    (
      SourceCodePoint: $00000388;
      TargetCodePoint: $000003AD
    ),
    (
      SourceCodePoint: $00000389;
      TargetCodePoint: $000003AE
    ),
    (
      SourceCodePoint: $0000038A;
      TargetCodePoint: $000003AF
    ),
    (
      SourceCodePoint: $0000038C;
      TargetCodePoint: $000003CC
    ),
    (
      SourceCodePoint: $0000038E;
      TargetCodePoint: $000003CD
    ),
    (
      SourceCodePoint: $0000038F;
      TargetCodePoint: $000003CE
    ),
    (
      SourceCodePoint: $00000391;
      TargetCodePoint: $000003B1
    ),
    (
      SourceCodePoint: $00000392;
      TargetCodePoint: $000003B2
    ),
    (
      SourceCodePoint: $00000393;
      TargetCodePoint: $000003B3
    ),
    (
      SourceCodePoint: $00000394;
      TargetCodePoint: $000003B4
    ),
    (
      SourceCodePoint: $00000395;
      TargetCodePoint: $000003B5
    ),
    (
      SourceCodePoint: $00000396;
      TargetCodePoint: $000003B6
    ),
    (
      SourceCodePoint: $00000397;
      TargetCodePoint: $000003B7
    ),
    (
      SourceCodePoint: $00000398;
      TargetCodePoint: $000003B8
    ),
    (
      SourceCodePoint: $00000399;
      TargetCodePoint: $000003B9
    ),
    (
      SourceCodePoint: $0000039A;
      TargetCodePoint: $000003BA
    ),
    (
      SourceCodePoint: $0000039B;
      TargetCodePoint: $000003BB
    ),
    (
      SourceCodePoint: $0000039C;
      TargetCodePoint: $000003BC
    ),
    (
      SourceCodePoint: $0000039D;
      TargetCodePoint: $000003BD
    ),
    (
      SourceCodePoint: $0000039E;
      TargetCodePoint: $000003BE
    ),
    (
      SourceCodePoint: $0000039F;
      TargetCodePoint: $000003BF
    ),
    (
      SourceCodePoint: $000003A0;
      TargetCodePoint: $000003C0
    ),
    (
      SourceCodePoint: $000003A1;
      TargetCodePoint: $000003C1
    ),
    (
      SourceCodePoint: $000003A3;
      TargetCodePoint: $000003C3
    ),
    (
      SourceCodePoint: $000003A4;
      TargetCodePoint: $000003C4
    ),
    (
      SourceCodePoint: $000003A5;
      TargetCodePoint: $000003C5
    ),
    (
      SourceCodePoint: $000003A6;
      TargetCodePoint: $000003C6
    ),
    (
      SourceCodePoint: $000003A7;
      TargetCodePoint: $000003C7
    ),
    (
      SourceCodePoint: $000003A8;
      TargetCodePoint: $000003C8
    ),
    (
      SourceCodePoint: $000003A9;
      TargetCodePoint: $000003C9
    ),
    (
      SourceCodePoint: $000003AA;
      TargetCodePoint: $000003CA
    ),
    (
      SourceCodePoint: $000003AB;
      TargetCodePoint: $000003CB
    ),
    (
      SourceCodePoint: $000003CF;
      TargetCodePoint: $000003D7
    ),
    (
      SourceCodePoint: $000003D8;
      TargetCodePoint: $000003D9
    ),
    (
      SourceCodePoint: $000003DA;
      TargetCodePoint: $000003DB
    ),
    (
      SourceCodePoint: $000003DC;
      TargetCodePoint: $000003DD
    ),
    (
      SourceCodePoint: $000003DE;
      TargetCodePoint: $000003DF
    ),
    (
      SourceCodePoint: $000003E0;
      TargetCodePoint: $000003E1
    ),
    (
      SourceCodePoint: $000003E2;
      TargetCodePoint: $000003E3
    ),
    (
      SourceCodePoint: $000003E4;
      TargetCodePoint: $000003E5
    ),
    (
      SourceCodePoint: $000003E6;
      TargetCodePoint: $000003E7
    ),
    (
      SourceCodePoint: $000003E8;
      TargetCodePoint: $000003E9
    ),
    (
      SourceCodePoint: $000003EA;
      TargetCodePoint: $000003EB
    ),
    (
      SourceCodePoint: $000003EC;
      TargetCodePoint: $000003ED
    ),
    (
      SourceCodePoint: $000003EE;
      TargetCodePoint: $000003EF
    ),
    (
      SourceCodePoint: $000003F4;
      TargetCodePoint: $000003B8
    ),
    (
      SourceCodePoint: $000003F7;
      TargetCodePoint: $000003F8
    ),
    (
      SourceCodePoint: $000003F9;
      TargetCodePoint: $000003F2
    ),
    (
      SourceCodePoint: $000003FA;
      TargetCodePoint: $000003FB
    ),
    (
      SourceCodePoint: $000003FD;
      TargetCodePoint: $0000037B
    ),
    (
      SourceCodePoint: $000003FE;
      TargetCodePoint: $0000037C
    ),
    (
      SourceCodePoint: $000003FF;
      TargetCodePoint: $0000037D
    ),
    (
      SourceCodePoint: $00000400;
      TargetCodePoint: $00000450
    ),
    (
      SourceCodePoint: $00000401;
      TargetCodePoint: $00000451
    ),
    (
      SourceCodePoint: $00000402;
      TargetCodePoint: $00000452
    ),
    (
      SourceCodePoint: $00000403;
      TargetCodePoint: $00000453
    ),
    (
      SourceCodePoint: $00000404;
      TargetCodePoint: $00000454
    ),
    (
      SourceCodePoint: $00000405;
      TargetCodePoint: $00000455
    ),
    (
      SourceCodePoint: $00000406;
      TargetCodePoint: $00000456
    ),
    (
      SourceCodePoint: $00000407;
      TargetCodePoint: $00000457
    ),
    (
      SourceCodePoint: $00000408;
      TargetCodePoint: $00000458
    ),
    (
      SourceCodePoint: $00000409;
      TargetCodePoint: $00000459
    ),
    (
      SourceCodePoint: $0000040A;
      TargetCodePoint: $0000045A
    ),
    (
      SourceCodePoint: $0000040B;
      TargetCodePoint: $0000045B
    ),
    (
      SourceCodePoint: $0000040C;
      TargetCodePoint: $0000045C
    ),
    (
      SourceCodePoint: $0000040D;
      TargetCodePoint: $0000045D
    ),
    (
      SourceCodePoint: $0000040E;
      TargetCodePoint: $0000045E
    ),
    (
      SourceCodePoint: $0000040F;
      TargetCodePoint: $0000045F
    ),
    (
      SourceCodePoint: $00000410;
      TargetCodePoint: $00000430
    ),
    (
      SourceCodePoint: $00000411;
      TargetCodePoint: $00000431
    ),
    (
      SourceCodePoint: $00000412;
      TargetCodePoint: $00000432
    ),
    (
      SourceCodePoint: $00000413;
      TargetCodePoint: $00000433
    ),
    (
      SourceCodePoint: $00000414;
      TargetCodePoint: $00000434
    ),
    (
      SourceCodePoint: $00000415;
      TargetCodePoint: $00000435
    ),
    (
      SourceCodePoint: $00000416;
      TargetCodePoint: $00000436
    ),
    (
      SourceCodePoint: $00000417;
      TargetCodePoint: $00000437
    ),
    (
      SourceCodePoint: $00000418;
      TargetCodePoint: $00000438
    ),
    (
      SourceCodePoint: $00000419;
      TargetCodePoint: $00000439
    ),
    (
      SourceCodePoint: $0000041A;
      TargetCodePoint: $0000043A
    ),
    (
      SourceCodePoint: $0000041B;
      TargetCodePoint: $0000043B
    ),
    (
      SourceCodePoint: $0000041C;
      TargetCodePoint: $0000043C
    ),
    (
      SourceCodePoint: $0000041D;
      TargetCodePoint: $0000043D
    ),
    (
      SourceCodePoint: $0000041E;
      TargetCodePoint: $0000043E
    ),
    (
      SourceCodePoint: $0000041F;
      TargetCodePoint: $0000043F
    ),
    (
      SourceCodePoint: $00000420;
      TargetCodePoint: $00000440
    ),
    (
      SourceCodePoint: $00000421;
      TargetCodePoint: $00000441
    ),
    (
      SourceCodePoint: $00000422;
      TargetCodePoint: $00000442
    ),
    (
      SourceCodePoint: $00000423;
      TargetCodePoint: $00000443
    ),
    (
      SourceCodePoint: $00000424;
      TargetCodePoint: $00000444
    ),
    (
      SourceCodePoint: $00000425;
      TargetCodePoint: $00000445
    ),
    (
      SourceCodePoint: $00000426;
      TargetCodePoint: $00000446
    ),
    (
      SourceCodePoint: $00000427;
      TargetCodePoint: $00000447
    ),
    (
      SourceCodePoint: $00000428;
      TargetCodePoint: $00000448
    ),
    (
      SourceCodePoint: $00000429;
      TargetCodePoint: $00000449
    ),
    (
      SourceCodePoint: $0000042A;
      TargetCodePoint: $0000044A
    ),
    (
      SourceCodePoint: $0000042B;
      TargetCodePoint: $0000044B
    ),
    (
      SourceCodePoint: $0000042C;
      TargetCodePoint: $0000044C
    ),
    (
      SourceCodePoint: $0000042D;
      TargetCodePoint: $0000044D
    ),
    (
      SourceCodePoint: $0000042E;
      TargetCodePoint: $0000044E
    ),
    (
      SourceCodePoint: $0000042F;
      TargetCodePoint: $0000044F
    ),
    (
      SourceCodePoint: $00000460;
      TargetCodePoint: $00000461
    ),
    (
      SourceCodePoint: $00000462;
      TargetCodePoint: $00000463
    ),
    (
      SourceCodePoint: $00000464;
      TargetCodePoint: $00000465
    ),
    (
      SourceCodePoint: $00000466;
      TargetCodePoint: $00000467
    ),
    (
      SourceCodePoint: $00000468;
      TargetCodePoint: $00000469
    ),
    (
      SourceCodePoint: $0000046A;
      TargetCodePoint: $0000046B
    ),
    (
      SourceCodePoint: $0000046C;
      TargetCodePoint: $0000046D
    ),
    (
      SourceCodePoint: $0000046E;
      TargetCodePoint: $0000046F
    ),
    (
      SourceCodePoint: $00000470;
      TargetCodePoint: $00000471
    ),
    (
      SourceCodePoint: $00000472;
      TargetCodePoint: $00000473
    ),
    (
      SourceCodePoint: $00000474;
      TargetCodePoint: $00000475
    ),
    (
      SourceCodePoint: $00000476;
      TargetCodePoint: $00000477
    ),
    (
      SourceCodePoint: $00000478;
      TargetCodePoint: $00000479
    ),
    (
      SourceCodePoint: $0000047A;
      TargetCodePoint: $0000047B
    ),
    (
      SourceCodePoint: $0000047C;
      TargetCodePoint: $0000047D
    ),
    (
      SourceCodePoint: $0000047E;
      TargetCodePoint: $0000047F
    ),
    (
      SourceCodePoint: $00000480;
      TargetCodePoint: $00000481
    ),
    (
      SourceCodePoint: $0000048A;
      TargetCodePoint: $0000048B
    ),
    (
      SourceCodePoint: $0000048C;
      TargetCodePoint: $0000048D
    ),
    (
      SourceCodePoint: $0000048E;
      TargetCodePoint: $0000048F
    ),
    (
      SourceCodePoint: $00000490;
      TargetCodePoint: $00000491
    ),
    (
      SourceCodePoint: $00000492;
      TargetCodePoint: $00000493
    ),
    (
      SourceCodePoint: $00000494;
      TargetCodePoint: $00000495
    ),
    (
      SourceCodePoint: $00000496;
      TargetCodePoint: $00000497
    ),
    (
      SourceCodePoint: $00000498;
      TargetCodePoint: $00000499
    ),
    (
      SourceCodePoint: $0000049A;
      TargetCodePoint: $0000049B
    ),
    (
      SourceCodePoint: $0000049C;
      TargetCodePoint: $0000049D
    ),
    (
      SourceCodePoint: $0000049E;
      TargetCodePoint: $0000049F
    ),
    (
      SourceCodePoint: $000004A0;
      TargetCodePoint: $000004A1
    ),
    (
      SourceCodePoint: $000004A2;
      TargetCodePoint: $000004A3
    ),
    (
      SourceCodePoint: $000004A4;
      TargetCodePoint: $000004A5
    ),
    (
      SourceCodePoint: $000004A6;
      TargetCodePoint: $000004A7
    ),
    (
      SourceCodePoint: $000004A8;
      TargetCodePoint: $000004A9
    ),
    (
      SourceCodePoint: $000004AA;
      TargetCodePoint: $000004AB
    ),
    (
      SourceCodePoint: $000004AC;
      TargetCodePoint: $000004AD
    ),
    (
      SourceCodePoint: $000004AE;
      TargetCodePoint: $000004AF
    ),
    (
      SourceCodePoint: $000004B0;
      TargetCodePoint: $000004B1
    ),
    (
      SourceCodePoint: $000004B2;
      TargetCodePoint: $000004B3
    ),
    (
      SourceCodePoint: $000004B4;
      TargetCodePoint: $000004B5
    ),
    (
      SourceCodePoint: $000004B6;
      TargetCodePoint: $000004B7
    ),
    (
      SourceCodePoint: $000004B8;
      TargetCodePoint: $000004B9
    ),
    (
      SourceCodePoint: $000004BA;
      TargetCodePoint: $000004BB
    ),
    (
      SourceCodePoint: $000004BC;
      TargetCodePoint: $000004BD
    ),
    (
      SourceCodePoint: $000004BE;
      TargetCodePoint: $000004BF
    ),
    (
      SourceCodePoint: $000004C0;
      TargetCodePoint: $000004CF
    ),
    (
      SourceCodePoint: $000004C1;
      TargetCodePoint: $000004C2
    ),
    (
      SourceCodePoint: $000004C3;
      TargetCodePoint: $000004C4
    ),
    (
      SourceCodePoint: $000004C5;
      TargetCodePoint: $000004C6
    ),
    (
      SourceCodePoint: $000004C7;
      TargetCodePoint: $000004C8
    ),
    (
      SourceCodePoint: $000004C9;
      TargetCodePoint: $000004CA
    ),
    (
      SourceCodePoint: $000004CB;
      TargetCodePoint: $000004CC
    ),
    (
      SourceCodePoint: $000004CD;
      TargetCodePoint: $000004CE
    ),
    (
      SourceCodePoint: $000004D0;
      TargetCodePoint: $000004D1
    ),
    (
      SourceCodePoint: $000004D2;
      TargetCodePoint: $000004D3
    ),
    (
      SourceCodePoint: $000004D4;
      TargetCodePoint: $000004D5
    ),
    (
      SourceCodePoint: $000004D6;
      TargetCodePoint: $000004D7
    ),
    (
      SourceCodePoint: $000004D8;
      TargetCodePoint: $000004D9
    ),
    (
      SourceCodePoint: $000004DA;
      TargetCodePoint: $000004DB
    ),
    (
      SourceCodePoint: $000004DC;
      TargetCodePoint: $000004DD
    ),
    (
      SourceCodePoint: $000004DE;
      TargetCodePoint: $000004DF
    ),
    (
      SourceCodePoint: $000004E0;
      TargetCodePoint: $000004E1
    ),
    (
      SourceCodePoint: $000004E2;
      TargetCodePoint: $000004E3
    ),
    (
      SourceCodePoint: $000004E4;
      TargetCodePoint: $000004E5
    ),
    (
      SourceCodePoint: $000004E6;
      TargetCodePoint: $000004E7
    ),
    (
      SourceCodePoint: $000004E8;
      TargetCodePoint: $000004E9
    ),
    (
      SourceCodePoint: $000004EA;
      TargetCodePoint: $000004EB
    ),
    (
      SourceCodePoint: $000004EC;
      TargetCodePoint: $000004ED
    ),
    (
      SourceCodePoint: $000004EE;
      TargetCodePoint: $000004EF
    ),
    (
      SourceCodePoint: $000004F0;
      TargetCodePoint: $000004F1
    ),
    (
      SourceCodePoint: $000004F2;
      TargetCodePoint: $000004F3
    ),
    (
      SourceCodePoint: $000004F4;
      TargetCodePoint: $000004F5
    ),
    (
      SourceCodePoint: $000004F6;
      TargetCodePoint: $000004F7
    ),
    (
      SourceCodePoint: $000004F8;
      TargetCodePoint: $000004F9
    ),
    (
      SourceCodePoint: $000004FA;
      TargetCodePoint: $000004FB
    ),
    (
      SourceCodePoint: $000004FC;
      TargetCodePoint: $000004FD
    ),
    (
      SourceCodePoint: $000004FE;
      TargetCodePoint: $000004FF
    ),
    (
      SourceCodePoint: $00000500;
      TargetCodePoint: $00000501
    ),
    (
      SourceCodePoint: $00000502;
      TargetCodePoint: $00000503
    ),
    (
      SourceCodePoint: $00000504;
      TargetCodePoint: $00000505
    ),
    (
      SourceCodePoint: $00000506;
      TargetCodePoint: $00000507
    ),
    (
      SourceCodePoint: $00000508;
      TargetCodePoint: $00000509
    ),
    (
      SourceCodePoint: $0000050A;
      TargetCodePoint: $0000050B
    ),
    (
      SourceCodePoint: $0000050C;
      TargetCodePoint: $0000050D
    ),
    (
      SourceCodePoint: $0000050E;
      TargetCodePoint: $0000050F
    ),
    (
      SourceCodePoint: $00000510;
      TargetCodePoint: $00000511
    ),
    (
      SourceCodePoint: $00000512;
      TargetCodePoint: $00000513
    ),
    (
      SourceCodePoint: $00000514;
      TargetCodePoint: $00000515
    ),
    (
      SourceCodePoint: $00000516;
      TargetCodePoint: $00000517
    ),
    (
      SourceCodePoint: $00000518;
      TargetCodePoint: $00000519
    ),
    (
      SourceCodePoint: $0000051A;
      TargetCodePoint: $0000051B
    ),
    (
      SourceCodePoint: $0000051C;
      TargetCodePoint: $0000051D
    ),
    (
      SourceCodePoint: $0000051E;
      TargetCodePoint: $0000051F
    ),
    (
      SourceCodePoint: $00000520;
      TargetCodePoint: $00000521
    ),
    (
      SourceCodePoint: $00000522;
      TargetCodePoint: $00000523
    ),
    (
      SourceCodePoint: $00000524;
      TargetCodePoint: $00000525
    ),
    (
      SourceCodePoint: $00000526;
      TargetCodePoint: $00000527
    ),
    (
      SourceCodePoint: $00000528;
      TargetCodePoint: $00000529
    ),
    (
      SourceCodePoint: $0000052A;
      TargetCodePoint: $0000052B
    ),
    (
      SourceCodePoint: $0000052C;
      TargetCodePoint: $0000052D
    ),
    (
      SourceCodePoint: $0000052E;
      TargetCodePoint: $0000052F
    ),
    (
      SourceCodePoint: $00000531;
      TargetCodePoint: $00000561
    ),
    (
      SourceCodePoint: $00000532;
      TargetCodePoint: $00000562
    ),
    (
      SourceCodePoint: $00000533;
      TargetCodePoint: $00000563
    ),
    (
      SourceCodePoint: $00000534;
      TargetCodePoint: $00000564
    ),
    (
      SourceCodePoint: $00000535;
      TargetCodePoint: $00000565
    ),
    (
      SourceCodePoint: $00000536;
      TargetCodePoint: $00000566
    ),
    (
      SourceCodePoint: $00000537;
      TargetCodePoint: $00000567
    ),
    (
      SourceCodePoint: $00000538;
      TargetCodePoint: $00000568
    ),
    (
      SourceCodePoint: $00000539;
      TargetCodePoint: $00000569
    ),
    (
      SourceCodePoint: $0000053A;
      TargetCodePoint: $0000056A
    ),
    (
      SourceCodePoint: $0000053B;
      TargetCodePoint: $0000056B
    ),
    (
      SourceCodePoint: $0000053C;
      TargetCodePoint: $0000056C
    ),
    (
      SourceCodePoint: $0000053D;
      TargetCodePoint: $0000056D
    ),
    (
      SourceCodePoint: $0000053E;
      TargetCodePoint: $0000056E
    ),
    (
      SourceCodePoint: $0000053F;
      TargetCodePoint: $0000056F
    ),
    (
      SourceCodePoint: $00000540;
      TargetCodePoint: $00000570
    ),
    (
      SourceCodePoint: $00000541;
      TargetCodePoint: $00000571
    ),
    (
      SourceCodePoint: $00000542;
      TargetCodePoint: $00000572
    ),
    (
      SourceCodePoint: $00000543;
      TargetCodePoint: $00000573
    ),
    (
      SourceCodePoint: $00000544;
      TargetCodePoint: $00000574
    ),
    (
      SourceCodePoint: $00000545;
      TargetCodePoint: $00000575
    ),
    (
      SourceCodePoint: $00000546;
      TargetCodePoint: $00000576
    ),
    (
      SourceCodePoint: $00000547;
      TargetCodePoint: $00000577
    ),
    (
      SourceCodePoint: $00000548;
      TargetCodePoint: $00000578
    ),
    (
      SourceCodePoint: $00000549;
      TargetCodePoint: $00000579
    ),
    (
      SourceCodePoint: $0000054A;
      TargetCodePoint: $0000057A
    ),
    (
      SourceCodePoint: $0000054B;
      TargetCodePoint: $0000057B
    ),
    (
      SourceCodePoint: $0000054C;
      TargetCodePoint: $0000057C
    ),
    (
      SourceCodePoint: $0000054D;
      TargetCodePoint: $0000057D
    ),
    (
      SourceCodePoint: $0000054E;
      TargetCodePoint: $0000057E
    ),
    (
      SourceCodePoint: $0000054F;
      TargetCodePoint: $0000057F
    ),
    (
      SourceCodePoint: $00000550;
      TargetCodePoint: $00000580
    ),
    (
      SourceCodePoint: $00000551;
      TargetCodePoint: $00000581
    ),
    (
      SourceCodePoint: $00000552;
      TargetCodePoint: $00000582
    ),
    (
      SourceCodePoint: $00000553;
      TargetCodePoint: $00000583
    ),
    (
      SourceCodePoint: $00000554;
      TargetCodePoint: $00000584
    ),
    (
      SourceCodePoint: $00000555;
      TargetCodePoint: $00000585
    ),
    (
      SourceCodePoint: $00000556;
      TargetCodePoint: $00000586
    ),
    (
      SourceCodePoint: $000010A0;
      TargetCodePoint: $00002D00
    ),
    (
      SourceCodePoint: $000010A1;
      TargetCodePoint: $00002D01
    ),
    (
      SourceCodePoint: $000010A2;
      TargetCodePoint: $00002D02
    ),
    (
      SourceCodePoint: $000010A3;
      TargetCodePoint: $00002D03
    ),
    (
      SourceCodePoint: $000010A4;
      TargetCodePoint: $00002D04
    ),
    (
      SourceCodePoint: $000010A5;
      TargetCodePoint: $00002D05
    ),
    (
      SourceCodePoint: $000010A6;
      TargetCodePoint: $00002D06
    ),
    (
      SourceCodePoint: $000010A7;
      TargetCodePoint: $00002D07
    ),
    (
      SourceCodePoint: $000010A8;
      TargetCodePoint: $00002D08
    ),
    (
      SourceCodePoint: $000010A9;
      TargetCodePoint: $00002D09
    ),
    (
      SourceCodePoint: $000010AA;
      TargetCodePoint: $00002D0A
    ),
    (
      SourceCodePoint: $000010AB;
      TargetCodePoint: $00002D0B
    ),
    (
      SourceCodePoint: $000010AC;
      TargetCodePoint: $00002D0C
    ),
    (
      SourceCodePoint: $000010AD;
      TargetCodePoint: $00002D0D
    ),
    (
      SourceCodePoint: $000010AE;
      TargetCodePoint: $00002D0E
    ),
    (
      SourceCodePoint: $000010AF;
      TargetCodePoint: $00002D0F
    ),
    (
      SourceCodePoint: $000010B0;
      TargetCodePoint: $00002D10
    ),
    (
      SourceCodePoint: $000010B1;
      TargetCodePoint: $00002D11
    ),
    (
      SourceCodePoint: $000010B2;
      TargetCodePoint: $00002D12
    ),
    (
      SourceCodePoint: $000010B3;
      TargetCodePoint: $00002D13
    ),
    (
      SourceCodePoint: $000010B4;
      TargetCodePoint: $00002D14
    ),
    (
      SourceCodePoint: $000010B5;
      TargetCodePoint: $00002D15
    ),
    (
      SourceCodePoint: $000010B6;
      TargetCodePoint: $00002D16
    ),
    (
      SourceCodePoint: $000010B7;
      TargetCodePoint: $00002D17
    ),
    (
      SourceCodePoint: $000010B8;
      TargetCodePoint: $00002D18
    ),
    (
      SourceCodePoint: $000010B9;
      TargetCodePoint: $00002D19
    ),
    (
      SourceCodePoint: $000010BA;
      TargetCodePoint: $00002D1A
    ),
    (
      SourceCodePoint: $000010BB;
      TargetCodePoint: $00002D1B
    ),
    (
      SourceCodePoint: $000010BC;
      TargetCodePoint: $00002D1C
    ),
    (
      SourceCodePoint: $000010BD;
      TargetCodePoint: $00002D1D
    ),
    (
      SourceCodePoint: $000010BE;
      TargetCodePoint: $00002D1E
    ),
    (
      SourceCodePoint: $000010BF;
      TargetCodePoint: $00002D1F
    ),
    (
      SourceCodePoint: $000010C0;
      TargetCodePoint: $00002D20
    ),
    (
      SourceCodePoint: $000010C1;
      TargetCodePoint: $00002D21
    ),
    (
      SourceCodePoint: $000010C2;
      TargetCodePoint: $00002D22
    ),
    (
      SourceCodePoint: $000010C3;
      TargetCodePoint: $00002D23
    ),
    (
      SourceCodePoint: $000010C4;
      TargetCodePoint: $00002D24
    ),
    (
      SourceCodePoint: $000010C5;
      TargetCodePoint: $00002D25
    ),
    (
      SourceCodePoint: $000010C7;
      TargetCodePoint: $00002D27
    ),
    (
      SourceCodePoint: $000010CD;
      TargetCodePoint: $00002D2D
    ),
    (
      SourceCodePoint: $000013A0;
      TargetCodePoint: $0000AB70
    ),
    (
      SourceCodePoint: $000013A1;
      TargetCodePoint: $0000AB71
    ),
    (
      SourceCodePoint: $000013A2;
      TargetCodePoint: $0000AB72
    ),
    (
      SourceCodePoint: $000013A3;
      TargetCodePoint: $0000AB73
    ),
    (
      SourceCodePoint: $000013A4;
      TargetCodePoint: $0000AB74
    ),
    (
      SourceCodePoint: $000013A5;
      TargetCodePoint: $0000AB75
    ),
    (
      SourceCodePoint: $000013A6;
      TargetCodePoint: $0000AB76
    ),
    (
      SourceCodePoint: $000013A7;
      TargetCodePoint: $0000AB77
    ),
    (
      SourceCodePoint: $000013A8;
      TargetCodePoint: $0000AB78
    ),
    (
      SourceCodePoint: $000013A9;
      TargetCodePoint: $0000AB79
    ),
    (
      SourceCodePoint: $000013AA;
      TargetCodePoint: $0000AB7A
    ),
    (
      SourceCodePoint: $000013AB;
      TargetCodePoint: $0000AB7B
    ),
    (
      SourceCodePoint: $000013AC;
      TargetCodePoint: $0000AB7C
    ),
    (
      SourceCodePoint: $000013AD;
      TargetCodePoint: $0000AB7D
    ),
    (
      SourceCodePoint: $000013AE;
      TargetCodePoint: $0000AB7E
    ),
    (
      SourceCodePoint: $000013AF;
      TargetCodePoint: $0000AB7F
    ),
    (
      SourceCodePoint: $000013B0;
      TargetCodePoint: $0000AB80
    ),
    (
      SourceCodePoint: $000013B1;
      TargetCodePoint: $0000AB81
    ),
    (
      SourceCodePoint: $000013B2;
      TargetCodePoint: $0000AB82
    ),
    (
      SourceCodePoint: $000013B3;
      TargetCodePoint: $0000AB83
    ),
    (
      SourceCodePoint: $000013B4;
      TargetCodePoint: $0000AB84
    ),
    (
      SourceCodePoint: $000013B5;
      TargetCodePoint: $0000AB85
    ),
    (
      SourceCodePoint: $000013B6;
      TargetCodePoint: $0000AB86
    ),
    (
      SourceCodePoint: $000013B7;
      TargetCodePoint: $0000AB87
    ),
    (
      SourceCodePoint: $000013B8;
      TargetCodePoint: $0000AB88
    ),
    (
      SourceCodePoint: $000013B9;
      TargetCodePoint: $0000AB89
    ),
    (
      SourceCodePoint: $000013BA;
      TargetCodePoint: $0000AB8A
    ),
    (
      SourceCodePoint: $000013BB;
      TargetCodePoint: $0000AB8B
    ),
    (
      SourceCodePoint: $000013BC;
      TargetCodePoint: $0000AB8C
    ),
    (
      SourceCodePoint: $000013BD;
      TargetCodePoint: $0000AB8D
    ),
    (
      SourceCodePoint: $000013BE;
      TargetCodePoint: $0000AB8E
    ),
    (
      SourceCodePoint: $000013BF;
      TargetCodePoint: $0000AB8F
    ),
    (
      SourceCodePoint: $000013C0;
      TargetCodePoint: $0000AB90
    ),
    (
      SourceCodePoint: $000013C1;
      TargetCodePoint: $0000AB91
    ),
    (
      SourceCodePoint: $000013C2;
      TargetCodePoint: $0000AB92
    ),
    (
      SourceCodePoint: $000013C3;
      TargetCodePoint: $0000AB93
    ),
    (
      SourceCodePoint: $000013C4;
      TargetCodePoint: $0000AB94
    ),
    (
      SourceCodePoint: $000013C5;
      TargetCodePoint: $0000AB95
    ),
    (
      SourceCodePoint: $000013C6;
      TargetCodePoint: $0000AB96
    ),
    (
      SourceCodePoint: $000013C7;
      TargetCodePoint: $0000AB97
    ),
    (
      SourceCodePoint: $000013C8;
      TargetCodePoint: $0000AB98
    ),
    (
      SourceCodePoint: $000013C9;
      TargetCodePoint: $0000AB99
    ),
    (
      SourceCodePoint: $000013CA;
      TargetCodePoint: $0000AB9A
    ),
    (
      SourceCodePoint: $000013CB;
      TargetCodePoint: $0000AB9B
    ),
    (
      SourceCodePoint: $000013CC;
      TargetCodePoint: $0000AB9C
    ),
    (
      SourceCodePoint: $000013CD;
      TargetCodePoint: $0000AB9D
    ),
    (
      SourceCodePoint: $000013CE;
      TargetCodePoint: $0000AB9E
    ),
    (
      SourceCodePoint: $000013CF;
      TargetCodePoint: $0000AB9F
    ),
    (
      SourceCodePoint: $000013D0;
      TargetCodePoint: $0000ABA0
    ),
    (
      SourceCodePoint: $000013D1;
      TargetCodePoint: $0000ABA1
    ),
    (
      SourceCodePoint: $000013D2;
      TargetCodePoint: $0000ABA2
    ),
    (
      SourceCodePoint: $000013D3;
      TargetCodePoint: $0000ABA3
    ),
    (
      SourceCodePoint: $000013D4;
      TargetCodePoint: $0000ABA4
    ),
    (
      SourceCodePoint: $000013D5;
      TargetCodePoint: $0000ABA5
    ),
    (
      SourceCodePoint: $000013D6;
      TargetCodePoint: $0000ABA6
    ),
    (
      SourceCodePoint: $000013D7;
      TargetCodePoint: $0000ABA7
    ),
    (
      SourceCodePoint: $000013D8;
      TargetCodePoint: $0000ABA8
    ),
    (
      SourceCodePoint: $000013D9;
      TargetCodePoint: $0000ABA9
    ),
    (
      SourceCodePoint: $000013DA;
      TargetCodePoint: $0000ABAA
    ),
    (
      SourceCodePoint: $000013DB;
      TargetCodePoint: $0000ABAB
    ),
    (
      SourceCodePoint: $000013DC;
      TargetCodePoint: $0000ABAC
    ),
    (
      SourceCodePoint: $000013DD;
      TargetCodePoint: $0000ABAD
    ),
    (
      SourceCodePoint: $000013DE;
      TargetCodePoint: $0000ABAE
    ),
    (
      SourceCodePoint: $000013DF;
      TargetCodePoint: $0000ABAF
    ),
    (
      SourceCodePoint: $000013E0;
      TargetCodePoint: $0000ABB0
    ),
    (
      SourceCodePoint: $000013E1;
      TargetCodePoint: $0000ABB1
    ),
    (
      SourceCodePoint: $000013E2;
      TargetCodePoint: $0000ABB2
    ),
    (
      SourceCodePoint: $000013E3;
      TargetCodePoint: $0000ABB3
    ),
    (
      SourceCodePoint: $000013E4;
      TargetCodePoint: $0000ABB4
    ),
    (
      SourceCodePoint: $000013E5;
      TargetCodePoint: $0000ABB5
    ),
    (
      SourceCodePoint: $000013E6;
      TargetCodePoint: $0000ABB6
    ),
    (
      SourceCodePoint: $000013E7;
      TargetCodePoint: $0000ABB7
    ),
    (
      SourceCodePoint: $000013E8;
      TargetCodePoint: $0000ABB8
    ),
    (
      SourceCodePoint: $000013E9;
      TargetCodePoint: $0000ABB9
    ),
    (
      SourceCodePoint: $000013EA;
      TargetCodePoint: $0000ABBA
    ),
    (
      SourceCodePoint: $000013EB;
      TargetCodePoint: $0000ABBB
    ),
    (
      SourceCodePoint: $000013EC;
      TargetCodePoint: $0000ABBC
    ),
    (
      SourceCodePoint: $000013ED;
      TargetCodePoint: $0000ABBD
    ),
    (
      SourceCodePoint: $000013EE;
      TargetCodePoint: $0000ABBE
    ),
    (
      SourceCodePoint: $000013EF;
      TargetCodePoint: $0000ABBF
    ),
    (
      SourceCodePoint: $000013F0;
      TargetCodePoint: $000013F8
    ),
    (
      SourceCodePoint: $000013F1;
      TargetCodePoint: $000013F9
    ),
    (
      SourceCodePoint: $000013F2;
      TargetCodePoint: $000013FA
    ),
    (
      SourceCodePoint: $000013F3;
      TargetCodePoint: $000013FB
    ),
    (
      SourceCodePoint: $000013F4;
      TargetCodePoint: $000013FC
    ),
    (
      SourceCodePoint: $000013F5;
      TargetCodePoint: $000013FD
    ),
    (
      SourceCodePoint: $00001C90;
      TargetCodePoint: $000010D0
    ),
    (
      SourceCodePoint: $00001C91;
      TargetCodePoint: $000010D1
    ),
    (
      SourceCodePoint: $00001C92;
      TargetCodePoint: $000010D2
    ),
    (
      SourceCodePoint: $00001C93;
      TargetCodePoint: $000010D3
    ),
    (
      SourceCodePoint: $00001C94;
      TargetCodePoint: $000010D4
    ),
    (
      SourceCodePoint: $00001C95;
      TargetCodePoint: $000010D5
    ),
    (
      SourceCodePoint: $00001C96;
      TargetCodePoint: $000010D6
    ),
    (
      SourceCodePoint: $00001C97;
      TargetCodePoint: $000010D7
    ),
    (
      SourceCodePoint: $00001C98;
      TargetCodePoint: $000010D8
    ),
    (
      SourceCodePoint: $00001C99;
      TargetCodePoint: $000010D9
    ),
    (
      SourceCodePoint: $00001C9A;
      TargetCodePoint: $000010DA
    ),
    (
      SourceCodePoint: $00001C9B;
      TargetCodePoint: $000010DB
    ),
    (
      SourceCodePoint: $00001C9C;
      TargetCodePoint: $000010DC
    ),
    (
      SourceCodePoint: $00001C9D;
      TargetCodePoint: $000010DD
    ),
    (
      SourceCodePoint: $00001C9E;
      TargetCodePoint: $000010DE
    ),
    (
      SourceCodePoint: $00001C9F;
      TargetCodePoint: $000010DF
    ),
    (
      SourceCodePoint: $00001CA0;
      TargetCodePoint: $000010E0
    ),
    (
      SourceCodePoint: $00001CA1;
      TargetCodePoint: $000010E1
    ),
    (
      SourceCodePoint: $00001CA2;
      TargetCodePoint: $000010E2
    ),
    (
      SourceCodePoint: $00001CA3;
      TargetCodePoint: $000010E3
    ),
    (
      SourceCodePoint: $00001CA4;
      TargetCodePoint: $000010E4
    ),
    (
      SourceCodePoint: $00001CA5;
      TargetCodePoint: $000010E5
    ),
    (
      SourceCodePoint: $00001CA6;
      TargetCodePoint: $000010E6
    ),
    (
      SourceCodePoint: $00001CA7;
      TargetCodePoint: $000010E7
    ),
    (
      SourceCodePoint: $00001CA8;
      TargetCodePoint: $000010E8
    ),
    (
      SourceCodePoint: $00001CA9;
      TargetCodePoint: $000010E9
    ),
    (
      SourceCodePoint: $00001CAA;
      TargetCodePoint: $000010EA
    ),
    (
      SourceCodePoint: $00001CAB;
      TargetCodePoint: $000010EB
    ),
    (
      SourceCodePoint: $00001CAC;
      TargetCodePoint: $000010EC
    ),
    (
      SourceCodePoint: $00001CAD;
      TargetCodePoint: $000010ED
    ),
    (
      SourceCodePoint: $00001CAE;
      TargetCodePoint: $000010EE
    ),
    (
      SourceCodePoint: $00001CAF;
      TargetCodePoint: $000010EF
    ),
    (
      SourceCodePoint: $00001CB0;
      TargetCodePoint: $000010F0
    ),
    (
      SourceCodePoint: $00001CB1;
      TargetCodePoint: $000010F1
    ),
    (
      SourceCodePoint: $00001CB2;
      TargetCodePoint: $000010F2
    ),
    (
      SourceCodePoint: $00001CB3;
      TargetCodePoint: $000010F3
    ),
    (
      SourceCodePoint: $00001CB4;
      TargetCodePoint: $000010F4
    ),
    (
      SourceCodePoint: $00001CB5;
      TargetCodePoint: $000010F5
    ),
    (
      SourceCodePoint: $00001CB6;
      TargetCodePoint: $000010F6
    ),
    (
      SourceCodePoint: $00001CB7;
      TargetCodePoint: $000010F7
    ),
    (
      SourceCodePoint: $00001CB8;
      TargetCodePoint: $000010F8
    ),
    (
      SourceCodePoint: $00001CB9;
      TargetCodePoint: $000010F9
    ),
    (
      SourceCodePoint: $00001CBA;
      TargetCodePoint: $000010FA
    ),
    (
      SourceCodePoint: $00001CBD;
      TargetCodePoint: $000010FD
    ),
    (
      SourceCodePoint: $00001CBE;
      TargetCodePoint: $000010FE
    ),
    (
      SourceCodePoint: $00001CBF;
      TargetCodePoint: $000010FF
    ),
    (
      SourceCodePoint: $00001E00;
      TargetCodePoint: $00001E01
    ),
    (
      SourceCodePoint: $00001E02;
      TargetCodePoint: $00001E03
    ),
    (
      SourceCodePoint: $00001E04;
      TargetCodePoint: $00001E05
    ),
    (
      SourceCodePoint: $00001E06;
      TargetCodePoint: $00001E07
    ),
    (
      SourceCodePoint: $00001E08;
      TargetCodePoint: $00001E09
    ),
    (
      SourceCodePoint: $00001E0A;
      TargetCodePoint: $00001E0B
    ),
    (
      SourceCodePoint: $00001E0C;
      TargetCodePoint: $00001E0D
    ),
    (
      SourceCodePoint: $00001E0E;
      TargetCodePoint: $00001E0F
    ),
    (
      SourceCodePoint: $00001E10;
      TargetCodePoint: $00001E11
    ),
    (
      SourceCodePoint: $00001E12;
      TargetCodePoint: $00001E13
    ),
    (
      SourceCodePoint: $00001E14;
      TargetCodePoint: $00001E15
    ),
    (
      SourceCodePoint: $00001E16;
      TargetCodePoint: $00001E17
    ),
    (
      SourceCodePoint: $00001E18;
      TargetCodePoint: $00001E19
    ),
    (
      SourceCodePoint: $00001E1A;
      TargetCodePoint: $00001E1B
    ),
    (
      SourceCodePoint: $00001E1C;
      TargetCodePoint: $00001E1D
    ),
    (
      SourceCodePoint: $00001E1E;
      TargetCodePoint: $00001E1F
    ),
    (
      SourceCodePoint: $00001E20;
      TargetCodePoint: $00001E21
    ),
    (
      SourceCodePoint: $00001E22;
      TargetCodePoint: $00001E23
    ),
    (
      SourceCodePoint: $00001E24;
      TargetCodePoint: $00001E25
    ),
    (
      SourceCodePoint: $00001E26;
      TargetCodePoint: $00001E27
    ),
    (
      SourceCodePoint: $00001E28;
      TargetCodePoint: $00001E29
    ),
    (
      SourceCodePoint: $00001E2A;
      TargetCodePoint: $00001E2B
    ),
    (
      SourceCodePoint: $00001E2C;
      TargetCodePoint: $00001E2D
    ),
    (
      SourceCodePoint: $00001E2E;
      TargetCodePoint: $00001E2F
    ),
    (
      SourceCodePoint: $00001E30;
      TargetCodePoint: $00001E31
    ),
    (
      SourceCodePoint: $00001E32;
      TargetCodePoint: $00001E33
    ),
    (
      SourceCodePoint: $00001E34;
      TargetCodePoint: $00001E35
    ),
    (
      SourceCodePoint: $00001E36;
      TargetCodePoint: $00001E37
    ),
    (
      SourceCodePoint: $00001E38;
      TargetCodePoint: $00001E39
    ),
    (
      SourceCodePoint: $00001E3A;
      TargetCodePoint: $00001E3B
    ),
    (
      SourceCodePoint: $00001E3C;
      TargetCodePoint: $00001E3D
    ),
    (
      SourceCodePoint: $00001E3E;
      TargetCodePoint: $00001E3F
    ),
    (
      SourceCodePoint: $00001E40;
      TargetCodePoint: $00001E41
    ),
    (
      SourceCodePoint: $00001E42;
      TargetCodePoint: $00001E43
    ),
    (
      SourceCodePoint: $00001E44;
      TargetCodePoint: $00001E45
    ),
    (
      SourceCodePoint: $00001E46;
      TargetCodePoint: $00001E47
    ),
    (
      SourceCodePoint: $00001E48;
      TargetCodePoint: $00001E49
    ),
    (
      SourceCodePoint: $00001E4A;
      TargetCodePoint: $00001E4B
    ),
    (
      SourceCodePoint: $00001E4C;
      TargetCodePoint: $00001E4D
    ),
    (
      SourceCodePoint: $00001E4E;
      TargetCodePoint: $00001E4F
    ),
    (
      SourceCodePoint: $00001E50;
      TargetCodePoint: $00001E51
    ),
    (
      SourceCodePoint: $00001E52;
      TargetCodePoint: $00001E53
    ),
    (
      SourceCodePoint: $00001E54;
      TargetCodePoint: $00001E55
    ),
    (
      SourceCodePoint: $00001E56;
      TargetCodePoint: $00001E57
    ),
    (
      SourceCodePoint: $00001E58;
      TargetCodePoint: $00001E59
    ),
    (
      SourceCodePoint: $00001E5A;
      TargetCodePoint: $00001E5B
    ),
    (
      SourceCodePoint: $00001E5C;
      TargetCodePoint: $00001E5D
    ),
    (
      SourceCodePoint: $00001E5E;
      TargetCodePoint: $00001E5F
    ),
    (
      SourceCodePoint: $00001E60;
      TargetCodePoint: $00001E61
    ),
    (
      SourceCodePoint: $00001E62;
      TargetCodePoint: $00001E63
    ),
    (
      SourceCodePoint: $00001E64;
      TargetCodePoint: $00001E65
    ),
    (
      SourceCodePoint: $00001E66;
      TargetCodePoint: $00001E67
    ),
    (
      SourceCodePoint: $00001E68;
      TargetCodePoint: $00001E69
    ),
    (
      SourceCodePoint: $00001E6A;
      TargetCodePoint: $00001E6B
    ),
    (
      SourceCodePoint: $00001E6C;
      TargetCodePoint: $00001E6D
    ),
    (
      SourceCodePoint: $00001E6E;
      TargetCodePoint: $00001E6F
    ),
    (
      SourceCodePoint: $00001E70;
      TargetCodePoint: $00001E71
    ),
    (
      SourceCodePoint: $00001E72;
      TargetCodePoint: $00001E73
    ),
    (
      SourceCodePoint: $00001E74;
      TargetCodePoint: $00001E75
    ),
    (
      SourceCodePoint: $00001E76;
      TargetCodePoint: $00001E77
    ),
    (
      SourceCodePoint: $00001E78;
      TargetCodePoint: $00001E79
    ),
    (
      SourceCodePoint: $00001E7A;
      TargetCodePoint: $00001E7B
    ),
    (
      SourceCodePoint: $00001E7C;
      TargetCodePoint: $00001E7D
    ),
    (
      SourceCodePoint: $00001E7E;
      TargetCodePoint: $00001E7F
    ),
    (
      SourceCodePoint: $00001E80;
      TargetCodePoint: $00001E81
    ),
    (
      SourceCodePoint: $00001E82;
      TargetCodePoint: $00001E83
    ),
    (
      SourceCodePoint: $00001E84;
      TargetCodePoint: $00001E85
    ),
    (
      SourceCodePoint: $00001E86;
      TargetCodePoint: $00001E87
    ),
    (
      SourceCodePoint: $00001E88;
      TargetCodePoint: $00001E89
    ),
    (
      SourceCodePoint: $00001E8A;
      TargetCodePoint: $00001E8B
    ),
    (
      SourceCodePoint: $00001E8C;
      TargetCodePoint: $00001E8D
    ),
    (
      SourceCodePoint: $00001E8E;
      TargetCodePoint: $00001E8F
    ),
    (
      SourceCodePoint: $00001E90;
      TargetCodePoint: $00001E91
    ),
    (
      SourceCodePoint: $00001E92;
      TargetCodePoint: $00001E93
    ),
    (
      SourceCodePoint: $00001E94;
      TargetCodePoint: $00001E95
    ),
    (
      SourceCodePoint: $00001E9E;
      TargetCodePoint: $000000DF
    ),
    (
      SourceCodePoint: $00001EA0;
      TargetCodePoint: $00001EA1
    ),
    (
      SourceCodePoint: $00001EA2;
      TargetCodePoint: $00001EA3
    ),
    (
      SourceCodePoint: $00001EA4;
      TargetCodePoint: $00001EA5
    ),
    (
      SourceCodePoint: $00001EA6;
      TargetCodePoint: $00001EA7
    ),
    (
      SourceCodePoint: $00001EA8;
      TargetCodePoint: $00001EA9
    ),
    (
      SourceCodePoint: $00001EAA;
      TargetCodePoint: $00001EAB
    ),
    (
      SourceCodePoint: $00001EAC;
      TargetCodePoint: $00001EAD
    ),
    (
      SourceCodePoint: $00001EAE;
      TargetCodePoint: $00001EAF
    ),
    (
      SourceCodePoint: $00001EB0;
      TargetCodePoint: $00001EB1
    ),
    (
      SourceCodePoint: $00001EB2;
      TargetCodePoint: $00001EB3
    ),
    (
      SourceCodePoint: $00001EB4;
      TargetCodePoint: $00001EB5
    ),
    (
      SourceCodePoint: $00001EB6;
      TargetCodePoint: $00001EB7
    ),
    (
      SourceCodePoint: $00001EB8;
      TargetCodePoint: $00001EB9
    ),
    (
      SourceCodePoint: $00001EBA;
      TargetCodePoint: $00001EBB
    ),
    (
      SourceCodePoint: $00001EBC;
      TargetCodePoint: $00001EBD
    ),
    (
      SourceCodePoint: $00001EBE;
      TargetCodePoint: $00001EBF
    ),
    (
      SourceCodePoint: $00001EC0;
      TargetCodePoint: $00001EC1
    ),
    (
      SourceCodePoint: $00001EC2;
      TargetCodePoint: $00001EC3
    ),
    (
      SourceCodePoint: $00001EC4;
      TargetCodePoint: $00001EC5
    ),
    (
      SourceCodePoint: $00001EC6;
      TargetCodePoint: $00001EC7
    ),
    (
      SourceCodePoint: $00001EC8;
      TargetCodePoint: $00001EC9
    ),
    (
      SourceCodePoint: $00001ECA;
      TargetCodePoint: $00001ECB
    ),
    (
      SourceCodePoint: $00001ECC;
      TargetCodePoint: $00001ECD
    ),
    (
      SourceCodePoint: $00001ECE;
      TargetCodePoint: $00001ECF
    ),
    (
      SourceCodePoint: $00001ED0;
      TargetCodePoint: $00001ED1
    ),
    (
      SourceCodePoint: $00001ED2;
      TargetCodePoint: $00001ED3
    ),
    (
      SourceCodePoint: $00001ED4;
      TargetCodePoint: $00001ED5
    ),
    (
      SourceCodePoint: $00001ED6;
      TargetCodePoint: $00001ED7
    ),
    (
      SourceCodePoint: $00001ED8;
      TargetCodePoint: $00001ED9
    ),
    (
      SourceCodePoint: $00001EDA;
      TargetCodePoint: $00001EDB
    ),
    (
      SourceCodePoint: $00001EDC;
      TargetCodePoint: $00001EDD
    ),
    (
      SourceCodePoint: $00001EDE;
      TargetCodePoint: $00001EDF
    ),
    (
      SourceCodePoint: $00001EE0;
      TargetCodePoint: $00001EE1
    ),
    (
      SourceCodePoint: $00001EE2;
      TargetCodePoint: $00001EE3
    ),
    (
      SourceCodePoint: $00001EE4;
      TargetCodePoint: $00001EE5
    ),
    (
      SourceCodePoint: $00001EE6;
      TargetCodePoint: $00001EE7
    ),
    (
      SourceCodePoint: $00001EE8;
      TargetCodePoint: $00001EE9
    ),
    (
      SourceCodePoint: $00001EEA;
      TargetCodePoint: $00001EEB
    ),
    (
      SourceCodePoint: $00001EEC;
      TargetCodePoint: $00001EED
    ),
    (
      SourceCodePoint: $00001EEE;
      TargetCodePoint: $00001EEF
    ),
    (
      SourceCodePoint: $00001EF0;
      TargetCodePoint: $00001EF1
    ),
    (
      SourceCodePoint: $00001EF2;
      TargetCodePoint: $00001EF3
    ),
    (
      SourceCodePoint: $00001EF4;
      TargetCodePoint: $00001EF5
    ),
    (
      SourceCodePoint: $00001EF6;
      TargetCodePoint: $00001EF7
    ),
    (
      SourceCodePoint: $00001EF8;
      TargetCodePoint: $00001EF9
    ),
    (
      SourceCodePoint: $00001EFA;
      TargetCodePoint: $00001EFB
    ),
    (
      SourceCodePoint: $00001EFC;
      TargetCodePoint: $00001EFD
    ),
    (
      SourceCodePoint: $00001EFE;
      TargetCodePoint: $00001EFF
    ),
    (
      SourceCodePoint: $00001F08;
      TargetCodePoint: $00001F00
    ),
    (
      SourceCodePoint: $00001F09;
      TargetCodePoint: $00001F01
    ),
    (
      SourceCodePoint: $00001F0A;
      TargetCodePoint: $00001F02
    ),
    (
      SourceCodePoint: $00001F0B;
      TargetCodePoint: $00001F03
    ),
    (
      SourceCodePoint: $00001F0C;
      TargetCodePoint: $00001F04
    ),
    (
      SourceCodePoint: $00001F0D;
      TargetCodePoint: $00001F05
    ),
    (
      SourceCodePoint: $00001F0E;
      TargetCodePoint: $00001F06
    ),
    (
      SourceCodePoint: $00001F0F;
      TargetCodePoint: $00001F07
    ),
    (
      SourceCodePoint: $00001F18;
      TargetCodePoint: $00001F10
    ),
    (
      SourceCodePoint: $00001F19;
      TargetCodePoint: $00001F11
    ),
    (
      SourceCodePoint: $00001F1A;
      TargetCodePoint: $00001F12
    ),
    (
      SourceCodePoint: $00001F1B;
      TargetCodePoint: $00001F13
    ),
    (
      SourceCodePoint: $00001F1C;
      TargetCodePoint: $00001F14
    ),
    (
      SourceCodePoint: $00001F1D;
      TargetCodePoint: $00001F15
    ),
    (
      SourceCodePoint: $00001F28;
      TargetCodePoint: $00001F20
    ),
    (
      SourceCodePoint: $00001F29;
      TargetCodePoint: $00001F21
    ),
    (
      SourceCodePoint: $00001F2A;
      TargetCodePoint: $00001F22
    ),
    (
      SourceCodePoint: $00001F2B;
      TargetCodePoint: $00001F23
    ),
    (
      SourceCodePoint: $00001F2C;
      TargetCodePoint: $00001F24
    ),
    (
      SourceCodePoint: $00001F2D;
      TargetCodePoint: $00001F25
    ),
    (
      SourceCodePoint: $00001F2E;
      TargetCodePoint: $00001F26
    ),
    (
      SourceCodePoint: $00001F2F;
      TargetCodePoint: $00001F27
    ),
    (
      SourceCodePoint: $00001F38;
      TargetCodePoint: $00001F30
    ),
    (
      SourceCodePoint: $00001F39;
      TargetCodePoint: $00001F31
    ),
    (
      SourceCodePoint: $00001F3A;
      TargetCodePoint: $00001F32
    ),
    (
      SourceCodePoint: $00001F3B;
      TargetCodePoint: $00001F33
    ),
    (
      SourceCodePoint: $00001F3C;
      TargetCodePoint: $00001F34
    ),
    (
      SourceCodePoint: $00001F3D;
      TargetCodePoint: $00001F35
    ),
    (
      SourceCodePoint: $00001F3E;
      TargetCodePoint: $00001F36
    ),
    (
      SourceCodePoint: $00001F3F;
      TargetCodePoint: $00001F37
    ),
    (
      SourceCodePoint: $00001F48;
      TargetCodePoint: $00001F40
    ),
    (
      SourceCodePoint: $00001F49;
      TargetCodePoint: $00001F41
    ),
    (
      SourceCodePoint: $00001F4A;
      TargetCodePoint: $00001F42
    ),
    (
      SourceCodePoint: $00001F4B;
      TargetCodePoint: $00001F43
    ),
    (
      SourceCodePoint: $00001F4C;
      TargetCodePoint: $00001F44
    ),
    (
      SourceCodePoint: $00001F4D;
      TargetCodePoint: $00001F45
    ),
    (
      SourceCodePoint: $00001F59;
      TargetCodePoint: $00001F51
    ),
    (
      SourceCodePoint: $00001F5B;
      TargetCodePoint: $00001F53
    ),
    (
      SourceCodePoint: $00001F5D;
      TargetCodePoint: $00001F55
    ),
    (
      SourceCodePoint: $00001F5F;
      TargetCodePoint: $00001F57
    ),
    (
      SourceCodePoint: $00001F68;
      TargetCodePoint: $00001F60
    ),
    (
      SourceCodePoint: $00001F69;
      TargetCodePoint: $00001F61
    ),
    (
      SourceCodePoint: $00001F6A;
      TargetCodePoint: $00001F62
    ),
    (
      SourceCodePoint: $00001F6B;
      TargetCodePoint: $00001F63
    ),
    (
      SourceCodePoint: $00001F6C;
      TargetCodePoint: $00001F64
    ),
    (
      SourceCodePoint: $00001F6D;
      TargetCodePoint: $00001F65
    ),
    (
      SourceCodePoint: $00001F6E;
      TargetCodePoint: $00001F66
    ),
    (
      SourceCodePoint: $00001F6F;
      TargetCodePoint: $00001F67
    ),
    (
      SourceCodePoint: $00001F88;
      TargetCodePoint: $00001F80
    ),
    (
      SourceCodePoint: $00001F89;
      TargetCodePoint: $00001F81
    ),
    (
      SourceCodePoint: $00001F8A;
      TargetCodePoint: $00001F82
    ),
    (
      SourceCodePoint: $00001F8B;
      TargetCodePoint: $00001F83
    ),
    (
      SourceCodePoint: $00001F8C;
      TargetCodePoint: $00001F84
    ),
    (
      SourceCodePoint: $00001F8D;
      TargetCodePoint: $00001F85
    ),
    (
      SourceCodePoint: $00001F8E;
      TargetCodePoint: $00001F86
    ),
    (
      SourceCodePoint: $00001F8F;
      TargetCodePoint: $00001F87
    ),
    (
      SourceCodePoint: $00001F98;
      TargetCodePoint: $00001F90
    ),
    (
      SourceCodePoint: $00001F99;
      TargetCodePoint: $00001F91
    ),
    (
      SourceCodePoint: $00001F9A;
      TargetCodePoint: $00001F92
    ),
    (
      SourceCodePoint: $00001F9B;
      TargetCodePoint: $00001F93
    ),
    (
      SourceCodePoint: $00001F9C;
      TargetCodePoint: $00001F94
    ),
    (
      SourceCodePoint: $00001F9D;
      TargetCodePoint: $00001F95
    ),
    (
      SourceCodePoint: $00001F9E;
      TargetCodePoint: $00001F96
    ),
    (
      SourceCodePoint: $00001F9F;
      TargetCodePoint: $00001F97
    ),
    (
      SourceCodePoint: $00001FA8;
      TargetCodePoint: $00001FA0
    ),
    (
      SourceCodePoint: $00001FA9;
      TargetCodePoint: $00001FA1
    ),
    (
      SourceCodePoint: $00001FAA;
      TargetCodePoint: $00001FA2
    ),
    (
      SourceCodePoint: $00001FAB;
      TargetCodePoint: $00001FA3
    ),
    (
      SourceCodePoint: $00001FAC;
      TargetCodePoint: $00001FA4
    ),
    (
      SourceCodePoint: $00001FAD;
      TargetCodePoint: $00001FA5
    ),
    (
      SourceCodePoint: $00001FAE;
      TargetCodePoint: $00001FA6
    ),
    (
      SourceCodePoint: $00001FAF;
      TargetCodePoint: $00001FA7
    ),
    (
      SourceCodePoint: $00001FB8;
      TargetCodePoint: $00001FB0
    ),
    (
      SourceCodePoint: $00001FB9;
      TargetCodePoint: $00001FB1
    ),
    (
      SourceCodePoint: $00001FBA;
      TargetCodePoint: $00001F70
    ),
    (
      SourceCodePoint: $00001FBB;
      TargetCodePoint: $00001F71
    ),
    (
      SourceCodePoint: $00001FBC;
      TargetCodePoint: $00001FB3
    ),
    (
      SourceCodePoint: $00001FC8;
      TargetCodePoint: $00001F72
    ),
    (
      SourceCodePoint: $00001FC9;
      TargetCodePoint: $00001F73
    ),
    (
      SourceCodePoint: $00001FCA;
      TargetCodePoint: $00001F74
    ),
    (
      SourceCodePoint: $00001FCB;
      TargetCodePoint: $00001F75
    ),
    (
      SourceCodePoint: $00001FCC;
      TargetCodePoint: $00001FC3
    ),
    (
      SourceCodePoint: $00001FD8;
      TargetCodePoint: $00001FD0
    ),
    (
      SourceCodePoint: $00001FD9;
      TargetCodePoint: $00001FD1
    ),
    (
      SourceCodePoint: $00001FDA;
      TargetCodePoint: $00001F76
    ),
    (
      SourceCodePoint: $00001FDB;
      TargetCodePoint: $00001F77
    ),
    (
      SourceCodePoint: $00001FE8;
      TargetCodePoint: $00001FE0
    ),
    (
      SourceCodePoint: $00001FE9;
      TargetCodePoint: $00001FE1
    ),
    (
      SourceCodePoint: $00001FEA;
      TargetCodePoint: $00001F7A
    ),
    (
      SourceCodePoint: $00001FEB;
      TargetCodePoint: $00001F7B
    ),
    (
      SourceCodePoint: $00001FEC;
      TargetCodePoint: $00001FE5
    ),
    (
      SourceCodePoint: $00001FF8;
      TargetCodePoint: $00001F78
    ),
    (
      SourceCodePoint: $00001FF9;
      TargetCodePoint: $00001F79
    ),
    (
      SourceCodePoint: $00001FFA;
      TargetCodePoint: $00001F7C
    ),
    (
      SourceCodePoint: $00001FFB;
      TargetCodePoint: $00001F7D
    ),
    (
      SourceCodePoint: $00001FFC;
      TargetCodePoint: $00001FF3
    ),
    (
      SourceCodePoint: $00002126;
      TargetCodePoint: $000003C9
    ),
    (
      SourceCodePoint: $0000212A;
      TargetCodePoint: $0000006B
    ),
    (
      SourceCodePoint: $0000212B;
      TargetCodePoint: $000000E5
    ),
    (
      SourceCodePoint: $00002132;
      TargetCodePoint: $0000214E
    ),
    (
      SourceCodePoint: $00002160;
      TargetCodePoint: $00002170
    ),
    (
      SourceCodePoint: $00002161;
      TargetCodePoint: $00002171
    ),
    (
      SourceCodePoint: $00002162;
      TargetCodePoint: $00002172
    ),
    (
      SourceCodePoint: $00002163;
      TargetCodePoint: $00002173
    ),
    (
      SourceCodePoint: $00002164;
      TargetCodePoint: $00002174
    ),
    (
      SourceCodePoint: $00002165;
      TargetCodePoint: $00002175
    ),
    (
      SourceCodePoint: $00002166;
      TargetCodePoint: $00002176
    ),
    (
      SourceCodePoint: $00002167;
      TargetCodePoint: $00002177
    ),
    (
      SourceCodePoint: $00002168;
      TargetCodePoint: $00002178
    ),
    (
      SourceCodePoint: $00002169;
      TargetCodePoint: $00002179
    ),
    (
      SourceCodePoint: $0000216A;
      TargetCodePoint: $0000217A
    ),
    (
      SourceCodePoint: $0000216B;
      TargetCodePoint: $0000217B
    ),
    (
      SourceCodePoint: $0000216C;
      TargetCodePoint: $0000217C
    ),
    (
      SourceCodePoint: $0000216D;
      TargetCodePoint: $0000217D
    ),
    (
      SourceCodePoint: $0000216E;
      TargetCodePoint: $0000217E
    ),
    (
      SourceCodePoint: $0000216F;
      TargetCodePoint: $0000217F
    ),
    (
      SourceCodePoint: $00002183;
      TargetCodePoint: $00002184
    ),
    (
      SourceCodePoint: $000024B6;
      TargetCodePoint: $000024D0
    ),
    (
      SourceCodePoint: $000024B7;
      TargetCodePoint: $000024D1
    ),
    (
      SourceCodePoint: $000024B8;
      TargetCodePoint: $000024D2
    ),
    (
      SourceCodePoint: $000024B9;
      TargetCodePoint: $000024D3
    ),
    (
      SourceCodePoint: $000024BA;
      TargetCodePoint: $000024D4
    ),
    (
      SourceCodePoint: $000024BB;
      TargetCodePoint: $000024D5
    ),
    (
      SourceCodePoint: $000024BC;
      TargetCodePoint: $000024D6
    ),
    (
      SourceCodePoint: $000024BD;
      TargetCodePoint: $000024D7
    ),
    (
      SourceCodePoint: $000024BE;
      TargetCodePoint: $000024D8
    ),
    (
      SourceCodePoint: $000024BF;
      TargetCodePoint: $000024D9
    ),
    (
      SourceCodePoint: $000024C0;
      TargetCodePoint: $000024DA
    ),
    (
      SourceCodePoint: $000024C1;
      TargetCodePoint: $000024DB
    ),
    (
      SourceCodePoint: $000024C2;
      TargetCodePoint: $000024DC
    ),
    (
      SourceCodePoint: $000024C3;
      TargetCodePoint: $000024DD
    ),
    (
      SourceCodePoint: $000024C4;
      TargetCodePoint: $000024DE
    ),
    (
      SourceCodePoint: $000024C5;
      TargetCodePoint: $000024DF
    ),
    (
      SourceCodePoint: $000024C6;
      TargetCodePoint: $000024E0
    ),
    (
      SourceCodePoint: $000024C7;
      TargetCodePoint: $000024E1
    ),
    (
      SourceCodePoint: $000024C8;
      TargetCodePoint: $000024E2
    ),
    (
      SourceCodePoint: $000024C9;
      TargetCodePoint: $000024E3
    ),
    (
      SourceCodePoint: $000024CA;
      TargetCodePoint: $000024E4
    ),
    (
      SourceCodePoint: $000024CB;
      TargetCodePoint: $000024E5
    ),
    (
      SourceCodePoint: $000024CC;
      TargetCodePoint: $000024E6
    ),
    (
      SourceCodePoint: $000024CD;
      TargetCodePoint: $000024E7
    ),
    (
      SourceCodePoint: $000024CE;
      TargetCodePoint: $000024E8
    ),
    (
      SourceCodePoint: $000024CF;
      TargetCodePoint: $000024E9
    ),
    (
      SourceCodePoint: $00002C00;
      TargetCodePoint: $00002C30
    ),
    (
      SourceCodePoint: $00002C01;
      TargetCodePoint: $00002C31
    ),
    (
      SourceCodePoint: $00002C02;
      TargetCodePoint: $00002C32
    ),
    (
      SourceCodePoint: $00002C03;
      TargetCodePoint: $00002C33
    ),
    (
      SourceCodePoint: $00002C04;
      TargetCodePoint: $00002C34
    ),
    (
      SourceCodePoint: $00002C05;
      TargetCodePoint: $00002C35
    ),
    (
      SourceCodePoint: $00002C06;
      TargetCodePoint: $00002C36
    ),
    (
      SourceCodePoint: $00002C07;
      TargetCodePoint: $00002C37
    ),
    (
      SourceCodePoint: $00002C08;
      TargetCodePoint: $00002C38
    ),
    (
      SourceCodePoint: $00002C09;
      TargetCodePoint: $00002C39
    ),
    (
      SourceCodePoint: $00002C0A;
      TargetCodePoint: $00002C3A
    ),
    (
      SourceCodePoint: $00002C0B;
      TargetCodePoint: $00002C3B
    ),
    (
      SourceCodePoint: $00002C0C;
      TargetCodePoint: $00002C3C
    ),
    (
      SourceCodePoint: $00002C0D;
      TargetCodePoint: $00002C3D
    ),
    (
      SourceCodePoint: $00002C0E;
      TargetCodePoint: $00002C3E
    ),
    (
      SourceCodePoint: $00002C0F;
      TargetCodePoint: $00002C3F
    ),
    (
      SourceCodePoint: $00002C10;
      TargetCodePoint: $00002C40
    ),
    (
      SourceCodePoint: $00002C11;
      TargetCodePoint: $00002C41
    ),
    (
      SourceCodePoint: $00002C12;
      TargetCodePoint: $00002C42
    ),
    (
      SourceCodePoint: $00002C13;
      TargetCodePoint: $00002C43
    ),
    (
      SourceCodePoint: $00002C14;
      TargetCodePoint: $00002C44
    ),
    (
      SourceCodePoint: $00002C15;
      TargetCodePoint: $00002C45
    ),
    (
      SourceCodePoint: $00002C16;
      TargetCodePoint: $00002C46
    ),
    (
      SourceCodePoint: $00002C17;
      TargetCodePoint: $00002C47
    ),
    (
      SourceCodePoint: $00002C18;
      TargetCodePoint: $00002C48
    ),
    (
      SourceCodePoint: $00002C19;
      TargetCodePoint: $00002C49
    ),
    (
      SourceCodePoint: $00002C1A;
      TargetCodePoint: $00002C4A
    ),
    (
      SourceCodePoint: $00002C1B;
      TargetCodePoint: $00002C4B
    ),
    (
      SourceCodePoint: $00002C1C;
      TargetCodePoint: $00002C4C
    ),
    (
      SourceCodePoint: $00002C1D;
      TargetCodePoint: $00002C4D
    ),
    (
      SourceCodePoint: $00002C1E;
      TargetCodePoint: $00002C4E
    ),
    (
      SourceCodePoint: $00002C1F;
      TargetCodePoint: $00002C4F
    ),
    (
      SourceCodePoint: $00002C20;
      TargetCodePoint: $00002C50
    ),
    (
      SourceCodePoint: $00002C21;
      TargetCodePoint: $00002C51
    ),
    (
      SourceCodePoint: $00002C22;
      TargetCodePoint: $00002C52
    ),
    (
      SourceCodePoint: $00002C23;
      TargetCodePoint: $00002C53
    ),
    (
      SourceCodePoint: $00002C24;
      TargetCodePoint: $00002C54
    ),
    (
      SourceCodePoint: $00002C25;
      TargetCodePoint: $00002C55
    ),
    (
      SourceCodePoint: $00002C26;
      TargetCodePoint: $00002C56
    ),
    (
      SourceCodePoint: $00002C27;
      TargetCodePoint: $00002C57
    ),
    (
      SourceCodePoint: $00002C28;
      TargetCodePoint: $00002C58
    ),
    (
      SourceCodePoint: $00002C29;
      TargetCodePoint: $00002C59
    ),
    (
      SourceCodePoint: $00002C2A;
      TargetCodePoint: $00002C5A
    ),
    (
      SourceCodePoint: $00002C2B;
      TargetCodePoint: $00002C5B
    ),
    (
      SourceCodePoint: $00002C2C;
      TargetCodePoint: $00002C5C
    ),
    (
      SourceCodePoint: $00002C2D;
      TargetCodePoint: $00002C5D
    ),
    (
      SourceCodePoint: $00002C2E;
      TargetCodePoint: $00002C5E
    ),
    (
      SourceCodePoint: $00002C2F;
      TargetCodePoint: $00002C5F
    ),
    (
      SourceCodePoint: $00002C60;
      TargetCodePoint: $00002C61
    ),
    (
      SourceCodePoint: $00002C62;
      TargetCodePoint: $0000026B
    ),
    (
      SourceCodePoint: $00002C63;
      TargetCodePoint: $00001D7D
    ),
    (
      SourceCodePoint: $00002C64;
      TargetCodePoint: $0000027D
    ),
    (
      SourceCodePoint: $00002C67;
      TargetCodePoint: $00002C68
    ),
    (
      SourceCodePoint: $00002C69;
      TargetCodePoint: $00002C6A
    ),
    (
      SourceCodePoint: $00002C6B;
      TargetCodePoint: $00002C6C
    ),
    (
      SourceCodePoint: $00002C6D;
      TargetCodePoint: $00000251
    ),
    (
      SourceCodePoint: $00002C6E;
      TargetCodePoint: $00000271
    ),
    (
      SourceCodePoint: $00002C6F;
      TargetCodePoint: $00000250
    ),
    (
      SourceCodePoint: $00002C70;
      TargetCodePoint: $00000252
    ),
    (
      SourceCodePoint: $00002C72;
      TargetCodePoint: $00002C73
    ),
    (
      SourceCodePoint: $00002C75;
      TargetCodePoint: $00002C76
    ),
    (
      SourceCodePoint: $00002C7E;
      TargetCodePoint: $0000023F
    ),
    (
      SourceCodePoint: $00002C7F;
      TargetCodePoint: $00000240
    ),
    (
      SourceCodePoint: $00002C80;
      TargetCodePoint: $00002C81
    ),
    (
      SourceCodePoint: $00002C82;
      TargetCodePoint: $00002C83
    ),
    (
      SourceCodePoint: $00002C84;
      TargetCodePoint: $00002C85
    ),
    (
      SourceCodePoint: $00002C86;
      TargetCodePoint: $00002C87
    ),
    (
      SourceCodePoint: $00002C88;
      TargetCodePoint: $00002C89
    ),
    (
      SourceCodePoint: $00002C8A;
      TargetCodePoint: $00002C8B
    ),
    (
      SourceCodePoint: $00002C8C;
      TargetCodePoint: $00002C8D
    ),
    (
      SourceCodePoint: $00002C8E;
      TargetCodePoint: $00002C8F
    ),
    (
      SourceCodePoint: $00002C90;
      TargetCodePoint: $00002C91
    ),
    (
      SourceCodePoint: $00002C92;
      TargetCodePoint: $00002C93
    ),
    (
      SourceCodePoint: $00002C94;
      TargetCodePoint: $00002C95
    ),
    (
      SourceCodePoint: $00002C96;
      TargetCodePoint: $00002C97
    ),
    (
      SourceCodePoint: $00002C98;
      TargetCodePoint: $00002C99
    ),
    (
      SourceCodePoint: $00002C9A;
      TargetCodePoint: $00002C9B
    ),
    (
      SourceCodePoint: $00002C9C;
      TargetCodePoint: $00002C9D
    ),
    (
      SourceCodePoint: $00002C9E;
      TargetCodePoint: $00002C9F
    ),
    (
      SourceCodePoint: $00002CA0;
      TargetCodePoint: $00002CA1
    ),
    (
      SourceCodePoint: $00002CA2;
      TargetCodePoint: $00002CA3
    ),
    (
      SourceCodePoint: $00002CA4;
      TargetCodePoint: $00002CA5
    ),
    (
      SourceCodePoint: $00002CA6;
      TargetCodePoint: $00002CA7
    ),
    (
      SourceCodePoint: $00002CA8;
      TargetCodePoint: $00002CA9
    ),
    (
      SourceCodePoint: $00002CAA;
      TargetCodePoint: $00002CAB
    ),
    (
      SourceCodePoint: $00002CAC;
      TargetCodePoint: $00002CAD
    ),
    (
      SourceCodePoint: $00002CAE;
      TargetCodePoint: $00002CAF
    ),
    (
      SourceCodePoint: $00002CB0;
      TargetCodePoint: $00002CB1
    ),
    (
      SourceCodePoint: $00002CB2;
      TargetCodePoint: $00002CB3
    ),
    (
      SourceCodePoint: $00002CB4;
      TargetCodePoint: $00002CB5
    ),
    (
      SourceCodePoint: $00002CB6;
      TargetCodePoint: $00002CB7
    ),
    (
      SourceCodePoint: $00002CB8;
      TargetCodePoint: $00002CB9
    ),
    (
      SourceCodePoint: $00002CBA;
      TargetCodePoint: $00002CBB
    ),
    (
      SourceCodePoint: $00002CBC;
      TargetCodePoint: $00002CBD
    ),
    (
      SourceCodePoint: $00002CBE;
      TargetCodePoint: $00002CBF
    ),
    (
      SourceCodePoint: $00002CC0;
      TargetCodePoint: $00002CC1
    ),
    (
      SourceCodePoint: $00002CC2;
      TargetCodePoint: $00002CC3
    ),
    (
      SourceCodePoint: $00002CC4;
      TargetCodePoint: $00002CC5
    ),
    (
      SourceCodePoint: $00002CC6;
      TargetCodePoint: $00002CC7
    ),
    (
      SourceCodePoint: $00002CC8;
      TargetCodePoint: $00002CC9
    ),
    (
      SourceCodePoint: $00002CCA;
      TargetCodePoint: $00002CCB
    ),
    (
      SourceCodePoint: $00002CCC;
      TargetCodePoint: $00002CCD
    ),
    (
      SourceCodePoint: $00002CCE;
      TargetCodePoint: $00002CCF
    ),
    (
      SourceCodePoint: $00002CD0;
      TargetCodePoint: $00002CD1
    ),
    (
      SourceCodePoint: $00002CD2;
      TargetCodePoint: $00002CD3
    ),
    (
      SourceCodePoint: $00002CD4;
      TargetCodePoint: $00002CD5
    ),
    (
      SourceCodePoint: $00002CD6;
      TargetCodePoint: $00002CD7
    ),
    (
      SourceCodePoint: $00002CD8;
      TargetCodePoint: $00002CD9
    ),
    (
      SourceCodePoint: $00002CDA;
      TargetCodePoint: $00002CDB
    ),
    (
      SourceCodePoint: $00002CDC;
      TargetCodePoint: $00002CDD
    ),
    (
      SourceCodePoint: $00002CDE;
      TargetCodePoint: $00002CDF
    ),
    (
      SourceCodePoint: $00002CE0;
      TargetCodePoint: $00002CE1
    ),
    (
      SourceCodePoint: $00002CE2;
      TargetCodePoint: $00002CE3
    ),
    (
      SourceCodePoint: $00002CEB;
      TargetCodePoint: $00002CEC
    ),
    (
      SourceCodePoint: $00002CED;
      TargetCodePoint: $00002CEE
    ),
    (
      SourceCodePoint: $00002CF2;
      TargetCodePoint: $00002CF3
    ),
    (
      SourceCodePoint: $0000A640;
      TargetCodePoint: $0000A641
    ),
    (
      SourceCodePoint: $0000A642;
      TargetCodePoint: $0000A643
    ),
    (
      SourceCodePoint: $0000A644;
      TargetCodePoint: $0000A645
    ),
    (
      SourceCodePoint: $0000A646;
      TargetCodePoint: $0000A647
    ),
    (
      SourceCodePoint: $0000A648;
      TargetCodePoint: $0000A649
    ),
    (
      SourceCodePoint: $0000A64A;
      TargetCodePoint: $0000A64B
    ),
    (
      SourceCodePoint: $0000A64C;
      TargetCodePoint: $0000A64D
    ),
    (
      SourceCodePoint: $0000A64E;
      TargetCodePoint: $0000A64F
    ),
    (
      SourceCodePoint: $0000A650;
      TargetCodePoint: $0000A651
    ),
    (
      SourceCodePoint: $0000A652;
      TargetCodePoint: $0000A653
    ),
    (
      SourceCodePoint: $0000A654;
      TargetCodePoint: $0000A655
    ),
    (
      SourceCodePoint: $0000A656;
      TargetCodePoint: $0000A657
    ),
    (
      SourceCodePoint: $0000A658;
      TargetCodePoint: $0000A659
    ),
    (
      SourceCodePoint: $0000A65A;
      TargetCodePoint: $0000A65B
    ),
    (
      SourceCodePoint: $0000A65C;
      TargetCodePoint: $0000A65D
    ),
    (
      SourceCodePoint: $0000A65E;
      TargetCodePoint: $0000A65F
    ),
    (
      SourceCodePoint: $0000A660;
      TargetCodePoint: $0000A661
    ),
    (
      SourceCodePoint: $0000A662;
      TargetCodePoint: $0000A663
    ),
    (
      SourceCodePoint: $0000A664;
      TargetCodePoint: $0000A665
    ),
    (
      SourceCodePoint: $0000A666;
      TargetCodePoint: $0000A667
    ),
    (
      SourceCodePoint: $0000A668;
      TargetCodePoint: $0000A669
    ),
    (
      SourceCodePoint: $0000A66A;
      TargetCodePoint: $0000A66B
    ),
    (
      SourceCodePoint: $0000A66C;
      TargetCodePoint: $0000A66D
    ),
    (
      SourceCodePoint: $0000A680;
      TargetCodePoint: $0000A681
    ),
    (
      SourceCodePoint: $0000A682;
      TargetCodePoint: $0000A683
    ),
    (
      SourceCodePoint: $0000A684;
      TargetCodePoint: $0000A685
    ),
    (
      SourceCodePoint: $0000A686;
      TargetCodePoint: $0000A687
    ),
    (
      SourceCodePoint: $0000A688;
      TargetCodePoint: $0000A689
    ),
    (
      SourceCodePoint: $0000A68A;
      TargetCodePoint: $0000A68B
    ),
    (
      SourceCodePoint: $0000A68C;
      TargetCodePoint: $0000A68D
    ),
    (
      SourceCodePoint: $0000A68E;
      TargetCodePoint: $0000A68F
    ),
    (
      SourceCodePoint: $0000A690;
      TargetCodePoint: $0000A691
    ),
    (
      SourceCodePoint: $0000A692;
      TargetCodePoint: $0000A693
    ),
    (
      SourceCodePoint: $0000A694;
      TargetCodePoint: $0000A695
    ),
    (
      SourceCodePoint: $0000A696;
      TargetCodePoint: $0000A697
    ),
    (
      SourceCodePoint: $0000A698;
      TargetCodePoint: $0000A699
    ),
    (
      SourceCodePoint: $0000A69A;
      TargetCodePoint: $0000A69B
    ),
    (
      SourceCodePoint: $0000A722;
      TargetCodePoint: $0000A723
    ),
    (
      SourceCodePoint: $0000A724;
      TargetCodePoint: $0000A725
    ),
    (
      SourceCodePoint: $0000A726;
      TargetCodePoint: $0000A727
    ),
    (
      SourceCodePoint: $0000A728;
      TargetCodePoint: $0000A729
    ),
    (
      SourceCodePoint: $0000A72A;
      TargetCodePoint: $0000A72B
    ),
    (
      SourceCodePoint: $0000A72C;
      TargetCodePoint: $0000A72D
    ),
    (
      SourceCodePoint: $0000A72E;
      TargetCodePoint: $0000A72F
    ),
    (
      SourceCodePoint: $0000A732;
      TargetCodePoint: $0000A733
    ),
    (
      SourceCodePoint: $0000A734;
      TargetCodePoint: $0000A735
    ),
    (
      SourceCodePoint: $0000A736;
      TargetCodePoint: $0000A737
    ),
    (
      SourceCodePoint: $0000A738;
      TargetCodePoint: $0000A739
    ),
    (
      SourceCodePoint: $0000A73A;
      TargetCodePoint: $0000A73B
    ),
    (
      SourceCodePoint: $0000A73C;
      TargetCodePoint: $0000A73D
    ),
    (
      SourceCodePoint: $0000A73E;
      TargetCodePoint: $0000A73F
    ),
    (
      SourceCodePoint: $0000A740;
      TargetCodePoint: $0000A741
    ),
    (
      SourceCodePoint: $0000A742;
      TargetCodePoint: $0000A743
    ),
    (
      SourceCodePoint: $0000A744;
      TargetCodePoint: $0000A745
    ),
    (
      SourceCodePoint: $0000A746;
      TargetCodePoint: $0000A747
    ),
    (
      SourceCodePoint: $0000A748;
      TargetCodePoint: $0000A749
    ),
    (
      SourceCodePoint: $0000A74A;
      TargetCodePoint: $0000A74B
    ),
    (
      SourceCodePoint: $0000A74C;
      TargetCodePoint: $0000A74D
    ),
    (
      SourceCodePoint: $0000A74E;
      TargetCodePoint: $0000A74F
    ),
    (
      SourceCodePoint: $0000A750;
      TargetCodePoint: $0000A751
    ),
    (
      SourceCodePoint: $0000A752;
      TargetCodePoint: $0000A753
    ),
    (
      SourceCodePoint: $0000A754;
      TargetCodePoint: $0000A755
    ),
    (
      SourceCodePoint: $0000A756;
      TargetCodePoint: $0000A757
    ),
    (
      SourceCodePoint: $0000A758;
      TargetCodePoint: $0000A759
    ),
    (
      SourceCodePoint: $0000A75A;
      TargetCodePoint: $0000A75B
    ),
    (
      SourceCodePoint: $0000A75C;
      TargetCodePoint: $0000A75D
    ),
    (
      SourceCodePoint: $0000A75E;
      TargetCodePoint: $0000A75F
    ),
    (
      SourceCodePoint: $0000A760;
      TargetCodePoint: $0000A761
    ),
    (
      SourceCodePoint: $0000A762;
      TargetCodePoint: $0000A763
    ),
    (
      SourceCodePoint: $0000A764;
      TargetCodePoint: $0000A765
    ),
    (
      SourceCodePoint: $0000A766;
      TargetCodePoint: $0000A767
    ),
    (
      SourceCodePoint: $0000A768;
      TargetCodePoint: $0000A769
    ),
    (
      SourceCodePoint: $0000A76A;
      TargetCodePoint: $0000A76B
    ),
    (
      SourceCodePoint: $0000A76C;
      TargetCodePoint: $0000A76D
    ),
    (
      SourceCodePoint: $0000A76E;
      TargetCodePoint: $0000A76F
    ),
    (
      SourceCodePoint: $0000A779;
      TargetCodePoint: $0000A77A
    ),
    (
      SourceCodePoint: $0000A77B;
      TargetCodePoint: $0000A77C
    ),
    (
      SourceCodePoint: $0000A77D;
      TargetCodePoint: $00001D79
    ),
    (
      SourceCodePoint: $0000A77E;
      TargetCodePoint: $0000A77F
    ),
    (
      SourceCodePoint: $0000A780;
      TargetCodePoint: $0000A781
    ),
    (
      SourceCodePoint: $0000A782;
      TargetCodePoint: $0000A783
    ),
    (
      SourceCodePoint: $0000A784;
      TargetCodePoint: $0000A785
    ),
    (
      SourceCodePoint: $0000A786;
      TargetCodePoint: $0000A787
    ),
    (
      SourceCodePoint: $0000A78B;
      TargetCodePoint: $0000A78C
    ),
    (
      SourceCodePoint: $0000A78D;
      TargetCodePoint: $00000265
    ),
    (
      SourceCodePoint: $0000A790;
      TargetCodePoint: $0000A791
    ),
    (
      SourceCodePoint: $0000A792;
      TargetCodePoint: $0000A793
    ),
    (
      SourceCodePoint: $0000A796;
      TargetCodePoint: $0000A797
    ),
    (
      SourceCodePoint: $0000A798;
      TargetCodePoint: $0000A799
    ),
    (
      SourceCodePoint: $0000A79A;
      TargetCodePoint: $0000A79B
    ),
    (
      SourceCodePoint: $0000A79C;
      TargetCodePoint: $0000A79D
    ),
    (
      SourceCodePoint: $0000A79E;
      TargetCodePoint: $0000A79F
    ),
    (
      SourceCodePoint: $0000A7A0;
      TargetCodePoint: $0000A7A1
    ),
    (
      SourceCodePoint: $0000A7A2;
      TargetCodePoint: $0000A7A3
    ),
    (
      SourceCodePoint: $0000A7A4;
      TargetCodePoint: $0000A7A5
    ),
    (
      SourceCodePoint: $0000A7A6;
      TargetCodePoint: $0000A7A7
    ),
    (
      SourceCodePoint: $0000A7A8;
      TargetCodePoint: $0000A7A9
    ),
    (
      SourceCodePoint: $0000A7AA;
      TargetCodePoint: $00000266
    ),
    (
      SourceCodePoint: $0000A7AB;
      TargetCodePoint: $0000025C
    ),
    (
      SourceCodePoint: $0000A7AC;
      TargetCodePoint: $00000261
    ),
    (
      SourceCodePoint: $0000A7AD;
      TargetCodePoint: $0000026C
    ),
    (
      SourceCodePoint: $0000A7AE;
      TargetCodePoint: $0000026A
    ),
    (
      SourceCodePoint: $0000A7B0;
      TargetCodePoint: $0000029E
    ),
    (
      SourceCodePoint: $0000A7B1;
      TargetCodePoint: $00000287
    ),
    (
      SourceCodePoint: $0000A7B2;
      TargetCodePoint: $0000029D
    ),
    (
      SourceCodePoint: $0000A7B3;
      TargetCodePoint: $0000AB53
    ),
    (
      SourceCodePoint: $0000A7B4;
      TargetCodePoint: $0000A7B5
    ),
    (
      SourceCodePoint: $0000A7B6;
      TargetCodePoint: $0000A7B7
    ),
    (
      SourceCodePoint: $0000A7B8;
      TargetCodePoint: $0000A7B9
    ),
    (
      SourceCodePoint: $0000A7BA;
      TargetCodePoint: $0000A7BB
    ),
    (
      SourceCodePoint: $0000A7BC;
      TargetCodePoint: $0000A7BD
    ),
    (
      SourceCodePoint: $0000A7BE;
      TargetCodePoint: $0000A7BF
    ),
    (
      SourceCodePoint: $0000A7C0;
      TargetCodePoint: $0000A7C1
    ),
    (
      SourceCodePoint: $0000A7C2;
      TargetCodePoint: $0000A7C3
    ),
    (
      SourceCodePoint: $0000A7C4;
      TargetCodePoint: $0000A794
    ),
    (
      SourceCodePoint: $0000A7C5;
      TargetCodePoint: $00000282
    ),
    (
      SourceCodePoint: $0000A7C6;
      TargetCodePoint: $00001D8E
    ),
    (
      SourceCodePoint: $0000A7C7;
      TargetCodePoint: $0000A7C8
    ),
    (
      SourceCodePoint: $0000A7C9;
      TargetCodePoint: $0000A7CA
    ),
    (
      SourceCodePoint: $0000A7D0;
      TargetCodePoint: $0000A7D1
    ),
    (
      SourceCodePoint: $0000A7D6;
      TargetCodePoint: $0000A7D7
    ),
    (
      SourceCodePoint: $0000A7D8;
      TargetCodePoint: $0000A7D9
    ),
    (
      SourceCodePoint: $0000A7F5;
      TargetCodePoint: $0000A7F6
    ),
    (
      SourceCodePoint: $0000FF21;
      TargetCodePoint: $0000FF41
    ),
    (
      SourceCodePoint: $0000FF22;
      TargetCodePoint: $0000FF42
    ),
    (
      SourceCodePoint: $0000FF23;
      TargetCodePoint: $0000FF43
    ),
    (
      SourceCodePoint: $0000FF24;
      TargetCodePoint: $0000FF44
    ),
    (
      SourceCodePoint: $0000FF25;
      TargetCodePoint: $0000FF45
    ),
    (
      SourceCodePoint: $0000FF26;
      TargetCodePoint: $0000FF46
    ),
    (
      SourceCodePoint: $0000FF27;
      TargetCodePoint: $0000FF47
    ),
    (
      SourceCodePoint: $0000FF28;
      TargetCodePoint: $0000FF48
    ),
    (
      SourceCodePoint: $0000FF29;
      TargetCodePoint: $0000FF49
    ),
    (
      SourceCodePoint: $0000FF2A;
      TargetCodePoint: $0000FF4A
    ),
    (
      SourceCodePoint: $0000FF2B;
      TargetCodePoint: $0000FF4B
    ),
    (
      SourceCodePoint: $0000FF2C;
      TargetCodePoint: $0000FF4C
    ),
    (
      SourceCodePoint: $0000FF2D;
      TargetCodePoint: $0000FF4D
    ),
    (
      SourceCodePoint: $0000FF2E;
      TargetCodePoint: $0000FF4E
    ),
    (
      SourceCodePoint: $0000FF2F;
      TargetCodePoint: $0000FF4F
    ),
    (
      SourceCodePoint: $0000FF30;
      TargetCodePoint: $0000FF50
    ),
    (
      SourceCodePoint: $0000FF31;
      TargetCodePoint: $0000FF51
    ),
    (
      SourceCodePoint: $0000FF32;
      TargetCodePoint: $0000FF52
    ),
    (
      SourceCodePoint: $0000FF33;
      TargetCodePoint: $0000FF53
    ),
    (
      SourceCodePoint: $0000FF34;
      TargetCodePoint: $0000FF54
    ),
    (
      SourceCodePoint: $0000FF35;
      TargetCodePoint: $0000FF55
    ),
    (
      SourceCodePoint: $0000FF36;
      TargetCodePoint: $0000FF56
    ),
    (
      SourceCodePoint: $0000FF37;
      TargetCodePoint: $0000FF57
    ),
    (
      SourceCodePoint: $0000FF38;
      TargetCodePoint: $0000FF58
    ),
    (
      SourceCodePoint: $0000FF39;
      TargetCodePoint: $0000FF59
    ),
    (
      SourceCodePoint: $0000FF3A;
      TargetCodePoint: $0000FF5A
    ),
    (
      SourceCodePoint: $00010400;
      TargetCodePoint: $00010428
    ),
    (
      SourceCodePoint: $00010401;
      TargetCodePoint: $00010429
    ),
    (
      SourceCodePoint: $00010402;
      TargetCodePoint: $0001042A
    ),
    (
      SourceCodePoint: $00010403;
      TargetCodePoint: $0001042B
    ),
    (
      SourceCodePoint: $00010404;
      TargetCodePoint: $0001042C
    ),
    (
      SourceCodePoint: $00010405;
      TargetCodePoint: $0001042D
    ),
    (
      SourceCodePoint: $00010406;
      TargetCodePoint: $0001042E
    ),
    (
      SourceCodePoint: $00010407;
      TargetCodePoint: $0001042F
    ),
    (
      SourceCodePoint: $00010408;
      TargetCodePoint: $00010430
    ),
    (
      SourceCodePoint: $00010409;
      TargetCodePoint: $00010431
    ),
    (
      SourceCodePoint: $0001040A;
      TargetCodePoint: $00010432
    ),
    (
      SourceCodePoint: $0001040B;
      TargetCodePoint: $00010433
    ),
    (
      SourceCodePoint: $0001040C;
      TargetCodePoint: $00010434
    ),
    (
      SourceCodePoint: $0001040D;
      TargetCodePoint: $00010435
    ),
    (
      SourceCodePoint: $0001040E;
      TargetCodePoint: $00010436
    ),
    (
      SourceCodePoint: $0001040F;
      TargetCodePoint: $00010437
    ),
    (
      SourceCodePoint: $00010410;
      TargetCodePoint: $00010438
    ),
    (
      SourceCodePoint: $00010411;
      TargetCodePoint: $00010439
    ),
    (
      SourceCodePoint: $00010412;
      TargetCodePoint: $0001043A
    ),
    (
      SourceCodePoint: $00010413;
      TargetCodePoint: $0001043B
    ),
    (
      SourceCodePoint: $00010414;
      TargetCodePoint: $0001043C
    ),
    (
      SourceCodePoint: $00010415;
      TargetCodePoint: $0001043D
    ),
    (
      SourceCodePoint: $00010416;
      TargetCodePoint: $0001043E
    ),
    (
      SourceCodePoint: $00010417;
      TargetCodePoint: $0001043F
    ),
    (
      SourceCodePoint: $00010418;
      TargetCodePoint: $00010440
    ),
    (
      SourceCodePoint: $00010419;
      TargetCodePoint: $00010441
    ),
    (
      SourceCodePoint: $0001041A;
      TargetCodePoint: $00010442
    ),
    (
      SourceCodePoint: $0001041B;
      TargetCodePoint: $00010443
    ),
    (
      SourceCodePoint: $0001041C;
      TargetCodePoint: $00010444
    ),
    (
      SourceCodePoint: $0001041D;
      TargetCodePoint: $00010445
    ),
    (
      SourceCodePoint: $0001041E;
      TargetCodePoint: $00010446
    ),
    (
      SourceCodePoint: $0001041F;
      TargetCodePoint: $00010447
    ),
    (
      SourceCodePoint: $00010420;
      TargetCodePoint: $00010448
    ),
    (
      SourceCodePoint: $00010421;
      TargetCodePoint: $00010449
    ),
    (
      SourceCodePoint: $00010422;
      TargetCodePoint: $0001044A
    ),
    (
      SourceCodePoint: $00010423;
      TargetCodePoint: $0001044B
    ),
    (
      SourceCodePoint: $00010424;
      TargetCodePoint: $0001044C
    ),
    (
      SourceCodePoint: $00010425;
      TargetCodePoint: $0001044D
    ),
    (
      SourceCodePoint: $00010426;
      TargetCodePoint: $0001044E
    ),
    (
      SourceCodePoint: $00010427;
      TargetCodePoint: $0001044F
    ),
    (
      SourceCodePoint: $000104B0;
      TargetCodePoint: $000104D8
    ),
    (
      SourceCodePoint: $000104B1;
      TargetCodePoint: $000104D9
    ),
    (
      SourceCodePoint: $000104B2;
      TargetCodePoint: $000104DA
    ),
    (
      SourceCodePoint: $000104B3;
      TargetCodePoint: $000104DB
    ),
    (
      SourceCodePoint: $000104B4;
      TargetCodePoint: $000104DC
    ),
    (
      SourceCodePoint: $000104B5;
      TargetCodePoint: $000104DD
    ),
    (
      SourceCodePoint: $000104B6;
      TargetCodePoint: $000104DE
    ),
    (
      SourceCodePoint: $000104B7;
      TargetCodePoint: $000104DF
    ),
    (
      SourceCodePoint: $000104B8;
      TargetCodePoint: $000104E0
    ),
    (
      SourceCodePoint: $000104B9;
      TargetCodePoint: $000104E1
    ),
    (
      SourceCodePoint: $000104BA;
      TargetCodePoint: $000104E2
    ),
    (
      SourceCodePoint: $000104BB;
      TargetCodePoint: $000104E3
    ),
    (
      SourceCodePoint: $000104BC;
      TargetCodePoint: $000104E4
    ),
    (
      SourceCodePoint: $000104BD;
      TargetCodePoint: $000104E5
    ),
    (
      SourceCodePoint: $000104BE;
      TargetCodePoint: $000104E6
    ),
    (
      SourceCodePoint: $000104BF;
      TargetCodePoint: $000104E7
    ),
    (
      SourceCodePoint: $000104C0;
      TargetCodePoint: $000104E8
    ),
    (
      SourceCodePoint: $000104C1;
      TargetCodePoint: $000104E9
    ),
    (
      SourceCodePoint: $000104C2;
      TargetCodePoint: $000104EA
    ),
    (
      SourceCodePoint: $000104C3;
      TargetCodePoint: $000104EB
    ),
    (
      SourceCodePoint: $000104C4;
      TargetCodePoint: $000104EC
    ),
    (
      SourceCodePoint: $000104C5;
      TargetCodePoint: $000104ED
    ),
    (
      SourceCodePoint: $000104C6;
      TargetCodePoint: $000104EE
    ),
    (
      SourceCodePoint: $000104C7;
      TargetCodePoint: $000104EF
    ),
    (
      SourceCodePoint: $000104C8;
      TargetCodePoint: $000104F0
    ),
    (
      SourceCodePoint: $000104C9;
      TargetCodePoint: $000104F1
    ),
    (
      SourceCodePoint: $000104CA;
      TargetCodePoint: $000104F2
    ),
    (
      SourceCodePoint: $000104CB;
      TargetCodePoint: $000104F3
    ),
    (
      SourceCodePoint: $000104CC;
      TargetCodePoint: $000104F4
    ),
    (
      SourceCodePoint: $000104CD;
      TargetCodePoint: $000104F5
    ),
    (
      SourceCodePoint: $000104CE;
      TargetCodePoint: $000104F6
    ),
    (
      SourceCodePoint: $000104CF;
      TargetCodePoint: $000104F7
    ),
    (
      SourceCodePoint: $000104D0;
      TargetCodePoint: $000104F8
    ),
    (
      SourceCodePoint: $000104D1;
      TargetCodePoint: $000104F9
    ),
    (
      SourceCodePoint: $000104D2;
      TargetCodePoint: $000104FA
    ),
    (
      SourceCodePoint: $000104D3;
      TargetCodePoint: $000104FB
    ),
    (
      SourceCodePoint: $00010570;
      TargetCodePoint: $00010597
    ),
    (
      SourceCodePoint: $00010571;
      TargetCodePoint: $00010598
    ),
    (
      SourceCodePoint: $00010572;
      TargetCodePoint: $00010599
    ),
    (
      SourceCodePoint: $00010573;
      TargetCodePoint: $0001059A
    ),
    (
      SourceCodePoint: $00010574;
      TargetCodePoint: $0001059B
    ),
    (
      SourceCodePoint: $00010575;
      TargetCodePoint: $0001059C
    ),
    (
      SourceCodePoint: $00010576;
      TargetCodePoint: $0001059D
    ),
    (
      SourceCodePoint: $00010577;
      TargetCodePoint: $0001059E
    ),
    (
      SourceCodePoint: $00010578;
      TargetCodePoint: $0001059F
    ),
    (
      SourceCodePoint: $00010579;
      TargetCodePoint: $000105A0
    ),
    (
      SourceCodePoint: $0001057A;
      TargetCodePoint: $000105A1
    ),
    (
      SourceCodePoint: $0001057C;
      TargetCodePoint: $000105A3
    ),
    (
      SourceCodePoint: $0001057D;
      TargetCodePoint: $000105A4
    ),
    (
      SourceCodePoint: $0001057E;
      TargetCodePoint: $000105A5
    ),
    (
      SourceCodePoint: $0001057F;
      TargetCodePoint: $000105A6
    ),
    (
      SourceCodePoint: $00010580;
      TargetCodePoint: $000105A7
    ),
    (
      SourceCodePoint: $00010581;
      TargetCodePoint: $000105A8
    ),
    (
      SourceCodePoint: $00010582;
      TargetCodePoint: $000105A9
    ),
    (
      SourceCodePoint: $00010583;
      TargetCodePoint: $000105AA
    ),
    (
      SourceCodePoint: $00010584;
      TargetCodePoint: $000105AB
    ),
    (
      SourceCodePoint: $00010585;
      TargetCodePoint: $000105AC
    ),
    (
      SourceCodePoint: $00010586;
      TargetCodePoint: $000105AD
    ),
    (
      SourceCodePoint: $00010587;
      TargetCodePoint: $000105AE
    ),
    (
      SourceCodePoint: $00010588;
      TargetCodePoint: $000105AF
    ),
    (
      SourceCodePoint: $00010589;
      TargetCodePoint: $000105B0
    ),
    (
      SourceCodePoint: $0001058A;
      TargetCodePoint: $000105B1
    ),
    (
      SourceCodePoint: $0001058C;
      TargetCodePoint: $000105B3
    ),
    (
      SourceCodePoint: $0001058D;
      TargetCodePoint: $000105B4
    ),
    (
      SourceCodePoint: $0001058E;
      TargetCodePoint: $000105B5
    ),
    (
      SourceCodePoint: $0001058F;
      TargetCodePoint: $000105B6
    ),
    (
      SourceCodePoint: $00010590;
      TargetCodePoint: $000105B7
    ),
    (
      SourceCodePoint: $00010591;
      TargetCodePoint: $000105B8
    ),
    (
      SourceCodePoint: $00010592;
      TargetCodePoint: $000105B9
    ),
    (
      SourceCodePoint: $00010594;
      TargetCodePoint: $000105BB
    ),
    (
      SourceCodePoint: $00010595;
      TargetCodePoint: $000105BC
    ),
    (
      SourceCodePoint: $00010C80;
      TargetCodePoint: $00010CC0
    ),
    (
      SourceCodePoint: $00010C81;
      TargetCodePoint: $00010CC1
    ),
    (
      SourceCodePoint: $00010C82;
      TargetCodePoint: $00010CC2
    ),
    (
      SourceCodePoint: $00010C83;
      TargetCodePoint: $00010CC3
    ),
    (
      SourceCodePoint: $00010C84;
      TargetCodePoint: $00010CC4
    ),
    (
      SourceCodePoint: $00010C85;
      TargetCodePoint: $00010CC5
    ),
    (
      SourceCodePoint: $00010C86;
      TargetCodePoint: $00010CC6
    ),
    (
      SourceCodePoint: $00010C87;
      TargetCodePoint: $00010CC7
    ),
    (
      SourceCodePoint: $00010C88;
      TargetCodePoint: $00010CC8
    ),
    (
      SourceCodePoint: $00010C89;
      TargetCodePoint: $00010CC9
    ),
    (
      SourceCodePoint: $00010C8A;
      TargetCodePoint: $00010CCA
    ),
    (
      SourceCodePoint: $00010C8B;
      TargetCodePoint: $00010CCB
    ),
    (
      SourceCodePoint: $00010C8C;
      TargetCodePoint: $00010CCC
    ),
    (
      SourceCodePoint: $00010C8D;
      TargetCodePoint: $00010CCD
    ),
    (
      SourceCodePoint: $00010C8E;
      TargetCodePoint: $00010CCE
    ),
    (
      SourceCodePoint: $00010C8F;
      TargetCodePoint: $00010CCF
    ),
    (
      SourceCodePoint: $00010C90;
      TargetCodePoint: $00010CD0
    ),
    (
      SourceCodePoint: $00010C91;
      TargetCodePoint: $00010CD1
    ),
    (
      SourceCodePoint: $00010C92;
      TargetCodePoint: $00010CD2
    ),
    (
      SourceCodePoint: $00010C93;
      TargetCodePoint: $00010CD3
    ),
    (
      SourceCodePoint: $00010C94;
      TargetCodePoint: $00010CD4
    ),
    (
      SourceCodePoint: $00010C95;
      TargetCodePoint: $00010CD5
    ),
    (
      SourceCodePoint: $00010C96;
      TargetCodePoint: $00010CD6
    ),
    (
      SourceCodePoint: $00010C97;
      TargetCodePoint: $00010CD7
    ),
    (
      SourceCodePoint: $00010C98;
      TargetCodePoint: $00010CD8
    ),
    (
      SourceCodePoint: $00010C99;
      TargetCodePoint: $00010CD9
    ),
    (
      SourceCodePoint: $00010C9A;
      TargetCodePoint: $00010CDA
    ),
    (
      SourceCodePoint: $00010C9B;
      TargetCodePoint: $00010CDB
    ),
    (
      SourceCodePoint: $00010C9C;
      TargetCodePoint: $00010CDC
    ),
    (
      SourceCodePoint: $00010C9D;
      TargetCodePoint: $00010CDD
    ),
    (
      SourceCodePoint: $00010C9E;
      TargetCodePoint: $00010CDE
    ),
    (
      SourceCodePoint: $00010C9F;
      TargetCodePoint: $00010CDF
    ),
    (
      SourceCodePoint: $00010CA0;
      TargetCodePoint: $00010CE0
    ),
    (
      SourceCodePoint: $00010CA1;
      TargetCodePoint: $00010CE1
    ),
    (
      SourceCodePoint: $00010CA2;
      TargetCodePoint: $00010CE2
    ),
    (
      SourceCodePoint: $00010CA3;
      TargetCodePoint: $00010CE3
    ),
    (
      SourceCodePoint: $00010CA4;
      TargetCodePoint: $00010CE4
    ),
    (
      SourceCodePoint: $00010CA5;
      TargetCodePoint: $00010CE5
    ),
    (
      SourceCodePoint: $00010CA6;
      TargetCodePoint: $00010CE6
    ),
    (
      SourceCodePoint: $00010CA7;
      TargetCodePoint: $00010CE7
    ),
    (
      SourceCodePoint: $00010CA8;
      TargetCodePoint: $00010CE8
    ),
    (
      SourceCodePoint: $00010CA9;
      TargetCodePoint: $00010CE9
    ),
    (
      SourceCodePoint: $00010CAA;
      TargetCodePoint: $00010CEA
    ),
    (
      SourceCodePoint: $00010CAB;
      TargetCodePoint: $00010CEB
    ),
    (
      SourceCodePoint: $00010CAC;
      TargetCodePoint: $00010CEC
    ),
    (
      SourceCodePoint: $00010CAD;
      TargetCodePoint: $00010CED
    ),
    (
      SourceCodePoint: $00010CAE;
      TargetCodePoint: $00010CEE
    ),
    (
      SourceCodePoint: $00010CAF;
      TargetCodePoint: $00010CEF
    ),
    (
      SourceCodePoint: $00010CB0;
      TargetCodePoint: $00010CF0
    ),
    (
      SourceCodePoint: $00010CB1;
      TargetCodePoint: $00010CF1
    ),
    (
      SourceCodePoint: $00010CB2;
      TargetCodePoint: $00010CF2
    ),
    (
      SourceCodePoint: $000118A0;
      TargetCodePoint: $000118C0
    ),
    (
      SourceCodePoint: $000118A1;
      TargetCodePoint: $000118C1
    ),
    (
      SourceCodePoint: $000118A2;
      TargetCodePoint: $000118C2
    ),
    (
      SourceCodePoint: $000118A3;
      TargetCodePoint: $000118C3
    ),
    (
      SourceCodePoint: $000118A4;
      TargetCodePoint: $000118C4
    ),
    (
      SourceCodePoint: $000118A5;
      TargetCodePoint: $000118C5
    ),
    (
      SourceCodePoint: $000118A6;
      TargetCodePoint: $000118C6
    ),
    (
      SourceCodePoint: $000118A7;
      TargetCodePoint: $000118C7
    ),
    (
      SourceCodePoint: $000118A8;
      TargetCodePoint: $000118C8
    ),
    (
      SourceCodePoint: $000118A9;
      TargetCodePoint: $000118C9
    ),
    (
      SourceCodePoint: $000118AA;
      TargetCodePoint: $000118CA
    ),
    (
      SourceCodePoint: $000118AB;
      TargetCodePoint: $000118CB
    ),
    (
      SourceCodePoint: $000118AC;
      TargetCodePoint: $000118CC
    ),
    (
      SourceCodePoint: $000118AD;
      TargetCodePoint: $000118CD
    ),
    (
      SourceCodePoint: $000118AE;
      TargetCodePoint: $000118CE
    ),
    (
      SourceCodePoint: $000118AF;
      TargetCodePoint: $000118CF
    ),
    (
      SourceCodePoint: $000118B0;
      TargetCodePoint: $000118D0
    ),
    (
      SourceCodePoint: $000118B1;
      TargetCodePoint: $000118D1
    ),
    (
      SourceCodePoint: $000118B2;
      TargetCodePoint: $000118D2
    ),
    (
      SourceCodePoint: $000118B3;
      TargetCodePoint: $000118D3
    ),
    (
      SourceCodePoint: $000118B4;
      TargetCodePoint: $000118D4
    ),
    (
      SourceCodePoint: $000118B5;
      TargetCodePoint: $000118D5
    ),
    (
      SourceCodePoint: $000118B6;
      TargetCodePoint: $000118D6
    ),
    (
      SourceCodePoint: $000118B7;
      TargetCodePoint: $000118D7
    ),
    (
      SourceCodePoint: $000118B8;
      TargetCodePoint: $000118D8
    ),
    (
      SourceCodePoint: $000118B9;
      TargetCodePoint: $000118D9
    ),
    (
      SourceCodePoint: $000118BA;
      TargetCodePoint: $000118DA
    ),
    (
      SourceCodePoint: $000118BB;
      TargetCodePoint: $000118DB
    ),
    (
      SourceCodePoint: $000118BC;
      TargetCodePoint: $000118DC
    ),
    (
      SourceCodePoint: $000118BD;
      TargetCodePoint: $000118DD
    ),
    (
      SourceCodePoint: $000118BE;
      TargetCodePoint: $000118DE
    ),
    (
      SourceCodePoint: $000118BF;
      TargetCodePoint: $000118DF
    ),
    (
      SourceCodePoint: $00016E40;
      TargetCodePoint: $00016E60
    ),
    (
      SourceCodePoint: $00016E41;
      TargetCodePoint: $00016E61
    ),
    (
      SourceCodePoint: $00016E42;
      TargetCodePoint: $00016E62
    ),
    (
      SourceCodePoint: $00016E43;
      TargetCodePoint: $00016E63
    ),
    (
      SourceCodePoint: $00016E44;
      TargetCodePoint: $00016E64
    ),
    (
      SourceCodePoint: $00016E45;
      TargetCodePoint: $00016E65
    ),
    (
      SourceCodePoint: $00016E46;
      TargetCodePoint: $00016E66
    ),
    (
      SourceCodePoint: $00016E47;
      TargetCodePoint: $00016E67
    ),
    (
      SourceCodePoint: $00016E48;
      TargetCodePoint: $00016E68
    ),
    (
      SourceCodePoint: $00016E49;
      TargetCodePoint: $00016E69
    ),
    (
      SourceCodePoint: $00016E4A;
      TargetCodePoint: $00016E6A
    ),
    (
      SourceCodePoint: $00016E4B;
      TargetCodePoint: $00016E6B
    ),
    (
      SourceCodePoint: $00016E4C;
      TargetCodePoint: $00016E6C
    ),
    (
      SourceCodePoint: $00016E4D;
      TargetCodePoint: $00016E6D
    ),
    (
      SourceCodePoint: $00016E4E;
      TargetCodePoint: $00016E6E
    ),
    (
      SourceCodePoint: $00016E4F;
      TargetCodePoint: $00016E6F
    ),
    (
      SourceCodePoint: $00016E50;
      TargetCodePoint: $00016E70
    ),
    (
      SourceCodePoint: $00016E51;
      TargetCodePoint: $00016E71
    ),
    (
      SourceCodePoint: $00016E52;
      TargetCodePoint: $00016E72
    ),
    (
      SourceCodePoint: $00016E53;
      TargetCodePoint: $00016E73
    ),
    (
      SourceCodePoint: $00016E54;
      TargetCodePoint: $00016E74
    ),
    (
      SourceCodePoint: $00016E55;
      TargetCodePoint: $00016E75
    ),
    (
      SourceCodePoint: $00016E56;
      TargetCodePoint: $00016E76
    ),
    (
      SourceCodePoint: $00016E57;
      TargetCodePoint: $00016E77
    ),
    (
      SourceCodePoint: $00016E58;
      TargetCodePoint: $00016E78
    ),
    (
      SourceCodePoint: $00016E59;
      TargetCodePoint: $00016E79
    ),
    (
      SourceCodePoint: $00016E5A;
      TargetCodePoint: $00016E7A
    ),
    (
      SourceCodePoint: $00016E5B;
      TargetCodePoint: $00016E7B
    ),
    (
      SourceCodePoint: $00016E5C;
      TargetCodePoint: $00016E7C
    ),
    (
      SourceCodePoint: $00016E5D;
      TargetCodePoint: $00016E7D
    ),
    (
      SourceCodePoint: $00016E5E;
      TargetCodePoint: $00016E7E
    ),
    (
      SourceCodePoint: $00016E5F;
      TargetCodePoint: $00016E7F
    ),
    (
      SourceCodePoint: $0001E900;
      TargetCodePoint: $0001E922
    ),
    (
      SourceCodePoint: $0001E901;
      TargetCodePoint: $0001E923
    ),
    (
      SourceCodePoint: $0001E902;
      TargetCodePoint: $0001E924
    ),
    (
      SourceCodePoint: $0001E903;
      TargetCodePoint: $0001E925
    ),
    (
      SourceCodePoint: $0001E904;
      TargetCodePoint: $0001E926
    ),
    (
      SourceCodePoint: $0001E905;
      TargetCodePoint: $0001E927
    ),
    (
      SourceCodePoint: $0001E906;
      TargetCodePoint: $0001E928
    ),
    (
      SourceCodePoint: $0001E907;
      TargetCodePoint: $0001E929
    ),
    (
      SourceCodePoint: $0001E908;
      TargetCodePoint: $0001E92A
    ),
    (
      SourceCodePoint: $0001E909;
      TargetCodePoint: $0001E92B
    ),
    (
      SourceCodePoint: $0001E90A;
      TargetCodePoint: $0001E92C
    ),
    (
      SourceCodePoint: $0001E90B;
      TargetCodePoint: $0001E92D
    ),
    (
      SourceCodePoint: $0001E90C;
      TargetCodePoint: $0001E92E
    ),
    (
      SourceCodePoint: $0001E90D;
      TargetCodePoint: $0001E92F
    ),
    (
      SourceCodePoint: $0001E90E;
      TargetCodePoint: $0001E930
    ),
    (
      SourceCodePoint: $0001E90F;
      TargetCodePoint: $0001E931
    ),
    (
      SourceCodePoint: $0001E910;
      TargetCodePoint: $0001E932
    ),
    (
      SourceCodePoint: $0001E911;
      TargetCodePoint: $0001E933
    ),
    (
      SourceCodePoint: $0001E912;
      TargetCodePoint: $0001E934
    ),
    (
      SourceCodePoint: $0001E913;
      TargetCodePoint: $0001E935
    ),
    (
      SourceCodePoint: $0001E914;
      TargetCodePoint: $0001E936
    ),
    (
      SourceCodePoint: $0001E915;
      TargetCodePoint: $0001E937
    ),
    (
      SourceCodePoint: $0001E916;
      TargetCodePoint: $0001E938
    ),
    (
      SourceCodePoint: $0001E917;
      TargetCodePoint: $0001E939
    ),
    (
      SourceCodePoint: $0001E918;
      TargetCodePoint: $0001E93A
    ),
    (
      SourceCodePoint: $0001E919;
      TargetCodePoint: $0001E93B
    ),
    (
      SourceCodePoint: $0001E91A;
      TargetCodePoint: $0001E93C
    ),
    (
      SourceCodePoint: $0001E91B;
      TargetCodePoint: $0001E93D
    ),
    (
      SourceCodePoint: $0001E91C;
      TargetCodePoint: $0001E93E
    ),
    (
      SourceCodePoint: $0001E91D;
      TargetCodePoint: $0001E93F
    ),
    (
      SourceCodePoint: $0001E91E;
      TargetCodePoint: $0001E940
    ),
    (
      SourceCodePoint: $0001E91F;
      TargetCodePoint: $0001E941
    ),
    (
      SourceCodePoint: $0001E920;
      TargetCodePoint: $0001E942
    ),
    (
      SourceCodePoint: $0001E921;
      TargetCodePoint: $0001E943
    )
  );

  UNICODE_SIMPLE_UPPER_MAP: array[0..1422] of TUnicodeMapping = (
    (
      SourceCodePoint: $00000061;
      TargetCodePoint: $00000041
    ),
    (
      SourceCodePoint: $00000062;
      TargetCodePoint: $00000042
    ),
    (
      SourceCodePoint: $00000063;
      TargetCodePoint: $00000043
    ),
    (
      SourceCodePoint: $00000064;
      TargetCodePoint: $00000044
    ),
    (
      SourceCodePoint: $00000065;
      TargetCodePoint: $00000045
    ),
    (
      SourceCodePoint: $00000066;
      TargetCodePoint: $00000046
    ),
    (
      SourceCodePoint: $00000067;
      TargetCodePoint: $00000047
    ),
    (
      SourceCodePoint: $00000068;
      TargetCodePoint: $00000048
    ),
    (
      SourceCodePoint: $00000069;
      TargetCodePoint: $00000049
    ),
    (
      SourceCodePoint: $0000006A;
      TargetCodePoint: $0000004A
    ),
    (
      SourceCodePoint: $0000006B;
      TargetCodePoint: $0000004B
    ),
    (
      SourceCodePoint: $0000006C;
      TargetCodePoint: $0000004C
    ),
    (
      SourceCodePoint: $0000006D;
      TargetCodePoint: $0000004D
    ),
    (
      SourceCodePoint: $0000006E;
      TargetCodePoint: $0000004E
    ),
    (
      SourceCodePoint: $0000006F;
      TargetCodePoint: $0000004F
    ),
    (
      SourceCodePoint: $00000070;
      TargetCodePoint: $00000050
    ),
    (
      SourceCodePoint: $00000071;
      TargetCodePoint: $00000051
    ),
    (
      SourceCodePoint: $00000072;
      TargetCodePoint: $00000052
    ),
    (
      SourceCodePoint: $00000073;
      TargetCodePoint: $00000053
    ),
    (
      SourceCodePoint: $00000074;
      TargetCodePoint: $00000054
    ),
    (
      SourceCodePoint: $00000075;
      TargetCodePoint: $00000055
    ),
    (
      SourceCodePoint: $00000076;
      TargetCodePoint: $00000056
    ),
    (
      SourceCodePoint: $00000077;
      TargetCodePoint: $00000057
    ),
    (
      SourceCodePoint: $00000078;
      TargetCodePoint: $00000058
    ),
    (
      SourceCodePoint: $00000079;
      TargetCodePoint: $00000059
    ),
    (
      SourceCodePoint: $0000007A;
      TargetCodePoint: $0000005A
    ),
    (
      SourceCodePoint: $000000B5;
      TargetCodePoint: $0000039C
    ),
    (
      SourceCodePoint: $000000E0;
      TargetCodePoint: $000000C0
    ),
    (
      SourceCodePoint: $000000E1;
      TargetCodePoint: $000000C1
    ),
    (
      SourceCodePoint: $000000E2;
      TargetCodePoint: $000000C2
    ),
    (
      SourceCodePoint: $000000E3;
      TargetCodePoint: $000000C3
    ),
    (
      SourceCodePoint: $000000E4;
      TargetCodePoint: $000000C4
    ),
    (
      SourceCodePoint: $000000E5;
      TargetCodePoint: $000000C5
    ),
    (
      SourceCodePoint: $000000E6;
      TargetCodePoint: $000000C6
    ),
    (
      SourceCodePoint: $000000E7;
      TargetCodePoint: $000000C7
    ),
    (
      SourceCodePoint: $000000E8;
      TargetCodePoint: $000000C8
    ),
    (
      SourceCodePoint: $000000E9;
      TargetCodePoint: $000000C9
    ),
    (
      SourceCodePoint: $000000EA;
      TargetCodePoint: $000000CA
    ),
    (
      SourceCodePoint: $000000EB;
      TargetCodePoint: $000000CB
    ),
    (
      SourceCodePoint: $000000EC;
      TargetCodePoint: $000000CC
    ),
    (
      SourceCodePoint: $000000ED;
      TargetCodePoint: $000000CD
    ),
    (
      SourceCodePoint: $000000EE;
      TargetCodePoint: $000000CE
    ),
    (
      SourceCodePoint: $000000EF;
      TargetCodePoint: $000000CF
    ),
    (
      SourceCodePoint: $000000F0;
      TargetCodePoint: $000000D0
    ),
    (
      SourceCodePoint: $000000F1;
      TargetCodePoint: $000000D1
    ),
    (
      SourceCodePoint: $000000F2;
      TargetCodePoint: $000000D2
    ),
    (
      SourceCodePoint: $000000F3;
      TargetCodePoint: $000000D3
    ),
    (
      SourceCodePoint: $000000F4;
      TargetCodePoint: $000000D4
    ),
    (
      SourceCodePoint: $000000F5;
      TargetCodePoint: $000000D5
    ),
    (
      SourceCodePoint: $000000F6;
      TargetCodePoint: $000000D6
    ),
    (
      SourceCodePoint: $000000F8;
      TargetCodePoint: $000000D8
    ),
    (
      SourceCodePoint: $000000F9;
      TargetCodePoint: $000000D9
    ),
    (
      SourceCodePoint: $000000FA;
      TargetCodePoint: $000000DA
    ),
    (
      SourceCodePoint: $000000FB;
      TargetCodePoint: $000000DB
    ),
    (
      SourceCodePoint: $000000FC;
      TargetCodePoint: $000000DC
    ),
    (
      SourceCodePoint: $000000FD;
      TargetCodePoint: $000000DD
    ),
    (
      SourceCodePoint: $000000FE;
      TargetCodePoint: $000000DE
    ),
    (
      SourceCodePoint: $000000FF;
      TargetCodePoint: $00000178
    ),
    (
      SourceCodePoint: $00000101;
      TargetCodePoint: $00000100
    ),
    (
      SourceCodePoint: $00000103;
      TargetCodePoint: $00000102
    ),
    (
      SourceCodePoint: $00000105;
      TargetCodePoint: $00000104
    ),
    (
      SourceCodePoint: $00000107;
      TargetCodePoint: $00000106
    ),
    (
      SourceCodePoint: $00000109;
      TargetCodePoint: $00000108
    ),
    (
      SourceCodePoint: $0000010B;
      TargetCodePoint: $0000010A
    ),
    (
      SourceCodePoint: $0000010D;
      TargetCodePoint: $0000010C
    ),
    (
      SourceCodePoint: $0000010F;
      TargetCodePoint: $0000010E
    ),
    (
      SourceCodePoint: $00000111;
      TargetCodePoint: $00000110
    ),
    (
      SourceCodePoint: $00000113;
      TargetCodePoint: $00000112
    ),
    (
      SourceCodePoint: $00000115;
      TargetCodePoint: $00000114
    ),
    (
      SourceCodePoint: $00000117;
      TargetCodePoint: $00000116
    ),
    (
      SourceCodePoint: $00000119;
      TargetCodePoint: $00000118
    ),
    (
      SourceCodePoint: $0000011B;
      TargetCodePoint: $0000011A
    ),
    (
      SourceCodePoint: $0000011D;
      TargetCodePoint: $0000011C
    ),
    (
      SourceCodePoint: $0000011F;
      TargetCodePoint: $0000011E
    ),
    (
      SourceCodePoint: $00000121;
      TargetCodePoint: $00000120
    ),
    (
      SourceCodePoint: $00000123;
      TargetCodePoint: $00000122
    ),
    (
      SourceCodePoint: $00000125;
      TargetCodePoint: $00000124
    ),
    (
      SourceCodePoint: $00000127;
      TargetCodePoint: $00000126
    ),
    (
      SourceCodePoint: $00000129;
      TargetCodePoint: $00000128
    ),
    (
      SourceCodePoint: $0000012B;
      TargetCodePoint: $0000012A
    ),
    (
      SourceCodePoint: $0000012D;
      TargetCodePoint: $0000012C
    ),
    (
      SourceCodePoint: $0000012F;
      TargetCodePoint: $0000012E
    ),
    (
      SourceCodePoint: $00000131;
      TargetCodePoint: $00000049
    ),
    (
      SourceCodePoint: $00000133;
      TargetCodePoint: $00000132
    ),
    (
      SourceCodePoint: $00000135;
      TargetCodePoint: $00000134
    ),
    (
      SourceCodePoint: $00000137;
      TargetCodePoint: $00000136
    ),
    (
      SourceCodePoint: $0000013A;
      TargetCodePoint: $00000139
    ),
    (
      SourceCodePoint: $0000013C;
      TargetCodePoint: $0000013B
    ),
    (
      SourceCodePoint: $0000013E;
      TargetCodePoint: $0000013D
    ),
    (
      SourceCodePoint: $00000140;
      TargetCodePoint: $0000013F
    ),
    (
      SourceCodePoint: $00000142;
      TargetCodePoint: $00000141
    ),
    (
      SourceCodePoint: $00000144;
      TargetCodePoint: $00000143
    ),
    (
      SourceCodePoint: $00000146;
      TargetCodePoint: $00000145
    ),
    (
      SourceCodePoint: $00000148;
      TargetCodePoint: $00000147
    ),
    (
      SourceCodePoint: $0000014B;
      TargetCodePoint: $0000014A
    ),
    (
      SourceCodePoint: $0000014D;
      TargetCodePoint: $0000014C
    ),
    (
      SourceCodePoint: $0000014F;
      TargetCodePoint: $0000014E
    ),
    (
      SourceCodePoint: $00000151;
      TargetCodePoint: $00000150
    ),
    (
      SourceCodePoint: $00000153;
      TargetCodePoint: $00000152
    ),
    (
      SourceCodePoint: $00000155;
      TargetCodePoint: $00000154
    ),
    (
      SourceCodePoint: $00000157;
      TargetCodePoint: $00000156
    ),
    (
      SourceCodePoint: $00000159;
      TargetCodePoint: $00000158
    ),
    (
      SourceCodePoint: $0000015B;
      TargetCodePoint: $0000015A
    ),
    (
      SourceCodePoint: $0000015D;
      TargetCodePoint: $0000015C
    ),
    (
      SourceCodePoint: $0000015F;
      TargetCodePoint: $0000015E
    ),
    (
      SourceCodePoint: $00000161;
      TargetCodePoint: $00000160
    ),
    (
      SourceCodePoint: $00000163;
      TargetCodePoint: $00000162
    ),
    (
      SourceCodePoint: $00000165;
      TargetCodePoint: $00000164
    ),
    (
      SourceCodePoint: $00000167;
      TargetCodePoint: $00000166
    ),
    (
      SourceCodePoint: $00000169;
      TargetCodePoint: $00000168
    ),
    (
      SourceCodePoint: $0000016B;
      TargetCodePoint: $0000016A
    ),
    (
      SourceCodePoint: $0000016D;
      TargetCodePoint: $0000016C
    ),
    (
      SourceCodePoint: $0000016F;
      TargetCodePoint: $0000016E
    ),
    (
      SourceCodePoint: $00000171;
      TargetCodePoint: $00000170
    ),
    (
      SourceCodePoint: $00000173;
      TargetCodePoint: $00000172
    ),
    (
      SourceCodePoint: $00000175;
      TargetCodePoint: $00000174
    ),
    (
      SourceCodePoint: $00000177;
      TargetCodePoint: $00000176
    ),
    (
      SourceCodePoint: $0000017A;
      TargetCodePoint: $00000179
    ),
    (
      SourceCodePoint: $0000017C;
      TargetCodePoint: $0000017B
    ),
    (
      SourceCodePoint: $0000017E;
      TargetCodePoint: $0000017D
    ),
    (
      SourceCodePoint: $0000017F;
      TargetCodePoint: $00000053
    ),
    (
      SourceCodePoint: $00000180;
      TargetCodePoint: $00000243
    ),
    (
      SourceCodePoint: $00000183;
      TargetCodePoint: $00000182
    ),
    (
      SourceCodePoint: $00000185;
      TargetCodePoint: $00000184
    ),
    (
      SourceCodePoint: $00000188;
      TargetCodePoint: $00000187
    ),
    (
      SourceCodePoint: $0000018C;
      TargetCodePoint: $0000018B
    ),
    (
      SourceCodePoint: $00000192;
      TargetCodePoint: $00000191
    ),
    (
      SourceCodePoint: $00000195;
      TargetCodePoint: $000001F6
    ),
    (
      SourceCodePoint: $00000199;
      TargetCodePoint: $00000198
    ),
    (
      SourceCodePoint: $0000019A;
      TargetCodePoint: $0000023D
    ),
    (
      SourceCodePoint: $0000019E;
      TargetCodePoint: $00000220
    ),
    (
      SourceCodePoint: $000001A1;
      TargetCodePoint: $000001A0
    ),
    (
      SourceCodePoint: $000001A3;
      TargetCodePoint: $000001A2
    ),
    (
      SourceCodePoint: $000001A5;
      TargetCodePoint: $000001A4
    ),
    (
      SourceCodePoint: $000001A8;
      TargetCodePoint: $000001A7
    ),
    (
      SourceCodePoint: $000001AD;
      TargetCodePoint: $000001AC
    ),
    (
      SourceCodePoint: $000001B0;
      TargetCodePoint: $000001AF
    ),
    (
      SourceCodePoint: $000001B4;
      TargetCodePoint: $000001B3
    ),
    (
      SourceCodePoint: $000001B6;
      TargetCodePoint: $000001B5
    ),
    (
      SourceCodePoint: $000001B9;
      TargetCodePoint: $000001B8
    ),
    (
      SourceCodePoint: $000001BD;
      TargetCodePoint: $000001BC
    ),
    (
      SourceCodePoint: $000001BF;
      TargetCodePoint: $000001F7
    ),
    (
      SourceCodePoint: $000001C5;
      TargetCodePoint: $000001C4
    ),
    (
      SourceCodePoint: $000001C6;
      TargetCodePoint: $000001C4
    ),
    (
      SourceCodePoint: $000001C8;
      TargetCodePoint: $000001C7
    ),
    (
      SourceCodePoint: $000001C9;
      TargetCodePoint: $000001C7
    ),
    (
      SourceCodePoint: $000001CB;
      TargetCodePoint: $000001CA
    ),
    (
      SourceCodePoint: $000001CC;
      TargetCodePoint: $000001CA
    ),
    (
      SourceCodePoint: $000001CE;
      TargetCodePoint: $000001CD
    ),
    (
      SourceCodePoint: $000001D0;
      TargetCodePoint: $000001CF
    ),
    (
      SourceCodePoint: $000001D2;
      TargetCodePoint: $000001D1
    ),
    (
      SourceCodePoint: $000001D4;
      TargetCodePoint: $000001D3
    ),
    (
      SourceCodePoint: $000001D6;
      TargetCodePoint: $000001D5
    ),
    (
      SourceCodePoint: $000001D8;
      TargetCodePoint: $000001D7
    ),
    (
      SourceCodePoint: $000001DA;
      TargetCodePoint: $000001D9
    ),
    (
      SourceCodePoint: $000001DC;
      TargetCodePoint: $000001DB
    ),
    (
      SourceCodePoint: $000001DD;
      TargetCodePoint: $0000018E
    ),
    (
      SourceCodePoint: $000001DF;
      TargetCodePoint: $000001DE
    ),
    (
      SourceCodePoint: $000001E1;
      TargetCodePoint: $000001E0
    ),
    (
      SourceCodePoint: $000001E3;
      TargetCodePoint: $000001E2
    ),
    (
      SourceCodePoint: $000001E5;
      TargetCodePoint: $000001E4
    ),
    (
      SourceCodePoint: $000001E7;
      TargetCodePoint: $000001E6
    ),
    (
      SourceCodePoint: $000001E9;
      TargetCodePoint: $000001E8
    ),
    (
      SourceCodePoint: $000001EB;
      TargetCodePoint: $000001EA
    ),
    (
      SourceCodePoint: $000001ED;
      TargetCodePoint: $000001EC
    ),
    (
      SourceCodePoint: $000001EF;
      TargetCodePoint: $000001EE
    ),
    (
      SourceCodePoint: $000001F2;
      TargetCodePoint: $000001F1
    ),
    (
      SourceCodePoint: $000001F3;
      TargetCodePoint: $000001F1
    ),
    (
      SourceCodePoint: $000001F5;
      TargetCodePoint: $000001F4
    ),
    (
      SourceCodePoint: $000001F9;
      TargetCodePoint: $000001F8
    ),
    (
      SourceCodePoint: $000001FB;
      TargetCodePoint: $000001FA
    ),
    (
      SourceCodePoint: $000001FD;
      TargetCodePoint: $000001FC
    ),
    (
      SourceCodePoint: $000001FF;
      TargetCodePoint: $000001FE
    ),
    (
      SourceCodePoint: $00000201;
      TargetCodePoint: $00000200
    ),
    (
      SourceCodePoint: $00000203;
      TargetCodePoint: $00000202
    ),
    (
      SourceCodePoint: $00000205;
      TargetCodePoint: $00000204
    ),
    (
      SourceCodePoint: $00000207;
      TargetCodePoint: $00000206
    ),
    (
      SourceCodePoint: $00000209;
      TargetCodePoint: $00000208
    ),
    (
      SourceCodePoint: $0000020B;
      TargetCodePoint: $0000020A
    ),
    (
      SourceCodePoint: $0000020D;
      TargetCodePoint: $0000020C
    ),
    (
      SourceCodePoint: $0000020F;
      TargetCodePoint: $0000020E
    ),
    (
      SourceCodePoint: $00000211;
      TargetCodePoint: $00000210
    ),
    (
      SourceCodePoint: $00000213;
      TargetCodePoint: $00000212
    ),
    (
      SourceCodePoint: $00000215;
      TargetCodePoint: $00000214
    ),
    (
      SourceCodePoint: $00000217;
      TargetCodePoint: $00000216
    ),
    (
      SourceCodePoint: $00000219;
      TargetCodePoint: $00000218
    ),
    (
      SourceCodePoint: $0000021B;
      TargetCodePoint: $0000021A
    ),
    (
      SourceCodePoint: $0000021D;
      TargetCodePoint: $0000021C
    ),
    (
      SourceCodePoint: $0000021F;
      TargetCodePoint: $0000021E
    ),
    (
      SourceCodePoint: $00000223;
      TargetCodePoint: $00000222
    ),
    (
      SourceCodePoint: $00000225;
      TargetCodePoint: $00000224
    ),
    (
      SourceCodePoint: $00000227;
      TargetCodePoint: $00000226
    ),
    (
      SourceCodePoint: $00000229;
      TargetCodePoint: $00000228
    ),
    (
      SourceCodePoint: $0000022B;
      TargetCodePoint: $0000022A
    ),
    (
      SourceCodePoint: $0000022D;
      TargetCodePoint: $0000022C
    ),
    (
      SourceCodePoint: $0000022F;
      TargetCodePoint: $0000022E
    ),
    (
      SourceCodePoint: $00000231;
      TargetCodePoint: $00000230
    ),
    (
      SourceCodePoint: $00000233;
      TargetCodePoint: $00000232
    ),
    (
      SourceCodePoint: $0000023C;
      TargetCodePoint: $0000023B
    ),
    (
      SourceCodePoint: $0000023F;
      TargetCodePoint: $00002C7E
    ),
    (
      SourceCodePoint: $00000240;
      TargetCodePoint: $00002C7F
    ),
    (
      SourceCodePoint: $00000242;
      TargetCodePoint: $00000241
    ),
    (
      SourceCodePoint: $00000247;
      TargetCodePoint: $00000246
    ),
    (
      SourceCodePoint: $00000249;
      TargetCodePoint: $00000248
    ),
    (
      SourceCodePoint: $0000024B;
      TargetCodePoint: $0000024A
    ),
    (
      SourceCodePoint: $0000024D;
      TargetCodePoint: $0000024C
    ),
    (
      SourceCodePoint: $0000024F;
      TargetCodePoint: $0000024E
    ),
    (
      SourceCodePoint: $00000250;
      TargetCodePoint: $00002C6F
    ),
    (
      SourceCodePoint: $00000251;
      TargetCodePoint: $00002C6D
    ),
    (
      SourceCodePoint: $00000252;
      TargetCodePoint: $00002C70
    ),
    (
      SourceCodePoint: $00000253;
      TargetCodePoint: $00000181
    ),
    (
      SourceCodePoint: $00000254;
      TargetCodePoint: $00000186
    ),
    (
      SourceCodePoint: $00000256;
      TargetCodePoint: $00000189
    ),
    (
      SourceCodePoint: $00000257;
      TargetCodePoint: $0000018A
    ),
    (
      SourceCodePoint: $00000259;
      TargetCodePoint: $0000018F
    ),
    (
      SourceCodePoint: $0000025B;
      TargetCodePoint: $00000190
    ),
    (
      SourceCodePoint: $0000025C;
      TargetCodePoint: $0000A7AB
    ),
    (
      SourceCodePoint: $00000260;
      TargetCodePoint: $00000193
    ),
    (
      SourceCodePoint: $00000261;
      TargetCodePoint: $0000A7AC
    ),
    (
      SourceCodePoint: $00000263;
      TargetCodePoint: $00000194
    ),
    (
      SourceCodePoint: $00000265;
      TargetCodePoint: $0000A78D
    ),
    (
      SourceCodePoint: $00000266;
      TargetCodePoint: $0000A7AA
    ),
    (
      SourceCodePoint: $00000268;
      TargetCodePoint: $00000197
    ),
    (
      SourceCodePoint: $00000269;
      TargetCodePoint: $00000196
    ),
    (
      SourceCodePoint: $0000026A;
      TargetCodePoint: $0000A7AE
    ),
    (
      SourceCodePoint: $0000026B;
      TargetCodePoint: $00002C62
    ),
    (
      SourceCodePoint: $0000026C;
      TargetCodePoint: $0000A7AD
    ),
    (
      SourceCodePoint: $0000026F;
      TargetCodePoint: $0000019C
    ),
    (
      SourceCodePoint: $00000271;
      TargetCodePoint: $00002C6E
    ),
    (
      SourceCodePoint: $00000272;
      TargetCodePoint: $0000019D
    ),
    (
      SourceCodePoint: $00000275;
      TargetCodePoint: $0000019F
    ),
    (
      SourceCodePoint: $0000027D;
      TargetCodePoint: $00002C64
    ),
    (
      SourceCodePoint: $00000280;
      TargetCodePoint: $000001A6
    ),
    (
      SourceCodePoint: $00000282;
      TargetCodePoint: $0000A7C5
    ),
    (
      SourceCodePoint: $00000283;
      TargetCodePoint: $000001A9
    ),
    (
      SourceCodePoint: $00000287;
      TargetCodePoint: $0000A7B1
    ),
    (
      SourceCodePoint: $00000288;
      TargetCodePoint: $000001AE
    ),
    (
      SourceCodePoint: $00000289;
      TargetCodePoint: $00000244
    ),
    (
      SourceCodePoint: $0000028A;
      TargetCodePoint: $000001B1
    ),
    (
      SourceCodePoint: $0000028B;
      TargetCodePoint: $000001B2
    ),
    (
      SourceCodePoint: $0000028C;
      TargetCodePoint: $00000245
    ),
    (
      SourceCodePoint: $00000292;
      TargetCodePoint: $000001B7
    ),
    (
      SourceCodePoint: $0000029D;
      TargetCodePoint: $0000A7B2
    ),
    (
      SourceCodePoint: $0000029E;
      TargetCodePoint: $0000A7B0
    ),
    (
      SourceCodePoint: $00000345;
      TargetCodePoint: $00000399
    ),
    (
      SourceCodePoint: $00000371;
      TargetCodePoint: $00000370
    ),
    (
      SourceCodePoint: $00000373;
      TargetCodePoint: $00000372
    ),
    (
      SourceCodePoint: $00000377;
      TargetCodePoint: $00000376
    ),
    (
      SourceCodePoint: $0000037B;
      TargetCodePoint: $000003FD
    ),
    (
      SourceCodePoint: $0000037C;
      TargetCodePoint: $000003FE
    ),
    (
      SourceCodePoint: $0000037D;
      TargetCodePoint: $000003FF
    ),
    (
      SourceCodePoint: $000003AC;
      TargetCodePoint: $00000386
    ),
    (
      SourceCodePoint: $000003AD;
      TargetCodePoint: $00000388
    ),
    (
      SourceCodePoint: $000003AE;
      TargetCodePoint: $00000389
    ),
    (
      SourceCodePoint: $000003AF;
      TargetCodePoint: $0000038A
    ),
    (
      SourceCodePoint: $000003B1;
      TargetCodePoint: $00000391
    ),
    (
      SourceCodePoint: $000003B2;
      TargetCodePoint: $00000392
    ),
    (
      SourceCodePoint: $000003B3;
      TargetCodePoint: $00000393
    ),
    (
      SourceCodePoint: $000003B4;
      TargetCodePoint: $00000394
    ),
    (
      SourceCodePoint: $000003B5;
      TargetCodePoint: $00000395
    ),
    (
      SourceCodePoint: $000003B6;
      TargetCodePoint: $00000396
    ),
    (
      SourceCodePoint: $000003B7;
      TargetCodePoint: $00000397
    ),
    (
      SourceCodePoint: $000003B8;
      TargetCodePoint: $00000398
    ),
    (
      SourceCodePoint: $000003B9;
      TargetCodePoint: $00000399
    ),
    (
      SourceCodePoint: $000003BA;
      TargetCodePoint: $0000039A
    ),
    (
      SourceCodePoint: $000003BB;
      TargetCodePoint: $0000039B
    ),
    (
      SourceCodePoint: $000003BC;
      TargetCodePoint: $0000039C
    ),
    (
      SourceCodePoint: $000003BD;
      TargetCodePoint: $0000039D
    ),
    (
      SourceCodePoint: $000003BE;
      TargetCodePoint: $0000039E
    ),
    (
      SourceCodePoint: $000003BF;
      TargetCodePoint: $0000039F
    ),
    (
      SourceCodePoint: $000003C0;
      TargetCodePoint: $000003A0
    ),
    (
      SourceCodePoint: $000003C1;
      TargetCodePoint: $000003A1
    ),
    (
      SourceCodePoint: $000003C2;
      TargetCodePoint: $000003A3
    ),
    (
      SourceCodePoint: $000003C3;
      TargetCodePoint: $000003A3
    ),
    (
      SourceCodePoint: $000003C4;
      TargetCodePoint: $000003A4
    ),
    (
      SourceCodePoint: $000003C5;
      TargetCodePoint: $000003A5
    ),
    (
      SourceCodePoint: $000003C6;
      TargetCodePoint: $000003A6
    ),
    (
      SourceCodePoint: $000003C7;
      TargetCodePoint: $000003A7
    ),
    (
      SourceCodePoint: $000003C8;
      TargetCodePoint: $000003A8
    ),
    (
      SourceCodePoint: $000003C9;
      TargetCodePoint: $000003A9
    ),
    (
      SourceCodePoint: $000003CA;
      TargetCodePoint: $000003AA
    ),
    (
      SourceCodePoint: $000003CB;
      TargetCodePoint: $000003AB
    ),
    (
      SourceCodePoint: $000003CC;
      TargetCodePoint: $0000038C
    ),
    (
      SourceCodePoint: $000003CD;
      TargetCodePoint: $0000038E
    ),
    (
      SourceCodePoint: $000003CE;
      TargetCodePoint: $0000038F
    ),
    (
      SourceCodePoint: $000003D0;
      TargetCodePoint: $00000392
    ),
    (
      SourceCodePoint: $000003D1;
      TargetCodePoint: $00000398
    ),
    (
      SourceCodePoint: $000003D5;
      TargetCodePoint: $000003A6
    ),
    (
      SourceCodePoint: $000003D6;
      TargetCodePoint: $000003A0
    ),
    (
      SourceCodePoint: $000003D7;
      TargetCodePoint: $000003CF
    ),
    (
      SourceCodePoint: $000003D9;
      TargetCodePoint: $000003D8
    ),
    (
      SourceCodePoint: $000003DB;
      TargetCodePoint: $000003DA
    ),
    (
      SourceCodePoint: $000003DD;
      TargetCodePoint: $000003DC
    ),
    (
      SourceCodePoint: $000003DF;
      TargetCodePoint: $000003DE
    ),
    (
      SourceCodePoint: $000003E1;
      TargetCodePoint: $000003E0
    ),
    (
      SourceCodePoint: $000003E3;
      TargetCodePoint: $000003E2
    ),
    (
      SourceCodePoint: $000003E5;
      TargetCodePoint: $000003E4
    ),
    (
      SourceCodePoint: $000003E7;
      TargetCodePoint: $000003E6
    ),
    (
      SourceCodePoint: $000003E9;
      TargetCodePoint: $000003E8
    ),
    (
      SourceCodePoint: $000003EB;
      TargetCodePoint: $000003EA
    ),
    (
      SourceCodePoint: $000003ED;
      TargetCodePoint: $000003EC
    ),
    (
      SourceCodePoint: $000003EF;
      TargetCodePoint: $000003EE
    ),
    (
      SourceCodePoint: $000003F0;
      TargetCodePoint: $0000039A
    ),
    (
      SourceCodePoint: $000003F1;
      TargetCodePoint: $000003A1
    ),
    (
      SourceCodePoint: $000003F2;
      TargetCodePoint: $000003F9
    ),
    (
      SourceCodePoint: $000003F3;
      TargetCodePoint: $0000037F
    ),
    (
      SourceCodePoint: $000003F5;
      TargetCodePoint: $00000395
    ),
    (
      SourceCodePoint: $000003F8;
      TargetCodePoint: $000003F7
    ),
    (
      SourceCodePoint: $000003FB;
      TargetCodePoint: $000003FA
    ),
    (
      SourceCodePoint: $00000430;
      TargetCodePoint: $00000410
    ),
    (
      SourceCodePoint: $00000431;
      TargetCodePoint: $00000411
    ),
    (
      SourceCodePoint: $00000432;
      TargetCodePoint: $00000412
    ),
    (
      SourceCodePoint: $00000433;
      TargetCodePoint: $00000413
    ),
    (
      SourceCodePoint: $00000434;
      TargetCodePoint: $00000414
    ),
    (
      SourceCodePoint: $00000435;
      TargetCodePoint: $00000415
    ),
    (
      SourceCodePoint: $00000436;
      TargetCodePoint: $00000416
    ),
    (
      SourceCodePoint: $00000437;
      TargetCodePoint: $00000417
    ),
    (
      SourceCodePoint: $00000438;
      TargetCodePoint: $00000418
    ),
    (
      SourceCodePoint: $00000439;
      TargetCodePoint: $00000419
    ),
    (
      SourceCodePoint: $0000043A;
      TargetCodePoint: $0000041A
    ),
    (
      SourceCodePoint: $0000043B;
      TargetCodePoint: $0000041B
    ),
    (
      SourceCodePoint: $0000043C;
      TargetCodePoint: $0000041C
    ),
    (
      SourceCodePoint: $0000043D;
      TargetCodePoint: $0000041D
    ),
    (
      SourceCodePoint: $0000043E;
      TargetCodePoint: $0000041E
    ),
    (
      SourceCodePoint: $0000043F;
      TargetCodePoint: $0000041F
    ),
    (
      SourceCodePoint: $00000440;
      TargetCodePoint: $00000420
    ),
    (
      SourceCodePoint: $00000441;
      TargetCodePoint: $00000421
    ),
    (
      SourceCodePoint: $00000442;
      TargetCodePoint: $00000422
    ),
    (
      SourceCodePoint: $00000443;
      TargetCodePoint: $00000423
    ),
    (
      SourceCodePoint: $00000444;
      TargetCodePoint: $00000424
    ),
    (
      SourceCodePoint: $00000445;
      TargetCodePoint: $00000425
    ),
    (
      SourceCodePoint: $00000446;
      TargetCodePoint: $00000426
    ),
    (
      SourceCodePoint: $00000447;
      TargetCodePoint: $00000427
    ),
    (
      SourceCodePoint: $00000448;
      TargetCodePoint: $00000428
    ),
    (
      SourceCodePoint: $00000449;
      TargetCodePoint: $00000429
    ),
    (
      SourceCodePoint: $0000044A;
      TargetCodePoint: $0000042A
    ),
    (
      SourceCodePoint: $0000044B;
      TargetCodePoint: $0000042B
    ),
    (
      SourceCodePoint: $0000044C;
      TargetCodePoint: $0000042C
    ),
    (
      SourceCodePoint: $0000044D;
      TargetCodePoint: $0000042D
    ),
    (
      SourceCodePoint: $0000044E;
      TargetCodePoint: $0000042E
    ),
    (
      SourceCodePoint: $0000044F;
      TargetCodePoint: $0000042F
    ),
    (
      SourceCodePoint: $00000450;
      TargetCodePoint: $00000400
    ),
    (
      SourceCodePoint: $00000451;
      TargetCodePoint: $00000401
    ),
    (
      SourceCodePoint: $00000452;
      TargetCodePoint: $00000402
    ),
    (
      SourceCodePoint: $00000453;
      TargetCodePoint: $00000403
    ),
    (
      SourceCodePoint: $00000454;
      TargetCodePoint: $00000404
    ),
    (
      SourceCodePoint: $00000455;
      TargetCodePoint: $00000405
    ),
    (
      SourceCodePoint: $00000456;
      TargetCodePoint: $00000406
    ),
    (
      SourceCodePoint: $00000457;
      TargetCodePoint: $00000407
    ),
    (
      SourceCodePoint: $00000458;
      TargetCodePoint: $00000408
    ),
    (
      SourceCodePoint: $00000459;
      TargetCodePoint: $00000409
    ),
    (
      SourceCodePoint: $0000045A;
      TargetCodePoint: $0000040A
    ),
    (
      SourceCodePoint: $0000045B;
      TargetCodePoint: $0000040B
    ),
    (
      SourceCodePoint: $0000045C;
      TargetCodePoint: $0000040C
    ),
    (
      SourceCodePoint: $0000045D;
      TargetCodePoint: $0000040D
    ),
    (
      SourceCodePoint: $0000045E;
      TargetCodePoint: $0000040E
    ),
    (
      SourceCodePoint: $0000045F;
      TargetCodePoint: $0000040F
    ),
    (
      SourceCodePoint: $00000461;
      TargetCodePoint: $00000460
    ),
    (
      SourceCodePoint: $00000463;
      TargetCodePoint: $00000462
    ),
    (
      SourceCodePoint: $00000465;
      TargetCodePoint: $00000464
    ),
    (
      SourceCodePoint: $00000467;
      TargetCodePoint: $00000466
    ),
    (
      SourceCodePoint: $00000469;
      TargetCodePoint: $00000468
    ),
    (
      SourceCodePoint: $0000046B;
      TargetCodePoint: $0000046A
    ),
    (
      SourceCodePoint: $0000046D;
      TargetCodePoint: $0000046C
    ),
    (
      SourceCodePoint: $0000046F;
      TargetCodePoint: $0000046E
    ),
    (
      SourceCodePoint: $00000471;
      TargetCodePoint: $00000470
    ),
    (
      SourceCodePoint: $00000473;
      TargetCodePoint: $00000472
    ),
    (
      SourceCodePoint: $00000475;
      TargetCodePoint: $00000474
    ),
    (
      SourceCodePoint: $00000477;
      TargetCodePoint: $00000476
    ),
    (
      SourceCodePoint: $00000479;
      TargetCodePoint: $00000478
    ),
    (
      SourceCodePoint: $0000047B;
      TargetCodePoint: $0000047A
    ),
    (
      SourceCodePoint: $0000047D;
      TargetCodePoint: $0000047C
    ),
    (
      SourceCodePoint: $0000047F;
      TargetCodePoint: $0000047E
    ),
    (
      SourceCodePoint: $00000481;
      TargetCodePoint: $00000480
    ),
    (
      SourceCodePoint: $0000048B;
      TargetCodePoint: $0000048A
    ),
    (
      SourceCodePoint: $0000048D;
      TargetCodePoint: $0000048C
    ),
    (
      SourceCodePoint: $0000048F;
      TargetCodePoint: $0000048E
    ),
    (
      SourceCodePoint: $00000491;
      TargetCodePoint: $00000490
    ),
    (
      SourceCodePoint: $00000493;
      TargetCodePoint: $00000492
    ),
    (
      SourceCodePoint: $00000495;
      TargetCodePoint: $00000494
    ),
    (
      SourceCodePoint: $00000497;
      TargetCodePoint: $00000496
    ),
    (
      SourceCodePoint: $00000499;
      TargetCodePoint: $00000498
    ),
    (
      SourceCodePoint: $0000049B;
      TargetCodePoint: $0000049A
    ),
    (
      SourceCodePoint: $0000049D;
      TargetCodePoint: $0000049C
    ),
    (
      SourceCodePoint: $0000049F;
      TargetCodePoint: $0000049E
    ),
    (
      SourceCodePoint: $000004A1;
      TargetCodePoint: $000004A0
    ),
    (
      SourceCodePoint: $000004A3;
      TargetCodePoint: $000004A2
    ),
    (
      SourceCodePoint: $000004A5;
      TargetCodePoint: $000004A4
    ),
    (
      SourceCodePoint: $000004A7;
      TargetCodePoint: $000004A6
    ),
    (
      SourceCodePoint: $000004A9;
      TargetCodePoint: $000004A8
    ),
    (
      SourceCodePoint: $000004AB;
      TargetCodePoint: $000004AA
    ),
    (
      SourceCodePoint: $000004AD;
      TargetCodePoint: $000004AC
    ),
    (
      SourceCodePoint: $000004AF;
      TargetCodePoint: $000004AE
    ),
    (
      SourceCodePoint: $000004B1;
      TargetCodePoint: $000004B0
    ),
    (
      SourceCodePoint: $000004B3;
      TargetCodePoint: $000004B2
    ),
    (
      SourceCodePoint: $000004B5;
      TargetCodePoint: $000004B4
    ),
    (
      SourceCodePoint: $000004B7;
      TargetCodePoint: $000004B6
    ),
    (
      SourceCodePoint: $000004B9;
      TargetCodePoint: $000004B8
    ),
    (
      SourceCodePoint: $000004BB;
      TargetCodePoint: $000004BA
    ),
    (
      SourceCodePoint: $000004BD;
      TargetCodePoint: $000004BC
    ),
    (
      SourceCodePoint: $000004BF;
      TargetCodePoint: $000004BE
    ),
    (
      SourceCodePoint: $000004C2;
      TargetCodePoint: $000004C1
    ),
    (
      SourceCodePoint: $000004C4;
      TargetCodePoint: $000004C3
    ),
    (
      SourceCodePoint: $000004C6;
      TargetCodePoint: $000004C5
    ),
    (
      SourceCodePoint: $000004C8;
      TargetCodePoint: $000004C7
    ),
    (
      SourceCodePoint: $000004CA;
      TargetCodePoint: $000004C9
    ),
    (
      SourceCodePoint: $000004CC;
      TargetCodePoint: $000004CB
    ),
    (
      SourceCodePoint: $000004CE;
      TargetCodePoint: $000004CD
    ),
    (
      SourceCodePoint: $000004CF;
      TargetCodePoint: $000004C0
    ),
    (
      SourceCodePoint: $000004D1;
      TargetCodePoint: $000004D0
    ),
    (
      SourceCodePoint: $000004D3;
      TargetCodePoint: $000004D2
    ),
    (
      SourceCodePoint: $000004D5;
      TargetCodePoint: $000004D4
    ),
    (
      SourceCodePoint: $000004D7;
      TargetCodePoint: $000004D6
    ),
    (
      SourceCodePoint: $000004D9;
      TargetCodePoint: $000004D8
    ),
    (
      SourceCodePoint: $000004DB;
      TargetCodePoint: $000004DA
    ),
    (
      SourceCodePoint: $000004DD;
      TargetCodePoint: $000004DC
    ),
    (
      SourceCodePoint: $000004DF;
      TargetCodePoint: $000004DE
    ),
    (
      SourceCodePoint: $000004E1;
      TargetCodePoint: $000004E0
    ),
    (
      SourceCodePoint: $000004E3;
      TargetCodePoint: $000004E2
    ),
    (
      SourceCodePoint: $000004E5;
      TargetCodePoint: $000004E4
    ),
    (
      SourceCodePoint: $000004E7;
      TargetCodePoint: $000004E6
    ),
    (
      SourceCodePoint: $000004E9;
      TargetCodePoint: $000004E8
    ),
    (
      SourceCodePoint: $000004EB;
      TargetCodePoint: $000004EA
    ),
    (
      SourceCodePoint: $000004ED;
      TargetCodePoint: $000004EC
    ),
    (
      SourceCodePoint: $000004EF;
      TargetCodePoint: $000004EE
    ),
    (
      SourceCodePoint: $000004F1;
      TargetCodePoint: $000004F0
    ),
    (
      SourceCodePoint: $000004F3;
      TargetCodePoint: $000004F2
    ),
    (
      SourceCodePoint: $000004F5;
      TargetCodePoint: $000004F4
    ),
    (
      SourceCodePoint: $000004F7;
      TargetCodePoint: $000004F6
    ),
    (
      SourceCodePoint: $000004F9;
      TargetCodePoint: $000004F8
    ),
    (
      SourceCodePoint: $000004FB;
      TargetCodePoint: $000004FA
    ),
    (
      SourceCodePoint: $000004FD;
      TargetCodePoint: $000004FC
    ),
    (
      SourceCodePoint: $000004FF;
      TargetCodePoint: $000004FE
    ),
    (
      SourceCodePoint: $00000501;
      TargetCodePoint: $00000500
    ),
    (
      SourceCodePoint: $00000503;
      TargetCodePoint: $00000502
    ),
    (
      SourceCodePoint: $00000505;
      TargetCodePoint: $00000504
    ),
    (
      SourceCodePoint: $00000507;
      TargetCodePoint: $00000506
    ),
    (
      SourceCodePoint: $00000509;
      TargetCodePoint: $00000508
    ),
    (
      SourceCodePoint: $0000050B;
      TargetCodePoint: $0000050A
    ),
    (
      SourceCodePoint: $0000050D;
      TargetCodePoint: $0000050C
    ),
    (
      SourceCodePoint: $0000050F;
      TargetCodePoint: $0000050E
    ),
    (
      SourceCodePoint: $00000511;
      TargetCodePoint: $00000510
    ),
    (
      SourceCodePoint: $00000513;
      TargetCodePoint: $00000512
    ),
    (
      SourceCodePoint: $00000515;
      TargetCodePoint: $00000514
    ),
    (
      SourceCodePoint: $00000517;
      TargetCodePoint: $00000516
    ),
    (
      SourceCodePoint: $00000519;
      TargetCodePoint: $00000518
    ),
    (
      SourceCodePoint: $0000051B;
      TargetCodePoint: $0000051A
    ),
    (
      SourceCodePoint: $0000051D;
      TargetCodePoint: $0000051C
    ),
    (
      SourceCodePoint: $0000051F;
      TargetCodePoint: $0000051E
    ),
    (
      SourceCodePoint: $00000521;
      TargetCodePoint: $00000520
    ),
    (
      SourceCodePoint: $00000523;
      TargetCodePoint: $00000522
    ),
    (
      SourceCodePoint: $00000525;
      TargetCodePoint: $00000524
    ),
    (
      SourceCodePoint: $00000527;
      TargetCodePoint: $00000526
    ),
    (
      SourceCodePoint: $00000529;
      TargetCodePoint: $00000528
    ),
    (
      SourceCodePoint: $0000052B;
      TargetCodePoint: $0000052A
    ),
    (
      SourceCodePoint: $0000052D;
      TargetCodePoint: $0000052C
    ),
    (
      SourceCodePoint: $0000052F;
      TargetCodePoint: $0000052E
    ),
    (
      SourceCodePoint: $00000561;
      TargetCodePoint: $00000531
    ),
    (
      SourceCodePoint: $00000562;
      TargetCodePoint: $00000532
    ),
    (
      SourceCodePoint: $00000563;
      TargetCodePoint: $00000533
    ),
    (
      SourceCodePoint: $00000564;
      TargetCodePoint: $00000534
    ),
    (
      SourceCodePoint: $00000565;
      TargetCodePoint: $00000535
    ),
    (
      SourceCodePoint: $00000566;
      TargetCodePoint: $00000536
    ),
    (
      SourceCodePoint: $00000567;
      TargetCodePoint: $00000537
    ),
    (
      SourceCodePoint: $00000568;
      TargetCodePoint: $00000538
    ),
    (
      SourceCodePoint: $00000569;
      TargetCodePoint: $00000539
    ),
    (
      SourceCodePoint: $0000056A;
      TargetCodePoint: $0000053A
    ),
    (
      SourceCodePoint: $0000056B;
      TargetCodePoint: $0000053B
    ),
    (
      SourceCodePoint: $0000056C;
      TargetCodePoint: $0000053C
    ),
    (
      SourceCodePoint: $0000056D;
      TargetCodePoint: $0000053D
    ),
    (
      SourceCodePoint: $0000056E;
      TargetCodePoint: $0000053E
    ),
    (
      SourceCodePoint: $0000056F;
      TargetCodePoint: $0000053F
    ),
    (
      SourceCodePoint: $00000570;
      TargetCodePoint: $00000540
    ),
    (
      SourceCodePoint: $00000571;
      TargetCodePoint: $00000541
    ),
    (
      SourceCodePoint: $00000572;
      TargetCodePoint: $00000542
    ),
    (
      SourceCodePoint: $00000573;
      TargetCodePoint: $00000543
    ),
    (
      SourceCodePoint: $00000574;
      TargetCodePoint: $00000544
    ),
    (
      SourceCodePoint: $00000575;
      TargetCodePoint: $00000545
    ),
    (
      SourceCodePoint: $00000576;
      TargetCodePoint: $00000546
    ),
    (
      SourceCodePoint: $00000577;
      TargetCodePoint: $00000547
    ),
    (
      SourceCodePoint: $00000578;
      TargetCodePoint: $00000548
    ),
    (
      SourceCodePoint: $00000579;
      TargetCodePoint: $00000549
    ),
    (
      SourceCodePoint: $0000057A;
      TargetCodePoint: $0000054A
    ),
    (
      SourceCodePoint: $0000057B;
      TargetCodePoint: $0000054B
    ),
    (
      SourceCodePoint: $0000057C;
      TargetCodePoint: $0000054C
    ),
    (
      SourceCodePoint: $0000057D;
      TargetCodePoint: $0000054D
    ),
    (
      SourceCodePoint: $0000057E;
      TargetCodePoint: $0000054E
    ),
    (
      SourceCodePoint: $0000057F;
      TargetCodePoint: $0000054F
    ),
    (
      SourceCodePoint: $00000580;
      TargetCodePoint: $00000550
    ),
    (
      SourceCodePoint: $00000581;
      TargetCodePoint: $00000551
    ),
    (
      SourceCodePoint: $00000582;
      TargetCodePoint: $00000552
    ),
    (
      SourceCodePoint: $00000583;
      TargetCodePoint: $00000553
    ),
    (
      SourceCodePoint: $00000584;
      TargetCodePoint: $00000554
    ),
    (
      SourceCodePoint: $00000585;
      TargetCodePoint: $00000555
    ),
    (
      SourceCodePoint: $00000586;
      TargetCodePoint: $00000556
    ),
    (
      SourceCodePoint: $000010D0;
      TargetCodePoint: $00001C90
    ),
    (
      SourceCodePoint: $000010D1;
      TargetCodePoint: $00001C91
    ),
    (
      SourceCodePoint: $000010D2;
      TargetCodePoint: $00001C92
    ),
    (
      SourceCodePoint: $000010D3;
      TargetCodePoint: $00001C93
    ),
    (
      SourceCodePoint: $000010D4;
      TargetCodePoint: $00001C94
    ),
    (
      SourceCodePoint: $000010D5;
      TargetCodePoint: $00001C95
    ),
    (
      SourceCodePoint: $000010D6;
      TargetCodePoint: $00001C96
    ),
    (
      SourceCodePoint: $000010D7;
      TargetCodePoint: $00001C97
    ),
    (
      SourceCodePoint: $000010D8;
      TargetCodePoint: $00001C98
    ),
    (
      SourceCodePoint: $000010D9;
      TargetCodePoint: $00001C99
    ),
    (
      SourceCodePoint: $000010DA;
      TargetCodePoint: $00001C9A
    ),
    (
      SourceCodePoint: $000010DB;
      TargetCodePoint: $00001C9B
    ),
    (
      SourceCodePoint: $000010DC;
      TargetCodePoint: $00001C9C
    ),
    (
      SourceCodePoint: $000010DD;
      TargetCodePoint: $00001C9D
    ),
    (
      SourceCodePoint: $000010DE;
      TargetCodePoint: $00001C9E
    ),
    (
      SourceCodePoint: $000010DF;
      TargetCodePoint: $00001C9F
    ),
    (
      SourceCodePoint: $000010E0;
      TargetCodePoint: $00001CA0
    ),
    (
      SourceCodePoint: $000010E1;
      TargetCodePoint: $00001CA1
    ),
    (
      SourceCodePoint: $000010E2;
      TargetCodePoint: $00001CA2
    ),
    (
      SourceCodePoint: $000010E3;
      TargetCodePoint: $00001CA3
    ),
    (
      SourceCodePoint: $000010E4;
      TargetCodePoint: $00001CA4
    ),
    (
      SourceCodePoint: $000010E5;
      TargetCodePoint: $00001CA5
    ),
    (
      SourceCodePoint: $000010E6;
      TargetCodePoint: $00001CA6
    ),
    (
      SourceCodePoint: $000010E7;
      TargetCodePoint: $00001CA7
    ),
    (
      SourceCodePoint: $000010E8;
      TargetCodePoint: $00001CA8
    ),
    (
      SourceCodePoint: $000010E9;
      TargetCodePoint: $00001CA9
    ),
    (
      SourceCodePoint: $000010EA;
      TargetCodePoint: $00001CAA
    ),
    (
      SourceCodePoint: $000010EB;
      TargetCodePoint: $00001CAB
    ),
    (
      SourceCodePoint: $000010EC;
      TargetCodePoint: $00001CAC
    ),
    (
      SourceCodePoint: $000010ED;
      TargetCodePoint: $00001CAD
    ),
    (
      SourceCodePoint: $000010EE;
      TargetCodePoint: $00001CAE
    ),
    (
      SourceCodePoint: $000010EF;
      TargetCodePoint: $00001CAF
    ),
    (
      SourceCodePoint: $000010F0;
      TargetCodePoint: $00001CB0
    ),
    (
      SourceCodePoint: $000010F1;
      TargetCodePoint: $00001CB1
    ),
    (
      SourceCodePoint: $000010F2;
      TargetCodePoint: $00001CB2
    ),
    (
      SourceCodePoint: $000010F3;
      TargetCodePoint: $00001CB3
    ),
    (
      SourceCodePoint: $000010F4;
      TargetCodePoint: $00001CB4
    ),
    (
      SourceCodePoint: $000010F5;
      TargetCodePoint: $00001CB5
    ),
    (
      SourceCodePoint: $000010F6;
      TargetCodePoint: $00001CB6
    ),
    (
      SourceCodePoint: $000010F7;
      TargetCodePoint: $00001CB7
    ),
    (
      SourceCodePoint: $000010F8;
      TargetCodePoint: $00001CB8
    ),
    (
      SourceCodePoint: $000010F9;
      TargetCodePoint: $00001CB9
    ),
    (
      SourceCodePoint: $000010FA;
      TargetCodePoint: $00001CBA
    ),
    (
      SourceCodePoint: $000010FD;
      TargetCodePoint: $00001CBD
    ),
    (
      SourceCodePoint: $000010FE;
      TargetCodePoint: $00001CBE
    ),
    (
      SourceCodePoint: $000010FF;
      TargetCodePoint: $00001CBF
    ),
    (
      SourceCodePoint: $000013F8;
      TargetCodePoint: $000013F0
    ),
    (
      SourceCodePoint: $000013F9;
      TargetCodePoint: $000013F1
    ),
    (
      SourceCodePoint: $000013FA;
      TargetCodePoint: $000013F2
    ),
    (
      SourceCodePoint: $000013FB;
      TargetCodePoint: $000013F3
    ),
    (
      SourceCodePoint: $000013FC;
      TargetCodePoint: $000013F4
    ),
    (
      SourceCodePoint: $000013FD;
      TargetCodePoint: $000013F5
    ),
    (
      SourceCodePoint: $00001C80;
      TargetCodePoint: $00000412
    ),
    (
      SourceCodePoint: $00001C81;
      TargetCodePoint: $00000414
    ),
    (
      SourceCodePoint: $00001C82;
      TargetCodePoint: $0000041E
    ),
    (
      SourceCodePoint: $00001C83;
      TargetCodePoint: $00000421
    ),
    (
      SourceCodePoint: $00001C84;
      TargetCodePoint: $00000422
    ),
    (
      SourceCodePoint: $00001C85;
      TargetCodePoint: $00000422
    ),
    (
      SourceCodePoint: $00001C86;
      TargetCodePoint: $0000042A
    ),
    (
      SourceCodePoint: $00001C87;
      TargetCodePoint: $00000462
    ),
    (
      SourceCodePoint: $00001C88;
      TargetCodePoint: $0000A64A
    ),
    (
      SourceCodePoint: $00001D79;
      TargetCodePoint: $0000A77D
    ),
    (
      SourceCodePoint: $00001D7D;
      TargetCodePoint: $00002C63
    ),
    (
      SourceCodePoint: $00001D8E;
      TargetCodePoint: $0000A7C6
    ),
    (
      SourceCodePoint: $00001E01;
      TargetCodePoint: $00001E00
    ),
    (
      SourceCodePoint: $00001E03;
      TargetCodePoint: $00001E02
    ),
    (
      SourceCodePoint: $00001E05;
      TargetCodePoint: $00001E04
    ),
    (
      SourceCodePoint: $00001E07;
      TargetCodePoint: $00001E06
    ),
    (
      SourceCodePoint: $00001E09;
      TargetCodePoint: $00001E08
    ),
    (
      SourceCodePoint: $00001E0B;
      TargetCodePoint: $00001E0A
    ),
    (
      SourceCodePoint: $00001E0D;
      TargetCodePoint: $00001E0C
    ),
    (
      SourceCodePoint: $00001E0F;
      TargetCodePoint: $00001E0E
    ),
    (
      SourceCodePoint: $00001E11;
      TargetCodePoint: $00001E10
    ),
    (
      SourceCodePoint: $00001E13;
      TargetCodePoint: $00001E12
    ),
    (
      SourceCodePoint: $00001E15;
      TargetCodePoint: $00001E14
    ),
    (
      SourceCodePoint: $00001E17;
      TargetCodePoint: $00001E16
    ),
    (
      SourceCodePoint: $00001E19;
      TargetCodePoint: $00001E18
    ),
    (
      SourceCodePoint: $00001E1B;
      TargetCodePoint: $00001E1A
    ),
    (
      SourceCodePoint: $00001E1D;
      TargetCodePoint: $00001E1C
    ),
    (
      SourceCodePoint: $00001E1F;
      TargetCodePoint: $00001E1E
    ),
    (
      SourceCodePoint: $00001E21;
      TargetCodePoint: $00001E20
    ),
    (
      SourceCodePoint: $00001E23;
      TargetCodePoint: $00001E22
    ),
    (
      SourceCodePoint: $00001E25;
      TargetCodePoint: $00001E24
    ),
    (
      SourceCodePoint: $00001E27;
      TargetCodePoint: $00001E26
    ),
    (
      SourceCodePoint: $00001E29;
      TargetCodePoint: $00001E28
    ),
    (
      SourceCodePoint: $00001E2B;
      TargetCodePoint: $00001E2A
    ),
    (
      SourceCodePoint: $00001E2D;
      TargetCodePoint: $00001E2C
    ),
    (
      SourceCodePoint: $00001E2F;
      TargetCodePoint: $00001E2E
    ),
    (
      SourceCodePoint: $00001E31;
      TargetCodePoint: $00001E30
    ),
    (
      SourceCodePoint: $00001E33;
      TargetCodePoint: $00001E32
    ),
    (
      SourceCodePoint: $00001E35;
      TargetCodePoint: $00001E34
    ),
    (
      SourceCodePoint: $00001E37;
      TargetCodePoint: $00001E36
    ),
    (
      SourceCodePoint: $00001E39;
      TargetCodePoint: $00001E38
    ),
    (
      SourceCodePoint: $00001E3B;
      TargetCodePoint: $00001E3A
    ),
    (
      SourceCodePoint: $00001E3D;
      TargetCodePoint: $00001E3C
    ),
    (
      SourceCodePoint: $00001E3F;
      TargetCodePoint: $00001E3E
    ),
    (
      SourceCodePoint: $00001E41;
      TargetCodePoint: $00001E40
    ),
    (
      SourceCodePoint: $00001E43;
      TargetCodePoint: $00001E42
    ),
    (
      SourceCodePoint: $00001E45;
      TargetCodePoint: $00001E44
    ),
    (
      SourceCodePoint: $00001E47;
      TargetCodePoint: $00001E46
    ),
    (
      SourceCodePoint: $00001E49;
      TargetCodePoint: $00001E48
    ),
    (
      SourceCodePoint: $00001E4B;
      TargetCodePoint: $00001E4A
    ),
    (
      SourceCodePoint: $00001E4D;
      TargetCodePoint: $00001E4C
    ),
    (
      SourceCodePoint: $00001E4F;
      TargetCodePoint: $00001E4E
    ),
    (
      SourceCodePoint: $00001E51;
      TargetCodePoint: $00001E50
    ),
    (
      SourceCodePoint: $00001E53;
      TargetCodePoint: $00001E52
    ),
    (
      SourceCodePoint: $00001E55;
      TargetCodePoint: $00001E54
    ),
    (
      SourceCodePoint: $00001E57;
      TargetCodePoint: $00001E56
    ),
    (
      SourceCodePoint: $00001E59;
      TargetCodePoint: $00001E58
    ),
    (
      SourceCodePoint: $00001E5B;
      TargetCodePoint: $00001E5A
    ),
    (
      SourceCodePoint: $00001E5D;
      TargetCodePoint: $00001E5C
    ),
    (
      SourceCodePoint: $00001E5F;
      TargetCodePoint: $00001E5E
    ),
    (
      SourceCodePoint: $00001E61;
      TargetCodePoint: $00001E60
    ),
    (
      SourceCodePoint: $00001E63;
      TargetCodePoint: $00001E62
    ),
    (
      SourceCodePoint: $00001E65;
      TargetCodePoint: $00001E64
    ),
    (
      SourceCodePoint: $00001E67;
      TargetCodePoint: $00001E66
    ),
    (
      SourceCodePoint: $00001E69;
      TargetCodePoint: $00001E68
    ),
    (
      SourceCodePoint: $00001E6B;
      TargetCodePoint: $00001E6A
    ),
    (
      SourceCodePoint: $00001E6D;
      TargetCodePoint: $00001E6C
    ),
    (
      SourceCodePoint: $00001E6F;
      TargetCodePoint: $00001E6E
    ),
    (
      SourceCodePoint: $00001E71;
      TargetCodePoint: $00001E70
    ),
    (
      SourceCodePoint: $00001E73;
      TargetCodePoint: $00001E72
    ),
    (
      SourceCodePoint: $00001E75;
      TargetCodePoint: $00001E74
    ),
    (
      SourceCodePoint: $00001E77;
      TargetCodePoint: $00001E76
    ),
    (
      SourceCodePoint: $00001E79;
      TargetCodePoint: $00001E78
    ),
    (
      SourceCodePoint: $00001E7B;
      TargetCodePoint: $00001E7A
    ),
    (
      SourceCodePoint: $00001E7D;
      TargetCodePoint: $00001E7C
    ),
    (
      SourceCodePoint: $00001E7F;
      TargetCodePoint: $00001E7E
    ),
    (
      SourceCodePoint: $00001E81;
      TargetCodePoint: $00001E80
    ),
    (
      SourceCodePoint: $00001E83;
      TargetCodePoint: $00001E82
    ),
    (
      SourceCodePoint: $00001E85;
      TargetCodePoint: $00001E84
    ),
    (
      SourceCodePoint: $00001E87;
      TargetCodePoint: $00001E86
    ),
    (
      SourceCodePoint: $00001E89;
      TargetCodePoint: $00001E88
    ),
    (
      SourceCodePoint: $00001E8B;
      TargetCodePoint: $00001E8A
    ),
    (
      SourceCodePoint: $00001E8D;
      TargetCodePoint: $00001E8C
    ),
    (
      SourceCodePoint: $00001E8F;
      TargetCodePoint: $00001E8E
    ),
    (
      SourceCodePoint: $00001E91;
      TargetCodePoint: $00001E90
    ),
    (
      SourceCodePoint: $00001E93;
      TargetCodePoint: $00001E92
    ),
    (
      SourceCodePoint: $00001E95;
      TargetCodePoint: $00001E94
    ),
    (
      SourceCodePoint: $00001E9B;
      TargetCodePoint: $00001E60
    ),
    (
      SourceCodePoint: $00001EA1;
      TargetCodePoint: $00001EA0
    ),
    (
      SourceCodePoint: $00001EA3;
      TargetCodePoint: $00001EA2
    ),
    (
      SourceCodePoint: $00001EA5;
      TargetCodePoint: $00001EA4
    ),
    (
      SourceCodePoint: $00001EA7;
      TargetCodePoint: $00001EA6
    ),
    (
      SourceCodePoint: $00001EA9;
      TargetCodePoint: $00001EA8
    ),
    (
      SourceCodePoint: $00001EAB;
      TargetCodePoint: $00001EAA
    ),
    (
      SourceCodePoint: $00001EAD;
      TargetCodePoint: $00001EAC
    ),
    (
      SourceCodePoint: $00001EAF;
      TargetCodePoint: $00001EAE
    ),
    (
      SourceCodePoint: $00001EB1;
      TargetCodePoint: $00001EB0
    ),
    (
      SourceCodePoint: $00001EB3;
      TargetCodePoint: $00001EB2
    ),
    (
      SourceCodePoint: $00001EB5;
      TargetCodePoint: $00001EB4
    ),
    (
      SourceCodePoint: $00001EB7;
      TargetCodePoint: $00001EB6
    ),
    (
      SourceCodePoint: $00001EB9;
      TargetCodePoint: $00001EB8
    ),
    (
      SourceCodePoint: $00001EBB;
      TargetCodePoint: $00001EBA
    ),
    (
      SourceCodePoint: $00001EBD;
      TargetCodePoint: $00001EBC
    ),
    (
      SourceCodePoint: $00001EBF;
      TargetCodePoint: $00001EBE
    ),
    (
      SourceCodePoint: $00001EC1;
      TargetCodePoint: $00001EC0
    ),
    (
      SourceCodePoint: $00001EC3;
      TargetCodePoint: $00001EC2
    ),
    (
      SourceCodePoint: $00001EC5;
      TargetCodePoint: $00001EC4
    ),
    (
      SourceCodePoint: $00001EC7;
      TargetCodePoint: $00001EC6
    ),
    (
      SourceCodePoint: $00001EC9;
      TargetCodePoint: $00001EC8
    ),
    (
      SourceCodePoint: $00001ECB;
      TargetCodePoint: $00001ECA
    ),
    (
      SourceCodePoint: $00001ECD;
      TargetCodePoint: $00001ECC
    ),
    (
      SourceCodePoint: $00001ECF;
      TargetCodePoint: $00001ECE
    ),
    (
      SourceCodePoint: $00001ED1;
      TargetCodePoint: $00001ED0
    ),
    (
      SourceCodePoint: $00001ED3;
      TargetCodePoint: $00001ED2
    ),
    (
      SourceCodePoint: $00001ED5;
      TargetCodePoint: $00001ED4
    ),
    (
      SourceCodePoint: $00001ED7;
      TargetCodePoint: $00001ED6
    ),
    (
      SourceCodePoint: $00001ED9;
      TargetCodePoint: $00001ED8
    ),
    (
      SourceCodePoint: $00001EDB;
      TargetCodePoint: $00001EDA
    ),
    (
      SourceCodePoint: $00001EDD;
      TargetCodePoint: $00001EDC
    ),
    (
      SourceCodePoint: $00001EDF;
      TargetCodePoint: $00001EDE
    ),
    (
      SourceCodePoint: $00001EE1;
      TargetCodePoint: $00001EE0
    ),
    (
      SourceCodePoint: $00001EE3;
      TargetCodePoint: $00001EE2
    ),
    (
      SourceCodePoint: $00001EE5;
      TargetCodePoint: $00001EE4
    ),
    (
      SourceCodePoint: $00001EE7;
      TargetCodePoint: $00001EE6
    ),
    (
      SourceCodePoint: $00001EE9;
      TargetCodePoint: $00001EE8
    ),
    (
      SourceCodePoint: $00001EEB;
      TargetCodePoint: $00001EEA
    ),
    (
      SourceCodePoint: $00001EED;
      TargetCodePoint: $00001EEC
    ),
    (
      SourceCodePoint: $00001EEF;
      TargetCodePoint: $00001EEE
    ),
    (
      SourceCodePoint: $00001EF1;
      TargetCodePoint: $00001EF0
    ),
    (
      SourceCodePoint: $00001EF3;
      TargetCodePoint: $00001EF2
    ),
    (
      SourceCodePoint: $00001EF5;
      TargetCodePoint: $00001EF4
    ),
    (
      SourceCodePoint: $00001EF7;
      TargetCodePoint: $00001EF6
    ),
    (
      SourceCodePoint: $00001EF9;
      TargetCodePoint: $00001EF8
    ),
    (
      SourceCodePoint: $00001EFB;
      TargetCodePoint: $00001EFA
    ),
    (
      SourceCodePoint: $00001EFD;
      TargetCodePoint: $00001EFC
    ),
    (
      SourceCodePoint: $00001EFF;
      TargetCodePoint: $00001EFE
    ),
    (
      SourceCodePoint: $00001F00;
      TargetCodePoint: $00001F08
    ),
    (
      SourceCodePoint: $00001F01;
      TargetCodePoint: $00001F09
    ),
    (
      SourceCodePoint: $00001F02;
      TargetCodePoint: $00001F0A
    ),
    (
      SourceCodePoint: $00001F03;
      TargetCodePoint: $00001F0B
    ),
    (
      SourceCodePoint: $00001F04;
      TargetCodePoint: $00001F0C
    ),
    (
      SourceCodePoint: $00001F05;
      TargetCodePoint: $00001F0D
    ),
    (
      SourceCodePoint: $00001F06;
      TargetCodePoint: $00001F0E
    ),
    (
      SourceCodePoint: $00001F07;
      TargetCodePoint: $00001F0F
    ),
    (
      SourceCodePoint: $00001F10;
      TargetCodePoint: $00001F18
    ),
    (
      SourceCodePoint: $00001F11;
      TargetCodePoint: $00001F19
    ),
    (
      SourceCodePoint: $00001F12;
      TargetCodePoint: $00001F1A
    ),
    (
      SourceCodePoint: $00001F13;
      TargetCodePoint: $00001F1B
    ),
    (
      SourceCodePoint: $00001F14;
      TargetCodePoint: $00001F1C
    ),
    (
      SourceCodePoint: $00001F15;
      TargetCodePoint: $00001F1D
    ),
    (
      SourceCodePoint: $00001F20;
      TargetCodePoint: $00001F28
    ),
    (
      SourceCodePoint: $00001F21;
      TargetCodePoint: $00001F29
    ),
    (
      SourceCodePoint: $00001F22;
      TargetCodePoint: $00001F2A
    ),
    (
      SourceCodePoint: $00001F23;
      TargetCodePoint: $00001F2B
    ),
    (
      SourceCodePoint: $00001F24;
      TargetCodePoint: $00001F2C
    ),
    (
      SourceCodePoint: $00001F25;
      TargetCodePoint: $00001F2D
    ),
    (
      SourceCodePoint: $00001F26;
      TargetCodePoint: $00001F2E
    ),
    (
      SourceCodePoint: $00001F27;
      TargetCodePoint: $00001F2F
    ),
    (
      SourceCodePoint: $00001F30;
      TargetCodePoint: $00001F38
    ),
    (
      SourceCodePoint: $00001F31;
      TargetCodePoint: $00001F39
    ),
    (
      SourceCodePoint: $00001F32;
      TargetCodePoint: $00001F3A
    ),
    (
      SourceCodePoint: $00001F33;
      TargetCodePoint: $00001F3B
    ),
    (
      SourceCodePoint: $00001F34;
      TargetCodePoint: $00001F3C
    ),
    (
      SourceCodePoint: $00001F35;
      TargetCodePoint: $00001F3D
    ),
    (
      SourceCodePoint: $00001F36;
      TargetCodePoint: $00001F3E
    ),
    (
      SourceCodePoint: $00001F37;
      TargetCodePoint: $00001F3F
    ),
    (
      SourceCodePoint: $00001F40;
      TargetCodePoint: $00001F48
    ),
    (
      SourceCodePoint: $00001F41;
      TargetCodePoint: $00001F49
    ),
    (
      SourceCodePoint: $00001F42;
      TargetCodePoint: $00001F4A
    ),
    (
      SourceCodePoint: $00001F43;
      TargetCodePoint: $00001F4B
    ),
    (
      SourceCodePoint: $00001F44;
      TargetCodePoint: $00001F4C
    ),
    (
      SourceCodePoint: $00001F45;
      TargetCodePoint: $00001F4D
    ),
    (
      SourceCodePoint: $00001F51;
      TargetCodePoint: $00001F59
    ),
    (
      SourceCodePoint: $00001F53;
      TargetCodePoint: $00001F5B
    ),
    (
      SourceCodePoint: $00001F55;
      TargetCodePoint: $00001F5D
    ),
    (
      SourceCodePoint: $00001F57;
      TargetCodePoint: $00001F5F
    ),
    (
      SourceCodePoint: $00001F60;
      TargetCodePoint: $00001F68
    ),
    (
      SourceCodePoint: $00001F61;
      TargetCodePoint: $00001F69
    ),
    (
      SourceCodePoint: $00001F62;
      TargetCodePoint: $00001F6A
    ),
    (
      SourceCodePoint: $00001F63;
      TargetCodePoint: $00001F6B
    ),
    (
      SourceCodePoint: $00001F64;
      TargetCodePoint: $00001F6C
    ),
    (
      SourceCodePoint: $00001F65;
      TargetCodePoint: $00001F6D
    ),
    (
      SourceCodePoint: $00001F66;
      TargetCodePoint: $00001F6E
    ),
    (
      SourceCodePoint: $00001F67;
      TargetCodePoint: $00001F6F
    ),
    (
      SourceCodePoint: $00001F70;
      TargetCodePoint: $00001FBA
    ),
    (
      SourceCodePoint: $00001F71;
      TargetCodePoint: $00001FBB
    ),
    (
      SourceCodePoint: $00001F72;
      TargetCodePoint: $00001FC8
    ),
    (
      SourceCodePoint: $00001F73;
      TargetCodePoint: $00001FC9
    ),
    (
      SourceCodePoint: $00001F74;
      TargetCodePoint: $00001FCA
    ),
    (
      SourceCodePoint: $00001F75;
      TargetCodePoint: $00001FCB
    ),
    (
      SourceCodePoint: $00001F76;
      TargetCodePoint: $00001FDA
    ),
    (
      SourceCodePoint: $00001F77;
      TargetCodePoint: $00001FDB
    ),
    (
      SourceCodePoint: $00001F78;
      TargetCodePoint: $00001FF8
    ),
    (
      SourceCodePoint: $00001F79;
      TargetCodePoint: $00001FF9
    ),
    (
      SourceCodePoint: $00001F7A;
      TargetCodePoint: $00001FEA
    ),
    (
      SourceCodePoint: $00001F7B;
      TargetCodePoint: $00001FEB
    ),
    (
      SourceCodePoint: $00001F7C;
      TargetCodePoint: $00001FFA
    ),
    (
      SourceCodePoint: $00001F7D;
      TargetCodePoint: $00001FFB
    ),
    (
      SourceCodePoint: $00001FB0;
      TargetCodePoint: $00001FB8
    ),
    (
      SourceCodePoint: $00001FB1;
      TargetCodePoint: $00001FB9
    ),
    (
      SourceCodePoint: $00001FBE;
      TargetCodePoint: $00000399
    ),
    (
      SourceCodePoint: $00001FD0;
      TargetCodePoint: $00001FD8
    ),
    (
      SourceCodePoint: $00001FD1;
      TargetCodePoint: $00001FD9
    ),
    (
      SourceCodePoint: $00001FE0;
      TargetCodePoint: $00001FE8
    ),
    (
      SourceCodePoint: $00001FE1;
      TargetCodePoint: $00001FE9
    ),
    (
      SourceCodePoint: $00001FE5;
      TargetCodePoint: $00001FEC
    ),
    (
      SourceCodePoint: $0000214E;
      TargetCodePoint: $00002132
    ),
    (
      SourceCodePoint: $00002170;
      TargetCodePoint: $00002160
    ),
    (
      SourceCodePoint: $00002171;
      TargetCodePoint: $00002161
    ),
    (
      SourceCodePoint: $00002172;
      TargetCodePoint: $00002162
    ),
    (
      SourceCodePoint: $00002173;
      TargetCodePoint: $00002163
    ),
    (
      SourceCodePoint: $00002174;
      TargetCodePoint: $00002164
    ),
    (
      SourceCodePoint: $00002175;
      TargetCodePoint: $00002165
    ),
    (
      SourceCodePoint: $00002176;
      TargetCodePoint: $00002166
    ),
    (
      SourceCodePoint: $00002177;
      TargetCodePoint: $00002167
    ),
    (
      SourceCodePoint: $00002178;
      TargetCodePoint: $00002168
    ),
    (
      SourceCodePoint: $00002179;
      TargetCodePoint: $00002169
    ),
    (
      SourceCodePoint: $0000217A;
      TargetCodePoint: $0000216A
    ),
    (
      SourceCodePoint: $0000217B;
      TargetCodePoint: $0000216B
    ),
    (
      SourceCodePoint: $0000217C;
      TargetCodePoint: $0000216C
    ),
    (
      SourceCodePoint: $0000217D;
      TargetCodePoint: $0000216D
    ),
    (
      SourceCodePoint: $0000217E;
      TargetCodePoint: $0000216E
    ),
    (
      SourceCodePoint: $0000217F;
      TargetCodePoint: $0000216F
    ),
    (
      SourceCodePoint: $00002184;
      TargetCodePoint: $00002183
    ),
    (
      SourceCodePoint: $000024D0;
      TargetCodePoint: $000024B6
    ),
    (
      SourceCodePoint: $000024D1;
      TargetCodePoint: $000024B7
    ),
    (
      SourceCodePoint: $000024D2;
      TargetCodePoint: $000024B8
    ),
    (
      SourceCodePoint: $000024D3;
      TargetCodePoint: $000024B9
    ),
    (
      SourceCodePoint: $000024D4;
      TargetCodePoint: $000024BA
    ),
    (
      SourceCodePoint: $000024D5;
      TargetCodePoint: $000024BB
    ),
    (
      SourceCodePoint: $000024D6;
      TargetCodePoint: $000024BC
    ),
    (
      SourceCodePoint: $000024D7;
      TargetCodePoint: $000024BD
    ),
    (
      SourceCodePoint: $000024D8;
      TargetCodePoint: $000024BE
    ),
    (
      SourceCodePoint: $000024D9;
      TargetCodePoint: $000024BF
    ),
    (
      SourceCodePoint: $000024DA;
      TargetCodePoint: $000024C0
    ),
    (
      SourceCodePoint: $000024DB;
      TargetCodePoint: $000024C1
    ),
    (
      SourceCodePoint: $000024DC;
      TargetCodePoint: $000024C2
    ),
    (
      SourceCodePoint: $000024DD;
      TargetCodePoint: $000024C3
    ),
    (
      SourceCodePoint: $000024DE;
      TargetCodePoint: $000024C4
    ),
    (
      SourceCodePoint: $000024DF;
      TargetCodePoint: $000024C5
    ),
    (
      SourceCodePoint: $000024E0;
      TargetCodePoint: $000024C6
    ),
    (
      SourceCodePoint: $000024E1;
      TargetCodePoint: $000024C7
    ),
    (
      SourceCodePoint: $000024E2;
      TargetCodePoint: $000024C8
    ),
    (
      SourceCodePoint: $000024E3;
      TargetCodePoint: $000024C9
    ),
    (
      SourceCodePoint: $000024E4;
      TargetCodePoint: $000024CA
    ),
    (
      SourceCodePoint: $000024E5;
      TargetCodePoint: $000024CB
    ),
    (
      SourceCodePoint: $000024E6;
      TargetCodePoint: $000024CC
    ),
    (
      SourceCodePoint: $000024E7;
      TargetCodePoint: $000024CD
    ),
    (
      SourceCodePoint: $000024E8;
      TargetCodePoint: $000024CE
    ),
    (
      SourceCodePoint: $000024E9;
      TargetCodePoint: $000024CF
    ),
    (
      SourceCodePoint: $00002C30;
      TargetCodePoint: $00002C00
    ),
    (
      SourceCodePoint: $00002C31;
      TargetCodePoint: $00002C01
    ),
    (
      SourceCodePoint: $00002C32;
      TargetCodePoint: $00002C02
    ),
    (
      SourceCodePoint: $00002C33;
      TargetCodePoint: $00002C03
    ),
    (
      SourceCodePoint: $00002C34;
      TargetCodePoint: $00002C04
    ),
    (
      SourceCodePoint: $00002C35;
      TargetCodePoint: $00002C05
    ),
    (
      SourceCodePoint: $00002C36;
      TargetCodePoint: $00002C06
    ),
    (
      SourceCodePoint: $00002C37;
      TargetCodePoint: $00002C07
    ),
    (
      SourceCodePoint: $00002C38;
      TargetCodePoint: $00002C08
    ),
    (
      SourceCodePoint: $00002C39;
      TargetCodePoint: $00002C09
    ),
    (
      SourceCodePoint: $00002C3A;
      TargetCodePoint: $00002C0A
    ),
    (
      SourceCodePoint: $00002C3B;
      TargetCodePoint: $00002C0B
    ),
    (
      SourceCodePoint: $00002C3C;
      TargetCodePoint: $00002C0C
    ),
    (
      SourceCodePoint: $00002C3D;
      TargetCodePoint: $00002C0D
    ),
    (
      SourceCodePoint: $00002C3E;
      TargetCodePoint: $00002C0E
    ),
    (
      SourceCodePoint: $00002C3F;
      TargetCodePoint: $00002C0F
    ),
    (
      SourceCodePoint: $00002C40;
      TargetCodePoint: $00002C10
    ),
    (
      SourceCodePoint: $00002C41;
      TargetCodePoint: $00002C11
    ),
    (
      SourceCodePoint: $00002C42;
      TargetCodePoint: $00002C12
    ),
    (
      SourceCodePoint: $00002C43;
      TargetCodePoint: $00002C13
    ),
    (
      SourceCodePoint: $00002C44;
      TargetCodePoint: $00002C14
    ),
    (
      SourceCodePoint: $00002C45;
      TargetCodePoint: $00002C15
    ),
    (
      SourceCodePoint: $00002C46;
      TargetCodePoint: $00002C16
    ),
    (
      SourceCodePoint: $00002C47;
      TargetCodePoint: $00002C17
    ),
    (
      SourceCodePoint: $00002C48;
      TargetCodePoint: $00002C18
    ),
    (
      SourceCodePoint: $00002C49;
      TargetCodePoint: $00002C19
    ),
    (
      SourceCodePoint: $00002C4A;
      TargetCodePoint: $00002C1A
    ),
    (
      SourceCodePoint: $00002C4B;
      TargetCodePoint: $00002C1B
    ),
    (
      SourceCodePoint: $00002C4C;
      TargetCodePoint: $00002C1C
    ),
    (
      SourceCodePoint: $00002C4D;
      TargetCodePoint: $00002C1D
    ),
    (
      SourceCodePoint: $00002C4E;
      TargetCodePoint: $00002C1E
    ),
    (
      SourceCodePoint: $00002C4F;
      TargetCodePoint: $00002C1F
    ),
    (
      SourceCodePoint: $00002C50;
      TargetCodePoint: $00002C20
    ),
    (
      SourceCodePoint: $00002C51;
      TargetCodePoint: $00002C21
    ),
    (
      SourceCodePoint: $00002C52;
      TargetCodePoint: $00002C22
    ),
    (
      SourceCodePoint: $00002C53;
      TargetCodePoint: $00002C23
    ),
    (
      SourceCodePoint: $00002C54;
      TargetCodePoint: $00002C24
    ),
    (
      SourceCodePoint: $00002C55;
      TargetCodePoint: $00002C25
    ),
    (
      SourceCodePoint: $00002C56;
      TargetCodePoint: $00002C26
    ),
    (
      SourceCodePoint: $00002C57;
      TargetCodePoint: $00002C27
    ),
    (
      SourceCodePoint: $00002C58;
      TargetCodePoint: $00002C28
    ),
    (
      SourceCodePoint: $00002C59;
      TargetCodePoint: $00002C29
    ),
    (
      SourceCodePoint: $00002C5A;
      TargetCodePoint: $00002C2A
    ),
    (
      SourceCodePoint: $00002C5B;
      TargetCodePoint: $00002C2B
    ),
    (
      SourceCodePoint: $00002C5C;
      TargetCodePoint: $00002C2C
    ),
    (
      SourceCodePoint: $00002C5D;
      TargetCodePoint: $00002C2D
    ),
    (
      SourceCodePoint: $00002C5E;
      TargetCodePoint: $00002C2E
    ),
    (
      SourceCodePoint: $00002C5F;
      TargetCodePoint: $00002C2F
    ),
    (
      SourceCodePoint: $00002C61;
      TargetCodePoint: $00002C60
    ),
    (
      SourceCodePoint: $00002C65;
      TargetCodePoint: $0000023A
    ),
    (
      SourceCodePoint: $00002C66;
      TargetCodePoint: $0000023E
    ),
    (
      SourceCodePoint: $00002C68;
      TargetCodePoint: $00002C67
    ),
    (
      SourceCodePoint: $00002C6A;
      TargetCodePoint: $00002C69
    ),
    (
      SourceCodePoint: $00002C6C;
      TargetCodePoint: $00002C6B
    ),
    (
      SourceCodePoint: $00002C73;
      TargetCodePoint: $00002C72
    ),
    (
      SourceCodePoint: $00002C76;
      TargetCodePoint: $00002C75
    ),
    (
      SourceCodePoint: $00002C81;
      TargetCodePoint: $00002C80
    ),
    (
      SourceCodePoint: $00002C83;
      TargetCodePoint: $00002C82
    ),
    (
      SourceCodePoint: $00002C85;
      TargetCodePoint: $00002C84
    ),
    (
      SourceCodePoint: $00002C87;
      TargetCodePoint: $00002C86
    ),
    (
      SourceCodePoint: $00002C89;
      TargetCodePoint: $00002C88
    ),
    (
      SourceCodePoint: $00002C8B;
      TargetCodePoint: $00002C8A
    ),
    (
      SourceCodePoint: $00002C8D;
      TargetCodePoint: $00002C8C
    ),
    (
      SourceCodePoint: $00002C8F;
      TargetCodePoint: $00002C8E
    ),
    (
      SourceCodePoint: $00002C91;
      TargetCodePoint: $00002C90
    ),
    (
      SourceCodePoint: $00002C93;
      TargetCodePoint: $00002C92
    ),
    (
      SourceCodePoint: $00002C95;
      TargetCodePoint: $00002C94
    ),
    (
      SourceCodePoint: $00002C97;
      TargetCodePoint: $00002C96
    ),
    (
      SourceCodePoint: $00002C99;
      TargetCodePoint: $00002C98
    ),
    (
      SourceCodePoint: $00002C9B;
      TargetCodePoint: $00002C9A
    ),
    (
      SourceCodePoint: $00002C9D;
      TargetCodePoint: $00002C9C
    ),
    (
      SourceCodePoint: $00002C9F;
      TargetCodePoint: $00002C9E
    ),
    (
      SourceCodePoint: $00002CA1;
      TargetCodePoint: $00002CA0
    ),
    (
      SourceCodePoint: $00002CA3;
      TargetCodePoint: $00002CA2
    ),
    (
      SourceCodePoint: $00002CA5;
      TargetCodePoint: $00002CA4
    ),
    (
      SourceCodePoint: $00002CA7;
      TargetCodePoint: $00002CA6
    ),
    (
      SourceCodePoint: $00002CA9;
      TargetCodePoint: $00002CA8
    ),
    (
      SourceCodePoint: $00002CAB;
      TargetCodePoint: $00002CAA
    ),
    (
      SourceCodePoint: $00002CAD;
      TargetCodePoint: $00002CAC
    ),
    (
      SourceCodePoint: $00002CAF;
      TargetCodePoint: $00002CAE
    ),
    (
      SourceCodePoint: $00002CB1;
      TargetCodePoint: $00002CB0
    ),
    (
      SourceCodePoint: $00002CB3;
      TargetCodePoint: $00002CB2
    ),
    (
      SourceCodePoint: $00002CB5;
      TargetCodePoint: $00002CB4
    ),
    (
      SourceCodePoint: $00002CB7;
      TargetCodePoint: $00002CB6
    ),
    (
      SourceCodePoint: $00002CB9;
      TargetCodePoint: $00002CB8
    ),
    (
      SourceCodePoint: $00002CBB;
      TargetCodePoint: $00002CBA
    ),
    (
      SourceCodePoint: $00002CBD;
      TargetCodePoint: $00002CBC
    ),
    (
      SourceCodePoint: $00002CBF;
      TargetCodePoint: $00002CBE
    ),
    (
      SourceCodePoint: $00002CC1;
      TargetCodePoint: $00002CC0
    ),
    (
      SourceCodePoint: $00002CC3;
      TargetCodePoint: $00002CC2
    ),
    (
      SourceCodePoint: $00002CC5;
      TargetCodePoint: $00002CC4
    ),
    (
      SourceCodePoint: $00002CC7;
      TargetCodePoint: $00002CC6
    ),
    (
      SourceCodePoint: $00002CC9;
      TargetCodePoint: $00002CC8
    ),
    (
      SourceCodePoint: $00002CCB;
      TargetCodePoint: $00002CCA
    ),
    (
      SourceCodePoint: $00002CCD;
      TargetCodePoint: $00002CCC
    ),
    (
      SourceCodePoint: $00002CCF;
      TargetCodePoint: $00002CCE
    ),
    (
      SourceCodePoint: $00002CD1;
      TargetCodePoint: $00002CD0
    ),
    (
      SourceCodePoint: $00002CD3;
      TargetCodePoint: $00002CD2
    ),
    (
      SourceCodePoint: $00002CD5;
      TargetCodePoint: $00002CD4
    ),
    (
      SourceCodePoint: $00002CD7;
      TargetCodePoint: $00002CD6
    ),
    (
      SourceCodePoint: $00002CD9;
      TargetCodePoint: $00002CD8
    ),
    (
      SourceCodePoint: $00002CDB;
      TargetCodePoint: $00002CDA
    ),
    (
      SourceCodePoint: $00002CDD;
      TargetCodePoint: $00002CDC
    ),
    (
      SourceCodePoint: $00002CDF;
      TargetCodePoint: $00002CDE
    ),
    (
      SourceCodePoint: $00002CE1;
      TargetCodePoint: $00002CE0
    ),
    (
      SourceCodePoint: $00002CE3;
      TargetCodePoint: $00002CE2
    ),
    (
      SourceCodePoint: $00002CEC;
      TargetCodePoint: $00002CEB
    ),
    (
      SourceCodePoint: $00002CEE;
      TargetCodePoint: $00002CED
    ),
    (
      SourceCodePoint: $00002CF3;
      TargetCodePoint: $00002CF2
    ),
    (
      SourceCodePoint: $00002D00;
      TargetCodePoint: $000010A0
    ),
    (
      SourceCodePoint: $00002D01;
      TargetCodePoint: $000010A1
    ),
    (
      SourceCodePoint: $00002D02;
      TargetCodePoint: $000010A2
    ),
    (
      SourceCodePoint: $00002D03;
      TargetCodePoint: $000010A3
    ),
    (
      SourceCodePoint: $00002D04;
      TargetCodePoint: $000010A4
    ),
    (
      SourceCodePoint: $00002D05;
      TargetCodePoint: $000010A5
    ),
    (
      SourceCodePoint: $00002D06;
      TargetCodePoint: $000010A6
    ),
    (
      SourceCodePoint: $00002D07;
      TargetCodePoint: $000010A7
    ),
    (
      SourceCodePoint: $00002D08;
      TargetCodePoint: $000010A8
    ),
    (
      SourceCodePoint: $00002D09;
      TargetCodePoint: $000010A9
    ),
    (
      SourceCodePoint: $00002D0A;
      TargetCodePoint: $000010AA
    ),
    (
      SourceCodePoint: $00002D0B;
      TargetCodePoint: $000010AB
    ),
    (
      SourceCodePoint: $00002D0C;
      TargetCodePoint: $000010AC
    ),
    (
      SourceCodePoint: $00002D0D;
      TargetCodePoint: $000010AD
    ),
    (
      SourceCodePoint: $00002D0E;
      TargetCodePoint: $000010AE
    ),
    (
      SourceCodePoint: $00002D0F;
      TargetCodePoint: $000010AF
    ),
    (
      SourceCodePoint: $00002D10;
      TargetCodePoint: $000010B0
    ),
    (
      SourceCodePoint: $00002D11;
      TargetCodePoint: $000010B1
    ),
    (
      SourceCodePoint: $00002D12;
      TargetCodePoint: $000010B2
    ),
    (
      SourceCodePoint: $00002D13;
      TargetCodePoint: $000010B3
    ),
    (
      SourceCodePoint: $00002D14;
      TargetCodePoint: $000010B4
    ),
    (
      SourceCodePoint: $00002D15;
      TargetCodePoint: $000010B5
    ),
    (
      SourceCodePoint: $00002D16;
      TargetCodePoint: $000010B6
    ),
    (
      SourceCodePoint: $00002D17;
      TargetCodePoint: $000010B7
    ),
    (
      SourceCodePoint: $00002D18;
      TargetCodePoint: $000010B8
    ),
    (
      SourceCodePoint: $00002D19;
      TargetCodePoint: $000010B9
    ),
    (
      SourceCodePoint: $00002D1A;
      TargetCodePoint: $000010BA
    ),
    (
      SourceCodePoint: $00002D1B;
      TargetCodePoint: $000010BB
    ),
    (
      SourceCodePoint: $00002D1C;
      TargetCodePoint: $000010BC
    ),
    (
      SourceCodePoint: $00002D1D;
      TargetCodePoint: $000010BD
    ),
    (
      SourceCodePoint: $00002D1E;
      TargetCodePoint: $000010BE
    ),
    (
      SourceCodePoint: $00002D1F;
      TargetCodePoint: $000010BF
    ),
    (
      SourceCodePoint: $00002D20;
      TargetCodePoint: $000010C0
    ),
    (
      SourceCodePoint: $00002D21;
      TargetCodePoint: $000010C1
    ),
    (
      SourceCodePoint: $00002D22;
      TargetCodePoint: $000010C2
    ),
    (
      SourceCodePoint: $00002D23;
      TargetCodePoint: $000010C3
    ),
    (
      SourceCodePoint: $00002D24;
      TargetCodePoint: $000010C4
    ),
    (
      SourceCodePoint: $00002D25;
      TargetCodePoint: $000010C5
    ),
    (
      SourceCodePoint: $00002D27;
      TargetCodePoint: $000010C7
    ),
    (
      SourceCodePoint: $00002D2D;
      TargetCodePoint: $000010CD
    ),
    (
      SourceCodePoint: $0000A641;
      TargetCodePoint: $0000A640
    ),
    (
      SourceCodePoint: $0000A643;
      TargetCodePoint: $0000A642
    ),
    (
      SourceCodePoint: $0000A645;
      TargetCodePoint: $0000A644
    ),
    (
      SourceCodePoint: $0000A647;
      TargetCodePoint: $0000A646
    ),
    (
      SourceCodePoint: $0000A649;
      TargetCodePoint: $0000A648
    ),
    (
      SourceCodePoint: $0000A64B;
      TargetCodePoint: $0000A64A
    ),
    (
      SourceCodePoint: $0000A64D;
      TargetCodePoint: $0000A64C
    ),
    (
      SourceCodePoint: $0000A64F;
      TargetCodePoint: $0000A64E
    ),
    (
      SourceCodePoint: $0000A651;
      TargetCodePoint: $0000A650
    ),
    (
      SourceCodePoint: $0000A653;
      TargetCodePoint: $0000A652
    ),
    (
      SourceCodePoint: $0000A655;
      TargetCodePoint: $0000A654
    ),
    (
      SourceCodePoint: $0000A657;
      TargetCodePoint: $0000A656
    ),
    (
      SourceCodePoint: $0000A659;
      TargetCodePoint: $0000A658
    ),
    (
      SourceCodePoint: $0000A65B;
      TargetCodePoint: $0000A65A
    ),
    (
      SourceCodePoint: $0000A65D;
      TargetCodePoint: $0000A65C
    ),
    (
      SourceCodePoint: $0000A65F;
      TargetCodePoint: $0000A65E
    ),
    (
      SourceCodePoint: $0000A661;
      TargetCodePoint: $0000A660
    ),
    (
      SourceCodePoint: $0000A663;
      TargetCodePoint: $0000A662
    ),
    (
      SourceCodePoint: $0000A665;
      TargetCodePoint: $0000A664
    ),
    (
      SourceCodePoint: $0000A667;
      TargetCodePoint: $0000A666
    ),
    (
      SourceCodePoint: $0000A669;
      TargetCodePoint: $0000A668
    ),
    (
      SourceCodePoint: $0000A66B;
      TargetCodePoint: $0000A66A
    ),
    (
      SourceCodePoint: $0000A66D;
      TargetCodePoint: $0000A66C
    ),
    (
      SourceCodePoint: $0000A681;
      TargetCodePoint: $0000A680
    ),
    (
      SourceCodePoint: $0000A683;
      TargetCodePoint: $0000A682
    ),
    (
      SourceCodePoint: $0000A685;
      TargetCodePoint: $0000A684
    ),
    (
      SourceCodePoint: $0000A687;
      TargetCodePoint: $0000A686
    ),
    (
      SourceCodePoint: $0000A689;
      TargetCodePoint: $0000A688
    ),
    (
      SourceCodePoint: $0000A68B;
      TargetCodePoint: $0000A68A
    ),
    (
      SourceCodePoint: $0000A68D;
      TargetCodePoint: $0000A68C
    ),
    (
      SourceCodePoint: $0000A68F;
      TargetCodePoint: $0000A68E
    ),
    (
      SourceCodePoint: $0000A691;
      TargetCodePoint: $0000A690
    ),
    (
      SourceCodePoint: $0000A693;
      TargetCodePoint: $0000A692
    ),
    (
      SourceCodePoint: $0000A695;
      TargetCodePoint: $0000A694
    ),
    (
      SourceCodePoint: $0000A697;
      TargetCodePoint: $0000A696
    ),
    (
      SourceCodePoint: $0000A699;
      TargetCodePoint: $0000A698
    ),
    (
      SourceCodePoint: $0000A69B;
      TargetCodePoint: $0000A69A
    ),
    (
      SourceCodePoint: $0000A723;
      TargetCodePoint: $0000A722
    ),
    (
      SourceCodePoint: $0000A725;
      TargetCodePoint: $0000A724
    ),
    (
      SourceCodePoint: $0000A727;
      TargetCodePoint: $0000A726
    ),
    (
      SourceCodePoint: $0000A729;
      TargetCodePoint: $0000A728
    ),
    (
      SourceCodePoint: $0000A72B;
      TargetCodePoint: $0000A72A
    ),
    (
      SourceCodePoint: $0000A72D;
      TargetCodePoint: $0000A72C
    ),
    (
      SourceCodePoint: $0000A72F;
      TargetCodePoint: $0000A72E
    ),
    (
      SourceCodePoint: $0000A733;
      TargetCodePoint: $0000A732
    ),
    (
      SourceCodePoint: $0000A735;
      TargetCodePoint: $0000A734
    ),
    (
      SourceCodePoint: $0000A737;
      TargetCodePoint: $0000A736
    ),
    (
      SourceCodePoint: $0000A739;
      TargetCodePoint: $0000A738
    ),
    (
      SourceCodePoint: $0000A73B;
      TargetCodePoint: $0000A73A
    ),
    (
      SourceCodePoint: $0000A73D;
      TargetCodePoint: $0000A73C
    ),
    (
      SourceCodePoint: $0000A73F;
      TargetCodePoint: $0000A73E
    ),
    (
      SourceCodePoint: $0000A741;
      TargetCodePoint: $0000A740
    ),
    (
      SourceCodePoint: $0000A743;
      TargetCodePoint: $0000A742
    ),
    (
      SourceCodePoint: $0000A745;
      TargetCodePoint: $0000A744
    ),
    (
      SourceCodePoint: $0000A747;
      TargetCodePoint: $0000A746
    ),
    (
      SourceCodePoint: $0000A749;
      TargetCodePoint: $0000A748
    ),
    (
      SourceCodePoint: $0000A74B;
      TargetCodePoint: $0000A74A
    ),
    (
      SourceCodePoint: $0000A74D;
      TargetCodePoint: $0000A74C
    ),
    (
      SourceCodePoint: $0000A74F;
      TargetCodePoint: $0000A74E
    ),
    (
      SourceCodePoint: $0000A751;
      TargetCodePoint: $0000A750
    ),
    (
      SourceCodePoint: $0000A753;
      TargetCodePoint: $0000A752
    ),
    (
      SourceCodePoint: $0000A755;
      TargetCodePoint: $0000A754
    ),
    (
      SourceCodePoint: $0000A757;
      TargetCodePoint: $0000A756
    ),
    (
      SourceCodePoint: $0000A759;
      TargetCodePoint: $0000A758
    ),
    (
      SourceCodePoint: $0000A75B;
      TargetCodePoint: $0000A75A
    ),
    (
      SourceCodePoint: $0000A75D;
      TargetCodePoint: $0000A75C
    ),
    (
      SourceCodePoint: $0000A75F;
      TargetCodePoint: $0000A75E
    ),
    (
      SourceCodePoint: $0000A761;
      TargetCodePoint: $0000A760
    ),
    (
      SourceCodePoint: $0000A763;
      TargetCodePoint: $0000A762
    ),
    (
      SourceCodePoint: $0000A765;
      TargetCodePoint: $0000A764
    ),
    (
      SourceCodePoint: $0000A767;
      TargetCodePoint: $0000A766
    ),
    (
      SourceCodePoint: $0000A769;
      TargetCodePoint: $0000A768
    ),
    (
      SourceCodePoint: $0000A76B;
      TargetCodePoint: $0000A76A
    ),
    (
      SourceCodePoint: $0000A76D;
      TargetCodePoint: $0000A76C
    ),
    (
      SourceCodePoint: $0000A76F;
      TargetCodePoint: $0000A76E
    ),
    (
      SourceCodePoint: $0000A77A;
      TargetCodePoint: $0000A779
    ),
    (
      SourceCodePoint: $0000A77C;
      TargetCodePoint: $0000A77B
    ),
    (
      SourceCodePoint: $0000A77F;
      TargetCodePoint: $0000A77E
    ),
    (
      SourceCodePoint: $0000A781;
      TargetCodePoint: $0000A780
    ),
    (
      SourceCodePoint: $0000A783;
      TargetCodePoint: $0000A782
    ),
    (
      SourceCodePoint: $0000A785;
      TargetCodePoint: $0000A784
    ),
    (
      SourceCodePoint: $0000A787;
      TargetCodePoint: $0000A786
    ),
    (
      SourceCodePoint: $0000A78C;
      TargetCodePoint: $0000A78B
    ),
    (
      SourceCodePoint: $0000A791;
      TargetCodePoint: $0000A790
    ),
    (
      SourceCodePoint: $0000A793;
      TargetCodePoint: $0000A792
    ),
    (
      SourceCodePoint: $0000A794;
      TargetCodePoint: $0000A7C4
    ),
    (
      SourceCodePoint: $0000A797;
      TargetCodePoint: $0000A796
    ),
    (
      SourceCodePoint: $0000A799;
      TargetCodePoint: $0000A798
    ),
    (
      SourceCodePoint: $0000A79B;
      TargetCodePoint: $0000A79A
    ),
    (
      SourceCodePoint: $0000A79D;
      TargetCodePoint: $0000A79C
    ),
    (
      SourceCodePoint: $0000A79F;
      TargetCodePoint: $0000A79E
    ),
    (
      SourceCodePoint: $0000A7A1;
      TargetCodePoint: $0000A7A0
    ),
    (
      SourceCodePoint: $0000A7A3;
      TargetCodePoint: $0000A7A2
    ),
    (
      SourceCodePoint: $0000A7A5;
      TargetCodePoint: $0000A7A4
    ),
    (
      SourceCodePoint: $0000A7A7;
      TargetCodePoint: $0000A7A6
    ),
    (
      SourceCodePoint: $0000A7A9;
      TargetCodePoint: $0000A7A8
    ),
    (
      SourceCodePoint: $0000A7B5;
      TargetCodePoint: $0000A7B4
    ),
    (
      SourceCodePoint: $0000A7B7;
      TargetCodePoint: $0000A7B6
    ),
    (
      SourceCodePoint: $0000A7B9;
      TargetCodePoint: $0000A7B8
    ),
    (
      SourceCodePoint: $0000A7BB;
      TargetCodePoint: $0000A7BA
    ),
    (
      SourceCodePoint: $0000A7BD;
      TargetCodePoint: $0000A7BC
    ),
    (
      SourceCodePoint: $0000A7BF;
      TargetCodePoint: $0000A7BE
    ),
    (
      SourceCodePoint: $0000A7C1;
      TargetCodePoint: $0000A7C0
    ),
    (
      SourceCodePoint: $0000A7C3;
      TargetCodePoint: $0000A7C2
    ),
    (
      SourceCodePoint: $0000A7C8;
      TargetCodePoint: $0000A7C7
    ),
    (
      SourceCodePoint: $0000A7CA;
      TargetCodePoint: $0000A7C9
    ),
    (
      SourceCodePoint: $0000A7D1;
      TargetCodePoint: $0000A7D0
    ),
    (
      SourceCodePoint: $0000A7D7;
      TargetCodePoint: $0000A7D6
    ),
    (
      SourceCodePoint: $0000A7D9;
      TargetCodePoint: $0000A7D8
    ),
    (
      SourceCodePoint: $0000A7F6;
      TargetCodePoint: $0000A7F5
    ),
    (
      SourceCodePoint: $0000AB53;
      TargetCodePoint: $0000A7B3
    ),
    (
      SourceCodePoint: $0000AB70;
      TargetCodePoint: $000013A0
    ),
    (
      SourceCodePoint: $0000AB71;
      TargetCodePoint: $000013A1
    ),
    (
      SourceCodePoint: $0000AB72;
      TargetCodePoint: $000013A2
    ),
    (
      SourceCodePoint: $0000AB73;
      TargetCodePoint: $000013A3
    ),
    (
      SourceCodePoint: $0000AB74;
      TargetCodePoint: $000013A4
    ),
    (
      SourceCodePoint: $0000AB75;
      TargetCodePoint: $000013A5
    ),
    (
      SourceCodePoint: $0000AB76;
      TargetCodePoint: $000013A6
    ),
    (
      SourceCodePoint: $0000AB77;
      TargetCodePoint: $000013A7
    ),
    (
      SourceCodePoint: $0000AB78;
      TargetCodePoint: $000013A8
    ),
    (
      SourceCodePoint: $0000AB79;
      TargetCodePoint: $000013A9
    ),
    (
      SourceCodePoint: $0000AB7A;
      TargetCodePoint: $000013AA
    ),
    (
      SourceCodePoint: $0000AB7B;
      TargetCodePoint: $000013AB
    ),
    (
      SourceCodePoint: $0000AB7C;
      TargetCodePoint: $000013AC
    ),
    (
      SourceCodePoint: $0000AB7D;
      TargetCodePoint: $000013AD
    ),
    (
      SourceCodePoint: $0000AB7E;
      TargetCodePoint: $000013AE
    ),
    (
      SourceCodePoint: $0000AB7F;
      TargetCodePoint: $000013AF
    ),
    (
      SourceCodePoint: $0000AB80;
      TargetCodePoint: $000013B0
    ),
    (
      SourceCodePoint: $0000AB81;
      TargetCodePoint: $000013B1
    ),
    (
      SourceCodePoint: $0000AB82;
      TargetCodePoint: $000013B2
    ),
    (
      SourceCodePoint: $0000AB83;
      TargetCodePoint: $000013B3
    ),
    (
      SourceCodePoint: $0000AB84;
      TargetCodePoint: $000013B4
    ),
    (
      SourceCodePoint: $0000AB85;
      TargetCodePoint: $000013B5
    ),
    (
      SourceCodePoint: $0000AB86;
      TargetCodePoint: $000013B6
    ),
    (
      SourceCodePoint: $0000AB87;
      TargetCodePoint: $000013B7
    ),
    (
      SourceCodePoint: $0000AB88;
      TargetCodePoint: $000013B8
    ),
    (
      SourceCodePoint: $0000AB89;
      TargetCodePoint: $000013B9
    ),
    (
      SourceCodePoint: $0000AB8A;
      TargetCodePoint: $000013BA
    ),
    (
      SourceCodePoint: $0000AB8B;
      TargetCodePoint: $000013BB
    ),
    (
      SourceCodePoint: $0000AB8C;
      TargetCodePoint: $000013BC
    ),
    (
      SourceCodePoint: $0000AB8D;
      TargetCodePoint: $000013BD
    ),
    (
      SourceCodePoint: $0000AB8E;
      TargetCodePoint: $000013BE
    ),
    (
      SourceCodePoint: $0000AB8F;
      TargetCodePoint: $000013BF
    ),
    (
      SourceCodePoint: $0000AB90;
      TargetCodePoint: $000013C0
    ),
    (
      SourceCodePoint: $0000AB91;
      TargetCodePoint: $000013C1
    ),
    (
      SourceCodePoint: $0000AB92;
      TargetCodePoint: $000013C2
    ),
    (
      SourceCodePoint: $0000AB93;
      TargetCodePoint: $000013C3
    ),
    (
      SourceCodePoint: $0000AB94;
      TargetCodePoint: $000013C4
    ),
    (
      SourceCodePoint: $0000AB95;
      TargetCodePoint: $000013C5
    ),
    (
      SourceCodePoint: $0000AB96;
      TargetCodePoint: $000013C6
    ),
    (
      SourceCodePoint: $0000AB97;
      TargetCodePoint: $000013C7
    ),
    (
      SourceCodePoint: $0000AB98;
      TargetCodePoint: $000013C8
    ),
    (
      SourceCodePoint: $0000AB99;
      TargetCodePoint: $000013C9
    ),
    (
      SourceCodePoint: $0000AB9A;
      TargetCodePoint: $000013CA
    ),
    (
      SourceCodePoint: $0000AB9B;
      TargetCodePoint: $000013CB
    ),
    (
      SourceCodePoint: $0000AB9C;
      TargetCodePoint: $000013CC
    ),
    (
      SourceCodePoint: $0000AB9D;
      TargetCodePoint: $000013CD
    ),
    (
      SourceCodePoint: $0000AB9E;
      TargetCodePoint: $000013CE
    ),
    (
      SourceCodePoint: $0000AB9F;
      TargetCodePoint: $000013CF
    ),
    (
      SourceCodePoint: $0000ABA0;
      TargetCodePoint: $000013D0
    ),
    (
      SourceCodePoint: $0000ABA1;
      TargetCodePoint: $000013D1
    ),
    (
      SourceCodePoint: $0000ABA2;
      TargetCodePoint: $000013D2
    ),
    (
      SourceCodePoint: $0000ABA3;
      TargetCodePoint: $000013D3
    ),
    (
      SourceCodePoint: $0000ABA4;
      TargetCodePoint: $000013D4
    ),
    (
      SourceCodePoint: $0000ABA5;
      TargetCodePoint: $000013D5
    ),
    (
      SourceCodePoint: $0000ABA6;
      TargetCodePoint: $000013D6
    ),
    (
      SourceCodePoint: $0000ABA7;
      TargetCodePoint: $000013D7
    ),
    (
      SourceCodePoint: $0000ABA8;
      TargetCodePoint: $000013D8
    ),
    (
      SourceCodePoint: $0000ABA9;
      TargetCodePoint: $000013D9
    ),
    (
      SourceCodePoint: $0000ABAA;
      TargetCodePoint: $000013DA
    ),
    (
      SourceCodePoint: $0000ABAB;
      TargetCodePoint: $000013DB
    ),
    (
      SourceCodePoint: $0000ABAC;
      TargetCodePoint: $000013DC
    ),
    (
      SourceCodePoint: $0000ABAD;
      TargetCodePoint: $000013DD
    ),
    (
      SourceCodePoint: $0000ABAE;
      TargetCodePoint: $000013DE
    ),
    (
      SourceCodePoint: $0000ABAF;
      TargetCodePoint: $000013DF
    ),
    (
      SourceCodePoint: $0000ABB0;
      TargetCodePoint: $000013E0
    ),
    (
      SourceCodePoint: $0000ABB1;
      TargetCodePoint: $000013E1
    ),
    (
      SourceCodePoint: $0000ABB2;
      TargetCodePoint: $000013E2
    ),
    (
      SourceCodePoint: $0000ABB3;
      TargetCodePoint: $000013E3
    ),
    (
      SourceCodePoint: $0000ABB4;
      TargetCodePoint: $000013E4
    ),
    (
      SourceCodePoint: $0000ABB5;
      TargetCodePoint: $000013E5
    ),
    (
      SourceCodePoint: $0000ABB6;
      TargetCodePoint: $000013E6
    ),
    (
      SourceCodePoint: $0000ABB7;
      TargetCodePoint: $000013E7
    ),
    (
      SourceCodePoint: $0000ABB8;
      TargetCodePoint: $000013E8
    ),
    (
      SourceCodePoint: $0000ABB9;
      TargetCodePoint: $000013E9
    ),
    (
      SourceCodePoint: $0000ABBA;
      TargetCodePoint: $000013EA
    ),
    (
      SourceCodePoint: $0000ABBB;
      TargetCodePoint: $000013EB
    ),
    (
      SourceCodePoint: $0000ABBC;
      TargetCodePoint: $000013EC
    ),
    (
      SourceCodePoint: $0000ABBD;
      TargetCodePoint: $000013ED
    ),
    (
      SourceCodePoint: $0000ABBE;
      TargetCodePoint: $000013EE
    ),
    (
      SourceCodePoint: $0000ABBF;
      TargetCodePoint: $000013EF
    ),
    (
      SourceCodePoint: $0000FF41;
      TargetCodePoint: $0000FF21
    ),
    (
      SourceCodePoint: $0000FF42;
      TargetCodePoint: $0000FF22
    ),
    (
      SourceCodePoint: $0000FF43;
      TargetCodePoint: $0000FF23
    ),
    (
      SourceCodePoint: $0000FF44;
      TargetCodePoint: $0000FF24
    ),
    (
      SourceCodePoint: $0000FF45;
      TargetCodePoint: $0000FF25
    ),
    (
      SourceCodePoint: $0000FF46;
      TargetCodePoint: $0000FF26
    ),
    (
      SourceCodePoint: $0000FF47;
      TargetCodePoint: $0000FF27
    ),
    (
      SourceCodePoint: $0000FF48;
      TargetCodePoint: $0000FF28
    ),
    (
      SourceCodePoint: $0000FF49;
      TargetCodePoint: $0000FF29
    ),
    (
      SourceCodePoint: $0000FF4A;
      TargetCodePoint: $0000FF2A
    ),
    (
      SourceCodePoint: $0000FF4B;
      TargetCodePoint: $0000FF2B
    ),
    (
      SourceCodePoint: $0000FF4C;
      TargetCodePoint: $0000FF2C
    ),
    (
      SourceCodePoint: $0000FF4D;
      TargetCodePoint: $0000FF2D
    ),
    (
      SourceCodePoint: $0000FF4E;
      TargetCodePoint: $0000FF2E
    ),
    (
      SourceCodePoint: $0000FF4F;
      TargetCodePoint: $0000FF2F
    ),
    (
      SourceCodePoint: $0000FF50;
      TargetCodePoint: $0000FF30
    ),
    (
      SourceCodePoint: $0000FF51;
      TargetCodePoint: $0000FF31
    ),
    (
      SourceCodePoint: $0000FF52;
      TargetCodePoint: $0000FF32
    ),
    (
      SourceCodePoint: $0000FF53;
      TargetCodePoint: $0000FF33
    ),
    (
      SourceCodePoint: $0000FF54;
      TargetCodePoint: $0000FF34
    ),
    (
      SourceCodePoint: $0000FF55;
      TargetCodePoint: $0000FF35
    ),
    (
      SourceCodePoint: $0000FF56;
      TargetCodePoint: $0000FF36
    ),
    (
      SourceCodePoint: $0000FF57;
      TargetCodePoint: $0000FF37
    ),
    (
      SourceCodePoint: $0000FF58;
      TargetCodePoint: $0000FF38
    ),
    (
      SourceCodePoint: $0000FF59;
      TargetCodePoint: $0000FF39
    ),
    (
      SourceCodePoint: $0000FF5A;
      TargetCodePoint: $0000FF3A
    ),
    (
      SourceCodePoint: $00010428;
      TargetCodePoint: $00010400
    ),
    (
      SourceCodePoint: $00010429;
      TargetCodePoint: $00010401
    ),
    (
      SourceCodePoint: $0001042A;
      TargetCodePoint: $00010402
    ),
    (
      SourceCodePoint: $0001042B;
      TargetCodePoint: $00010403
    ),
    (
      SourceCodePoint: $0001042C;
      TargetCodePoint: $00010404
    ),
    (
      SourceCodePoint: $0001042D;
      TargetCodePoint: $00010405
    ),
    (
      SourceCodePoint: $0001042E;
      TargetCodePoint: $00010406
    ),
    (
      SourceCodePoint: $0001042F;
      TargetCodePoint: $00010407
    ),
    (
      SourceCodePoint: $00010430;
      TargetCodePoint: $00010408
    ),
    (
      SourceCodePoint: $00010431;
      TargetCodePoint: $00010409
    ),
    (
      SourceCodePoint: $00010432;
      TargetCodePoint: $0001040A
    ),
    (
      SourceCodePoint: $00010433;
      TargetCodePoint: $0001040B
    ),
    (
      SourceCodePoint: $00010434;
      TargetCodePoint: $0001040C
    ),
    (
      SourceCodePoint: $00010435;
      TargetCodePoint: $0001040D
    ),
    (
      SourceCodePoint: $00010436;
      TargetCodePoint: $0001040E
    ),
    (
      SourceCodePoint: $00010437;
      TargetCodePoint: $0001040F
    ),
    (
      SourceCodePoint: $00010438;
      TargetCodePoint: $00010410
    ),
    (
      SourceCodePoint: $00010439;
      TargetCodePoint: $00010411
    ),
    (
      SourceCodePoint: $0001043A;
      TargetCodePoint: $00010412
    ),
    (
      SourceCodePoint: $0001043B;
      TargetCodePoint: $00010413
    ),
    (
      SourceCodePoint: $0001043C;
      TargetCodePoint: $00010414
    ),
    (
      SourceCodePoint: $0001043D;
      TargetCodePoint: $00010415
    ),
    (
      SourceCodePoint: $0001043E;
      TargetCodePoint: $00010416
    ),
    (
      SourceCodePoint: $0001043F;
      TargetCodePoint: $00010417
    ),
    (
      SourceCodePoint: $00010440;
      TargetCodePoint: $00010418
    ),
    (
      SourceCodePoint: $00010441;
      TargetCodePoint: $00010419
    ),
    (
      SourceCodePoint: $00010442;
      TargetCodePoint: $0001041A
    ),
    (
      SourceCodePoint: $00010443;
      TargetCodePoint: $0001041B
    ),
    (
      SourceCodePoint: $00010444;
      TargetCodePoint: $0001041C
    ),
    (
      SourceCodePoint: $00010445;
      TargetCodePoint: $0001041D
    ),
    (
      SourceCodePoint: $00010446;
      TargetCodePoint: $0001041E
    ),
    (
      SourceCodePoint: $00010447;
      TargetCodePoint: $0001041F
    ),
    (
      SourceCodePoint: $00010448;
      TargetCodePoint: $00010420
    ),
    (
      SourceCodePoint: $00010449;
      TargetCodePoint: $00010421
    ),
    (
      SourceCodePoint: $0001044A;
      TargetCodePoint: $00010422
    ),
    (
      SourceCodePoint: $0001044B;
      TargetCodePoint: $00010423
    ),
    (
      SourceCodePoint: $0001044C;
      TargetCodePoint: $00010424
    ),
    (
      SourceCodePoint: $0001044D;
      TargetCodePoint: $00010425
    ),
    (
      SourceCodePoint: $0001044E;
      TargetCodePoint: $00010426
    ),
    (
      SourceCodePoint: $0001044F;
      TargetCodePoint: $00010427
    ),
    (
      SourceCodePoint: $000104D8;
      TargetCodePoint: $000104B0
    ),
    (
      SourceCodePoint: $000104D9;
      TargetCodePoint: $000104B1
    ),
    (
      SourceCodePoint: $000104DA;
      TargetCodePoint: $000104B2
    ),
    (
      SourceCodePoint: $000104DB;
      TargetCodePoint: $000104B3
    ),
    (
      SourceCodePoint: $000104DC;
      TargetCodePoint: $000104B4
    ),
    (
      SourceCodePoint: $000104DD;
      TargetCodePoint: $000104B5
    ),
    (
      SourceCodePoint: $000104DE;
      TargetCodePoint: $000104B6
    ),
    (
      SourceCodePoint: $000104DF;
      TargetCodePoint: $000104B7
    ),
    (
      SourceCodePoint: $000104E0;
      TargetCodePoint: $000104B8
    ),
    (
      SourceCodePoint: $000104E1;
      TargetCodePoint: $000104B9
    ),
    (
      SourceCodePoint: $000104E2;
      TargetCodePoint: $000104BA
    ),
    (
      SourceCodePoint: $000104E3;
      TargetCodePoint: $000104BB
    ),
    (
      SourceCodePoint: $000104E4;
      TargetCodePoint: $000104BC
    ),
    (
      SourceCodePoint: $000104E5;
      TargetCodePoint: $000104BD
    ),
    (
      SourceCodePoint: $000104E6;
      TargetCodePoint: $000104BE
    ),
    (
      SourceCodePoint: $000104E7;
      TargetCodePoint: $000104BF
    ),
    (
      SourceCodePoint: $000104E8;
      TargetCodePoint: $000104C0
    ),
    (
      SourceCodePoint: $000104E9;
      TargetCodePoint: $000104C1
    ),
    (
      SourceCodePoint: $000104EA;
      TargetCodePoint: $000104C2
    ),
    (
      SourceCodePoint: $000104EB;
      TargetCodePoint: $000104C3
    ),
    (
      SourceCodePoint: $000104EC;
      TargetCodePoint: $000104C4
    ),
    (
      SourceCodePoint: $000104ED;
      TargetCodePoint: $000104C5
    ),
    (
      SourceCodePoint: $000104EE;
      TargetCodePoint: $000104C6
    ),
    (
      SourceCodePoint: $000104EF;
      TargetCodePoint: $000104C7
    ),
    (
      SourceCodePoint: $000104F0;
      TargetCodePoint: $000104C8
    ),
    (
      SourceCodePoint: $000104F1;
      TargetCodePoint: $000104C9
    ),
    (
      SourceCodePoint: $000104F2;
      TargetCodePoint: $000104CA
    ),
    (
      SourceCodePoint: $000104F3;
      TargetCodePoint: $000104CB
    ),
    (
      SourceCodePoint: $000104F4;
      TargetCodePoint: $000104CC
    ),
    (
      SourceCodePoint: $000104F5;
      TargetCodePoint: $000104CD
    ),
    (
      SourceCodePoint: $000104F6;
      TargetCodePoint: $000104CE
    ),
    (
      SourceCodePoint: $000104F7;
      TargetCodePoint: $000104CF
    ),
    (
      SourceCodePoint: $000104F8;
      TargetCodePoint: $000104D0
    ),
    (
      SourceCodePoint: $000104F9;
      TargetCodePoint: $000104D1
    ),
    (
      SourceCodePoint: $000104FA;
      TargetCodePoint: $000104D2
    ),
    (
      SourceCodePoint: $000104FB;
      TargetCodePoint: $000104D3
    ),
    (
      SourceCodePoint: $00010597;
      TargetCodePoint: $00010570
    ),
    (
      SourceCodePoint: $00010598;
      TargetCodePoint: $00010571
    ),
    (
      SourceCodePoint: $00010599;
      TargetCodePoint: $00010572
    ),
    (
      SourceCodePoint: $0001059A;
      TargetCodePoint: $00010573
    ),
    (
      SourceCodePoint: $0001059B;
      TargetCodePoint: $00010574
    ),
    (
      SourceCodePoint: $0001059C;
      TargetCodePoint: $00010575
    ),
    (
      SourceCodePoint: $0001059D;
      TargetCodePoint: $00010576
    ),
    (
      SourceCodePoint: $0001059E;
      TargetCodePoint: $00010577
    ),
    (
      SourceCodePoint: $0001059F;
      TargetCodePoint: $00010578
    ),
    (
      SourceCodePoint: $000105A0;
      TargetCodePoint: $00010579
    ),
    (
      SourceCodePoint: $000105A1;
      TargetCodePoint: $0001057A
    ),
    (
      SourceCodePoint: $000105A3;
      TargetCodePoint: $0001057C
    ),
    (
      SourceCodePoint: $000105A4;
      TargetCodePoint: $0001057D
    ),
    (
      SourceCodePoint: $000105A5;
      TargetCodePoint: $0001057E
    ),
    (
      SourceCodePoint: $000105A6;
      TargetCodePoint: $0001057F
    ),
    (
      SourceCodePoint: $000105A7;
      TargetCodePoint: $00010580
    ),
    (
      SourceCodePoint: $000105A8;
      TargetCodePoint: $00010581
    ),
    (
      SourceCodePoint: $000105A9;
      TargetCodePoint: $00010582
    ),
    (
      SourceCodePoint: $000105AA;
      TargetCodePoint: $00010583
    ),
    (
      SourceCodePoint: $000105AB;
      TargetCodePoint: $00010584
    ),
    (
      SourceCodePoint: $000105AC;
      TargetCodePoint: $00010585
    ),
    (
      SourceCodePoint: $000105AD;
      TargetCodePoint: $00010586
    ),
    (
      SourceCodePoint: $000105AE;
      TargetCodePoint: $00010587
    ),
    (
      SourceCodePoint: $000105AF;
      TargetCodePoint: $00010588
    ),
    (
      SourceCodePoint: $000105B0;
      TargetCodePoint: $00010589
    ),
    (
      SourceCodePoint: $000105B1;
      TargetCodePoint: $0001058A
    ),
    (
      SourceCodePoint: $000105B3;
      TargetCodePoint: $0001058C
    ),
    (
      SourceCodePoint: $000105B4;
      TargetCodePoint: $0001058D
    ),
    (
      SourceCodePoint: $000105B5;
      TargetCodePoint: $0001058E
    ),
    (
      SourceCodePoint: $000105B6;
      TargetCodePoint: $0001058F
    ),
    (
      SourceCodePoint: $000105B7;
      TargetCodePoint: $00010590
    ),
    (
      SourceCodePoint: $000105B8;
      TargetCodePoint: $00010591
    ),
    (
      SourceCodePoint: $000105B9;
      TargetCodePoint: $00010592
    ),
    (
      SourceCodePoint: $000105BB;
      TargetCodePoint: $00010594
    ),
    (
      SourceCodePoint: $000105BC;
      TargetCodePoint: $00010595
    ),
    (
      SourceCodePoint: $00010CC0;
      TargetCodePoint: $00010C80
    ),
    (
      SourceCodePoint: $00010CC1;
      TargetCodePoint: $00010C81
    ),
    (
      SourceCodePoint: $00010CC2;
      TargetCodePoint: $00010C82
    ),
    (
      SourceCodePoint: $00010CC3;
      TargetCodePoint: $00010C83
    ),
    (
      SourceCodePoint: $00010CC4;
      TargetCodePoint: $00010C84
    ),
    (
      SourceCodePoint: $00010CC5;
      TargetCodePoint: $00010C85
    ),
    (
      SourceCodePoint: $00010CC6;
      TargetCodePoint: $00010C86
    ),
    (
      SourceCodePoint: $00010CC7;
      TargetCodePoint: $00010C87
    ),
    (
      SourceCodePoint: $00010CC8;
      TargetCodePoint: $00010C88
    ),
    (
      SourceCodePoint: $00010CC9;
      TargetCodePoint: $00010C89
    ),
    (
      SourceCodePoint: $00010CCA;
      TargetCodePoint: $00010C8A
    ),
    (
      SourceCodePoint: $00010CCB;
      TargetCodePoint: $00010C8B
    ),
    (
      SourceCodePoint: $00010CCC;
      TargetCodePoint: $00010C8C
    ),
    (
      SourceCodePoint: $00010CCD;
      TargetCodePoint: $00010C8D
    ),
    (
      SourceCodePoint: $00010CCE;
      TargetCodePoint: $00010C8E
    ),
    (
      SourceCodePoint: $00010CCF;
      TargetCodePoint: $00010C8F
    ),
    (
      SourceCodePoint: $00010CD0;
      TargetCodePoint: $00010C90
    ),
    (
      SourceCodePoint: $00010CD1;
      TargetCodePoint: $00010C91
    ),
    (
      SourceCodePoint: $00010CD2;
      TargetCodePoint: $00010C92
    ),
    (
      SourceCodePoint: $00010CD3;
      TargetCodePoint: $00010C93
    ),
    (
      SourceCodePoint: $00010CD4;
      TargetCodePoint: $00010C94
    ),
    (
      SourceCodePoint: $00010CD5;
      TargetCodePoint: $00010C95
    ),
    (
      SourceCodePoint: $00010CD6;
      TargetCodePoint: $00010C96
    ),
    (
      SourceCodePoint: $00010CD7;
      TargetCodePoint: $00010C97
    ),
    (
      SourceCodePoint: $00010CD8;
      TargetCodePoint: $00010C98
    ),
    (
      SourceCodePoint: $00010CD9;
      TargetCodePoint: $00010C99
    ),
    (
      SourceCodePoint: $00010CDA;
      TargetCodePoint: $00010C9A
    ),
    (
      SourceCodePoint: $00010CDB;
      TargetCodePoint: $00010C9B
    ),
    (
      SourceCodePoint: $00010CDC;
      TargetCodePoint: $00010C9C
    ),
    (
      SourceCodePoint: $00010CDD;
      TargetCodePoint: $00010C9D
    ),
    (
      SourceCodePoint: $00010CDE;
      TargetCodePoint: $00010C9E
    ),
    (
      SourceCodePoint: $00010CDF;
      TargetCodePoint: $00010C9F
    ),
    (
      SourceCodePoint: $00010CE0;
      TargetCodePoint: $00010CA0
    ),
    (
      SourceCodePoint: $00010CE1;
      TargetCodePoint: $00010CA1
    ),
    (
      SourceCodePoint: $00010CE2;
      TargetCodePoint: $00010CA2
    ),
    (
      SourceCodePoint: $00010CE3;
      TargetCodePoint: $00010CA3
    ),
    (
      SourceCodePoint: $00010CE4;
      TargetCodePoint: $00010CA4
    ),
    (
      SourceCodePoint: $00010CE5;
      TargetCodePoint: $00010CA5
    ),
    (
      SourceCodePoint: $00010CE6;
      TargetCodePoint: $00010CA6
    ),
    (
      SourceCodePoint: $00010CE7;
      TargetCodePoint: $00010CA7
    ),
    (
      SourceCodePoint: $00010CE8;
      TargetCodePoint: $00010CA8
    ),
    (
      SourceCodePoint: $00010CE9;
      TargetCodePoint: $00010CA9
    ),
    (
      SourceCodePoint: $00010CEA;
      TargetCodePoint: $00010CAA
    ),
    (
      SourceCodePoint: $00010CEB;
      TargetCodePoint: $00010CAB
    ),
    (
      SourceCodePoint: $00010CEC;
      TargetCodePoint: $00010CAC
    ),
    (
      SourceCodePoint: $00010CED;
      TargetCodePoint: $00010CAD
    ),
    (
      SourceCodePoint: $00010CEE;
      TargetCodePoint: $00010CAE
    ),
    (
      SourceCodePoint: $00010CEF;
      TargetCodePoint: $00010CAF
    ),
    (
      SourceCodePoint: $00010CF0;
      TargetCodePoint: $00010CB0
    ),
    (
      SourceCodePoint: $00010CF1;
      TargetCodePoint: $00010CB1
    ),
    (
      SourceCodePoint: $00010CF2;
      TargetCodePoint: $00010CB2
    ),
    (
      SourceCodePoint: $000118C0;
      TargetCodePoint: $000118A0
    ),
    (
      SourceCodePoint: $000118C1;
      TargetCodePoint: $000118A1
    ),
    (
      SourceCodePoint: $000118C2;
      TargetCodePoint: $000118A2
    ),
    (
      SourceCodePoint: $000118C3;
      TargetCodePoint: $000118A3
    ),
    (
      SourceCodePoint: $000118C4;
      TargetCodePoint: $000118A4
    ),
    (
      SourceCodePoint: $000118C5;
      TargetCodePoint: $000118A5
    ),
    (
      SourceCodePoint: $000118C6;
      TargetCodePoint: $000118A6
    ),
    (
      SourceCodePoint: $000118C7;
      TargetCodePoint: $000118A7
    ),
    (
      SourceCodePoint: $000118C8;
      TargetCodePoint: $000118A8
    ),
    (
      SourceCodePoint: $000118C9;
      TargetCodePoint: $000118A9
    ),
    (
      SourceCodePoint: $000118CA;
      TargetCodePoint: $000118AA
    ),
    (
      SourceCodePoint: $000118CB;
      TargetCodePoint: $000118AB
    ),
    (
      SourceCodePoint: $000118CC;
      TargetCodePoint: $000118AC
    ),
    (
      SourceCodePoint: $000118CD;
      TargetCodePoint: $000118AD
    ),
    (
      SourceCodePoint: $000118CE;
      TargetCodePoint: $000118AE
    ),
    (
      SourceCodePoint: $000118CF;
      TargetCodePoint: $000118AF
    ),
    (
      SourceCodePoint: $000118D0;
      TargetCodePoint: $000118B0
    ),
    (
      SourceCodePoint: $000118D1;
      TargetCodePoint: $000118B1
    ),
    (
      SourceCodePoint: $000118D2;
      TargetCodePoint: $000118B2
    ),
    (
      SourceCodePoint: $000118D3;
      TargetCodePoint: $000118B3
    ),
    (
      SourceCodePoint: $000118D4;
      TargetCodePoint: $000118B4
    ),
    (
      SourceCodePoint: $000118D5;
      TargetCodePoint: $000118B5
    ),
    (
      SourceCodePoint: $000118D6;
      TargetCodePoint: $000118B6
    ),
    (
      SourceCodePoint: $000118D7;
      TargetCodePoint: $000118B7
    ),
    (
      SourceCodePoint: $000118D8;
      TargetCodePoint: $000118B8
    ),
    (
      SourceCodePoint: $000118D9;
      TargetCodePoint: $000118B9
    ),
    (
      SourceCodePoint: $000118DA;
      TargetCodePoint: $000118BA
    ),
    (
      SourceCodePoint: $000118DB;
      TargetCodePoint: $000118BB
    ),
    (
      SourceCodePoint: $000118DC;
      TargetCodePoint: $000118BC
    ),
    (
      SourceCodePoint: $000118DD;
      TargetCodePoint: $000118BD
    ),
    (
      SourceCodePoint: $000118DE;
      TargetCodePoint: $000118BE
    ),
    (
      SourceCodePoint: $000118DF;
      TargetCodePoint: $000118BF
    ),
    (
      SourceCodePoint: $00016E60;
      TargetCodePoint: $00016E40
    ),
    (
      SourceCodePoint: $00016E61;
      TargetCodePoint: $00016E41
    ),
    (
      SourceCodePoint: $00016E62;
      TargetCodePoint: $00016E42
    ),
    (
      SourceCodePoint: $00016E63;
      TargetCodePoint: $00016E43
    ),
    (
      SourceCodePoint: $00016E64;
      TargetCodePoint: $00016E44
    ),
    (
      SourceCodePoint: $00016E65;
      TargetCodePoint: $00016E45
    ),
    (
      SourceCodePoint: $00016E66;
      TargetCodePoint: $00016E46
    ),
    (
      SourceCodePoint: $00016E67;
      TargetCodePoint: $00016E47
    ),
    (
      SourceCodePoint: $00016E68;
      TargetCodePoint: $00016E48
    ),
    (
      SourceCodePoint: $00016E69;
      TargetCodePoint: $00016E49
    ),
    (
      SourceCodePoint: $00016E6A;
      TargetCodePoint: $00016E4A
    ),
    (
      SourceCodePoint: $00016E6B;
      TargetCodePoint: $00016E4B
    ),
    (
      SourceCodePoint: $00016E6C;
      TargetCodePoint: $00016E4C
    ),
    (
      SourceCodePoint: $00016E6D;
      TargetCodePoint: $00016E4D
    ),
    (
      SourceCodePoint: $00016E6E;
      TargetCodePoint: $00016E4E
    ),
    (
      SourceCodePoint: $00016E6F;
      TargetCodePoint: $00016E4F
    ),
    (
      SourceCodePoint: $00016E70;
      TargetCodePoint: $00016E50
    ),
    (
      SourceCodePoint: $00016E71;
      TargetCodePoint: $00016E51
    ),
    (
      SourceCodePoint: $00016E72;
      TargetCodePoint: $00016E52
    ),
    (
      SourceCodePoint: $00016E73;
      TargetCodePoint: $00016E53
    ),
    (
      SourceCodePoint: $00016E74;
      TargetCodePoint: $00016E54
    ),
    (
      SourceCodePoint: $00016E75;
      TargetCodePoint: $00016E55
    ),
    (
      SourceCodePoint: $00016E76;
      TargetCodePoint: $00016E56
    ),
    (
      SourceCodePoint: $00016E77;
      TargetCodePoint: $00016E57
    ),
    (
      SourceCodePoint: $00016E78;
      TargetCodePoint: $00016E58
    ),
    (
      SourceCodePoint: $00016E79;
      TargetCodePoint: $00016E59
    ),
    (
      SourceCodePoint: $00016E7A;
      TargetCodePoint: $00016E5A
    ),
    (
      SourceCodePoint: $00016E7B;
      TargetCodePoint: $00016E5B
    ),
    (
      SourceCodePoint: $00016E7C;
      TargetCodePoint: $00016E5C
    ),
    (
      SourceCodePoint: $00016E7D;
      TargetCodePoint: $00016E5D
    ),
    (
      SourceCodePoint: $00016E7E;
      TargetCodePoint: $00016E5E
    ),
    (
      SourceCodePoint: $00016E7F;
      TargetCodePoint: $00016E5F
    ),
    (
      SourceCodePoint: $0001E922;
      TargetCodePoint: $0001E900
    ),
    (
      SourceCodePoint: $0001E923;
      TargetCodePoint: $0001E901
    ),
    (
      SourceCodePoint: $0001E924;
      TargetCodePoint: $0001E902
    ),
    (
      SourceCodePoint: $0001E925;
      TargetCodePoint: $0001E903
    ),
    (
      SourceCodePoint: $0001E926;
      TargetCodePoint: $0001E904
    ),
    (
      SourceCodePoint: $0001E927;
      TargetCodePoint: $0001E905
    ),
    (
      SourceCodePoint: $0001E928;
      TargetCodePoint: $0001E906
    ),
    (
      SourceCodePoint: $0001E929;
      TargetCodePoint: $0001E907
    ),
    (
      SourceCodePoint: $0001E92A;
      TargetCodePoint: $0001E908
    ),
    (
      SourceCodePoint: $0001E92B;
      TargetCodePoint: $0001E909
    ),
    (
      SourceCodePoint: $0001E92C;
      TargetCodePoint: $0001E90A
    ),
    (
      SourceCodePoint: $0001E92D;
      TargetCodePoint: $0001E90B
    ),
    (
      SourceCodePoint: $0001E92E;
      TargetCodePoint: $0001E90C
    ),
    (
      SourceCodePoint: $0001E92F;
      TargetCodePoint: $0001E90D
    ),
    (
      SourceCodePoint: $0001E930;
      TargetCodePoint: $0001E90E
    ),
    (
      SourceCodePoint: $0001E931;
      TargetCodePoint: $0001E90F
    ),
    (
      SourceCodePoint: $0001E932;
      TargetCodePoint: $0001E910
    ),
    (
      SourceCodePoint: $0001E933;
      TargetCodePoint: $0001E911
    ),
    (
      SourceCodePoint: $0001E934;
      TargetCodePoint: $0001E912
    ),
    (
      SourceCodePoint: $0001E935;
      TargetCodePoint: $0001E913
    ),
    (
      SourceCodePoint: $0001E936;
      TargetCodePoint: $0001E914
    ),
    (
      SourceCodePoint: $0001E937;
      TargetCodePoint: $0001E915
    ),
    (
      SourceCodePoint: $0001E938;
      TargetCodePoint: $0001E916
    ),
    (
      SourceCodePoint: $0001E939;
      TargetCodePoint: $0001E917
    ),
    (
      SourceCodePoint: $0001E93A;
      TargetCodePoint: $0001E918
    ),
    (
      SourceCodePoint: $0001E93B;
      TargetCodePoint: $0001E919
    ),
    (
      SourceCodePoint: $0001E93C;
      TargetCodePoint: $0001E91A
    ),
    (
      SourceCodePoint: $0001E93D;
      TargetCodePoint: $0001E91B
    ),
    (
      SourceCodePoint: $0001E93E;
      TargetCodePoint: $0001E91C
    ),
    (
      SourceCodePoint: $0001E93F;
      TargetCodePoint: $0001E91D
    ),
    (
      SourceCodePoint: $0001E940;
      TargetCodePoint: $0001E91E
    ),
    (
      SourceCodePoint: $0001E941;
      TargetCodePoint: $0001E91F
    ),
    (
      SourceCodePoint: $0001E942;
      TargetCodePoint: $0001E920
    ),
    (
      SourceCodePoint: $0001E943;
      TargetCodePoint: $0001E921
    )
  );

  UNICODE_SIMPLE_FOLD_MAP: array[0..1425] of TUnicodeMapping = (
    (
      SourceCodePoint: $00000041;
      TargetCodePoint: $00000061
    ),
    (
      SourceCodePoint: $00000042;
      TargetCodePoint: $00000062
    ),
    (
      SourceCodePoint: $00000043;
      TargetCodePoint: $00000063
    ),
    (
      SourceCodePoint: $00000044;
      TargetCodePoint: $00000064
    ),
    (
      SourceCodePoint: $00000045;
      TargetCodePoint: $00000065
    ),
    (
      SourceCodePoint: $00000046;
      TargetCodePoint: $00000066
    ),
    (
      SourceCodePoint: $00000047;
      TargetCodePoint: $00000067
    ),
    (
      SourceCodePoint: $00000048;
      TargetCodePoint: $00000068
    ),
    (
      SourceCodePoint: $00000049;
      TargetCodePoint: $00000069
    ),
    (
      SourceCodePoint: $0000004A;
      TargetCodePoint: $0000006A
    ),
    (
      SourceCodePoint: $0000004B;
      TargetCodePoint: $0000006B
    ),
    (
      SourceCodePoint: $0000004C;
      TargetCodePoint: $0000006C
    ),
    (
      SourceCodePoint: $0000004D;
      TargetCodePoint: $0000006D
    ),
    (
      SourceCodePoint: $0000004E;
      TargetCodePoint: $0000006E
    ),
    (
      SourceCodePoint: $0000004F;
      TargetCodePoint: $0000006F
    ),
    (
      SourceCodePoint: $00000050;
      TargetCodePoint: $00000070
    ),
    (
      SourceCodePoint: $00000051;
      TargetCodePoint: $00000071
    ),
    (
      SourceCodePoint: $00000052;
      TargetCodePoint: $00000072
    ),
    (
      SourceCodePoint: $00000053;
      TargetCodePoint: $00000073
    ),
    (
      SourceCodePoint: $00000054;
      TargetCodePoint: $00000074
    ),
    (
      SourceCodePoint: $00000055;
      TargetCodePoint: $00000075
    ),
    (
      SourceCodePoint: $00000056;
      TargetCodePoint: $00000076
    ),
    (
      SourceCodePoint: $00000057;
      TargetCodePoint: $00000077
    ),
    (
      SourceCodePoint: $00000058;
      TargetCodePoint: $00000078
    ),
    (
      SourceCodePoint: $00000059;
      TargetCodePoint: $00000079
    ),
    (
      SourceCodePoint: $0000005A;
      TargetCodePoint: $0000007A
    ),
    (
      SourceCodePoint: $000000B5;
      TargetCodePoint: $000003BC
    ),
    (
      SourceCodePoint: $000000C0;
      TargetCodePoint: $000000E0
    ),
    (
      SourceCodePoint: $000000C1;
      TargetCodePoint: $000000E1
    ),
    (
      SourceCodePoint: $000000C2;
      TargetCodePoint: $000000E2
    ),
    (
      SourceCodePoint: $000000C3;
      TargetCodePoint: $000000E3
    ),
    (
      SourceCodePoint: $000000C4;
      TargetCodePoint: $000000E4
    ),
    (
      SourceCodePoint: $000000C5;
      TargetCodePoint: $000000E5
    ),
    (
      SourceCodePoint: $000000C6;
      TargetCodePoint: $000000E6
    ),
    (
      SourceCodePoint: $000000C7;
      TargetCodePoint: $000000E7
    ),
    (
      SourceCodePoint: $000000C8;
      TargetCodePoint: $000000E8
    ),
    (
      SourceCodePoint: $000000C9;
      TargetCodePoint: $000000E9
    ),
    (
      SourceCodePoint: $000000CA;
      TargetCodePoint: $000000EA
    ),
    (
      SourceCodePoint: $000000CB;
      TargetCodePoint: $000000EB
    ),
    (
      SourceCodePoint: $000000CC;
      TargetCodePoint: $000000EC
    ),
    (
      SourceCodePoint: $000000CD;
      TargetCodePoint: $000000ED
    ),
    (
      SourceCodePoint: $000000CE;
      TargetCodePoint: $000000EE
    ),
    (
      SourceCodePoint: $000000CF;
      TargetCodePoint: $000000EF
    ),
    (
      SourceCodePoint: $000000D0;
      TargetCodePoint: $000000F0
    ),
    (
      SourceCodePoint: $000000D1;
      TargetCodePoint: $000000F1
    ),
    (
      SourceCodePoint: $000000D2;
      TargetCodePoint: $000000F2
    ),
    (
      SourceCodePoint: $000000D3;
      TargetCodePoint: $000000F3
    ),
    (
      SourceCodePoint: $000000D4;
      TargetCodePoint: $000000F4
    ),
    (
      SourceCodePoint: $000000D5;
      TargetCodePoint: $000000F5
    ),
    (
      SourceCodePoint: $000000D6;
      TargetCodePoint: $000000F6
    ),
    (
      SourceCodePoint: $000000D8;
      TargetCodePoint: $000000F8
    ),
    (
      SourceCodePoint: $000000D9;
      TargetCodePoint: $000000F9
    ),
    (
      SourceCodePoint: $000000DA;
      TargetCodePoint: $000000FA
    ),
    (
      SourceCodePoint: $000000DB;
      TargetCodePoint: $000000FB
    ),
    (
      SourceCodePoint: $000000DC;
      TargetCodePoint: $000000FC
    ),
    (
      SourceCodePoint: $000000DD;
      TargetCodePoint: $000000FD
    ),
    (
      SourceCodePoint: $000000DE;
      TargetCodePoint: $000000FE
    ),
    (
      SourceCodePoint: $00000100;
      TargetCodePoint: $00000101
    ),
    (
      SourceCodePoint: $00000102;
      TargetCodePoint: $00000103
    ),
    (
      SourceCodePoint: $00000104;
      TargetCodePoint: $00000105
    ),
    (
      SourceCodePoint: $00000106;
      TargetCodePoint: $00000107
    ),
    (
      SourceCodePoint: $00000108;
      TargetCodePoint: $00000109
    ),
    (
      SourceCodePoint: $0000010A;
      TargetCodePoint: $0000010B
    ),
    (
      SourceCodePoint: $0000010C;
      TargetCodePoint: $0000010D
    ),
    (
      SourceCodePoint: $0000010E;
      TargetCodePoint: $0000010F
    ),
    (
      SourceCodePoint: $00000110;
      TargetCodePoint: $00000111
    ),
    (
      SourceCodePoint: $00000112;
      TargetCodePoint: $00000113
    ),
    (
      SourceCodePoint: $00000114;
      TargetCodePoint: $00000115
    ),
    (
      SourceCodePoint: $00000116;
      TargetCodePoint: $00000117
    ),
    (
      SourceCodePoint: $00000118;
      TargetCodePoint: $00000119
    ),
    (
      SourceCodePoint: $0000011A;
      TargetCodePoint: $0000011B
    ),
    (
      SourceCodePoint: $0000011C;
      TargetCodePoint: $0000011D
    ),
    (
      SourceCodePoint: $0000011E;
      TargetCodePoint: $0000011F
    ),
    (
      SourceCodePoint: $00000120;
      TargetCodePoint: $00000121
    ),
    (
      SourceCodePoint: $00000122;
      TargetCodePoint: $00000123
    ),
    (
      SourceCodePoint: $00000124;
      TargetCodePoint: $00000125
    ),
    (
      SourceCodePoint: $00000126;
      TargetCodePoint: $00000127
    ),
    (
      SourceCodePoint: $00000128;
      TargetCodePoint: $00000129
    ),
    (
      SourceCodePoint: $0000012A;
      TargetCodePoint: $0000012B
    ),
    (
      SourceCodePoint: $0000012C;
      TargetCodePoint: $0000012D
    ),
    (
      SourceCodePoint: $0000012E;
      TargetCodePoint: $0000012F
    ),
    (
      SourceCodePoint: $00000132;
      TargetCodePoint: $00000133
    ),
    (
      SourceCodePoint: $00000134;
      TargetCodePoint: $00000135
    ),
    (
      SourceCodePoint: $00000136;
      TargetCodePoint: $00000137
    ),
    (
      SourceCodePoint: $00000139;
      TargetCodePoint: $0000013A
    ),
    (
      SourceCodePoint: $0000013B;
      TargetCodePoint: $0000013C
    ),
    (
      SourceCodePoint: $0000013D;
      TargetCodePoint: $0000013E
    ),
    (
      SourceCodePoint: $0000013F;
      TargetCodePoint: $00000140
    ),
    (
      SourceCodePoint: $00000141;
      TargetCodePoint: $00000142
    ),
    (
      SourceCodePoint: $00000143;
      TargetCodePoint: $00000144
    ),
    (
      SourceCodePoint: $00000145;
      TargetCodePoint: $00000146
    ),
    (
      SourceCodePoint: $00000147;
      TargetCodePoint: $00000148
    ),
    (
      SourceCodePoint: $0000014A;
      TargetCodePoint: $0000014B
    ),
    (
      SourceCodePoint: $0000014C;
      TargetCodePoint: $0000014D
    ),
    (
      SourceCodePoint: $0000014E;
      TargetCodePoint: $0000014F
    ),
    (
      SourceCodePoint: $00000150;
      TargetCodePoint: $00000151
    ),
    (
      SourceCodePoint: $00000152;
      TargetCodePoint: $00000153
    ),
    (
      SourceCodePoint: $00000154;
      TargetCodePoint: $00000155
    ),
    (
      SourceCodePoint: $00000156;
      TargetCodePoint: $00000157
    ),
    (
      SourceCodePoint: $00000158;
      TargetCodePoint: $00000159
    ),
    (
      SourceCodePoint: $0000015A;
      TargetCodePoint: $0000015B
    ),
    (
      SourceCodePoint: $0000015C;
      TargetCodePoint: $0000015D
    ),
    (
      SourceCodePoint: $0000015E;
      TargetCodePoint: $0000015F
    ),
    (
      SourceCodePoint: $00000160;
      TargetCodePoint: $00000161
    ),
    (
      SourceCodePoint: $00000162;
      TargetCodePoint: $00000163
    ),
    (
      SourceCodePoint: $00000164;
      TargetCodePoint: $00000165
    ),
    (
      SourceCodePoint: $00000166;
      TargetCodePoint: $00000167
    ),
    (
      SourceCodePoint: $00000168;
      TargetCodePoint: $00000169
    ),
    (
      SourceCodePoint: $0000016A;
      TargetCodePoint: $0000016B
    ),
    (
      SourceCodePoint: $0000016C;
      TargetCodePoint: $0000016D
    ),
    (
      SourceCodePoint: $0000016E;
      TargetCodePoint: $0000016F
    ),
    (
      SourceCodePoint: $00000170;
      TargetCodePoint: $00000171
    ),
    (
      SourceCodePoint: $00000172;
      TargetCodePoint: $00000173
    ),
    (
      SourceCodePoint: $00000174;
      TargetCodePoint: $00000175
    ),
    (
      SourceCodePoint: $00000176;
      TargetCodePoint: $00000177
    ),
    (
      SourceCodePoint: $00000178;
      TargetCodePoint: $000000FF
    ),
    (
      SourceCodePoint: $00000179;
      TargetCodePoint: $0000017A
    ),
    (
      SourceCodePoint: $0000017B;
      TargetCodePoint: $0000017C
    ),
    (
      SourceCodePoint: $0000017D;
      TargetCodePoint: $0000017E
    ),
    (
      SourceCodePoint: $0000017F;
      TargetCodePoint: $00000073
    ),
    (
      SourceCodePoint: $00000181;
      TargetCodePoint: $00000253
    ),
    (
      SourceCodePoint: $00000182;
      TargetCodePoint: $00000183
    ),
    (
      SourceCodePoint: $00000184;
      TargetCodePoint: $00000185
    ),
    (
      SourceCodePoint: $00000186;
      TargetCodePoint: $00000254
    ),
    (
      SourceCodePoint: $00000187;
      TargetCodePoint: $00000188
    ),
    (
      SourceCodePoint: $00000189;
      TargetCodePoint: $00000256
    ),
    (
      SourceCodePoint: $0000018A;
      TargetCodePoint: $00000257
    ),
    (
      SourceCodePoint: $0000018B;
      TargetCodePoint: $0000018C
    ),
    (
      SourceCodePoint: $0000018E;
      TargetCodePoint: $000001DD
    ),
    (
      SourceCodePoint: $0000018F;
      TargetCodePoint: $00000259
    ),
    (
      SourceCodePoint: $00000190;
      TargetCodePoint: $0000025B
    ),
    (
      SourceCodePoint: $00000191;
      TargetCodePoint: $00000192
    ),
    (
      SourceCodePoint: $00000193;
      TargetCodePoint: $00000260
    ),
    (
      SourceCodePoint: $00000194;
      TargetCodePoint: $00000263
    ),
    (
      SourceCodePoint: $00000196;
      TargetCodePoint: $00000269
    ),
    (
      SourceCodePoint: $00000197;
      TargetCodePoint: $00000268
    ),
    (
      SourceCodePoint: $00000198;
      TargetCodePoint: $00000199
    ),
    (
      SourceCodePoint: $0000019C;
      TargetCodePoint: $0000026F
    ),
    (
      SourceCodePoint: $0000019D;
      TargetCodePoint: $00000272
    ),
    (
      SourceCodePoint: $0000019F;
      TargetCodePoint: $00000275
    ),
    (
      SourceCodePoint: $000001A0;
      TargetCodePoint: $000001A1
    ),
    (
      SourceCodePoint: $000001A2;
      TargetCodePoint: $000001A3
    ),
    (
      SourceCodePoint: $000001A4;
      TargetCodePoint: $000001A5
    ),
    (
      SourceCodePoint: $000001A6;
      TargetCodePoint: $00000280
    ),
    (
      SourceCodePoint: $000001A7;
      TargetCodePoint: $000001A8
    ),
    (
      SourceCodePoint: $000001A9;
      TargetCodePoint: $00000283
    ),
    (
      SourceCodePoint: $000001AC;
      TargetCodePoint: $000001AD
    ),
    (
      SourceCodePoint: $000001AE;
      TargetCodePoint: $00000288
    ),
    (
      SourceCodePoint: $000001AF;
      TargetCodePoint: $000001B0
    ),
    (
      SourceCodePoint: $000001B1;
      TargetCodePoint: $0000028A
    ),
    (
      SourceCodePoint: $000001B2;
      TargetCodePoint: $0000028B
    ),
    (
      SourceCodePoint: $000001B3;
      TargetCodePoint: $000001B4
    ),
    (
      SourceCodePoint: $000001B5;
      TargetCodePoint: $000001B6
    ),
    (
      SourceCodePoint: $000001B7;
      TargetCodePoint: $00000292
    ),
    (
      SourceCodePoint: $000001B8;
      TargetCodePoint: $000001B9
    ),
    (
      SourceCodePoint: $000001BC;
      TargetCodePoint: $000001BD
    ),
    (
      SourceCodePoint: $000001C4;
      TargetCodePoint: $000001C6
    ),
    (
      SourceCodePoint: $000001C5;
      TargetCodePoint: $000001C6
    ),
    (
      SourceCodePoint: $000001C7;
      TargetCodePoint: $000001C9
    ),
    (
      SourceCodePoint: $000001C8;
      TargetCodePoint: $000001C9
    ),
    (
      SourceCodePoint: $000001CA;
      TargetCodePoint: $000001CC
    ),
    (
      SourceCodePoint: $000001CB;
      TargetCodePoint: $000001CC
    ),
    (
      SourceCodePoint: $000001CD;
      TargetCodePoint: $000001CE
    ),
    (
      SourceCodePoint: $000001CF;
      TargetCodePoint: $000001D0
    ),
    (
      SourceCodePoint: $000001D1;
      TargetCodePoint: $000001D2
    ),
    (
      SourceCodePoint: $000001D3;
      TargetCodePoint: $000001D4
    ),
    (
      SourceCodePoint: $000001D5;
      TargetCodePoint: $000001D6
    ),
    (
      SourceCodePoint: $000001D7;
      TargetCodePoint: $000001D8
    ),
    (
      SourceCodePoint: $000001D9;
      TargetCodePoint: $000001DA
    ),
    (
      SourceCodePoint: $000001DB;
      TargetCodePoint: $000001DC
    ),
    (
      SourceCodePoint: $000001DE;
      TargetCodePoint: $000001DF
    ),
    (
      SourceCodePoint: $000001E0;
      TargetCodePoint: $000001E1
    ),
    (
      SourceCodePoint: $000001E2;
      TargetCodePoint: $000001E3
    ),
    (
      SourceCodePoint: $000001E4;
      TargetCodePoint: $000001E5
    ),
    (
      SourceCodePoint: $000001E6;
      TargetCodePoint: $000001E7
    ),
    (
      SourceCodePoint: $000001E8;
      TargetCodePoint: $000001E9
    ),
    (
      SourceCodePoint: $000001EA;
      TargetCodePoint: $000001EB
    ),
    (
      SourceCodePoint: $000001EC;
      TargetCodePoint: $000001ED
    ),
    (
      SourceCodePoint: $000001EE;
      TargetCodePoint: $000001EF
    ),
    (
      SourceCodePoint: $000001F1;
      TargetCodePoint: $000001F3
    ),
    (
      SourceCodePoint: $000001F2;
      TargetCodePoint: $000001F3
    ),
    (
      SourceCodePoint: $000001F4;
      TargetCodePoint: $000001F5
    ),
    (
      SourceCodePoint: $000001F6;
      TargetCodePoint: $00000195
    ),
    (
      SourceCodePoint: $000001F7;
      TargetCodePoint: $000001BF
    ),
    (
      SourceCodePoint: $000001F8;
      TargetCodePoint: $000001F9
    ),
    (
      SourceCodePoint: $000001FA;
      TargetCodePoint: $000001FB
    ),
    (
      SourceCodePoint: $000001FC;
      TargetCodePoint: $000001FD
    ),
    (
      SourceCodePoint: $000001FE;
      TargetCodePoint: $000001FF
    ),
    (
      SourceCodePoint: $00000200;
      TargetCodePoint: $00000201
    ),
    (
      SourceCodePoint: $00000202;
      TargetCodePoint: $00000203
    ),
    (
      SourceCodePoint: $00000204;
      TargetCodePoint: $00000205
    ),
    (
      SourceCodePoint: $00000206;
      TargetCodePoint: $00000207
    ),
    (
      SourceCodePoint: $00000208;
      TargetCodePoint: $00000209
    ),
    (
      SourceCodePoint: $0000020A;
      TargetCodePoint: $0000020B
    ),
    (
      SourceCodePoint: $0000020C;
      TargetCodePoint: $0000020D
    ),
    (
      SourceCodePoint: $0000020E;
      TargetCodePoint: $0000020F
    ),
    (
      SourceCodePoint: $00000210;
      TargetCodePoint: $00000211
    ),
    (
      SourceCodePoint: $00000212;
      TargetCodePoint: $00000213
    ),
    (
      SourceCodePoint: $00000214;
      TargetCodePoint: $00000215
    ),
    (
      SourceCodePoint: $00000216;
      TargetCodePoint: $00000217
    ),
    (
      SourceCodePoint: $00000218;
      TargetCodePoint: $00000219
    ),
    (
      SourceCodePoint: $0000021A;
      TargetCodePoint: $0000021B
    ),
    (
      SourceCodePoint: $0000021C;
      TargetCodePoint: $0000021D
    ),
    (
      SourceCodePoint: $0000021E;
      TargetCodePoint: $0000021F
    ),
    (
      SourceCodePoint: $00000220;
      TargetCodePoint: $0000019E
    ),
    (
      SourceCodePoint: $00000222;
      TargetCodePoint: $00000223
    ),
    (
      SourceCodePoint: $00000224;
      TargetCodePoint: $00000225
    ),
    (
      SourceCodePoint: $00000226;
      TargetCodePoint: $00000227
    ),
    (
      SourceCodePoint: $00000228;
      TargetCodePoint: $00000229
    ),
    (
      SourceCodePoint: $0000022A;
      TargetCodePoint: $0000022B
    ),
    (
      SourceCodePoint: $0000022C;
      TargetCodePoint: $0000022D
    ),
    (
      SourceCodePoint: $0000022E;
      TargetCodePoint: $0000022F
    ),
    (
      SourceCodePoint: $00000230;
      TargetCodePoint: $00000231
    ),
    (
      SourceCodePoint: $00000232;
      TargetCodePoint: $00000233
    ),
    (
      SourceCodePoint: $0000023A;
      TargetCodePoint: $00002C65
    ),
    (
      SourceCodePoint: $0000023B;
      TargetCodePoint: $0000023C
    ),
    (
      SourceCodePoint: $0000023D;
      TargetCodePoint: $0000019A
    ),
    (
      SourceCodePoint: $0000023E;
      TargetCodePoint: $00002C66
    ),
    (
      SourceCodePoint: $00000241;
      TargetCodePoint: $00000242
    ),
    (
      SourceCodePoint: $00000243;
      TargetCodePoint: $00000180
    ),
    (
      SourceCodePoint: $00000244;
      TargetCodePoint: $00000289
    ),
    (
      SourceCodePoint: $00000245;
      TargetCodePoint: $0000028C
    ),
    (
      SourceCodePoint: $00000246;
      TargetCodePoint: $00000247
    ),
    (
      SourceCodePoint: $00000248;
      TargetCodePoint: $00000249
    ),
    (
      SourceCodePoint: $0000024A;
      TargetCodePoint: $0000024B
    ),
    (
      SourceCodePoint: $0000024C;
      TargetCodePoint: $0000024D
    ),
    (
      SourceCodePoint: $0000024E;
      TargetCodePoint: $0000024F
    ),
    (
      SourceCodePoint: $00000345;
      TargetCodePoint: $000003B9
    ),
    (
      SourceCodePoint: $00000370;
      TargetCodePoint: $00000371
    ),
    (
      SourceCodePoint: $00000372;
      TargetCodePoint: $00000373
    ),
    (
      SourceCodePoint: $00000376;
      TargetCodePoint: $00000377
    ),
    (
      SourceCodePoint: $0000037F;
      TargetCodePoint: $000003F3
    ),
    (
      SourceCodePoint: $00000386;
      TargetCodePoint: $000003AC
    ),
    (
      SourceCodePoint: $00000388;
      TargetCodePoint: $000003AD
    ),
    (
      SourceCodePoint: $00000389;
      TargetCodePoint: $000003AE
    ),
    (
      SourceCodePoint: $0000038A;
      TargetCodePoint: $000003AF
    ),
    (
      SourceCodePoint: $0000038C;
      TargetCodePoint: $000003CC
    ),
    (
      SourceCodePoint: $0000038E;
      TargetCodePoint: $000003CD
    ),
    (
      SourceCodePoint: $0000038F;
      TargetCodePoint: $000003CE
    ),
    (
      SourceCodePoint: $00000391;
      TargetCodePoint: $000003B1
    ),
    (
      SourceCodePoint: $00000392;
      TargetCodePoint: $000003B2
    ),
    (
      SourceCodePoint: $00000393;
      TargetCodePoint: $000003B3
    ),
    (
      SourceCodePoint: $00000394;
      TargetCodePoint: $000003B4
    ),
    (
      SourceCodePoint: $00000395;
      TargetCodePoint: $000003B5
    ),
    (
      SourceCodePoint: $00000396;
      TargetCodePoint: $000003B6
    ),
    (
      SourceCodePoint: $00000397;
      TargetCodePoint: $000003B7
    ),
    (
      SourceCodePoint: $00000398;
      TargetCodePoint: $000003B8
    ),
    (
      SourceCodePoint: $00000399;
      TargetCodePoint: $000003B9
    ),
    (
      SourceCodePoint: $0000039A;
      TargetCodePoint: $000003BA
    ),
    (
      SourceCodePoint: $0000039B;
      TargetCodePoint: $000003BB
    ),
    (
      SourceCodePoint: $0000039C;
      TargetCodePoint: $000003BC
    ),
    (
      SourceCodePoint: $0000039D;
      TargetCodePoint: $000003BD
    ),
    (
      SourceCodePoint: $0000039E;
      TargetCodePoint: $000003BE
    ),
    (
      SourceCodePoint: $0000039F;
      TargetCodePoint: $000003BF
    ),
    (
      SourceCodePoint: $000003A0;
      TargetCodePoint: $000003C0
    ),
    (
      SourceCodePoint: $000003A1;
      TargetCodePoint: $000003C1
    ),
    (
      SourceCodePoint: $000003A3;
      TargetCodePoint: $000003C3
    ),
    (
      SourceCodePoint: $000003A4;
      TargetCodePoint: $000003C4
    ),
    (
      SourceCodePoint: $000003A5;
      TargetCodePoint: $000003C5
    ),
    (
      SourceCodePoint: $000003A6;
      TargetCodePoint: $000003C6
    ),
    (
      SourceCodePoint: $000003A7;
      TargetCodePoint: $000003C7
    ),
    (
      SourceCodePoint: $000003A8;
      TargetCodePoint: $000003C8
    ),
    (
      SourceCodePoint: $000003A9;
      TargetCodePoint: $000003C9
    ),
    (
      SourceCodePoint: $000003AA;
      TargetCodePoint: $000003CA
    ),
    (
      SourceCodePoint: $000003AB;
      TargetCodePoint: $000003CB
    ),
    (
      SourceCodePoint: $000003C2;
      TargetCodePoint: $000003C3
    ),
    (
      SourceCodePoint: $000003CF;
      TargetCodePoint: $000003D7
    ),
    (
      SourceCodePoint: $000003D0;
      TargetCodePoint: $000003B2
    ),
    (
      SourceCodePoint: $000003D1;
      TargetCodePoint: $000003B8
    ),
    (
      SourceCodePoint: $000003D5;
      TargetCodePoint: $000003C6
    ),
    (
      SourceCodePoint: $000003D6;
      TargetCodePoint: $000003C0
    ),
    (
      SourceCodePoint: $000003D8;
      TargetCodePoint: $000003D9
    ),
    (
      SourceCodePoint: $000003DA;
      TargetCodePoint: $000003DB
    ),
    (
      SourceCodePoint: $000003DC;
      TargetCodePoint: $000003DD
    ),
    (
      SourceCodePoint: $000003DE;
      TargetCodePoint: $000003DF
    ),
    (
      SourceCodePoint: $000003E0;
      TargetCodePoint: $000003E1
    ),
    (
      SourceCodePoint: $000003E2;
      TargetCodePoint: $000003E3
    ),
    (
      SourceCodePoint: $000003E4;
      TargetCodePoint: $000003E5
    ),
    (
      SourceCodePoint: $000003E6;
      TargetCodePoint: $000003E7
    ),
    (
      SourceCodePoint: $000003E8;
      TargetCodePoint: $000003E9
    ),
    (
      SourceCodePoint: $000003EA;
      TargetCodePoint: $000003EB
    ),
    (
      SourceCodePoint: $000003EC;
      TargetCodePoint: $000003ED
    ),
    (
      SourceCodePoint: $000003EE;
      TargetCodePoint: $000003EF
    ),
    (
      SourceCodePoint: $000003F0;
      TargetCodePoint: $000003BA
    ),
    (
      SourceCodePoint: $000003F1;
      TargetCodePoint: $000003C1
    ),
    (
      SourceCodePoint: $000003F4;
      TargetCodePoint: $000003B8
    ),
    (
      SourceCodePoint: $000003F5;
      TargetCodePoint: $000003B5
    ),
    (
      SourceCodePoint: $000003F7;
      TargetCodePoint: $000003F8
    ),
    (
      SourceCodePoint: $000003F9;
      TargetCodePoint: $000003F2
    ),
    (
      SourceCodePoint: $000003FA;
      TargetCodePoint: $000003FB
    ),
    (
      SourceCodePoint: $000003FD;
      TargetCodePoint: $0000037B
    ),
    (
      SourceCodePoint: $000003FE;
      TargetCodePoint: $0000037C
    ),
    (
      SourceCodePoint: $000003FF;
      TargetCodePoint: $0000037D
    ),
    (
      SourceCodePoint: $00000400;
      TargetCodePoint: $00000450
    ),
    (
      SourceCodePoint: $00000401;
      TargetCodePoint: $00000451
    ),
    (
      SourceCodePoint: $00000402;
      TargetCodePoint: $00000452
    ),
    (
      SourceCodePoint: $00000403;
      TargetCodePoint: $00000453
    ),
    (
      SourceCodePoint: $00000404;
      TargetCodePoint: $00000454
    ),
    (
      SourceCodePoint: $00000405;
      TargetCodePoint: $00000455
    ),
    (
      SourceCodePoint: $00000406;
      TargetCodePoint: $00000456
    ),
    (
      SourceCodePoint: $00000407;
      TargetCodePoint: $00000457
    ),
    (
      SourceCodePoint: $00000408;
      TargetCodePoint: $00000458
    ),
    (
      SourceCodePoint: $00000409;
      TargetCodePoint: $00000459
    ),
    (
      SourceCodePoint: $0000040A;
      TargetCodePoint: $0000045A
    ),
    (
      SourceCodePoint: $0000040B;
      TargetCodePoint: $0000045B
    ),
    (
      SourceCodePoint: $0000040C;
      TargetCodePoint: $0000045C
    ),
    (
      SourceCodePoint: $0000040D;
      TargetCodePoint: $0000045D
    ),
    (
      SourceCodePoint: $0000040E;
      TargetCodePoint: $0000045E
    ),
    (
      SourceCodePoint: $0000040F;
      TargetCodePoint: $0000045F
    ),
    (
      SourceCodePoint: $00000410;
      TargetCodePoint: $00000430
    ),
    (
      SourceCodePoint: $00000411;
      TargetCodePoint: $00000431
    ),
    (
      SourceCodePoint: $00000412;
      TargetCodePoint: $00000432
    ),
    (
      SourceCodePoint: $00000413;
      TargetCodePoint: $00000433
    ),
    (
      SourceCodePoint: $00000414;
      TargetCodePoint: $00000434
    ),
    (
      SourceCodePoint: $00000415;
      TargetCodePoint: $00000435
    ),
    (
      SourceCodePoint: $00000416;
      TargetCodePoint: $00000436
    ),
    (
      SourceCodePoint: $00000417;
      TargetCodePoint: $00000437
    ),
    (
      SourceCodePoint: $00000418;
      TargetCodePoint: $00000438
    ),
    (
      SourceCodePoint: $00000419;
      TargetCodePoint: $00000439
    ),
    (
      SourceCodePoint: $0000041A;
      TargetCodePoint: $0000043A
    ),
    (
      SourceCodePoint: $0000041B;
      TargetCodePoint: $0000043B
    ),
    (
      SourceCodePoint: $0000041C;
      TargetCodePoint: $0000043C
    ),
    (
      SourceCodePoint: $0000041D;
      TargetCodePoint: $0000043D
    ),
    (
      SourceCodePoint: $0000041E;
      TargetCodePoint: $0000043E
    ),
    (
      SourceCodePoint: $0000041F;
      TargetCodePoint: $0000043F
    ),
    (
      SourceCodePoint: $00000420;
      TargetCodePoint: $00000440
    ),
    (
      SourceCodePoint: $00000421;
      TargetCodePoint: $00000441
    ),
    (
      SourceCodePoint: $00000422;
      TargetCodePoint: $00000442
    ),
    (
      SourceCodePoint: $00000423;
      TargetCodePoint: $00000443
    ),
    (
      SourceCodePoint: $00000424;
      TargetCodePoint: $00000444
    ),
    (
      SourceCodePoint: $00000425;
      TargetCodePoint: $00000445
    ),
    (
      SourceCodePoint: $00000426;
      TargetCodePoint: $00000446
    ),
    (
      SourceCodePoint: $00000427;
      TargetCodePoint: $00000447
    ),
    (
      SourceCodePoint: $00000428;
      TargetCodePoint: $00000448
    ),
    (
      SourceCodePoint: $00000429;
      TargetCodePoint: $00000449
    ),
    (
      SourceCodePoint: $0000042A;
      TargetCodePoint: $0000044A
    ),
    (
      SourceCodePoint: $0000042B;
      TargetCodePoint: $0000044B
    ),
    (
      SourceCodePoint: $0000042C;
      TargetCodePoint: $0000044C
    ),
    (
      SourceCodePoint: $0000042D;
      TargetCodePoint: $0000044D
    ),
    (
      SourceCodePoint: $0000042E;
      TargetCodePoint: $0000044E
    ),
    (
      SourceCodePoint: $0000042F;
      TargetCodePoint: $0000044F
    ),
    (
      SourceCodePoint: $00000460;
      TargetCodePoint: $00000461
    ),
    (
      SourceCodePoint: $00000462;
      TargetCodePoint: $00000463
    ),
    (
      SourceCodePoint: $00000464;
      TargetCodePoint: $00000465
    ),
    (
      SourceCodePoint: $00000466;
      TargetCodePoint: $00000467
    ),
    (
      SourceCodePoint: $00000468;
      TargetCodePoint: $00000469
    ),
    (
      SourceCodePoint: $0000046A;
      TargetCodePoint: $0000046B
    ),
    (
      SourceCodePoint: $0000046C;
      TargetCodePoint: $0000046D
    ),
    (
      SourceCodePoint: $0000046E;
      TargetCodePoint: $0000046F
    ),
    (
      SourceCodePoint: $00000470;
      TargetCodePoint: $00000471
    ),
    (
      SourceCodePoint: $00000472;
      TargetCodePoint: $00000473
    ),
    (
      SourceCodePoint: $00000474;
      TargetCodePoint: $00000475
    ),
    (
      SourceCodePoint: $00000476;
      TargetCodePoint: $00000477
    ),
    (
      SourceCodePoint: $00000478;
      TargetCodePoint: $00000479
    ),
    (
      SourceCodePoint: $0000047A;
      TargetCodePoint: $0000047B
    ),
    (
      SourceCodePoint: $0000047C;
      TargetCodePoint: $0000047D
    ),
    (
      SourceCodePoint: $0000047E;
      TargetCodePoint: $0000047F
    ),
    (
      SourceCodePoint: $00000480;
      TargetCodePoint: $00000481
    ),
    (
      SourceCodePoint: $0000048A;
      TargetCodePoint: $0000048B
    ),
    (
      SourceCodePoint: $0000048C;
      TargetCodePoint: $0000048D
    ),
    (
      SourceCodePoint: $0000048E;
      TargetCodePoint: $0000048F
    ),
    (
      SourceCodePoint: $00000490;
      TargetCodePoint: $00000491
    ),
    (
      SourceCodePoint: $00000492;
      TargetCodePoint: $00000493
    ),
    (
      SourceCodePoint: $00000494;
      TargetCodePoint: $00000495
    ),
    (
      SourceCodePoint: $00000496;
      TargetCodePoint: $00000497
    ),
    (
      SourceCodePoint: $00000498;
      TargetCodePoint: $00000499
    ),
    (
      SourceCodePoint: $0000049A;
      TargetCodePoint: $0000049B
    ),
    (
      SourceCodePoint: $0000049C;
      TargetCodePoint: $0000049D
    ),
    (
      SourceCodePoint: $0000049E;
      TargetCodePoint: $0000049F
    ),
    (
      SourceCodePoint: $000004A0;
      TargetCodePoint: $000004A1
    ),
    (
      SourceCodePoint: $000004A2;
      TargetCodePoint: $000004A3
    ),
    (
      SourceCodePoint: $000004A4;
      TargetCodePoint: $000004A5
    ),
    (
      SourceCodePoint: $000004A6;
      TargetCodePoint: $000004A7
    ),
    (
      SourceCodePoint: $000004A8;
      TargetCodePoint: $000004A9
    ),
    (
      SourceCodePoint: $000004AA;
      TargetCodePoint: $000004AB
    ),
    (
      SourceCodePoint: $000004AC;
      TargetCodePoint: $000004AD
    ),
    (
      SourceCodePoint: $000004AE;
      TargetCodePoint: $000004AF
    ),
    (
      SourceCodePoint: $000004B0;
      TargetCodePoint: $000004B1
    ),
    (
      SourceCodePoint: $000004B2;
      TargetCodePoint: $000004B3
    ),
    (
      SourceCodePoint: $000004B4;
      TargetCodePoint: $000004B5
    ),
    (
      SourceCodePoint: $000004B6;
      TargetCodePoint: $000004B7
    ),
    (
      SourceCodePoint: $000004B8;
      TargetCodePoint: $000004B9
    ),
    (
      SourceCodePoint: $000004BA;
      TargetCodePoint: $000004BB
    ),
    (
      SourceCodePoint: $000004BC;
      TargetCodePoint: $000004BD
    ),
    (
      SourceCodePoint: $000004BE;
      TargetCodePoint: $000004BF
    ),
    (
      SourceCodePoint: $000004C0;
      TargetCodePoint: $000004CF
    ),
    (
      SourceCodePoint: $000004C1;
      TargetCodePoint: $000004C2
    ),
    (
      SourceCodePoint: $000004C3;
      TargetCodePoint: $000004C4
    ),
    (
      SourceCodePoint: $000004C5;
      TargetCodePoint: $000004C6
    ),
    (
      SourceCodePoint: $000004C7;
      TargetCodePoint: $000004C8
    ),
    (
      SourceCodePoint: $000004C9;
      TargetCodePoint: $000004CA
    ),
    (
      SourceCodePoint: $000004CB;
      TargetCodePoint: $000004CC
    ),
    (
      SourceCodePoint: $000004CD;
      TargetCodePoint: $000004CE
    ),
    (
      SourceCodePoint: $000004D0;
      TargetCodePoint: $000004D1
    ),
    (
      SourceCodePoint: $000004D2;
      TargetCodePoint: $000004D3
    ),
    (
      SourceCodePoint: $000004D4;
      TargetCodePoint: $000004D5
    ),
    (
      SourceCodePoint: $000004D6;
      TargetCodePoint: $000004D7
    ),
    (
      SourceCodePoint: $000004D8;
      TargetCodePoint: $000004D9
    ),
    (
      SourceCodePoint: $000004DA;
      TargetCodePoint: $000004DB
    ),
    (
      SourceCodePoint: $000004DC;
      TargetCodePoint: $000004DD
    ),
    (
      SourceCodePoint: $000004DE;
      TargetCodePoint: $000004DF
    ),
    (
      SourceCodePoint: $000004E0;
      TargetCodePoint: $000004E1
    ),
    (
      SourceCodePoint: $000004E2;
      TargetCodePoint: $000004E3
    ),
    (
      SourceCodePoint: $000004E4;
      TargetCodePoint: $000004E5
    ),
    (
      SourceCodePoint: $000004E6;
      TargetCodePoint: $000004E7
    ),
    (
      SourceCodePoint: $000004E8;
      TargetCodePoint: $000004E9
    ),
    (
      SourceCodePoint: $000004EA;
      TargetCodePoint: $000004EB
    ),
    (
      SourceCodePoint: $000004EC;
      TargetCodePoint: $000004ED
    ),
    (
      SourceCodePoint: $000004EE;
      TargetCodePoint: $000004EF
    ),
    (
      SourceCodePoint: $000004F0;
      TargetCodePoint: $000004F1
    ),
    (
      SourceCodePoint: $000004F2;
      TargetCodePoint: $000004F3
    ),
    (
      SourceCodePoint: $000004F4;
      TargetCodePoint: $000004F5
    ),
    (
      SourceCodePoint: $000004F6;
      TargetCodePoint: $000004F7
    ),
    (
      SourceCodePoint: $000004F8;
      TargetCodePoint: $000004F9
    ),
    (
      SourceCodePoint: $000004FA;
      TargetCodePoint: $000004FB
    ),
    (
      SourceCodePoint: $000004FC;
      TargetCodePoint: $000004FD
    ),
    (
      SourceCodePoint: $000004FE;
      TargetCodePoint: $000004FF
    ),
    (
      SourceCodePoint: $00000500;
      TargetCodePoint: $00000501
    ),
    (
      SourceCodePoint: $00000502;
      TargetCodePoint: $00000503
    ),
    (
      SourceCodePoint: $00000504;
      TargetCodePoint: $00000505
    ),
    (
      SourceCodePoint: $00000506;
      TargetCodePoint: $00000507
    ),
    (
      SourceCodePoint: $00000508;
      TargetCodePoint: $00000509
    ),
    (
      SourceCodePoint: $0000050A;
      TargetCodePoint: $0000050B
    ),
    (
      SourceCodePoint: $0000050C;
      TargetCodePoint: $0000050D
    ),
    (
      SourceCodePoint: $0000050E;
      TargetCodePoint: $0000050F
    ),
    (
      SourceCodePoint: $00000510;
      TargetCodePoint: $00000511
    ),
    (
      SourceCodePoint: $00000512;
      TargetCodePoint: $00000513
    ),
    (
      SourceCodePoint: $00000514;
      TargetCodePoint: $00000515
    ),
    (
      SourceCodePoint: $00000516;
      TargetCodePoint: $00000517
    ),
    (
      SourceCodePoint: $00000518;
      TargetCodePoint: $00000519
    ),
    (
      SourceCodePoint: $0000051A;
      TargetCodePoint: $0000051B
    ),
    (
      SourceCodePoint: $0000051C;
      TargetCodePoint: $0000051D
    ),
    (
      SourceCodePoint: $0000051E;
      TargetCodePoint: $0000051F
    ),
    (
      SourceCodePoint: $00000520;
      TargetCodePoint: $00000521
    ),
    (
      SourceCodePoint: $00000522;
      TargetCodePoint: $00000523
    ),
    (
      SourceCodePoint: $00000524;
      TargetCodePoint: $00000525
    ),
    (
      SourceCodePoint: $00000526;
      TargetCodePoint: $00000527
    ),
    (
      SourceCodePoint: $00000528;
      TargetCodePoint: $00000529
    ),
    (
      SourceCodePoint: $0000052A;
      TargetCodePoint: $0000052B
    ),
    (
      SourceCodePoint: $0000052C;
      TargetCodePoint: $0000052D
    ),
    (
      SourceCodePoint: $0000052E;
      TargetCodePoint: $0000052F
    ),
    (
      SourceCodePoint: $00000531;
      TargetCodePoint: $00000561
    ),
    (
      SourceCodePoint: $00000532;
      TargetCodePoint: $00000562
    ),
    (
      SourceCodePoint: $00000533;
      TargetCodePoint: $00000563
    ),
    (
      SourceCodePoint: $00000534;
      TargetCodePoint: $00000564
    ),
    (
      SourceCodePoint: $00000535;
      TargetCodePoint: $00000565
    ),
    (
      SourceCodePoint: $00000536;
      TargetCodePoint: $00000566
    ),
    (
      SourceCodePoint: $00000537;
      TargetCodePoint: $00000567
    ),
    (
      SourceCodePoint: $00000538;
      TargetCodePoint: $00000568
    ),
    (
      SourceCodePoint: $00000539;
      TargetCodePoint: $00000569
    ),
    (
      SourceCodePoint: $0000053A;
      TargetCodePoint: $0000056A
    ),
    (
      SourceCodePoint: $0000053B;
      TargetCodePoint: $0000056B
    ),
    (
      SourceCodePoint: $0000053C;
      TargetCodePoint: $0000056C
    ),
    (
      SourceCodePoint: $0000053D;
      TargetCodePoint: $0000056D
    ),
    (
      SourceCodePoint: $0000053E;
      TargetCodePoint: $0000056E
    ),
    (
      SourceCodePoint: $0000053F;
      TargetCodePoint: $0000056F
    ),
    (
      SourceCodePoint: $00000540;
      TargetCodePoint: $00000570
    ),
    (
      SourceCodePoint: $00000541;
      TargetCodePoint: $00000571
    ),
    (
      SourceCodePoint: $00000542;
      TargetCodePoint: $00000572
    ),
    (
      SourceCodePoint: $00000543;
      TargetCodePoint: $00000573
    ),
    (
      SourceCodePoint: $00000544;
      TargetCodePoint: $00000574
    ),
    (
      SourceCodePoint: $00000545;
      TargetCodePoint: $00000575
    ),
    (
      SourceCodePoint: $00000546;
      TargetCodePoint: $00000576
    ),
    (
      SourceCodePoint: $00000547;
      TargetCodePoint: $00000577
    ),
    (
      SourceCodePoint: $00000548;
      TargetCodePoint: $00000578
    ),
    (
      SourceCodePoint: $00000549;
      TargetCodePoint: $00000579
    ),
    (
      SourceCodePoint: $0000054A;
      TargetCodePoint: $0000057A
    ),
    (
      SourceCodePoint: $0000054B;
      TargetCodePoint: $0000057B
    ),
    (
      SourceCodePoint: $0000054C;
      TargetCodePoint: $0000057C
    ),
    (
      SourceCodePoint: $0000054D;
      TargetCodePoint: $0000057D
    ),
    (
      SourceCodePoint: $0000054E;
      TargetCodePoint: $0000057E
    ),
    (
      SourceCodePoint: $0000054F;
      TargetCodePoint: $0000057F
    ),
    (
      SourceCodePoint: $00000550;
      TargetCodePoint: $00000580
    ),
    (
      SourceCodePoint: $00000551;
      TargetCodePoint: $00000581
    ),
    (
      SourceCodePoint: $00000552;
      TargetCodePoint: $00000582
    ),
    (
      SourceCodePoint: $00000553;
      TargetCodePoint: $00000583
    ),
    (
      SourceCodePoint: $00000554;
      TargetCodePoint: $00000584
    ),
    (
      SourceCodePoint: $00000555;
      TargetCodePoint: $00000585
    ),
    (
      SourceCodePoint: $00000556;
      TargetCodePoint: $00000586
    ),
    (
      SourceCodePoint: $000010A0;
      TargetCodePoint: $00002D00
    ),
    (
      SourceCodePoint: $000010A1;
      TargetCodePoint: $00002D01
    ),
    (
      SourceCodePoint: $000010A2;
      TargetCodePoint: $00002D02
    ),
    (
      SourceCodePoint: $000010A3;
      TargetCodePoint: $00002D03
    ),
    (
      SourceCodePoint: $000010A4;
      TargetCodePoint: $00002D04
    ),
    (
      SourceCodePoint: $000010A5;
      TargetCodePoint: $00002D05
    ),
    (
      SourceCodePoint: $000010A6;
      TargetCodePoint: $00002D06
    ),
    (
      SourceCodePoint: $000010A7;
      TargetCodePoint: $00002D07
    ),
    (
      SourceCodePoint: $000010A8;
      TargetCodePoint: $00002D08
    ),
    (
      SourceCodePoint: $000010A9;
      TargetCodePoint: $00002D09
    ),
    (
      SourceCodePoint: $000010AA;
      TargetCodePoint: $00002D0A
    ),
    (
      SourceCodePoint: $000010AB;
      TargetCodePoint: $00002D0B
    ),
    (
      SourceCodePoint: $000010AC;
      TargetCodePoint: $00002D0C
    ),
    (
      SourceCodePoint: $000010AD;
      TargetCodePoint: $00002D0D
    ),
    (
      SourceCodePoint: $000010AE;
      TargetCodePoint: $00002D0E
    ),
    (
      SourceCodePoint: $000010AF;
      TargetCodePoint: $00002D0F
    ),
    (
      SourceCodePoint: $000010B0;
      TargetCodePoint: $00002D10
    ),
    (
      SourceCodePoint: $000010B1;
      TargetCodePoint: $00002D11
    ),
    (
      SourceCodePoint: $000010B2;
      TargetCodePoint: $00002D12
    ),
    (
      SourceCodePoint: $000010B3;
      TargetCodePoint: $00002D13
    ),
    (
      SourceCodePoint: $000010B4;
      TargetCodePoint: $00002D14
    ),
    (
      SourceCodePoint: $000010B5;
      TargetCodePoint: $00002D15
    ),
    (
      SourceCodePoint: $000010B6;
      TargetCodePoint: $00002D16
    ),
    (
      SourceCodePoint: $000010B7;
      TargetCodePoint: $00002D17
    ),
    (
      SourceCodePoint: $000010B8;
      TargetCodePoint: $00002D18
    ),
    (
      SourceCodePoint: $000010B9;
      TargetCodePoint: $00002D19
    ),
    (
      SourceCodePoint: $000010BA;
      TargetCodePoint: $00002D1A
    ),
    (
      SourceCodePoint: $000010BB;
      TargetCodePoint: $00002D1B
    ),
    (
      SourceCodePoint: $000010BC;
      TargetCodePoint: $00002D1C
    ),
    (
      SourceCodePoint: $000010BD;
      TargetCodePoint: $00002D1D
    ),
    (
      SourceCodePoint: $000010BE;
      TargetCodePoint: $00002D1E
    ),
    (
      SourceCodePoint: $000010BF;
      TargetCodePoint: $00002D1F
    ),
    (
      SourceCodePoint: $000010C0;
      TargetCodePoint: $00002D20
    ),
    (
      SourceCodePoint: $000010C1;
      TargetCodePoint: $00002D21
    ),
    (
      SourceCodePoint: $000010C2;
      TargetCodePoint: $00002D22
    ),
    (
      SourceCodePoint: $000010C3;
      TargetCodePoint: $00002D23
    ),
    (
      SourceCodePoint: $000010C4;
      TargetCodePoint: $00002D24
    ),
    (
      SourceCodePoint: $000010C5;
      TargetCodePoint: $00002D25
    ),
    (
      SourceCodePoint: $000010C7;
      TargetCodePoint: $00002D27
    ),
    (
      SourceCodePoint: $000010CD;
      TargetCodePoint: $00002D2D
    ),
    (
      SourceCodePoint: $000013F8;
      TargetCodePoint: $000013F0
    ),
    (
      SourceCodePoint: $000013F9;
      TargetCodePoint: $000013F1
    ),
    (
      SourceCodePoint: $000013FA;
      TargetCodePoint: $000013F2
    ),
    (
      SourceCodePoint: $000013FB;
      TargetCodePoint: $000013F3
    ),
    (
      SourceCodePoint: $000013FC;
      TargetCodePoint: $000013F4
    ),
    (
      SourceCodePoint: $000013FD;
      TargetCodePoint: $000013F5
    ),
    (
      SourceCodePoint: $00001C80;
      TargetCodePoint: $00000432
    ),
    (
      SourceCodePoint: $00001C81;
      TargetCodePoint: $00000434
    ),
    (
      SourceCodePoint: $00001C82;
      TargetCodePoint: $0000043E
    ),
    (
      SourceCodePoint: $00001C83;
      TargetCodePoint: $00000441
    ),
    (
      SourceCodePoint: $00001C84;
      TargetCodePoint: $00000442
    ),
    (
      SourceCodePoint: $00001C85;
      TargetCodePoint: $00000442
    ),
    (
      SourceCodePoint: $00001C86;
      TargetCodePoint: $0000044A
    ),
    (
      SourceCodePoint: $00001C87;
      TargetCodePoint: $00000463
    ),
    (
      SourceCodePoint: $00001C88;
      TargetCodePoint: $0000A64B
    ),
    (
      SourceCodePoint: $00001C90;
      TargetCodePoint: $000010D0
    ),
    (
      SourceCodePoint: $00001C91;
      TargetCodePoint: $000010D1
    ),
    (
      SourceCodePoint: $00001C92;
      TargetCodePoint: $000010D2
    ),
    (
      SourceCodePoint: $00001C93;
      TargetCodePoint: $000010D3
    ),
    (
      SourceCodePoint: $00001C94;
      TargetCodePoint: $000010D4
    ),
    (
      SourceCodePoint: $00001C95;
      TargetCodePoint: $000010D5
    ),
    (
      SourceCodePoint: $00001C96;
      TargetCodePoint: $000010D6
    ),
    (
      SourceCodePoint: $00001C97;
      TargetCodePoint: $000010D7
    ),
    (
      SourceCodePoint: $00001C98;
      TargetCodePoint: $000010D8
    ),
    (
      SourceCodePoint: $00001C99;
      TargetCodePoint: $000010D9
    ),
    (
      SourceCodePoint: $00001C9A;
      TargetCodePoint: $000010DA
    ),
    (
      SourceCodePoint: $00001C9B;
      TargetCodePoint: $000010DB
    ),
    (
      SourceCodePoint: $00001C9C;
      TargetCodePoint: $000010DC
    ),
    (
      SourceCodePoint: $00001C9D;
      TargetCodePoint: $000010DD
    ),
    (
      SourceCodePoint: $00001C9E;
      TargetCodePoint: $000010DE
    ),
    (
      SourceCodePoint: $00001C9F;
      TargetCodePoint: $000010DF
    ),
    (
      SourceCodePoint: $00001CA0;
      TargetCodePoint: $000010E0
    ),
    (
      SourceCodePoint: $00001CA1;
      TargetCodePoint: $000010E1
    ),
    (
      SourceCodePoint: $00001CA2;
      TargetCodePoint: $000010E2
    ),
    (
      SourceCodePoint: $00001CA3;
      TargetCodePoint: $000010E3
    ),
    (
      SourceCodePoint: $00001CA4;
      TargetCodePoint: $000010E4
    ),
    (
      SourceCodePoint: $00001CA5;
      TargetCodePoint: $000010E5
    ),
    (
      SourceCodePoint: $00001CA6;
      TargetCodePoint: $000010E6
    ),
    (
      SourceCodePoint: $00001CA7;
      TargetCodePoint: $000010E7
    ),
    (
      SourceCodePoint: $00001CA8;
      TargetCodePoint: $000010E8
    ),
    (
      SourceCodePoint: $00001CA9;
      TargetCodePoint: $000010E9
    ),
    (
      SourceCodePoint: $00001CAA;
      TargetCodePoint: $000010EA
    ),
    (
      SourceCodePoint: $00001CAB;
      TargetCodePoint: $000010EB
    ),
    (
      SourceCodePoint: $00001CAC;
      TargetCodePoint: $000010EC
    ),
    (
      SourceCodePoint: $00001CAD;
      TargetCodePoint: $000010ED
    ),
    (
      SourceCodePoint: $00001CAE;
      TargetCodePoint: $000010EE
    ),
    (
      SourceCodePoint: $00001CAF;
      TargetCodePoint: $000010EF
    ),
    (
      SourceCodePoint: $00001CB0;
      TargetCodePoint: $000010F0
    ),
    (
      SourceCodePoint: $00001CB1;
      TargetCodePoint: $000010F1
    ),
    (
      SourceCodePoint: $00001CB2;
      TargetCodePoint: $000010F2
    ),
    (
      SourceCodePoint: $00001CB3;
      TargetCodePoint: $000010F3
    ),
    (
      SourceCodePoint: $00001CB4;
      TargetCodePoint: $000010F4
    ),
    (
      SourceCodePoint: $00001CB5;
      TargetCodePoint: $000010F5
    ),
    (
      SourceCodePoint: $00001CB6;
      TargetCodePoint: $000010F6
    ),
    (
      SourceCodePoint: $00001CB7;
      TargetCodePoint: $000010F7
    ),
    (
      SourceCodePoint: $00001CB8;
      TargetCodePoint: $000010F8
    ),
    (
      SourceCodePoint: $00001CB9;
      TargetCodePoint: $000010F9
    ),
    (
      SourceCodePoint: $00001CBA;
      TargetCodePoint: $000010FA
    ),
    (
      SourceCodePoint: $00001CBD;
      TargetCodePoint: $000010FD
    ),
    (
      SourceCodePoint: $00001CBE;
      TargetCodePoint: $000010FE
    ),
    (
      SourceCodePoint: $00001CBF;
      TargetCodePoint: $000010FF
    ),
    (
      SourceCodePoint: $00001E00;
      TargetCodePoint: $00001E01
    ),
    (
      SourceCodePoint: $00001E02;
      TargetCodePoint: $00001E03
    ),
    (
      SourceCodePoint: $00001E04;
      TargetCodePoint: $00001E05
    ),
    (
      SourceCodePoint: $00001E06;
      TargetCodePoint: $00001E07
    ),
    (
      SourceCodePoint: $00001E08;
      TargetCodePoint: $00001E09
    ),
    (
      SourceCodePoint: $00001E0A;
      TargetCodePoint: $00001E0B
    ),
    (
      SourceCodePoint: $00001E0C;
      TargetCodePoint: $00001E0D
    ),
    (
      SourceCodePoint: $00001E0E;
      TargetCodePoint: $00001E0F
    ),
    (
      SourceCodePoint: $00001E10;
      TargetCodePoint: $00001E11
    ),
    (
      SourceCodePoint: $00001E12;
      TargetCodePoint: $00001E13
    ),
    (
      SourceCodePoint: $00001E14;
      TargetCodePoint: $00001E15
    ),
    (
      SourceCodePoint: $00001E16;
      TargetCodePoint: $00001E17
    ),
    (
      SourceCodePoint: $00001E18;
      TargetCodePoint: $00001E19
    ),
    (
      SourceCodePoint: $00001E1A;
      TargetCodePoint: $00001E1B
    ),
    (
      SourceCodePoint: $00001E1C;
      TargetCodePoint: $00001E1D
    ),
    (
      SourceCodePoint: $00001E1E;
      TargetCodePoint: $00001E1F
    ),
    (
      SourceCodePoint: $00001E20;
      TargetCodePoint: $00001E21
    ),
    (
      SourceCodePoint: $00001E22;
      TargetCodePoint: $00001E23
    ),
    (
      SourceCodePoint: $00001E24;
      TargetCodePoint: $00001E25
    ),
    (
      SourceCodePoint: $00001E26;
      TargetCodePoint: $00001E27
    ),
    (
      SourceCodePoint: $00001E28;
      TargetCodePoint: $00001E29
    ),
    (
      SourceCodePoint: $00001E2A;
      TargetCodePoint: $00001E2B
    ),
    (
      SourceCodePoint: $00001E2C;
      TargetCodePoint: $00001E2D
    ),
    (
      SourceCodePoint: $00001E2E;
      TargetCodePoint: $00001E2F
    ),
    (
      SourceCodePoint: $00001E30;
      TargetCodePoint: $00001E31
    ),
    (
      SourceCodePoint: $00001E32;
      TargetCodePoint: $00001E33
    ),
    (
      SourceCodePoint: $00001E34;
      TargetCodePoint: $00001E35
    ),
    (
      SourceCodePoint: $00001E36;
      TargetCodePoint: $00001E37
    ),
    (
      SourceCodePoint: $00001E38;
      TargetCodePoint: $00001E39
    ),
    (
      SourceCodePoint: $00001E3A;
      TargetCodePoint: $00001E3B
    ),
    (
      SourceCodePoint: $00001E3C;
      TargetCodePoint: $00001E3D
    ),
    (
      SourceCodePoint: $00001E3E;
      TargetCodePoint: $00001E3F
    ),
    (
      SourceCodePoint: $00001E40;
      TargetCodePoint: $00001E41
    ),
    (
      SourceCodePoint: $00001E42;
      TargetCodePoint: $00001E43
    ),
    (
      SourceCodePoint: $00001E44;
      TargetCodePoint: $00001E45
    ),
    (
      SourceCodePoint: $00001E46;
      TargetCodePoint: $00001E47
    ),
    (
      SourceCodePoint: $00001E48;
      TargetCodePoint: $00001E49
    ),
    (
      SourceCodePoint: $00001E4A;
      TargetCodePoint: $00001E4B
    ),
    (
      SourceCodePoint: $00001E4C;
      TargetCodePoint: $00001E4D
    ),
    (
      SourceCodePoint: $00001E4E;
      TargetCodePoint: $00001E4F
    ),
    (
      SourceCodePoint: $00001E50;
      TargetCodePoint: $00001E51
    ),
    (
      SourceCodePoint: $00001E52;
      TargetCodePoint: $00001E53
    ),
    (
      SourceCodePoint: $00001E54;
      TargetCodePoint: $00001E55
    ),
    (
      SourceCodePoint: $00001E56;
      TargetCodePoint: $00001E57
    ),
    (
      SourceCodePoint: $00001E58;
      TargetCodePoint: $00001E59
    ),
    (
      SourceCodePoint: $00001E5A;
      TargetCodePoint: $00001E5B
    ),
    (
      SourceCodePoint: $00001E5C;
      TargetCodePoint: $00001E5D
    ),
    (
      SourceCodePoint: $00001E5E;
      TargetCodePoint: $00001E5F
    ),
    (
      SourceCodePoint: $00001E60;
      TargetCodePoint: $00001E61
    ),
    (
      SourceCodePoint: $00001E62;
      TargetCodePoint: $00001E63
    ),
    (
      SourceCodePoint: $00001E64;
      TargetCodePoint: $00001E65
    ),
    (
      SourceCodePoint: $00001E66;
      TargetCodePoint: $00001E67
    ),
    (
      SourceCodePoint: $00001E68;
      TargetCodePoint: $00001E69
    ),
    (
      SourceCodePoint: $00001E6A;
      TargetCodePoint: $00001E6B
    ),
    (
      SourceCodePoint: $00001E6C;
      TargetCodePoint: $00001E6D
    ),
    (
      SourceCodePoint: $00001E6E;
      TargetCodePoint: $00001E6F
    ),
    (
      SourceCodePoint: $00001E70;
      TargetCodePoint: $00001E71
    ),
    (
      SourceCodePoint: $00001E72;
      TargetCodePoint: $00001E73
    ),
    (
      SourceCodePoint: $00001E74;
      TargetCodePoint: $00001E75
    ),
    (
      SourceCodePoint: $00001E76;
      TargetCodePoint: $00001E77
    ),
    (
      SourceCodePoint: $00001E78;
      TargetCodePoint: $00001E79
    ),
    (
      SourceCodePoint: $00001E7A;
      TargetCodePoint: $00001E7B
    ),
    (
      SourceCodePoint: $00001E7C;
      TargetCodePoint: $00001E7D
    ),
    (
      SourceCodePoint: $00001E7E;
      TargetCodePoint: $00001E7F
    ),
    (
      SourceCodePoint: $00001E80;
      TargetCodePoint: $00001E81
    ),
    (
      SourceCodePoint: $00001E82;
      TargetCodePoint: $00001E83
    ),
    (
      SourceCodePoint: $00001E84;
      TargetCodePoint: $00001E85
    ),
    (
      SourceCodePoint: $00001E86;
      TargetCodePoint: $00001E87
    ),
    (
      SourceCodePoint: $00001E88;
      TargetCodePoint: $00001E89
    ),
    (
      SourceCodePoint: $00001E8A;
      TargetCodePoint: $00001E8B
    ),
    (
      SourceCodePoint: $00001E8C;
      TargetCodePoint: $00001E8D
    ),
    (
      SourceCodePoint: $00001E8E;
      TargetCodePoint: $00001E8F
    ),
    (
      SourceCodePoint: $00001E90;
      TargetCodePoint: $00001E91
    ),
    (
      SourceCodePoint: $00001E92;
      TargetCodePoint: $00001E93
    ),
    (
      SourceCodePoint: $00001E94;
      TargetCodePoint: $00001E95
    ),
    (
      SourceCodePoint: $00001E9B;
      TargetCodePoint: $00001E61
    ),
    (
      SourceCodePoint: $00001EA0;
      TargetCodePoint: $00001EA1
    ),
    (
      SourceCodePoint: $00001EA2;
      TargetCodePoint: $00001EA3
    ),
    (
      SourceCodePoint: $00001EA4;
      TargetCodePoint: $00001EA5
    ),
    (
      SourceCodePoint: $00001EA6;
      TargetCodePoint: $00001EA7
    ),
    (
      SourceCodePoint: $00001EA8;
      TargetCodePoint: $00001EA9
    ),
    (
      SourceCodePoint: $00001EAA;
      TargetCodePoint: $00001EAB
    ),
    (
      SourceCodePoint: $00001EAC;
      TargetCodePoint: $00001EAD
    ),
    (
      SourceCodePoint: $00001EAE;
      TargetCodePoint: $00001EAF
    ),
    (
      SourceCodePoint: $00001EB0;
      TargetCodePoint: $00001EB1
    ),
    (
      SourceCodePoint: $00001EB2;
      TargetCodePoint: $00001EB3
    ),
    (
      SourceCodePoint: $00001EB4;
      TargetCodePoint: $00001EB5
    ),
    (
      SourceCodePoint: $00001EB6;
      TargetCodePoint: $00001EB7
    ),
    (
      SourceCodePoint: $00001EB8;
      TargetCodePoint: $00001EB9
    ),
    (
      SourceCodePoint: $00001EBA;
      TargetCodePoint: $00001EBB
    ),
    (
      SourceCodePoint: $00001EBC;
      TargetCodePoint: $00001EBD
    ),
    (
      SourceCodePoint: $00001EBE;
      TargetCodePoint: $00001EBF
    ),
    (
      SourceCodePoint: $00001EC0;
      TargetCodePoint: $00001EC1
    ),
    (
      SourceCodePoint: $00001EC2;
      TargetCodePoint: $00001EC3
    ),
    (
      SourceCodePoint: $00001EC4;
      TargetCodePoint: $00001EC5
    ),
    (
      SourceCodePoint: $00001EC6;
      TargetCodePoint: $00001EC7
    ),
    (
      SourceCodePoint: $00001EC8;
      TargetCodePoint: $00001EC9
    ),
    (
      SourceCodePoint: $00001ECA;
      TargetCodePoint: $00001ECB
    ),
    (
      SourceCodePoint: $00001ECC;
      TargetCodePoint: $00001ECD
    ),
    (
      SourceCodePoint: $00001ECE;
      TargetCodePoint: $00001ECF
    ),
    (
      SourceCodePoint: $00001ED0;
      TargetCodePoint: $00001ED1
    ),
    (
      SourceCodePoint: $00001ED2;
      TargetCodePoint: $00001ED3
    ),
    (
      SourceCodePoint: $00001ED4;
      TargetCodePoint: $00001ED5
    ),
    (
      SourceCodePoint: $00001ED6;
      TargetCodePoint: $00001ED7
    ),
    (
      SourceCodePoint: $00001ED8;
      TargetCodePoint: $00001ED9
    ),
    (
      SourceCodePoint: $00001EDA;
      TargetCodePoint: $00001EDB
    ),
    (
      SourceCodePoint: $00001EDC;
      TargetCodePoint: $00001EDD
    ),
    (
      SourceCodePoint: $00001EDE;
      TargetCodePoint: $00001EDF
    ),
    (
      SourceCodePoint: $00001EE0;
      TargetCodePoint: $00001EE1
    ),
    (
      SourceCodePoint: $00001EE2;
      TargetCodePoint: $00001EE3
    ),
    (
      SourceCodePoint: $00001EE4;
      TargetCodePoint: $00001EE5
    ),
    (
      SourceCodePoint: $00001EE6;
      TargetCodePoint: $00001EE7
    ),
    (
      SourceCodePoint: $00001EE8;
      TargetCodePoint: $00001EE9
    ),
    (
      SourceCodePoint: $00001EEA;
      TargetCodePoint: $00001EEB
    ),
    (
      SourceCodePoint: $00001EEC;
      TargetCodePoint: $00001EED
    ),
    (
      SourceCodePoint: $00001EEE;
      TargetCodePoint: $00001EEF
    ),
    (
      SourceCodePoint: $00001EF0;
      TargetCodePoint: $00001EF1
    ),
    (
      SourceCodePoint: $00001EF2;
      TargetCodePoint: $00001EF3
    ),
    (
      SourceCodePoint: $00001EF4;
      TargetCodePoint: $00001EF5
    ),
    (
      SourceCodePoint: $00001EF6;
      TargetCodePoint: $00001EF7
    ),
    (
      SourceCodePoint: $00001EF8;
      TargetCodePoint: $00001EF9
    ),
    (
      SourceCodePoint: $00001EFA;
      TargetCodePoint: $00001EFB
    ),
    (
      SourceCodePoint: $00001EFC;
      TargetCodePoint: $00001EFD
    ),
    (
      SourceCodePoint: $00001EFE;
      TargetCodePoint: $00001EFF
    ),
    (
      SourceCodePoint: $00001F08;
      TargetCodePoint: $00001F00
    ),
    (
      SourceCodePoint: $00001F09;
      TargetCodePoint: $00001F01
    ),
    (
      SourceCodePoint: $00001F0A;
      TargetCodePoint: $00001F02
    ),
    (
      SourceCodePoint: $00001F0B;
      TargetCodePoint: $00001F03
    ),
    (
      SourceCodePoint: $00001F0C;
      TargetCodePoint: $00001F04
    ),
    (
      SourceCodePoint: $00001F0D;
      TargetCodePoint: $00001F05
    ),
    (
      SourceCodePoint: $00001F0E;
      TargetCodePoint: $00001F06
    ),
    (
      SourceCodePoint: $00001F0F;
      TargetCodePoint: $00001F07
    ),
    (
      SourceCodePoint: $00001F18;
      TargetCodePoint: $00001F10
    ),
    (
      SourceCodePoint: $00001F19;
      TargetCodePoint: $00001F11
    ),
    (
      SourceCodePoint: $00001F1A;
      TargetCodePoint: $00001F12
    ),
    (
      SourceCodePoint: $00001F1B;
      TargetCodePoint: $00001F13
    ),
    (
      SourceCodePoint: $00001F1C;
      TargetCodePoint: $00001F14
    ),
    (
      SourceCodePoint: $00001F1D;
      TargetCodePoint: $00001F15
    ),
    (
      SourceCodePoint: $00001F28;
      TargetCodePoint: $00001F20
    ),
    (
      SourceCodePoint: $00001F29;
      TargetCodePoint: $00001F21
    ),
    (
      SourceCodePoint: $00001F2A;
      TargetCodePoint: $00001F22
    ),
    (
      SourceCodePoint: $00001F2B;
      TargetCodePoint: $00001F23
    ),
    (
      SourceCodePoint: $00001F2C;
      TargetCodePoint: $00001F24
    ),
    (
      SourceCodePoint: $00001F2D;
      TargetCodePoint: $00001F25
    ),
    (
      SourceCodePoint: $00001F2E;
      TargetCodePoint: $00001F26
    ),
    (
      SourceCodePoint: $00001F2F;
      TargetCodePoint: $00001F27
    ),
    (
      SourceCodePoint: $00001F38;
      TargetCodePoint: $00001F30
    ),
    (
      SourceCodePoint: $00001F39;
      TargetCodePoint: $00001F31
    ),
    (
      SourceCodePoint: $00001F3A;
      TargetCodePoint: $00001F32
    ),
    (
      SourceCodePoint: $00001F3B;
      TargetCodePoint: $00001F33
    ),
    (
      SourceCodePoint: $00001F3C;
      TargetCodePoint: $00001F34
    ),
    (
      SourceCodePoint: $00001F3D;
      TargetCodePoint: $00001F35
    ),
    (
      SourceCodePoint: $00001F3E;
      TargetCodePoint: $00001F36
    ),
    (
      SourceCodePoint: $00001F3F;
      TargetCodePoint: $00001F37
    ),
    (
      SourceCodePoint: $00001F48;
      TargetCodePoint: $00001F40
    ),
    (
      SourceCodePoint: $00001F49;
      TargetCodePoint: $00001F41
    ),
    (
      SourceCodePoint: $00001F4A;
      TargetCodePoint: $00001F42
    ),
    (
      SourceCodePoint: $00001F4B;
      TargetCodePoint: $00001F43
    ),
    (
      SourceCodePoint: $00001F4C;
      TargetCodePoint: $00001F44
    ),
    (
      SourceCodePoint: $00001F4D;
      TargetCodePoint: $00001F45
    ),
    (
      SourceCodePoint: $00001F59;
      TargetCodePoint: $00001F51
    ),
    (
      SourceCodePoint: $00001F5B;
      TargetCodePoint: $00001F53
    ),
    (
      SourceCodePoint: $00001F5D;
      TargetCodePoint: $00001F55
    ),
    (
      SourceCodePoint: $00001F5F;
      TargetCodePoint: $00001F57
    ),
    (
      SourceCodePoint: $00001F68;
      TargetCodePoint: $00001F60
    ),
    (
      SourceCodePoint: $00001F69;
      TargetCodePoint: $00001F61
    ),
    (
      SourceCodePoint: $00001F6A;
      TargetCodePoint: $00001F62
    ),
    (
      SourceCodePoint: $00001F6B;
      TargetCodePoint: $00001F63
    ),
    (
      SourceCodePoint: $00001F6C;
      TargetCodePoint: $00001F64
    ),
    (
      SourceCodePoint: $00001F6D;
      TargetCodePoint: $00001F65
    ),
    (
      SourceCodePoint: $00001F6E;
      TargetCodePoint: $00001F66
    ),
    (
      SourceCodePoint: $00001F6F;
      TargetCodePoint: $00001F67
    ),
    (
      SourceCodePoint: $00001FB8;
      TargetCodePoint: $00001FB0
    ),
    (
      SourceCodePoint: $00001FB9;
      TargetCodePoint: $00001FB1
    ),
    (
      SourceCodePoint: $00001FBA;
      TargetCodePoint: $00001F70
    ),
    (
      SourceCodePoint: $00001FBB;
      TargetCodePoint: $00001F71
    ),
    (
      SourceCodePoint: $00001FBE;
      TargetCodePoint: $000003B9
    ),
    (
      SourceCodePoint: $00001FC8;
      TargetCodePoint: $00001F72
    ),
    (
      SourceCodePoint: $00001FC9;
      TargetCodePoint: $00001F73
    ),
    (
      SourceCodePoint: $00001FCA;
      TargetCodePoint: $00001F74
    ),
    (
      SourceCodePoint: $00001FCB;
      TargetCodePoint: $00001F75
    ),
    (
      SourceCodePoint: $00001FD8;
      TargetCodePoint: $00001FD0
    ),
    (
      SourceCodePoint: $00001FD9;
      TargetCodePoint: $00001FD1
    ),
    (
      SourceCodePoint: $00001FDA;
      TargetCodePoint: $00001F76
    ),
    (
      SourceCodePoint: $00001FDB;
      TargetCodePoint: $00001F77
    ),
    (
      SourceCodePoint: $00001FE8;
      TargetCodePoint: $00001FE0
    ),
    (
      SourceCodePoint: $00001FE9;
      TargetCodePoint: $00001FE1
    ),
    (
      SourceCodePoint: $00001FEA;
      TargetCodePoint: $00001F7A
    ),
    (
      SourceCodePoint: $00001FEB;
      TargetCodePoint: $00001F7B
    ),
    (
      SourceCodePoint: $00001FEC;
      TargetCodePoint: $00001FE5
    ),
    (
      SourceCodePoint: $00001FF8;
      TargetCodePoint: $00001F78
    ),
    (
      SourceCodePoint: $00001FF9;
      TargetCodePoint: $00001F79
    ),
    (
      SourceCodePoint: $00001FFA;
      TargetCodePoint: $00001F7C
    ),
    (
      SourceCodePoint: $00001FFB;
      TargetCodePoint: $00001F7D
    ),
    (
      SourceCodePoint: $00002126;
      TargetCodePoint: $000003C9
    ),
    (
      SourceCodePoint: $0000212A;
      TargetCodePoint: $0000006B
    ),
    (
      SourceCodePoint: $0000212B;
      TargetCodePoint: $000000E5
    ),
    (
      SourceCodePoint: $00002132;
      TargetCodePoint: $0000214E
    ),
    (
      SourceCodePoint: $00002160;
      TargetCodePoint: $00002170
    ),
    (
      SourceCodePoint: $00002161;
      TargetCodePoint: $00002171
    ),
    (
      SourceCodePoint: $00002162;
      TargetCodePoint: $00002172
    ),
    (
      SourceCodePoint: $00002163;
      TargetCodePoint: $00002173
    ),
    (
      SourceCodePoint: $00002164;
      TargetCodePoint: $00002174
    ),
    (
      SourceCodePoint: $00002165;
      TargetCodePoint: $00002175
    ),
    (
      SourceCodePoint: $00002166;
      TargetCodePoint: $00002176
    ),
    (
      SourceCodePoint: $00002167;
      TargetCodePoint: $00002177
    ),
    (
      SourceCodePoint: $00002168;
      TargetCodePoint: $00002178
    ),
    (
      SourceCodePoint: $00002169;
      TargetCodePoint: $00002179
    ),
    (
      SourceCodePoint: $0000216A;
      TargetCodePoint: $0000217A
    ),
    (
      SourceCodePoint: $0000216B;
      TargetCodePoint: $0000217B
    ),
    (
      SourceCodePoint: $0000216C;
      TargetCodePoint: $0000217C
    ),
    (
      SourceCodePoint: $0000216D;
      TargetCodePoint: $0000217D
    ),
    (
      SourceCodePoint: $0000216E;
      TargetCodePoint: $0000217E
    ),
    (
      SourceCodePoint: $0000216F;
      TargetCodePoint: $0000217F
    ),
    (
      SourceCodePoint: $00002183;
      TargetCodePoint: $00002184
    ),
    (
      SourceCodePoint: $000024B6;
      TargetCodePoint: $000024D0
    ),
    (
      SourceCodePoint: $000024B7;
      TargetCodePoint: $000024D1
    ),
    (
      SourceCodePoint: $000024B8;
      TargetCodePoint: $000024D2
    ),
    (
      SourceCodePoint: $000024B9;
      TargetCodePoint: $000024D3
    ),
    (
      SourceCodePoint: $000024BA;
      TargetCodePoint: $000024D4
    ),
    (
      SourceCodePoint: $000024BB;
      TargetCodePoint: $000024D5
    ),
    (
      SourceCodePoint: $000024BC;
      TargetCodePoint: $000024D6
    ),
    (
      SourceCodePoint: $000024BD;
      TargetCodePoint: $000024D7
    ),
    (
      SourceCodePoint: $000024BE;
      TargetCodePoint: $000024D8
    ),
    (
      SourceCodePoint: $000024BF;
      TargetCodePoint: $000024D9
    ),
    (
      SourceCodePoint: $000024C0;
      TargetCodePoint: $000024DA
    ),
    (
      SourceCodePoint: $000024C1;
      TargetCodePoint: $000024DB
    ),
    (
      SourceCodePoint: $000024C2;
      TargetCodePoint: $000024DC
    ),
    (
      SourceCodePoint: $000024C3;
      TargetCodePoint: $000024DD
    ),
    (
      SourceCodePoint: $000024C4;
      TargetCodePoint: $000024DE
    ),
    (
      SourceCodePoint: $000024C5;
      TargetCodePoint: $000024DF
    ),
    (
      SourceCodePoint: $000024C6;
      TargetCodePoint: $000024E0
    ),
    (
      SourceCodePoint: $000024C7;
      TargetCodePoint: $000024E1
    ),
    (
      SourceCodePoint: $000024C8;
      TargetCodePoint: $000024E2
    ),
    (
      SourceCodePoint: $000024C9;
      TargetCodePoint: $000024E3
    ),
    (
      SourceCodePoint: $000024CA;
      TargetCodePoint: $000024E4
    ),
    (
      SourceCodePoint: $000024CB;
      TargetCodePoint: $000024E5
    ),
    (
      SourceCodePoint: $000024CC;
      TargetCodePoint: $000024E6
    ),
    (
      SourceCodePoint: $000024CD;
      TargetCodePoint: $000024E7
    ),
    (
      SourceCodePoint: $000024CE;
      TargetCodePoint: $000024E8
    ),
    (
      SourceCodePoint: $000024CF;
      TargetCodePoint: $000024E9
    ),
    (
      SourceCodePoint: $00002C00;
      TargetCodePoint: $00002C30
    ),
    (
      SourceCodePoint: $00002C01;
      TargetCodePoint: $00002C31
    ),
    (
      SourceCodePoint: $00002C02;
      TargetCodePoint: $00002C32
    ),
    (
      SourceCodePoint: $00002C03;
      TargetCodePoint: $00002C33
    ),
    (
      SourceCodePoint: $00002C04;
      TargetCodePoint: $00002C34
    ),
    (
      SourceCodePoint: $00002C05;
      TargetCodePoint: $00002C35
    ),
    (
      SourceCodePoint: $00002C06;
      TargetCodePoint: $00002C36
    ),
    (
      SourceCodePoint: $00002C07;
      TargetCodePoint: $00002C37
    ),
    (
      SourceCodePoint: $00002C08;
      TargetCodePoint: $00002C38
    ),
    (
      SourceCodePoint: $00002C09;
      TargetCodePoint: $00002C39
    ),
    (
      SourceCodePoint: $00002C0A;
      TargetCodePoint: $00002C3A
    ),
    (
      SourceCodePoint: $00002C0B;
      TargetCodePoint: $00002C3B
    ),
    (
      SourceCodePoint: $00002C0C;
      TargetCodePoint: $00002C3C
    ),
    (
      SourceCodePoint: $00002C0D;
      TargetCodePoint: $00002C3D
    ),
    (
      SourceCodePoint: $00002C0E;
      TargetCodePoint: $00002C3E
    ),
    (
      SourceCodePoint: $00002C0F;
      TargetCodePoint: $00002C3F
    ),
    (
      SourceCodePoint: $00002C10;
      TargetCodePoint: $00002C40
    ),
    (
      SourceCodePoint: $00002C11;
      TargetCodePoint: $00002C41
    ),
    (
      SourceCodePoint: $00002C12;
      TargetCodePoint: $00002C42
    ),
    (
      SourceCodePoint: $00002C13;
      TargetCodePoint: $00002C43
    ),
    (
      SourceCodePoint: $00002C14;
      TargetCodePoint: $00002C44
    ),
    (
      SourceCodePoint: $00002C15;
      TargetCodePoint: $00002C45
    ),
    (
      SourceCodePoint: $00002C16;
      TargetCodePoint: $00002C46
    ),
    (
      SourceCodePoint: $00002C17;
      TargetCodePoint: $00002C47
    ),
    (
      SourceCodePoint: $00002C18;
      TargetCodePoint: $00002C48
    ),
    (
      SourceCodePoint: $00002C19;
      TargetCodePoint: $00002C49
    ),
    (
      SourceCodePoint: $00002C1A;
      TargetCodePoint: $00002C4A
    ),
    (
      SourceCodePoint: $00002C1B;
      TargetCodePoint: $00002C4B
    ),
    (
      SourceCodePoint: $00002C1C;
      TargetCodePoint: $00002C4C
    ),
    (
      SourceCodePoint: $00002C1D;
      TargetCodePoint: $00002C4D
    ),
    (
      SourceCodePoint: $00002C1E;
      TargetCodePoint: $00002C4E
    ),
    (
      SourceCodePoint: $00002C1F;
      TargetCodePoint: $00002C4F
    ),
    (
      SourceCodePoint: $00002C20;
      TargetCodePoint: $00002C50
    ),
    (
      SourceCodePoint: $00002C21;
      TargetCodePoint: $00002C51
    ),
    (
      SourceCodePoint: $00002C22;
      TargetCodePoint: $00002C52
    ),
    (
      SourceCodePoint: $00002C23;
      TargetCodePoint: $00002C53
    ),
    (
      SourceCodePoint: $00002C24;
      TargetCodePoint: $00002C54
    ),
    (
      SourceCodePoint: $00002C25;
      TargetCodePoint: $00002C55
    ),
    (
      SourceCodePoint: $00002C26;
      TargetCodePoint: $00002C56
    ),
    (
      SourceCodePoint: $00002C27;
      TargetCodePoint: $00002C57
    ),
    (
      SourceCodePoint: $00002C28;
      TargetCodePoint: $00002C58
    ),
    (
      SourceCodePoint: $00002C29;
      TargetCodePoint: $00002C59
    ),
    (
      SourceCodePoint: $00002C2A;
      TargetCodePoint: $00002C5A
    ),
    (
      SourceCodePoint: $00002C2B;
      TargetCodePoint: $00002C5B
    ),
    (
      SourceCodePoint: $00002C2C;
      TargetCodePoint: $00002C5C
    ),
    (
      SourceCodePoint: $00002C2D;
      TargetCodePoint: $00002C5D
    ),
    (
      SourceCodePoint: $00002C2E;
      TargetCodePoint: $00002C5E
    ),
    (
      SourceCodePoint: $00002C2F;
      TargetCodePoint: $00002C5F
    ),
    (
      SourceCodePoint: $00002C60;
      TargetCodePoint: $00002C61
    ),
    (
      SourceCodePoint: $00002C62;
      TargetCodePoint: $0000026B
    ),
    (
      SourceCodePoint: $00002C63;
      TargetCodePoint: $00001D7D
    ),
    (
      SourceCodePoint: $00002C64;
      TargetCodePoint: $0000027D
    ),
    (
      SourceCodePoint: $00002C67;
      TargetCodePoint: $00002C68
    ),
    (
      SourceCodePoint: $00002C69;
      TargetCodePoint: $00002C6A
    ),
    (
      SourceCodePoint: $00002C6B;
      TargetCodePoint: $00002C6C
    ),
    (
      SourceCodePoint: $00002C6D;
      TargetCodePoint: $00000251
    ),
    (
      SourceCodePoint: $00002C6E;
      TargetCodePoint: $00000271
    ),
    (
      SourceCodePoint: $00002C6F;
      TargetCodePoint: $00000250
    ),
    (
      SourceCodePoint: $00002C70;
      TargetCodePoint: $00000252
    ),
    (
      SourceCodePoint: $00002C72;
      TargetCodePoint: $00002C73
    ),
    (
      SourceCodePoint: $00002C75;
      TargetCodePoint: $00002C76
    ),
    (
      SourceCodePoint: $00002C7E;
      TargetCodePoint: $0000023F
    ),
    (
      SourceCodePoint: $00002C7F;
      TargetCodePoint: $00000240
    ),
    (
      SourceCodePoint: $00002C80;
      TargetCodePoint: $00002C81
    ),
    (
      SourceCodePoint: $00002C82;
      TargetCodePoint: $00002C83
    ),
    (
      SourceCodePoint: $00002C84;
      TargetCodePoint: $00002C85
    ),
    (
      SourceCodePoint: $00002C86;
      TargetCodePoint: $00002C87
    ),
    (
      SourceCodePoint: $00002C88;
      TargetCodePoint: $00002C89
    ),
    (
      SourceCodePoint: $00002C8A;
      TargetCodePoint: $00002C8B
    ),
    (
      SourceCodePoint: $00002C8C;
      TargetCodePoint: $00002C8D
    ),
    (
      SourceCodePoint: $00002C8E;
      TargetCodePoint: $00002C8F
    ),
    (
      SourceCodePoint: $00002C90;
      TargetCodePoint: $00002C91
    ),
    (
      SourceCodePoint: $00002C92;
      TargetCodePoint: $00002C93
    ),
    (
      SourceCodePoint: $00002C94;
      TargetCodePoint: $00002C95
    ),
    (
      SourceCodePoint: $00002C96;
      TargetCodePoint: $00002C97
    ),
    (
      SourceCodePoint: $00002C98;
      TargetCodePoint: $00002C99
    ),
    (
      SourceCodePoint: $00002C9A;
      TargetCodePoint: $00002C9B
    ),
    (
      SourceCodePoint: $00002C9C;
      TargetCodePoint: $00002C9D
    ),
    (
      SourceCodePoint: $00002C9E;
      TargetCodePoint: $00002C9F
    ),
    (
      SourceCodePoint: $00002CA0;
      TargetCodePoint: $00002CA1
    ),
    (
      SourceCodePoint: $00002CA2;
      TargetCodePoint: $00002CA3
    ),
    (
      SourceCodePoint: $00002CA4;
      TargetCodePoint: $00002CA5
    ),
    (
      SourceCodePoint: $00002CA6;
      TargetCodePoint: $00002CA7
    ),
    (
      SourceCodePoint: $00002CA8;
      TargetCodePoint: $00002CA9
    ),
    (
      SourceCodePoint: $00002CAA;
      TargetCodePoint: $00002CAB
    ),
    (
      SourceCodePoint: $00002CAC;
      TargetCodePoint: $00002CAD
    ),
    (
      SourceCodePoint: $00002CAE;
      TargetCodePoint: $00002CAF
    ),
    (
      SourceCodePoint: $00002CB0;
      TargetCodePoint: $00002CB1
    ),
    (
      SourceCodePoint: $00002CB2;
      TargetCodePoint: $00002CB3
    ),
    (
      SourceCodePoint: $00002CB4;
      TargetCodePoint: $00002CB5
    ),
    (
      SourceCodePoint: $00002CB6;
      TargetCodePoint: $00002CB7
    ),
    (
      SourceCodePoint: $00002CB8;
      TargetCodePoint: $00002CB9
    ),
    (
      SourceCodePoint: $00002CBA;
      TargetCodePoint: $00002CBB
    ),
    (
      SourceCodePoint: $00002CBC;
      TargetCodePoint: $00002CBD
    ),
    (
      SourceCodePoint: $00002CBE;
      TargetCodePoint: $00002CBF
    ),
    (
      SourceCodePoint: $00002CC0;
      TargetCodePoint: $00002CC1
    ),
    (
      SourceCodePoint: $00002CC2;
      TargetCodePoint: $00002CC3
    ),
    (
      SourceCodePoint: $00002CC4;
      TargetCodePoint: $00002CC5
    ),
    (
      SourceCodePoint: $00002CC6;
      TargetCodePoint: $00002CC7
    ),
    (
      SourceCodePoint: $00002CC8;
      TargetCodePoint: $00002CC9
    ),
    (
      SourceCodePoint: $00002CCA;
      TargetCodePoint: $00002CCB
    ),
    (
      SourceCodePoint: $00002CCC;
      TargetCodePoint: $00002CCD
    ),
    (
      SourceCodePoint: $00002CCE;
      TargetCodePoint: $00002CCF
    ),
    (
      SourceCodePoint: $00002CD0;
      TargetCodePoint: $00002CD1
    ),
    (
      SourceCodePoint: $00002CD2;
      TargetCodePoint: $00002CD3
    ),
    (
      SourceCodePoint: $00002CD4;
      TargetCodePoint: $00002CD5
    ),
    (
      SourceCodePoint: $00002CD6;
      TargetCodePoint: $00002CD7
    ),
    (
      SourceCodePoint: $00002CD8;
      TargetCodePoint: $00002CD9
    ),
    (
      SourceCodePoint: $00002CDA;
      TargetCodePoint: $00002CDB
    ),
    (
      SourceCodePoint: $00002CDC;
      TargetCodePoint: $00002CDD
    ),
    (
      SourceCodePoint: $00002CDE;
      TargetCodePoint: $00002CDF
    ),
    (
      SourceCodePoint: $00002CE0;
      TargetCodePoint: $00002CE1
    ),
    (
      SourceCodePoint: $00002CE2;
      TargetCodePoint: $00002CE3
    ),
    (
      SourceCodePoint: $00002CEB;
      TargetCodePoint: $00002CEC
    ),
    (
      SourceCodePoint: $00002CED;
      TargetCodePoint: $00002CEE
    ),
    (
      SourceCodePoint: $00002CF2;
      TargetCodePoint: $00002CF3
    ),
    (
      SourceCodePoint: $0000A640;
      TargetCodePoint: $0000A641
    ),
    (
      SourceCodePoint: $0000A642;
      TargetCodePoint: $0000A643
    ),
    (
      SourceCodePoint: $0000A644;
      TargetCodePoint: $0000A645
    ),
    (
      SourceCodePoint: $0000A646;
      TargetCodePoint: $0000A647
    ),
    (
      SourceCodePoint: $0000A648;
      TargetCodePoint: $0000A649
    ),
    (
      SourceCodePoint: $0000A64A;
      TargetCodePoint: $0000A64B
    ),
    (
      SourceCodePoint: $0000A64C;
      TargetCodePoint: $0000A64D
    ),
    (
      SourceCodePoint: $0000A64E;
      TargetCodePoint: $0000A64F
    ),
    (
      SourceCodePoint: $0000A650;
      TargetCodePoint: $0000A651
    ),
    (
      SourceCodePoint: $0000A652;
      TargetCodePoint: $0000A653
    ),
    (
      SourceCodePoint: $0000A654;
      TargetCodePoint: $0000A655
    ),
    (
      SourceCodePoint: $0000A656;
      TargetCodePoint: $0000A657
    ),
    (
      SourceCodePoint: $0000A658;
      TargetCodePoint: $0000A659
    ),
    (
      SourceCodePoint: $0000A65A;
      TargetCodePoint: $0000A65B
    ),
    (
      SourceCodePoint: $0000A65C;
      TargetCodePoint: $0000A65D
    ),
    (
      SourceCodePoint: $0000A65E;
      TargetCodePoint: $0000A65F
    ),
    (
      SourceCodePoint: $0000A660;
      TargetCodePoint: $0000A661
    ),
    (
      SourceCodePoint: $0000A662;
      TargetCodePoint: $0000A663
    ),
    (
      SourceCodePoint: $0000A664;
      TargetCodePoint: $0000A665
    ),
    (
      SourceCodePoint: $0000A666;
      TargetCodePoint: $0000A667
    ),
    (
      SourceCodePoint: $0000A668;
      TargetCodePoint: $0000A669
    ),
    (
      SourceCodePoint: $0000A66A;
      TargetCodePoint: $0000A66B
    ),
    (
      SourceCodePoint: $0000A66C;
      TargetCodePoint: $0000A66D
    ),
    (
      SourceCodePoint: $0000A680;
      TargetCodePoint: $0000A681
    ),
    (
      SourceCodePoint: $0000A682;
      TargetCodePoint: $0000A683
    ),
    (
      SourceCodePoint: $0000A684;
      TargetCodePoint: $0000A685
    ),
    (
      SourceCodePoint: $0000A686;
      TargetCodePoint: $0000A687
    ),
    (
      SourceCodePoint: $0000A688;
      TargetCodePoint: $0000A689
    ),
    (
      SourceCodePoint: $0000A68A;
      TargetCodePoint: $0000A68B
    ),
    (
      SourceCodePoint: $0000A68C;
      TargetCodePoint: $0000A68D
    ),
    (
      SourceCodePoint: $0000A68E;
      TargetCodePoint: $0000A68F
    ),
    (
      SourceCodePoint: $0000A690;
      TargetCodePoint: $0000A691
    ),
    (
      SourceCodePoint: $0000A692;
      TargetCodePoint: $0000A693
    ),
    (
      SourceCodePoint: $0000A694;
      TargetCodePoint: $0000A695
    ),
    (
      SourceCodePoint: $0000A696;
      TargetCodePoint: $0000A697
    ),
    (
      SourceCodePoint: $0000A698;
      TargetCodePoint: $0000A699
    ),
    (
      SourceCodePoint: $0000A69A;
      TargetCodePoint: $0000A69B
    ),
    (
      SourceCodePoint: $0000A722;
      TargetCodePoint: $0000A723
    ),
    (
      SourceCodePoint: $0000A724;
      TargetCodePoint: $0000A725
    ),
    (
      SourceCodePoint: $0000A726;
      TargetCodePoint: $0000A727
    ),
    (
      SourceCodePoint: $0000A728;
      TargetCodePoint: $0000A729
    ),
    (
      SourceCodePoint: $0000A72A;
      TargetCodePoint: $0000A72B
    ),
    (
      SourceCodePoint: $0000A72C;
      TargetCodePoint: $0000A72D
    ),
    (
      SourceCodePoint: $0000A72E;
      TargetCodePoint: $0000A72F
    ),
    (
      SourceCodePoint: $0000A732;
      TargetCodePoint: $0000A733
    ),
    (
      SourceCodePoint: $0000A734;
      TargetCodePoint: $0000A735
    ),
    (
      SourceCodePoint: $0000A736;
      TargetCodePoint: $0000A737
    ),
    (
      SourceCodePoint: $0000A738;
      TargetCodePoint: $0000A739
    ),
    (
      SourceCodePoint: $0000A73A;
      TargetCodePoint: $0000A73B
    ),
    (
      SourceCodePoint: $0000A73C;
      TargetCodePoint: $0000A73D
    ),
    (
      SourceCodePoint: $0000A73E;
      TargetCodePoint: $0000A73F
    ),
    (
      SourceCodePoint: $0000A740;
      TargetCodePoint: $0000A741
    ),
    (
      SourceCodePoint: $0000A742;
      TargetCodePoint: $0000A743
    ),
    (
      SourceCodePoint: $0000A744;
      TargetCodePoint: $0000A745
    ),
    (
      SourceCodePoint: $0000A746;
      TargetCodePoint: $0000A747
    ),
    (
      SourceCodePoint: $0000A748;
      TargetCodePoint: $0000A749
    ),
    (
      SourceCodePoint: $0000A74A;
      TargetCodePoint: $0000A74B
    ),
    (
      SourceCodePoint: $0000A74C;
      TargetCodePoint: $0000A74D
    ),
    (
      SourceCodePoint: $0000A74E;
      TargetCodePoint: $0000A74F
    ),
    (
      SourceCodePoint: $0000A750;
      TargetCodePoint: $0000A751
    ),
    (
      SourceCodePoint: $0000A752;
      TargetCodePoint: $0000A753
    ),
    (
      SourceCodePoint: $0000A754;
      TargetCodePoint: $0000A755
    ),
    (
      SourceCodePoint: $0000A756;
      TargetCodePoint: $0000A757
    ),
    (
      SourceCodePoint: $0000A758;
      TargetCodePoint: $0000A759
    ),
    (
      SourceCodePoint: $0000A75A;
      TargetCodePoint: $0000A75B
    ),
    (
      SourceCodePoint: $0000A75C;
      TargetCodePoint: $0000A75D
    ),
    (
      SourceCodePoint: $0000A75E;
      TargetCodePoint: $0000A75F
    ),
    (
      SourceCodePoint: $0000A760;
      TargetCodePoint: $0000A761
    ),
    (
      SourceCodePoint: $0000A762;
      TargetCodePoint: $0000A763
    ),
    (
      SourceCodePoint: $0000A764;
      TargetCodePoint: $0000A765
    ),
    (
      SourceCodePoint: $0000A766;
      TargetCodePoint: $0000A767
    ),
    (
      SourceCodePoint: $0000A768;
      TargetCodePoint: $0000A769
    ),
    (
      SourceCodePoint: $0000A76A;
      TargetCodePoint: $0000A76B
    ),
    (
      SourceCodePoint: $0000A76C;
      TargetCodePoint: $0000A76D
    ),
    (
      SourceCodePoint: $0000A76E;
      TargetCodePoint: $0000A76F
    ),
    (
      SourceCodePoint: $0000A779;
      TargetCodePoint: $0000A77A
    ),
    (
      SourceCodePoint: $0000A77B;
      TargetCodePoint: $0000A77C
    ),
    (
      SourceCodePoint: $0000A77D;
      TargetCodePoint: $00001D79
    ),
    (
      SourceCodePoint: $0000A77E;
      TargetCodePoint: $0000A77F
    ),
    (
      SourceCodePoint: $0000A780;
      TargetCodePoint: $0000A781
    ),
    (
      SourceCodePoint: $0000A782;
      TargetCodePoint: $0000A783
    ),
    (
      SourceCodePoint: $0000A784;
      TargetCodePoint: $0000A785
    ),
    (
      SourceCodePoint: $0000A786;
      TargetCodePoint: $0000A787
    ),
    (
      SourceCodePoint: $0000A78B;
      TargetCodePoint: $0000A78C
    ),
    (
      SourceCodePoint: $0000A78D;
      TargetCodePoint: $00000265
    ),
    (
      SourceCodePoint: $0000A790;
      TargetCodePoint: $0000A791
    ),
    (
      SourceCodePoint: $0000A792;
      TargetCodePoint: $0000A793
    ),
    (
      SourceCodePoint: $0000A796;
      TargetCodePoint: $0000A797
    ),
    (
      SourceCodePoint: $0000A798;
      TargetCodePoint: $0000A799
    ),
    (
      SourceCodePoint: $0000A79A;
      TargetCodePoint: $0000A79B
    ),
    (
      SourceCodePoint: $0000A79C;
      TargetCodePoint: $0000A79D
    ),
    (
      SourceCodePoint: $0000A79E;
      TargetCodePoint: $0000A79F
    ),
    (
      SourceCodePoint: $0000A7A0;
      TargetCodePoint: $0000A7A1
    ),
    (
      SourceCodePoint: $0000A7A2;
      TargetCodePoint: $0000A7A3
    ),
    (
      SourceCodePoint: $0000A7A4;
      TargetCodePoint: $0000A7A5
    ),
    (
      SourceCodePoint: $0000A7A6;
      TargetCodePoint: $0000A7A7
    ),
    (
      SourceCodePoint: $0000A7A8;
      TargetCodePoint: $0000A7A9
    ),
    (
      SourceCodePoint: $0000A7AA;
      TargetCodePoint: $00000266
    ),
    (
      SourceCodePoint: $0000A7AB;
      TargetCodePoint: $0000025C
    ),
    (
      SourceCodePoint: $0000A7AC;
      TargetCodePoint: $00000261
    ),
    (
      SourceCodePoint: $0000A7AD;
      TargetCodePoint: $0000026C
    ),
    (
      SourceCodePoint: $0000A7AE;
      TargetCodePoint: $0000026A
    ),
    (
      SourceCodePoint: $0000A7B0;
      TargetCodePoint: $0000029E
    ),
    (
      SourceCodePoint: $0000A7B1;
      TargetCodePoint: $00000287
    ),
    (
      SourceCodePoint: $0000A7B2;
      TargetCodePoint: $0000029D
    ),
    (
      SourceCodePoint: $0000A7B3;
      TargetCodePoint: $0000AB53
    ),
    (
      SourceCodePoint: $0000A7B4;
      TargetCodePoint: $0000A7B5
    ),
    (
      SourceCodePoint: $0000A7B6;
      TargetCodePoint: $0000A7B7
    ),
    (
      SourceCodePoint: $0000A7B8;
      TargetCodePoint: $0000A7B9
    ),
    (
      SourceCodePoint: $0000A7BA;
      TargetCodePoint: $0000A7BB
    ),
    (
      SourceCodePoint: $0000A7BC;
      TargetCodePoint: $0000A7BD
    ),
    (
      SourceCodePoint: $0000A7BE;
      TargetCodePoint: $0000A7BF
    ),
    (
      SourceCodePoint: $0000A7C0;
      TargetCodePoint: $0000A7C1
    ),
    (
      SourceCodePoint: $0000A7C2;
      TargetCodePoint: $0000A7C3
    ),
    (
      SourceCodePoint: $0000A7C4;
      TargetCodePoint: $0000A794
    ),
    (
      SourceCodePoint: $0000A7C5;
      TargetCodePoint: $00000282
    ),
    (
      SourceCodePoint: $0000A7C6;
      TargetCodePoint: $00001D8E
    ),
    (
      SourceCodePoint: $0000A7C7;
      TargetCodePoint: $0000A7C8
    ),
    (
      SourceCodePoint: $0000A7C9;
      TargetCodePoint: $0000A7CA
    ),
    (
      SourceCodePoint: $0000A7D0;
      TargetCodePoint: $0000A7D1
    ),
    (
      SourceCodePoint: $0000A7D6;
      TargetCodePoint: $0000A7D7
    ),
    (
      SourceCodePoint: $0000A7D8;
      TargetCodePoint: $0000A7D9
    ),
    (
      SourceCodePoint: $0000A7F5;
      TargetCodePoint: $0000A7F6
    ),
    (
      SourceCodePoint: $0000AB70;
      TargetCodePoint: $000013A0
    ),
    (
      SourceCodePoint: $0000AB71;
      TargetCodePoint: $000013A1
    ),
    (
      SourceCodePoint: $0000AB72;
      TargetCodePoint: $000013A2
    ),
    (
      SourceCodePoint: $0000AB73;
      TargetCodePoint: $000013A3
    ),
    (
      SourceCodePoint: $0000AB74;
      TargetCodePoint: $000013A4
    ),
    (
      SourceCodePoint: $0000AB75;
      TargetCodePoint: $000013A5
    ),
    (
      SourceCodePoint: $0000AB76;
      TargetCodePoint: $000013A6
    ),
    (
      SourceCodePoint: $0000AB77;
      TargetCodePoint: $000013A7
    ),
    (
      SourceCodePoint: $0000AB78;
      TargetCodePoint: $000013A8
    ),
    (
      SourceCodePoint: $0000AB79;
      TargetCodePoint: $000013A9
    ),
    (
      SourceCodePoint: $0000AB7A;
      TargetCodePoint: $000013AA
    ),
    (
      SourceCodePoint: $0000AB7B;
      TargetCodePoint: $000013AB
    ),
    (
      SourceCodePoint: $0000AB7C;
      TargetCodePoint: $000013AC
    ),
    (
      SourceCodePoint: $0000AB7D;
      TargetCodePoint: $000013AD
    ),
    (
      SourceCodePoint: $0000AB7E;
      TargetCodePoint: $000013AE
    ),
    (
      SourceCodePoint: $0000AB7F;
      TargetCodePoint: $000013AF
    ),
    (
      SourceCodePoint: $0000AB80;
      TargetCodePoint: $000013B0
    ),
    (
      SourceCodePoint: $0000AB81;
      TargetCodePoint: $000013B1
    ),
    (
      SourceCodePoint: $0000AB82;
      TargetCodePoint: $000013B2
    ),
    (
      SourceCodePoint: $0000AB83;
      TargetCodePoint: $000013B3
    ),
    (
      SourceCodePoint: $0000AB84;
      TargetCodePoint: $000013B4
    ),
    (
      SourceCodePoint: $0000AB85;
      TargetCodePoint: $000013B5
    ),
    (
      SourceCodePoint: $0000AB86;
      TargetCodePoint: $000013B6
    ),
    (
      SourceCodePoint: $0000AB87;
      TargetCodePoint: $000013B7
    ),
    (
      SourceCodePoint: $0000AB88;
      TargetCodePoint: $000013B8
    ),
    (
      SourceCodePoint: $0000AB89;
      TargetCodePoint: $000013B9
    ),
    (
      SourceCodePoint: $0000AB8A;
      TargetCodePoint: $000013BA
    ),
    (
      SourceCodePoint: $0000AB8B;
      TargetCodePoint: $000013BB
    ),
    (
      SourceCodePoint: $0000AB8C;
      TargetCodePoint: $000013BC
    ),
    (
      SourceCodePoint: $0000AB8D;
      TargetCodePoint: $000013BD
    ),
    (
      SourceCodePoint: $0000AB8E;
      TargetCodePoint: $000013BE
    ),
    (
      SourceCodePoint: $0000AB8F;
      TargetCodePoint: $000013BF
    ),
    (
      SourceCodePoint: $0000AB90;
      TargetCodePoint: $000013C0
    ),
    (
      SourceCodePoint: $0000AB91;
      TargetCodePoint: $000013C1
    ),
    (
      SourceCodePoint: $0000AB92;
      TargetCodePoint: $000013C2
    ),
    (
      SourceCodePoint: $0000AB93;
      TargetCodePoint: $000013C3
    ),
    (
      SourceCodePoint: $0000AB94;
      TargetCodePoint: $000013C4
    ),
    (
      SourceCodePoint: $0000AB95;
      TargetCodePoint: $000013C5
    ),
    (
      SourceCodePoint: $0000AB96;
      TargetCodePoint: $000013C6
    ),
    (
      SourceCodePoint: $0000AB97;
      TargetCodePoint: $000013C7
    ),
    (
      SourceCodePoint: $0000AB98;
      TargetCodePoint: $000013C8
    ),
    (
      SourceCodePoint: $0000AB99;
      TargetCodePoint: $000013C9
    ),
    (
      SourceCodePoint: $0000AB9A;
      TargetCodePoint: $000013CA
    ),
    (
      SourceCodePoint: $0000AB9B;
      TargetCodePoint: $000013CB
    ),
    (
      SourceCodePoint: $0000AB9C;
      TargetCodePoint: $000013CC
    ),
    (
      SourceCodePoint: $0000AB9D;
      TargetCodePoint: $000013CD
    ),
    (
      SourceCodePoint: $0000AB9E;
      TargetCodePoint: $000013CE
    ),
    (
      SourceCodePoint: $0000AB9F;
      TargetCodePoint: $000013CF
    ),
    (
      SourceCodePoint: $0000ABA0;
      TargetCodePoint: $000013D0
    ),
    (
      SourceCodePoint: $0000ABA1;
      TargetCodePoint: $000013D1
    ),
    (
      SourceCodePoint: $0000ABA2;
      TargetCodePoint: $000013D2
    ),
    (
      SourceCodePoint: $0000ABA3;
      TargetCodePoint: $000013D3
    ),
    (
      SourceCodePoint: $0000ABA4;
      TargetCodePoint: $000013D4
    ),
    (
      SourceCodePoint: $0000ABA5;
      TargetCodePoint: $000013D5
    ),
    (
      SourceCodePoint: $0000ABA6;
      TargetCodePoint: $000013D6
    ),
    (
      SourceCodePoint: $0000ABA7;
      TargetCodePoint: $000013D7
    ),
    (
      SourceCodePoint: $0000ABA8;
      TargetCodePoint: $000013D8
    ),
    (
      SourceCodePoint: $0000ABA9;
      TargetCodePoint: $000013D9
    ),
    (
      SourceCodePoint: $0000ABAA;
      TargetCodePoint: $000013DA
    ),
    (
      SourceCodePoint: $0000ABAB;
      TargetCodePoint: $000013DB
    ),
    (
      SourceCodePoint: $0000ABAC;
      TargetCodePoint: $000013DC
    ),
    (
      SourceCodePoint: $0000ABAD;
      TargetCodePoint: $000013DD
    ),
    (
      SourceCodePoint: $0000ABAE;
      TargetCodePoint: $000013DE
    ),
    (
      SourceCodePoint: $0000ABAF;
      TargetCodePoint: $000013DF
    ),
    (
      SourceCodePoint: $0000ABB0;
      TargetCodePoint: $000013E0
    ),
    (
      SourceCodePoint: $0000ABB1;
      TargetCodePoint: $000013E1
    ),
    (
      SourceCodePoint: $0000ABB2;
      TargetCodePoint: $000013E2
    ),
    (
      SourceCodePoint: $0000ABB3;
      TargetCodePoint: $000013E3
    ),
    (
      SourceCodePoint: $0000ABB4;
      TargetCodePoint: $000013E4
    ),
    (
      SourceCodePoint: $0000ABB5;
      TargetCodePoint: $000013E5
    ),
    (
      SourceCodePoint: $0000ABB6;
      TargetCodePoint: $000013E6
    ),
    (
      SourceCodePoint: $0000ABB7;
      TargetCodePoint: $000013E7
    ),
    (
      SourceCodePoint: $0000ABB8;
      TargetCodePoint: $000013E8
    ),
    (
      SourceCodePoint: $0000ABB9;
      TargetCodePoint: $000013E9
    ),
    (
      SourceCodePoint: $0000ABBA;
      TargetCodePoint: $000013EA
    ),
    (
      SourceCodePoint: $0000ABBB;
      TargetCodePoint: $000013EB
    ),
    (
      SourceCodePoint: $0000ABBC;
      TargetCodePoint: $000013EC
    ),
    (
      SourceCodePoint: $0000ABBD;
      TargetCodePoint: $000013ED
    ),
    (
      SourceCodePoint: $0000ABBE;
      TargetCodePoint: $000013EE
    ),
    (
      SourceCodePoint: $0000ABBF;
      TargetCodePoint: $000013EF
    ),
    (
      SourceCodePoint: $0000FF21;
      TargetCodePoint: $0000FF41
    ),
    (
      SourceCodePoint: $0000FF22;
      TargetCodePoint: $0000FF42
    ),
    (
      SourceCodePoint: $0000FF23;
      TargetCodePoint: $0000FF43
    ),
    (
      SourceCodePoint: $0000FF24;
      TargetCodePoint: $0000FF44
    ),
    (
      SourceCodePoint: $0000FF25;
      TargetCodePoint: $0000FF45
    ),
    (
      SourceCodePoint: $0000FF26;
      TargetCodePoint: $0000FF46
    ),
    (
      SourceCodePoint: $0000FF27;
      TargetCodePoint: $0000FF47
    ),
    (
      SourceCodePoint: $0000FF28;
      TargetCodePoint: $0000FF48
    ),
    (
      SourceCodePoint: $0000FF29;
      TargetCodePoint: $0000FF49
    ),
    (
      SourceCodePoint: $0000FF2A;
      TargetCodePoint: $0000FF4A
    ),
    (
      SourceCodePoint: $0000FF2B;
      TargetCodePoint: $0000FF4B
    ),
    (
      SourceCodePoint: $0000FF2C;
      TargetCodePoint: $0000FF4C
    ),
    (
      SourceCodePoint: $0000FF2D;
      TargetCodePoint: $0000FF4D
    ),
    (
      SourceCodePoint: $0000FF2E;
      TargetCodePoint: $0000FF4E
    ),
    (
      SourceCodePoint: $0000FF2F;
      TargetCodePoint: $0000FF4F
    ),
    (
      SourceCodePoint: $0000FF30;
      TargetCodePoint: $0000FF50
    ),
    (
      SourceCodePoint: $0000FF31;
      TargetCodePoint: $0000FF51
    ),
    (
      SourceCodePoint: $0000FF32;
      TargetCodePoint: $0000FF52
    ),
    (
      SourceCodePoint: $0000FF33;
      TargetCodePoint: $0000FF53
    ),
    (
      SourceCodePoint: $0000FF34;
      TargetCodePoint: $0000FF54
    ),
    (
      SourceCodePoint: $0000FF35;
      TargetCodePoint: $0000FF55
    ),
    (
      SourceCodePoint: $0000FF36;
      TargetCodePoint: $0000FF56
    ),
    (
      SourceCodePoint: $0000FF37;
      TargetCodePoint: $0000FF57
    ),
    (
      SourceCodePoint: $0000FF38;
      TargetCodePoint: $0000FF58
    ),
    (
      SourceCodePoint: $0000FF39;
      TargetCodePoint: $0000FF59
    ),
    (
      SourceCodePoint: $0000FF3A;
      TargetCodePoint: $0000FF5A
    ),
    (
      SourceCodePoint: $00010400;
      TargetCodePoint: $00010428
    ),
    (
      SourceCodePoint: $00010401;
      TargetCodePoint: $00010429
    ),
    (
      SourceCodePoint: $00010402;
      TargetCodePoint: $0001042A
    ),
    (
      SourceCodePoint: $00010403;
      TargetCodePoint: $0001042B
    ),
    (
      SourceCodePoint: $00010404;
      TargetCodePoint: $0001042C
    ),
    (
      SourceCodePoint: $00010405;
      TargetCodePoint: $0001042D
    ),
    (
      SourceCodePoint: $00010406;
      TargetCodePoint: $0001042E
    ),
    (
      SourceCodePoint: $00010407;
      TargetCodePoint: $0001042F
    ),
    (
      SourceCodePoint: $00010408;
      TargetCodePoint: $00010430
    ),
    (
      SourceCodePoint: $00010409;
      TargetCodePoint: $00010431
    ),
    (
      SourceCodePoint: $0001040A;
      TargetCodePoint: $00010432
    ),
    (
      SourceCodePoint: $0001040B;
      TargetCodePoint: $00010433
    ),
    (
      SourceCodePoint: $0001040C;
      TargetCodePoint: $00010434
    ),
    (
      SourceCodePoint: $0001040D;
      TargetCodePoint: $00010435
    ),
    (
      SourceCodePoint: $0001040E;
      TargetCodePoint: $00010436
    ),
    (
      SourceCodePoint: $0001040F;
      TargetCodePoint: $00010437
    ),
    (
      SourceCodePoint: $00010410;
      TargetCodePoint: $00010438
    ),
    (
      SourceCodePoint: $00010411;
      TargetCodePoint: $00010439
    ),
    (
      SourceCodePoint: $00010412;
      TargetCodePoint: $0001043A
    ),
    (
      SourceCodePoint: $00010413;
      TargetCodePoint: $0001043B
    ),
    (
      SourceCodePoint: $00010414;
      TargetCodePoint: $0001043C
    ),
    (
      SourceCodePoint: $00010415;
      TargetCodePoint: $0001043D
    ),
    (
      SourceCodePoint: $00010416;
      TargetCodePoint: $0001043E
    ),
    (
      SourceCodePoint: $00010417;
      TargetCodePoint: $0001043F
    ),
    (
      SourceCodePoint: $00010418;
      TargetCodePoint: $00010440
    ),
    (
      SourceCodePoint: $00010419;
      TargetCodePoint: $00010441
    ),
    (
      SourceCodePoint: $0001041A;
      TargetCodePoint: $00010442
    ),
    (
      SourceCodePoint: $0001041B;
      TargetCodePoint: $00010443
    ),
    (
      SourceCodePoint: $0001041C;
      TargetCodePoint: $00010444
    ),
    (
      SourceCodePoint: $0001041D;
      TargetCodePoint: $00010445
    ),
    (
      SourceCodePoint: $0001041E;
      TargetCodePoint: $00010446
    ),
    (
      SourceCodePoint: $0001041F;
      TargetCodePoint: $00010447
    ),
    (
      SourceCodePoint: $00010420;
      TargetCodePoint: $00010448
    ),
    (
      SourceCodePoint: $00010421;
      TargetCodePoint: $00010449
    ),
    (
      SourceCodePoint: $00010422;
      TargetCodePoint: $0001044A
    ),
    (
      SourceCodePoint: $00010423;
      TargetCodePoint: $0001044B
    ),
    (
      SourceCodePoint: $00010424;
      TargetCodePoint: $0001044C
    ),
    (
      SourceCodePoint: $00010425;
      TargetCodePoint: $0001044D
    ),
    (
      SourceCodePoint: $00010426;
      TargetCodePoint: $0001044E
    ),
    (
      SourceCodePoint: $00010427;
      TargetCodePoint: $0001044F
    ),
    (
      SourceCodePoint: $000104B0;
      TargetCodePoint: $000104D8
    ),
    (
      SourceCodePoint: $000104B1;
      TargetCodePoint: $000104D9
    ),
    (
      SourceCodePoint: $000104B2;
      TargetCodePoint: $000104DA
    ),
    (
      SourceCodePoint: $000104B3;
      TargetCodePoint: $000104DB
    ),
    (
      SourceCodePoint: $000104B4;
      TargetCodePoint: $000104DC
    ),
    (
      SourceCodePoint: $000104B5;
      TargetCodePoint: $000104DD
    ),
    (
      SourceCodePoint: $000104B6;
      TargetCodePoint: $000104DE
    ),
    (
      SourceCodePoint: $000104B7;
      TargetCodePoint: $000104DF
    ),
    (
      SourceCodePoint: $000104B8;
      TargetCodePoint: $000104E0
    ),
    (
      SourceCodePoint: $000104B9;
      TargetCodePoint: $000104E1
    ),
    (
      SourceCodePoint: $000104BA;
      TargetCodePoint: $000104E2
    ),
    (
      SourceCodePoint: $000104BB;
      TargetCodePoint: $000104E3
    ),
    (
      SourceCodePoint: $000104BC;
      TargetCodePoint: $000104E4
    ),
    (
      SourceCodePoint: $000104BD;
      TargetCodePoint: $000104E5
    ),
    (
      SourceCodePoint: $000104BE;
      TargetCodePoint: $000104E6
    ),
    (
      SourceCodePoint: $000104BF;
      TargetCodePoint: $000104E7
    ),
    (
      SourceCodePoint: $000104C0;
      TargetCodePoint: $000104E8
    ),
    (
      SourceCodePoint: $000104C1;
      TargetCodePoint: $000104E9
    ),
    (
      SourceCodePoint: $000104C2;
      TargetCodePoint: $000104EA
    ),
    (
      SourceCodePoint: $000104C3;
      TargetCodePoint: $000104EB
    ),
    (
      SourceCodePoint: $000104C4;
      TargetCodePoint: $000104EC
    ),
    (
      SourceCodePoint: $000104C5;
      TargetCodePoint: $000104ED
    ),
    (
      SourceCodePoint: $000104C6;
      TargetCodePoint: $000104EE
    ),
    (
      SourceCodePoint: $000104C7;
      TargetCodePoint: $000104EF
    ),
    (
      SourceCodePoint: $000104C8;
      TargetCodePoint: $000104F0
    ),
    (
      SourceCodePoint: $000104C9;
      TargetCodePoint: $000104F1
    ),
    (
      SourceCodePoint: $000104CA;
      TargetCodePoint: $000104F2
    ),
    (
      SourceCodePoint: $000104CB;
      TargetCodePoint: $000104F3
    ),
    (
      SourceCodePoint: $000104CC;
      TargetCodePoint: $000104F4
    ),
    (
      SourceCodePoint: $000104CD;
      TargetCodePoint: $000104F5
    ),
    (
      SourceCodePoint: $000104CE;
      TargetCodePoint: $000104F6
    ),
    (
      SourceCodePoint: $000104CF;
      TargetCodePoint: $000104F7
    ),
    (
      SourceCodePoint: $000104D0;
      TargetCodePoint: $000104F8
    ),
    (
      SourceCodePoint: $000104D1;
      TargetCodePoint: $000104F9
    ),
    (
      SourceCodePoint: $000104D2;
      TargetCodePoint: $000104FA
    ),
    (
      SourceCodePoint: $000104D3;
      TargetCodePoint: $000104FB
    ),
    (
      SourceCodePoint: $00010570;
      TargetCodePoint: $00010597
    ),
    (
      SourceCodePoint: $00010571;
      TargetCodePoint: $00010598
    ),
    (
      SourceCodePoint: $00010572;
      TargetCodePoint: $00010599
    ),
    (
      SourceCodePoint: $00010573;
      TargetCodePoint: $0001059A
    ),
    (
      SourceCodePoint: $00010574;
      TargetCodePoint: $0001059B
    ),
    (
      SourceCodePoint: $00010575;
      TargetCodePoint: $0001059C
    ),
    (
      SourceCodePoint: $00010576;
      TargetCodePoint: $0001059D
    ),
    (
      SourceCodePoint: $00010577;
      TargetCodePoint: $0001059E
    ),
    (
      SourceCodePoint: $00010578;
      TargetCodePoint: $0001059F
    ),
    (
      SourceCodePoint: $00010579;
      TargetCodePoint: $000105A0
    ),
    (
      SourceCodePoint: $0001057A;
      TargetCodePoint: $000105A1
    ),
    (
      SourceCodePoint: $0001057C;
      TargetCodePoint: $000105A3
    ),
    (
      SourceCodePoint: $0001057D;
      TargetCodePoint: $000105A4
    ),
    (
      SourceCodePoint: $0001057E;
      TargetCodePoint: $000105A5
    ),
    (
      SourceCodePoint: $0001057F;
      TargetCodePoint: $000105A6
    ),
    (
      SourceCodePoint: $00010580;
      TargetCodePoint: $000105A7
    ),
    (
      SourceCodePoint: $00010581;
      TargetCodePoint: $000105A8
    ),
    (
      SourceCodePoint: $00010582;
      TargetCodePoint: $000105A9
    ),
    (
      SourceCodePoint: $00010583;
      TargetCodePoint: $000105AA
    ),
    (
      SourceCodePoint: $00010584;
      TargetCodePoint: $000105AB
    ),
    (
      SourceCodePoint: $00010585;
      TargetCodePoint: $000105AC
    ),
    (
      SourceCodePoint: $00010586;
      TargetCodePoint: $000105AD
    ),
    (
      SourceCodePoint: $00010587;
      TargetCodePoint: $000105AE
    ),
    (
      SourceCodePoint: $00010588;
      TargetCodePoint: $000105AF
    ),
    (
      SourceCodePoint: $00010589;
      TargetCodePoint: $000105B0
    ),
    (
      SourceCodePoint: $0001058A;
      TargetCodePoint: $000105B1
    ),
    (
      SourceCodePoint: $0001058C;
      TargetCodePoint: $000105B3
    ),
    (
      SourceCodePoint: $0001058D;
      TargetCodePoint: $000105B4
    ),
    (
      SourceCodePoint: $0001058E;
      TargetCodePoint: $000105B5
    ),
    (
      SourceCodePoint: $0001058F;
      TargetCodePoint: $000105B6
    ),
    (
      SourceCodePoint: $00010590;
      TargetCodePoint: $000105B7
    ),
    (
      SourceCodePoint: $00010591;
      TargetCodePoint: $000105B8
    ),
    (
      SourceCodePoint: $00010592;
      TargetCodePoint: $000105B9
    ),
    (
      SourceCodePoint: $00010594;
      TargetCodePoint: $000105BB
    ),
    (
      SourceCodePoint: $00010595;
      TargetCodePoint: $000105BC
    ),
    (
      SourceCodePoint: $00010C80;
      TargetCodePoint: $00010CC0
    ),
    (
      SourceCodePoint: $00010C81;
      TargetCodePoint: $00010CC1
    ),
    (
      SourceCodePoint: $00010C82;
      TargetCodePoint: $00010CC2
    ),
    (
      SourceCodePoint: $00010C83;
      TargetCodePoint: $00010CC3
    ),
    (
      SourceCodePoint: $00010C84;
      TargetCodePoint: $00010CC4
    ),
    (
      SourceCodePoint: $00010C85;
      TargetCodePoint: $00010CC5
    ),
    (
      SourceCodePoint: $00010C86;
      TargetCodePoint: $00010CC6
    ),
    (
      SourceCodePoint: $00010C87;
      TargetCodePoint: $00010CC7
    ),
    (
      SourceCodePoint: $00010C88;
      TargetCodePoint: $00010CC8
    ),
    (
      SourceCodePoint: $00010C89;
      TargetCodePoint: $00010CC9
    ),
    (
      SourceCodePoint: $00010C8A;
      TargetCodePoint: $00010CCA
    ),
    (
      SourceCodePoint: $00010C8B;
      TargetCodePoint: $00010CCB
    ),
    (
      SourceCodePoint: $00010C8C;
      TargetCodePoint: $00010CCC
    ),
    (
      SourceCodePoint: $00010C8D;
      TargetCodePoint: $00010CCD
    ),
    (
      SourceCodePoint: $00010C8E;
      TargetCodePoint: $00010CCE
    ),
    (
      SourceCodePoint: $00010C8F;
      TargetCodePoint: $00010CCF
    ),
    (
      SourceCodePoint: $00010C90;
      TargetCodePoint: $00010CD0
    ),
    (
      SourceCodePoint: $00010C91;
      TargetCodePoint: $00010CD1
    ),
    (
      SourceCodePoint: $00010C92;
      TargetCodePoint: $00010CD2
    ),
    (
      SourceCodePoint: $00010C93;
      TargetCodePoint: $00010CD3
    ),
    (
      SourceCodePoint: $00010C94;
      TargetCodePoint: $00010CD4
    ),
    (
      SourceCodePoint: $00010C95;
      TargetCodePoint: $00010CD5
    ),
    (
      SourceCodePoint: $00010C96;
      TargetCodePoint: $00010CD6
    ),
    (
      SourceCodePoint: $00010C97;
      TargetCodePoint: $00010CD7
    ),
    (
      SourceCodePoint: $00010C98;
      TargetCodePoint: $00010CD8
    ),
    (
      SourceCodePoint: $00010C99;
      TargetCodePoint: $00010CD9
    ),
    (
      SourceCodePoint: $00010C9A;
      TargetCodePoint: $00010CDA
    ),
    (
      SourceCodePoint: $00010C9B;
      TargetCodePoint: $00010CDB
    ),
    (
      SourceCodePoint: $00010C9C;
      TargetCodePoint: $00010CDC
    ),
    (
      SourceCodePoint: $00010C9D;
      TargetCodePoint: $00010CDD
    ),
    (
      SourceCodePoint: $00010C9E;
      TargetCodePoint: $00010CDE
    ),
    (
      SourceCodePoint: $00010C9F;
      TargetCodePoint: $00010CDF
    ),
    (
      SourceCodePoint: $00010CA0;
      TargetCodePoint: $00010CE0
    ),
    (
      SourceCodePoint: $00010CA1;
      TargetCodePoint: $00010CE1
    ),
    (
      SourceCodePoint: $00010CA2;
      TargetCodePoint: $00010CE2
    ),
    (
      SourceCodePoint: $00010CA3;
      TargetCodePoint: $00010CE3
    ),
    (
      SourceCodePoint: $00010CA4;
      TargetCodePoint: $00010CE4
    ),
    (
      SourceCodePoint: $00010CA5;
      TargetCodePoint: $00010CE5
    ),
    (
      SourceCodePoint: $00010CA6;
      TargetCodePoint: $00010CE6
    ),
    (
      SourceCodePoint: $00010CA7;
      TargetCodePoint: $00010CE7
    ),
    (
      SourceCodePoint: $00010CA8;
      TargetCodePoint: $00010CE8
    ),
    (
      SourceCodePoint: $00010CA9;
      TargetCodePoint: $00010CE9
    ),
    (
      SourceCodePoint: $00010CAA;
      TargetCodePoint: $00010CEA
    ),
    (
      SourceCodePoint: $00010CAB;
      TargetCodePoint: $00010CEB
    ),
    (
      SourceCodePoint: $00010CAC;
      TargetCodePoint: $00010CEC
    ),
    (
      SourceCodePoint: $00010CAD;
      TargetCodePoint: $00010CED
    ),
    (
      SourceCodePoint: $00010CAE;
      TargetCodePoint: $00010CEE
    ),
    (
      SourceCodePoint: $00010CAF;
      TargetCodePoint: $00010CEF
    ),
    (
      SourceCodePoint: $00010CB0;
      TargetCodePoint: $00010CF0
    ),
    (
      SourceCodePoint: $00010CB1;
      TargetCodePoint: $00010CF1
    ),
    (
      SourceCodePoint: $00010CB2;
      TargetCodePoint: $00010CF2
    ),
    (
      SourceCodePoint: $000118A0;
      TargetCodePoint: $000118C0
    ),
    (
      SourceCodePoint: $000118A1;
      TargetCodePoint: $000118C1
    ),
    (
      SourceCodePoint: $000118A2;
      TargetCodePoint: $000118C2
    ),
    (
      SourceCodePoint: $000118A3;
      TargetCodePoint: $000118C3
    ),
    (
      SourceCodePoint: $000118A4;
      TargetCodePoint: $000118C4
    ),
    (
      SourceCodePoint: $000118A5;
      TargetCodePoint: $000118C5
    ),
    (
      SourceCodePoint: $000118A6;
      TargetCodePoint: $000118C6
    ),
    (
      SourceCodePoint: $000118A7;
      TargetCodePoint: $000118C7
    ),
    (
      SourceCodePoint: $000118A8;
      TargetCodePoint: $000118C8
    ),
    (
      SourceCodePoint: $000118A9;
      TargetCodePoint: $000118C9
    ),
    (
      SourceCodePoint: $000118AA;
      TargetCodePoint: $000118CA
    ),
    (
      SourceCodePoint: $000118AB;
      TargetCodePoint: $000118CB
    ),
    (
      SourceCodePoint: $000118AC;
      TargetCodePoint: $000118CC
    ),
    (
      SourceCodePoint: $000118AD;
      TargetCodePoint: $000118CD
    ),
    (
      SourceCodePoint: $000118AE;
      TargetCodePoint: $000118CE
    ),
    (
      SourceCodePoint: $000118AF;
      TargetCodePoint: $000118CF
    ),
    (
      SourceCodePoint: $000118B0;
      TargetCodePoint: $000118D0
    ),
    (
      SourceCodePoint: $000118B1;
      TargetCodePoint: $000118D1
    ),
    (
      SourceCodePoint: $000118B2;
      TargetCodePoint: $000118D2
    ),
    (
      SourceCodePoint: $000118B3;
      TargetCodePoint: $000118D3
    ),
    (
      SourceCodePoint: $000118B4;
      TargetCodePoint: $000118D4
    ),
    (
      SourceCodePoint: $000118B5;
      TargetCodePoint: $000118D5
    ),
    (
      SourceCodePoint: $000118B6;
      TargetCodePoint: $000118D6
    ),
    (
      SourceCodePoint: $000118B7;
      TargetCodePoint: $000118D7
    ),
    (
      SourceCodePoint: $000118B8;
      TargetCodePoint: $000118D8
    ),
    (
      SourceCodePoint: $000118B9;
      TargetCodePoint: $000118D9
    ),
    (
      SourceCodePoint: $000118BA;
      TargetCodePoint: $000118DA
    ),
    (
      SourceCodePoint: $000118BB;
      TargetCodePoint: $000118DB
    ),
    (
      SourceCodePoint: $000118BC;
      TargetCodePoint: $000118DC
    ),
    (
      SourceCodePoint: $000118BD;
      TargetCodePoint: $000118DD
    ),
    (
      SourceCodePoint: $000118BE;
      TargetCodePoint: $000118DE
    ),
    (
      SourceCodePoint: $000118BF;
      TargetCodePoint: $000118DF
    ),
    (
      SourceCodePoint: $00016E40;
      TargetCodePoint: $00016E60
    ),
    (
      SourceCodePoint: $00016E41;
      TargetCodePoint: $00016E61
    ),
    (
      SourceCodePoint: $00016E42;
      TargetCodePoint: $00016E62
    ),
    (
      SourceCodePoint: $00016E43;
      TargetCodePoint: $00016E63
    ),
    (
      SourceCodePoint: $00016E44;
      TargetCodePoint: $00016E64
    ),
    (
      SourceCodePoint: $00016E45;
      TargetCodePoint: $00016E65
    ),
    (
      SourceCodePoint: $00016E46;
      TargetCodePoint: $00016E66
    ),
    (
      SourceCodePoint: $00016E47;
      TargetCodePoint: $00016E67
    ),
    (
      SourceCodePoint: $00016E48;
      TargetCodePoint: $00016E68
    ),
    (
      SourceCodePoint: $00016E49;
      TargetCodePoint: $00016E69
    ),
    (
      SourceCodePoint: $00016E4A;
      TargetCodePoint: $00016E6A
    ),
    (
      SourceCodePoint: $00016E4B;
      TargetCodePoint: $00016E6B
    ),
    (
      SourceCodePoint: $00016E4C;
      TargetCodePoint: $00016E6C
    ),
    (
      SourceCodePoint: $00016E4D;
      TargetCodePoint: $00016E6D
    ),
    (
      SourceCodePoint: $00016E4E;
      TargetCodePoint: $00016E6E
    ),
    (
      SourceCodePoint: $00016E4F;
      TargetCodePoint: $00016E6F
    ),
    (
      SourceCodePoint: $00016E50;
      TargetCodePoint: $00016E70
    ),
    (
      SourceCodePoint: $00016E51;
      TargetCodePoint: $00016E71
    ),
    (
      SourceCodePoint: $00016E52;
      TargetCodePoint: $00016E72
    ),
    (
      SourceCodePoint: $00016E53;
      TargetCodePoint: $00016E73
    ),
    (
      SourceCodePoint: $00016E54;
      TargetCodePoint: $00016E74
    ),
    (
      SourceCodePoint: $00016E55;
      TargetCodePoint: $00016E75
    ),
    (
      SourceCodePoint: $00016E56;
      TargetCodePoint: $00016E76
    ),
    (
      SourceCodePoint: $00016E57;
      TargetCodePoint: $00016E77
    ),
    (
      SourceCodePoint: $00016E58;
      TargetCodePoint: $00016E78
    ),
    (
      SourceCodePoint: $00016E59;
      TargetCodePoint: $00016E79
    ),
    (
      SourceCodePoint: $00016E5A;
      TargetCodePoint: $00016E7A
    ),
    (
      SourceCodePoint: $00016E5B;
      TargetCodePoint: $00016E7B
    ),
    (
      SourceCodePoint: $00016E5C;
      TargetCodePoint: $00016E7C
    ),
    (
      SourceCodePoint: $00016E5D;
      TargetCodePoint: $00016E7D
    ),
    (
      SourceCodePoint: $00016E5E;
      TargetCodePoint: $00016E7E
    ),
    (
      SourceCodePoint: $00016E5F;
      TargetCodePoint: $00016E7F
    ),
    (
      SourceCodePoint: $0001E900;
      TargetCodePoint: $0001E922
    ),
    (
      SourceCodePoint: $0001E901;
      TargetCodePoint: $0001E923
    ),
    (
      SourceCodePoint: $0001E902;
      TargetCodePoint: $0001E924
    ),
    (
      SourceCodePoint: $0001E903;
      TargetCodePoint: $0001E925
    ),
    (
      SourceCodePoint: $0001E904;
      TargetCodePoint: $0001E926
    ),
    (
      SourceCodePoint: $0001E905;
      TargetCodePoint: $0001E927
    ),
    (
      SourceCodePoint: $0001E906;
      TargetCodePoint: $0001E928
    ),
    (
      SourceCodePoint: $0001E907;
      TargetCodePoint: $0001E929
    ),
    (
      SourceCodePoint: $0001E908;
      TargetCodePoint: $0001E92A
    ),
    (
      SourceCodePoint: $0001E909;
      TargetCodePoint: $0001E92B
    ),
    (
      SourceCodePoint: $0001E90A;
      TargetCodePoint: $0001E92C
    ),
    (
      SourceCodePoint: $0001E90B;
      TargetCodePoint: $0001E92D
    ),
    (
      SourceCodePoint: $0001E90C;
      TargetCodePoint: $0001E92E
    ),
    (
      SourceCodePoint: $0001E90D;
      TargetCodePoint: $0001E92F
    ),
    (
      SourceCodePoint: $0001E90E;
      TargetCodePoint: $0001E930
    ),
    (
      SourceCodePoint: $0001E90F;
      TargetCodePoint: $0001E931
    ),
    (
      SourceCodePoint: $0001E910;
      TargetCodePoint: $0001E932
    ),
    (
      SourceCodePoint: $0001E911;
      TargetCodePoint: $0001E933
    ),
    (
      SourceCodePoint: $0001E912;
      TargetCodePoint: $0001E934
    ),
    (
      SourceCodePoint: $0001E913;
      TargetCodePoint: $0001E935
    ),
    (
      SourceCodePoint: $0001E914;
      TargetCodePoint: $0001E936
    ),
    (
      SourceCodePoint: $0001E915;
      TargetCodePoint: $0001E937
    ),
    (
      SourceCodePoint: $0001E916;
      TargetCodePoint: $0001E938
    ),
    (
      SourceCodePoint: $0001E917;
      TargetCodePoint: $0001E939
    ),
    (
      SourceCodePoint: $0001E918;
      TargetCodePoint: $0001E93A
    ),
    (
      SourceCodePoint: $0001E919;
      TargetCodePoint: $0001E93B
    ),
    (
      SourceCodePoint: $0001E91A;
      TargetCodePoint: $0001E93C
    ),
    (
      SourceCodePoint: $0001E91B;
      TargetCodePoint: $0001E93D
    ),
    (
      SourceCodePoint: $0001E91C;
      TargetCodePoint: $0001E93E
    ),
    (
      SourceCodePoint: $0001E91D;
      TargetCodePoint: $0001E93F
    ),
    (
      SourceCodePoint: $0001E91E;
      TargetCodePoint: $0001E940
    ),
    (
      SourceCodePoint: $0001E91F;
      TargetCodePoint: $0001E941
    ),
    (
      SourceCodePoint: $0001E920;
      TargetCodePoint: $0001E942
    ),
    (
      SourceCodePoint: $0001E921;
      TargetCodePoint: $0001E943
    )
  );


implementation

end.

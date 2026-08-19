unit symbols;

{$mode objfpc}{$H+}{$J-}
{$R+}{$Q+}

interface

uses
  SysUtils, core, diagnostics;

const
  FSIM_TYPE_INVALID = 0;
  FSIM_TYPE_VOID = 1;
  FSIM_TYPE_INTEGER = 2;
  FSIM_TYPE_LONG_INTEGER = 3;
  FSIM_TYPE_SHORT_INTEGER = 4;
  FSIM_TYPE_REAL = 5;
  FSIM_TYPE_BOOLEAN = 6;
  FSIM_TYPE_CHARACTER = 7;
  FSIM_TYPE_TEXT = 8;
  FSIM_TYPE_STRING = 9;
  FSIM_TYPE_HEAD = 10;
  FSIM_TYPE_LINK = 11;
  FSIM_TYPE_CHANNEL = 12;
  FSIM_TYPE_MUTEX = 13;
  FSIM_TYPE_FUTURE = 14;
  FSIM_TYPE_SEMAPHORE = 15;
  FSIM_TYPE_BARRIER = 16;
  FSIM_TYPE_CONDITION = 17;
  FSIM_TYPE_ATOMIC = 18;
  FSIM_TYPE_C_CHAR = 19;
  FSIM_TYPE_C_SCHAR = 20;
  FSIM_TYPE_C_UCHAR = 21;
  FSIM_TYPE_C_SHORT = 22;
  FSIM_TYPE_C_USHORT = 23;
  FSIM_TYPE_C_INT = 24;
  FSIM_TYPE_C_UINT = 25;
  FSIM_TYPE_C_LONG = 26;
  FSIM_TYPE_C_ULONG = 27;
  FSIM_TYPE_C_LONGLONG = 28;
  FSIM_TYPE_C_ULONGLONG = 29;
  FSIM_TYPE_C_SIZE = 30;
  FSIM_TYPE_C_SSIZE = 31;
  FSIM_TYPE_C_INTPTR = 32;
  FSIM_TYPE_C_UINTPTR = 33;
  FSIM_TYPE_C_FLOAT = 34;
  FSIM_TYPE_C_DOUBLE = 35;
  FSIM_TYPE_C_BOOL = 36;
  FSIM_TYPE_C_PTR = 37;
  FSIM_TYPE_C_STRING = 38;
  FSIM_TYPE_C_FN = 39;
  FSIM_FIRST_USER_TYPE = 40;

  FSIM_C_INTRINSIC_ADDR = 1;
  FSIM_C_INTRINSIC_LOAD = 2;
  FSIM_C_INTRINSIC_STORE = 3;
  FSIM_C_INTRINSIC_OFFSET = 4;
  FSIM_C_INTRINSIC_SIZEOF = 5;
  FSIM_C_INTRINSIC_ALIGNOF = 6;
  FSIM_C_INTRINSIC_OFFSETOF = 7;

type
  TVisibility = (visPublic, visPrivate, visProtected);
  TPassingMode = (pmValue, pmName, pmReference);

  TTypeKind = (
    tyInvalid,
    tyVoid,
    tyInteger,
    tyReal,
    tyBoolean,
    tyCharacter,
    tyText,
    tyString,
    tyReference,
    tyHead,
    tyLink,
    tyChannel,
    tyMutex,
    tyFuture,
    tySemaphore,
    tyBarrier,
    tyCondition,
    tyAtomic,
    tyCInteger,
    tyCReal,
    tyCPointer,
    tyCFunction,
    tyArray,
    tyProcedure,
    tyClass,
    tyRecord,
    tyEnum,
    tyGenericParameter
  );

  TTypeFlag = (
    tfNone,
    tfSigned,
    tfManaged,
    tfNullable,
    tfValueType,
    tfReferenceType,
    tfCallable,
    tfComplete,
    tfRuntimeVisible,
    tfFixedLength,
    tfRuntimeBound,
    tfCLayout,
    tfCUnion,
    tfCVariadic,
    tfUnspecifiedSignature,
    tfGeneric
  );
  TTypeFlags = set of TTypeFlag;

  TSymbolKind = (
    skInvalid,
    skModule,
    skProgram,
    skClass,
    skProcessClass,
    skThreadClass,
    skProcedure,
    skFunction,
    skVirtualSpec,
    skParameter,
    skVariable,
    skConstant,
    skField,
    skLabel,
    skSwitch,
    skType,
    skEnumValue,
    skImport
  );

  TSymbolFlag = (
    sfNone,
    sfDefined,
    sfReferenced,
    sfAssigned,
    sfAddressTaken,
    sfVirtual,
    sfOverride,
    sfAbstract,
    sfFinal,
    sfInline,
    sfNative,
    sfOwn,
    sfValueParameter,
    sfNameParameter,
    sfSynthetic,
    sfExported,
    sfImported,
    sfMutable,
    sfThreadLocal,
    sfRuntimeRequired,
    sfForeign,
    sfVariadic,
    sfForeignExport
  );
  TSymbolFlags = set of TSymbolFlag;

  TScopeKind = (
    scGlobal,
    scModule,
    scProgram,
    scClass,
    scProcedure,
    scFunction,
    scBlock,
    scCatch
  );

  TTypeInfo = packed record
    Kind: TTypeKind;
    Flags: TTypeFlags;
    NameId: Int32;
    Size: UInt32;
    Alignment: UInt32;
    ElementType: Int32;
    ReturnType: Int32;
    RefClassSymbol: Int32;
    ParameterStart: Int32;
    ParameterCount: Int32;
    LowerBound: Int64;
    UpperBound: Int64;
    GenericArity: Int16;
    Reserved: Int16;
  end;

  TParameterInfo = packed record
    NameId: Int32;
    TypeId: Int32;
    Mode: TPassingMode;
    SymbolId: Int32;
    DefaultNode: Int32;
  end;

  TSymbol = packed record
    NameId: Int32;
    Hash: UInt32;
    Kind: TSymbolKind;
    Flags: TSymbolFlags;
    Visibility: TVisibility;
    TypeId: Int32;
    ScopeId: Int32;
    OwnerSymbol: Int32;
    DeclNode: Int32;
    BodyNode: Int32;
    SourceSpan: TSourceSpan;
    StorageOffset: Int32;
    StorageSize: UInt32;
    ParameterIndex: Int16;
    NestingLevel: Int16;
    VMTSlot: Int32;
    RTTIIndex: Int32;
    PrefixClass: Int32;
    NextInScope: Int32;
    NextInHash: Int32;
    ConstantInt: Int64;
    ConstantReal: Double;
    ConstantString: Int32;
    ForeignIndex: Int32;
  end;


  TForeignConvention = (fcNone, fcCSystemVAMD64);
  TForeignBindingKind = (fbFunction, fbObject);

  TForeignBinding = packed record
    SymbolId: Int32;
    LinkNameId: Int32;
    LibraryNameId: Int32;
    Convention: TForeignConvention;
    Kind: TForeignBindingKind;
    FixedParameterCount: Int16;
    Variadic: Boolean;
    Reserved: Byte;
  end;

  TScope = packed record
    Kind: TScopeKind;
    ParentScope: Int32;
    OwnerSymbol: Int32;
    Level: Int32;
    FirstSymbol: Int32;
    LastSymbol: Int32;
    SymbolCount: Int32;
    HashStart: Int32;
    HashCapacity: Int32;
    LocalSize: UInt32;
    MaximumAlignment: UInt32;
  end;

  TClassInfo = packed record
    SymbolId: Int32;
    PrefixClass: Int32;
    FirstField: Int32;
    FieldCount: Int32;
    FirstMethod: Int32;
    MethodCount: Int32;
    ParameterStart: Int32;
    ParameterCount: Int32;
    InstanceSize: UInt32;
    InstanceAlignment: UInt32;
    VMTSlotCount: UInt32;
    RTTIIndex: UInt32;
    IsProcess: Boolean;
    IsThread: Boolean;
    IsAbstract: Boolean;
    IsFinal: Boolean;
  end;

  TFieldInfo = packed record
    SymbolId: Int32;
    OwnerClass: Int32;
    TypeId: Int32;
    Offset: UInt32;
    Size: UInt32;
    Alignment: UInt32;
    Visibility: TVisibility;
  end;

  TMethodInfo = packed record
    SymbolId: Int32;
    OwnerClass: Int32;
    ProcedureType: Int32;
    VMTSlot: Int32;
    Visibility: TVisibility;
    IsVirtual: Boolean;
    IsOverride: Boolean;
    IsAbstract: Boolean;
    IsFinal: Boolean;
  end;

  TProtectionInfo = packed record
    ClassSymbol: Int32;
    AttributeSymbol: Int32;
    IsProtected: Boolean;
    IsHidden: Boolean;
  end;

  TRTTIEntry = packed record
    NameOffset: UInt32;
    NameLength: UInt32;
    ParentRTTI: Int32;
    InstanceSize: UInt32;
    InstanceAlignment: UInt32;
    VMTSlotCount: UInt32;
    Flags: UInt32;
  end;

  TSymbolTable = record
    Strings: TStringPool;
    Types: array of TTypeInfo;
    Parameters: array of TParameterInfo;
    Symbols: array of TSymbol;
    Scopes: array of TScope;
    HashBuckets: TInt32Array;
    Classes: array of TClassInfo;
    Fields: array of TFieldInfo;
    Methods: array of TMethodInfo;
    Protections: array of TProtectionInfo;
    RTTI: array of TRTTIEntry;
    ForeignBindings: array of TForeignBinding;
    CurrentScope: Int32;
    CurrentClass: Int32;
    CurrentRoutine: Int32;
    Dialect: TFSimDialect;
    Diagnostics: ^TDiagnosticBag;
  end;

procedure SymTableInit(var Table: TSymbolTable; var Diagnostics: TDiagnosticBag;
  Dialect: TFSimDialect = fdFSim);
procedure SymTableClear(var Table: TSymbolTable);
function SymEnterScope(var Table: TSymbolTable; Kind: TScopeKind;
  OwnerSymbol: Int32): Int32;
procedure SymLeaveScope(var Table: TSymbolTable);
function SymAdd(var Table: TSymbolTable; const Name: RawByteString;
  Kind: TSymbolKind; TypeId: Int32; Visibility: TVisibility;
  Flags: TSymbolFlags; DeclNode: Int32; const Span: TSourceSpan): Int32;
function SymLookup(const Table: TSymbolTable; const Name: RawByteString;
  StartScope: Int32 = -1): Int32;
function SymLookupLocal(const Table: TSymbolTable; const Name: RawByteString;
  ScopeId: Int32 = -1): Int32;
function SymLookupClass(const Table: TSymbolTable; const Name: RawByteString): Int32;
function SymLookupMember(const Table: TSymbolTable; ClassSymbol: Int32;
  const Name: RawByteString): Int32;
function SymName(const Table: TSymbolTable; SymbolId: Int32): RawByteString;
function TypeName(const Table: TSymbolTable; TypeId: Int32): RawByteString;
function SymAddType(var Table: TSymbolTable; const Info: TTypeInfo): Int32;
function SymAddForeignBinding(var Table: TSymbolTable; SymbolId: Int32;
  const LinkName, LibraryName: RawByteString; Variadic: Boolean;
  Kind: TForeignBindingKind = fbFunction): Int32;
function SymForeignBinding(const Table: TSymbolTable; SymbolId: Int32): Int32;
function SymMakeReferenceType(var Table: TSymbolTable; ClassSymbol: Int32): Int32;
function SymMakeCPointerType(var Table: TSymbolTable; ElementType: Int32): Int32;
function SymMakeCFunctionType(var Table: TSymbolTable; ReturnType, ParameterStart,
  ParameterCount: Int32; Variadic: Boolean): Int32;
function SymMakeChannelType(var Table: TSymbolTable; ElementType: Int32): Int32;
function SymMakeFutureType(var Table: TSymbolTable; ElementType: Int32): Int32;
function SymMakeArrayType(var Table: TSymbolTable; ElementType: Int32;
  LowerBound, UpperBound: Int64): Int32;
function SymMakeDynamicArrayType(var Table: TSymbolTable;
  ElementType: Int32): Int32;
function SymMakeProcedureType(var Table: TSymbolTable; ReturnType: Int32;
  ParameterStart, ParameterCount: Int32; UnspecifiedSignature: Boolean = False): Int32;
function SymAddParameter(var Table: TSymbolTable; const Name: RawByteString;
  TypeId: Int32; Mode: TPassingMode; SymbolId, DefaultNode: Int32): Int32;
function SymRegisterClass(var Table: TSymbolTable; SymbolId, PrefixClass: Int32;
  IsProcess, IsThread: Boolean): Int32;
procedure SymSetClassParameters(var Table: TSymbolTable; ClassSymbol,
  ParameterStart, ParameterCount: Int32);
function SymClassIndex(const Table: TSymbolTable; ClassSymbol: Int32): Int32;
function SymAddField(var Table: TSymbolTable; ClassSymbol, FieldSymbol,
  TypeId: Int32; Visibility: TVisibility): Int32;
function SymAddMethod(var Table: TSymbolTable; ClassSymbol, MethodSymbol,
  ProcedureType: Int32; Visibility: TVisibility; IsVirtual, IsOverride,
  IsAbstract, IsFinal: Boolean): Int32;
procedure SymFinalizeClass(var Table: TSymbolTable; ClassSymbol: Int32);
function SymIsDerivedFrom(const Table: TSymbolTable; ChildClass,
  ParentClass: Int32): Boolean;
function SymCanAccess(const Table: TSymbolTable; RequestingClass,
  DeclaringClass: Int32; Visibility: TVisibility): Boolean;
function SymAddProtection(var Table: TSymbolTable; ClassSymbol,
  AttributeSymbol: Int32; IsProtected, IsHidden: Boolean): Int32;
function SymCanAccessMember(const Table: TSymbolTable; RequestingClass,
  AttributeSymbol: Int32): Boolean;
function SymTypeEqual(const Table: TSymbolTable; LeftType, RightType: Int32): Boolean;
function SymIsReferenceType(const Table: TSymbolTable; TypeId: Int32): Boolean;
function SymCanConvert(const Table: TSymbolTable; TargetType, SourceType: Int32): Boolean;
function SymIsCABIType(const Table: TSymbolTable; TypeId: Int32;
  AllowVoid: Boolean = False): Boolean;
function SymIsCStorageType(const Table: TSymbolTable; TypeId: Int32): Boolean;
function SymIsCPointeeType(const Table: TSymbolTable; TypeId: Int32): Boolean;
function SymCanCArgumentConvert(const Table: TSymbolTable; TargetType,
  SourceType: Int32): Boolean;
function SymCanAssign(const Table: TSymbolTable; TargetType, SourceType: Int32;
  IsReferenceAssignment: Boolean): Boolean;
function SymCommonType(const Table: TSymbolTable; LeftType,
  RightType: Int32): Int32;
function SymAllocateLocal(var Table: TSymbolTable; SymbolId: Int32): Int32;
function SymSerializeRTTI(var Table: TSymbolTable; var Destination: TByteBuffer): UInt32;
procedure SymDump(const Table: TSymbolTable);
procedure SymVerify(const Table: TSymbolTable);

implementation

function MakeBuiltinType(Kind: TTypeKind; const Name: RawByteString;
  Size, Alignment: UInt32; Flags: TTypeFlags; var Pool: TStringPool): TTypeInfo;
begin
  Result := Default(TTypeInfo);
  Result.Kind := Kind;
  Result.Flags := Flags;
  Result.NameId := StringPoolIntern(Pool, Name);
  Result.Size := Size;
  Result.Alignment := Alignment;
  Result.ElementType := FSIM_TYPE_INVALID;
  Result.ReturnType := FSIM_TYPE_INVALID;
  Result.RefClassSymbol := FSIM_INVALID_INDEX;
  Result.ParameterStart := FSIM_INVALID_INDEX;
  Result.LowerBound := 0;
  Result.UpperBound := -1;
end;

procedure AddBuiltinTypes(var Table: TSymbolTable);
begin
  SetLength(Table.Types, FSIM_FIRST_USER_TYPE);
  Table.Types[FSIM_TYPE_INVALID] := MakeBuiltinType(tyInvalid, '<invalid>', 0, 1,
    [], Table.Strings);
  Table.Types[FSIM_TYPE_VOID] := MakeBuiltinType(tyVoid, 'void', 0, 1,
    [tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_INTEGER] := MakeBuiltinType(tyInteger, 'integer', 8, 8,
    [tfSigned, tfValueType, tfComplete, tfRuntimeVisible], Table.Strings);
  Table.Types[FSIM_TYPE_LONG_INTEGER] := MakeBuiltinType(tyInteger, 'long integer',
    8, 8, [tfSigned, tfValueType, tfComplete, tfRuntimeVisible], Table.Strings);
  Table.Types[FSIM_TYPE_SHORT_INTEGER] := MakeBuiltinType(tyInteger,
    'short integer', 4, 4, [tfSigned, tfValueType, tfComplete,
    tfRuntimeVisible], Table.Strings);
  Table.Types[FSIM_TYPE_REAL] := MakeBuiltinType(tyReal, 'real', 8, 8,
    [tfValueType, tfComplete, tfRuntimeVisible], Table.Strings);
  Table.Types[FSIM_TYPE_BOOLEAN] := MakeBuiltinType(tyBoolean, 'boolean', 1, 1,
    [tfValueType, tfComplete, tfRuntimeVisible], Table.Strings);
  Table.Types[FSIM_TYPE_CHARACTER] := MakeBuiltinType(tyCharacter, 'character', 1,
    1, [tfValueType, tfComplete, tfRuntimeVisible], Table.Strings);
  Table.Types[FSIM_TYPE_TEXT] := MakeBuiltinType(tyText, 'text', 16, 8,
    [tfManaged, tfValueType, tfComplete, tfFixedLength, tfRuntimeVisible],
    Table.Strings);
  Table.Types[FSIM_TYPE_STRING] := MakeBuiltinType(tyString, 'string', 24, 8,
    [tfManaged, tfValueType, tfComplete, tfRuntimeVisible], Table.Strings);
  Table.Types[FSIM_TYPE_HEAD] := MakeBuiltinType(tyHead, 'head', 24, 8,
    [tfReferenceType, tfNullable, tfComplete, tfRuntimeVisible], Table.Strings);
  Table.Types[FSIM_TYPE_LINK] := MakeBuiltinType(tyLink, 'link', 24, 8,
    [tfReferenceType, tfNullable, tfComplete, tfRuntimeVisible], Table.Strings);
  Table.Types[FSIM_TYPE_CHANNEL] := MakeBuiltinType(tyChannel,
    'channel(integer)', 16, 8, [tfReferenceType, tfManaged, tfComplete,
    tfRuntimeVisible], Table.Strings);
  Table.Types[FSIM_TYPE_CHANNEL].ElementType := FSIM_TYPE_INTEGER;
  Table.Types[FSIM_TYPE_MUTEX] := MakeBuiltinType(tyMutex, 'mutex', 8, 8,
    [tfReferenceType, tfManaged, tfComplete, tfRuntimeVisible], Table.Strings);
  Table.Types[FSIM_TYPE_FUTURE] := MakeBuiltinType(tyFuture,
    'future(integer)', 16, 8, [tfReferenceType, tfManaged, tfComplete,
    tfRuntimeVisible], Table.Strings);
  Table.Types[FSIM_TYPE_FUTURE].ElementType := FSIM_TYPE_INTEGER;
  Table.Types[FSIM_TYPE_SEMAPHORE] := MakeBuiltinType(tySemaphore,
    'semaphore', 16, 8, [tfReferenceType, tfManaged, tfComplete,
    tfRuntimeVisible], Table.Strings);
  Table.Types[FSIM_TYPE_BARRIER] := MakeBuiltinType(tyBarrier,
    'barrier', 24, 8, [tfReferenceType, tfManaged, tfComplete,
    tfRuntimeVisible], Table.Strings);
  Table.Types[FSIM_TYPE_CONDITION] := MakeBuiltinType(tyCondition,
    'condition', 16, 8, [tfReferenceType, tfManaged, tfComplete,
    tfRuntimeVisible], Table.Strings);
  Table.Types[FSIM_TYPE_ATOMIC] := MakeBuiltinType(tyAtomic,
    'atomic(integer)', 8, 8, [tfReferenceType, tfManaged, tfComplete,
    tfRuntimeVisible], Table.Strings);
  Table.Types[FSIM_TYPE_ATOMIC].ElementType := FSIM_TYPE_INTEGER;

  Table.Types[FSIM_TYPE_C_CHAR] := MakeBuiltinType(tyCInteger, 'c_char', 1, 1,
    [tfSigned, tfValueType, tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_C_SCHAR] := MakeBuiltinType(tyCInteger, 'c_schar', 1, 1,
    [tfSigned, tfValueType, tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_C_UCHAR] := MakeBuiltinType(tyCInteger, 'c_uchar', 1, 1,
    [tfValueType, tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_C_SHORT] := MakeBuiltinType(tyCInteger, 'c_short', 2, 2,
    [tfSigned, tfValueType, tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_C_USHORT] := MakeBuiltinType(tyCInteger, 'c_ushort', 2, 2,
    [tfValueType, tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_C_INT] := MakeBuiltinType(tyCInteger, 'c_int', 4, 4,
    [tfSigned, tfValueType, tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_C_UINT] := MakeBuiltinType(tyCInteger, 'c_uint', 4, 4,
    [tfValueType, tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_C_LONG] := MakeBuiltinType(tyCInteger, 'c_long', 8, 8,
    [tfSigned, tfValueType, tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_C_ULONG] := MakeBuiltinType(tyCInteger, 'c_ulong', 8, 8,
    [tfValueType, tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_C_LONGLONG] := MakeBuiltinType(tyCInteger, 'c_longlong', 8, 8,
    [tfSigned, tfValueType, tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_C_ULONGLONG] := MakeBuiltinType(tyCInteger, 'c_ulonglong', 8, 8,
    [tfValueType, tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_C_SIZE] := MakeBuiltinType(tyCInteger, 'c_size', 8, 8,
    [tfValueType, tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_C_SSIZE] := MakeBuiltinType(tyCInteger, 'c_ssize', 8, 8,
    [tfSigned, tfValueType, tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_C_INTPTR] := MakeBuiltinType(tyCInteger, 'c_intptr', 8, 8,
    [tfSigned, tfValueType, tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_C_UINTPTR] := MakeBuiltinType(tyCInteger, 'c_uintptr', 8, 8,
    [tfValueType, tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_C_FLOAT] := MakeBuiltinType(tyCReal, 'c_float', 4, 4,
    [tfValueType, tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_C_DOUBLE] := MakeBuiltinType(tyCReal, 'c_double', 8, 8,
    [tfValueType, tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_C_BOOL] := MakeBuiltinType(tyCInteger, 'c_bool', 1, 1,
    [tfValueType, tfComplete], Table.Strings);
  Table.Types[FSIM_TYPE_C_PTR] := MakeBuiltinType(tyCPointer, 'c_ptr', 8, 8,
    [tfValueType, tfComplete, tfNullable], Table.Strings);
  Table.Types[FSIM_TYPE_C_STRING] := MakeBuiltinType(tyCPointer, 'c_string', 8, 8,
    [tfValueType, tfComplete, tfNullable], Table.Strings);
  Table.Types[FSIM_TYPE_C_STRING].ElementType := FSIM_TYPE_C_CHAR;
  Table.Types[FSIM_TYPE_C_FN] := MakeBuiltinType(tyCFunction, 'c_fn', 8, 8,
    [tfValueType, tfComplete, tfNullable, tfCallable], Table.Strings);
end;

function AddBuiltinClass(var Table: TSymbolTable;
  const Name: RawByteString; PrefixClass: Int32; IsProcess: Boolean): Int32;
var
  Span: TSourceSpan;
  Kind: TSymbolKind;
begin
  Span := Default(TSourceSpan);
  if IsProcess then Kind := skProcessClass else Kind := skClass;
  Result := SymAdd(Table, Name, Kind, FSIM_TYPE_INVALID,
    visPublic, [sfDefined, sfRuntimeRequired, sfSynthetic],
    FSIM_INVALID_INDEX, Span);
  if Result >= 0 then
    SymRegisterClass(Table, Result, PrefixClass, IsProcess, False);
end;

function AddBuiltinField(var Table: TSymbolTable; ClassSymbol: Int32;
  const Name: RawByteString; TypeId: Int32): Int32;
var
  Span: TSourceSpan;
begin
  Span := Default(TSourceSpan);
  Result := SymAdd(Table, Name, skField, TypeId, visPrivate,
    [sfMutable, sfSynthetic], FSIM_INVALID_INDEX, Span);
  if Result >= 0 then
    SymAddField(Table, ClassSymbol, Result, TypeId, visPrivate);
end;

function AddPublicBuiltinField(var Table: TSymbolTable; ClassSymbol: Int32;
  const Name: RawByteString; TypeId: Int32): Int32;
var
  Span: TSourceSpan;
begin
  Span := Default(TSourceSpan);
  Result := SymAdd(Table, Name, skField, TypeId, visPublic,
    [sfMutable, sfSynthetic], FSIM_INVALID_INDEX, Span);
  if Result >= 0 then
    SymAddField(Table, ClassSymbol, Result, TypeId, visPublic);
end;

function AddBuiltinRoutine(var Table: TSymbolTable; const Name: RawByteString;
  ReturnType: Int32; const ParameterTypes: array of Int32): Int32;
var
  Span: TSourceSpan;
  ParameterStart, I, ProcedureType: Int32;
  Kind: TSymbolKind;
begin
  Span := Default(TSourceSpan);
  ParameterStart := Length(Table.Parameters);
  for I := 0 to High(ParameterTypes) do
    SymAddParameter(Table, '$arg' + IntToStr(I + 1), ParameterTypes[I],
      pmValue, FSIM_INVALID_INDEX, FSIM_INVALID_INDEX);
  ProcedureType := SymMakeProcedureType(Table, ReturnType,
    ParameterStart, Length(ParameterTypes));
  if ReturnType = FSIM_TYPE_VOID then Kind := skProcedure else Kind := skFunction;
  Result := SymAdd(Table, Name, Kind, ProcedureType, visPublic,
    [sfDefined, sfNative, sfSynthetic, sfRuntimeRequired],
    FSIM_INVALID_INDEX, Span);
end;

function AddBuiltinMethod(var Table: TSymbolTable; ClassSymbol: Int32;
  const Name: RawByteString; ReturnType: Int32;
  const ParameterTypes: array of Int32): Int32;
var
  Span: TSourceSpan;
  ParameterStart, I, ProcedureType: Int32;
  Kind: TSymbolKind;
begin
  Span := Default(TSourceSpan);
  ParameterStart := Length(Table.Parameters);
  for I := 0 to High(ParameterTypes) do
    SymAddParameter(Table, '$arg' + IntToStr(I + 1), ParameterTypes[I],
      pmValue, FSIM_INVALID_INDEX, FSIM_INVALID_INDEX);
  ProcedureType := SymMakeProcedureType(Table, ReturnType,
    ParameterStart, Length(ParameterTypes));
  if ReturnType = FSIM_TYPE_VOID then Kind := skProcedure else Kind := skFunction;
  Result := SymAdd(Table, Name, Kind, ProcedureType, visPublic,
    [sfDefined, sfNative, sfSynthetic], FSIM_INVALID_INDEX, Span);
  if Result >= 0 then
    SymAddMethod(Table, ClassSymbol, Result, ProcedureType,
      visPublic, False, False, False, False);
end;

procedure AddSimulaSystemClasses(var Table: TSymbolTable);
var
  SavedScope, ClassScope: Int32;
  LinkClass, HeadClass, SimsetClass, ProcessClass, SimulationClass: Int32;
  LinkRef, HeadRef, ProcessRef: Int32;

  procedure EnterClass(ClassSymbol: Int32);
  begin
    ClassScope := SymEnterScope(Table, scClass, ClassSymbol);
    Table.CurrentClass := ClassSymbol;
  end;

  procedure LeaveClass;
  begin
    SymLeaveScope(Table);
    Table.CurrentClass := FSIM_INVALID_INDEX;
  end;

begin
  SavedScope := Table.CurrentScope;

  LinkClass := AddBuiltinClass(Table, 'link', FSIM_INVALID_INDEX, False);
  EnterClass(LinkClass);
  LinkRef := SymMakeReferenceType(Table, LinkClass);
  AddBuiltinField(Table, LinkClass, '$suc', LinkRef);
  AddBuiltinField(Table, LinkClass, '$pred', LinkRef);
  AddBuiltinField(Table, LinkClass, '$head', FSIM_TYPE_HEAD);
  AddBuiltinMethod(Table, LinkClass, 'suc', LinkRef, []);
  AddBuiltinMethod(Table, LinkClass, 'pred', LinkRef, []);
  AddBuiltinMethod(Table, LinkClass, 'out', FSIM_TYPE_VOID, []);
  AddBuiltinMethod(Table, LinkClass, 'follow', FSIM_TYPE_VOID, [LinkRef]);
  AddBuiltinMethod(Table, LinkClass, 'precede', FSIM_TYPE_VOID, [LinkRef]);
  LeaveClass;
  SymFinalizeClass(Table, LinkClass);

  HeadClass := AddBuiltinClass(Table, 'head', FSIM_INVALID_INDEX, False);
  EnterClass(HeadClass);
  HeadRef := SymMakeReferenceType(Table, HeadClass);
  AddBuiltinField(Table, HeadClass, '$first', LinkRef);
  AddBuiltinField(Table, HeadClass, '$last', LinkRef);
  AddBuiltinField(Table, HeadClass, '$cardinal', FSIM_TYPE_INTEGER);
  AddBuiltinMethod(Table, HeadClass, 'first', LinkRef, []);
  AddBuiltinMethod(Table, HeadClass, 'last', LinkRef, []);
  AddBuiltinMethod(Table, HeadClass, 'empty', FSIM_TYPE_BOOLEAN, []);
  AddBuiltinMethod(Table, HeadClass, 'cardinal', FSIM_TYPE_INTEGER, []);
  AddBuiltinMethod(Table, HeadClass, 'clear', FSIM_TYPE_VOID, []);
  LeaveClass;
  SymFinalizeClass(Table, HeadClass);

  { into is declared after head exists, but remains a member of link. }
  ClassScope := SymEnterScope(Table, scClass, LinkClass);
  Table.CurrentClass := LinkClass;
  AddBuiltinMethod(Table, LinkClass, 'into', FSIM_TYPE_VOID, [HeadRef]);
  LeaveClass;

  SimsetClass := AddBuiltinClass(Table, 'simset', FSIM_INVALID_INDEX, False);
  EnterClass(SimsetClass);
  LeaveClass;
  SymFinalizeClass(Table, SimsetClass);

  ProcessClass := AddBuiltinClass(Table, 'process', LinkClass, True);
  EnterClass(ProcessClass);
  ProcessRef := SymMakeReferenceType(Table, ProcessClass);
  AddBuiltinField(Table, ProcessClass, '$event_time', FSIM_TYPE_REAL);
  AddBuiltinField(Table, ProcessClass, '$process_state', FSIM_TYPE_INTEGER);
  AddBuiltinField(Table, ProcessClass, '$terminated', FSIM_TYPE_BOOLEAN);
  AddBuiltinMethod(Table, ProcessClass, 'idle', FSIM_TYPE_BOOLEAN, []);
  AddBuiltinMethod(Table, ProcessClass, 'terminated', FSIM_TYPE_BOOLEAN, []);
  AddBuiltinMethod(Table, ProcessClass, 'evtime', FSIM_TYPE_REAL, []);
  AddBuiltinMethod(Table, ProcessClass, 'nextev', ProcessRef, []);
  LeaveClass;
  SymFinalizeClass(Table, ProcessClass);

  SimulationClass := AddBuiltinClass(Table, 'simulation', SimsetClass, False);
  EnterClass(SimulationClass);
  AddBuiltinField(Table, SimulationClass, '$current_time', FSIM_TYPE_REAL);
  AddBuiltinField(Table, SimulationClass, '$current_process', ProcessRef);
  AddBuiltinField(Table, SimulationClass, '$sequencing_set', HeadRef);
  AddBuiltinMethod(Table, SimulationClass, 'time', FSIM_TYPE_REAL, []);
  AddBuiltinMethod(Table, SimulationClass, 'current', ProcessRef, []);
  AddBuiltinMethod(Table, SimulationClass, 'hold', FSIM_TYPE_VOID,
    [FSIM_TYPE_REAL]);
  AddBuiltinMethod(Table, SimulationClass, 'passivate', FSIM_TYPE_VOID, []);
  AddBuiltinMethod(Table, SimulationClass, 'wait', FSIM_TYPE_VOID, [HeadRef]);
  AddBuiltinMethod(Table, SimulationClass, 'cancel', FSIM_TYPE_VOID,
    [ProcessRef]);
  LeaveClass;
  SymFinalizeClass(Table, SimulationClass);

  Table.CurrentScope := SavedScope;
  Table.CurrentClass := FSIM_INVALID_INDEX;
end;

procedure AddSimula67BasicIO(var Table: TSymbolTable);
var
  SavedScope, FileClass, InFileClass, OutFileClass, PrintFileClass: Int32;
  InFileRef, PrintFileRef: Int32;

  procedure EnterClass(ClassSymbol: Int32);
  begin
    SymEnterScope(Table, scClass, ClassSymbol);
    Table.CurrentClass := ClassSymbol;
  end;

  procedure LeaveClass;
  begin
    SymLeaveScope(Table);
    Table.CurrentClass := FSIM_INVALID_INDEX;
  end;

begin
  SavedScope := Table.CurrentScope;

  FileClass := AddBuiltinClass(Table, 'file', FSIM_INVALID_INDEX, False);
  EnterClass(FileClass);
  AddPublicBuiltinField(Table, FileClass, 'image', FSIM_TYPE_TEXT);
  AddBuiltinMethod(Table, FileClass, 'open', FSIM_TYPE_BOOLEAN, [FSIM_TYPE_TEXT]);
  AddBuiltinMethod(Table, FileClass, 'close', FSIM_TYPE_BOOLEAN, []);
  AddBuiltinMethod(Table, FileClass, 'isopen', FSIM_TYPE_BOOLEAN, []);
  LeaveClass;
  SymFinalizeClass(Table, FileClass);

  InFileClass := AddBuiltinClass(Table, 'infile', FileClass, False);
  EnterClass(InFileClass);
  AddBuiltinMethod(Table, InFileClass, 'inimage', FSIM_TYPE_VOID, []);
  AddBuiltinMethod(Table, InFileClass, 'inchar', FSIM_TYPE_CHARACTER, []);
  AddBuiltinMethod(Table, InFileClass, 'inint', FSIM_TYPE_INTEGER, []);
  AddBuiltinMethod(Table, InFileClass, 'inreal', FSIM_TYPE_REAL, []);
  AddBuiltinMethod(Table, InFileClass, 'infrac', FSIM_TYPE_INTEGER, []);
  AddBuiltinMethod(Table, InFileClass, 'intext', FSIM_TYPE_TEXT,
    [FSIM_TYPE_INTEGER]);
  AddBuiltinMethod(Table, InFileClass, 'lastitem', FSIM_TYPE_BOOLEAN, []);
  AddBuiltinMethod(Table, InFileClass, 'endfile', FSIM_TYPE_BOOLEAN, []);
  LeaveClass;
  SymFinalizeClass(Table, InFileClass);

  OutFileClass := AddBuiltinClass(Table, 'outfile', FileClass, False);
  EnterClass(OutFileClass);
  AddBuiltinMethod(Table, OutFileClass, 'outimage', FSIM_TYPE_VOID, []);
  AddBuiltinMethod(Table, OutFileClass, 'outchar', FSIM_TYPE_VOID,
    [FSIM_TYPE_CHARACTER]);
  AddBuiltinMethod(Table, OutFileClass, 'outtext', FSIM_TYPE_VOID,
    [FSIM_TYPE_TEXT]);
  AddBuiltinMethod(Table, OutFileClass, 'outint', FSIM_TYPE_VOID,
    [FSIM_TYPE_INTEGER, FSIM_TYPE_INTEGER]);
  AddBuiltinMethod(Table, OutFileClass, 'outfix', FSIM_TYPE_VOID,
    [FSIM_TYPE_REAL, FSIM_TYPE_INTEGER, FSIM_TYPE_INTEGER]);
  AddBuiltinMethod(Table, OutFileClass, 'outreal', FSIM_TYPE_VOID,
    [FSIM_TYPE_REAL, FSIM_TYPE_INTEGER, FSIM_TYPE_INTEGER]);
  AddBuiltinMethod(Table, OutFileClass, 'outfrac', FSIM_TYPE_VOID,
    [FSIM_TYPE_INTEGER, FSIM_TYPE_INTEGER, FSIM_TYPE_INTEGER]);
  AddBuiltinMethod(Table, OutFileClass, 'field', FSIM_TYPE_TEXT,
    [FSIM_TYPE_INTEGER]);
  LeaveClass;
  SymFinalizeClass(Table, OutFileClass);

  PrintFileClass := AddBuiltinClass(Table, 'printfile', OutFileClass, False);
  EnterClass(PrintFileClass);
  AddBuiltinMethod(Table, PrintFileClass, 'line', FSIM_TYPE_INTEGER, []);
  AddBuiltinMethod(Table, PrintFileClass, 'linesperpage', FSIM_TYPE_INTEGER, []);
  AddBuiltinMethod(Table, PrintFileClass, 'spacing', FSIM_TYPE_INTEGER,
    [FSIM_TYPE_INTEGER]);
  AddBuiltinMethod(Table, PrintFileClass, 'eject', FSIM_TYPE_VOID,
    [FSIM_TYPE_INTEGER]);
  LeaveClass;
  SymFinalizeClass(Table, PrintFileClass);

  InFileRef := SymMakeReferenceType(Table, InFileClass);
  PrintFileRef := SymMakeReferenceType(Table, PrintFileClass);
  { The BASICIO classes are useful compatibility types in fsim mode, but the
    implicit SIMULA 67 environment (sysin/sysout/blanks/math globals) remains
    strict-mode-only.  This keeps modern modules from acquiring invisible
    legacy globals while still allowing explicit Ref(InFile), Ref(PrintFile),
    Link/Head/Process compatibility. }
  if Table.Dialect = fdSimula67 then
  begin
    AddBuiltinRoutine(Table, 'sysin', InFileRef, []);
    AddBuiltinRoutine(Table, 'sysout', PrintFileRef, []);

    AddBuiltinRoutine(Table, 'blanks', FSIM_TYPE_TEXT, [FSIM_TYPE_INTEGER]);
    AddBuiltinRoutine(Table, 'copy', FSIM_TYPE_TEXT, [FSIM_TYPE_TEXT]);
    AddBuiltinRoutine(Table, 'char', FSIM_TYPE_CHARACTER, [FSIM_TYPE_INTEGER]);
    AddBuiltinRoutine(Table, 'isochar', FSIM_TYPE_CHARACTER, [FSIM_TYPE_INTEGER]);
    AddBuiltinRoutine(Table, 'rank', FSIM_TYPE_INTEGER, [FSIM_TYPE_CHARACTER]);
    AddBuiltinRoutine(Table, 'isorank', FSIM_TYPE_INTEGER, [FSIM_TYPE_CHARACTER]);
    AddBuiltinRoutine(Table, 'digit', FSIM_TYPE_BOOLEAN, [FSIM_TYPE_CHARACTER]);
    AddBuiltinRoutine(Table, 'letter', FSIM_TYPE_BOOLEAN, [FSIM_TYPE_CHARACTER]);
    AddBuiltinRoutine(Table, 'lowten', FSIM_TYPE_CHARACTER, [FSIM_TYPE_CHARACTER]);
    AddBuiltinRoutine(Table, 'decimalmark', FSIM_TYPE_CHARACTER,
      [FSIM_TYPE_CHARACTER]);
    AddBuiltinRoutine(Table, 'upcase', FSIM_TYPE_TEXT, [FSIM_TYPE_TEXT]);
    AddBuiltinRoutine(Table, 'lowcase', FSIM_TYPE_TEXT, [FSIM_TYPE_TEXT]);
    AddBuiltinRoutine(Table, 'mod', FSIM_TYPE_INTEGER,
      [FSIM_TYPE_INTEGER, FSIM_TYPE_INTEGER]);
    AddBuiltinRoutine(Table, 'rem', FSIM_TYPE_INTEGER,
      [FSIM_TYPE_INTEGER, FSIM_TYPE_INTEGER]);
    AddBuiltinRoutine(Table, 'entier', FSIM_TYPE_INTEGER, [FSIM_TYPE_REAL]);
    AddBuiltinRoutine(Table, 'addepsilon', FSIM_TYPE_REAL, [FSIM_TYPE_REAL]);
    AddBuiltinRoutine(Table, 'subepsilon', FSIM_TYPE_REAL, [FSIM_TYPE_REAL]);
    AddBuiltinRoutine(Table, 'sqrt', FSIM_TYPE_REAL, [FSIM_TYPE_REAL]);
    AddBuiltinRoutine(Table, 'sin', FSIM_TYPE_REAL, [FSIM_TYPE_REAL]);
    AddBuiltinRoutine(Table, 'cos', FSIM_TYPE_REAL, [FSIM_TYPE_REAL]);
    AddBuiltinRoutine(Table, 'tan', FSIM_TYPE_REAL, [FSIM_TYPE_REAL]);
    AddBuiltinRoutine(Table, 'arctan', FSIM_TYPE_REAL, [FSIM_TYPE_REAL]);
    AddBuiltinRoutine(Table, 'ln', FSIM_TYPE_REAL, [FSIM_TYPE_REAL]);
    AddBuiltinRoutine(Table, 'log10', FSIM_TYPE_REAL, [FSIM_TYPE_REAL]);
    AddBuiltinRoutine(Table, 'exp', FSIM_TYPE_REAL, [FSIM_TYPE_REAL]);
  end;

  Table.CurrentScope := SavedScope;
  Table.CurrentClass := FSIM_INVALID_INDEX;
end;

procedure AddFSimNativeEnvironment(var Table: TSymbolTable);
  procedure AddCType(const Name: RawByteString; TypeId: Int32);
  var
    Span: TSourceSpan;
  begin
    Span := Default(TSourceSpan);
    SymAdd(Table, Name, skType, TypeId, visPublic,
      [sfDefined, sfSynthetic, sfFinal], FSIM_INVALID_INDEX, Span);
  end;
begin
  AddCType('c_void', FSIM_TYPE_VOID);
  AddCType('c_char', FSIM_TYPE_C_CHAR);
  AddCType('c_schar', FSIM_TYPE_C_SCHAR);
  AddCType('c_uchar', FSIM_TYPE_C_UCHAR);
  AddCType('c_short', FSIM_TYPE_C_SHORT);
  AddCType('c_ushort', FSIM_TYPE_C_USHORT);
  AddCType('c_int', FSIM_TYPE_C_INT);
  AddCType('c_uint', FSIM_TYPE_C_UINT);
  AddCType('c_long', FSIM_TYPE_C_LONG);
  AddCType('c_ulong', FSIM_TYPE_C_ULONG);
  AddCType('c_longlong', FSIM_TYPE_C_LONGLONG);
  AddCType('c_ulonglong', FSIM_TYPE_C_ULONGLONG);
  AddCType('c_size', FSIM_TYPE_C_SIZE);
  AddCType('c_ssize', FSIM_TYPE_C_SSIZE);
  AddCType('c_intptr', FSIM_TYPE_C_INTPTR);
  AddCType('c_uintptr', FSIM_TYPE_C_UINTPTR);
  AddCType('c_float', FSIM_TYPE_C_FLOAT);
  AddCType('c_double', FSIM_TYPE_C_DOUBLE);
  AddCType('c_bool', FSIM_TYPE_C_BOOL);
  AddCType('c_ptr', FSIM_TYPE_C_PTR);
  AddCType('c_string', FSIM_TYPE_C_STRING);
  AddCType('c_fn', FSIM_TYPE_C_FN);
  { Small systems surface for native fsim programs.  Keep this out of the
    Simula 67 environment; old code should never see modern OS names. }
  AddBuiltinRoutine(Table, 'os_argc', FSIM_TYPE_INTEGER, []);
  AddBuiltinRoutine(Table, 'os_argv', FSIM_TYPE_STRING, [FSIM_TYPE_INTEGER]);
  AddBuiltinRoutine(Table, 'os_dir_open', FSIM_TYPE_INTEGER, [FSIM_TYPE_STRING]);
  AddBuiltinRoutine(Table, 'os_dir_open_at', FSIM_TYPE_INTEGER,
    [FSIM_TYPE_INTEGER, FSIM_TYPE_STRING]);
  AddBuiltinRoutine(Table, 'os_dir_next', FSIM_TYPE_STRING, [FSIM_TYPE_INTEGER]);
  AddBuiltinRoutine(Table, 'os_dir_type', FSIM_TYPE_INTEGER, [FSIM_TYPE_INTEGER]);
  AddBuiltinRoutine(Table, 'os_dir_close', FSIM_TYPE_VOID, [FSIM_TYPE_INTEGER]);
  AddBuiltinRoutine(Table, 'os_path_type', FSIM_TYPE_INTEGER, [FSIM_TYPE_STRING]);
  AddBuiltinRoutine(Table, 'os_path_size', FSIM_TYPE_INTEGER, [FSIM_TYPE_STRING]);
  AddBuiltinRoutine(Table, 'os_path_join', FSIM_TYPE_STRING,
    [FSIM_TYPE_STRING, FSIM_TYPE_STRING]);
  AddBuiltinRoutine(Table, 'os_path_basename', FSIM_TYPE_STRING,
    [FSIM_TYPE_STRING]);
  AddBuiltinRoutine(Table, 'os_write_path', FSIM_TYPE_VOID,
    [FSIM_TYPE_STRING, FSIM_TYPE_STRING, FSIM_TYPE_BOOLEAN]);
  AddBuiltinRoutine(Table, 'os_stderr_write', FSIM_TYPE_VOID,
    [FSIM_TYPE_STRING]);

  { Managed heap controls.  gc_live_bytes reports the live payload measured
    by the most recently completed collection. }
  AddBuiltinRoutine(Table, 'gc_collect', FSIM_TYPE_INTEGER, []);
  AddBuiltinRoutine(Table, 'gc_pin', FSIM_TYPE_BOOLEAN, [FSIM_TYPE_C_PTR]);
  AddBuiltinRoutine(Table, 'gc_unpin', FSIM_TYPE_BOOLEAN, [FSIM_TYPE_C_PTR]);
  AddBuiltinRoutine(Table, 'gc_live_bytes', FSIM_TYPE_INTEGER, []);
  AddBuiltinRoutine(Table, 'gc_reclaimed_bytes', FSIM_TYPE_INTEGER, []);
  AddBuiltinRoutine(Table, 'gc_collection_count', FSIM_TYPE_INTEGER, []);
  AddBuiltinRoutine(Table, 'gc_last_pause_ns', FSIM_TYPE_INTEGER, []);
  AddBuiltinRoutine(Table, 'gc_max_pause_ns', FSIM_TYPE_INTEGER, []);
  AddBuiltinRoutine(Table, 'gc_total_pause_ns', FSIM_TYPE_INTEGER, []);

  AddBuiltinRoutine(Table, 'atomic_load', FSIM_TYPE_INTEGER,
    [FSIM_TYPE_ATOMIC]);
  AddBuiltinRoutine(Table, 'atomic_store', FSIM_TYPE_VOID,
    [FSIM_TYPE_ATOMIC, FSIM_TYPE_INTEGER]);
  AddBuiltinRoutine(Table, 'atomic_exchange', FSIM_TYPE_INTEGER,
    [FSIM_TYPE_ATOMIC, FSIM_TYPE_INTEGER]);
  AddBuiltinRoutine(Table, 'atomic_compare_exchange', FSIM_TYPE_BOOLEAN,
    [FSIM_TYPE_ATOMIC, FSIM_TYPE_INTEGER, FSIM_TYPE_INTEGER]);
  AddBuiltinRoutine(Table, 'atomic_fetch_add', FSIM_TYPE_INTEGER,
    [FSIM_TYPE_ATOMIC, FSIM_TYPE_INTEGER]);
  AddBuiltinRoutine(Table, 'atomic_fetch_sub', FSIM_TYPE_INTEGER,
    [FSIM_TYPE_ATOMIC, FSIM_TYPE_INTEGER]);

  AddBuiltinRoutine(Table, 'mutex_try_lock', FSIM_TYPE_BOOLEAN,
    [FSIM_TYPE_MUTEX]);
  AddBuiltinRoutine(Table, 'semaphore_init', FSIM_TYPE_VOID,
    [FSIM_TYPE_SEMAPHORE, FSIM_TYPE_INTEGER]);
  AddBuiltinRoutine(Table, 'semaphore_wait', FSIM_TYPE_VOID,
    [FSIM_TYPE_SEMAPHORE]);
  AddBuiltinRoutine(Table, 'semaphore_try_wait', FSIM_TYPE_BOOLEAN,
    [FSIM_TYPE_SEMAPHORE]);
  AddBuiltinRoutine(Table, 'semaphore_post', FSIM_TYPE_VOID,
    [FSIM_TYPE_SEMAPHORE]);
  AddBuiltinRoutine(Table, 'barrier_init', FSIM_TYPE_VOID,
    [FSIM_TYPE_BARRIER, FSIM_TYPE_INTEGER]);
  AddBuiltinRoutine(Table, 'barrier_wait', FSIM_TYPE_BOOLEAN,
    [FSIM_TYPE_BARRIER]);
  AddBuiltinRoutine(Table, 'condition_wait', FSIM_TYPE_VOID,
    [FSIM_TYPE_CONDITION, FSIM_TYPE_MUTEX]);
  AddBuiltinRoutine(Table, 'condition_signal', FSIM_TYPE_VOID,
    [FSIM_TYPE_CONDITION]);
  AddBuiltinRoutine(Table, 'condition_broadcast', FSIM_TYPE_VOID,
    [FSIM_TYPE_CONDITION]);
  AddBuiltinRoutine(Table, 'future_ready', FSIM_TYPE_BOOLEAN,
    [FSIM_TYPE_FUTURE]);
  AddBuiltinRoutine(Table, 'future_cancel_requested', FSIM_TYPE_BOOLEAN,
    [FSIM_TYPE_FUTURE]);
  AddBuiltinRoutine(Table, 'future_state', FSIM_TYPE_INTEGER,
    [FSIM_TYPE_FUTURE]);
  AddBuiltinRoutine(Table, 'future_thread_id', FSIM_TYPE_INTEGER,
    [FSIM_TYPE_FUTURE]);
  AddBuiltinRoutine(Table, 'thread_id', FSIM_TYPE_INTEGER, []);
  AddBuiltinRoutine(Table, 'monotonic_ns', FSIM_TYPE_INTEGER, []);
  AddBuiltinRoutine(Table, 'sleep_ns', FSIM_TYPE_VOID, [FSIM_TYPE_INTEGER]);
end;

procedure SymTableInit(var Table: TSymbolTable; var Diagnostics: TDiagnosticBag;
  Dialect: TFSimDialect);
begin
  Table := Default(TSymbolTable);
  Table.CurrentScope := FSIM_INVALID_INDEX;
  BufferInit(Table.Strings.Bytes, 4096);
  Table.Diagnostics := @Diagnostics;
  Table.Dialect := Dialect;
  AddBuiltinTypes(Table);
  SymEnterScope(Table, scGlobal, FSIM_INVALID_INDEX);
  Table.CurrentClass := FSIM_INVALID_INDEX;
  Table.CurrentRoutine := FSIM_INVALID_INDEX;
  if Dialect = fdSimula67 then
  begin
    AddSimulaSystemClasses(Table);
    AddSimula67BasicIO(Table);
  end
  else
  begin
    { fsim is a superset, not a separate universe: classic LINK/HEAD,
      PROCESS/SIMULATION and BASICIO stay visible alongside modern natives. }
    AddSimulaSystemClasses(Table);
    AddSimula67BasicIO(Table);
    AddFSimNativeEnvironment(Table);
  end;
end;

procedure SymTableClear(var Table: TSymbolTable);
begin
  SetLength(Table.Types, 0);
  SetLength(Table.Parameters, 0);
  SetLength(Table.Symbols, 0);
  SetLength(Table.Scopes, 0);
  SetLength(Table.HashBuckets, 0);
  SetLength(Table.Classes, 0);
  SetLength(Table.Fields, 0);
  SetLength(Table.Methods, 0);
  SetLength(Table.Protections, 0);
  SetLength(Table.RTTI, 0);
  SetLength(Table.ForeignBindings, 0);
  SetLength(Table.Strings.Entries, 0);
  BufferClear(Table.Strings.Bytes);
  Table.CurrentScope := FSIM_INVALID_INDEX;
  Table.CurrentClass := FSIM_INVALID_INDEX;
  Table.CurrentRoutine := FSIM_INVALID_INDEX;
end;

function ScopeBucketIndex(const Table: TSymbolTable; ScopeId: Int32;
  Hash: UInt32): Int32; inline;
begin
  Result := Table.Scopes[ScopeId].HashStart +
    Int32(Hash and UInt32(Table.Scopes[ScopeId].HashCapacity - 1));
end;

function SymEnterScope(var Table: TSymbolTable; Kind: TScopeKind;
  OwnerSymbol: Int32): Int32;
const
  INITIAL_BUCKETS = 32;
var
  N, HashStart: Integer;
begin
  N := Length(Table.Scopes);
  SetLength(Table.Scopes, N + 1);
  Table.Scopes[N] := Default(TScope);
  Table.Scopes[N].Kind := Kind;
  Table.Scopes[N].ParentScope := Table.CurrentScope;
  Table.Scopes[N].OwnerSymbol := OwnerSymbol;
  if Table.CurrentScope >= 0 then
    Table.Scopes[N].Level := Table.Scopes[Table.CurrentScope].Level + 1
  else
    Table.Scopes[N].Level := 0;
  Table.Scopes[N].FirstSymbol := FSIM_INVALID_INDEX;
  Table.Scopes[N].LastSymbol := FSIM_INVALID_INDEX;
  Table.Scopes[N].MaximumAlignment := 1;
  HashStart := Length(Table.HashBuckets);
  SetLength(Table.HashBuckets, HashStart + INITIAL_BUCKETS);
  FillChar(Table.HashBuckets[HashStart], INITIAL_BUCKETS * SizeOf(Int32), $FF);
  Table.Scopes[N].HashStart := HashStart;
  Table.Scopes[N].HashCapacity := INITIAL_BUCKETS;
  Table.CurrentScope := N;
  Result := N;
end;

procedure SymLeaveScope(var Table: TSymbolTable);
begin
  if Table.CurrentScope < 0 then
    raise EInvalidOp.Create('cannot leave an absent scope');
  Table.CurrentScope := Table.Scopes[Table.CurrentScope].ParentScope;
end;

function IdentifierHash(const Table: TSymbolTable;
  const Name: RawByteString): UInt32; inline;
begin
  if Table.Dialect = fdSimula67 then
    Result := HashString(LowerASCII(Name))
  else
    Result := HashString(Name);
end;

function IdentifierEqual(const Table: TSymbolTable;
  const Left, Right: RawByteString): Boolean; inline;
begin
  if Table.Dialect = fdSimula67 then
    Result := ASCIIEqualFold(Left, Right)
  else
    Result := Left = Right;
end;

function SymbolNameMatches(const Table: TSymbolTable; SymbolId: Int32;
  const Name: RawByteString; Hash: UInt32): Boolean;
begin
  Result := (Table.Symbols[SymbolId].Hash = Hash) and
    IdentifierEqual(Table,
      StringPoolGet(Table.Strings, Table.Symbols[SymbolId].NameId), Name);
end;

function SymLookupLocal(const Table: TSymbolTable; const Name: RawByteString;
  ScopeId: Int32): Int32;
var
  Hash: UInt32;
  Bucket: Int32;
  SymbolId: Int32;
begin
  if ScopeId < 0 then
    ScopeId := Table.CurrentScope;
  if (ScopeId < 0) or (ScopeId > High(Table.Scopes)) then
    Exit(FSIM_INVALID_INDEX);
  Hash := IdentifierHash(Table, Name);
  Bucket := ScopeBucketIndex(Table, ScopeId, Hash);
  SymbolId := Table.HashBuckets[Bucket];
  while SymbolId <> FSIM_INVALID_INDEX do
  begin
    if SymbolNameMatches(Table, SymbolId, Name, Hash) then
      Exit(SymbolId);
    SymbolId := Table.Symbols[SymbolId].NextInHash;
  end;
  Result := FSIM_INVALID_INDEX;
end;

function SymLookup(const Table: TSymbolTable; const Name: RawByteString;
  StartScope: Int32): Int32;
begin
  if StartScope < 0 then
    StartScope := Table.CurrentScope;
  while StartScope >= 0 do
  begin
    Result := SymLookupLocal(Table, Name, StartScope);
    if Result <> FSIM_INVALID_INDEX then
      Exit;
    StartScope := Table.Scopes[StartScope].ParentScope;
  end;
  Result := FSIM_INVALID_INDEX;
end;

function SymAdd(var Table: TSymbolTable; const Name: RawByteString;
  Kind: TSymbolKind; TypeId: Int32; Visibility: TVisibility;
  Flags: TSymbolFlags; DeclNode: Int32; const Span: TSourceSpan): Int32;
var
  ScopeId: Int32;
  Existing: Int32;
  Hash: UInt32;
  Bucket: Int32;
  Owner: Int32;
begin
  ScopeId := Table.CurrentScope;
  if ScopeId < 0 then
    raise EInvalidOp.Create('symbol insertion requires an active scope');
  Existing := SymLookupLocal(Table, Name, ScopeId);
  if Existing <> FSIM_INVALID_INDEX then
  begin
    if not ((Table.Symbols[Existing].Kind = skVirtualSpec) and
      (Kind in [skProcedure, skFunction])) then
    begin
      if Table.Diagnostics <> nil then
        AddError(Table.Diagnostics^, dcDuplicateSymbol, Span,
          'duplicate declaration of ''' + Name + '''');
      Exit(FSIM_INVALID_INDEX);
    end;
  end;
  Result := Length(Table.Symbols);
  SetLength(Table.Symbols, Result + 1);
  Table.Symbols[Result] := Default(TSymbol);
  Hash := IdentifierHash(Table, Name);
  Owner := Table.Scopes[ScopeId].OwnerSymbol;
  Table.Symbols[Result].NameId := StringPoolIntern(Table.Strings, Name);
  Table.Symbols[Result].Hash := Hash;
  Table.Symbols[Result].Kind := Kind;
  Table.Symbols[Result].Flags := Flags;
  Table.Symbols[Result].Visibility := Visibility;
  Table.Symbols[Result].TypeId := TypeId;
  Table.Symbols[Result].ScopeId := ScopeId;
  Table.Symbols[Result].OwnerSymbol := Owner;
  Table.Symbols[Result].DeclNode := DeclNode;
  Table.Symbols[Result].BodyNode := FSIM_INVALID_INDEX;
  Table.Symbols[Result].SourceSpan := Span;
  Table.Symbols[Result].StorageOffset := FSIM_INVALID_INDEX;
  if (TypeId >= 0) and (TypeId <= High(Table.Types)) then
    Table.Symbols[Result].StorageSize := Table.Types[TypeId].Size;
  Table.Symbols[Result].ParameterIndex := -1;
  Table.Symbols[Result].ForeignIndex := FSIM_INVALID_INDEX;
  Table.Symbols[Result].NestingLevel := Table.Scopes[ScopeId].Level;
  Table.Symbols[Result].VMTSlot := FSIM_INVALID_INDEX;
  Table.Symbols[Result].RTTIIndex := FSIM_INVALID_INDEX;
  Table.Symbols[Result].PrefixClass := FSIM_INVALID_INDEX;
  Table.Symbols[Result].NextInScope := FSIM_INVALID_INDEX;
  Table.Symbols[Result].NextInHash := FSIM_INVALID_INDEX;
  Table.Symbols[Result].ConstantString := FSIM_INVALID_INDEX;
  if Table.Scopes[ScopeId].FirstSymbol = FSIM_INVALID_INDEX then
    Table.Scopes[ScopeId].FirstSymbol := Result
  else
    Table.Symbols[Table.Scopes[ScopeId].LastSymbol].NextInScope := Result;
  Table.Scopes[ScopeId].LastSymbol := Result;
  Inc(Table.Scopes[ScopeId].SymbolCount);
  Bucket := ScopeBucketIndex(Table, ScopeId, Hash);
  Table.Symbols[Result].NextInHash := Table.HashBuckets[Bucket];
  Table.HashBuckets[Bucket] := Result;
end;

function SymLookupClass(const Table: TSymbolTable; const Name: RawByteString): Int32;
var
  I: Integer;
begin
  for I := High(Table.Symbols) downto 0 do
    if (Table.Symbols[I].Kind in [skClass, skProcessClass, skThreadClass]) and
       IdentifierEqual(Table, SymName(Table, I), Name) then
      Exit(I);
  { The standard environment is synthetic and historically case-insensitive.
    Keep Free Simula user declarations case-sensitive, but let `Process`,
    `Link`, `Head`, etc. name the compiler-provided SIMULA classes. }
  if Table.Dialect = fdFSim then
    for I := High(Table.Symbols) downto 0 do
      if (Table.Symbols[I].Kind in [skClass, skProcessClass, skThreadClass]) and
         (sfSynthetic in Table.Symbols[I].Flags) and
         ASCIIEqualFold(SymName(Table, I), Name) then
        Exit(I);
  Result := FSIM_INVALID_INDEX;
end;

function SymLookupMember(const Table: TSymbolTable; ClassSymbol: Int32;
  const Name: RawByteString): Int32;
var
  I, Guard: Integer;
begin
  Guard := 0;
  while (ClassSymbol >= 0) and (Guard <= Length(Table.Symbols)) do
  begin
    for I := High(Table.Symbols) downto 0 do
      if (Table.Symbols[I].OwnerSymbol = ClassSymbol) and
         IdentifierEqual(Table, SymName(Table, I), Name) then
        Exit(I);
    if Table.Dialect = fdFSim then
      for I := High(Table.Symbols) downto 0 do
        if (Table.Symbols[I].OwnerSymbol = ClassSymbol) and
           (sfSynthetic in Table.Symbols[I].Flags) and
           ASCIIEqualFold(SymName(Table, I), Name) then
          Exit(I);
    ClassSymbol := Table.Symbols[ClassSymbol].PrefixClass;
    Inc(Guard);
  end;
  Result := FSIM_INVALID_INDEX;
end;

function SymName(const Table: TSymbolTable; SymbolId: Int32): RawByteString;
begin
  if (SymbolId < 0) or (SymbolId > High(Table.Symbols)) then
    Exit('<invalid-symbol>');
  Result := StringPoolGet(Table.Strings, Table.Symbols[SymbolId].NameId);
end;

function TypeName(const Table: TSymbolTable; TypeId: Int32): RawByteString;
begin
  if (TypeId < 0) or (TypeId > High(Table.Types)) then
    Exit('<invalid-type>');
  Result := StringPoolGet(Table.Strings, Table.Types[TypeId].NameId);
end;

function SymAddType(var Table: TSymbolTable; const Info: TTypeInfo): Int32;
begin
  Result := Length(Table.Types);
  SetLength(Table.Types, Result + 1);
  Table.Types[Result] := Info;
end;

function FindReferenceType(const Table: TSymbolTable; ClassSymbol: Int32): Int32;
var
  I: Integer;
begin
  for I := FSIM_FIRST_USER_TYPE to High(Table.Types) do
    if (Table.Types[I].Kind = tyReference) and
       (Table.Types[I].RefClassSymbol = ClassSymbol) then
      Exit(I);
  Result := FSIM_INVALID_INDEX;
end;

function SymAddForeignBinding(var Table: TSymbolTable; SymbolId: Int32;
  const LinkName, LibraryName: RawByteString; Variadic: Boolean;
  Kind: TForeignBindingKind): Int32;
begin
  if (SymbolId < 0) or (SymbolId > High(Table.Symbols)) then
    raise ERangeError.Create('foreign symbol index outside range');
  Result := Length(Table.ForeignBindings);
  SetLength(Table.ForeignBindings, Result + 1);
  Table.ForeignBindings[Result] := Default(TForeignBinding);
  Table.ForeignBindings[Result].SymbolId := SymbolId;
  Table.ForeignBindings[Result].LinkNameId := StringPoolIntern(Table.Strings,
    LinkName);
  Table.ForeignBindings[Result].LibraryNameId := StringPoolIntern(Table.Strings,
    LibraryName);
  Table.ForeignBindings[Result].Convention := fcCSystemVAMD64;
  Table.ForeignBindings[Result].Kind := Kind;
  if Kind = fbFunction then
    Table.ForeignBindings[Result].FixedParameterCount :=
      Table.Types[Table.Symbols[SymbolId].TypeId].ParameterCount
  else
    Table.ForeignBindings[Result].FixedParameterCount := 0;
  Table.ForeignBindings[Result].Variadic := Variadic;
  Table.Symbols[SymbolId].ForeignIndex := Result;
  Include(Table.Symbols[SymbolId].Flags, sfForeign);
  if Variadic then Include(Table.Symbols[SymbolId].Flags, sfVariadic);
end;

function SymForeignBinding(const Table: TSymbolTable; SymbolId: Int32): Int32;
begin
  if (SymbolId < 0) or (SymbolId > High(Table.Symbols)) then
    Exit(FSIM_INVALID_INDEX);
  Result := Table.Symbols[SymbolId].ForeignIndex;
  if (Result < 0) or (Result > High(Table.ForeignBindings)) then
    Result := FSIM_INVALID_INDEX;
end;

function SymMakeCPointerType(var Table: TSymbolTable; ElementType: Int32): Int32;
var
  I: Int32;
  Info: TTypeInfo;
begin
  if (ElementType < 0) or (ElementType > High(Table.Types)) then
    Exit(FSIM_TYPE_C_PTR);
  for I := FSIM_FIRST_USER_TYPE to High(Table.Types) do
    if (Table.Types[I].Kind = tyCPointer) and
       (Table.Types[I].ElementType = ElementType) then
      Exit(I);
  Info := Default(TTypeInfo);
  Info.Kind := tyCPointer;
  Info.Flags := [tfValueType, tfComplete, tfNullable];
  Info.NameId := StringPoolIntern(Table.Strings,
    'c_ptr(' + TypeName(Table, ElementType) + ')');
  Info.Size := 8;
  Info.Alignment := 8;
  Info.ElementType := ElementType;
  Info.ReturnType := FSIM_TYPE_INVALID;
  Info.RefClassSymbol := FSIM_INVALID_INDEX;
  Info.ParameterStart := FSIM_INVALID_INDEX;
  Info.LowerBound := 0;
  Info.UpperBound := -1;
  Info.GenericArity := 1;
  Result := SymAddType(Table, Info);
end;

function SymMakeCFunctionType(var Table: TSymbolTable; ReturnType, ParameterStart,
  ParameterCount: Int32; Variadic: Boolean): Int32;
var
  I, J: Int32;
  Info: TTypeInfo;
  Same: Boolean;
  Name: RawByteString;
begin
  for I := FSIM_FIRST_USER_TYPE to High(Table.Types) do
    if (Table.Types[I].Kind = tyCFunction) and
       (Table.Types[I].ReturnType = ReturnType) and
       (Table.Types[I].ParameterCount = ParameterCount) and
       ((tfCVariadic in Table.Types[I].Flags) = Variadic) then
    begin
      Same := True;
      for J := 0 to ParameterCount - 1 do
        if not SymTypeEqual(Table,
          Table.Parameters[Table.Types[I].ParameterStart + J].TypeId,
          Table.Parameters[ParameterStart + J].TypeId) then
        begin
          Same := False;
          Break;
        end;
      if Same then Exit(I);
    end;

  Name := 'c_fn(';
  for J := 0 to ParameterCount - 1 do
  begin
    if J <> 0 then Name := Name + ', ';
    Name := Name + TypeName(Table, Table.Parameters[ParameterStart + J].TypeId);
  end;
  if Variadic then
  begin
    if ParameterCount <> 0 then Name := Name + ', ';
    Name := Name + '...';
  end;
  Name := Name + '):' + TypeName(Table, ReturnType);

  Info := Default(TTypeInfo);
  Info.Kind := tyCFunction;
  Info.Flags := [tfValueType, tfComplete, tfNullable, tfCallable];
  if Variadic then Include(Info.Flags, tfCVariadic);
  Info.NameId := StringPoolIntern(Table.Strings, Name);
  Info.Size := 8;
  Info.Alignment := 8;
  Info.ElementType := FSIM_TYPE_INVALID;
  Info.ReturnType := ReturnType;
  Info.RefClassSymbol := FSIM_INVALID_INDEX;
  Info.ParameterStart := ParameterStart;
  Info.ParameterCount := ParameterCount;
  Info.LowerBound := 0;
  Info.UpperBound := -1;
  Result := SymAddType(Table, Info);
end;

function SymMakeReferenceType(var Table: TSymbolTable; ClassSymbol: Int32): Int32;
var
  Info: TTypeInfo;
  Existing: Int32;
  N: RawByteString;
begin
  Existing := FindReferenceType(Table, ClassSymbol);
  if Existing <> FSIM_INVALID_INDEX then
    Exit(Existing);
  Info := Default(TTypeInfo);
  Info.Kind := tyReference;
  Info.Flags := [tfReferenceType, tfNullable, tfComplete, tfRuntimeVisible];
  N := 'ref(' + SymName(Table, ClassSymbol) + ')';
  Info.NameId := StringPoolIntern(Table.Strings, N);
  Info.Size := 8;
  Info.Alignment := 8;
  Info.ElementType := FSIM_TYPE_INVALID;
  Info.ReturnType := FSIM_TYPE_INVALID;
  Info.RefClassSymbol := ClassSymbol;
  Info.ParameterStart := FSIM_INVALID_INDEX;
  Info.LowerBound := 0;
  Info.UpperBound := -1;
  Result := SymAddType(Table, Info);
end;

function SymMakeHandleType(var Table: TSymbolTable;
  Kind: TTypeKind; ElementType: Int32; const Prefix: RawByteString): Int32;
var
  I: Int32;
  Info: TTypeInfo;
begin
  for I := FSIM_FIRST_USER_TYPE to High(Table.Types) do
    if (Table.Types[I].Kind = Kind) and
       (Table.Types[I].ElementType = ElementType) then
      Exit(I);
  Info := Default(TTypeInfo);
  Info.Kind := Kind;
  Info.Flags := [tfReferenceType, tfManaged, tfComplete, tfRuntimeVisible];
  Info.NameId := StringPoolIntern(Table.Strings,
    Prefix + '(' + TypeName(Table, ElementType) + ')');
  Info.Size := 16;
  Info.Alignment := 8;
  Info.ElementType := ElementType;
  Info.ReturnType := FSIM_TYPE_INVALID;
  Info.RefClassSymbol := FSIM_INVALID_INDEX;
  Info.ParameterStart := FSIM_INVALID_INDEX;
  Info.LowerBound := 0;
  Info.UpperBound := -1;
  Info.GenericArity := 1;
  Result := SymAddType(Table, Info);
end;

function SymMakeChannelType(var Table: TSymbolTable; ElementType: Int32): Int32;
begin
  Result := SymMakeHandleType(Table, tyChannel, ElementType, 'channel');
end;

function SymMakeFutureType(var Table: TSymbolTable; ElementType: Int32): Int32;
begin
  if (ElementType < 0) or (ElementType > High(Table.Types)) then
    ElementType := FSIM_TYPE_INTEGER;
  Result := SymMakeHandleType(Table, tyFuture, ElementType, 'future');
end;

function SymMakeArrayType(var Table: TSymbolTable; ElementType: Int32;
  LowerBound, UpperBound: Int64): Int32;
var
  I: Integer;
  Info: TTypeInfo;
  Count, MaxCount: QWord;
  ElementSize: UInt32;
  N: RawByteString;
begin
  { Malformed source must never be able to turn a bad type id into a compiler
    range/division exception.  The parser already owns the diagnostic; the
    type table just refuses to construct nonsense. }
  if (ElementType < 0) or (ElementType > High(Table.Types)) then
    Exit(FSIM_TYPE_INVALID);
  ElementSize := Table.Types[ElementType].Size;
  if (ElementType = FSIM_TYPE_VOID) or (ElementSize = 0) or
     not (tfComplete in Table.Types[ElementType].Flags) then
    Exit(FSIM_TYPE_INVALID);

  for I := FSIM_FIRST_USER_TYPE to High(Table.Types) do
    if (Table.Types[I].Kind = tyArray) and
       (Table.Types[I].ElementType = ElementType) and
       (Table.Types[I].LowerBound = LowerBound) and
       (Table.Types[I].UpperBound = UpperBound) then
      Exit(I);
  Info := Default(TTypeInfo);
  Info.Kind := tyArray;
  Info.Flags := [tfValueType, tfComplete, tfRuntimeVisible];
  if tfManaged in Table.Types[ElementType].Flags then
    Include(Info.Flags, tfManaged);
  N := 'array[' + IntToStr(LowerBound) + ':' + IntToStr(UpperBound) + '] of ' +
    TypeName(Table, ElementType);
  Info.NameId := StringPoolIntern(Table.Strings, N);
  Info.ElementType := ElementType;
  Info.Alignment := Table.Types[ElementType].Alignment;
  if Info.Alignment = 0 then Info.Alignment := 1;
  Info.LowerBound := LowerBound;
  Info.UpperBound := UpperBound;
  if UpperBound < LowerBound then
    Count := 0
  else
  begin
    MaxCount := High(UInt32) div ElementSize;
    if (LowerBound <= High(Int64) - Int64(MaxCount)) and
       (UpperBound > LowerBound + Int64(MaxCount) - 1) then
      Count := MaxCount + 1
    else
      Count := QWord(UpperBound - LowerBound) + 1;
  end;
  if Count > High(UInt32) div ElementSize then
    Info.Size := High(UInt32)
  else
    Info.Size := UInt32(Count * ElementSize);
  Info.RefClassSymbol := FSIM_INVALID_INDEX;
  Info.ReturnType := FSIM_TYPE_INVALID;
  Result := SymAddType(Table, Info);
end;

function SymMakeDynamicArrayType(var Table: TSymbolTable;
  ElementType: Int32): Int32;
var
  I: Integer;
  Info: TTypeInfo;
  N: RawByteString;
begin
  if (ElementType < 0) or (ElementType > High(Table.Types)) or
     (ElementType = FSIM_TYPE_VOID) or
     (Table.Types[ElementType].Size = 0) then
    Exit(FSIM_TYPE_INVALID);
  if (ElementType < 0) or (ElementType > High(Table.Types)) then
    ElementType := FSIM_TYPE_INTEGER;
  for I := FSIM_FIRST_USER_TYPE to High(Table.Types) do
    if (Table.Types[I].Kind = tyArray) and
       (tfRuntimeBound in Table.Types[I].Flags) and
       (Table.Types[I].ElementType = ElementType) then
      Exit(I);
  Info := Default(TTypeInfo);
  Info.Kind := tyArray;
  Info.Flags := [tfManaged, tfReferenceType, tfComplete, tfRuntimeVisible,
    tfRuntimeBound];
  N := 'array[*] of ' + TypeName(Table, ElementType);
  Info.NameId := StringPoolIntern(Table.Strings, N);
  Info.ElementType := ElementType;
  Info.Size := SizeOf(Pointer);
  Info.Alignment := SizeOf(Pointer);
  Info.LowerBound := 0;
  Info.UpperBound := -1;
  Info.RefClassSymbol := FSIM_INVALID_INDEX;
  Info.ReturnType := FSIM_TYPE_INVALID;
  Info.ParameterStart := FSIM_INVALID_INDEX;
  Result := SymAddType(Table, Info);
end;

function SymMakeProcedureType(var Table: TSymbolTable; ReturnType: Int32;
  ParameterStart, ParameterCount: Int32; UnspecifiedSignature: Boolean): Int32;
var
  Info: TTypeInfo;
  N: RawByteString;
  I: Int32;
begin
  Info := Default(TTypeInfo);
  Info.Kind := tyProcedure;
  Info.Flags := [tfCallable, tfComplete, tfValueType];
  if UnspecifiedSignature then Include(Info.Flags, tfUnspecifiedSignature);
  N := 'procedure(';
  if UnspecifiedSignature then
    N := N + '...'
  else
    for I := 0 to ParameterCount - 1 do
    begin
      if I > 0 then N := N + ', ';
      if (ParameterStart + I >= 0) and
         (ParameterStart + I <= High(Table.Parameters)) then
      begin
        case Table.Parameters[ParameterStart + I].Mode of
          pmName: N := N + 'name ';
          pmReference: N := N + 'ref ';
        else
          ;
        end;
        N := N + TypeName(Table,
          Table.Parameters[ParameterStart + I].TypeId);
      end
      else
        N := N + '<invalid-type>';
    end;
  N := N + ')';
  if ReturnType <> FSIM_TYPE_VOID then
    N := N + ': ' + TypeName(Table, ReturnType);
  Info.NameId := StringPoolIntern(Table.Strings, N);
  Info.Size := 8;
  Info.Alignment := 8;
  Info.ReturnType := ReturnType;
  Info.ParameterStart := ParameterStart;
  Info.ParameterCount := ParameterCount;
  Info.ElementType := FSIM_TYPE_INVALID;
  Info.RefClassSymbol := FSIM_INVALID_INDEX;
  Result := SymAddType(Table, Info);
end;

function SymAddParameter(var Table: TSymbolTable; const Name: RawByteString;
  TypeId: Int32; Mode: TPassingMode; SymbolId, DefaultNode: Int32): Int32;
begin
  Result := Length(Table.Parameters);
  SetLength(Table.Parameters, Result + 1);
  Table.Parameters[Result].NameId := StringPoolIntern(Table.Strings, Name);
  Table.Parameters[Result].TypeId := TypeId;
  Table.Parameters[Result].Mode := Mode;
  Table.Parameters[Result].SymbolId := SymbolId;
  Table.Parameters[Result].DefaultNode := DefaultNode;
end;

function SymRegisterClass(var Table: TSymbolTable; SymbolId, PrefixClass: Int32;
  IsProcess, IsThread: Boolean): Int32;
var
  PrefixIndex: Int32;
begin
  Result := Length(Table.Classes);
  SetLength(Table.Classes, Result + 1);
  Table.Classes[Result] := Default(TClassInfo);
  Table.Classes[Result].SymbolId := SymbolId;
  Table.Classes[Result].PrefixClass := PrefixClass;
  Table.Classes[Result].FirstField := Length(Table.Fields);
  Table.Classes[Result].FirstMethod := Length(Table.Methods);
  Table.Classes[Result].ParameterStart := Length(Table.Parameters);
  Table.Classes[Result].ParameterCount := 0;
  Table.Classes[Result].InstanceSize := 16;
  Table.Classes[Result].InstanceAlignment := 8;
  Table.Classes[Result].IsProcess := IsProcess;
  Table.Classes[Result].IsThread := IsThread;
  Table.Symbols[SymbolId].PrefixClass := PrefixClass;
  if PrefixClass >= 0 then
  begin
    PrefixIndex := SymClassIndex(Table, PrefixClass);
    if PrefixIndex >= 0 then
    begin
      Table.Classes[Result].InstanceSize :=
        Table.Classes[PrefixIndex].InstanceSize;
      Table.Classes[Result].InstanceAlignment :=
        Table.Classes[PrefixIndex].InstanceAlignment;
      Table.Classes[Result].VMTSlotCount :=
        Table.Classes[PrefixIndex].VMTSlotCount;
    end;
  end;
end;

procedure SymSetClassParameters(var Table: TSymbolTable; ClassSymbol,
  ParameterStart, ParameterCount: Int32);
var
  ClassIndex, PrefixIndex, CombinedStart, I, SourceStart, SourceCount: Int32;
  OwnParameters: array of TParameterInfo;
begin
  ClassIndex := SymClassIndex(Table, ClassSymbol);
  if ClassIndex < 0 then
    raise EInvalidOp.Create('parameter owner is not a registered class');
  if (ParameterStart < 0) or (ParameterCount < 0) or
     (ParameterStart + ParameterCount > Length(Table.Parameters)) then
    raise ERangeError.Create('class parameter range is invalid');

  SetLength(OwnParameters, ParameterCount);
  for I := 0 to ParameterCount - 1 do
    OwnParameters[I] := Table.Parameters[ParameterStart + I];

  PrefixIndex := SymClassIndex(Table, Table.Classes[ClassIndex].PrefixClass);
  if (PrefixIndex < 0) or (Table.Classes[PrefixIndex].ParameterCount = 0) then
  begin
    Table.Classes[ClassIndex].ParameterStart := ParameterStart;
    Table.Classes[ClassIndex].ParameterCount := ParameterCount;
    Exit;
  end;

  CombinedStart := Length(Table.Parameters);
  SourceStart := Table.Classes[PrefixIndex].ParameterStart;
  SourceCount := Table.Classes[PrefixIndex].ParameterCount;
  SetLength(Table.Parameters, CombinedStart + SourceCount + ParameterCount);
  for I := 0 to SourceCount - 1 do
    Table.Parameters[CombinedStart + I] := Table.Parameters[SourceStart + I];
  for I := 0 to ParameterCount - 1 do
    Table.Parameters[CombinedStart + SourceCount + I] := OwnParameters[I];
  Table.Classes[ClassIndex].ParameterStart := CombinedStart;
  Table.Classes[ClassIndex].ParameterCount := SourceCount + ParameterCount;
end;

function SymClassIndex(const Table: TSymbolTable; ClassSymbol: Int32): Int32;
var
  I: Integer;
begin
  for I := 0 to High(Table.Classes) do
    if Table.Classes[I].SymbolId = ClassSymbol then
      Exit(I);
  Result := FSIM_INVALID_INDEX;
end;

function SymAddField(var Table: TSymbolTable; ClassSymbol, FieldSymbol,
  TypeId: Int32; Visibility: TVisibility): Int32;
var
  ClassIndex: Int32;
  Offset: QWord;
  Alignment: UInt32;
begin
  ClassIndex := SymClassIndex(Table, ClassSymbol);
  if ClassIndex < 0 then
    raise EInvalidOp.Create('field owner is not a registered class');
  Alignment := Table.Types[TypeId].Alignment;
  if Alignment = 0 then
    Alignment := 1;
  Offset := AlignUp(Table.Classes[ClassIndex].InstanceSize, Alignment);
  if Offset > High(UInt32) then
    raise ERangeError.Create('class instance layout exceeds 4 GiB');
  Result := Length(Table.Fields);
  SetLength(Table.Fields, Result + 1);
  Table.Fields[Result].SymbolId := FieldSymbol;
  Table.Fields[Result].OwnerClass := ClassSymbol;
  Table.Fields[Result].TypeId := TypeId;
  Table.Fields[Result].Offset := Offset;
  Table.Fields[Result].Size := Table.Types[TypeId].Size;
  Table.Fields[Result].Alignment := Alignment;
  Table.Fields[Result].Visibility := Visibility;
  Table.Symbols[FieldSymbol].StorageOffset := Offset;
  Table.Symbols[FieldSymbol].StorageSize := Table.Types[TypeId].Size;
  Table.Classes[ClassIndex].InstanceSize := Offset + Table.Types[TypeId].Size;
  if Alignment > Table.Classes[ClassIndex].InstanceAlignment then
    Table.Classes[ClassIndex].InstanceAlignment := Alignment;
  Inc(Table.Classes[ClassIndex].FieldCount);
end;

function FindInheritedVirtualSlot(const Table: TSymbolTable; ClassSymbol: Int32;
  const MethodName: RawByteString; ExcludeSymbol: Int32): Int32;
var
  M, ClassIndex, Guard: Int32;
begin
  Guard := 0;
  while (ClassSymbol >= 0) and (Guard <= Length(Table.Classes)) do
  begin
    for M := High(Table.Methods) downto 0 do
      if (Table.Methods[M].OwnerClass = ClassSymbol) and
         (Table.Methods[M].SymbolId <> ExcludeSymbol) and
         Table.Methods[M].IsVirtual and
         IdentifierEqual(Table, SymName(Table, Table.Methods[M].SymbolId),
           MethodName) then
        Exit(Table.Methods[M].VMTSlot);
    ClassIndex := SymClassIndex(Table, ClassSymbol);
    if ClassIndex < 0 then Break;
    ClassSymbol := Table.Classes[ClassIndex].PrefixClass;
    Inc(Guard);
  end;
  Result := FSIM_INVALID_INDEX;
end;

function SymAddMethod(var Table: TSymbolTable; ClassSymbol, MethodSymbol,
  ProcedureType: Int32; Visibility: TVisibility; IsVirtual, IsOverride,
  IsAbstract, IsFinal: Boolean): Int32;
var
  ClassIndex: Int32;
  Slot: Int32;
  MethodName: RawByteString;
begin
  ClassIndex := SymClassIndex(Table, ClassSymbol);
  if ClassIndex < 0 then
    raise EInvalidOp.Create('method owner is not a registered class');
  Slot := FSIM_INVALID_INDEX;
  MethodName := SymName(Table, MethodSymbol);
  if IsVirtual or IsOverride then
    Slot := FindInheritedVirtualSlot(Table, ClassSymbol, MethodName,
      MethodSymbol);
  if (IsVirtual or IsOverride) and (Slot = FSIM_INVALID_INDEX) then
  begin
    Slot := Table.Classes[ClassIndex].VMTSlotCount;
    Inc(Table.Classes[ClassIndex].VMTSlotCount);
  end;
  Result := Length(Table.Methods);
  SetLength(Table.Methods, Result + 1);
  Table.Methods[Result].SymbolId := MethodSymbol;
  Table.Methods[Result].OwnerClass := ClassSymbol;
  Table.Methods[Result].ProcedureType := ProcedureType;
  Table.Methods[Result].VMTSlot := Slot;
  Table.Methods[Result].Visibility := Visibility;
  Table.Methods[Result].IsVirtual := IsVirtual or IsOverride;
  Table.Methods[Result].IsOverride := IsOverride;
  Table.Methods[Result].IsAbstract := IsAbstract;
  Table.Methods[Result].IsFinal := IsFinal;
  Table.Symbols[MethodSymbol].VMTSlot := Slot;
  if IsVirtual or IsOverride then Include(Table.Symbols[MethodSymbol].Flags, sfVirtual);
  if IsOverride then Include(Table.Symbols[MethodSymbol].Flags, sfOverride);
  if IsAbstract then Include(Table.Symbols[MethodSymbol].Flags, sfAbstract);
  if IsFinal then Include(Table.Symbols[MethodSymbol].Flags, sfFinal);
  Inc(Table.Classes[ClassIndex].MethodCount);
end;

procedure SymFinalizeClass(var Table: TSymbolTable; ClassSymbol: Int32);
var
  ClassIndex, PrefixIndex: Int32;
  Entry: TRTTIEntry;
  ClassType: TTypeInfo;
  Name: RawByteString;
begin
  ClassIndex := SymClassIndex(Table, ClassSymbol);
  if ClassIndex < 0 then
    raise EInvalidOp.Create('cannot finalize unknown class');
  PrefixIndex := SymClassIndex(Table, Table.Classes[ClassIndex].PrefixClass);
  if PrefixIndex >= 0 then
  begin
    if Table.Classes[ClassIndex].InstanceSize <
       Table.Classes[PrefixIndex].InstanceSize then
      Table.Classes[ClassIndex].InstanceSize :=
        Table.Classes[PrefixIndex].InstanceSize;
    if Table.Classes[ClassIndex].VMTSlotCount <
       Table.Classes[PrefixIndex].VMTSlotCount then
      Table.Classes[ClassIndex].VMTSlotCount :=
        Table.Classes[PrefixIndex].VMTSlotCount;
  end;
  Table.Classes[ClassIndex].InstanceSize := AlignUp(
    Table.Classes[ClassIndex].InstanceSize,
    Table.Classes[ClassIndex].InstanceAlignment);
  Entry := Default(TRTTIEntry);
  Name := SymName(Table, ClassSymbol);
  Entry.NameOffset := Table.Strings.Entries[Table.Symbols[ClassSymbol].NameId].Offset;
  Entry.NameLength := Length(Name);
  if PrefixIndex >= 0 then
    Entry.ParentRTTI := Table.Classes[PrefixIndex].RTTIIndex
  else
    Entry.ParentRTTI := FSIM_INVALID_INDEX;
  Entry.InstanceSize := Table.Classes[ClassIndex].InstanceSize;
  Entry.InstanceAlignment := Table.Classes[ClassIndex].InstanceAlignment;
  Entry.VMTSlotCount := Table.Classes[ClassIndex].VMTSlotCount;
  if Table.Classes[ClassIndex].IsProcess then Entry.Flags := Entry.Flags or 1;
  if Table.Classes[ClassIndex].IsThread then Entry.Flags := Entry.Flags or 2;
  if Table.Classes[ClassIndex].IsAbstract then Entry.Flags := Entry.Flags or 4;
  if Table.Classes[ClassIndex].IsFinal then Entry.Flags := Entry.Flags or 8;
  Table.Classes[ClassIndex].RTTIIndex := Length(Table.RTTI);
  SetLength(Table.RTTI, Length(Table.RTTI) + 1);
  Table.RTTI[High(Table.RTTI)] := Entry;
  Table.Symbols[ClassSymbol].RTTIIndex := Table.Classes[ClassIndex].RTTIIndex;
  ClassType := Default(TTypeInfo);
  ClassType.Kind := tyClass;
  ClassType.Flags := [tfReferenceType, tfComplete, tfRuntimeVisible];
  ClassType.NameId := Table.Symbols[ClassSymbol].NameId;
  ClassType.Size := Table.Classes[ClassIndex].InstanceSize;
  ClassType.Alignment := Table.Classes[ClassIndex].InstanceAlignment;
  ClassType.RefClassSymbol := ClassSymbol;
  Table.Symbols[ClassSymbol].TypeId := SymAddType(Table, ClassType);
end;

function SymIsDerivedFrom(const Table: TSymbolTable; ChildClass,
  ParentClass: Int32): Boolean;
var
  Guard: Integer;
begin
  Guard := 0;
  while (ChildClass >= 0) and (Guard <= Length(Table.Symbols)) do
  begin
    if ChildClass = ParentClass then
      Exit(True);
    ChildClass := Table.Symbols[ChildClass].PrefixClass;
    Inc(Guard);
  end;
  Result := False;
end;

function SymCanAccess(const Table: TSymbolTable; RequestingClass,
  DeclaringClass: Int32; Visibility: TVisibility): Boolean;
begin
  case Visibility of
    visPublic: Result := True;
    visPrivate: Result := RequestingClass = DeclaringClass;
    visProtected: Result := (RequestingClass = DeclaringClass) or
      SymIsDerivedFrom(Table, RequestingClass, DeclaringClass);
  else
    Result := False;
  end;
end;

function SymAddProtection(var Table: TSymbolTable; ClassSymbol,
  AttributeSymbol: Int32; IsProtected, IsHidden: Boolean): Int32;
begin
  if (ClassSymbol < 0) or (ClassSymbol > High(Table.Symbols)) or
     (AttributeSymbol < 0) or (AttributeSymbol > High(Table.Symbols)) then
    raise ERangeError.Create('invalid class protection symbol');
  Result := Length(Table.Protections);
  SetLength(Table.Protections, Result + 1);
  Table.Protections[Result] := Default(TProtectionInfo);
  Table.Protections[Result].ClassSymbol := ClassSymbol;
  Table.Protections[Result].AttributeSymbol := AttributeSymbol;
  Table.Protections[Result].IsProtected := IsProtected;
  Table.Protections[Result].IsHidden := IsHidden;
end;

function SymCanAccessMember(const Table: TSymbolTable; RequestingClass,
  AttributeSymbol: Int32): Boolean;
var
  DeclaringClass, I: Int32;
begin
  if (AttributeSymbol < 0) or (AttributeSymbol > High(Table.Symbols)) then
    Exit(False);
  DeclaringClass := Table.Symbols[AttributeSymbol].OwnerSymbol;
  Result := SymCanAccess(Table, RequestingClass, DeclaringClass,
    Table.Symbols[AttributeSymbol].Visibility);
  if not Result then
    Exit;
  for I := 0 to High(Table.Protections) do
    if Table.Protections[I].AttributeSymbol = AttributeSymbol then
    begin
      if Table.Protections[I].IsProtected and
         not ((RequestingClass = Table.Protections[I].ClassSymbol) or
           SymIsDerivedFrom(Table, RequestingClass,
             Table.Protections[I].ClassSymbol)) then
        Exit(False);
      if Table.Protections[I].IsHidden and
         (RequestingClass <> Table.Protections[I].ClassSymbol) and
         SymIsDerivedFrom(Table, RequestingClass,
           Table.Protections[I].ClassSymbol) then
        Exit(False);
    end;
end;

function SymTypeEqual(const Table: TSymbolTable; LeftType, RightType: Int32): Boolean;
var
  I: Integer;
  L, R: TTypeInfo;
begin
  if LeftType = RightType then
    Exit(True);
  if (LeftType < 0) or (LeftType > High(Table.Types)) or
     (RightType < 0) or (RightType > High(Table.Types)) then
    Exit(False);
  L := Table.Types[LeftType];
  R := Table.Types[RightType];
  if L.Kind <> R.Kind then
    Exit(False);
  case L.Kind of
    tyReference:
      Result := L.RefClassSymbol = R.RefClassSymbol;
    tyChannel, tyFuture, tyAtomic:
      Result := SymTypeEqual(Table, L.ElementType, R.ElementType);
    tyArray:
      Result := SymTypeEqual(Table, L.ElementType, R.ElementType) and
        (L.LowerBound = R.LowerBound) and (L.UpperBound = R.UpperBound) and
        ((tfRuntimeBound in L.Flags) = (tfRuntimeBound in R.Flags));
    tyProcedure, tyCFunction:
      begin
        if not SymTypeEqual(Table, L.ReturnType, R.ReturnType) then
          Exit(False);
        if (L.Kind = tyProcedure) and
           ((tfUnspecifiedSignature in L.Flags) or
            (tfUnspecifiedSignature in R.Flags)) then
          Exit(True);
        if (L.ParameterCount <> R.ParameterCount) or
           ((tfCVariadic in L.Flags) <> (tfCVariadic in R.Flags)) then
          Exit(False);
        for I := 0 to L.ParameterCount - 1 do
        begin
          if (L.Kind = tyProcedure) and
             (Table.Parameters[L.ParameterStart + I].Mode <>
              Table.Parameters[R.ParameterStart + I].Mode) then
            Exit(False);
          if not SymTypeEqual(Table,
              Table.Parameters[L.ParameterStart + I].TypeId,
              Table.Parameters[R.ParameterStart + I].TypeId) then
            Exit(False);
        end;
        Result := True;
      end;
    tyClass, tyRecord, tyEnum, tyGenericParameter:
      Result := False;
    tyCInteger, tyCReal:
      Result := (L.Size = R.Size) and (L.Flags = R.Flags);
    tyCPointer:
      begin
        if (LeftType = FSIM_TYPE_C_PTR) or (RightType = FSIM_TYPE_C_PTR) then
          Exit(True);
        if (L.ElementType = FSIM_TYPE_INVALID) or
           (R.ElementType = FSIM_TYPE_INVALID) then
          Exit(True);
        Result := SymTypeEqual(Table, L.ElementType, R.ElementType);
      end;
    tyInvalid, tyVoid, tyInteger, tyReal, tyBoolean, tyCharacter, tyText,
    tyString, tyHead, tyLink, tyMutex, tySemaphore, tyBarrier, tyCondition:
      Result := False;
  else
    Result := False;
  end;
end;

function IsIntegerType(const Table: TSymbolTable; TypeId: Int32): Boolean;
begin
  Result := (TypeId >= 0) and (TypeId <= High(Table.Types)) and
    (Table.Types[TypeId].Kind in [tyInteger, tyCInteger]);
end;

function SymIsReferenceType(const Table: TSymbolTable; TypeId: Int32): Boolean;
begin
  Result := (TypeId >= 0) and (TypeId <= High(Table.Types)) and
    (tfReferenceType in Table.Types[TypeId].Flags);
end;

function IsReferenceLike(const Table: TSymbolTable; TypeId: Int32): Boolean;
begin
  Result := SymIsReferenceType(Table, TypeId);
end;

function SymCanConvert(const Table: TSymbolTable; TargetType, SourceType: Int32): Boolean;
var
  TargetClass, SourceClass: Int32;
begin
  if (TargetType = FSIM_TYPE_INVALID) or (SourceType = FSIM_TYPE_INVALID) then
    Exit(False);
  if SymTypeEqual(Table, TargetType, SourceType) then
    Exit(True);
  if SymIsReferenceType(Table, TargetType) then
  begin
    if not SymIsReferenceType(Table, SourceType) then
      Exit(False);
    if (Table.Types[TargetType].Kind = tyReference) and
       (Table.Types[SourceType].Kind = tyReference) then
    begin
      TargetClass := Table.Types[TargetType].RefClassSymbol;
      SourceClass := Table.Types[SourceType].RefClassSymbol;
      Exit(SymIsDerivedFrom(Table, SourceClass, TargetClass));
    end;
    Exit(False);
  end;
  if (Table.Types[TargetType].Kind in [tyText, tyString]) and
     (Table.Types[SourceType].Kind in [tyText, tyString]) then
    Exit(True);
  if IsIntegerType(Table, TargetType) and IsIntegerType(Table, SourceType) then
    Exit(Table.Types[SourceType].Size <= Table.Types[TargetType].Size);
  if (Table.Types[TargetType].Kind in [tyReal, tyCReal]) and IsIntegerType(Table, SourceType) then
    Exit(True);
  if (Table.Types[SourceType].Kind in [tyReal, tyCReal]) and
     (Table.Types[TargetType].Kind in [tyReal, tyCReal]) then
    Exit(True);
  if (Table.Types[TargetType].Kind = tyCPointer) then
  begin
    if Table.Types[SourceType].Kind in [tyCPointer, tyCFunction] then Exit(True);
    if (TargetType = FSIM_TYPE_C_STRING) and (SourceType = FSIM_TYPE_STRING) then
      Exit(True);
    if SourceType = FSIM_TYPE_VOID then Exit(True);
  end;
  if (Table.Types[TargetType].Kind = tyCFunction) and
     (Table.Types[SourceType].Kind in [tyCFunction, tyCPointer]) then
    Exit(True);
  Result := False;
end;

function SymIsCABIType(const Table: TSymbolTable; TypeId: Int32;
  AllowVoid: Boolean): Boolean;
begin
  if (TypeId < 0) or (TypeId > High(Table.Types)) then
    Exit(False);
  if AllowVoid and (TypeId = FSIM_TYPE_VOID) then
    Exit(True);
  Result := Table.Types[TypeId].Kind in [tyCInteger, tyCReal, tyCPointer,
    tyCFunction];
  if (Table.Types[TypeId].Kind = tyRecord) and
     (tfCLayout in Table.Types[TypeId].Flags) and
     (tfComplete in Table.Types[TypeId].Flags) then
    Result := True;
end;

function SymIsCStorageType(const Table: TSymbolTable; TypeId: Int32): Boolean;
var
  Info: TTypeInfo;
begin
  if (TypeId < 0) or (TypeId > High(Table.Types)) then Exit(False);
  if SymIsCABIType(Table, TypeId, False) then Exit(True);
  Info := Table.Types[TypeId];
  if (Info.Kind = tyArray) and not (tfRuntimeBound in Info.Flags) then
    Exit(SymIsCStorageType(Table, Info.ElementType));
  Result := False;
end;

function SymIsCPointeeType(const Table: TSymbolTable; TypeId: Int32): Boolean;
var
  Info: TTypeInfo;
begin
  if (TypeId < 0) or (TypeId > High(Table.Types)) then
    Exit(False);
  if SymIsCABIType(Table, TypeId, False) then
    Exit(True);
  Info := Table.Types[TypeId];
  if (Info.Kind = tyRecord) and (tfCLayout in Info.Flags) then
    Exit(True);
  if (Info.Kind = tyArray) and not (tfRuntimeBound in Info.Flags) then
    Exit(SymIsCPointeeType(Table, Info.ElementType));
  Result := False;
end;

function SymCanCArgumentConvert(const Table: TSymbolTable; TargetType,
  SourceType: Int32): Boolean;
var
  TK, SK: TTypeKind;
begin
  if (TargetType < 0) or (TargetType > High(Table.Types)) or
     (SourceType < 0) or (SourceType > High(Table.Types)) then
    Exit(False);
  if SymTypeEqual(Table, TargetType, SourceType) then
    Exit(True);
  TK := Table.Types[TargetType].Kind;
  SK := Table.Types[SourceType].Kind;
  case TK of
    tyCInteger:
      Result := SK in [tyInteger, tyCInteger, tyBoolean, tyCharacter, tyReal,
        tyCReal];
    tyCReal:
      Result := SK in [tyInteger, tyCInteger, tyBoolean, tyCharacter, tyReal,
        tyCReal];
    tyCPointer:
      begin
        Result := (SK in [tyCPointer, tyCFunction]) or
          (SourceType = FSIM_TYPE_VOID);
        if (TargetType = FSIM_TYPE_C_STRING) and
           (SourceType = FSIM_TYPE_STRING) then
          Result := True;
      end;
    tyCFunction:
      Result := SK in [tyCFunction, tyCPointer];
    tyRecord:
      Result := (tfCLayout in Table.Types[TargetType].Flags) and
        SymTypeEqual(Table, TargetType, SourceType);
  else
    Result := False;
  end;
end;

function SymCanAssign(const Table: TSymbolTable; TargetType, SourceType: Int32;
  IsReferenceAssignment: Boolean): Boolean;
var
  TargetClass, SourceClass: Int32;
begin
  if (TargetType = FSIM_TYPE_INVALID) or (SourceType = FSIM_TYPE_INVALID) then
    Exit(False);
  if IsReferenceAssignment then
  begin
    { text reference assignment is part of old simula, even though TEXT is
      not an object ref in our type table. forgetting that made the modern
      dialect reject perfectly ordinary old programs. annoying as hell. }
    if (Table.Types[TargetType].Kind = tyText) and
       (Table.Types[SourceType].Kind in [tyText, tyString]) then
      Exit(True);
    if not IsReferenceLike(Table, TargetType) then
      Exit(False);
    if SourceType = FSIM_TYPE_VOID then
      Exit(True);
    if not IsReferenceLike(Table, SourceType) then
      Exit(False);
    if (Table.Types[TargetType].Kind = tyReference) and
       (Table.Types[SourceType].Kind = tyReference) then
    begin
      TargetClass := Table.Types[TargetType].RefClassSymbol;
      SourceClass := Table.Types[SourceType].RefClassSymbol;
      { Standard SIMULA permits assignment between related qualified
        references in either direction.  A narrowing assignment is checked
        dynamically by the lowering pass before the destination is updated. }
      Exit(SymIsDerivedFrom(Table, SourceClass, TargetClass) or
        SymIsDerivedFrom(Table, TargetClass, SourceClass));
    end;
    Exit(SymTypeEqual(Table, TargetType, SourceType));
  end;
  if IsReferenceLike(Table, TargetType) then
    Exit(False);
  Result := SymCanConvert(Table, TargetType, SourceType);
end;

function SymCommonType(const Table: TSymbolTable; LeftType,
  RightType: Int32): Int32;
begin
  if SymTypeEqual(Table, LeftType, RightType) then
    Exit(LeftType);
  if (LeftType >= 0) and (RightType >= 0) and
     (LeftType <= High(Table.Types)) and (RightType <= High(Table.Types)) and
     (Table.Types[LeftType].Kind in [tyText, tyString]) and
     (Table.Types[RightType].Kind in [tyText, tyString]) then
  begin
    if (Table.Types[LeftType].Kind = tyText) then Exit(LeftType);
    if (Table.Types[RightType].Kind = tyText) then Exit(RightType);
    Exit(LeftType);
  end;
  { Keep C scalar arithmetic in its ABI domain when it is mixed with an
    ordinary Simula scalar.  Without this, `c_int_value + 1` widened to the
    native 64-bit integer type and then failed when returned from a c_int
    export.  The C scalar is the explicit type in that expression; preserving
    it is both useful and considerably less surprising than silently escaping
    the ABI type system. }
  if (LeftType >= 0) and (LeftType <= High(Table.Types)) and
     (RightType >= 0) and (RightType <= High(Table.Types)) then
  begin
    if (Table.Types[LeftType].Kind = tyCInteger) and
       (Table.Types[RightType].Kind = tyInteger) then
      Exit(LeftType);
    if (Table.Types[RightType].Kind = tyCInteger) and
       (Table.Types[LeftType].Kind = tyInteger) then
      Exit(RightType);
    if (Table.Types[LeftType].Kind = tyCReal) and
       (Table.Types[RightType].Kind in [tyInteger, tyCInteger, tyReal]) then
      Exit(LeftType);
    if (Table.Types[RightType].Kind = tyCReal) and
       (Table.Types[LeftType].Kind in [tyInteger, tyCInteger, tyReal]) then
      Exit(RightType);
  end;
  if (LeftType = FSIM_TYPE_REAL) and IsIntegerType(Table, RightType) then
    Exit(FSIM_TYPE_REAL);
  if (RightType = FSIM_TYPE_REAL) and IsIntegerType(Table, LeftType) then
    Exit(FSIM_TYPE_REAL);
  if (LeftType >= 0) and (LeftType <= High(Table.Types)) and
     (Table.Types[LeftType].Kind = tyEnum) and IsIntegerType(Table, RightType) then
    Exit(FSIM_TYPE_INTEGER);
  if (RightType >= 0) and (RightType <= High(Table.Types)) and
     (Table.Types[RightType].Kind = tyEnum) and IsIntegerType(Table, LeftType) then
    Exit(FSIM_TYPE_INTEGER);
  if IsIntegerType(Table, LeftType) and IsIntegerType(Table, RightType) then
  begin
    if Table.Types[LeftType].Size >= Table.Types[RightType].Size then
      Exit(LeftType)
    else
      Exit(RightType);
  end;
  if IsReferenceLike(Table, LeftType) and IsReferenceLike(Table, RightType) then
  begin
    if (Table.Types[LeftType].Kind = tyReference) and
       (Table.Types[RightType].Kind = tyReference) then
    begin
      if SymIsDerivedFrom(Table, Table.Types[RightType].RefClassSymbol,
        Table.Types[LeftType].RefClassSymbol) then
        Exit(LeftType);
      if SymIsDerivedFrom(Table, Table.Types[LeftType].RefClassSymbol,
        Table.Types[RightType].RefClassSymbol) then
        Exit(RightType);
    end;
  end;
  Result := FSIM_TYPE_INVALID;
end;

function SymAllocateLocal(var Table: TSymbolTable; SymbolId: Int32): Int32;
var
  ScopeId: Int32;
  Alignment, Size: UInt32;
  Offset: QWord;
begin
  if (SymbolId < 0) or (SymbolId > High(Table.Symbols)) then
    Exit(FSIM_INVALID_INDEX);
  if (Table.Symbols[SymbolId].TypeId < 0) or
     (Table.Symbols[SymbolId].TypeId > High(Table.Types)) then
    Exit(FSIM_INVALID_INDEX);
  ScopeId := Table.Symbols[SymbolId].ScopeId;
  if (ScopeId < 0) or (ScopeId > High(Table.Scopes)) then
    Exit(FSIM_INVALID_INDEX);
  Alignment := Table.Types[Table.Symbols[SymbolId].TypeId].Alignment;
  Size := Table.Types[Table.Symbols[SymbolId].TypeId].Size;
  if Alignment = 0 then Alignment := 1;
  Offset := AlignUp(Table.Scopes[ScopeId].LocalSize, Alignment);
  if Offset + Size > High(UInt32) then
    raise ERangeError.Create('routine local frame exceeds 4 GiB');
  Table.Symbols[SymbolId].StorageOffset := Offset;
  Table.Symbols[SymbolId].StorageSize := Size;
  Table.Scopes[ScopeId].LocalSize := Offset + Size;
  if Alignment > Table.Scopes[ScopeId].MaximumAlignment then
    Table.Scopes[ScopeId].MaximumAlignment := Alignment;
  Result := Offset;
end;

function SymSerializeRTTI(var Table: TSymbolTable; var Destination: TByteBuffer): UInt32;
var
  I: Integer;
  Entry: TRTTIEntry;
begin
  Result := Destination.Count;
  BufferAppendDWord(Destination, Length(Table.RTTI));
  BufferAppendDWord(Destination, 0);
  for I := 0 to High(Table.RTTI) do
  begin
    Entry := Table.RTTI[I];
    BufferAppendDWord(Destination, Entry.NameOffset);
    BufferAppendDWord(Destination, Entry.NameLength);
    BufferAppendInt32(Destination, Entry.ParentRTTI);
    BufferAppendDWord(Destination, Entry.InstanceSize);
    BufferAppendDWord(Destination, Entry.InstanceAlignment);
    BufferAppendDWord(Destination, Entry.VMTSlotCount);
    BufferAppendDWord(Destination, Entry.Flags);
    BufferAppendDWord(Destination, 0);
  end;
end;

function SymbolKindName(Kind: TSymbolKind): RawByteString;
begin
  case Kind of
    skInvalid: Result := 'invalid';
    skModule: Result := 'module';
    skProgram: Result := 'program';
    skClass: Result := 'class';
    skProcessClass: Result := 'process-class';
    skThreadClass: Result := 'thread-class';
    skProcedure: Result := 'procedure';
    skFunction: Result := 'function';
    skVirtualSpec: Result := 'virtual-spec';
    skParameter: Result := 'parameter';
    skVariable: Result := 'variable';
    skConstant: Result := 'constant';
    skField: Result := 'field';
    skLabel: Result := 'label';
    skSwitch: Result := 'switch';
    skType: Result := 'type';
    skEnumValue: Result := 'enum-value';
    skImport: Result := 'import';
  else
    Result := '?';
  end;
end;

function VisibilityName(Visibility: TVisibility): RawByteString;
begin
  case Visibility of
    visPublic: Result := 'public';
    visPrivate: Result := 'private';
    visProtected: Result := 'protected';
  else
    Result := '?';
  end;
end;

procedure SymDump(const Table: TSymbolTable);
var
  I: Integer;
begin
  Writeln('Types:');
  for I := 0 to High(Table.Types) do
    Writeln('  #', I:4, ' ', TypeName(Table, I), ' kind=', Ord(Table.Types[I].Kind),
      ' size=', Table.Types[I].Size, ' align=', Table.Types[I].Alignment,
      ' ref=', Table.Types[I].RefClassSymbol);
  Writeln('Symbols:');
  for I := 0 to High(Table.Symbols) do
    Writeln('  #', I:4, ' ', SymName(Table, I), ' kind=',
      SymbolKindName(Table.Symbols[I].Kind), ' type=',
      TypeName(Table, Table.Symbols[I].TypeId), ' scope=',
      Table.Symbols[I].ScopeId, ' owner=', Table.Symbols[I].OwnerSymbol,
      ' visibility=', VisibilityName(Table.Symbols[I].Visibility),
      ' offset=', Table.Symbols[I].StorageOffset, ' vmt=',
      Table.Symbols[I].VMTSlot, ' prefix=', Table.Symbols[I].PrefixClass);
end;

procedure SymVerify(const Table: TSymbolTable);
var
  I, ScopeId, SymbolId, Count, Guard: Integer;
begin
  for I := 0 to High(Table.Types) do
  begin
    if Table.Types[I].Alignment = 0 then
      raise EInvalidOp.CreateFmt('type %d has zero alignment', [I]);
    if not IsPowerOfTwo(Table.Types[I].Alignment) then
      raise EInvalidOp.CreateFmt('type %d has non-power-of-two alignment', [I]);
    if (Table.Types[I].NameId < 0) or
       (Table.Types[I].NameId > High(Table.Strings.Entries)) then
      raise EInvalidOp.CreateFmt('type %d has invalid name', [I]);
  end;
  for ScopeId := 0 to High(Table.Scopes) do
  begin
    SymbolId := Table.Scopes[ScopeId].FirstSymbol;
    Count := 0;
    Guard := 0;
    while SymbolId <> FSIM_INVALID_INDEX do
    begin
      if (SymbolId < 0) or (SymbolId > High(Table.Symbols)) then
        raise EInvalidOp.CreateFmt('scope %d has invalid symbol link', [ScopeId]);
      if Table.Symbols[SymbolId].ScopeId <> ScopeId then
        raise EInvalidOp.CreateFmt('symbol %d scope mismatch', [SymbolId]);
      Inc(Count);
      Inc(Guard);
      if Guard > Length(Table.Symbols) then
        raise EInvalidOp.CreateFmt('scope %d symbol cycle', [ScopeId]);
      SymbolId := Table.Symbols[SymbolId].NextInScope;
    end;
    if Count <> Table.Scopes[ScopeId].SymbolCount then
      raise EInvalidOp.CreateFmt('scope %d symbol count mismatch', [ScopeId]);
  end;
  for I := 0 to High(Table.Symbols) do
  begin
    if (Table.Symbols[I].TypeId < 0) or
       (Table.Symbols[I].TypeId > High(Table.Types)) then
      raise EInvalidOp.CreateFmt('symbol %d has invalid type', [I]);
    if (Table.Symbols[I].ScopeId < 0) or
       (Table.Symbols[I].ScopeId > High(Table.Scopes)) then
      raise EInvalidOp.CreateFmt('symbol %d has invalid scope', [I]);
  end;
end;

end.

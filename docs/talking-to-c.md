# Talking to C

The C ABI belongs to the `fsim` profile. It is not injected into `-std=simula67`, and it does not change the meaning of classic `external` declarations. If you want old-style externals, that is the classic profile's business, and the classic profile's problem.

The native x86-64 Linux backend implements the System V AMD64 ABI itself. A foreign call is lowered directly from fsim IR into the ABI register/stack assignment and a GOT-resolved call. fsim does not generate C, invoke GCC or Clang as a linker, or run a helper process for each call. The only third party involved is the platform loader, and it runs once.

## foreign blocks

Imports are grouped by shared library:

```simula
foreign c from "libm.so.6" begin
    function cos(value: c_double): c_double;
    function pow(base: c_double, exponent: c_double): c_double;
end;
```

A local name may identify a different exported C symbol:

```simula
foreign c from "libexample.so" begin
    function checksum(data: c_ptr(c_uchar), bytes: c_size): c_uint = "example_checksum_v2";
end;
```

Foreign data objects use `var` and are accessed as ordinary lvalues:

```simula
foreign c from "libexample.so" begin
    var library_mode: c_int = "example_mode";
end;

begin
    library_mode := c_int(2)
end;
```

The executable contains a normal dynamic symbol table, SysV hash table, dynamic relocations, and GOT slots. Imported data and functions are resolved by the platform loader at process startup. `--dynamic-linker=PATH` is authoritative when supplied. Otherwise fsim first honors `FSIM_DYNAMIC_LINKER`, then looks for a mapped loader or mapped `libc.so.6`, active Guix/Nix profiles and library search paths, and finally glibc packages in `/gnu/store` or `/nix/store` before checking conventional FHS loader paths. This matters when the compiler executable itself is statically linked and therefore has no loader entry in `/proc/self/maps`. Fsim refuses to emit a dynamic executable if it cannot find an interpreter that actually exists; use the option or the environment variable to override discovery explicitly. The failure mode is a clear error, not a binary that crashes at startup on someone else's machine.

Foreign binaries normally return through the C runtime, so C `atexit` handlers and shared-library finalizers run. The default runtime dependency is `libc.so.6`; `--c-runtime=LIB` selects another C runtime soname for musl or a custom environment. `--c-raw-exit` keeps fsim's direct process-exit path and does not add the synthetic C-runtime `exit` binding. These options affect only binaries which use the foreign ABI; ordinary fsim executables remain on the compiler-owned native runtime path.

## ABI types

The LP64 x86-64 target provides explicit C-width types:

- `c_char`, `c_schar`, `c_uchar`
- `c_short`, `c_ushort`
- `c_int`, `c_uint`
- `c_long`, `c_ulong`
- `c_longlong`, `c_ulonglong`
- `c_size`, `c_ssize`, `c_intptr`, `c_uintptr`
- `c_float`, `c_double`, `c_bool`
- `c_ptr`, `c_ptr(T)`, `c_string`
- `c_fn(...): R`
- C-layout records and unions

Use explicit conversions at ABI boundaries when the width matters:

```simula
var n: c_uint;
n := c_uint(42);
```

`c_string` is a nullable `char *`. A Free Simula native `string` may be passed to a fixed `c_string` parameter without copying, because native strings keep a trailing NUL byte. C code must not retain that pointer past the lifetime of the Free Simula string and must not write through it. If the C library keeps your pointer overnight, that is what pinning is for; see [memory-and-gc.md](memory-and-gc.md).

`c_ptr(c_void)` is the accepted spelling of `void *`; the unparameterized `c_ptr` is the same ABI category when the pointee type is intentionally unknown.

## pointers

Typed pointers keep pointee information in the compiler:

```simula
var p: c_ptr(c_int);
var x: c_int;

p := c_addr(x);
p.store(c_int(12));
assert(p.load() = c_int(12));
p := p.offset(1);
```

`offset(n)` scales by the pointee ABI size. `load` and `store` are direct native memory operations. Records are copied by their exact C layout rather than treated as object references.

Compile-time layout inquiries are available for bindings and assertions:

```simula
c_sizeof(Type)
c_alignof(Type)
c_offsetof(Type, "field")
```

## records, unions, opaque, and packed layouts

Natural C layout:

```simula
foreign c record Point begin
    x: c_double;
    y: c_double;
end;
```

Union fields overlap at offset zero:

```simula
foreign c union WordBits begin
    whole: c_uint;
    low: c_ushort;
end;
```

Packed layouts deliberately suppress field padding:

```simula
foreign c packed record Header begin
    kind: c_uchar;
    length: c_uint;
end;
```

Opaque declarations are pointer-only types for C handles whose layout is private:

```simula
foreign c opaque record FILE;
var stream: c_ptr(FILE);
```

An opaque type is valid behind `c_ptr(T)` but is rejected as a by-value parameter, result, local storage object, or `c_sizeof` target until a complete layout is declared.

For small aggregates the backend recursively classifies up to two eightbytes and assigns INTEGER/SSE registers according to the SysV AMD64 ABI. Register assignment is all-or-nothing for an aggregate. Larger or ABI-memory-class aggregates are copied to the outgoing stack. Large aggregate results use the hidden sret pointer. Mixed records such as `{double, int}` therefore use the proper mixed XMM/GPR path instead of a blanket pointer convention.

## variadic functions

Use `...` in the import or function pointer type:

```simula
foreign c from "libc.so.6" begin
    function printf(format: c_string, ...): c_int;
end;

begin
    printf("value = %d\n", c_int(42))
end;
```

Variadic arguments after the fixed portion must already have an explicit `c_*` type. This prevents an fsim `integer` or `real` from accidentally entering C varargs with the wrong width. The backend applies C default argument promotions (`c_float` to `c_double`, narrow integer types to `c_int`) and sets the AMD64 varargs SSE-register count in `AL`.

## function pointers and callbacks

Typed C function pointers are first-class ABI values:

```simula
var callback: c_fn(c_int): c_int;
callback := get_callback();
answer := callback(c_int(21));
```

A top-level Free Simula routine can be given a C entry adapter:

```simula
foreign c export function triple(value: c_int): c_int;
begin
    return value * c_int(3)
end;

begin
    register_callback(c_addr(triple))
end;
```

The adapter translates the C ABI into fsim's internal native calling convention and translates the result back. Scalar, floating, pointer, and supported aggregate arguments and results use the same classifier as outbound calls. `foreign c export` functions are also emitted into `.dynsym` under their Free Simula name, so a loader or C library can resolve them by name when appropriate.

Callbacks are top-level in this ABI revision. There is deliberately no invisible closure pointer. C APIs which accept context should receive an explicit `c_ptr` userdata parameter, which makes ownership and lifetime visible on both sides of the boundary. Hidden closures are how callback bugs become legendary.

## performance model

The hot call path has no generated wrapper process and no runtime signature interpreter. Fixed signatures are classified during compilation and become ordinary register moves, stack stores, and a native call. Dynamic symbol resolution is delegated once to the ELF loader through GOT relocations. Typed indirect calls use exactly the same compile-time ABI lowering and then call the function pointer directly.

C records used internally are represented by addressable native storage, so large values are not bounced through Pascal objects. Copies use exact byte counts; odd-sized packed aggregates do not over-read or overwrite adjacent storage.

## deliberate boundaries

This backend is a System V AMD64 C ABI implementation, not a C or C++ compiler. It does not parse C headers. Bindings state the ABI contract explicitly, because guessing is how ABI bugs get into production.

The current ABI intentionally does not claim support for x87 `long double`, `_Complex`, compiler vector extensions, C bit-field declaration syntax, C++ classes/member functions/exceptions, the Microsoft x64 calling convention, or architecture-specific attributes. Those require additional ABI classes or language-specific object models and should produce a binding-time diagnostic rather than be guessed. Plain C bit-field-containing structs can still be bound through an explicitly matched storage record or helper API, but fsim will not infer implementation-defined bit-field packing.

This boundary matters: the supported surface is direct and native, and unsupported ABI extensions are not silently approximated. A clear "no" beats a confident wrong answer.

## testing

`make test-ffi` compiles a host C shared library and exercises both sides of the boundary: integer widths, float/double, strings, foreign globals, typed void pointers, small mixed aggregates, packed aggregates, unions, large sret aggregates, C varargs, returned function pointers, callbacks into Free Simula, and named dynamic exports.

The test is also part of `make test` and `make release-check`. If you broke the C ABI, it will find out, and so will your users.

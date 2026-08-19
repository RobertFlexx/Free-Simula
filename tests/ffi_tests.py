#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import struct
import sys
import tempfile


def run(cmd: list[str], *, env: dict[str, str] | None = None, timeout: int = 60) -> subprocess.CompletedProcess[str]:
    merged = dict(os.environ)
    merged.update({"LC_ALL": "C", "LANG": "C"})
    if env:
        merged.update(env)
    return subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          timeout=timeout, check=False, env=merged)


def fail(message: str, result: subprocess.CompletedProcess[str] | None = None) -> int:
    print("FAIL ffi: " + message, file=sys.stderr)
    if result is not None:
        if result.stdout:
            print(result.stdout, file=sys.stderr, end="")
        if result.stderr:
            print(result.stderr, file=sys.stderr, end="")
    return 1


def elf_interpreter(path: Path) -> str | None:
    """Return PT_INTERP for fsim's ELF64 little-endian target, if present."""
    try:
        with path.open("rb") as stream:
            header = stream.read(64)
            if len(header) < 64 or header[:4] != b"\x7fELF":
                return None
            if header[4] != 2 or header[5] != 1:  # ELFCLASS64 / little endian
                return None
            phoff = struct.unpack_from("<Q", header, 32)[0]
            phentsize = struct.unpack_from("<H", header, 54)[0]
            phnum = struct.unpack_from("<H", header, 56)[0]
            if phentsize < 56:
                return None
            for index in range(phnum):
                stream.seek(phoff + index * phentsize)
                ph = stream.read(phentsize)
                if len(ph) < 56:
                    return None
                p_type = struct.unpack_from("<I", ph, 0)[0]
                if p_type != 3:  # PT_INTERP
                    continue
                p_offset = struct.unpack_from("<Q", ph, 8)[0]
                p_filesz = struct.unpack_from("<Q", ph, 32)[0]
                stream.seek(p_offset)
                raw = stream.read(p_filesz)
                return raw.split(b"\0", 1)[0].decode("utf-8", "replace")
    except OSError:
        return None
    return None


C_SOURCE = r'''
#include <stdint.h>
#include <stddef.h>
#include <stdarg.h>
#include <string.h>

struct Mixed { double weight; int32_t code; };
struct Big { uint64_t a, b, c; };
struct __attribute__((packed)) Packed { uint8_t tag; uint32_t length; };
union WordBits { uint32_t whole; uint16_t low; };

int32_t ffi_global = 17;

int8_t ffi_i8(int8_t x) { return (int8_t)(x - 1); }
uint8_t ffi_u8(uint8_t x) { return (uint8_t)(x + 1); }
int16_t ffi_i16(int16_t x) { return (int16_t)(x - 2); }
uint16_t ffi_u16(uint16_t x) { return (uint16_t)(x + 2); }
int32_t ffi_i32(int32_t a, int32_t b) { return a + b; }
uint64_t ffi_u64(uint64_t x) { return x ^ UINT64_C(0x1020304050607080); }
float ffi_float(float x) { return x * 1.5f; }
double ffi_double(double x) { return x * 2.0; }
double ffi_three_doubles(double a, double b, double c) { return a + 10.0 * b + 100.0 * c; }
size_t ffi_strlen(const char *s) { return s ? strlen(s) : 0; }
void *ffi_identity(void *p) { return p; }

struct Mixed ffi_mixed(struct Mixed v) {
    v.weight += 0.5;
    v.code += 3;
    return v;
}

struct Big ffi_big(uint64_t a, uint64_t b, uint64_t c) {
    struct Big v = { a, b, c };
    return v;
}

uint32_t ffi_packed(struct Packed p) {
    return ((uint32_t)p.tag << 24) | p.length;
}

union WordBits ffi_union(union WordBits v) {
    v.whole ^= UINT32_C(0x00ff00ff);
    return v;
}

int32_t ffi_varints(int32_t n, ...) {
    va_list ap;
    int32_t sum = 0;
    va_start(ap, n);
    for (int32_t i = 0; i < n; ++i) sum += va_arg(ap, int);
    va_end(ap);
    return sum;
}

double ffi_vardoubles(int32_t n, ...) {
    va_list ap;
    double sum = 0.0;
    va_start(ap, n);
    for (int32_t i = 0; i < n; ++i) sum += va_arg(ap, double);
    va_end(ap);
    return sum;
}

int32_t ffi_call_i32(int32_t (*cb)(int32_t), int32_t value) {
    return cb(value);
}

struct Mixed ffi_call_mixed(struct Mixed (*cb)(struct Mixed), struct Mixed value) {
    return cb(value);
}

struct Big ffi_call_big(struct Big (*cb)(struct Big), struct Big value) {
    return cb(value);
}

static int32_t plus_five(int32_t x) { return x + 5; }
int32_t (*ffi_get_callback(void))(int32_t) { return plus_five; }
'''


def fsim_source(lib: Path) -> tuple[str, dict[int, str]]:
    q = str(lib).replace('\\', '\\\\').replace('"', '\\"')
    source = f'''foreign c record Mixed begin
    weight: c_double;
    code: c_int;
end;

foreign c record Big begin
    a: c_ulonglong;
    b: c_ulonglong;
    c: c_ulonglong;
end;

foreign c packed record Packed begin
    tag: c_uchar;
    length: c_uint;
end;

foreign c union WordBits begin
    whole: c_uint;
    low: c_ushort;
end;

foreign c opaque record Opaque;

foreign c from "{q}" begin
    function ffi_i8(x: c_schar): c_schar;
    function ffi_u8(x: c_uchar): c_uchar;
    function ffi_i16(x: c_short): c_short;
    function ffi_u16(x: c_ushort): c_ushort;
    function ffi_i32(a: c_int, b: c_int): c_int;
    function ffi_u64(x: c_ulonglong): c_ulonglong;
    function ffi_float(x: c_float): c_float;
    function ffi_double(x: c_double): c_double;
    function ffi_three_doubles(a: c_double, b: c_double, c: c_double): c_double;
    function ffi_strlen(s: c_string): c_size;
    function ffi_identity(p: c_ptr(c_void)): c_ptr(c_void);
    function ffi_mixed(v: Mixed): Mixed;
    function ffi_big(a: c_ulonglong, b: c_ulonglong, c: c_ulonglong): Big;
    function ffi_packed(v: Packed): c_uint;
    function ffi_union(v: WordBits): WordBits;
    function ffi_varints(n: c_int, ...): c_int;
    function ffi_vardoubles(n: c_int, ...): c_double;
    function ffi_call_i32(cb: c_fn(c_int): c_int, value: c_int): c_int;
    function ffi_call_mixed(cb: c_fn(Mixed): Mixed, value: Mixed): Mixed;
    function ffi_call_big(cb: c_fn(Big): Big, value: Big): Big;
    function ffi_get_callback(): c_fn(c_int): c_int;
    var ffi_global: c_int;
end;

foreign c export function fsim_times_three(value: c_int): c_int;
begin
    return value * c_int(3)
end;

foreign c export function fsim_mixed_callback(value: Mixed): Mixed;
begin
    value.weight := value.weight + c_double(1.0);
    value.code := value.code + c_int(10);
    return value
end;

foreign c export function fsim_big_callback(value: Big): Big;
begin
    value.a := value.a + c_ulonglong(1);
    value.b := value.b + c_ulonglong(2);
    value.c := value.c + c_ulonglong(3);
    return value
end;

program FFIRoundTrip;
begin
    var mixed: Mixed;
    var big: Big;
    var packed: Packed;
    var bits: WordBits;
    var raw: c_ptr(c_void);
    var cb: c_fn(c_int): c_int;
    var ffi_failures: integer;

    ffi_failures := 0;
    assert(ffi_i8(c_schar(9)) = c_schar(8));
    assert(ffi_u8(c_uchar(9)) = c_uchar(10));
    assert(ffi_i16(c_short(20)) = c_short(18));
    assert(ffi_u16(c_ushort(20)) = c_ushort(22));
    assert(ffi_i32(c_int(19), c_int(23)) = c_int(42));
    assert(ffi_float(c_float(4.0)) = c_float(6.0));
    assert(ffi_double(c_double(3.0)) = c_double(6.0));
    assert(ffi_three_doubles(c_double(1.5), c_double(2.0), c_double(2.5)) = c_double(271.5));
    assert(ffi_strlen("native ffi") = c_size(10));

    ffi_global := c_int(29);
    assert(ffi_global = c_int(29));
    raw := c_ptr(c_void)(c_addr(ffi_global));
    assert(ffi_identity(raw) = raw);

    mixed.weight := c_double(2.5);
    mixed.code := c_int(7);
    mixed := ffi_mixed(mixed);
    assert(mixed.weight = c_double(3.0));
    assert(mixed.code = c_int(10));

    big := ffi_big(c_ulonglong(11), c_ulonglong(22), c_ulonglong(33));
    assert(big.a = c_ulonglong(11));
    assert(big.b = c_ulonglong(22));
    assert(big.c = c_ulonglong(33));

    packed.tag := c_uchar(2);
    packed.length := c_uint(42);
    assert(ffi_packed(packed) = c_uint(33554474));

    bits.whole := c_uint(305419896);
    bits := ffi_union(bits);
    assert(bits.whole = c_uint(315315847));

    assert(ffi_varints(c_int(4), c_int(10), c_int(11), c_int(9), c_int(12)) = c_int(42));
    assert(ffi_vardoubles(c_int(3), c_double(1.5), c_double(2.0), c_double(2.5)) = c_double(6.0));
    assert(ffi_vardoubles(c_int(2), c_float(1.5), c_float(2.5)) = c_double(4.0));

    assert(ffi_call_i32(c_addr(fsim_times_three), c_int(14)) = c_int(42));
    mixed.weight := c_double(4.0);
    mixed.code := c_int(5);
    mixed := ffi_call_mixed(c_addr(fsim_mixed_callback), mixed);
    assert(mixed.weight = c_double(5.0));
    assert(mixed.code = c_int(15));

    big.a := c_ulonglong(100);
    big.b := c_ulonglong(200);
    big.c := c_ulonglong(300);
    big := ffi_call_big(c_addr(fsim_big_callback), big);
    assert(big.a = c_ulonglong(101));
    assert(big.b = c_ulonglong(202));
    assert(big.c = c_ulonglong(303));

    cb := ffi_get_callback();
    assert(cb(c_int(37)) = c_int(42));

    assert(c_sizeof(Packed) = c_size(5));
    assert(c_alignof(Packed) = c_size(1));
    assert(c_offsetof(Packed, "length") = c_size(1));
    assert(c_sizeof(Big) = c_size(24));

    if ffi_failures <> 0 then exit(76);
    outtext("ffi ok");
    outimage;
    exit(0)
end;
'''
    checkpoints: dict[int, str] = {}
    rewritten: list[str] = []
    next_code = 101
    for line in source.splitlines():
        stripped = line.strip()
        if stripped.startswith("assert(") and stripped.endswith(");"):
            condition = stripped[len("assert("):-2]
            checkpoints[next_code] = condition
            indent = line[:len(line) - len(line.lstrip())]
            rewritten.extend([
                f"{indent}if not ({condition}) then begin",
                f'{indent}    outtext("FFI_CHECKPOINT_{next_code}");',
                f"{indent}    outimage;",
                f"{indent}    ffi_failures := ffi_failures + 1",
                f"{indent}end;",
            ])
            next_code += 1
        else:
            rewritten.append(line)
    return "\n".join(rewritten) + "\n", checkpoints


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--compiler", type=Path, required=True)
    args = parser.parse_args()
    compiler = args.compiler.resolve()
    if not compiler.exists():
        return fail(f"compiler not found: {compiler}")

    cc = os.environ.get("CC") or shutil.which("cc") or shutil.which("clang") or shutil.which("gcc")
    if not cc:
        print("SKIP ffi: no host C compiler for ABI fixture")
        return 0

    with tempfile.TemporaryDirectory(prefix="fsim-ffi-") as tmp_name:
        tmp = Path(tmp_name)
        c_file = tmp / "fixture.c"
        lib = tmp / "libfsim_ffi_fixture.so"
        source = tmp / "roundtrip.sim"
        exe = tmp / "roundtrip"
        c_file.write_text(C_SOURCE, encoding="utf-8")
        generated_source, checkpoints = fsim_source(lib)
        source.write_text(generated_source, encoding="utf-8")

        build_c = run([cc, "-std=c11", "-O2", "-fPIC", "-shared", str(c_file), "-o", str(lib)])
        if build_c.returncode != 0:
            return fail("could not build C ABI fixture", build_c)

        check = run([str(compiler), "-std=fsim", "--check", str(source)])
        if check.returncode != 0:
            return fail("Free Simula FFI fixture did not type-check", check)

        compile_result = run([str(compiler), "-std=fsim", "-O3", str(source), "-o", str(exe)])
        if compile_result.returncode != 0:
            return fail("Free Simula FFI fixture did not compile", compile_result)
        if not exe.exists():
            return fail("compiler reported success without producing the FFI executable")

        interp = elf_interpreter(exe)
        if interp and not Path(interp).exists():
            return fail(
                "generated FFI binary requests a missing ELF interpreter: "
                f"{interp!r}; set FSIM_DYNAMIC_LINKER or --dynamic-linker to "
                "an existing x86-64 loader"
            )

        try:
            execute = run([str(exe)], timeout=20)
        except OSError as error:
            detail = f" PT_INTERP={interp!r}." if interp else ""
            return fail(
                "could not execute the generated FFI binary: "
                f"{error}.{detail}"
            )
        if execute.returncode != 0:
            failed_checkpoints: list[int] = []
            for line in execute.stdout.splitlines():
                if not line.startswith("FFI_CHECKPOINT_"):
                    continue
                try:
                    code = int(line.removeprefix("FFI_CHECKPOINT_"))
                except ValueError:
                    continue
                if code in checkpoints and code not in failed_checkpoints:
                    failed_checkpoints.append(code)
            if failed_checkpoints:
                details = "; ".join(
                    f"{code}: {checkpoints[code]}" for code in failed_checkpoints
                )
                # Do not pass the raw result here: stdout contains only the
                # machine-readable checkpoint markers that were just decoded.
                return fail(f"FFI ABI checkpoints failed: {details}")
            return fail(f"FFI executable exited {execute.returncode}", execute)
        if execute.stdout != "ffi ok\n":
            return fail(f"unexpected FFI stdout: {execute.stdout!r}", execute)

        # A named C export should be visible in the executable's dynamic symbols.
        readelf = shutil.which("readelf")
        if readelf:
            symbols = run([readelf, "--dyn-syms", "--wide", str(exe)])
            if symbols.returncode != 0:
                return fail("readelf could not inspect dynamic symbols", symbols)
            if "fsim_times_three" not in symbols.stdout or "fsim_mixed_callback" not in symbols.stdout:
                return fail("foreign c export routines are missing from .dynsym", symbols)

    print("PASS ffi: SysV AMD64 import/export/callback/aggregate/varargs round trip")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

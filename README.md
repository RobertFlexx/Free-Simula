# Free Simula

Free Simula (`fsim`) is a native Simula-family compiler for x86-64 Linux. It started back in 2022 as a school programming-history project a few friends and I built, and then we kept going long after it had stopped being a sensible school project.

The point is not to turn Simula into C with different keywords. Free Simula keeps the ALGOL/Simula shape: `begin`/`end` blocks, classes and prefixing, `inner`, references, `new`, `inspect`, arrays, procedure values, labels, and the separate `:=` value and `:-` reference assignments. The Free Simula profile adds things that are useful on a current system: modules, modern strings, native tasks and synchronization, C interoperability, enums, aliases, and a larger source standard library, without replacing that base language.

`fsim` has its own x86-64 machine-code and ELF backend. Ordinary native output does not go through generated C, GCC, Clang, LLVM, `as`, or `ld`.

**This** is my long awaited, long development project i had been eager to finish and release. I thank everyone along the way of the creation of this, and it is my honor to present a compiler for Simula, as i have had an interest in classic ALGOL languages.

***Warning!*** this is not guaranteed to compile every Simula source code out there, it is meant as a stable release candidate, and compiles majority Standard Simula67, and the specific home-grown modern dialect of Free Simula.

**Read below for more info regarding this project.**

## Status

This tree is **2.0.0-rc2**. It is a release candidate, not a claim that every historical Standard SIMULA program works.

There are two source profiles:

- `-std=fsim`, the modern Free Simula dialect.
- `-std=simula67`, the classic compatibility profile, with case-folded names and the historical implicit environment.

The classic profile covers a substantial part of Simula 67 syntax, object semantics, TEXT/BASICIO behavior, classes, prefixing, `inner`, arrays, classic procedure forms, labels/switches, and the native standard environment. General call-by-name, non-local `goto` unwinding, the complete historical `Simulation` continuation model, and parts of the old file/environment surface are still listed as open work in [docs/simula67-conformance.md](docs/simula67-conformance.md).

That boundary is intentional. If the compiler knows a construct is not implemented correctly, it should diagnose it instead of quietly generating a wrong executable.

## Build

You need Linux x86-64, Free Pascal 3.2.2 or newer, and `make`.

```sh
make clean
make
./bin/fsim --self-test
```

If FPC is not named `fpc`:

```sh
make FPC=/path/to/fpc
```

Install an already-built compiler with:

```sh
sudo make install PREFIX=/usr/local
```

This installs `fsim`, the source standard library, and the user documentation. The bundled Raylib and ncurses modules are installed with the rest of the standard library.

Maintainer checkouts also contain the test and audit machinery used for release validation. The small public source distribution intentionally leaves that machinery out.

## Hello world

```simula
program Hello;
begin
    outtext("hello from Free Simula");
    outimage
end;
```

```sh
fsim -std=fsim hello.sim -o hello
./hello
```

For old source that expects the Standard SIMULA environment:

```sh
fsim -std=simula67 old.sim -o old
./old
```

## A little Free Simula

```simula
module Demo;

type Counter = integer;
enum Direction begin North = 0, East, South, West end;

integer function Twice(integer value);
begin
    return value * 2
end;

program DemoProgram;
begin
    integer total;
    procedure(integer): integer operation;

    operation := Twice;
    total := operation(21);
    assert(total = 42)
end;
```

Modern lookup is case-sensitive and does not inject the classic implicit namespace. The old profile keeps classic case folding and old lexical forms.

## Memory

The 2.0 runtime has a native **non-moving tracing collector**. Managed objects do not change address, which keeps the C ABI and interior pointers practical.

Small allocations use 1 MiB mmap-backed slabs and lock-free power-of-two free lists. Dead small blocks are reused. Large managed allocations use individual mappings and can be returned to Linux. Collection scans active roots conservatively and supports explicit pin/unpin for pointers retained by C.

```simula
import Memory;

program HeapStats;
begin
    CollectGarbage;
    outint(LiveHeapBytes);
    outimage
end;
```

Native task stacks are part of their managed task allocation. A completed task is not reclaimable until Linux has cleared its child TID, so the runtime cannot free a stack while the worker is still executing on it. The current collector chooses correctness over pause complexity and postpones collection while an fsim native worker is live.

The exact model and FFI ownership rules are in [docs/memory-and-gc.md](docs/memory-and-gc.md).

## Standard library

The library is ordinary Free Simula source where practical. Some modules wrap compiler/runtime primitives where an OS or machine boundary is unavoidable.

Examples:

```simula
import Math;
import Strings;
import Statistics;
import Random;
import Filesystem;
import Tasking;
import Synchronization;
import Memory;
```

Simulation-oriented modules such as `Simset`, `Process`, `Simulation`, `EventCalendar`, `ResourceFacility`, and queue/statistics helpers are included too. They do not replace the strict profile's historical environment.

See [docs/standard-library.md](docs/standard-library.md).

## Raylib

Free Simula ships a first-party Free Simula binding for the raylib 6.0 C ABI:

```simula
import Raylib;

program Window;
begin
    InitWindow(c_int(960), c_int(540), "Free Simula");
    SetTargetFPS(c_int(60));

    while not WindowShouldClose() do
    begin
        BeginDrawing;
        ClearBackground(Black);
        DrawText("hello raylib", c_int(32), c_int(32), c_int(28), RayWhite);
        EndDrawing
    end;

    CloseWindow
end;
```

The module is bundled with fsim; the raylib shared library is still a host dependency. On Linux the current binding targets the raylib 6.0 shared ABI (`libraylib.so.600`).

## ncurses

The standard library also includes a wide-character ncurses binding:

```simula
import Ncurses;

program Terminal;
begin
    initscr();
    cbreak();
    noecho();
    mvaddstr(c_int(1), c_int(2), "Free Simula + ncurses");
    refresh();
    getch();
    endwin()
end;
```

It binds the real exported ABI rather than pretending ncurses C macros are dynamic symbols. Linux builds use `libncursesw.so.6` and the terminal-support entries provided by `libtinfo.so.6`.

See [docs/bundled-bindings.md](docs/bundled-bindings.md) for dependency and ABI details.

## C interoperability

The Free Simula profile has a native System V AMD64 C ABI:

```simula
foreign c from "libm.so.6" begin
    function cos(value: c_double): c_double;
end;

foreign c export function triple(value: c_int): c_int;
begin
    return value * c_int(3)
end;
```

The compiler supports explicit C-width scalar types, typed `c_ptr(T)`, `c_fn`, variadics, imported data, natural/packed records, unions, opaque handles, callbacks, and aggregate argument/return classification for the documented ABI surface. Dynamic imports are emitted directly into the ELF image.

See [docs/talking-to-c.md](docs/talking-to-c.md).

## Repository layout

The public source release is deliberately small:

- `src/`: compiler, optimizer, x86-64 backend, runtime, classic runtime, and ELF writer.
- `stdlib/`: installed Free Simula modules and bundled native-library bindings.
- `examples/`: small language, raylib, and ncurses examples.
- `docs/`: language and ABI documentation.
- `fsim.lpr`: compiler entry point.

The maintainer distribution additionally contains regression tests, conformance fixtures, static audits, and release tooling. Those files are useful for development but are not required to build or use fsim.

## Release policy

A source audit is not proof that a compiler works. Before a stable tag, the maintainer tree is expected to pass a clean FPC build, self-test, native backend tests, strict Simula tests, C ABI round trips, concurrency stress, optimization differential tests, and release checks on the compiler binary that is actually being shipped.

See [docs/release-checklist.md](docs/release-checklist.md) and [docs/what-is-verified.md](docs/what-is-verified.md).

## License

See [LICENSE](LICENSE).


## Credits (me, and others that wish to be anon)

**RobertFlexx** - Project Lead, Software Developer, and Publisher/Maintainer
**Anonymous 1** - Software Developer
**Anonymous 2** - Software Developer, Assistant Lead
**Anonymous 3** - Debugger, Software Developer

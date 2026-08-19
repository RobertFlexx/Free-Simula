# Free Simula

Free Simula (`fsim`) is a native compiler for **Free Simula**, a modern successor dialect of Simula 67 for x86-64 Linux.

It started in 2022 as a school programming-history project a few friends and I worked on. We were interested in old ALGOL-family languages, wrote a Simula compiler because that sounded fun, and then kept going long after it had stopped being a sensible school project.

Free Simula exists to answer a simple question: **what would Simula look like if it had kept evolving?**

The point is not to turn Simula into C with different keywords. Free Simula keeps the recognizable ALGOL/Simula shape: `begin`/`end` blocks, classes and prefixing, `inner`, references, `new`, `inspect`, arrays, procedure values, labels, and the separate `:=` value and `:-` reference assignments. The modern profile builds on that base with modules, native strings, tasks and synchronization, C interoperability, enums, aliases, managed memory, and a larger source standard library.

`fsim` has its own x86-64 machine-code and ELF backend. Ordinary native output does not go through generated C, GCC, Clang, LLVM, `as`, or `ld`.

## Language profiles

Free Simula is the primary language of the project.

```text
-std=fsim       Free Simula, the modern successor dialect
-std=simula67   historical Standard Simula compatibility profile
```

The Free Simula profile is case-sensitive and exposes the modern native environment. The Simula 67 profile folds identifiers for classic lookup and installs the historical implicit environment.

Some classic sequencing constructs intentionally exist **only** in `-std=simula67`. `QUA`, process-class declarations, `detach`, `resume`, activation statements, `hold`, and `passivate` are rejected from the modern profile instead of quietly changing their meaning.

The classic profile is substantial, but this repository does not claim that every Standard Simula program is implemented yet. In particular, complete call-by-name environments, non-local `goto` unwinding, and the full Standard quasi-parallel continuation model are still conformance work. Unsupported native sequencing is diagnosed rather than emitted incorrectly. See [docs/simula67-conformance.md](docs/simula67-conformance.md).

## Version 3.0

This tree is **3.0.0**.

The 3.0 work concentrates on runtime latency, backend hardening, binding quality, and a stronger release gate:

- a substantially faster non-moving tracing collector with an explicit mark worklist;
- arena-local pointer lookup instead of repeated whole-heap searches;
- an exact-payload fast path for the common managed-reference case;
- reusable small-object size classes and reclaimable large mappings;
- adaptive automatic-collection pressure instead of a collection check on every small allocation;
- GC pause telemetry through the `Memory` module;
- faster word-at-a-time runtime memory copy/zero paths;
- stronger backend, optimizer, ABI, malformed-input and lowering audits;
- first-party bindings for raylib 6.0, wide-character ncurses 6, SDL3, SQLite3 and zlib;
- stricter separation between modern Free Simula constructs and classic-only sequencing.

A version number is not a magic proof of correctness. Before publishing a binary as production-certified, run the maintainer tree's complete `make certify` gate with the exact compiler binary you plan to ship. See [docs/release-checklist.md](docs/release-checklist.md).

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

For a maintainer/release build (the clean public archive intentionally omits the test and release tooling):

```sh
make certify
```

Install an already-built compiler with:

```sh
sudo make install PREFIX=/usr/local
```

This installs `fsim`, the source standard library, and the user documentation.

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

For historical source:

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

Modern lookup is case-sensitive and does not inject classic globals such as `sysout` or `blanks`.

## Memory and garbage collection

Free Simula uses a compiler-owned **non-moving tracing collector**. Managed objects stay at stable addresses, which keeps native/C interoperability practical.

The 3.0 collector is designed to avoid the periodic full-heap behavior that could make allocation-heavy programs hitch:

- small allocations first try lock-free reusable size-class lists;
- fresh small blocks come from 1 MiB `mmap` arenas;
- the ordinary small-allocation fast path does not poll the collector every allocation;
- collection uses an explicit mark worklist, so each reached allocation is scanned once;
- exact object pointers are recognized in constant time after arena lookup;
- conservative interior-pointer fallback scans only the containing arena rather than the entire heap;
- large objects live in individual mappings and dead mappings are returned to Linux;
- automatic collection pressure adapts to the measured live heap;
- collector bookkeeping is kept outside the user-global root range;
- active fsim worker stacks are not guessed at: collection is postponed while a worker is live until the runtime has a safe stack protocol.

The `Memory` module exposes useful telemetry:

```simula
import Memory;

program HeapStats;
begin
    CollectGarbage;
    outint(LiveHeapBytes);
    outimage;
    outint(GarbageCollectionLastPauseNS);
    outimage
end;
```

See [docs/memory-management.md](docs/memory-management.md).

## Standard library

The standard library is ordinary Free Simula source where practical. Low-level modules wrap compiler/runtime primitives or native ABIs where necessary.

Examples include:

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

Simulation-oriented structures, collections, algorithms, time/filesystem helpers and concurrency modules are included as well.

See [docs/standard-library.md](docs/standard-library.md).

## First-party native-library bindings

The bindings below are maintained as part of Free Simula. “First-party” means first-party to fsim; it does **not** mean the upstream library projects endorse or maintain them.

### raylib 6.0

```simula
import Raylib;
```

The binding covers the commonly used window/input, shapes, textures, images, text/fonts, cameras/3D basics, shaders, audio/music, gamepad and file APIs, with audited C-layout records for the value types crossing the ABI.

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

The Linux module targets `libraylib.so.600`; the host library remains a dependency.

### ncurses 6

```simula
import Ncurses;
```

The wide-character binding uses real exported `libncursesw.so.6`/`libtinfo.so.6` symbols and includes windows, subwindows, pads, staged refresh, bounded input, colors and terminal state operations.

### SDL3

```simula
import SDL3;
```

The SDL3 module provides a typed core surface for initialization, windows, events, keyboard/mouse input, renderers, textures, timing, clipboard and IO. ABI-sensitive types such as `SDL_Event` use the published fixed 128-byte event storage contract.

### SQLite3 and zlib

```simula
import SQLite3;
import Zlib;
```

SQLite3 covers the common database/statement/binding/column API. Zlib covers basic buffer compression/decompression, checksums, version and compile flags.

See [docs/bindings.md](docs/bindings.md).

## C interoperability

Free Simula has native System V AMD64 C interoperability:

```simula
foreign c from "libm.so.6" begin
    function cos(value: c_double): c_double;
end;

foreign c export function triple(value: c_int): c_int;
begin
    return value * c_int(3)
end;
```

The compiler supports explicit C-width scalar types, typed `c_ptr(T)`, C function pointers, variadics, imported data, natural/packed records, unions, opaque handles, callbacks, and aggregate argument/return classification for the documented SysV AMD64 surface. Dynamic imports are emitted directly into the generated ELF image.

See [docs/c-interop.md](docs/c-interop.md).

## Diagnostics

Normal text diagnostics include the source line and a caret/span underline in addition to the stable diagnostic code, while `--diagnostic-format=json` remains available for editors and tooling. `-Werror` promotes warnings without changing the underlying diagnostic code.

For example, an error is reported in the familiar form:

```text
main.sim:12:9: error [type-mismatch]: expected integer, got text
  total := title;
           ^^^^^
```

## Optimization

`-O0`, `-O1`, `-O2`, `-O3`, and `-Ofast` are supported. The optimizer works over typed three-address IR and includes constant/copy propagation, algebraic folding, reachability cleanup, DCE, local CSE, branch threading, conservative load forwarding/dead stores, integer strength reduction, tail-call discovery, dominator/loop analysis and fixed-point cleanup.

Optimization passes are required to preserve verified IR. If an advanced pass fails internally, the compiler can roll back instead of silently emitting damaged IR; release tests compare deterministic programs across optimization levels.

See [docs/optimization-pipeline.md](docs/optimization-pipeline.md).

## Repository layout

The public source release is intentionally small:

- `src/` — compiler, optimizer, x86-64 backend, runtimes, and ELF writer;
- `stdlib/` — installed source modules and bundled native-library bindings;
- `examples/` — language and binding examples;
- `docs/` — language, runtime, ABI and release documentation;
- `fsim.lpr` — compiler entry point.

The maintainer distribution additionally contains tests, conformance fixtures, stress suites, static audits, benchmarks and release tooling.

## Release policy

A source audit is not proof that a compiler works. `make certify` is the release gate and must run against the exact compiler binary being shipped. It includes the static compiler/backend audits, clean compiler build, unit tests, strict-Simula suite, C ABI round trips, GC regressions, concurrency stress, malformed-input tests, optimization differential tests, lowering canaries and the generated conformance corpus.

Known Standard Simula gaps remain documented instead of being hidden behind a “production” label. See [docs/release-checklist.md](docs/release-checklist.md), [docs/verification-status.md](docs/verification-status.md), and [docs/simula67-conformance.md](docs/simula67-conformance.md).

## License

See [LICENSE](LICENSE).

## Credits

Free Simula has been worked on by me and several friends, some of whom prefer to remain anonymous.

**RobertFlexx** — project lead, software developer, publisher and maintainer  
**Anonymous 1** — software developer  
**Anonymous 2** — software developer and assistant lead  
**Anonymous 3** — debugging and software development

## Extras

**WE** need help to add Simula recognition to github linguist. **ANYONE** can help

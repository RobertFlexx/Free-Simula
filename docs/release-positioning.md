# Release positioning

Free Simula is a native Simula-family compiler and modern successor dialect. It keeps ALGOL/Simula block structure, prefix classes, `inner`, references, `new`, `inspect`, classic arrays, procedure values, `:=`/`:-`, labels/switches and the classic expression/object model as its foundation.

The `fsim` profile adds modules, modern strings, native concurrency, garbage-collected managed storage, C interoperability, enums, aliases and an expanded source library without turning the language into a C-family syntax.

## Defensible wording for 3.0.0

- native x86-64 Linux Free Simula compiler;
- modern direct Simula successor dialect rooted in ALGOL and Simula;
- substantial native Simula 67 compatibility profile through `-std=simula67`;
- native ELF backend with no GCC/Clang/LLVM/`as`/`ld` requirement for ordinary output;
- compiler-owned non-moving tracing heap with reusable small-object classes, reclaimable large mappings, worklist marking, adaptive pressure and pause telemetry;
- native System V AMD64 C interoperability for the documented ABI surface;
- first-party fsim bindings for raylib 6.0, ncurses 6, SDL3, SQLite3 and zlib on Linux.

## Claims to avoid

Do not say “100% Standard SIMULA”, “fully Standard SIMULA-conforming”, “compiles every Simula 67 program”, “bug-free”, “guaranteed stable”, or “upstream-official raylib/SDL/ncurses bindings”.

The Standard's quasi-parallel sequencing model is more than a `resume` keyword: it requires saved reactivation points, operating/reactivation chains, and the specified state transitions between attached, detached, resumed and terminated class objects. The native backend still rejects that incomplete continuation path rather than emitting a fake coroutine.

General call-by-name environments, non-local `goto` unwinding, full quasi-parallel sequencing/Simulation continuations, parts of the historical file/environment surface and arbitrary historical external object formats remain outside the proven implementation.

A defensible short description is:

> Free Simula is a native x86-64 modern Simula successor with a substantial Simula 67 compatibility mode, native C interoperability, concurrency, managed memory, and a source standard library.

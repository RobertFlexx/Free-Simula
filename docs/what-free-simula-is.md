# What Free Simula is

Free Simula is a native Simula-family compiler and a direct modern Simula dialect. It deliberately keeps the ALGOL/Simula block structure, prefix classes, `inner`, `Ref`, `new`, `inspect`, classic arrays, procedure values, `:=`/`:-`, labels/switches, and the classic expression model as its base. The base language is the point, not an obstacle to be modernized away.

The `fsim` profile adds modules, modern strings, native concurrency, garbage-collected managed storage, C interoperability, enums, aliases, and an expanded source library without replacing that base language. You get the old bones and new organs, all in one animal.

## Supported wording for 2.0.0-rc2

- native x86-64 Linux Simula-family compiler;
- direct modern Free Simula dialect rooted in ALGOL and Simula;
- substantial native Simula 67 compatibility profile through `-std=simula67`;
- native ELF backend with no GCC/Clang/LLVM/`as`/`ld` requirement for ordinary output;
- compiler-owned non-moving tracing heap;
- native System V AMD64 C interoperability for the documented ABI surface;
- bundled first-party Free Simula bindings for raylib 6.0 and ncurses 6 on Linux.

## Claims to avoid

Do not say "100% Standard SIMULA", "fully Standard SIMULA-conforming", "compiles every Simula 67 program", "bug-free", or "guaranteed stable". General call-by-name, non-local goto unwinding, the complete historical `Simulation` continuation/scheduler model, parts of the historical file/environment surface, and arbitrary historical external object formats remain outside the currently proven implementation. Saying otherwise would be marketing, and this project does not do marketing.

A defensible short description is:

> Free Simula is a native x86-64 Simula-family compiler and modern direct Simula dialect, with a substantial Simula 67 compatibility mode, native C interoperability, concurrency, managed memory, and a source standard library.

That sentence has been through the wringer. Use it without fear.

# Release checklist

This checklist is intentionally stricter than “the source audit passed”. A compiler release is certified only when the exact binary being distributed passes the dynamic gates.

## Source and package

- [ ] `make static-check` passes for this exact release tree.
- [ ] Public source archive contains only compiler, stdlib, examples, docs, build files, license, changelog and version metadata.
- [ ] Maintainer archive retains tests/audits/benchmarks used to validate the release.
- [ ] TAR/ZIP payloads and SHA-256 sums verify.
- [x] Known partial Simula semantics are documented without a false universal-conformance claim.

## Compiler/runtime

- [ ] Clean FPC 3.2.2+ build succeeds.
- [ ] `./bin/fsim --self-test` passes.
- [ ] `make test` passes.
- [ ] `make certify` passes from a clean tree.
- [ ] Multi-cycle GC reclamation and pause-stat regressions pass at release optimization levels.
- [ ] Program-global-state and C-float-record regressions pass at release optimization levels.
- [ ] Concurrency stress passes repeatedly; task-stack lifetime/reclamation remains clean.
- [ ] Optimization differential tests agree at release levels.
- [ ] Frontend robustness/malformed-input tests produce diagnostics rather than internal compiler failures.
- [ ] Lowering canaries pass with the release backend.

## Simula 67

- [ ] Strict Simula suite passes native/check/rejection/trap categories.
- [ ] Full generated compatibility corpus completes under the rebuilt compiler.
- [ ] `QUA` works in `-std=simula67` and rejects in `-std=fsim`.
- [ ] classic process/sequencing syntax rejects from `-std=fsim`.
- [ ] Known unsupported Standard sequencing/continuation cases still reject cleanly rather than miscompile.
- [ ] Any future claim of complete quasi-parallel sequencing is backed by native detach/call/resume continuation tests, not parser-only tests.

## C ABI and bundled bindings

- [ ] `make test-ffi` passes imports/exports/aggregates/varargs/callbacks.
- [ ] ELF audit confirms only declared dynamic dependencies are emitted.
- [ ] raylib example compiles and runs against raylib 6.0.
- [ ] ncurses example compiles and runs in a real terminal.
- [ ] SDL3 example compiles and opens/closes cleanly against the supported SDL3 ABI.
- [ ] SQLite3 example compiles/runs against `libsqlite3.so.0`.
- [ ] zlib example compiles/runs against `libz.so.1`.
- [ ] binding symbol audit passes against every available validation-host DSO.

## Performance sanity

- [ ] compile benchmark completes without a major regression from the previous release on the same host.
- [ ] GC pressure test shows bounded live heap and successful reclamation across repeated cycles.
- [ ] GC pause telemetry is nonzero and internally monotonic/consistent.
- [ ] `-O0`/`-O3` differential execution agrees for deterministic regression programs.

Only publish a binary as production-certified after every required dynamic gate applicable to that binary is green.

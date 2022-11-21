# Release checklist

(from what i know, plus what i keep relearning)

## Source and package

- [ ] `make static-check` passes for this exact release tree.
- [ ] Public source archive contains only compiler, stdlib, examples, docs, build files, license, changelog, and version metadata.
- [ ] Maintainer archive retains tests/audits used to validate the release.
- [ ] TAR/ZIP payloads and SHA-256 sums are verified.
- [x] Known partial Simula semantics are documented without a false universal-conformance claim.

## Compiler/runtime

- [ ] Clean FPC 3.2.2+ build succeeds.
- [ ] `./bin/fsim --self-test` passes.
- [ ] `make test` passes.
- [ ] `make release-check` passes.
- [ ] GC reclamation/pinning regression passes under the rebuilt 2.0 compiler.
- [ ] Program-global-state and C-float-record regressions pass at release optimization levels.
- [ ] Concurrency stress passes repeatedly; task-stack lifetime/reclamation stays clean.
- [ ] Optimization differential tests agree at release levels.

## Simula 67

- [ ] Strict Simula suite passes native/check/rejection/trap categories.
- [ ] Full generated compatibility corpus completes under the rebuilt compiler.
- [ ] Any known unsupported Standard semantics still reject cleanly rather than miscompile.

## C ABI and bundled bindings

- [ ] `make test-ffi` passes imports/exports/aggregates/varargs/callbacks.
- [ ] ELF audit confirms only declared dynamic dependencies are emitted.
- [ ] raylib example compiles and runs against raylib 6.0.
- [ ] ncurses example compiles and runs in a real terminal. Not a pretend terminal. A real one.

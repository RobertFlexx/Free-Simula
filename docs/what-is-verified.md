# Verification status

This source snapshot is `2.0.0-rc2`.

Signed off by RobertFlexx, the project lead, who is the one running these checks. The semicolon is me winking, because we all know how much verification deserves one. ;)

## What has been checked in the artifact environment

The release source passed through the maintainer static audit set, including Pascal structure/API/order checks, compiler wiring audits, range/optimizer/native-frame/native-parameter/native-aggregate/native-clobber checks, parser regressions, label checks, C-ABI audits, higher-order wiring, and Free Simula source/comment validation.

The existing 1.6.1 compiler frontend has also been used as an independent syntax/type-check smoke test for the new `Raylib` and `Ncurses` modules and their examples. That does not validate 2.0 runtime code generation. It validates that the source looks right, not that the machine code is right.

The ncurses example was dynamically smoke-tested against the host `libncursesw.so.6`/`libtinfo.so.6` ABI, and all imported ncurses/tinfo symbols in the bundled module were checked against exported dynamic symbols on the test host.

The release misc passed, among other things:

- stable writable storage for program-scope variables used by nested procedures;
- non-moving managed allocation with reusable small blocks and reclaimable large mappings;
- separation of program GC roots from allocator bookkeeping;
- transient mark-bit clearing across collection cycles;
- native task-stack lifetime barriers based on the kernel-cleared child TID;
- `c_float` C-record field stores that previously could clobber their destination-address register;
- raylib/ncurses binding parser keyword collisions and explicit C pointer types;
- Standard SIMULA class `text` parameter construction, plus explicit `value text` copy-on-entry for procedures and classes.

## Required dynamic gate

This artifact environment does not contain an executable Free Pascal compiler. The modified Object Pascal compiler therefore has **not** been rebuilt and executed here. I am not going to pretend otherwise; the whole point of this file is the truth.

Before changing the version from a release candidate to a stable tag, build it on Linux x86-64 with FPC 3.2.2 or newer and run:

```sh
make clean
make
./bin/fsim --self-test
make test-simula67
make test-concurrency-stress
make test-ffi
make test
make release-check
```

For the full generated corpus:

```sh
FSIM_FULL_CONFORMANCE=1 make test-generated
```

The bundled raylib example should additionally be compiled and run with raylib 6.0 installed, and the ncurses example should be run in a real terminal.

No release should claim universal Standard SIMULA conformance while the semantic blockers in [simula67-conformance.md](simula67-conformance.md) remain open. work on this is WORK IN PROGRESS PEOPLE!

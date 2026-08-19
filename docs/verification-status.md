# Verification status

This source snapshot is `3.0.0`.

## Verified in the artifact environment

The 3.0 source has passed the maintainer static compiler/backend audits available without Free Pascal, including Pascal structure/API/order checks, compiler wiring, range/optimizer safety, native frame/parameter/aggregate/handle/clobber checks, GC runtime invariants, parser regressions, native-label/OS/C-ABI audits, dialect-boundary checks, higher-order wiring, binding audits and repository Free Simula source validation.

The GC hardening audit checks the 3.0 worklist mark path, arena-local candidate lookup, exact-payload fast path, adaptive arena pressure, program-root separation, pinning behavior, large-object reclamation wiring and pause-stat labels.

An existing older fsim frontend has also been used as an independent parser/type smoke test for all five bundled native-library binding modules and their examples. That validates source compatibility, not the modified 3.0 backend.

On the validation host:

- every declared ncurses/tinfo import in the expanded module resolves to an exported host symbol;
- every declared SQLite3 and zlib import resolves to an exported host symbol;
- the SQLite3 and zlib example programs compiled with the older compiler and executed successfully against the host DSOs;
- the ncurses example compiled and entered its terminal UI under a PTY;
- raylib 6.0 and SDL3 are not installed in this artifact environment, so their 3.0 dynamic examples have not been executed here.

## Not certified in this artifact environment

This environment does not currently provide a usable Free Pascal compiler executable. The modified 3.0 Object Pascal compiler therefore has **not** been rebuilt and dynamically certified here.

Before publishing a production binary, build the exact tree on Linux x86-64 with FPC 3.2.2 or newer and run:

```sh
make clean
make
./bin/fsim --self-test
make certify
```

The complete gate includes strict Simula tests, C ABI round trips, concurrency stress, GC regressions, malformed-source robustness, optimization differential execution, lowering canaries and the full generated corpus.

## Standard Simula boundary

`QUA` and classic process/sequencing syntax are restricted to `-std=simula67`; modern mode diagnoses them.

The native backend does **not** yet claim complete Standard quasi-parallel sequencing. Standard detach/call/resume semantics require saved continuation/reactivation points and operating/reactivation-chain transitions. Known incomplete native paths diagnose rather than silently compile with different coroutine semantics.

No release should claim universal Standard Simula conformance until the blockers in [simula67-conformance.md](simula67-conformance.md) are closed and validated by native execution.

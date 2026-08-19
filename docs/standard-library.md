# Standard library

Free Simula 3.0 ships 49 source modules. Most are written in Free Simula; low-level operations that require an OS, runtime, or C ABI boundary use compiler intrinsics or `foreign c`.

## Import resolution

```simula
import Math;
import StringAlgorithms;
import Memory;
import "local.sim";
```

Lookup is deterministic: importing directory, explicit `-I` paths, `FSIM_PATH`, `--stdlib-path`, `FSIM_STDLIB`, installed `share/fsim/stdlib`, then source-tree fallbacks. Dependency files are available with `-MD`, `-MF`, and `--depfile`.

## Collections and algorithms

`Algorithms`, `Searching`, `Sorting`, `IntegerCollections`, `Deque`, `PriorityQueue`, `RingBuffer`, `DisjointSet`, `Matrix`, and `StateMachine` provide common explicit data structures and algorithms.

## Numeric and data helpers

`Math`, `Numerics`, `Statistics`, `Random`, `RandomDistributions`, `Geometry`, `Histogram`, `Option`, `Result`, `Assertions`, and `Prelude` cover arithmetic, statistics, deterministic random helpers, geometry, result/optional values, and contracts.

## Strings and systems

`Strings`, `StringAlgorithms`, and `TextBuilder` provide dynamic-string helpers including prefix/suffix tests, search, slicing, construction, checked byte access, and integer parsing.

`Filesystem` wraps the native filesystem boundary. `Time` provides monotonic timing, sleeping, thread IDs, and a stopwatch. `Bits` contains integer bit helpers. `Memory` exposes garbage-collection statistics, pause telemetry, explicit collection and foreign-pointer pin/unpin.

## Concurrency

`Concurrency`, `Tasking`, `Futures`, `Atomics`, `Synchronization`, and `BoundedChannel` wrap native tasks/futures, atomics, futex-backed mutex/semaphore/barrier/condition handles, and typed communication.

These modern facilities do not leak into `-std=simula67`.

## Simulation-oriented modules

`ClassicText`, `ClassicQueue`, `Simset`, `Process`, `Simulation`, `EventCalendar`, `ResourceFacility`, `QueueStatistics`, `SimulationMetrics`, and `Environment` provide source-level simulation structures and adapters.

They are not a substitute for the strict profile's implicit Standard Simula environment. Exact historical compatibility lives in [simula67-conformance.md](simula67-conformance.md).

## Native-library bindings

The installed first-party native-library modules are:

```simula
import Raylib;
import Ncurses;
import SDL3;
import SQLite3;
import Zlib;
```

The corresponding native shared libraries remain host dependencies. See [bindings.md](bindings.md).

## Validation

Maintainer releases run frontend checks over every installed source module. The binding audit additionally checks declared imported symbols against available host DSOs, and executable examples are used where the host has the required libraries.

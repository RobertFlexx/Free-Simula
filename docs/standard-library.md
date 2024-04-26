# Standard library

Free Simula 2.0.0-rc2 ships 46 source modules. Most are written in Free Simula; low-level operations that require an OS, runtime, or C ABI boundary use compiler intrinsics or `foreign c`. The library is source you can read, which is the best kind of library.

## Import resolution

```simula
import Math;
import StringAlgorithms;
import Memory;
import "local.sim";
```

Lookup is deterministic: importing directory, explicit `-I` paths, `FSIM_PATH`, `--stdlib-path`, `FSIM_STDLIB`, installed `share/fsim/stdlib`, then source-tree fallbacks. Dependency files are available with `-MD`, `-MF`, and `--depfile`.

## Collections and algorithms

`Algorithms`, `Searching`, `Sorting`, `IntegerCollections`, `Deque`, `PriorityQueue`, `RingBuffer`, `DisjointSet`, `Matrix`, and `StateMachine` provide common explicit data structures and algorithms. Everything is explicit, because hidden magic belongs in card tricks, not libraries.

## Numeric and data helpers

`Math`, `Numerics`, `Statistics`, `Random`, `RandomDistributions`, `Geometry`, `Histogram`, `Option`, `Result`, `Assertions`, and `Prelude` cover arithmetic, statistics, deterministic random helpers, geometry, result/optional values, and contracts.

## Strings and systems

`Strings`, `StringAlgorithms`, and `TextBuilder` provide dynamic-string helpers including prefix/suffix tests, search, slicing, construction, checked byte access, and integer parsing.

`Filesystem` wraps the native filesystem boundary. `Time` provides monotonic timing, sleeping, thread IDs, and a stopwatch. `Bits` contains integer bit helpers. `Memory` exposes garbage-collection statistics plus explicit collection and foreign-pointer liveness pinning.

## Concurrency

`Concurrency`, `Tasking`, `Futures`, `Atomics`, `Synchronization`, and `BoundedChannel` wrap native tasks/futures, atomics, futex-backed mutex/semaphore/barrier/condition handles, and typed communication.

These modules do not leak into `-std=simula67`; imports and modern native builtins belong to the Free Simula profile. The classic profile gets classic things and does not want your channel.

## Simulation-oriented modules

`ClassicText`, `ClassicQueue`, `Simset`, `Process`, `Simulation`, `EventCalendar`, `ResourceFacility`, `QueueStatistics`, `SimulationMetrics`, and `Environment` provide source-level simulation structures and adapters.

They are not a substitute for the strict profile's implicit Standard SIMULA environment. Exact historical compatibility lives in [simula67-conformance.md](simula67-conformance.md).

## Native-library bindings

`Raylib` is the bundled raylib 6.0 C-ABI module. `Ncurses` is the bundled Linux wide-character ncurses 6 module. They are installed with the rest of the standard library, so source can simply use:

```simula
import Raylib;
import Ncurses;
```

The corresponding host shared libraries still need to be installed. See [bundled-bindings.md](bundled-bindings.md).

## Validation

Maintainer releases run frontend checks over the library and executable integration tests for modules that cross runtime/OS/foreign-library boundaries. Static source auditing is useful, but it is not treated as proof of runtime correctness. Reading the source tells you what the library does; running it tells you what the library does on a Tuesday.

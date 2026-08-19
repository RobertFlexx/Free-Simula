# Memory management

Free Simula 3.0 uses a compiler-owned, non-moving tracing heap on Linux x86-64. It does not depend on libc `malloc` or an external garbage collector.

The collector is deliberately non-moving: managed addresses remain stable for native calls, interior pointers, classic text/frame operations and explicitly pinned foreign references.

## Managed allocation

Every managed allocation has a 32-byte runtime header followed by the payload returned to generated code.

Small payloads up to 32 KiB are rounded to power-of-two size classes. Allocation first checks a lock-free reusable free list. Fresh blocks come from 1 MiB `mmap` arenas through a CAS bump pointer. A dead small block is cleared and returned to its size class at sweep time.

Large payloads receive their own anonymous mapping. Dead large mappings are unlinked and returned to Linux with `munmap`.

The normal small-object hot path does **not** ask whether a GC is needed on every allocation. Automatic collection pressure is checked at arena refill and large-allocation boundaries instead.

## 3.0 mark path

The older collector could repeatedly search the complete managed-allocation list while interpreting conservative pointer candidates, and then repeat whole-heap scans to discover transitive reachability. That behavior could turn a collection into far more work than the number of live objects justified.

3.0 uses an explicit mark worklist:

1. transient mark/scanned state is cleared;
2. roots are examined;
3. each newly reached allocation is marked and linked onto the worklist;
4. each marked payload is scanned once;
5. sweep reclaims everything that remains unmarked.

Pointer validation has two paths:

- an exact-payload fast path checks the candidate's header after locating its arena;
- an interior-pointer fallback scans only the containing 1 MiB arena.

Large mappings are kept separately and are only searched when the candidate lies in the managed large-object address range.

The collector maintains a coarse minimum/maximum managed-address range so obviously unrelated values are rejected before any arena work.

## Roots

Roots currently include:

- the active main-thread stack, including callee-saved state preserved by the collector;
- program-owned writable global storage;
- explicitly pinned managed allocations.

Allocator/free-list metadata is not part of the program-global root range. Otherwise the collector could keep its own object list alive by mistake.

Payloads are conservatively scanned one machine word at a time. A word retains an allocation only when it resolves to a currently allocated managed block. Interior pointers are supported. As with other conservative collectors, unrelated integer data that happens to resemble a managed address can delay reclamation.

## Collection scheduling

Automatic GC pressure is measured in fresh arena/large-allocation events rather than every small object allocation. After a completed collection, the next arena trigger adapts to the live-heap size and is clamped to a bounded range.

This deliberately trades some memory headroom for much lower allocator overhead and fewer surprise collections in allocation-heavy programs.

Applications with known quiet points can explicitly call `CollectGarbage` from the `Memory` module.

## Pause telemetry

The runtime records monotonic pause statistics for completed collections:

```simula
import Memory;

program Stats;
begin
    CollectGarbage;
    outint(GarbageCollectionCount);
    outimage;
    outint(GarbageCollectionLastPauseNS);
    outimage;
    outint(GarbageCollectionMaxPauseNS);
    outimage;
    outint(GarbageCollectionTotalPauseNS);
    outimage
end;
```

These values make it possible to distinguish a GC hitch from rendering, IO, shader compilation, driver stalls or some other source of frame-time spikes.

## Native tasks

A native task descriptor and task stack are one managed allocation. Linux `CLONE_CHILD_SETTID`/`CLONE_CHILD_CLEARTID` provides the lifetime barrier: a completed task allocation is not reclaimable until the kernel has cleared the child TID.

The current collector postpones collection while an fsim native worker has a nonzero child TID. This is intentionally conservative. Freeing or scanning a concurrently mutating stack without a real stop-the-world handshake would be incorrect.

A future concurrent/thread-aware collector can replace this gate, but 3.0 does not pretend that protocol already exists.

## Foreign pointers

If native code keeps a pointer into managed storage after the call returns, pin the allocation before handing the pointer away and unpin it only after the foreign owner has finished:

```simula
PinManagedPointer(pointer);
...
UnpinManagedPointer(pointer);
```

Pinning is a liveness operation, not ownership transfer. C allocations are not automatically adopted by the fsim collector.

## Runtime memory operations

The native runtime copy/zero helpers process aligned word-sized chunks before handling byte tails. This avoids byte-at-a-time loops for ordinary object/record initialization and copies without requiring an external libc implementation.

## Release gates

The maintainer tree contains multi-cycle reclamation and pause-stat regressions in addition to static runtime-structure auditing. The full 3.0 release gate must run these tests on a compiler rebuilt from the exact source tree being shipped.

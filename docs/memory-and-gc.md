# Memory and garbage collection

Free Simula 2.0 uses a compiler-owned, non-moving tracing heap on Linux x86-64. It does not depend on libc `malloc` or an external garbage collector. The collector is ours, the bugs are ours, and so is the fix.

## Managed allocation

Every managed allocation has a small runtime header followed by the payload returned to generated code. Objects never move after allocation, which is the single most important fact in this document because it is what keeps C interop and interior pointers sane.

Small payloads (up to 32 KiB) are rounded to a power-of-two size class. Fresh small blocks come from 1 MiB `mmap` arenas through a CAS bump pointer. When the collector proves a small block dead, the block is cleared and returned to a lock-free size-class free list for reuse.

Large payloads receive their own anonymous mapping. Dead large allocations are unlinked from the managed allocation list and returned to Linux with `munmap`. Big objects get their own room, and when they die, the room goes back to the system.

## Collection

Collection is mark-and-sweep and non-moving.

Roots currently include:

- the active main-thread stack, including callee-saved registers preserved by the collector;
- program-scope writable variables;
- allocations explicitly pinned for foreign code.

The collector deliberately does **not** treat its allocator/free-list bookkeeping as a root range. Keeping your own notes does not make them live data.

Managed payloads are conservatively scanned one machine word at a time. A word is treated as a reference only when it points into the payload of a currently allocated managed block. Interior pointers therefore keep their allocation alive. This is useful for C interop and classic text/frame operations, but like other conservative collectors it can retain an otherwise dead object if unrelated integer data happens to look like a managed address. Yes, that can happen. No, we do not have a better idea that is still fast.

## Native tasks

A native task descriptor and its task stack are one managed allocation. Linux `CLONE_CHILD_SETTID`/`CLONE_CHILD_CLEARTID` provides the lifetime barrier used by the runtime: `join` waits until the child TID has been cleared before the task allocation can become reclaimable. The kernel does the cleanup, which means the cleanup actually happens.

The collector currently postpones a collection while any fsim native worker has a nonzero child TID. This avoids scanning a concurrently changing foreign stack without pretending a stop-the-world protocol exists. It also means a program with a permanently live worker can grow its managed heap until that worker exits. A future concurrent or stop-the-world collector can remove this restriction without changing the object ABI. We call this "correct now, fancy later".

## C pointers and pinning

The heap is non-moving, so pinning is about **liveness**, not address stability. The address was always stable; the object just needed permission to stay alive.

If C only borrows a managed pointer for the duration of a foreign call, no extra action is required as long as the Free Simula reference remains live.

If a C library retains a managed pointer after the call returns, explicitly pin that allocation before handing the pointer over and unpin it when the C library releases ownership:

```simula
import Memory;

! pointer is a c_ptr(c_void) into managed storage;
assert(PinManagedPointer(pointer));
! C may retain pointer here;
assert(UnpinManagedPointer(pointer));
```

Pin/unpin accepts an exact or interior pointer into a managed allocation. It returns false for null, unmanaged, or already-reclaimed storage.

## Diagnostics API

`Memory` exposes:

- `CollectGarbage`
- `LiveHeapBytes`
- `ReclaimedHeapBytes`
- `GarbageCollectionCount`
- `PinManagedPointer`
- `UnpinManagedPointer`

The byte counters describe managed payload bytes, not total process RSS or allocator metadata. If you want RSS, ask Linux. The collector only knows about its own house.

## Resources are not garbage-collected

Memory reachability is not a replacement for deterministic release of files, sockets, terminal state, GPU resources, or foreign-library handles. Those resources should continue to use the library's explicit close/unload APIs. The garbage collector will not close your terminal, and it refuses to feel bad about it.

The parser/IR contains work toward `defer`, but it is not advertised as native-release-ready until all scope exits and cross-function exception unwinding have a tested lowering. A resource API must not depend on GC timing in the meantime. "The collector will get to it" is not a resource management strategy.

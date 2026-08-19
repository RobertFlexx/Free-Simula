# Native concurrency

modern fsim concurrency is deliberately separate from classic SIMULA process sequencing. `-std=simula67` does not receive these names or types.

## tasks and futures

`Task Class` and `Thread Class` routines can be launched with `spawn` or `async`. The linux x86-64 backend creates native tasks directly with `clone`; completion is published through a shared descriptor and `join`/`await` sleep on a private futex instead of polling.

```simula
Task Class Worker;
begin
    Public:
    integer function Run;
    begin
        return 42
    end
end;

program Main;
begin
    Ref(Worker) worker;
    future(integer) work;
    worker :- new Worker();
    work :- spawn worker.Run();
    assert(await work = 42)
end;
```

cancellation is cooperative. `cancel work` sets a cancellation-request flag, but the future does not become terminal until the native task actually leaves its entry routine. this prevents `await` from returning while cancelled code is still executing. `future_ready`, `future_cancel_requested`, `future_state`, and `future_thread_id` expose descriptor state without changing it.

current native spawn ABI carries either a method receiver or one machine-word argument. multi-argument capture frames and lexical closures are not finished yet, so the semantic pass rejects task calls that would otherwise lose arguments. rejecting it is intentional, silently dropping an argument would be insane.

## channels and locks

`channel(T)` is a compiler-owned synchronized handoff cell. blocking channel operations use futex wait/wake paths under contention.

`mutex` has a small atomic uncontended path and futex-backed waiting. `lock`, `unlock`, and `mutex_try_lock` operate on the native handle.

`critical begin ... end` and `synchronized begin ... end` use the same process-wide futex-backed critical region. the region is currently non-reentrant, so code should not nest it in the same thread.

## atomics and synchronization handles

`atomic(integer)` is an fsim-only native handle. current primitives are `atomic_load`, `atomic_store`, `atomic_exchange`, `atomic_compare_exchange`, `atomic_fetch_add`, and `atomic_fetch_sub`.

semaphores, barriers, and conditions are compiler-owned handles too:

- `semaphore_init`, `semaphore_wait`, `semaphore_try_wait`, `semaphore_post`
- `barrier_init`, `barrier_wait`
- `condition_wait`, `condition_signal`, `condition_broadcast`

condition wait releases the supplied mutex, sleeps on a sequence futex, and reacquires the mutex before returning. barriers use a generation counter so one completed round cannot be mistaken for the next.

## timing

`thread_id`, `monotonic_ns`, and `sleep_ns` are direct native helpers. `stdlib/time.sim` wraps them with millisecond and microsecond helpers plus a small stopwatch class.

## allocation

small modern runtime allocations use a process-lifetime one-megabyte mmap arena. the normal allocation hot path reserves aligned space with a compare-and-swap bump pointer; a lock is only taken when a new slab has to be mapped. large allocations still receive their own mapping.

this is intentionally simple and fast for compiler-owned descriptors and short-lived native programs. general-purpose reclamation and a moving garbage collector are not part of the ABI.

## structured concurrency status

`parallel begin ... end` is recognized by the frontend but the native backend currently rejects it because real structured task lowering needs capture frames, child lifetime tracking, and exception propagation. it is not emitted as a no-op.

`defer` is in the same category: syntax exists, native code generation rejects it until scope-exit lowering is correct on every exit edge.

explicit `spawn`/`async`, `await`, `join`, channels, atomics, locks, semaphores, barriers, conditions, and `synchronized` are the usable native concurrency surface in this release.

## runtime boundaries

native tasks currently use dedicated mapped stacks and do not yet provide work stealing, a fixed async executor pool, stack guard pages, or automatic task-stack reclamation. those are runtime engineering targets, not features the compiler pretends are already there.

classic `Process Class`, SIMSET, activation and `Simulation` belong to the historical runtime and are tracked separately in `simula67-conformance.md`.

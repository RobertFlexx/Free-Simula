# the two profiles

fsim has two deliberately separate profiles. selecting a profile changes name lookup, the implicit environment, accepted syntax, and the runtime ABI. they are not skins over the same compiler; they are two contracts with one compiler underneath.

## `-std=simula67`

this profile keeps the classical language shape:

- ALGOL `begin`/`end` blocks and classic declaration order
- `:=` value assignment and `:-` reference/text-frame binding
- prefix classes, `inner`, virtual specifications, `Ref(C)`, `new`, `none`, `this`, `QUA`
- classic arrays, procedures, labels, switches, `go to`, `inspect`, `when`, `otherwise`
- process vocabulary including `detach`, `resume`, `activate`, `reactivate`, `hold` and `passivate`
- fixed-frame `text` and the strict standard environment
- case-insensitive identifier resolution as required by the historical profile

modern fsim constructs diagnose in this mode. dynamic `string`, modules, Pascal `var`, native tasks/futures/channels/atomics, modern visibility sections, and the native OS surface are not implicitly available. if you want them, you picked the wrong profile, which is fine, that is what the other one is for.

`simula67` compatibility is a runtime/semantic target, not a parser costume. the exact implemented boundary and remaining blockers are listed in `simula67-conformance.md`.

## `-std=fsim`

free simula retains the useful classical forms but adds modern ALGOL-family conveniences rather than replacing the language with C syntax:

- exact case-sensitive user identifier lookup
- `Public:`, `Protected:` and `Private:` sections
- `var name: type`, Pascal-style parameter/result annotations, constants, aliases and enums
- `repeat`, `case` and `with`
- modules/imports/exports
- dynamic native `string` values
- integer `and`, `or`, `xor`, `shl` and `shr` bit operations while boolean operators retain boolean semantics
- `Task Class`, `Thread Class`, `channel(T)`, `future(T)`, `mutex`, `semaphore`, `barrier`, `condition` and `atomic(integer)`
- `spawn`, `async`, `await`, `join`, `cancel`, `yield`, `send`, `receive`, `critical` and `synchronized`
- thread-local declarations and direct native Linux systems helpers under explicit `os_` names
- Unicode identifiers validated from generated Unicode tables

classic implicit names such as `sysin`, `sysout` and `blanks` are not installed in this profile, so modern programs can use those spellings themselves. name collisions are a you problem, and this time you get to win them.

## assignment separation

both profiles keep the Simula distinction:

```simula
count := count + 1;
object :- new Worker();
```

`:=` is value assignment. `:-` is reference binding and performs reference/class compatibility checks. strict `text` additionally uses this distinction for frame transfer versus frame rebinding. two operators, two meanings, both checked.

## features recognized but not silently faked

`parallel` and `defer` have frontend/IR representation, but native lowering rejects them until structured task capture and general scope-exit cleanup are complete. this is deliberate. successful compilation must mean the backend can preserve the construct's semantics. a program that compiles and is wrong is worse than a program that refuses to compile, and we are not shipping the first one.

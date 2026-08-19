# 3.0.0 — 2026-08-19

- redesigned the managed-heap mark path around an explicit worklist so each reached allocation is scanned once instead of repeatedly rescanning the whole heap for transitive references
- replaced whole-allocation-list pointer candidate searches with managed-address rejection, arena-local lookup, an exact-payload fast path, and interior-pointer fallback limited to the containing arena
- moved automatic GC pressure checks off the ordinary small-allocation hot path; fresh arena/large-allocation events drive an adaptive bounded collection trigger instead
- retained lock-free reusable small-object size classes, individual large mappings and non-moving addresses while adding real monotonic last/max/total GC pause telemetry
- sped up native runtime memory copy/zero helpers with qword loops plus byte tails
- added repeated multi-cycle reclamation and pause-stat regressions and strengthened the static GC runtime release audit around worklist, root-range and scheduling invariants
- made `QUA`, process-class declarations and classic sequencing operations explicit `simula67`-only constructs; modern fsim mode diagnoses them instead of mixing historical continuation semantics with native tasks
- documented the actual Standard quasi-parallel boundary: detach/call/resume requires saved reactivation points and operating/reactivation chains, so still-incomplete native continuation cases continue to reject rather than silently behaving like modern coroutines
- expanded the first-party raylib 6.0 binding with shader, file/directory, drawing-mode, gamepad and additional shapes APIs; corrected the 6.0 `FilePathList` ABI to its published count-plus-paths layout
- expanded the ncurses 6 binding with pads/subwindows, staged refresh, bounded input and window synchronization helpers
- added first-party SDL3, SQLite3 and zlib source bindings plus examples; SDL event storage follows the published fixed 128-byte ABI contract
- extended binding release auditing to verify typed declarations and, when a host DSO is available, every imported dynamic symbol against the actual exported symbol table
- added `make certify` as the explicit full release gate and strengthened release documentation around GC latency, backend/optimizer differential testing, ABI smoke tests and honest Standard-Simula conformance claims
- versioned the source tree as 3.0.0; production binary certification still requires the complete dynamic release gate on the exact rebuilt compiler being distributed

# 2.0.0-rc2 — 2026-08-18

- Fixed Standard SIMULA class `text` parameter transmission. Default `text` parameters now bind by reference during construction instead of attempting value assignment into an uninitialized frame.
- Added native `text.copy` IR lowering for explicit `value text` procedure and class parameters, matching the Standard copy-on-entry rule while keeping the ordinary pointer-sized runtime representation.
- Applied the same class-parameter initialization rules to prefixed program/class construction.
- Added executable regressions for default reference `text`, procedure `value text`, and class `value text`, including the classic `Book` example that previously trapped with `invalid simula text operation`.
- Added a static parameter-transmission release audit so the constructor/reference/copy wiring cannot silently disappear from a release build.

# 2.0.0-rc1 — 2026-08-18

- added a compiler-owned non-moving mark/sweep heap for modern managed allocations; small objects reuse power-of-two free lists backed by 1 MiB mmap arenas and dead large objects can be unmapped
- separated program-global GC roots from allocator bookkeeping, fixed stale transient mark bits between collections, and added explicit managed-pointer pin/unpin plus heap statistics builtins and the `Memory` standard-library module
- made native task descriptors and stacks managed together and use Linux child-TID clearing as the lifetime barrier before a completed task allocation can be reclaimed
- retained correctness-first collection semantics while native workers are live rather than pretending concurrent stack scanning is safe
- fixed C `float` record-field stores that could overwrite an address held in RAX with float payload bits and then store through the corrupted address
- added a GC reclamation regression plus the existing program-global-state and C-record ABI canaries to the maintainer release suite
- added first-party `Raylib` and `Ncurses` standard-library modules, raylib/ncurses examples, explicit Linux ABI dependencies, and parser-safe wrapper names for C identifiers that collide with Free Simula keywords
- expanded and reorganized standard-library documentation around 46 source modules, memory management, native-library bindings, concurrency, systems helpers, and simulation-oriented modules
- rewrote the public README around the compiler's actual goals and history: a school programming-history project that grew into a native modern Simula dialect
- kept `-std=simula67` as an explicitly documented compatibility contract rather than claiming complete Standard SIMULA conformance while call-by-name, non-local goto unwinding, the full historical Simulation continuation model, and remaining environment/file semantics are incomplete
- versioned this tree as a release candidate because the modified Pascal compiler still requires a clean FPC rebuild and complete executable release gate before a stable 2.0.0 tag

# 1.6.2 — 2026-08-18

- fixed program-scope variable storage in the native x86-64 backend: program variables now live in stable writable ELF storage instead of being addressed through whichever routine stack frame happened to be active
- fixed nested program procedures reading and mutating top-level scalars, booleans, C scalar types, records, and static arrays; this was the root cause of RIFTLINE repeatedly returning to its title-state after `Restart()`
- removed program-scope variables from per-function stack allocation and taught ordinary loads, stores, aggregate access, and `c_addr` to use RIP-relative writable storage
- added an executable `program_global_state` regression that fails on 1.6.1 and verifies cross-procedure scalar plus fixed-array state at `-O3`
- version bumped to 1.6.2

# 1.6.1 — 2026-08-17

- Corrected the RIFTLINE parser diagnosis from 1.6.0: the failing source used `! Fixed value pools; startup ...;`. Standard Simula ends a bang comment at the first semicolon, so the trailing English words were source code. Arrays and underscore identifiers were not the cause of that failure.
- Replaced the bundled RIFTLINE surface canary with the corrected 1.1.3 source.
- Added `simula_comment_style_check.py` to `static-check`; repository `.sim` sources may not place text after the first semicolon of a line-leading bang comment. This is a project hygiene rule, not a language change.
- Added lexer and frontend regressions proving the Standard Simula rule that scanning resumes immediately after the first comment-terminating semicolon.
- Version bumped to 1.6.1. No Simula comment semantics were relaxed.

- hardened malformed array parsing so invalid element types and bounds produce diagnostics instead of Pascal range/division exceptions
- Free Simula identifiers may contain underscores; strict `-std=simula67` diagnoses them as a dialect extension instead of making the lexer context-dependent
- type-form fixed arrays accept signed integer constants and named integer constants as bounds
- classic array constant detection now recognizes declared integer constants and enum values, preserving static layout where possible
- local storage allocation and array type construction defensively reject invalid type/scope indices instead of crashing on already-diagnosed source
- hardened O3 loop/data-flow/constant-dedup passes against stale or empty IR ranges; optimizer candidates with invalid intermediate indices are skipped rather than causing a range-check fallback
- added RIFTLINE as a check-only application canary covering C FFI records, variadics, underscore identifiers, large fixed arrays, and program-scope state
- added explicit robustness tests for malformed arrays and strict-vs-Free-Simula identifier rules

# 1.5.5 — 2026-08-17

- fixed the release `fsfind` source check: the worker-slot traversal now uses reference identity inequality (`=/=`) against `none` instead of value inequality (`<>`), matching fsim object-reference semantics
- reconciled the frontend robustness gate with the supported declarations-before-program layout: a legal late named program is now a positive regression, while a malformed late header remains a required parser rejection
- extended static release audits to guard both the `fsfind` reference comparison and the declarations-before-program robustness contract
- fixed the last executable C-varargs failure at its real source: representation-preserving real/C-real casts now create an IR value tagged with the requested target type, so explicit `c_double(...)` and `c_float(...)` variadic arguments are classified as C SSE values instead of silently falling back to ordinary fsim `real` and being stack-passed
- hardened call coercion to use the actual lowered IR value type rather than trusting the AST type annotation, closing the same class of ABI-tag mismatch for future representation-preserving conversions
- made copy propagation type-aware: `irMove` chains are no longer collapsed across different IR type IDs, so O3 cannot erase a representation-preserving cast whose nominal type carries ABI semantics
- restored exact SysV `%al` vector-register counts for variadic calls (while keeping redundant variadic metadata detection), and expanded the executable FFI fixture with a three-XMM fixed-arity control plus `c_float` default-promotion coverage
- hardened SysV AMD64 variadic C calls: imported ellipsis signatures now retain `tfCVariadic` on their procedure type, direct/indirect call lowering redundantly detects varargs metadata, indirect targets are captured before `%al` is materialized, and vector-bearing varargs calls use the ABI-permitted upper-bound value 8 so `va_start` cannot skip XMM register saves
- repaired the two strict visibility-negative fixtures so their class field declarations are syntactically complete (`integer secret;`); they now reach the intended `hidden`/`protected` semantic diagnostics instead of dying earlier on a missing declaration semicolon
- corrected the strict old-lexical-forms regression to use TEXT reference assignment (`:-`) when binding a fresh `notext` variable to a nonempty literal; added a runtime-negative case that preserves the standard-required trap for illegal `notext := nonempty-text` value assignment
- made the strict Simula 67 runner continue after individual failures and report the entire failing tail in one invocation, avoiding one-fix-per-run test blindness
- made the executable C-FFI round trip report every failed ABI checkpoint by number and expression instead of collapsing all runtime mismatches into the generic assertion exit 76
- added 24-byte native and C-layout record canaries so the next native run distinguishes general large-record internal ABI failures from C callback/export bridging failures
- fixed multidimensional static-array codegen: indexing an outer dimension now yields the address of the nested row aggregate instead of loading its first qword as a fake pointer; whole static-array stores use aggregate copy semantics too
- fixed C-export record callbacks across the fsim/SysV ABI boundary: internal record returns now receive fsim's hidden sret pointer even when SysV returns the C struct in registers, explicit parameters are shifted accordingly, and MEMORY-class returns reuse the C caller's buffer
- added a native aggregate release audit, a fast multidimensional-array regression, and expanded executable FFI callback coverage for both register-class `Mixed` and MEMORY-class `Big` record returns
- fixed classic member chains such as `sysout.outtext(...)`: suppression of implicit zero-argument calls now applies only to the callable member itself, not to its receiver; this restores BASICIO `sysout`/`sysin` method calls and zero-argument object-returning function member access
- hardened non-FHS ELF loader discovery for statically linked compiler builds: fsim now derives loaders from mapped libc, Guix/Nix profiles, library search paths, and direct `/gnu/store`/`/nix/store` glibc packages; if no real loader exists it reports a compile error instead of embedding an unchecked `/lib64/ld-linux-x86-64.so.2`
- made the executable FFI gate parse ELF64 `PT_INTERP` itself before `execve`, so any remaining host-loader mismatch reports the exact embedded interpreter path without depending on `readelf`
- fixed aggregate-return parameter homing: the native prologue no longer uses SysV argument register RDX as an address scratch before all shifted sret arguments are saved; R10 is reserved for this prologue scratch path, restoring multi-argument native/C record returns
- fixed strict bare-`end` source parsing under the module loader by removing the keyword `end` from the synthetic closing source-boundary comment; the classic END-comment scanner can no longer expose the compiler's own boundary marker as a second source token
- made dynamic C-FFI ELF interpreter selection non-FHS aware: when `--dynamic-linker` is absent, fsim honors `FSIM_DYNAMIC_LINKER`, discovers the loader used by the compiler from `/proc/self/maps` (covering Guix/Nix store paths), then falls back to conventional x86-64 Linux loader paths
- hardened the FFI executable test so an `execve` ENOENT on an existing ELF reports a missing PT_INTERP loader instead of throwing an uncaught Python traceback
- extended the native-parameter audit to reject all SysV incoming argument registers as prologue address scratch and added lexer coverage for the synthetic source-boundary trailer after a bare END
- fixed native parameter prologue stores to honor each parameter's declared width; booleans/characters/C-width scalars no longer receive unconditional 8-byte stores that can overwrite the saved frame pointer and return address
- added a native-parameter release audit plus named/lambda procedure-return regressions that specifically cover narrow parameters feeding first-class procedure-valued returns
- made typed C pointer conversions such as `c_ptr(c_void)(p)` a real parser construct instead of parsing the type constructor as a value call; C layout/address intrinsics are also tagged explicitly in the AST
- excluded internal and C procedure values from local scalar forwarding so optimizer substitutions cannot outlive callable-result/register boundaries
- corrected the lexer unit expectations for comment terminators: the semicolon ending a Simula comment is consumed by the comment token and is not emitted a second time
- hardened anonymous outer-block EOF handling so a bare final `end` remains a complete strict-Simula compilation unit without accepting a genuinely duplicated source `end`
- fixed deferred call-argument lowering so indirect/nested calls evaluate the callee and every argument before emitting the contiguous `irParameter` run consumed by native call codegen; this closes a register-lifetime hole in higher-order calls
- fixed nested callable-signature construction: `procedure(...)` and `c_fn(...)` descriptors are now appended only after nested parameter types are complete, so an inner callback signature cannot reorder the outer function's parameters
- preserved explicit C scalar domains in mixed C/native arithmetic (`c_int + integer`, `c_double + real`, etc.) and taught numeric lowering/comparison code to handle C integer/real kinds as arithmetic values
- repaired inherited virtual dispatch: subclass implementations inherit their prefix slot, overrides stay virtual, and subclass VMTs materialize the most-derived concrete method for inherited slots
- fixed punctuation token text in the lexer, including `:=`, so the real FPC lexer unit test observes the spelling that the parser already consumed
- added nested higher-order, inherited-virtual, and per-operation atomic regression coverage plus static virtual-dispatch/call-layout release gates
- corrected the classic proper-procedure regression fixture to declare its formal procedure's integer result and kept classic `outint(value, width)` as an fsim compatibility overload alongside the one-argument shorthand
- fixed classic-output ABI ordering: `sysout` is now resolved before materializing `outtext`/`outint`/`outreal`/`outfix`/`outchar` arguments, so the receiver lookup call cannot clobber caller-saved argument registers
- repaired contextual-identifier parsing around classic formal lists and modern `name:`/`value:` parameters, including labels whose following statement begins with a contextual keyword
- made synthetic classic `Process`, `Link`, `Head`, `Simulation`, and BASICIO classes resolve case-insensitively inside the fsim compatibility layer without making ordinary fsim declarations case-insensitive
- kept BASICIO compatibility classes in fsim while limiting implicit strict-Simula globals such as `sysout` and `blanks` to `-std=simula67`
- made enum/integer equality use a common integer representation where the fsim enum surface expects it, without turning enums into general arithmetic operands
- added optimizer rollback to the original verified IR when an optimization pass throws an internal exception; the compiler now warns and continues instead of crashing a valid source file, while `-Werror` can still make the recovery fatal in compiler CI
- restricted advanced local load/store forwarding to plain scalar values; aggregate, managed, and reference-bearing values are no longer rewritten with scalar alias assumptions
- expanded runtime/syscall clobber classification and added split atomic/mutex/critical/semaphore/barrier integration canaries so native synchronization failures identify the primitive involved
- fixed more FPC case-insensitive unit-test collisions (`Diagnostics`, `Lexer`, and `Symbols`) and taught the unit API audit to reject locals that shadow imported unit names
- corrected the task-pipeline example so a spawned procedure is joined directly instead of assigning `future(void)` to `future(integer)`
- restored the repository's long-supported ALGOL/Simula layout where classes, procedures, types, and foreign declarations may precede a named `program`; the program now receives a child scope without hiding earlier declarations
- made `value`, `name`, `low`, `condition`, `step`, `task`, and keyword-shaped routine names contextual where an identifier is actually declared/resolved, fixing classic formals, FFI fields/parameters, and stdlib APIs without making the lexer context-sensitive
- added ordinary native `record` aliases and whole-record internal ABI lowering, while keeping C-layout records on the separate audited SysV ABI path
- fixed a native x86-64 frame corruption bug: callee-saved register pushes used to overlap compiler-owned negative-RBP locals/spills/hidden-sret slots; saved registers now live below the allocated frame
- hardened CFG construction, reachability, DCE, and IR verification against invalid block/instruction/value indices; optimizer failures now identify the pass instead of surfacing as a bare range-check exception
- stopped scalar load/store forwarding across aggregate records/arrays and aggregate stores, closing an aliasing hole that could delete observable writes
- resolved imports by declared module name as a fallback when a source filename differs from its `module` name, and restored the classic Process/Link/Head/BASICIO environment in the fsim superset dialect
- fixed the FPC unit regression where a local `Arena` variable collided case-insensitively with the `arena` unit; added native-frame, optimizer-safety, and native-record regression gates
- fixed the 1.5.5 source-build regression in `elf.pas`: foreign-export diagnostics now use the real `TSymbol.SourceSpan` field instead of stale `Span`/`DeclSpan` names
- extended the FPC compatibility gate with structural checks for common `TSymbolTable` element member accesses, so stale symbol/type/parameter field names are rejected before a native compile; the compiler audit now also keeps numeric and string version constants in sync
- added typed first-class internal procedure values with structural `procedure(...)` signatures, procedure variables, indirect calls, routine-address lowering, higher-order arguments, and procedure-valued returns
- added fsim-only expression lambdas with explicit result types; non-capturing lambdas lower to ordinary native routines with no interpreter or C trampoline
- completed the classic proper-procedure parameter path far enough for native higher-order calls: the frontend infers a proper procedure's effective signature from its use and checks compatible actual routines
- hardened lambda/method handling so unsupported outer-local, class-member, and `this` captures are diagnosed instead of becoming invalid code pointers
- fixed native frame ownership for nested scopes and replaced missing-frame load/store zero fallbacks with backend diagnostics, preventing silent native miscompiles
- classified internal indirect calls consistently across IR side effects, optimization barriers, tail-call discovery, register call-crossing analysis, and x86-64 emission
- added higher-order integration, strict-dialect, classic-procedure-parameter, and capture-rejection regression sources plus a dedicated static wiring audit
- strengthened the FPC 3.2.2 compatibility gate to reject an accidentally unquoted `=>` in Object Pascal source, which catches malformed target-token spellings before the real build
- audited the standard-library directory for empty/stub modules; no public module was deleted merely for being internally unused because the library is installed as source and those files are user-facing API

# 1.5.4 — 2026-08-17

- fixed the x86/ELF backend FPC build: `AppendForeignGOTLoad` now has an explicit forward declaration before the C-address lowering code that calls it
- rewrote native runtime dispatch with explicit `begin/end` branches so FPC 3.2.2 no longer hits the dangling `else` syntax failure in `EmitCallInstruction`
- added a Pascal local-order audit which catches calls to later same-unit helpers that are missing a `forward` declaration
- kept the 1.5.2 member-lowering fix, aggregate-return ABI fix, full Neon Breach codegen canary, and 1.5.3 cross-unit visibility audit in the release gate

# 1.5.3 — 2026-08-17

- fixed the public symbol-table API: `SymIsCStorageType` is now exported from `symbols.pas`, so `parser.pas` and `semantics.pas` compile cleanly with FPC 3.2.2
- added a cross-unit Pascal visibility audit which rejects calls to implementation-only routines from another unit before release packaging
- kept the 1.5.2 IR member-lowering and full-codegen canaries unchanged; this release is a build-correctness hotfix on top of them

# 1.5.2 — 2026-08-17

- fixed IR lowering for ordinary class and C-record member access; unset AST `Aux` values are no longer misread as legacy text intrinsics
- added full code-generation canaries for the raylib/Neon Breach FFI workload so `--check` cannot hide lowering crashes
- `make install` now installs only an already-built compiler whose embedded version matches `VERSION`; it never triggers a root-owned compiler build
- install validation also rejects a binary older than the Pascal sources, which catches stale extracted build products

# 1.5.1 — 2026-08-17

- Fixed fsim scalar conversion constructors such as `real(x)`, `integer(x)`, `boolean(x)`, `character(x)`, `short integer(x)`, and `long integer(x)` when the type spelling is represented by lexer keywords rather than ordinary identifiers.
- `program Name;` now forms a proper compilation unit with declarations, types, classes, and foreign blocks between the header and its `begin/end` body. A misplaced late program header gets a focused diagnostic instead of parser-recovery noise.
- Fixed explicit boolean and character coercion lowering: boolean conversions normalize to 0/1 and character conversions mask to the native byte domain.
- Fixed internal Free Simula functions returning C-layout records. Aggregate results now use a caller-owned hidden return slot instead of returning an address into callee stack storage. This keeps helpers returning `Vector2`, `Color`, and similar FFI records allocation-free and lifetime-safe.
- Added compiler canaries for scalar conversions, declaration-bearing named programs, raylib-style C aggregate/vararg signatures, and a full Neon Breach source check. Added an executable integration regression for internal C-record returns.
- Added `make doctor`, which compares `./bin/fsim` with the `fsim` resolved through `PATH` and warns about stale installed compilers.
- `make release-check` now forces the full generated conformance corpus rather than the shortened developer subset.
- Added a frontend robustness gate that feeds malformed programs through the real compiler and rejects internal-error exits, plus an O0/O3 differential execution gate for deterministic programs so optimizer changes have to preserve observable behavior.

# Changelog

## 1.5.0 — 2026-08-16

### native C ABI

- Added an fsim-only `foreign c` system with direct System V AMD64 lowering rather than generated C or a runtime signature interpreter. Imports are grouped by shared library and support explicit C symbol names and mutable foreign data objects.
- Added explicit LP64 C scalar types, `c_ptr(T)`, `c_ptr(c_void)`, `c_string`, typed `c_fn(...): T` function pointers, C default vararg promotions, and indirect C calls.
- Added natural, packed, union, and opaque C record declarations. Opaque records are pointer-only; complete records receive audited C field offsets, size, alignment, exact byte copies, and compile-time `c_sizeof`, `c_alignof`, and `c_offsetof`.
- Added recursive SysV aggregate classification into INTEGER/SSE/MEMORY classes, all-or-nothing register reservation for small aggregates, aligned stack copies, mixed GPR/XMM aggregate calls and returns, and hidden sret handling for memory-class results.
- Added `foreign c export` callback adapters for scalar, floating, pointer, and supported aggregate signatures. Export adapters are addressable through `c_addr` and are emitted as global dynamic ELF symbols for loader lookup.
- Added GOT-resolved foreign functions/data, ELF `.interp`, `.dynstr`, `.dynsym`, SysV `.hash`, `.rela.dyn`, `.got`, `.dynamic`, `DT_NEEDED`, and a `--dynamic-linker=PATH` override without invoking a host linker.
- Fixed exact storage of odd-sized 3/5/6/7-byte aggregate chunks so packed values cannot overwrite adjacent bytes.

### ABI and compiler correctness

- Extended fsim's internal native call ABI past six parameters by passing overflow values on the stack and loading them in the callee.
- Moved virtual-call null checks ahead of argument materialization so diagnostic calls cannot clobber already prepared argument registers.
- Kept C records address-valued inside the compiler backend, with whole-record assignment and parameter copies using exact native storage rather than Pascal objects.
- Kept the C namespace and syntax out of `-std=simula67`; historical `external` remains a separate classic-language facility.

### tests and documentation

- Added `make test-ffi`, which builds a real C shared-library fixture and round-trips integer widths, floats, strings, globals, void pointers, natural/packed/union aggregates, large sret values, varargs, returned function pointers, callbacks, and named dynamic exports.
- Added a static C-FFI wiring audit and strict-dialect rejection coverage.
- Added `docs/c-interop.md` with the ABI contract, performance model, ownership rules, and explicit unsupported extension boundary.

## 1.4.0 — 2026-08-16

### strict simula runtime

- Isolated the implicit Simula 67 environment from the default free simula namespace and made strict identifier lookup case-insensitive.
- Added a flat native text descriptor runtime with writable arena frames, zero-copy subtexts, independent positions, classic value/reference assignment behavior, cursor attributes, numeric de-editing and fixed-frame editing.
- Added compiler-owned `sysin`/`sysout` image I/O, 132-character buffers, item scanning, numeric input and buffered output without libc.
- Added strict standard character/text helpers, `mod`, `rem`, `entier`, epsilon stepping and the currently supported mathematical entrypoints.
- Corrected `mod` backend semantics so it is no longer accidentally identical to `rem`.

### modern runtime and language

- Replaced per-object small `mmap` allocation with a 1 MiB slab allocator using a CAS bump-pointer fast path and locked refill only when a slab is exhausted.
- Reworked contended channels and mutexes around private futex wait/wake paths and added native atomics, semaphores, barriers, conditions, monotonic timing, sleep and thread/future state helpers.
- Fixed cancellation so it records a request separately from terminal task completion; `await` and `join` no longer return while cancelled code is still executing.
- Added `atomic(integer)`, integer `and`/`or` bit operations in fsim mode, `synchronized`, and modern string `byte_value`/`slice` attributes.
- Made `critical`/`synchronized` emit a real futex-backed critical region. `parallel` and `defer` now diagnose at native code generation instead of silently becoming no-ops.
- Reject native spawn calls which cannot fit the current receiver/one-word payload ABI instead of silently discarding arguments.
- Expanded the source library to 43 modules with atomics, futures, synchronization, time, filesystem, bit and string-algorithm helpers.

### compiler correctness

- Added real integer-to-real coercion lowering at assignments, initializers, calls, returns, mixed real arithmetic and comparisons.
- Added strict text opcodes through semantic analysis, IR and the native backend instead of routing classic text through the modern string ABI.
- Fixed BASICIO member parsing for names which also have shorthand tokens such as `sysout.outtext`.
- Added native runtime label auditing after a missing generated-label declaration was caught during the pass.

- Fixed structural/nominal type equality for references, futures, channels, arrays, records, classes and enums so separately constructed `future(integer)`/`ref(C)` types no longer reject themselves.
- Fixed signed division strength reduction, multiply-by-power-of-two shift counts, and NaN-invalid self-comparison folding.
- Expanded handwritten x86 generated-label auditing from the strict/OS runtimes to 130 emitters across the modern runtime and ELF backend too.

### tests and docs

- Added host tests for text descriptors and dialect symbol isolation.
- Added strict native regressions for frame aliasing, image spanning, numeric editing and environment numeric behavior.
- Rewrote the conformance notes to separate implemented text/BASICIO work from the remaining call-by-name, Simulation, non-local goto, full file/environment and external-linkage gaps.

## 1.3.0 — 2026-08-02

### Simula compatibility

- Audited the frontend against the 1986 SIMULA Standard and Norwegian Computing Center Common Base material.
- Added standard class-header `protected`/`hidden` identifier lists and prefix-aware visibility enforcement.
- Added class-parameter fields, inherited constructor parameters, object-body elaboration, unqualified receiver access, and non-overlapping inherited layouts.
- Added split class-body execution with explicit and implicit `inner` continuation.
- Added traditional procedure headings, result assignment, object relations, `this C`, conditional object expressions, checked narrowing assignment, and reference identity.
- Added classic parenthesized arrays and complete value/reference `for` list element forms.
- Generalized switches to designational expressions, including conditional and nested switch designators.

### Runtime and safety

- Replaced classic process no-ops and null-entry thread launches with explicit backend diagnostics.
- Added explicit native rejection for call-by-name procedures until thunk environments are implemented.
- Added automatic channel/mutex/synchronization-handle initialization and kernel-yield contention paths.
- Added a 256-cycle native spawn/await/channel stress gate.

### Library and tests

- Expanded the source library to 37 modules with deques, priority queues, disjoint sets, ring buffers, matrices, random distributions, simulation metrics, and state machines.
- Split strict tests into native, check-only, backend-negative, and runtime-negative categories.
- Added a researched compatibility matrix that distinguishes parser acceptance from native execution.

## 1.2.1 — 2026-07-31

### Fixed

- Fixed the unconditional startup `ERangeError`/range-check failure caused by performing the intentionally wrapping FNV-1a hash multiplication directly in a checked `UInt32` expression.
- FNV-1a now computes in `QWord`, masks modulo 2^32, and narrows only after the value is provably in range; global `{$R+}` and `{$Q+}` checking remains enabled.
- Added stage-aware internal compiler diagnostics and `--trace-stages`, so any future uncaught exception reports whether it occurred during module loading, parsing, semantic analysis, IR lowering, optimization, register allocation, code generation, or output writing.
- Added a checked debug build target (`make debug`) producing `bin/fsim-debug` with line information, heap tracing, range, overflow, I/O, and stack checks.

### Verification

- Added canonical FNV-1a regression vectors and string-pool tests compiled with range and overflow checks.
- Added black-box driver smoke tests for the exact accepted command orders `fsim source -o output -std=simula67`, `fsim -std=simula67 source -o output`, and the default fsim dialect.
- Added executable smoke tests for both language profiles and an audit preventing unsafe checked-width FNV arithmetic from returning.

## 1.2.0 — 2026-07-31

- Replaced the hand-ordered unit build with one FPC dependency-resolved compilation of `fsim.lpr` using `-Fu./src` and filename/unit-name parity.
- Added an explicit minimum-version gate for Free Pascal 3.2.2 and a forced `make rebuild` path.
- Fixed imported sources retaining an embedded NUL byte, which could terminate lexing before later modules were reached.
- Added classic named imports such as `import Math;` alongside quoted imports, `.sim` inference, dotted module-name mapping, case-stable lookup, `-I`, `FSIM_PATH`, `FSIM_STDLIB`, installed-library discovery, and `--no-stdlib`.
- Added import-specific cycle and missing-module diagnostics, machine-readable JSON diagnostics, and Make-compatible dependency files through `-MD`, `-MF`, and `--depfile`.
- Added target selection validation, effective search-directory output, and a complete dialect feature-matrix command.
- Added FPC compatibility, unit-graph, module-loader, depfile, diagnostic, optimization-equivalence, and autonomous ELF validation tools.
- Added ELF release tests that reject dynamic interpreter and dynamic segment dependencies and verify segment bounds and entry-point coverage.
- Expanded the source standard library to 23 modules covering collections, searching, sorting, statistics, numerics, random generation, geometry, options/results, assertions, synchronization, tasking, event calendars, process support, strings, and classic queues.
- Added standard-library import, classic event-process, and typed task-pipeline examples.
- Hardened managed-record initialization and removed stale build/audit assumptions left by earlier filenames.
- Corrected arena alignment to align the returned machine address rather than only the block-relative offset; added overflow, stale-offset, zero-fill, and 16/32-byte alignment tests.
- Reconciled all Pascal unit tests with the current public APIs and added a release gate that rejects references to removed compiler interfaces.
- Made `release-check` sequential and deterministic, added embedded-manifest verification for both archive formats, and cross-checks TAR/ZIP payload identity.

## 1.1.0 — 2026-07-31

- Expanded compiler-owned Object Pascal source beyond 60,000 lines and made that threshold a release audit invariant.
- Replaced the scanner keyword dispatch with length-independent pointer comparisons for 156 reserved words.
- Added generated Unicode identifier classification and UTF-8 source validation.
- Added a centralized 221-feature dialect matrix for `simula67` and `fsim`.
- Added classical labels, switch declarations, `go to`, `inspect/when/otherwise`, activation clauses, `inner`, fixed text frames, and Head/Link queue metadata.
- Added Pascal-style variable and parameter declarations, function result annotations, `repeat`, `case`, and `with`.
- Added task classes, typed channels and futures, mutex/semaphore/barrier/condition handles, thread-local storage, spawn/join/await/cancel/yield/send/receive, critical sections, and parallel regions.
- Added target records for ABI classification, registers, relocation models, ELF layout, Linux syscalls, clone flags, and CPU features.
- Added non-trapping RTTI type tests, native scheduler yield, atomic one-slot channel handoff, spin mutexes, pause instructions, and memory fences to the x86-64 backend.
- Added shared native task descriptors, receiver-aware spawn lowering, clone-based thread entry, futex-backed join/await, result transport, atomic cancellation, and completion wakeups.
- Added global data-flow analysis with reverse postorder, dominators, immediate dominators, and natural loops.
- Added advanced optimization passes for store-to-load forwarding, dead local stores, branch threading, strength reduction, double-negation elimination, tail-call discovery, and function-property inference.
- Added semantic-only compatibility suites, expanded lexer regression tests, detailed dialect/classic/concurrency/optimization manuals, and a deep compiler source audit.

## 1.0.0 — 2026-07-31

- Added the independent `fsim` and strict `simula67` dialect profiles.
- Added a pointer-streaming lexer with source spans, UTF-8 literals, numeric bases, and strict semicolon-bounded comments.
- Added flat-record AST, scope, symbol, type, class, field, method, VMT, and RTTI tables.
- Added prefix-style inheritance, virtual specification blocks, visibility sections, typed constants, aliases, enums, arrays, procedures, functions, and classes.
- Added value and reference assignment enforcement, protected/private access checks, and checked QUA casts.
- Added target-independent linear 3AC with explicit basic blocks and use/definition metadata.
- Added global constant propagation, algebraic simplification, branch folding, unreachable block removal, dead-code elimination, common-subexpression elimination, and loop analysis.
- Added x86-64 linear-scan allocation with callee-saved register tracking and spill slots.
- Added a direct AMD64 encoder, embedded syscall runtime, UTF-8 string descriptors, object initialization, VMT calls, RTTI ancestry checks, and native thread helpers.
- Added autonomous ELF64 construction with program headers, section headers, `.text`, `.rodata`, `.data`, `.bss`, `.symtab`, `.strtab`, and `.shstrtab`.
- Added deterministic module loading, import-cycle diagnostics, release tooling, examples, negative tests, integration tests, unit tests, and 240 generated executable conformance programs.

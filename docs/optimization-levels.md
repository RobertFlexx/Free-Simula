# Optimization levels

fsim optimizes a target-independent linear three-address representation. Every instruction belongs to a function and basic block and has explicit destination, operand, symbol, target, type, and side-effect metadata. The optimizer is not guessing what the code means; the IR told it exactly.

## Optimization levels

### `-O0`

- Build and verify control-flow edges.
- Remove structurally unreachable blocks.
- Infer leaf, call, exception, and frame properties.

At `-O0` the code is naive but honest. The compiler fixes what it must for correctness and leaves the rest of your performance sins alone.

### `-O1`

- Copy propagation.
- Integer and real constant folding.
- Algebraic identities.
- Small algebraic identity folds.
- Constant conditional-branch folding.
- Reachability cleanup.
- Dead-code elimination.
- Conservative local load forwarding and dead-store removal.

`-O1` is the polite pass. It removes what is obviously silly and stops there.

### `-O2`

Adds:

- Local common-subexpression elimination.
- Repeated propagation and folding.
- Branch threading through branch-only blocks.
- Double-negation elimination.
- Multiplication strength reduction for powers of two.
- Tail-call discovery.

`-O2` is where the compiler starts doing actual work for you, including noticing that you wrote `x * 8` and deciding a shift was always the plan.

### `-O3`

Adds:

- Whole-function predecessor and successor analysis.
- Reverse-postorder numbering.
- Iterative dominator computation.
- Immediate-dominator derivation.
- Natural-loop discovery and loop-depth annotation.
- Loop-invariant simplification.
- Constant deduplication.
- Repeated fixed-point cleanup.

`-O3` is where the dominator tree gets built and your hot loop gets treated seriously.

### `-Ofast`

Adds aggressive arithmetic assumptions. Signed division by a positive power of two may become a shift, integer overflow traps are disabled where marked, and real arithmetic receives fast-math flags. Bounds, null, and mandatory RTTI checks remain separately controlled. Fast math means the compiler trusts the numbers; it is up to you to deserve that trust.

## Advanced optimizer

`src/passes.pas` is isolated from the baseline optimizer. It performs conservative transformations that require def-use or block-local state:

- value forwarding from the most recent local store;
- removal of overwritten local stores when no intervening observation exists;
- invalidation at calls, exception boundaries, atomics, and process operations;
- self-comparison simplification for non-real values;
- double integer, real, and Boolean negation removal;
- branch-chain threading with cycle guards;
- tail-call pattern discovery;
- function attribute inference.

All transformations update use lists and rebuild CFG edges before register allocation. "Conservative" here means it would rather keep a dead store than delete a live one, and it sleeps better for it.

## Register allocation

The allocator computes live intervals over flattened instruction positions. It expires old intervals, allocates from the target register bank, chooses spill victims, assigns aligned frame slots, and records callee-saved usage. The Linux x86-64 target currently exposes five general-purpose allocation registers while reserving ABI and runtime scratch registers. Five registers sounds like a small number until you remember what spilled to memory instead.

## Verification

`--verify-each-pass` invokes IR structural verification after pass boundaries. The verifier checks value definitions, function/block ownership, terminators, targets, instruction ranges, and use metadata. `--stats` prints both baseline and advanced pass counters. If a pass broke the IR, the verifier is the one that tells you, in front of everyone.

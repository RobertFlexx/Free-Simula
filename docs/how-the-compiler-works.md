# How the compiler works

This is the tour of the internals. Read it before you go poking around `src/`, or at least read it after the first time you get lost in there, which will happen.

## Pipeline

The driver performs these phases in order:

1. Parse command-line options and establish dialect and safety policy.
2. Load the root module and recursively expand imports.
3. Scan source through a pointer-streaming lexer.
4. Parse into a flat syntax graph.
5. Populate scopes, symbols, classes, fields, methods, types, VMT slots, and RTTI metadata.
6. Resolve names and enforce type, visibility, assignment, control-flow, and QUA rules.
7. Lower executable routines into target-independent three-address code.
8. Construct CFG predecessor and successor edges and verify definitions and uses.
9. Run optimization passes selected by `-O0` through `-Ofast`.
10. Build live intervals and perform linear-scan x86-64 register allocation.
11. Encode runtime helpers and program instructions into byte buffers.
12. Resolve code and data relocations.
13. Serialize ELF64 program headers, sections, symbols, strings, and payloads.
14. Write the output in one file operation and apply executable permissions.

No phase executes an external program. Not even the exciting ones.

## Flat records

The compiler does not use Object Pascal classes for compiler state. Every central entity is a packed record stored in a contiguous dynamic array, and relationships use signed 32-bit IDs with `-1` as the invalid link. This avoids per-node heap allocation, vtable dispatch, ownership ambiguity, and recursive destruction, which is a whole neighborhood of bugs we simply do not live in.

Array growth is centralized and observable. The AST is a first-child/next-sibling graph; IR is a linear instruction stream partitioned by basic-block ranges.

## Arena

The arena allocates large blocks and returns encoded offsets. An offset contains the block index and the offset within that block. Alignment is handled before every allocation. Resetting rewinds usage counters without walking allocations; clearing releases all blocks together. It is fast, it is simple, and it does not fragment.

## Scanner

The lexer keeps current, token-start, and end pointers. Whitespace and comments are skipped without allocating token strings. Identifier and literal spelling is represented by a source pointer plus length, and the parser interns only the names that survive into the AST or symbols.

Dialect-sensitive keyword recognition happens after ASCII-folded keyword lookup. This lets the scanner report a dialect violation at the exact token instead of letting later syntax recovery obscure it.

## Parser

The parser uses one current token and one lookahead token. Precedence-climbing functions build expressions, and statement and declaration routines append nodes directly to the flat AST.

Class parsing maintains explicit `CurrentClass`, `CurrentVisibility`, `CurrentRoutine`, and scope IDs. Prefix lookup occurs before entering the child class scope. The virtual specification section is accepted only at the absolute header position. Visibility keywords mutate parser state and emit a structural marker node for diagnostics and tooling.

## Symbol and type engine

Each scope owns a hash table range and an insertion-order chain. Lookup walks lexical parent scopes, and class member lookup walks the prefix chain. Types are canonical records for primitives, arrays, references, call signatures, classes, records, enums, and generic parameters.

Class finalization computes inherited and local field layout, method slots, object size, alignment, and RTTI records. Reference types are canonicalized by target class symbol, so two spellings of the same reference do not start a custody dispute.

## Semantic analysis

The semantic pass annotates expression nodes with symbol and type IDs. It distinguishes value assignment from reference binding, validates argument modes, checks member visibility against declaring and requesting classes, verifies function returns, and tracks loop and exception nesting. If it says no, it means no.

## IR

IR instructions have an opcode, destination, three operands, type, symbol, branch targets, flags, string ID, integer immediate, real immediate, source span, and owning block. Basic blocks retain instruction ranges and CFG edges. Functions retain entry/exit blocks and value ranges.

The IR is intentionally target blind. Object operations, VMT lookup, QUA checks, strings, exceptions, simulation operations, and output are explicit opcodes rather than hidden backend patterns. What the IR says is what the backend does.

## Optimization

Optimization levels compose passes:

- `-O0`: CFG construction, structural verification, unreachable cleanup required for correctness.
- `-O1`: local constant folding, propagation, algebraic identities, branch folding, DCE.
- `-O2`: repeated global propagation, CFG simplification, common-subexpression elimination.
- `-O3`: loop discovery, invariant analysis, repeated fixed-point optimization.
- `-Ofast`: `-O3` plus transforms allowed to assume unchecked signed arithmetic. Fast, yes. Absolved, no.

Every destructive pass preserves source spans and marks removed instructions rather than invalidating all indices. Optional verification runs after each pass, so the optimizer gets graded on its homework.

## Register allocation

The allocator computes first definition, first use, and last use for each value. Intervals are sorted by start position, and expired intervals return registers to the free set. When pressure exceeds the allocatable registers, the interval ending latest is spilled if replacing it benefits the current interval; otherwise the current interval spills. Linear scan is not glamorous, but it finishes before the user finishes a coffee.

The backend reserves scratch and ABI registers, tracks callee-saved use masks, aligns each frame, and assigns independent stack areas for values, source symbols, the method receiver, and outgoing call state.

## Native backend

The x86-64 encoder emits REX prefixes, ModRM/SIB bytes, immediates, branches, calls, SSE scalar operations, syscalls, and RIP-relative references. Labels and relocations are integer records, and resolution patches signed displacements after code layout.

Runtime helpers are emitted by calling the same encoder API as user code. Every executable byte in a program comes from the same audited encoder, which is how the whole thing stays trustworthy without a second toolchain in the loop.

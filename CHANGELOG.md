# Changelog

The history of Free Simula as far as I can reconstruct it. The project started in 2022 as a school programming-history project and then just kept going, so the early entries are a bit fuzzy. Dates are roughly right; I stopped keeping careful receipts around 1.4.

## 1.0.0 (2022-11-21)

The first release. Everything after this is a decision I made one release at a time.

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

# Contributing

So you want to touch the compiler. Good. A few ground rules before you break something:

- Keep compiler data in packed records and contiguous arrays. New AST, symbol, IR, relocation, or runtime entities should use integer IDs and explicit invalid values. Do not introduce Object Pascal class hierarchies into the compilation pipeline. We had a phase, it is over.
- Every language feature should include scanner coverage, parser construction, semantic validation, IR lowering, optimizer behavior, backend emission or an explicit compile-time diagnostic, and positive and negative tests. "It parses" is not a feature.
- No compiler path may invoke an external assembler, linker, C compiler, LLVM component, or dynamic-loader helper. Host-side test and packaging scripts may execute the built `fsim` binary and its generated executables. The pipeline being self-contained is a feature, not a habit.
- Run `make static-check` before committing. Run `make test-fast` for ordinary changes and the complete conformance suite before release.

Yes, that last one is written in the blood of someone who skipped it.

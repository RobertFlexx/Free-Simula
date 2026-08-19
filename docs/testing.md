# Testing and Release Verification

## Layers

The test system has seven layers:

1. Static repository checks validate mandatory units, dependency graphs, FPC 3.2.2 compatibility, self-contained pipeline rules, placeholder absence, generated corpus integrity, and source-size floors.
2. Pascal unit programs exercise checked FNV-1a hashing, string interning, arena reset/alignment, scanning, and optimizer analysis.
3. Driver smoke tests repeat supported option orders, check both dialects, generate ELF files, and execute them.
4. Module tests exercise named and quoted imports, search paths, cycles, missing-module diagnostics, JSON output, and dependency files.
5. Backend tests compile and execute representative programs at every optimization level and parse ELF structures directly.
6. Integration and negative programs test execution results, dialect separation, type safety, and stable diagnostic fragments.
7. Generated conformance programs stress arithmetic, comparisons, loops, branching, folding, DCE, register pressure, spills, relocation, ELF writing, and process exit.

## Commands

```sh
make static-check
make unit-tests
make test-driver
make test-modules
make test-backend
make test-fast
make test
FSIM_FULL_CONFORMANCE=1 make test-generated
make benchmark
make release-check
```

The default `make test` samples generated programs to keep developer iteration practical. The full generated suite is mandatory for a release build.

## Deterministic corpus

`tools/generate_conformance.py` uses only its program index and fixed formulas. Every manifest entry stores the filename, expected stdout, expected exit status, line count, and SHA-256 digest. Static checks recompute all digests and totals.

## Negative tests

A negative source has a sibling `.expect` file containing a case-insensitive diagnostic fragment. The test passes only when compilation fails and the fragment appears. This avoids coupling tests to terminal color or absolute paths while preserving diagnostic intent.

## Release gate

A release gate requires:

- clean FPC compilation with the configured warning set;
- static checks;
- all module and backend tests;
- all examples;
- all integration and negative tests;
- the complete generated suite;
- valid `--version` output;
- deterministic archive generation and SHA-256 recording.

# Building Free Simula

## Requirements

The compiler currently targets Linux x86-64 and is built with Free Pascal 3.2.2 or newer plus `make`.

Generated Free Simula executables do not require GCC, Clang, LLVM, a separate assembler, or a separate linker for ordinary native output. FPC is used to build the compiler itself.

## Public source release

```sh
make clean
make
./bin/fsim --self-test
```

If FPC is somewhere unusual:

```sh
make FPC=/path/to/fpc
```

Install an already-built compiler:

```sh
sudo make install PREFIX=/usr/local
```

The install target places the compiler in `bin`, the source standard library in `share/fsim/stdlib`, and documentation in `share/doc/fsim` under the selected prefix.

## Maintainer tree

The maintainer distribution additionally requires Python 3 for source audits, conformance generation, integration tests, release packaging, and ABI checks.

Typical pre-release validation is:

```sh
make static-check
make clean
make
./bin/fsim --self-test
make test
make test-concurrency-stress
make release-check
```

The debug compiler enables FPC runtime checks and line information:

```sh
make debug
./bin/fsim-debug --trace-stages source.sim -o program
```

A stable source tag should not be cut from static audits alone. The compiler being shipped must be rebuilt from the tagged Pascal source and its generated programs must execute successfully on the release target.

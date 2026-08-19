# Free Simula

Free Simula (`fsim`) is a native compiler for **Free Simula**, a modern successor dialect of Simula 67 for x86-64 Linux.

Free Simula exists to answer a fairly simple question:

**What would Simula look like if it had kept evolving?**

Simula is one of the foundational languages of the ALGOL family and one of the earliest object-oriented programming languages, but it never really received the kind of modern continuation that languages such as Pascal and BASIC eventually did.

Free Simula is an attempt to continue that lineage without throwing away what made Simula recognizable in the first place.

The language keeps the ALGOL/Simula shape: `begin`/`end` blocks, classes and prefixing, `inner`, references, `new`, `inspect`, arrays, procedure values, labels, and the separate `:=` value and `:-` reference assignments.

Around that foundation, Free Simula adds facilities that make sense on a modern system: modules, modern strings, native tasks and synchronization, C interoperability, enums, aliases, managed memory, a larger standard library, and first-party native-library bindings.

**The point is not to turn Simula into C with different keywords.** Free Simula is meant to remain recognizably Simula. Its syntax, block structure, object model, and programming style are part of the language's identity. Modernization happens around that foundation rather than replacing it with a C-, C++-, or Java-like model.

Free Simula is also not intended to be Simula 67 frozen in time. Historical facilities that depend heavily on the computing environment of the original language may be replaced or supplemented with modern mechanisms while retaining the language's original structure and style.

The compiler also provides a separate -std=simula67 compatibility profile for historical Standard Simula 67 source.

> Not all historical Simula 67 source will compile unchanged. The compatibility profile is intended to provide substantial practical coverage of    Standard Simula 67 rather than claim perfect compatibility with every historical implementation.

`fsim` has its own x86-64 machine-code and ELF backend. Ordinary native output does not pass through generated C, GCC, Clang, LLVM, `as`, or `ld`.

## Where this came from

This project started in 2022 as a school programming-history project that a few friends and I worked on.

We were interested in older ALGOL-family languages and started experimenting with the idea of writing a Simula compiler.

Then we kept working on it.

And kept working on it.

At some point it stopped being a sensible school project and turned into a real compiler project with its own native backend, runtime, dialect, standard library, C ABI, concurrency system, garbage collector, and compatibility mode.

This has been a long-running project that I have wanted to finish and release for a long time. I'm grateful to everyone who helped build, debug, test, break, and rebuild it along the way.

Free Simula is our attempt to give Simula a modern continuation while respecting where the language came from.

## Free Simula and Simula 67

There are two language profiles.

### Free Simula

```sh
-std=fsim
```

This is the **primary language mode**.

Free Simula is the modern successor dialect developed by this project. It keeps the underlying ALGOL/Simula model while extending and modernizing parts of the language and runtime.

Modern Free Simula includes things such as:

* modules
* modern strings
* native tasks
* synchronization primitives
* C interoperability
* enums
* type aliases
* procedure values
* managed memory
* a larger standard library
* Raylib and ncurses bindings

Modern lookup is case-sensitive and does not automatically inject the historical Standard Simula environment.

### Simula 67 compatibility

```sh
-std=simula67
```

This profile exists for historical Standard Simula 67 source.

It uses classic case-folded names, historical lexical conventions, and the traditional implicit environment.

In short:

```text
-std=fsim       Free Simula, the primary modern dialect
-std=simula67   Standard Simula 67 compatibility
```

Free Simula is the language this project is developing forward.

The Simula 67 profile is the bridge back to the language it extends.

## Status

The current tree is **2.0.0-rc2**.

It is a release candidate.

The compiler implements a substantial portion of Standard Simula 67, but this release does **not** claim that every historical Simula program or every implementation-specific extension will compile unchanged.

The classic profile includes substantial support for:

* classes
* class parameters
* prefixing
* `inner`
* object references
* `new`
* `inspect`
* `text`
* arrays
* classic procedure forms
* labels
* switches
* Standard Simula-style I/O
* the historical implicit environment

Some historical facilities are still incomplete.

Known compatibility work includes:

* fully general call-by-name
* non-local `goto` activation unwinding
* the complete historical `Simulation` continuation model
* portions of the old file and environment facilities
* implementation-specific external object formats

See [docs/simula67-conformance.md](docs/simula67-conformance.md).

This boundary is intentional.

If the compiler knows that it cannot implement a construct correctly, it should diagnose it rather than quietly generating the wrong executable.

## A small taste of Simula

Classic Simula ideas remain at the center of the language:

```simula
class Book(title, pages);
text title;
integer pages;
begin
    procedure printDetails;
    begin
        outtext("Title: ");
        outtext(title);
        outtext(", Pages: ");
        outint(pages, 0);
        outimage
    end
end;
```

Object references still look like Simula:

```simula
ref(Book) favoriteBook;

favoriteBook :-
    new Book("The Art of Computer Programming", 672);

favoriteBook.printDetails;
```

And Free Simula can build on that same language with modern facilities:

```simula
module Demo;

type Counter = integer;

enum Direction begin
    North = 0,
    East,
    South,
    West
end;

integer function Twice(integer value);
begin
    return value * 2
end;

program DemoProgram;
begin
    integer total;
    procedure(integer): integer operation;

    operation := Twice;
    total := operation(21);

    assert(total = 42)
end;
```

The intention is evolution, not replacement.

## Build

You need:

* x86-64 Linux
* Free Pascal 3.2.2 or newer
* `make`

Build the compiler:

```sh
make clean
make
```

Then run its self-test:

```sh
./bin/fsim --self-test
```

If Free Pascal is not available as `fpc`:

```sh
make FPC=/path/to/fpc
```

Install an already-built compiler with:

```sh
sudo make install PREFIX=/usr/local
```

This installs:

* `fsim`
* the Free Simula standard library
* bundled library modules
* user documentation

The Raylib and ncurses modules are installed with the rest of the standard library.

The small public source distribution intentionally leaves maintainer-only test and audit machinery out.

## Hello world

Free Simula:

```simula
program Hello;
begin
    outtext("hello from Free Simula");
    outimage
end;
```

Compile it:

```sh
fsim hello.sim -o hello
./hello
```

or explicitly select the language profile:

```sh
fsim -std=fsim hello.sim -o hello
```

For historical source:

```sh
fsim -std=simula67 old.sim -o old
./old
```

## Native compiler

Free Simula has its own native backend.

The normal compilation path is:

```text
Simula source
     |
     v
parser / semantic analysis
     |
     v
Free Simula IR
     |
     v
optimizer
     |
     v
x86-64 backend
     |
     v
ELF executable
```

It does not normally translate the program to C and hand the result to another compiler.

The compiler contains its own:

* parser
* semantic analyzer
* intermediate representation
* optimizer
* x86-64 instruction emitter
* System V AMD64 ABI lowering
* ELF writer
* runtime support

## Memory management

The 2.0 runtime includes a native **non-moving tracing garbage collector**.

Managed objects stay at stable addresses, which is important for native interoperability and pointers retained by C.

Small allocations use mmap-backed slabs and reusable size classes. Dead small objects can be recycled, while sufficiently large managed mappings can be returned to Linux.

The runtime also supports explicit pinning for objects whose addresses are retained by external native code.

For example:

```simula
import Memory;

program HeapStats;
begin
    CollectGarbage;

    outint(LiveHeapBytes);
    outimage
end;
```

Native task stacks are managed separately from ordinary object allocations. Completed task storage is not reclaimed until the runtime can establish that the worker has actually stopped executing on its stack.

The current collector intentionally favors correctness over complicated concurrent collection behavior.

See [docs/memory-and-gc.md](docs/memory-and-gc.md).

## Standard library

The standard library is written in Free Simula where practical.

Runtime or operating-system primitives are used where a native boundary requires them.

Common modules include:

```simula
import Math;
import Strings;
import Statistics;
import Random;
import Filesystem;
import Tasking;
import Synchronization;
import Memory;
```

Simulation-oriented facilities are also included, such as:

```text
Simset
Process
Simulation
EventCalendar
ResourceFacility
```

along with queue and statistics helpers.

These modern modules do not replace the historical environment provided by `-std=simula67`.

See [docs/standard-library.md](docs/standard-library.md).

## Raylib

Free Simula includes a first-party binding for the raylib 6.0 C ABI.

```simula
import Raylib;

program Window;
begin
    InitWindow(c_int(960), c_int(540), "Free Simula");
    SetTargetFPS(c_int(60));

    while not WindowShouldClose() do
    begin
        BeginDrawing;
        ClearBackground(Black);

        DrawText(
            "hello raylib",
            c_int(32),
            c_int(32),
            c_int(28),
            RayWhite
        );

        EndDrawing
    end;

    CloseWindow
end;
```

The Free Simula module ships with the compiler.

The native raylib shared library itself remains a host dependency.

The current Linux binding targets the raylib 6.0 shared ABI:

```text
libraylib.so.600
```

See [docs/bundled-bindings.md](docs/bundled-bindings.md).

## ncurses

The standard library also includes a wide-character ncurses binding.

```simula
import Ncurses;

program Terminal;
begin
    initscr();
    cbreak();
    noecho();

    mvaddstr(
        c_int(1),
        c_int(2),
        "Free Simula + ncurses"
    );

    refresh();
    getch();
    endwin()
end;
```

The module binds the real exported ncurses ABI rather than treating C preprocessor macros as dynamic symbols.

Linux builds use:

```text
libncursesw.so.6
libtinfo.so.6
```

See [docs/bundled-bindings.md](docs/bundled-bindings.md).

## C interoperability

Free Simula has native System V AMD64 C interoperability.

```simula
foreign c from "libm.so.6" begin
    function cos(value: c_double): c_double;
end;

foreign c export function triple(value: c_int): c_int;
begin
    return value * c_int(3)
end;
```

The compiler supports facilities including:

* explicit C-width scalar types
* typed `c_ptr(T)`
* `c_fn`
* variadic functions
* imported native data
* natural and packed records
* unions
* opaque handles
* callbacks
* native aggregate argument and return classification

Dynamic imports are represented directly in the generated ELF image.

See [docs/talking-to-c.md](docs/talking-to-c.md).

## Repository layout

The public source repository is deliberately small.

```text
src/       compiler, optimizer, native backend and runtime
stdlib/    Free Simula standard library and bundled bindings
examples/  example programs
docs/      language, runtime and ABI documentation
fsim.lpr   compiler entry point
```

The maintainer distribution additionally contains:

* regression tests
* conformance fixtures
* backend tests
* static audits
* stress tests
* release tooling

Those files are useful when developing or validating the compiler, but they are not necessary simply to build and use fsim.

## Release policy

Compiler correctness is something that has to be tested, not declared.

Before a stable release tag, the maintainer tree is expected to pass:

* a clean Free Pascal build
* compiler self-tests
* native backend tests
* Simula 67 compatibility tests
* C ABI round trips
* concurrency stress tests
* optimization differential tests
* runtime regressions
* release audits

The important part is that these checks run against the compiler binary that will actually be released.

See:

* [docs/release-checklist.md](docs/release-checklist.md)
* [docs/what-is-verified.md](docs/what-is-verified.md)

## License

See [LICENSE](LICENSE).

## Credits

Free Simula has been worked on by me and several friends, some of whom prefer to remain anonymous.

**RobertFlexx** - Project lead, software developer, publisher and maintainer
**Anonymous 1** - Software developer
**Anonymous 2** - Software developer and assistant lead
**Anonymous 3** - Debugging and software development

# Bundled native-library bindings

Free Simula installs first-party source bindings alongside the standard library. They are maintained by the fsim project and use the compiler's native `foreign c` ABI. They are **not** claims of endorsement or maintenance by the upstream library projects.

## Raylib

```simula
import Raylib;
```

The bundled module targets the raylib 6.0 Linux shared ABI (`libraylib.so.600`).

The 3.0 surface covers commonly used:

- window/monitor/clipboard/cursor APIs;
- keyboard, mouse, touch and gamepad input;
- drawing, shapes and collision helpers;
- images, textures, fonts and text;
- camera/basic 3D/model-related value types and calls used by the binding;
- shader loading, uniform lookup/update and shader mode;
- blend/scissor drawing modes;
- wave, sound, music and audio stream APIs;
- file/directory/drop-file helpers;
- gamepad mappings and vibration.

C-layout records are declared for the public value types used by these calls. ABI-sensitive definitions are checked against the raylib 6.0 header; for example, 6.0 `FilePathList` is represented as `count` plus `paths`, without the old capacity field.

Example:

```sh
fsim examples/raylib/hello.sim -o raylib-hello
./raylib-hello
```

The binding source ships with fsim. The raylib library itself remains a host dependency.

## ncurses

```simula
import Ncurses;
```

The bundled module targets the wide-character ncurses 6 ABI on Linux. It uses `libncursesw.so.6` and `libtinfo.so.6` where terminal symbols are split into tinfo.

It covers the core screen/window interface plus subwindows, derived windows, pads, staged `noutrefresh`/`doupdate` style refresh, bounded input, colors, touch/synchronization operations and common key constants.

The binding declares real exported dynamic symbols. C-only convenience macros are not invented as ELF functions. Names that collide with Free Simula syntax receive parser-safe wrapper names.

Example:

```sh
fsim examples/ncurses/hello.sim -o ncurses-hello
TERM=xterm ./ncurses-hello
```

## SDL3

```simula
import SDL3;
```

The SDL3 binding provides a typed core surface for:

- subsystem initialization/shutdown and errors;
- windows;
- event polling/pushing/flushing;
- keyboard and mouse state;
- renderer creation and primitive drawing;
- textures and surfaces used by the core example surface;
- timing and delays;
- clipboard text;
- SDL IO streams.

Opaque handles are represented as typed C pointers. `SDL_Event` is modeled with the ABI's fixed 128-byte storage guarantee rather than an undersized guessed record.

Example:

```sh
fsim examples/sdl3/hello.sim -o sdl3-hello
./sdl3-hello
```

The host must provide `libSDL3.so.0`.

## SQLite3

```simula
import SQLite3;
```

The SQLite3 module targets `libsqlite3.so.0` and covers common connection, prepare/step/reset/finalize, parameter binding, column access, error/status and busy-timeout operations.

Example:

```sh
fsim examples/sqlite3/version.sim -o sqlite-version
./sqlite-version
```

## zlib

```simula
import Zlib;
```

The zlib module targets `libz.so.1` and provides version/compile flags, buffer compression/decompression, compression bounds, CRC32 and Adler-32 helpers.

Example:

```sh
fsim examples/zlib/version.sim -o zlib-version
./zlib-version
```

## ABI policy

Bindings use explicit major-version SONAMEs so a source module cannot silently pick an incompatible ABI under a generic library name.

The maintainer binding audit checks parser/type hygiene and, when a target DSO exists on the validation host, verifies that every declared imported C symbol is actually exported by that DSO. Binding examples are also part of frontend/release validation; dynamic examples are required on hosts where the relevant library is available.

The compiler's C ABI contract is documented in [c-interop.md](c-interop.md).

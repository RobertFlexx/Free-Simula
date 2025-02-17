# Bundled native library bindings

Free Simula installs first-party source bindings alongside the rest of its standard library. They are maintained as part of fsim and use the compiler's native `foreign c` ABI. They are not claims of upstream endorsement: the raylib and ncurses people did not bless us, we just read their headers and behaved.

## Raylib

```simula
import Raylib;
```

The bundled module targets the raylib 6.0 C ABI on Linux and names the shared-library ABI as `libraylib.so.600`.

The binding covers the commonly used core, window/input, drawing, shapes/collision, image/texture, font/text, basic 3D/camera, shader, wave/sound/audio-stream, and music APIs. C-layout records are declared for the public value types used by those calls, including vectors, matrix, color, rectangle, image, textures, font/glyph, camera, shader, ray/collision, wave, audio stream, sound, and music.

Small constructors such as `Vec2`, `Vec3`, `Rect`, `Rgba`, `White`, `Black`, and `RayWhite` make C records less noisy to create from Free Simula. Nobody wants to write `Vec2(c_float(0), c_float(0))` at the top of every frame.

Example:

```sh
fsim examples/raylib/hello.sim -o raylib-hello
./raylib-hello
```

The binding source ships with fsim. The raylib shared library itself does not; install raylib 6.0 through the operating system or another trusted package source.

Because raylib passes several `float`-based records by value, the maintainer test suite contains ABI canaries for C-record field stores and aggregate arguments and returns. Those tests are release gates for this binding, which is a polite way of saying we got burned once and now we verify.

## ncurses

```simula
import Ncurses;
```

The bundled module targets the wide-character ncurses 6 ABI on Linux. It uses `libncursesw.so.6` for the window/screen API and explicitly names `libtinfo.so.6` for terminal-mode functions that are exported there on split builds.

The binding declares real dynamic symbols. C convenience macros are either omitted or represented by a Free Simula wrapper or name that ultimately calls an exported function. For example, the C symbol `timeout` is exposed as `SetInputTimeout`, because `timeout` is a Free Simula keyword and you are not going to win that fight.

Example:

```sh
fsim examples/ncurses/hello.sim -o ncurses-hello
TERM=xterm ./ncurses-hello
```

The ncurses and tinfo shared libraries are host dependencies. The terminal, sadly, is not optional.

## ABI policy

Bundled bindings use explicit major-version SONAMEs, so a source module cannot silently bind against an incompatible ABI that happens to share a generic library name. A future fsim release may ship additional binding modules when a library introduces a new ABI, or when the maintainer gets bored enough to write more bindings.

The compiler's C ABI documentation is in [talking-to-c.md](talking-to-c.md).

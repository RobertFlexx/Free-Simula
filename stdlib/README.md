# Free Simula standard library

The installed library is ordinary Free Simula source where practical. Import a module by name:

```simula
import Math;
import Strings;
import Memory;
import Raylib;
import Ncurses;
```

The library keeps Simula-style classes, explicit `begin`/`end` structure, reference/value assignment, and simulation-oriented modules while adding current systems pieces such as tasks, synchronization, result/option containers, strings, filesystem helpers, memory diagnostics, and native C-library bindings.

`Raylib` and `Ncurses` ship as binding source; their shared libraries remain host dependencies.

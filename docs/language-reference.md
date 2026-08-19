# Free Simula 1.5 Language Reference

## 1. Dialects

`-std=simula67` selects the historical profile. The scanner and parser reject fsim extensions, including `string`, visibility sections, thread classes, exceptions, modules, aliases, enums, assertions, and modern allocation syntax. Historical `text` remains a fixed-length value when a length is supplied.

`-std=fsim` selects the modern profile. It retains Simula token shapes and block syntax while enabling checked systems features.

Keywords are case-insensitive. In `-std=simula67`, identifier lookup is case-insensitive as well. In `-std=fsim`, user identifiers are case-sensitive; diagnostics and emitted symbol records preserve the spelling written in source.

## 2. Lexical structure

A comment begins with `!` or the word `comment` and ends at the next semicolon. The semicolon belongs to the comment.

```simula
! this complete comment ends here;
comment this one does too;
```

Strings use double quotes and characters use single quotes. Escapes include `\n`, `\r`, `\t`, `\\`, `\"`, `\'`, hexadecimal byte escapes, and Unicode scalar escapes. Source text is interpreted as UTF-8.

Integer literals may be decimal, hexadecimal, binary, or octal. Real literals use a decimal point and optional exponent.

## 3. Blocks

Every compound statement uses `begin` and `end`.

```simula
begin
    integer value;
    value := 42;
end
```

Declarations precede executable statements within a block. A semicolon separates declarations and statements. A semicolon following `end` is accepted where the enclosing grammar requires separation.

## 4. Types

Core scalar/classic types include `integer`, `long integer`, `short integer`, `real`, `boolean`, `character`, `text`, `Head`, and `Link`. `-std=fsim` additionally provides dynamic `string`, `channel(T)`, `future(T)`, `mutex`, `semaphore`, `barrier`, `condition`, and `atomic(integer)` handles.

Class references use `Ref(ClassName)`. Arrays carry compile-time lower and upper bounds:

```simula
array[1:10] integer values;
```

Aliases and enums are available in fsim mode:

```simula
type Counter = integer;
enum Direction begin North = 1, East, South, West end;
```

## 5. Assignment

`:=` performs value assignment. It is required for integer, real, boolean, character, enum, array-value, text, and string values.

`:-` performs reference assignment. Both operands must be compatible reference types. A base-class reference may receive a derived-class object. The reverse direction requires a checked `QUA` expression.

```simula
integer count;
Ref(Animal) animal;
count := 4;
animal :- new Dog();
```

The semantic analyzer rejects the wrong assignment operator even when the machine representation happens to be pointer-sized.

## 6. Classes and prefix inheritance

A class is declared with the historical header:

```simula
Class Parent;
begin
end;
```

A derived class prefixes its declaration with the parent name:

```simula
Parent Class Child;
begin
end;
```

The prefix must name an earlier class declaration. Prefix cycles and invalid prefix kinds are diagnosed. Field layout begins after the two-word object header and includes inherited storage before derived storage.

## 7. Visibility

`Public:`, `Private:`, and `Protected:` are parser state switches. Every declaration after a switch receives that visibility until the next switch or the end of the class.

Private members are visible only to the declaring class. Protected members are visible to the declaring class and descendants. Public members are visible everywhere.

## 8. Virtual specifications

A virtual specification block appears immediately after the class header and before `begin`:

```simula
Class Shape;
Virtual: Procedure Draw Is Procedure Draw;;
begin
    Procedure Draw;
    begin
    end;
end;
```

The repeated name is mandatory. The double semicolon terminates the structural specification. A concrete method matching the specification receives the inherited VMT slot. VMT slots are stable across prefix chains.

## 9. Procedures and functions

Procedures have no result. Functions have an explicit result type.

```simula
integer function Square(integer value);
begin
    return value * value
end;
```

Parameters default to value mode. `name` selects historical call-by-name metadata and `ref` selects reference passing. The current x86-64 ABI passes the receiver first for methods, followed by explicit arguments.

In `-std=fsim`, routines are first-class values through structural `procedure(...)` types. For example, `procedure(integer): integer` accepts one integer and returns an integer. Named routines, compatible procedure variables, and non-capturing lambdas can be passed, stored, called indirectly, and returned from functions. Expression lambdas use `lambda (integer x): integer => x * 2`. Capturing an outer local or `this` is currently rejected rather than miscompiled; see `higher-order-procedures.md`.

## 10. Expressions

Arithmetic operators include `+`, `-`, `*`, `/`, `//`, `mod`, `rem`, and `**`. Comparisons include `=`, `<>`, `<`, `<=`, `>`, and `>=`. Logical operators include `not`, `and`, `or`, `eqv`, and `imp`. In `-std=fsim`, integer operands make `and` and `or` bitwise, alongside `xor`, `shl`, and `shr`. Strict Simula 67 keeps `and`/`or` boolean-only.

In fsim mode, `+` concatenates strings. String equality compares length and UTF-8 bytes, not descriptor addresses. `s.length` returns the UTF-8 byte length, `s.byte(i)` returns the byte at a zero-based index as a `character`, `s.byte_value(i)` returns its integer byte value, `s.slice(first,count)` returns a checked copied slice, and `s.to_integer(default)` parses a base-10 signed integer without constructing a historical text frame. These byte-oriented attributes are intentional for systems code and filesystem paths.

## 11. QUA and RTTI

`reference QUA TargetClass` performs a checked runtime cast. The static analyzer requires related source and target class hierarchies. The generated runtime walks serialized parent RTTI pointers. A failed cast transfers to the compiler-owned panic path before any field or VMT access occurs.

## 12. Control flow

The language provides `if`/`then`/`else`, `while`/`do`, and historical `for` loops.

```simula
for index := 1 step 1 until 10 do
begin
    total := total + index
end
```

Fsim additionally provides `break`, `continue`, `return`, `exit(status)`, and `assert(condition)`.

## 13. Exceptions

Fsim recognizes structured `try`, `catch`, `finally`, and `raise` statements. Same-function exception regions are represented explicitly in IR and a raised object must be a reference value. General cross-function unwinding and scope-exit cleanup are still backend work; `defer` therefore diagnoses during native emission instead of being compiled away.

## 14. Processes and threads

`Process Class`, `detach`, `resume`, `activate`, `reactivate`, `hold`, `delay`, and `passivate` retain Simula vocabulary. `Thread Class` and `Task Class` are fsim-only native forms. Spawned tasks use direct Linux clone-backed stacks and futex completion. Cancellation is cooperative: a request does not mark the future complete until the task actually returns.

## 15. Modules

A source file may begin with a module declaration and import other files:

```simula
module Geometry;
import Math;
import "integer_collections.sim";
```

Imports are expanded deterministically before lexing. Paths are resolved relative to the importing file and then through `-I`, `FSIM_PATH`, explicit standard-library configuration, installed-library discovery, and source-tree fallbacks. Unquoted names receive a `.sim` suffix and dotted names map to directories. Loading uses a DFS state machine, rejects cycles with a dedicated diagnostic, and can emit Make-compatible dependency files.


## 16. Modern syntax additions

The fsim profile accepts Pascal-style declaration forms while retaining Simula block and class syntax:

```simula
var count: integer := 0;
integer function Add(left: integer, right: integer): integer;
begin
    return left + right
end;
```

Classic control forms include labels, switches, `inspect`, and process activation. Modern executable forms include `repeat`, `case`, `with`, `critical`, and `synchronized`. Native concurrency types are `channel(T)`, `future(T)`, `mutex`, `semaphore`, `barrier`, `condition`, and `atomic(integer)`. `parallel` and `defer` are recognized but deliberately rejected by the native backend until structured capture and scope-exit lowering are complete. See `dialects.md`, `classic-simula-compatibility.md`, and `concurrency.md` for profile-specific rules.
## 17. Native OS surface

The native Linux backend exposes a small fsim-only systems surface with `os_` prefixes. It is not injected in `-std=simula67`. Current primitives cover argv access, directory handles backed by `openat`/`getdents64`, non-following path metadata, path joining/basenames, stdout path writes, and stderr writes. The surface is deliberately narrow rather than exposing a generic syscall-number escape hatch.

`tools/fsfind.sim` is the main systems example. It uses a bounded worker pool and shares directory work through a mutex-protected queue. Ordinary entries are matched from the directory buffer without constructing a full path, and output uses a single `writev` call for parent/name/separator/terminator.


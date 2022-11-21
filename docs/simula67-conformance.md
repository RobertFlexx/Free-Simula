# simula 67 conformance notes

this is deliberately less exciting than the readme. if you want drama, go read the changelog.

syntax accepted, semantics represented, and native runtime behavior are three different things. fsim should not claim the third because the first one happened to parse. that sentence is the entire thesis of this document.

## dialect boundary

`-std=simula67` folds identifiers for lookup and injects the historical standard environment before user declarations are analyzed. `sysout`, `SYSOUT` and `SySoUt` therefore resolve to the same standard object. yes, all three. history was not case sensitive.

`-std=fsim` does neither of those things. lookup remains exact, and legacy globals/classes are absent unless a future explicit compatibility module is imported. classic source syntax which is useful outside the implicit environment remains accepted where it does not conflict with the modern profile.

there are unit tests for both sides of this rule, because namespace leakage is the kind of bug that feels harmless until somebody names their own helper `blanks`.

## text runtime

strict native `text` values are pointers to this visible descriptor shape:

```pascal
type
  TTextDescriptor = packed record
    StartPos: PAnsiChar;
    CurrentPos: Int32;
    Length: Int32;
  end;
```

that is 16 bytes on the amd64 target. the runtime keeps ownership/main-frame flags in hidden metadata before descriptors it owns, so the language value stays one pointer wide and the general ir does not need aggregate registers.

| operation | strict implementation |
|---|---|
| literal frame | readonly descriptor emitted in rodata |
| `blanks(n)` | writable arena frame filled with spaces |
| `copy(t)` | independent writable copy |
| `:-` | descriptor reference binding |
| `:=` | character transfer into existing frame plus blank fill |
| `constant`, `start`, `length`, `main`, `pos`, `more` | native |
| `setpos` | native, invalid positions move to `length + 1` |
| `getchar` / `putchar` | native cursor operations with bounds/write checks |
| `sub(i,n)` | zero-copy slice descriptor sharing the character buffer |
| `strip` | zero-copy trailing-space slice |
| `getint`, `getreal`, `getfrac` | direct parsing from the active slice |
| `putint`, `putfix`, `putreal`, `putfrac` | fixed-frame editing with overflow fill |
| `upcase`, `lowcase` | in-place ascii case mapping on writable frames |

small strict descriptors and owned frames come from a dedicated 64 kib mmap backed arena, separate from the modern string/object allocator. Class and procedure parameter transmission preserves the Standard distinction: default `text` is a reference parameter; explicit `value text` receives an independent `copy` before entry.

modern `string` keeps the previous native string abi and has no cursor position or historical frame aliasing hidden inside it. it is a string, not a museum piece.

## basic io

strict startup creates static `sysin` and `sysout` compatible objects and 132 character images.

| attribute | current native path |
|---|---|
| `sysin.image`, `sysout.image` | real text descriptors attached to ordinary object fields |
| `inimage` | line read from linux fd 0 with crlf handling and overlong-line drain |
| `inchar` | advances image and obtains a new image when needed |
| `inint`, `inreal`, `infrac` | image item scan plus text de-editing |
| `intext(w)` | writable frame filled from input characters |
| `lastitem`, `endfile` | native image/eof state |
| `field(w)` | output image slice with standard image boundary handling |
| `outchar`, `outtext` | buffered through the output image |
| `outint`, `outfix`, `outreal`, `outfrac` | field editing and image output |
| `outimage` | transfers the used image to fd 1, reblanks and resets it |

old shorthand output statements are lowered through the same strict sysout path. they are not a second, slightly different printf implementation. one image layer, one set of bugs, one set of fixes.

`file.open`, arbitrary external files, `directfile`, `bytefile`, and complete `printfile` page control are not finished yet. symbols which have no compiler-owned native implementation must diagnose rather than silently pretending success. a diagnostic is the compiler admitting the truth early.

## environment procedures

currently bound and natively implemented in strict mode:

- `blanks`, `copy`
- `char`, `isochar`, `rank`, `isorank`, `digit`, `letter`
- `lowten`, `decimalmark`, `upcase`, `lowcase`
- `mod`, `rem`, `entier`, `addepsilon`, `subepsilon`
- `sqrt`, `sin`, `cos`, `tan`, `arctan`, `ln`, `log10`, `exp`

`mod` and `rem` have separate backend semantics. `rem` follows signed division remainder while `mod` adjusts a nonzero remainder to have the divisor's sign. they were accidentally identical once, and there is a test so they never are again.

not yet complete from the full standard environment are the generic arithmetic overloads such as `abs`, `sign`, `max` and `min`, the remaining transcendental functions, array bound inquiry, random-number procedures with name parameters, timing/error details, and the full implementation-defined constants set. they need proper type/runtime semantics rather than fake one-signature wrappers. to be continued :-)

## source and object semantics

| area | status |
|---|---|
| algol blocks and declaration forms | parsed checked lowered |
| `:=` and `:-` distinction | native paths including strict text behavior |
| prefix classes, inherited layout, and `inner` | native path plus regression coverage |
| class parameters / constructors | checked and lowered, including Standard default-reference `text` and explicit `value text` copy-on-entry |
| `new`, `this`, `qua`, `is`, `in`, `none`, identity comparison | native paths |
| `inspect / when / otherwise` | checked and lowered |
| classic `protected` / `hidden` lists | access checked |
| old procedure/function heads and result-name assignment | supported |
| proper procedure parameters | callable by native code pointer with signature compatibility checks; general call-by-name remains incomplete |
| radix numbers, old exponent forms, comments, end comments, strings, char codes | lexer regression coverage |
| logical precedence, `and then`, `or else`, `imp`, `eqv` | cfg lowering with short circuit |
| multidimensional `a(i,j)` | nested-dimension read/write lowering |
| labels, switches, local designational transfer | supported locally |
| external class/procedure heads | source model only, target linkage is implementation specific |

numeric lowering now materializes integer to real widening at calls, assignments, initializers, returns, and mixed real operations. the conversion opcodes existed before but were not actually emitted at those boundaries; now they are, and the numbers finally agree.

## hard blockers before a universal standards-conformance claim

- true call by name needs caller thunks and environments, including writable/name assignment behavior
- non local goto needs runtime unwinding across active block/procedure instances
- `Simulation` still needs the full cooperative event-set scheduler, activation/reactivation rules, and process continuation model
- complete historical file classes and the rest of `ENVIRONMENT` still need native implementations
- arbitrary external object formats need explicit target adapters; there is no honest generic linker trick for that
- a release claiming full standards conformance needs comparison against a published reference corpus using a compiler actually built with fpc; static source audits do not count

Free Simula may be advertised as a direct Simula dialect, and the `-std=simula67` profile as a substantial/native Simula 67 compatibility mode. that is the claim, and that is the whole claim.

for known unsupported native cases the backend is expected to give a diagnostic instead of producing an executable it already knows is wrong.

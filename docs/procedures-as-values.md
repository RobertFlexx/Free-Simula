# procedures as values

Free Simula keeps the old ALGOL/Simula idea that a procedure can be supplied to another routine, while the `fsim` dialect also gives procedure values an explicit structural type. passing a function is not a new idea, but it is a good one, so we kept both old and new forms.

## classic proper-procedure parameters

Strict `-std=simula67` keeps the historical declaration shape:

```simula
integer procedure Apply(fn, value);
procedure fn;
value value;
integer value;
begin
    Apply := fn(value)
end;
```

A proper-procedure formal is callable inside the receiving routine. Its effective parameter signature is learned from calls in that routine and checked against an actual routine passed by the caller. Procedure parameters themselves are read-only, because nobody needs a formal parameter you can reassign at 3 a.m.

This support does not pretend that general call-by-name is finished. Native call-by-name still needs thunk/environment lowering and remains a documented conformance gap. we accept the old syntax, we check the types, and we tell the truth about the rest.

## first-class procedure types

The modern `fsim` profile adds structural procedure types:

```simula
type Unary = procedure(integer): integer;
```

The part in parentheses is the argument list. A missing result annotation means a procedure with no result. Parameter modes may be written in the type when needed:

```simula
type Mutator = procedure(ref integer);
type Producer = procedure(): integer;
```

Procedure values use ordinary `:=` value assignment. Compatible signatures require the same result type, argument count, parameter types, and passing modes. close enough is not a type checker's philosophy, and it is not ours either.

## lambdas

Expression lambdas use a deliberately small syntax that still looks at home next to Simula declarations:

```simula
lambda (integer value): integer => value * 2
```

The result type is explicit. Lambdas are real compiler-generated routines, not interpreter objects or generated C. They can be stored, passed to higher-order routines, called indirectly, and returned from functions.

```simula
type Unary = procedure(integer): integer;

integer function Apply(Unary fn, integer value);
begin
    return fn(value)
end;

program Demo;
begin
    Unary twice;
    integer answer;
    twice := lambda (integer value): integer => value * 2;
    answer := Apply(twice, 21);
    assert(answer = 42)
end;
```

`lambda` and `procedure(...)` type syntax are `-std=fsim` extensions. Strict Simula 67 rejects them instead of silently changing the historical language. the old language does not do lambdas and it is too old to start pretending.

## closure boundary

The current native representation is one machine-word code pointer. Non-capturing lambdas therefore have no heap allocation and use the same internal calling convention as a named routine.

A lambda that references an outer local, parameter, class field, or `this` is rejected at compile time. Supporting those cases correctly requires an environment object plus a static/closure link; emitting a raw code pointer would be a silent miscompile. Bound method values are rejected for the same reason until receiver closures are implemented. a closure is a box you pay for; we are not handing out empty boxes labeled as real ones.

## backend safety

Indirect internal calls are explicit IR operations and are classified as calls by the optimizer and register allocator. Missing native bodies, invalid frame storage, null indirect targets when null checks are enabled, and unsupported receiver captures produce diagnostics rather than zero-valued fallbacks. a crash you can see coming beats a wrong answer you cannot.

# the classic profile

everything in this file is about `-std=simula67`, the profile that behaves like the language has a memory of the 1960s and is not ashamed of it.

## profiles

classic source syntax is intentionally kept useful in both profiles, but the implicit historical environment belongs only to `-std=simula67`. strict lookup is case insensitive and installs the standard classes, text helpers, and basic io objects. free simula lookup is exact and leaves those names alone, so you can write your own `sysout` without summoning the ghost of standard environment.

## blocks, assignments, and classes

both profiles use algol style `begin` / `end`, `:=` is value assignment and `:-` is reference binding.

prefix classes and `inner` keep the old model:

```simula
Class Vehicle;
begin
    outtext("prefix");
    inner;
    outtext("suffix")
end;

Vehicle Class Bus;
begin
    outtext("body")
end;
```

inherited field layout and vmt slots are kept stable, and prefix bodies lower in prefix order. the bus is still a vehicle, just with a body.

## protection and virtual parts

historical heading protection is accepted separately from free simula visibility sections:

```simula
Class Vault;
protected secret;
begin
    integer secret
end;
```

virtual specifications remain heading declarations rather than being rewritten into a modern keyword scheme. the old grammar gets to keep its dignity.

## procedures and name parameters

traditional headings and assignment to a function name are accepted:

```simula
integer Procedure Sum(first, last);
value first, last;
integer first, last;
begin
    Sum := first + last
end;
```

value and reference parameters have native paths. name mode is represented and type checked, but full call-by-name thunk environments are still one of the remaining hard compatibility jobs. we type check it; we do not fake it.

## loops, arrays, labels, and switches

classic for elements signed `step ... until`, value/reference while elements, old bounded arrays, and multidimensional comma indexing are handled directly.

local labels, switches, and conditional designators lower through the cfg. non local goto across active procedure/block instances still needs runtime unwinding, which is a polite way of saying "do not hold your breath, but it is on the list".

## text

strict text is no longer an alias for the modern dynamic string runtime. they are different things that happen to both be called text-ish things, and the language knows which one you mean.

literals and writable frames are descriptors, positions are 1 based, `setpos`, `more`, character get/put, zero-copy `sub`, `strip`, numeric de-editing, and fixed-frame numeric editing have their own strict backend operations.

`:-` changes the referenced frame, `:=` writes characters into the destination frame. subtexts share the original byte storage, and therefore writable subtext edits are visible through the main frame, like old code expects. yes, this is exactly as foot-gun-adjacent as it sounds, and yes, it is required for compatibility.

`sysin` and `sysout` use 132 character image frames, and the classic output shorthand goes through that image layer too. there is not a second, slightly different printf hiding in the corner.

## process and simulation classes

`Link`, `Head`, `SIMSET`, process syntax, and the `Simulation` surface are modeled independently from free simula threads/tasks. the old process vocabulary is its own universe with its own rules.

list operations have native code. the full historical cooperative simulation scheduler is not complete yet, and modern native threads are not being passed off as the same semantics, because they are not. a thread is not a process; whoever says otherwise has not read the manual, which is this document.

## externals

historical external heads can be represented and checked. actually consuming implementation-specific old object formats requires a target adapter and remains explicit rather than silently routed through gcc or a host linker. old object formats get explicit adapters or they get nothing, and that is the correct order.

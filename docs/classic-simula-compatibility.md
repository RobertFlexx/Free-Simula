# classic simula compatibility

## profiles

classic source syntax is intentionally kept useful in both profiles but the implicit historical environment belongs only to `-std=simula67`

strict lookup is case insensitive and installs the standard classes text helpers and basic io objects, free simula lookup is exact and leaves those names alone

## blocks assignments and classes

both profiles use algol style `begin` / `end`, `:=` is value assignment and `:-` is reference binding

prefix classes and `inner` keep the old model

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

inherited field layout and vmt slots are kept stable and prefix bodies lower in prefix order

## protection and virtual parts

historical heading protection is accepted separately from free simula visibility sections

```simula
Class Vault;
protected secret;
begin
    integer secret
end;
```

virtual specifications remain heading declarations rather than being rewritten into a modern keyword scheme

## procedures and name parameters

traditional headings and assignment to a function name are accepted

```simula
integer Procedure Sum(first, last);
value first, last;
integer first, last;
begin
    Sum := first + last
end;
```

value and reference parameters have native paths, name mode is represented and type checked but full call-by-name thunk environments are still one of the remaining hard compatibility jobs

## loops arrays labels and switches

classic for elements signed `step ... until`, value/reference while elements, old bounded arrays and multidimensional comma indexing are handled directly

local labels switches and conditional designators lower through the cfg, non local goto across active procedure/block instances still needs runtime unwinding

## text

strict text is no longer an alias for the modern dynamic string runtime

literals and writable frames are descriptors, positions are 1 based, `setpos`, `more`, character get/put, zero-copy `sub`, `strip`, numeric de-editing and fixed-frame numeric editing have their own strict backend operations

`:-` changes the referenced frame, `:=` writes characters into the destination frame, subtexts share the original byte storage and therefore writable subtext edits are visible through the main frame like old code expects

`sysin` and `sysout` use 132 character image frames and the classic output shorthand goes through that image layer too

## process and simulation classes

`Link`, `Head`, `SIMSET`, process syntax and the `Simulation` surface are modeled independently from free simula threads/tasks

list operations have native code, the full historical cooperative simulation scheduler is not complete yet and modern native threads are not being passed off as the same semantics because they are not

## externals

historical external heads can be represented and checked, actually consuming implementation specific old object formats requires a target adapter and remains explicit rather than silently routed through gcc or a host linker

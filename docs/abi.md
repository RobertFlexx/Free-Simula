# Linux x86-64 ABI

## Calling convention

Fsim uses the System V AMD64 integer argument sequence `rdi`, `rsi`, `rdx`, `rcx`, `r8`, and `r9`. A method receiver occupies `rdi`; explicit method parameters begin at `rsi`. Integer, boolean, character, reference, descriptor pointer, enum, and address-sized values use general-purpose registers.

Integer and pointer results use `rax`. Real values are internally represented as IEEE-754 binary64 bits in IR value locations and moved through `xmm0` for arithmetic and conversion operations.

The allocator may use caller-saved registers for short intervals and `rbx`, `r12`, `r13`, `r14`, and `r15` for intervals crossing calls. Used callee-saved registers are recorded per function and saved in deterministic order.

## Stack frame

A function prologue saves `rbp`, establishes a frame pointer, saves selected callee-saved registers, and reserves a 16-byte-aligned local frame. The frame contains spill slots, the optional method receiver, parameters copied from registers, and source-level local variables.

A common epilogue target restores the stack and registers. Return statements move the result to `rax` and jump to this target.

## Object layout

Every object begins with:

| Offset | Size | Meaning |
|---:|---:|---|
| 0 | 8 | pointer to class RTTI record |
| 8 | 8 | pointer to class VMT |
| 16 | ... | inherited fields followed by local fields |

Fields are aligned to their type alignment. Derived objects retain the complete prefix object layout, allowing base methods to use fixed offsets.

## String layout

A string value is a pointer to an immutable or heap-backed descriptor:

| Offset | Size | Meaning |
|---:|---:|---|
| 0 | 8 | UTF-8 byte length |
| 8 | length | UTF-8 bytes |
| 8+length | 1 | zero terminator for diagnostics and syscall interoperability |

The terminator is not included in equality or length. Concatenation allocates one descriptor, checks the total size, copies both byte ranges, and writes a terminator.

## RTTI layout

Each class RTTI record begins with a parent RTTI pointer, object size, VMT slot count, name length, flags, and UTF-8 class name. Parent pointers are relocated after read-only data receives its final virtual address.

`QUA` compares the object's RTTI pointer with the requested RTTI and walks parent pointers until a match or null. Null remains null under a cast. A non-null failed cast enters the panic routine.

## Native threads

The runtime allocates a dedicated stack with `mmap`, places the child entry and context in a startup record, and invokes Linux `clone` with VM, filesystem, file-descriptor, signal-handler, and thread-group sharing flags. The child transfers to the compiler-generated entry thunk and exits through the thread-exit syscall path.

## Syscalls

The embedded runtime directly uses Linux x86-64 syscall numbers for read, write, mmap, munmap, clone, exit, and exit-group. Executables do not require an ELF interpreter segment or dynamic section.

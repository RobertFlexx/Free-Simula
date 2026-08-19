# ELF64 Image Construction

The linker writes a little-endian `ET_EXEC`, `EM_X86_64` image. The file has no interpreter and no dynamic dependencies.

Two loadable segments are used. The first is read/execute and contains the ELF header, program-header table, and `.text`. The second is read/write and contains `.rodata`, `.data`, and the memory-only `.bss` tail. Section headers are retained unless stripping policy removes optional symbols.

The section set is:

- `.text`: runtime and user machine code.
- `.rodata`: panic text, string descriptors, RTTI records, and VMT arrays.
- `.data`: compiler-emitted writable initial data.
- `.bss`: zero-initialized storage represented only by segment memory size.
- `.symtab`: local section symbols and global function symbols.
- `.strtab`: symbol names.
- `.shstrtab`: section names.

Layout uses 4096-byte segment alignment. Section and segment offsets are calculated with checked 64-bit arithmetic. All code labels are resolved before ELF serialization. Function addresses stored in VMTs and parent pointers stored in RTTI are patched after final virtual addresses are known.

The entry point is a compiler-generated `_start` thunk. It clears `rbp`, calls the selected program entry function, moves its result to the Linux exit-status argument register, and jumps to the embedded process-exit helper.

`-S` does not invoke a disassembler. It emits the backend's resolved instruction annotations and byte ranges. `--emit-raw` writes the finalized `.text` payload without an ELF wrapper.

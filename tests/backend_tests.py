#!/usr/bin/env python3
"""Optimization-equivalence and autonomous ELF backend validation."""
from __future__ import annotations

import argparse
import os
import struct
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OPT_LEVELS = ["-O0", "-O1", "-O2", "-O3", "-Ofast"]
CASES = [
    ROOT / "tests/integration/value_assignment.sim",
    ROOT / "tests/integration/for_loop.sim",
    ROOT / "tests/integration/optimizer_branches.sim",
    ROOT / "tests/integration/string_equality.sim",
]


def run(command: list[str], timeout: int = 30) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=timeout,
        check=False,
        env={**os.environ, "LC_ALL": "C", "LANG": "C"},
    )


def validate_elf(path: Path) -> list[str]:
    failures: list[str] = []
    data = path.read_bytes()
    if len(data) < 64:
        return [f"ELF image is only {len(data)} bytes"]
    if data[:4] != b"\x7fELF":
        return ["missing ELF magic"]
    if data[4] != 2:
        failures.append("ELF is not 64-bit")
    if data[5] != 1:
        failures.append("ELF is not little-endian")
    if data[6] != 1:
        failures.append("unexpected ELF identification version")
    header = struct.unpack_from("<16sHHIQQQIHHHHHH", data, 0)
    _, elf_type, machine, version, entry, program_offset, section_offset, _, _, program_size, program_count, section_size, section_count, section_names = header
    if elf_type != 2:
        failures.append(f"ELF type is {elf_type}, expected ET_EXEC")
    if machine != 62:
        failures.append(f"ELF machine is {machine}, expected EM_X86_64")
    if version != 1:
        failures.append("ELF header version is not current")
    if entry == 0:
        failures.append("ELF entry point is zero")
    if program_size != 56:
        failures.append(f"program-header size is {program_size}, expected 56")
    if program_count == 0:
        failures.append("ELF has no program headers")
    if program_offset + program_count * program_size > len(data):
        failures.append("program-header table extends beyond the file")
        return failures
    load_segments = 0
    executable_loads = 0
    writable_loads = 0
    entry_covered = False
    for index in range(program_count):
        offset = program_offset + index * program_size
        p_type, flags, file_offset, virtual_address, _, file_size, memory_size, alignment = struct.unpack_from("<IIQQQQQQ", data, offset)
        if p_type == 3:
            failures.append("ELF contains PT_INTERP and would require a dynamic loader")
        if p_type == 2:
            failures.append("ELF contains PT_DYNAMIC")
        if p_type == 1:
            load_segments += 1
            if flags & 1:
                executable_loads += 1
            if flags & 2:
                writable_loads += 1
            if virtual_address <= entry < virtual_address + memory_size:
                entry_covered = True
            if file_offset + file_size > len(data):
                failures.append(f"PT_LOAD {index} extends beyond the file")
            if alignment and (alignment & (alignment - 1)):
                failures.append(f"PT_LOAD {index} alignment is not a power of two")
    if load_segments == 0:
        failures.append("ELF has no PT_LOAD segment")
    if executable_loads == 0:
        failures.append("ELF has no executable PT_LOAD segment")
    if not entry_covered:
        failures.append("ELF entry point is outside all loadable segments")
    if section_count:
        if section_size != 64:
            failures.append(f"section-header size is {section_size}, expected 64")
        if section_offset + section_count * section_size > len(data):
            failures.append("section-header table extends beyond the file")
        if section_names >= section_count:
            failures.append("section-name table index is outside section table")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--compiler", type=Path, required=True)
    args = parser.parse_args()
    compiler = args.compiler.resolve()
    failures = 0
    with tempfile.TemporaryDirectory(prefix="fsim-backend-") as temporary:
        output_directory = Path(temporary)
        for source in CASES:
            expected_path = source.with_suffix(".out")
            expected = expected_path.read_bytes() if expected_path.exists() else b""
            baseline: bytes | None = None
            for level in OPT_LEVELS:
                executable = output_directory / f"{source.stem}-{level[1:]}"
                compilation = run([
                    str(compiler), "-std=fsim", level,
                    "--verify-each-pass", "-o", str(executable), str(source),
                ], 60)
                if compilation.returncode != 0:
                    failures += 1
                    print(f"FAIL {source.name} {level}: compile\n{compilation.stderr.decode(errors='replace')}")
                    continue
                elf_failures = validate_elf(executable)
                if elf_failures:
                    failures += 1
                    print(f"FAIL {source.name} {level}: " + "; ".join(elf_failures))
                    continue
                execution = run([str(executable)], 15)
                if execution.returncode != 0:
                    failures += 1
                    print(f"FAIL {source.name} {level}: exit {execution.returncode}\n{execution.stderr.decode(errors='replace')}")
                    continue
                if execution.stdout != expected:
                    failures += 1
                    print(f"FAIL {source.name} {level}: stdout {execution.stdout!r}, expected {expected!r}")
                    continue
                if baseline is None:
                    baseline = execution.stdout
                elif execution.stdout != baseline:
                    failures += 1
                    print(f"FAIL {source.name} {level}: optimization changed observable output")
                    continue
                print(f"PASS {source.name:30} {level:6} autonomous ELF")
    if failures:
        print(f"{failures} backend test(s) failed")
        return 1
    print("all optimization-equivalence and ELF backend tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

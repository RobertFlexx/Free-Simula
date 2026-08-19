#!/usr/bin/env python3
"""Compare O0 and O3 behavior on deterministic native programs."""
from __future__ import annotations

import argparse
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CASES = [
    "value_assignment.sim",
    "optimizer_branches.sim",
    "arrays.sim",
    "integer_power.sim",
    "integer_bitops.sim",
    "for_loop.sim",
    "numeric_widening.sim",
    "real_power.sim",
    "string_equality.sim",
    "string_extended.sim",
]


def run(command: list[str], timeout: int = 30) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, timeout=timeout, check=False)


def build_and_run(compiler: Path, source: Path, opt: str, out: Path) -> tuple[int, str, str]:
    compiled = run([str(compiler), "-std=fsim", opt, str(source), "-o", str(out)], 60)
    if compiled.returncode != 0:
        return 1000 + compiled.returncode, "", compiled.stdout + compiled.stderr
    executed = run([str(out)], 20)
    return executed.returncode, executed.stdout, executed.stderr


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--compiler", type=Path, required=True)
    args = ap.parse_args()
    compiler = args.compiler.resolve()
    failures = 0
    with tempfile.TemporaryDirectory(prefix="fsim-opt-diff-") as tmp:
        tmpdir = Path(tmp)
        for filename in CASES:
            source = ROOT / "tests" / "integration" / filename
            o0 = build_and_run(compiler, source, "-O0", tmpdir / (source.stem + "-o0"))
            o3 = build_and_run(compiler, source, "-O3", tmpdir / (source.stem + "-o3"))
            if o0 != o3:
                print(f"FAIL {filename}")
                print(f"  O0: exit={o0[0]} stdout={o0[1]!r} stderr={o0[2]!r}")
                print(f"  O3: exit={o3[0]} stdout={o3[1]!r} stderr={o3[2]!r}")
                failures += 1
            else:
                print(f"PASS {filename}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Compile real-world canaries through IR and native code generation without running them."""
from __future__ import annotations

import argparse
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CASES = [
    ROOT / "tests/check/neon_breach_full_canary.sim",
    ROOT / "tests/check/raylib_ffi_canary.sim",
    ROOT / "tests/integration/fsim_c_record_return.sim",
]


def run(command: list[str], timeout: int = 90) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=timeout,
        check=False,
        env={**os.environ, "LC_ALL": "C", "LANG": "C"},
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--compiler", type=Path, required=True)
    args = parser.parse_args()
    compiler = args.compiler.resolve()
    if not compiler.is_file():
        print(f"error: compiler not found: {compiler}")
        return 2

    failures = 0
    with tempfile.TemporaryDirectory(prefix="fsim-lowering-") as temporary:
        outdir = Path(temporary)
        for source in CASES:
            output = outdir / source.stem
            result = run([
                str(compiler), "-std=fsim", "-O3", "--verify-each-pass",
                "-o", str(output), str(source),
            ])
            if result.returncode != 0:
                failures += 1
                print(f"FAIL {source.name}")
                if result.stdout:
                    print(result.stdout.rstrip())
                if result.stderr:
                    print(result.stderr.rstrip())
                continue
            if not output.is_file() or output.stat().st_size == 0:
                failures += 1
                print(f"FAIL {source.name}: compiler returned success without an executable")
                continue
            print(f"PASS {source.name}")

    if failures:
        print(f"{failures} lowering canary failure(s)")
        return 1
    print("all lowering/codegen canaries passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

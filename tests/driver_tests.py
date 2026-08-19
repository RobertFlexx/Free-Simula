#!/usr/bin/env python3
"""Driver startup, option-order, dialect, and executable smoke tests."""
from __future__ import annotations

import argparse
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def run(command: list[str], timeout: int = 45) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        command,
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=timeout,
        check=False,
        env={**os.environ, "LC_ALL": "C", "LANG": "C"},
    )


def require_success(command: list[str], label: str) -> subprocess.CompletedProcess[bytes]:
    result = run(command)
    if result.returncode != 0:
        raise RuntimeError(
            f"{label} failed with exit {result.returncode}\n"
            f"stdout:\n{result.stdout.decode(errors='replace')}\n"
            f"stderr:\n{result.stderr.decode(errors='replace')}"
        )
    combined = (result.stdout + result.stderr).lower()
    if b"internal compiler error" in combined or b"erangeerror" in combined:
        raise RuntimeError(f"{label} reported an internal range failure")
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--compiler", type=Path, required=True)
    args = parser.parse_args()
    compiler = args.compiler.resolve()
    fsim_source = ROOT / "tests/smoke/minimal_fsim.sim"
    classic_source = ROOT / "tests/smoke/minimal_simula67.sim"

    version = require_success([str(compiler), "--version"], "version query")
    if b"fsim 1.6.2" not in version.stdout:
        raise RuntimeError("version output does not identify fsim 1.6.2")
    self_test = require_success([str(compiler), "--self-test"], "compiler self-test")
    if b"self-test passed" not in self_test.stdout.lower():
        raise RuntimeError("compiler self-test did not report success")

    require_success(
        [str(compiler), "--check", str(fsim_source)],
        "default-dialect check",
    )
    require_success(
        [str(compiler), str(classic_source), "--check", "-std=simula67"],
        "trailing-dialect check",
    )
    require_success(
        [str(compiler), "-std=simula67", "--check", str(classic_source)],
        "leading-dialect check",
    )

    with tempfile.TemporaryDirectory(prefix="fsim-driver-") as temporary:
        directory = Path(temporary)
        cases = [
            ("default", [str(compiler), str(fsim_source), "-o", str(directory / "default")]),
            ("classic-trailing", [str(compiler), str(classic_source), "-o", str(directory / "classic-trailing"), "-std=simula67"]),
            ("classic-leading", [str(compiler), "-std=simula67", str(classic_source), "-o", str(directory / "classic-leading")]),
        ]
        for label, command in cases:
            require_success(command, label + " compilation")
            executable = Path(command[command.index("-o") + 1])
            if not executable.exists():
                raise RuntimeError(f"{label} did not produce {executable}")
            if executable.read_bytes()[:4] != b"\x7fELF":
                raise RuntimeError(f"{label} output is not ELF")
            execution = require_success([str(executable)], label + " execution")
            if execution.stdout:
                raise RuntimeError(f"{label} unexpectedly wrote {execution.stdout!r}")

    print("all driver startup and dialect-order smoke tests passed")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, subprocess.TimeoutExpired) as error:
        print(f"FAIL: {error}")
        raise SystemExit(1)

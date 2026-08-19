#!/usr/bin/env python3
"""Authoritative-style Simula 67 syntax and native execution regressions."""
from __future__ import annotations

import argparse
import os
import subprocess
import tempfile
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SUITE = ROOT / "tests" / "simula67"


def run(command: list[str], timeout: int = 60) -> subprocess.CompletedProcess[str]:
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


def fail(label: str, result: subprocess.CompletedProcess[str], detail: str = "") -> None:
    raise RuntimeError(
        f"{label}: {detail}\nexit={result.returncode}\n"
        f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
    )


def check_source(compiler: Path, source: Path) -> None:
    for dialect in ("simula67", "fsim"):
        result = run([str(compiler), f"-std={dialect}", "--check", str(source)])
        if result.returncode != 0:
            fail(source.name, result, f"{dialect} source check failed")
        combined = (result.stdout + result.stderr).lower()
        if "internal compiler error" in combined or "erangeerror" in combined:
            fail(source.name, result, "compiler reported an internal failure")


def compile_and_run(compiler: Path, source: Path) -> None:
    expected = source.with_suffix(".out").read_text(encoding="utf-8")
    with tempfile.TemporaryDirectory(prefix="fsim-simula67-") as temporary:
        executable = Path(temporary) / source.stem
        result = run([
            str(compiler), "-std=simula67", "-O2", str(source),
            "-o", str(executable),
        ])
        if result.returncode != 0:
            fail(source.name, result, "native compilation failed")
        if not executable.exists() or executable.read_bytes()[:4] != b"\x7fELF":
            raise RuntimeError(f"{source.name}: compiler did not create an ELF executable")
        execution = run([str(executable)], timeout=15)
        if execution.returncode != 0:
            fail(source.name, execution, "generated executable failed")
        if execution.stdout != expected:
            fail(
                source.name,
                execution,
                f"stdout mismatch: expected {expected!r}, got {execution.stdout!r}",
            )


def negative(compiler: Path, source: Path) -> None:
    expected = source.with_suffix(".expect").read_text(encoding="utf-8").strip().lower()
    result = run([str(compiler), "-std=simula67", "--check", str(source)])
    if result.returncode == 0:
        fail(source.name, result, "invalid modern extension was accepted")
    combined = (result.stdout + result.stderr).lower()
    if expected and expected not in combined:
        fail(source.name, result, f"missing diagnostic fragment {expected!r}")



def backend_negative(compiler: Path, source: Path) -> None:
    expected = source.with_suffix(".expect").read_text(encoding="utf-8").strip().lower()
    with tempfile.TemporaryDirectory(prefix="fsim-simula67-backend-negative-") as temporary:
        executable = Path(temporary) / source.stem
        result = run([
            str(compiler), "-std=simula67", "-O2", str(source),
            "-o", str(executable),
        ])
        if result.returncode == 0:
            fail(source.name, result, "unsupported native semantic was silently accepted")
        combined = (result.stdout + result.stderr).lower()
        if expected and expected not in combined:
            fail(source.name, result, f"missing backend diagnostic {expected!r}")


def runtime_negative(compiler: Path, source: Path) -> None:
    expected_exit = int(source.with_suffix(".exit").read_text(encoding="utf-8").strip())
    expected_text = source.with_suffix(".expect").read_text(encoding="utf-8").strip().lower()
    with tempfile.TemporaryDirectory(prefix="fsim-simula67-negative-") as temporary:
        executable = Path(temporary) / source.stem
        result = run([
            str(compiler), "-std=simula67", "-O2", str(source),
            "-o", str(executable),
        ])
        if result.returncode != 0:
            fail(source.name, result, "runtime-negative source did not compile")
        execution = run([str(executable)], timeout=15)
        if execution.returncode != expected_exit:
            fail(
                source.name, execution,
                f"expected runtime exit {expected_exit}, got {execution.returncode}",
            )
        combined = (execution.stdout + execution.stderr).lower()
        if expected_text and expected_text not in combined:
            fail(source.name, execution, f"missing runtime diagnostic {expected_text!r}")

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--compiler", type=Path, required=True)
    args = parser.parse_args()
    compiler = args.compiler.resolve()
    passed = 0
    failures: list[str] = []

    def attempt(label: str, action) -> None:
        nonlocal passed
        try:
            action()
        except (RuntimeError, subprocess.TimeoutExpired) as error:
            failures.append(f"{label}: {error}")
            print(f"FAIL {label}")
        else:
            print(f"PASS {label}")
            passed += 1

    for source in sorted((SUITE / "check").glob("*.sim")):
        attempt(f"check {source.name}", lambda source=source: check_source(compiler, source))
    for source in sorted((SUITE / "run").glob("*.sim")):
        attempt(f"run   {source.name}", lambda source=source: compile_and_run(compiler, source))
    for source in sorted((SUITE / "negative").glob("*.sim")):
        attempt(f"reject {source.name}", lambda source=source: negative(compiler, source))
    for source in sorted((SUITE / "backend-negative").glob("*.sim")):
        attempt(f"backend-reject {source.name}", lambda source=source: backend_negative(compiler, source))
    for source in sorted((SUITE / "runtime-negative").glob("*.sim")):
        attempt(f"trap  {source.name}", lambda source=source: runtime_negative(compiler, source))

    print(f"{passed} strict Simula 67 regression cases passed")
    if failures:
        print(f"{len(failures)} strict Simula 67 regression case(s) failed", file=sys.stderr)
        for failure in failures:
            print("---", file=sys.stderr)
            print(failure, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Compile and execute fsim conformance, integration, and negative tests."""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


@dataclass
class Result:
    name: str
    passed: bool
    detail: str = ""
    duration: float = 0.0


def run(command: list[str], timeout: int = 30) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=timeout,
        check=False,
        env={**os.environ, "LC_ALL": "C", "LANG": "C"},
    )


def compile_and_run(compiler: Path, source: Path, expected_stdout: str = "", expected_exit: int = 0) -> Result:
    start = time.perf_counter()
    with tempfile.TemporaryDirectory(prefix="fsim-test-") as temporary:
        executable = Path(temporary) / "program"
        compile_result = run([str(compiler), "-std=fsim", "-O3", "-o", str(executable), str(source)], 60)
        if compile_result.returncode != 0:
            return Result(source.name, False, "compile failed:\n" + compile_result.stderr, time.perf_counter() - start)
        if not executable.exists():
            return Result(source.name, False, "compiler reported success without producing an executable", time.perf_counter() - start)
        execute_result = run([str(executable)], 15)
        if execute_result.returncode != expected_exit:
            return Result(source.name, False, f"exit {execute_result.returncode}, expected {expected_exit}\nstderr:\n{execute_result.stderr}", time.perf_counter() - start)
        if execute_result.stdout != expected_stdout:
            return Result(source.name, False, f"stdout mismatch\nactual: {execute_result.stdout!r}\nexpected: {expected_stdout!r}", time.perf_counter() - start)
    return Result(source.name, True, duration=time.perf_counter() - start)


def check_only(compiler: Path, source: Path, dialect: str = "fsim") -> Result:
    start = time.perf_counter()
    result = run([str(compiler), f"-std={dialect}", "--check", str(source)], 30)
    if result.returncode != 0:
        return Result(source.name, False, result.stderr, time.perf_counter() - start)
    return Result(source.name, True, duration=time.perf_counter() - start)


def negative_test(compiler: Path, source: Path) -> Result:
    start = time.perf_counter()
    expectation = source.with_suffix(".expect").read_text(encoding="utf-8").strip()
    dialect = "simula67" if source.name.startswith("simula67_") else "fsim"
    result = run([str(compiler), f"-std={dialect}", "--check", str(source)], 30)
    if result.returncode == 0:
        return Result(source.name, False, "invalid source was accepted", time.perf_counter() - start)
    combined = result.stdout + result.stderr
    if expectation and expectation.lower() not in combined.lower():
        return Result(source.name, False, f"expected diagnostic fragment {expectation!r}\nactual:\n{combined}", time.perf_counter() - start)
    return Result(source.name, True, duration=time.perf_counter() - start)



def dialect_for(source: Path) -> str:
    sidecar = source.with_suffix(".dialect")
    if sidecar.exists():
        value = sidecar.read_text(encoding="utf-8").strip().lower()
        if value not in {"fsim", "simula67"}:
            raise ValueError(f"invalid dialect sidecar {sidecar}: {value!r}")
        return value
    return "simula67" if source.name.startswith("simula67_") else "fsim"

def collect(compiler: Path, suite: str) -> list[Result]:
    results: list[Result] = []
    if suite in {"all", "fast", "examples"}:
        for source in sorted((ROOT / "examples").glob("*.sim")):
            expected_file = source.with_suffix(".out")
            if expected_file.exists():
                expected = expected_file.read_text(encoding="utf-8")
                results.append(compile_and_run(compiler, source, expected))
            else:
                results.append(check_only(compiler, source, dialect_for(source)))
        if suite == "examples":
            return results
    if suite in {"all", "fast", "check"}:
        for source in sorted((ROOT / "tests" / "check").glob("*.sim")):
            results.append(check_only(compiler, source, dialect_for(source)))
        for source in sorted((ROOT / "stdlib").glob("*.sim")):
            results.append(check_only(compiler, source, "fsim"))
        if suite == "check":
            return results
    if suite in {"all", "fast"}:
        for source in sorted((ROOT / "tests" / "integration").glob("*.sim")):
            expected_file = source.with_suffix(".out")
            expected = expected_file.read_text(encoding="utf-8") if expected_file.exists() else ""
            results.append(compile_and_run(compiler, source, expected))
        for source in sorted((ROOT / "tests" / "negative").glob("*.sim")):
            results.append(negative_test(compiler, source))
    if suite in {"all", "generated"}:
        manifest = json.loads((ROOT / "tests" / "generated" / "manifest.json").read_text())
        cases = manifest["cases"]
        if suite == "all" and os.environ.get("FSIM_FULL_CONFORMANCE") != "1":
            cases = cases[:24]
        for case in cases:
            results.append(
                compile_and_run(
                    compiler,
                    ROOT / "tests" / "generated" / case["file"],
                    str(case["stdout"]),
                    int(case["exit"]),
                )
            )
    return results


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--compiler", type=Path, required=True)
    parser.add_argument("--suite", choices=["all", "fast", "generated", "examples", "check"], default="all")
    args = parser.parse_args()
    compiler = args.compiler.resolve()
    if not compiler.exists():
        print(f"error: compiler not found: {compiler}", file=sys.stderr)
        return 2
    results = collect(compiler, args.suite)
    failures = 0
    for result in results:
        status = "PASS" if result.passed else "FAIL"
        print(f"{status:4} {result.name:42} {result.duration:7.3f}s")
        if not result.passed:
            failures += 1
            print(result.detail.rstrip())
    total = sum(result.duration for result in results)
    print(f"\n{len(results) - failures}/{len(results)} passed in {total:.2f}s")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())

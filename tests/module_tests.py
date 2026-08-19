#!/usr/bin/env python3
"""Black-box tests for fsim module search, cycles, JSON diagnostics, and depfiles."""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=30,
        check=False,
        env={**os.environ, "LC_ALL": "C", "LANG": "C"},
    )


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.strip() + "\n", encoding="utf-8")


def fail(name: str, detail: str) -> int:
    print(f"FAIL {name}")
    print(detail.rstrip())
    return 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--compiler", type=Path, required=True)
    args = parser.parse_args()
    compiler = args.compiler.resolve()
    failures = 0
    with tempfile.TemporaryDirectory(prefix="fsim-modules-") as temporary:
        root = Path(temporary)
        library = root / "library"
        write(
            library / "helper.sim",
            """
            module Helper;
            integer function Twice(integer value);
            begin
                return value * 2
            end;
            """,
        )
        write(
            root / "named.sim",
            """
            program NamedImport;
            import Helper;
            begin
                integer value;
                value := Twice(21);
                exit(0)
            end;
            """,
        )
        depfile = root / "named.d"
        result = run([
            str(compiler), "-std=fsim", "--check", "--no-stdlib",
            "-I", str(library), "-MF", str(depfile), str(root / "named.sim"),
        ])
        if result.returncode != 0:
            failures += fail("named import", result.stderr)
        elif not depfile.exists():
            failures += fail("dependency file", "compiler did not create -MF output")
        else:
            dependency_text = depfile.read_text(encoding="utf-8")
            if "named.sim" not in dependency_text or "helper.sim" not in dependency_text:
                failures += fail("dependency file", dependency_text)
            else:
                print("PASS named import and dependency file")

        write(
            root / "quoted.sim",
            """
            program QuotedImport;
            import "library/helper.sim";
            begin
                exit(0)
            end;
            """,
        )
        result = run([str(compiler), "--check", "--no-stdlib", str(root / "quoted.sim")])
        if result.returncode != 0:
            failures += fail("quoted relative import", result.stderr)
        else:
            print("PASS quoted relative import")

        write(root / "cycle_a.sim", "module CycleA; import \"cycle_b.sim\";")
        write(root / "cycle_b.sim", "module CycleB; import \"cycle_a.sim\";")
        result = run([
            str(compiler), "--check", "--diagnostics=json", "--no-stdlib",
            str(root / "cycle_a.sim"),
        ])
        if result.returncode == 0:
            failures += fail("cycle diagnostic", "cyclic imports were accepted")
        else:
            try:
                payload = json.loads(result.stderr)
            except json.JSONDecodeError as error:
                failures += fail("JSON diagnostics", f"{error}\n{result.stderr}")
            else:
                codes = {item.get("code") for item in payload.get("diagnostics", [])}
                if "import-cycle" not in codes:
                    failures += fail("cycle diagnostic", result.stderr)
                else:
                    print("PASS cycle-specific JSON diagnostic")

        write(
            root / "missing.sim",
            """
            program MissingImport;
            import DefinitelyMissing;
            begin
                exit(0)
            end;
            """,
        )
        result = run([
            str(compiler), "--check", "--diagnostics=json", "--no-stdlib",
            str(root / "missing.sim"),
        ])
        if result.returncode == 0:
            failures += fail("missing import", "missing import was accepted")
        else:
            try:
                payload = json.loads(result.stderr)
                codes = {item.get("code") for item in payload.get("diagnostics", [])}
            except json.JSONDecodeError as error:
                failures += fail("missing import JSON", f"{error}\n{result.stderr}")
            else:
                if "import-not-found" not in codes:
                    failures += fail("missing import diagnostic", result.stderr)
                else:
                    print("PASS missing-import JSON diagnostic")

    if failures:
        print(f"{failures} module test(s) failed", file=sys.stderr)
        return 1
    print("all module-system tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

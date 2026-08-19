#!/usr/bin/env python3
"""Make sure bad source gets diagnostics instead of crashing the compiler."""
from __future__ import annotations

import argparse
import subprocess
import tempfile
from pathlib import Path

INVALID_CASES = {
    "missing-expression": "program Broken; begin integer x; x := ; end;\n",
    "broken-call": "program Broken; begin outint((1 + 2); end;\n",
    "bad-class": "program Broken; Class C begin integer x; begin end;\n",
    "bad-foreign": 'program Broken; foreign c from "libc.so.6" begin function puts(: c_int; end; begin end;\n',
    "malformed-late-program-header": "integer x; program TooLate begin x := 1 end;\n",
    "bad-conversion": "program Broken; begin integer x; x := real(1, 2); end;\n",
    "bad-index": "program Broken; begin array[1:3] integer a; a[1 := 2 end;\n",
    "bad-array-type": "program Broken; begin array[1:3] void nope; end;\n",
    "bad-array-bound": "program Broken; begin array[missing:3] integer nope; end;\n",
    "unterminated": "program Broken; begin if true then begin outtext(\"x\")\n",
}

VALID_CASES = {
    "declarations-before-program": "integer x; program AllowedLate; begin x := 1 end;\n",
    "underscore-and-constant-array-bound": (
        "program Modern; const integer max_items = 4; "
        "array[1:max_items] integer item_value; begin item_value[1] := 1 end;\n"
    ),
    "bang-comment-first-semicolon": (
        "program CommentRule; begin integer value; value := 0; "
        "! this comment ends here; value := 1; assert(value = 1) end;\n"
    ),
}

STRICT_INVALID_CASES = {
    "simula67-underscore": "program Strict; begin integer old_style_name; old_style_name := 1 end;\n",
}


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, timeout=20, check=False)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--compiler", type=Path, required=True)
    args = ap.parse_args()
    compiler = args.compiler.resolve()
    failures = 0
    with tempfile.TemporaryDirectory(prefix="fsim-front-") as tmp:
        tmpdir = Path(tmp)
        for name, text in INVALID_CASES.items():
            source = tmpdir / f"{name}.sim"
            source.write_text(text, encoding="utf-8")
            result = run([str(compiler), "-std=fsim", "--check", str(source)])
            combined = result.stdout + result.stderr
            if result.returncode == 0:
                print(f"FAIL {name}: invalid source was accepted")
                failures += 1
            elif result.returncode == 3 or "internal error" in combined.lower():
                print(f"FAIL {name}: compiler crashed\n{combined}")
                failures += 1
            else:
                print(f"PASS {name}")
        for name, text in STRICT_INVALID_CASES.items():
            source = tmpdir / f"strict-{name}.sim"
            source.write_text(text, encoding="utf-8")
            result = run([str(compiler), "-std=simula67", "--check", str(source)])
            combined = result.stdout + result.stderr
            if result.returncode == 0:
                print(f"FAIL {name}: strict source extension was accepted")
                failures += 1
            elif result.returncode == 3 or "internal error" in combined.lower():
                print(f"FAIL {name}: compiler crashed\n{combined}")
                failures += 1
            elif "underscore identifiers" not in combined.lower():
                print(f"FAIL {name}: expected underscore dialect diagnostic\n{combined}")
                failures += 1
            else:
                print(f"PASS {name}")

        for name, text in VALID_CASES.items():
            source = tmpdir / f"valid-{name}.sim"
            source.write_text(text, encoding="utf-8")
            result = run([str(compiler), "-std=fsim", "--check", str(source)])
            combined = result.stdout + result.stderr
            if result.returncode != 0:
                print(f"FAIL {name}: valid source was rejected\n{combined}")
                failures += 1
            else:
                print(f"PASS {name}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())

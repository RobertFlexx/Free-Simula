#!/usr/bin/env python3
"""Native task/channel smoke stress for release candidates."""
from __future__ import annotations

import argparse
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

SOURCE = r'''Task Class Worker;
begin
    Public:
    integer input_value;
    integer function Run;
    begin
        yield;
        return input_value * 3 + 1
    end
end;

program ConcurrencyStress;
begin
    Ref(Worker) worker;
    future(integer) work;
    channel(integer) mailbox;
    integer iteration;
    integer result;
    for iteration := 0 step 1 until 255 do
    begin
        worker :- new Worker();
        worker.input_value := iteration;
        work :- spawn worker.Run();
        result := await work;
        assert(result = iteration * 3 + 1);
        send(mailbox, result);
        assert(receive(mailbox) = result)
    end;
    outtext("concurrency stress passed");
    outimage;
    exit(0)
end;
'''


def run(command: list[str], timeout: int) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        timeout=timeout,
        env={**os.environ, "LC_ALL": "C", "LANG": "C"},
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--compiler", type=Path, required=True)
    args = parser.parse_args()
    compiler = args.compiler.resolve()
    with tempfile.TemporaryDirectory(prefix="fsim-concurrency-stress-") as temporary:
        root = Path(temporary)
        source = root / "stress.sim"
        executable = root / "stress"
        source.write_text(SOURCE, encoding="utf-8")
        compiled = run([
            str(compiler), "-std=fsim", "-O2", str(source),
            "-o", str(executable),
        ], 90)
        if compiled.returncode != 0:
            print(compiled.stdout, end="")
            print(compiled.stderr, end="")
            return 1
        executed = run([str(executable)], 60)
        if executed.returncode != 0 or executed.stdout != "concurrency stress passed\n":
            print(executed.stdout, end="")
            print(executed.stderr, end="")
            print(f"unexpected exit status {executed.returncode}")
            return 1
    print("native task/channel stress passed: 256 spawn/await/channel cycles")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

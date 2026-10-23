#!/usr/bin/env python3
"""Exercise desktop editor reload with an existing native object and saved state."""

import argparse
import json
import shutil
import subprocess
import time
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--editor", type=Path, required=True)
parser.add_argument("--cycles", type=int, default=6)
args = parser.parse_args()
if args.cycles < 2:
    parser.error("Use at least two reloads")
root = Path(__file__).resolve().parent
project = root / "project"
live = project / "bin/x86_64/libaurora_reload.so"
command = project / ".aurora-reload-command.json"
result = project / ".aurora-reload-result.json"
log = root / "desktop-reload.log"


def replace_library(revision):
    source = root / f"bin/x86_64/revision{revision}/libaurora_reload.so"
    live.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, live.with_suffix(".so.next"))
    live.with_suffix(".so.next").replace(live)


def send(data):
    temporary = command.with_suffix(".json.tmp")
    temporary.write_text(json.dumps(data))
    temporary.replace(command)


def wait_result(sequence, process):
    deadline = time.monotonic() + 40
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise RuntimeError(f"Editor exited ({process.returncode}); see {log}")
        if result.exists():
            data = json.loads(result.read_text())
            if data.get("ready") is False:
                raise RuntimeError(str(data))
            if data.get("sequence") == sequence:
                return data
        time.sleep(0.1)
    raise TimeoutError(f"No editor result for sequence {sequence}; see {log}")


command.unlink(missing_ok=True)
result.unlink(missing_ok=True)
replace_library(1)
evidence = []
with log.open("w") as output:
    process = subprocess.Popen(
        [str(args.editor.resolve()), "--headless", "--editor", "--path", str(project)],
        stdout=output,
        stderr=subprocess.STDOUT,
    )
    try:
        initial = wait_result(0, process)
        assert initial["revision"] == 1 and initial["state"] == 73, initial
        evidence.append(initial)
        for sequence in range(1, args.cycles + 1):
            revision = 2 if sequence % 2 else 1
            replace_library(revision)
            send({"sequence": sequence})
            data = wait_result(sequence, process)
            assert data["reload_status"] == 0 and data["revision"] == revision, data
            assert data["same_instance"] and data["state"] == 73, data
            maps = Path(f"/proc/{process.pid}/maps").read_text()
            loaded = [line for line in maps.splitlines() if "libaurora_reload.so" in line]
            assert loaded and not any("(deleted)" in line for line in loaded), loaded
            evidence.append(data)
        send({"sequence": args.cycles + 1, "quit": True})
        assert process.wait(timeout=20) == 0
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
        command.unlink(missing_ok=True)
(root / "desktop-reload-results.json").write_text(json.dumps(evidence, indent=2) + "\n")
print(f"PASS: {args.cycles} native reloads, current code, same ObjectID/state, no old deleted DSO mappings")

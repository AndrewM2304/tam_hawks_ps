#!/usr/bin/env python3
"""Bounded, local source-launch regression in a disposable, initially cold copy.

No downloads, exports, rendering, player-profile writes outside the copy, or
changes to the source checkout. Run only after game/test/launcher edits stop.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import time


ROOT = Path(__file__).resolve().parents[1]
ERRORS = re.compile(r"SCRIPT ERROR:|Parse Error:|ERROR:|FAIL:|TIMEOUT")
RESULT = re.compile(r"^PLAYABILITY RESULT: ([1-9][0-9]*) passed, 0 failed$", re.MULTILINE)
NORMAL_BRANCH = "PASS: playability boot: unmodified Main enters its actual paused title branch"
REFUSAL = "Game assets could not be prepared; the game was not started."
TIMEOUTS = {"cold": 180, "normal-branch": 240, "warm": 120, "invalid-source": 120}


def utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def inputs(root: Path) -> dict:
    paths = [root / "project.godot", root / "tools/run.sh"]
    for name in ("game", "tests"):
        directory = root / name
        if not directory.is_dir() or directory.is_symlink():
            raise RuntimeError(f"Missing or symlinked input directory: {directory}")
        for path in directory.rglob("*"):
            if path.is_symlink():
                raise RuntimeError(f"Input symlinks are not copied: {path}")
            if path.is_file():
                if any(part in (".godot", ".local", "__pycache__") for part in path.relative_to(directory).parts):
                    raise RuntimeError(f"Unexpected generated cache inside source inputs: {path}")
                paths.append(path)
    result = {}
    for path in sorted(paths):
        if path.is_symlink() or not path.is_file():
            raise RuntimeError(f"Missing or symlinked source input: {path}")
        result[path.relative_to(root).as_posix()] = {
            "sha256": sha(path), "bytes": path.stat().st_size,
            "mode": oct(path.stat().st_mode & 0o777),
        }
    return result


def fingerprint(manifest: dict) -> str:
    return hashlib.sha256(json.dumps(manifest, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def stop_group(process: subprocess.Popen) -> None:
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    try:
        process.wait(timeout=3)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait(timeout=3)


def phase(name: str, copy: Path, output: Path, arguments: list[str], receipt: dict) -> None:
    command = [str(copy / "tools/run.sh"), "--headless", "--audio-driver", "Dummy", *arguments]
    limit = TIMEOUTS[name]
    log = output / f"{name}.log"
    import_source = copy / ".local/source-import.log"
    if import_source.exists():
        import_source.unlink()  # Require this invocation to create its own import receipt.
    entry = {"name": name, "command": command, "timeout_seconds": limit, "started_utc": utc()}
    receipt["phases"].append(entry)
    print(f"SOURCE LAUNCH: {name} (limit {limit}s)", flush=True)
    start = time.monotonic()
    with log.open("wb") as stream:
        process = subprocess.Popen(command, cwd=copy, stdout=stream, stderr=subprocess.STDOUT,
                                   start_new_session=True)
        try:
            entry["exit_code"] = process.wait(timeout=limit)
        except subprocess.TimeoutExpired:
            entry["timed_out"] = True
            stop_group(process)
            entry["exit_code"] = process.returncode
        except BaseException:
            stop_group(process)
            raise
    entry.update(completed_utc=utc(), wall_seconds=round(time.monotonic() - start, 6),
                 log=log.name, log_sha256=sha(log))
    text = log.read_text(errors="replace")
    entry["error_lines"] = [line for line in text.splitlines() if ERRORS.search(line)]
    if not import_source.is_file():
        raise RuntimeError(f"{name}: launcher did not create source-import.log")
    import_log = output / f"{name}-source-import.log"
    shutil.copy2(import_source, import_log)
    imported = import_log.read_text(errors="replace")
    entry.update(import_log=import_log.name, import_sha256=sha(import_log),
                 import_error_lines=[line for line in imported.splitlines() if ERRORS.search(line)])
    if entry.get("timed_out"):
        raise RuntimeError(f"{name}: bounded subprocess timed out")
    if name == "invalid-source":
        entry["launcher_refused"] = REFUSAL in text
        entry["parse_error_detected"] = "Parse Error:" in imported or "SCRIPT ERROR:" in imported
        if entry["exit_code"] == 0 or not entry["launcher_refused"] or not entry["parse_error_detected"]:
            raise RuntimeError("Deliberate copied parse failure did not make the launcher refuse play")
    else:
        if entry["exit_code"] != 0 or entry["error_lines"] or entry["import_error_lines"]:
            raise RuntimeError(f"{name}: nonzero exit or engine/script/resource/test error")
        if "Godot Engine v4.6.3." not in text or "Godot Engine v4.6.3." not in imported:
            raise RuntimeError(f"{name}: missing pinned-engine startup/import output")
        if name == "normal-branch":
            matches = RESULT.findall(text)
            entry["normal_title_branch_count"] = text.splitlines().count(NORMAL_BRANCH)
            entry["passed"] = int(matches[0]) if len(matches) == 1 else 0
            entry["failed"] = 0 if len(matches) == 1 else None
            if entry["normal_title_branch_count"] < 1 or entry["passed"] <= 0:
                raise RuntimeError("Normal scene did not prove its actual title branch and passing checks")
    entry["accepted"] = True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="New/empty directory beneath this checkout's ignored .local/")
    args = parser.parse_args()
    default = ROOT / ".local" / ("source-launch-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ"))
    output = (args.output if args.output else default).resolve()
    ignored = ROOT / ".local"
    if ignored.is_symlink() or not output.is_relative_to(ignored.resolve()) or output == ignored.resolve():
        parser.error("Output must be a dedicated directory beneath the checkout's real .local/")
    if output.exists() and (not output.is_dir() or any(output.iterdir())):
        parser.error("Output already exists and is not empty; previous evidence is never overwritten")
    output.mkdir(parents=True, exist_ok=True)
    copy = output / "project"
    receipt = {"schema": 1, "started_utc": utc(), "source_root": str(ROOT), "output": str(output),
               "helper_sha256": sha(Path(__file__)), "phases": [], "passed": False,
               "limits": ["Linux source-launch diagnostic; no Mac executable was launched.",
                          "Headless Dummy audio; no rendered-frame, listening or performance acceptance.",
                          "The normal-scene test uses synthetic mapped inputs at fixed 60 Hz.",
                          "Wall-clock timeouts bound work; durations are not frame-rate measurements."]}
    original_main = None
    try:
        before = inputs(ROOT)
        receipt.update(source_inputs=before, input_count=len(before), source_fingerprint=fingerprint(before))
        for relative in before:
            destination = copy / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, destination)
        if inputs(copy) != before or inputs(ROOT) != before:
            raise RuntimeError("Source changed during copying or the copy differs from source")
        if not (copy / "tests/playability_boot.tscn").is_file():
            raise RuntimeError("Normal-scene playability harness is missing")
        receipt["initial_cache_absent"] = not (copy / ".godot").exists()
        if not receipt["initial_cache_absent"]:
            raise RuntimeError("Cold source copy unexpectedly contains .godot")
        phase("cold", copy, output, ["--quit-after", "5"], receipt)
        receipt["cold_import_created_cache"] = (copy / ".godot").is_dir()
        if not receipt["cold_import_created_cache"]:
            raise RuntimeError("Cold launcher did not produce its import cache")
        phase("normal-branch", copy, output,
              ["--fixed-fps", "60", "res://tests/playability_boot.tscn"], receipt)
        phase("warm", copy, output, ["--quit-after", "5"], receipt)
        target = copy / "game/main.gd"
        original_main = target.read_bytes()
        target.write_bytes(original_main + b"\nfunc deliberate_source_launch_parse_failure( -> void:\n")
        receipt["injected_copy_only"] = "game/main.gd: deliberately incomplete function declaration"
        phase("invalid-source", copy, output, ["--quit-after", "5"], receipt)
        receipt["passed"] = True
    except (OSError, RuntimeError, ValueError, KeyboardInterrupt) as error:
        receipt["error"] = f"{type(error).__name__}: {error}"
        print("SOURCE LAUNCH FAIL: " + receipt["error"], file=sys.stderr, flush=True)
    finally:
        if original_main is not None:
            (copy / "game/main.gd").write_bytes(original_main)
            receipt["copied_main_restored"] = True
        if "source_inputs" in receipt:
            try:
                after = inputs(ROOT)
                receipt["source_stable"] = after == receipt["source_inputs"]
                receipt["changed_inputs"] = sorted(k for k in set(after) | set(receipt["source_inputs"])
                                                   if after.get(k) != receipt["source_inputs"].get(k))
                receipt["source_fingerprint_after"] = fingerprint(after)
                receipt["copied_source_unchanged"] = inputs(copy) == receipt["source_inputs"]
                if not receipt["source_stable"] or not receipt["copied_source_unchanged"]:
                    receipt["passed"] = False
                    receipt["error"] = "Source or copied inputs changed during the launch checks"
            except (OSError, RuntimeError) as error:
                receipt.update(passed=False, error=f"Final source guard: {error}")
        receipt["completed_utc"] = utc()
        (output / "SOURCE-LAUNCH.json").write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n")
    print(f"SOURCE LAUNCH {'PASS' if receipt['passed'] else 'FAIL'}: {output / 'SOURCE-LAUNCH.json'}", flush=True)
    return 0 if receipt["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

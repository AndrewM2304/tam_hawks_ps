#!/usr/bin/env bash
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
mkdir -p .local
# Godot editor import can log parse errors without returning a failure code.
./tools/run.sh --headless --editor --import 2>&1 | tee .local/import.log
if grep -Eq 'SCRIPT ERROR:|Parse Error:|ERROR:' .local/import.log; then
  echo 'Import failed; inspect .local/import.log.' >&2
  exit 1
fi
# The input drivers observe physics_frame then process_frame. Run one 60 Hz
# logical frame per observation, so real-time catch-up under CPU load cannot
# skip a scheduled press/release. This is simulation verification, not a timing
# or target-hardware benchmark; production frame/physics settings are untouched.
./tools/run.sh --headless --fixed-fps 60 --script tests/run_tests.gd 2>&1 | tee .local/tests.log
if grep -Eq 'SCRIPT ERROR:|ERROR:|FAIL:' .local/tests.log; then
  echo 'Checks failed; inspect .local/tests.log.' >&2
  exit 1
fi
grep -Eq 'RESULT: [1-9][0-9]* passed, 0 failed' .local/tests.log
# Exercise the actual short script option too. This fixture checks Main before
# it enters the tree, so an isolation regression is detected before profile or
# personal Music access. Backend behavior remains in the main suite above.
./tools/run.sh --headless --fixed-fps 60 -s tests/support/music_launch_guard.gd -- --guard-only 2>&1 | tee .local/script-launch.log
if grep -Eq 'SCRIPT ERROR:|Parse Error:|ERROR:|FAIL:' .local/script-launch.log; then
  echo 'Script-launch isolation failed; inspect .local/script-launch.log.' >&2
  exit 1
fi
grep -Eq 'SCRIPT LAUNCH: [1-9][0-9]* passed, 0 failed' .local/script-launch.log

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
./tools/run.sh --headless --script tests/run_tests.gd 2>&1 | tee .local/tests.log
if grep -Eq 'SCRIPT ERROR:|ERROR:|FAIL:' .local/tests.log; then
  echo 'Checks failed; inspect .local/tests.log.' >&2
  exit 1
fi
grep -Eq 'RESULT: [1-9][0-9]* passed, 0 failed' .local/tests.log

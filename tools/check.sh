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
# Independent exact-integer enclosure authority for actual native shoe buffers.
python3 tools/testing/verify_shoe_support_certificate.py .local/shoe-support-certificate.json --output .local/shoe-support-exact.json
# Exercise the actual short script option too. This fixture checks Main before
# it enters the tree, so an isolation regression is detected before profile or
# personal Music access. Backend behavior remains in the main suite above.
./tools/run.sh --headless --fixed-fps 60 -s tests/support/music_launch_guard.gd -- --guard-only 2>&1 | tee .local/script-launch.log
if grep -Eq 'SCRIPT ERROR:|Parse Error:|ERROR:|FAIL:' .local/script-launch.log; then
  echo 'Script-launch isolation failed; inspect .local/script-launch.log.' >&2
  exit 1
fi
grep -Eq 'SCRIPT LAUNCH: [1-9][0-9]* passed, 0 failed' .local/script-launch.log
# The persistence fault fixtures deliberately poison default user:// paths.
# Always use their separate-app launcher, including on macOS where XDG does
# not isolate Godot's user data. Never run this script in the game namespace.
python3 tools/testing/check_level_book.py 2>&1 | tee .local/level-book.log
for TASK_FIXTURE in neighbourhood_integration_smoke neighbourhood_level_input_probe; do
  ./tools/run.sh --headless --fixed-fps 60 --script "tests/$TASK_FIXTURE.gd" 2>&1 | tee ".local/$TASK_FIXTURE.log"
  if grep -Eq 'SCRIPT ERROR:|Parse Error:|ERROR:|FAIL:' ".local/$TASK_FIXTURE.log"; then
    echo "Selected-world checks failed; inspect .local/$TASK_FIXTURE.log." >&2
    exit 1
  fi
done
grep -Eq 'NEIGHBOURHOOD RESULT: [1-9][0-9]* passed, 0 failed' .local/neighbourhood_integration_smoke.log
grep -Eq 'LEVEL INPUT RESULT: [1-9][0-9]* passed, 0 failed' .local/neighbourhood_level_input_probe.log

#!/usr/bin/env bash
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
TASK_CELL="${1:-64}"
[[ "$TASK_CELL" == 32 || "$TASK_CELL" == 48 || "$TASK_CELL" == 64 ]] || { echo 'Usage: tools/static_batches_probe.sh [32|48|64]' >&2; exit 2; }
mkdir -p .local
TASK_OUTPUT="$(mktemp -d "$TASK_ROOT/.local/static-batches-${TASK_CELL}-XXXXXX")"
TASK_DISPLAY_PID=""
cleanup() {
  if [[ -n "$TASK_DISPLAY_PID" ]]; then
    kill "$TASK_DISPLAY_PID" 2>/dev/null || true
    wait "$TASK_DISPLAY_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT
if [[ "$(uname -s)" == Linux && -z "${DISPLAY:-}" ]]; then
  /usr/lib/xorg/Xorg -displayfd 3 -config "$TASK_ROOT/tools/xorg-dummy.conf" -logfile "$TASK_OUTPUT/xorg.log" -noreset -nolisten tcp 3>"$TASK_OUTPUT/display" >"$TASK_OUTPUT/xorg-console.log" 2>&1 &
  TASK_DISPLAY_PID=$!
  for attempt in {1..50}; do
    [[ -s "$TASK_OUTPUT/display" ]] && break
    kill -0 "$TASK_DISPLAY_PID" 2>/dev/null || { cat "$TASK_OUTPUT/xorg-console.log" >&2; exit 1; }
    sleep .1
  done
  [[ -s "$TASK_OUTPUT/display" ]] || exit 1
  export DISPLAY=":$(cat "$TASK_OUTPUT/display")"
  export LIBGL_ALWAYS_SOFTWARE=1
fi
python3 tools/static_batches_probe.py "$TASK_OUTPUT" "$TASK_CELL"

#!/usr/bin/env bash
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
mkdir -p .local
TASK_DISPLAY_PID=""
cleanup() {
  if [[ -n "$TASK_DISPLAY_PID" ]]; then
    kill "$TASK_DISPLAY_PID" 2>/dev/null || true
    wait "$TASK_DISPLAY_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT
if [[ "$(uname -s)" == Linux && -z "${DISPLAY:-}" ]]; then
  if [[ ! -x /usr/lib/xorg/Xorg ]]; then
    echo 'A graphical display or installed Xorg with the dummy driver is required.' >&2
    exit 1
  fi
  : > .local/capture-display
  /usr/lib/xorg/Xorg -displayfd 3 -config "$TASK_ROOT/tools/xorg-dummy.conf" \
    -logfile "$TASK_ROOT/.local/xorg-capture.log" -noreset -nolisten tcp \
    3>.local/capture-display >.local/xorg-capture-console.log 2>&1 &
  TASK_DISPLAY_PID=$!
  for attempt in {1..50}; do
    [[ -s .local/capture-display ]] && break
    if ! kill -0 "$TASK_DISPLAY_PID" 2>/dev/null; then
      cat .local/xorg-capture-console.log >&2
      exit 1
    fi
    sleep 0.1
  done
  [[ -s .local/capture-display ]] || { echo 'Display startup timed out.' >&2; exit 1; }
  export DISPLAY=":$(cat .local/capture-display)"
  export LIBGL_ALWAYS_SOFTWARE=1
fi
./tools/run.sh --audio-driver Dummy --script tools/capture.gd

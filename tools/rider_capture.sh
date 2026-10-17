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
  : > .local/rider_capture-display
  /usr/lib/xorg/Xorg -displayfd 3 -config "$TASK_ROOT/tools/xorg-dummy.conf" \
    -logfile "$TASK_ROOT/.local/xorg-rider_capture.log" -noreset -nolisten tcp \
    3>.local/rider_capture-display >.local/xorg-rider_capture-console.log 2>&1 &
  TASK_DISPLAY_PID=$!
  for attempt in {1..50}; do
    [[ -s .local/rider_capture-display ]] && break
    if ! kill -0 "$TASK_DISPLAY_PID" 2>/dev/null; then
      cat .local/xorg-rider_capture-console.log >&2
      exit 1
    fi
    sleep 0.1
  done
  [[ -s .local/rider_capture-display ]] || { echo 'Display startup timed out.' >&2; exit 1; }
  export DISPLAY=":$(cat .local/rider_capture-display)"
  export LIBGL_ALWAYS_SOFTWARE=1
fi
if command -v timeout >/dev/null 2>&1; then
  timeout 600s ./tools/run.sh --audio-driver Dummy --disable-render-loop --fixed-fps 60 --script tools/rider_capture.gd
else
  ./tools/run.sh --audio-driver Dummy --disable-render-loop --fixed-fps 60 --script tools/rider_capture.gd
fi

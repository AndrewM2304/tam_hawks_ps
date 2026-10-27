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
  : > .local/recorder-display-display
  /usr/lib/xorg/Xorg -displayfd 3 -config "$TASK_ROOT/tools/xorg-dummy.conf" \
    -logfile "$TASK_ROOT/.local/xorg-recorder-display.log" -noreset -nolisten tcp \
    3>.local/recorder-display-display >.local/xorg-recorder-display-console.log 2>&1 &
  TASK_DISPLAY_PID=$!
  for attempt in {1..50}; do
    [[ -s .local/recorder-display-display ]] && break
    if ! kill -0 "$TASK_DISPLAY_PID" 2>/dev/null; then
      cat .local/xorg-recorder-display-console.log
      exit 1
    fi
    sleep .1
  done
  [[ -s .local/recorder-display-display ]] || { echo 'No native display'; exit 1; }
  export DISPLAY=":$(cat .local/recorder-display-display)"
  export LIBGL_ALWAYS_SOFTWARE=1
fi
timeout 100s ./tools/run.sh --rendering-method gl_compatibility --windowed \
  --resolution 1440x900 --audio-driver Dummy --fixed-fps 60 \
  --script .local/recorder_display_witness.gd -- "$@"

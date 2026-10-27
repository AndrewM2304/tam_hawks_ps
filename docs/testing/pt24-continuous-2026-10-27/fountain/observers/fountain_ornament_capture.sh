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
 : > .local/fountain-ornament-display
 /usr/lib/xorg/Xorg -displayfd 3 -config "$TASK_ROOT/tools/xorg-dummy.conf" -logfile "$TASK_ROOT/.local/xorg-fountain-ornament.log" -noreset -nolisten tcp 3>.local/fountain-ornament-display >.local/xorg-fountain-ornament-console.log 2>&1 &
 TASK_DISPLAY_PID=$!
 for attempt in {1..50}; do
  [[ -s .local/fountain-ornament-display ]] && break
  if ! kill -0 "$TASK_DISPLAY_PID" 2>/dev/null; then cat .local/xorg-fountain-ornament-console.log;exit 1;fi
  sleep .1
 done
 [[ -s .local/fountain-ornament-display ]] || { echo 'No native display';exit 1; }
 export DISPLAY=":$(cat .local/fountain-ornament-display)"
 export LIBGL_ALWAYS_SOFTWARE=1
fi
for phase in original-a profile original-b; do
 echo "ORNAMENT_PHASE $phase"
 timeout 120s ./tools/run.sh --rendering-method gl_compatibility --windowed --resolution 960x640 --audio-driver Dummy --fixed-fps 60 --script .local/fountain_ornament_capture.gd -- "--phase=$phase"
done

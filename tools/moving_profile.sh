#!/usr/bin/env bash
# Bounded normal-render moving diagnostics. Installed local tools only.
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
TASK_DURATION=60
TASK_WIDTH=1920
TASK_HEIGHT=1080
TASK_QUICK=false
TASK_DURATION_SET=false
TASK_RESOLUTION_SET=false
TASK_PRIVATE_DISPLAY=false
TASK_QUALITY=balanced
usage() { echo 'Usage: tools/moving_profile.sh [--quick] [--duration 15..600] [--resolution WIDTHxHEIGHT] [--private-display] [--quality performance|balanced|high]'; }
while (($#)); do
  case "$1" in
    --quick) TASK_QUICK=true ;;
    --duration) shift; TASK_DURATION="${1:?Supply whole seconds}"; TASK_DURATION_SET=true ;;
    --resolution)
      shift
      [[ "${1:?Supply WIDTHxHEIGHT}" =~ ^([0-9]+)x([0-9]+)$ ]] || { usage >&2; exit 2; }
      TASK_WIDTH="${BASH_REMATCH[1]}"; TASK_HEIGHT="${BASH_REMATCH[2]}"; TASK_RESOLUTION_SET=true ;;
    --private-display) TASK_PRIVATE_DISPLAY=true ;;
    --quality) shift; TASK_QUALITY="${1:?Supply performance, balanced or high}" ;;
    --help|-h) usage; exit 0 ;;
    --headless) echo 'Headless cannot provide rendered moving evidence.' >&2; exit 2 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done
case "$TASK_QUALITY" in performance|balanced|high) ;; *) echo 'Unknown graphics quality.' >&2; exit 2 ;; esac
if "$TASK_QUICK"; then
  "$TASK_DURATION_SET" || TASK_DURATION=24
  if ! "$TASK_RESOLUTION_SET"; then TASK_WIDTH=960; TASK_HEIGHT=540; fi
fi
[[ "$TASK_DURATION" =~ ^[0-9]{1,3}$ && "$TASK_WIDTH" =~ ^[0-9]{1,4}$ && "$TASK_HEIGHT" =~ ^[0-9]{1,4}$ ]] || { usage >&2; exit 2; }
TASK_DURATION=$((10#$TASK_DURATION)); TASK_WIDTH=$((10#$TASK_WIDTH)); TASK_HEIGHT=$((10#$TASK_HEIGHT))
((TASK_DURATION >= 15 && TASK_DURATION <= 600 && TASK_WIDTH >= 320 && TASK_WIDTH <= 3840 && TASK_HEIGHT >= 200 && TASK_HEIGHT <= 2160)) || { usage >&2; exit 2; }
if "$TASK_PRIVATE_DISPLAY" && [[ "$(uname -s)" != Linux ]]; then echo '--private-display requires Linux Xorg; use the native Mac desktop.' >&2; exit 2; fi
TASK_VERSION="$(./tools/run.sh --version)"
case "$TASK_VERSION" in 4.6.3.*) ;; *) echo "Expected free Godot 4.6.3, found $TASK_VERSION" >&2; exit 1 ;; esac
mkdir -p .local
TASK_OUTPUT="$(mktemp -d "$TASK_ROOT/.local/moving-profile-$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")"
TASK_DISPLAY_PID=""
TASK_PROFILE_PID=""
cleanup() {
  if [[ -n "$TASK_PROFILE_PID" ]]; then kill -TERM "$TASK_PROFILE_PID" 2>/dev/null || true; wait "$TASK_PROFILE_PID" 2>/dev/null || true; fi
  if [[ -n "$TASK_DISPLAY_PID" ]]; then
    kill -TERM "$TASK_DISPLAY_PID" 2>/dev/null || true
    for attempt in {1..20}; do kill -0 "$TASK_DISPLAY_PID" 2>/dev/null || break; sleep 0.1; done
    kill -KILL "$TASK_DISPLAY_PID" 2>/dev/null || true
    wait "$TASK_DISPLAY_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
python3 - "$TASK_ROOT" "$TASK_OUTPUT/import.log" <<'PY'
import os, pathlib, signal, subprocess, sys
root, logfile = map(pathlib.Path, sys.argv[1:])
with logfile.open('w') as log:
    child = subprocess.Popen([str(root/'tools/run.sh'), '--headless', '--editor', '--import'], cwd=root, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    def stop(*_):
        if child.poll() is None:
            os.killpg(child.pid, signal.SIGTERM)
            try: child.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(child.pid, signal.SIGKILL)
                child.wait(timeout=5)
        raise SystemExit('Bounded import stopped; moving sampling did not start.')
    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)
    try: code = child.wait(timeout=180)
    except subprocess.TimeoutExpired: stop()
if code: raise SystemExit(code)
PY
if grep -Eq 'SCRIPT ERROR:|Parse Error:|ERROR:' "$TASK_OUTPUT/import.log"; then cat "$TASK_OUTPUT/import.log" >&2; exit 1; fi
if [[ "$(uname -s)" == Linux && ( -z "${DISPLAY:-}" || "$TASK_PRIVATE_DISPLAY" == true ) ]]; then
  [[ -x /usr/lib/xorg/Xorg ]] || { echo 'An installed Xorg dummy driver or graphical display is required.' >&2; exit 1; }
  /usr/lib/xorg/Xorg -displayfd 3 -config "$TASK_ROOT/tools/xorg-dummy.conf" -logfile "$TASK_OUTPUT/xorg.log" -noreset -nolisten tcp \
    3>"$TASK_OUTPUT/display" >"$TASK_OUTPUT/xorg-console.log" 2>&1 &
  TASK_DISPLAY_PID=$!
  for attempt in {1..50}; do
    [[ -s "$TASK_OUTPUT/display" ]] && break
    if ! kill -0 "$TASK_DISPLAY_PID" 2>/dev/null; then cat "$TASK_OUTPUT/xorg-console.log" >&2; exit 1; fi
    sleep 0.1
  done
  [[ -s "$TASK_OUTPUT/display" ]] || { echo 'Private display startup timed out.' >&2; exit 1; }
  export DISPLAY=":$(cat "$TASK_OUTPUT/display")"
  export LIBGL_ALWAYS_SOFTWARE=1
fi
TASK_MODE=normal
"$TASK_QUICK" && TASK_MODE=quick
python3 tools/moving_profile.py "$TASK_DURATION" "$TASK_OUTPUT" "$TASK_WIDTH" "$TASK_HEIGHT" "$TASK_MODE" "$TASK_QUALITY" &
TASK_PROFILE_PID=$!
wait "$TASK_PROFILE_PID"
TASK_PROFILE_PID=""

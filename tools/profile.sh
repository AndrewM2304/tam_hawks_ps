#!/usr/bin/env bash
# Bounded local rendered profiling. No installs, hosting, profile saves or background service.
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
TASK_DURATION=36
TASK_WIDTH=1920
TASK_HEIGHT=1080
TASK_PRIVATE_DISPLAY=false
usage() {
  echo 'Usage: tools/profile.sh [--duration 12..600] [--resolution WIDTHxHEIGHT] [--private-display]'
}
while (($#)); do
  case "$1" in
    --duration) shift; TASK_DURATION="${1:?Supply duration in whole seconds}" ;;
    --resolution)
      shift
      TASK_RESOLUTION="${1:?Supply WIDTHxHEIGHT}"
      [[ "$TASK_RESOLUTION" =~ ^([0-9]+)x([0-9]+)$ ]] || { usage >&2; exit 2; }
      TASK_WIDTH="${BASH_REMATCH[1]}"; TASK_HEIGHT="${BASH_REMATCH[2]}"
      ;;
    --private-display) TASK_PRIVATE_DISPLAY=true ;;
    --help|-h) usage; exit 0 ;;
    --headless) echo 'Headless runs cannot supply rendered GPU evidence.' >&2; exit 2 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done
[[ "$TASK_DURATION" =~ ^[0-9]{1,3}$ && "$TASK_WIDTH" =~ ^[0-9]{1,4}$ && "$TASK_HEIGHT" =~ ^[0-9]{1,4}$ ]] || { usage >&2; exit 2; }
TASK_DURATION=$((10#$TASK_DURATION))
TASK_WIDTH=$((10#$TASK_WIDTH))
TASK_HEIGHT=$((10#$TASK_HEIGHT))
((TASK_DURATION >= 12 && TASK_DURATION <= 600)) || { usage >&2; exit 2; }
((TASK_WIDTH >= 320 && TASK_WIDTH <= 3840 && TASK_HEIGHT >= 200 && TASK_HEIGHT <= 2160)) || { usage >&2; exit 2; }
TASK_VERSION="$(./tools/run.sh --version)"
case "$TASK_VERSION" in 4.6.3.*) ;; *) echo "Expected Godot 4.6.3, found $TASK_VERSION" >&2; exit 1 ;; esac
mkdir -p .local
TASK_OUTPUT="$(mktemp -d "$TASK_ROOT/.local/profile-$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")"
TASK_DISPLAY_PID=""
TASK_PROFILE_PID=""
cleanup() {
  if [[ -n "$TASK_PROFILE_PID" ]]; then
    kill -TERM "$TASK_PROFILE_PID" 2>/dev/null || true
    wait "$TASK_PROFILE_PID" 2>/dev/null || true
  fi
  if [[ -n "$TASK_DISPLAY_PID" ]]; then
    kill -TERM "$TASK_DISPLAY_PID" 2>/dev/null || true
    for attempt in {1..20}; do
      kill -0 "$TASK_DISPLAY_PID" 2>/dev/null || break
      sleep 0.1
    done
    kill -KILL "$TASK_DISPLAY_PID" 2>/dev/null || true
    wait "$TASK_DISPLAY_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
if [[ "$(uname -s)" == Linux && ( -z "${DISPLAY:-}" || "$TASK_PRIVATE_DISPLAY" == true ) ]]; then
  [[ -x /usr/lib/xorg/Xorg ]] || { echo 'An existing display or installed Xorg dummy driver is required.' >&2; exit 1; }
  cat > "$TASK_OUTPUT/xorg.conf" <<'CONFIG'
Section "ServerFlags"
 Option "AutoAddDevices" "false"
 Option "AutoEnableDevices" "false"
 Option "DontVTSwitch" "true"
 Option "PciForceNone" "true"
EndSection
Section "Device"
 Identifier "ProfileDummy"
 Driver "dummy"
 VideoRam 256000
EndSection
Section "Monitor"
 Identifier "ProfileMonitor"
 HorizSync 5.0-1000.0
 VertRefresh 5.0-200.0
 Modeline "3840x2160" 594.00 3840 4016 4104 4400 2160 2168 2178 2250 +hsync +vsync
EndSection
Section "Screen"
 Identifier "ProfileScreen"
 Device "ProfileDummy"
 Monitor "ProfileMonitor"
 DefaultDepth 24
 SubSection "Display"
  Depth 24
  Modes "3840x2160"
  Virtual 3840 2160
 EndSubSection
EndSection
CONFIG
  /usr/lib/xorg/Xorg -displayfd 3 -config "$TASK_OUTPUT/xorg.conf" \
    -logfile "$TASK_OUTPUT/xorg.log" -noreset -nolisten tcp \
    3>"$TASK_OUTPUT/display" >"$TASK_OUTPUT/xorg-console.log" 2>&1 &
  TASK_DISPLAY_PID=$!
  for attempt in {1..50}; do
    [[ -s "$TASK_OUTPUT/display" ]] && break
    if ! kill -0 "$TASK_DISPLAY_PID" 2>/dev/null; then
      cat "$TASK_OUTPUT/xorg-console.log" >&2
      exit 1
    fi
    sleep 0.1
  done
  [[ -s "$TASK_OUTPUT/display" ]] || { echo 'Private display startup timed out.' >&2; exit 1; }
  export DISPLAY=":$(cat "$TASK_OUTPUT/display")"
  export LIBGL_ALWAYS_SOFTWARE=1
elif [[ "$TASK_PRIVATE_DISPLAY" == true && "$(uname -s)" != Linux ]]; then
  echo '--private-display is for the installed Linux Xorg dummy driver; use the native desktop on macOS.' >&2
  exit 2
fi
python3 - "$TASK_ROOT" "$TASK_DURATION" "$TASK_OUTPUT" "$TASK_WIDTH" "$TASK_HEIGHT" <<'PY' &
import hashlib, json, os, pathlib, re, signal, subprocess, sys, time
root, duration, output, width, height = pathlib.Path(sys.argv[1]), int(sys.argv[2]), pathlib.Path(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
def manifest():
    files = [root / 'project.godot', root / 'tools/profile.gd', root / 'tools/profile.sh']
    for folder in ('game', 'assets'):
        if (root / folder).is_dir():
            files.extend(path for path in (root / folder).rglob('*') if path.is_file())
    return {str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted(files)}
def git(*args):
    result = subprocess.run(['git', *args], cwd=root, capture_output=True, text=True, check=False)
    return result.stdout.strip() if result.returncode == 0 else 'unavailable'
before = manifest()
(output / 'source-manifest.json').write_text(json.dumps(before, indent=2) + '\n')
command = [str(root / 'tools/run.sh'), '--windowed', '--resolution', f'{width}x{height}', '--disable-vsync',
           '--audio-driver', 'Dummy', '--script', 'tools/profile.gd', '--', str(duration), str(output), str(width), str(height)]
print(f'Profiling four rendered chase views for approximately {duration}s; outputs: {output}', flush=True)
process = None
def stop_process():
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)
def interrupted(signum, _frame):
    stop_process()
    raise SystemExit(128 + signum)
signal.signal(signal.SIGINT, interrupted)
signal.signal(signal.SIGTERM, interrupted)
start = time.monotonic()
try:
    with (output / 'engine.log').open('w') as log:
        process = subprocess.Popen(command, cwd=root, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            code = process.wait(timeout=duration + 90)
        except subprocess.TimeoutExpired:
            stop_process()
            raise SystemExit('Profiler exceeded its bounded runtime; child process stopped.')
finally:
    stop_process()
log_text = (output / 'engine.log').read_text()
print(log_text, end='', flush=True)
report_path = output / 'report.json'
if code != 0 or re.search(r'SCRIPT ERROR:|ERROR:|FAIL:', log_text) or not report_path.exists():
    raise SystemExit('Rendered profile failed; inspect engine.log. No performance acceptance is implied.')
report = json.loads(report_path.read_text())
after = manifest()
changed = sorted(name for name in before.keys() | after.keys() if before.get(name) != after.get(name))
report.update(git_commit=git('rev-parse', 'HEAD'), git_dirty=bool(git('status', '--porcelain')),
              source_manifest='source-manifest.json', source_changed_during_run=bool(changed), changed_inputs=changed,
              process_elapsed_seconds=round(time.monotonic() - start, 3), command=command,
              source_stable_rendered_run=bool(report.get('valid_rendered_run')) and not changed)
report_path.write_text(json.dumps(report, indent=2) + '\n')
if changed:
    raise SystemExit('Source inputs changed during profiling; result marked non-comparable. Rerun after edits settle.')
if not report['source_stable_rendered_run']:
    raise SystemExit('Profiler did not produce four valid rendered samples.')
print(f"PROFILE_OK: {report['adapter']}; {width}x{height}; {report['summary']['samples']} samples; Mac acceptance remains unverified.", flush=True)
PY
TASK_PROFILE_PID=$!
wait "$TASK_PROFILE_PID"
TASK_PROFILE_PID=""

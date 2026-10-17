#!/usr/bin/env bash
# Local bounded, source-stable terrain evidence. No downloads, remote writes or profile saves.
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
TASK_PRIVATE_DISPLAY=false
while (($#)); do
  case "$1" in
    --private-display) TASK_PRIVATE_DISPLAY=true ;;
    --help|-h) echo 'Usage: tools/level_design_capture.sh [--private-display]'; exit 0 ;;
    --headless) echo 'Headless cannot provide rendered image evidence.' >&2; exit 2 ;;
    *) echo 'Usage: tools/level_design_capture.sh [--private-display]' >&2; exit 2 ;;
  esac
  shift
done
TASK_VERSION="$(./tools/run.sh --version)"
case "$TASK_VERSION" in 4.6.3.*) ;; *) echo "Expected Godot 4.6.3, found $TASK_VERSION" >&2; exit 1 ;; esac
mkdir -p .local
TASK_OUTPUT="$(mktemp -d "$TASK_ROOT/.local/level-design-$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")"
TASK_DISPLAY_PID=""
TASK_CAPTURE_PID=""
cleanup() {
  if [[ -n "$TASK_CAPTURE_PID" ]]; then
    kill -TERM "$TASK_CAPTURE_PID" 2>/dev/null || true
    wait "$TASK_CAPTURE_PID" 2>/dev/null || true
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
  [[ -x /usr/lib/xorg/Xorg ]] || { echo 'A graphical desktop or installed Xorg dummy driver is required.' >&2; exit 1; }
  cp tools/xorg-dummy.conf "$TASK_OUTPUT/xorg.conf"
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
  echo '--private-display requires the Linux Xorg dummy driver; use the native macOS desktop.' >&2
  exit 2
fi
python3 - "$TASK_ROOT" "$TASK_OUTPUT" <<'PY' &
import hashlib, json, os, pathlib, re, shutil, signal, subprocess, sys
root, output = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
destination = root / 'docs/testing/screenshots/court-cat'
def fingerprint():
    inputs = [root / name for name in ('project.godot', 'tools/run.sh', 'tools/level_design_capture.gd', 'tools/level_design_capture.sh', 'tools/xorg-dummy.conf')]
    for name in ('game', 'assets'):
        inputs.extend(path for path in (root / name).rglob('*') if path.is_file())
    return {str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted(inputs)}
def git(*args):
    result = subprocess.run(['git', *args], cwd=root, capture_output=True, text=True, check=False)
    return result.stdout.strip() if result.returncode == 0 else 'unavailable'
before = fingerprint()
command = [str(root / 'tools/run.sh'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy',
           '--windowed', '--resolution', '1280x800', '--disable-render-loop', '--fixed-fps', '60',
           '--script', 'tools/level_design_capture.gd', '--', str(output)]
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
print(f'Capturing actual six-area court/cat/map evidence; temporary outputs: {output}', flush=True)
try:
    with (output / 'engine.log').open('w') as log:
        process = subprocess.Popen(command, cwd=root, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            code = process.wait(timeout=420)
        except subprocess.TimeoutExpired:
            stop_process()
            raise SystemExit('Level capture exceeded 420 seconds; its game process was stopped.')
finally:
    stop_process()
log_text = (output / 'engine.log').read_text()
print(log_text, end='', flush=True)
manifest_path = output / 'manifest.json'
if code != 0 or re.search(r'SCRIPT ERROR:|ERROR:|FAIL:', log_text) or not manifest_path.exists():
    raise SystemExit('Level capture failed; inspect the temporary engine.log. No images published.')
report = json.loads(manifest_path.read_text())
after = fingerprint()
changed = sorted(path for path in before.keys() | after.keys() if before.get(path) != after.get(path))
report.update(git_commit=git('rev-parse', 'HEAD'), git_dirty=bool(git('status', '--porcelain')),
              source_sha256=before, source_changed_during_run=bool(changed), changed_inputs=changed,
              command=command, source_stable_capture_set=bool(report.get('valid_capture_set')) and not changed)
manifest_path.write_text(json.dumps(report, indent=2) + '\n')
if not report['source_stable_capture_set'] or len(report.get('captures', [])) != 34:
    raise SystemExit('Incomplete captures or source inputs changed during capture; no images published.')
for capture in report['captures']:
    filename = capture['file']
    if pathlib.Path(filename).name != filename or not filename.endswith('.png') or not (output / filename).is_file():
        raise SystemExit('Unexpected/missing capture file; no images published.')
    capture['sha256'] = hashlib.sha256((output / filename).read_bytes()).hexdigest()
manifest_path.write_text(json.dumps(report, indent=2) + '\n')
destination.mkdir(parents=True, exist_ok=True)
for capture in report['captures']:
    shutil.copyfile(output / capture['file'], destination / capture['file'])
shutil.copyfile(manifest_path, destination / 'manifest.json')
print(f'LEVEL_CAPTURE_OK: 34 actual PNGs and source/fixture manifest in {destination}', flush=True)
PY
TASK_CAPTURE_PID=$!
wait "$TASK_CAPTURE_PID"
TASK_CAPTURE_PID=""

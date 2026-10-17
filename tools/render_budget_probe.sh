#!/usr/bin/env bash
# Bounded local A/B rendering; no imports, installations, saves or hosted jobs.
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
TASK_PRIVATE_DISPLAY=false
for TASK_ARGUMENT in "$@"; do
  case "$TASK_ARGUMENT" in
    --private-display) TASK_PRIVATE_DISPLAY=true ;;
    --help|-h) echo 'Usage: tools/render_budget_probe.sh [--private-display]'; exit 0 ;;
    *) echo 'Usage: tools/render_budget_probe.sh [--private-display]' >&2; exit 2 ;;
  esac
done
mkdir -p .local
TASK_OUTPUT="$(mktemp -d "$TASK_ROOT/.local/render-budget-$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")"
TASK_DISPLAY_PID=""
TASK_PROBE_PID=""
cleanup() {
  if [[ -n "$TASK_PROBE_PID" ]]; then
    kill -TERM "$TASK_PROBE_PID" 2>/dev/null || true
    wait "$TASK_PROBE_PID" 2>/dev/null || true
  fi
  if [[ -n "$TASK_DISPLAY_PID" ]]; then
    kill -TERM "$TASK_DISPLAY_PID" 2>/dev/null || true
    wait "$TASK_DISPLAY_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
if [[ "$(uname -s)" == Linux && ( -z "${DISPLAY:-}" || "$TASK_PRIVATE_DISPLAY" == true ) ]]; then
  [[ -x /usr/lib/xorg/Xorg ]] || { echo 'A desktop or installed Xorg dummy driver is required.' >&2; exit 1; }
  cp tools/xorg-dummy.conf "$TASK_OUTPUT/xorg.conf"
  /usr/lib/xorg/Xorg -displayfd 3 -config "$TASK_OUTPUT/xorg.conf" \
    -logfile "$TASK_OUTPUT/xorg.log" -noreset -nolisten tcp \
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
elif [[ "$TASK_PRIVATE_DISPLAY" == true && "$(uname -s)" != Linux ]]; then
  echo '--private-display requires the installed Linux Xorg dummy driver; use the native desktop on macOS.' >&2
  exit 2
fi
python3 - "$TASK_ROOT" "$TASK_OUTPUT" <<'PY' &
import hashlib, json, os, pathlib, re, signal, subprocess, sys
root, output = map(pathlib.Path, sys.argv[1:])
def fingerprint():
    files = [root/'project.godot', root/'tools/render_budget_probe.gd',
             root/'tools/render_budget_probe.sh', root/'tools/run.sh']
    files += [path for path in (root/'game').rglob('*') if path.is_file()]
    return {str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted(files)}
before = fingerprint()
(output/'source-manifest.json').write_text(json.dumps(before, indent=2)+'\n')
command = [str(root/'tools/run.sh'), '--audio-driver', 'Dummy', '--script',
           'res://tools/render_budget_probe.gd', '--', str(output)]
with (output/'engine.log').open('w') as logfile:
    child = subprocess.Popen(command, cwd=root, stdout=logfile, stderr=subprocess.STDOUT, start_new_session=True)
    def stop(*_):
        if child.poll() is None:
            os.killpg(child.pid, signal.SIGTERM)
            try: child.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(child.pid, signal.SIGKILL)
                child.wait(timeout=5)
        raise SystemExit('Bounded render-budget probe stopped.')
    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)
    try: code = child.wait(timeout=180)
    except subprocess.TimeoutExpired: stop()
log = (output/'engine.log').read_text()
print(log, end='', flush=True)
after = fingerprint()
changed = sorted(path for path in before.keys() | after.keys() if before.get(path) != after.get(path))
report_path = output/'report.json'
report = json.loads(report_path.read_text()) if report_path.is_file() else {}
valid = (code == 0 and not re.search(r'SCRIPT ERROR:|ERROR:|FAIL:', log) and not changed
         and report.get('tree_data_preserved') and len(report.get('views', [])) == 16
         and all(view.get('screenshot_error') == 0 for view in report.get('views', [])))
report.update(source_stable=not changed, changed_inputs=changed, command=command,
              source_manifest_sha256=hashlib.sha256((output/'source-manifest.json').read_bytes()).hexdigest(),
              valid_rendered_comparison=bool(valid))
report_path.write_text(json.dumps(report, indent=2)+'\n')
artifacts = {path.name: {'bytes': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
             for path in sorted(output.iterdir()) if path.suffix in ('.png','.json') or path.name == 'engine.log'}
(output/'artifacts.json').write_text(json.dumps(artifacts, indent=2)+'\n')
if not valid:
    raise SystemExit('Render-budget comparison failed; inspect '+str(output))
print('RENDER_BUDGET_OK: exact tree data retained; rendered counter comparison at '+str(output), flush=True)
PY
TASK_PROBE_PID=$!
wait "$TASK_PROBE_PID"
TASK_PROBE_PID=""

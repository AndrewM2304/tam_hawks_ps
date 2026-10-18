#!/usr/bin/env bash
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
mkdir -p .local
TASK_OUTPUT="$(mktemp -d "$TASK_ROOT/.local/render-repair-$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")"
echo "Output: $TASK_OUTPUT"
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
  : > .local/render_repair_capture-display
  /usr/lib/xorg/Xorg -displayfd 3 -config "$TASK_ROOT/tools/xorg-dummy.conf" \
    -logfile "$TASK_ROOT/.local/xorg-render_repair_capture.log" -noreset -nolisten tcp \
    3>.local/render_repair_capture-display >.local/xorg-render_repair_capture-console.log 2>&1 &
  TASK_DISPLAY_PID=$!
  for attempt in {1..50}; do
    [[ -s .local/render_repair_capture-display ]] && break
    if ! kill -0 "$TASK_DISPLAY_PID" 2>/dev/null; then
      cat .local/xorg-render_repair_capture-console.log >&2
      exit 1
    fi
    sleep 0.1
  done
  [[ -s .local/render_repair_capture-display ]] || { echo 'Display startup timed out.' >&2; exit 1; }
  export DISPLAY=":$(cat .local/render_repair_capture-display)"
  export LIBGL_ALWAYS_SOFTWARE=1
fi
python3 - "$TASK_ROOT" "$TASK_OUTPUT" <<'CAPTURE'
import datetime, hashlib, json, os, pathlib, re, signal, struct, subprocess, sys, time
from zoneinfo import ZoneInfo
repo, output = map(pathlib.Path, sys.argv[1:])
process = None

def timestamp():
    return datetime.datetime.now(ZoneInfo('Europe/London')).isoformat()

def fingerprint():
    files = [repo / 'project.godot']
    for folder in ('game', 'assets', 'tests', 'tools'):
        files.extend(p for p in (repo / folder).rglob('*') if p.is_file() and '__pycache__' not in p.parts and p.suffix != '.pyc')
    return {str(p.relative_to(repo)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(files)}

def stop(*_):
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try: process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)
    raise SystemExit('Bounded capture stopped.')

signal.signal(signal.SIGINT, stop)
signal.signal(signal.SIGTERM, stop)

def run(command, name, seconds):
    global process
    with (output / name).open('w') as log:
        process = subprocess.Popen(command, cwd=repo, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        try: code = process.wait(timeout=seconds)
        except subprocess.TimeoutExpired: stop()
    return code

if run(['./tools/run.sh','--headless','--editor','--import'], 'import.log', 180) or re.search(r'SCRIPT ERROR:|ERROR:', (output/'import.log').read_text()):
    raise SystemExit('Import failed; see ' + str(output/'import.log'))
before = fingerprint()
receipt = {'schema':1,'started_london':timestamp(),'source_inputs':before,'input_count':len(before),
    'command':'tools/render_repair_capture.sh','limits':'Real Linux renderer; world-only observers and 24 frames per phase. Not Mac or gameplay acceptance.'}
(output/'source-start.json').write_text(json.dumps(receipt,indent=2)+'\n')
started = time.monotonic()
code = run(['./tools/run.sh','--rendering-method','gl_compatibility','--windowed','--resolution','1280x800',
    '--audio-driver','Dummy','--script','tools/render_repair_capture.gd','--',str(output)],'capture.log',600)
after = fingerprint()
changed = sorted(k for k in before.keys() | after.keys() if before.get(k) != after.get(k))
images = {}
for path in sorted(output.glob('*.png')):
    data=path.read_bytes()
    images[path.name]={'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'resolution':list(struct.unpack('>II',data[16:24]))}
clean = not re.search(r'SCRIPT ERROR:|ERROR:', (output/'capture.log').read_text())
receipt.update(completed_london=timestamp(),wall_seconds=time.monotonic()-started,exit_code=code,source_stable=not changed,
    changed_inputs=changed,images=images,clean_log=clean,accepted=code==0 and not changed and clean and len(images)==28
        and all(v['resolution']==[1280,800] for v in images.values()))
(output/'source.json').write_text(json.dumps(receipt,indent=2)+'\n')
print('RENDER_REPAIR_RECEIPT',json.dumps({k:v for k,v in receipt.items() if k not in ('source_inputs','images')}))
raise SystemExit(0 if receipt['accepted'] else 1)
CAPTURE

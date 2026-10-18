#!/usr/bin/env bash
# Bounded ordinary-scene evidence. Local installed tools only; no profile writes.
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
TASK_PRIVATE_DISPLAY=false
TASK_PUBLISH_DIR="docs/testing/screenshots/playability-repair"
while (($#)); do
  case "$1" in
    --private-display) TASK_PRIVATE_DISPLAY=true ;;
    --publish-dir) shift; TASK_PUBLISH_DIR="${1:?Supply a destination under docs/testing}" ;;
    --help|-h) echo 'Usage: tools/playability_capture.sh [--private-display] [--publish-dir docs/testing/PATH]'; exit 0 ;;
    --headless) echo 'Headless cannot provide rendered playability evidence.' >&2; exit 2 ;;
    *) echo 'Usage: tools/playability_capture.sh [--private-display] [--publish-dir docs/testing/PATH]' >&2; exit 2 ;;
  esac
  shift
done
TASK_VERSION="$(./tools/run.sh --version)"
case "$TASK_VERSION" in 4.6.3.*) ;; *) echo "Expected Godot 4.6.3, found $TASK_VERSION" >&2; exit 1 ;; esac
mkdir -p .local
TASK_OUTPUT="$(mktemp -d "$TASK_ROOT/.local/playability-capture-$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")"
# Prepare generated imports/UIDs before the source fingerprint. The normal
# run.sh launch also verifies imports, exactly as a user's ordinary source launch.
python3 - "$TASK_ROOT" "$TASK_OUTPUT/import.log" <<'IMPORT'
import os, pathlib, signal, subprocess, sys
root, logfile = map(pathlib.Path, sys.argv[1:])
with logfile.open('w') as log:
    child = subprocess.Popen([str(root/'tools/run.sh'), '--headless', '--editor', '--import'],
        cwd=root, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    def stop(*_):
        if child.poll() is None:
            os.killpg(child.pid, signal.SIGTERM)
            try: child.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(child.pid, signal.SIGKILL)
                child.wait(timeout=5)
        raise SystemExit('Bounded import stopped; no capture started.')
    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)
    try: code = child.wait(timeout=180)
    except subprocess.TimeoutExpired: stop()
if code:
    print(logfile.read_text(), file=sys.stderr)
    raise SystemExit(code)
IMPORT
if grep -Eq 'SCRIPT ERROR:|Parse Error:|ERROR:' "$TASK_OUTPUT/import.log"; then
  cat "$TASK_OUTPUT/import.log" >&2
  exit 1
fi
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
    if ! kill -0 "$TASK_DISPLAY_PID" 2>/dev/null; then cat "$TASK_OUTPUT/xorg-console.log" >&2; exit 1; fi
    sleep 0.1
  done
  [[ -s "$TASK_OUTPUT/display" ]] || { echo 'Private display startup timed out.' >&2; exit 1; }
  export DISPLAY=":$(cat "$TASK_OUTPUT/display")"
  export LIBGL_ALWAYS_SOFTWARE=1
elif [[ "$TASK_PRIVATE_DISPLAY" == true && "$(uname -s)" != Linux ]]; then
  echo '--private-display requires the Linux Xorg dummy driver; on macOS use the native desktop.' >&2
  exit 2
fi
python3 - "$TASK_ROOT" "$TASK_OUTPUT" "$TASK_PUBLISH_DIR" <<'PY' &
import hashlib, json, os, pathlib, re, shutil, signal, struct, subprocess, sys, zlib
root, output = map(pathlib.Path, sys.argv[1:3])
destination = (root / sys.argv[3]).resolve()
if not destination.is_relative_to((root / 'docs/testing').resolve()):
    raise SystemExit('Capture destination must stay inside docs/testing.')
expected_files = [
    '01-normal-title', '02-normal-spawn', '03-natural-push', '04-natural-left-turn',
    '05-natural-right-turn', '06-natural-coast', '07-actual-brake-stop', '08-shop-wall-camera',
    '09-station-undercroft-camera', '10-gallery-column-camera', '11-north-west-close',
    '12-north-east-close', '13-south-west-close', '14-south-east-close', '15-park-repaired-taper',
    '16-park-visible-boundary', '17-current-48-route-map', '18-barras-through-market', '19-clyde-safe-bridge']

def fingerprint():
    inputs = [root / name for name in ('project.godot', 'tools/run.sh', 'tools/playability_capture.gd',
        'tools/playability_capture.gd.uid', 'tools/playability_capture.tscn', 'tools/playability_capture.sh', 'tools/xorg-dummy.conf')]
    for name in ('game', 'assets', 'tests'):
        inputs.extend(path for path in (root / name).rglob('*') if path.is_file())
    return {str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted(inputs)}

def git(*args):
    result = subprocess.run(['git', *args], cwd=root, capture_output=True, text=True, check=False)
    return result.stdout.strip() if result.returncode == 0 else 'unavailable'

def png_details(path):
    data = path.read_bytes()
    if data[:8] != b'\x89PNG\r\n\x1a\n': raise ValueError('Invalid PNG signature: ' + str(path))
    offset, compressed, dimensions, ended = 8, bytearray(), None, False
    while offset < len(data):
        length = struct.unpack('>I', data[offset:offset+4])[0]
        kind = data[offset+4:offset+8]
        chunk = data[offset+8:offset+8+length]
        crc = struct.unpack('>I', data[offset+8+length:offset+12+length])[0]
        if zlib.crc32(kind + chunk) & 0xffffffff != crc: raise ValueError('PNG CRC mismatch: ' + str(path))
        if kind == b'IHDR': dimensions = struct.unpack('>IIBBBBB', chunk)
        if kind == b'IDAT': compressed.extend(chunk)
        if kind == b'IEND': ended = True
        offset += length + 12
    if not ended or dimensions is None or dimensions[:2] != (1280, 800): raise ValueError('PNG size/end invalid: ' + str(path))
    width, height, depth, colour, _, _, interlace = dimensions
    channels = {2: 3, 6: 4}.get(colour)
    if depth != 8 or channels is None or interlace != 0: raise ValueError('Unexpected PNG encoding: ' + str(path))
    raw = zlib.decompress(compressed)
    if len(raw) != height * (1 + width * channels): raise ValueError('PNG decompressed rows invalid: ' + str(path))
    return {'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data), 'resolution': [width, height], 'png_crc_and_rows_valid': True}

before = fingerprint()
command = [str(root / 'tools/run.sh'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy',
    '--windowed', '--resolution', '1280x800', '--disable-render-loop', '--fixed-fps', '60',
    'res://tools/playability_capture.tscn', '--', str(output)]
process = None

def stop_process():
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try: process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)

def interrupted(signum, _frame):
    stop_process()
    raise SystemExit(128 + signum)

signal.signal(signal.SIGINT, interrupted)
signal.signal(signal.SIGTERM, interrupted)
print(f'Capturing ordinary-scene playability evidence; temporary outputs: {output}', flush=True)
try:
    with (output / 'engine.log').open('w') as log:
        process = subprocess.Popen(command, cwd=root, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        try: code = process.wait(timeout=420)
        except subprocess.TimeoutExpired:
            stop_process()
            raise SystemExit('Capture exceeded 420 seconds; its game/import process group was stopped.')
finally:
    stop_process()
log_text = (output / 'engine.log').read_text()
print(log_text, end='', flush=True)
manifest_path = output / 'manifest.json'
if code != 0 or re.search(r'SCRIPT ERROR:|Parse Error:|ERROR:|FAIL:', log_text) or not manifest_path.exists():
    raise SystemExit('Capture failed; inspect staging engine.log. No current evidence published.')
report = json.loads(manifest_path.read_text())
after = fingerprint()
changed = sorted(path for path in before.keys() | after.keys() if before.get(path) != after.get(path))
report.update(publication_directory=str(destination.relative_to(root)), git_commit=git('rev-parse', 'HEAD'), git_dirty=bool(git('status', '--porcelain')),
    source_sha256=before, source_changed_during_run=bool(changed), changed_inputs=changed, command=command,
    source_stable_capture_set=bool(report.get('valid_capture_set')) and not changed,
    import_prepared_before_fingerprint=True,
    engine_log_sha256=hashlib.sha256((output / 'engine.log').read_bytes()).hexdigest(),
    import_log_sha256=hashlib.sha256((output / 'import.log').read_bytes()).hexdigest())
manifest_path.write_text(json.dumps(report, indent=2) + '\n')
expected = [name + '.png' for name in expected_files]
if not report['source_stable_capture_set'] or report.get('schema_version') != 5 or report.get('route_count') != 48 \
        or not report.get('normal_scene_launch') or not report.get('actual_title_branch') \
        or report.get('profile_writes_enabled') or report.get('resolution') != [1280, 800] \
        or [item.get('file') for item in report.get('captures', [])] != expected:
    raise SystemExit('Invalid, incomplete or source-changed ordinary capture; no images published.')
for item in report['captures']:
    item.update(png_details(output / item['file']))
if fingerprint() != before: raise SystemExit('Source changed during image validation; no evidence published.')
manifest_path.write_text(json.dumps(report, indent=2) + '\n')
destination.mkdir(parents=True, exist_ok=True)
for name in expected + ['manifest.json', 'engine.log', 'import.log']:
    shutil.copyfile(output / name, destination / name)
print('PLAYABILITY_CAPTURE_OK: 19 actual PNGs, normal scene/title branch and stable source manifest in ' + str(destination), flush=True)
print('MANIFEST_SHA256: ' + hashlib.sha256(manifest_path.read_bytes()).hexdigest(), flush=True)
PY
TASK_CAPTURE_PID=$!
wait "$TASK_CAPTURE_PID"
TASK_CAPTURE_PID=""

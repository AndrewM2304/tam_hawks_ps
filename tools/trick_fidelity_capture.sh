#!/usr/bin/env bash
# Bounded real-action render evidence; no network, profile writes or hosted work.
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
TASK_PRIVATE_DISPLAY=false
while (($#)); do
  case "$1" in
    --private-display) TASK_PRIVATE_DISPLAY=true ;;
    --help|-h) echo 'Usage: tools/trick_fidelity_capture.sh [--private-display]'; exit 0 ;;
    *) echo 'Usage: tools/trick_fidelity_capture.sh [--private-display]' >&2; exit 2 ;;
  esac
  shift
done
TASK_VERSION="$(./tools/run.sh --version)"
case "$TASK_VERSION" in 4.6.3.*) ;; *) echo "Expected Godot 4.6.3, found $TASK_VERSION" >&2; exit 1 ;; esac
mkdir -p .local
TASK_OUTPUT="$(mktemp -d "$TASK_ROOT/.local/trick-fidelity-$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")"
./tools/run.sh --headless --editor --import >"$TASK_OUTPUT/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|Parse Error:|ERROR:' "$TASK_OUTPUT/import.log"; then
  cat "$TASK_OUTPUT/import.log" >&2
  exit 1
fi
TASK_DISPLAY_PID=""
cleanup() {
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
if [[ "$(uname -s)" == Linux && ( -z "${DISPLAY:-}" || "$TASK_PRIVATE_DISPLAY" == true ) ]]; then
  [[ -x /usr/lib/xorg/Xorg ]] || { echo 'A graphical desktop or installed Xorg dummy driver is required.' >&2; exit 1; }
  /usr/lib/xorg/Xorg -displayfd 3 -config "$TASK_ROOT/tools/xorg-dummy.conf" \
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
fi
python3 - "$TASK_ROOT" "$TASK_OUTPUT" <<'PY'
import datetime, hashlib, json, os, pathlib, re, shutil, signal, struct, subprocess, sys, zlib
root, output = map(pathlib.Path, sys.argv[1:])
destination = root / 'docs/testing/screenshots/trick-fidelity'

def fingerprint():
    inputs = [root / 'project.godot', root / 'tools/run.sh', root / 'tools/xorg-dummy.conf']
    inputs += sorted((root / 'tools').glob('trick_fidelity_capture*'))
    for directory in ('game', 'tests'):
        inputs += sorted(path for path in (root / directory).rglob('*') if path.is_file())
    return {str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted(set(inputs))}

def png_details(path):
    data = path.read_bytes()
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError('Invalid PNG: ' + str(path))
    offset, compressed, dimensions, ended = 8, bytearray(), None, False
    while offset < len(data):
        size = struct.unpack('>I', data[offset:offset+4])[0]
        kind = data[offset+4:offset+8]
        chunk = data[offset+8:offset+8+size]
        checksum = struct.unpack('>I', data[offset+8+size:offset+12+size])[0]
        if zlib.crc32(kind + chunk) & 0xffffffff != checksum:
            raise ValueError('PNG CRC failure: ' + str(path))
        if kind == b'IHDR': dimensions = struct.unpack('>IIBBBBB', chunk)
        if kind == b'IDAT': compressed.extend(chunk)
        if kind == b'IEND': ended = True
        offset += size + 12
    if not ended or dimensions is None or dimensions[:2] != (1280, 800):
        raise ValueError('PNG size/end failure: ' + str(path))
    width, height, depth, colour, _, _, interlace = dimensions
    channels = {2: 3, 6: 4}.get(colour)
    if depth != 8 or channels is None or interlace:
        raise ValueError('Unsupported PNG encoding: ' + str(path))
    if len(zlib.decompress(compressed)) != height * (1 + width * channels):
        raise ValueError('Incomplete PNG rows: ' + str(path))
    return {'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data),
        'resolution': [width, height], 'png_crc_and_rows_valid': True}

before = fingerprint()
command = [str(root / 'tools/run.sh'), '--rendering-method', 'gl_compatibility',
    '--audio-driver', 'Dummy', '--windowed', '--resolution', '1280x800',
    '--disable-render-loop', '--fixed-fps', '60', '--script', 'tools/trick_fidelity_capture.gd', '--', str(output)]
process = None
def stop(*_):
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try: process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)
signal.signal(signal.SIGTERM, lambda *args: (stop(), sys.exit(143)))
signal.signal(signal.SIGINT, lambda *args: (stop(), sys.exit(130)))
print('Capturing trick-fidelity evidence in ' + str(output), flush=True)
try:
    with (output / 'engine.log').open('w') as log:
        process = subprocess.Popen(command, cwd=root, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        try: code = process.wait(timeout=420)
        except subprocess.TimeoutExpired:
            stop()
            raise SystemExit('Capture exceeded its 420-second bound.')
finally:
    stop()
log_text = (output / 'engine.log').read_text()
print(log_text, end='', flush=True)
if code or re.search(r'SCRIPT ERROR:|Parse Error:|ERROR:|FAIL:', log_text):
    raise SystemExit('Capture failed; no current evidence published. Inspect ' + str(output))
report = json.loads((output / 'manifest.json').read_text())
after = fingerprint()
changed = sorted(path for path in before.keys() | after.keys() if before.get(path) != after.get(path))
report.update(source_sha256=before, source_changed_during_run=bool(changed),
    changed_inputs=changed, command=command,
    git_commit=subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=root, capture_output=True, text=True, check=True).stdout.strip(),
    git_dirty=bool(subprocess.run(['git', 'status', '--porcelain'], cwd=root, capture_output=True, text=True, check=True).stdout.strip()),
    engine_log_sha256=hashlib.sha256((output / 'engine.log').read_bytes()).hexdigest(),
    import_log_sha256=hashlib.sha256((output / 'import.log').read_bytes()).hexdigest())
if changed or report.get('failures') != 0 or not report.get('production_main') or report.get('profile_writes_enabled'):
    raise SystemExit('Invalid or source-changed capture; no current evidence published.')
captures = report.get('captures', [])
if len(captures) != 36 or len({item['file'] for item in captures}) != 36:
    raise SystemExit('Expected 36 distinct actual captures; no current evidence published.')
for item in captures:
    item.update(png_details(output / item['file']))
if fingerprint() != before:
    raise SystemExit('Source changed during image validation; no current evidence published.')
report['source_stable_capture_set'] = True
(output / 'manifest.json').write_text(json.dumps(report, indent=2) + '\n')
destination.mkdir(parents=True, exist_ok=True)
for filename in [item['file'] for item in captures] + ['manifest.json', 'engine.log', 'import.log']:
    shutil.copyfile(output / filename, destination / filename)
print('TRICK_FIDELITY_CAPTURE_OK: 36 real PNGs, stable source, zero failures in ' + str(destination))
print('MANIFEST_SHA256: ' + hashlib.sha256((output / 'manifest.json').read_bytes()).hexdigest())
PY

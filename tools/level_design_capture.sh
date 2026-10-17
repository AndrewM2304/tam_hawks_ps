#!/usr/bin/env bash
# Local bounded, source-stable terrain evidence. No downloads, remote writes or profile saves.
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
TASK_PRIVATE_DISPLAY=false
TASK_CAT_MOTION=false
while (($#)); do
  case "$1" in
    --private-display) TASK_PRIVATE_DISPLAY=true ;;
    --cat-motion) TASK_CAT_MOTION=true ;;
    --help|-h) echo 'Usage: tools/level_design_capture.sh [--private-display] [--cat-motion]'; exit 0 ;;
    --headless) echo 'Headless cannot provide rendered image evidence.' >&2; exit 2 ;;
    *) echo 'Usage: tools/level_design_capture.sh [--private-display] [--cat-motion]' >&2; exit 2 ;;
  esac
  shift
done
if [[ "$TASK_CAT_MOTION" == true ]]; then
  command -v ffmpeg >/dev/null 2>&1 && command -v ffprobe >/dev/null 2>&1 || { echo 'The optional motion capture requires installed free ffmpeg/ffprobe.' >&2; exit 1; }
fi
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
python3 - "$TASK_ROOT" "$TASK_OUTPUT" "$TASK_CAT_MOTION" <<'PY' &
import hashlib, json, os, pathlib, re, shutil, signal, subprocess, sys
root, output = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
destination = root / 'docs/testing/screenshots/exchange-gallery'
capture_motion = sys.argv[3] == 'true'
expected_captures = 30 if capture_motion else 22
def fingerprint():
    inputs = [root / name for name in ('project.godot', 'tools/run.sh', 'tools/level_design_capture.gd', 'tools/level_design_capture.sh', 'tools/xorg-dummy.conf')]
    for name in ('game', 'assets', 'tests'):
        inputs.extend(path for path in (root / name).rglob('*') if path.is_file())
    return {str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted(inputs)}
def git(*args):
    result = subprocess.run(['git', *args], cwd=root, capture_output=True, text=True, check=False)
    return result.stdout.strip() if result.returncode == 0 else 'unavailable'
before = fingerprint()
command = [str(root / 'tools/run.sh'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy',
           '--windowed', '--resolution', '1280x800', '--disable-render-loop', '--fixed-fps', '60',
           '--script', 'tools/level_design_capture.gd', '--', str(output)]
if capture_motion:
    command.append('--cat-motion')
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
def run_media(arguments, timeout):
    global process
    process = subprocess.Popen(arguments, cwd=root, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               text=True, start_new_session=True)
    try:
        stdout, stderr = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        stop_process()
        raise SystemExit('Media validation exceeded its bound; child process stopped.')
    if process.returncode:
        raise SystemExit('Media validation failed: ' + stderr[-2000:])
    return stdout
print(f'Capturing actual Exchange/gallery terrain and earned-line evidence; temporary outputs: {output}', flush=True)
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
if not report['source_stable_capture_set'] or len(report.get('captures', [])) != expected_captures:
    raise SystemExit('Incomplete captures or source inputs changed during capture; no images published.')
for capture in report['captures']:
    filename = capture['file']
    if pathlib.Path(filename).name != filename or not filename.endswith('.png') or not (output / filename).is_file():
        raise SystemExit('Unexpected/missing capture file; no images published.')
    capture['sha256'] = hashlib.sha256((output / filename).read_bytes()).hexdigest()
if capture_motion:
    motion = report.get('cat_motion', {})
    frames = motion.get('frames', [])
    if motion.get('frame_count') != 100 or len(frames) != 100:
        raise SystemExit('Incomplete earned-stage motion; no images published.')
    for index, frame in enumerate(frames):
        frame_path = output / 'cat-motion-frames' / f'{index:05d}.png'
        if frame.get('file') != frame_path.name or not frame_path.is_file():
            raise SystemExit('Missing motion frame; no evidence published.')
        frame['sha256'] = hashlib.sha256(frame_path.read_bytes()).hexdigest()
    video = output / 'bin-cats-earned-motion.mp4'
    run_media(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-framerate', '30',
                    '-i', str(output / 'cat-motion-frames/%05d.png'), '-frames:v', '100',
                    '-c:v', 'libx264', '-crf', '20', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', str(video)],
                   timeout=60)
    decoded = run_media(['ffprobe', '-v', 'error', '-count_frames', '-select_streams', 'v:0',
                              '-show_entries', 'stream=nb_read_frames', '-of', 'default=noprint_wrappers=1:nokey=1', str(video)],
                             timeout=30).strip()
    if decoded != '100':
        raise SystemExit('Motion decode frame count differs; no evidence published.')
    run_media(['ffmpeg', '-v', 'error', '-i', str(video), '-f', 'null', '-'], timeout=60)
    motion.update(video_file=video.name, video_sha256=hashlib.sha256(video.read_bytes()).hexdigest(),
                  video_bytes=video.stat().st_size, decoded_frames=100, full_decode_passed=True,
                  promoted_path=str(root.parent / 'TamHawks-bin-cats-preview.mp4'))
    if fingerprint() != before:
        raise SystemExit('Source changed during motion validation; no evidence published.')
manifest_path.write_text(json.dumps(report, indent=2) + '\n')
destination.mkdir(parents=True, exist_ok=True)
for capture in report['captures']:
    shutil.copyfile(output / capture['file'], destination / capture['file'])
shutil.copyfile(manifest_path, destination / 'manifest.json')
if capture_motion:
    shutil.copyfile(video, root.parent / 'TamHawks-bin-cats-preview.mp4')
print(f'LEVEL_CAPTURE_OK: {expected_captures} actual PNGs and source/fixture manifest in {destination}', flush=True)
PY
TASK_CAPTURE_PID=$!
wait "$TASK_CAPTURE_PID"
TASK_CAPTURE_PID=""

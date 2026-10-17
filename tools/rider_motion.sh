#!/usr/bin/env bash
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
mkdir -p .local
command -v ffmpeg >/dev/null 2>&1 || { echo 'Install the free ffmpeg tool locally to encode the clip.' >&2; exit 1; }
command -v ffprobe >/dev/null 2>&1 || { echo 'The free ffmpeg package must include ffprobe to validate the clip.' >&2; exit 1; }
# A failed scene/script startup must never encode a previous run as new evidence.
rm -f .local/rider-motion-frame-count.txt .local/rider-motion-sequence.json
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
  : > .local/rider_motion-display
  /usr/lib/xorg/Xorg -displayfd 3 -config "$TASK_ROOT/tools/xorg-dummy.conf" \
    -logfile "$TASK_ROOT/.local/xorg-rider_motion.log" -noreset -nolisten tcp \
    3>.local/rider_motion-display >.local/xorg-rider_motion-console.log 2>&1 &
  TASK_DISPLAY_PID=$!
  for attempt in {1..50}; do
    [[ -s .local/rider_motion-display ]] && break
    if ! kill -0 "$TASK_DISPLAY_PID" 2>/dev/null; then
      cat .local/xorg-rider_motion-console.log >&2
      exit 1
    fi
    sleep 0.1
  done
  [[ -s .local/rider_motion-display ]] || { echo 'Display startup timed out.' >&2; exit 1; }
  export DISPLAY=":$(cat .local/rider_motion-display)"
  export LIBGL_ALWAYS_SOFTWARE=1
fi
if command -v timeout >/dev/null 2>&1; then
  timeout 600s ./tools/run.sh --audio-driver Dummy --disable-render-loop --fixed-fps 60 --script tools/rider_motion.gd
else
  ./tools/run.sh --audio-driver Dummy --disable-render-loop --fixed-fps 60 --script tools/rider_motion.gd
fi

read -r TASK_FRAME_COUNT < .local/rider-motion-frame-count.txt
[[ "$TASK_FRAME_COUNT" =~ ^[1-9][0-9]*$ ]] || { echo 'Motion capture did not report a positive frame count.' >&2; exit 1; }
ffmpeg -hide_banner -loglevel error -y -framerate 30 -i .local/rider-motion-frames/%05d.png \
  -frames:v "$TASK_FRAME_COUNT" -c:v libx264 -crf 20 -pix_fmt yuv420p -movflags +faststart \
  .local/rider-cleanup-motion.mp4
TASK_DECODED_FRAMES="$(ffprobe -v error -count_frames -select_streams v:0 \
  -show_entries stream=nb_read_frames -of default=noprint_wrappers=1:nokey=1 \
  .local/rider-cleanup-motion.mp4)"
[[ "$TASK_DECODED_FRAMES" == "$TASK_FRAME_COUNT" ]] || { echo 'Encoded motion frame count did not match the capture.' >&2; exit 1; }
ffmpeg -v error -i .local/rider-cleanup-motion.mp4 -f null -
printf 'Saved .local/rider-cleanup-motion.mp4 (%s frames at 30 fps). See .local/rider-motion-sequence.json for cuts.\n' "$TASK_FRAME_COUNT"

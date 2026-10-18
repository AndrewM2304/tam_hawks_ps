#!/usr/bin/env bash
# Explicitly released, bounded disposable preview. Never open the live project.
set -euo pipefail
[[ "${1:-}" == --render-approved ]] || { echo 'Wait for the root render window; then pass --render-approved.' >&2; exit 2; }
TASK_PREVIEW="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TASK_GODOT="${GODOT_BIN:-godot}"
mkdir -p "$TASK_PREVIEW/runs"
TASK_OUTPUT="$(mktemp -d "$TASK_PREVIEW/runs/comparison-XXXXXX")"
export PYTHONDONTWRITEBYTECODE=1
export OMP_NUM_THREADS=2
export OPENBLAS_NUM_THREADS=2
export XDG_DATA_HOME="$TASK_OUTPUT/data"
export XDG_CONFIG_HOME="$TASK_OUTPUT/config"
export XDG_CACHE_HOME="$TASK_OUTPUT/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
TASK_VERSION="$("$TASK_GODOT" --version)"
[[ "$TASK_VERSION" == 4.6.3.* ]] || { echo 'Godot 4.6.3 required.' >&2; exit 1; }
printf '%s\n' "$TASK_VERSION" > "$TASK_OUTPUT/engine-version.txt"
python3 -B "$TASK_PREVIEW/prepare.py" stage "$TASK_OUTPUT"
TASK_DISPLAY_PID=""
TASK_GAME_PID=""
cleanup() {
  if [[ -n "$TASK_GAME_PID" ]]; then kill "$TASK_GAME_PID" 2>/dev/null || true; wait "$TASK_GAME_PID" 2>/dev/null || true; fi
  if [[ -n "$TASK_DISPLAY_PID" ]]; then kill "$TASK_DISPLAY_PID" 2>/dev/null || true; wait "$TASK_DISPLAY_PID" 2>/dev/null || true; fi
}
trap cleanup EXIT
timeout 180s "$TASK_GODOT" --path "$TASK_OUTPUT" --headless --editor --import > "$TASK_OUTPUT/import-initial.log" 2>&1
python3 -B "$TASK_PREVIEW/prepare.py" configure "$TASK_OUTPUT"
timeout 180s "$TASK_GODOT" --path "$TASK_OUTPUT" --headless --editor --import > "$TASK_OUTPUT/import-configured.log" 2>&1
if [[ "$(uname -s)" == Linux ]]; then
  /usr/lib/xorg/Xorg -displayfd 3 -config "$TASK_PREVIEW/xorg.conf" -logfile "$TASK_OUTPUT/xorg.log" -noreset -nolisten tcp 3>"$TASK_OUTPUT/display" >"$TASK_OUTPUT/xorg-console.log" 2>&1 &
  TASK_DISPLAY_PID=$!
  for attempt in {1..50}; do
    [[ -s "$TASK_OUTPUT/display" ]] && break
    kill -0 "$TASK_DISPLAY_PID" 2>/dev/null || { cat "$TASK_OUTPUT/xorg-console.log" >&2; exit 1; }
    sleep 0.1
  done
  [[ -s "$TASK_OUTPUT/display" ]] || { echo 'Private Xorg did not become ready.' >&2; exit 1; }
  export DISPLAY=":$(cat "$TASK_OUTPUT/display")"
  export LIBGL_ALWAYS_SOFTWARE=1
fi
timeout 480s "$TASK_GODOT" --path "$TASK_OUTPUT" --windowed --resolution 1920x1080 --position 0,0 --audio-driver Dummy --script render.gd > "$TASK_OUTPUT/engine.log" 2>&1 &
TASK_GAME_PID=$!
wait "$TASK_GAME_PID"
TASK_GAME_PID=""
python3 -B "$TASK_PREVIEW/prepare.py" finalize "$TASK_OUTPUT"
printf 'TWO_SURFACE_PREVIEW_OUTPUT %s\n' "$TASK_OUTPUT"

#!/usr/bin/env bash
# Free installed tools only; isolated copy, no game/profile changes.
set -euo pipefail
TASK_SOURCE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TASK_ROOT="$(cd -- "$TASK_SOURCE/../.." && pwd)"
TASK_OUTPUT="$(mktemp -d "$TASK_ROOT/.local/glasgow-bay-preview-XXXXXX")"
TASK_GODOT="${GODOT_BIN:-godot}"
export XDG_DATA_HOME="$TASK_OUTPUT/data"
export XDG_CONFIG_HOME="$TASK_OUTPUT/config"
export XDG_CACHE_HOME="$TASK_OUTPUT/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
TASK_VERSION="$("$TASK_GODOT" --version)"
[[ "$TASK_VERSION" == 4.6.3.* ]] || { echo 'Godot 4.6.3 required.' >&2; exit 1; }
cp "$TASK_SOURCE/preview/project.godot" "$TASK_SOURCE/preview/render.gd" "$TASK_OUTPUT/"
cp "$TASK_SOURCE"/generated/*.glb "$TASK_OUTPUT/"
TASK_DISPLAY_PID=""
cleanup() {
  if [[ -n "$TASK_DISPLAY_PID" ]]; then kill "$TASK_DISPLAY_PID" 2>/dev/null || true; wait "$TASK_DISPLAY_PID" 2>/dev/null || true; fi
}
trap cleanup EXIT
run_bounded() {
  if command -v timeout >/dev/null 2>&1; then timeout 120s "$@"; else "$@"; fi
}
run_bounded "$TASK_GODOT" --path "$TASK_OUTPUT" --headless --editor --import > "$TASK_OUTPUT/import.log" 2>&1
if grep -Eq 'ERROR:|SCRIPT ERROR:' "$TASK_OUTPUT/import.log"; then cat "$TASK_OUTPUT/import.log" >&2; exit 1; fi
if [[ "$(uname -s)" == Linux && -z "${DISPLAY:-}" ]]; then
  /usr/lib/xorg/Xorg -displayfd 3 -config "$TASK_ROOT/tools/xorg-dummy.conf" -logfile "$TASK_OUTPUT/xorg.log" -noreset -nolisten tcp 3>"$TASK_OUTPUT/display" >"$TASK_OUTPUT/xorg-console.log" 2>&1 &
  TASK_DISPLAY_PID=$!
  for attempt in {1..50}; do [[ -s "$TASK_OUTPUT/display" ]] && break; sleep 0.1; done
  [[ -s "$TASK_OUTPUT/display" ]] || { echo 'Display startup failed.' >&2; exit 1; }
  export DISPLAY=":$(cat "$TASK_OUTPUT/display")"
  export LIBGL_ALWAYS_SOFTWARE=1
fi
run_bounded "$TASK_GODOT" --path "$TASK_OUTPUT" --windowed --resolution 1280x800 --audio-driver Dummy --disable-render-loop --fixed-fps 60 --script render.gd > "$TASK_OUTPUT/engine.log" 2>&1
if grep -Eq 'ERROR:|SCRIPT ERROR:' "$TASK_OUTPUT/engine.log"; then cat "$TASK_OUTPUT/engine.log" >&2; exit 1; fi
printf 'BAY_PREVIEW_OUTPUT %s\n' "$TASK_OUTPUT"

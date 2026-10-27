#!/usr/bin/env bash
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
export XDG_DATA_HOME="$TASK_ROOT/.local/data"
export XDG_CONFIG_HOME="$TASK_ROOT/.local/config"
export XDG_CACHE_HOME="$TASK_ROOT/.local/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
TASK_GODOT="${GODOT_BIN:-godot}"
# A source archive deliberately excludes .godot/. Starting its game directly
# does not import OBJ/textures or discover class_name scripts. Prepare ordinary
# play here, so a fresh download works with the same command as a warm checkout.
# Editor, test and export tools already own their import/check sequence.
TASK_PREPARE_PLAY=true
for TASK_ARGUMENT in "$@"; do
  case "$TASK_ARGUMENT" in
    --editor|-e|--import|--script|-s|--check-only|--version|--help|-h|--export-release|--export-debug|--export-pack|--main-pack|--doctool)
      TASK_PREPARE_PLAY=false ;;
  esac
done
if "$TASK_PREPARE_PLAY"; then
  TASK_VERSION="$("$TASK_GODOT" --version)"
  case "$TASK_VERSION" in
    4.6.3.*) ;;
    *) echo "Expected free Godot 4.6.3, found $TASK_VERSION. Set GODOT_BIN to the pinned editor." >&2; exit 1 ;;
  esac
  echo 'Preparing local game assets…'
  TASK_IMPORT_LOG="$TASK_ROOT/.local/source-import.log"
  TASK_IMPORT_RESULT=0
  "$TASK_GODOT" --path "$TASK_ROOT" --headless --editor --import >"$TASK_IMPORT_LOG" 2>&1 || TASK_IMPORT_RESULT=$?
  if [[ "$TASK_IMPORT_RESULT" != 0 ]] || grep -Eq 'SCRIPT ERROR:|Parse Error:|ERROR:' "$TASK_IMPORT_LOG"; then
    cat "$TASK_IMPORT_LOG" >&2
    echo 'Game assets could not be prepared; the game was not started.' >&2
    [[ "$TASK_IMPORT_RESULT" != 0 ]] && exit "$TASK_IMPORT_RESULT"
    exit 1
  fi
fi
exec "$TASK_GODOT" --path "$TASK_ROOT" "$@"

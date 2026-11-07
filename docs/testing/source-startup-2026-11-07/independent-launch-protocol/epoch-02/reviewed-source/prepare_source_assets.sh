#!/usr/bin/env bash
# Local editor import with live progress and a portable macOS/Linux deadline.
set -euo pipefail
TASK_GODOT="${1:?Supply the Godot executable}"
TASK_ROOT="${2:?Supply the project directory}"
TASK_LIMIT="${TAM_ASSET_IMPORT_TIMEOUT_SECONDS:-300}"
case "$TASK_LIMIT" in ''|*[!0-9]*) echo 'Asset import timeout must be an integer from 1 to 3600 seconds.' >&2; exit 2 ;; esac
if (( ${#TASK_LIMIT} > 4 )); then echo 'Asset import timeout must be from 1 to 3600 seconds.' >&2; exit 2; fi
TASK_LIMIT=$((10#$TASK_LIMIT))
if (( TASK_LIMIT < 1 || TASK_LIMIT > 3600 )); then echo 'Asset import timeout must be from 1 to 3600 seconds.' >&2; exit 2; fi
mkdir -p "$TASK_ROOT/.local"
TASK_LOG="$TASK_ROOT/.local/source-import.log"
if ! : > "$TASK_LOG"; then
  echo "Cannot write the asset import log: $TASK_LOG" >&2
  exit 1
fi
TASK_ENGINE_PID=''
TASK_ENGINE_GROUP=''
cleanup_import() {
  if [[ -n "$TASK_ENGINE_GROUP" ]]; then
    kill -TERM -- "-$TASK_ENGINE_GROUP" 2>/dev/null || true
    kill -KILL -- "-$TASK_ENGINE_GROUP" 2>/dev/null || true
  fi
  if [[ -n "$TASK_ENGINE_PID" ]]; then
    wait "$TASK_ENGINE_PID" 2>/dev/null || true
  fi
}
trap cleanup_import EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
TASK_NEXT_LINE=1
show_import_progress() {
  local TASK_LINES
  TASK_LINES="$(wc -l < "$TASK_LOG")"
  if (( TASK_LINES >= TASK_NEXT_LINE )); then
    sed -n "${TASK_NEXT_LINE},${TASK_LINES}p" "$TASK_LOG"
    TASK_NEXT_LINE=$((TASK_LINES + 1))
  fi
}
echo "Preparing local game assets (first launch can take a few minutes; limit ${TASK_LIMIT}s)…"
echo "Import log: $TASK_LOG"
# Bash job control gives this importer its own process group on macOS and Linux.
# Its worker processes must stop too if import times out or launch is cancelled.
set -m
"$TASK_GODOT" --path "$TASK_ROOT" --headless --audio-driver Dummy --editor --import > "$TASK_LOG" 2>&1 &
TASK_ENGINE_PID=$!
TASK_ENGINE_GROUP=$TASK_ENGINE_PID
set +m
TASK_STARTED=$SECONDS
TASK_LAST_NOTICE=0
TASK_TIMED_OUT=false
while kill -0 "$TASK_ENGINE_PID" 2>/dev/null; do
  show_import_progress
  TASK_ELAPSED=$((SECONDS - TASK_STARTED))
  if (( TASK_ELAPSED >= TASK_LIMIT )); then
    TASK_TIMED_OUT=true
    echo "Asset preparation timed out after ${TASK_LIMIT}s. Last importer output is above; log: $TASK_LOG" >&2
    kill -TERM -- "-$TASK_ENGINE_GROUP" 2>/dev/null || true
    sleep 2
    kill -KILL -- "-$TASK_ENGINE_GROUP" 2>/dev/null || true
    break
  fi
  if (( TASK_ELAPSED - TASK_LAST_NOTICE >= 30 )); then
    echo "Still preparing assets (${TASK_ELAPSED}s); waiting for Godot's importer…"
    TASK_LAST_NOTICE=$TASK_ELAPSED
  fi
  sleep 1
done
TASK_RESULT=0
wait "$TASK_ENGINE_PID" || TASK_RESULT=$?
TASK_ENGINE_PID=''
show_import_progress
# Include an unterminated final line after the native process closes the file.
sed -n "${TASK_NEXT_LINE},\$p" "$TASK_LOG"
if "$TASK_TIMED_OUT"; then TASK_RESULT=124; fi
if (( TASK_RESULT != 0 )) || grep -Eq 'SCRIPT ERROR:|Parse Error:|ERROR:' "$TASK_LOG"; then
  echo 'Game assets could not be prepared; the game was not started.' >&2
  if (( TASK_RESULT == 0 )); then TASK_RESULT=1; fi
  exit "$TASK_RESULT"
fi
echo 'Game assets ready. Starting Tam Hawks Pro Skater…'

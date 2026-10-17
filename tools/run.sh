#!/usr/bin/env bash
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
export XDG_DATA_HOME="$TASK_ROOT/.local/data"
export XDG_CONFIG_HOME="$TASK_ROOT/.local/config"
export XDG_CACHE_HOME="$TASK_ROOT/.local/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
TASK_GODOT="${GODOT_BIN:-godot}"
exec "$TASK_GODOT" --path "$TASK_ROOT" "$@"

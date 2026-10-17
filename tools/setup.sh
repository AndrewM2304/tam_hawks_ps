#!/usr/bin/env bash
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
TASK_GODOT="${GODOT_BIN:-godot}"
if ! command -v "$TASK_GODOT" >/dev/null 2>&1; then
  echo 'Install free Godot 4.6.3 from godotengine.org, or set GODOT_BIN to its executable.' >&2
  exit 1
fi
TASK_VERSION="$(./tools/run.sh --version)"
case "$TASK_VERSION" in
  4.6.3.*) ;;
  *) echo "Expected Godot 4.6.3, found $TASK_VERSION" >&2; exit 1 ;;
esac
./tools/check.sh

#!/usr/bin/env bash
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
mkdir -p .local
TASK_DISPLAY_PID=""
cleanup() {
  if [[ -n "$TASK_DISPLAY_PID" ]]; then
    kill "$TASK_DISPLAY_PID" 2>/dev/null || true
    wait "$TASK_DISPLAY_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT
if [[ "$(uname -s)" == Linux && -z "${DISPLAY:-}" ]]; then
  : > .local/rider-studio-display
  /usr/lib/xorg/Xorg -displayfd 3 -config "$TASK_ROOT/tools/xorg-dummy.conf" \
    -logfile "$TASK_ROOT/.local/xorg-rider-studio.log" -noreset -nolisten tcp \
    3>.local/rider-studio-display >.local/xorg-rider-studio-console.log 2>&1 &
  TASK_DISPLAY_PID=$!
  for attempt in {1..50}; do
    [[ -s .local/rider-studio-display ]] && break
    kill -0 "$TASK_DISPLAY_PID" 2>/dev/null || { cat .local/xorg-rider-studio-console.log >&2; exit 1; }
    sleep 0.1
  done
  [[ -s .local/rider-studio-display ]] || { echo 'Display startup timed out.' >&2; exit 1; }
  export DISPLAY=":$(cat .local/rider-studio-display)"
  export LIBGL_ALWAYS_SOFTWARE=1
fi
TASK_STUDIO_LOG="$TASK_ROOT/.local/rider-studio-native.log"
if [[ -d .local/fidelity/rider-studio ]]; then
  TASK_EPOCH_TAG="$(date -u +%Y%m%dT%H%M%SZ)"
  mv .local/fidelity/rider-studio ".local/fidelity/rider-studio-history-$TASK_EPOCH_TAG"
fi
./tools/run.sh --audio-driver Dummy --fixed-fps 60 --script tools/rider_asset_inspect.gd 2>&1 | tee "$TASK_STUDIO_LOG"
python3 - "$TASK_STUDIO_LOG" <<'PY'
from pathlib import Path
import hashlib, json, re, sys
log = Path(sys.argv[1]).read_bytes()
path = Path('.local/fidelity/rider-studio/receipt.json')
receipt = json.loads(path.read_text())
clean = not re.search(rb'SCRIPT ERROR:|Parse Error:|ERROR:', log)
receipt['engine_log_clean'] = clean
receipt['engine_log_sha256'] = hashlib.sha256(log).hexdigest()
if not clean:
    receipt['failures'] += 1
path.write_text(json.dumps(receipt, indent=2) + '\n')
PY
if rg -q 'SCRIPT ERROR:|Parse Error:|ERROR:' "$TASK_STUDIO_LOG"; then
  echo 'Rider studio rejected engine/script errors; inspect .local/rider-studio-native.log.' >&2
  exit 1
fi

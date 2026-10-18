#!/usr/bin/env bash
# Six independently placed production-Main traversals, native mapped inputs.
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
TASK_PRIVATE=false
TASK_OUTPUT=""
while (($#)); do
  case "$1" in
    --private-display) TASK_PRIVATE=true ;;
    --output) shift; TASK_OUTPUT="${1:?Supply output directory}" ;;
    --help|-h) echo 'Usage: tools/area_audit_play.sh [--private-display] [--output DIRECTORY]'; exit 0 ;;
    *) echo "Unknown area-audit argument: $1" >&2; exit 2 ;;
  esac
  shift
done
if "$TASK_PRIVATE" && [[ "$(uname -s)" != Linux ]]; then echo '--private-display requires Linux; use the native Mac desktop.' >&2; exit 2; fi
mkdir -p .local
if [[ -z "$TASK_OUTPUT" ]]; then TASK_OUTPUT="$(mktemp -d "$TASK_ROOT/.local/area-audit-play-$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")"; else mkdir -p "$TASK_OUTPUT"; fi
TASK_OUTPUT="$(cd -- "$TASK_OUTPUT" && pwd)"
TASK_XORG_PID=""
TASK_RUN_PID=""
cleanup() {
  if [[ -n "$TASK_RUN_PID" ]]; then kill -TERM "$TASK_RUN_PID" 2>/dev/null || true; wait "$TASK_RUN_PID" 2>/dev/null || true; fi
  if [[ -n "$TASK_XORG_PID" ]]; then
    kill -TERM "$TASK_XORG_PID" 2>/dev/null || true
    for attempt in {1..20}; do kill -0 "$TASK_XORG_PID" 2>/dev/null || break; sleep 0.1; done
    kill -KILL "$TASK_XORG_PID" 2>/dev/null || true
    wait "$TASK_XORG_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
TASK_VERSION="$(./tools/run.sh --version)"
case "$TASK_VERSION" in 4.6.3.*) ;; *) echo "Expected Godot 4.6.3, found $TASK_VERSION" >&2; exit 1 ;; esac
python3 - "$TASK_ROOT" "$TASK_OUTPUT" <<'PY'
import os, pathlib, signal, subprocess, sys
root, output = map(pathlib.Path, sys.argv[1:])
with (output/'import.log').open('w') as logfile:
    child = subprocess.Popen([str(root/'tools/run.sh'),'--headless','--editor','--import'],cwd=root,stdout=logfile,stderr=subprocess.STDOUT,start_new_session=True)
    def stop(*_):
        if child.poll() is None:
            os.killpg(child.pid,signal.SIGTERM)
            try: child.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(child.pid,signal.SIGKILL)
                child.wait(timeout=5)
        raise SystemExit('Area audit import stopped; no traversal started.')
    signal.signal(signal.SIGTERM,stop)
    signal.signal(signal.SIGINT,stop)
    try: code = child.wait(timeout=180)
    except subprocess.TimeoutExpired: stop()
if code or any(token in (output/'import.log').read_text() for token in ('SCRIPT ERROR:','Parse Error:','ERROR:')):
    raise SystemExit('Area audit import failed; inspect '+str(output/'import.log'))
PY
if [[ "$(uname -s)" == Linux && ( -z "${DISPLAY:-}" || "$TASK_PRIVATE" == true ) ]]; then
  [[ -x /usr/lib/xorg/Xorg ]] || { echo 'Installed Xorg is required for native rendered evidence.' >&2; exit 1; }
  /usr/lib/xorg/Xorg -displayfd 3 -config "$TASK_ROOT/tools/xorg-dummy.conf" -logfile "$TASK_OUTPUT/xorg.log" -noreset -nolisten tcp \
    3>"$TASK_OUTPUT/display" >"$TASK_OUTPUT/xorg-console.log" 2>&1 &
  TASK_XORG_PID=$!
  for attempt in {1..50}; do
    [[ -s "$TASK_OUTPUT/display" ]] && break
    kill -0 "$TASK_XORG_PID" 2>/dev/null || { cat "$TASK_OUTPUT/xorg-console.log" >&2; exit 1; }
    sleep 0.1
  done
  [[ -s "$TASK_OUTPUT/display" ]] || { echo 'Private display startup timed out.' >&2; exit 1; }
  export DISPLAY=":$(cat "$TASK_OUTPUT/display")"
  export LIBGL_ALWAYS_SOFTWARE=1
fi
python3 - "$TASK_ROOT" "$TASK_OUTPUT" <<'PY' &
import hashlib, json, os, pathlib, signal, subprocess, sys
root, output = map(pathlib.Path, sys.argv[1:])
def fingerprint():
    files = [root/'project.godot']
    for folder in ('game','assets','tests','tools'):
        if (root/folder).exists(): files.extend(p for p in (root/folder).rglob('*') if p.is_file() and '__pycache__' not in p.parts)
    return {str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(files)}
before = fingerprint()
(output/'source-before.json').write_text(json.dumps(before,indent=2)+'\n')
(output/'executed-area_audit_play.gd.txt').write_bytes((root/'tools/area_audit_play.gd').read_bytes())
command = [str(root/'tools/run.sh'),'--rendering-method','gl_compatibility','--audio-driver','Dummy','--script','tools/area_audit_play.gd','--',str(output)]
(output/'command.json').write_text(json.dumps(command,indent=2)+'\n')
with (output/'run.log').open('w') as logfile:
    child = subprocess.Popen(command,cwd=root,stdout=logfile,stderr=subprocess.STDOUT,start_new_session=True)
    def stop(*_):
        if child.poll() is None:
            os.killpg(child.pid,signal.SIGTERM)
            try: child.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(child.pid,signal.SIGKILL)
                child.wait(timeout=5)
        raise SystemExit('Area audit stopped before completion.')
    signal.signal(signal.SIGTERM,stop)
    signal.signal(signal.SIGINT,stop)
    try: code = child.wait(timeout=1500)
    except subprocess.TimeoutExpired: stop()
after = fingerprint()
(output/'source-after.json').write_text(json.dumps(after,indent=2)+'\n')
same = before == after
log_clean = not any(token in (output/'run.log').read_text() for token in ('SCRIPT ERROR:','Parse Error:','ERROR:'))
manifest_path = output/'manifest.json'
manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
pngs = {}
for item in manifest.get('images',[]):
    path = output/item['file']
    if not path.is_file(): raise SystemExit('Missing declared PNG '+str(path))
    pngs[item['file']] = hashlib.sha256(path.read_bytes()).hexdigest()
receipt = {'source_stable':same,'source_inputs':len(before),'exit_code':code,'clean_log':log_clean,
           'manifest_valid':manifest.get('valid',False),'png_sha256':pngs,
           'git_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),
           'accepted':code==0 and same and log_clean and bool(manifest.get('valid'))}
(output/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
print('AREA_AUDIT_RECEIPT '+str(output)+' accepted='+str(receipt['accepted']),flush=True)
raise SystemExit(0 if receipt['accepted'] else 1)
PY
TASK_RUN_PID=$!
wait "$TASK_RUN_PID"
TASK_RUN_PID=""

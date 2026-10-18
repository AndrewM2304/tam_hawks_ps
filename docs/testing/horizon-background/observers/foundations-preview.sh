#!/usr/bin/env bash
set -euo pipefail
cd /workspace/tam_hawks_ps
TASK_CAPTURE_OUTPUT="${1:?output directory required}"
mkdir -p "$TASK_CAPTURE_OUTPUT"
TASK_CAPTURE_DISPLAY_PID=""
cleanup() {
  if [[ -n "$TASK_CAPTURE_DISPLAY_PID" ]]; then
    kill -TERM "$TASK_CAPTURE_DISPLAY_PID" 2>/dev/null || true
    wait "$TASK_CAPTURE_DISPLAY_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT
/usr/lib/xorg/Xorg -displayfd 3 -config /workspace/tam_hawks_ps/tools/xorg-dummy.conf \
  -logfile "$TASK_CAPTURE_OUTPUT/xorg.log" -noreset -nolisten tcp \
  3>"$TASK_CAPTURE_OUTPUT/display" >"$TASK_CAPTURE_OUTPUT/xorg-console.log" 2>&1 &
TASK_CAPTURE_DISPLAY_PID=$!
for attempt in {1..50}; do
  [[ -s "$TASK_CAPTURE_OUTPUT/display" ]] && break
  kill -0 "$TASK_CAPTURE_DISPLAY_PID" 2>/dev/null || exit 1
  sleep .1
done
export DISPLAY=":$(cat "$TASK_CAPTURE_OUTPUT/display")"
export LIBGL_ALWAYS_SOFTWARE=1
# Four-core cgroup quota; reserve one core for main/Xorg instead of oversubscribing.
export LP_NUM_THREADS=3
python3 - "$TASK_CAPTURE_OUTPUT" <<'PY'
from pathlib import Path
import hashlib,json,os,signal,subprocess,sys,time
from datetime import datetime
from zoneinfo import ZoneInfo
from PIL import Image
root=Path.cwd();out=Path(sys.argv[1]).resolve()
def fingerprint():
 files=[root/'project.godot',root/'.local/horizon-background/foundations-preview.gd',root/'.local/horizon-background/foundations-preview.sh',root/'.local/horizon-background/views.gd']
 files += [p for folder in ('game','tests','tools') for p in (root/folder).rglob('*') if p.is_file() and '__pycache__' not in p.parts]
 return {str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(files)}
cpu_stat_before=Path('/sys/fs/cgroup/cpu.stat').read_text()
before=fingerprint();(out/'source-before.json').write_text(json.dumps(before,indent=2)+'\n')
command=['./tools/run.sh','--rendering-method','gl_compatibility','--windowed','--resolution','1280x800','--disable-vsync','--audio-driver','Dummy','--script','.local/horizon-background/foundations-preview.gd','--',str(out)]
started=datetime.now(ZoneInfo('Europe/London')).isoformat();wall=time.monotonic()
with (out/'engine.log').open('w') as log:
 child=subprocess.Popen(command,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
 def stop(*_):
  if child.poll() is None:
   os.killpg(child.pid,signal.SIGTERM)
   try:child.wait(timeout=10)
   except subprocess.TimeoutExpired:os.killpg(child.pid,signal.SIGKILL);child.wait(timeout=5)
  raise SystemExit('Bounded compact capture stopped')
 signal.signal(signal.SIGTERM,stop);signal.signal(signal.SIGINT,stop)
 try:code=child.wait(timeout=3000)
 except subprocess.TimeoutExpired:stop()
after=fingerprint();(out/'source-after.json').write_text(json.dumps(after,indent=2)+'\n')
log=(out/'engine.log').read_text();clean=not any(s in log for s in ['SCRIPT ERROR','ERROR:','Parse Error'])
data=json.loads((out/'capture.json').read_text()) if (out/'capture.json').is_file() else {}
images={}
for p in sorted(out.glob('*.png')):
 with Image.open(p) as im:im.load();assert im.size==(1280,800)
 images[p.name]=hashlib.sha256(p.read_bytes()).hexdigest()
valid=code==0 and before==after and clean and data.get('valid') and len(images)==12
receipt={'started_london':started,'completed_london':datetime.now(ZoneInfo('Europe/London')).isoformat(),
 'wall_seconds':time.monotonic()-wall,'source_inputs':len(before),'source_stable':before==after,
 'exit_code':code,'clean_log':clean,'image_sha256':images,'valid':valid,
 'cgroup_cpu_stat_before':cpu_stat_before,'cgroup_cpu_stat_after':Path('/sys/fs/cgroup/cpu.stat').read_text(),
 'render_environment':{'LIBGL_ALWAYS_SOFTWARE':os.environ.get('LIBGL_ALWAYS_SOFTWARE'),'LP_NUM_THREADS':os.environ.get('LP_NUM_THREADS'),'cpu_max':Path('/sys/fs/cgroup/cpu.max').read_text().strip(),'cpuset':Path('/sys/fs/cgroup/cpuset.cpus.effective').read_text().strip()},
 'command':command,'git_head':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),
 'limits':'Native settled production chase observers; not moving play, human fun or target-Mac timings.'}
(out/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(receipt,indent=2),flush=True)
raise SystemExit(0 if valid else 1)
PY

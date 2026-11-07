from pathlib import Path
import os,json,hashlib,datetime,subprocess,time,re,sys
R=Path.cwd(); E=R/'.local/fitted-rig-admission'/sys.argv[1];P=E/'project';RA=R/'.local/rider-fit-staging/project/game/art/rider'
def manifest():
 files=[p for b in ['game','tests'] for p in (P/b).rglob('*') if p.is_file()]+[P/'project.godot',P/'pilot.gd',P/(sys.argv[2].removeprefix('res://') if len(sys.argv)>2 else 'pilot.gd')]
 return {str(p.relative_to(P)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(files)}
before=manifest();env=os.environ.copy();xdg=E/'xdg'
for key,name in [('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data')]:
 dest=xdg/name;dest.mkdir(parents=True,exist_ok=True);env[key]=str(dest)
cmd=['godot','--headless','--path',str(P),'--fixed-fps','60','--script',sys.argv[2] if len(sys.argv)>2 else 'res://pilot.gd'];start=datetime.datetime.now(datetime.timezone.utc).isoformat();t=time.monotonic();timedout=False;limit=float(sys.argv[3]) if len(sys.argv)>3 else 90
with (E/'native.log').open('w') as log:
 process=subprocess.Popen(cmd,stdout=log,stderr=subprocess.STDOUT,env=env)
 print(json.dumps({'pid':process.pid,'utc_start':start,'command':cmd}),flush=True)
 aborted_on_engine_error=False
 seen=0
 while process.poll() is None:
  time.sleep(.05)
  with (E/'native.log').open('rb') as streamed:
   streamed.seek(seen);chunk=streamed.read();seen=streamed.tell()
  if re.search(rb'SCRIPT ERROR|ERROR:|Parse Error',chunk):
   aborted_on_engine_error=True;process.terminate();break
  if time.monotonic()-t>=limit:
   timedout=True;process.kill();break
 code=process.wait(timeout=5)
raw=(E/'native.log').read_text();receipt={'command':cmd,'pid':process.pid,'utc_start':start,'utc_end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'returncode':code,'timed_out':timedout,'os_bound_seconds':limit,'aborted_on_engine_error':aborted_on_engine_error,'wrapper_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'wall_s':time.monotonic()-t,'raw_engine_error':bool(re.search(r'SCRIPT ERROR|ERROR:|Parse Error',raw)),'source_before':before,'source_after':manifest(),'known_overlap':'Root-permitted RA V12 qualitative graphics may overlap; no CPU/GPU exclusivity, performance or M5 claim'};receipt['source_stable']=receipt['source_before']==receipt['source_after'];(E/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps({k:v for k,v in receipt.items() if k not in ['source_before','source_after']}),flush=True)
result_file=P/('semantic-result.json' if len(sys.argv)>2 and sys.argv[2].endswith('controls.gd') else 'result.json')
if result_file.is_file():
 (E/'result.json').write_bytes(result_file.read_bytes())
 print(result_file.read_text())
print(raw[-5500:]);sys.exit(0 if code==0 and not receipt['raw_engine_error'] and receipt['source_stable'] else 1)

from pathlib import Path
import json,hashlib,datetime,os,signal,subprocess,time,re,shutil
R=Path.cwd();B=R/'.local/c04-camera-diagnosis';P=B/'project';O=B/'native-01';O.mkdir(exist_ok=False)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def manifest(base):return {str(p.relative_to(base)):sha(p) for n in ['game','tests','tools'] for p in (base/n).rglob('*') if p.is_file() and '__pycache__' not in p.parts}|{'project.godot':sha(base/'project.godot')}
before=manifest(P);actual_before=manifest(R);before['OBSERVER']=sha(P/'.local/probe.gd');before['WRAPPER']=sha(Path(__file__));(O/'source-before.json').write_text(json.dumps(before,indent=2)+'\n');(O/'actual-source-before.json').write_text(json.dumps(actual_before,indent=2)+'\n');shutil.copy2(P/'.local/probe.gd',O/'probe.gd');shutil.copy2(Path(__file__),O/'run.py')
env=os.environ.copy()
for key in ['DATA','CONFIG','CACHE']:
 q=O/('xdg-'+key.lower());q.mkdir();env['XDG_'+key+'_HOME']=str(q)
cmd=['godot','--headless','--path',str(P),'--audio-driver','Dummy','--fixed-fps','60','--script','.local/probe.gd'];start=datetime.datetime.now(datetime.timezone.utc).isoformat();timer=time.monotonic();reason=None
with (O/'native.log').open('w') as log:
 p=subprocess.Popen(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True);print(json.dumps({'pid':p.pid,'utc':start,'bound_seconds':90,'command':cmd}),flush=True);seen=0;carry=b''
 while p.poll() is None:
  time.sleep(.05)
  with (O/'native.log').open('rb') as f:f.seek(seen);chunk=f.read();seen=f.tell()
  a=carry+chunk;carry=a[-100:]
  if re.search(rb'SCRIPT ERROR:|Parse Error:|ERROR:',a):reason='first raw engine error'
  if time.monotonic()-timer>=90:reason='OS deadline'
  if reason:
   try:os.killpg(p.pid,signal.SIGTERM)
   except ProcessLookupError:pass
   break
 try:code=p.wait(timeout=3)
 except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);code=p.wait(timeout=3)
after=manifest(P);after['OBSERVER']=sha(P/'.local/probe.gd');after['WRAPPER']=sha(Path(__file__));actual_after=manifest(R)
(O/'source-after.json').write_text(json.dumps(after,indent=2)+'\n');(O/'actual-source-after.json').write_text(json.dumps(actual_after,indent=2)+'\n')
if (P/'.local/result.json').is_file():shutil.copy2(P/'.local/result.json',O/'result.json')
raw=(O/'native.log').read_text();receipt={'start_utc':start,'end_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'pid':p.pid,'exit_code':code,'stop_reason':reason,'raw_errors':bool(re.search('SCRIPT ERROR:|Parse Error:|ERROR:',raw)),'private_source_stable':before==after,'actual_source_stable':actual_before==actual_after,'base_source_equal':{k:v for k,v in before.items() if k not in ['OBSERVER','WRAPPER']}==actual_before,'scope':'PRIVATE exact C04 module prefix+bankreturn with late priority1000 read-only current/GTI/native-ray witness. Expected assertion failures retained. Root fullcheck/known qualitative jobs may overlap; no GPU/FPS/M5/whole-suite claim.'};(O/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(receipt,indent=2));print(raw[-1500:]);raise SystemExit(0 if code in [0,1] and not reason and not receipt['raw_errors'] and before==after and actual_before==actual_after else 1)

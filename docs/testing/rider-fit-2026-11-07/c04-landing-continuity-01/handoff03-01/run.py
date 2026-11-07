from pathlib import Path
import hashlib,json,datetime,os,sys,time,signal,subprocess,re,shutil
R=Path.cwd();B=R/'.local/c04-landing-continuity';MODE=sys.argv[1];assert MODE in ['handoff03'];P=B/MODE;O=B/(MODE+'-01');O.mkdir(exist_ok=False)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def source():
 d={str(p.relative_to(P)):sha(p)for n in ['game','tests','tools']for p in(P/n).rglob('*')if p.is_file()and'__pycache__'not in p.parts};d['project.godot']=sha(P/'project.godot');d['OBSERVER']=sha(P/'.local/probe.gd');d['WRAPPER']=sha(Path(__file__));return d
def imported():return {str(p.relative_to(P/'.godot/imported')):sha(p.resolve())for p in sorted((P/'.godot/imported').rglob('*'))if p.is_file()}
def metadata():return {p.name:sha(p.resolve())for p in (P/'.godot').iterdir()if p.is_file()}
def native():
 r=[]
 for row in subprocess.check_output(['ps','-eo','pid=,comm=,args='],text=True).splitlines():
  a=row.strip().split(None,2)
  if len(a)==3 and a[1]in['godot','Xorg','Xvfb']and'<defunct>'not in a[2]:r.append({'pid':int(a[0]),'command':a[2]})
 return r
before=source();imp=imported();meta=metadata();(O/'source-before.json').write_text(json.dumps(before,indent=2)+'\n');(O/'imported-before.json').write_text(json.dumps(imp,indent=2)+'\n');(O/'metadata-before.json').write_text(json.dumps(meta,indent=2)+'\n');shutil.copy2(P/'.local/probe.gd',O/'probe.gd');shutil.copy2(Path(__file__),O/'run.py');shutil.copy2(P/'game/player/skater.gd',O/'skater.gd')
env=dict(os.environ,D022_OUTPUT=str(O/'result.json'))
for n in ['DATA','CONFIG','CACHE']:
 p=O/('xdg-'+n.lower());p.mkdir();env['XDG_'+n+'_HOME']=str(p)
command=['godot','--headless','--path',str(P),'--audio-driver','Dummy','--fixed-fps','60','--script','.local/probe.gd'];start=datetime.datetime.now(datetime.timezone.utc).isoformat();clock=time.monotonic();reason=None;seen={x['pid']:x for x in native()};next_ps=1
with (O/'native.log').open('w')as log:
 p=subprocess.Popen(command,cwd=P,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True);print(json.dumps({'mode':MODE,'pid':p.pid,'start_utc':start,'bound_seconds':100}),flush=True);offset=0;carry=b''
 while p.poll()is None:
  time.sleep(.05)
  with (O/'native.log').open('rb')as f:f.seek(offset);a=carry+f.read();offset=f.tell();carry=a[-100:]
  if re.search(rb'SCRIPT ERROR:|Parse Error:|ERROR:',a):reason='firstrawerror'
  if time.monotonic()-clock>=100:reason='OSdeadline'
  if time.monotonic()-clock>=next_ps:
   for x in native():seen[x['pid']]=x
   next_ps+=1
  if reason:
   try:os.killpg(p.pid,signal.SIGTERM)
   except ProcessLookupError:pass
   break
 try:code=p.wait(timeout=3)
 except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);code=p.wait(timeout=3)
end=datetime.datetime.now(datetime.timezone.utc).isoformat();after=source();impa=imported();metaa=metadata();(O/'source-after.json').write_text(json.dumps(after,indent=2)+'\n');(O/'imported-after.json').write_text(json.dumps(impa,indent=2)+'\n');(O/'metadata-after.json').write_text(json.dumps(metaa,indent=2)+'\n');raw=(O/'native.log').read_text();m=re.search(r'D022_MATCHED_RESULT (\d+) (\d+)',raw)
r={'mode':MODE,'start_utc':start,'end_utc':end,'pid':p.pid,'code':code,'stop':reason,'raw_error':bool(re.search(r'SCRIPT ERROR:|Parse Error:|ERROR:',raw)),'source_stable':before==after,'shared_resolved_imported_stable':imp==impa,'independent_cache_metadata_stable':meta==metaa,'source_count':len(before),'imported_files':len(imp),'summary':[int(m[1]),int(m[2])]if m else None,'native_processes':list(seen.values()),'scope':'Privateactualsourcecopies; baselineonly2pre-C04runtimefilespreserveparentguards. Commonread-onlyinstrumentation/inputoriginalC04. Noeditor/import/writesactualcache. NoFPS/M5/GPUclaim.'};r['eligible_diagnostic']=code in[0,1]and not reason and not r['raw_error']and before==after and imp==impa and meta==metaa and m is not None;(O/'receipt.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r,indent=2));print(raw[-1200:]);raise SystemExit(0 if r['eligible_diagnostic']else 1)

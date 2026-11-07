import datetime,hashlib,json,os,re,signal,subprocess,time
from pathlib import Path
P=Path(__file__).resolve().parent;project=P/'project';O=P/'replay-native-01';O.mkdir(exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def sources():
 files=[]
 for n in ['game','tests','tools','.godot/imported']:
  files.extend(p for p in(project/n).rglob('*')if p.is_file())
 files.extend(project/n for n in ['project.godot','arm_replay.gd','replay_control_visual.gd','arm-replay-input.json'])
 d={str(p.relative_to(project)):sha(p)for p in files};d['OWNER_LAUNCHER']=sha(Path(__file__));d['REPLAY_PLAN']=sha(P/'replay-plan.json');return d
before=sources();(O/'source-before.json').write_text(json.dumps(before,indent=2)+'\n');(O/'known-processes.txt').write_text(subprocess.run(['ps','-eo','pid,ppid,lstart,args'],capture_output=True,text=True).stdout)
start=datetime.datetime.now(datetime.timezone.utc).isoformat();wall=time.monotonic();x=None;g=None;rows=[];failure=None
try:
 with(O/'display').open('w')as disp,(O/'xorg-console.log').open('w')as log:
  x=subprocess.Popen(['/usr/lib/xorg/Xorg','-displayfd',str(disp.fileno()),'-config',str(project/'tools/xorg-dummy.conf'),'-logfile',str(O/'xorg.log'),'-noreset','-nolisten','tcp'],pass_fds=[disp.fileno()],stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
 for _ in range(100):
  if(O/'display').stat().st_size:break
  if x.poll()is not None:raise RuntimeError('Xorgexit')
  time.sleep(.05)
 display=':'+str((O/'display').read_text().strip());env=dict(os.environ,DISPLAY=display,LIBGL_ALWAYS_SOFTWARE='1',LP_NUM_THREADS='4')
 for k,n in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
  q=O/n;q.mkdir(exist_ok=True);env[k]=str(q)
 for variant in ['control','candidate']:
  cmd=['godot','--path',str(project),'--rendering-method','gl_compatibility','--rendering-driver','opengl3','--audio-driver','Dummy','--display-driver','x11','--disable-vsync','--max-fps','144','--script','res://arm_replay.gd','--',variant]
  t=time.monotonic();utc=datetime.datetime.now(datetime.timezone.utc).isoformat()
  with(O/(variant+'.log')).open('w')as log:
   g=subprocess.Popen(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
   print(json.dumps({'variant':variant,'pid':g.pid,'xorg_pid':x.pid,'utc_start':utc,'total_bound_seconds':180,'scope':'Private source-current pose replay, not physics resimulation. No timing, actualcityrender orhuman cadence claim.'}),flush=True)
   while g.poll()is None:
    if time.monotonic()-wall>180:raise TimeoutError('combinedgraphics180s')
    raw=(O/(variant+'.log')).read_text()
    if re.search('SCRIPT ERROR|ERROR:|Parse Error',raw):raise RuntimeError('rawnativeerror'+variant)
    time.sleep(.2)
  raw=(O/(variant+'.log')).read_text();row={'variant':variant,'pid':g.pid,'utc_start':utc,'utc_end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'wall_seconds':time.monotonic()-t,'returncode':g.returncode,'raw_error':bool(re.search('SCRIPT ERROR|ERROR:|Parse Error',raw)),'argv':cmd};rows.append(row)
  if g.returncode or row['raw_error']:raise RuntimeError('nativefailed'+variant)
  (O/'partial-process-receipt.json').write_text(json.dumps(rows,indent=2)+'\n')
except Exception as exc:failure=str(exc)
finally:
 for proc in [g,x]:
  if proc and proc.poll()is None:
   os.killpg(proc.pid,signal.SIGTERM)
   try:proc.wait(timeout=3)
   except subprocess.TimeoutExpired:os.killpg(proc.pid,signal.SIGKILL);proc.wait()
after=sources();(O/'source-after.json').write_text(json.dumps(after,indent=2)+'\n');out={'utc_start':start,'utc_end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'wall_seconds':time.monotonic()-wall,'bound_seconds':180,'xorg_pid':x.pid if x else None,'processes':rows,'failure':failure,'source_count':len(before),'source_unchanged':before==after,'scope':'Private isolated actualMain CURRENTstate replay; sourcephysics/process indices retained, currentRigid/Skin poses applied without newsimulation. No city/interpolation/fullcadence/AAA/M5/FPS acceptance.'};(O/'launch-receipt.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out,indent=2),flush=True)
if failure:
 for v in ['control','candidate']:
  f=O/(v+'.log')
  if f.exists():print(f.read_text()[-3500:])
raise SystemExit(0 if not failure and before==after else 1)

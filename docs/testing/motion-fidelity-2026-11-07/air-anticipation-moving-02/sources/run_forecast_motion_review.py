from pathlib import Path
from PIL import Image
import datetime,gzip,hashlib,json,math,os,re,signal,subprocess,sys,time,collections
R=Path('/workspace/tam_hawks_ps');S=R/'.local/qa-fidelity/forecast-capture-source-01'
O=R/'.local/qa-fidelity/native-review'/sys.argv[1];assert not O.exists();O.mkdir()
view=sys.argv[3] if len(sys.argv)>3 else 'side';assert view in ['side','chase'];mode=sys.argv[2] if len(sys.argv)>2 else 'capture';assert mode in ['parse','capture']
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def inv():return {str(p.relative_to(S)):sha(p) for d in ['game','tests','tools'] for p in sorted((S/d).rglob('*')) if p.is_file() and '__pycache__' not in p.parts}|{'project.godot':sha(S/'project.godot'),'EXTERNAL_WRAPPER':sha(Path(__file__))}
def procs():return subprocess.run(['ps','-C','godot','-o','pid=,ppid=,args='],capture_output=True,text=True).stdout
def stop(p):
 if p and p.poll() is None:
  os.killpg(p.pid,signal.SIGTERM)
  try:p.wait(timeout=5)
  except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait(timeout=5)
concurrent_before=procs();before=inv();(O/'source-before.json').write_text(json.dumps(before,indent=2)+'\n');started=datetime.datetime.now(datetime.timezone.utc).isoformat();t=time.monotonic();records=[];host=[];engine=xorg=None;error=None;code=None;checks=[]
def ck(n,b):checks.append({'name':n,'pass':bool(b)})
try:
 env=dict(os.environ,XDG_DATA_HOME=str(S/'.local/data'),XDG_CONFIG_HOME=str(S/'.local/config'),XDG_CACHE_HOME=str(S/'.local/cache'))
 if mode=='parse':
  cmd=['godot','--headless','--path',str(S),'--check-only','--script','tools/qa_forecast_capture.gd']
  with (O/'parse.log').open('w') as log:
   engine=subprocess.Popen(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True);pid=engine.pid;engine.wait(timeout=60)
  code=engine.returncode;records.append({'command':cmd,'pid':pid,'exit':code});ck('observer parses without raw native errors',code==0 and not re.search(r'SCRIPT ERROR:|Parse Error:|ERROR:',(O/'parse.log').read_text()))
 else:
  for line in procs().splitlines():
   if '--headless' not in line or '--editor' in line:raise RuntimeError('Unleased graphics/import engine '+line)
  with (O/'display').open('w') as d,(O/'xorg-console.log').open('w') as log:
   xorg=subprocess.Popen(['/usr/lib/xorg/Xorg','-displayfd',str(d.fileno()),'-config',str(S/'tools/xorg-dummy.conf'),'-logfile',str(O/'xorg.log'),'-noreset','-nolisten','tcp'],stdout=log,stderr=subprocess.STDOUT,pass_fds=[d.fileno()],start_new_session=True)
   for _ in range(50):
    display=(O/'display').read_text().strip()
    if display:break
    if xorg.poll() is not None:raise RuntimeError('Xorg exited')
    time.sleep(.1)
  if not display:raise RuntimeError('Xorg display missing')
  env.update(DISPLAY=':'+display,LIBGL_ALWAYS_SOFTWARE='1',LP_NUM_THREADS='4')
  cmd=['godot','--path',str(S),'--rendering-method','gl_compatibility','--audio-driver','Dummy','--windowed','--resolution','1280x800','--disable-render-loop','--fixed-fps','60','--script','tools/qa_forecast_capture.gd','--',str(O),view]
  with (O/'engine.log').open('w') as log:
   engine=subprocess.Popen(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True);pid=engine.pid;deadline=min(time.monotonic()+360,float(os.environ.get("QA_LEASE_DEADLINE_MONOTONIC","inf"))-15)
   while engine.poll() is None:
    host.append({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'processes':procs()});(O/'host-observer.json').write_text(json.dumps(host,indent=2)+'\n')
    if time.monotonic()>deadline:raise TimeoutError('360s native graphics deadline; preserve partial frames, reject whole epoch')
    time.sleep(1)
  code=engine.returncode;records.append({'command':cmd,'pid':pid,'exit':code})
  ck('native engine completed clean',code==0 and not re.search(r'SCRIPT ERROR:|Parse Error:|ERROR:|^FAIL:',(O/'engine.log').read_text(),re.M))
  report=json.loads((O/'manifest.json').read_text());ck('complete35images no native assertion failures',report['complete'] and not report['failures'] and ((report['side_count']==32 and report['chase_count']==0) if view=='side' else (report['chase_count']==3 and report['side_count']==0)))
  side=[x for x in report['frames'] if x['view']=='side'];chase=[x for x in report['frames'] if x['view']=='chase']
  selected=side if view=='side' else chase;ck('declared actual successive physics states',len(selected)==(32 if view=='side' else 3) and all(b['state']['physics_frame']-a['state']['physics_frame']==1 for a,b in zip(selected,selected[1:])))
  ck('full original4case native driver explicitly completes',len(re.findall('NOVEMBER_BANK_TOP_MISS physics_start=',(O/'engine.log').read_text()))==4)
  baseline=json.loads(gzip.decompress((R/'docs/testing/motion-fidelity-2026-11-07/air-anticipation-192-native/trace.json.gz').read_bytes()))['frames'];new=report['trace'];fields=['physics','air','wall','floor','body','velocity','sequence']
  differences=[{'row':i,'field':k} for i in range(min(len(new),len(baseline))) for k in fields if new[i][k]!=baseline[i][k]]
  (O/'physical-parity.json').write_text(json.dumps({'baseline_rows':len(baseline),'candidate_rows':len(new),'fields':fields,'differences':differences[:30],'difference_count':len(differences),'exact_equal':len(new)==len(baseline)==1408 and not differences},indent=2)+'\n')
  ck('all1408 physical rows exactly equal corrected192 native epoch',len(new)==len(baseline)==1408 and not differences)
  for row in report['frames']:
   im=Image.open(O/row['file']).convert('RGBA');ck(row['file']+': nativeRGBA byte identity',im.size==(1280,800) and sha(O/row['file']) and hashlib.sha256(im.tobytes()).hexdigest()==row['pixels']['rgba8_sha256'])
   ck(row['file']+': all actor/bone/camera/tick draw brackets identical',row['before']==row['after'])
   ck(row['file']+': currentCanvas',list(im.getpixel(tuple(row['canvas_pixel'])))==row['canvas_expected'])
   cam=row['before']['camera'];proj=row['before']['projection']
   for n,m in enumerate(row['markers']):
    delta=[m['world'][j]-cam['origin'][j] for j in range(3)];local=[sum(delta[j]*cam[k][j] for j in range(3)) for k in ['x','y','z']]+[1.]
    clip=[sum(proj[j][i]*local[j] for j in range(4)) for i in range(4)];p=[(clip[0]/clip[3]*.5+.5)*1280,(.5-clip[1]/clip[3]*.5)*800]
    ck(row['file']+': independent3D projection'+str(n),math.dist(p,m['projected_pixel'])<.001)
    points=[]
    for y in range(max(0,int(p[1])-12),min(800,int(p[1])+13)):
     for x in range(max(0,int(p[0])-12),min(1280,int(p[0])+13)):
      c=im.getpixel((x,y));channel=c[n];others=[c[i] for i in range(3) if i!=n]
      if channel>191.25 and all(channel-o>51 for o in others):points.append((x+.5,y+.5))
    ck(row['file']+': independentnative marker centroid'+str(n),len(points)>=4 and math.dist([sum(v[i] for v in points)/len(points) for i in range(2)],p)<=2.5)
  if view=='side' and all(x['pass'] for x in checks):
   movie=O/'forecast-side-60fps.mp4';subprocess.run(['ffmpeg','-v','error','-nostdin','-y','-framerate','60','-i',str(O/'frames/side-%03d.png'),'-c:v','libx264','-preset','medium','-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',str(movie)],check=True,timeout=60)
   info=json.loads(subprocess.check_output(['ffprobe','-v','error','-select_streams','v:0','-show_entries','stream=width,height,nb_frames,r_frame_rate,duration','-of','json',str(movie)]))['streams'][0];ck('32decoded60Hzmovieframes',int(info['nb_frames'])==32 and info['r_frame_rate']=='60/1');subprocess.run(['ffmpeg','-v','error','-nostdin','-i',str(movie),'-f','null','-'],check=True,timeout=60)
except Exception as e:error=repr(e)
finally:stop(engine);stop(xorg)
if code is None and engine:code=engine.returncode
after=inv();(O/'source-after.json').write_text(json.dumps(after,indent=2)+'\n');ck('all executed source bytes stable',before==after)
receipt={'schema':1,'started_utc':started,'finished_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'elapsed_seconds':time.monotonic()-t,'mode':mode,'view':view,'concurrent_processes_before':concurrent_before,'known_authorized_overlap':'Root explicitly permits named EA/RA qualitative graphics during parser. Actual process rows retained; no timing claim.','commands':records,'source_count':len(before),'source_stable':before==after,'error':error,'checks':checks,'failures':sum(not x['pass'] for x in checks),'eligible':code==0 and not error and all(x['pass'] for x in checks),'limits':'Integrity and narrow native motion replay only. Untimed overlap is retained by process observer, no process-exclusivity, CPU/GPU cost, Mac, whole animation or AAA acceptance.'}
(O/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps({k:v for k,v in receipt.items() if k not in ['checks','commands']},indent=2));print('OUTPUT',O,flush=True);raise SystemExit(0 if receipt['eligible'] else 1)

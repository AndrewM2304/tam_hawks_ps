from pathlib import Path
import datetime,hashlib,json,os,re,signal,subprocess,time
P=Path(__file__).resolve().parent;T=P/'project';O=P/'native-02';O.mkdir(exist_ok=True);C=json.loads((P/'current-copy.json').read_text());sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();pins=list(C['source_sha256'])+list(C['compiled_dependency_sha256'])+['arm_motion_observer.gd']
def sources():return {n:sha(T/n)for n in pins}
start=time.monotonic();rows=[];fail=None;env=os.environ.copy();(O/'known-processes.txt').write_text(subprocess.run(['ps','-eo','pid,ppid,lstart,args'],capture_output=True,text=True).stdout)
for variant in ['control','candidate']:
 src=P/('baseline_visual.gd'if variant=='control'else'skater_visual_candidate.gd');(T/'game/player/skater_visual.gd').write_bytes(src.read_bytes());before=sources();(O/(variant+'-before.json')).write_text(json.dumps(before,indent=2)+'\n')
 for k,n in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
  d=O/variant/n;d.mkdir(parents=True,exist_ok=True);env[k]=str(d)
 stages=[('parse',['godot','--path',str(T),'--headless','--script','res://arm_motion_observer.gd','--check-only'],5),('motion',['godot','--path',str(T),'--headless','--fixed-fps','60','--script','res://arm_motion_observer.gd','--',variant],55)]
 for stage,cmd,limit in stages:
  elapsed=time.monotonic()-start;limit=min(limit,max(0,120-elapsed))
  if limit<=0:fail='combined120second deadline';break
  stamp=datetime.datetime.now(datetime.timezone.utc).isoformat();tick=time.monotonic()
  with(O/(variant+'-'+stage+'.log')).open('w')as log:
   p=subprocess.Popen(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True);print(json.dumps({'variant':variant,'stage':stage,'pid':p.pid,'utc_start':stamp,'bound_seconds':limit,'scope':'Private currentMain native comparison, secondaryflock; actualfull04 knownoverlap, noFPS orpixelproof.'}),flush=True)
   try:code=p.wait(timeout=limit)
   except subprocess.TimeoutExpired:
    os.killpg(p.pid,signal.SIGTERM)
    try:p.wait(timeout=3)
    except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait()
    code=p.returncode;fail=variant+'/'+stage+' timeout'
  raw=(O/(variant+'-'+stage+'.log')).read_text();err=bool(re.search('SCRIPT ERROR|ERROR:|Parse Error',raw));rows.append({'variant':variant,'stage':stage,'pid':p.pid,'start':stamp,'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'seconds':time.monotonic()-tick,'returncode':code,'raw_error':err})
  if code or err or fail:
   fail=fail or variant+'/'+stage+' enginefailure';print(raw[-7000:],flush=True);break
 after=sources();(O/(variant+'-after.json')).write_text(json.dumps(after,indent=2)+'\n')
 if before!=after:fail=variant+' source changed'
 if(T/('arm-'+variant+'.json')).exists():(O/('arm-'+variant+'.json')).write_bytes((T/('arm-'+variant+'.json')).read_bytes())
 if fail:break
report={'processes':rows,'failure':fail,'wall_seconds':time.monotonic()-start,'combined_bound_seconds':120,'scope':'PRIVATE currentMain sevenphase nativeinput/pose comparison only. One sourceVisual diff between serialprocesses, all other copiedsources/cache unchanged. No graphics/FPS/human/M5/AAA acceptance.','utc_end':datetime.datetime.now(datetime.timezone.utc).isoformat()};(O/'launch-receipt.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2),flush=True);raise SystemExit(bool(fail))

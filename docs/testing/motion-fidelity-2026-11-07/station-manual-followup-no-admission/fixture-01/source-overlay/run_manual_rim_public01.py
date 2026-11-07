from pathlib import Path
import datetime,hashlib,json,os,re,signal,subprocess,time
R=Path(__file__).resolve().parent.parent;P=R/'.local/manual-rim-public-source';O=R/'.local/manual-rim-public-01';O.mkdir(exist_ok=False)
def now():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def source():
 names=[Path(__file__).resolve(),P/'project.godot',P/'export_presets.cfg',P/'.local/run_manual_rim.gd']
 for folder in ['game','tests','tools']:names +=[p for p in (P/folder).rglob('*') if p.is_file() and '__pycache__' not in p.parts]
 return {str(p.relative_to(P)) if p.is_relative_to(P) else 'outer/'+p.name:sha(p) for p in sorted(set(names))}
def cache():
 d={p.name:sha(p) for p in sorted((P/'.godot/imported').iterdir()) if p.is_file()}
 for name in ['global_script_class_cache.cfg','uid_cache.bin']:d[name]=sha(P/'.godot'/name)
 return d
controller=P/'game/player/skater.gd';assert sha(controller)=='1ef6cdb7dfe2942d1d3aa8f025d89213e2f1f06500fcfb588b7d18734de27f84'
start=time.monotonic();deadline=start+120;records=[];original=controller.read_bytes();cache_before=cache()
try:
 for label,cap,options,neighbors in [('parser',15,['--check-only'],False),('baseline',35,['--fixed-fps','60'],False),('candidate',70,['--fixed-fps','60'],True)]:
  if label=='candidate':controller.write_bytes((R/'.local/station-manual-proposal-01/payload/game/player/skater.gd').read_bytes())
  before=source();env=os.environ.copy();env['TAM_MANUAL_TRACE']=str(O/(label+'-result.json'));env['TAM_MANUAL_NEIGHBORS']='1' if neighbors else '0'
  command=[str(P/'tools/run.sh'),'--headless']+options+['--script','res://.local/run_manual_rim.gd'];log=O/(label+'.log')
  item={'label':label,'start':now(),'cap_seconds':cap,'command':command,'source_before':before,'expected':'one real model-clearance failure' if label=='baseline' else 'exit0/rawclean/all assertions pass'};stop=None
  with log.open('wb') as output:
   proc=subprocess.Popen(command,env=env,stdout=output,stderr=subprocess.STDOUT,start_new_session=True);item['pid']=proc.pid;print(json.dumps({k:v for k,v in item.items() if k!='source_before'}),flush=True);limit=min(deadline,time.monotonic()+cap)
   while proc.poll() is None:
    if re.search(rb'ERROR:|Parse Error:',log.read_bytes()):stop='first raw error';break
    if time.monotonic()>limit:stop='declared epoch/120-second total bound';break
    time.sleep(.05)
   if proc.poll() is None:
    os.killpg(proc.pid,signal.SIGTERM)
    try:proc.wait(timeout=1)
    except subprocess.TimeoutExpired:os.killpg(proc.pid,signal.SIGKILL);proc.wait()
  raw=log.read_text();after=source();result=json.loads((O/(label+'-result.json')).read_text()) if (O/(label+'-result.json')).exists() else None
  item.update(end=now(),exit=proc.returncode,stop=stop,raw_errors=bool(re.search(r'ERROR:|Parse Error:',raw)),source_after=after,source_stable=before==after,result={'passed':result['passed'],'failed':result['failed']} if result else None,log_sha256=sha(log))
  records.append(item)
  if stop or item['raw_errors'] or not item['source_stable'] or (label=='parser' and proc.returncode!=0):break
finally:
 controller.write_bytes(original)
 cache_after=cache();receipt={'epochs':records,'cache_before':cache_before,'cache_after':cache_after,'cache_stable':cache_before==cache_after,'scope':'PRIVATE fresh exact c0cb41a game/tests/tools copy plus new actual-bank public fixture; unchanged native Main geometry. Original1ef baseline then one-file09fe candidate; production controller restored only after processes stop. Source/cache bound. Runtime coordinates/velocity seeded once before mapped Manual input, no per-frame physical writes. No visual/M5/performance claim.'}
 (O/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps({**{k:v for k,v in receipt.items() if k not in ['epochs','cache_before','cache_after']},'epochs':[{k:v for k,v in x.items() if k not in ['source_before','source_after']} for x in records]},indent=2))
print((O/'candidate.log').read_text()[-5000:] if (O/'candidate.log').exists() else (O/'baseline.log').read_text()[-5000:] if (O/'baseline.log').exists() else (O/'parser.log').read_text())

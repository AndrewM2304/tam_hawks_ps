from pathlib import Path
import datetime,hashlib,json,os,subprocess,time,signal
root=Path('/workspace/tam_hawks_ps');project=root/'.local/legacy-native-current-source';out=project/'.local/native-01';out.mkdir(exist_ok=False)
def utc():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def inventory():
 files=[project/'project.godot']
 files += [p for directory in ('game','tests','tools') for p in (project/directory).rglob('*') if p.is_file() and '.godot' not in p.parts]
 files += [project/'.local/legacy_generic_grind_probe.gd']
 return {str(p.relative_to(project)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(files)}
def godots():
 rows=[]
 for row in subprocess.check_output(['ps','-eo','pid=,comm=,args='],text=True).splitlines():
  parts=row.strip().split(None,2)
  if len(parts)==3 and parts[1]=='godot':rows.append({'pid':int(parts[0]),'args':parts[2]})
 return rows
start=time.monotonic();deadline=start+60;before=inventory();epochs=[];overlap=godots();env=os.environ.copy();profile=Path('/tmp/tam-motion-legacy-current');profile.mkdir(exist_ok=True)
for key,sub in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
 (profile/sub).mkdir(exist_ok=True);env[key]=str(profile/sub)
def run(name,args,limit):
 path=out/(name+'.log');t=time.monotonic();record={'name':name,'command':args,'utc_start':utc(),'hard_limit_s':limit};timed=False;error=False
 with path.open('wb') as output:
  process=subprocess.Popen(args,stdout=output,stderr=subprocess.STDOUT,env=env,start_new_session=True);record['pid']=process.pid
  with path.open('rb') as reader:
   carry=b''
   while process.poll() is None:
    data=reader.read();check=carry+data;carry=check[-120:]
    if b'SCRIPT ERROR:' in check or b'\nERROR:' in check:error=True;break
    if time.monotonic()-t>limit or time.monotonic()>deadline:timed=True;break
    time.sleep(.05)
  if process.poll() is None:
   os.killpg(process.pid,signal.SIGTERM)
   try:process.wait(timeout=1)
   except subprocess.TimeoutExpired:os.killpg(process.pid,signal.SIGKILL);process.wait()
  status=process.returncode
 raw=path.read_bytes();error=error or b'SCRIPT ERROR:' in raw or b'\nERROR:' in raw
 record.update({'utc_end':utc(),'returncode':status,'timed_out':timed,'raw_engine_error':error,'wall_s':time.monotonic()-t,'raw_log_sha256':hashlib.sha256(raw).hexdigest()});epochs.append(record);print(json.dumps(record),flush=True)
 return status==0 and not timed and not error
base=['godot','--headless','--path',str(project),'--audio-driver','Dummy']
okay=run('parser',base+['--check-only','--script','res://.local/legacy_generic_grind_probe.gd'],min(5,max(.1,deadline-time.monotonic())))
if okay:okay=run('native',base+['--fixed-fps','60','--script','res://.local/legacy_generic_grind_probe.gd'],max(.1,deadline-time.monotonic()))
after=inventory();resultpath=project/'.local/legacy-generic-grind-native.json';result={}
if resultpath.exists():
 result=json.loads(resultpath.read_text());(out/'native-result.json').write_bytes(resultpath.read_bytes())
summary=[]
for c in result.get('cases',[]):
 material=[m for row in c.get('rows',[]) for m in row['drawn_material_tests']]
 summary.append({'requested_id':c['requested_id'],'available':c.get('available',False),'actual_physics_samples':len(c.get('rows',[])),'captured_ids':sorted({r['captured_id'] for r in c.get('rows',[])}),'styles':sorted({r['style'] for r in c.get('rows',[])}),'drawn_intrusion_frames':sum(any(m['unique_drawn_vertices_inside_by_over1mm']>0 for m in row['drawn_material_tests']) for row in c.get('rows',[])),'maximum_drawn_depth_m':max([m['maximum_depth_m'] for m in material],default=0),'component_hit_frames':sum(bool(r['native_component_hits']) for r in c.get('rows',[])),'unknown_saturated_frames':sum(r['hit_buffer_saturated_unknown'] for r in c.get('rows',[])),'camera_samples':len(c.get('completed_frame_camera',[])),'camera_clear':all(r['clear'] for r in c.get('completed_frame_camera',[])) if c.get('completed_frame_camera') else None,'new_bails':c.get('new_bails'),'queries_read_only':all(r['queries_read_only'] for r in c.get('rows',[]))})
receipt={'utc_end':utc(),'source_before':before,'source_after':after,'source_stable':before==after,'source_preparation':'../source-preparation.json','epochs':epochs,'authorized_qualitative_overlap_at_start':overlap,'godot_processes_at_end':godots(),'scope':'bounded declared airborne start/momentum then mappedGrind; whole ordinaryMain, no ordinary approach/visual/M5/cost acceptance; unknown/missing catch cannot pass','elapsed_is_metadata_not_performance':True,'cases':summary,'complete':okay and before==after and len(summary)==4}
(out/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps({k:v for k,v in receipt.items() if k not in ('source_before','source_after')},indent=2),flush=True)
raise SystemExit(0 if receipt['complete'] else 1)

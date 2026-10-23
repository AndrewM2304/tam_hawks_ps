"""Audit final local source, accepted receipts, pinned controls and original frames."""
from pathlib import Path
import gzip,hashlib,json,re,subprocess,sys
root=Path.cwd();base=root/'docs/testing/named-grinds';e=base/'evidence'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):
 if not p.exists():p=p.with_suffix(p.suffix+'.gz')
 return json.loads(gzip.decompress(p.read_bytes()) if p.suffix=='.gz' else p.read_text())
core={str(p.relative_to(root)):sha(p) for p in sorted([root/'project.godot']+[p for d in ['game','tests','tools'] for p in(root/d).rglob('*') if p.is_file() and '__pycache__' not in p.parts])}
accepted=sys.argv[1:];assert accepted and 'required-02' in accepted
receipts={};comparisons={};captures={};unloaded_exceptions={}
def closure(entries):
 pending=list(entries);seen=set()
 while pending:
  name=pending.pop()
  if name in seen:continue
  seen.add(name);f=root/name
  if f.exists() and f.suffix in ['.gd','.tscn']:pending+=re.findall(r'res://([^"\s\)]+\.(?:gd|tscn))',f.read_text())
 return seen
for name in accepted:
 folder=e/name;r=read(folder/'receipt.json');m=read(folder/'source-before.json')
 assert r['valid'] and r['clean_log'] and r['source_stable'] and r['exit_code']==0,name
 assert m==read(folder/'source-after.json'),name
 assert r['result_counts'] and all(int(p)>0 and int(f)==0 for p,f in r['result_counts']),name
 loaded=closure([arg for arg in r['command'] if arg.endswith('.gd')])
 changed_core={p for p,h in core.items() if m.get(p)!=h}
 allowed_core={'tests/grind_index_tests.gd'} if not name.startswith('required-') else set()
 assert changed_core<=allowed_core and not changed_core.intersection(loaded),(name,'loaded core differs',changed_core)
 unloaded_exceptions[name]={'changed_unloaded_core':sorted(changed_core),'reason':'Only the later rail-index fixture correction may differ, and it must be outside the admitted run res script/scene closure. Final required source has no exception.'}
 for p,h in m.items():
  if p not in core:assert (root/p).exists() and sha(root/p)==h,(name,p)
 if (folder/'observer-receipt.json').exists():
  assert read(folder/'observer-receipt.json')['stable'],name
  a=read(folder/'observers-before.json');assert a==read(folder/'observers-after.json'),name
  changed={p for p,h in a.items() if sha(root/p)!=h}
  allowed={'docs/testing/named-grinds/observers/capture.gd','docs/testing/named-grinds/observers/audit.py'}
  loaded=closure([arg for arg in r['command'] if arg.endswith('.gd')])
  assert changed<=allowed and not changed.intersection(loaded),(name,'loaded observer differs',changed)
  unloaded_exceptions[name].update({'changed_unloaded_observers':sorted(changed),'conservative_res_closure':sorted(loaded),'observer_reason':'Capture-only type annotation/rising-air snapshot timing and audit closure accounting may follow an earlier timing run. Neither may be in its loaded res script/scene closure; all loaded runtime inputs remain identical.'})
 if (folder/'comparison.json').exists():
  c=read(folder/'comparison.json');assert c['pass'] and c['workload_pass'] and all(v['pass'] for v in c['strict_render_gates'].values()),name
  comparisons[name]=c
 if (folder/'capture.json').exists():
  c=read(folder/'capture.json');assert not c['errors'] and len(c['images'])==8 and all(t['valid'] for t in c['trials']),name
  assert all(i['airborne'] and not i['grinding'] and i['body_position'][1]>1.20 and i['velocity'][1]>0 and abs(i['air_spin'])<.001 for i in c['images'] if '-release' in i['file']),name
  captures[name]=c
 receipts[name]=r
assert comparisons and captures
rejected={}
for name in ['routes-01','compare-01','compare-02','capture-01','required-01']:
 folder=e/name;r=read(folder/'receipt.json');assert not r['valid'] and r['source_stable'],name
 assert read(folder/'source-before.json')==read(folder/'source-after.json'),name
 if name=='routes-01':
  for path,h in read(folder/'source-before.json').items():
   if not path.startswith(('game/','tests/','tools/')):continue
   original=subprocess.run(['git','show','ef0eb9f:'+path],stdout=subprocess.PIPE,stderr=subprocess.DEVNULL)
   if original.returncode==0 and hashlib.sha256(original.stdout).hexdigest()==h:continue
   snapshot=folder/'loaded-source'/(path+'.txt');assert snapshot.exists() and sha(snapshot)==h,(name,path)
 elif name=='required-01':
  previous=read(folder/'source-before.json');changed={p for p,h in core.items() if previous.get(p)!=h}
  assert changed=={'tests/grind_index_tests.gd'},changed
  assert hashlib.sha256(subprocess.check_output(['git','show','ef0eb9f:tests/grind_index_tests.gd'])).hexdigest()==previous['tests/grind_index_tests.gd']
  assert r['result_counts']==[['2556','1']]
 else:
  for path,h in read(folder/'observers-before.json').items():
   snapshot=folder/'loaded-observers'/(Path(path).name+'.txt');assert snapshot.exists() and sha(snapshot)==h,(name,path)
 rejected[name]={'counts':r['result_counts'],'exit_code':r['exit_code'],'source_stable':True,'retained_loaded_source_verified':True}
for name,path in [('baseline_main.gd','game/main.gd'),('baseline_skater.gd','game/player/skater.gd'),('baseline_grind_ride.gd','game/tricks/grind_ride.gd')]:
 actual=(base/'observers'/name).read_text().replace('res://docs/testing/named-grinds/observers/baseline_skater.gd','res://game/player/skater.gd').replace('res://docs/testing/named-grinds/observers/baseline_grind_ride.gd','res://game/tricks/grind_ride.gd')
 assert actual==subprocess.check_output(['git','show','ef0eb9f:'+path],text=True),name
for kind,source in [('original',(base/'observers/baseline_main.gd').read_text()),('current',(root/'game/main.gd').read_text())]:
 actual=(base/'observers'/(kind+'_timed_main.gd')).read_text().replace('res://docs/testing/named-grinds/observers/'+kind+'_timed_skater.gd','res://docs/testing/named-grinds/observers/baseline_skater.gd' if kind=='original' else 'res://game/player/skater.gd')
 assert actual==source,kind
ids=re.findall(r'\{"id": "([a-z0-9_]+)"',(root/'game/tricks/trick_catalog.gd').read_text());assert len(ids)==len(set(ids))==26 and read(base/'catalog-ids.json')['current_ids']==ids
assert (root/'game/levels/skate_edges.gd').read_bytes()==subprocess.check_output(['git','show','ef0eb9f:game/levels/skate_edges.gd'])
pattern=re.compile(r'^### (M\d\d-\d\d\d)\b[^\n]*\n.*?(?=^### M\d\d-\d\d\d\b|^## [^#]|\Z)',re.M|re.S)
def tasks(s):return {m[1]:hashlib.sha256(m[0].encode()).hexdigest() for m in pattern.finditer(s)}
a=tasks(subprocess.check_output(['git','show','ef0eb9f:docs/planning/BACKLOG.md'],text=True));assert len(a)==75 and a==tasks((root/'docs/planning/BACKLOG.md').read_text())
line=next(x[len('PNG_AUDIT '):] for x in (e/'png-audit/console.log').read_text().splitlines() if x.startswith('PNG_AUDIT '));png=json.loads(line);assert not png['failures'];images={}
for row in png['decoded']:
 f=root/row['file'];assert f.is_relative_to(e) and sha(f)==row['sha256'] and (row['width'],row['height'])==(1280,800);images[row['file']]=row['sha256']
assert len(images)==16 and set(images)=={str(p.relative_to(root)) for p in e.rglob('*.png')}
links=[]
for f in [base/'README.md',root/'docs/planning/NAMED-GRINDS-2026-10-23.md',root/'docs/architecture/decisions/ADR-029-named-grind-contact-contract.md',root/'docs/planning/OUTSTANDING-2026-10-23.md']:
 for target in re.findall(r'(?<!!)\[[^\]]+\]\(([^)]+)\)',f.read_text()):
  if '://' in target:continue
  p=(f.parent/target.split('#')[0]).resolve();assert p.exists() or p==base/'audit.json',(f,target);links.append(str(p.relative_to(root)))
result={'valid':True,'current_core_inputs':len(core),'core_manifest':core,'accepted_receipts':receipts,'verified_rejected_evidence':rejected,'explicit_unloaded_observer_exceptions':unloaded_exceptions,'comparisons':comparisons,'captures':captures,'original_native_pngs':images,'catalog_ids':ids,'unchanged_complete_backlog_bodies':75,'semantic_edges_byte_identical_to_original':True,'local_links_checked':len(links),'observer_sha256':{str(p.relative_to(root)):sha(p) for p in sorted((base/'observers').rglob('*')) if p.is_file() and p.suffix in ('.gd','.py','.sh')},'artifacts':{str(p.relative_to(root)):sha(p) for p in sorted(e.rglob('*')) if p.is_file()},'limits':'Local root integration and independently authored test logic, not independent visual-QE/owner acceptance. Whole-board bounding box conservatively limits named eligibility; semantic world-solid edges and changing-grade radial joints remain generic. No full grind roster, THPS3 constant verification, wallrides/plants/predictivelanding, physical DualSense, standalone export, cold native memory, fully isolated performance/long-play stutter or final art certification.'}
(base/'audit.json').write_text(json.dumps(result,indent=2)+'\n');print('AUDIT PASS',len(core),'core inputs,',len(images),'native PNGs,26catalog IDs,75unchanged full tasks')

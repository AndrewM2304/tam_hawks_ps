"""Verify final code, admitted evidence, source-only exceptions and all trick IDs."""
from pathlib import Path
import gzip,hashlib,json,re,subprocess
ROOT=Path.cwd();B=ROOT/'docs/testing/flat-ollie';E=B/'evidence'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):
 if not p.exists():p=p.with_suffix(p.suffix+'.gz')
 return json.loads(gzip.decompress(p.read_bytes())if p.suffix=='.gz'else p.read_text())
core={str(p.relative_to(ROOT)):sha(p)for p in sorted([ROOT/'project.godot']+[p for d in ['game','tests','tools']for p in(ROOT/d).rglob('*')if p.is_file()and '__pycache__'not in p.parts])}
# Conservatively follow all explicit res://script/scene references, including
# references in unexecuted functions. An allowed test must remain outside this set.
def closure(entries):
 pending=list(entries);seen=set()
 while pending:
  name=pending.pop()
  if name in seen:continue
  seen.add(name);file=ROOT/name
  if file.exists()and file.suffix in ['.gd','.tscn']:
   pending+=re.findall(r'res://([^"\s\)]+\.(?:gd|tscn))',file.read_text())
 return seen
accepted=['cat-probe-02','compact-02','focused-03','controls-03','compare-04','compare-05','capture-03','ramp-capture-02','required-02','png-audit']
receipts={};exceptions={}
for name in accepted:
 f=E/name;r=read(f/'receipt.json');m=read(f/'source-before.json')
 assert r['valid']and r['clean_log']and r['source_stable']and r['exit_code']==0,name
 assert m==read(f/'source-after.json')and r['result_counts']and all(int(p)>0 and int(x)==0 for p,x in r['result_counts']),name
 diff={p for p,h in core.items()if m.get(p)!=h}
 allowed={'tests/compact_clyde_lines_tests.gd','tests/camera_turn_review_tests.gd'}if name=='cat-probe-02'else ({'tests/camera_turn_review_tests.gd'}if name=='compact-02'else set())
 assert diff<=allowed,(name,diff)
 for path,h in m.items():
  if path not in core and (ROOT/path).is_file():assert sha(ROOT/path)==h,(name,'changed recorded tool',path)
 entry=[a for a in r['command']if a.endswith('.gd')and(ROOT/a).exists()]
 loaded=closure(entry)
 assert not(diff&loaded),(name,'changed source was loaded')
 exceptions[name]={'changed_inputs':sorted(diff),'loaded_res_paths':sorted(loaded),'reason':'Cat-probe02 predates compact/camera fixture changes; compact02 predates the camera sampler. Each difference must be outside its conservative res dependency closure. All other admitted core inputs exactly match final source.'}
 receipts[name]=r
comparisons={name:read(E/name/'comparison.json')for name in ['compare-04','compare-05']}
assert all(c['pass']and c['flat_motion_gate']for c in comparisons.values())
comp=comparisons['compare-05']
for label in ['original-before','candidate','original-after']:
 d=read(E/'compare-05'/(label+'.json'));assert not d['errors']and d['unsafe_frames']==0 and d['jumps']==5 and len(d['flights'])==5 and d['bails']==0
capture=read(E/'capture-03/capture.json');assert not capture['errors']and all(t['valid']for t in capture['trials'])and len(capture['images'])==20
assert read(E/'ramp-capture-02/pop.json')['valid']
for local,source in [('baseline_main.gd','game/main.gd'),('baseline_skater.gd','game/player/skater.gd'),('baseline_visual.gd','game/player/skater_visual.gd'),('baseline_clips.gd','game/player/trick_animation.gd')]:
 actual=(B/'observers'/local).read_text()
 for old,new in [('baseline_skater.gd','game/player/skater.gd'),('baseline_visual.gd','game/player/skater_visual.gd'),('baseline_clips.gd','game/player/trick_animation.gd')]:actual=actual.replace('res://docs/testing/flat-ollie/observers/'+old,'res://'+new)
 assert actual==subprocess.check_output(['git','show','de6505d:'+source],text=True),local
ids=re.findall(r'\{"id": "([a-z0-9_]+)"',(ROOT/'game/tricks/trick_catalog.gd').read_text());assert len(ids)==len(set(ids))==24
report=(ROOT/'docs/research/TRICK-STYLE-AUDIT-2026-10-23.md').read_text();assert all('`'+i+'`'in report for i in ids)
source=read(ROOT/'docs/research/TRICK-STYLE-SOURCES-2026-10-23.json');assert source['catalog_ids']==ids
assert all(hashlib.sha256(subprocess.check_output(['git','show','de6505d:'+p])).hexdigest()==h for p,h in source['baseline_source_sha256'].items())
pattern=re.compile(r'^### (M\d\d-\d\d\d)\b[^\n]*\n.*?(?=^### M\d\d-\d\d\d\b|^## [^#]|\Z)',re.M|re.S)
def tasks(s):return{m[1]:hashlib.sha256(m[0].encode()).hexdigest()for m in pattern.finditer(s)}
a=tasks(subprocess.check_output(['git','show','de6505d:docs/planning/BACKLOG.md'],text=True));assert len(a)==75 and a==tasks((ROOT/'docs/planning/BACKLOG.md').read_text())
line=next(x[len('PNG_AUDIT '):]for x in(E/'png-audit/console.log').read_text().splitlines()if x.startswith('PNG_AUDIT '));png=json.loads(line);assert not png['failures'];images={}
for row in png['decoded']:
 p=ROOT/row['file'];assert p.is_relative_to(E)and sha(p)==row['sha256']and(row['width'],row['height'])==(1280,800);images[row['file']]=row['sha256']
assert set(images)=={str(p.relative_to(ROOT))for p in E.rglob('*.png')}
for path,h in core.items():
 snapshot=E/'final-source'/(path+'.txt')
 if snapshot.exists():assert sha(snapshot)==h,path
links=[]
for file in[B/'README.md',ROOT/'docs/research/TRICK-STYLE-AUDIT-2026-10-23.md',ROOT/'docs/planning/TRICK-FIDELITY-2026-10-23.md']:
 for target in re.findall(r'(?<!!)\[[^\]]+\]\(([^)]+)\)',file.read_text()):
  if '://'in target:continue
  p=(file.parent/target.split('#')[0]).resolve();assert p.exists()or p==B/'audit.json',(file,target);links.append(str(p.relative_to(ROOT)))
result={'valid':True,'observer_and_analysis_sha256':{str(p.relative_to(ROOT)):sha(p)for p in sorted((B/'observers').glob('*'))if p.is_file()},'current_core_inputs':len(core),'core_manifest':core,'accepted_receipts':receipts,'explicit_unloaded_test_and_UID_exceptions':exceptions,'comparison':comp,'two_consecutive_strict_comparisons':comparisons,'timing_isolation':'Background CPU bursts are retained in system-load.jsonl; fully isolated rendering/long-play stutter admission remains open. Earlier failed strict p99 runs are rejected and retained.','capture_trials':capture['trials'],'native_original_pngs':images,'catalog_ids_audited':ids,'unchanged_complete_backlog_bodies':75,'local_links_checked':len(links),'artifacts':{str(p.relative_to(ROOT)):sha(p)for p in sorted(E.rglob('*'))if p.is_file()},'limits':'Source/trick-family audit and root self-review, not original-game constant verification, complete THPS3 roster parity, new named grinds/wallrides/plants/self-righting, independent QE, owner feel, physical controllers/exports, long-play stutter or final art acceptance.'}
(B/'audit.json').write_text(json.dumps(result,indent=2)+'\n');print('AUDIT PASS',len(core),'core inputs,',len(images),'native PNGs,24catalog IDs,75full task bodies')

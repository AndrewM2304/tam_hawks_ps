"""Audit final source, unchanged task bodies and original native evidence."""
from pathlib import Path
import gzip,hashlib,json,re,subprocess
ROOT=Path.cwd();BASE=ROOT/'docs/testing/bail-pose';E=BASE/'evidence'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):
 if not p.exists():p=p.with_suffix(p.suffix+'.gz')
 return json.loads(gzip.decompress(p.read_bytes())if p.suffix=='.gz'else p.read_text())
paths=[ROOT/'project.godot']+[p for d in ['game','tests','tools']for p in(ROOT/d).rglob('*')if p.is_file()and '__pycache__'not in p.parts]
core={str(p.relative_to(ROOT)):sha(p)for p in sorted(paths)}
accepted=['required-final-02','recovery-capture-07','hud-capture-03','pop-capture-02','compare-04','recovery-compare-04','png-audit-final']
receipts={}
for name in accepted:
 folder=E/name;r=read(folder/'receipt.json');m=read(folder/'source-before.json')
 assert r['valid']and r['exit_code']==0 and r['clean_log']and r['source_stable'],name
 assert r['result_counts']and all(int(p)>0 and int(f)==0 for p,f in r['result_counts']),name
 assert all(m.get(p)==h for p,h in core.items()),name
 assert m==read(folder/'source-after.json'),name
 receipts[name]=r
for name in ['compare-04','recovery-compare-04']:assert read(E/name/'comparison.json')['pass'],name
compare=read(E/'compare-04/comparison.json');assert compare['rows_compared']==1933 and not compare['any_velocity_mismatch'] and compare['max_position_error_m']==0
capture=read(E/'recovery-capture-07/recovery.json');assert not capture['errors']and len(capture['trials'])==2
assert all(t['stages']==['before','fall','slide','get_up','ready']and t['bails']==1 and t['unsafe']==0 and t['maximum_step_m']<.3 for t in capture['trials'])
assert read(E/'pop-capture-02/pop.json')['valid']
# Exact original project controls. Only import redirects are allowed.
original={'baseline_visual.gd':'game/player/skater_visual.gd','baseline_skater.gd':'game/player/skater.gd','baseline_main.gd':'game/main.gd','baseline_hud.gd':'game/ui/hud.gd'}
for local,source in original.items():
 expected=subprocess.check_output(['git','show','83758c3:'+source],text=True)
 actual=(BASE/'observers'/local).read_text()
 if local=='baseline_skater.gd':actual=actual.replace('res://docs/testing/bail-pose/observers/baseline_visual.gd','res://game/player/skater_visual.gd')
 if local=='baseline_main.gd':actual=actual.replace('res://docs/testing/bail-pose/observers/baseline_skater.gd','res://game/player/skater.gd').replace('res://docs/testing/bail-pose/observers/baseline_hud.gd','res://game/ui/hud.gd')
 assert actual==expected,local
pattern=re.compile(r'^### (M\d\d-\d\d\d)\b[^\n]*\n.*?(?=^### M\d\d-\d\d\d\b|^## [^#]|\Z)',re.M|re.S)
def tasks(s):return {m[1]:hashlib.sha256(m[0].encode()).hexdigest()for m in pattern.finditer(s)}
old=tasks(subprocess.check_output(['git','show','4eb9c03:docs/planning/BACKLOG.md'],text=True));assert len(old)==75 and old==tasks((ROOT/'docs/planning/BACKLOG.md').read_text())
line=next(x[len('PNG_AUDIT '):]for x in(E/'png-audit-final/console.log').read_text().splitlines()if x.startswith('PNG_AUDIT '));png= json.loads(line);assert not png['failures']
images={}
for row in png['decoded']:
 p=ROOT/row['file'];assert p.is_relative_to(E)and sha(p)==row['sha256'];assert row['width']>0 and row['height']>0
 images[str(p.relative_to(ROOT))]=sha(p)
assert set(images)=={str(p.relative_to(ROOT))for p in E.rglob('*.png')}
for path,hash_value in core.items():
 snapshot=E/'final-source'/(path+'.txt')
 if snapshot.exists():assert sha(snapshot)==hash_value,path
changed={p for p in subprocess.check_output(['git','diff','--name-only','4eb9c03','--','game','tests','tools','project.godot'],text=True).splitlines()}
assert changed=={'game/main.gd','game/player/skater.gd','game/player/skater_visual.gd','game/ui/hud.gd','tests/camera_turn_review_tests.gd','tests/run_tests.gd','tests/ui_feedback_tests.gd','tests/grind_regression_tests.gd'},changed
links=[]
for file in [BASE/'README.md',ROOT/'docs/planning/BAIL-HUD-REFINEMENT-2026-10-22.md',ROOT/'docs/architecture/decisions/ADR-027-ramp-pitch-and-classic-hud.md']:
 for target in re.findall(r'(?<!!)\[[^\]]+\]\(([^)]+)\)',file.read_text()):
  if '://'in target:continue
  p=(file.parent/target.split('#')[0]).resolve();assert p.exists()or p==BASE/'audit.json',target
  links.append(str(p.relative_to(ROOT)))
result={'valid':True,'current_core_inputs':len(core),'core_manifest':core,'accepted_receipts':receipts,'pose_comparison':compare,'recovery_comparison':read(E/'recovery-compare-04/comparison.json'),'recovery_capture_trials':capture['trials'],'native_pngs':images,'unchanged_complete_backlog_bodies':75,'original_project_controls_verified':original,'changed_existing_core_files':sorted(changed),'links_checked':len(links),'artifacts':{str(p.relative_to(ROOT)):sha(p)for p in sorted(E.rglob('*'))if p.is_file()},'limits':'Self-review, not independent QE or owner approval. Assisted ramp return is original tuning, not THPS3 code verification. Capsule fall and rigid board are not a full-body ragdoll or physical board pickup. Strict native comparisons are bounded; long-play stutter, broader ramps, DualSense, exports and final art remain open.'}
(BASE/'audit.json').write_text(json.dumps(result,indent=2)+'\n');print('AUDIT PASS:',len(core),'core inputs,',len(images),'original PNGs,75unchanged task bodies')

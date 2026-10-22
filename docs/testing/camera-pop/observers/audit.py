"""Bind owner-playtest corrections to exact source, real frames and original tasks."""
from pathlib import Path
import gzip,hashlib,json,re,subprocess,sys
ROOT=Path.cwd();BASE=ROOT/'docs/testing/camera-pop';E=BASE/'evidence'
preflight='--preflight' in sys.argv
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):
    if not p.exists():p=p.with_suffix(p.suffix+'.gz')
    return json.loads(gzip.decompress(p.read_bytes())if p.suffix=='.gz'else p.read_text())
paths=[ROOT/'project.godot']+[p for d in ('game','tests','tools')for p in(ROOT/d).rglob('*')if p.is_file()and '__pycache__'not in p.parts]
current={str(p.relative_to(ROOT)):sha(p)for p in sorted(paths)}
unused_test_differences={}
def resource_closure(command):
    pending=[ROOT/'project.godot']+[ROOT/x for x in command if Path(x).suffix in ('.gd','.tscn','.tres')and(ROOT/x).is_file()]
    seen=set()
    while pending:
        path=pending.pop().resolve()
        if path in seen or not path.is_relative_to(ROOT):continue
        seen.add(path)
        if path.suffix not in ('.gd','.tscn','.tres','.godot'):continue
        for ref in re.findall(r'[\"\']res://([^\"\']+)[\"\']',path.read_text()):
            child=(ROOT/ref).resolve()
            if child.is_file()and child.suffix in ('.gd','.tscn','.tres'):pending.append(child)
    return {str(p.relative_to(ROOT))for p in seen}
def admit(name,allow_unused_test=False):
    receipt=read(E/name/'receipt.json')
    assert receipt['valid']and receipt['source_stable']and receipt['clean_log'],name
    assert receipt['result_counts']and all(int(p)>0 and int(f)==0 for p,f in receipt['result_counts']),name
    manifest=read(E/name/'source-before.json')
    differences={path:{'recorded':manifest.get(path),'current':h}for path,h in current.items()if manifest.get(path)!=h}
    allowed={'tests/grind_regression_tests.gd','tests/camera_turn_review_tests.gd','tests/market_encounter_tests.gd'}if allow_unused_test else set()
    assert set(differences)<=allowed,(name,differences)
    if differences:
        closure=resource_closure(receipt['command'])
        assert not set(differences)&closure,(name,'changed test is loaded')
        unused_test_differences[name]={'differences':differences,'dependency_closure_paths':sorted(closure),'reason':'Only unloaded regression fixtures changed after these trials; all production, tools and loaded core tests match.'}
    return receipt,manifest
required=None
if not preflight:required,_=admit('required-final-02')
safety,_=admit('focused-final')
grind,_=admit('grind-fixture-01',True)
market,_=admit('market-final')
native,native_manifest=admit('compare-03',True)
comparison=read(E/'compare-03/comparison.json')
assert comparison['pass']and comparison['camera_quality']['pass']
assert comparison['max_position_error_m']==0 and not comparison['any_velocity_mismatch']
assert all(s['draws']['0']>0 for s in comparison['summaries'].values())
for name,path in [('compare.gd','docs/testing/camera-pop/observers/compare.gd'),('motion.gd','docs/testing/camera-flow/observers/motion.gd'),('baseline_camera.gd','docs/testing/camera-pop/observers/baseline_camera.gd')]:
    assert sha(E/'compare-03'/('loaded-'+name+'.txt'))==native_manifest[path]
old_camera=subprocess.check_output(['git','show','00fc616:game/player/chase_camera.gd'])
assert hashlib.sha256(old_camera).hexdigest()==sha(E/'compare-03/loaded-baseline_camera.gd.txt')
flat,flat_manifest=admit('flat-capture-05',True);pop,pop_manifest=admit('pop-capture-04',True)
assert sha(E/'flat-capture-05/loaded-flat_capture.gd.txt')==flat_manifest['docs/testing/camera-pop/observers/flat_capture.gd']
for name,path in [('pop_capture.gd','docs/testing/camera-pop/observers/pop_capture.gd'),('current_preview.gd','docs/testing/camera-flow/observers/current_preview.gd'),('capture.gd','docs/testing/camera-flow/observers/capture.gd'),('ramp_camera.gd','docs/testing/map-flow/observers/ramp_camera.gd')]:
    assert sha(E/'pop-capture-04'/('loaded-'+name+'.txt'))==pop_manifest[path]
assert read(E/'pop-capture-04/pop.json')['valid']
assert not read(E/'flat-capture-05/quiet.json')['errors']
png_receipt,_=admit('png-audit-final')
line=next(x[len('PNG_AUDIT '):]for x in(E/'png-audit-final/console.log').read_text().splitlines()if x.startswith('PNG_AUDIT '))
png=json.loads(line);assert not png['failures'];seen=set()
for row in png['decoded']:
    path=Path(row['file']);path=path if path.is_absolute()else ROOT/path
    assert path.is_relative_to(E)and path.exists()and sha(path)==row['sha256']
    assert(row['width'],row['height'])==(1280,800)
    seen.add(path.resolve())
assert seen=={p.resolve()for p in E.rglob('*.png')}
for name,path in [('current-chase_camera.gd.txt','game/player/chase_camera.gd'),('current-skater.gd.txt','game/player/skater.gd')]:assert sha(E/name)==current[path]
pattern=re.compile(r'^### (M\d\d-\d\d\d)\b[^\n]*\n.*?(?=^### M\d\d-\d\d\d\b|^## [^#]|\Z)',re.M|re.S)
def tasks(text):return {m[1]:hashlib.sha256(m[0].encode()).hexdigest()for m in pattern.finditer(text)}
old=tasks(subprocess.check_output(['git','show','00fc616:docs/planning/BACKLOG.md'],text=True))
assert len(old)==75 and old==tasks((ROOT/'docs/planning/BACKLOG.md').read_text())
research=read(ROOT/'docs/research/THPS-PHYSICS-SOURCES-2026-10-19.json')
for path,h in research['local_movement_and_existing_test_hashes'].items():assert hashlib.sha256(subprocess.check_output(['git','show','84f04fa:'+path])).hexdigest()==h
changed=set(subprocess.check_output(['git','diff','--name-only','00fc616','--','game'],text=True).splitlines())
assert changed=={'game/player/chase_camera.gd','game/player/skater.gd'}
links=[]
for file in [BASE/'README.md',ROOT/'docs/architecture/decisions/ADR-024-quiet-ollies-and-charged-ramp-pop.md']:
    for m in re.finditer(r'(?<!!)\[[^\]]+\]\(([^)]+)\)',file.read_text()):
        target=m[1].split('#')[0]
        if not target or '://'in target:continue
        path=(file.parent/target).resolve()
        assert path.exists()or path==(BASE/'audit.json').resolve(),(str(file),target)
        links.append(str(path.relative_to(ROOT)))
artifacts={str(p.relative_to(ROOT)):sha(p)for p in sorted(E.rglob('*'))if p.is_file()}
result={'valid':not preflight,'pending_required':preflight,'current_core_inputs':len(current),'core_manifest':current,'required':required,'focused_safety':safety,'native':native,'accepted_comparison':'compare-03','exact_physical_rows':comparison['rows_compared'],'all_native_draw_counters_positive':True,'all_production_tools_and_loaded_core_sources_match':True,'unused_test_differences':unused_test_differences,'descending_rail_fixture':grind,'delivery_camera':market,'flat_capture':flat,'charged_ramp_capture':pop,'png_receipt':png_receipt,'png_count':len(seen),'png_decode_and_file_hashes':png['decoded'],'unchanged_complete_backlog_records':75,'historical_research_hashes_verified':len(research['local_movement_and_existing_test_hashes']),'production_paths_changed':sorted(changed),'local_links_checked':len(links),'artifact_count':len(artifacts),'artifact_hashes':artifacts,'limits':'Root checks are not independent QE, human pop/camera comfort, oblique/alternate ramps, physical DualSense, export or long-play/stutter certification. Every final native phase long-frame count remains disclosed. Earlier69/0, timing passes and capture diagnostics bind their own source; failed p99, faster-follow snap and observer criteria remain recorded.'}
out=ROOT/'.local/camera-pop/preflight.json'if preflight else BASE/'audit.json'
out.write_text(json.dumps(result,indent=2)+'\n')
print('PREFLIGHT (required pending)'if preflight else 'AUDIT PASS',len(current),'core inputs,',len(artifacts),'artifacts,',len(seen),'PNGs,75unchanged full tasks')

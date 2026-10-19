"""Bind final camera source, current native evidence, PNG bytes and original tasks."""
from pathlib import Path
import hashlib,json,re,subprocess,gzip
ROOT=Path.cwd();BASE=ROOT/'docs/testing/camera-flow';E=BASE/'evidence'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(gzip.decompress(p.read_bytes())if p.suffix=='.gz'else p.read_text())
def core():
    paths=[ROOT/'project.godot']
    paths += [p for d in ('game','tests','tools')for p in(ROOT/d).rglob('*')if p.is_file()and '__pycache__'not in p.parts]
    return {str(p.relative_to(ROOT)):sha(p)for p in sorted(paths)}
def matches(folder,production_only=False):
    receipt=read(E/folder/'receipt.json');assert receipt['valid'],folder
    manifest=read(E/folder/'source-before.json')
    for path,h in current.items():
        if not production_only or path.startswith('game/')or path=='project.godot':assert manifest[path]==h,(folder,path)
    return receipt
current=core()
required=matches('required-forward-fixed')
assert all(int(f)==0 and int(p)>0 for p,f in required['result_counts'])
focused=matches('focused-forward-fixed')
native=matches('compare-forward-fixed')
comparison=read(E/'compare-forward-fixed/comparison.json');assert comparison['pass']and comparison['camera_quality']['pass']
manifest=read(E/'compare-forward-fixed/source-before.json')
for name in ('compare.gd','motion.gd','baseline_camera.gd'):
    assert sha(E/'compare-forward-fixed'/('loaded-'+name))==manifest['docs/testing/camera-flow/observers/'+name]
capture=matches('capture-forward-fixed')
capture_manifest=read(E/'capture-forward-fixed/source-before.json')
for name,path in [('current_preview.gd','docs/testing/camera-flow/observers/current_preview.gd'),('capture.gd','docs/testing/camera-flow/observers/capture.gd'),('ramp_camera.gd','docs/testing/map-flow/observers/ramp_camera.gd')]:
    assert sha(E/'capture-forward-fixed'/('loaded-'+name+'.txt'))==capture_manifest[path]
route=matches('approach-forward-fixed')
assert read(E/'approach-forward-fixed/approach.json')['valid']
playability=matches('playability-idle-pitch-02',True)
playability_manifest=read(E/'playability-idle-pitch-02/source-before.json')
assert playability_manifest['tests/playability_regression_tests.gd']==current['tests/playability_regression_tests.gd']
log=(E/'png-audit/console.log').read_text()
png=json.loads(next(x[len('PNG_AUDIT '):]for x in log.splitlines()if x.startswith('PNG_AUDIT ')))
assert not png['failures']
seen=set()
for record in png['decoded']:
    path=Path(record['file']);path=path if path.is_absolute()else ROOT/path
    assert path.is_relative_to(E)and path.exists()and sha(path)==record['sha256']
    assert(record['width'],record['height'])==(1280,800)
    seen.add(path.resolve())
assert seen=={p.resolve()for p in E.rglob('*.png')}
assert read(E/'png-audit/receipt.json')['valid']
pattern=re.compile(r'^### (M\d\d-\d\d\d)\b[^\n]*\n.*?(?=^### M\d\d-\d\d\d\b|^## [^#]|\Z)',re.M|re.S)
def tasks(text):return {m[1]:hashlib.sha256(m[0].encode()).hexdigest()for m in pattern.finditer(text)}
old=subprocess.check_output(['git','show','84f04fa:docs/planning/BACKLOG.md'],text=True)
a=tasks(old);b=tasks((ROOT/'docs/planning/BACKLOG.md').read_text());assert len(a)==75 and a==b
research=read(ROOT/'docs/research/THPS-PHYSICS-SOURCES-2026-10-19.json')
for path,h in research['local_movement_and_existing_test_hashes'].items():
    raw=subprocess.check_output(['git','show','84f04fa:'+path]);assert hashlib.sha256(raw).hexdigest()==h
files=[BASE/'README.md',BASE/'CONTRACT.md',ROOT/'docs/research/THPS-PHYSICS-COMPARISON-2026-10-19.md',ROOT/'docs/architecture/decisions/ADR-023-ramp-camera-heading-and-framing.md']
links=[]
for file in files:
    for match in re.finditer(r'(?<!!)\[[^\]]+\]\(([^)]+)\)',file.read_text()):
        target=match[1].split('#')[0]
        if not target or '://'in target:continue
        path=(file.parent/target).resolve();assert path.exists() or path==(BASE/'audit.json').resolve(),(str(file),target);links.append(str(path.relative_to(ROOT)))
artifacts={str(p.relative_to(ROOT)):sha(p)for p in sorted(E.rglob('*'))if p.is_file()}
result={'valid':True,'current_core_inputs':len(current),'core_manifest':current,'required':required,'focused':focused,'accepted_comparison':'compare-forward-fixed','native_receipt':native,'exact_native_core_matches':True,'capture_all_core_matches':True,'ordinary_route_all_core_matches':True,'ordinary_playability_production_and_test_match':True,'png_count':len(png['decoded']),'png_decode_and_file_hashes':png['decoded'],'complete_backlog_records_unchanged':len(a),'historical_research_local_hashes_verified':len(research['local_movement_and_existing_test_hashes']),'local_links_checked':len(links),'artifact_count':len(artifacts),'artifact_hashes':artifacts,'limits':'Encoded PNG file hashes, not raw pixel hashes. Root checks are not independent QE/human/controller/export/whole-map/long-play acceptance. One63.907ms candidate native interval stays disclosed. Historical required2199/0 and earlier camera designs are superseded; current controller intentionally changes ramp gravity/pose.'}
(BASE/'audit.json').write_text(json.dumps(result,indent=2)+'\n')
print('AUDIT PASS',len(current),'core inputs,',len(artifacts),'artifacts,',len(png['decoded']),'PNGs,',len(a),'unchanged full backlog records')

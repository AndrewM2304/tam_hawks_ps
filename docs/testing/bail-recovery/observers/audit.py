"""Bind research diagnostics to unchanged production and original native images."""
from pathlib import Path
import gzip,hashlib,json,re,subprocess
ROOT=Path.cwd();BASE=ROOT/'docs/testing/bail-recovery';E=BASE/'evidence'
BASELINE='83758c3d0f004659d9a07e748793b0075845fff4'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):
    if not p.exists():p=p.with_suffix(p.suffix+'.gz')
    return json.loads(gzip.decompress(p.read_bytes())if p.suffix=='.gz'else p.read_text())
core=[ROOT/'project.godot']+[p for d in ('game','tests','tools')for p in(ROOT/d).rglob('*')if p.is_file()and '__pycache__'not in p.parts]
manifest={str(p.relative_to(ROOT)):sha(p)for p in sorted(core)}
tracked=set(subprocess.check_output(['git','ls-tree','-r','--name-only',BASELINE,'--','game','tests','tools','project.godot'],text=True).splitlines())
assert set(manifest)==tracked and len(manifest)==375
subprocess.run(['git','diff','--exit-code',BASELINE,'--','game','tests','tools','project.godot'],check=True,stdout=subprocess.DEVNULL)
receipts={}
for name in ['current-01','current-02','current-03','png-audit']:
    folder=E/name;r=read(folder/'receipt.json');m=read(folder/'source-before.json')
    assert r['source_stable']and all(m.get(p)==h for p,h in manifest.items())
    if name.startswith('current-'):
        assert sha(folder/'loaded-current_audit.gd.txt')==m['docs/testing/bail-recovery/observers/current_audit.gd']
    if name in ('current-03','png-audit'):
        assert r['valid']and r['clean_log']and all(int(p)>0 and int(f)==0 for p,f in r['result_counts'])
    receipts[name]=r
assert sha(E/'current-03/loaded-current_audit.gd.txt')==sha(BASE/'observers/current_audit.gd')
summary=read(E/'summary.json');observation=read(E/'current-03/observations.json')
assert summary['samples']==len(observation['rows'])==1061 and not observation['errors']
assert len(observation['bails'])==1 and len(observation['images'])==24
assert 23.15<summary['one_tick_bail_displacement_m']<23.17
assert summary['maxima']==observation['maxima']
line=next(x[len('PNG_AUDIT '):]for x in(E/'png-audit/console.log').read_text().splitlines()if x.startswith('PNG_AUDIT '))
png=json.loads(line);assert not png['failures'];images={}
for row in png['decoded']:
    p=ROOT/row['file'];assert p.is_relative_to(E)and sha(p)==row['sha256']and(row['width'],row['height'])==(1280,800)
    images[str(p.relative_to(ROOT))]=sha(p)
assert set(images)=={str(p.relative_to(ROOT))for p in E.rglob('*.png')}and len(images)==12
pattern=re.compile(r'^### (M\d\d-\d\d\d)\b[^\n]*\n.*?(?=^### M\d\d-\d\d\d\b|^## [^#]|\Z)',re.M|re.S)
def tasks(s):return {m[1]:hashlib.sha256(m[0].encode()).hexdigest()for m in pattern.finditer(s)}
original=tasks(subprocess.check_output(['git','show',BASELINE+':docs/planning/BACKLOG.md'],text=True))
assert len(original)==75 and original==tasks((ROOT/'docs/planning/BACKLOG.md').read_text())
reference=ROOT/'docs/research/THPS-BAIL-SOURCES-2026-10-22.json';ref=read(reference)
assert ref['revision']=='fa128f5ba222e0f24a9bff019d59262b79141e48'and len(ref['source_files'])==12 and not ref['licence_named_paths']
for file in [BASE/'README.md',ROOT/'docs/research/THPS-BAIL-AND-HUMAN-MOTION-2026-10-22.md']:
    for target in re.findall(r'(?<!!)\[[^\]]+\]\(([^)]+)\)',file.read_text()):
        if '://'in target:continue
        p=(file.parent/target.split('#')[0]).resolve()
        assert p.exists()or p==BASE/'audit.json',target
result={'valid':True,'baseline_production':BASELINE,'unchanged_core_inputs':375,'core_manifest':manifest,'unchanged_complete_backlog_bodies':75,'receipts':receipts,'observed_bail_displacement_m':summary['one_tick_bail_displacement_m'],'native_pngs':images,'reference_metadata_sha256':sha(reference),'artifacts':{str(p.relative_to(ROOT)):sha(p)for p in sorted(E.rglob('*'))if p.is_file()},'limits':'Research and diagnostic completion only. No bail/recovery/limb fix, production performance admission, new full regression, independent QE or human/hardware/visual acceptance.'}
(BASE/'audit.json').write_text(json.dumps(result,indent=2)+'\n')
print('AUDIT PASS:375unchanged production/core inputs,75unchanged full tasks,12native PNGs; research only')

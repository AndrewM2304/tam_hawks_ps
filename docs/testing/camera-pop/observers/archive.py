"""Archive completed bounded runs; selected historical frames are explicitly indexed."""
from pathlib import Path
import gzip,json,shutil,sys
E=Path('docs/testing/camera-pop/evidence');E.mkdir(exist_ok=True)
def keep_png(run,name):
    if run in ('flat-capture-05','pop-capture-04'):return True
    if run=='pop-capture-01':return name.startswith('phase-')
    if run=='pop-capture-03':return name in ('halfpipe-06.png','phase-ascent.png','phase-first-descent.png')
    if run=='flat-capture-02':return name in ('tap-crouch.png','charged-apex.png','charged-landed.png')
    if run=='flat-capture-03':return name in ('tap-crouch.png','charged-apex.png')
    return False
for name in sys.argv[1:]:
    source=Path('.local/camera-pop')/name
    assert (source/'receipt.json').exists(),name
    for p in source.rglob('*'):
        if not p.is_file():continue
        if p.suffix=='.png' and not keep_png(name,p.name):continue
        target=E/name/p.relative_to(source);target.parent.mkdir(parents=True,exist_ok=True)
        if p.suffix=='.json' and p.stat().st_size>200000:target.with_suffix('.json.gz').write_bytes(gzip.compress(p.read_bytes(),mtime=0))
        else:shutil.copyfile(p,target)
for folder in (p for p in E.iterdir()if p.is_dir()):
    for png in folder.glob('*.png'):
        if not keep_png(folder.name,png.name):png.unlink()
index=[]
for folder in sorted(p for p in E.iterdir()if p.is_dir()):
    r=json.loads((folder/'receipt.json').read_text())
    index.append({'run':folder.name,'valid_process_receipt':r['valid'],'result_counts':r['result_counts'],'retained_pngs':[p.name for p in sorted(folder.glob('*.png'))],'limits':'Process validity alone is not admission. compare-03 admits the final flat-bottom correction; compare-02 is its earlier source; earlier failed performance/diagnostic/capture results stay rejected. Historical captures retain selected frames only.'})
(E/'RUN-INDEX.json').write_text(json.dumps(index,indent=2)+'\n')

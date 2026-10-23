"""Archive frozen observations and unmodified native PNGs; keep rejected runs."""
from pathlib import Path
import gzip,json,shutil,sys
E=Path('docs/testing/flat-ollie/evidence');E.mkdir(exist_ok=True)
for name in sys.argv[1:]:
 source=Path('.local/ollie-audit')/name;assert(source/'receipt.json').exists(),name
 for p in source.rglob('*'):
  if not p.is_file():continue
  if p.suffix=='.png':
   selected={'capture-01':['charged-rear-level-profile.png','tap-apex-chase.png'],'capture-02':['charged-front-lead-profile.png','charged-rear-level-profile.png'],'ramp-capture-01':['phase-ascent.png']}
   if name in selected and p.name not in selected[name]:continue
  target=E/name/p.relative_to(source);target.parent.mkdir(parents=True,exist_ok=True)
  if p.suffix=='.json' and p.stat().st_size>200000:target.with_suffix('.json.gz').write_bytes(gzip.compress(p.read_bytes(),mtime=0))
  else:shutil.copyfile(p,target)
index=[]
for folder in sorted(p for p in E.iterdir()if p.is_dir()and(p/'receipt.json').exists()):
 r=json.loads((folder/'receipt.json').read_text());index.append({'run':folder.name,'valid_process_receipt':r['valid'],'counts':r['result_counts'],'retained_pngs':[p.name for p in sorted(folder.glob('*.png'))],'limits':'Valid process alone is not admission. capture01 and grind01 are rejected; subsequent targeted/native/full source rules belong in README/audit.'})
(E/'RUN-INDEX.json').write_text(json.dumps(index,indent=2)+'\n')

"""Retain receipts and observations, including rejected trials; PNGs stay original."""
from pathlib import Path
import gzip,json,shutil,sys
base=Path('docs/testing/bail-pose');e=base/'evidence';e.mkdir(exist_ok=True)
for name in sys.argv[1:]:
 source=Path('.local/bail-pose')/name
 assert (source/'receipt.json').exists(),name
 for p in source.rglob('*'):
  if not p.is_file():continue
  if p.suffix=='.png' and name=='recovery-capture-06' and p.name not in ['normal-fall-chase.png','normal-slide-profile.png']:continue
  if p.suffix=='.png' and name=='pop-capture-01' and not p.name.startswith('phase-'):continue
  if p.suffix=='.png' and name=='hud-capture-02' and p.name!='hud-640x480-scale-1.4.png':continue
  if p.suffix=='.png' and name=='recovery-capture-04' and p.name not in ['normal-fall-chase.png','normal-slide-profile.png']:continue
  if p.suffix=='.png' and name=='recovery-capture-05' and p.name!='reduced-slide-profile.png':continue
  if p.suffix=='.png' and name=='hud-capture-01' and p.name!='hud-640x480-scale-1.4.png':continue
  if p.suffix=='.png' and name in ['capture-01','recovery-capture-01','recovery-capture-02','recovery-capture-03'] and not ('normal-slide' in p.name or 'melon_grab-profile' in p.name):continue
  target=e/name/p.relative_to(source);target.parent.mkdir(parents=True,exist_ok=True)
  if p.suffix=='.json' and p.stat().st_size>200000:target.with_suffix('.json.gz').write_bytes(gzip.compress(p.read_bytes(),mtime=0))
  else:shutil.copyfile(p,target)
index=[]
for folder in sorted(p for p in e.iterdir() if p.is_dir() and (p/'receipt.json').exists()):
 r=json.loads((folder/'receipt.json').read_text());index.append({'run':folder.name,'valid_process_receipt':r['valid'],'counts':r['result_counts'],'retained_pngs':[p.name for p in sorted(folder.glob('*.png'))],'limits':'A valid process receipt alone is not gameplay/performance admission; see README for final source and rejected/intermediate runs.'})
(e/'RUN-INDEX.json').write_text(json.dumps(index,indent=2)+'\n')

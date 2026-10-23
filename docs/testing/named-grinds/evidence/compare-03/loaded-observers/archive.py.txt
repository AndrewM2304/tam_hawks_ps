"""Archive bounded receipts, raw results and original PNGs; retain rejected runs."""
from pathlib import Path
import gzip,json,shutil,sys,subprocess,hashlib
base=Path('docs/testing/named-grinds');e=base/'evidence';e.mkdir(exist_ok=True)
original={}
for name in sys.argv[1:]:
 source=Path('.local/named-grinds')/name
 assert (source/'receipt.json').exists(),name
 for f in source.rglob('*'):
  if not f.is_file():continue
  relative=f.relative_to(source)
  if 'loaded-source' in relative.parts:
   path=str(relative).split('loaded-source/',1)[1].removesuffix('.txt')
   if path not in original:
    result=subprocess.run(['git','show','ef0eb9f:'+path],stdout=subprocess.PIPE,stderr=subprocess.DEVNULL)
    original[path]=hashlib.sha256(result.stdout).hexdigest() if result.returncode==0 else None
   if hashlib.sha256(f.read_bytes()).hexdigest()==original[path]:continue
  target=e/name/relative;target.parent.mkdir(parents=True,exist_ok=True)
  if f.suffix=='.json' and f.stat().st_size>200000:target.with_suffix('.json.gz').write_bytes(gzip.compress(f.read_bytes(),mtime=0))
  else:shutil.copyfile(f,target)
index=[]
for folder in sorted(p for p in e.iterdir() if p.is_dir() and (p/'receipt.json').exists()):
 r=json.loads((folder/'receipt.json').read_text())
 index.append({'run':folder.name,'valid_process_receipt':r['valid'],'counts':r['result_counts'],'retained_pngs':[p.name for p in sorted(folder.glob('*.png'))],'limits':'Process validity alone does not admit timing, source closure, gameplay or human gates. README/audit owns accepted vs historical/rejected status.'})
(e/'RUN-INDEX.json').write_text(json.dumps(index,indent=2)+'\n')

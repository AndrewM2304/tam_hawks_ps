#!/usr/bin/env python3
"""Portable offline preservation/binding/parity checks; no Godot or production import."""
from pathlib import Path
import gzip,hashlib,json,re,tarfile
R=Path(__file__).resolve().parent
count=0
def check(ok,label):
 global count
 if not ok:raise AssertionError(label)
 count+=1
def sha(data):return hashlib.sha256(data).hexdigest()
manifest=json.loads((R/'preservation.json').read_text())
for name,expected in manifest['files'].items():check(sha((R/name).read_bytes())==expected,'preserved '+name)
bindings=json.loads((R/'source-bindings.json').read_text())
refs=json.loads((R/'unchanged-binary-source-references.json').read_text())
with tarfile.open(R/'source-objects.tar.gz','r:gz') as tar:
 objects={m.name:tar.extractfile(m).read() for m in tar.getmembers() if m.isfile()}
for epoch,mapping in bindings['epochs'].items():
 receipt=json.loads((R/epoch/'receipt.json').read_text())
 check(set(mapping)==set(receipt['source_before']),'complete source map '+epoch)
 for path,item in mapping.items():
  expected=receipt['source_before'][path]
  check(item['sha256']==expected,'binding '+epoch+' '+path)
  if 'object' in item:check(sha(objects[item['object']])==expected,'source object '+path)
  else:check(refs['files'][item['base_reference']]['source_sha256']==expected,'base binary '+path)
for path,item in bindings['final_cache_metadata'].items():
 check(sha(objects[item['object']])==item['sha256'],'cache metadata '+path)
r=json.loads((R/'clean-08/receipt.json').read_text())
check(r['eligible'] and r['assertions']=={'passed':22,'failed':0},'clean22 result')
check(r['source_before']==r['source_after'],'source stable')
check(r['private_shared_cache_before']==r['private_shared_cache_after'],'cache stable')
check(len(r['epochs'])==2 and all(x['exit']==0 and not x['stop'] and not x['raw_errors'] for x in r['epochs']),'all process exits')
check(not re.search(r'ERROR:|Parse Error:',(R/'clean-08/native.log').read_text()),'raw native clean')
a=json.loads(gzip.decompress((R/'branch-02/trajectory.json.gz').read_bytes()))
b=json.loads(gzip.decompress((R/'clean-08/trajectory.json.gz').read_bytes()))
check(len(a['physical_rows'])==len(b['physical_rows'])==1004,'physical row count')
check(a['physical_rows']==b['physical_rows'],'all physical fields exact')
rows=b['presentation_rows']
check(len(rows)==993,'presentation row count')
check(all(int(y['physics'])==int(x['physics'])+1 for x,y in zip(rows,rows[1:])),'ordinary physics contiguous')
check(all(x['board_zero'] and x['shoes_zero'] for x in rows),'ordinary model/shoe-box clear')
raw_capsule=[x['physics'] for x in rows if not x['capsule_zero']]
check(raw_capsule==[115]+list(range(301,316)),'raw capsule failures retained')
observations=b['loaded_capsule_observations']
check(len(observations)==16 and not observations[0]['loaded_native_floor_proof']['clear'] and all(x['loaded_native_floor_proof']['clear'] for x in observations[1:]),'loaded predicate limits retained')
proposal=json.loads((R/'proposal/manifest.json').read_text())['entries'][0]
check(sha((R/'proposal/before-skater.gd.txt').read_bytes())==proposal['before_sha256'],'proposal before')
check(sha((R/'proposal/payload-skater.gd.txt').read_bytes())==proposal['after_sha256'],'proposal after')
print(json.dumps({'passed':count,'failed':0,'scope':'offline preservation/executed-source bindings/physical parity; no independent native or visual acceptance'}))

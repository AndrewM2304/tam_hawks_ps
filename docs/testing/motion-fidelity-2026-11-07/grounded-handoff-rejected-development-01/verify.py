from pathlib import Path
import argparse,gzip,hashlib,json,subprocess
p=argparse.ArgumentParser();p.add_argument('--git-root',type=Path);a=p.parse_args();root=Path(__file__).resolve().parent;data=json.loads((root/'preservation.json').read_text());checks=0
def sha(b):return hashlib.sha256(b).hexdigest()
for h,info in data['objects'].items():
 raw=(root/'objects'/(h+'.gz')).read_bytes();assert sha(raw)==info['gzip_sha256'];b=gzip.decompress(raw);assert sha(b)==h and len(b)==info['bytes'];checks+=2
for name,info in data['paths'].items():assert info['sha256'] in data['objects'] and data['objects'][info['sha256']]['bytes']==info['bytes'];checks+=1
if a.git_root:
 cache={}
 for closure in data['source_closures'].values():
  for name,info in closure.items():
   if info['kind']=='git':
    blob=info['git_blob']
    if blob not in cache:cache[blob]=subprocess.check_output(['git','cat-file','blob',blob],cwd=a.git_root)
    assert sha(cache[blob])==info['sha256'] and len(cache[blob])==info['bytes'];checks+=1
   elif info['kind']=='object':assert info['sha256'] in data['objects'];checks+=1
print(json.dumps({'preservation_checks':checks,'passed':True,'unavailable_historical_metadata':data['unavailable_original_source_bytes'],'scope':'Offline byte preservation/source references only; no engine/visual/performance acceptance'},indent=2))

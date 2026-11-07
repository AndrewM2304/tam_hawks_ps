from pathlib import Path
import argparse,gzip,hashlib,json,subprocess,tarfile
R=Path(__file__).resolve().parent;P=R.parent
arg=argparse.ArgumentParser();arg.add_argument('--repo',type=Path);args=arg.parse_args();count=0
def sha(data):return hashlib.sha256(data).hexdigest()
def check(ok,label):
 global count
 if not ok:raise AssertionError(label)
 count+=1
index=json.loads((R/'preservation.json').read_text())
for name,item in index['files'].items():
 data=(R/name).read_bytes();check(sha(data)==item['sha256'] and len(data)==item['bytes'],'preserved '+name)
raw_index=json.loads((P/'raw-preservation.json').read_text())
for item in raw_index['files']:
 data=(P/item['destination']).read_bytes();check(sha(data)==item['stored_sha256'],'raw stored '+item['destination'])
 if item['encoding']=='gzip':data=gzip.decompress(data)
 check(sha(data)==item['raw_sha256'] and len(data)==item['raw_bytes'],'raw original '+item['source_name'])
receipt=json.loads((P/'receipt.json').read_text());before=json.loads(gzip.decompress((P/'source-before.json.gz').read_bytes()));after=json.loads(gzip.decompress((P/'source-after.json.gz').read_bytes()))
check(receipt['eligible'] is False and receipt['engine_exit']==0,'raw false eligibility retained')
check(receipt['main_result']==[6697,0] and receipt['script_launch_result']==[2,0] and not receipt['error_lines'],'technical counts/raw clean')
check(len(before)==895 and len(after)==900 and all(after.get(p)==x for p,x in before.items()),'all895 prebound bytes unchanged')
added=sorted(set(after)-set(before));check(added==receipt['changed_inputs'] and len(added)==5 and all(p.endswith('.gd.uid') for p in added),'exact new UID-only exception')
bindings=json.loads((R/'source-bindings.json').read_text());refs=json.loads((R/'unchanged-git-source-references.json').read_text());uids=json.loads((R/'uid-exception.json').read_text())
check(bindings['base_commit']==refs['base_commit']==receipt['git_head']=='305d037a539670cf51244064cf20932293c0bab4','exact base')
check(set(bindings['inputs'])==set(after),'complete900 source closure')
with tarfile.open(R/'source-delta-objects.tar.gz','r:gz') as tar:objects={x.name:tar.extractfile(x).read() for x in tar.getmembers() if x.isfile()}
for path,item in bindings['inputs'].items():
 check(item['sha256']==after[path]['sha256'] and item['bytes']==after[path]['bytes'],'source map '+path)
 if 'object'in item:
  data=objects[item['object']];check(sha(data)==item['sha256'] and len(data)==item['bytes'],'archived source '+path)
 else:check(refs['files'][path]['sha256']==item['sha256'] and refs['files'][path]['bytes']==item['bytes'],'Git reference '+path)
check(len(objects)==17 and len(refs['files'])==883,'deduplicated complete split')
for path in added:
 item=bindings['inputs'][path];data=objects[item['object']]
 check(uids['only_new_paths'][path]['sha256']==sha(data) and uids['only_new_paths'][path]['text']==data.decode(),'exact UID bytes '+path)
check(sha((P/'runner.py.txt').read_bytes())==before['.local/run-fidelity-checkpoint04.py']['sha256'],'launcher before-bound')
repo=args.repo or next((p for p in R.parents if (p/'.git').exists()),None)
if repo is not None:
 proc=subprocess.Popen(['git','cat-file','--batch'],cwd=repo,stdin=subprocess.PIPE,stdout=subprocess.PIPE)
 for path,item in refs['files'].items():
  proc.stdin.write((item['git_blob']+'\n').encode());proc.stdin.flush();header=proc.stdout.readline().decode().split();check(len(header)==3 and header[1]=='blob','base blob '+path)
  data=proc.stdout.read(int(header[2]));check(proc.stdout.read(1)==b'\n','blob framing');check(sha(data)==item['sha256'] and len(data)==item['bytes'],'exact base bytes '+path)
 proc.stdin.close();check(proc.wait()==0,'Git batch clean exit')
print(json.dumps({'passed':count,'failed':0,'raw_eligible':False,'after_import_inputs':900,'base_git_objects_verified':repo is not None,'scope':'offline after-import source closure; five UID sidecars remain explicit; no new native/visual/hardware acceptance'}))

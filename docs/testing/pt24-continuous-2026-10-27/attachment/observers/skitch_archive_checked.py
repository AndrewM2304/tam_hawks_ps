from pathlib import Path
import hashlib,json,shutil,subprocess,sys
root=Path.cwd();origin=root/sys.argv[1];target=root/sys.argv[2]
assert origin.is_dir() and not target.exists(), (origin,target)
receipt=json.loads((origin/'receipt.json').read_text());manifest=json.loads((origin/'source-before.json').read_text())
assert manifest==json.loads((origin/'source-after.json').read_text()), 'changing source cannot be archived as immutable'
parent=receipt['git_head'];tree={}
for item in subprocess.check_output(['git','ls-tree','-rz',parent]).split(b'\0'):
 if not item:continue
 metadata,name=item.split(b'\t',1);tree[name.decode()]=metadata.split()[2].decode()
rows=[];target.mkdir(parents=True)
for name in ('receipt.json','source-before.json','source-after.json','console.log'):
 shutil.copyfile(origin/name,target/name)
for name,expected in manifest.items():
 source=root/name;data=source.read_bytes();actual=hashlib.sha256(data).hexdigest()
 assert actual==expected,(name,expected,actual)
 oid=hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
 if tree.get(name)==oid:continue
 dest=target/'source-snapshot'/name;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
 rows.append({'input':name,'file':str(dest.relative_to(target)),'sha256':actual,'bytes':len(data)})
(target/'SNAPSHOTS.json').write_text(json.dumps({'git_parent':parent,'method':'Exact non-parent source inputs and command-input copies; each hash equals the raw source-before manifest. Other source inputs resolve to immutable Git parent.','files':rows},indent=2)+'\n')
shutil.copyfile(root/'game/player/skater_visual.gd',target/'skater_visual.gd')
assert hashlib.sha256((target/'skater_visual.gd').read_bytes()).hexdigest()==manifest['game/player/skater_visual.gd']
print('Archived',receipt['valid'],'receipt,',len(rows),'exact non-parent source inputs to',target.relative_to(root))

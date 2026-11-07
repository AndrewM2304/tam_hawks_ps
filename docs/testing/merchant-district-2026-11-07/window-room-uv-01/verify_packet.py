from pathlib import Path
import gzip,hashlib,json,subprocess
P=Path(__file__).resolve().parent
R=Path(subprocess.check_output(['git','rev-parse','--show-toplevel'],cwd=P,text=True).strip())
def sha(b):return hashlib.sha256(b).hexdigest()
payload=json.loads((P/'payload-manifest.json').read_text())
for row in payload['files']:
    b=(P/row['path']).read_bytes()
    assert sha(b)==row['sha256'],row['path']
    if 'original_sha256'in row:
        raw=gzip.decompress(b)if row['path'].endswith('.gz')else b
        assert sha(raw)==row['original_sha256']and len(raw)==row['original_bytes'],row['path']
closure=json.loads((P/'source-closure.json').read_text())
for name,row in closure.items():
    b=(subprocess.check_output(['git','cat-file','blob',row['oid']],cwd=R)
       if row['kind']=='git_blob'else gzip.decompress((P/row['path']).read_bytes()))
    assert len(b)==row['bytes']and sha(b)==row['sha256'],name
print(f"Verified {len(payload['files'])} preserved payloads and {len(closure)} exact source inputs; native/human acceptance is unchanged.")

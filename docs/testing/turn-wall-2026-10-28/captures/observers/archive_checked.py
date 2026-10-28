from pathlib import Path
import gzip
import hashlib
import json
import shutil
import subprocess
import sys

root = Path.cwd()
origin = root / sys.argv[1]
target = root / sys.argv[2]
assert origin.is_dir() and not target.exists(), (origin, target)
receipt = json.loads((origin / 'receipt.json').read_text())
manifest = json.loads((origin / 'source-before.json').read_text())
assert manifest == json.loads((origin / 'source-after.json').read_text())
parent = receipt['git_head']
tree = {}
for item in subprocess.check_output(['git', 'ls-tree', '-rz', parent]).split(b'\0'):
    if item:
        metadata, name = item.split(b'\t', 1)
        tree[name.decode()] = metadata.split()[2].decode()
target.mkdir(parents=True)
rows = []
for name in ('receipt.json', 'source-before.json', 'source-after.json', 'console.log'):
    shutil.copyfile(origin / name, target / name)
snapshots = []
parent_inputs = 0
for name, expected in manifest.items():
    data = (root / name).read_bytes()
    assert hashlib.sha256(data).hexdigest() == expected, name
    oid = hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()
    if tree.get(name) == oid:
        parent_inputs += 1
        continue
    dest = target / 'source-snapshot' / name
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data)
    snapshots.append({'input': name, 'file': str(dest.relative_to(target)),
                      'sha256': expected, 'bytes': len(data)})
(target / 'SNAPSHOTS.json').write_text(json.dumps({
    'git_parent': parent, 'source_inputs': len(manifest), 'parent_inputs': parent_inputs,
    'method': 'Every input resolves to its immutable parent Git blob or exact retained non-parent snapshot.',
    'files': snapshots}, indent=2) + '\n')
if (origin / 'lines').is_dir():
    for source in sorted((origin / 'lines').rglob('*')):
        if not source.is_file():
            continue
        data = source.read_bytes()
        dest = target / 'lines' / (str(source.relative_to(origin / 'lines')) + '.gz')
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(gzip.compress(data, mtime=0))
        rows.append({'file': str(dest.relative_to(target)), 'bytes': dest.stat().st_size,
                     'sha256': hashlib.sha256(dest.read_bytes()).hexdigest(),
                     'original_file': str(source.relative_to(origin)), 'original_bytes': len(data),
                     'original_sha256': hashlib.sha256(data).hexdigest(), 'encoding': 'gzip;mtime=0'})
for source in sorted(target.iterdir()):
    if source.is_file():
        data = source.read_bytes()
        rows.append({'file': source.name, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
(target / 'MANIFEST.json').write_text(json.dumps({'method': 'Raw immutable run receipts, maps, logs and losslessly compressed line traces.', 'files': rows}, indent=2) + '\n')
print(json.dumps({'archive': str(target.relative_to(root)), 'valid': receipt['valid'],
                  'source_inputs': len(manifest), 'parent_inputs': parent_inputs,
                  'exact_changed_snapshots': len(snapshots), 'artifacts': len(rows)}))

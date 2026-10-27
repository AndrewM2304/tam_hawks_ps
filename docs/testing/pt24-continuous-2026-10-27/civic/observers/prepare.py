"""Restore the exact ignored civic observer; this does not run an engine."""
from pathlib import Path
import hashlib
import json
import shutil

root = Path.cwd()
assert (root / 'project.godot').is_file(), 'Run from the repository root'
package = Path(__file__).resolve().parents[1]
index = json.loads((package / 'source-snapshots.json').read_text())
for entry in index['inputs']:
    if not entry['input'].startswith('.local/'):
        continue
    source = package / entry['snapshot']
    assert hashlib.sha256(source.read_bytes()).hexdigest() == entry['sha256']
    target = root / entry['input']
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
comparison = package / 'observers/inspect_civic_stationary.py'
assert hashlib.sha256(comparison.read_bytes()).hexdigest() == '42cfc0e6e70dbe3b21545e0aa41fbf34fe3177005cd0a13886924b72ce0604b5'
shutil.copy2(comparison, root / '.local/inspect_civic_stationary.py')
print('Restored exact civic observer, display launcher and read-only comparator')

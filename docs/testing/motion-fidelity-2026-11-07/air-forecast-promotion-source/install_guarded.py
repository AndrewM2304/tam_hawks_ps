#!/usr/bin/env python3
"""Root-only explicit installer; defaults to a read-only guard check."""
from pathlib import Path
import hashlib,json,sys,shutil
root=Path('/workspace/tam_hawks_ps');bundle=Path(__file__).resolve().parent
manifest=json.loads((bundle/'manifest.json').read_text())
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
expected={'game/player/skater.gd':manifest['actual_controller_base_sha256'],'tests/line_design_tests.gd':manifest['actual_line_test_base_sha256'],'game/player/skater_visual.gd':manifest['unchanged_visual_sha256']}
for rel,want in expected.items():
 actual=sha(root/rel)
 if actual!=want:raise SystemExit(f'REFUSED base source changed: {rel} {actual} != {want}')
for rel,want in manifest['files'].items():
 if sha(bundle/Path(rel).name)!=want:raise SystemExit(f'REFUSED candidate bytes changed: {rel}')
print('READ_ONLY_GUARDS_PASS current controller/test/visual and exactcandidate bytes')
if sys.argv[1:]!=['--install']:
 print('No production files modified; root may explicitly invoke --install.');raise SystemExit(0)
backup=bundle/'preinstall'
if backup.exists():raise SystemExit('REFUSED existing preinstall directory; inspect before repeating install')
backup.mkdir()
for rel in expected:
 shutil.copy2(root/rel,backup/Path(rel).name)
for rel,want in manifest['files'].items():
 shutil.copy2(bundle/Path(rel).name,root/rel)
 assert sha(root/rel)==want
assert sha(root/'game/player/skater_visual.gd')==expected['game/player/skater_visual.gd']
print('INSTALLED exact reviewedforecast controller+independent observer; visualunchanged; backup retained')

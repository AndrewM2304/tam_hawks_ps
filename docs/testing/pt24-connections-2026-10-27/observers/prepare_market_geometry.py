"""Reconstruct the immutable old query and copy the exact focused observer."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
root = Path(__file__).resolve().parents[4]
legacy_commit = '69fcbc836e79e87f3a1734b7fb200b35c45f7ae6'
source = subprocess.check_output(['git', 'show', legacy_commit + ':game/levels/core_terrain.gd'], cwd=root)
local = root / '.local'
local.mkdir(exist_ok=True)
(local / 'market_legacy_terrain.gd').write_bytes(source)
shutil.copyfile(Path(__file__).with_name('market_geometry_focused.gd'), local / 'market_geometry_focused.gd')
print(json.dumps({'legacy_commit': legacy_commit, 'legacy_source': 'game/levels/core_terrain.gd',
                  'legacy_sha256': hashlib.sha256(source).hexdigest(),
                  'observer_sha256': hashlib.sha256((local / 'market_geometry_focused.gd').read_bytes()).hexdigest()}, indent=2))

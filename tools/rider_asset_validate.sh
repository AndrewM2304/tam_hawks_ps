#!/usr/bin/env bash
# Native body/contact/resource checks with a source-bound receipt. A zero
# internal failure count never overrides a Godot resource or script error.
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
TASK_EVIDENCE="${RIDER_VALIDATION_OUTPUT:-$TASK_ROOT/.local/fidelity/rider-validation}"
mkdir -p "$TASK_EVIDENCE"
python3 - "$TASK_EVIDENCE/source-before.json" <<'PY'
from pathlib import Path
import hashlib, json, sys
root = Path.cwd()
paths = {Path('project.godot'), Path('tools/run.sh'), Path('tools/rider_asset_validate.sh'),
         Path('tools/rider_asset_validate.gd')}
for directory in ['game/player', 'tests']:
    paths.update(Path(directory).rglob('*.gd'))
for directory in ['game/art/rider', 'game/art/assets/makehuman_hm08', 'game/art/assets/tam_skateboard']:
    paths.update(p for p in Path(directory).rglob('*') if p.is_file())
manifest = {str(p): hashlib.sha256((root / p).read_bytes()).hexdigest() for p in sorted(paths)}
Path(sys.argv[1]).write_text(json.dumps(manifest, indent=2) + '\n')
PY
set +e
./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script tools/rider_asset_validate.gd \
  2>&1 | tee "$TASK_EVIDENCE/native.log"
TASK_ENGINE_STATUS=${PIPESTATUS[0]}
set -e
python3 - "$TASK_EVIDENCE" "$TASK_ENGINE_STATUS" <<'PY'
from datetime import datetime, timezone
from pathlib import Path
import hashlib, json, re, sys
output = Path(sys.argv[1])
before = json.loads((output / 'source-before.json').read_text())
after = {p: hashlib.sha256(Path(p).read_bytes()).hexdigest() if Path(p).is_file() else None for p in before}
raw = (output / 'native.log').read_bytes()
log = raw.decode(errors='replace')
result = re.search(r'^RESULT: (\d+) passed, (\d+) failed$', log, re.M)
inventory = re.search(r'^RIDER_INVENTORY triangles=(\d+) surfaces=(\d+) meshes=(\d+) unique_textures=(\d+) rgba_mip_bytes_estimate=(\d+)$', log, re.M)
clean = not re.search(r'SCRIPT ERROR:|Parse Error:|ERROR:', log)
accepted = (int(sys.argv[2]) == 0 and clean and before == after and result is not None
            and int(result[1]) > 0 and int(result[2]) == 0 and inventory is not None)
receipt = {'purpose': 'Headless native body/contact/resource regression; visual and hardware acceptance remain separate.',
           'captured_at_utc': datetime.now(timezone.utc).isoformat(),
           'engine_exit_code': int(sys.argv[2]), 'engine_log_clean': clean,
           'engine_log_sha256': hashlib.sha256(raw).hexdigest(),
           'source_stable': before == after, 'source_sha256': before,
           'passed': int(result[1]) if result else 0, 'failed': int(result[2]) if result else None,
           'accepted': accepted}
if inventory:
    receipt['inventory'] = dict(zip(['triangles', 'surfaces', 'meshes', 'unique_textures',
                                     'rgba_mip_bytes_estimate'], map(int, inventory.groups())))
(output / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
print('Rider native validation ' + ('accepted.' if accepted else 'rejected; inspect receipt and raw log.'))
sys.exit(0 if accepted else 1)
PY

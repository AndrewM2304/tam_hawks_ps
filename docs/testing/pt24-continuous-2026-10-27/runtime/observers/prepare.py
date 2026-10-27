"""Stage bounded camera observers and the immutable original camera locally."""
from pathlib import Path
import hashlib,json,shutil,subprocess
root=Path.cwd()
if not (root/'project.godot').is_file():raise SystemExit('Run from the repository root.')
local=root/'.local';local.mkdir(exist_ok=True)
source=Path(__file__).resolve().parent
for name in ['camera_reuse_focused.gd','camera_reuse_legacy_parity.gd']:
    shutil.copyfile(source/name,local/name)
commit='700e304861c282bb11dcd762c0cae04a06ec2642'
path='game/player/chase_camera.gd'
data=subprocess.check_output(['git','show',commit+':'+path])
expected='30dbff9dd1d6e93a9a668552158ef12a4667b48e512de21e393b0544b6c3f1cb'
if hashlib.sha256(data).hexdigest()!=expected:raise SystemExit('Original camera does not match its inspected source.')
target=local/'camera_reuse_legacy_camera.gd';target.write_bytes(data)
(local/'camera-reuse-legacy-source.json').write_text(json.dumps({'git_commit':commit,'git_path':path,'sha256':expected,'local_path':str(target.relative_to(root))},indent=2)+'\n')
print('Staged two camera observers and the exact original source under .local.')

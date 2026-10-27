"""Stage the bounded actual-rig fallback allocation witness under .local."""
from pathlib import Path
import shutil
root=Path.cwd()
if not (root/'project.godot').is_file():raise SystemExit('Run from the repository root.')
local=root/'.local';local.mkdir(exist_ok=True)
shutil.copyfile(Path(__file__).resolve().with_name('grab_pose_cache_focused.gd'),local/'grab_pose_cache_focused.gd')
print('Staged the bounded grab fallback observer under .local.')

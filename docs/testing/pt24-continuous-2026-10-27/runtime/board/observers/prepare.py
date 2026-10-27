"""Stage the bounded board-support parameter-object witness under .local."""
from pathlib import Path
import shutil
root=Path.cwd()
if not (root/'project.godot').is_file():raise SystemExit('Run from the repository root.')
local=root/'.local';local.mkdir(exist_ok=True)
shutil.copyfile(Path(__file__).resolve().with_name('board_floor_ray_focused.gd'),local/'board_floor_ray_focused.gd')
print('Staged the bounded board support observer under .local.')

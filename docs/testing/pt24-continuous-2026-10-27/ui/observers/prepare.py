"""Restore the exact admitted ignored observers; game/test sources stay tracked."""
from pathlib import Path
import hashlib
import json
import shutil

root = Path.cwd()
evidence = root / "docs/testing/pt24-continuous-2026-10-27/ui/focused"
for run, name in (("accepted", "menu_launch_focused.gd"),
                  ("render30", "menu_boundary_rates.gd")):
    folder = evidence / run
    source = folder / "source-snapshot/local" / name
    expected = json.loads((folder / "source-before.json").read_text())[".local/" + name]
    assert hashlib.sha256(source.read_bytes()).hexdigest() == expected
    target = root / ".local" / name
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)
    print(target.relative_to(root), expected)

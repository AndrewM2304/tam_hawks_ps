#!/usr/bin/env python3
"""Stage exact retained observers and verify the immutable causal controller."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess

here = Path(__file__).resolve().parent
root = here.parents[4]
local = root / ".local"
local.mkdir(exist_ok=True)
record = json.loads((here / "wall_ollie_legacy_sources.json").read_text())
legacy = subprocess.check_output(["git", "show", f"{record['git']}:{record['path']}"], cwd=root)
assert hashlib.sha256(legacy).hexdigest() == record["sha256"]
assert legacy == (here / "wall_ollie_legacy_skater.gd").read_bytes()
for name in ("wall_ollie_capture.gd", "wall_ollie_capture.sh", "wall_ollie_legacy_skater.gd", "wall_ollie_legacy_sources.json"):
    shutil.copy2(here / name, local / name)
(local / "wall_ollie_capture.sh").chmod(0o755)
print("Staged four-frame native wall observer and verified exact legacy controller.")

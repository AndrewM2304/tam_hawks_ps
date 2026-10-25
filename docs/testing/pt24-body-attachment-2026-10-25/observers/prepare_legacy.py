"""Prepare the immutable previous visual comparison, from the repository root."""
from pathlib import Path
import subprocess
import hashlib
import json
root=Path.cwd()
output=root/".local"
output.mkdir(exist_ok=True)
commit="b7d9aa60b8951b114466d7acd2a98796d2995e41"
visual=subprocess.check_output(["git","show",commit+":game/player/skater_visual.gd"])
(output/"body_attachment_legacy_visual.gd").write_bytes(visual)
controller=(root/"game/player/skater.gd").read_text()
legacy=controller.replace("res://game/player/skater_visual.gd","res://.local/body_attachment_legacy_visual.gd")
assert legacy!=controller
(output/"body_attachment_legacy_skater.gd").write_text(legacy)
for name in ("body_attachment_capture.gd","body_attachment_capture.sh"):
 (output/name).write_bytes((Path(__file__).parent/name).read_bytes())
(output/"body_attachment_capture.sh").chmod(0o755)
print(json.dumps({"commit":commit,"previous_visual_sha256":hashlib.sha256(visual).hexdigest(),"controller_change":"Only the visual preload; no physical/controller difference."},indent=2))

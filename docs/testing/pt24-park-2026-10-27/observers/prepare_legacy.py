"""Prepare immutable old-controller comparison; run from the repository root."""
from pathlib import Path
import hashlib
import json
import subprocess
root=Path.cwd()
output=root/".local"
output.mkdir(exist_ok=True)
commit="c82ffac26265de4a379d5079ad61ece08075fa0e"
legacy=subprocess.check_output(["git","show",commit+":game/player/skater.gd"])
visual=subprocess.check_output(["git","show",commit+":game/player/skater_visual.gd"])
assert visual==(root/"game/player/skater_visual.gd").read_bytes(), "Comparison requires unchanged body-fixed visual"
assert b'res://game/player/skater_visual.gd' in legacy
(output/"wall_contact_legacy_skater.gd").write_bytes(legacy)
record={"commit":commit,"old_controller_sha256":hashlib.sha256(legacy).hexdigest(),
 "common_visual_sha256":hashlib.sha256(visual).hexdigest(),
 "controller_edits":"None: exact Git object. Only the capture's legacy-controller preload uses the ignored local copy.",
 "common_visual":"Both controllers preload the same unchanged current body-fixed skater_visual.gd."}
(output/"wall_contact_legacy_sources.json").write_text(json.dumps(record,indent=2)+"\n")
for name in ("wall_contact_capture.gd","wall_contact_capture.sh"):
 (output/name).write_bytes((Path(__file__).parent/name).read_bytes())
(output/"wall_contact_capture.sh").chmod(0o755)
print(json.dumps(record,indent=2))

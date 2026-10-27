from pathlib import Path
import hashlib,json,subprocess
root=Path.cwd()
visual=subprocess.check_output(["git","show","700e304:game/player/skater_visual.gd"])
old=root/".local/skitch_attachment_baseline_visual.gd"
old.write_bytes(visual)
rows=[{"kind":"exact old visual","source":"700e304:game/player/skater_visual.gd","path":str(old.relative_to(root)),"sha256":hashlib.sha256(visual).hexdigest()}]
for source,target,replacements in [
("game/player/skater.gd","skitch_attachment_legacy_skater.gd",[("res://game/player/skater_visual.gd","res://.local/skitch_attachment_baseline_visual.gd")]),
("game/main.gd","skitch_attachment_legacy_main.gd",[("res://game/player/skater.gd","res://.local/skitch_attachment_legacy_skater.gd")]),
("tests/authentic_pose_tests.gd","skitch_attachment_legacy_authentic.gd",[("res://game/player/skater_visual.gd","res://.local/skitch_attachment_baseline_visual.gd")]),
("tests/skater_skitch_attachment_tests.gd","skitch_attachment_legacy_tests.gd",[("res://tests/authentic_pose_tests.gd","res://.local/skitch_attachment_legacy_authentic.gd"),("res://game/main.gd","res://.local/skitch_attachment_legacy_main.gd")])]:
 data=(root/source).read_text()
 original=hashlib.sha256(data.encode()).hexdigest()
 for before,after in replacements:
  assert data.count(before)==1,(source,before)
  data=data.replace(before,after)
 p=root/".local"/target;p.write_text(data)
 rows.append({"kind":"preload-only redirect","source":source,"source_sha256":original,"path":str(p.relative_to(root)),"sha256":hashlib.sha256(p.read_bytes()).hexdigest(),"replacements":replacements})
(root/".local/skitch_attachment_legacy_sources.json").write_text(json.dumps(rows,indent=2)+"\n")
print("Prepared exact old visual and preload-only native/pose controls")

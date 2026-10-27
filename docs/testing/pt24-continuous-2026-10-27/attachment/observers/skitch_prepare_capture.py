from pathlib import Path
import hashlib,json
root=Path.cwd()
source=root/'game/player/skater_visual.gd';data=source.read_text();original=hashlib.sha256(data.encode()).hexdigest()
replacements=[('''\t\tvar toward_shift := Vector3(toward.x, 0, toward.z).limit_length(0.12) * _skitch_blend
\t\t_upper.position += toward_shift
\t\t# The existing tow lean belongs to the connected torso and pelvis.
\t\thips_origin += toward_shift
\t\thips_y = hips_origin.y''','''\t\t_upper.position += Vector3(toward.x, 0, toward.z).limit_length(0.12) * _skitch_blend'''),('''\tif skitch_pose:
\t\tvar unconstrained_torso := _upper.position
\t\tfor iteration in 5:''','''\tif skitch_pose:
\t\tfor iteration in 5:'''),('''\t\t# Preserve the authored palm-reach path while the legs share its shift.
\t\thips_origin += _upper.position - unconstrained_torso
\t\thips_y = hips_origin.y
''','')]
for before,after in replacements:
 assert data.count(before)==1,(before,data.count(before))
 data=data.replace(before,after)
visual=root/'.local/skitch_attachment_capture_before_visual.gd';visual.write_text(data)
controller=root/'game/player/skater.gd';body=controller.read_text();needle='res://game/player/skater_visual.gd'
assert body.count(needle)==1
body=body.replace(needle,'res://.local/skitch_attachment_capture_before_visual.gd')
legacy=root/'.local/skitch_attachment_capture_before_skater.gd';legacy.write_text(body)
records={'method':'Frozen current visual with only the three approved skitch attachment hunks reversed exactly once; current grab fallback cache and every other visual/controller change remain. Current controller differs only by this visual preload. Exact700e304 negative control remains separately archived.','visual_source_sha256':original,'before_visual_sha256':hashlib.sha256(visual.read_bytes()).hexdigest(),'controller_source_sha256':hashlib.sha256(controller.read_bytes()).hexdigest(),'before_controller_sha256':hashlib.sha256(legacy.read_bytes()).hexdigest(),'reverse_replacements':replacements,'controller_preload':[[needle,'res://.local/skitch_attachment_capture_before_visual.gd']]}
(root/'.local/skitch_attachment_capture_sources.json').write_text(json.dumps(records,indent=2)+'\n')
print('Prepared isolated attachment before-visual; exact3hunks reversed once, current cache retained',records['before_visual_sha256'])

from pathlib import Path
import hashlib,json
root=Path.cwd(); local=root/'.local'
new='''\t# Keep the original display slots/transforms/materials and all physical data.
\t# Reallocate redundant straight height rings into a hollow, turned profile.
\tfor part: Array in [["FountainPedestal",Vector3(0,1.2,0),"stone_light"],
\t\t\t["FountainBowl",Vector3(0,2.1,0),"stone_light"],
\t\t\t["FountainCrown",Vector3(0,2.7,0),"bronze"]]:
\t\tvar ornament := MeshInstance3D.new()
\t\tornament.name = part[0]
\t\tornament.set_meta("art_label",part[0])
\t\tornament.position = part[1]
\t\tornament.mesh = preload("res://game/levels/art/fountain_ornament.gd").shared_mesh(part[0])
\t\tornament.material_override = _materials[part[2]]
\t\tbody.add_child(ornament)
'''
old='''\t_cylinder(body, "FountainPedestal", Vector3(0, 1.2, 0), 0.65, 1.0, 2.0, "stone_light")
\t_cylinder(body, "FountainBowl", Vector3(0, 2.1, 0), 1.65, 0.65, 0.5, "stone_light")
\t_cylinder(body, "FountainCrown", Vector3(0, 2.7, 0), 0.22, 0.42, 0.85, "bronze")
'''
world=root/'game/levels/glasgow_square.gd';main=root/'game/main.gd'
assert world.read_text().count(new)==1
legacy_world=world.read_text().replace(new,old)
legacy_main=main.read_text().replace('preload("res://game/levels/glasgow_square.gd")','preload("res://.local/fountain_ornament_legacy_world.gd")')
assert legacy_main!=main.read_text()
(local/'fountain_ornament_legacy_world.gd').write_text(legacy_world)
(local/'fountain_ornament_legacy_main.gd').write_text(legacy_main)
manifest={'method':'Exact current source with only the three ornament display constructors restored; Main differs only in its World preload. No other world, rig, input, shader or gameplay change.', 'source':{str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [world,main]}, 'legacy':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [local/'fountain_ornament_legacy_world.gd',local/'fountain_ornament_legacy_main.gd']}}
(local/'fountain-ornament-legacy.json').write_text(json.dumps(manifest,indent=2)+'\n')

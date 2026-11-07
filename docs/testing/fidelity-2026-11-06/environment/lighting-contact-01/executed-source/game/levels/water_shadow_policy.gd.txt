extends RefCounted
## Opaque water proxies receive scene shadows but must not shadow themselves.
## Exact audited shader identity only; no name/path/metadata heuristic.
const WATER = preload("res://game/art/assets/horizon/clyde_water.gdshader")

static func apply(root_node: Node) -> Dictionary:
	var records: Array[Dictionary] = []
	var unsupported: Array[Dictionary] = []
	var changed := 0
	for instance: GeometryInstance3D in root_node.find_children("*","GeometryInstance3D",true,false):
		var classification := classify(instance)
		if not classification.matched: continue
		if not classification.eligible:
			unsupported.append({"path":str(root_node.get_path_to(instance)),"reason":classification.reason})
			continue
		var before := instance.cast_shadow
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if before != instance.cast_shadow: changed += 1
		records.append({"path":str(root_node.get_path_to(instance)),"instance_id":instance.get_instance_id(),
			"before_cast_shadow":before,"after_cast_shadow":instance.cast_shadow,"material_id":instance.material_override.get_instance_id() if instance.material_override else 0})
	return {"shader_path":WATER.resource_path,"shader_instance_id":WATER.get_instance_id(),
		"matched_count":records.size(),"changed_count":changed,"water_instances":records,"unsupported":unsupported}

static func classify(instance: GeometryInstance3D) -> Dictionary:
	if not instance is MeshInstance3D and not instance is MultiMeshInstance3D:
		return {"matched":false,"eligible":false,"reason":"not a mesh instance"}
	var materials: Array[Material] = []
	if instance.material_override:
		materials.append(instance.material_override)
	else:
		var mesh: Mesh = instance.mesh if instance is MeshInstance3D else (instance.multimesh.mesh if instance.multimesh else null)
		if mesh:
			for surface: int in mesh.get_surface_count():
				var material: Material = instance.get_surface_override_material(surface) if instance is MeshInstance3D else null
				materials.append(material if material else mesh.surface_get_material(surface))
	var matched := _references_water(instance.material_overlay,{})
	var pure := not materials.is_empty()
	for material: Material in materials:
		matched = _references_water(material,{}) or matched
		pure = _exact(material) and material.next_pass == null and pure
	if not matched: return {"matched":false,"eligible":false,"reason":"non-water materials"}
	if not pure: return {"matched":true,"eligible":false,"reason":"mixed, foreign or extra-pass material"}
	if instance.material_overlay != null: return {"matched":true,"eligible":false,"reason":"material overlay retained"}
	if instance.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
		return {"matched":true,"eligible":false,"reason":"shadow-only geometry would change visible content"}
	return {"matched":true,"eligible":true,"reason":"all effective surfaces use exact opaque shared water shader"}

static func _exact(material: Material) -> bool:
	return material is ShaderMaterial and material.shader == WATER

static func _references_water(material: Material,seen: Dictionary) -> bool:
	if material == null or seen.has(material.get_instance_id()): return false
	seen[material.get_instance_id()] = true
	return _exact(material) or _references_water(material.next_pass,seen)

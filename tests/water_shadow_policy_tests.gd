extends RefCounted
const Policy = preload("res://game/levels/water_shadow_policy.gd")

static func run(tree: SceneTree,check: Callable) -> void:
	var scene:=Node3D.new()
	tree.root.add_child(scene)
	var water:=ShaderMaterial.new()
	water.shader=Policy.WATER
	var native:=StandardMaterial3D.new()
	var lookalike:=ShaderMaterial.new()
	lookalike.shader=Policy.WATER.duplicate() as Shader
	var extra:=ShaderMaterial.new()
	extra.shader=Policy.WATER
	extra.next_pass=native
	var instances: Dictionary={}
	for key: String in ["water","solid","lookalike","extra-pass","overlay","shadow-only"]:
		var mesh:=MeshInstance3D.new()
		mesh.name=key
		mesh.mesh=BoxMesh.new()
		mesh.material_override=water if key in ["water","overlay","shadow-only"] else (lookalike if key=="lookalike" else (extra if key=="extra-pass" else native))
		if key=="overlay":mesh.material_overlay=native
		if key=="shadow-only":mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		scene.add_child(mesh)
		instances[key]=mesh
	var multi:=MultiMeshInstance3D.new()
	multi.name="multimesh-water"
	multi.multimesh=MultiMesh.new()
	multi.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	multi.multimesh.mesh=BoxMesh.new()
	multi.multimesh.instance_count=2
	multi.material_override=water
	scene.add_child(multi)
	var embedded:=MeshInstance3D.new()
	embedded.name="embedded-water"
	var embedded_mesh:=BoxMesh.new()
	embedded_mesh.material=water
	embedded.mesh=embedded_mesh
	scene.add_child(embedded)
	var mixed:=MeshInstance3D.new()
	mixed.name="mixed-water-solid"
	var combined:=ArrayMesh.new()
	for material: Material in [water,native]:
		combined.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,BoxMesh.new().surface_get_arrays(0))
		combined.surface_set_material(combined.get_surface_count()-1,material)
	mixed.mesh=combined
	scene.add_child(mixed)
	var surface_override_water:=MeshInstance3D.new()
	surface_override_water.name="effective-water-override"
	var solid_source:=BoxMesh.new()
	solid_source.material=native
	surface_override_water.mesh=solid_source
	surface_override_water.set_surface_override_material(0,water)
	scene.add_child(surface_override_water)
	var surface_override_native:=MeshInstance3D.new()
	surface_override_native.name="water-hidden-by-surface-override"
	surface_override_native.mesh=embedded_mesh
	surface_override_native.set_surface_override_material(0,native)
	scene.add_child(surface_override_native)
	var global_override_native:=MeshInstance3D.new()
	global_override_native.name="water-hidden-by-global-override"
	global_override_native.mesh=embedded_mesh
	global_override_native.material_override=native
	scene.add_child(global_override_native)
	var resources := [water.get_instance_id(),native.get_instance_id(),multi.multimesh.get_instance_id(),embedded.mesh.get_instance_id(),mixed.mesh.get_instance_id()]
	var report:=Policy.apply(scene)
	check.call(report.matched_count==4 and report.changed_count==4,"only effective exact water override, embedded, MultiMesh and per-surface override instances change")
	check.call(report.unsupported.size()==4,"extra pass, overlay, shadow-only and mixed material cases remain explicit unsupported")
	for node: GeometryInstance3D in [instances.water,multi,embedded,surface_override_water]:check.call(node.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"pure exact water stops casting")
	for key: String in ["solid","lookalike","extra-pass","overlay"]:check.call(instances[key].cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_ON,"non-water/unsupported caster remains unchanged: "+key)
	check.call(instances["shadow-only"].cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY and mixed.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_ON,"mixed/hidden geometry retains original rendering semantics")
	check.call(resources==[water.get_instance_id(),native.get_instance_id(),multi.multimesh.get_instance_id(),embedded.mesh.get_instance_id(),mixed.mesh.get_instance_id()],"material, mesh and instance resources retain native identities")
	check.call(surface_override_native.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_ON and global_override_native.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_ON,"native per-surface/global overrides mask an embedded water material without changing casting")
	check.call(surface_override_water.get_surface_override_material(0)==water and surface_override_native.get_surface_override_material(0)==native and global_override_native.material_override==native,"effective override resource identities remain unchanged")
	check.call(Policy.apply(scene).changed_count==0,"policy is idempotent")
	check.call(not Policy.WATER.code.contains("shadows_disabled"),"water shader continues to receive real scene shadows")
	scene.free()

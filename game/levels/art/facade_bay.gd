extends RefCounted
## One original fitted foreground bay. Native visibility owns LOD selection;
## this helper runs only during world construction, never per frame.

const META: StringName = &"glasgow_bay_proof"
const REPORT: StringName = &"glasgow_bay_report"
const AUDIT_RECORDS: StringName = &"glasgow_bay_front_records"
const STRIP := Vector2(-9.0, -2.5)
const MOUNT := Vector3(-5.75, 0.0, 6.0)
const DEFAULT_ENABLED := false # Enable only after matched pilot acceptance.
const LEVELS: Array[String] = ["near", "mid", "far"]
const SLOT_NAMES: Array[String] = ["01_Original_sandstone", "02_Painted_forest_joinery",
	"03_Opaque_glazing", "04_Aged_dark_metal"]
const ASSET_ROOT := "res://game/art/assets/glasgow_bay/"
static var _materials: Array[Material] = []
static var _meshes: Array[Mesh] = []


static func enabled(world: Node) -> bool:
	return bool(world.get_meta(&"facade_bay_enabled", DEFAULT_ENABLED))


static func install(building: Node3D, wall: Node3D, audit: bool = false) -> bool:
	# Validate the complete replacement before touching any existing visual.
	if not _load_resources(): return false
	var visual: MeshInstance3D
	for child: Node in wall.get_children():
		if child is MeshInstance3D: visual = child
	if visual == null or not visual.mesh is BoxMesh or not visual.mesh.size.is_equal_approx(Vector3(30,16,12)):
		push_error("Fitted facade needs its original 30 x 16 x 12 visual/collision wall.")
		return false
	var holder := Node3D.new()
	holder.name = "GlasgowBayLOD"
	holder.position = MOUNT
	building.add_child(holder)
	var instances: Array[MeshInstance3D] = []
	for index: int in range(LEVELS.size()):
		var instance := MeshInstance3D.new()
		instance.name = LEVELS[index].capitalize()
		instance.mesh = _meshes[index]
		for slot: int in range(_materials.size()):
			instance.set_surface_override_material(slot, _materials[slot])
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		holder.add_child(instance)
		instances.append(instance)
	instances[2].visibility_range_begin = 80.0
	instances[2].visibility_range_begin_margin = 6.0
	instances[1].visibility_range_begin = 25.0
	instances[1].visibility_range_begin_margin = 4.0
	instances[1].visibility_parent = instances[1].get_path_to(instances[2])
	instances[0].visibility_parent = instances[0].get_path_to(instances[1])
	visual.mesh = open_front_mesh(Vector3(30,16,12), STRIP)
	building.set_meta(META, true)
	building.set_meta(&"facade_bay_audit", audit)
	building.set_meta(REPORT, {"omitted_window_groups":0, "omitted_shop_bays":0,
		"clipped_records":0, "omitted_records":0, "baseline_front_records":0,
		"retained_front_records":0})
	return true


static func _load_resources() -> bool:
	if _meshes.size() == LEVELS.size(): return true
	var loaded: Array[Mesh] = []
	for level: String in LEVELS:
		var path := ASSET_ROOT + "glasgow_bay_" + level + ".glb"
		var packed := load(path) as PackedScene
		if packed == null:
			push_error("Fitted facade asset cannot load: " + path)
			return false
		var model := packed.instantiate()
		var nodes := model.find_children("*", "MeshInstance3D", true, false)
		if nodes.size() != 1 or nodes[0].mesh.get_surface_count() != 4:
			model.free()
			push_error("Fitted facade must import as one four-surface mesh: " + path)
			return false
		var item: MeshInstance3D = nodes[0]
		for slot: int in range(SLOT_NAMES.size()):
			var material: Material = item.mesh.surface_get_material(slot)
			if material == null or material.resource_name != SLOT_NAMES[slot]:
				model.free()
				push_error("Fitted facade surface names/order differ from the audited material contract.")
				return false
		var frame := item.transform
		var ancestor: Node = item.get_parent()
		while ancestor != null:
			if ancestor is Node3D: frame = ancestor.transform * frame
			if ancestor == model: break
			ancestor = ancestor.get_parent()
		if not frame.is_equal_approx(Transform3D.IDENTITY):
			model.free()
			push_error("Fitted facade import must have applied metre/axis transforms.")
			return false
		loaded.append(item.mesh)
		model.free()
	if not _make_materials(): return false
	_meshes = loaded
	return true


static func _make_materials() -> bool:
	if _materials.size() == 4: return true
	var textures: Array[Texture2D] = []
	for filename: String in ["sandstone_basecolor.png", "sandstone_normal_opengl.png",
		"sandstone_orm.png", "opaque_glazing_basecolor.png"]:
		var texture := load(ASSET_ROOT + "textures/" + filename) as Texture2D
		if texture == null or texture.get_width() != 1024 or texture.get_height() != 1024:
			push_error("Fitted facade needs its four shared 1024px original maps.")
			return false
		textures.append(texture)
	var stone := StandardMaterial3D.new()
	stone.resource_name = SLOT_NAMES[0]
	stone.albedo_texture = textures[0]
	stone.normal_enabled = true
	stone.normal_texture = textures[1]
	stone.normal_scale = 1.0
	stone.roughness_texture = textures[2]
	stone.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	stone.roughness = 1.0
	var paint := StandardMaterial3D.new()
	paint.resource_name = SLOT_NAMES[1]
	# glTF factors are linear; Godot's albedo property uses sRGB colour values.
	paint.albedo_color = Color(0.028, 0.085, 0.067).linear_to_srgb()
	paint.roughness = 0.48
	var glass := StandardMaterial3D.new()
	glass.resource_name = SLOT_NAMES[2]
	glass.albedo_texture = textures[3]
	glass.roughness = 0.32
	glass.metallic = 0.0
	var metal := StandardMaterial3D.new()
	metal.resource_name = SLOT_NAMES[3]
	metal.albedo_color = Color(0.105, 0.095, 0.069).linear_to_srgb()
	metal.metallic = 0.65
	metal.roughness = 0.46
	_materials = [stone, paint, glass, metal]
	for material: StandardMaterial3D in _materials:
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		material.cull_mode = BaseMaterial3D.CULL_BACK
	return true


static func overlaps(center: float, width: float) -> bool:
	return center + width * 0.5 > STRIP.x and center - width * 0.5 < STRIP.y


static func filter_front(batches: Dictionary, building: Node3D) -> void:
	if not bool(building.get_meta(META, false)): return
	var report: Dictionary = building.get_meta(REPORT)
	for key: String in batches.keys():
		var batch: Dictionary = batches[key]
		var retained: Array = []
		for frame: Transform3D in batch.transforms:
			report.baseline_front_records += 1
			var kind: String = batch.get("mesh_kind", "box")
			var width: float = absf(frame.basis.x.x)
			# Front boxes may slope around X (awnings), but never around Y/Z.
			if not overlaps(frame.origin.x, width):
				retained.append(frame)
				continue
			if kind != "box" or absf(frame.basis.y.x) > 0.000001 or absf(frame.basis.z.x) > 0.000001:
				report.omitted_records += 1
				continue
			var lo := frame.origin.x - width * 0.5
			var hi := frame.origin.x + width * 0.5
			for span: Vector2 in [Vector2(lo, minf(hi, STRIP.x)), Vector2(maxf(lo, STRIP.y), hi)]:
				if span.y - span.x <= 0.000001: continue
				var clipped := frame
				clipped.origin.x = (span.x + span.y) * 0.5
				clipped.basis.x *= (span.y - span.x) / width
				retained.append(clipped)
				report.clipped_records += 1
			if lo >= STRIP.x and hi <= STRIP.y: report.omitted_records += 1
		batch.transforms = retained
		report.retained_front_records += retained.size()
		if retained.is_empty(): batches.erase(key)
		else: batches[key] = batch
	building.set_meta(REPORT, report)
	if bool(building.get_meta(&"facade_bay_audit", false)):
		var records: Array = building.get_meta(AUDIT_RECORDS, [])
		for key: String in batches:
			var batch: Dictionary = batches[key]
			for frame: Transform3D in batch.transforms:
				records.append({"mesh_kind":batch.get("mesh_kind", "box"),
					"material":batch.material, "transform":frame})
		building.set_meta(AUDIT_RECORDS, records)


static func open_front_mesh(size: Vector3, strip: Vector2) -> ArrayMesh:
	# Wall-local origin is its centre. Only front triangles are replaced;
	# the caller retains the original StaticBody3D/BoxShape and its transform.
	var h := size * 0.5
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_quad(surface, Vector3(-h.x,-h.y,h.z), Vector3(strip.x,-h.y,h.z), Vector3(strip.x,h.y,h.z), Vector3(-h.x,h.y,h.z), Vector3.BACK)
	_quad(surface, Vector3(strip.y,-h.y,h.z), Vector3(h.x,-h.y,h.z), Vector3(h.x,h.y,h.z), Vector3(strip.y,h.y,h.z), Vector3.BACK)
	_quad(surface, Vector3(-h.x,-h.y,-h.z), Vector3(h.x,-h.y,-h.z), Vector3(h.x,h.y,-h.z), Vector3(-h.x,h.y,-h.z), Vector3.FORWARD)
	_quad(surface, Vector3(-h.x,-h.y,-h.z), Vector3(-h.x,-h.y,h.z), Vector3(-h.x,h.y,h.z), Vector3(-h.x,h.y,-h.z), Vector3.LEFT)
	_quad(surface, Vector3(h.x,-h.y,-h.z), Vector3(h.x,-h.y,h.z), Vector3(h.x,h.y,h.z), Vector3(h.x,h.y,-h.z), Vector3.RIGHT)
	_quad(surface, Vector3(-h.x,h.y,-h.z), Vector3(h.x,h.y,-h.z), Vector3(h.x,h.y,h.z), Vector3(-h.x,h.y,h.z), Vector3.UP)
	_quad(surface, Vector3(-h.x,-h.y,-h.z), Vector3(h.x,-h.y,-h.z), Vector3(h.x,-h.y,h.z), Vector3(-h.x,-h.y,h.z), Vector3.DOWN)
	surface.generate_tangents()
	return surface.commit()


static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	for triangle: Array in [[a,b,c],[a,c,d]]:
		if (triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).dot(normal) > 0.0: triangle.reverse()
		for at: Vector3 in triangle:
			surface.set_normal(normal)
			var uv := Vector2(at.x, at.y)
			if absf(normal.x) > 0.5: uv = Vector2(at.z, at.y)
			elif absf(normal.y) > 0.5: uv = Vector2(at.x, at.z)
			surface.set_uv(uv)
			surface.add_vertex(at)

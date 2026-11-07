extends RefCounted
## Anatomical MakeHuman CC0 derivatives; see the asset manifest and retained licence.
## Only visible geometry/materials live here. The skating rig owns every pose target.

const HEAD: Mesh = preload("res://game/art/rider/fitted_head.obj")
const HAIR: Mesh = preload("res://game/art/rider/fitted_hair.obj")
const LEFT_HAND: Mesh = preload("res://game/art/assets/makehuman_hm08/left_hand.obj")
const RIGHT_HAND: Mesh = preload("res://game/art/assets/makehuman_hm08/right_hand.obj")
## Physical marker on the retained palm mesh, unchanged by distal finger curl.
const PALM_CONTACT := Vector3(0, -0.075, -0.015)
# Baked from manifest head_markers_m; no runtime JSON/file-service dependency.
const EYE_CENTERS: Array[Vector3] = [Vector3(0.0294083333, 0.04127, -0.0787933333),
	Vector3(-0.0294083333, 0.04127, -0.0787933333)]
static var _head_cache: ArrayMesh
static var _hair_cache: ArrayMesh
static var _hand_cache: Dictionary = {}
var _skin: StandardMaterial3D
var _head_skin: StandardMaterial3D
static var _hand_atlas_layout: Dictionary = {}

func _init() -> void:
	_skin = _material(Color.WHITE, 0.68)
	_skin.metallic_specular = 0.30
	_skin.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_head_skin = _skin.duplicate()
	_apply_skin_maps(_head_skin, "head")

func build_head(parent: Node3D, automatic_neck_driver: bool = true) -> void:
	_instance(parent, "AnatomicalHead", _head_surface(), _head_skin)
	var hair_material := _material(Color.WHITE, 0.80)
	hair_material.metallic_specular = 0.18
	hair_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	hair_material.alpha_scissor_threshold = 0.35
	hair_material.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
	hair_material.alpha_antialiasing_edge = 0.20
	hair_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	hair_material.albedo_texture = preload("res://game/art/rider/fitted_hair_albedo.png")
	hair_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_instance(parent, "CroppedHair", _styled_hair(), hair_material)
	var brow_material := _material(Color.WHITE, 0.86)
	brow_material.albedo_texture = preload("res://game/art/rider/fitted_brows_albedo.png")
	brow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	brow_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	brow_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var brows := _instance(parent, "FittedBrows", preload("res://game/art/rider/fitted_brows.obj"), brow_material)
	brows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var eyes := _material(Color.WHITE, 0.13)
	eyes.metallic_specular = 0.68
	eyes.clearcoat_enabled = true
	eyes.clearcoat = 0.55
	eyes.clearcoat_roughness = 0.09
	eyes.albedo_texture = preload("res://game/art/rider/head_albedo.png")
	eyes.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_instance(parent, "FittedEyes", preload("res://game/art/rider/fitted_eyes.obj"), eyes)
	_bind_neck(parent, automatic_neck_driver)

func _bind_neck(parent: Node3D, automatic_neck_driver: bool) -> void:
	# This native constraint also serves the existing NPC callers, whose head
	# frames differ from the skater. Driver identity must be assigned LAST:
	# binding a bone while follow-mode is active can introduce a torso offset.
	var cursor: Node = parent.get_parent()
	var skeleton: Skeleton3D
	while cursor != null and skeleton == null:
		skeleton = cursor.get_node_or_null("ClothingSkeleton") as Skeleton3D
		cursor = cursor.get_parent()
	if skeleton == null or skeleton.find_bone("neck") < 0:
		return
	# Share the exact material object across the real head/body source seam,
	# including fine normal, roughness and specular response for every caller.
	for mesh in skeleton.get_parent().get_children():
		if mesh is MeshInstance3D and mesh.name == "UpperChest":
			mesh.material_override = _head_skin
	# Player owns the final Rider-local pose_head call; avoid a second global
	# constraint overwriting it after finite root fitting. NPC defaults retain it.
	if not automatic_neck_driver:
		return
	var driver := BoneAttachment3D.new()
	driver.name = "NeckSkinPose"
	parent.add_child(driver)
	driver.set_use_external_skeleton(true)
	driver.set_external_skeleton(driver.get_path_to(skeleton))
	driver.set_override_pose(true)
	driver.set_bone_name("neck")
	driver.transform = Transform3D.IDENTITY

func build_hand(parent: Node3D, side: float) -> Node3D:
	var node := Node3D.new()
	node.name = "LeftAnatomicalHand" if side < 0 else "RightAnatomicalHand"
	parent.add_child(node)
	# MakeHuman subject-left is +X; the rig's negative side is subject-right.
	var mesh := RIGHT_HAND if side < 0 else LEFT_HAND
	var hand_material: StandardMaterial3D = _skin.duplicate()
	_apply_skin_maps(hand_material, "right_hand" if side < 0 else "left_hand")
	_instance(node, "HandAndFingers", _hand_mesh(mesh), hand_material)
	return node

func _apply_skin_maps(material: StandardMaterial3D, part: String) -> void:
	material.albedo_texture = load("res://game/art/rider/" + part + "_albedo.png")
	material.roughness_texture = load("res://game/art/rider/" + part + "_roughness.png")
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.normal_enabled = true
	material.normal_texture = load("res://game/art/rider/" + part + "_normal.png")
	material.normal_scale = 0.35
	material.roughness = 1.0
	if part == "left_hand" or part == "right_hand":
		if _hand_atlas_layout.is_empty():
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://game/art/rider/hand-atlas-layout.json"))
			assert(parsed is Dictionary and parsed.get("schema", 0) == 1)
			_hand_atlas_layout = parsed.hands
		var layout: Dictionary = _hand_atlas_layout[part]
		var scale: Array = layout.material_uv1_scale
		var offset: Array = layout.material_uv1_offset
		# Positive uniform scale/offset + native repeat preserves every original
		# mesh UV/position/index/normal and the tangent basis used by the maps.
		material.uv1_scale = Vector3(float(scale[0]),float(scale[1]),float(scale[2]))
		material.uv1_offset = Vector3(float(offset[0]),float(offset[1]),float(offset[2]))
		material.texture_repeat = true

func _styled_hair() -> ArrayMesh:
	if _hair_cache != null:
		return _hair_cache
	_hair_cache = ArrayMesh.new()
	for surface in HAIR.get_surface_count():
		# The fibers are one startup-shared native surface. Keep its authored
		# silhouette matched to the full-detail face rather than an unrelated LOD.
		_hair_cache.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, HAIR.surface_get_arrays(surface))
	return _hair_cache

func pose_hand(node: Node3D, grabbing: float) -> void:
	var mesh: MeshInstance3D = node.get_node("HandAndFingers")
	mesh.set_blend_shape_value(0, lerpf(0.22, 1.0, grabbing))

func _hand_mesh(source: Mesh) -> ArrayMesh:
	var key := source.get_instance_id()
	if _hand_cache.has(key):
		return _hand_cache[key]
	var result := ArrayMesh.new()
	result.add_blend_shape("GripCurl")
	result.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_NORMALIZED
	for surface in source.get_surface_count():
		var arrays := source.surface_get_arrays(surface)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var curled := PackedVector3Array()
		var curled_normals := PackedVector3Array()
		for index in points.size():
			var point := points[index]
			# A continuous distal bend preserves the palm contact and leaves the
			# shorter thumb untouched. It is an authored visual curl, not hand physics.
			var distance := maxf(0.0, -point.y - 0.090)
			var angle := distance * 11.0
			curled.append(Vector3(point.x, point.y + distance - sin(angle) / 11.0,
				point.z - (1.0 - cos(angle)) / 11.0))
			curled_normals.append(Basis(Vector3.RIGHT, angle) * normals[index])
		var shape: Array = []
		shape.resize(Mesh.ARRAY_MAX)
		shape[Mesh.ARRAY_VERTEX] = curled
		shape[Mesh.ARRAY_NORMAL] = curled_normals
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [shape])
	# Blend values belong to each MeshInstance3D; the immutable geometry and
	# authored curl deltas can be shared by every activity actor and the player.
	_hand_cache[key] = result
	return result

func _head_surface() -> ArrayMesh:
	if _head_cache != null:
		return _head_cache
	_head_cache = ArrayMesh.new()
	# Keep full-detail head and scalp matched at chase distance. Imported generated
	# LODs must not independently collapse one surface through the other.
	for surface in HEAD.get_surface_count():
		_head_cache.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, HEAD.surface_get_arrays(surface))
	return _head_cache

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _instance(parent: Node3D, label: String, mesh: Mesh, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node)
	return node

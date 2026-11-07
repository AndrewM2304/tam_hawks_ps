extends RefCounted
## Source-fitted CC0 shoes; original flat laces. Contact authority is unchanged.
const SOLE_CONTACT := Vector3(0, -0.0605, 0)
const TOE_CONTACT := Vector3(0, 0.001, -0.115)
const ALBEDO: Texture2D = preload("res://game/art/rider/fitted_shoe_albedo.png")

static func build(parent: Node3D, upper_material: Material, sole_material: Material,
		seam_material: Material, side: float = 0.0) -> void:
	if is_zero_approx(side):
		side = -1.0 if String(parent.name).to_lower().begins_with("left") or parent.position.x < 0.0 else 1.0
	var label := "left" if side < 0 else "right"
	# Callers sometimes share denim with their shoe arguments. Duplicate it
	# before applying footwear maps, so trousers retain their own live material.
	var upper := _copy_material(upper_material, Color("343c42"), 0.86, 0.22)
	var sole := _copy_material(sole_material, Color("a5aaa3"), 0.92, 0.16)
	upper.albedo_texture = ALBEDO
	sole.albedo_texture = ALBEDO
	var laces := _copy_material(seam_material, Color("b9b7ad"), 0.94, 0.12)
	laces.albedo_texture = null
	laces.normal_enabled = false
	for part: String in ["sole", "upper", "laces"]:
		var instance := MeshInstance3D.new()
		instance.name = "Cupsole" if part == "sole" else ("CanvasUpper" if part == "upper" else "FlatLaces")
		instance.mesh = load("res://game/art/rider/fitted_shoe_" + label + "_" + part + ".obj")
		instance.material_override = sole if part == "sole" else (upper if part == "upper" else laces)
		parent.add_child(instance)

static func _copy_material(source: Material, fallback: Color, roughness: float,
		specular: float) -> StandardMaterial3D:
	var result: StandardMaterial3D
	if source is StandardMaterial3D:
		result = source.duplicate() as StandardMaterial3D
	else:
		result = StandardMaterial3D.new()
		result.albedo_color = fallback
	result.normal_enabled = false
	result.uv1_scale = Vector3.ONE
	result.uv1_offset = Vector3.ZERO
	result.roughness = roughness
	result.metallic_specular = specular
	result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return result

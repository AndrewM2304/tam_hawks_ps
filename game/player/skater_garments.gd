extends RefCounted
## Original ring-built garments with smooth skin weights across elbow/knee joints.
## Bones are independent in rider space: analytic contact poses supply their transforms.
## This uses Godot's native Skeleton3D/Skin pipeline, with no per-frame mesh rebuilding.

const SIDES: Array[float] = [-1.0, 1.0]
const RADIAL := 20
var skeleton: Skeleton3D
var _bones: Dictionary = {}
var _surfaces: Array[MeshInstance3D] = []

func build(parent: Node3D, shirt: StandardMaterial3D, denim: StandardMaterial3D) -> void:
	skeleton = Skeleton3D.new()
	skeleton.name = "ClothingSkeleton"
	parent.add_child(skeleton)
	_add_bone("hips", Transform3D(Basis.IDENTITY, Vector3(0, 0.94, 0)))
	_add_bone("torso", Transform3D(Basis.IDENTITY, Vector3(0, 0.94, 0)))
	for side: float in SIDES:
		var prefix := "left" if side < 0 else "right"
		_add_bone(prefix + "_thigh", _bone_transform(Vector3(side * 0.105, 0.965, 0), Vector3.DOWN))
		_add_bone(prefix + "_calf", _bone_transform(Vector3(side * 0.105, 0.535, 0), Vector3.DOWN))
		_add_bone(prefix + "_sleeve", _bone_transform(Vector3(side * 0.215, 1.365, 0), Vector3.DOWN))
		_add_bone(prefix + "_forearm", _bone_transform(Vector3(side * 0.215, 1.065, 0), Vector3.DOWN))
	var cloth_texture := _weave_texture()
	for material: StandardMaterial3D in [shirt, denim]:
		material.vertex_color_use_as_albedo = true
		material.albedo_texture = cloth_texture
		material.roughness = 0.94
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var jacket := SurfaceTool.new()
	jacket.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body_rings: Array[Vector4] = [
		Vector4(0.02, 0.184, 0.143, 0), Vector4(0.045, 0.183, 0.141, 0),
		Vector4(0.08, 0.178, 0.137, 0), Vector4(0.16, 0.170, 0.130, -0.002),
		Vector4(0.24, 0.184, 0.137, -0.004), Vector4(0.33, 0.206, 0.141, -0.008),
		Vector4(0.40, 0.221, 0.133, 0), Vector4(0.445, 0.214, 0.116, 0),
		Vector4(0.475, 0.143, 0.092, -0.003), Vector4(0.495, 0.078, 0.071, -0.008)]
	_body(jacket, body_rings, Vector3(0, 0.94, 0), int(_bones["torso"]), 0.006)
	for side: float in SIDES:
		var prefix := "left" if side < 0 else "right"
		_tube(jacket, Vector3(side * 0.215, 1.365, 0), 0.59,
			[0.102, 0.107, 0.104, 0.098, 0.089, 0.092, 0.083, 0.076, 0.070, 0.062, 0.058, 0.061],
			int(_bones[prefix + "_sleeve"]), int(_bones[prefix + "_forearm"]),
			0.30 / 0.59, int(_bones["torso"]), 0.01)
	_finish(parent, "SkinnedJacket", jacket, shirt)
	var trousers := SurfaceTool.new()
	trousers.begin(Mesh.PRIMITIVE_TRIANGLES)
	_body(trousers, [Vector4(-0.13, 0.15, 0.112, 0), Vector4(-0.085, 0.172, 0.128, 0.006),
		Vector4(0.01, 0.177, 0.126, 0), Vector4(0.07, 0.158, 0.111, 0)],
		Vector3(0, 0.94, 0), int(_bones["hips"]), 0.004)
	for side: float in SIDES:
		var prefix := "left" if side < 0 else "right"
		_tube(trousers, Vector3(side * 0.105, 0.965, 0), 0.84,
			[0.112, 0.125, 0.121, 0.114, 0.105, 0.104, 0.110, 0.100, 0.090, 0.085, 0.079, 0.077, 0.081],
			int(_bones[prefix + "_thigh"]), int(_bones[prefix + "_calf"]),
			0.43 / 0.84, int(_bones["hips"]), 0.009)
	_finish(parent, "SkinnedTrousers", trousers, denim)
	var skin := skeleton.create_skin_from_rest_transforms()
	for mesh: MeshInstance3D in _surfaces:
		mesh.skin = skin
		mesh.skeleton = mesh.get_path_to(skeleton)
		skeleton.reset_bone_poses()

func pose_body(hips: Transform3D, torso: Transform3D) -> void:
	_pose("hips", hips)
	_pose("torso", torso)

func pose_leg(side: float, hip: Vector3, knee: Vector3, ankle: Vector3) -> void:
	var prefix := "left" if side < 0 else "right"
	_pose_segment(prefix + "_thigh", hip, knee, 0.43)
	_pose_segment(prefix + "_calf", knee, ankle, 0.41)

func pose_arm(side: float, shoulder: Vector3, elbow: Vector3, wrist: Vector3) -> void:
	var prefix := "left" if side < 0 else "right"
	_pose_segment(prefix + "_sleeve", shoulder, elbow, 0.30)
	_pose_segment(prefix + "_forearm", elbow, wrist, 0.29)

func _add_bone(bone_name: String, rest: Transform3D) -> void:
	var index := skeleton.get_bone_count()
	skeleton.add_bone(bone_name)
	skeleton.set_bone_rest(index, rest)
	_bones[bone_name] = index

func _bone_transform(origin: Vector3, direction: Vector3) -> Transform3D:
	return Transform3D(Basis(Quaternion(Vector3.UP, direction.normalized())), origin)

func _pose(bone_name: String, transform: Transform3D) -> void:
	var bone: int = _bones[bone_name]
	skeleton.set_bone_pose_position(bone, transform.origin)
	skeleton.set_bone_pose_rotation(bone, transform.basis.get_rotation_quaternion())
	skeleton.set_bone_pose_scale(bone, transform.basis.get_scale())

func _pose_segment(bone_name: String, start: Vector3, end: Vector3, rest_length: float) -> void:
	var direction := end - start
	var transform := _bone_transform(start, direction)
	transform.basis = transform.basis.scaled_local(Vector3(1, direction.length() / rest_length, 1))
	_pose(bone_name, transform)

func _body(surface: SurfaceTool, rings: Array, origin: Vector3, bone: int, fold: float) -> void:
	for row in range(rings.size() - 1):
		for col in RADIAL:
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0),
				Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 0)]:
				var ring: Vector4 = rings[row + corner.x]
				var angle := TAU * float(col + corner.y) / RADIAL
				var ripple := fold * sin(angle * 5.0 + ring.x * 30.0)
				# Flatter chest/front and seat panels, curved side seams.
				var x := signf(cos(angle)) * pow(absf(cos(angle)), 0.86) * (ring.y + ripple)
				var z := signf(sin(angle)) * pow(absf(sin(angle)), 0.86) * (ring.z + ripple) + ring.w
				_vertex(surface, origin + Vector3(x, ring.x, z), PackedInt32Array([bone, 0, 0, 0]),
					PackedFloat32Array([1, 0, 0, 0]), Vector2(float(col + corner.y) / RADIAL * 3.0, ring.x * 5.0),
					Color.WHITE * (0.96 + 0.04 * sin(angle * 3.0 + ring.x * 17.0)))

func _tube(surface: SurfaceTool, origin: Vector3, length: float, radii: Array,
		upper: int, lower: int, joint: float, parent_bone: int, fold: float) -> void:
	# Close the attachment ring. Deep tucks expose its underside beyond the torso;
	# an open tube otherwise reveals the world through the shoulder/hip.
	var attachment_bones := PackedInt32Array([upper, lower, parent_bone, 0])
	var attachment_weights := PackedFloat32Array([0.58, 0, 0.42, 0])
	for col in RADIAL:
		var angle := TAU * float(col) / RADIAL
		var next_angle := TAU * float(col + 1) / RADIAL
		var a := origin + Vector3(cos(angle) * float(radii[0]), 0, sin(angle) * float(radii[0]) * 0.90)
		var b := origin + Vector3(cos(next_angle) * float(radii[0]), 0, sin(next_angle) * float(radii[0]) * 0.90)
		for point: Vector3 in [origin, a, b]:
			_vertex(surface, point, attachment_bones, attachment_weights, Vector2.ZERO, Color.WHITE)
	var rows := (radii.size() - 1) * 2
	for row in rows:
		for col in RADIAL:
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1),
				Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1)]:
				var ring := row + corner.x
				var t := float(ring) / rows
				var radius_index := t * (radii.size() - 1)
				var radius_lower := mini(int(radius_index), radii.size() - 1)
				var radius_upper := mini(radius_lower + 1, radii.size() - 1)
				var angle := TAU * float(col + corner.y) / RADIAL
				var radius := lerpf(float(radii[radius_lower]), float(radii[radius_upper]), smoothstep(0.0, 1.0, radius_index - radius_lower))
				radius += fold * 0.5 * sin(angle * 3.0 + t * 31.0) * sin(PI * t)
				var point := origin + Vector3(cos(angle) * radius, -t * length, sin(angle) * radius * 0.90)
				var lower_weight := smoothstep(joint - 0.11, joint + 0.11, t)
				var parent_weight := 0.42 * (1.0 - smoothstep(0.0, 0.14, t))
				var upper_weight := (1.0 - lower_weight) * (1.0 - parent_weight)
				lower_weight *= 1.0 - parent_weight
				var shade := 0.96 + 0.035 * sin(angle * 2.0 + t * 8.0)
				_vertex(surface, point, PackedInt32Array([upper, lower, parent_bone, 0]),
					PackedFloat32Array([upper_weight, lower_weight, parent_weight, 0]),
					Vector2(float(col + corner.y) / RADIAL * 2.0, t * 4.0), Color(shade, shade, shade))

func _vertex(surface: SurfaceTool, position: Vector3, bones: PackedInt32Array,
		weights: PackedFloat32Array, uv: Vector2, color: Color) -> void:
	surface.set_bones(bones)
	surface.set_weights(weights)
	surface.set_uv(uv)
	surface.set_color(color)
	surface.add_vertex(position)

func _finish(parent: Node3D, mesh_name: String, surface: SurfaceTool, material: Material) -> void:
	surface.generate_normals()
	surface.index()
	var mesh := MeshInstance3D.new()
	mesh.name = mesh_name
	mesh.mesh = surface.commit()
	mesh.material_override = material
	# The rider can crouch/tuck far outside the undeformed rest mesh's bounds.
	mesh.custom_aabb = AABB(Vector3(-1.5, -0.4, -1.5), Vector3(3, 3, 3))
	parent.add_child(mesh)
	_surfaces.append(mesh)

func _weave_texture() -> ImageTexture:
	var image := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var weft := 0.96 + 0.009 * cos(float(x) * PI) + 0.009 * cos(float(y) * PI * 0.5)
			var diagonal := 0.006 * sin(float(x + y) * PI * 0.5)
			image.set_pixel(x, y, Color(weft + diagonal, weft + diagonal, weft + diagonal))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

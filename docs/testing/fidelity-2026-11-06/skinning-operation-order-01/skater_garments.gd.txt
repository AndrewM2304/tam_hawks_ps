extends RefCounted
## Original ring-built garments with smooth skin weights across elbow/knee joints.
## Bones are independent in rider space: analytic contact poses supply their transforms.
## This uses Godot's native Skeleton3D/Skin pipeline, with no per-frame mesh rebuilding.

const SIDES: Array[float] = [-1.0, 1.0]
const RADIAL := 32
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
	for material: StandardMaterial3D in [shirt, denim]:
		material.vertex_color_use_as_albedo = true
		material.albedo_texture = preload("res://game/art/rider/cloth_albedo.png")
		material.normal_enabled = true
		material.normal_texture = preload("res://game/art/rider/cloth_normal.png")
		material.normal_scale = 0.16
		material.uv1_scale = Vector3(3, 3, 1)
		material.roughness_texture = preload("res://game/art/rider/cloth_roughness.png")
		material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		material.roughness = 1.0
		material.metallic_specular = 0.18
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var jacket := SurfaceTool.new()
	jacket.begin(Mesh.PRIMITIVE_TRIANGLES)
	jacket.set_smooth_group(0)
	var body_rings: Array[Vector4] = [
		Vector4(0.015, 0.176, 0.126, 0), Vector4(0.04, 0.178, 0.127, 0),
		Vector4(0.10, 0.174, 0.121, 0), Vector4(0.17, 0.175, 0.116, -0.002),
		Vector4(0.25, 0.188, 0.118, -0.005), Vector4(0.33, 0.207, 0.121, -0.007),
		Vector4(0.40, 0.226, 0.115, -0.003), Vector4(0.44, 0.216, 0.104, 0),
		Vector4(0.475, 0.131, 0.081, -0.003), Vector4(0.495, 0.065, 0.057, -0.008)]
	_body(jacket, body_rings, Vector3(0, 0.94, 0), int(_bones["torso"]), 0.002)
	for side: float in SIDES:
		var prefix := "left" if side < 0 else "right"
		_tube(jacket, Vector3(side * 0.215, 1.365, 0), 0.59,
			[0.078, 0.083, 0.081, 0.076, 0.070, 0.071, 0.065, 0.061, 0.057, 0.052, 0.046, 0.047],
			int(_bones[prefix + "_sleeve"]), int(_bones[prefix + "_forearm"]),
			0.30 / 0.59, int(_bones["torso"]), 0.003)
	_finish(parent, "SkinnedJacket", jacket, shirt)
	var trousers := SurfaceTool.new()
	trousers.begin(Mesh.PRIMITIVE_TRIANGLES)
	trousers.set_smooth_group(0)
	_body(trousers, [Vector4(-0.13, 0.148, 0.103, 0), Vector4(-0.085, 0.168, 0.115, 0.006),
		Vector4(0.01, 0.170, 0.115, 0), Vector4(0.07, 0.157, 0.103, 0)],
		Vector3(0, 0.94, 0), int(_bones["hips"]), 0.002, true)
	for side: float in SIDES:
		var prefix := "left" if side < 0 else "right"
		_tube(trousers, Vector3(side * 0.105, 0.965, 0), 0.84,
			[0.100, 0.108, 0.104, 0.096, 0.085, 0.080, 0.079, 0.077, 0.072, 0.067, 0.063, 0.062, 0.064],
			int(_bones[prefix + "_thigh"]), int(_bones[prefix + "_calf"]),
			0.43 / 0.84, int(_bones["hips"]), 0.003)
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
	# A shortest-arc UP rotation twists unpredictably near DOWN when the knee
	# changes sides. A shared back-facing pole keeps sleeve/trouser rings aligned.
	var y := direction.normalized()
	var z := Vector3.BACK.slide(y).normalized()
	if z.length_squared() < 0.01:
		z = Vector3.RIGHT.slide(y).normalized()
	var x := y.cross(z).normalized()
	z = x.cross(y).normalized()
	return Transform3D(Basis(x, y, z), origin)

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

func _body(surface: SurfaceTool, rings: Array, origin: Vector3, bone: int, fold: float, crotch: bool = false) -> void:
	const SUBDIVISIONS := 3
	for row in range((rings.size() - 1) * SUBDIVISIONS):
		for col in RADIAL:
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0),
				Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 0)]:
				var sample := float(row + corner.x) / SUBDIVISIONS
				var lower := mini(int(sample), rings.size() - 2)
				var ring := _tailored_ring(rings, lower, sample - lower)
				var angle := TAU * float(col + corner.y) / RADIAL
				var ripple := fold * sin(angle * 5.0 + ring.x * 30.0)
				if not crotch:
					# Broad folds gather where a jacket meets the waistband and
					# under the arms. These are millimetres of cloth, rather than
					# rigid concentric panels around an anatomical cylinder.
					var hem := exp(-pow((ring.x - 0.055) / 0.065, 2.0))
					var axilla := exp(-pow((ring.x - 0.345) / 0.065, 2.0)) * pow(absf(cos(angle)), 5.0)
					ripple += 0.004 * hem * sin(angle * 4.0 + ring.x * 65.0 + sin(angle * 2.0))
					ripple += 0.0045 * axilla * sin(ring.x * 89.0 + angle * 1.7)
				# Flatter chest/front and seat panels, curved side seams.
				var x := signf(cos(angle)) * pow(absf(cos(angle)), 0.94) * (ring.y + ripple)
				var z := signf(sin(angle)) * pow(absf(sin(angle)), 0.94) * (ring.z + ripple) + ring.w
				# A trouser yoke has a curved crotch saddle, not a level rectangular
				# lower skirt. Raise its side exits into the overlapping thigh roots.
				var y := ring.x
				if crotch:
					y += 0.085 * pow(absf(cos(angle)), 1.5) * (1.0 - smoothstep(-0.13, 0.01, ring.x))
				_vertex(surface, origin + Vector3(x, y, z), PackedInt32Array([bone, 0, 0, 0]),
					PackedFloat32Array([1, 0, 0, 0]), Vector2(float(col + corner.y) / RADIAL * 3.0, ring.x * 5.0),
					Color.WHITE * (0.97 + 0.025 * sin(angle * 3.0 + ring.x * 17.0)))

func _tube(surface: SurfaceTool, origin: Vector3, length: float, radii: Array,
		upper: int, lower: int, joint: float, parent_bone: int, fold: float) -> void:
	# Close the attachment ring. Deep tucks expose its underside beyond the torso;
	# an open tube otherwise reveals the world through the shoulder/hip.
	var attachment_bones := PackedInt32Array([upper, lower, parent_bone, 0])
	var attachment_weights := PackedFloat32Array([0.58, 0, 0.42, 0])
	var is_sleeve := parent_bone == int(_bones["torso"])
	var shoulder_inset := Vector3(-signf(origin.x) * 0.055, 0, 0) if is_sleeve else Vector3.ZERO
	for col in RADIAL:
		var angle := TAU * float(col) / RADIAL
		var next_angle := TAU * float(col + 1) / RADIAL
		var a := origin + shoulder_inset + Vector3(cos(angle) * float(radii[0]), 0, sin(angle) * float(radii[0]) * 0.90)
		var b := origin + shoulder_inset + Vector3(cos(next_angle) * float(radii[0]), 0, sin(next_angle) * float(radii[0]) * 0.90)
		for point: Vector3 in [origin + shoulder_inset, a, b]:
			_vertex(surface, point, attachment_bones, attachment_weights, Vector2.ZERO, Color.WHITE)
	var rows := (radii.size() - 1) * 3
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
				var radius := _tailored_radius(radii, radius_lower, radius_upper, radius_index - radius_lower)
				radius += fold * 0.5 * sin(angle * 3.0 + t * 31.0) * sin(PI * t)
				var joint_fold := exp(-pow((t - joint) / 0.085, 2.0))
				var compression := 0.35 + 0.65 * maxf(0.0, sin(angle))
				radius += 0.005 * joint_fold * compression * sin((t - joint) * 104.0 + angle * 1.3 + signf(origin.x) * 0.8)
				if not is_sleeve:
					var ankle_fold := exp(-pow((t - 0.925) / 0.065, 2.0))
					radius += 0.004 * ankle_fold * sin(t * 133.0 + angle * 1.7 + origin.x * 7.0)
				var point := origin + Vector3(cos(angle) * radius, -t * length, sin(angle) * radius * 0.90)
				# The sleeve root disappears inside the yoke instead of presenting a
				# separate flat tube cap above the shoulder during balance poses.
				point += shoulder_inset * (1.0 - smoothstep(0.0, 0.18, t))
				var lower_weight := smoothstep(joint - 0.11, joint + 0.11, t)
				var parent_weight := 0.42 * (1.0 - smoothstep(0.0, 0.14, t))
				var upper_weight := (1.0 - lower_weight) * (1.0 - parent_weight)
				lower_weight *= 1.0 - parent_weight
				# Faded seam tracks and worn knees/elbows are surface pigmentation,
				# not bright floating pipes around the silhouette.
				var seam := exp(-pow(sin(angle) / 0.075, 2.0)) * 0.055
				var wear := exp(-pow((t - joint) / 0.12, 2.0)) * maxf(0.0, -sin(angle)) * 0.055
				var cuff := smoothstep(0.94, 0.98, t) * 0.045
				var shade := 0.94 + seam + wear - cuff + 0.025 * sin(angle * 2.0 + t * 8.0)
				_vertex(surface, point, PackedInt32Array([upper, lower, parent_bone, 0]),
					PackedFloat32Array([upper_weight, lower_weight, parent_weight, 0]),
					Vector2(float(col + corner.y) / RADIAL * 2.0, t * 4.0), Color(shade, shade, shade))

func _tailored_ring(rings: Array, index: int, t: float) -> Vector4:
	var a: Vector4 = rings[maxi(0, index - 1)]
	var b: Vector4 = rings[index]
	var c: Vector4 = rings[index + 1]
	var d: Vector4 = rings[mini(rings.size() - 1, index + 2)]
	var value := 0.5 * ((b * 2.0) + (-a + c) * t
		+ (a * 2.0 - b * 5.0 + c * 4.0 - d) * t * t
		+ (-a + b * 3.0 - c * 3.0 + d) * t * t * t)
	# Preserve every authored attachment height while smoothing the panel's
	# cross-section derivative between them.
	value.x = lerpf(b.x, c.x, t)
	return value

func _tailored_radius(radii: Array, lower: int, upper: int, t: float) -> float:
	var a := float(radii[maxi(0, lower - 1)])
	var b := float(radii[lower])
	var c := float(radii[upper])
	var d := float(radii[mini(radii.size() - 1, upper + 1)])
	return 0.5 * ((2.0 * b) + (-a + c) * t + (2.0 * a - 5.0 * b + 4.0 * c - d) * t * t
		+ (-a + 3.0 * b - 3.0 * c + d) * t * t * t)

func _vertex(surface: SurfaceTool, position: Vector3, bones: PackedInt32Array,
		weights: PackedFloat32Array, uv: Vector2, color: Color) -> void:
	surface.set_bones(bones)
	surface.set_weights(weights)
	surface.set_uv(uv)
	surface.set_color(color)
	surface.add_vertex(position)

func _finish(parent: Node3D, mesh_name: String, surface: SurfaceTool, material: Material) -> void:
	surface.generate_normals()
	surface.generate_tangents()
	surface.index()
	var mesh := MeshInstance3D.new()
	mesh.name = mesh_name
	mesh.mesh = surface.commit()
	mesh.material_override = material
	# The rider can crouch/tuck far outside the undeformed rest mesh's bounds.
	mesh.custom_aabb = AABB(Vector3(-1.5, -0.4, -1.5), Vector3(3, 3, 3))
	parent.add_child(mesh)
	_surfaces.append(mesh)

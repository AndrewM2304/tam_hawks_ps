extends RefCounted
## Original procedural set dressing shared by the optional local activities.

static func material(colour: Color, metal: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = colour
	result.roughness = 0.82
	result.metallic = metal
	return result

static func box(parent: Node3D, label: String, at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var result := MeshInstance3D.new()
	result.name = label
	result.position = at
	result.mesh = mesh
	result.material_override = material(colour)
	parent.add_child(result)
	return result

static func cylinder(parent: Node3D, label: String, at: Vector3, radius: float, height: float, colour: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	var result := MeshInstance3D.new()
	result.name = label
	result.position = at
	result.mesh = mesh
	result.material_override = material(colour)
	parent.add_child(result)
	return result

static func sign(parent: Node3D, at: Vector3, title: String, colour: Color = Color("eee7d8")) -> Label3D:
	var result := Label3D.new()
	result.name = "ActivitySign"
	result.position = at
	result.text = title
	result.font_size = 42
	result.pixel_size = 0.009
	result.modulate = colour
	result.outline_modulate = Color("202a2b")
	result.outline_size = 12
	result.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	result.no_depth_test = false
	parent.add_child(result)
	return result

static func regular(parent: Node3D, at: Vector3, steward: bool = false) -> Node3D:
	var figure = preload("res://game/features/activity_actor.gd").new()
	figure.steward = steward
	figure.name = "FestivalSteward" if steward else "ParkRegular"
	figure.position = at
	parent.add_child(figure)
	return figure

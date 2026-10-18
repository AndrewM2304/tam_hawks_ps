extends RefCounted
const Visibility = preload("res://game/levels/city_visibility.gd")

static func run(tree: SceneTree, check: Callable) -> void:
	var world := Node3D.new()
	tree.root.add_child(world)
	var solid := _box(world,"closed",true)
	solid.position = Vector3(10,3,8)
	solid.scale = Vector3(1,1,.7)
	var hidden := _box(world,"hidden gallery original",true)
	hidden.get_child(0).visible=false
	var glass := _box(world,"transparent",true)
	glass.get_child(0).material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	var open := _box(world,"open passage",false)
	var shadow_only := _box(world,"shadow approximation",true)
	shadow_only.get_child(0).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	check.call(Visibility.build(world)==1,"city visibility: only explicitly registered visible opaque walls create occluders")
	check.call(open.get_child_count()==1 and hidden.get_child_count()==1 and glass.get_child_count()==1,
		"city visibility: open passages, replaced walls and transparent surfaces stay unobstructed")
	check.call(shadow_only.get_child_count()==1,
		"city visibility: an invisible shadow approximation never becomes a wall occluder")
	var occluder := solid.get_node("ClosedFacadeOccluder") as OccluderInstance3D
	check.call(occluder!=null and occluder.occluder.size.is_equal_approx(Vector3(19.8,11.8,11.8)),
		"city visibility: blocker remains inset inside the actual closed box")
	check.call(occluder.global_transform.is_equal_approx(solid.global_transform) and is_equal_approx(solid.scale.z,.7),
		"city visibility: final parent placement and nonuniform facade scale are preserved")
	check.call(Visibility.build(world)==0 and solid.get_child_count()==2,
		"city visibility: rebuilding is idempotent and adds no collision bodies or shapes")
	world.free()

static func _box(world: Node3D, label: String, registered: bool) -> Node3D:
	var body := Node3D.new()
	body.name=label
	world.add_child(body)
	var geometry := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size=Vector3(20,12,12)
	geometry.mesh=mesh
	geometry.material_override=StandardMaterial3D.new()
	body.add_child(geometry)
	if registered: Visibility.register_closed_facade(body)
	return body

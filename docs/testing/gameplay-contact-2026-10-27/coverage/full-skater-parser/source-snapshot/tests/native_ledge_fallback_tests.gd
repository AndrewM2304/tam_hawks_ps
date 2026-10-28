extends RefCounted
## Finite native geometry, independent of prop names and render-only caps.
const Audit = preload("res://game/levels/surface_audit.gd")
const Skater = preload("res://game/player/skater.gd")
const Ride = preload("res://game/tricks/grind_ride.gd")
const Line = preload("res://game/tricks/grind_line.gd")
const Setup = preload("res://game/core/input_setup.gd")

class FlatWorld extends Node3D:
	var ground_y := 0.0
	func get_ground_height(_at: Vector3) -> float:
		return global_position.y + ground_y

static func run(tree: SceneTree, world: Node3D, check: Callable) -> void:
	Setup.register_actions()
	for kind: String in ["bench", "ledge", "curb", "floor", "buried", "fence", "protected_glass", "provider_cap", "overhead", "round_overhead", "decor"]:
		await _fixture(tree, kind, check)
	_north_rim(world, check)

static func _fixture(tree: SceneTree, kind: String, check: Callable) -> void:
	var fixture := FlatWorld.new()
	fixture.position = Vector3(2700, 300, 2700)
	if kind == "buried": fixture.ground_y = 0.6
	tree.root.add_child(fixture)
	_box(fixture,"NativeFloor",Vector3(30,0.2,30),Vector3(0,fixture.ground_y-0.1,0))
	var size := Vector3(3,0.1,0.6)
	var at := Vector3(0,0.5,0)
	match kind:
		"ledge": size=Vector3(2,0.4,2);at=Vector3(0,0.2,0)
		"curb": size=Vector3(4,0.12,0.18);at=Vector3(0,0.06,0)
		"floor": size=Vector3(4,0.1,4);at=Vector3(0,-0.05,0)
		"buried": size=Vector3(3,0.4,0.6);at=Vector3(0,0.2,0)
	var body: Node3D
	if kind == "decor":
		body=Node3D.new();fixture.add_child(body)
		var visual := MeshInstance3D.new();var mesh := BoxMesh.new();mesh.size=size
		visual.mesh=mesh;visual.position=at;body.add_child(visual)
	else: body=_box(fixture,"UnlistedPhysicalObject",size,at)
	if kind == "bench":
		body.set_meta("authored_grind_ids",[]);body.set_meta("grind_id","")
	if kind == "ledge":
		body.rotation.y=PI*0.5;body.scale=Vector3(1.5,1,1.2)
	var authored: Array = []
	if kind == "fence": body.set_meta("exploration_boundary",true)
	if kind == "protected_glass":
		body.set_meta("surface_audio","glass")
		body.set_meta("grind_exclusion_reason","protected scenic barrier")
	if kind == "provider_cap":
		body.set_meta("authored_grind_ids",["ExistingCapProvider"])
		authored.append(Line.new("ExistingCapProvider",PackedVector3Array([fixture.to_global(Vector3(-1,0.7,0)),fixture.to_global(Vector3(1,0.7,0))]),"ledge"))
		var cap := MeshInstance3D.new()
		var mesh := BoxMesh.new();mesh.size=Vector3(3.2,0.08,0.7)
		cap.mesh=mesh;cap.position=Vector3(0,0.65,0);fixture.add_child(cap)
	if kind == "overhead":
		var roof := _box(fixture,"Shelter",Vector3(4,0.2,2),Vector3(0,1.8,0))
		roof.set_meta("grind_exclusion_reason","overhead shelter")
	if kind == "round_overhead":
		var bar := StaticBody3D.new();bar.name="SteelOverhead";bar.position=Vector3(0,1.8,0)
		fixture.add_child(bar)
		var cylinder := CylinderShape3D.new();cylinder.radius=0.35;cylinder.height=4.0
		var solid := CollisionShape3D.new();solid.shape=cylinder;solid.rotation.z=PI*0.5;bar.add_child(solid)
	var before := fixture.get_child_count()
	var audit := Audit.new();audit.build(fixture,authored)
	var positive := kind in ["bench","ledge","curb"]
	check.call((not audit.lines.is_empty()) == positive and fixture.get_child_count() == before,
		"native ledge fallback: unlisted " + kind + " has honest exposed-top coverage without new scene nodes")
	if positive:
		var deterministic := Audit.new();deterministic.build(fixture,authored)
		var equal := deterministic.lines.size() == audit.lines.size()
		for index: int in audit.lines.size():
			var a = audit.lines[index];var b = deterministic.lines[index]
			equal = equal and a.id==b.id and a.points==b.points and a.contact_verified \
				and a.contact_source=="surface.native_box_top" and is_equal_approx(a.contact_vertical_offset,-0.02)
		check.call(equal,"native ledge fallback: unlisted " + kind + " keeps deterministic identity and exact native20mm contact datum")
		var previous_camera := tree.root.get_camera_3d()
		var rider := Skater.new();rider.spawn_position=fixture.to_global(Vector3(8,1,8))
		fixture.add_child(rider);rider.set_physics_process(false);rider.set_process(false)
		if is_instance_valid(previous_camera): previous_camera.current=true
		await tree.physics_frame;await tree.process_frame
		var usable := true
		for line in audit.lines:
			for fraction: float in [0.2,0.5,0.8]:
				var point: Vector3=rider._grind._body_point(line,line.length*fraction)
				var direction: Vector3=line.dir_at(line.length*fraction)
				var ride := Ride.new()
				ride.body_radius=rider._grind.body_radius
				ride.body_base_offset=rider._grind.body_base_offset
				usable = usable and ride.start([line],point+Vector3.UP*0.15,direction*6.0-Vector3.UP,
					func(from: Vector3,to: Vector3) -> bool:return rider._rail_path_clear(from,to))
		check.call(usable,"native ledge fallback: all unlisted " + kind + " interior samples admit the production capsule and finite motion")
	fixture.queue_free();await tree.process_frame;await tree.physics_frame

static func _north_rim(world: Node3D, check: Callable) -> void:
	var park := world.get_node_or_null("OutdoorRoutes/KelvingroveSunkenSkatepark") as Node3D
	check.call(park!=null,"native ledge fallback: ordinary world contains the actual sunken-park retaining edges")
	if park == null:return
	var audit: Dictionary=world.get_surface_audit()
	var found := 0;var covered := true;var finite := true
	var lines: Dictionary={}
	for line in world.get_grind_lines():lines[line.id]=line
	for record: Dictionary in audit.surfaces:
		if record.label!="NorthStreetRetaining":continue
		found+=1
		var own := 0
		for id: String in record.grind_ids:
			if not id.begins_with("Grind_Ledge_"+record.id+"_Native_"):continue
			own+=1
			var line = lines.get(id)
			if line==null:finite=false;continue
			finite=finite and absf(park.to_local(line.contact_at(line.length*0.5)).y)<0.00001
			for point: Vector3 in line.points:
				var local: Vector3=park.to_local(point)
				finite=finite and absf(local.y-0.02)<0.00001 and absf(local.z-3.5)<0.00001
		covered=covered and own>0
	check.call(found==5 and covered and finite,
		"native ledge fallback: all five real north retaining lips expose finite south top guides while flush north faces and port gaps stay unregistered")

static func _box(parent: Node3D,label: String,size: Vector3,at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new();body.name=label;body.position=at;parent.add_child(body)
	var shape := BoxShape3D.new();shape.size=size
	var collision := CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
	return body

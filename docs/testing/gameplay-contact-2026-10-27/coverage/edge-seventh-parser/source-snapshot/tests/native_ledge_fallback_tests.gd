extends RefCounted
## Finite native geometry, independent of prop names and render-only caps.
const Audit = preload("res://game/levels/surface_audit.gd")
const Skater = preload("res://game/player/skater.gd")
const Ride = preload("res://game/tricks/grind_ride.gd")
const Line = preload("res://game/tricks/grind_line.gd")
const Setup = preload("res://game/core/input_setup.gd")
const Style = preload("res://game/tricks/grind_style.gd")

class FlatWorld extends Node3D:
	var ground_y := 0.0
	func get_ground_height(_at: Vector3) -> float:
		return global_position.y + ground_y

static func run(tree: SceneTree, world: Node3D, check: Callable) -> void:
	Setup.register_actions()
	for kind: String in ["bench", "ledge", "curb", "floor", "buried", "fence", "protected_glass", "provider_cap", "overhead", "round_overhead", "decor"]:
		await _fixture(tree, kind, check)
	await _full_skater_edge(tree,check,-1.0,false)
	await _full_skater_edge(tree,check,1.0,false)
	await _full_skater_edge(tree,check,1.0,true)
	await _north_rim(tree,world,check)

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
				and a.contact_source=="surface.native_box_top" and is_equal_approx(a.contact_vertical_offset,-0.02) \
				and a.contact_edge_outward==b.contact_edge_outward and a.contact_edge_outward.length_squared()>0.99
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
				ride.body_clearance=rider._grind.body_clearance
				usable = usable and ride.start([line],point+Vector3.UP*0.15,direction*6.0-Vector3.UP,
					func(from: Vector3,to: Vector3) -> bool:return rider._rail_path_clear(from,to))
		check.call(usable,"native ledge fallback: all unlisted " + kind + " interior samples admit the production capsule and finite motion")
	fixture.queue_free();await tree.process_frame;await tree.physics_frame

static func _full_skater_edge(tree: SceneTree,check: Callable,side: float,blocked: bool) -> void:
	for action: StringName in InputMap.get_actions():Input.action_release(action)
	var viewport := SubViewport.new();viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;tree.root.add_child(viewport)
	var fixture := FlatWorld.new();viewport.add_child(fixture)
	_box(fixture,"NativeFloor",Vector3(30,0.2,30),Vector3(0,-0.1,0))
	_box(fixture,"UnlistedPhysicalBench",Vector3(6,0.1,0.6),Vector3(0,0.5,0))
	var audit := Audit.new();audit.build(fixture,[])
	var line: Line
	for candidate in audit.lines:
		if candidate.contact_edge_outward.dot(Vector3(0,0,side))>0.99:line=candidate;break
	check.call(line!=null,"native edge contact: generated physical bench publishes the real outward side "+str(side))
	if line==null:viewport.queue_free();await tree.process_frame;return
	var distance: float=line.length*0.4
	var target: Vector3=line.contact_at(distance)
	var tangent: Vector3=line.dir_at(distance)
	# Declared initial-air fixture: the actual controller owns acquisition,
	# scoring and subsequent native movement. No Ride.start or filter is mocked.
	var rider := Skater.new();rider.spawn_position=target+Vector3.UP*0.15;fixture.add_child(rider)
	rider.set_physics_process(false);rider.set_process(false)
	rider.rotation.y=atan2(-tangent.x,-tangent.z);rider.set_grind_lines([line])
	if blocked:
		# This low neighbouring solid occupies the outer tyre's space while
		# remaining below the upright capsule and below the true bench crown.
		_box(fixture,"ForeignLowBlocker",Vector3(2.0,0.07,0.12),
			target+line.contact_edge_outward*0.115-Vector3.UP*0.04)
	await tree.physics_frame;await tree.process_frame
	rider.velocity=tangent*6.0-Vector3.UP;rider.speed=6.0;rider.airborne=true
	var captures: Array[String]=[]
	rider.grind_captured.connect(func(id: String):captures.append(id))
	var pose := Style.ContactPose.new()
	var solved: bool=rider._solve_grind_contact(pose,line,distance,1.0,0.0,"grind_50_50",0.0)
	var capsule_clear: bool=rider._rail_path_clear(rider.global_position,rider._grind._body_point(line,distance))
	var model_clear: bool=solved and rider._grind_clearance.allows_frame_path(pose.board_transform,pose.board_transform,Vector3.UP)
	check.call(solved and capsule_clear and rider._grind_native_crown(line,distance),
		"native edge contact: exact crown and real capsule admit the same supported candidate "+str(side)+" blocked="+str(blocked))
	check.call(model_clear != blocked,
		"native edge contact: actual connected model distinguishes clear edge from neighbouring solid "+str(side)+" blocked="+str(blocked))
	Input.action_press("grind");rider.set_physics_process(true);rider.set_process(true)
	await tree.physics_frame;await tree.process_frame
	if blocked:
		check.call(captures.is_empty() and not rider.grinding,
			"native edge contact: held Grind cannot ignore a real adjacent model obstruction")
	else:
		check.call(captures==[line.id] and rider.grinding and rider.grind_style_id=="grind_50_50",
			"native edge contact: full Skater held input catches the generated edge with exact Fifty-Fifty support "+str(side))
		var first: float=rider._grind.distance
		for tick: int in 8:await tree.physics_frame;await tree.process_frame
		check.call(rider.grinding and not rider.bailing and captures==[line.id] and rider._grind.distance>first+0.5,
			"native edge contact: mirrored supported grind advances through eight native ticks without duplicate capture "+str(side))
		var exact := rider._grind_contact.valid and rider._grind_contact.max_error<=Style.CONTACT_TOLERANCE \
			and line.contact_up(rider._grind.distance)==Vector3.UP \
			and rider._grind_contact.board_transform.basis.y.dot(line.contact_edge_outward)>0.0
		check.call(exact,"native edge contact: both truck anchors keep the physical crown while the board leans over its exposed side "+str(side))
	print("NATIVE_EDGE_FULL_SKATER ",{"side":side,"blocked":blocked,"roll":rider._grind_clearance.edge_roll_angle,
		"crown":target,"body_clearance":rider._grind.body_clearance,"model_clear":model_clear,
		"capsule_clear":capsule_clear,"captures":captures,"grinding":rider.grinding,"position":rider.global_position,
		"support_error":rider._grind_contact.max_error})
	for action: StringName in InputMap.get_actions():Input.action_release(action)
	viewport.queue_free();await tree.process_frame;await tree.physics_frame

static func _north_rim(tree: SceneTree,world: Node3D, check: Callable) -> void:
	var park := world.get_node_or_null("OutdoorRoutes/KelvingroveSunkenSkatepark") as Node3D
	check.call(park!=null,"native ledge fallback: ordinary world contains the actual sunken-park retaining edges")
	if park == null:return
	var audit: Dictionary=world.get_surface_audit()
	var found := 0;var covered := true;var finite := true
	var representative: Line
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
			if representative==null:representative=line
			finite=finite and absf(park.to_local(line.contact_at(line.length*0.5)).y)<0.00001
			for point: Vector3 in line.points:
				var local: Vector3=park.to_local(point)
				finite=finite and absf(local.y-0.02)<0.00001 and absf(local.z-3.5)<0.00001
		covered=covered and own>0
	check.call(found==5 and covered and finite,
		"native ledge fallback: all five real north retaining lips expose finite south top guides while flush north faces and port gaps stay unregistered")
	if representative==null:return
	for action: StringName in InputMap.get_actions():Input.action_release(action)
	var previous_camera := world.get_viewport().get_camera_3d()
	var distance: float=representative.length*0.5
	var crown: Vector3=representative.contact_at(distance)
	var tangent: Vector3=representative.dir_at(distance)
	var rider := Skater.new();rider.spawn_position=crown+Vector3.UP*0.15;world.add_child(rider)
	rider.set_physics_process(false);rider.set_process(false)
	rider.rotation.y=atan2(-tangent.x,-tangent.z);rider.set_grind_lines([representative])
	if is_instance_valid(previous_camera):previous_camera.current=true
	await tree.physics_frame;await tree.process_frame
	rider.velocity=tangent*6.0-Vector3.UP;rider.speed=6.0;rider.airborne=true
	var pose := Style.ContactPose.new()
	var solved: bool=rider._solve_grind_contact(pose,representative,distance,1.0,0.0,"grind_50_50",0.0)
	var native_crown: bool=rider._grind_native_crown(representative,distance)
	var capsule: bool=rider._rail_path_clear(rider.global_position,rider._grind._body_point(representative,distance))
	var model: bool=solved and rider._grind_clearance.allows_frame_path(pose.board_transform,pose.board_transform,Vector3.UP)
	var board: bool=solved and rider._grind_board_clear(pose.board_transform,representative,distance)
	var captures: Array[String]=[];rider.grind_captured.connect(func(id: String):captures.append(id))
	Input.action_press("grind");rider.set_physics_process(true);rider.set_process(true)
	await tree.physics_frame;await tree.process_frame
	var first: float=rider._grind.distance
	for tick: int in 8:await tree.physics_frame;await tree.process_frame
	check.call(captures==[representative.id] and rider.grinding and not rider.bailing and rider._grind.distance>first+0.5,
		"native edge contact: held Grind catches and advances on the actual retaining lip beside the excavated upper deck")
	print("NATIVE_RETAINING_FULL_SKATER ",{"id":representative.id,"crown":crown,"solved":solved,"native_crown":native_crown,
		"capsule":capsule,"actual_model":model,"board":board,"captures":captures,"grinding":rider.grinding,
		"position":rider.global_position,"support_error":rider._grind_contact.max_error})
	for action: StringName in InputMap.get_actions():Input.action_release(action)
	rider.queue_free();await tree.process_frame;await tree.physics_frame
	await _rising_retaining(tree,world,representative,check)

static func _rising_retaining(tree: SceneTree,world: Node3D,line: Line,check: Callable) -> void:
	var previous_camera := world.get_viewport().get_camera_3d()
	var distance: float=line.length*0.5
	var crown: Vector3=line.contact_at(distance)
	var tangent: Vector3=line.dir_at(distance)
	var outward: Vector3=line.contact_edge_outward
	var rider := Skater.new();rider.spawn_position=crown+outward*0.45-Vector3.UP*0.5;world.add_child(rider)
	rider.set_physics_process(false);rider.set_process(false)
	rider.rotation.y=atan2(-tangent.x,-tangent.z);rider.set_grind_lines([line])
	if is_instance_valid(previous_camera):previous_camera.current=true
	await tree.physics_frame;await tree.process_frame
	# Declared initial air/heading, followed only by real controller physics.
	# The incoming wall motion and independent aligned board are intentional.
	rider.velocity=tangent*0.6-outward*6.0+Vector3.UP*7.0;rider.speed=Vector2(rider.velocity.x,rider.velocity.z).length();rider.airborne=true
	var earned: Dictionary={}
	var captures: Array[String]=[];rider.grind_captured.connect(func(id: String):captures.append(id))
	Input.action_press("grind");rider.set_physics_process(true);rider.set_process(true)
	for tick: int in 12:
		await tree.physics_frame;await tree.process_frame
		if earned.is_empty() and rider._grind_rail_intent_remaining>0.0 and not rider.grinding:
			earned={"rid":rider._grind_rail_intent_rid,"at":rider.global_position,"velocity":rider.velocity,
				"remaining":rider._grind_rail_intent_remaining,"ids":rider._grind_rail_intent_ids.duplicate()}
		if rider.grinding:break
	var ray := PhysicsRayQueryParameters3D.create(crown+Vector3.UP*0.04,crown-Vector3.UP*0.08,1|2|8)
	ray.exclude=[rider.get_rid()]
	var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
	var hit_rid: RID=hit.get("rid",RID())
	var exact_assembly: bool=not earned.is_empty() and line.native_support_rids.size()>=2 \
		and earned.rid==line.native_support_rids[0] and earned.rid!=hit_rid \
		and line.native_support_rids.has(hit_rid) and earned.ids==[line.id] \
		and Vector2(earned.velocity.x,earned.velocity.z).length()<Ride.ENTRY_SPEED
	check.call(exact_assembly,"native retaining rise: actual box impact earns clipped held-input intent while the crown ray selects its separately proven coplanar deck")
	check.call(not earned.is_empty() and rider._grind_native_crown(line,distance,earned.rid) \
		and not rider._grind_native_crown(line,distance,rider.get_rid()),
		"native retaining rise: only proven native assembly RIDs bridge the real ray tie; an unrelated live RID remains refused")
	var first: float=rider._grind.distance
	for tick: int in 8:await tree.physics_frame;await tree.process_frame
	check.call(exact_assembly and captures==[line.id] and rider.grinding and not rider.bailing and rider._grind.distance>first+0.5,
		"native retaining rise: real cached wall momentum catches the same finite Fifty-Fifty edge and advances without duplicate capture")
	print("NATIVE_RETAINING_RISE ",{"line":line.id,"earned":earned,"ray_rid":hit_rid,"proven_rids":line.native_support_rids,
		"captures":captures,"position":rider.global_position,"grinding":rider.grinding,"style":rider.grind_style_id})
	for action: StringName in InputMap.get_actions():Input.action_release(action)
	rider.queue_free();await tree.process_frame;await tree.physics_frame

static func _box(parent: Node3D,label: String,size: Vector3,at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new();body.name=label;body.position=at;parent.add_child(body)
	var shape := BoxShape3D.new();shape.size=size
	var collision := CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
	return body

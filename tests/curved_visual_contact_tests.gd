extends RefCounted
## Production Main support visuals, measured from all four actual wheel meshes
## against independent native surface rays. Initial contact fixtures are declared
## once; no visual/support pose or ongoing motion is injected into the player.

const Repertoire = preload("res://tests/full_repertoire_tests.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")

const SAFE := Vector3(-22,0.8,28)
const MIN_GAP := -0.003
const MAX_GAP := 0.030
const MAX_SPREAD := 0.020
static var _observer := Callable()
static var _game: Node
static var _phase := ""
static var _step := 0

static func run(tree: SceneTree, game: Node, check: Callable, observer: Callable=Callable()) -> void:
	var original_spawn: Vector3 = game.skater.spawn_position
	var original_free: bool = game.free_skate_mode
	_observer = observer
	_game = game
	_step = 0
	game.start_mode(true)
	await _bowl_lap(tree,game,check)
	await _bowl_flip_return(tree,game,check)
	await _halfpipe_faces(tree,game,check)
	await _ordinary_bank(tree,game,check,20.0)
	await _ordinary_bank(tree,game,check,45.0)
	_release()
	_phase = ""
	_observer = Callable()
	_game = null
	game.skater.spawn_position = original_spawn
	game.start_mode(original_free)

static func _bowl_lap(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree,game,SAFE)
	var bowl: Node3D = game.world.get_node("ClydeEastBowl")
	var sample: Dictionary = bowl.sample(0.6,0.0)
	var speed := sqrt(22.0*(bowl.floor_radius+bowl.radius*sin(0.6))*tan(0.6))
	# Same single native contact/momentum fixture as the independent authentic
	# Main bowl lap. All subsequent contact and carving come from the controller.
	game.skater.set_physics_process(false)
	game.skater.spawn_position = sample.point+sample.normal*0.022
	game.skater.reset_skater()
	game.skater.velocity = sample.lateral*speed
	game.skater.speed = speed
	game.skater.airborne = false
	game.skater.rotation.y = atan2(-game.skater.velocity.x,-game.skater.velocity.z)
	game.skater.set_physics_process(true)
	_phase = "curved_visual_bowl_lap"
	var stats := _stats()
	var previous := 0.0
	var sweep := 0.0
	var supported := true
	for frame in 300:
		await _frames(tree,1)
		var local: Vector3 = bowl.to_local(game.skater.global_position)
		var phi := atan2(local.x,-local.z)
		sweep += angle_difference(previous,phi)
		previous = phi
		supported = supported and game.skater.transition_active and not game.skater.airborne and not game.skater.bail_active
		if frame>=12: _measure(game.skater,bowl,stats)
		if sweep>=TAU: break
	check.call(supported and sweep>=TAU and int(stats.samples)>=180 and stats.max_steer==0.0,
		"curved visual contact: production player completes a full neutral caught-board bowl lap")
	check.call(stats.ray_misses==0 and stats.complete_frames==stats.samples and stats.capsule_dot_min>=0.9999,
		"curved visual contact: every bowl wheel ray hits the real finite face while native collider support stays aligned")
	check.call(stats.board_dot_min>=0.999,
		"curved visual contact: actual caught board normal follows the bowl support through the entire lateral carve")
	check.call(_healthy(stats),
		"curved visual contact: actual bowl wheel geometry retains healthy contact skin without penetration or large floating gaps")
	_print("bowl",stats)
	_phase = ""

static func _bowl_flip_return(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree,game,SAFE)
	var bowl: Node3D = game.world.get_node("ClydeEastBowl")
	var sample: Dictionary = bowl.sample(0.6,0.0)
	var speed := sqrt(22.0*(bowl.floor_radius+bowl.radius*sin(0.6))*tan(0.6))
	var rider: CharacterBody3D = game.skater
	rider.set_physics_process(false)
	rider.spawn_position = sample.point+sample.normal*0.022
	rider.reset_skater()
	rider.velocity = sample.lateral*speed
	rider.speed = speed
	rider.airborne = false
	rider.rotation.y = atan2(-rider.velocity.x,-rider.velocity.z)
	rider.set_physics_process(true)
	await _frames(tree,30)
	var setup_valid: bool = rider.transition_active and rider._transition.state=="surface" and not rider.airborne
	var evidence := {"bails":0,"landings":0,"entries":[],"banks":0}
	var on_bail := func(): evidence.bails += 1
	var on_land := func(clean: bool):
		if clean: evidence.landings += 1
	var on_trick := func(_label: String, _points: int): evidence.entries.append(rider.last_trick_id)
	rider.bailed.connect(on_bail)
	rider.landed.connect(on_land)
	rider.trick_performed.connect(on_trick)
	_phase = "curved_visual_bowl_flip_return"
	Input.action_press("ollie")
	await _frames(tree,2)
	var previous_body: Vector3 = rider.global_position
	var previous_head: Vector3 = rider._visual_rig._head.global_position
	var previous_air: bool = rider.airborne
	var saw_air := false
	var saw_flip := false
	var caught := false
	var descending_return := false
	var max_head_relative := 0.0
	var max_body_step := 0.0
	var contact_steps: Array = []
	var stats := _stats()
	var feet := {"samples":0,"gap_min":INF,"gap_max":-INF,"reach_max":0.0,"board_up_min":1.0}
	var post_land := 0
	var camera_blocked := 0
	var previous_bank: int = game.score.total_score
	Input.action_release("ollie")
	for frame in 180:
		if frame==1: Input.action_press("flip")
		if frame==3: Input.action_release("flip")
		var descending: bool = rider.velocity.y<0.0
		await _frames(tree,1)
		# The process-frame signal precedes camera processing; measure the actual
		# completed player/chase update before examining native visibility.
		if not (_observer.is_valid() and not _phase.is_empty()):
			await tree.create_timer(0.0).timeout
		var body: Vector3 = rider.global_position
		var head: Vector3 = rider._visual_rig._head.global_position
		var body_step := body-previous_body
		var head_relative := (head-previous_head-body_step).length()
		max_head_relative = maxf(max_head_relative,head_relative)
		max_body_step = maxf(max_body_step,body_step.length())
		saw_air = saw_air or rider.airborne
		saw_flip = saw_flip or rider._flip_remaining>0.0
		caught = caught or (saw_flip and rider._flip_remaining<=0.0)
		if previous_air and not rider.airborne:
			descending_return = descending_return or descending
			post_land = 1
			contact_steps.append({"frame":frame,"body_step":body_step.length(),"head_relative":head_relative,
				"normal":var_to_str(rider.get_support_normal())})
		elif post_land>0: post_land += 1
		if post_land>0 and not rider.airborne and rider._flip_remaining<=0.0 and rider._grab_remaining<=0.0 and feet.samples<16:
			_caught_feet(rider,feet)
		if post_land>=12 and rider.transition_active and rider._transition.state=="surface":
			_measure(rider,bowl,stats)
		var ray := PhysicsRayQueryParameters3D.create(rider._camera.global_position,head,9)
		ray.exclude = [rider.get_rid()]
		if not rider.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): camera_blocked += 1
		if game.score.total_score>previous_bank:
			evidence.banks += 1
			previous_bank = game.score.total_score
		previous_body = body
		previous_head = head
		previous_air = rider.airborne
		if evidence.bails>0 or post_land>50: break
	_release()
	rider.bailed.disconnect(on_bail)
	rider.landed.disconnect(on_land)
	rider.trick_performed.disconnect(on_trick)
	check.call(setup_valid and saw_air and saw_flip and caught and descending_return and evidence.landings>=1 and evidence.bails==0,
		"curved visual return: mapped bowl pop and Kickflip catch reach a genuine clean descending contact")
	check.call(evidence.entries==["ollie","kickflip"] and game.score.total_score==800 and game.score.get_combo_value()==0 and evidence.banks==1,
		"curved visual return: actual bowl pop and Kickflip bank once without manufactured surface trick entries")
	check.call(max_head_relative<=0.30 and max_body_step<=0.30,
		"curved visual return: actual head motion stays continuous relative to body travel through catch, landing and toe exit")
	check.call(feet.samples>=8 and feet.gap_min>=-0.003 and feet.gap_max<=0.012,
		"curved visual return: both actual caught sole contacts meet detailed griptape triangles during the first landing frames")
	check.call(feet.samples>=8 and feet.reach_max<=0.845,
		"curved visual return: caught feet remain within the authored anatomical leg reach while the figure follows the support")
	check.call(stats.samples>=12 and stats.ray_misses==0 and _healthy(stats) and stats.board_dot_min>=0.999,
		"curved visual return: settled caught-board wheel geometry regains healthy actual native bowl contact")
	check.call(camera_blocked==0,
		"curved visual return: production chase keeps an unobstructed native view of the rider's actual head")
	print("CURVED_VISUAL_RETURN ",JSON.stringify({"evidence":evidence,"head_relative_max":max_head_relative,
		"body_step_max":max_body_step,"contact_steps":contact_steps,"camera_blocked":camera_blocked,"caught_feet":feet,"wheels":stats}))
	_phase = ""

static func _caught_feet(rider: CharacterBody3D, stats: Dictionary) -> void:
	var grip: MeshInstance3D = rider._board_visual.get_node("Griptape")
	var skeleton: Skeleton3D = rider._visual_rig._garments.skeleton
	for leg: Dictionary in rider._visual_rig._legs:
		var foot: Node3D = leg.foot
		var sole: Vector3 = foot.to_global(Footwear.SOLE_CONTACT)
		var distance: float = Repertoire._surface_distance(sole,[grip])
		var signed := INF
		var vertices := grip.mesh.get_faces()
		for index in range(0,vertices.size(),3):
			var a := grip.to_global(vertices[index])
			var b := grip.to_global(vertices[index+1])
			var c := grip.to_global(vertices[index+2])
			var normal := (b-a).cross(c-a).normalized()
			var projected := sole-normal*(sole-a).dot(normal)
			if normal.dot((b-a).cross(projected-a))>=-0.000001 \
				and normal.dot((c-b).cross(projected-b))>=-0.000001 \
				and normal.dot((a-c).cross(projected-c))>=-0.000001 \
				and sole.distance_to(projected)<=distance+0.00001:
				signed = distance*signf((sole-projected).dot(grip.global_basis.y))
				break
		var bone := skeleton.find_bone("left_thigh" if leg.side<0.0 else "right_thigh")
		var hip := skeleton.to_global(skeleton.get_bone_pose(bone).origin)
		stats.samples += 1
		stats.gap_min = minf(stats.gap_min,signed)
		stats.gap_max = maxf(stats.gap_max,signed)
		stats.reach_max = maxf(stats.reach_max,hip.distance_to(foot.global_position))
		stats.board_up_min = minf(stats.board_up_min,foot.global_basis.y.normalized().dot(grip.global_basis.y.normalized()))

static func _halfpipe_faces(tree: SceneTree, game: Node, check: Callable) -> void:
	var halfpipe: Node3D = game.world.get_node("StationConcourseHalfpipe")
	await _reset(tree,game,halfpipe.global_position+Vector3(2.4,0.8,0),PI*0.5)
	var faces := {"NorthTransition":_stats(),"SouthTransition":_stats()}
	_phase = "curved_visual_halfpipe_faces"
	Input.action_press("push")
	for frame in 520:
		await _frames(tree,1)
		if game.skater.bail_active: break
		if not game.skater.transition_active or game.skater._transition.state!="surface": continue
		var feature: Node3D = game.skater._transition.feature
		var theta: float = game.skater._transition._theta
		# All four wheels remain inside actual finite collision here. Toe/lip
		# straddles legitimately have another support or an airborne axle.
		if theta>=0.20 and theta<=1.30 and faces.has(str(feature.name)):
			_measure(game.skater,feature,faces[str(feature.name)])
		if faces.NorthTransition.samples>=8 and faces.SouthTransition.samples>=8: break
	Input.action_release("push")
	for name: String in ["NorthTransition","SouthTransition"]:
		var stats: Dictionary = faces[name]
		check.call(stats.samples>=8 and stats.ray_misses==0 and stats.complete_frames==stats.samples
			and stats.max_steer==0.0 and not game.skater.bail_active,
			"curved visual contact: real push-driven halfpipe traversal audits all four native wheel planes on "+name)
		check.call(stats.board_dot_min>=0.999 and stats.capsule_dot_min>=0.9999,
			"curved visual contact: supported board and unchanged native capsule align on "+name)
		check.call(_healthy(stats),
			"curved visual contact: connected "+name+" keeps actual wheel geometry within healthy contact skin")
		_print(name,stats)
	_phase = ""

static func _ordinary_bank(tree: SceneTree, game: Node, check: Callable, degrees: float) -> void:
	var bank := StaticBody3D.new()
	bank.name = "DeclaredNativeVisualCrossSlope"
	bank.position = Vector3(-22,2,28)
	var slope := tan(deg_to_rad(degrees))
	var a := Vector3(-4,-4*slope,-10)
	var b := Vector3(-4,-4*slope,10)
	var c := Vector3(4,4*slope,10)
	var d := Vector3(4,4*slope,-10)
	var faces := PackedVector3Array([a,c,b,a,d,c])
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	bank.add_child(collision)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex: Vector3 in faces: surface.add_vertex(vertex)
	surface.generate_normals()
	var visible := MeshInstance3D.new()
	visible.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("707c78")
	material.roughness = 0.9
	visible.material_override = material
	bank.add_child(visible)
	game.world.add_child(bank)
	await _reset(tree,game,bank.global_position+Vector3.UP*0.8)
	var stats := _stats()
	_phase = "curved_visual_native_bank" if degrees==20.0 else "curved_visual_native_bank_45"
	Input.action_press("push")
	for frame in 42:
		await _frames(tree,1)
		if frame>=12: _measure(game.skater,null,stats,bank)
	Input.action_release("push")
	check.call(stats.samples>=24 and stats.ray_misses==0 and stats.complete_frames==stats.samples
		and stats.max_steer==0.0 and game.skater.is_on_floor() and not game.skater.transition_active,
		"curved visual contact: ordinary native %.0f-degree cross-slope is measured during actual neutral skating"%degrees)
	check.call(stats.board_dot_min>=0.999,
		"curved visual contact: ordinary caught board follows the full native %.0f-degree cross-slope normal"%degrees)
	check.call(_healthy(stats),
		"curved visual contact: ordinary %.0f-degree bank wheels meet actual native planes without capsule-induced visual hovering"%degrees)
	_print("ordinary_native_bank_%.0f"%degrees,stats)
	_phase = ""
	await _reset(tree,game,SAFE)
	bank.queue_free()
	await tree.process_frame

static func _measure(rider: CharacterBody3D, feature: Node3D, stats: Dictionary, ordinary_floor: StaticBody3D=null) -> void:
	if rider.airborne or rider.bail_active or rider.grinding or rider.manual_active or rider.lip_active \
		or rider._flip_remaining>0.0 or rider._grab_remaining>0.0 or rider._special_remaining>0.0: return
	var normal: Vector3 = rider._transition.normal if feature!=null else rider.get_floor_normal()
	if normal.length_squared()<0.9: return
	normal = normal.normalized()
	stats.samples += 1
	if stats.samples==1: stats.support_normal_first=var_to_str(normal)
	stats.support_normal_last = var_to_str(normal)
	stats.max_steer = maxf(stats.max_steer,absf(Input.get_axis("steer_left","steer_right")))
	stats.board_dot_min = minf(stats.board_dot_min,rider._board_visual.global_basis.y.normalized().dot(normal))
	if feature!=null:
		stats.capsule_samples += 1
		stats.capsule_dot_min = minf(stats.capsule_dot_min,rider.get_node("BodyCollision").global_basis.y.normalized().dot(normal))
	var minimum := INF
	var maximum := -INF
	var wheel_count := 0
	var wheel_gaps: Array[float] = []
	var wheel_normals: Array[String] = []
	for child: Node in rider._board_visual.get_children():
		if not child is MeshInstance3D or not child.mesh is CylinderMesh: continue
		var cylinder: CylinderMesh = child.mesh
		if not is_equal_approx(cylinder.top_radius,0.032) or not is_equal_approx(cylinder.height,0.032): continue
		var point: Vector3 = child.global_position
		var axis := normal
		var wanted: Object = ordinary_floor
		if feature!=null:
			var sample: Dictionary = feature.surface_sample(point)
			if sample.is_empty():
				stats.ray_misses += 1
				continue
			point = sample.point
			axis = sample.normal
			wanted = feature.surface_body
		var ray := PhysicsRayQueryParameters3D.create(point+axis*0.30,point-axis*0.50,1)
		ray.exclude = [rider.get_rid()]
		var hit := rider.get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.is_empty() or hit.collider!=wanted:
			stats.ray_misses += 1
			continue
		var gap := INF
		for surface in child.mesh.get_surface_count():
			var vertices: PackedVector3Array = child.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for vertex: Vector3 in vertices:
				gap = minf(gap,(child.to_global(vertex)-Vector3(hit.position)).dot(hit.normal))
		minimum = minf(minimum,gap)
		maximum = maxf(maximum,gap)
		wheel_count += 1
		wheel_gaps.append(gap)
		wheel_normals.append(var_to_str(hit.normal))
	if wheel_count==4:
		if stats.complete_frames==0:
			stats.first_wheel_gaps = wheel_gaps
			stats.first_native_normals = wheel_normals
		stats.last_wheel_gaps = wheel_gaps
		stats.complete_frames += 1
		stats.wheel_min = minf(stats.wheel_min,minimum)
		stats.wheel_max = maxf(stats.wheel_max,maximum)
		stats.spread_max = maxf(stats.spread_max,maximum-minimum)

static func _stats() -> Dictionary:
	return {"samples":0,"complete_frames":0,"ray_misses":0,"max_steer":0.0,"capsule_samples":0,
		"board_dot_min":1.0,"capsule_dot_min":1.0,"wheel_min":999.0,"wheel_max":-999.0,"spread_max":0.0}

static func _healthy(stats: Dictionary) -> bool:
	return stats.complete_frames>0 and stats.wheel_min>=MIN_GAP and stats.wheel_max<=MAX_GAP and stats.spread_max<=MAX_SPREAD

static func _print(label: String, stats: Dictionary) -> void:
	var report := stats.duplicate()
	if report.capsule_samples==0: report.erase("capsule_dot_min")
	print("CURVED_VISUAL_CONTACT ",label," ",JSON.stringify(report))

static func _reset(tree: SceneTree, game: Node, at: Vector3, yaw: float=0.0) -> void:
	_phase = ""
	_release()
	game.skater.spawn_position = at
	game.restart_run()
	await _frames(tree,40)
	game.skater.rotation.y = yaw

static func _release() -> void:
	for action in InputMap.get_actions(): Input.action_release(action)

static func _frames(tree: SceneTree, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame
		_step += 1
		if _observer.is_valid() and not _phase.is_empty(): await _observer.call(_phase,_game,_step)

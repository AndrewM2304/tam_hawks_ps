extends RefCounted
## Actual Main capture on an authored sloped handrail. Only initial airborne
## position/momentum/facing are declared; every capture, pivot and exit is native.

const SAFE := Vector3(-22,0.8,28)
static var _observer := Callable()
static var _phase := ""
static var _step := 0

static func run(tree: SceneTree, game: Node, check: Callable, observer: Callable=Callable()) -> void:
	var old_spawn: Vector3 = game.skater.spawn_position
	var old_free: bool = game.free_skate_mode
	_observer = observer
	_step = 0
	await _case(tree,game,check,false)
	await _case(tree,game,check,true)
	_release()
	_phase = ""
	_observer = Callable()
	game.skater.spawn_position = old_spawn
	game.start_mode(old_free)

static func _case(tree: SceneTree, game: Node, check: Callable, backwards: bool) -> void:
	_release()
	game.skater.spawn_position = SAFE
	game.start_mode(true)
	await _frames(tree,game,8)
	var rail = null
	for line in game.world.get_grind_lines():
		if line.id == "Grind_Park_FiveStepHandrail": rail = line
	check.call(rail!=null and rail.is_valid,"grind grade: actual authored park stair handrail is available")
	if rail==null: return
	var best := -1.0
	var start := Vector3.ZERO
	var direction := Vector3.ZERO
	for i in range(rail.points.size()-1):
		var delta: Vector3 = rail.points[i+1]-rail.points[i]
		if absf(delta.normalized().y)<0.08 or delta.length()<best: continue
		best = delta.length()
		start = rail.points[i].lerp(rail.points[i+1],0.15)
		direction = delta.normalized()
	check.call(best>=4.0 and absf(direction.y)>0.08,"grind grade: fixture uses a real nonflat finite rail segment")
	if best<4.0: return
	var rider: CharacterBody3D = game.skater
	rider.set_physics_process(false)
	rider.spawn_position = start+Vector3.UP*0.15
	rider.reset_skater()
	rider.velocity = direction*4.0
	rider.velocity.y = minf(rider.velocity.y,-0.4)
	rider.speed = -4.0 if backwards else 4.0
	rider.airborne = true
	rider.rotation.y = atan2(-direction.x,-direction.z)+(PI if backwards else 0.0)
	var evidence := {"entries":[],"bails":0}
	var on_trick := func(_label: String,_points: int): evidence.entries.append(rider.last_trick_id)
	var on_bail := func(): evidence.bails += 1
	rider.trick_performed.connect(on_trick)
	rider.bailed.connect(on_bail)
	_phase = "grind_grade_backwards" if backwards else "grind_grade_forward"
	Input.action_press("grind")
	rider.set_physics_process(true)
	var contact_frames := 0
	var minimum_alignment := 1.0
	for frame in 18:
		await _frames(tree,game,1)
		if rider.grinding:
			contact_frames += 1
			minimum_alignment = minf(minimum_alignment,_alignment(rider))
	check.call(rider.grinding and rider._grind.line.id==rail.id and rider._rail_backwards==backwards \
		and rider.speed*(-1.0 if backwards else 1.0)>2.0 and evidence.entries==["rail_grind"] and evidence.bails==0,
		"grind grade: native capture retains declared facing and one real 50-50 entry "+str(backwards))
	var alignment := _alignment(rider)
	print("GRIND GRADE ",{"backwards":backwards,"position":str(rider.global_position),
		"velocity":str(rider.velocity),"board_alignment":alignment,"surface_pitch":rider._surface_pitch,
		"minimum_alignment":minimum_alignment,"contact_frames":contact_frames})
	check.call(rider.grinding and alignment>0.9995 and contact_frames>=16 and minimum_alignment>0.9995,
		"grind grade: actual board follows the physical rail from the first caught frame in its functional facing "+str(backwards))
	if backwards and rider.grinding:
		_phase = "grind_grade_rail_pivot"
		var heading: float = rider.rotation.y
		Input.action_press("revert")
		await _frames(tree,game,1)
		Input.action_release("revert")
		check.call(rider.grinding and not rider._rail_backwards and rider.speed>0 \
			and absf(absf(angle_difference(heading,rider.rotation.y))-PI)<0.001 \
			and evidence.entries==["rail_grind","grind_pivot"],
			"grind grade: actual fresh Rail Pivot turns physical facing once on the sloped rail")
		minimum_alignment = _normal_alignment(rider)
		for frame in 18:
			await _frames(tree,game,1)
			minimum_alignment = minf(minimum_alignment,_normal_alignment(rider))
		alignment = _alignment(rider)
		print("GRIND GRADE PIVOT ",{"position":str(rider.global_position),"board_alignment":alignment,
			"surface_pitch":rider._surface_pitch,"velocity":str(rider.velocity),"minimum_plane_alignment":minimum_alignment})
		check.call(rider.grinding and alignment>0.9995 and minimum_alignment>0.999 and evidence.bails==0,
			"grind grade: the actual animated pivot stays in the rail plane and finishes aligned to its new facing")
	Input.action_release("grind")
	await _frames(tree,game,2)
	check.call(not rider.grinding and evidence.bails==0 and evidence.entries.count("rail_grind")==1 \
		and evidence.entries.count("grind_pivot")==int(backwards),
		"grind grade: actual release preserves once-only entry/pivot receipts "+str(backwards))
	rider.trick_performed.disconnect(on_trick)
	rider.bailed.disconnect(on_bail)
	_phase = ""

static func _alignment(rider: CharacterBody3D) -> float:
	if not rider.grinding or rider.velocity.length_squared()<0.001: return -1.0
	var functional: Vector3 = rider.velocity.normalized()*(-1.0 if rider._rail_backwards else 1.0)
	var board: Node3D = rider._board_visual
	return (-board.global_basis.z).normalized().dot(functional)

static func _normal_alignment(rider: CharacterBody3D) -> float:
	if not rider.grinding or rider.velocity.length_squared()<0.001: return -1.0
	var normal := Vector3.UP.slide(rider.velocity.normalized()).normalized()
	var board: Node3D = rider._board_visual
	return board.global_basis.y.normalized().dot(normal)

static func _frames(tree: SceneTree, game: Node, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame
		_step += 1
		if _observer.is_valid() and not _phase.is_empty():
			await _observer.call(game,_phase,_step)

static func _release() -> void:
	for action: String in ["push","brake","steer_left","steer_right","ollie","flip","grab","grind", \
		"manual","revert","spin_left","spin_right","interact","special_one","special_two"]:
		Input.action_release(action)

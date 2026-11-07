extends RefCounted
## Current ordinary Main bank; one moving-start fixture, then mapped Manual and
## balance input only. No Station layout/geometry changes or per-frame pose writes.
const Balance=preload("res://tests/support/manual_balance_driver.gd")
const Driver=preload("res://tests/pt24_flagship_runs_tests.gd")
static var last_trace:Dictionary={}

class Witness extends Node:
	var rider:CharacterBody3D
	var score:RefCounted
	var active:=false
	var rows:Array[Dictionary]=[]
	var query:=PhysicsShapeQueryParameters3D.new()
	var first_hit:Dictionary={}
	func _physics_process(_delta:float)->void:
		if not active:return
		var space:PhysicsDirectSpaceState3D=rider.get_world_3d().direct_space_state
		query.transform=rider._board_visual.global_transform
		query.motion=Vector3.ZERO;query.margin=0.0
		query.collision_mask=1|2|8;query.exclude=[rider.get_rid()]
		var clear:=true
		for index:int in rider._grind_clearance._parts.size():
			query.shape=rider._grind_clearance._parts[index].shape
			var hits:Array[Dictionary]=space.intersect_shape(query,16)
			if hits.is_empty():continue
			clear=false
			if first_hit.is_empty():
				var hit:Dictionary=hits[0]
				first_hit={"physics":Engine.get_physics_frames(),"part":index,
					"native_path":str(hit.collider.get_path()),"native_rid":str(hit.rid),"integer_shape":hit.shape,
					"board":_matrix(query.transform),"body":_matrix(rider.global_transform),
					"rest":space.get_rest_info(query),"pairs":space.collide_shape(query,32)}
		var tyres_clear:=true
		for shape:ConvexPolygonShape3D in rider._floor_wheel_shapes:
			query.shape=shape
			tyres_clear=tyres_clear and space.intersect_shape(query,16).is_empty()
		rows.append({"physics":Engine.get_physics_frames(),"body":_matrix(rider.global_transform),
			"capsule":_matrix(rider.get_node("BodyCollision").global_transform),
			"visual":_matrix(rider._visual.global_transform),"board":_matrix(rider._board_visual.global_transform),
			"velocity":[rider.velocity.x,rider.velocity.y,rider.velocity.z],"speed":rider.speed,
			"manual":rider.manual_active,"balance":rider.manual_balance,"air":rider.airborne,
			"floor":rider.is_on_floor(),"bail":rider.bail_active,"score":score.total_score,"combo":score.get_combo_value(),
			"all_parts_clear":clear,"all_tyres_clear":tyres_clear,
			"manual_pitch":rider._board_visual.rotation.x})
	static func _matrix(t:Transform3D)->Array:
		return [t.basis.x.x,t.basis.x.y,t.basis.x.z,t.basis.y.x,t.basis.y.y,t.basis.y.z,t.basis.z.x,t.basis.z.y,t.basis.z.z,t.origin.x,t.origin.y,t.origin.z]

static func run(tree:SceneTree,game:Node,check:Callable)->void:
	last_trace={"cases":[]}
	await _crossing(tree,game,check,false)
	await _crossing(tree,game,check,true)

static func _crossing(tree:SceneTree,game:Node,check:Callable,completed_turn:bool)->void:
	var old_spawn:Vector3=game.skater.spawn_position
	var old_free:bool=game.free_skate_mode
	_release()
	var bank:=game.world.get_node_or_null("station_low_manualManualDeck") as StaticBody3D
	check.call(is_instance_valid(bank),"Manual rim: existing actual Main Manual bank is present")
	if bank==null:return
	# The bank position comes from the current native actual body. A single
	# approach placement and moving-start seed are declared before input begins.
	var center:Vector3=bank.global_position
	game.skater.spawn_position=Vector3(center.x-11.14338684082031,2.08,center.z-.99549789428711) if completed_turn else Vector3(center.x-6.8,2.08,center.z-.16)
	game.start_mode(true)
	game.skater.rotation.y=atan2(-9.001139640808105,-1.6229463815689087) if completed_turn else -1.5907448530197144
	await _frames(tree,40)
	var rider:CharacterBody3D=game.skater
	check.call(rider.is_on_floor() and not rider.airborne,"Manual rim: declared current-world approach settles on native support")
	# Explicit native-contact/moving-start fixture, not a claimed earned
	# preceding shuvit/whole route. Only this initial body placement/board
	# completed-turn state and momentum are seeded; later travel is native.
	if completed_turn:
		rider.global_position=Vector3(center.x-11.14338684082031,2.0124166011810303,center.z-.99549789428711)
		rider._deck_yaw=PI
		rider.reset_physics_interpolation()
	var native:Dictionary=rider._native_floor_hit(Vector3.UP)
	check.call(not native.is_empty() and Vector3(native.get("normal",Vector3.ZERO)).y>=cos(rider.floor_max_angle),"Manual rim: declared moving-start frame retains genuine native walkable floor proof")
	rider.speed=9.146161079406738 if completed_turn else 7.402595043182373
	rider.velocity=-rider.global_basis.z*rider.speed
	var witness:=Witness.new()
	witness.rider=rider;witness.score=game.score
	witness.process_physics_priority=100
	game.add_child(witness);witness.active=true
	Input.action_press("manual")
	var first_target:=Vector3(center.x-8,2,center.z)
	for tick:int in 90:
		if completed_turn and tick>0:
			var target:Vector3=first_target if rider.global_position.x<center.x-9.66 else Vector3(center.x+7,2,center.z)
			Driver._manual_to(game,target)
		elif rider.manual_active:
			var correction:float=-(0.18+0.08*rider._manual_elapsed)/rider.MANUAL_BALANCE_CONTROL-(rider.manual_balance-.012848351488510787)*1.2
			Balance.correct(rider,correction)
		await _frames(tree,1)
	witness.active=false
	var samples:=0
	var all_clear:=true
	var supported:=true
	var crossed:=false
	for row:Dictionary in witness.rows:
		if not row.manual:continue
		samples+=1
		all_clear=all_clear and row.all_parts_clear and row.all_tyres_clear
		supported=supported and row.floor and not row.air and not row.bail
		crossed=crossed or float(row.body[9])>center.x-2.5
	check.call(samples>=60 and crossed and supported,"Manual rim: mapped Manual crosses the unchanged finite west crest without bail or support loss")
	check.call(samples>=60 and all_clear,"Manual rim: every real-physics actual tyre and connected board component clears every native solid")
	var trace:Dictionary={"bank_center":center,"completed_turn":completed_turn,"fixture":"declared native-contact body/heading/completed-turn moving-start seed, then mapped Manual/steer/balance only",
		"rows":witness.rows,"first_hit":witness.first_hit,"manual_samples":samples,"crossed":crossed,"supported":supported}
	last_trace.cases.append(trace)
	print("MANUAL_RIM_CURRENT_MAIN ",JSON.stringify({"completed_turn":completed_turn,"samples":samples,"crossed":crossed,"supported":supported,"all_clear":all_clear,"first_hit":witness.first_hit}))
	_release();witness.queue_free()
	game.skater.spawn_position=old_spawn
	game.start_mode(old_free)
	await _frames(tree,2)

static func _frames(tree:SceneTree,count:int)->void:
	for tick:int in count:
		await tree.physics_frame
		await tree.process_frame
static func _release()->void:
	for action:StringName in InputMap.get_actions():Input.action_release(action)

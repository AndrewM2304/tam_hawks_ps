extends RefCounted
## Current ordinary Main bank; one moving-start fixture, then mapped Manual and
## balance input only. No Station layout/geometry changes or per-frame pose writes.
const Balance=preload("res://tests/support/manual_balance_driver.gd")
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
	var old_spawn:Vector3=game.skater.spawn_position
	var old_free:bool=game.free_skate_mode
	_release()
	var bank:=game.world.get_node_or_null("station_low_manualManualDeck") as StaticBody3D
	check.call(is_instance_valid(bank),"Manual rim: existing actual Main Manual bank is present")
	if bank==null:return
	# The bank position comes from the current native actual body. A single
	# approach placement and moving-start seed are declared before input begins.
	var center:Vector3=bank.global_position
	game.skater.spawn_position=Vector3(center.x-6.8,2.08,center.z-.16)
	game.start_mode(true)
	game.skater.rotation.y=-1.5907448530197144
	await _frames(tree,40)
	var rider:CharacterBody3D=game.skater
	check.call(rider.is_on_floor() and not rider.airborne,"Manual rim: declared current-world approach settles on native support")
	rider.speed=7.402595043182373
	rider.velocity=-rider.global_basis.z*rider.speed
	var witness:=Witness.new()
	witness.rider=rider;witness.score=game.score
	witness.process_physics_priority=100
	game.add_child(witness);witness.active=true
	Input.action_press("manual")
	for tick:int in 90:
		if rider.manual_active:
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
	last_trace={"bank_center":center,"fixture":"one placement/heading and moving-start seed, then mapped Manual/balance only",
		"rows":witness.rows,"first_hit":witness.first_hit,"manual_samples":samples,"crossed":crossed,"supported":supported}
	print("MANUAL_RIM_CURRENT_MAIN ",JSON.stringify({"samples":samples,"crossed":crossed,"supported":supported,"all_clear":all_clear,"first_hit":witness.first_hit}))
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

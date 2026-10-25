extends SceneTree
const Main = preload("res://game/main.gd")
const Civic = preload("res://tests/pt24_civic_flagship_tests.gd")
const Board = preload("res://tests/board_geometry_tests_support.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")
var passed := 0
var failed := 0
var seen := {}
var hulls := {}
const WITNESSES := [
	{"rider": Vector3(-12.00201,1.999328,-41.88755), "marker": Vector3(-12.1306,2.017051,-42.12531)},
	{"rider": Vector3(-9.898241,2.03735,-37.07586), "marker": Vector3(-10.16565,1.990563,-37.12523)},
]
func _initialize() -> void: _run.call_deferred()
func _check(ok: bool,label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ",label)
func _run() -> void:
	var game := Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	_check(not game.music._can_control and not game.music._persist,"manual diagnostic has no Music control or preferences")
	await Civic.run_player(self,game,_check,_observe)
	_check(seen.size()==2,"both exact Civic manual-grade witnesses classified")
	game.queue_free()
	await process_frame
	print("RESULT: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
func _observe(stage: String,game: Node,tick: int) -> void:
	if stage != "manual_court_close_entrance": return
	for index: int in WITNESSES.size():
		if seen.has(index) or game.skater.global_position.distance_to(WITNESSES[index].rider)>0.025: continue
		seen[index] = true
		var rider: CharacterBody3D = game.skater
		var rig: RefCounted = rider._visual_rig
		var entries: Array[Dictionary] = [{"kind":"head_origin","at":rig._head.global_position},
			{"kind":"board_origin","at":rider._board_visual.global_position}]
		for mesh: MeshInstance3D in Board.visible_meshes(rig):
			var key := mesh.mesh.get_instance_id()
			if not hulls.has(key): hulls[key]=mesh.mesh.create_convex_shape(true,false).points
			for point: Vector3 in hulls[key]:
				entries.append({"kind":"mesh_convex","mesh":str(mesh.get_path()),"local":point,"at":mesh.to_global(point)})
		for leg: Dictionary in rig._legs:
			entries.append({"kind":"sole","side":leg.side,"at":leg.foot.to_global(Footwear.SOLE_CONTACT)})
			entries.append({"kind":"toe","side":leg.side,"at":leg.foot.to_global(Footwear.TOE_CONTACT)})
		var chosen: Dictionary = {}
		var nearest := INF
		for entry: Dictionary in entries:
			var delta: float = entry.at.distance_squared_to(WITNESSES[index].marker)
			if delta<nearest: nearest=delta;chosen=entry
		var shape: Transform3D = rider._board_visual.global_transform
		var component := -1
		var wheel_distance := INF
		var wheel_stats: Array[Dictionary] = []
		var space := rider.get_world_3d().direct_space_state
		var excluded: Array[RID] = [rider.get_rid()]
		var wheel_index := 0
		for wheel: Dictionary in rig.board_contact_geometry().wheels:
			var minimum_gap := INF
			var lowest_point := Vector3.ZERO
			var lowest_hit := {}
			for point: Vector3 in wheel.points:
				var actual: Vector3=shape*point
				var delta: float=actual.distance_squared_to(chosen.at)
				if delta<wheel_distance: wheel_distance=delta;component=wheel_index
				var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(actual+Vector3.UP*.08,actual-Vector3.UP*.18,1|8,excluded))
				if not hit.is_empty() and Vector3(hit.normal).y>.5:
					var gap: float=(actual-Vector3(hit.position)).dot(hit.normal)
					if gap<minimum_gap: minimum_gap=gap;lowest_point=actual;lowest_hit=hit
			wheel_stats.append({"wheel":wheel_index,"local_center":wheel.center,"minimum_native_gap":minimum_gap,
				"lowest_actual_vertex":lowest_point,"support_point":lowest_hit.get("position"),"normal":lowest_hit.get("normal"),
				"support":str(lowest_hit.get("collider"))})
			wheel_index+=1
		var marker: Vector3=chosen.at
		var native:=space.intersect_ray(PhysicsRayQueryParameters3D.create(marker+Vector3.UP*.08,marker-Vector3.UP*.18,1|8,excluded))
		var sight:=space.intersect_ray(PhysicsRayQueryParameters3D.create(rider._camera.global_position,marker,1|8,excluded))
		print("MANUAL_GRADE_CLASSIFICATION ",JSON.stringify({"witness":index,"tick":tick,"rider":rider.global_position,
			"chosen":chosen,"match_error_m":sqrt(nearest),"nearest_tyre_component":component,
			"tyre_vertex_error_m":sqrt(wheel_distance),"actual_support":native.get("position"),
			"native_normal":native.get("normal"),"native_gap_m":(marker-Vector3(native.position)).dot(native.normal) if not native.is_empty() else INF,
			"collider":str(native.get("collider")),"sight_hit":sight.get("position"),"manual":rider.manual_active,
			"manual_id":rider.manual_trick_id,"balance":rider.manual_balance,"board_rotation":rider._board_visual.rotation,
			"board_origin":rider._board_visual.global_position,"board_local_origin":rider._board_visual.position,
			"visual_basis":rider._visual.global_basis,"visual_origin":rider._visual.global_position,
			"native_floor_normal":rider._native_floor_normal(),"wheel_stats":wheel_stats}))

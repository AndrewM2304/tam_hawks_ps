extends SceneTree
const Main = preload("res://game/main.gd")
const Run = preload("res://tests/pt24_clyde_flagship_tests.gd")
const Board = preload("res://tests/board_geometry_tests_support.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")
const WITNESSES := [
	{"rider":Vector3(-5.628685,.60745,139.6117),"marker":Vector3(-5.884013,.532281,139.782)},
	{"rider":Vector3(-4.377836,.793868,139.2057),"marker":Vector3(-4.160343,.929683,139.3932)},
	{"rider":Vector3(-1.96736,1.133256,136.7784),"marker":Vector3(-1.728428,1.275433,136.9654)},
]
var passed := 0
var failed := 0
var seen := {}
var hulls := {}
class Trace extends Node:
	var game: Node
	var host: Object
	func _ready() -> void: process_priority=200
	func _process(_delta: float) -> void:
		if is_instance_valid(game): host.call("_observe",game)
func _initialize() -> void: _run.call_deferred()
func _check(ok: bool,label: String) -> void:
	if ok:passed+=1
	else:failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run() -> void:
	var game := Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	for frame in 20:
		await physics_frame
		await process_frame
	var trace := Trace.new()
	trace.game=game
	trace.host=self
	game.add_child(trace)
	await Run.run_bank_return(self,game,_check)
	_check(seen.size()==3,"all three exact bowl contact witnesses have component/native support classifications")
	game.queue_free()
	await process_frame
	await physics_frame
	await process_frame
	print("CLYDE_CONTACT_TRACE_RESULT passed=",passed," failed=",failed)
	quit(1 if failed else 0)
func _observe(game: Node) -> void:
	for index: int in WITNESSES.size():
		if seen.has(index) or game.skater.global_position.distance_to(WITNESSES[index].rider)>.025: continue
		seen[index]=true
		_classify(game,index)
func _classify(game: Node,index: int) -> void:
	var rider: CharacterBody3D=game.skater
	var rig: RefCounted=rider._visual_rig
	var entries: Array[Dictionary]=[{"kind":"head_origin","at":rig._head.global_position},
		{"kind":"board_origin","at":rider._board_visual.global_position}]
	for mesh: MeshInstance3D in Board.visible_meshes(rig):
		var key: int=mesh.mesh.get_instance_id()
		if not hulls.has(key):hulls[key]=mesh.mesh.create_convex_shape(true,false).points
		for point: Vector3 in hulls[key]:
			entries.append({"kind":"mesh_convex","mesh":str(mesh.get_path()),"local":point,
				"at":mesh.to_global(point),"interpolated_at":mesh.get_global_transform_interpolated()*point,
				"frame":mesh.global_transform,"interpolated_frame":mesh.get_global_transform_interpolated()})
	for leg: Dictionary in rig._legs:
		entries.append({"kind":"sole","side":leg.side,"at":leg.foot.to_global(Footwear.SOLE_CONTACT),
			"interpolated_at":leg.foot.get_global_transform_interpolated()*Footwear.SOLE_CONTACT})
		entries.append({"kind":"toe","side":leg.side,"at":leg.foot.to_global(Footwear.TOE_CONTACT),
			"interpolated_at":leg.foot.get_global_transform_interpolated()*Footwear.TOE_CONTACT})
	var chosen: Dictionary={}
	var nearest:=INF
	for entry: Dictionary in entries:
		var distance: float=entry.at.distance_squared_to(WITNESSES[index].marker)
		if distance<nearest:nearest=distance;chosen=entry
	var space:=rider.get_world_3d().direct_space_state
	var excluded: Array[RID]=[rider.get_rid()]
	var marker: Vector3=chosen.at
	var sight:=space.intersect_ray(PhysicsRayQueryParameters3D.create(rider._camera.global_position,marker,1|8,excluded))
	var vertical:=space.intersect_ray(PhysicsRayQueryParameters3D.create(marker+Vector3.UP*.08,marker-Vector3.UP*.18,1|8,excluded))
	var axis: Vector3=sight.get("normal",Vector3.UP)
	var normal_probe:=space.intersect_ray(PhysicsRayQueryParameters3D.create(marker+axis*.08,marker-axis*.18,1|8,excluded))
	var board_frame: Transform3D=rider._board_visual.global_transform
	var wheel_distance:=INF
	var component:=-1
	var wheel_stats: Array[Dictionary]=[]
	var wheel_index:=0
	for wheel: Dictionary in rig.board_contact_geometry().wheels:
		var minimum_gap:=INF
		var lowest_point:=Vector3.ZERO
		var lowest_hit: Dictionary={}
		for point: Vector3 in wheel.points:
			var actual: Vector3=board_frame*point
			var distance: float=actual.distance_squared_to(marker)
			if distance<wheel_distance:wheel_distance=distance;component=wheel_index
			var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(actual+axis*.08,actual-axis*.18,1|8,excluded))
			if hit.is_empty():continue
			var gap: float=(actual-Vector3(hit.position)).dot(hit.normal)
			if gap<minimum_gap:minimum_gap=gap;lowest_point=actual;lowest_hit=hit
		wheel_stats.append({"wheel":wheel_index,"centre":wheel.center,"minimum_native_gap":minimum_gap,
			"lowest_actual_vertex":lowest_point,"support_point":lowest_hit.get("position"),"normal":lowest_hit.get("normal"),
			"collider":str(lowest_hit.get("collider"))})
		wheel_index+=1
	print("CLYDE_BOWL_CONTACT_CLASSIFICATION ",JSON.stringify({"witness":index,"rider":rider.global_position,
		"chosen":chosen,"match_error_m":sqrt(nearest),"nearest_tyre_component":component,
		"tyre_vertex_error_m":sqrt(wheel_distance),"camera":rider._camera.global_position,
		"camera_interpolated":rider._camera.get_global_transform_interpolated().origin,
		"sight_hit":sight.get("position"),"sight_normal":sight.get("normal"),
		"vertical_support":vertical.get("position"),"vertical_normal":vertical.get("normal"),
		"vertical_gap_m":(marker-Vector3(vertical.position)).dot(vertical.normal) if not vertical.is_empty() else INF,
		"normal_support":normal_probe.get("position"),"normal_axis":axis,
		"normal_gap_m":(marker-Vector3(normal_probe.position)).dot(normal_probe.normal) if not normal_probe.is_empty() else INF,
		"collider":str(normal_probe.get("collider")),"board_origin":rider._board_visual.global_position,
		"board_interpolated_origin":rider._board_visual.get_global_transform_interpolated().origin,
		"visual_origin":rider._visual.global_position,"normal":rider._native_floor_normal(),
		"transition_normal":rider.transition_normal,"feature_state":rider._feature_transition.state,
		"wheel_stats":wheel_stats}))

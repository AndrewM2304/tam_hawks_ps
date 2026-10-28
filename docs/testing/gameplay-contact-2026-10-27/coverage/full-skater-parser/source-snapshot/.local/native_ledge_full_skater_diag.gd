extends SceneTree
const Audit=preload("res://game/levels/surface_audit.gd")
const Skater=preload("res://game/player/skater.gd")
const Style=preload("res://game/tricks/grind_style.gd")
const Setup=preload("res://game/core/input_setup.gd")
class Flat extends Node3D:
	func get_ground_height(_at: Vector3) -> float:return global_position.y
func _initialize() -> void:_run.call_deferred()
func _box(parent: Node3D,size: Vector3,at: Vector3) -> StaticBody3D:
	var body:=StaticBody3D.new();body.position=at;parent.add_child(body)
	var shape:=BoxShape3D.new();shape.size=size
	var collision:=CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
	return body
func _frames(count: int) -> void:
	for tick:int in count:await physics_frame;await process_frame
func _run() -> void:
	Setup.register_actions()
	for action:StringName in InputMap.get_actions():Input.action_release(action)
	var viewport:=SubViewport.new();viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;root.add_child(viewport)
	var fixture:=Flat.new();viewport.add_child(fixture)
	_box(fixture,Vector3(30,.2,30),Vector3(0,-.1,0))
	var bench:=_box(fixture,Vector3(6,.1,.6),Vector3(0,.5,0))
	var audit:=Audit.new();audit.build(fixture,[])
	var line= audit.lines[0]
	var distance:float=line.length*.4
	var target:Vector3=line.contact_at(distance)
	var tangent:Vector3=line.dir_at(distance)
	var rider:=Skater.new();rider.spawn_position=target+Vector3.UP*.15;fixture.add_child(rider)
	rider.set_physics_process(false);rider.set_process(false)
	rider.rotation.y=atan2(-tangent.x,-tangent.z);rider.set_grind_lines(audit.lines)
	await _frames(3)
	rider.velocity=tangent*6.0-Vector3.UP;rider.speed=6.0;rider.airborne=true
	# Match a real rendered neutral heading before measuring the normal candidate path.
	rider._visual.rotation.y=0.0;rider._board_visual.rotation.y=0.0
	rider._grind_board_forward=-rider._board_visual.global_basis.z
	var solved:bool=Style.solve_into(rider._grind_candidate_contact,line,distance,1.0,0.0,"grind_50_50",0.0)
	var frame:Transform3D=rider._grind_candidate_contact.board_transform
	var body_clear:bool=rider._rail_path_clear(rider.global_position,rider._grind._body_point(line,distance))
	var crown:bool=rider._grind_native_crown(line,distance)
	var model_clear:bool=rider._grind_clearance.allows_frame_path(frame,frame,Vector3.UP)
	var model_error:String=rider._grind_clearance.last_rejection
	var obstruction:Dictionary=rider._grind_clearance.last_obstruction.duplicate()
	var component_bounds:Array=[]
	for part:Dictionary in rider._grind_clearance._parts:
		var minimum:=Vector3.INF;var maximum:=-Vector3.INF
		for point:Vector3 in part.points:
			var world_point:Vector3=frame*point
			minimum=minimum.min(world_point);maximum=maximum.max(world_point)
		component_bounds.append({"min":minimum,"max":maximum,"points":part.points.size()})
	print("FULL_LEDGE_CANDIDATE ",{"guide":line.id,"points":line.points,"contact":target,"body":rider.global_position,
		"solved":solved,"crown":crown,"body_path_clear":body_clear,"model_clear":model_clear,
		"model_error":model_error,"obstruction":obstruction,"components":component_bounds,
		"supported":rider._grind_candidate_supported(line,distance,1.0)})
	var captures:Array[String]=[];rider.grind_captured.connect(func(id:String):captures.append(id))
	Input.action_press("grind");rider.set_physics_process(true);rider.set_process(true)
	for tick:int in 8:
		await _frames(1)
		print("FULL_LEDGE_TICK ",{"tick":tick,"position":rider.global_position,"velocity":rider.velocity,
			"grinding":rider.grinding,"style":rider.grind_style_id,"bailing":rider.bailing,"captures":captures,
			"model_error":rider._grind_clearance.last_rejection})
	for action:StringName in InputMap.get_actions():Input.action_release(action)
	viewport.queue_free();await process_frame
	quit()

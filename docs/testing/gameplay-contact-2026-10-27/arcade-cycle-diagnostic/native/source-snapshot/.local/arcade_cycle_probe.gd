extends SceneTree
const Arcade=preload("res://tests/arcade_response_integration_tests.gd")
const Setup=preload("res://game/core/input_setup.gd")
class Probe extends Node:
	var rider:CharacterBody3D
	var rows:Array[Dictionary]=[]
	func _ready()->void:process_physics_priority=200
	func _physics_process(_delta:float)->void:
		var contacts:Array[Dictionary]=[]
		for index:int in rider.get_slide_collision_count():
			var collision:KinematicCollision3D=rider.get_slide_collision(index)
			for item:int in collision.get_collision_count():
				var object:Object=collision.get_collider(item)
				contacts.append({"body":str(object.name) if object is Node else str(object),"grind_id":str(object.get_meta("grind_id","")) if object is Node else "","normal":_v(collision.get_normal(item)),"position":_v(collision.get_position(item))})
		var feature:Dictionary=rider._vert_return
		var local:=Vector3.INF;var lip_height:=INF
		if not feature.is_empty():
			local=feature.transform.affine_inverse()*rider.global_position
			lip_height=float(feature.radius)*(1.0-cos(float(feature.angle)))
		rows.append({"tick":Engine.get_physics_frames(),"position":_v(rider.global_position),"velocity":_v(rider.velocity),"air":rider.airborne,"floor":rider.is_on_floor(),"transition":str(rider._transition.feature.get("id","")) if rider.transition_active else "","theta":rider._transition.theta if rider.transition_active else 0.0,"vert_return":str(feature.get("id","")),"return_local":_v(local),"lip_height":lip_height,"transition_cooldown":rider._transition_cooldown,"body_axis":_v(rider._body_collision.global_basis.y),"shape_local_origin":_v(rider._body_collision.position),"collisions":contacts})
	func _v(point:Vector3)->Array:return [point.x,point.y,point.z]
func _initialize()->void:_run.call_deferred()
func _run()->void:
	Setup.register_actions();Arcade._release()
	var fixture:Dictionary=await Arcade._fixture(self,true)
	var probe:=Probe.new();probe.rider=fixture.rider;fixture.root.add_child(probe)
	fixture.recorder.active=true
	Arcade._key(KEY_W,true);await Arcade._ticks(self,360);Arcade._release()
	var lip_heights:Dictionary={}
	for feature:Dictionary in fixture.features:lip_heights[feature.id]=feature.transform.origin.y+float(feature.radius)*(1.0-cos(float(feature.angle)))
	var natural:Dictionary=Arcade._natural_returns(fixture.recorder.rows,lip_heights)
	var output:String=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	var report:Dictionary={"rows":probe.rows,"natural":natural,"scope":"Read-only actual original Arcade Push fixture;360nativeupdates,nonewposition/velocityassignments. Actual production bug classification, not passing regression evidence."}
	FileAccess.open(output.path_join("rows.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("ARCADE_CYCLE_DIAGNOSTIC rows=",probe.rows.size()," natural=",natural)
	await Arcade._dispose(self,fixture);quit(0)

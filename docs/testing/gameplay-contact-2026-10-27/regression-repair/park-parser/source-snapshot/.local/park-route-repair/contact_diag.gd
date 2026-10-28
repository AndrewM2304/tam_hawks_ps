extends SceneTree
const Main=preload("res://game/main.gd")
const Park=preload("res://tests/pt24_park_run_tests.gd")
const Gallery=preload("res://tests/pt24_gallery_entrance_run_tests.gd")
var passed:=0
var failed:=0
class Poll extends Node:
	var game:Node
	var seen:=0
	var bail_seen:=false
	func _physics_process(_delta:float)->void:
		if not is_instance_valid(game):return
		var rider=game.skater
		var at:Vector3=rider.global_position
		if rider.bailing and not bail_seen:
			bail_seen=true;print("PARK_NATIVE_FIRST_BAIL ",JSON.stringify({"at":at,"reason":rider.bail_reason,"model_rejection":rider._grind_clearance.last_rejection,"model_obstruction":rider._grind_clearance.last_obstruction}))
		if not Input.is_action_pressed("grind") or rider.grinding or not rider.airborne or seen>=40:return
		var wanted:="Grind_Ledge_park_east_lower" if at.x< -140 else "Grind_Ledge_GalleryEntrance"
		for line in game.world.get_grind_lines():
			if line.id!=wanted:continue
			var near:Dictionary=line.closest(at)
			if near.gap>.9:return
			var shift:Vector3=rider._grind._body_point(line,float(near.dist))-line.point_at(float(near.dist))
			near=line.closest(at-shift)
			var offset:float=float(near.dist)
			var target:Vector3=rider._grind._body_point(line,offset)
			var dir:float=1 if rider.velocity.dot(line.dir_at(offset))>=0 else -1
			var crown:bool=rider._grind_native_crown(line,offset)
			var body:bool=rider._grind_capture_path_clear(line,at,target,offset,dir,rider.velocity,false)
			var model:bool=rider._grind_candidate_supported(line,offset,dir)
			seen+=1
			print("PARK_NATIVE_ADMISSION ",JSON.stringify({"at":at,"velocity":rider.velocity,"target":target,"gap":at.distance_to(target),"height":at.y-target.y,"offset":offset,"crown":crown,"body":body,"model":model,"model_reason":rider._grind_clearance.last_rejection,"model_obstruction":rider._grind_clearance.last_obstruction,"request":rider._grind_request_available(),"cooldown":rider._grind_cooldown,"flip":rider._flip_remaining,"flip_buffer":rider._flip_buffer_remaining,"special":rider._special_remaining,"spin_clean":rider._spin_landing_clean(),"on_floor":rider.is_on_floor()}))
			return
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var game=Main.new();game.persistence_enabled=false;root.add_child(game);game.start_mode(true)
	var poll:=Poll.new();poll.game=game;poll.process_physics_priority=100;root.add_child(poll)
	if OS.get_cmdline_user_args().has("gallery"):await Gallery.run(self,game,_check)
	else:await Park.run(self,game,_check)
	poll.queue_free();game.queue_free();await process_frame
	print("RESULT: ",passed," passed, ",failed," failed");quit(1 if failed else 0)
func _check(ok:bool,label:String)->void:
	if ok:passed+=1;print("PASS: "+label)
	else:failed+=1;push_error("FAIL: "+label)

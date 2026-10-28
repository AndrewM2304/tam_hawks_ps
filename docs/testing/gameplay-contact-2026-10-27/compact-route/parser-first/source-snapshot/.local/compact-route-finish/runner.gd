extends SceneTree
const Main=preload("res://game/main.gd")
const Setup=preload("res://game/core/input_setup.gd")
const Suite=preload("res://tests/compact_clyde_lines_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
	if ok:passed+=1;print("PASS: "+label)
	else:failed+=1;push_error("FAIL: "+label)
func _run()->void:
	Setup.register_actions()
	var game=Main.new()
	game.persistence_enabled=false
	game.set_meta("pt24_design_preview",false)
	root.add_child(game)
	for frame:int in 35:
		await physics_frame
		await process_frame
	print("COMPACT_FOCUS_CONTEXT main=",game.get_meta("pt24_design_preview")," world=",game.world.get_meta("pt24_design_preview",false))
	var args:=OS.get_cmdline_user_args()
	if args.has("runway"):
		_runway(game)
	elif args.has("quay"):
		await Suite._line(self,game,_check,"clyde_quay_coping",5.2,18.0,false)
	elif args.has("river"):
		await Suite._river_circuit(self,game,_check)
	else:
		_runway(game)
		await Suite._line(self,game,_check,"clyde_quay_coping",5.2,18.0,false)
		await Suite._river_circuit(self,game,_check)
	Suite.Driver.release()
	game.queue_free()
	await process_frame
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)

func _runway(game:Node)->void:
	var rider:CharacterBody3D=game.skater
	var body:CollisionShape3D=rider.get_node("BodyCollision")
	var original:=body.shape as CapsuleShape3D
	var shell:=original.duplicate() as CapsuleShape3D
	# Keep the exact native height/base; expand only the horizontal support
	# envelope by the player's existing safety margin while standing abovefloor.
	shell.radius=original.radius+rider.safe_margin
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=shell;query.collision_mask=rider.collision_mask
	query.exclude=[rider.get_rid()];query.collide_with_areas=false;query.margin=0.0
	var space:PhysicsDirectSpaceState3D=game.world.get_world_3d().direct_space_state
	for points:PackedVector3Array in [
		PackedVector3Array([Vector3(20,2,120),Vector3(20,2,125.2),Vector3(25,2,125.2),Vector3(54,2,125.2),Vector3(54,2,127.5)]),
		PackedVector3Array([Vector3(20,2,138),Vector3(14,2,125.2),Vector3(-25,2,125.2),Vector3(-25,2,124)])]:
		var clear:=true;var minimum:=1.0
		for index:int in points.size()-1:
			for reverse:bool in [false,true]:
				var from:Vector3=points[index+1] if reverse else points[index]
				var to:Vector3=points[index] if reverse else points[index+1]
				query.transform=Transform3D(rider.global_basis,from+Vector3.UP*rider.safe_margin)*body.transform
				query.motion=Vector3.ZERO
				clear=clear and space.intersect_shape(query,1).is_empty()
				query.motion=to-from
				var fractions:=space.cast_motion(query)
				clear=clear and fractions.size()==2 and fractions[0]>=.9999 and fractions[1]>=.9999
				if fractions.size()==2:minimum=minf(minimum,fractions[0])
				query.transform.origin+=to-from;query.motion=Vector3.ZERO
				clear=clear and space.intersect_shape(query,1).is_empty()
		_check(clear,"compact finite-end runway: same native capsule height/base plus actual horizontal15mm shell clears every ground segment in both directions")
		print("COMPACT_RUNWAY minimum_native_fraction=",minimum," radius=",shell.radius," height=",shell.height," original_height=",original.height," from=",points[0]," to=",points[-1])

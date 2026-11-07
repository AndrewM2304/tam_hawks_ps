extends SceneTree
const Skater=preload("res://game/player/skater.gd")
const Bowl=preload("res://game/levels/bowl_feature.gd")
const Setup=preload("res://game/core/input_setup.gd")
func _initialize():run.call_deferred()
func run():
	print("CLYDE TINY START ",Time.get_ticks_msec())
	Setup.register_actions()
	var fixture:=Node3D.new()
	root.add_child(fixture)
	var bowl:=Bowl.new()
	bowl.radius=2.4
	bowl.floor_radius=3.5
	bowl.deck_length=1.8
	bowl.build_access=false
	bowl.position=Vector3(-7,-0.4,134.5)
	bowl.rotation.y=PI*0.5
	fixture.add_child(bowl)
	bowl.build()
	var rider=Skater.new()
	rider.spawn_position=Vector3(-12.4,2.05,139.5004)
	fixture.add_child(rider)
	rider.rotation.y=-PI*0.5
	for i:int in 30:await physics_frame
	rider.velocity=Vector3(13.558563,0,0)
	rider.speed=13.558563
	for i:int in 22:
		await physics_frame
		var gaps:Array=[]
		var space:=rider.get_world_3d().direct_space_state
		for wheel:Dictionary in rider._visual_rig.board_contact_geometry().wheels:
			var gap:=INF
			var at_hit:Dictionary={}
			for point:Vector3 in wheel.points:
				var at:Vector3=rider._board_visual.to_global(point)
				var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*.15,at-Vector3.UP*.35,1|8,[rider.get_rid()]))
				if hit.is_empty():continue
				var current:float=(at-Vector3(hit.position)).dot(hit.normal)
				if current<gap:gap=current;at_hit={"normal":hit.normal,"at":hit.position,"body":str(hit.collider.get_path())}
			gaps.append({"gap":gap,"support":at_hit})
		print("CLYDE_TINY ",JSON.stringify({"step":i,"at":rider.global_position,"velocity":rider.velocity,"floor":rider.is_on_floor(),"normal":rider._native_floor_normal(),"board":rider._board_visual.global_transform,"wheels":gaps,"clear":rider._manual_model_frame_clear(rider._board_visual.global_transform)}))
	fixture.free()
	print("CLYDE TINY DONE")
	quit()

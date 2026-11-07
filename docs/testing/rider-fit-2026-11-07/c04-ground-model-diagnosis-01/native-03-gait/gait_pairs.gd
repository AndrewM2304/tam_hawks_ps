extends RefCounted
const Current=preload("res://game/player/skater_visual.gd")
const Before=preload("res://.local/skater_visual_before_gait.gd")
const Skater=preload("res://game/player/skater.gd")
const Setup=preload("res://game/core/input_setup.gd")
static func packed(rig:RefCounted)->PackedByteArray:
	var values:=PackedFloat32Array()
	var transforms:Array[Transform3D]=[rig._board.transform,rig._rider.transform,rig._upper.transform,rig._head.transform]
	for leg:Dictionary in rig._legs:transforms.append(leg.foot.transform)
	for arm:Dictionary in rig._arms:transforms.append(arm.hand.transform)
	for bone:int in rig._garments.skeleton.get_bone_count():transforms.append(rig._garments.skeleton.get_bone_pose(bone))
	for t:Transform3D in transforms:
		for v:Vector3 in [t.basis.x,t.basis.y,t.basis.z,t.origin]:values.append_array(PackedFloat32Array([v.x,v.y,v.z]))
	values.append_array(PackedFloat32Array([rig._push_phase,rig._push_blend,rig._brake_blend]))
	return values.to_byte_array()
static func build_twin(body:CharacterBody3D,source:Script)->RefCounted:
	var visual:=Node3D.new();body.add_child(visual);visual.transform=body._visual.transform
	var board:=Node3D.new();board.position.y=.12;visual.add_child(board)
	var rider:=Node3D.new();rider.rotation.y=-PI/2+.28;visual.add_child(rider)
	var rig:RefCounted=source.new();rig.build(board,rider,StandardMaterial3D.new())
	return rig
static func run(tree:SceneTree)->Dictionary:
	Setup.register_actions()
	for action:String in InputMap.get_actions():Input.action_release(action)
	var records:Array[Dictionary]=[]
	var okay:=true
	for grade:float in [0.0,-8.0,8.0,-20.0,20.0]:
		var viewport:=SubViewport.new();viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;tree.root.add_child(viewport)
		var root:=Node3D.new();viewport.add_child(root)
		var floor:=StaticBody3D.new();floor.rotation.x=deg_to_rad(grade);root.add_child(floor)
		var shape:=BoxShape3D.new();shape.size=Vector3(100,.2,100)
		var collision:=CollisionShape3D.new();collision.shape=shape;collision.position.y=-.1;floor.add_child(collision)
		var body:=Skater.new();body.spawn_position=Vector3(0,.08,0);root.add_child(body)
		for frame:int in 45:await tree.physics_frame;await tree.process_frame
		body.set_physics_process(false);body.set_process(false)
		var before:Transform3D=body.global_transform
		var velocity:Vector3=body.velocity
		var capsule:Transform3D=body._body_collision.transform
		var native_ok:bool=body.is_on_floor() and body._native_floor_valid
		var normal:Vector3=body.get_support_normal()
		var a:RefCounted=build_twin(body,Before)
		var b:RefCounted=build_twin(body,Current)
		for direction:float in [1.0,-1.0]:
			a.reset();b.reset()
			var equal:=true
			var first:=-1
			for tick:int in 240:
				var state:Dictionary={"airborne":false,"grab":false,"flip":false,"manual":false,"grind":false,"speed":6.0*direction,"travel_sign":direction,"push":tick<120,"brake":tick>=120 and tick<180}
				a.animate(1.0/60.0,state);b.animate(1.0/60.0,state)
				if packed(a)!=packed(b):
					equal=false
					if first<0:first=tick
			var protected:bool=body.global_transform==before and body.velocity==velocity and body._body_collision.transform==capsule
			var item:Dictionary={"grade":grade,"direction":direction,"native_floor_valid":native_ok,"native_normal":[normal.x,normal.y,normal.z],"samples":240,"pose_and_gait_float32_bytes_equal":equal,"first_difference":first,"physics_and_capsule_unchanged":protected}
			records.append(item);okay=okay and native_ok and equal and protected
		viewport.queue_free();await tree.process_frame;await tree.physics_frame
	return {"passed":okay,"records":records,"scope":"Declared paired pose-source regressions under the SAME actual authenticated frozen native support/capsule; all node+bone and gait float32 bytes compared. Not a controller trajectory or target-performance claim."}

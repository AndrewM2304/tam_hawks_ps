extends RefCounted
## Genuine Main rail transfers: the existing declared initial contact and mapped
## style commands use native physics. Observers never assign body/board pose,
## velocity, contact results, balance or score. Include the FIRST completed frame.
const Main = preload("res://game/main.gd")
const Overnight = preload("res://tests/overnight_integration_tests.gd")
const Geometry = preload("res://tests/board_geometry_tests_support.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")

class Sampler extends Node:
	var rider:CharacterBody3D
	var transfer_frames:=0
	var completion_frames:=0
	var prior_transfer:=false
	var camera_measure:=false
	var camera_frames:=0
	var camera_blocked:=0
	var camera_outside:=0
	var maximum_position_error:=0.0
	var maximum_axis_error:=0.0
	var maximum_sole_error:=0.0
	var maximum_limb_scale:=0.0
	var maximum_body_from_native_rail:=0.0
	var maximum_marker_step:=0.0
	var marker_worst={}
	var prior_board:=Basis.IDENTITY
	var prior_markers:Array[Vector3]=[]
	var prior_body:=Vector3.ZERO
	var styles=[]
	func _ready()->void:
		process_physics_priority=100
		process_priority=100
	func _physics_process(_delta:float)->void:
		if not is_instance_valid(rider) or not rider.grinding:
			prior_markers.clear();prior_transfer=false;camera_measure=false;return
		var rig=rider._visual_rig
		var board:Node3D=rider._board_visual
		var transfer:Variant=rider.get('_grind_transfer')
		var markers:Array[Vector3]=[rig._head.global_position]
		for leg:Dictionary in rig._legs:markers.append(leg.foot.global_position)
		for arm:Dictionary in rig._arms:markers.append(arm.hand.global_position)
		var active:bool=transfer!=null and transfer.active
		camera_measure=active or prior_transfer
		if camera_measure:
			if active:transfer_frames+=1
			else:completion_frames+=1
			if not styles.has(rider.grind_trick_id):styles.append(rider.grind_trick_id)
			var expected:Transform3D=transfer.board_transform if active else rider._grind_contact.board_transform
			maximum_position_error=maxf(maximum_position_error,board.global_position.distance_to(expected.origin))
			for axis in 3:maximum_axis_error=maxf(maximum_axis_error,board.global_basis[axis].distance_to(expected.basis[axis]))
			for leg:Dictionary in rig._legs:maximum_sole_error=maxf(maximum_sole_error,Geometry.grip_distance(rig,leg.foot.to_global(Footwear.SOLE_CONTACT)))
			for index in rig._garments.skeleton.get_bone_count():
				if rig._garments.skeleton.get_bone_name(index) in ['hips','torso']:continue
				maximum_limb_scale=maxf(maximum_limb_scale,rig._garments.skeleton.get_bone_pose_scale(index).y)
			maximum_body_from_native_rail=maxf(maximum_body_from_native_rail,rider.global_position.distance_to(rider._grind.position()))
			if not prior_markers.is_empty():
				for index in markers.size():
					var movement:float=(markers[index]-prior_markers[index]-(rider.global_position-prior_body)).length()
					if movement>maximum_marker_step:
						maximum_marker_step=movement
						marker_worst={'physics_frame':Engine.get_physics_frames(),'marker_index':index,'before':var_to_str(prior_markers[index]),'after':var_to_str(markers[index]),'body_step':rider.global_position.distance_to(prior_body),'phase':transfer.phase,'elapsed':transfer._elapsed,'leg':transfer._leg,'style':rider.grind_trick_id,'board_angle_degrees':rad_to_deg(prior_board.get_rotation_quaternion().angle_to(board.global_basis.get_rotation_quaternion()))}
		prior_markers=markers;prior_body=rider.global_position;prior_board=board.global_basis;prior_transfer=active
	func _process(_delta:float)->void:
		if not is_instance_valid(rider) or not rider.grinding:return
		var transfer:Variant=rider.get('_grind_transfer')
		if transfer==null or not camera_measure:return
		camera_frames+=1
		var camera:Camera3D=rider._camera
		var rig=rider._visual_rig
		var points:Array[Vector3]=[rig._head.get_global_transform_interpolated()*Vector3.ZERO]
		for leg:Dictionary in rig._legs:
			var frame:Transform3D=leg.foot.get_global_transform_interpolated()
			points.append(frame*Footwear.SOLE_CONTACT);points.append(frame*Footwear.TOE_CONTACT)
		for point:Vector3 in points:
			if not camera.is_position_in_frustum(point):camera_outside+=1
			var ray=PhysicsRayQueryParameters3D.create(camera.global_position,point,9);ray.exclude=[rider.get_rid()]
			if not rider.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():camera_blocked+=1


static func run(tree: SceneTree, check: Callable) -> void:
	var game = Main.new()
	game.persistence_enabled = false
	tree.root.add_child(game)
	for frame in 20:
		await tree.physics_frame
		await tree.process_frame
	var sampler := Sampler.new()
	sampler.rider = game.skater
	tree.root.add_child(sampler)
	await Overnight._rail_process(tree, game, check)
	check.call(sampler.transfer_frames >= 20 and sampler.maximum_position_error <= 0.0001
		and sampler.maximum_axis_error <= 0.0001,
		"native grind transfer: both live style changes display their natively tested board frames exactly")
	check.call(sampler.completion_frames == 2,
		"native grind transfer: both FIRST completed frames retain exact native target poses")
	check.call(sampler.transfer_frames > 0 and sampler.maximum_sole_error <= 0.001
		and sampler.maximum_limb_scale <= 1.12 and sampler.maximum_marker_step <= 0.24,
		"native grind transfer: actual soles, anatomical reach and unweight/turn/reseat continuity retain their strict bands")
	check.call(sampler.transfer_frames > 0 and sampler.maximum_body_from_native_rail <= 0.0001,
		"native grind transfer: presentation unweighting keeps the native body on its actual rail helper")
	check.call(sampler.camera_frames >= 10 and sampler.camera_blocked == 0 and sampler.camera_outside == 0,
		"native grind transfer: actual displayed head, soles and toes stay visible in the unchanged camera")
	print("NATIVE_GRIND_TRANSFER ", JSON.stringify({
		"transfer_frames":sampler.transfer_frames, "completion_frames":sampler.completion_frames,
		"camera_frames":sampler.camera_frames, "maximum_position_error":sampler.maximum_position_error,
		"maximum_axis_error":sampler.maximum_axis_error, "maximum_sole_error":sampler.maximum_sole_error,
		"maximum_limb_scale":sampler.maximum_limb_scale, "maximum_body_from_native_rail":sampler.maximum_body_from_native_rail,
		"maximum_marker_step":sampler.maximum_marker_step, "marker_worst":sampler.marker_worst,
		"camera_blocked":sampler.camera_blocked, "camera_outside":sampler.camera_outside, "styles":sampler.styles}))
	Overnight._release()
	sampler.queue_free()
	game.queue_free()
	await tree.process_frame
	await tree.physics_frame
	await tree.process_frame

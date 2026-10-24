extends RefCounted
## Real-input pose regressions: every native physics tick is observed after Skater.
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
const MotionClips=preload("res://game/player/trick_animation.gd")
const BoardGeometry=preload("res://tests/board_geometry_tests_support.gd")
const Footwear=preload("res://game/player/skater_footwear.gd")
class Probe extends Node:
	var rider:CharacterBody3D
	var samples:=0
	var maximum_length_error:=0.0
	var maximum_sole_error:=0.0
	var maximum_palm_error:=0.0
	var palm_samples:=0
	var finite:=true
	func _ready()->void:process_physics_priority=100
	func _physics_process(_delta:float)->void:
		var rig:RefCounted=rider._visual_rig
		var skin:Skeleton3D=rig._garments.skeleton
		for index in 2:
			var side:='left' if index==0 else 'right'
			var hip:=skin.get_bone_pose_position(skin.find_bone(side+'_thigh'))
			var knee:=skin.get_bone_pose_position(skin.find_bone(side+'_calf'))
			var shoulder:=skin.get_bone_pose_position(skin.find_bone(side+'_sleeve'))
			var elbow:=skin.get_bone_pose_position(skin.find_bone(side+'_forearm'))
			var foot:Node3D=rig._legs[index].foot
			var hand:Node3D=rig._arms[index].hand
			for ratio:float in [hip.distance_to(knee)/.43,knee.distance_to(foot.position)/.41,shoulder.distance_to(elbow)/.30,elbow.distance_to(hand.position)/.29]:
				finite=finite and is_finite(ratio)
				maximum_length_error=maxf(maximum_length_error,absf(ratio-1.0))
			# The front foot stays mounted on the deck except during a flip.
			if index==0 and rig._flip_blend<.001 and not rider.bailing:
				maximum_sole_error=maxf(maximum_sole_error,BoardGeometry.grip_distance(rig,foot.to_global(Footwear.SOLE_CONTACT)))
			if rider.airborne and rig._grab_blend>.98:
				var fallback:Dictionary=MotionClips.grab_pose(rider.active_grab_id)
				var definition:Dictionary=rider._grab_definition
				if float(definition.get("grab_side",fallback.hand_side))==rig._arms[index].side:
					var palm:Vector3=hand.to_global(Vector3(0,-.075,-.015))
					var target:Vector3=Basis(Vector3.UP,-rider._deck_yaw)*Vector3(definition.get("grab_target",fallback.deck_target))
					maximum_palm_error=maxf(maximum_palm_error,palm.distance_to(rig._board.to_global(target)))
					palm_samples+=1
		samples+=1
static func run(tree:SceneTree,check:Callable)->void:
	Classic.Setup.register_actions()
	for action:String in ['push','brake','manual']:
		var f:Dictionary=await Classic._fixture(tree)
		var probe:=Probe.new();probe.rider=f.rider;tree.root.add_child(probe)
		Input.action_press('push');await Classic._frames(tree,45)
		if action!='push':Input.action_release('push');Input.action_press(action)
		await Classic._frames(tree,70)
		_verify(probe,check,action,false)
		probe.queue_free();await Classic._dispose(tree,f)
	for entry:Dictionary in [
		{'id':'melon_grab','direction':Vector2.LEFT},
		{'id':'indy_grab','direction':Vector2.RIGHT},
		{'id':'nose_grab','direction':Vector2.UP},
		{'id':'tail_grab','direction':Vector2.DOWN},
		{'id':'method_grab','direction':Vector2(-1,-1)}]:
		var f:Dictionary=await Classic._fixture(tree)
		var probe:=Probe.new();probe.rider=f.rider;tree.root.add_child(probe)
		Input.action_press('ollie');await Classic._frames(tree,24);Input.action_release('ollie')
		await Classic._frames(tree,3);Classic._direction(entry.direction);Classic._key(KEY_K,true)
		await Classic._frames(tree,24);Classic._key(KEY_K,false);Classic._direction(Vector2.ZERO)
		await Classic._frames(tree,60)
		check.call(f.rider.is_on_floor() and f.rider.active_grab_id==entry.id,'limbs: actual '+entry.id+' input and support landing observed')
		_verify(probe,check,entry.id,true)
		probe.queue_free();await Classic._dispose(tree,f)
	for entry:Dictionary in [
		{'id':'kickflip','direction':Vector2.ZERO},
		{'id':'heelflip','direction':Vector2.RIGHT},
		{'id':'frontside_shuvit','direction':Vector2.UP},
		{'id':'pop_shuvit','direction':Vector2.DOWN},
		{'id':'varial_flip','direction':Vector2(-1,1)},
		{'id':'hardflip','direction':Vector2(1,-1)}]:
		var f:Dictionary=await Classic._fixture(tree)
		var probe:=Probe.new();probe.rider=f.rider;tree.root.add_child(probe)
		Input.action_press('ollie');await Classic._frames(tree,24);Input.action_release('ollie')
		await Classic._frames(tree,3);Classic._direction(entry.direction);Classic._key(KEY_J,true)
		await Classic._frames(tree,3);Classic._key(KEY_J,false);Classic._direction(Vector2.ZERO)
		await Classic._frames(tree,80)
		check.call(f.rider.is_on_floor() and f.rider.active_flip_id==entry.id,'limbs: actual '+entry.id+' and landing observed')
		_verify(probe,check,entry.id,false)
		probe.queue_free();await Classic._dispose(tree,f)
	var pipe:Dictionary=await Classic._pipe_fixture(tree,false,Vector3(-42,2.8,60.5),-PI*.5,true)
	var ramp_probe:=Probe.new();ramp_probe.rider=pipe.rider;tree.root.add_child(ramp_probe)
	Input.action_press('push');await Classic._frames(tree,720)
	_verify(ramp_probe,check,'natural half-pipe cycles',false)
	ramp_probe.queue_free();await Classic._dispose(tree,pipe)
	var rig=Classic.SkaterSource.SkaterVisualSource.new()
	for target:Vector3 in [Vector3.ZERO,Vector3.RIGHT*2,Vector3.DOWN*.4]:
		var endpoint:Vector3=rig._reachable(Vector3.ZERO,target,.30,.29)
		var elbow:Vector3=rig._joint(Vector3.ZERO,endpoint,.30,.29,Vector3.RIGHT)
		check.call(elbow.is_finite() and absf(elbow.length()-.30)<.00001 and absf(elbow.distance_to(endpoint)-.29)<.00001,'limbs: coincident/parallel/out-of-reach input retains finite authored lengths '+str(target))
	# A tiny uniform parent drift reproduces the native long-route quaternion
	# precondition failure without forcing motion/pose on any simulation tick.
	var drift:Dictionary=await Classic._fixture(tree)
	drift.rider.scale=Vector3.ONE*1.0001
	Input.action_press('push');Input.action_press('steer_left')
	await Classic._frames(tree,45)
	var stable:=true
	for leg:Dictionary in drift.rider._visual_rig._legs:
		stable=stable and leg.foot.basis.is_finite() and absf(leg.foot.basis.determinant()-1.0)<.00001
	check.call(stable,'limbs: actual turning under small parent drift keeps finite unit shoe orientation')
	await Classic._dispose(tree,drift)
static func _verify(probe:Probe,check:Callable,label:String,grab:bool)->void:
	check.call(probe.samples>80 and probe.finite and probe.maximum_length_error<.01,'limbs: '+label+' preserves authored segment lengths through entry/action/exit')
	check.call(probe.maximum_sole_error<.02 and (not grab or (probe.palm_samples>0 and probe.maximum_palm_error<.03)),'limbs: '+label+' retains planted front sole and active grab palm contacts')
	print('LIMB_POSE ',label,' samples=',probe.samples,' max_length_error=',probe.maximum_length_error,' sole_error_m=',probe.maximum_sole_error,' palm_error_m=',probe.maximum_palm_error,' palms=',probe.palm_samples)

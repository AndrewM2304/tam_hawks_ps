extends SceneTree
const Wall = preload("res://tests/skater_wall_presentation_tests.gd")
var passed:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	Wall.Setup.register_actions()
	for family: String in ["grab"]:
		_release()
		var f: Dictionary=await Wall._fixture(self,-8.0)
		var r: CharacterBody3D=f.rider
		var c: CharacterBody3D=f.control
		var reached:=false
		Input.action_press("push",0.55)
		for tick: int in 180:
			await Wall._frames(self,1)
			if Wall._wall_contact(r,f.wall):reached=true;break
		_release()
		Input.action_press("brake")
		await Wall._frames(self,20)
		_release()
		await Wall._frames(self,2)
		Input.action_press("ollie")
		await Wall._frames(self,20)
		Input.action_release("ollie")
		await Wall._frames(self,2)
		var prior: Vector3=r._obstacle_visual_offset
		var before:=Wall._plane_gap(r)
		var events: Array=[]
		r.trick_performed.connect(func(label: String,points: int):events.append({"label":label,"points":points}))
		var minimum:=INF
		var active:=0
		var prior_clear:=0
		var derived_clear:=0
		var max_derived:=0.0
		var derived_rows: Array=[]
		var minimum_derived_skin:=INF
		var all_restored:=true
		var parity:=true
		var pose_equal:=true
		var trace: Array=[]
		Input.action_press(family)
		for tick: int in 65:
			if tick==6:Input.action_release(family)
			await Wall._frames(self,1)
			var is_active: bool=r._flip_remaining>0 if family=="flip" else r._grab_remaining>0
			var gap:=Wall._plane_gap(r)
			if is_active:
				active+=1
				minimum=minf(minimum,gap)
				prior_clear+=int(r._obstacle_air_clear(prior))
				var deriv:=_derive(r,prior)
				derived_clear+=int(deriv.valid)
				max_derived=maxf(max_derived,deriv.offset.length())
				derived_rows.append(deriv)
				minimum_derived_skin=minf(minimum_derived_skin,deriv.independent_plane_gap)
				all_restored=all_restored and deriv.restored
			parity=parity and Wall._physics(r)==Wall._physics(c)
			pose_equal=pose_equal and r._board_visual.transform==c._board_visual.transform and r._rider_visual.transform==c._rider_visual.transform
			trace.append({"tick":tick,"gap":gap,"offset":r._obstacle_visual_offset,"active":is_active,"air":r.airborne,"bail":r.bail_active})
		_check(reached and before>=0.0079 and prior.length()>0.10,"valid native pre-trick wall/Ollie "+family)
		_check(active>0 and not events.is_empty() and parity and pose_equal,"real scored active trick with identical physical/local-pose twin "+family)
		_check(derived_clear==active and active>=10 and minimum_derived_skin>=0.0079 and all_restored,"derived native contact plus existing skin clears every actual Grab pose and restores query")
		print("ACTIVE_WALL_PROBE ",{"family":family,"before":before,"prior":prior,"active":active,"minimum":minimum,"prior_finite_clear":prior_clear,"derived_clear":derived_clear,"max_derived":max_derived,"derived_rows":derived_rows,"physics_equal":parity,"local_pose_equal":pose_equal,"events":events,"landed":r.is_on_floor(),"bail":r.bail_active,"trace":trace})
		_release()
		f.viewport.queue_free()
		await process_frame
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
func _release() -> void:
	for action: String in InputMap.get_actions():Input.action_release(action)
func _check(ok: bool,label: String) -> void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;print("FAIL: ",label)

func _derive(r: CharacterBody3D,prior: Vector3) -> Dictionary:
	var q: PhysicsShapeQueryParameters3D=r._grind_board_query
	var box: BoxShape3D=r._grind_board_box
	var saved_shape:=q.shape
	var saved_size:=box.size
	var saved_margin:=q.margin
	var saved_pose:=q.transform
	var saved_motion:=q.motion
	var space:=r.get_world_3d().direct_space_state
	var direction:=prior.normalized()
	var ceiling:=direction*0.18
	var safe:=1.0
	var unsafe:=1.0
	var critical:=-1
	var rows: Array=[]
	var valid:=true
	for index: int in 3:
		if index==0:
			q.shape=r._visual_rig.board_contact_geometry().convex_shape
			q.transform=r._board_visual.global_transform
		else:
			var bounds: AABB=r._obstacle_shoe_bounds[index-1]
			box.size=bounds.size
			q.shape=box
			q.transform=r._visual_rig._legs[index-1].foot.global_transform*Transform3D(Basis.IDENTITY,bounds.get_center())
		var pose:=q.transform
		pose.origin+=ceiling
		q.transform=pose
		q.motion=Vector3.ZERO
		q.margin=0.00799
		var clear:=space.intersect_shape(q,1).is_empty()
		if not clear:valid=false;break
		# Explicit zero margin: obtain a native contact interval, then derive
		# the existing presentation skin from a live aligned native normal.
		q.margin=0.0
		q.motion=-ceiling
		var fractions:=space.cast_motion(q)
		if fractions[0]<safe:
			safe=fractions[0]
			unsafe=fractions[1]
			critical=index
		rows.append({"shape":index,"safe":fractions[0],"unsafe":fractions[1]})
	var normal:=Vector3.ZERO
	var point:=Vector3.ZERO
	var collider:=0
	if valid and critical>=0:
		if critical==0:
			q.shape=r._visual_rig.board_contact_geometry().convex_shape
			q.transform=r._board_visual.global_transform
		else:
			var bounds: AABB=r._obstacle_shoe_bounds[critical-1]
			box.size=bounds.size
			q.shape=box
			q.transform=r._visual_rig._legs[critical-1].foot.global_transform*Transform3D(Basis.IDENTITY,bounds.get_center())
		var pose:=q.transform
		pose.origin+=ceiling*(1.0-unsafe)
		q.transform=pose
		q.motion=Vector3.ZERO
		q.margin=0.0
		var rest:=space.get_rest_info(q)
		normal=rest.get("normal",Vector3.ZERO)
		point=rest.get("point",Vector3.ZERO)
		collider=int(rest.get("collider_id",0))
		valid=not rest.is_empty() and absf(normal.y)<=0.001 and normal.dot(direction)>=0.999
	else:valid=false
	q.shape=saved_shape
	box.size=saved_size
	q.margin=saved_margin
	q.transform=saved_pose
	q.motion=saved_motion
	var offset:=ceiling*(1.0-safe)
	if valid:offset+=direction*(0.008/normal.dot(direction))
	valid=valid and offset.length()<=0.18 and r._obstacle_air_clear(offset)
	return {"valid":valid,"offset":offset,"fractions":rows,"native_normal":normal,"native_point":point,"collider_id":collider,"interval_width_m":0.18*(unsafe-safe),"independent_plane_gap":Wall._plane_gap(r)-offset.z,"restored":q.shape==saved_shape and q.margin==saved_margin and q.transform==saved_pose and q.motion==saved_motion and box.size==saved_size}

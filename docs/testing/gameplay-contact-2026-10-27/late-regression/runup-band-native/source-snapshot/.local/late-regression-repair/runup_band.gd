extends SceneTree
## Earn one unchanged real run-up in clear flat space; never reposition the
## actor after restart. Geometry queries evaluate virtual poses, not actors.
const Main=preload("res://game/main.gd")
const Style=preload("res://game/tricks/grind_style.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var game=Main.new();game.persistence_enabled=false;root.add_child(game)
	game.skater.spawn_position=Vector3(-22,.8,28);game.start_mode(false)
	await _frames(40)
	var floor_at:Vector3=game.skater.global_position
	Input.action_press("push");Input.action_press("grind");await _frames(50)
	Input.action_release("grind");Input.action_press("ollie");await _frames(24)
	var prepop:Vector3=game.skater.global_position
	var prepop_velocity:Vector3=game.skater.velocity
	Input.action_release("ollie");await _frames(1);Input.action_release("push")
	var launch:Vector3=game.skater.global_position
	var motion:Vector3=game.skater.velocity
	_check(game.skater.airborne and game.skater._weighted_ollie_air and motion.z< -10.0 and motion.z> -15.0 and absf(motion.x)<.001,
		"run-up band: unchanged50Push/24charge earns actual unblocked weighted launch")
	var rail:Node3D=game.world.find_child("Grind_Rail_Exchange",true,false)
	var bar:StaticBody3D=rail.get_node("RailProp")
	var bar_collision:CollisionShape3D
	for child:Node in bar.get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D:bar_collision=child
	if bar_collision==null:_check(false,"run-up band: actual box bar exists");quit(1);return
	var box:BoxShape3D=bar_collision.shape
	var bar_frame:Transform3D=bar_collision.global_transform
	var half:Vector3=box.size*.5
	var front:float=bar_frame.origin.z+half.z
	var back:float=bar_frame.origin.z-half.z
	var crown:float=bar_frame.origin.y+half.y
	var original:CapsuleShape3D=game.skater.get_node("BodyCollision").shape
	var capsule:=CapsuleShape3D.new()
	capsule.radius=original.radius+game.skater.safe_margin
	capsule.height=original.height+2.0*game.skater.safe_margin
	var collider_frame:Transform3D=game.skater.get_node("BodyCollision").transform
	var speed:float=-motion.z
	var gravity:float=game.skater.WEIGHTED_OLLIE_GRAVITY
	# The driver observes the first negative native velocity, presses Grind,
	# then production admission first runs on the following update.
	var first_negative:int=floori(motion.y/(gravity/60.0))+1
	var catch_updates:int=first_negative+1
	var relative_y:float=launch.y-floor_at.y
	var lower:float=-INF
	for i in 1001:
		var updates:float=float(catch_updates)*float(i)/1000.0
		var y:float=floor_at.y+_flight_y(relative_y,motion.y,gravity,updates)
		var lower_centre:float=y+collider_frame.origin.y-(capsule.height*.5-capsule.radius)
		var dy:float=maxf(0.0,lower_centre-crown)
		if dy>=capsule.radius:continue
		var toe:float=sqrt(maxf(0.0,capsule.radius*capsule.radius-dy*dy))
		lower=maxf(lower,front+toe+speed*updates/60.0)
	var upper:float=front-Style.TRUCK_HALF_SPAN-Style.CONTACT_TOLERANCE+speed*catch_updates/60.0
	var runup:float=floor_at.z-launch.z
	var spawn_min:float=lower+runup
	var spawn_max:float=upper+runup
	var selected:float=roundf(((spawn_min+spawn_max)*.5)*4.0)/4.0
	_check(is_finite(selected) and selected>spawn_min and selected<spawn_max,
		"run-up band: quarter-metre midpoint stays inside native capsule/finite truck support interval")
	var virtual_launch:=Vector3(rail.global_position.x,launch.y,selected-runup)
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule
	query.exclude=[game.skater.get_rid()];query.collision_mask=1|8;query.margin=0.0
	var space:PhysicsDirectSpaceState3D=game.world.get_world_3d().direct_space_state
	var rows:Array[Dictionary]=[]
	var all_clear:=true
	# Include every exact native acceleration corner. Splitting the first
	# half-tick once gives41 straight segments for the measured20-update span;
	# no chord ever skips an internal physics velocity change.
	var boundaries:Array[float]=[0.0,.25]
	for i in range(1,catch_updates*2+1):boundaries.append(float(i)*.5)
	_check(boundaries.size()==42,"run-up band: actual launch yields exactly41 native-linear flight intervals")
	for i in range(boundaries.size()-1):
		var f0:float=boundaries[i]
		var f1:float=boundaries[i+1]
		var from:Vector3=virtual_launch+Vector3(0,_flight_y(relative_y,motion.y,gravity,f0)-relative_y,-speed*f0/60.0)
		var to:Vector3=virtual_launch+Vector3(0,_flight_y(relative_y,motion.y,gravity,f1)-relative_y,-speed*f1/60.0)
		query.transform=Transform3D(Basis.IDENTITY,from)*collider_frame;query.motion=to-from
		var fractions:PackedFloat32Array=space.cast_motion(query)
		query.motion=Vector3.ZERO
		var start_hits:Array[Dictionary]=space.intersect_shape(query,1)
		query.transform=Transform3D(Basis.IDENTITY,to)*collider_frame
		var end_hits:Array[Dictionary]=space.intersect_shape(query,1)
		var clear:bool=fractions.size()==2 and fractions[0]==1.0 and fractions[1]==1.0 and start_hits.is_empty() and end_hits.is_empty()
		all_clear=all_clear and clear
		rows.append({"i":i,"from":_vec(from),"to":_vec(to),"fractions":Array(fractions),"start_hits":str(start_hits),"end_hits":str(end_hits),"clear":clear})
	_check(all_clear,"run-up band: all41 native continuous capsule sweeps/endpoints clear every world solid before descending catch")
	var report:Dictionary={"valid":failed==0,"actor_warped_after_restart":false,"safe_fixture":_vec(floor_at),"prepop":_vec(prepop),"prepop_velocity":_vec(prepop_velocity),"actual_launch":_vec(launch),"actual_motion":_vec(motion),"gravity":gravity,"radius":original.radius,"height":original.height,"safety_shell":game.skater.safe_margin,"bar_front":front,"bar_back":back,"bar_crown":crown,"first_negative_update":first_negative,"first_catch_update":catch_updates,"measured_runup":runup,"launch_z_min":lower,"launch_z_max":upper,"spawn_z_min":spawn_min,"spawn_z_max":spawn_max,"selected_spawn_z":selected,"virtual_sweeps":rows,"actual_rail_catch_claimed":false}
	var args:=OS.get_cmdline_user_args()
	if args.size()==1:
		var path:String=ProjectSettings.globalize_path(args[0])
		if path.begins_with(ProjectSettings.globalize_path("res://.local/")):
			var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"  ")+"\n");file.close()
	print("RUNUP_BAND ",JSON.stringify(report))
	for action in InputMap.get_actions():Input.action_release(action)
	game.queue_free();await process_frame
	print("RESULT: ",passed," passed, ",failed," failed");quit(1 if failed else 0)
func _flight_y(first_y:float,vy:float,g:float,updates:float)->float:
	var whole:int=floori(updates)
	var fraction:float=updates-whole
	var decrement:float=float(whole*(whole+1))*.5+fraction*(whole+1)
	return first_y+vy*updates/60.0-g*decrement/3600.0
func _vec(v:Vector3)->Array[float]:return [v.x,v.y,v.z]
func _frames(count:int)->void:
	for i in count:await physics_frame;await process_frame
func _check(ok:bool,label:String)->void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)

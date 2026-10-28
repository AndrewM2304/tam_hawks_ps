extends RefCounted
## Fixed owner-witness coordinates and actual native input, independent of the
## placement helper's transform implementation. No mid-run actor correction.

const Routes = preload("res://tests/world_routes_tests.gd")
const Density = preload("res://.local/contact-camera-diagnostic/density_adapter.gd")
const Faces = preload("res://tests/pt24_boundary_tests.gd")


static func run(tree: SceneTree,game: Node,check: Callable) -> void:
	await tree.physics_frame
	await tree.process_frame
	var world: Node3D=game.world
	check.call(world.get_meta("pt24_connected_runs_built",false),"PT24 runs: placement precedes ordinary world snapshots")
	var tracks: Dictionary={}
	for line in world.get_grind_lines(): tracks[line.id]=line
	var exchange=tracks.get("Grind_Ledge_exchange_south_return")
	var civic=tracks.get("Grind_Ledge_civic_island_return")
	var clyde=tracks.get("Grind_Ledge_clyde_south_return")
	check.call(exchange!=null and exchange.points[0].distance_to(Vector3(12,0.60,32))<0.002
		and exchange.points[-1].distance_to(Vector3(12,0.60,38))<0.002,
		"PT24 runs: Exchange seat physically follows the north-south east quay close")
	check.call(civic!=null and civic.points[0].distance_to(Vector3(62,4.58,-84.7))<0.002
		and civic.points[-1].distance_to(Vector3(70,4.58,-84.7))<0.002,
		"PT24-19: existing civic seat becomes the corridor's east-west technical line")
	check.call(clyde!=null and clyde.points[0].distance_to(Vector3(-32.2,2.60,131))<0.002
		and clyde.points[-1].distance_to(Vector3(-32.2,2.60,138))<0.002,
		"PT24 runs: safe bridge return ledge follows the landing's north-south heading")
	var moved_contacts := true
	for expected: Vector3 in [Vector3(12,0.60,35),Vector3(66,4.58,-84.7),Vector3(-32.2,2.60,134.5)]:
		var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			expected+Vector3.UP*0.1,expected-Vector3.UP*0.1,1|2))
		moved_contacts=moved_contacts and not hit.is_empty() and Vector3(hit.position).distance_to(expected)<0.002
	check.call(moved_contacts,"PT24 runs: fixed moved-seat contacts have real native bearings under their transformed guides")
	var protected: Variant=tracks.get("Grind_Rail_Exchange")
	check.call(protected!=null and protected.points[0].distance_to(Vector3(12,0.92,12.75))<0.002
		and protected.points[-1].distance_to(Vector3(12,0.92,5.25))<0.002,
		"PT24 runs: original Exchange teaching rail keeps both native guide endpoints")
	var side: StaticBody3D=world.get_node("RecordingAlcoveSide")
	var back: StaticBody3D=world.get_node("RecordingAlcoveBack")
	check.call(_matching_box(side,Vector3(113,1.8,-32.875),Vector3(0.5,0.6,17.75))
		and _matching_box(back,Vector3(113,2.17,-32.875),Vector3(0.14,0.14,17.75)) and back.collision_layer==(1|2),
		"PT24-20: existing wall resources become a low loading kerb and real steel bearing with tyre clearance")
	var yard=tracks.get("Grind_Ledge_RecordingCourt")
	var real_contact: bool=yard!=null and yard.contact_verified
	if yard!=null:
		for ratio: float in [0.10,0.35,0.65,0.90]:
			var contact: Vector3=yard.contact_at(yard.length*ratio)
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters3D.create(contact+Vector3.UP*0.1,contact-Vector3.UP*0.1,1|2))
			real_contact=real_contact and not hit.is_empty() and hit.collider==back \
				and absf(hit.position.y-contact.y)<0.002
	check.call(real_contact,"PT24-20: all four new guide contacts sit on the reused steel bearing's real native top")
	var run_ids: Array[String]=["exchange_east_quay_handoff","civic_backstreet_ledge_return",
		"station_transition_handoff","clyde_west_landing_return","recording_court_return"]
	for route: Dictionary in world.get_route_definitions():
		if String(route.id)=="station_low_manual":
			var bank_points: PackedVector3Array=route.points
			check.call(bank_points[0].distance_to(Vector3(-89.2,2,40))<0.002
				and bank_points[-1].distance_to(Vector3(-70.8,2,40))<0.002,
				"PT24 runs: original station bank route is translated once alongside its physical terrain and feature record")
		if not run_ids.has(String(route.id)): continue
		run_ids.erase(String(route.id))
		var points: PackedVector3Array=route.points
		var supported := true
		var clear := true
		for index: int in points.size()-1:
			clear=clear and Routes._clear_sweep(world,points[index],points[index+1]) \
				and Routes._clear_sweep(world,points[index+1],points[index])
			var direction: Vector3=points[index+1]-points[index]
			var side_offset:=Vector3(direction.z,0,-direction.x).normalized()*0.65
			for step: int in 11:
				for lateral: float in [-1.0,0.0,1.0]:
					var point:=points[index].lerp(points[index+1],float(step)/10)+side_offset*lateral
					var hit:=world.get_world_3d().direct_space_state.intersect_ray(
						PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.12,point-Vector3.UP*0.12,1))
					supported=supported and not hit.is_empty() and absf(hit.position.y-point.y)<0.025
		check.call(supported and clear,"PT24 runs: full-width native support and clear return "+String(route.id))
	check.call(run_ids.is_empty(),"PT24 runs: all five actual placement continuations are published")
	for fixed: Array in [[Vector3(-82,2,34),Vector3(-82,2,-34)],
		[Vector3(57,4,-80),Vector3(82,4,-80)],
		[Vector3(-25,2.329411765,118),Vector3(-25,2,122)],
		[Vector3(-25,2,122),Vector3(-25,2,125)],
		[Vector3(-22,0,28),Vector3(22,0,28)]]:
		check.call(Routes._clear_sweep(world,fixed[0],fixed[1]) and Routes._clear_sweep(world,fixed[1],fixed[0]),
			"PT24 runs: fixed protected two-way passage stays open "+str(fixed))
	var marker_supported := false
	for marker: Dictionary in world.get_goal_markers():
		if marker.id=="secret_recording":
			marker_supported=Routes._ground_below(world,marker.position) and Routes._clear_standing(world,marker.position)
	check.call(marker_supported,"PT24-20: unchanged secret recording has native support and a clear standing capsule")
	await _gate_route(tree,game,check)
	await _civic_port(tree,game,check)
	await run_player(tree,game,check)


static func _gate_route(tree: SceneTree,game: Node,check: Callable) -> void:
	var world: Node3D=game.world
	var native_and_visible := true
	for z: float in [-14,-9,-4,1,6,9]:
		for y: float in [2.1,3.2,4.8]:
			var start:=Vector3(-50.5,y,z)
			var finish:=Vector3(-49.6,y,z)
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,finish,1))
			native_and_visible=native_and_visible and not hit.is_empty() \
				and Faces._visible_segment(world.get_node("CentralStationFloor"),start,finish)
	check.call(native_and_visible,"PT24-27: eighteen fixed service-wall sites have real collision and matching displayed masonry")
	var gate: Node3D=game.feature_hub.gate
	gate.reset_run()
	await _frames(tree,2)
	var north:=Vector3(-48.5,2.04,-18)
	var south:=Vector3(-48.5,2.04,12)
	var closed_blocked:=not Routes._clear_sweep(world,north,south)
	var detour:=PackedVector3Array([north,Vector3(-52,2.04,-18),Vector3(-52,2.04,12),south])
	var detour_clear := true
	var detour_distance := 0.0
	for index: int in detour.size()-1:
		detour_clear=detour_clear and Routes._clear_sweep(world,detour[index],detour[index+1]) \
			and Routes._clear_sweep(world,detour[index+1],detour[index])
		detour_distance+=detour[index].distance_to(detour[index+1])
	gate.request_toggle()
	gate.tick(1.3)
	await _frames(tree,2)
	var open_clear:=Routes._clear_sweep(world,north,south) and Routes._clear_sweep(world,south,north)
	check.call(closed_blocked and open_clear and detour_clear and detour_distance>=north.distance_to(south)+6.9,
		"PT24-27: opened native alley saves seven metres against a supported closed-gate detour while both street mouths stay clear")
	gate.reset_run()
	await _frames(tree,2)


static func _civic_port(tree: SceneTree,game: Node,check: Callable) -> void:
	var world: Node3D=game.world
	var quarter: Node3D=world.get_node_or_null("CivicPortReturn")
	var preview: bool=world.get_meta("pt24_design_preview",false)
	check.call(is_instance_valid(quarter)==preview,"PT24-18: civic return geometry matches the fixture's explicit construction setting")
	if not preview or not is_instance_valid(quarter): return
	check.call(quarter.position.is_equal_approx(Vector3(-38.5,6,-116)) and quarter.radius==2.4
		and quarter.width==4.5 and quarter.deck_length==2.0 and not quarter.build_access
		and quarter.global_basis.z.dot(Vector3.BACK)<-0.999,
		"PT24-18: return transition faces the exact southbound witness with a4.5m mouth and two1.25m escape shoulders")
	var support := true
	for x: float in [-2,0,2]:
		for degrees: float in [5,15,30,45,60,75]:
			var sample: Dictionary=quarter.sample(deg_to_rad(degrees),x)
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
				sample.point+sample.normal*0.08,sample.point-sample.normal*0.08,1))
			support=support and not hit.is_empty() and Vector3(hit.position).distance_to(sample.point)<0.002
	check.call(support,"PT24-18: eighteen independent curved return samples match the real finite native face")
	var foundation: Node3D=world.get_node("CivicPortReturnFoundation")
	var closed_sides := true
	for z: float in [-115.5,-114,-112,-110.2]:
		for y: float in [-2,2,5.8]:
			for side: float in [-1,1]:
				var start:=Vector3(-38.5+side*3.8,y,z)
				var finish:=Vector3(-38.5+side*3.2,y,z)
				var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,finish,1))
				closed_sides=closed_sides and not hit.is_empty() and Faces._visible_segment(foundation,start,finish)
	check.call(closed_sides and Routes._clear_sweep(world,Vector3(-33,6,-122),Vector3(-44,6,-122)),
		"PT24-18: grounded visible/native return sides preserve the original west-going park port")
	var miss_floor := true
	for x: float in [-41.4,-40,-38.5,-37,-35.6]:
		for z: float in [-111.3,-110.8,-110.2,-109.5]:
			var point:=Vector3(x,6,z)
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
				point+Vector3.UP*0.1,point-Vector3.UP*0.1,1))
			miss_floor=miss_floor and not hit.is_empty() and absf(Vector3(hit.position).y-6.0)<0.002 \
				and absf(world.get_support_height(point,0.1)-6.0)<0.002 \
				and Faces._visible_segment(foundation,point+Vector3.UP*0.1,point-Vector3.UP*0.1)
	check.call(miss_floor,"PT24-18: twenty independent rear-miss sites have real displayed/nativeY6 floor through to the frontage")
	for x: float in [-35.6,-41.4]:
		var rear:=Vector3(x,6.04,-110.2)
		var port:=Vector3(x,6.04,-122)
		var shoulder_support := true
		for step: int in 25:
			var point:=rear.lerp(port,float(step)/24)
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
				point+Vector3.UP*0.08,point-Vector3.UP*0.08,1))
			shoulder_support=shoulder_support and not hit.is_empty() and absf(Vector3(hit.position).y-6.0)<0.002
		check.call(shoulder_support and Routes._clear_sweep(world,rear,port) and Routes._clear_sweep(world,port,rear),
			"PT24-18: fixed full-length shoulder is supported and capsule-clear in both directionsX"+str(x))
	var frontage_closed := true
	for x: float in [-36.2,-35.6,-34.9]:
		for y: float in [6.15,7.2,8.25]:
			for direction: float in [-1,1]:
				var start:=Vector3(x,y,-109+direction*0.4)
				var finish:=Vector3(x,y,-109-direction*0.4)
				var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,finish,1))
				frontage_closed=frontage_closed and not hit.is_empty() and hit.collider==foundation \
					and Faces._visible_segment(foundation,start,finish)
	check.call(frontage_closed,"PT24-18: eighteen two-sided displayed/native frontage-return witnesses close the east gutter before the retained floor ends")
	await _civic_continued_miss_input(tree,game,check)
	await _civic_miss_recovery_input(tree,game,check)
	await _civic_return_input(tree,game,check)


static func _civic_continued_miss_input(tree: SceneTree,game: Node,check: Callable) -> void:
	var previous_spawn: Vector3=game.skater.spawn_position
	var previous_mode: bool=game.free_skate_mode
	_release()
	game.skater.spawn_position=Vector3(-35.6,6.04,-110.2)
	game.start_mode(true)
	game.skater.rotation.y=PI
	await _frames(tree,6)
	var bails := [0]
	var ollies := [0]
	var on_bail:=func()->void: bails[0]+=1
	var on_trick:=func(label:String,_points:int)->void:
		if label.contains("Ollie"): ollies[0]+=1
	game.skater.bailed.connect(on_bail)
	game.skater.trick_performed.connect(on_trick)
	var supported := true
	var solid_contact := false
	var progressed := false
	var furthest_z := -110.2
	var still_frames := 0
	var previous_z: float=game.skater.global_position.z
	Input.action_press("push",0.25)
	for frame: int in 120:
		await _frames(tree,1)
		var point: Vector3=game.skater.global_position
		supported=supported and absf(point.y-6.0)<0.13 and not game.skater.airborne
		furthest_z=maxf(furthest_z,point.z)
		progressed=progressed or point.z> -109.9
		still_frames=still_frames+1 if progressed and absf(point.z-previous_z)<0.002 else 0
		previous_z=point.z
		for index: int in game.skater.get_slide_collision_count():
			var contact: KinematicCollision3D=game.skater.get_slide_collision(index)
			solid_contact=solid_contact or (contact.get_collider()==game.world.get_node("CivicPortReturnFoundation") \
				and contact.get_normal().z< -0.8)
		if bails[0]>0: break
	_release()
	check.call(progressed and supported and solid_contact and furthest_z< -109.2
		and still_frames>=20 and bails[0]==0 and ollies[0]==0,
		"PT24-18: continued southward no-jump Push meets the real frontage return and stops safely on supported ground")
	print("PT24_CIVIC_CONTINUED_MISS progressed=%s supported=%s contact=%s furthestZ=%s still=%d bails=%d ollies=%d at=%s"%[
		progressed,supported,solid_contact,furthest_z,still_frames,bails[0],ollies[0],game.skater.global_position])
	game.skater.bailed.disconnect(on_bail)
	game.skater.trick_performed.disconnect(on_trick)
	game.skater.spawn_position=previous_spawn
	game.start_mode(previous_mode)
	await _frames(tree,3)


static func _civic_miss_recovery_input(tree: SceneTree,game: Node,check: Callable) -> void:
	var previous_spawn: Vector3=game.skater.spawn_position
	var previous_mode: bool=game.free_skate_mode
	for x: float in [-35.6,-41.4]:
		_release()
		game.skater.spawn_position=Vector3(x,6.04,-110.2)
		game.start_mode(true)
		game.skater.rotation.y=0.0
		await _frames(tree,6)
		var bails := [0]
		var ollies := [0]
		var on_bail:=func()->void: bails[0]+=1
		var on_trick:=func(label:String,_points:int)->void:
			if label.contains("Ollie"): ollies[0]+=1
		game.skater.bailed.connect(on_bail)
		game.skater.trick_performed.connect(on_trick)
		var supported := true
		var reached := false
		for frame: int in 300:
			if absf(game.skater.speed)>3.0:
				Input.action_release("push")
				Input.action_press("brake")
			else:
				Input.action_release("brake")
				Input.action_press("push")
			await _frames(tree,1)
			var point: Vector3=game.skater.global_position
			supported=supported and absf(point.y-6.0)<0.13 and not game.skater.airborne
			reached=point.z<=-121.8
			if reached or bails[0]>0: break
		_release()
		check.call(reached and supported and bails[0]==0 and ollies[0]==0,
			"PT24-18: ordinary no-jump Push/Brake leaves the rear miss pocket along shoulderX"+str(x))
		print("PT24_CIVIC_MISS_RECOVERY x=%s reached=%s supported=%s bails=%d ollies=%d at=%s"%[
			x,reached,supported,bails[0],ollies[0],game.skater.global_position])
		game.skater.bailed.disconnect(on_bail)
		game.skater.trick_performed.disconnect(on_trick)
	game.skater.spawn_position=previous_spawn
	game.start_mode(previous_mode)
	await _frames(tree,3)


static func _civic_return_input(tree: SceneTree,game: Node,check: Callable) -> void:
	var previous_spawn: Vector3=game.skater.spawn_position
	var previous_mode: bool=game.free_skate_mode
	_release()
	game.skater.spawn_position=Vector3(-38.5,6.08,-124.8)
	game.start_mode(true)
	game.skater.rotation.y=PI
	await _frames(tree,12)
	var bails := [0]
	var on_bail:=func()->void: bails[0]+=1
	game.skater.bailed.connect(on_bail)
	var climbed := false
	var airtime := false
	var returned := false
	var camera_clear := true
	Input.action_press("push")
	for frame: int in 420:
		await _frames(tree,1)
		var at: Vector3=game.skater.global_position
		climbed=climbed or at.y>7.5
		if climbed and game.skater.airborne:
			airtime=true
			Input.action_release("push")
		if frame%8==0:
			# process_frame is emitted before node _process callbacks. Observe
			# the camera after its update, alongside the matching current pose.
			await tree.create_timer(0.0,false,false).timeout
			var visible: bool = Density._camera_clear(game)
			if not visible:
				print("PT24_CIVIC_CAMERA mode=",game.skater._camera_follow._ramp_mode,
					" exit=",game.skater._camera_follow._ramp_exit_remaining,
					" ramp_air=",game.skater._ramp_air," fov=",game.skater._camera.fov,
					" basis=",game.skater._camera.global_basis,
					" head_vertices=",game.skater._camera_follow._head_landmarks.size())
			camera_clear=camera_clear and visible
		returned=airtime and not game.skater.airborne and at.y<6.15 and at.z< -116.3
		if returned or bails[0]>0: break
	_release()
	check.call(climbed and airtime and returned and bails[0]==0 and camera_clear,
		"PT24-18: ordinary native push earns civic ramp air and returns to the supported port without a forced wall impact")
	print("PT24_CIVIC_RETURN climbed=%s air=%s returned=%s bails=%d camera=%s at=%s"%[
		climbed,airtime,returned,bails[0],camera_clear,game.skater.global_position])
	game.skater.bailed.disconnect(on_bail)
	game.skater.spawn_position=previous_spawn
	game.start_mode(previous_mode)
	await _frames(tree,3)


static func run_player(tree: SceneTree,game: Node,check: Callable) -> void:
	var previous_spawn: Vector3=game.skater.spawn_position
	var previous_mode: bool=game.free_skate_mode
	_release()
	game.skater.spawn_position=Vector3(113,1.55,-18.6)
	game.start_mode(true)
	game.skater.rotation.y=0.0
	await _frames(tree,12)
	var events: Dictionary={"bails":0,"banks":0,"manuals":0}
	var captured: Array[String]=[]
	var on_bail:=func()->void: events.bails+=1
	var on_trick:=func(label:String,_points:int)->void:
		if label=="Manual": events.manuals+=1
	var on_capture:=func(id:String)->void: captured.append(id)
	game.skater.bailed.connect(on_bail)
	game.skater.trick_performed.connect(on_trick)
	game.skater.grind_captured.connect(on_capture)
	var phase := 0
	var manual_frames := 0
	var charge_frames := 0
	var held := 0
	var previous_score: int=game.score.total_score
	var camera_clear := true
	Input.action_press("push")
	for frame: int in 360:
		var at: Vector3=game.skater.global_position
		if phase==0 and at.z<=-20.7:
			Input.action_release("push")
			Input.action_press("manual")
			phase=1
		if phase==1 and game.skater.manual_active:
			manual_frames+=1
			Input.action_press("push",clampf(0.15+(game.skater.manual_balance-0.05)*2.0,0.0,0.4))
			if manual_frames>=10:
				Input.action_press("ollie")
				phase=2
		elif phase==2:
			charge_frames+=1
			if charge_frames>=12:
				Input.action_release("ollie")
				Input.action_release("manual")
				Input.action_release("push")
				Input.action_press("grind")
				phase=3
		elif phase==3 and game.skater.grinding:
			held+=1
			if held>=24:
				Input.action_release("grind")
				Input.action_press("brake")
				phase=4
		if frame%8==0: camera_clear=camera_clear and Density._camera_clear(game)
		await _frames(tree,1)
		if game.score.total_score>previous_score:
			events.banks+=1
			previous_score=game.score.total_score
		if events.bails>0 or (phase==4 and events.banks>0): break
	_release()
	await _frames(tree,45)
	var score: int=game.score.total_score
	if score>previous_score: events.banks+=1
	check.call(events.bails==0 and events.manuals==1 and manual_frames>=10
		and captured==["Grind_Ledge_RecordingCourt"] and held>=24
		and events.banks==1 and score>0 and camera_clear,
		"PT24-20: actual Manual to Ollie to loading-edge grind earns one combo bank with clear chase")
	print("PT24_CONNECTED_INPUT phase=%d manuals=%d frames=%d held=%d captures=%s banks=%d score=%d bails=%d camera=%s at=%s"%[
		phase,events.manuals,manual_frames,held,captured,events.banks,score,events.bails,camera_clear,game.skater.global_position])
	game.skater.bailed.disconnect(on_bail)
	game.skater.trick_performed.disconnect(on_trick)
	game.skater.grind_captured.disconnect(on_capture)
	game.skater.spawn_position=previous_spawn
	game.start_mode(previous_mode)
	await _frames(tree,3)


static func _matching_box(body: StaticBody3D,at: Vector3,size: Vector3) -> bool:
	var collision_ok := false
	var mesh_ok := false
	for child: Node in body.get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D: collision_ok=child.shape.size.is_equal_approx(size)
		elif child is MeshInstance3D and child.mesh is BoxMesh: mesh_ok=child.mesh.size.is_equal_approx(size)
	return body.position.is_equal_approx(at) and collision_ok and mesh_ok


static func _frames(tree: SceneTree,count: int) -> void:
	for index: int in count:
		await tree.physics_frame
		await tree.process_frame


static func _release() -> void:
	for action: String in InputMap.get_actions(): Input.action_release(action)

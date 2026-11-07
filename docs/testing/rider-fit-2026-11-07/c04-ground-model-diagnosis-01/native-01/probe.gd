extends SceneTree
const Main=preload("res://game/main.gd")
const Clyde=preload("res://tests/pt24_clyde_flagship_tests.gd")
const Density=preload("res://tests/full_level_density_tests.gd")
const Geometry=preload("res://tests/board_geometry_tests_support.gd")
const Footwear=preload("res://game/player/skater_footwear.gd")
var passes:=0
var failures:Array[String]=[]
var rows:Array[Dictionary]=[]
var sampled:=0
var bad_current:=0
var bad_rendered:=0
var source_cache:Dictionary={}
class LateObserver extends Node:
	var game:Node
	var probe
	var active:=false
	func _ready()->void:process_priority=1000
	func _process(_delta:float)->void:
		if not active:return
		for sampler:Node in game.get_children():
			if sampler.has_method("_contact_failure") and bool(sampler.get("active")) and int(sampler.get("warmup_frames"))<=0:
				probe.collect(game)
				return
func _initialize()->void:_run.call_deferred()
func check(ok:bool,label:String)->void:
	if ok:passes+=1
	else:failures.append(label)
	print("DIAG_PASS " if ok else "DIAG_ASSERTION_FAILURE ",label)
func vec(v:Vector3)->Array:return [v.x,v.y,v.z]
func mat(t:Transform3D)->Array:return [[t.basis.x.x,t.basis.y.x,t.basis.z.x,t.origin.x],[t.basis.x.y,t.basis.y.y,t.basis.z.y,t.origin.y],[t.basis.x.z,t.basis.y.z,t.basis.z.z,t.origin.z],[0,0,0,1]]
func ray(space:PhysicsDirectSpaceState3D,a:Vector3,b:Vector3,rider:CharacterBody3D)->Dictionary:
	var q:=PhysicsRayQueryParameters3D.create(a,b,1|8,[rider.get_rid()])
	return space.intersect_ray(q)
func hit_info(h:Dictionary)->Dictionary:
	if h.is_empty():return {}
	return {"at":vec(h.position),"normal":vec(h.normal),"rid":str(h.rid),"shape":h.shape,"collider":str(h.collider.get_meta("art_label",h.collider.name)),"path":str(h.collider.get_path())}
func native(mesh:MeshInstance3D)->Dictionary:
	var key:int=mesh.mesh.get_instance_id()
	if source_cache.has(key):return source_cache[key]
	var used:Dictionary={}
	for s:int in mesh.mesh.get_surface_count():
		var a:Array=mesh.mesh.surface_get_arrays(s)
		var p:PackedVector3Array=a[Mesh.ARRAY_VERTEX]
		var ids:PackedInt32Array=a[Mesh.ARRAY_INDEX]
		if ids.is_empty():
			for point:Vector3 in p:used[point]=true
		else:
			for i:int in ids:used[p[i]]=true
	var points:=PackedVector3Array()
	for p:Vector3 in used:points.append(p)
	var hull:ConvexPolygonShape3D=mesh.mesh.create_convex_shape(true,false)
	source_cache[key]={"indexed":points,"hull":hull.points}
	return source_cache[key]
func entries(rider:CharacterBody3D)->Array[Dictionary]:
	var rig:RefCounted=rider._visual_rig
	var list:Array[Dictionary]=[{"kind":"head_origin","node":rig._head,"local":Vector3.ZERO},{"kind":"board_origin","node":rider._board_visual,"local":Vector3.ZERO}]
	for m:MeshInstance3D in Geometry.visible_meshes(rig):
		for p:Vector3 in native(m).hull:list.append({"kind":"mesh_hull","node":m,"local":p})
	for leg:Dictionary in rig._legs:
		for p:Vector3 in [Footwear.SOLE_CONTACT,Footwear.TOE_CONTACT]:list.append({"kind":"foot_marker","node":leg.foot,"local":p})
	return list
func trace(rider:CharacterBody3D,list:Array[Dictionary],rendered:bool)->Dictionary:
	var camera:Camera3D=rider._camera
	var space:=rider.get_world_3d().direct_space_state
	var failed:Array[Dictionary]=[]
	var hits:=0
	var outside:=0
	for item:Dictionary in list:
		var node:Node3D=item.node
		var frame:Transform3D=node.get_global_transform_interpolated() if rendered else node.global_transform
		var point:Vector3=frame*Vector3(item.local)
		var in_view:bool=camera.is_position_in_frustum(point)
		var h:Dictionary=ray(space,camera.global_position,point,rider)
		if h.is_empty() and in_view:continue
		hits+=int(not h.is_empty());outside+=int(not in_view)
		if failed.size()>=16:continue
		var rec:Dictionary={"kind":item.kind,"node":str(node.get_path()),"local":vec(item.local),"world":vec(point),"in_frustum":in_view,"hit":hit_info(h)}
		if not h.is_empty():rec.ray_endpoint_signed_gap_m=(point-Vector3(h.position)).dot(h.normal)
		if item.kind=="mesh_hull":
			var source:PackedVector3Array=native(node as MeshInstance3D).indexed
			var best:=INF
			var local:=Vector3.ZERO
			for p:Vector3 in source:
				var d:=p.distance_squared_to(item.local)
				if d<best:best=d;local=p
			var actual:Vector3=frame*local
			var actual_hit:Dictionary=ray(space,camera.global_position,actual,rider)
			rec.nearest_indexed={"local":vec(local),"world":vec(actual),"hull_local_error_m":sqrt(best),"camera_ray":hit_info(actual_hit)}
			if not h.is_empty():
				var n:Vector3=h.normal
				var support:Dictionary=ray(space,actual+n*.04,actual-n*.04,rider)
				rec.nearest_indexed.normal_support=hit_info(support)
				if not support.is_empty():rec.nearest_indexed.signed_normal_gap_m=(actual-Vector3(support.position)).dot(support.normal)
		failed.append(rec)
	return {"hits":hits,"outside":outside,"failed":failed,"scope":"Actual indexed nearest-point/native-ray diagnostics; rendered means native Node3D GTI CPU frame, not GPU pixels."}
func collect(game:Node)->void:
	var rider:CharacterBody3D=game.skater
	sampled+=1
	var list:Array[Dictionary]=entries(rider)
	var now:Dictionary=trace(rider,list,false)
	var rendered:Dictionary=trace(rider,list,true)
	bad_current+=int(now.hits>0 or now.outside>0)
	bad_rendered+=int(rendered.hits>0 or rendered.outside>0)
	if (now.hits==0 and now.outside==0 and rendered.hits==0 and rendered.outside==0) or rows.size()>=12:return
	var camera:RefCounted=rider._camera_follow
	var space:=rider.get_world_3d().direct_space_state
	var board:Vector3=camera._follow_transform(rider).origin
	var anchor:Vector3=camera._last_anchor
	var excluded:Array[RID]=[rider.get_rid()]
	var own_usable:bool=camera._usable(space,board,anchor,rider._camera.global_position,excluded)
	var candidates:Array[Dictionary]=[]
	var speed:float=clampf(Vector2(camera._travel_velocity.x,camera._travel_velocity.z).length(),0,15)
	for angle:float in [0.0]+camera.ORBIT_ANGLES:
		for height:float in [camera.NORMAL_HEIGHT,camera.LOW_HEIGHT,camera.HIGH_HEIGHT]:
			var c:Dictionary=camera._candidate(space,anchor,board,camera._world_rear,4.9+speed*.02,angle,height,excluded)
			candidates.append({"angle":angle,"height":height,"position":vec(c.position),"usable":c.usable,"reach":c.reach,"score":c.score})
	var row:Dictionary={"physics":Engine.get_physics_frames(),"process":Engine.get_process_frames(),"camera_process":rider.last_presentation_process_frame,"observer_priority":1000,"camera_cache_active_after_update":camera._query_cache_active,"fraction":Engine.get_physics_interpolation_fraction(),"body":mat(rider.global_transform),"body_GTI":mat(rider.get_global_transform_interpolated()),"board":mat(rider._board_visual.global_transform),"board_GTI":mat(rider._board_visual.get_global_transform_interpolated()),"camera":mat(rider._camera.global_transform),"body_up":vec(camera._body_up),"anchor":vec(anchor),"board_proxy":vec(board),"camera_ramp_mode":camera._ramp_mode,"selected_angle":camera._selected_angle,"minimum_arm":camera._minimum_arm,"actual_camera_usable":own_usable,"current":now,"rendered_GTI":rendered,"candidates":candidates,"queries_are_read_only":true}
	rows.append(row)
	print("C04_LATE_FAILURE ",JSON.stringify(row,"",true,true))
func _run()->void:
	var game:=Main.new()
	if game.persistence_enabled:push_error("private C04 probe requires isolated Main");quit(2);return
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	var observer:=LateObserver.new()
	observer.game=game;observer.probe=self
	root.add_child(observer)
	# Exact local C04 module prefix, preserving its own reset/camera history.
	await Clyde._construction(self,game,check)
	await Clyde.run_player(self,game,check)
	observer.active=true
	await Clyde.run_bank_return(self,game,check)
	observer.active=false
	var result:Dictionary={"passes":passes,"failures":failures,"late_samples":sampled,"current_bad_frames":bad_current,"rendered_GTI_bad_frames":bad_rendered,"rows":rows,"scope":"Exact C04 construction+bridge prefix+bank return, unchanged input/assertions; extra priority1000 read-only native/current/GTI witness only. No GPU or performance acceptance."}
	var f:=FileAccess.open("res://.local/result.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"\t",true,true));f.close()
	game.queue_free();observer.queue_free();await process_frame
	print("C04_DIAG_RESULT ",passes," failures=",failures," late_bad=",bad_current," rendered=",bad_rendered)
	quit(0 if failures.is_empty() else 1)

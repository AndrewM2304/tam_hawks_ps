extends SceneTree
## Exercise the complete real Main with its ordinary default construction.
## No content opt-in is assigned; Music/account persistence remains disabled.
const Main = preload("res://game/main.gd")
const Green = preload("res://tests/pt24_central_green_tests.gd")
const Pond = preload("res://tests/park_pond_tests.gd")
const Layout = preload("res://tests/pt24_connected_runs_tests.gd")
const Routes = preload("res://tests/world_routes_tests.gd")
const GalleryEntrance = preload("res://tests/pt24_gallery_entrance_run_tests.gd")
const CivicRun = preload("res://tests/pt24_civic_flagship_tests.gd")
const FlagshipRuns = preload("res://tests/pt24_flagship_runs_tests.gd")
const ClydeRun = preload("res://tests/pt24_clyde_flagship_tests.gd")
const ParkRun = preload("res://tests/pt24_park_run_tests.gd")
const GateRoute = preload("res://tests/pt24_gate_route_tests.gd")
const ParkTransit = preload("res://tests/pt24_park_flagship_tests.gd")
const ParkCombo = preload("res://tests/pt24_park_full_combo_tests.gd")
const BankEdges = preload("res://tests/terrain_bank_edge_tests.gd")
const MarketRun = preload("res://tests/pt24_market_full_run_tests.gd")
const CivicParkRun = preload("res://tests/pt24_civic_park_run_tests.gd")
const FacilityConnection = preload("res://tests/pt24_facility_connection_tests.gd")
const FountainFinish = preload("res://tests/fountain_finish_tests.gd")
const FountainOrnament = preload("res://tests/fountain_ornament_tests.gd")


const Density=preload("res://tests/full_level_density_tests.gd")
const Geometry=preload("res://tests/board_geometry_tests_support.gd")
const Footwear=preload("res://game/player/skater_footwear.gd")
var passed:=0
var failed:=0
var _sensor:FrustumSensor
class FrustumSensor extends Node:
 var game:Node
 var enabled:=false
 func _ready()->void:process_priority=101
 func _process(_delta:float)->void:
  if not enabled or not is_instance_valid(game):return
  var r:CharacterBody3D=game.skater
  if not (r.airborne and r.global_position.z>127 and r.global_position.z<131):return
  var camera:Camera3D=r._camera
  var points:=PackedVector3Array([r._visual_rig._head.global_position,r._board_visual.global_position])
  for mesh:MeshInstance3D in Geometry.visible_meshes(r._visual_rig):
   var key:int=mesh.mesh.get_instance_id()
   if not Density._camera_hulls.has(key):return
   var hull:PackedVector3Array=Density._camera_hulls[key]
   for point:Vector3 in hull:points.append(mesh.to_global(point))
  for leg:Dictionary in r._visual_rig._legs:
   points.append(leg.foot.to_global(Footwear.SOLE_CONTACT));points.append(leg.foot.to_global(Footwear.TOE_CONTACT))
  var first:=Vector3.INF
  for point:Vector3 in points:
   if not camera.is_position_in_frustum(point):first=point;break
  if not first.is_finite():return
  enabled=false
  var c=r._camera_follow
  var body:Transform3D=c._follow_transform(r)
  var excluded:Array[RID]=[r.get_rid()]
  var usable:bool=c._usable(r.get_world_3d().direct_space_state,body.origin,c._last_anchor,camera.global_position,excluded)
  var all_framing:=PackedVector3Array()
  all_framing.append_array(c._foot_targets);all_framing.append_array(c._head_bounds);all_framing.append_array(c._head_targets)
  var first_source:Dictionary={}
  for mesh:MeshInstance3D in Geometry.visible_meshes(r._visual_rig):
   var hull:PackedVector3Array=Density._camera_hulls[mesh.mesh.get_instance_id()]
   for index:int in hull.size():
    if mesh.to_global(hull[index])!=first:continue
    var nearest_vertex:=Vector3.ZERO;var nearest_error:=INF
    for surface:int in mesh.mesh.get_surface_count():
     var vertices:PackedVector3Array=mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
     for vertex:Vector3 in vertices:
      var error:float=vertex.distance_squared_to(hull[index])
      if error<nearest_error:nearest_error=error;nearest_vertex=vertex
    first_source={"mesh":str(r.get_path_to(mesh)),"hull_index":index,"hull_local":hull[index],"actual_mesh_vertex_local":nearest_vertex,"actual_mesh_vertex":mesh.to_global(nearest_vertex),"hull_to_actual_m":mesh.to_global(nearest_vertex).distance_to(first),"displayed_marker":mesh.get_global_transform_interpolated()*hull[index],"mesh_frame":mesh.global_transform}
  var nearest:=INF
  for point:Vector3 in c._foot_targets:nearest=minf(nearest,point.distance_to(first))
  for point:Vector3 in c._head_bounds:nearest=minf(nearest,point.distance_to(first))
  print("CLYDE_FRUSTUM_NATIVE ",JSON.stringify({"physics":Engine.get_physics_frames(),"process":Engine.get_process_frames(),"fraction":Engine.get_physics_interpolation_fraction(),"last_camera":r.last_presentation_process_frame,"body":r.global_transform,"body_displayed":body,"visual":r._visual.global_transform,"board":r._board_visual.global_transform,"head":r._visual_rig._head.global_transform,"camera":camera.global_transform,"fov":camera.fov,"viewport":camera.get_viewport().get_visible_rect(),"first":first,"first_source":first_source,"nearest_target":nearest,"usable":usable,"anchor":c._last_anchor,"actual_anchor_radius":camera.global_position.distance_to(c._last_anchor),"camera_clear_volume":c._clear_volume(r.get_world_3d().direct_space_state,camera.global_position),"head_bounds":c._head_bounds,"head_targets":c._head_targets,"foot_targets":c._foot_targets,"body_up":c._body_up,"ramp_mode":c._ramp_mode,"ramp_exit":c._ramp_exit_remaining,"min_arm":c._minimum_arm,"return_arm":c._return_arm,"ground_y":c._ground_board_y,"motion_pitch":c._motion_pitch,"selected_angle":c._selected_angle,"ramp_lift":c._ramp_lift,"ramp_turn":c._ramp_turn,"world_rear":c._world_rear,"orbit_up":c._orbit_up,"ramp_air":r._ramp_air,"force_air":r._force_air_tick,"transition":r.transition_active,"feature":r._feature_transition.state,"camera_sensitivity":r._camera_sensitivity,"reduced_motion":r._reduced_motion,"strict_actual_fit_geometry":_fit_geometry(camera,c,points),"existing_current_and_displayed_fit_geometry":_fit_geometry(camera,c,all_framing)}))
  print("DIAGNOSTIC_STOP first original Clyde frustum failure; original assertions and predicate unchanged, no complete route acceptance claimed")
  get_tree().quit(0)
 func _fit_geometry(camera:Camera3D,c:RefCounted,points:PackedVector3Array)->Array[Dictionary]:
  var basis:=camera.global_basis
  var projection:=camera.get_camera_projection()
  var hx:=atan(1.0/absf(projection.x.x))*.97
  var hy:=atan(1.0/absf(projection.y.y))*.97
  var rows:Array[Dictionary]=[]
  for attempt:int in 3:
   var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
   for point:Vector3 in points:
    var local:Vector3=basis.inverse()*(point-camera.global_position)
    var angle:=Vector2(atan2(local.x,-local.z),atan2(local.y,-local.z))
    low=low.min(angle);high=high.max(angle)
   var yl:=high.x-hx;var yh:=low.x+hx;var pl:=high.y-hy;var ph:=low.y+hy
   rows.append({"basis":basis,"min":low,"max":high,"half":Vector2(hx,hy),"yaw_solution":yl<=yh,"pitch_solution":pl<=ph})
   var yaw:=clampf(0.0,yl,yh) if yl<=yh else (low.x+high.x)*.5
   var pitch:=clampf(0.0,pl,ph) if pl<=ph else (low.y+high.y)*.5
   var direction:Vector3=(basis*Vector3(tan(yaw),tan(pitch),-1)).normalized()
   basis=Basis.looking_at(direction,basis.y.slide(direction).normalized())
  return rows
func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
 if ok:passed+=1;print("PASS: ",label)
 else:failed+=1;push_error("FAIL: "+label)
func _run()->void:
	var tree:SceneTree=self
	var check:Callable=_check
	for action: String in InputMap.get_actions(): Input.action_release(action)
	var game := Main.new()
	game.persistence_enabled = false
	check.call(not game.has_meta("pt24_design_preview"),
		"PT24 default integration: fixture assigns no content opt-in")
	tree.root.add_child(game)
	_sensor=FrustumSensor.new();_sensor.game=game;game.add_child(_sensor)
	game.start_mode(true)
	for frame in 25:
		await tree.physics_frame
		await tree.process_frame
	var railway: Node3D = game.world.get_node_or_null("StationRailway")
	check.call(railway != null and railway.built and railway.report.budget_pass,
		"PT24 default integration: ordinary Main constructs the complete bounded railway")
	for span: Array in [[Vector3(-126,2,0),Vector3(-145,2,0)],
		[Vector3(-82,2,34),Vector3(-82,2,-34)],
		[Vector3(-42,6,-122),Vector3(-34,6,-122)]]:
		check.call(Routes._clear_sweep(game.world,span[0],span[1])
			and Routes._clear_sweep(game.world,span[1],span[0]),
			"PT24 default integration: actual railway and civic return preserve two-way route "+str(span))
	await BankEdges.run(tree,check)
	await BankEdges.run_world(tree,game,check)
	await Green.run(tree,game.world,check)
	await Pond.run_installed(tree,game,check)
	await Pond.run_player(tree,game,check)
	# Route acceptance uses the same enabled content as ordinary play. The
	# separate historical Main retains exact inventory/coverage controls only.
	await Layout.run(tree,game,check)
	await CivicRun.run(tree,game,check)
	await FlagshipRuns.run(tree,game,check)
	_sensor.enabled=true
	await ClydeRun.run(tree,game,check)
	_sensor.enabled=false
	game.queue_free()
	await process_frame
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)

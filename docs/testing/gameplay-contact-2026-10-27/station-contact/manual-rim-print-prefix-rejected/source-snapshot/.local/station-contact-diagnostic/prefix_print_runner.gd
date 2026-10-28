extends SceneTree
const Main=preload("res://.local/station-contact-diagnostic/main_print_adapter.gd")
const Driver=preload("res://.local/station-contact-diagnostic/driver_adapter.gd")
const DensityObserver=preload("res://.local/station-contact-diagnostic/density_adapter.gd")
const Market=preload("res://tests/pt24_market_full_run_tests.gd")
const Park=preload("res://tests/pt24_park_full_combo_tests.gd")
const Clyde=preload("res://tests/pt24_clyde_flagship_tests.gd")
const WorldRoutes=preload("res://tests/world_routes_tests.gd")
const Compact=preload("res://tests/test_compact_clyde.gd")
const Cable=preload("res://tests/clyde_cable_line_tests.gd")
const Exchange=preload("res://tests/exchange_place_tests.gd")
const Topography=preload("res://tests/topography_tests.gd")
var passed:=0
var failed:=0
var previous:=""
var _bail_seen:=false
func _initialize()->void:_run.call_deferred()
func _run()->void:
 var game=Main.new();game.persistence_enabled=false;root.add_child(game);game.start_mode(true)
 await Driver._frames(self,3)
 var args=OS.get_cmdline_user_args()
 var selected=args[0] if args.size()>0 else "station"
 match selected:
  "station_prefix":
   await Driver._gallery(self,game,_check,_observe)
   DensityObserver.enabled=true
   await Driver._station(self,game,_check,_observe)
  "pending":
   await Driver._gallery(self,game,_check,_observe)
   await Driver._station(self,game,_check,_observe)
   await Market.run_player(self,game,_check,_observe)
   await Cable.run_player(self,game,_check,_observe)
   await Topography._fountain(self,game,_check)
   await WorldRoutes.run(self,game.world,_check)
   await Clyde._construction(self,game,_check)
   print("ORDINARY_ROUTE_CONTEXT design=",game.world.get_meta("pt24_design_preview",false)," station=",game.world.find_child("StationRailway",true,false)!=null)
   game.queue_free();await process_frame;await physics_frame
   game=Main.new();game.persistence_enabled=false;game.set_meta("pt24_design_preview",false);root.add_child(game);game.start_mode(true)
   await Driver._frames(self,3)
   print("LEGACY_COMPACT_CONTEXT design=",game.world.get_meta("pt24_design_preview",true)," station=",game.world.find_child("StationRailway",true,false)!=null)
   _removed_probe(game)
   await Compact.run(self,game.world,_check)
  "routes":
   await Driver._gallery(self,game,_check,_observe)
   await Driver._station(self,game,_check,_observe)
   await Market.run_player(self,game,_check,_observe)
  "gallery":await Driver._gallery(self,game,_check,_observe)
  "station":await Driver._station(self,game,_check,_observe)
  "market":await Market.run_player(self,game,_check,_observe)
  "park":await Park.run_player(self,game,_check,_observe)
  "clyde":await Clyde._construction(self,game,_check)
  "world":
   await WorldRoutes.run(self,game.world,_check)
   await Clyde._construction(self,game,_check)
   print("ORDINARY_ROUTE_CONTEXT design=",game.world.get_meta("pt24_design_preview",false)," station=",game.world.find_child("StationRailway",true,false)!=null)
   game.queue_free();await process_frame;await physics_frame
   game=Main.new();game.persistence_enabled=false;game.set_meta("pt24_design_preview",false);root.add_child(game);game.start_mode(true)
   await Driver._frames(self,3)
   print("LEGACY_COMPACT_CONTEXT design=",game.world.get_meta("pt24_design_preview",true)," station=",game.world.find_child("StationRailway",true,false)!=null)
   _removed_probe(game)
   await Compact.run(self,game.world,_check)
  "cable":await Cable.run_player(self,game,_check,_observe)
  "fountain":await Topography._fountain(self,game,_check)
  "exchange":
   await Exchange._reset(self,game,Exchange.combo_fixture(game).position)
   var e=await Exchange.drive_ledge_combo(self,game)
   print("EXCHANGE_TRACE ",e," reason=",game.skater.bail_reason)
   var earned=Exchange._earned_combo(e)
   _check(e.captured and e.south_exit and e.manual_entered and e.connected and e.bails==0 and e.bank==earned.value,"real bent ledge combo and independently calculated bank")
  _:_check(false,"unknown diagnostic selection")
 print("RESULT: ",passed," passed, ",failed," failed")
 game.queue_free();await process_frame
 quit(1 if failed else 0)
func _check(ok:bool,label:String)->void:
 if ok:passed+=1;print("PASS: ",label)
 else:failed+=1;push_error("FAIL: "+label)
func _observe(phase:String,game:Node,tick:int)->void:
 var r=game.skater
 if not r.bailing:_bail_seen=false
 var first_bail:bool=r.bailing and not _bail_seen
 if phase!=previous or tick%15==0 or first_bail:
  print("FLAGSHIP_TRACE phase=",phase," tick=",tick," at=",r.global_position," vel=",r.velocity," speed=",r.speed," air=",r.airborne," floor=",r.is_on_floor()," manual=",r.manual_active," manualElapsed=",r._manual_elapsed," balance=",r.manual_balance," grind=",r.grinding," grindId=",r._grind.line.id if r.grinding else ""," held=",r._ollie_held," buffer=",r._jump_buffer_remaining," reason=",r.bail_reason," pending=",game.score.get_combo_value()," bank=",game.score.total_score)
  if first_bail and r.bail_reason=="grind_board_obstruction":
   var c=r._grind_clearance
   var low:=Vector3(INF,INF,INF)
   var high:=Vector3(-INF,-INF,-INF)
   if c._query.shape is ConvexPolygonShape3D:
    for v:Vector3 in c._query.shape.points:low=low.min(v);high=high.max(v)
   print("FLAGSHIP_GRIND_FAILURE reason=",r.bail_reason," model_reason=",c.last_rejection," obstruction=",c.last_obstruction," query_transform=",c._query.transform," query_margin=",c._query.margin," query_shape_bounds=",[low,high]," contact_valid=",r._grind_contact.valid," contact_frame=",r._grind_contact.board_transform)
  previous=phase
  _bail_seen=r.bailing

func _removed_probe(game:Node)->void:
 var outdoors=game.world.get_node("OutdoorRoutes")
 var points:Array[Vector3]=[]
 for x:float in [-250.0,-200.0,-140.0,-90.0,-50.0,0.0,50.0,90.0,140.0,200.0,250.0]:
  for z:float in [170.0,195.0,215.0]:points.append(Vector3(x,0,z))
 points.append_array([Vector3(-135,0,68),Vector3(135,0,68),Vector3(-100,0,124),Vector3(120,0,124)])
 for p:Vector3 in points:
  var at:Vector3=outdoors.to_global(p)
  var hit=game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*(20 if p.z>160 else 8),at-Vector3.UP*5,1))
  if not hit.is_empty():print("COMPACT_REMOVED_DIAGNOSTIC at=",at," hit=",hit," height=",outdoors.get_ground_height(at.x,at.z))

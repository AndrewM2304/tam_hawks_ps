extends SceneTree
const Main=preload("res://game/main.gd")
const Driver=preload("res://tests/pt24_flagship_runs_tests.gd")
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
func _initialize()->void:_run.call_deferred()
func _run()->void:
 var game=Main.new();game.persistence_enabled=false;root.add_child(game);game.start_mode(true)
 await Driver._frames(self,3)
 var args=OS.get_cmdline_user_args()
 var selected=args[0] if args.size()>0 else "station"
 match selected:
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
   await Compact.run(self,game.world,_check)
   await Clyde._construction(self,game,_check)
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
 if phase!=previous or tick%15==0 or r.bailing:
  print("FLAGSHIP_TRACE phase=",phase," tick=",tick," at=",r.global_position," vel=",r.velocity," speed=",r.speed," air=",r.airborne," floor=",r.is_on_floor()," manual=",r.manual_active," manualElapsed=",r._manual_elapsed," balance=",r.manual_balance," grind=",r.grinding," grindId=",r._grind.line.id if r.grinding else ""," held=",r._ollie_held," buffer=",r._jump_buffer_remaining," reason=",r.bail_reason," pending=",game.score.get_combo_value()," bank=",game.score.total_score)
  previous=phase

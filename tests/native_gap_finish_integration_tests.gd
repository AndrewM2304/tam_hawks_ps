extends RefCounted
## Real Main caller and native capture regression. Use an initialized City Tour
## Main with persistence/Music isolated. Counterfactual controls are explicit;
## this test is not a visual/contact/performance or physical-parity receipt.
const Driver=preload("res://tests/cable_gap_input_driver.gd")
const Controls=preload("res://tests/native_gap_finish_capture_controls.gd")
const Score=preload("res://game/scoring/score_session.gd")

class Awards extends Score:
 var entries:Array=[]
 var banks:Array=[]
 var run_label:=""
 func add_trick(label:String,points:int,identity:String="")->int:
  var result:int=super.add_trick(label,points,identity)
  entries.append({"run":run_label,"identity":identity,"points":points,"awarded":result,"physics":Engine.get_physics_frames()})
  return result
 func bank_combo()->int:
  var value:int=super.bank_combo()
  if value>0:banks.append({"run":run_label,"value":value,"physics":Engine.get_physics_frames()})
  return value

static func run_player(tree:SceneTree,game:Node,check:Callable)->void:
 var old_score:RefCounted=game.score
 var old_helper:RefCounted=game.native_gap_finish
 var old_spawn:Vector3=game.skater.spawn_position
 var old_free:bool=game.free_skate_mode
 var helper:=Controls.new()
 var ledger:=Awards.new()
 check.call(not game.persistence_enabled and not game.music._can_control and not game.music._persist,"native gap input: actual Main isolates personal profile and Music")
 check.call(helper.configure(game.world,game.skater),"native gap input: real constructor-owned destination bodies and configured guide identities register")
 if not helper.ready:return
 game.native_gap_finish=helper
 game.score=ledger
 var source_points:Dictionary={}
 for gap:Dictionary in game.world.get_gap_definitions():source_points["gap:"+str(gap.id)]=gap.points
 var witnessed:Dictionary={}
 var cases:Array=[
  {"side":"west","direction":1.0,"wait":12},
  {"side":"east","direction":1.0,"wait":12},
  {"side":"west","direction":1.0,"wait":0},
  {"side":"east","direction":1.0,"wait":0},
  {"side":"west","direction":-1.0,"wait":0},
  {"side":"east","direction":-1.0,"wait":0}]
 for entry:Dictionary in cases:
  var label:String=str(entry.side)+":"+str(entry.direction)+":"+str(entry.wait)
  ledger.run_label=label
  Driver.side=entry.side
  Driver.extra_cable_wait=entry.wait
  await Driver._drive_player(tree,game,check,entry.direction,Callable())
  var awards:Array=[]
  for event:Dictionary in ledger.entries:
   if event.run!=label or not str(event.identity).begins_with("gap:"):continue
   check.call(source_points.has(event.identity)and event.points==source_points[event.identity]and event.awarded==event.points,"native gap input: direct actual gap score call uses registered ID and source points "+str(event.identity))
   awards.append(event.identity)
   witnessed[event.identity]=true
  var expected:Array=[]
  if entry.direction>0:
   expected.append("gap:clyde_handrail_to_cable_"+entry.side)
   if entry.wait==12:expected.append("gap:clyde_cable_to_handrail_"+entry.side)
  check.call(awards==expected,"native gap input: exact ordered scored IDs for "+label)
  var banks:int=0
  for bank:Dictionary in ledger.banks:
   if bank.run==label:banks+=1
  check.call(banks==1,"native gap input: one terminal positive bank without combining separately reset cases "+label)
 for id:String in ["clyde_handrail_to_cable_west","clyde_cable_to_handrail_west","clyde_handrail_to_cable_east","clyde_cable_to_handrail_east"]:
  check.call(witnessed.has("gap:"+id),"native gap input: genuine mapped-input coverage "+id)
 check.call(helper._tested,"native gap input: fault controls execute at a genuine native captured finish")
 for result:Dictionary in helper.control_checks:check.call(result.passed,"native gap capture control: "+str(result.label))
 var context:Dictionary=helper.control_context
 check.call(not context.is_empty()and context.capture_source_sample==context.consuming_sample_frame and context.capture_frame>=context.capture_source_sample and context.capture_frame-context.capture_source_sample<=1 and context.sample_frame>=context.capture_frame and context.sample_frame-context.capture_frame<=1,"native gap input: actual capture and Main finish reference the same fresh sampled segment across physics order")
 helper.invalidate()
 old_helper.invalidate()
 game.native_gap_finish=old_helper
 game.score=old_score
 game.skater.spawn_position=old_spawn
 game.start_mode(old_free)
 Driver.side="west"
 Driver.extra_cable_wait=0

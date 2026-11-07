extends "res://tools/full_fidelity_capture.gd"
## PRIVATE tooling guard on ordinary Main: actual mapped half-pipe approach.
## Only initial spawn/heading are placed. No helper active/state injection.
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
class NativeSnapshotObserver extends Node:
 var observed:Node
 var runner
 var seen:=false
 var record:Dictionary={}
 func _physics_process(_delta:float)->void:
  if seen or not observed.skater._transition.active:return
  seen=true
  record=runner._snapshot(observed)
  var feature:Dictionary=observed.skater._transition.feature
  var body:StaticBody3D=feature.body
  runner._check(record.cylindrical_transition_active and record.cylindrical_transition_feature_id==str(feature.id) \
   and record.cylindrical_transition_body==str(body.get_path()) and is_finite(record.cylindrical_transition_theta),
   "capture snapshot: real mapped Main half-pipe contact records the actual cylindrical Dictionary ID/native body/theta")
func _frames(count:int)->void:
 for frame:int in count:
  await physics_frame
  await process_frame
func _run()->void:
 Classic.Setup.register_actions()
 Classic._release()
 game=Main.new()
 game.persistence_enabled=false
 root.add_child(game)
 var feature:Dictionary={}
 for item:Dictionary in game.world.get_transition_features():
  if item.id=="clyde_half_east":feature=item;break
 _check(not feature.is_empty(),"capture snapshot: ordinary Main retains the actual cylindrical half-pipe feature")
 if feature.is_empty():quit(1);return
 game.skater.spawn_position=Vector3(feature.entry)+Vector3.UP*.8
 game.start_mode(true)
 await _frames(45)
 var forward:Vector3=-Transform3D(feature.transform).basis.z
 game.skater.rotation.y=atan2(-forward.x,-forward.z)
 var observer:=NativeSnapshotObserver.new()
 observer.observed=game
 observer.runner=self
 observer.process_physics_priority=200
 root.add_child(observer)
 Input.action_press("push")
 await _frames(42)
 Input.action_release("push")
 for tick:int in 120:
  if observer.seen:break
  await _frames(1)
 _check(observer.seen,"capture snapshot: mapped acceleration earns a real active cylindrical branch without helper injection")
 FileAccess.open("res://.local/cylindrical-active-snapshot.json",FileAccess.WRITE).store_string(JSON.stringify({"seen":observer.seen,"snapshot":observer.record,"fixture":"ordinary Main actual half-pipe; one initial spawn/heading,42 mapped push ticks, then coasting; no active/state injection"}))
 print("CYLINDRICAL_ACTIVE_SNAPSHOT ",checks-failures," passed ",failures," failed seen=",observer.seen)
 observer.free()
 Classic._release()
 game.free()
 quit(1 if failures else 0)

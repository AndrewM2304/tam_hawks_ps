extends "res://tools/full_fidelity_capture.gd"
var variant:="control"
var rows:Array=[]
var endpoint_rows:Array=[]
var prime_position:=Vector3(-22,0,28)
func _run()->void:
 var args:=OS.get_cmdline_user_args()
 if args.size()!=1 or args[0]not in["control","candidate"]:
  push_error("Explicit arm control/candidate required")
  quit(2)
  return
 variant=args[0]
 RenderingServer.set_render_loop_enabled(false)
 game=Main.new()
 game.persistence_enabled=false
 root.add_child(game)
 game.start_mode(true)
 for tick in 40:
  await physics_frame
  await process_frame
 await PushContact.run_main(self,game,_check,_observe)
 _endpoint_fixtures()
 _check(rows.size()==657,"Arm comparison retains all657 real seven-phase observations")
 var f:=FileAccess.open("res://arm-"+variant+".json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"variant":variant,"checks":checks,"failures":failures,"native_motion":rows,"endpoint_fixtures":endpoint_rows,"physics_hz":Engine.physics_ticks_per_second,"scope":"PRIVATE currentMain mapped-input native observations. All original seven physical testphases retained, no renders/pixels/FPS/human cadence claim. Finalendpoint rows are separatelydeclared frozen-controller assetpose fixtures afterthe realphysical cohort."},"\t"))
 print("ARM_NATIVE checks=",checks," failures=",failures," real observations=",rows.size())
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)
func _mat(t:Transform3D)->Array:
 return [[t.basis.x.x,t.basis.y.x,t.basis.z.x,t.origin.x],[t.basis.x.y,t.basis.y.y,t.basis.z.y,t.origin.y],[t.basis.x.z,t.basis.y.z,t.basis.z.z,t.origin.z],[0,0,0,1]]
func _rig_data()->Dictionary:
 var rig:RefCounted=game.skater._visual_rig
 var bones:Array=[]
 for i in rig._garments.skeleton.get_bone_count():bones.append(_mat(rig._garments.skeleton.get_bone_global_pose(i)))
 return {"actor":_mat(game.skater.global_transform),"board":_mat(rig._board.global_transform),"rider":_mat(rig._rider.global_transform),"upper":_mat(rig._upper.global_transform),"head":_mat(rig._head.global_transform),"hand0":_mat(rig._arms[0].hand.global_transform),"hand1":_mat(rig._arms[1].hand.global_transform),"foot0":_mat(rig._legs[0].foot.global_transform),"foot1":_mat(rig._legs[1].foot.global_transform),"bones":bones,"push_phase":rig._push_phase,"push_blend":rig._push_blend,"arm_swing":rig._push_arm_swing * rig._push_blend if variant=="candidate" else sin(TAU*rig._push_phase)*rig._push_blend,"grab_blend":rig._grab_blend,"handplant_blend":rig._handplant_blend}
func _observe(phase:String,observed_game:Node,step:int)->void:
 if phase.is_empty()or phase=="fixture"or step<0:return
 await create_timer(0.0,true,false,true).timeout
 _global_step+=1
 var s:=_snapshot(observed_game)
 var rig:=_rig_data()
 rows.append({"phase":phase,"phase_step":step,"state":s,"rig":rig,"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames()})
 if phase=="push_contact_from_rest"and step==60:prime_position=observed_game.skater.global_position
func _endpoint_fixtures()->void:
 var actor:CharacterBody3D=game.skater
 var rig:RefCounted=actor._visual_rig
 actor.process_mode=Node.PROCESS_MODE_DISABLED
 actor.global_position=prime_position
 actor.velocity=Vector3(0,0,-11.5)
 var prime:Dictionary={"airborne":false,"grab":false,"flip":false,"manual":false,"grind":false,"speed":11.5,"push":true,"brake":false,"native_floor_valid":true}
 for pose:String in["grab","handplant"]:
  rig.reset()
  for tick in 31:rig.animate(1./60.,prime)
  var primed:Dictionary=_rig_data()
  var state:Dictionary={"airborne":pose=="grab","grab":pose=="grab","grab_id":"melon_grab","flip":false,"manual":false,"grind":false,"speed":0.,"push":false,"brake":false}
  if pose=="handplant":
   state.lip_active=true
   state.lip_id="handplant"
   state.lip_definition=Catalog.definition("handplant")
   state.lip_ground_point=actor.global_position
   state.lip_normal=Vector3.UP
  for tick in 120:rig.animate(1./60.,state)
  endpoint_rows.append({"pose":pose,"prime":primed,"final":_rig_data(),"declared_fixture":"Controller disabled afterallrealphysicaltraces; nativeVisual animate primesnonzero counterbalance thenholds fullpose120ticks. No ordinaryinput/motion claim forendpoints."})

extends RefCounted
const Feature=preload("res://game/levels/transition_feature.gd")
const Style=preload("res://game/tricks/grind_style.gd")

class RideWitness extends Node:
 var rider:Node
 var rows:Array[Dictionary]=[]
 var all_clear:=true
 var exact_supported:=true
 var release_exact:=false
 var saw_grind:=false
 var release_ticks:=0
 var previous_board:=Transform3D.IDENTITY
 var previous_body:=Transform3D.IDENTITY
 var maximum_angle:=0.0
 var maximum_relative_step:=0.0
 var maximum_anchor_error:=0.0
 func _physics_process(_delta:float)->void:
  if not is_instance_valid(rider) or (not rider.grinding and not saw_grind):return
  var frame:Transform3D=rider._board_visual.global_transform
  var body:Transform3D=rider.global_transform
  if saw_grind:
   var angle:float=previous_board.basis.get_rotation_quaternion().angle_to(frame.basis.get_rotation_quaternion())
   maximum_angle=maxf(maximum_angle,angle)
   maximum_relative_step=maxf(maximum_relative_step,(frame.origin-previous_board.origin-(body.origin-previous_body.origin)).length())
  var runtime_path_queries:int=rider._grind_clearance.last_path_queries
  var clear:bool=rider._grind_clearance.allows_frame(frame,frame.basis.y)
  all_clear=all_clear and clear
  var anchor_error:float=0.0
  if rider.grinding:
   var pose:Style.ContactPose=rider._grind_contact
   for index:int in pose.anchor_count:
    anchor_error=maxf(anchor_error,(frame*pose.anchors[index]).distance_to(pose.supports[index]))
   maximum_anchor_error=maxf(maximum_anchor_error,anchor_error)
   exact_supported=exact_supported and pose.anchor_count==2 and anchor_error<=.0001      and frame.origin.distance_to(pose.board_transform.origin)<=.0001      and frame.basis.x.distance_to(pose.board_transform.basis.x)<.00001      and frame.basis.y.distance_to(pose.board_transform.basis.y)<.00001      and frame.basis.z.distance_to(pose.board_transform.basis.z)<.00001
  else:
   release_ticks+=1
   if release_ticks==1:
    release_exact=frame.origin.distance_to(previous_board.origin)<=.00001       and frame.basis.x.distance_to(previous_board.basis.x)<.00001       and frame.basis.y.distance_to(previous_board.basis.y)<.00001       and frame.basis.z.distance_to(previous_board.basis.z)<.00001       and body.origin.distance_to(previous_body.origin)<=.00001
  rows.append({"physics":Engine.get_physics_frames(),"grinding":rider.grinding,"airborne":rider.airborne,
    "clear":clear,"last_runtime_path_queries":runtime_path_queries,"board":str(frame),"body":str(body),"anchor_error":anchor_error})
  saw_grind=true
  previous_board=frame
  previous_body=body

static func run(tree:SceneTree,game:Node,check:Callable)->void:
 var rider:Node=game.skater
 var cached:int=rider._grind_clearance.component_count
 await _native_captures(tree,game,check)
 check.call(cached==32,"round coping: actual admitted native skateboard cache has32components")
 for yaw:float in [0.0,PI*.5,-.61]:
  var feature:Node3D=Feature.new()
  feature.feature_id="RoundContact_"+str(yaw)
  feature.position=Vector3(0,70,0)
  feature.rotation.y=yaw
  feature.width=8.0
  feature.build_access=false
  tree.root.add_child(feature)
  await tree.physics_frame
  await tree.physics_frame
  var line=feature.get_grind_lines()[0]
  check.call(line.contact_round_declared and line.round_contact_live(),"round coping: exact live cylinder/feature/deck/crown profile "+str(yaw))
  var original:PackedVector3Array=line.points.duplicate()
  var body:StaticBody3D=feature.get_node("NativeSteelCoping")
  var deck:StaticBody3D=feature.get_node("RearDeck")
  var angle:float=rider._grind_clearance.round_roll_angle(line.contact_round_radius,line.contact_round_deck_reveal)
  check.call(angle>.0473 and angle<.05,"round coping: neutral roll derived from actual32-component wheel geometry")
  for direction:float in [-1.0,1.0]:
   for board_yaw:float in [0.0,PI]:
    var pose:=Style.ContactPose.new()
    var solved:bool=rider._solve_grind_contact(pose,line,line.length*.5,direction,board_yaw,"grind_50_50",0.0)
    var native:bool=solved and rider._round_grind_native_contacts(pose,line)
    var clear:bool=solved and rider._grind_board_clear(pose.board_transform,line,line.length*.5)
    var gap:float=_deck_gap(rider,pose.board_transform,deck) if solved else -INF
    var normal:Vector3=pose.board_transform.basis.y
    var expected:Vector3=Vector3.UP*cos(angle)+line.contact_round_outward*sin(angle)
    check.call(solved and native and clear and pose.anchor_count==2 and pose.max_error<=.0001 \
      and normal.distance_to(expected)<.00001 and gap>=0.0 and line.points==original,
      "round coping: exact two actual hanger/native cylinder contacts plus all-model clearance direction="+str(direction)+" boardyaw="+str(board_yaw)+" featureyaw="+str(yaw))
    print("ROUND_COPING_POSITIVE ",{"feature_yaw":yaw,"direction":direction,"board_yaw":board_yaw,"roll":angle,"anchor_error":pose.max_error,"deck_vertex_gap":gap,"owner":str(line.round_contact_rid()),"shape":line.contact_round_shape,"frame":str(pose.board_transform)})
  if yaw==0.0:
   await _negatives(tree,rider,feature,line,check)
  feature.queue_free()
  await tree.physics_frame
  await tree.physics_frame
  check.call(not line.round_contact_live() and not rider._grind_candidate_supported(line,line.length*.5,1.0),"round coping: freed native owner refuses before cast/query or generic fallback")

static func _deck_gap(rider:Node,frame:Transform3D,deck:StaticBody3D)->float:
 var primitive:CollisionShape3D=deck.shape_owner_get_owner(deck.shape_find_owner(0))
 var half:Vector3=primitive.shape.size*.5
 var minimum:float=INF
 for part:Dictionary in rider._grind_clearance._parts:
  for point:Vector3 in part.points:
   var local:Vector3=deck.to_local(frame*point)
   if absf(local.x)<=half.x and absf(local.z)<=half.z:
    minimum=minf(minimum,local.y-half.y)
 return minimum

static func _refused(rider:Node,line,check:Callable,label:String)->void:
 var pose:=Style.ContactPose.new()
 check.call(not line.round_contact_live() and not rider._solve_grind_contact(pose,line,line.length*.5,1.0,0.0,"grind_50_50",0.0) \
   and not rider._grind_candidate_supported(line,line.length*.5,1.0),"round coping negative: "+label+" rejects native profile/solve/generic fallback")

static func _negatives(tree:SceneTree,rider:Node,feature:Node3D,line,check:Callable)->void:
 var old_length:float=line.length
 for wrong:float in [0.0,NAN,old_length+.01]:
  line.length=wrong
  _refused(rider,line,check,"zero/NaN/stale chord length "+str(wrong))
 line.length=old_length
 var original_points:PackedVector3Array=line.points.duplicate()
 line.points[0]=Vector3(NAN,0,0)
 _refused(rider,line,check,"nonfinite native guide endpoint")
 line.points=original_points
 line.contact_vertical_offset=.01
 _refused(rider,line,check,"forged vertical crown offset")
 line.contact_vertical_offset=0.0
 line.contact_normal_offset=.01
 _refused(rider,line,check,"forged radial crown offset")
 line.contact_normal_offset=0.0
 var face_reveal:float=line.contact_round_face_reveal
 for wrong:float in [NAN,.02]:
  line.contact_round_face_reveal=wrong
  _refused(rider,line,check,"wrong/NaN native finite face reveal")
 line.contact_round_face_reveal=face_reveal
 var deck:StaticBody3D=feature.get_node("RearDeck")
 var deck_frame:Transform3D=deck.transform
 for shift:Vector3 in [Vector3(100,0,0),Vector3(0,0,100)]:
  deck.position+=shift
  _refused(rider,line,check,"same-height real Box moved away from finite coping "+str(shift))
  deck.transform=deck_frame
 deck.scale=Vector3(2,1,.5)
 _refused(rider,line,check,"nonunit Deck basis with determinant1")
 deck.transform=deck_frame
 var overflow:=Transform3D(Basis(Vector3(1e20,0,0),Vector3(0,1e20,0),Vector3(0,0,1e20)),Vector3.ZERO)
 check.call(not line._round_unit_frame(overflow),"round coping negative: finite entries with determinant overflow fail before native query")
 var radius:float=line.contact_round_radius
 var reveal:float=line.contact_round_deck_reveal
 var outward:Vector3=line.contact_round_outward
 var shape:int=line.contact_round_shape
 var body:StaticBody3D=feature.get_node("NativeSteelCoping")
 for wrong:float in [NAN,0.0,.04]:
  line.contact_round_radius=wrong
  _refused(rider,line,check,"wrong/NaN/zero native radius "+str(wrong))
 line.contact_round_radius=radius
 for wrong:float in [NAN,.02]:
  line.contact_round_deck_reveal=wrong
  _refused(rider,line,check,"wrong/NaN actual native deck reveal "+str(wrong))
 line.contact_round_deck_reveal=reveal
 for wrong:Vector3 in [Vector3.ZERO,-outward,Vector3.UP,Vector3(NAN,0,0)]:
  line.contact_round_outward=wrong
  _refused(rider,line,check,"zero/opposite/vertical/NaN outward "+str(wrong))
 line.contact_round_outward=outward
 line.contact_round_shape=1
 _refused(rider,line,check,"wrong integer shape")
 line.contact_round_shape=shape
 var source:String=line.contact_source
 line.contact_source="foreign"
 _refused(rider,line,check,"foreign declared source")
 line.contact_source=source
 body.set_meta("coping_feature",rider)
 _refused(rider,line,check,"wrong feature object")
 body.set_meta("coping_feature",feature)
 var saved:Transform3D=body.transform
 body.position.x+=.01
 _refused(rider,line,check,"moved native body cannot retain old crown")
 body.transform=saved
 body.scale.x=1.01
 _refused(rider,line,check,"scaled native body")
 body.transform=saved
 var weak:WeakRef=line._contact_round_body
 line._contact_round_body=weakref(feature.get_node("RearDeck"))
 _refused(rider,line,check,"foreign actual body/BoxShape")
 line._contact_round_body=weak
 var valid:bool=line.contact_verified
 line.contact_verified=false
 _refused(rider,line,check,"unverified contact cannot become legacy fallback")
 line.contact_verified=valid
 var pose:=Style.ContactPose.new()
 var solved:bool=rider._solve_grind_contact(pose,line,line.length*.5,1.0,0.0,"grind_50_50",0.0)
 check.call(solved,"round coping: fixture restored after malformed profile controls")
 if not solved:return
 var frame:Transform3D=pose.board_transform
 pose.board_transform.origin+=line.dir_at(line.length*.5)*(line.length+1.0)
 check.call(not rider._round_grind_native_contacts(pose,line),"round coping negative: real hanger rays beyond finite native ends fail")
 pose.board_transform=frame
 var blocker:=StaticBody3D.new()
 blocker.collision_layer=1
 var primitive:=CollisionShape3D.new()
 var box:=BoxShape3D.new()
 box.size=Vector3(.4,.1,.9)
 primitive.shape=box
 blocker.add_child(primitive)
 tree.root.add_child(blocker)
 blocker.global_position=frame.origin+Vector3.UP*.01
 await tree.physics_frame
 await tree.physics_frame
 check.call(not rider._grind_board_clear(frame,line,line.length*.5),"round coping negative: actual foreign blocker remains in full native model queries")
 blocker.queue_free()
 await tree.physics_frame
 await tree.physics_frame
 check.call(rider._grind_board_clear(frame,line,line.length*.5),"round coping: foreign blocker removal restores same authentic target")

static func _native_captures(tree:SceneTree,game:Node,check:Callable)->void:
 var rider:Node=game.skater
 var old_spawn:Vector3=rider.spawn_position
 var old_mode:bool=game.free_skate_mode
 var guide=null
 for line in game.world.get_grind_lines():
  if line.id=="Grind_KelvingrovePromenadeQuarter_Coping":guide=line
 check.call(guide!=null and guide.round_contact_live(),"round coping: actual promenade finite native cylinder is the moving-start fixture")
 if guide==null:return
 for direction:float in [-1.0,1.0]:
  for backwards:bool in [false,true]:
   for action:String in ["push","brake","grind","ollie","steer_left","steer_right"]:Input.action_release(action)
   rider.spawn_position=old_spawn
   game.start_mode(true)
   await tree.physics_frame
   await tree.process_frame
   rider.set_physics_process(false)
   var tangent:Vector3=guide.dir_at(guide.length*.5)*direction
   rider.spawn_position=guide.point_at(guide.length*.5)+Vector3.UP*.25+guide.contact_round_outward*.04
   rider.reset_skater()
   rider.velocity=tangent*4.0+Vector3.DOWN
   rider.speed=-4.0 if backwards else 4.0
   rider.airborne=true
   rider.rotation.y=atan2(-tangent.x,-tangent.z)+(PI if backwards else 0.0)
   rider.reset_physics_interpolation()
   var evidence:Dictionary={"entries":0,"bails":0}
   var entry:Callable=func(_id:String):evidence.entries+=1
   var bail:Callable=func():evidence.bails+=1
   rider.grind_captured.connect(entry)
   rider.bailed.connect(bail)
   var witness:=RideWitness.new()
   witness.rider=rider
   witness.process_physics_priority=100
   tree.root.add_child(witness)
   Input.action_press("grind")
   rider.set_physics_process(true)
   var contact_ticks:int=0
   var allclear:bool=true
   var error:float=0.0
   for tick:int in 45:
    await tree.physics_frame
    await tree.process_frame
    if rider.grinding:
     contact_ticks+=1
     allclear=allclear and rider._grind_clearance.allows_frame(rider._board_visual.global_transform,rider._board_visual.global_basis.y)
     error=maxf(error,rider._grind_contact.max_error)
     if contact_ticks>=12:break
   check.call(rider.grinding and rider._grind.line.id==guide.id and contact_ticks>=12      and rider._rail_backwards==backwards and evidence.entries==1 and evidence.bails==0      and error<=.0001 and allclear,
     "round coping: native mapped moving-start capture and12supported ticks travel="+str(direction)+" fakie="+str(backwards))
   print("ROUND_COPING_NATIVE_RUN ",{"direction":direction,"backwards":backwards,"contact_ticks":contact_ticks,"entries":evidence.entries,"bails":evidence.bails,"error":error,"all_model_clear":allclear,"speed":rider.speed,"position":str(rider.global_position)})
   Input.action_release("grind")
   await tree.physics_frame
   await tree.process_frame
   check.call(not rider.grinding and evidence.entries==1 and evidence.bails==0,"round coping: actual release ends once without another catch/award")
   for frame:int in 4:
    await tree.physics_frame
    await tree.process_frame
   check.call(witness.all_clear and witness.exact_supported and witness.release_exact      and witness.release_ticks>=4 and witness.maximum_anchor_error<=.0001,
     "round coping: every native physics board frame keeps exact roll/anchors and zero-travel release pose")
   print("ROUND_COPING_NATIVE_WITNESS ",{"direction":direction,"backwards":backwards,"all_clear":witness.all_clear,
     "exact_supported":witness.exact_supported,"release_exact":witness.release_exact,"release_ticks":witness.release_ticks,
     "maximum_angular_step":witness.maximum_angle,"maximum_relative_translation":witness.maximum_relative_step,
     "maximum_actual_anchor_error":witness.maximum_anchor_error,"rows":witness.rows})
   witness.queue_free()
   rider.grind_captured.disconnect(entry)
   rider.bailed.disconnect(bail)
 rider.spawn_position=old_spawn
 game.start_mode(old_mode)

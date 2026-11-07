extends "res://game/tricks/native_gap_finish.gd"
const Base=preload("res://game/tricks/native_gap_finish.gd")
var control_checks:Array=[]
var control_context:Dictionary={}
var _tested:=false
func _check(label:String,value:bool,expected:bool)->void:
 control_checks.append({"label":label,"observed":value,"expected":expected,"passed":value==expected,"physics":Engine.get_physics_frames()})
func finish(definition:Dictionary,from:Vector3,to:Vector3,sample_frame:int)->bool:
 if not _tested and str(definition.get("id","")).begins_with("clyde_cable_to_handrail_")and _finish_ready(definition,from,to,sample_frame):
  _tested=true
  _controls(definition,from,to,sample_frame)
 return super.finish(definition,from,to,sample_frame)
func _controls(definition:Dictionary,from:Vector3,to:Vector3,sample_frame:int)->void:
 var rider:CharacterBody3D=_object(_rider)
 var world:Node3D=_object(_world)
 var other:=Base.new()
 _check("independent control helper registers same genuine native scene",other.configure(world,rider),true)
 other._epoch=_epoch;other._capture_serial=_capture_serial
 var token:Dictionary=_pending.duplicate(true)
 other._pending=token.duplicate(true)
 _check("frozen actual capture interval is a nontrivial positive control",other._finish_ready(definition,from,to,sample_frame),true)
 control_context={"capture_frame":token.frame,"capture_source_sample":token.sample_frame,"consuming_sample_frame":sample_frame,"sample_frame":Engine.get_physics_frames(),"from":from,"to":to,"target":token.target,"native_rid":token.proof.rid.get_id(),"native_shape":token.proof.shape,"diagnostic_only":"Fault matrix clones a genuine token into an independently configured test helper; only final original helper return feeds Main. Native body/flag mutations are restored in the same callback; this epoch is not physical parity evidence."}
 for field:String in ["epoch","serial","frame","sample_frame","line_instance"]:
  other._pending=token.duplicate(true);other._pending[field]=float(token[field])
  _check("noninteger capture token field "+field,other._finish_ready(definition,from,to,sample_frame),false)
 for field:String in ["epoch","serial"]:
  other._pending=token.duplicate(true);other._pending[field]=int(token[field])-1
  _check("recycled stale capture "+field,other._finish_ready(definition,from,to,sample_frame),false)
 other._pending=token.duplicate(true);other._pending.frame=int(token.frame)-2
 _check("older than sampled capture interval",other._finish_ready(definition,from,to,sample_frame),false)
 other._pending=token.duplicate(true);other._pending.frame=Engine.get_physics_frames()+1
 _check("future capture clock",other._finish_ready(definition,from,to,sample_frame),false)
 other._pending=token.duplicate(true)
 _check("wrong previous-sample physics stamp",other._finish_ready(definition,from,to,sample_frame-1),false)
 _check("wrong sampled start",other._finish_ready(definition,from+Vector3(.001,0,0),to,sample_frame),false)
 _check("wrong sampled finish",other._finish_ready(definition,from,to+Vector3(.001,0,0),sample_frame),false)
 for patch:Dictionary in [{"id":"copied_unknown_gap"},{"finish_destination":"clyde_safe_handrail_east"},{"finish_kind":"unknown"},{"radius":0.8},{"start":Vector3.ZERO},{"direction":Vector3.BACK}]:
  var fake:Dictionary=definition.duplicate(true);fake.merge(patch,true)
  _check("copied or altered authoring declaration "+str(patch),other._finish_ready(fake,from,to,sample_frame),false)
 other._pending=token.duplicate(true);other._pending.raw_id="copied_"+str(token.raw_id)
 _check("copied raw guide identity",other._finish_ready(definition,from,to,sample_frame),false)
 other._pending=token.duplicate(true);other._pending.line_instance=int(token.line_instance)+1
 _check("wrong configured line instance",other._finish_ready(definition,from,to,sample_frame),false)
 other._pending=token.duplicate(true);other._pending.proof.rid=RID()
 _check("wrong native RID in capture proof",other._finish_ready(definition,from,to,sample_frame),false)
 other._pending=token.duplicate(true);other._pending.proof.shape=999
 _check("wrong integer native shape in capture proof",other._finish_ready(definition,from,to,sample_frame),false)
 other._pending=token.duplicate(true);other._pending.proof.shape=float(token.proof.shape)
 _check("fractional-type native shape refuses even equal numeric value",other._finish_ready(definition,from,to,sample_frame),false)
 other._pending=token.duplicate(true)
 var old_controls:bool=rider._controls_enabled;rider._controls_enabled=false
 _check("unsupported controls",other._finish_ready(definition,from,to,sample_frame),false);rider._controls_enabled=old_controls
 var old_entries:bool=rider._trick_entries_enabled;rider._trick_entries_enabled=false
 _check("disabled trick entries",other._finish_ready(definition,from,to,sample_frame),false);rider._trick_entries_enabled=old_entries
 var old_bail:bool=rider.bailing;rider.bailing=true
 _check("bailed rider",other._finish_ready(definition,from,to,sample_frame),false);rider.bailing=old_bail
 var old_air:bool=rider.airborne;rider.airborne=true
 _check("inconsistent airborne plus grind state",other._finish_ready(definition,from,to,sample_frame),false);rider.airborne=old_air
 other.invalidate();other._pending=token.duplicate(true)
 _check("reset epoch cannot replay old capture",other._finish_ready(definition,from,to,sample_frame),false)
 other._epoch=int(token.epoch)
 var target:Dictionary=other._targets[token.target]
 var owner:Dictionary={};var shape:Dictionary={}
 for candidate:Dictionary in target.owners:
  if candidate.rid==token.proof.rid:
   owner=candidate
   for candidate_shape:Dictionary in candidate.shapes:
    if candidate_shape.index==token.proof.shape:shape=candidate_shape
 _check("genuine registered native RID/shape located",not owner.is_empty()and not shape.is_empty(),true)
 if owner.is_empty()or shape.is_empty():return
 other._pending=token.duplicate(true)
 var old_index:int=shape.index;shape.index=int(owner.shape_count)
 _check("out-of-range cached integer shape fails before native API",other._finish_ready(definition,from,to,sample_frame),false);shape.index=old_index
 var old_shape_rid:RID=shape.rid;shape.rid=RID()
 _check("unregistered native shape RID",other._finish_ready(definition,from,to,sample_frame),false);shape.rid=old_shape_rid
 var body:StaticBody3D=other._object(owner.body)
 var primitive:CollisionShape3D=other._object(shape.node)
 var saved_frame:Transform3D=body.global_transform;body.global_position+=Vector3(.25,0,0)
 _check("actual moved native body",other._finish_ready(definition,from,to,sample_frame),false);body.global_transform=saved_frame
 _check("restored actual native body returns valid proof",other._finish_ready(definition,from,to,sample_frame),true)
 var saved_mask:int=body.collision_layer;body.collision_layer=0
 _check("actual disabled native layer",other._finish_ready(definition,from,to,sample_frame),false);body.collision_layer=saved_mask
 var saved_disabled:bool=primitive.disabled;primitive.disabled=true
 _check("actual disabled primitive",other._finish_ready(definition,from,to,sample_frame),false);primitive.disabled=saved_disabled
 var saved_shape:Shape3D=primitive.shape
 var saved_native_data:Variant=PhysicsServer3D.shape_get_data(saved_shape.get_rid())
 primitive.shape=SphereShape3D.new()
 _check("actual unsupported native shape",other._finish_ready(definition,from,to,sample_frame),false);primitive.shape=saved_shape
 primitive.force_update_transform()
 PhysicsServer3D.body_set_shape_transform(owner.rid,old_index,body.global_transform.affine_inverse()*Transform3D(shape.frame))
 PhysicsServer3D.shape_set_data(saved_shape.get_rid(),saved_native_data)
 _check("restored exact original native shape returns valid proof",other._finish_ready(definition,from,to,sample_frame),true)
 var exact_native_data:Variant=PhysicsServer3D.shape_get_data(saved_shape.get_rid())
 PhysicsServer3D.shape_set_data(saved_shape.get_rid(),Vector3(exact_native_data)+Vector3(.005,0,0))
 _check("actual raw native box data change refuses matching resource metadata",other._finish_ready(definition,from,to,sample_frame),false)
 PhysicsServer3D.shape_set_data(saved_shape.get_rid(),exact_native_data)
 var saved_size:Vector3=(primitive.shape as BoxShape3D).size;(primitive.shape as BoxShape3D).size+=Vector3(.01,0,0)
 _check("actual altered primitive data",other._finish_ready(definition,from,to,sample_frame),false);(primitive.shape as BoxShape3D).size=saved_size
 var copied:=StaticBody3D.new();copied.name="CopiedGapOwner"
 for key:Variant in body.get_meta_list():copied.set_meta(key,body.get_meta(key))
 (other._object(target.provider)as Node).add_child(copied)
 var saved_ref:WeakRef=owner.body;owner.body=weakref(copied)
 _check("copied metadata foreign body never grants native authority",other._finish_ready(definition,from,to,sample_frame),false);owner.body=saved_ref
 copied.queue_free()
 _check("unmodified genuine context remains valid after restored faults",other._finish_ready(definition,from,to,sample_frame),true)
 _check("first independent helper consumption succeeds",other.finish(definition,from,to,sample_frame),true)
 _check("same capture cannot be consumed twice",other.finish(definition,from,to,sample_frame),false)
 other._pending=token.duplicate(true)
 Input.action_release("grind")
 _check("actual released grind refuses stale captured finish",other._finish_ready(definition,from,to,sample_frame),false)
 Input.action_press("grind")
 _check("all native/frame/shape and rider flags restored",body.global_transform==saved_frame and primitive.shape==saved_shape and primitive.disabled==saved_disabled and body.collision_layer==saved_mask and rider._controls_enabled==old_controls and rider._trick_entries_enabled==old_entries and rider.bailing==old_bail and rider.airborne==old_air,true)

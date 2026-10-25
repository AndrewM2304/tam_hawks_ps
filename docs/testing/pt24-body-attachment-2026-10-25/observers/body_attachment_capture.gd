extends SceneTree
const Current = preload("res://game/player/skater.gd")
const Legacy = preload("res://.local/body_attachment_legacy_skater.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")
const SIZE := Vector2i(960,800)
var output := "res://.local/body-attachment-captures"
var camera: Camera3D
var actor: CharacterBody3D
var records: Array[Dictionary] = []
var failures := 0
func _initialize(): _run.call_deferred()
func _run():
 if DisplayServer.get_name()=="headless": quit(2); return
 DirAccess.make_dir_recursive_absolute(output)
 root.size=SIZE;root.content_scale_size=SIZE
 var env:=WorldEnvironment.new()
 var settings:=Environment.new();settings.background_mode=Environment.BG_COLOR;settings.background_color=Color("9aaebd")
 settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color.WHITE;settings.ambient_light_energy=.8
 env.environment=settings;root.add_child(env)
 var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-25,0);sun.light_energy=1.6;sun.shadow_enabled=true;root.add_child(sun)
 var floor:=StaticBody3D.new();root.add_child(floor)
 var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(20,.2,20);shape.shape=box;shape.position.y=-.1;floor.add_child(shape)
 var mesh:=MeshInstance3D.new();var displayed:=BoxMesh.new();displayed.size=box.size;mesh.mesh=displayed;mesh.position.y=-.1
 var mat:=StandardMaterial3D.new();mat.albedo_color=Color("777d7b");mesh.material_override=mat;floor.add_child(mesh)
 camera=Camera3D.new();camera.position=Vector3(2.7,1.6,3.4);camera.fov=36;root.add_child(camera);camera.look_at(Vector3(0,.82,0))
 var start:=_sources()
 for old: bool in [true,false]:
  actor=Legacy.new() if old else Current.new();root.add_child(actor)
  actor.set_physics_process(false);actor.set_process(false);actor.global_position=Vector3.ZERO
  camera.make_current()
  await physics_frame;await process_frame
  var rig: RefCounted=actor._visual_rig
  var neutral: Dictionary={"airborne":false,"grab":false,"flip":false,"manual":false,"grind":false,"speed":5.0,"push":false}
  for n: int in 30: rig.animate(1.0/60.0,neutral)
  var grab:=neutral.duplicate(true);grab.airborne=true;grab.grab=true;grab.grab_side=-1.0;grab.grab_target=Catalog.definition("melon_grab").grab_target;grab.grab_definition=Catalog.definition("melon_grab")
  actor._board_visual.rotation.x=-.08
  for n: int in 6:rig.animate(1.0/60.0,grab)
  await _capture(("before" if old else "after")+"-partial-grab",rig)
  for n: int in 84:rig.animate(1.0/60.0,grab)
  await _capture(("before" if old else "after")+"-active-grab",rig)
  actor._board_visual.rotation.x=0
  for n: int in 180:rig.animate(1.0/60.0,neutral)
  await _capture(("before" if old else "after")+"-released-skating",rig)
  for n: int in 30:rig.animate(1.0/60.0,grab)
  var bail:=neutral.duplicate(true);bail.bail=1.0
  rig.begin_bail()
  for n: int in 20:rig.animate(1.0/60.0,bail)
  for n: int in 42:
   bail.bail=1.0-smoothstep(0,1,float(n)/41.0);rig.animate(1.0/60.0,bail)
  for n: int in 180:rig.animate(1.0/60.0,neutral)
  await _capture(("before" if old else "after")+"-recovered-skating",rig)
  actor.queue_free();await process_frame;await physics_frame
 var end:=_sources()
 if start!=end:failures+=1
 var report: Dictionary={"frames":records,"failures":failures,"source_stable":start==end,"source_before":start,"source_after":end,"method":"Two real native Skaters with immutable previous visual versus fixed visual. Controller, native garments/binds and all assets identical. Explicit static Rig.animate sequences: partial/full Melon Grab,180 neutral skating-pose calls after release, and declared bail/get-up followed by180 neutral calls. Physics/automatic actor process disabled after construction; no Main/Music/profile. Completed native frame_post_draw readbacks. These are static causal pose controls, not recorded input flight or a timing benchmark."}
 var f:=FileAccess.open(output+"/manifest.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t")+"\n");f.close()
 print("BODY_CAPTURE frames=",records.size()," failures=",failures," source_stable=",start==end);quit(1 if failures else 0)
func _capture(label: String,rig: RefCounted):
 actor.reset_physics_interpolation();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 var frame:=root.get_texture().get_image();var path:=output+"/"+label+".png"
 if frame.get_size()!=SIZE or frame.save_png(path)!=OK:failures+=1
 records.append({"file":label+".png","sha256":FileAccess.get_sha256(path),"size":[frame.get_width(),frame.get_height()],"torso":var_to_str(rig._upper.global_transform),"grab_blend":rig._grab_blend,"physics_enabled":actor.is_physics_processing(),"automatic_process":actor.is_processing()})
 print("BODY_CAPTURE_FRAME ",label)
func _sources() -> Dictionary:
 var paths:=PackedStringArray(["res://project.godot","res://.local/body_attachment_capture.gd","res://.local/body_attachment_legacy_visual.gd","res://.local/body_attachment_legacy_skater.gd"])
 _collect("res://game",paths);paths.sort();var result: Dictionary={}
 for p: String in paths:result[p]=FileAccess.get_sha256(p)
 return result
func _collect(path: String,paths: PackedStringArray):
 var dir:=DirAccess.open(path)
 for f: String in dir.get_files():paths.append(path.path_join(f))
 for d: String in dir.get_directories():_collect(path.path_join(d),paths)

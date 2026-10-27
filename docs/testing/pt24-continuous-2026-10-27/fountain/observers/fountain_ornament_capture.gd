extends SceneTree
## Fresh-process A/B/A ornamental mesh comparison; no runtime feature switch.
const Main=preload("res://game/main.gd")
const LegacyMain=preload("res://.local/fountain_ornament_legacy_main.gd")
const Ornament=preload("res://tests/fountain_ornament_tests.gd")
const Finish=preload("res://tests/fountain_finish_tests.gd")
const OUTPUT="res://.local/fountain-ornament-captures"
const SAMPLES:=36
const SIZE:=Vector2i(960,640)
var phase:="profile"
var passed:=0
var failed:=0
var camera: Camera3D
var records: Array[Dictionary]=[]

func _initialize()->void:_run.call_deferred()

func _run()->void:
 if DisplayServer.get_name()=="headless":quit(2);return
 for argument: String in OS.get_cmdline_user_args():
  if argument.begins_with("--phase="):phase=argument.trim_prefix("--phase=")
 if phase not in ["original-a","profile","original-b"]:quit(2);return
 root.size=SIZE
 root.content_scale_size=SIZE
 Engine.max_fps=0
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 create_timer(180,true).timeout.connect(func():push_error("Ornament capture timed out");quit(2))
 var before:=_sources()
 var output:=OUTPUT.path_join(phase)
 DirAccess.make_dir_recursive_absolute(output)
 var game: Node=Main.new() if phase=="profile" else LegacyMain.new()
 game.persistence_enabled=false
 _check(not game.has_meta("pt24_design_preview"),"ornament capture: ordinary Main has no feature override")
 root.add_child(game)
 game.start_mode(true)
 game.apply_settings({"graphics_quality":"balanced"},false)
 for tick in 30:
  await physics_frame
  await process_frame
 _check(not game.music._can_control and not game.music._persist and game.music._worker==null,"ornament capture: no personal Music/profile access")
 await Finish.run(self,game,_check)
 if phase=="profile":await Ornament.run(self,game,_check)
 else:await physics_frame
 var geometry: Array[Dictionary]=[]
 for name: String in ["FountainPedestal","FountainBowl","FountainCrown"]:
  var part: MeshInstance3D=game.world.get_node("ExchangeFountain/"+name)
  var arrays:=part.mesh.surface_get_arrays(0)
  var index_count: int=arrays[Mesh.ARRAY_INDEX].size()
  geometry.append({"node":name,"mesh_class":part.mesh.get_class(),"vertices":arrays[Mesh.ARRAY_VERTEX].size(),"triangles":index_count/3,"surfaces":part.mesh.get_surface_count(),"transform":str(part.transform),"material_id":part.material_override.get_instance_id()})
 paused=true
 game.hud.visible=false
 camera=Camera3D.new()
 camera.process_mode=Node.PROCESS_MODE_ALWAYS
 camera.near=.04
 camera.far=220
 camera.fov=50
 root.add_child(camera)
 camera.make_current()
 for view: String in ["cup-overhead","court-approach"]:
  _place(view,0)
  for warm in 18:await RenderingServer.frame_post_draw
  var rows: Array[Dictionary]=[]
  var previous:=Time.get_ticks_usec()
  for sample in SAMPLES:
   _place(view,float(sample)/float(SAMPLES-1))
   await RenderingServer.frame_post_draw
   var now:=Time.get_ticks_usec()
   rows.append({"ms":float(now-previous)/1000.0,"draws":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),"primitives":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),"objects":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_OBJECTS_IN_FRAME),"total_draws":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),"total_primitives":int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),"texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),"buffer_bytes":int(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)),"video_bytes":int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))})
   previous=now
  var filename:=view+".png"
  var frame:=root.get_texture().get_image()
  _check(frame.get_size()==SIZE and frame.save_png(output.path_join(filename))==OK,"ornament capture: completed native image "+phase+" "+view)
  records.append({"view":view,"rows":rows,"image":filename,"sha256":FileAccess.get_sha256(output.path_join(filename)),"camera_end":str(camera.global_transform),"fov":camera.fov,"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames()})
 var after:=_sources()
 _check(before==after,"ornament capture: frozen source unchanged")
 var file:=FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"phase":phase,"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),"rendering_method":RenderingServer.get_current_rendering_method(),"size":[SIZE.x,SIZE.y],"passed":passed,"failed":failed,"source_before":before,"source_after":after,"source_stable":before==after,"geometry":geometry,"views":records,"method":"Fresh-process A/B/A: two exact source copies restore only the former three display-frustum constructors, with a Main preload redirect. Current phase uses unmodified current Main. All phases use persistence false before tree entry, no feature override,30 ordinary native updates then explicitly paused gameplay/hidden HUD and labelled authored cameras. Each view warms18 rendered frames then observes36 identical slightly moving camera bearings. Existing shared water shader TIME remains live. Counters are native viewport/Performance values and times are frame_post_draw wall intervals. These are short Linux software diagnostics, not normal-chase, gameplay, target-Mac/60fps or human art acceptance."},"\t")+"\n")
 file.close()
 print("RESULT: ",passed," passed, ",failed," failed")
 quit(1 if failed else 0)

func _place(view: String,t:float)->void:
 if view=="cup-overhead":
  camera.position=Vector3(.6*t,8.2,10.2)
  camera.look_at(Vector3(.2*t,1.3,10))
 else:
  var angle:=lerpf(.62,.69,t)
  camera.position=Vector3(cos(angle)*11,3.8,10+sin(angle)*11)
  camera.look_at(Vector3(0,1.3,10))
 camera.reset_physics_interpolation()

func _check(value:bool,label:String)->void:
 if value:passed+=1;print("PASS: ",label)
 else:failed+=1;print("FAIL: ",label)

func _sources()->Dictionary:
 var files:=PackedStringArray(["res://project.godot","res://.local/fountain_ornament_capture.gd","res://.local/fountain_ornament_capture.sh","res://.local/fountain_ornament_legacy_world.gd","res://.local/fountain_ornament_legacy_main.gd","res://.local/prepare_fountain_ornament.py","res://.local/fountain-ornament-legacy.json","res://.local/compare_fountain_ornament.py"])
 for directory: String in ["res://game","res://tests","res://tools"]:_collect(directory,files)
 files.sort()
 var result: Dictionary={}
 for path: String in files:result[path]=FileAccess.get_sha256(path)
 return result

func _collect(path:String,files:PackedStringArray)->void:
 var directory:=DirAccess.open(path)
 for filename: String in directory.get_files():files.append(path.path_join(filename))
 for child: String in directory.get_directories():
  if child!="__pycache__":_collect(path.path_join(child),files)
